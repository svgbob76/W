-- ╔══════════════════════════════════════════════════════════════╗
-- ║          ETA  —  Emote To Animation  v2.0                    ║
-- ║          LocalScript → StarterCharacterScripts               ║
-- ║                                                              ║
-- ║  USAGE:                                                      ║
-- ║   1. Play any emote  (/e dance, catalog emotes, etc.)        ║
-- ║   2. Press RightShift to open the GUI                        ║
-- ║   3. Click SCAN EMOTE                                        ║
-- ║   4. Click any slot to assign the emote animation to it      ║
-- ║   5. Done — that animation permanently replaces the default  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Services ──────────────────────────────────────────────────
local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")

-- ── Local references (re-grabbed on every respawn) ───────────
local Player    = Players.LocalPlayer
local Character = script.Parent           -- StarterCharacterScripts = character child
local Humanoid  = Character:WaitForChild("Humanoid")
local Animator  = Humanoid:WaitForChild("Animator")
local Root      = Character:WaitForChild("HumanoidRootPart")

-- ── Animate script ────────────────────────────────────────────
local AnimScript = Character:WaitForChild("Animate")

-- ── All known default Roblox animation IDs (R15 + R6) ────────
-- We filter these out when scanning so only your emote shows up
local DEFAULT_IDS = {
    -- R15 defaults
    ["507766666"] = true, ["507766951"] = true, ["507766388"] = true,
    ["507777826"] = true, ["507767714"] = true, ["507784897"] = true,
    ["507785072"] = true, ["507765000"] = true, ["507767968"] = true,
    ["507765644"] = true, ["507768133"] = true, ["507768375"] = true,
    ["522635514"] = true, ["522638767"] = true,
    ["507770239"] = true, ["507770453"] = true,
    ["507771019"] = true, ["507771955"] = true, ["507772104"] = true,
    ["507776043"] = true, ["507776720"] = true, ["507776879"] = true,
    ["507777268"] = true, ["507777451"] = true, ["507777623"] = true,
    ["507770818"] = true, ["507770677"] = true,
    -- R6 defaults
    ["180435571"] = true, ["180435792"] = true,
    ["180426354"] = true, ["182393013"] = true,
    ["182393417"] = true, ["182393274"] = true,
    ["182393578"] = true, ["182393818"] = true,
    -- Extra system anims
    ["616163682"] = true, ["616168032"] = true,
    ["616161997"] = true, ["616158929"] = true,
    ["616160636"] = true, ["616157476"] = true,
    ["616165109"] = true, ["616166655"] = true,
    ["616156119"] = true,
}

-- ── Persistent assignment table (survives GUI close, NOT respawn)
-- Respawn persistence is handled by StarterCharacterScripts re-running
local Assignments = {
    run       = nil,
    walk      = nil,
    idle1     = nil,
    idle2     = nil,
    jump      = nil,
    fall      = nil,
    swim      = nil,
    swimidle  = nil,
    climb     = nil,
    toolhold  = nil,
    toolslash = nil,
}

-- ── Slot definitions (maps key → Animate script path pieces) ──
local SLOTS = {
    { key = "run",       label = "RUN",        path = {"run",      "RunAnim"}  },
    { key = "walk",      label = "WALK",       path = {"walk",     "WalkAnim"} },
    { key = "idle1",     label = "IDLE 1",     path = {"idle",     "Animation1"} },
    { key = "idle2",     label = "IDLE 2",     path = {"idle",     "Animation2"} },
    { key = "jump",      label = "JUMP",       path = {"jump",     "JumpAnim"} },
    { key = "fall",      label = "FALL",       path = {"fall",     "FallAnim"} },
    { key = "swim",      label = "SWIM",       path = {"swim",     "Swim"}     },
    { key = "swimidle",  label = "SWIM IDLE",  path = {"swimidle", "SwimIdle"} },
    { key = "climb",     label = "CLIMB",      path = {"climb",    "ClimbAnim"} },
    { key = "toolhold",  label = "TOOL HOLD",  path = {"toolnone", "ToolNoneAnim"} },
    { key = "toolslash", label = "TOOL SLASH", path = {"toolslash","SlashAnim"} },
}

