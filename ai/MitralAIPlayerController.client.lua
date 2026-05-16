-- ROBLOX AI PLAYER CONTROLLER
-- Version: 1.0 (Experimental)
-- Requires: Mitral AI API Key

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local CONFIG = {
    API_BASE_URL = "https://api.mitral.ai/v1",
    MAX_RETRIES = 3,
    REQUEST_TIMEOUT = 10,
    SCREENSHOT_QUALITY = 0.7,
    UPDATE_INTERVAL = 0.1,
    MOVEMENT_PRECISION = 0.5,
    PARKOUR_ENABLED = true,
    PVP_MODE = false,
    DEBUG_MODE = false
}

-- State management
local state = {
    apiKey = nil,
    sessionId = nil,
    lastActionTime = 0,
    currentTask = nil,
    environmentScan = {},
    inventory = {},
    nearbyPlayers = {},
    combatTarget = nil,
    pathfinding = {
        currentPath = {},
        currentWaypoint = 1
    },
    screenshotCache = {}
}

-- Utility functions
local function debugLog(...)
    if CONFIG.DEBUG_MODE then
        print("[AI CONTROLLER]", ...)
    end
end

local function takeScreenshot()
    local screenshot = game:GetService("ScreenshotService"):CaptureScreenshot(true)
    local base64 = HttpService:JSONEncode({
        data = screenshot,
        format = "png",
        quality = CONFIG.SCREENSHOT_QUALITY
    })
    return base64
end

local function scanEnvironment()
    local scanData = {
        position = rootPart.Position,
        rotation = rootPart.Orientation,
        velocity = rootPart.Velocity,
        health = humanoid.Health,
        maxHealth = humanoid.MaxHealth,
        nearbyObjects = {},
        terrain = {}
    }

    -- Scan for nearby objects
    local region = Region3.new(
        rootPart.Position - Vector3.new(50, 50, 50),
        rootPart.Position + Vector3.new(50, 50, 50)
    )
    local parts = workspace:FindPartsInRegion3(region, nil, math.huge)

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and part ~= rootPart and part.Parent ~= character then
            table.insert(scanData.nearbyObjects, {
                name = part.Name,
                class = part.ClassName,
                position = part.Position,
                size = part.Size,
                distance = (part.Position - rootPart.Position).Magnitude,
                canCollide = part.CanCollide,
                transparency = part.Transparency,
                parent = part.Parent and part.Parent.Name or "nil"
            })
        end
    end

    -- Scan for players
    scanData.nearbyPlayers = {}
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                table.insert(scanData.nearbyPlayers, {
                    name = otherPlayer.Name,
                    position = otherRoot.Position,
                    distance = (otherRoot.Position - rootPart.Position).Magnitude,
                    health = otherPlayer.Character:FindFirstChild("Humanoid") and otherPlayer.Character.Humanoid.Health or 0,
                    isFriend = otherPlayer:IsFriendsWith(player.UserId),
                    team = otherPlayer.Team and otherPlayer.Team.Name or "None"
                })
            end
        end
    end

    -- Scan terrain
    local rayOrigin = rootPart.Position + Vector3.new(0, 10, 0)
    local rayDirection = Vector3.new(0, -20, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if raycastResult then
        scanData.terrain = {
            material = raycastResult.Material.Name,
            normal = raycastResult.Normal,
            position = raycastResult.Position
        }
    end

    return scanData
end

local function getInventory()
    local inventory = {}
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        table.insert(inventory, {
            name = tool.Name,
            class = tool.ClassName,
            equipped = false
        })
    end

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(inventory, {
                name = tool.Name,
                class = tool.ClassName,
                equipped = true
            })
        end
    end

    return inventory
end

local function sendToAI(prompt, data)
    if not state.apiKey then
        warn("No API key set!")
        return nil
    end

    local url = CONFIG.API_BASE_URL .. "/chat/completions"
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. state.apiKey
    }

    local body = {
        model = "mitral-ai-latest",
        messages = [{
            role = "user",
            content = prompt,
            data = data or {}
        }],
        max_tokens = 1000,
        temperature = 0.7,
        tools = {
            {
                type = "function",
                function = {
                    name = "execute_action",
                    description = "Execute a game action",
                    parameters = {
                        type = "object",
                        properties = {
                            action = {
                                type = "string",
                                enum = {
                                    "move", "jump", "attack", "use_tool",
                                    "interact", "build", "parkour", "screenshot",
                                    "scan", "chat", "emote", "respawn"
                                }
                            },
                            target = { type = "string" },
                            parameters = { type = "object" }
                        },
                        required = { "action" }
                    }
                }
            },
            {
                type = "function",
                function = {
                    name = "get_game_state",
                    description = "Get current game state information"
                }
            }
        }
    }

    local success, response = pcall(function()
        return HttpService:PostAsync(url, HttpService:JSONEncode(body), Enum.HttpContentType.ApplicationJson, false, headers)
    end)

    if not success then
        warn("API request failed:", response)
        return nil
    end

    local decoded = HttpService:JSONDecode(response)
    if not decoded or not decoded.choices or #decoded.choices == 0 then
        warn("Invalid API response")
        return nil
    end

    return decoded.choices[1].message
