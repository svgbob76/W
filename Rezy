-- ╔══════════════════════════════════════════════════════════════╗
-- ║        ETA — Emote To Animation System  v2.0               ║
-- ║        StarterPlayerScripts  →  LocalScript                ║
-- ║        Toggle GUI: Right Shift  |  Scan then assign        ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")

local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

-- ────────────────────────────────────────────────────────────
--  CONSTANTS
-- ────────────────────────────────────────────────────────────
local DEFAULT_ANIM_IDS = {
    -- R15 defaults
    ["507766666"] = "idle1",    ["507766951"] = "idle2",
    ["507766388"] = "idle3",    ["507777826"] = "walk",
    ["507767714"] = "run",      ["507784897"] = "swim",
    ["507785072"] = "swimidle", ["507765000"] = "jump",
    ["507767968"] = "fall",     ["507765644"] = "climb",
    ["507768133"] = "sit",      ["507768375"] = "toolnone",
    ["522635514"] = "toolslash",["522638767"] = "toollunge",
    ["507771019"] = "dance",    ["507771955"] = "dance",
    ["507772104"] = "dance",    ["507776043"] = "dance2",
    ["507776720"] = "dance2",   ["507776879"] = "dance2",
    ["507777268"] = "dance3",   ["507777451"] = "dance3",
    ["507777623"] = "dance3",   ["507770239"] = "wave",
    ["507770453"] = "point",    ["507770818"] = "laugh",
    ["507770677"] = "cheer",
    -- R6 defaults
    ["180435571"] = "idle_r6",  ["180435792"] = "walk_r6",
    ["180435719"] = "run_r6",   ["180435855"] = "jump_r6",
    ["180436148"] = "fall_r6",  ["180435867"] = "swim_r6",
    ["180436334"] = "swimidle_r6",["180435780"] = "climb_r6",
}

local SLOTS = {
    { key = "run",      label = "RUN",       icon = "🏃",
      path = function(a) return a:FindFirstChild("run") end,
      animChild = "RunAnim" },
    { key = "walk",     label = "WALK",      icon = "🚶",
      path = function(a) return a:FindFirstChild("walk") end,
      animChild = "WalkAnim" },
    { key = "idle",     label = "IDLE",      icon = "💤",
      path = function(a) return a:FindFirstChild("idle") end,
      animChild = "Animation1" },
    { key = "jump",     label = "JUMP",      icon = "⬆",
      path = function(a) return a:FindFirstChild("jump") end,
      animChild = "JumpAnim" },
    { key = "fall",     label = "FALL",      icon = "⬇",
      path = function(a) return a:FindFirstChild("fall") end,
      animChild = "FallAnim" },
    { key = "swim",     label = "SWIM",      icon = "🏊",
      path = function(a) return a:FindFirstChild("swim") end,
      animChild = "Swim" },
    { key = "swimidle", label = "SWIM IDLE", icon = "🌊",
      path = function(a) return a:FindFirstChild("swimidle") end,
      animChild = "SwimIdle" },
    { key = "climb",    label = "CLIMB",     icon = "🧗",
      path = function(a) return a:FindFirstChild("climb") end,
      animChild = "ClimbAnim" },
    { key = "sit",      label = "SIT",       icon = "🪑",
      path = function(a) return a:FindFirstChild("sit") end,
      animChild = "SitAnim" },
    { key = "toolnone", label = "TOOL HOLD", icon = "🔧",
      path = function(a) return a:FindFirstChild("toolnone") end,
      animChild = "ToolNoneAnim" },
    { key = "toolslash",label = "TOOL SLASH",icon = "🗡",
      path = function(a) return a:FindFirstChild("toolslash") end,
      animChild = "SlashAnim" },
}

-- ────────────────────────────────────────────────────────────
--  STATE
-- ────────────────────────────────────────────────────────────
local assignments    = {}   -- key → animationId string
local scannedAnim    = nil  -- last scanned animation info
local guiVisible     = false
local character      = nil
local humanoid       = nil
local animator       = nil
local animateScript  = nil
local activeOverrideTracks = {}   -- key → AnimationTrack

