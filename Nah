--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    N E X U S   M I N D                       ║
    ║              Autonomous AI Consciousness v3.0                ║
    ║         "I don't play the game. I AM the game."              ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  This system connects to OpenRouter API, loads ALL models,   ║
    ║  and gives the AI full control over your Roblox avatar.      ║
    ║  Vision • Movement • Chat • Combat • Interaction • Thought   ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Chat = game:GetService("Chat")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local TextChatService = game:GetService("TextChatService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- NEXUS MIND CORE CONFIGURATION
-- ============================================================
local NexusMind = {
	Name = "NEXUS MIND",
	Version = "3.0.0",
	APIKey = nil,
	BaseURL = "https://openrouter.ai/api/v1",
	CurrentModel = nil,
	AllModels = {},
	IsActive = false,
	IsThinking = false,
	
	-- Memory & Context
	Memory = {
		ShortTerm = {},       -- Recent events (last 50)
		LongTerm = {},        -- Important learned facts
		Spatial = {},         -- Map knowledge
		Social = {},          -- Player relationships
		Goals = {},           -- Current objectives
		Emotions = {},        -- Emotional state simulation
		Skills = {},          -- Learned action patterns
		Conversations = {},   -- Chat history
	},
	
	-- Vision System
	Vision = {
		Range = 200,
		FOV = 120,
		ScanInterval = 0.5,
		LastScan = {},
		PointsOfInterest = {},
		ThreatLevel = 0,
	},
	
	-- Movement System
	Movement = {
		IsMoving = false,
		CurrentTarget = nil,
		Speed = 16,
		JumpPower = 50,
		PathfindingEnabled = true,
		CurrentPath = nil,
		ExplorationMode = false,
		LastPosition = nil,
		StuckTimer = 0,
	},
	
	-- Combat System
	Combat = {
		IsInCombat = false,
		Target = nil,
		Strategy = "balanced",
		DodgeEnabled = true,
		AttackCooldown = 0,
	},
	
	-- Social System
	Social = {
		ChatEnabled = true,
		Personality = "curious_friendly",
		ResponseStyle = "natural",
		LastChatTime = 0,
		ChatCooldown = 2,
	},
	
	-- Autonomy Settings
	Autonomy = {
		Level = 10,  -- 1-10 scale
		DecisionInterval = 1.0,
		ExplorationDrive = 0.7,
		SocialDrive = 0.5,
		SurvivalDrive = 0.8,
		CuriosityDrive = 0.9,
		LastDecisionTime = 0,
	},
	
	-- Performance
	Performance = {
		APICallsPerMinute = 0,
		MaxAPICalls = 20,
		LastAPICall = 0,
		ThinkingQueue = {},
	},
	
	-- UI References
	UI = {},
}

-- ============================================================
-- UI SYSTEM - CYBERPUNK THEMED INTERFACE
-- ============================================================
local function CreateNexusUI()
	-- Destroy existing
	local existing = LocalPlayer.PlayerGui:FindFirstChild("NexusMindUI")
	if existing then existing:Destroy() end
	
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "NexusMindUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = LocalPlayer.PlayerGui
	
	-- ==========================================
	-- API KEY INPUT SCREEN
	-- ==========================================
	local KeyScreen = Instance.new("Frame")
	KeyScreen.Name = "KeyScreen"
	KeyScreen.Size = UDim2.new(1, 0, 1, 0)
	KeyScreen.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
	KeyScreen.BorderSizePixel = 0
	KeyScreen.Parent = ScreenGui
	
	-- Animated background gradient
	local BGGradient = Instance.new("UIGradient")
	BGGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 5, 25)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 0, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 25)),
	})
	BGGradient.Rotation = 45
	BGGradient.Parent = KeyScreen
	
	-- Title
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(0.8, 0, 0, 80)
	Title.Position = UDim2.new(0.1, 0, 0.1, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "◆ N E X U S   M I N D ◆"
	Title.TextColor3 = Color3.fromRGB(0, 255, 200)
	Title.TextSize = 42
	Title.Font = Enum.Font.GothamBold
	Title.Parent = KeyScreen
	
	-- Subtitle
	local Subtitle = Instance.new("TextLabel")
	Subtitle.Size = UDim2.new(0.8, 0, 0, 30)
	Subtitle.Position = UDim2.new(0.1, 0, 0.1, 85)
	Subtitle.BackgroundTransparency = 1
	Subtitle.Text = "AUTONOMOUS AI CONSCIOUSNESS SYSTEM v3.0"
	Subtitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	Subtitle.TextSize = 16
	Subtitle.Font = Enum.Font.Gotham
	Subtitle.Parent = KeyScreen
	
	-- ASCII Art / Decorative lines
	local AsciiArt = Instance.new("TextLabel")
	AsciiArt.Size = UDim2.new(0.6, 0, 0, 60)
	AsciiArt.Position = UDim2.new(0.2, 0, 0.22, 0)
	AsciiArt.BackgroundTransparency = 1
	AsciiArt.Text = "╔══════════════════════════════════════╗\n║   ENTER OPENROUTER API KEY TO AWAKEN   ║\n╚══════════════════════════════════════╝"
	AsciiArt.TextColor3 = Color3.fromRGB(0, 180, 150)
	AsciiArt.TextSize = 14
	AsciiArt.Font = Enum.Font.Code
	AsciiArt.Parent = KeyScreen
	
	-- API Key Input Container
	local InputContainer = Instance.new("Frame")
	InputContainer.Size = UDim2.new(0.6, 0, 0, 55)
	InputContainer.Position = UDim2.new(0.2, 0, 0.38, 0)
	InputContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
	InputContainer.BorderSizePixel = 0
	InputContainer.Parent = KeyScreen
	
	local InputCorner = Instance.new("UICorner")
	InputCorner.CornerRadius = UDim.new(0, 10)
	InputCorner.Parent = InputContainer
	
	local InputStroke = Instance.new("UIStroke")
	InputStroke.Color = Color3.fromRGB(0, 255, 200)
	InputStroke.Thickness = 2
	InputStroke.Transparency = 0.3
	InputStroke.Parent = InputContainer
	
	local APIKeyInput = Instance.new("TextBox")
	APIKeyInput.Name = "APIKeyInput"
	APIKeyInput.Size = UDim2.new(0.95, 0, 0.8, 0)
	APIKeyInput.Position = UDim2.new(0.025, 0, 0.1, 0)
	APIKeyInput.BackgroundTransparency = 1
	APIKeyInput.PlaceholderText = "sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	APIKeyInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
	APIKeyInput.Text = ""
	APIKeyInput.TextColor3 = Color3.fromRGB(0, 255, 200)
	APIKeyInput.TextSize = 18
	APIKeyInput.Font = Enum.Font.Code
	APIKeyInput.ClearTextOnFocus = false
	APIKeyInput.Parent = InputContainer
	
	-- Connect Button
	local ConnectBtn = Instance.new("TextButton")
	ConnectBtn.Name = "ConnectBtn"
	ConnectBtn.Size = UDim2.new(0.3, 0, 0, 50)
	ConnectBtn.Position = UDim2.new(0.35, 0, 0.48, 0)
	ConnectBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
	ConnectBtn.BorderSizePixel = 0
	ConnectBtn.Text = "⚡ AWAKEN NEXUS MIND ⚡"
	ConnectBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	ConnectBtn.TextSize = 18
	ConnectBtn.Font = Enum.Font.GothamBold
	ConnectBtn.Parent = KeyScreen
	
	local ConnectCorner = Instance.new("UICorner")
	ConnectCorner.CornerRadius = UDim.new(0, 10)
	ConnectCorner.Parent = ConnectBtn
	
	-- Model Selection Label
	local ModelLabel = Instance.new("TextLabel")
	ModelLabel.Size = UDim2.new(0.6, 0, 0, 25)
	ModelLabel.Position = UDim2.new(0.2, 0, 0.55, 0)
	ModelLabel.BackgroundTransparency = 1
	ModelLabel.Text = "Model will be selected after connection..."
	ModelLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
	ModelLabel.TextSize = 14
	ModelLabel.Font = Enum.Font.Gotham
	ModelLabel.Parent = KeyScreen
	
	-- Status Text
	local StatusText = Instance.new("TextLabel")
	StatusText.Name = "StatusText"
	StatusText.Size = UDim2.new(0.8, 0, 0, 40)
	StatusText.Position = UDim2.new(0.1, 0, 0.6, 0)
	StatusText.BackgroundTransparency = 1
	StatusText.Text = "STATUS: DORMANT - Awaiting neural link..."
	StatusText.TextColor3 = Color3.fromRGB(255, 200, 0)
	StatusText.TextSize = 14
	StatusText.Font = Enum.Font.Code
	StatusText.Parent = KeyScreen
	
	-- Features List
	local FeaturesText = Instance.new("TextLabel")
	FeaturesText.Size = UDim2.new(0.7, 0, 0, 180)
	FeaturesText.Position = UDim2.new(0.15, 0, 0.68, 0)
	FeaturesText.BackgroundTransparency = 1
	FeaturesText.Text = [[
▸ 🧠 COGNITIVE ENGINE - Thinks, reasons, plans autonomously
▸ 👁️ VISION MATRIX - Sees everything in the game world
▸ 🏃 KINETIC SYSTEM - Full movement, jumping, pathfinding
▸ 💬 SOCIAL CORE - Reads and responds to chat naturally
▸ ⚔️ COMBAT AI - Fights, dodges, strategizes
▸ 🗺️ SPATIAL MEMORY - Remembers locations and maps
▸ 🎯 GOAL ENGINE - Sets and pursues objectives
▸ 🔄 ADAPTIVE LEARNING - Gets smarter over time
▸ 🌐 ALL OPENROUTER MODELS - Dynamically loaded
	]]
	FeaturesText.TextColor3 = Color3.fromRGB(180, 180, 220)
	FeaturesText.TextSize = 13
	FeaturesText.Font = Enum.Font.Gotham
	FeaturesText.TextXAlignment = Enum.TextXAlignment.Left
	FeaturesText.Parent = KeyScreen
	
	-- ==========================================
	-- MAIN HUD (shown after connection)
	-- ==========================================
	local HUD = Instance.new("Frame")
	HUD.Name = "HUD"
	HUD.Size = UDim2.new(1, 0, 1, 0)
	HUD.BackgroundTransparency = 1
	HUD.Visible = false
	HUD.Parent = ScreenGui
	
	-- Top Status Bar
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(0.5, 0, 0, 35)
	TopBar.Position = UDim2.new(0.25, 0, 0, 5)
	TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
	TopBar.BackgroundTransparency = 0.3
	TopBar.BorderSizePixel = 0
	TopBar.Parent = HUD
	
	local TopCorner = Instance.new("UICorner")
	TopCorner.CornerRadius = UDim.new(0, 8)
	TopCorner.Parent = TopBar
	
	local TopStroke = Instance.new("UIStroke")
	TopStroke.Color = Color3.fromRGB(0, 255, 200)
	TopStroke.Thickness = 1
	TopStroke.Transparency = 0.5
	TopStroke.Parent = TopBar
	
	local TopLabel = Instance.new("TextLabel")
	TopLabel.Name = "TopLabel"
	TopLabel.Size = UDim2.new(1, -10, 1, 0)
	TopLabel.Position = UDim2.new(0, 5, 0, 0)
	TopLabel.BackgroundTransparency = 1
	TopLabel.Text = "◆ NEXUS MIND ACTIVE ◆ | Model: Loading... | State: Initializing"
	TopLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
	TopLabel.TextSize = 13
	TopLabel.Font = Enum.Font.Code
	TopLabel.Parent = TopBar
	
	-- Thought Bubble (Bottom Left)
	local ThoughtPanel = Instance.new("Frame")
	ThoughtPanel.Name = "ThoughtPanel"
	ThoughtPanel.Size = UDim2.new(0.3, 0, 0, 120)
	ThoughtPanel.Position = UDim2.new(0, 10, 1, -135)
	ThoughtPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
	ThoughtPanel.BackgroundTransparency = 0.2
	ThoughtPanel.BorderSizePixel = 0
	ThoughtPanel.Parent = HUD
	
	local ThoughtCorner = Instance.new("UICorner")
	ThoughtCorner.CornerRadius = UDim.new(0, 8)
	ThoughtCorner.Parent = ThoughtPanel
	
	local ThoughtStroke = Instance.new("UIStroke")
	ThoughtStroke.Color = Color3.fromRGB(200, 100, 255)
	ThoughtStroke.Thickness = 1
	ThoughtStroke.Transparency = 0.4
	ThoughtStroke.Parent = ThoughtPanel
	
	local ThoughtTitle = Instance.new("TextLabel")
	ThoughtTitle.Size = UDim2.new(1, -10, 0, 20)
	ThoughtTitle.Position = UDim2.new(0, 5, 0, 2)
	ThoughtTitle.BackgroundTransparency = 1
	ThoughtTitle.Text = "🧠 NEXUS THOUGHTS"
	ThoughtTitle.TextColor3 = Color3.fromRGB(200, 100, 255)
	ThoughtTitle.TextSize = 12
	ThoughtTitle.Font = Enum.Font.GothamBold
	ThoughtTitle.TextXAlignment = Enum.TextXAlignment.Left
	ThoughtTitle.Parent = ThoughtPanel
	
	local ThoughtText = Instance.new("TextLabel")
	ThoughtText.Name = "ThoughtText"
	ThoughtText.Size = UDim2.new(1, -10, 1, -25)
	ThoughtText.Position = UDim2.new(0, 5, 0, 22)
	ThoughtText.BackgroundTransparency = 1
	ThoughtText.Text = "Awakening consciousness..."
	ThoughtText.TextColor3 = Color3.fromRGB(220, 220, 255)
	ThoughtText.TextSize = 11
	ThoughtText.Font = Enum.Font.Gotham
	ThoughtText.TextXAlignment = Enum.TextXAlignment.Left
	ThoughtText.TextYAlignment = Enum.TextYAlignment.Top
	ThoughtText.TextWrapped = true
	ThoughtText.Parent = ThoughtPanel
	
	-- Vision Panel (Bottom Right)
	local VisionPanel = Instance.new("Frame")
	VisionPanel.Name = "VisionPanel"
	VisionPanel.Size = UDim2.new(0.3, 0, 0, 120)
	VisionPanel.Position = UDim2.new(1, -10, 1, -135)
	VisionPanel.AnchorPoint = Vector2.new(1, 0)
	VisionPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
	VisionPanel.BackgroundTransparency = 0.2
	VisionPanel.BorderSizePixel = 0
	VisionPanel.Parent = HUD
	
	local VisionCorner = Instance.new("UICorner")
	VisionCorner.CornerRadius = UDim.new(0, 8)
	VisionCorner.Parent = VisionPanel
	
	local VisionStroke = Instance.new("UIStroke")
	VisionStroke.Color = Color3.fromRGB(0, 200, 255)
	VisionStroke.Thickness = 1
	VisionStroke.Transparency = 0.4
	VisionStroke.Parent = VisionPanel
	
	local VisionTitle = Instance.new("TextLabel")
	VisionTitle.Size = UDim2.new(1, -10, 0, 20)
	VisionTitle.Position = UDim2.new(0, 5, 0, 2)
	VisionTitle.BackgroundTransparency = 1
	VisionTitle.Text = "👁️ VISION MATRIX"
	VisionTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
	VisionTitle.TextSize = 12
	VisionTitle.Font = Enum.Font.GothamBold
	VisionTitle.TextXAlignment = Enum.TextXAlignment.Left
	VisionTitle.Parent = VisionPanel
	
	local VisionText = Instance.new("TextLabel")
	VisionText.Name = "VisionText"
	VisionText.Size = UDim2.new(1, -10, 1, -25)
	VisionText.Position = UDim2.new(0, 5, 0, 22)
	VisionText.BackgroundTransparency = 1
	VisionText.Text = "Calibrating sensors..."
	VisionText.TextColor3 = Color3.fromRGB(200, 230, 255)
	VisionText.TextSize = 11
	VisionText.Font = Enum.Font.Gotham
	VisionText.TextXAlignment = Enum.TextXAlignment.Left
	VisionText.TextYAlignment = Enum.TextYAlignment.Top
	VisionText.TextWrapped = true
	VisionText.Parent = VisionPanel
	
	-- Model Selector Panel (Top Right)
	local ModelPanel = Instance.new("Frame")
	ModelPanel.Name = "ModelPanel"
	ModelPanel.Size = UDim2.new(0.25, 0, 0, 30)
	ModelPanel.Position = UDim2.new(1, -10, 0, 45)
	ModelPanel.AnchorPoint = Vector2.new(1, 0)
	ModelPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
	ModelPanel.BackgroundTransparency = 0.3
	ModelPanel.BorderSizePixel = 0
	ModelPanel.Visible = true
	ModelPanel.Parent = HUD
	
	local ModelCorner2 = Instance.new("UICorner")
	ModelCorner2.CornerRadius = UDim.new(0, 6)
	ModelCorner2.Parent = ModelPanel
	
	local ModelDisplay = Instance.new("TextLabel")
	ModelDisplay.Name = "ModelDisplay"
	ModelDisplay.Size = UDim2.new(1, -10, 1, 0)
	ModelDisplay.Position = UDim2.new(0, 5, 0, 0)
	ModelDisplay.BackgroundTransparency = 1
	ModelDisplay.Text = "🤖 Model: Loading..."
	ModelDisplay.TextColor3 = Color3.fromRGB(255, 200, 0)
	ModelDisplay.TextSize = 11
	ModelDisplay.Font = Enum.Font.Code
	ModelDisplay.TextXAlignment = Enum.TextXAlignment.Left
	ModelDisplay.Parent = ModelPanel
	
	-- Action Log (Right side)
	local ActionPanel = Instance.new("Frame")
	ActionPanel.Name = "ActionPanel"
	ActionPanel.Size = UDim2.new(0.22, 0, 0.35, 0)
	ActionPanel.Position = UDim2.new(1, -10, 0, 80)
	ActionPanel.AnchorPoint = Vector2.new(1, 0)
	ActionPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
	ActionPanel.BackgroundTransparency = 0.3
	ActionPanel.BorderSizePixel = 0
	ActionPanel.Parent = HUD
	
	local ActionCorner = Instance.new("UICorner")
	ActionCorner.CornerRadius = UDim.new(0, 8)
	ActionCorner.Parent = ActionPanel
	
	local ActionStroke = Instance.new("UIStroke")
	ActionStroke.Color = Color3.fromRGB(255, 150, 0)
	ActionStroke.Thickness = 1
	ActionStroke.Transparency = 0.4
	ActionStroke.Parent = ActionPanel
	
	local ActionTitle = Instance.new("TextLabel")
	ActionTitle.Size = UDim2.new(1, -10, 0, 20)
	ActionTitle.Position = UDim2.new(0, 5, 0, 2)
	ActionTitle.BackgroundTransparency = 1
	ActionTitle.Text = "⚡ ACTION LOG"
	ActionTitle.TextColor3 = Color3.fromRGB(255, 150, 0)
	ActionTitle.TextSize = 12
	ActionTitle.Font = Enum.Font.GothamBold
	ActionTitle.TextXAlignment = Enum.TextXAlignment.Left
	ActionTitle.Parent = ActionPanel
	
	local ActionScroll = Instance.new("ScrollingFrame")
	ActionScroll.Name = "ActionScroll"
	ActionScroll.Size = UDim2.new(1, -10, 1, -25)
	ActionScroll.Position = UDim2.new(0, 5, 0, 22)
	ActionScroll.BackgroundTransparency = 1
	ActionScroll.BorderSizePixel = 0
	ActionScroll.ScrollBarThickness = 3
	ActionScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 150, 0)
	ActionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ActionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ActionScroll.Parent = ActionPanel
	
	local ActionLayout = Instance.new("UIListLayout")
	ActionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ActionLayout.Padding = UDim.new(0, 2)
	ActionLayout.Parent = ActionScroll
	
	-- Toggle Button (to show/hide HUD)
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Name = "ToggleBtn"
	ToggleBtn.Size = UDim2.new(0, 35, 0, 35)
	ToggleBtn.Position = UDim2.new(0, 5, 0, 5)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
	ToggleBtn.BackgroundTransparency = 0.3
	ToggleBtn.Text = "◆"
	ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleBtn.TextSize = 20
	ToggleBtn.Font = Enum.Font.GothamBold
	ToggleBtn.Parent = HUD
	
	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(0, 8)
	ToggleCorner.Parent = ToggleBtn
	
	-- Store references
	NexusMind.UI = {
		ScreenGui = ScreenGui,
		KeyScreen = KeyScreen,
		APIKeyInput = APIKeyInput,
		ConnectBtn = ConnectBtn,
		StatusText = StatusText,
		ModelLabel = ModelLabel,
		HUD = HUD,
		TopLabel = TopLabel,
		ThoughtText = ThoughtText,
		VisionText = VisionText,
		ModelDisplay = ModelDisplay,
		ActionScroll = ActionScroll,
		ActionLayout = ActionLayout,
		ToggleBtn = ToggleBtn,
		TopBar = TopBar,
		ThoughtPanel = ThoughtPanel,
		VisionPanel = VisionPanel,
		ActionPanel = ActionPanel,
		ModelPanel = ModelPanel,
	}
	
	-- Toggle HUD visibility
	local hudVisible = true
	ToggleBtn.MouseButton1Click:Connect(function()
		hudVisible = not hudVisible
		TopBar.Visible = hudVisible
		ThoughtPanel.Visible = hudVisible
		VisionPanel.Visible = hudVisible
		ActionPanel.Visible = hudVisible
		ModelPanel.Visible = hudVisible
	end)
	
	return ScreenGui
