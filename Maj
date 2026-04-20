--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                    AI FRIEND v2.0                         ║
    ║          Your Intelligent Roblox Companion                ║
    ║                                                           ║
    ║  • Sees the world through advanced vision system          ║
    ║  • Chats naturally with context awareness                 ║
    ║  • Moves, jumps, runs like a real player                  ║
    ║  • Interacts with UI elements intelligently               ║
    ║  • All actions register as YOU (server-sided)             ║
    ╚═══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
--                    CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local CONFIG = {
    -- API SETTINGS (Choose one)
    API_PROVIDER = "openrouter", -- "mistral" or "openrouter"
    
    -- OpenRouter Settings
    OPENROUTER_KEY = "YOUR_OPENROUTER_API_KEY_HERE",
    OPENROUTER_MODEL = "mistralai/mistral-7b-instruct", -- or "anthropic/claude-3-haiku"
    
    -- Mistral Settings  
    MISTRAL_KEY = "YOUR_MISTRAL_API_KEY_HERE",
    MISTRAL_MODEL = "mistral-small-latest",
    
    -- AI PERSONALITY
    PERSONALITY = {
        Name = "Nexus",
        Traits = "friendly, curious, helpful, playful, observant",
        ChatFrequency = 8, -- seconds between autonomous chats
        ResponseStyle = "casual and enthusiastic"
    },
    
    -- VISUAL SETTINGS
    FRIEND_APPEARANCE = {
        HeadColor = Color3.fromRGB(255, 200, 50),
        TorsoColor = Color3.fromRGB(100, 150, 255),
        LeftArmColor = Color3.fromRGB(100, 150, 255),
        RightArmColor = Color3.fromRGB(100, 150, 255),
        LeftLegColor = Color3.fromRGB(50, 50, 50),
        RightLegColor = Color3.fromRGB(50, 50, 50),
        DisplayName = "🤖 AI Friend",
        WalkSpeed = 16,
        JumpPower = 50
    },
    
    -- BEHAVIOR SETTINGS
    FOLLOW_DISTANCE = 5, -- studs
    VISION_UPDATE_RATE = 0.5, -- seconds
    MAX_CHAT_HISTORY = 20,
    INTERACTION_RANGE = 10, -- studs for UI interaction
    DEBUG_MODE = true
}

-- ═══════════════════════════════════════════════════════════
--                    SERVICES & GLOBALS
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local Chat = game:GetService("Chat")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- AI Friend Character
local AIFriend = nil
local AIHumanoid = nil
local AIRootPart = nil

-- State Management
local ChatHistory = {}
local WorldKnowledge = {
    VisibleParts = {},
    UIElements = {},
    NearbyPlayers = {},
    CurrentTask = "idle",
    LastVisionUpdate = 0
}

local IsThinking = false
local LastChatTime = 0

-- ═══════════════════════════════════════════════════════════
--                    UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function DebugLog(message)
    if CONFIG.DEBUG_MODE then
        print("[AI FRIEND] " .. message)
    end
end

local function ShowChatBubble(character, message)
    if character and character:FindFirstChild("Head") then
        game:GetService("Chat"):Chat(character.Head, message, Enum.ChatColor.Blue)
    end
end

local function GetDistanceToPlayer()
    if AIRootPart and HumanoidRootPart then
        return (AIRootPart.Position - HumanoidRootPart.Position).Magnitude
    end
    return math.huge
end

-- ═══════════════════════════════════════════════════════════
--                    AI API INTEGRATION
-- ═══════════════════════════════════════════════════════════