-- ────────────────────────────────────────────────────────────
--  HELPERS
-- ────────────────────────────────────────────────────────────
local function getAnimId(track)
    if track and track.Animation then
        local id = tostring(track.Animation.AnimationId)
        return id:match("%d+") or ""
    end
    return ""
end

local function isDefaultAnim(id)
    return DEFAULT_ANIM_IDS[tostring(id)] ~= nil
end

local function rbxId(numOrStr)
    local n = tostring(numOrStr):match("%d+") or numOrStr
    return "rbxassetid://" .. n
end

-- ────────────────────────────────────────────────────────────
--  APPLY ASSIGNMENT TO ANIMATE SCRIPT
-- ────────────────────────────────────────────────────────────
local function applySlot(slotDef, animId)
    if not animateScript then return end
    pcall(function()
        local folder = slotDef.path(animateScript)
        if folder then
            local animObj = folder:FindFirstChild(slotDef.animChild)
            if animObj and animObj:IsA("Animation") then
                animObj.AnimationId = rbxId(animId)
            elseif animObj and animObj.ClassName == "StringValue" then
                animObj.Value = rbxId(animId)
            else
                -- Try any Animation child
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("Animation") then
                        child.AnimationId = rbxId(animId)
                        break
                    end
                end
            end
        end
    end)
end

-- Also hook state changes for immediate effect
local stateConnection = nil

local function hookStates()
    if stateConnection then stateConnection:Disconnect() end
    if not humanoid then return end

    local stateMap = {
        [Enum.HumanoidStateType.Running]         = {"run",  "walk"},
        [Enum.HumanoidStateType.Jumping]         = {"jump"},
        [Enum.HumanoidStateType.Freefall]        = {"fall"},
        [Enum.HumanoidStateType.Swimming]        = {"swim", "swimidle"},
        [Enum.HumanoidStateType.Climbing]        = {"climb"},
        [Enum.HumanoidStateType.Seated]          = {"sit"},
        [Enum.HumanoidStateType.StrafingNoPhysics] = {"run","walk"},
    }

    stateConnection = humanoid.StateChanged:Connect(function(_, newState)
        local keys = stateMap[newState]
        if not keys then return end
        task.wait(0.05)
        for _, key in ipairs(keys) do
            local animId = assignments[key]
            if animId and animator then
                -- Stop any existing override for this slot
                if activeOverrideTracks[key] then
                    pcall(function() activeOverrideTracks[key]:Stop(0.15) end)
                end
                pcall(function()
                    local anim = Instance.new("Animation")
                    anim.AnimationId = rbxId(animId)
                    local track = animator:LoadAnimation(anim)
                    track.Priority = Enum.AnimationPriority.Action4
                    track:Play(0.15)
                    activeOverrideTracks[key] = track
                    -- Stop when state changes away
                    track.Stopped:Connect(function()
                        if activeOverrideTracks[key] == track then
                            activeOverrideTracks[key] = nil
                        end
                    end)
                end)
            end
        end
    end)
end

-- Additional: hook walk/idle via speed
local speedConn = nil
local function hookSpeed()
    if speedConn then speedConn:Disconnect() end
    if not humanoid then return end
    local lastKey = nil

    speedConn = RunService.Heartbeat:Connect(function()
        if not humanoid or not animator then return end
        local speed = humanoid.MoveDirection.Magnitude
        local inWater = humanoid:GetState() == Enum.HumanoidStateType.Swimming

        local targetKey = nil
        if inWater then
            targetKey = speed > 0.1 and "swim" or "swimidle"
        elseif humanoid:GetState() == Enum.HumanoidStateType.Running then
            targetKey = speed > 0.1 and "run" or "idle"
        end

        if targetKey and targetKey ~= lastKey and assignments[targetKey] then
            lastKey = targetKey
            if activeOverrideTracks[targetKey] then
                pcall(function() activeOverrideTracks[targetKey]:Stop(0.1) end)
            end
            pcall(function()
                local anim = Instance.new("Animation")
                anim.AnimationId = rbxId(assignments[targetKey])
                local track = animator:LoadAnimation(anim)
                track.Priority = Enum.AnimationPriority.Action4
                track:Play(0.1)
                activeOverrideTracks[targetKey] = track
            end)
        elseif not targetKey then
            lastKey = nil
        end
    end)