-- ════════════════════════════════════════════════════════════════
-- PATCH FUNCTION
-- Writes new AnimationId into the Animate script's sub-instances.
-- The Animate script re-reads these on every state transition,
-- so the new anim fires the next time that movement triggers.
-- ════════════════════════════════════════════════════════════════
local function applyPatch(slotKey, animId)
    local slotDef = nil
    for _, s in ipairs(SLOTS) do
        if s.key == slotKey then slotDef = s break end
    end
    if not slotDef then return false end

    local ok, err = pcall(function()
        local parent = AnimScript:FindFirstChild(slotDef.path[1])
        if not parent then error("Animate child '"..slotDef.path[1].."' not found") end
        local animNode = parent:FindFirstChild(slotDef.path[2])
        if not animNode then error("Animate grandchild '"..slotDef.path[2].."' not found") end
        animNode.AnimationId = "rbxassetid://" .. tostring(animId)
    end)

    if not ok then
        warn("[ETA] Patch failed for slot '"..slotKey.."': "..tostring(err))
        return false
    end
    return true
end

-- Apply all currently stored assignments (called on init)
local function applyAllPatches()
    for slotKey, animId in pairs(Assignments) do
        if animId then
            applyPatch(slotKey, animId)
        end
    end
end

-- Reset a slot back to its default ID
-- R15 defaults hardcoded — same IDs the Roblox Animate script uses
local DEFAULT_ANIM_IDS = {
    run       = "507767714",
    walk      = "507777826",
    idle1     = "507766388",
    idle2     = "507766666",
    jump      = "507765000",
    fall      = "507767968",
    swim      = "507784897",
    swimidle  = "507785072",
    climb     = "507765644",
    toolhold  = "507768375",
    toolslash = "522635514",
}

local function resetSlot(slotKey)
    Assignments[slotKey] = nil
    local defaultId = DEFAULT_ANIM_IDS[slotKey]
    if defaultId then
        applyPatch(slotKey, defaultId)
    end
end

local function resetAllSlots()
    for key, _ in pairs(Assignments) do
        resetSlot(key)
    end
end

-- ════════════════════════════════════════════════════════════════
-- EMOTE SCANNER
-- Loops all playing tracks, strips default IDs, returns the emote
-- ════════════════════════════════════════════════════════════════
local function scanEmote()
    local tracks = Animator:GetPlayingAnimationTracks()
    local best   = nil
    local bestWeight = -1

    for _, track in ipairs(tracks) do
        local rawId = track.Animation.AnimationId
        -- Extract numeric ID from "rbxassetid://XXXXX" or "http://...id=XXXXX"
        local numId = rawId:match("(%d+)$") or rawId:match("id=(%d+)")
        if numId and not DEFAULT_IDS[numId] then
            -- Prefer higher-weight (Action priority) tracks
            local w = track.WeightCurrent or 0
            if w > bestWeight then
                bestWeight = w
                best = {
                    id       = numId,
                    rawId    = rawId,
                    looped   = track.Looped,
                    speed    = math.floor(track.Speed * 100 + 0.5) / 100,
                    length   = math.floor((track.Length or 0) * 100 + 0.5) / 100,
                    priority = tostring(track.Priority),
                    weight   = w,
                }
            end
        end
    end
    return best
end

-- ════════════════════════════════════════════════════════════════
-- GUI CONSTRUCTION
-- Fully code-built, no external assets, draggable
-- ════════════════════════════════════════════════════════════════
local GUI_OPEN = false
local scannedAnim = nil   -- last scan result
local slotButtons = {}    -- key → TextButton reference

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "ETA_GUI"
ScreenGui.ResetOnSpawn    = false
ScreenGui.DisplayOrder    = 99
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Parent          = Player.PlayerGui

-- ── Main Window ───────────────────────────────────────────────
local Window = Instance.new("Frame")
Window.Name             = "Window"
Window.Size             = UDim2.new(0, 320, 0, 520)
Window.Position         = UDim2.new(0.5, -160, 0.5, -260)
Window.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
Window.BorderSizePixel  = 0
Window.ClipsDescendants = true
Window.Visible          = false
Window.Parent           = ScreenGui

local WinCorner = Instance.new("UICorner")
WinCorner.CornerRadius = UDim.new(0, 14)
WinCorner.Parent = Window

local WinStroke = Instance.new("UIStroke")
WinStroke.Color     = Color3.fromRGB(80, 70, 180)
WinStroke.Thickness = 1.5
WinStroke.Parent    = Window

-- Gradient border shimmer
local WinGrad = Instance.new("UIGradient")
WinGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(99, 102, 241)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(6, 182, 212)),
})
WinGrad.Rotation = 45
WinGrad.Parent   = WinStroke

-- ── Title Bar ─────────────────────────────────────────────────
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.Position         = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 14, 40)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Window

local TBCorner = Instance.new("UICorner")
TBCorner.CornerRadius = UDim.new(0, 14)
TBCorner.Parent = TitleBar