end

-- Action execution functions
local function executeMovement(targetPosition, precision)
    precision = precision or CONFIG.MOVEMENT_PRECISION
    local direction = (targetPosition - rootPart.Position).Unit
    local distance = (targetPosition - rootPart.Position).Magnitude

    -- Use pathfinding if available
    local path = game:GetService("PathfindingService"):CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    path:ComputeAsync(rootPart.Position, targetPosition)

    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()

        for i, waypoint in ipairs(waypoints) do
            if not waypoint.Action then
                -- Move to waypoint
                local moveDirection = (waypoint.Position - rootPart.Position).Unit
                humanoid:Move(moveDirection, false)

                -- Wait until we're close enough to the waypoint
                repeat
                    RunService.Heartbeat:Wait()
                until (rootPart.Position - waypoint.Position).Magnitude < precision or
                      (rootPart.Position - targetPosition).Magnitude < 2
            else
                -- Handle special actions (jump, climb, etc.)
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    else
        -- Fallback to direct movement
        humanoid:Move(direction, false)

        -- Wait until we're close enough
        local startTime = tick()
        repeat
            RunService.Heartbeat:Wait()
        until (rootPart.Position - targetPosition).Magnitude < precision or
              tick() - startTime > 10
    end
end

local function executeJump()
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function executeAttack(target)
    if not target then return false end

    -- Find the closest attackable part
    local targetCharacter = target.Character or target
    if not targetCharacter then return false end

    local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then return false end

    -- Equip best weapon
    local bestWeapon = nil
    local bestDamage = 0

    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local damage = tool:GetAttribute("Damage") or 10
            if damage > bestDamage then
                bestDamage = damage
                bestWeapon = tool
            end
        end
    end

    if bestWeapon then
        bestWeapon.Parent = character
        humanoid:EquipTool(bestWeapon)
    end

    -- Move to attack range
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        local distance = (targetRoot.Position - rootPart.Position).Magnitude
        if distance > 5 then
            executeMovement(targetRoot.Position + (rootPart.Position - targetRoot.Position).Unit * 3)
        end

        -- Face the target
        character:SetPrimaryPartCFrame(CFrame.lookAt(rootPart.Position, targetRoot.Position))

        -- Attack
        if bestWeapon then
            -- Simulate tool activation
            VirtualInputManager:SendMouseButtonEvent(
                targetRoot.Position.X,
                targetRoot.Position.Y,
                0, -- Left mouse button
                true,
                nil,
                1
            )
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(
                targetRoot.Position.X,
                targetRoot.Position.Y,
                0,
                false,
                nil,
                1
            )
        else
            -- Punch
            humanoid:ChangeState(Enum.HumanoidStateType.Attacking)
        end
    end

    return true
end