end

-- ────────────────────────────────────────────────────────────
--  SCAN EMOTE
-- ────────────────────────────────────────────────────────────
local function scanEmote()
    if not animator then
        return nil, "No character found!"
    end
    local tracks = animator:GetPlayingAnimationTracks()
    local found = nil
    local highestWeight = -1

    for _, track in ipairs(tracks) do
        local rawId = getAnimId(track)
        if rawId ~= "" and not isDefaultAnim(rawId) then
            if track.Weight > highestWeight then
                highestWeight = track.Weight
                found = {
                    id       = rawId,
                    fullId   = rbxId(rawId),
                    name     = track.Name or "Unknown",
                    looped   = track.Looped,
                    speed    = track.Speed,
                    priority = tostring(track.Priority),
                    length   = track.Length,
                    weight   = track.Weight,
                }
            end
        end
    end

    if not found then
        -- Fallback: scan all tracks and pick non-default with highest weight
        for _, track in ipairs(tracks) do
            local rawId = getAnimId(track)
            if rawId ~= "" then
                if track.Weight > highestWeight then
                    highestWeight = track.Weight
                    found = {
                        id     = rawId,
                        fullId = rbxId(rawId),
                        name   = track.Name or "Unknown",
                        looped = track.Looped,
                        speed  = track.Speed,
                        priority = tostring(track.Priority),
                        length = track.Length,
                        weight = track.Weight,
                    }
                end
            end
        end
    end

    return found, found and "Scanned!" or "No emote detected — play an emote first!"
end

-- ────────────────────────────────────────────────────────────
--  RE-APPLY ALL ASSIGNMENTS (after respawn)
-- ────────────────────────────────────────────────────────────
local function reapplyAll()
    for key, animId in pairs(assignments) do
        for _, slot in ipairs(SLOTS) do
            if slot.key == key then
                applySlot(slot, animId)
                break
            end
        end
    end
end

-- ────────────────────────────────────────────────────────────
--  GUI
-- ────────────────────────────────────────────────────────────
local screenGui     = nil
local mainFrame     = nil
local statusLabel   = nil
local scanResultFrame = nil
local scanIdLabel   = nil
local scanInfoLabel = nil
local slotButtons   = {}

local COLORS = {
    bg       = Color3.fromRGB(5,  10, 20),
    card     = Color3.fromRGB(10, 18, 32),
    card2    = Color3.fromRGB(13, 23, 40),
    border   = Color3.fromRGB(0,  200, 210),
    cyan     = Color3.fromRGB(0,  245, 255),
    purple   = Color3.fromRGB(180, 0,  255),
    pink     = Color3.fromRGB(255, 0,  110),
    gold     = Color3.fromRGB(255, 215, 0),
    green    = Color3.fromRGB(40,  200, 80),
    red      = Color3.fromRGB(255, 60,  60),
    text     = Color3.fromRGB(220, 230, 245),
    muted    = Color3.fromRGB(80,  100, 130),
    white    = Color3.fromRGB(255, 255, 255),
}

local function makeUIPadding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.Parent = parent
    return p
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.cyan
    s.Thickness = thickness or 1
    s.Transparency = trans or 0.6
    s.Parent = parent
    return s
end

local function makeLabel(parent, text, size, color, font, props)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or COLORS.text
    l.Font = font or Enum.Font.GothamBold
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1,0,0,size and size+4 or 17)
    if props then for k,v in pairs(props) do l[k] = v end end
    l.Parent = parent
    return l
end

local function makeButton(parent, text, size, props)
    local b = Instance.new("TextButton")
    b.Text = text
    b.TextSize = size or 12
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = COLORS.cyan
    b.BackgroundColor3 = Color3.fromRGB(0, 30, 40)
    b.Size = UDim2.new(1,0,0,32)
    b.AutoButtonColor = false
    if props then for k,v in pairs(props) do b[k] = v end end
    b.Parent = parent
    makeCorner(b, 8)
    makeStroke(b, COLORS.cyan, 1, 0.55)
    return b