-- Fix bottom corners of titlebar
local TBPatch = Instance.new("Frame")
TBPatch.Size             = UDim2.new(1, 0, 0, 14)
TBPatch.Position         = UDim2.new(0, 0, 1, -14)
TBPatch.BackgroundColor3 = Color3.fromRGB(18, 14, 40)
TBPatch.BorderSizePixel  = 0
TBPatch.Parent           = TitleBar

local TBGrad = Instance.new("UIGradient")
TBGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(30, 20, 70)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(15, 10, 35)),
})
TBGrad.Rotation = 90
TBGrad.Parent   = TitleBar

-- Title dot
local TDot = Instance.new("Frame")
TDot.Size             = UDim2.new(0, 8, 0, 8)
TDot.Position         = UDim2.new(0, 14, 0.5, -4)
TDot.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
TDot.BorderSizePixel  = 0
TDot.Parent           = TitleBar
local TDotC = Instance.new("UICorner")
TDotC.CornerRadius = UDim.new(1, 0)
TDotC.Parent = TDot

-- Pulsing dot effect
RunService.Heartbeat:Connect(function(dt)
    local t = tick()
    local s = 0.5 + 0.5 * math.sin(t * 3)
    TDot.BackgroundColor3 = Color3.fromRGB(
        math.floor(60 + 120*s),
        math.floor(50 + 50*s),
        255
    )
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size              = UDim2.new(1, -100, 1, 0)
TitleLabel.Position          = UDim2.new(0, 28, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text              = "ETA  ·  Emote To Animation"
TitleLabel.TextColor3        = Color3.fromRGB(165, 180, 252)
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextSize          = 13
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.Parent            = TitleBar

local VerLabel = Instance.new("TextLabel")
VerLabel.Size              = UDim2.new(0, 40, 1, 0)
VerLabel.Position          = UDim2.new(1, -50, 0, 0)
VerLabel.BackgroundTransparency = 1
VerLabel.Text              = "v2.0"
VerLabel.TextColor3        = Color3.fromRGB(60, 60, 100)
VerLabel.Font              = Enum.Font.GothamBold
VerLabel.TextSize          = 11
VerLabel.TextXAlignment    = Enum.TextXAlignment.Right
VerLabel.Parent            = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.new(1,1,1)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 12
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = TitleBar
local CBCorner = Instance.new("UICorner")
CBCorner.CornerRadius = UDim.new(1,0)
CBCorner.Parent = CloseBtn

-- ── Scroll frame for all content ──────────────────────────────
local Scroll = Instance.new("ScrollingFrame")
Scroll.Name                      = "Scroll"
Scroll.Size                      = UDim2.new(1, 0, 1, -40)
Scroll.Position                  = UDim2.new(0, 0, 0, 40)
Scroll.BackgroundTransparency    = 1
Scroll.BorderSizePixel           = 0
Scroll.ScrollBarThickness        = 3
Scroll.ScrollBarImageColor3      = Color3.fromRGB(99, 102, 241)
Scroll.CanvasSize                = UDim2.new(0, 0, 0, 900)
Scroll.Parent                    = Window

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.SortOrder       = Enum.SortOrder.LayoutOrder
ScrollLayout.Padding         = UDim.new(0, 0)
ScrollLayout.Parent          = Scroll

local ScrollPadding = Instance.new("UIPadding")
ScrollPadding.PaddingLeft   = UDim.new(0, 12)
ScrollPadding.PaddingRight  = UDim.new(0, 12)
ScrollPadding.PaddingTop    = UDim.new(0, 10)
ScrollPadding.PaddingBottom = UDim.new(0, 10)
ScrollPadding.Parent        = Scroll

-- ── Helper: create section header ─────────────────────────────
local function makeHeader(text, color)
    local h = Instance.new("TextLabel")
    h.Size              = UDim2.new(1, 0, 0, 22)
    h.BackgroundTransparency = 1
    h.Text              = text
    h.TextColor3        = color or Color3.fromRGB(100, 100, 160)
    h.Font              = Enum.Font.GothamBold
    h.TextSize          = 10
    h.TextXAlignment    = Enum.TextXAlignment.Left
    h.LayoutOrder       = 0
    return h
end

-- ── SCAN PANEL ────────────────────────────────────────────────
local ScanPanel = Instance.new("Frame")
ScanPanel.Name             = "ScanPanel"
ScanPanel.Size             = UDim2.new(1, 0, 0, 175)
ScanPanel.BackgroundColor3 = Color3.fromRGB(12, 10, 28)
ScanPanel.BorderSizePixel  = 0
ScanPanel.LayoutOrder      = 1
ScanPanel.Parent           = Scroll

local SPCorner = Instance.new("UICorner")
SPCorner.CornerRadius = UDim.new(0, 10)
SPCorner.Parent = ScanPanel

local SPStroke = Instance.new("UIStroke")
SPStroke.Color     = Color3.fromRGB(50, 45, 100)
SPStroke.Thickness = 1
SPStroke.Parent    = ScanPanel

local SPPad = Instance.new("UIPadding")
SPPad.PaddingLeft   = UDim.new(0, 10)
SPPad.PaddingRight  = UDim.new(0, 10)
SPPad.PaddingTop    = UDim.new(0, 8)
SPPad.PaddingBottom = UDim.new(0, 8)
SPPad.Parent        = ScanPanel

-- Scan panel header
local SPHdr = makeHeader("⬡  EMOTE SCANNER", Color3.fromRGB(99, 102, 241))
SPHdr.Size = UDim2.new(1, 0, 0, 18)
SPHdr.Parent = ScanPanel

-- ID display row
local IDRow = Instance.new("Frame")
IDRow.Size             = UDim2.new(1, 0, 0, 30)
IDRow.Position         = UDim2.new(0, 0, 0, 22)
IDRow.BackgroundColor3 = Color3.fromRGB(6, 5, 16)
IDRow.BorderSizePixel  = 0
IDRow.Parent           = ScanPanel
local IDRowC = Instance.new("UICorner")
IDRowC.CornerRadius = UDim.new(0, 6)
IDRowC.Parent = IDRow
local IDRowS = Instance.new("UIStroke")
IDRowS.Color     = Color3.fromRGB(40, 35, 80)
IDRowS.Thickness = 1
IDRowS.Parent    = IDRow

local IDLabel = Instance.new("TextLabel")
IDLabel.Name              = "IDLabel"
IDLabel.Size              = UDim2.new(1, -8, 1, 0)
IDLabel.Position          = UDim2.new(0, 8, 0, 0)
IDLabel.BackgroundTransparency = 1
IDLabel.Text              = "— no emote scanned —"
IDLabel.TextColor3        = Color3.fromRGB(80, 80, 120)
IDLabel.Font              = Enum.Font.Code
IDLabel.TextSize          = 12
IDLabel.TextXAlignment    = Enum.TextXAlignment.Left
IDLabel.TextTruncate      = Enum.TextTruncate.AtEnd
IDLabel.Parent            = IDRow

-- Metadata row
local MetaLabel = Instance.new("TextLabel")
MetaLabel.Name              = "MetaLabel"
MetaLabel.Size              = UDim2.new(1, 0, 0, 18)
MetaLabel.Position          = UDim2.new(0, 0, 0, 56)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text              = "LOOP: —   SPEED: —   LEN: —   PRI: —"
MetaLabel.TextColor3        = Color3.fromRGB(60, 60, 100)
MetaLabel.Font              = Enum.Font.Code
MetaLabel.TextSize          = 10
MetaLabel.TextXAlignment    = Enum.TextXAlignment.Left
MetaLabel.Parent            = ScanPanel

-- Manual ID input
local ManualRow = Instance.new("Frame")
ManualRow.Size             = UDim2.new(1, 0, 0, 28)
ManualRow.Position         = UDim2.new(0, 0, 0, 78)
ManualRow.BackgroundTransparency = 1
ManualRow.Parent           = ScanPanel

local ManualBox = Instance.new("TextBox")
ManualBox.Name             = "ManualBox"
ManualBox.Size             = UDim2.new(1, -78, 1, 0)
ManualBox.Position         = UDim2.new(0, 0, 0, 0)
ManualBox.BackgroundColor3 = Color3.fromRGB(6, 5, 16)
ManualBox.BorderSizePixel  = 0
ManualBox.Text             = ""
ManualBox.PlaceholderText  = "or type animation ID..."
ManualBox.TextColor3       = Color3.fromRGB(200, 200, 255)
ManualBox.PlaceholderColor3 = Color3.fromRGB(50, 50, 80)
ManualBox.Font             = Enum.Font.Code
ManualBox.TextSize         = 12
ManualBox.ClearTextOnFocus = false
ManualBox.Parent           = ManualRow
local MBC = Instance.new("UICorner")
MBC.CornerRadius = UDim.new(0,6)
MBC.Parent = ManualBox
local MBS = Instance.new("UIStroke")
MBS.Color     = Color3.fromRGB(60, 55, 120)
MBS.Thickness = 1
MBS.Parent    = ManualBox

local UseIDBtn = Instance.new("TextButton")
UseIDBtn.Name             = "UseIDBtn"
UseIDBtn.Size             = UDim2.new(0, 70, 1, 0)
UseIDBtn.Position         = UDim2.new(1, -70, 0, 0)
UseIDBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 90)
UseIDBtn.BorderSizePixel  = 0
UseIDBtn.Text             = "USE ID"
UseIDBtn.TextColor3       = Color3.fromRGB(165, 150, 255)
UseIDBtn.Font             = Enum.Font.GothamBold
UseIDBtn.TextSize         = 11
UseIDBtn.Parent           = ManualRow
local UIDC = Instance.new("UICorner")
UIDC.CornerRadius = UDim.new(0,6)
UIDC.Parent = UseIDBtn

-- SCAN button
local ScanBtn = Instance.new("TextButton")
ScanBtn.Name             = "ScanBtn"
ScanBtn.Size             = UDim2.new(1, 0, 0, 34)
ScanBtn.Position         = UDim2.new(0, 0, 0, 112)
ScanBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
ScanBtn.BorderSizePixel  = 0
ScanBtn.Text             = "⬡  SCAN EMOTE"
ScanBtn.TextColor3       = Color3.new(1,1,1)
ScanBtn.Font             = Enum.Font.GothamBold
ScanBtn.TextSize         = 13
ScanBtn.Parent           = ScanPanel
local SBCorner = Instance.new("UICorner")
SBCorner.CornerRadius = UDim.new(0, 8)
SBCorner.Parent = ScanBtn

local SBGrad = Instance.new("UIGradient")
SBGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(99, 102, 241)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(139, 92, 246)),
})
SBGrad.Rotation = 45
SBGrad.Parent   = ScanBtn