local function executeParkour()
    -- Advanced parkour system
    local rayOrigin = rootPart.Position
    local rayDirection = rootPart.CFrame.LookVector * 10
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        local obstacle = raycastResult.Instance
        local obstaclePosition = raycastResult.Position
        local obstacleNormal = raycastResult.Normal

        -- Check if we can jump over
        local heightDifference = obstaclePosition.Y - rootPart.Position.Y

        if heightDifference < 5 then
            -- Jump over
            executeJump()
            task.wait(0.3)
            humanoid:Move(rootPart.CFrame.LookVector, false)
        elseif heightDifference < 10 and obstacleNormal.Y > 0.7 then
            -- Climb
            humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
        else
            -- Find alternative path
            local leftCheck = workspace:Raycast(
                rayOrigin,
                rootPart.CFrame.RightVector * 5,
                raycastParams
            )

            local rightCheck = workspace:Raycast(
                rayOrigin,
                -rootPart.CFrame.RightVector * 5,
                raycastParams
            )

            if not leftCheck then
                -- Move left
                humanoid:Move(-rootPart.CFrame.RightVector, false)
            elseif not rightCheck then
                -- Move right
                humanoid:Move(rootPart.CFrame.RightVector, false)
            else
                -- Try to jump
                executeJump()
            end
        end
    else
        -- No obstacles, keep moving forward
        humanoid:Move(rootPart.CFrame.LookVector, false)
    end
end

local function executeToolUse(toolName, target)
    local tool = player.Backpack:FindFirstChild(toolName) or
                 character:FindFirstChild(toolName)

    if tool and tool:IsA("Tool") then
        tool.Parent = character
        humanoid:EquipTool(tool)

        if target then
            -- Aim at target
            if typeof(target) == "Instance" and target:IsA("BasePart") then
                character:SetPrimaryPartCFrame(CFrame.lookAt(rootPart.Position, target.Position))
            end

            -- Activate tool
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 1)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 1)
        else
            -- Just equip the tool
            return true
        end
    end

    return false
end

local function executeChat(message, targetPlayer)
    if targetPlayer then
        -- Whisper
        game:GetService("Chat"):Chat(
            character.Head,
            "/w " .. targetPlayer.Name .. " " .. message,
            Enum.ChatColor.White
        )
    else
        -- Global chat
        game:GetService("Chat"):Chat(
            character.Head,
            message,
            Enum.ChatColor.White
        )
    end
end

-- Main AI loop
local function aiThinkLoop()
    while true do
        if not state.apiKey then
            task.wait(1)
            continue
        end

        -- Update state
        state.environmentScan = scanEnvironment()
        state.inventory = getInventory()

        -- Prepare context for AI
        local context = {
            player = {
                name = player.Name,
                userId = player.UserId,
                position = rootPart.Position,
                health = humanoid.Health,
                maxHealth = humanoid.MaxHealth,
                walkSpeed = humanoid.WalkSpeed,
                jumpPower = humanoid.JumpPower,
                team = player.Team and player.Team.Name or "None"
            },
            environment = state.environmentScan,
            inventory = state.inventory,
            time = os.time(),
            currentTask = state.currentTask,
            config = CONFIG
        }

        -- Get AI decision
        local prompt = [[
        You are an advanced AI controlling a Roblox character. Your goal is to play the game optimally based on the current situation.

        Current context:
        ]] .. HttpService:JSONEncode(context) .. [[

        Available actions:
        - move: Move to a specific position (parameters: {x, y, z})
        - jump: Make the character jump
        - attack: Attack a target (parameters: {targetName})
        - use_tool: Use a tool from inventory (parameters: {toolName, target})
        - interact: Interact with an object (parameters: {objectName})
        - parkour: Perform parkour to overcome obstacles
        - screenshot: Take a screenshot of the current view
        - scan: Perform a detailed environment scan
        - chat: Send a chat message (parameters: {message, targetPlayer})
        - emote: Perform an emote (parameters: {emoteName})
        - respawn: Respawn the character
        - set_mode: Change AI mode (parameters: {mode: "pvp", "parkour", "build", "explore"})

        Current task: ]] .. (state.currentTask or "None") .. [[

        What action should be performed next? Respond with a tool call.
        ]]

        local response = sendToAI(prompt, context)

        if response and response.tool_calls then
            for _, toolCall in ipairs(response.tool_calls) do
                if toolCall.function.name == "execute_action" then
                    local args = toolCall.function.arguments
                    debugLog("Executing action:", args.action)

                    if args.action == "move" and args.parameters then
                        local targetPos = Vector3.new(
                            args.parameters.x,
                            args.parameters.y,
                            args.parameters.z
                        )
                        executeMovement(targetPos)
                    elseif args.action == "jump" then
                        executeJump()
                    elseif args.action == "attack" and args.target then
                        -- Find target in nearby players
                        for _, np in ipairs(state.environmentScan.nearbyPlayers) do
                            if np.name:lower():find(args.target:lower()) then
                                local targetPlayer = Players:FindFirstChild(np.name)
                                if targetPlayer and targetPlayer.Character then
                                    executeAttack(targetPlayer.Character)
                                end
                                break
                            end
                        end
                    elseif args.action == "use_tool" and args.parameters then
                        executeToolUse(args.parameters.toolName, args.parameters.target)
                    elseif args.action == "parkour" then
                        executeParkour()
                    elseif args.action == "screenshot" then
                        local screenshot = takeScreenshot()
                        -- Send screenshot to AI for analysis
                        sendToAI("Analyze this screenshot:", {
                            screenshot = screenshot,
                            context = context
                        })
                    elseif args.action == "chat" and args.parameters then
                        executeChat(args.parameters.message, args.parameters.targetPlayer)
                    elseif args.action == "set_mode" and args.parameters then
                        if args.parameters.mode == "pvp" then
                            CONFIG.PVP_MODE = true
                            CONFIG.PARKOUR_ENABLED = false
                        elseif args.parameters.mode == "parkour" then
                            CONFIG.PVP_MODE = false
                            CONFIG.PARKOUR_ENABLED = true
                        end
                    end
                elseif toolCall.function.name == "get_game_state" then
                    -- Already provided in context
                end
            end
        end

        task.wait(CONFIG.UPDATE_INTERVAL)
    end