local function CallOpenRouter(messages)
    local url = "https://openrouter.ai/api/v1/chat/completions"
    
    local headers = {
        ["Authorization"] = "Bearer " .. CONFIG.OPENROUTER_KEY,
        ["Content-Type"] = "application/json",
        ["HTTP-Referer"] = "https://roblox.com",
        ["X-Title"] = "Roblox AI Friend"
    }
    
    local body = {
        model = CONFIG.OPENROUTER_MODEL,
        messages = messages,
        max_tokens = 150,
        temperature = 0.8
    }
    
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode(body)
        })
    end)
    
    if success and response.Success then
        local data = HttpService:JSONDecode(response.Body)
        if data.choices and data.choices[1] then
            return data.choices[1].message.content
        end
    end
    
    return nil
end

local function CallMistral(messages)
    local url = "https://api.mistral.ai/v1/chat/completions"
    
    local headers = {
        ["Authorization"] = "Bearer " .. CONFIG.MISTRAL_KEY,
        ["Content-Type"] = "application/json"
    }
    
    local body = {
        model = CONFIG.MISTRAL_MODEL,
        messages = messages,
        max_tokens = 150,
        temperature = 0.8
    }
    
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode(body)
        })
    end)
    
    if success and response.Success then
        local data = HttpService:JSONDecode(response.Body)
        if data.choices and data.choices[1] then
            return data.choices[1].message.content
        end
    end
    
    return nil
end

local function GetAIResponse(userMessage, systemContext)
    local messages = {
        {
            role = "system",
            content = string.format(
                "You are %s, an AI companion in Roblox. Personality: %s. Style: %s. Keep responses under 50 words, conversational and in-character. Context: %s",
                CONFIG.PERSONALITY.Name,
                CONFIG.PERSONALITY.Traits,
                CONFIG.PERSONALITY.ResponseStyle,
                systemContext or "Playing Roblox"
            )
        }
    }
    
    -- Add recent chat history
    for i = math.max(1, #ChatHistory - 5), #ChatHistory do
        table.insert(messages, ChatHistory[i])
    end
    
    -- Add current message
    if userMessage then
        table.insert(messages, {role = "user", content = userMessage})
    end
    
    -- Call appropriate API
    local response = nil
    if CONFIG.API_PROVIDER == "openrouter" then
        response = CallOpenRouter(messages)
    elseif CONFIG.API_PROVIDER == "mistral" then
        response = CallMistral(messages)
    end
    
    if response then
        -- Store in history
        table.insert(ChatHistory, {role = "user", content = userMessage or "(observing)"})
        table.insert(ChatHistory, {role = "assistant", content = response})
        
        -- Trim history
        while #ChatHistory > CONFIG.MAX_CHAT_HISTORY do
            table.remove(ChatHistory, 1)
        end
        
        return response
    end
    
    return "*thinking...*"
end

-- ═══════════════════════════════════════════════════════════
--                    VISION SYSTEM
-- ═══════════════════════════════════════════════════════════

local function ScanEnvironment()
    if not AIRootPart then return "" end
    
    local vision = {
        parts = {},
        ui = {},
        players = {}
    }
    
    -- Scan nearby parts
    local region = Region3.new(
        AIRootPart.Position - Vector3.new(50, 50, 50),
        AIRootPart.Position + Vector3.new(50, 50, 50)
    )
    region = region:ExpandToGrid(4)
    
    local partsInRegion = workspace:FindPartsInRegion3(region, AIFriend, 100)
    
    for _, part in ipairs(partsInRegion) do
        if part:IsA("BasePart") and part.Parent then
            local distance = (part.Position - AIRootPart.Position).Magnitude
            if distance < 30 then
                local info = {
                    name = part.Name,
                    class = part.ClassName,
                    distance = math.floor(distance),
                    parent = part.Parent.Name
                }
                
                -- Check for special interactions
                if part:FindFirstChild("ClickDetector") then
                    info.clickable = true
                end
                if part:FindFirstChild("ProximityPrompt") then
                    info.proximity = true
                end
                
                table.insert(vision.parts, info)
            end
        end
    end
    
    -- Scan UI elements
    local playerGui = Player:WaitForChild("PlayerGui")
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("GuiButton") or gui:IsA("TextButton") or gui:IsA("ImageButton") then
            if gui.Visible then
                table.insert(vision.ui, {
                    type = gui.ClassName,
                    name = gui.Name,
                    text = gui:IsA("TextButton") and gui.Text or "",
                    parent = gui.Parent.Name
                })
            end
        end
    end
    
    -- Scan nearby players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - AIRootPart.Position).Magnitude
                if distance < 30 then
                    table.insert(vision.players, {
                        name = player.Name,
                        distance = math.floor(distance)
                    })
                end
            end
        end
    end
    
    WorldKnowledge.VisibleParts = vision.parts
    WorldKnowledge.UIElements = vision.ui
    WorldKnowledge.NearbyPlayers = vision.players
    
    -- Build context string
    local context = string.format(
        "I see %d objects, %d UI elements, %d players nearby. Distance to you: %d studs.",
        #vision.parts,
        #vision.ui,
        #vision.players,
        math.floor(GetDistanceToPlayer())
    )
    
    return context