end

local function tweenColor(obj, prop, target, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.2), {[prop] = target}):Play()
end

local function setStatus(msg, color)
    if statusLabel then
        statusLabel.Text = msg
        statusLabel.TextColor3 = color or COLORS.muted
    end
end

local function refreshSlotUI()
    for _, entry in ipairs(slotButtons) do
        local assigned = assignments[entry.slot.key]
        local btn = entry.button
        local rstBtn = entry.resetBtn
        local iconLbl = entry.iconLabel
        local nameLbl = entry.nameLabel
        local idLbl   = entry.idLabel

        if assigned then
            btn.BackgroundColor3 = Color3.fromRGB(0, 40, 55)
            nameLbl.TextColor3   = COLORS.cyan
            idLbl.Text = "rbxassetid://" .. assigned
            idLbl.TextColor3 = Color3.fromRGB(120, 200, 120)
            rstBtn.Visible = true
            makeStroke(btn, COLORS.cyan, 1, 0.2)
        else
            btn.BackgroundColor3 = Color3.fromRGB(8, 15, 28)
            nameLbl.TextColor3   = COLORS.text
            idLbl.Text = "— not assigned —"
            idLbl.TextColor3 = COLORS.muted
            rstBtn.Visible = false
            makeStroke(btn, COLORS.cyan, 1, 0.75)
        end
    end
end