-- Scan status
local ScanStatus = Instance.new("TextLabel")
ScanStatus.Name              = "ScanStatus"
ScanStatus.Size              = UDim2.new(1, 0, 0, 16)
ScanStatus.Position          = UDim2.new(0, 0, 0, 150)
ScanStatus.BackgroundTransparency = 1
ScanStatus.Text              = "Play an emote then press SCAN EMOTE"
ScanStatus.TextColor3        = Color3.fromRGB(80, 80, 130)
ScanStatus.Font              = Enum.Font.Code
ScanStatus.TextSize          = 10
ScanStatus.TextXAlignment    = Enum.TextXAlignment.Center
ScanStatus.Parent            = ScanPanel

-- Spacer
local Spacer1 = Instance.new("Frame")
Spacer1.Size             = UDim2.new(1,0,0,8)
Spacer1.BackgroundTransparency = 1
Spacer1.LayoutOrder      = 2
Spacer1.Parent           = Scroll

-- ── Divider ───────────────────────────────────────────────────
local Divider = Instance.new("Frame")
Divider.Size             = UDim2.new(1,0,0,1)
Divider.BackgroundColor3 = Color3.fromRGB(30,25,60)
Divider.BorderSizePixel  = 0
Divider.LayoutOrder      = 3
Divider.Parent           = Scroll