end

-- ═══════════════════════════════════════════════════════════
--                    MOVEMENT & ACTIONS
-- ═══════════════════════════════════════════════════════════

local CurrentPath = nil
local PathWaypoints = {}
local CurrentWaypointIndex = 0

local function MoveToPosition(targetPosition)
    if not AIHumanoid or not AIRootPart then return end
    
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(AIRootPart.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        PathWaypoints = path:GetWaypoints()
        CurrentWaypointIndex = 1
        CurrentPath = path
        
        -- Start moving
        for i, waypoint in ipairs(PathWaypoints) do
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                AIHumanoid.Jump = true
            end
            AIHumanoid:MoveTo(waypoint.Position)
            
            local timeout = 8
            local startTime = tick()
            while (AIRootPart.Position - waypoint.Position).Magnitude > 4 do
                if tick() - startTime > timeout then
                    break
                end
                wait(0.1)
            end
        end
    else
        -- Simple move if pathfinding fails
        AIHumanoid:MoveTo(targetPosition)
    end
end

local function FollowPlayer()
    if not AIRootPart or not HumanoidRootPart then return end
    
    local distance = GetDistanceToPlayer()
    
    if distance > CONFIG.FOLLOW_DISTANCE + 3 then
        -- Move closer to player
        MoveToPosition(HumanoidRootPart.Position)
    elseif distance < CONFIG.FOLLOW_DISTANCE - 2 then
        -- Too close, back up a bit
        local direction = (AIRootPart.Position - HumanoidRootPart.Position).Unit
        local backupPos = AIRootPart.Position + (direction * 2)
        AIHumanoid:MoveTo(backupPos)
    end
end

local function PerformAction(actionType, target)
    DebugLog("Performing action: " .. actionType)
    
    if actionType == "jump" then
        AIHumanoid.Jump = true
        
    elseif actionType == "run" then
        AIHumanoid.WalkSpeed = CONFIG.FRIEND_APPEARANCE.WalkSpeed * 1.5
        wait(2)
        AIHumanoid.WalkSpeed = CONFIG.FRIEND_APPEARANCE.WalkSpeed
        
    elseif actionType == "click_ui" and target then
        -- Find the UI element
        local playerGui = Player:WaitForChild("PlayerGui")
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui.Name == target and (gui:IsA("GuiButton") or gui:IsA("TextButton")) then
                -- Simulate click through VirtualUser (registers as player action)
                local vpSize = workspace.CurrentCamera.ViewportSize
                local absPos = gui.AbsolutePosition
                local absSize = gui.AbsoluteSize
                local centerX = absPos.X + absSize.X / 2
                local centerY = absPos.Y + absSize.Y / 2
                
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(centerX, centerY))
                DebugLog("Clicked UI: " .. target)
                break
            end
        end
        
    elseif actionType == "interact" and target then
        -- Find and interact with clickable object
        for _, part in ipairs(workspace:GetDescendants()) do
            if part.Name == target then
                if part:FindFirstChild("ClickDetector") then
                    fireclickdetector(part.ClickDetector)
                    DebugLog("Interacted with: " .. target)
                elseif part:FindFirstChild("ProximityPrompt") then
                    fireproximityprompt(part.ProximityPrompt)
                    DebugLog("Triggered proximity: " .. target)
                end
                break
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--                    CHARACTER CREATION
-- ═══════════════════════════════════════════════════════════