local function buildGui()
    -- Destroy old
    if screenGui then screenGui:Destroy() end
    activeOverrideTracks = {}
    slotButtons = {}

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ETA_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = LocalPlayer.PlayerGui

    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 420, 0, 640)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -320)
    mainFrame.BackgroundColor3 = COLORS.bg
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    makeCorner(mainFrame, 14)
    makeStroke(mainFrame, COLORS.cyan, 1, 0.5)

    -- Background gradient
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5,10,20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8,16,32)),
    })
    grad.Rotation = 135
    grad.Parent = mainFrame

    -- ── TITLE BAR ──
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,46)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 20, 32)
    titleBar.Parent = mainFrame
    makeCorner(titleBar, 14)

    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1,0,0.5,0)
    tbFix.Position = UDim2.new(0,0,0.5,0)
    tbFix.BackgroundColor3 = Color3.fromRGB(0,20,32)
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar

    local tbGrad = Instance.new("UIGradient")
    tbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 245, 255)):__mul and
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0,30,45)) or
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0,30,45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,0,40)),
    })
    tbGrad.Rotation = 90
    tbGrad.Parent = titleBar

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,9,0,9)
    dot.Position = UDim2.new(0,14,0.5,-4)
    dot.BackgroundColor3 = COLORS.cyan
    dot.Parent = titleBar
    makeCorner(dot, 9)

    local titleLbl = makeLabel(titleBar, " ETA  ·  Emote To Animation", 13, COLORS.cyan, Enum.Font.GothamBold, {
        Position = UDim2.new(0,28,0,0),
        Size = UDim2.new(1,-100,1,0),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    titleLbl.RichText = true
    titleLbl.Text = '<font color="#00f5ff"> ⚡ ETA</font><font color="#546e7a">  ·  Emote To Animation  v2.0</font>'

    local closeBtn = makeButton(titleBar, "✕", 13, {
        Size = UDim2.new(0,36,0,28),
        Position = UDim2.new(1,-44,0.5,-14),
        TextColor3 = COLORS.muted,
        BackgroundColor3 = Color3.fromRGB(255,40,40),
        BackgroundTransparency = 0.85,
    })
    makeStroke(closeBtn, COLORS.red, 1, 0.7)
    closeBtn.MouseButton1Click:Connect(function()
        guiVisible = false
        mainFrame.Visible = false
    end)
    closeBtn.MouseEnter:Connect(function()
        tweenColor(closeBtn, "BackgroundTransparency", 0.5)
        closeBtn.TextColor3 = COLORS.white
    end)
    closeBtn.MouseLeave:Connect(function()
        tweenColor(closeBtn, "BackgroundTransparency", 0.85)
        closeBtn.TextColor3 = COLORS.muted
    end)

    -- Draggable
    do
        local dragging, dragStart, startPos
        titleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = inp.Position
                startPos = mainFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = inp.Position - dragStart
                mainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- ── CONTENT SCROLL ──
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,-46)
    scroll.Position = UDim2.new(0,0,0,46)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = COLORS.cyan
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll
    makeUIPadding(scroll, 10, 10, 10, 10)

    -- ── STATUS BAR ──
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1,0,0,32)
    statusFrame.BackgroundColor3 = Color3.fromRGB(8,14,26)
    statusFrame.LayoutOrder = 1
    statusFrame.Parent = scroll
    makeCorner(statusFrame, 8)

    statusLabel = makeLabel(statusFrame,
        "Play any /e emote, then hit SCAN", 11, COLORS.muted,
        Enum.Font.Gotham, {
            Size = UDim2.new(1,0,1,0),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
        })

    -- ── SCAN SECTION ──
    local scanCard = Instance.new("Frame")
    scanCard.Size = UDim2.new(1,0,0,120)
    scanCard.BackgroundColor3 = Color3.fromRGB(8,16,30)
    scanCard.LayoutOrder = 2
    scanCard.Parent = scroll
    makeCorner(scanCard, 10)
    makeStroke(scanCard, COLORS.purple, 1, 0.6)
    makeUIPadding(scanCard, 10, 10, 10, 10)

    local scanTitle = makeLabel(scanCard, "SCAN EMOTE", 10, COLORS.purple,
        Enum.Font.GothamBold, {
            Size = UDim2.new(1,0,0,14),
            LetterSpacing = 3,
        })

    local scanBtn = makeButton(scanCard, "⬤  SCAN CURRENTLY PLAYING EMOTE", 13, {
        Size = UDim2.new(1,0,0,36),
        Position = UDim2.new(0,0,0,18),
        TextColor3 = COLORS.cyan,
        BackgroundColor3 = Color3.fromRGB(0, 35, 50),
    })
    makeStroke(scanBtn, COLORS.cyan, 1, 0.4)

    -- Scan result panel
    scanResultFrame = Instance.new("Frame")
    scanResultFrame.Size = UDim2.new(1,0,0,50)
    scanResultFrame.Position = UDim2.new(0,0,0,60)
    scanResultFrame.BackgroundColor3 = Color3.fromRGB(0, 22, 18)
    scanResultFrame.Visible = false
    scanResultFrame.Parent = scanCard
    makeCorner(scanResultFrame, 8)
    makeStroke(scanResultFrame, COLORS.green, 1, 0.5)
    makeUIPadding(scanResultFrame, 6, 8, 6, 8)

    scanIdLabel = makeLabel(scanResultFrame, "", 11, Color3.fromRGB(120,220,120),
        Enum.Font.GothamBold, {
            Size = UDim2.new(1,0,0,16),
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    scanInfoLabel = makeLabel(scanResultFrame, "", 10, COLORS.muted,
        Enum.Font.Gotham, {
            Size = UDim2.new(1,0,0,14),
            Position = UDim2.new(0,0,0,18),
        })

    scanBtn.MouseButton1Click:Connect(function()
        setStatus("Scanning...", COLORS.gold)
        task.wait(0.05)
        local result, msg = scanEmote()
        if result then
            scannedAnim = result
            scanResultFrame.Visible = true
            scanResultFrame.Size = UDim2.new(1,0,0,50)
            scanCard.Size = UDim2.new(1,0,0,120)
            scanIdLabel.Text = "✓  " .. result.fullId
            local info = string.format(
                "Loop: %s  ·  Speed: %.2f  ·  Len: %.1fs  ·  Priority: %s",
                tostring(result.looped), result.speed,
                result.length or 0, result.priority
            )
            scanInfoLabel.Text = info
            setStatus("Emote scanned! Click a slot to assign ↓", COLORS.cyan)
        else
            scannedAnim = nil
            scanResultFrame.Visible = false
            setStatus("✗ " .. msg, COLORS.red)
        end
    end)

    scanBtn.MouseEnter:Connect(function()
        TweenService:Create(scanBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(0, 50, 65)
        }):Play()
    end)
    scanBtn.MouseLeave:Connect(function()
        TweenService:Create(scanBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(0, 35, 50)
        }):Play()
    end)

    -- ── DIVIDER ──
    local divLbl = makeLabel(scroll, "ASSIGN TO SLOT", 10, COLORS.muted,
        Enum.Font.GothamBold, {
            LayoutOrder = 3,
            Size = UDim2.new(1,0,0,20),
            TextXAlignment = Enum.TextXAlignment.Center,
            LetterSpacing = 3,
        })

    -- ── SLOT BUTTONS ──
    for i, slot in ipairs(SLOTS) do
        local slotFrame = Instance.new("Frame")
        slotFrame.Size = UDim2.new(1,0,0,54)
        slotFrame.BackgroundColor3 = Color3.fromRGB(8,15,28)
        slotFrame.LayoutOrder = 3 + i
        slotFrame.Parent = scroll
        makeCorner(slotFrame, 10)
        makeStroke(slotFrame, COLORS.cyan, 1, 0.75)

        -- Clickable main area
        local slotBtn = Instance.new("TextButton")
        slotBtn.Size = UDim2.new(1,-46,1,0)
        slotBtn.BackgroundTransparency = 1
        slotBtn.Text = ""
        slotBtn.Parent = slotFrame

        -- Icon
        local iconLbl = makeLabel(slotFrame, slot.icon, 20, COLORS.white,
            Enum.Font.GothamBold, {
                Size = UDim2.new(0,36,0,36),
                Position = UDim2.new(0,10,0.5,-18),
                TextXAlignment = Enum.TextXAlignment.Center,
            })

        -- Name label
        local nameLbl = makeLabel(slotFrame, slot.label, 12, COLORS.text,
            Enum.Font.GothamBold, {
                Size = UDim2.new(1,-100,0,18),
                Position = UDim2.new(0,50,0,8),
            })

        -- ID label
        local idLbl = makeLabel(slotFrame, "— not assigned —", 10, COLORS.muted,
            Enum.Font.Gotham, {
                Size = UDim2.new(1,-100,0,14),
                Position = UDim2.new(0,50,0,28),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })

        -- Reset button
        local rstBtn = makeButton(slotFrame, "✕", 11, {
            Size = UDim2.new(0,34,0,34),
            Position = UDim2.new(1,-42,0.5,-17),
            TextColor3 = COLORS.red,
            BackgroundColor3 = Color3.fromRGB(60,0,0),
            BackgroundTransparency = 0.7,
            Visible = false,
        })
        makeStroke(rstBtn, COLORS.red, 1, 0.6)

        -- Hover effects
        slotBtn.MouseEnter:Connect(function()
            TweenService:Create(slotFrame, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(0, 30, 50)
            }):Play()
        end)
        slotBtn.MouseLeave:Connect(function()
            TweenService:Create(slotFrame, TweenInfo.new(0.15), {
                BackgroundColor3 = assignments[slot.key]
                    and Color3.fromRGB(0, 40, 55)
                    or  Color3.fromRGB(8, 15, 28)
            }):Play()
        end)

        -- Click: assign
        slotBtn.MouseButton1Click:Connect(function()
            if not scannedAnim then
                setStatus("No emote scanned yet! Play emote → SCAN first.", COLORS.red)
                return
            end
            assignments[slot.key] = scannedAnim.id
            applySlot(slot, scannedAnim.id)
            setStatus("✓ Assigned to " .. slot.label .. "!", COLORS.green)
            refreshSlotUI()
            -- Visual feedback
            TweenService:Create(slotFrame, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(0, 70, 30)
            }):Play()
            task.wait(0.25)
            TweenService:Create(slotFrame, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(0, 40, 55)
            }):Play()
        end)

        -- Reset click
        rstBtn.MouseButton1Click:Connect(function()
            assignments[slot.key] = nil
            if activeOverrideTracks[slot.key] then
                pcall(function() activeOverrideTracks[slot.key]:Stop(0.2) end)
                activeOverrideTracks[slot.key] = nil
            end
            -- Re-apply default by setting back the default ID
            local defaults = {
                run="507767714", walk="507777826", idle="507766388",
                jump="507765000", fall="507767968", swim="507784897",
                swimidle="507785072", climb="507765644", sit="507768133",
                toolnone="507768375", toolslash="522635514"
            }
            if defaults[slot.key] then
                applySlot(slot, defaults[slot.key])
            end
            setStatus("Reset " .. slot.label .. " to default.", COLORS.muted)
            refreshSlotUI()
        end)

        table.insert(slotButtons, {
            slot = slot,
            button = slotFrame,
            iconLabel = iconLbl,
            nameLabel = nameLbl,
            idLabel = idLbl,
            resetBtn = rstBtn,
        })
    end

    -- ── RESET ALL ──
    local resetAllBtn = makeButton(scroll, "✕  RESET ALL SLOTS TO DEFAULT", 12, {
        LayoutOrder = 100,
        Size = UDim2.new(1,0,0,36),
        TextColor3 = COLORS.red,
        BackgroundColor3 = Color3.fromRGB(40,0,0),
        BackgroundTransparency = 0.7,
    })
    makeStroke(resetAllBtn, COLORS.red, 1, 0.55)

    resetAllBtn.MouseButton1Click:Connect(function()
        local defaults = {
            run="507767714", walk="507777826", idle="507766388",
            jump="507765000", fall="507767968", swim="507784897",
            swimidle="507785072", climb="507765644", sit="507768133",
            toolnone="507768375", toolslash="522635514"
        }
        for _, slot in ipairs(SLOTS) do
            assignments[slot.key] = nil
            if activeOverrideTracks[slot.key] then
                pcall(function() activeOverrideTracks[slot.key]:Stop(0.2) end)
                activeOverrideTracks[slot.key] = nil
            end
            if defaults[slot.key] then
                applySlot(slot, defaults[slot.key])
            end
        end
        scannedAnim = nil
        scanResultFrame.Visible = false
        setStatus("All slots reset to Roblox defaults.", COLORS.muted)
        refreshSlotUI()
    end)

    -- Credit
    local creditLbl = makeLabel(scroll, "ETA v2.0  ·  Toggle: RightShift", 9,
        Color3.fromRGB(40,55,75), Enum.Font.Gotham, {
            LayoutOrder = 101,
            Size = UDim2.new(1,0,0,20),
            TextXAlignment = Enum.TextXAlignment.Center,
        })

    refreshSlotUI()
end

-- ────────────────────────────────────────────────────────────
--  CHARACTER SETUP
-- ────────────────────────────────────────────────────────────
local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid", 15)
    if not humanoid then return end

    animator = humanoid:WaitForChild("Animator", 15)
    animateScript = char:WaitForChild("Animate", 15)

    -- Clear old override tracks
    activeOverrideTracks = {}

    task.wait(0.5)  -- Let Animate script initialize
    reapplyAll()
    hookStates()
    hookSpeed()

    setStatus("Character ready! Play emote → SCAN → assign.", COLORS.muted)
end

-- ────────────────────────────────────────────────────────────
--  INPUT
-- ────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        if mainFrame then
            mainFrame.Visible = guiVisible
            if guiVisible then
                local tw = TweenService:Create(mainFrame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Position = UDim2.new(0.5,-210,0.5,-320) }
                )
                tw:Play()
            end
        end
    end
end)

-- ────────────────────────────────────────────────────────────
--  INIT
-- ────────────────────────────────────────────────────────────
buildGui()

-- Connect character
if LocalPlayer.Character then
    task.spawn(setupCharacter, LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    task.spawn(setupCharacter, char)
end)

print("[ETA] Emote To Animation system loaded. Press RightShift to open the GUI.")