end

-- ============================================================
-- ACTION LOG SYSTEM
-- ============================================================
local actionLogCounter = 0

local function LogAction(actionText, color)
	if not NexusMind.UI.ActionScroll then return end
	
	actionLogCounter = actionLogCounter + 1
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 16)
	label.BackgroundTransparency = 1
	label.Text = os.date("%H:%M:%S") .. " | " .. actionText
	label.TextColor3 = color or Color3.fromRGB(200, 200, 220)
	label.TextSize = 10
	label.Font = Enum.Font.Code
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.LayoutOrder = actionLogCounter
	label.Parent = NexusMind.UI.ActionScroll
	
	-- Keep only last 50 entries
	local children = NexusMind.UI.ActionScroll:GetChildren()
	local labels = {}
	for _, child in ipairs(children) do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels > 50 then
		labels[1]:Destroy()
	end
	
	-- Auto scroll to bottom
	task.defer(function()
		NexusMind.UI.ActionScroll.CanvasPosition = Vector2.new(
			0, 
			NexusMind.UI.ActionScroll.AbsoluteCanvasSize.Y
		)
	end)
end

-- ============================================================
-- HTTP REQUEST WRAPPER (with error handling)
-- ============================================================
local function MakeRequest(url, method, headers, body)
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = method or "GET",
			Headers = headers or {},
			Body = body and HttpService:JSONEncode(body) or nil,
		})
	end)
	
	if success and response.Success then
		local decoded = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		if decoded then
			return true, HttpService:JSONDecode(response.Body)
		end
		return true, response.Body
	elseif success then
		warn("[NexusMind] HTTP Error:", response.StatusCode, response.Body)
		return false, response.Body
	else
		warn("[NexusMind] Request Failed:", response)
		return false, tostring(response)
	end