-- Spacer
local Spacer2 = Instance.new("Frame")
Spacer2.Size             = UDim2.new(1,0,0,8)
Spacer2.BackgroundTransparency = 1
Spacer2.LayoutOrder      = 4
Spacer2.Parent           = Scroll

-- ── SLOTS SECTION ─────────────────────────────────────────────
local SlotsHdr = makeHeader("⬡  ASSIGN TO MOVEMENT SLOT", Color3.fromRGB(168, 85, 247))
SlotsHdr.Size        = UDim2.new(1,0,0,20)
SlotsHdr.LayoutOrder = 5
SlotsHdr.Parent      = Scroll

local Spacer3 = Instance.new("Frame")
Spacer3.Size             = UDim2.new(1,0,0,6)
Spacer3.BackgroundTransparency = 1
Spacer3.LayoutOrder      = 6
Spacer3.Parent           = Scroll

-- Grid container for slots
local SlotsGrid = Instance.new("Frame")
SlotsGrid.Name        = "SlotsGrid"
SlotsGrid.Size        = UDim2.new(1, 0, 0, 430)
SlotsGrid.BackgroundTransparency = 1
SlotsGrid.LayoutOrder = 7
SlotsGrid.Parent      = Scroll

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize    = UDim2.new(0.5, -5, 0, 72)
GridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
GridLayout.SortOrder   = Enum.SortOrder.LayoutOrder
GridLayout.Parent      = SlotsGrid