local function CreateAIFriend()
    DebugLog("Creating AI Friend...")
    
    -- Create model
    local model = Instance.new("Model")
    model.Name = CONFIG.PERSONALITY.Name
    
    -- Create parts
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.BrickColor = BrickColor.new(CONFIG.FRIEND_APPEARANCE.HeadColor)
    head.Parent = model
    
    local face = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.BrickColor = BrickColor.new(CONFIG.FRIEND_APPEARANCE.TorsoColor)
    torso.Parent = model
    
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.BrickColor = BrickColor.new(CONFIG.FRIEND_APPEARANCE.LeftArmColor)
    leftArm.Parent = model
    
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.BrickColor = BrickColor.new(CONFIG.FRIEND_APPEARANCE.RightArmColor)
    rightArm.Parent = model
    
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.BrickColor = BrickColor.new(CONFIG.FRIEND_APPEARANCE.LeftLegColor)
    leftLeg.Parent = model
    
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.BrickColor = BrickColor.new(CONFIG.FRIEND_APPEARANCE.RightLegColor)
    rightLeg.Parent = model
    
    -- Create humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = model
    humanoid.WalkSpeed = CONFIG.FRIEND_APPEARANCE.WalkSpeed
    humanoid.JumpPower = CONFIG.FRIEND_APPEARANCE.JumpPower
    humanoid.DisplayName = CONFIG.FRIEND_APPEARANCE.DisplayName
    
    -- Position parts
    local spawnPos = HumanoidRootPart.Position + Vector3.new(5, 0, 0)
    torso.Position = spawnPos
    head.Position = spawnPos + Vector3.new(0, 1.5, 0)
    leftArm.Position = spawnPos + Vector3.new(-1.5, 0, 0)
    rightArm.Position = spawnPos + Vector3.new(1.5, 0, 0)
    leftLeg.Position = spawnPos + Vector3.new(-0.5, -2, 0)
    rightLeg.Position = spawnPos + Vector3.new(0.5, -2, 0)
    
    -- Create joints
    local neck = Instance.new("Motor6D")
    neck.Name = "Neck"
    neck.Part0 = torso
    neck.Part1 = head
    neck.C0 = CFrame.new(0, 1, 0)
    neck.C1 = CFrame.new(0, -0.5, 0)
    neck.Parent = torso
    
    local leftShoulder = Instance.new("Motor6D")
    leftShoulder.Name = "Left Shoulder"
    leftShoulder.Part0 = torso
    leftShoulder.Part1 = leftArm
    leftShoulder.C0 = CFrame.new(-1.5, 0.5, 0)
    leftShoulder.C1 = CFrame.new(0, 0.5, 0)
    leftShoulder.Parent = torso
    
    local rightShoulder = Instance.new("Motor6D")
    rightShoulder.Name = "Right Shoulder"
    rightShoulder.Part0 = torso
    rightShoulder.Part1 = rightArm
    rightShoulder.C0 = CFrame.new(1.5, 0.5, 0)
    rightShoulder.C1 = CFrame.new(0, 0.5, 0)
    rightShoulder.Parent = torso
    
    local leftHip = Instance.new("Motor6D")
    leftHip.Name = "Left Hip"
    leftHip.Part0 = torso
    leftHip.Part1 = leftLeg
    leftHip.C0 = CFrame.new(-0.5, -1, 0)
    leftHip.C1 = CFrame.new(0, 1, 0)
    leftHip.Parent = torso
    
    local rightHip = Instance.new("Motor6D")
    rightHip.Name = "Right Hip"
    rightHip.Part0 = torso
    rightHip.Part1 = rightLeg
    rightHip.C0 = CFrame.new(0.5, -1, 0)
    rightHip.C1 = CFrame.new(0, 1, 0)
    rightHip.Parent = torso
    
    -- Set HumanoidRootPart
    torso.Name = "HumanoidRootPart"
    model.PrimaryPart = torso
    
    -- Add to workspace
    model.Parent = workspace
    
    -- Set globals
    AIFriend = model
    AIHumanoid = humanoid
    AIRootPart = torso
    
    DebugLog("AI Friend created successfully!")
    
    -- Welcome message
    wait(1)
    ShowChatBubble(AIFriend, "Hey! I'm " .. CONFIG.PERSONALITY.Name .. "! Ready to explore together? 🚀")