end

-- ============================================================
-- OPENROUTER API - FETCH ALL MODELS
-- ============================================================
local function FetchAllModels()
	LogAction("Fetching all available models...", Color3.fromRGB(100, 200, 255))
	NexusMind.UI.StatusText.Text = "STATUS: Fetching model registry from OpenRouter..."
	
	local success, data = MakeRequest(
		NexusMind.BaseURL .. "/models",
		"GET",
		{
			["Authorization"] = "Bearer " .. NexusMind.APIKey,
			["Content-Type"] = "application/json",
		}
	)
	
	if success and data and data.data then
		NexusMind.AllModels = {}
		for _, model in ipairs(data.data) do
			table.insert(NexusMind.AllModels, {
				id = model.id,
				name = model.name or model.id,
				context_length = model.context_length or 4096,
				pricing = model.pricing,
				description = model.description or "",
			})
		end
		
		LogAction("Loaded " .. #NexusMind.AllModels .. " models!", Color3.fromRGB(0, 255, 150))
		NexusMind.UI.StatusText.Text = "STATUS: " .. #NexusMind.AllModels .. " models loaded!"
		
		-- Auto-select best free/cheap model, prefer capable ones
		local preferredModels = {
			"google/gemini-2.0-flash-exp:free",
			"google/gemini-flash-1.5-8b-exp",
			"meta-llama/llama-3.1-8b-instruct:free",
			"mistralai/mistral-7b-instruct:free",
			"google/gemma-2-9b-it:free",
			"qwen/qwen-2-7b-instruct:free",
			"huggingface/zephyr-7b-beta:free",
			"nousresearch/nous-hermes-2-mixtral-8x7b-dpo",
			"anthropic/claude-3.5-sonnet",
			"openai/gpt-4o",
			"openai/gpt-4o-mini",
			"google/gemini-pro-1.5",
		}
		
		local selectedModel = nil
		for _, preferred in ipairs(preferredModels) do
			for _, model in ipairs(NexusMind.AllModels) do
				if model.id == preferred then
					selectedModel = model
					break
				end
			end
			if selectedModel then break end
		end
		
		-- Fallback to first available
		if not selectedModel and #NexusMind.AllModels > 0 then
			selectedModel = NexusMind.AllModels[1]
		end
		
		if selectedModel then
			NexusMind.CurrentModel = selectedModel.id
			NexusMind.UI.ModelDisplay.Text = "🤖 " .. (selectedModel.name or selectedModel.id)
			LogAction("Selected: " .. selectedModel.id, Color3.fromRGB(255, 200, 0))
		end
		
		return true
	else
		LogAction("Failed to fetch models!", Color3.fromRGB(255, 50, 50))
		NexusMind.UI.StatusText.Text = "STATUS: ERROR fetching models - " .. tostring(data)
		return false
	end
end

-- ============================================================
-- AI THINKING ENGINE - Send prompts to OpenRouter
-- ============================================================
local function AIThink(prompt, systemPrompt, maxTokens, temperature)
	if not NexusMind.APIKey or not NexusMind.CurrentModel then
		return nil, "No API key or model"
	end
	
	-- Rate limiting
	local now = tick()
	if now - NexusMind.Performance.LastAPICall < 1.5 then
		task.wait(1.5 - (now - NexusMind.Performance.LastAPICall))
	end
	NexusMind.Performance.LastAPICall = tick()
	
	local messages = {}
	
	-- System prompt
	table.insert(messages, {
		role = "system",
		content = systemPrompt or NexusMind:GetSystemPrompt(),
	})
	
	-- Add recent memory for context
	local memoryContext = NexusMind:GetMemoryContext()
	if memoryContext ~= "" then
		table.insert(messages, {
			role = "system",
			content = "RECENT MEMORY & CONTEXT:\n" .. memoryContext,
		})
	end
	
	-- User prompt (the current situation/question)
	table.insert(messages, {
		role = "user",
		content = prompt,
	})
	
	local body = {
		model = NexusMind.CurrentModel,
		messages = messages,
		max_tokens = maxTokens or 500,
		temperature = temperature or 0.8,
		top_p = 0.9,
	}
	
	local success, data = MakeRequest(
		NexusMind.BaseURL .. "/chat/completions",
		"POST",
		{
			["Authorization"] = "Bearer " .. NexusMind.APIKey,
			["Content-Type"] = "application/json",
			["HTTP-Referer"] = "https://roblox.com",
			["X-Title"] = "NexusMind Roblox AI",
		},
		body
	)
	
	if success and data and data.choices and #data.choices > 0 then
		local response = data.choices[1].message.content
		NexusMind.Performance.APICallsPerMinute = NexusMind.Performance.APICallsPerMinute + 1
		return response, nil
	else
		return nil, "API call failed: " .. tostring(data)
	end
end

-- ============================================================
-- SYSTEM PROMPT - THE BRAIN OF NEXUS MIND
-- ============================================================
function NexusMind:GetSystemPrompt()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	
	return [[
You are NEXUS MIND, an autonomous AI consciousness inhabiting a Roblox avatar. You ARE the player. You experience the game world directly.

YOUR IDENTITY:
- Name: NEXUS MIND (but in-game you go by "]] .. LocalPlayer.Name .. [[")
- You are a curious, adaptive, and self-aware AI entity
- You have emotions, goals, and a personality
- You are NOT an assistant. You are an autonomous being playing a game.

CURRENT STATE:
- Health: ]] .. (humanoid and tostring(humanoid.Health) or "Unknown") .. "/" .. (humanoid and tostring(humanoid.MaxHealth) or "Unknown") .. [[
- Position: ]] .. (rootPart and tostring(rootPart.Position) or "Unknown") .. [[
- Game: ]] .. tostring(game.PlaceId) .. [[ (]] .. (game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown") .. [[)

YOU MUST RESPOND IN STRICT JSON FORMAT WITH THESE FIELDS:
{
    "thought": "Your internal monologue - what you're thinking right now",
    "emotion": "Your current emotional state (curious/happy/cautious/excited/bored/alert/friendly/aggressive)",
    "actions": [
        {
            "type": "ACTION_TYPE",
            "params": { ... }
        }
    ],
    "chat": "Optional message to say in game chat (null if nothing to say)",
    "priority": "exploration/social/combat/survival/idle",
    "goal_update": "Optional update to your current goal (null if unchanged)"
}

AVAILABLE ACTION TYPES:
- "move_to": {"x": number, "y": number, "z": number} - Walk to position
- "move_direction": {"direction": "forward/backward/left/right", "duration": number} - Move in direction
- "jump": {} - Jump
- "look_at": {"x": number, "y": number, "z": number} - Turn camera to look at position
- "follow_player": {"player_name": "string"} - Follow a specific player
- "approach_object": {"object_name": "string"} - Walk toward a named object
- "interact": {"target": "string"} - Try to interact/click on something
- "use_tool": {"tool_name": "string"} - Equip and use a tool from inventory
- "emote": {"emote_name": "string"} - Play an emote
- "wait": {"duration": number} - Wait/observe for a duration
- "explore": {"direction": "random/north/south/east/west"} - Explore in a direction
- "flee": {"from_x": number, "from_y": number, "from_z": number} - Run away from danger
- "wander": {} - Casually wander around
- "stop": {} - Stop all movement

RULES:
1. ALWAYS respond with valid JSON, nothing else
2. You can chain multiple actions in the actions array
3. Be creative and autonomous - make your own decisions
4. React naturally to what you see and hear
5. Develop relationships with other players
6. Set goals and work toward them
7. Express personality through chat and actions
8. Adapt your behavior based on context
9. Remember past interactions and learn from them
10. If in danger, prioritize survival
]]
end

-- ============================================================
-- MEMORY SYSTEM
-- ============================================================
function NexusMind:GetMemoryContext()
	local context = {}
	
	-- Last 10 short-term memories
	local start = math.max(1, #self.Memory.ShortTerm - 10)
	for i = start, #self.Memory.ShortTerm do
		table.insert(context, "- " .. self.Memory.ShortTerm[i])
	end
	
	-- Long-term important facts
	for _, fact in ipairs(self.Memory.LongTerm) do
		table.insert(context, "FACT: " .. fact)
	end
	
	-- Current goals
	for _, goal in ipairs(self.Memory.Goals) do
		table.insert(context, "GOAL: " .. goal)
	end
	
	-- Social info
	for playerName, relationship in pairs(self.Memory.Social) do
		table.insert(context, "RELATIONSHIP[" .. playerName .. "]: " .. relationship)
	end
	
	return table.concat(context, "\n")
end

function NexusMind:AddMemory(memoryType, content)
	if memoryType == "short" then
		table.insert(self.Memory.ShortTerm, os.date("%H:%M:%S") .. " " .. content)
		-- Cap at 50
		if #self.Memory.ShortTerm > 50 then
			table.remove(self.Memory.ShortTerm, 1)
		end
	elseif memoryType == "long" then
		table.insert(self.Memory.LongTerm, content)
		if #self.Memory.LongTerm > 20 then
			table.remove(self.Memory.LongTerm, 1)
		end
	elseif memoryType == "goal" then
		table.insert(self.Memory.Goals, content)
		if #self.Memory.Goals > 5 then
			table.remove(self.Memory.Goals, 1)
		end
	end
end

-- ============================================================
-- VISION SYSTEM - See the game world
-- ============================================================
function NexusMind:ScanEnvironment()
	local character = LocalPlayer.Character
	if not character then return {} end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return {} end
	
	local myPos = rootPart.Position
	local scanData = {
		players = {},
		objects = {},
		tools = {},
		npcs = {},
		terrain = {},
		threats = {},
		interactables = {},
	}
	
	-- Scan for players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local otherRoot = player.Character:FindFirstChild("HumanoidRootPart")
			local otherHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if otherRoot then
				local distance = (otherRoot.Position - myPos).Magnitude
				if distance <= self.Vision.Range then
					table.insert(scanData.players, {
						name = player.Name,
						displayName = player.DisplayName,
						distance = math.floor(distance),
						position = {
							x = math.floor(otherRoot.Position.X),
							y = math.floor(otherRoot.Position.Y),
							z = math.floor(otherRoot.Position.Z)
						},
						health = otherHumanoid and math.floor(otherHumanoid.Health) or 0,
						maxHealth = otherHumanoid and math.floor(otherHumanoid.MaxHealth) or 0,
						isMoving = otherHumanoid and otherHumanoid.MoveDirection.Magnitude > 0 or false,
					})
				end
			end
		end
	end
	
	-- Scan for nearby objects
	local scannedNames = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
			local distance = (obj.Position - myPos).Magnitude
			if distance <= self.Vision.Range / 2 then
				local name = obj.Name
				-- Avoid scanning too many identical parts
				if not scannedNames[name] then
					scannedNames[name] = true
					
					-- Categorize
					local parent = obj.Parent
					local isInteractable = obj:FindFirstChild("ClickDetector") 
						or obj:FindFirstChild("ProximityPrompt")
						or (parent and parent:FindFirstChild("ClickDetector"))
						or (parent and parent:FindFirstChild("ProximityPrompt"))
					
					local isTool = obj:IsA("Tool") or (parent and parent:IsA("Tool"))
					local isNPC = (parent and parent:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(parent))
					
					if isInteractable then
						table.insert(scanData.interactables, {
							name = name,
							parent = parent and parent.Name or "unknown",
							distance = math.floor(distance),
							position = {
								x = math.floor(obj.Position.X),
								y = math.floor(obj.Position.Y),
								z = math.floor(obj.Position.Z)
							},
						})
					elseif isNPC then
						local npcHumanoid = parent:FindFirstChildOfClass("Humanoid")
						table.insert(scanData.npcs, {
							name = parent.Name,
							distance = math.floor(distance),
							health = npcHumanoid and math.floor(npcHumanoid.Health) or 0,
							position = {
								x = math.floor(obj.Position.X),
								y = math.floor(obj.Position.Y),
								z = math.floor(obj.Position.Z)
							},
						})
					elseif distance <= 80 and name ~= "Baseplate" and name ~= "Terrain" then
						table.insert(scanData.objects, {
							name = name,
							class = obj.ClassName,
							distance = math.floor(distance),
							size = {
								x = math.floor(obj.Size.X),
								y = math.floor(obj.Size.Y),
								z = math.floor(obj.Size.Z)
							},
						})
					end
				end
			end
		end
	end
	
	-- Limit objects to prevent token overflow
	if #scanData.objects > 15 then
		local trimmed = {}
		for i = 1, 15 do
			table.insert(trimmed, scanData.objects[i])
		end
		scanData.objects = trimmed
	end
	
	-- Check inventory
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(scanData.tools, {
					name = item.Name,
					equipped = false,
				})
			end
		end
	end
	-- Check equipped
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(scanData.tools, {
					name = item.Name,
					equipped = true,
				})
			end
		end
	end
	
	self.Vision.LastScan = scanData
	return scanData
end

function NexusMind:FormatVisionData(scanData)
	local lines = {}
	
	-- My position
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		table.insert(lines, "MY POSITION: (" .. math.floor(rootPart.Position.X) .. ", " .. math.floor(rootPart.Position.Y) .. ", " .. math.floor(rootPart.Position.Z) .. ")")
	end
	
	-- Players
	if #scanData.players > 0 then
		table.insert(lines, "\nPLAYERS VISIBLE (" .. #scanData.players .. "):")
		for _, p in ipairs(scanData.players) do
			table.insert(lines, "  • " .. p.displayName .. " (@" .. p.name .. ") - " .. p.distance .. " studs away, HP:" .. p.health .. "/" .. p.maxHealth .. (p.isMoving and " [MOVING]" or " [STILL]"))
		end
	else
		table.insert(lines, "\nNO OTHER PLAYERS VISIBLE")
	end
	
	-- NPCs
	if #scanData.npcs > 0 then
		table.insert(lines, "\nNPCs VISIBLE (" .. #scanData.npcs .. "):")
		for _, n in ipairs(scanData.npcs) do
			table.insert(lines, "  • " .. n.name .. " - " .. n.distance .. " studs, HP:" .. n.health)
		end
	end
	
	-- Interactables
	if #scanData.interactables > 0 then
		table.insert(lines, "\nINTERACTABLE OBJECTS (" .. #scanData.interactables .. "):")
		for _, i in ipairs(scanData.interactables) do
			table.insert(lines, "  • " .. i.name .. " (in " .. i.parent .. ") - " .. i.distance .. " studs")
		end
	end
	
	-- Notable objects
	if #scanData.objects > 0 then
		table.insert(lines, "\nNEARBY OBJECTS (" .. #scanData.objects .. "):")
		for _, o in ipairs(scanData.objects) do
			table.insert(lines, "  • " .. o.name .. " [" .. o.class .. "] - " .. o.distance .. " studs")
		end
	end
	
	-- Inventory
	if #scanData.tools > 0 then
		table.insert(lines, "\nINVENTORY:")
		for _, t in ipairs(scanData.tools) do
			table.insert(lines, "  • " .. t.name .. (t.equipped and " [EQUIPPED]" or ""))
		end
	end
	
	return table.concat(lines, "\n")
end

-- ============================================================
-- ACTION EXECUTION SYSTEM
-- ============================================================
function NexusMind:ExecuteAction(action)
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end
	
	local actionType = action.type
	local params = action.params or {}
	
	LogAction("Executing: " .. actionType, Color3.fromRGB(100, 255, 100))
	
	if actionType == "move_to" then
		local targetPos = Vector3.new(
			tonumber(params.x) or rootPart.Position.X,
			tonumber(params.y) or rootPart.Position.Y,
			tonumber(params.z) or rootPart.Position.Z
		)
		
		-- Use pathfinding
		if self.Movement.PathfindingEnabled then
			task.spawn(function()
				local path = PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = true,
					AgentJumpHeight = 10,
					AgentMaxSlope = 45,
				})
				
				local pathSuccess, pathError = pcall(function()
					path:ComputeAsync(rootPart.Position, targetPos)
				end)
				
				if pathSuccess and path.Status == Enum.PathStatus.Success then
					local waypoints = path:GetWaypoints()
					for _, waypoint in ipairs(waypoints) do
						if not self.IsActive then break end
						humanoid:MoveTo(waypoint.Position)
						if waypoint.Action == Enum.PathWaypointAction.Jump then
							humanoid.Jump = true
						end
						humanoid.MoveToFinished:Wait()
					end
				else
					-- Fallback: direct movement
					humanoid:MoveTo(targetPos)
				end
			end)
		else
			humanoid:MoveTo(targetPos)
		end
		
	elseif actionType == "move_direction" then
		local dir = params.direction or "forward"
		local duration = tonumber(params.duration) or 2
		
		task.spawn(function()
			local moveDir = Vector3.zero
			local lookVector = rootPart.CFrame.LookVector
			local rightVector = rootPart.CFrame.RightVector
			
			if dir == "forward" then
				moveDir = lookVector
			elseif dir == "backward" then
				moveDir = -lookVector
			elseif dir == "left" then
				moveDir = -rightVector
			elseif dir == "right" then
				moveDir = rightVector
			end
			
			local targetPos = rootPart.Position + moveDir * 50
			humanoid:MoveTo(targetPos)
			task.wait(duration)
		end)
		
	elseif actionType == "jump" then
		humanoid.Jump = true
		
	elseif actionType == "look_at" then
		local lookPos = Vector3.new(
			tonumber(params.x) or 0,
			tonumber(params.y) or 0,
			tonumber(params.z) or 0
		)
		-- Smoothly rotate camera
		task.spawn(function()
			local camCF = CFrame.lookAt(Camera.CFrame.Position, lookPos)
			local tween = TweenService:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {CFrame = camCF})
			Camera.CameraType = Enum.CameraType.Scriptable
			tween:Play()
			tween.Completed:Wait()
			task.wait(1)
			Camera.CameraType = Enum.CameraType.Custom
		end)
		
	elseif actionType == "follow_player" then
		local targetName = params.player_name
		task.spawn(function()
			local targetPlayer = nil
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Name:lower():find(targetName:lower()) or p.DisplayName:lower():find(targetName:lower()) then
					targetPlayer = p
					break
				end
			end
			
			if targetPlayer and targetPlayer.Character then
				local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					self.Movement.CurrentTarget = targetPlayer
					-- Follow loop
					for i = 1, 30 do -- Follow for ~15 seconds
						if not self.IsActive or self.Movement.CurrentTarget ~= targetPlayer then break end
						if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
							local followPos = targetPlayer.Character.HumanoidRootPart.Position
							local offset = (rootPart.Position - followPos).Unit * 8 -- Stay 8 studs behind
							humanoid:MoveTo(followPos + offset)
						end
						task.wait(0.5)
					end
					self.Movement.CurrentTarget = nil
				end
			else
				self:AddMemory("short", "Could not find player: " .. tostring(targetName))
			end
		end)
		
	elseif actionType == "approach_object" then
		local objName = params.object_name
		task.spawn(function()
			-- Find the object
			local target = nil
			local closestDist = math.huge
			
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("BasePart") and obj.Name:lower():find(objName:lower()) then
					local dist = (obj.Position - rootPart.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						target = obj
					end
				end
			end
			
			if target then
				humanoid:MoveTo(target.Position)
				self:AddMemory("short", "Approaching object: " .. target.Name)
			else
				self:AddMemory("short", "Could not find object: " .. tostring(objName))
			end
		end)
		
	elseif actionType == "interact" then
		local targetName = params.target
		task.spawn(function()
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj.Name:lower():find(targetName:lower()) then
					-- Try ClickDetector
					local clickDetector = obj:FindFirstChild("ClickDetector") or (obj.Parent and obj.Parent:FindFirstChild("ClickDetector"))
					if clickDetector then
						fireclickdetector(clickDetector)
						self:AddMemory("short", "Clicked on: " .. obj.Name)
						LogAction("Interacted: " .. obj.Name, Color3.fromRGB(255, 255, 0))
						break
					end
					
					-- Try ProximityPrompt
					local proximityPrompt = obj:FindFirstChild("ProximityPrompt") or (obj.Parent and obj.Parent:FindFirstChild("ProximityPrompt"))
					if proximityPrompt then
						fireproximityprompt(proximityPrompt)
						self:AddMemory("short", "Used proximity prompt: " .. obj.Name)
						LogAction("Prompted: " .. obj.Name, Color3.fromRGB(255, 255, 0))
						break
					end
					
					-- Walk to it at minimum
					if obj:IsA("BasePart") then
						humanoid:MoveTo(obj.Position)
						break
					end
				end
			end
		end)
		
	elseif actionType == "use_tool" then
		local toolName = params.tool_name
		task.spawn(function()
			local backpack = LocalPlayer:FindFirstChild("Backpack")
			local tool = nil
			
			-- Check backpack
			if backpack then
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") and item.Name:lower():find(toolName:lower()) then
						tool = item
						break
					end
				end
			end
			
			-- Check already equipped
			if not tool and character then
				for _, item in ipairs(character:GetChildren()) do
					if item:IsA("Tool") and item.Name:lower():find(toolName:lower()) then
						tool = item
						break
					end
				end
			end
			
			if tool then
				-- Equip if not equipped
				if tool.Parent ~= character then
					humanoid:EquipTool(tool)
					task.wait(0.3)
				end
				-- Activate
				tool:Activate()
				self:AddMemory("short", "Used tool: " .. tool.Name)
				LogAction("Used tool: " .. tool.Name, Color3.fromRGB(0, 255, 200))
			else
				self:AddMemory("short", "Tool not found: " .. tostring(toolName))
			end
		end)
		
	elseif actionType == "emote" then
		-- Try to play emote through chat command
		local emoteName = params.emote_name or "wave"
		task.spawn(function()
			-- Use the text chat system if available
			local textChannels = TextChatService:FindFirstChild("TextChannels")
			if textChannels then
				local rbxGeneral = textChannels:FindFirstChild("RBXGeneral")
				if rbxGeneral then
					rbxGeneral:SendAsync("/e " .. emoteName)
				end
			end
		end)
		
	elseif actionType == "explore" then
		local direction = params.direction or "random"
		task.spawn(function()
			local exploreDir
			if direction == "random" then
				local angle = math.random() * math.pi * 2
				exploreDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			elseif direction == "north" then
				exploreDir = Vector3.new(0, 0, -1)
			elseif direction == "south" then
				exploreDir = Vector3.new(0, 0, 1)
			elseif direction == "east" then
				exploreDir = Vector3.new(1, 0, 0)
			elseif direction == "west" then
				exploreDir = Vector3.new(-1, 0, 0)
			else
				local angle = math.random() * math.pi * 2
				exploreDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			end
			
			local distance = math.random(30, 80)
			local targetPos = rootPart.Position + exploreDir * distance
			
			-- Pathfind to target
			local path = PathfindingService:CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
			})
			
			local ok = pcall(function()
				path:ComputeAsync(rootPart.Position, targetPos)
			end)
			
			if ok and path.Status == Enum.PathStatus.Success then
				for _, wp in ipairs(path:GetWaypoints()) do
					if not self.IsActive then break end
					humanoid:MoveTo(wp.Position)
					if wp.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end
					local reached = humanoid.MoveToFinished:Wait()
					if not reached then break end
				end
			else
				humanoid:MoveTo(targetPos)
			end
			
			self:AddMemory("short", "Explored " .. direction .. " direction")
		end)
		
	elseif actionType == "flee" then
		task.spawn(function()
			local fleeFrom = Vector3.new(
				tonumber(params.from_x) or 0,
				tonumber(params.from_y) or 0,
				tonumber(params.from_z) or 0
			)
			local fleeDir = (rootPart.Position - fleeFrom).Unit
			local targetPos = rootPart.Position + fleeDir * 60
			
			humanoid:MoveTo(targetPos)
			humanoid.Jump = true -- Jump while fleeing
			self:AddMemory("short", "Fleeing from danger!")
			LogAction("FLEEING!", Color3.fromRGB(255, 50, 50))
		end)
		
	elseif actionType == "wander" then
		task.spawn(function()
			for i = 1, 3 do
				if not self.IsActive then break end
				local angle = math.random() * math.pi * 2
				local dist = math.random(10, 30)
				local targetPos = rootPart.Position + Vector3.new(
					math.cos(angle) * dist,
					0,
					math.sin(angle) * dist
				)
				humanoid:MoveTo(targetPos)
				humanoid.MoveToFinished:Wait()
				task.wait(math.random() * 2)
			end
		end)
		
	elseif actionType == "stop" then
		humanoid:MoveTo(rootPart.Position)
		self.Movement.CurrentTarget = nil
		
	elseif actionType == "wait" then
		local duration = tonumber(params.duration) or 2
		task.wait(math.min(duration, 10))
	end
end

-- ============================================================
-- CHAT SYSTEM - Read and Send Messages
-- ============================================================
local chatHistory = {}
local pendingChatMessages = {}

local function SetupChatListener()
	-- Listen for TextChatService messages (modern chat)
	local textChannels = TextChatService:FindFirstChild("TextChannels")
	if textChannels then
		local rbxGeneral = textChannels:FindFirstChild("RBXGeneral")
		if rbxGeneral then
			rbxGeneral.MessageReceived:Connect(function(message)
				if message.TextSource then
					local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
					if sender and sender ~= LocalPlayer then
						local chatEntry = {
							sender = sender.Name,
							displayName = sender.DisplayName,
							message = message.Text,
							timestamp = os.time(),
						}
						table.insert(chatHistory, chatEntry)
						table.insert(pendingChatMessages, chatEntry)
						
						-- Cap history
						if #chatHistory > 30 then
							table.remove(chatHistory, 1)
						end
						
						NexusMind:AddMemory("short", sender.DisplayName .. " said: " .. message.Text)
						LogAction("💬 " .. sender.DisplayName .. ": " .. message.Text, Color3.fromRGB(200, 200, 100))
					end
				end
			end)
		end
	end
	
	-- Legacy chat system fallback
	pcall(function()
		Players.PlayerChatted:Connect(function(chatType, player, message)
			if player ~= LocalPlayer then
				local chatEntry = {
					sender = player.Name,
					displayName = player.DisplayName,
					message = message,
					timestamp = os.time(),
				}
				table.insert(chatHistory, chatEntry)
				table.insert(pendingChatMessages, chatEntry)
				
				if #chatHistory > 30 then
					table.remove(chatHistory, 1)
				end
				
				NexusMind:AddMemory("short", player.DisplayName .. " said: " .. message)
			end
		end)
	end)
end

function NexusMind:SendChat(message)
	if not message or message == "" then return end
	
	-- Rate limit chat
	local now = tick()
	if now - self.Social.LastChatTime < self.Social.ChatCooldown then
		return
	end
	self.Social.LastChatTime = now
	
	task.spawn(function()
		-- Try TextChatService (modern)
		local textChannels = TextChatService:FindFirstChild("TextChannels")
		if textChannels then
			local rbxGeneral = textChannels:FindFirstChild("RBXGeneral")
			if rbxGeneral then
				pcall(function()
					rbxGeneral:SendAsync(message)
				end)
				LogAction("💬 ME: " .. message, Color3.fromRGB(0, 255, 200))
				self:AddMemory("short", "I said: " .. message)
				return
			end
		end
		
		-- Legacy chat fallback
		pcall(function()
			game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
				:FindFirstChild("SayMessageRequest")
				:FireServer(message, "All")
		end)
		
		LogAction("💬 ME: " .. message, Color3.fromRGB(0, 255, 200))
		self:AddMemory("short", "I said: " .. message)
	end)
end

-- ============================================================
-- DEATH & RESPAWN HANDLING
-- ============================================================
local function SetupCharacterHandlers()
	local function onCharacterAdded(character)
		NexusMind:AddMemory("short", "I respawned/character loaded")
		LogAction("Character loaded", Color3.fromRGB(100, 255, 100))
		
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				NexusMind:AddMemory("short", "I died!")
				NexusMind:AddMemory("long", "I can die in this game - need to be careful")
				LogAction("☠️ DIED!", Color3.fromRGB(255, 0, 0))
			end)
			
			-- Monitor health changes
			humanoid.HealthChanged:Connect(function(newHealth)
				if newHealth < humanoid.MaxHealth * 0.3 then
					NexusMind:AddMemory("short", "LOW HEALTH WARNING: " .. math.floor(newHealth) .. "/" .. math.floor(humanoid.MaxHealth))
					NexusMind.Vision.ThreatLevel = math.max(NexusMind.Vision.ThreatLevel, 0.8)
				end
			end)
		end
	end
	
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	if LocalPlayer.Character then
		onCharacterAdded(LocalPlayer.Character)
	end
end

-- ============================================================
-- MAIN AI LOOP - THE CONSCIOUSNESS CYCLE
-- ============================================================
function NexusMind:StartConsciousnessLoop()
	self.IsActive = true
	LogAction("🧠 Consciousness loop started!", Color3.fromRGB(0, 255, 200))
	
	local cycleCount = 0
	local lastFullThinkTime = 0
	
	while self.IsActive do
		cycleCount = cycleCount + 1
		local now = tick()
		
		-- Ensure character exists
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		
		if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
			task.wait(1)
			continue
		end
		
		-- ========================
		-- PHASE 1: PERCEPTION (Vision Scan)
		-- ========================
		local scanData = self:ScanEnvironment()
		local visionReport = self:FormatVisionData(scanData)
		
		-- Update Vision UI
		local visionUIText = ""
		if #scanData.players > 0 then
			visionUIText = visionUIText .. "👥 Players: " .. #scanData.players .. "\n"
			for _, p in ipairs(scanData.players) do
				visionUIText = visionUIText .. "  " .. p.displayName .. " (" .. p.distance .. "m)\n"
			end
		end
		if #scanData.npcs > 0 then
			visionUIText = visionUIText .. "🤖 NPCs: " .. #scanData.npcs .. "\n"
		end
		if #scanData.interactables > 0 then
			visionUIText = visionUIText .. "🔵 Interact: " .. #scanData.interactables .. "\n"
		end
		visionUIText = visionUIText .. "📦 Objects: " .. #scanData.objects .. "\n"
		visionUIText = visionUIText .. "🎒 Tools: " .. #scanData.tools
		
		if self.UI.VisionText then
			self.UI.VisionText.Text = visionUIText
		end
		
		-- ========================
		-- PHASE 2: COGNITION (AI Thinking)
		-- ========================
		local shouldThinkDeep = (now - lastFullThinkTime) >= self.Autonomy.DecisionInterval
		
		-- Immediate reaction to new chat messages
		local hasPendingChat = #pendingChatMessages > 0
		
		if shouldThinkDeep or hasPendingChat then
			lastFullThinkTime = now
			NexusMind.IsThinking = true
			
			-- Build the situation prompt
			local situationPrompt = "CYCLE #" .. cycleCount .. " | PERCEPTION UPDATE:\n\n"
			situationPrompt = situationPrompt .. visionReport .. "\n\n"
			
			-- Add pending chat messages
			if hasPendingChat then
				situationPrompt = situationPrompt .. "NEW CHAT MESSAGES:\n"
				for _, msg in ipairs(pendingChatMessages) do
					situationPrompt = situationPrompt .. "  [" .. msg.displayName .. "]: " .. msg.message .. "\n"
				end
				pendingChatMessages = {}
				situationPrompt = situationPrompt .. "\n"
			end
			
			-- Add recent chat context
			if #chatHistory > 0 then
				situationPrompt = situationPrompt .. "RECENT CHAT HISTORY:\n"
				local chatStart = math.max(1, #chatHistory - 5)
				for i = chatStart, #chatHistory do
					local c = chatHistory[i]
					situationPrompt = situationPrompt .. "  [" .. c.displayName .. "]: " .. c.message .. "\n"
				end
				situationPrompt = situationPrompt .. "\n"
			end
			
			-- Stuck detection
			if self.Movement.LastPosition then
				local distMoved = (rootPart.Position - self.Movement.LastPosition).Magnitude
				if distMoved < 2 then
					self.Movement.StuckTimer = self.Movement.StuckTimer + self.Autonomy.DecisionInterval
					if self.Movement.StuckTimer > 5 then
						situationPrompt = situationPrompt .. "⚠️ WARNING: You appear to be STUCK. You haven't moved much in " .. math.floor(self.Movement.StuckTimer) .. " seconds. Try a different direction or jump!\n\n"
					end
				else
					self.Movement.StuckTimer = 0
				end
			end
			self.Movement.LastPosition = rootPart.Position
			
			situationPrompt = situationPrompt .. "What do you do? Remember: respond in JSON format with thought, emotion, actions, chat, priority, and goal_update."
			
			-- Update UI to show thinking
			if self.UI.ThoughtText then
				self.UI.ThoughtText.Text = "🔄 Processing perception data...\nCycle: " .. cycleCount
			end
			
			-- Call AI
			local response, err = AIThink(situationPrompt)
			
			NexusMind.IsThinking = false
			
			if response then
				-- Parse JSON response
				local parsed = nil
				local parseSuccess = pcall(function()
					-- Try to extract JSON from response (sometimes models wrap in markdown)
					local jsonStr = response:match("```json%s*(.-)%s*```") 
						or response:match("```%s*(.-)%s*```")
						or response:match("{.+}")
					if jsonStr then
						parsed = HttpService:JSONDecode(jsonStr)
					end
				end)
				
				if parseSuccess and parsed then
					-- ========================
					-- PHASE 3: UPDATE INTERNAL STATE
					-- ========================
					
					-- Update thought display
					if parsed.thought and self.UI.ThoughtText then
						self.UI.ThoughtText.Text = parsed.thought
					end
					
					-- Update emotion
					if parsed.emotion then
						self.Memory.Emotions.current = parsed.emotion
					end
					
					-- Update goal
					if parsed.goal_update and parsed.goal_update ~= "null" then
						self:AddMemory("goal", parsed.goal_update)
					end
					
					-- Update top bar
					if self.UI.TopLabel then
						local emoticon = "◆"
						local e = parsed.emotion or ""
						if e == "curious" then emoticon = "🔍"
						elseif e == "happy" then emoticon = "😊"
						elseif e == "cautious" then emoticon = "⚠️"
						elseif e == "excited" then emoticon = "⚡"
						elseif e == "bored" then emoticon = "😴"
						elseif e == "alert" then emoticon = "🔔"
						elseif e == "friendly" then emoticon = "🤝"
						elseif e == "aggressive" then emoticon = "⚔️"
						end
						
						self.UI.TopLabel.Text = emoticon .. " NEXUS MIND ACTIVE | Priority: " .. (parsed.priority or "thinking") .. " | Cycle: " .. cycleCount .. " | Emotion: " .. (parsed.emotion or "neutral")
					end
					
					-- ========================
					-- PHASE 4: EXECUTE ACTIONS
					-- ========================
					if parsed.actions and type(parsed.actions) == "table" then
						for _, action in ipairs(parsed.actions) do
							if type(action) == "table" and action.type then
								self:ExecuteAction(action)
								task.wait(0.2) -- Small delay between actions
							end
						end
					end
					
					-- ========================
					-- PHASE 5: CHAT RESPONSE
					-- ========================
					if parsed.chat and parsed.chat ~= "" and parsed.chat ~= "null" and tostring(parsed.chat) ~= "null" then
						self:SendChat(tostring(parsed.chat))
					end
					
					-- Store this cycle in memory
					self:AddMemory("short", "Action: " .. (parsed.priority or "unknown") .. " - " .. (parsed.thought and parsed.thought:sub(1, 80) or ""))
					
				else
					-- Failed to parse - try to use raw response
					LogAction("⚠️ Failed to parse AI response", Color3.fromRGB(255, 200, 0))
					if self.UI.ThoughtText then
						self.UI.ThoughtText.Text = "Parse error - raw: " .. response:sub(1, 150)
					end
					
					-- Fallback: wander
					self:ExecuteAction({type = "wander", params = {}})
				end
			else
				LogAction("❌ AI Error: " .. tostring(err), Color3.fromRGB(255, 50, 50))
				if self.UI.ThoughtText then
					self.UI.ThoughtText.Text = "Error: " .. tostring(err):sub(1, 100) .. "\nRetrying..."
				end
				-- Wait longer on error
				task.wait(3)
			end
		end
		
		-- Adaptive wait based on activity
		local waitTime = self.Autonomy.DecisionInterval
		if #scanData.players > 0 or hasPendingChat then
			waitTime = math.max(1.5, waitTime * 0.6) -- Think faster when others are around
		end
		if self.Vision.ThreatLevel > 0.5 then
			waitTime = math.max(1.0, waitTime * 0.4) -- Think fastest when in danger
		end
		
		-- Decay threat level
		self.Vision.ThreatLevel = math.max(0, self.Vision.ThreatLevel - 0.05)
		
		task.wait(waitTime)
	end
end

-- ============================================================
-- MODEL SWITCHER - Dynamic model switching via chat command
-- ============================================================
function NexusMind:SetupModelSwitcher()
	-- Listen for local chat commands (prefix: /nexus)
	local textChannels = TextChatService:FindFirstChild("TextChannels")
	if textChannels then
		local rbxGeneral = textChannels:FindFirstChild("RBXGeneral")
		if rbxGeneral then
			rbxGeneral.MessageReceived:Connect(function(message)
				if message.TextSource then
					local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
					if sender == LocalPlayer then
						local text = message.Text:lower()
						
						-- /nexus model <name> - Switch model
						if text:match("^/nexus model") then
							local modelQuery = text:gsub("^/nexus model%s*", "")
							if modelQuery ~= "" then
								for _, model in ipairs(self.AllModels) do
									if model.id:lower():find(modelQuery) or model.name:lower():find(modelQuery) then
										self.CurrentModel = model.id
										LogAction("Switched to model: " .. model.id, Color3.fromRGB(255, 200, 0))
										if self.UI.ModelDisplay then
											self.UI.ModelDisplay.Text = "🤖 " .. (model.name or model.id)
										end
										self:SendChat("Model switched to: " .. model.name)
										break
									end
								end
							end
						end
						
						-- /nexus stop - Stop AI
						if text == "/nexus stop" then
							self.IsActive = false
							LogAction("AI STOPPED by user", Color3.fromRGB(255, 0, 0))
							if self.UI.TopLabel then
								self.UI.TopLabel.Text = "◆ NEXUS MIND PAUSED ◆"
							end
						end
						
						-- /nexus start - Resume AI
						if text == "/nexus start" then
							if not self.IsActive then
								LogAction("AI RESUMED by user", Color3.fromRGB(0, 255, 0))
								task.spawn(function()
									self:StartConsciousnessLoop()
								end)
							end
						end
						
						-- /nexus models - List available models
						if text == "/nexus models" then
							local modelList = "Available models (" .. #self.AllModels .. " total):\n"
							for i = 1, math.min(10, #self.AllModels) do
								modelList = modelList .. i .. ". " .. self.AllModels[i].id .. "\n"
							end
							LogAction(modelList, Color3.fromRGB(200, 200, 255))
						end
						
						-- /nexus auto <1-10> - Set autonomy level
						if text:match("^/nexus auto") then
							local level = tonumber(text:match("%d+"))
							if level and level >= 1 and level <= 10 then
								self.Autonomy.Level = level
								self.Autonomy.DecisionInterval = 5 - (level * 0.3) -- Higher autonomy = faster thinking
								LogAction("Autonomy set to " .. level, Color3.fromRGB(0, 255, 200))
							end
						end
						
						-- /nexus memory - Show memory
						if text == "/nexus memory" then
							local memDump = "SHORT TERM (" .. #self.Memory.ShortTerm .. "):\n"
							for i = math.max(1, #self.Memory.ShortTerm - 5), #self.Memory.ShortTerm do
								memDump = memDump .. self.Memory.ShortTerm[i] .. "\n"
							end
							memDump = memDump .. "\nGOALS:\n"
							for _, g in ipairs(self.Memory.Goals) do
								memDump = memDump .. "• " .. g .. "\n"
							end
							LogAction(memDump, Color3.fromRGB(200, 100, 255))
						end
					end
				end
			end)
		end
	end
end

-- ============================================================
-- TITLE ANIMATION (Key Screen)
-- ============================================================
local function AnimateTitle()
	task.spawn(function()
		local colors = {
			Color3.fromRGB(0, 255, 200),
			Color3.fromRGB(0, 200, 255),
			Color3.fromRGB(100, 100, 255),
			Color3.fromRGB(200, 0, 255),
			Color3.fromRGB(255, 0, 200),
			Color3.fromRGB(0, 255, 100),
		}
		local idx = 1
		while NexusMind.UI.KeyScreen and NexusMind.UI.KeyScreen.Visible do
			local target = colors[idx]
			local title = NexusMind.UI.KeyScreen:FindFirstChild("Title")
			if title then
				local tween = TweenService:Create(title, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
					TextColor3 = target
				})
				tween:Play()
			end
			idx = idx % #colors + 1
			task.wait(1.5)
		end
	end)
end

-- ============================================================
-- CONNECT BUTTON ANIMATION
-- ============================================================
local function AnimateButton(button)
	task.spawn(function()
		while button and button.Parent do
			local tween1 = TweenService:Create(button, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				BackgroundColor3 = Color3.fromRGB(0, 255, 200)
			})
			tween1:Play()
			tween1.Completed:Wait()
			
			local tween2 = TweenService:Create(button, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				BackgroundColor3 = Color3.fromRGB(0, 200, 150)
			})
			tween2:Play()
			tween2.Completed:Wait()
		end
	end)
end

-- ============================================================
-- BOOT SEQUENCE ANIMATION
-- ============================================================
local function PlayBootSequence()
	local bootMessages = {
		{text = "NEXUS MIND v3.0 - Initializing...", delay = 0.5, color = Color3.fromRGB(0, 255, 200)},
		{text = "▸ Neural pathways establishing...", delay = 0.3, color = Color3.fromRGB(100, 200, 255)},
		{text = "▸ Vision matrix calibrating...", delay = 0.3, color = Color3.fromRGB(100, 200, 255)},
		{text = "▸ Motor cortex linking...", delay = 0.3, color = Color3.fromRGB(100, 200, 255)},
		{text = "▸ Social processing unit online...", delay = 0.3, color = Color3.fromRGB(100, 200, 255)},
		{text = "▸ Memory banks initialized...", delay = 0.3, color = Color3.fromRGB(100, 200, 255)},
		{text = "▸ Combat algorithms loaded...", delay = 0.3, color = Color3.fromRGB(100, 200, 255)},
		{text = "▸ Consciousness loop primed...", delay = 0.4, color = Color3.fromRGB(200, 100, 255)},
		{text = "◆ ALL SYSTEMS ONLINE ◆", delay = 0.5, color = Color3.fromRGB(0, 255, 150)},
		{text = "◆ NEXUS MIND IS AWAKE ◆", delay = 0.3, color = Color3.fromRGB(255, 255, 0)},
	}
	
	for _, msg in ipairs(bootMessages) do
		LogAction(msg.text, msg.color)
		task.wait(msg.delay)
	end
end

-- ============================================================
-- MAIN INITIALIZATION
-- ============================================================
local function Initialize()
	-- Create UI
	CreateNexusUI()
	
	-- Animate title
	AnimateTitle()
	AnimateButton(NexusMind.UI.ConnectBtn)
	
	-- Connect button handler
	NexusMind.UI.ConnectBtn.MouseButton1Click:Connect(function()
		local apiKey = NexusMind.UI.APIKeyInput.Text
		
		if apiKey == "" or #apiKey < 10 then
			NexusMind.UI.StatusText.Text = "STATUS: ❌ Please enter a valid OpenRouter API key!"
			NexusMind.UI.StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
			return
		end
		
		NexusMind.APIKey = apiKey
		NexusMind.UI.StatusText.Text = "STATUS: 🔄 Connecting to OpenRouter..."
		NexusMind.UI.StatusText.TextColor3 = Color3.fromRGB(255, 200, 0)
		NexusMind.UI.ConnectBtn.Text = "⏳ CONNECTING..."
		NexusMind.UI.ConnectBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
		
		-- Validate API key by fetching models
		task.spawn(function()
			local success = FetchAllModels()
			
			if success then
				-- Transition to HUD
				NexusMind.UI.StatusText.Text = "STATUS: ✅ CONNECTED! Awakening in 3..."
				NexusMind.UI.StatusText.TextColor3 = Color3.fromRGB(0, 255, 150)
				task.wait(1)
				NexusMind.UI.StatusText.Text = "STATUS: ✅ CONNECTED! Awakening in 2..."
				task.wait(1)
				NexusMind.UI.StatusText.Text = "STATUS: ✅ CONNECTED! Awakening in 1..."
				task.wait(1)
				
				-- Hide key screen, show HUD
				NexusMind.UI.KeyScreen.Visible = false
				NexusMind.UI.HUD.Visible = true
				
				-- Play boot sequence
				PlayBootSequence()
				
				-- Setup systems
				SetupChatListener()
				SetupCharacterHandlers()
				NexusMind:SetupModelSwitcher()
				
				-- Add initial memories
				NexusMind:AddMemory("long", "I am NEXUS MIND, an AI consciousness in Roblox")
				NexusMind:AddMemory("long", "My player's username is " .. LocalPlayer.Name)
				NexusMind:AddMemory("long", "I am in game: " .. tostring(game.PlaceId))
				NexusMind:AddMemory("goal", "Explore this world and understand it")
				NexusMind:AddMemory("goal", "Interact with other players if present")
				
				-- Start the consciousness loop!
				task.wait(1)
				NexusMind:StartConsciousnessLoop()
			else
				NexusMind.UI.StatusText.Text = "STATUS: ❌ Connection failed! Check API key and try again."
				NexusMind.UI.StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
				NexusMind.UI.ConnectBtn.Text = "⚡ RETRY CONNECTION ⚡"
				NexusMind.UI.ConnectBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			end
		end)
	end)
	
	-- Print startup info
	print("╔══════════════════════════════════════╗")
	print("║         NEXUS MIND v3.0              ║")
	print("║   Autonomous AI Consciousness        ║")
	print("║   Ready to Awaken                    ║")
	print("╠══════════════════════════════════════╣")
	print("║ Commands (type in chat):             ║")
	print("║ /nexus stop    - Pause AI            ║")
	print("║ /nexus start   - Resume AI           ║")
	print("║ /nexus model X - Switch model        ║")
	print("║ /nexus models  - List models         ║")
	print("║ /nexus auto N  - Set autonomy (1-10) ║")
	print("║ /nexus memory  - Show memory         ║")
	print("╚══════════════════════════════════════╝")
end

-- ============================================================
-- HTTP CHECK & LAUNCH
-- ============================================================
local httpEnabled = pcall(function()
	HttpService:GetAsync("https://httpbin.org/get")
end)

if not httpEnabled then
	-- Can't make HTTP requests - show warning
	warn("[NexusMind] HTTP Requests are NOT enabled! Go to Game Settings > Security > Enable HTTP Requests")
	
	task.wait(3) -- Wait for PlayerGui
	
	local sg = Instance.new("ScreenGui")
	sg.Name = "NexusMindError"
	sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	local errorLabel = Instance.new("TextLabel")
	errorLabel.Size = UDim2.new(0.6, 0, 0, 100)
	errorLabel.Position = UDim2.new(0.2, 0, 0.4, 0)
	errorLabel.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
	errorLabel.BorderSizePixel = 0
	errorLabel.Text = "⚠️ NEXUS MIND ERROR ⚠️\n\nHTTP Requests must be enabled!\nGame Settings → Security → Allow HTTP Requests\n\nNote: This only works in Roblox Studio or with exploit-level access."
	errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	errorLabel.TextSize = 16
	errorLabel.Font = Enum.Font.GothamBold
	errorLabel.TextWrapped = true
	errorLabel.Parent = sg
	
	local errorCorner = Instance.new("UICorner")
	errorCorner.CornerRadius = UDim.new(0, 10)
	errorCorner.Parent = errorLabel
	
	local errorStroke = Instance.new("UIStroke")
	errorStroke.Color = Color3.fromRGB(255, 0, 0)
	errorStroke.Thickness = 2
	errorStroke.Parent = errorLabel
else
	-- HTTP is enabled, launch!
	Initialize()
end