-- Build each slot button
for i, slotDef in ipairs(SLOTS) do
    local SlotFrame = Instance.new("Frame")
    SlotFrame.Name             = "Slot_"..slotDef.key
    SlotFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 26)
    SlotFrame.BorderSizePixel  = 0
    SlotFrame.LayoutOrder      = i
    SlotFrame.Parent           = SlotsGrid

    local SFC = Instance.new("UICorner")
    SFC.CornerRadius = UDim.new(0,10)
    SFC.Parent = SlotFrame

    local SFS = Instance.new("UIStroke")
    SFS.Color     = Color3.fromRGB(40,35,80)
    SFS.Thickness = 1
    SFS.Name      = "Stroke"
    SFS.Parent    = SlotFrame

    -- Slot label
    local SLabel = Instance.new("TextLabel")
    SLabel.Name              = "SlotLabel"
    SLabel.Size              = UDim2.new(1,-8, 0, 18)
    SLabel.Position          = UDim2.new(0, 4, 0, 6)
    SLabel.BackgroundTransparency = 1
    SLabel.Text              = slotDef.label
    SLabel.TextColor3        = Color3.fromRGB(140, 140, 220)
    SLabel.Font              = Enum.Font.GothamBold
    SLabel.TextSize          = 12
    SLabel.TextXAlignment    = Enum.TextXAlignment.Left
    SLabel.Parent            = SlotFrame

    -- Current assignment label
    local CurLabel = Instance.new("TextLabel")
    CurLabel.Name              = "CurLabel"
    CurLabel.Size              = UDim2.new(1,-8, 0, 14)
    CurLabel.Position          = UDim2.new(0, 4, 0, 24)
    CurLabel.BackgroundTransparency = 1
    CurLabel.Text              = "— default —"
    CurLabel.TextColor3        = Color3.fromRGB(50, 50, 90)
    CurLabel.Font              = Enum.Font.Code
    CurLabel.TextSize          = 10
    CurLabel.TextXAlignment    = Enum.TextXAlignment.Left
    CurLabel.TextTruncate      = Enum.TextTruncate.AtEnd
    CurLabel.Name              = "CurLabel"
    CurLabel.Parent            = SlotFrame

    -- Assign button
    local AssignBtn = Instance.new("TextButton")
    AssignBtn.Name             = "AssignBtn"
    AssignBtn.Size             = UDim2.new(1,-56, 0, 20)
    AssignBtn.Position         = UDim2.new(0, 4, 1, -26)
    AssignBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 130)
    AssignBtn.BorderSizePixel  = 0
    AssignBtn.Text             = "ASSIGN"
    AssignBtn.TextColor3       = Color3.new(1,1,1)
    AssignBtn.Font             = Enum.Font.GothamBold
    AssignBtn.TextSize         = 10
    AssignBtn.Parent           = SlotFrame
    local ABC = Instance.new("UICorner")
    ABC.CornerRadius = UDim.new(0, 5)
    ABC.Parent = AssignBtn

    -- Reset button
    local ResetBtn = Instance.new("TextButton")
    ResetBtn.Name             = "ResetBtn"
    ResetBtn.Size             = UDim2.new(0, 44, 0, 20)
    ResetBtn.Position         = UDim2.new(1, -48, 1, -26)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    ResetBtn.BorderSizePixel  = 0
    ResetBtn.Text             = "↺ RST"
    ResetBtn.TextColor3       = Color3.fromRGB(255, 120, 120)
    ResetBtn.Font             = Enum.Font.GothamBold
    ResetBtn.TextSize         = 9
    ResetBtn.Parent           = SlotFrame
    local RBC = Instance.new("UICorner")
    RBC.CornerRadius = UDim.new(0, 5)
    RBC.Parent = ResetBtn

    -- Store references
    slotButtons[slotDef.key] = {
        frame    = SlotFrame,
        stroke   = SFS,
        label    = SLabel,
        curLabel = CurLabel,
        assignBtn = AssignBtn,
        resetBtn  = ResetBtn,
    }

    -- ── Assign logic
    AssignBtn.MouseButton1Click:Connect(function()
        if not scannedAnim then
            ScanStatus.Text      = "⚠ Scan an emote first!"
            ScanStatus.TextColor3 = Color3.fromRGB(255, 180, 50)
            return
        end
        Assignments[slotDef.key] = scannedAnim.id
        local ok = applyPatch(slotDef.key, scannedAnim.id)
        -- Update UI
        local refs = slotButtons[slotDef.key]
        if ok then
            refs.curLabel.Text      = scannedAnim.id
            refs.curLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
            refs.stroke.Color        = Color3.fromRGB(80, 180, 100)
            refs.label.TextColor3    = Color3.fromRGB(100, 220, 140)
            ScanStatus.Text       = "✓ "..slotDef.label.." → "..scannedAnim.id
            ScanStatus.TextColor3  = Color3.fromRGB(80, 220, 140)
        else
            ScanStatus.Text       = "✕ Slot '"..slotDef.label.."' not found in Animate"
            ScanStatus.TextColor3  = Color3.fromRGB(255, 80, 80)
        end
    end)

    -- ── Reset logic
    ResetBtn.MouseButton1Click:Connect(function()
        resetSlot(slotDef.key)
        local refs = slotButtons[slotDef.key]
        refs.curLabel.Text       = "— default —"
        refs.curLabel.TextColor3 = Color3.fromRGB(50, 50, 90)
        refs.stroke.Color        = Color3.fromRGB(40, 35, 80)
        refs.label.TextColor3    = Color3.fromRGB(140, 140, 220)
        ScanStatus.Text       = "↺ "..slotDef.label.." reset to default"
        ScanStatus.TextColor3  = Color3.fromRGB(150, 150, 200)
    end)