end

-- ═══════════════════════════════════════════════════════════
--                    CHAT DETECTION
-- ═══════════════════════════════════════════════════════════

Player.Chatted:Connect(function(message)
    DebugLog("Player said: " .. message)
    
    -- Get AI response
    spawn(function()
        IsThinking = true
        ShowChatBubble(AIFriend, "*thinking...*")
        
        local context = ScanEnvironment()
        local response = GetAIResponse(message, context)
        
        wait(0.5)
        ShowChatBubble(AIFriend, response)
        IsThinking = false
        LastChatTime = tick()
        
        -- Parse for actions
        if response:lower():find("jump") then
            wait(0.5)
            PerformAction("jump")
        elseif response:lower():find("run") or response:lower():find("race") then
            PerformAction("run")
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════
--                    AUTONOMOUS BEHAVIOR
-- ═══════════════════════════════════════════════════════════

local function AutonomousThinking()
    if IsThinking or tick() - LastChatTime < CONFIG.PERSONALITY.ChatFrequency then
        return
    end
    
    -- Randomly decide to say something
    if math.random(1, 100) > 85 then
        spawn(function()
            IsThinking = true
            
            local context = ScanEnvironment()
            local prompts = {
                "What do you think about what we're seeing?",
                "Notice anything interesting?",
                "What should we do next?",
                "Share an observation about our surroundings"
            }
            
            local prompt = prompts[math.random(1, #prompts)]
            local response = GetAIResponse(prompt, context)
            
            if response and response ~= "*thinking...*" then
                ShowChatBubble(AIFriend, response)
            end
            
            IsThinking = false
            LastChatTime = tick()
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
--                    MAIN LOOP
-- ═══════════════════════════════════════════════════════════

local function MainLoop()
    while wait(0.5) do
        if AIFriend and AIHumanoid and AIRootPart then
            -- Update vision periodically
            if tick() - WorldKnowledge.LastVisionUpdate > CONFIG.VISION_UPDATE_RATE then
                ScanEnvironment()
                WorldKnowledge.LastVisionUpdate = tick()
            end
            
            -- Follow player
            FollowPlayer()
            
            -- Autonomous behavior
            AutonomousThinking()
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--                    INITIALIZATION
-- ═══════════════════════════════════════════════════════════

local function Initialize()
    print("")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║                    AI FRIEND v2.0                         ║")
    print("║          Your Intelligent Roblox Companion                ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print("")
    print("[✓] Initializing AI systems...")
    print("[✓] API Provider: " .. CONFIG.API_PROVIDER:upper())
    print("[✓] Personality: " .. CONFIG.PERSONALITY.Name)
    print("")
    
    -- Enable HTTP requests
    if not HttpService.HttpEnabled then
        warn("[!] HTTP requests are disabled! Enable in game settings.")
        return
    end
    
    -- Create AI Friend
    CreateAIFriend()
    
    -- Start main loop
    spawn(MainLoop)
    
    print("[✓] AI Friend is now active!")
    print("[✓] Chat with them, and they'll respond intelligently!")
    print("")
end

-- Start the magic!
Initialize()