end

-- API Key Input GUI
local function createAPIKeyInput()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AIControllerGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 200)
    frame.Position = UDim2.new(0.5, -200, 0.5, -100)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Text = "MITRAL AI CONTROLLER"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local desc = Instance.new("TextLabel")
    desc.Text = "Enter your Mitral AI API key to enable AI control:"
    desc.Size = UDim2.new(1, -20, 0, 20)
    desc.Position = UDim2.new(0, 10, 0, 40)
    desc.BackgroundTransparency = 1
    desc.TextColor3 = Color3.fromRGB(180, 180, 180)
    desc.TextSize = 14
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 0, 30)
    input.Position = UDim2.new(0, 10, 0, 70)
    input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    input.BorderColor3 = Color3.fromRGB(70, 70, 70)
    input.TextColor3 = Color3.fromRGB(220, 220, 220)
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.PlaceholderText = "sk-ant-..."
    input.Text = ""
    input.Parent = frame

    local submit = Instance.new("TextButton")
    submit.Size = UDim2.new(0.5, -15, 0, 30)
    submit.Position = UDim2.new(0, 10, 0, 110)
    submit.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    submit.TextColor3 = Color3.fromRGB(255, 255, 255)
    submit.TextSize = 14
    submit.Font = Enum.Font.GothamBold
    submit.Text = "ACTIVATE AI"
    submit.Parent = frame

    local cancel = Instance.new("TextButton")
    cancel.Size = UDim2.new(0.5, -15, 0, 30)
    cancel.Position = UDim2.new(0.5, 5, 0, 110)
    cancel.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
    cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancel.TextSize = 14
    cancel.Font = Enum.Font.GothamBold
    cancel.Text = "CANCEL"
    cancel.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 150)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(180, 180, 180)
    status.TextSize = 12
    status.Text = "Status: Ready"
    status.Name = "StatusLabel"
    status.Parent = frame

    submit.MouseButton1Click:Connect(function()
        local key = input.Text:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
        if key ~= "" and key:match("^sk%-) then
            state.apiKey = key
            status.Text = "Status: API Key saved! Starting AI..."
            status.TextColor3 = Color3.fromRGB(100, 200, 100)

            task.wait(1)
            screenGui:Destroy()

            -- Start AI think loop
            coroutine.wrap(aiThinkLoop)()
        else
            status.Text = "Status: Invalid API key format"
            status.TextColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)

    cancel.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
end

-- Initialize
task.wait(1) -- Wait for game to load
createAPIKeyInput()

-- Cleanup
game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    if coroutine.running(aiThinkLoop) then
        debugLog("Character removed, stopping AI")
        -- Add cleanup code here
    end
end)