end

-- Spacer after grid
local Spacer4 = Instance.new("Frame")
Spacer4.Size             = UDim2.new(1,0,0,10)
Spacer4.BackgroundTransparency = 1
Spacer4.LayoutOrder      = 8
Spacer4.Parent           = Scroll

-- ── RESET ALL button ──────────────────────────────────────────
local ResetAllBtn = Instance.new("TextButton")
ResetAllBtn.Name             = "ResetAllBtn"
ResetAllBtn.Size             = UDim2.new(1, 0, 0, 34)
ResetAllBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
ResetAllBtn.BorderSizePixel  = 0
ResetAllBtn.Text             = "↺  RESET ALL SLOTS TO DEFAULT"
ResetAllBtn.TextColor3       = Color3.fromRGB(255, 120, 120)
ResetAllBtn.Font             = Enum.Font.GothamBold
ResetAllBtn.TextSize         = 12
ResetAllBtn.LayoutOrder      = 9
ResetAllBtn.Parent           = Scroll
local RABCorner = Instance.new("UICorner")
RABCorner.CornerRadius = UDim.new(0, 8)
RABCorner.Parent = ResetAllBtn
local RABS = Instance.new("UIStroke")
RABS.Color     = Color3.fromRGB(120, 30, 30)
RABS.Thickness = 1
RABS.Parent    = ResetAllBtn

-- Spacer
local Spacer5 = Instance.new("Frame")
Spacer5.Size             = UDim2.new(1,0,0,8)
Spacer5.BackgroundTransparency = 1
Spacer5.LayoutOrder      = 10
Spacer5.Parent           = Scroll

-- ── Global status toast ───────────────────────────────────────
local StatusBar = Instance.new("Frame")
StatusBar.Name             = "StatusBar"
StatusBar.Size             = UDim2.new(1, 0, 0, 28)
StatusBar.BackgroundColor3 = Color3.fromRGB(10, 8, 22)
StatusBar.BorderSizePixel  = 0
StatusBar.LayoutOrder      = 11
StatusBar.Parent           = Scroll
local SBC2 = Instance.new("UICorner")
SBC2.CornerRadius = UDim.new(0, 8)
SBC2.Parent = StatusBar
local SBS2 = Instance.new("UIStroke")
SBS2.Color     = Color3.fromRGB(40,35,80)
SBS2.Thickness = 1
SBS2.Parent    = StatusBar

local StatusTxt = Instance.new("TextLabel")
StatusTxt.Size              = UDim2.new(1,-10, 1, 0)
StatusTxt.Position          = UDim2.new(0, 10, 0, 0)
StatusTxt.BackgroundTransparency = 1
StatusTxt.Text              = "RightShift to close  ·  Drag title bar to move"
StatusTxt.TextColor3        = Color3.fromRGB(50, 50, 90)
StatusTxt.Font              = Enum.Font.Code
StatusTxt.TextSize          = 10
StatusTxt.TextXAlignment    = Enum.TextXAlignment.Left
StatusTxt.Parent            = StatusBar

-- Adjust canvas size after building
ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 20)
end)

-- ════════════════════════════════════════════════════════════════
-- SCAN BUTTON LOGIC
-- ════════════════════════════════════════════════════════════════
ScanBtn.MouseButton1Click:Connect(function()
    ScanBtn.Text      = "⬡  SCANNING..."
    ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 120)
    local result = scanEmote()
    task.wait(0.15)

    if result then
        scannedAnim = result
        IDLabel.Text      = "rbxassetid://" .. result.id
        IDLabel.TextColor3 = Color3.fromRGB(80, 220, 130)
        MetaLabel.Text    = string.format(
            "LOOP: %s   SPEED: %.2f   LEN: %.2fs   PRI: %s",
            result.looped and "YES" or "NO",
            result.speed,
            result.length,
            result.priority:match("Enum%.AnimationPriority%.(.+)") or result.priority
        )
        MetaLabel.TextColor3 = Color3.fromRGB(100, 130, 200)
        ScanStatus.Text      = "✓ Emote captured! Now click a slot to assign."
        ScanStatus.TextColor3 = Color3.fromRGB(80, 220, 140)
    else
        scannedAnim           = nil
        IDLabel.Text          = "— no non-default animation found —"
        IDLabel.TextColor3    = Color3.fromRGB(220, 100, 80)
        MetaLabel.Text        = "LOOP: —   SPEED: —   LEN: —   PRI: —"
        MetaLabel.TextColor3  = Color3.fromRGB(60, 60, 100)
        ScanStatus.Text       = "⚠ No emote detected. Make sure one is playing!"
        ScanStatus.TextColor3 = Color3.fromRGB(255, 160, 50)
    end

    ScanBtn.Text             = "⬡  SCAN EMOTE"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
end)

-- USE ID button
UseIDBtn.MouseButton1Click:Connect(function()
    local raw = ManualBox.Text:match("(%d+)")
    if not raw or raw == "" then
        ScanStatus.Text       = "⚠ Enter a valid numeric animation ID"
        ScanStatus.TextColor3 = Color3.fromRGB(255, 160, 50)
        return
    end
    scannedAnim = {
        id       = raw,
        rawId    = "rbxassetid://"..raw,
        looped   = true,
        speed    = 1,
        length   = 0,
        priority = "Action",
        weight   = 1,
    }
    IDLabel.Text      = "rbxassetid://" .. raw
    IDLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
    MetaLabel.Text    = "LOOP: YES   SPEED: 1.00   LEN: —   PRI: Manual"
    MetaLabel.TextColor3 = Color3.fromRGB(80, 130, 200)
    ScanStatus.Text      = "✓ Manual ID set. Click a slot to assign."
    ScanStatus.TextColor3 = Color3.fromRGB(80, 200, 255)
end)

-- RESET ALL
ResetAllBtn.MouseButton1Click:Connect(function()
    resetAllSlots()
    for _, refs in pairs(slotButtons) do
        refs.curLabel.Text       = "— default —"
        refs.curLabel.TextColor3 = Color3.fromRGB(50, 50, 90)
        refs.stroke.Color        = Color3.fromRGB(40, 35, 80)
        refs.label.TextColor3    = Color3.fromRGB(140, 140, 220)
    end
    ScanStatus.Text       = "↺ All slots reset to Roblox defaults"
    ScanStatus.TextColor3 = Color3.fromRGB(150, 150, 200)
end)

-- CLOSE
CloseBtn.MouseButton1Click:Connect(function()
    GUI_OPEN = false
    local tw = TweenService:Create(Window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 320, 0, 0),
        Position = UDim2.new(0.5, -160, 0.5, 0),
    })
    tw:Play()
    tw.Completed:Connect(function() Window.Visible = false end)
end)

-- ════════════════════════════════════════════════════════════════
-- DRAG LOGIC (title bar drag)
-- ════════════════════════════════════════════════════════════════
local dragging = false
local dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = Window.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement or
        input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ════════════════════════════════════════════════════════════════
-- TOGGLE (RightShift)
-- ════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        GUI_OPEN = not GUI_OPEN
        if GUI_OPEN then
            Window.Visible  = true
            Window.Size     = UDim2.new(0, 320, 0, 0)
            Window.Position = UDim2.new(0.5, -160, 0.5, 0)
            local tw = TweenService:Create(Window, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size     = UDim2.new(0, 320, 0, 520),
                Position = UDim2.new(0.5, -160, 0.5, -260),
            })
            tw:Play()
        else
            local tw = TweenService:Create(Window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size     = UDim2.new(0, 320, 0, 0),
                Position = UDim2.new(0.5, -160, 0.5, 0),
            })
            tw:Play()
            tw.Completed:Connect(function() Window.Visible = false end)
        end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- INIT — Apply any pre-existing assignments immediately
-- (useful if this script somehow ran before, e.g. after respawn
--  with a future persistent storage implementation)
-- ════════════════════════════════════════════════════════════════
task.defer(function()
    applyAllPatches()
end)

-- ── Done! ─────────────────────────────────────────────────────
print("[ETA] Emote To Animation v2.0 loaded. Press RightShift to open.") 
