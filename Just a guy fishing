-- StarterPlayerScripts > WEAPON EDITOR
-- Ultra Experimental Weapon Customizer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

-- ============================================================
-- THEME CONFIG
-- ============================================================
local THEME = {
	Background = Color3.fromRGB(15, 15, 25),
	Panel = Color3.fromRGB(22, 22, 38),
	PanelLight = Color3.fromRGB(30, 30, 50),
	Accent = Color3.fromRGB(120, 80, 255),
	AccentGlow = Color3.fromRGB(160, 120, 255),
	AccentSecondary = Color3.fromRGB(255, 60, 120),
	AccentTertiary = Color3.fromRGB(60, 220, 255),
	Text = Color3.fromRGB(240, 240, 255),
	TextDim = Color3.fromRGB(140, 140, 170),
	TextDark = Color3.fromRGB(80, 80, 110),
	Success = Color3.fromRGB(80, 255, 120),
	Warning = Color3.fromRGB(255, 200, 60),
	Error = Color3.fromRGB(255, 60, 80),
	Border = Color3.fromRGB(50, 50, 80),
	SliderTrack = Color3.fromRGB(40, 40, 65),
	SliderFill = Color3.fromRGB(120, 80, 255),
}

local MATERIALS_LIST = {
	"Plastic", "Wood", "Slate", "Concrete", "CorrodedMetal",
	"DiamondPlate", "Foil", "Grass", "Ice", "Marble",
	"Granite", "Brick", "Pebble", "Sand", "Fabric",
	"SmoothPlastic", "Metal", "WoodPlanks", "Cobblestone",
	"Neon", "Glass", "ForceField"
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
	currentTool = nil,
	currentParts = {},
	isOpen = false,
	selectedTab = "Transform",
	activeEffects = {},
	trailEnabled = false,
	particlesEnabled = false,
	glowEnabled = false,
	fireEnabled = false,
	sparklesEnabled = false,
	smokeEnabled = false,
	lightEnabled = false,
	afterimageEnabled = false,
	rainbowEnabled = false,
	pulseEnabled = false,
	spinEnabled = false,
	floatEnabled = false,
	selectedPartIndex = 1,
	history = {},
	historyIndex = 0,
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function Lerp(a, b, t)
	return a + (b - a) * t
end

local function CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function CreateStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0.5
	stroke.Parent = parent
	return stroke
end

local function CreatePadding(parent, padding)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, padding or 8)
	pad.PaddingBottom = UDim.new(0, padding or 8)
	pad.PaddingLeft = UDim.new(0, padding or 8)
	pad.PaddingRight = UDim.new(0, padding or 8)
	pad.Parent = parent
	return pad
end

local function CreateGradient(parent, c1, c2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(c1 or THEME.Accent, c2 or THEME.AccentSecondary)
	gradient.Rotation = rotation or 45
	gradient.Parent = parent
	return gradient
end

local function TweenElement(element, props, duration, style, direction)
	local tween = TweenService:Create(element, TweenInfo.new(
		duration or 0.3,
		style or Enum.EasingStyle.Quart,
		direction or Enum.EasingDirection.Out
	), props)
	tween:Play()
	return tween
end

local function SaveState()
	if not State.currentTool then return end
	local snapshot = {}
	for _, part in ipairs(State.currentParts) do
		if part:IsA("BasePart") then
			table.insert(snapshot, {
				Part = part,
				Size = part.Size,
				Color = part.Color,
				Material = part.Material,
				Transparency = part.Transparency,
				Reflectance = part.Reflectance,
			})
		end
	end
	State.historyIndex = State.historyIndex + 1
	State.history[State.historyIndex] = snapshot
	-- Remove future history
	for i = State.historyIndex + 1, #State.history do
		State.history[i] = nil
	end
end

local function Undo()
	if State.historyIndex < 1 then return end
	local snapshot = State.history[State.historyIndex]
	if snapshot then
		for _, data in ipairs(snapshot) do
			if data.Part and data.Part.Parent then
				data.Part.Size = data.Size
				data.Part.Color = data.Color
				data.Part.Material = data.Material
				data.Part.Transparency = data.Transparency
				data.Part.Reflectance = data.Reflectance
			end
		end
	end
	State.historyIndex = math.max(0, State.historyIndex - 1)
end

-- ============================================================
-- GUI CREATION
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WeaponEditor"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = player.PlayerGui

-- WAITING SCREEN
local WaitingFrame = Instance.new("Frame")
WaitingFrame.Name = "WaitingFrame"
WaitingFrame.Size = UDim2.new(0, 320, 0, 100)
WaitingFrame.Position = UDim2.new(0.5, -160, 0, 50)
WaitingFrame.BackgroundColor3 = THEME.Panel
WaitingFrame.BackgroundTransparency = 0.1
WaitingFrame.Parent = ScreenGui
CreateCorner(WaitingFrame, 12)
CreateStroke(WaitingFrame, THEME.Accent, 1.5, 0.3)

local waitGradientBar = Instance.new("Frame")
waitGradientBar.Name = "GradientBar"
waitGradientBar.Size = UDim2.new(1, 0, 0, 3)
waitGradientBar.Position = UDim2.new(0, 0, 0, 0)
waitGradientBar.BackgroundColor3 = Color3.new(1, 1, 1)
waitGradientBar.BorderSizePixel = 0
waitGradientBar.Parent = WaitingFrame
CreateCorner(waitGradientBar, 12)
CreateGradient(waitGradientBar, THEME.Accent, THEME.AccentSecondary, 0)

local waitIcon = Instance.new("TextLabel")
waitIcon.Name = "Icon"
waitIcon.Size = UDim2.new(0, 40, 0, 40)
waitIcon.Position = UDim2.new(0, 20, 0.5, -20)
waitIcon.BackgroundTransparency = 1
waitIcon.Text = "⚔️"
waitIcon.TextSize = 28
waitIcon.Font = Enum.Font.SourceSans
waitIcon.TextColor3 = THEME.Text
waitIcon.Parent = WaitingFrame

local waitTitle = Instance.new("TextLabel")
waitTitle.Name = "Title"
waitTitle.Size = UDim2.new(1, -80, 0, 24)
waitTitle.Position = UDim2.new(0, 70, 0, 20)
waitTitle.BackgroundTransparency = 1
waitTitle.Text = "WEAPON EDITOR"
waitTitle.TextSize = 16
waitTitle.Font = Enum.Font.GothamBold
waitTitle.TextColor3 = THEME.Text
waitTitle.TextXAlignment = Enum.TextXAlignment.Left
waitTitle.Parent = WaitingFrame

local waitSubtitle = Instance.new("TextLabel")
waitSubtitle.Name = "Subtitle"
waitSubtitle.Size = UDim2.new(1, -80, 0, 20)
waitSubtitle.Position = UDim2.new(0, 70, 0, 48)
waitSubtitle.BackgroundTransparency = 1
waitSubtitle.Text = "Equip a tool to begin editing..."
waitSubtitle.TextSize = 13
waitSubtitle.Font = Enum.Font.Gotham
waitSubtitle.TextColor3 = THEME.TextDim
waitSubtitle.TextXAlignment = Enum.TextXAlignment.Left
waitSubtitle.Parent = WaitingFrame

-- Pulsing dot
local waitDot = Instance.new("Frame")
waitDot.Name = "PulseDot"
waitDot.Size = UDim2.new(0, 8, 0, 8)
waitDot.Position = UDim2.new(0, 58, 0.5, -4)
waitDot.BackgroundColor3 = THEME.AccentTertiary
waitDot.Parent = WaitingFrame
CreateCorner(waitDot, 4)

spawn(function()
	while WaitingFrame.Parent do
		TweenElement(waitDot, {BackgroundTransparency = 0.8}, 0.8)
		wait(0.8)
		TweenElement(waitDot, {BackgroundTransparency = 0}, 0.8)
		wait(0.8)
	end
end)

-- ============================================================
-- MAIN EDITOR FRAME
-- ============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainEditor"
MainFrame.Size = UDim2.new(0, 440, 0, 620)
MainFrame.Position = UDim2.new(1, -460, 0.5, -310)
MainFrame.BackgroundColor3 = THEME.Background
MainFrame.BackgroundTransparency = 0.05
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
CreateCorner(MainFrame, 14)
CreateStroke(MainFrame, THEME.Border, 1, 0.4)

-- Shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 40, 1, 40)
shadow.Position = UDim2.new(0, -20, 0, -20)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ZIndex = -1
shadow.Parent = MainFrame

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 56)
TopBar.BackgroundColor3 = THEME.Panel
TopBar.BackgroundTransparency = 0.3
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
CreateCorner(TopBar, 14)

-- Fix bottom corners of topbar
local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 16)
topBarFix.Position = UDim2.new(0, 0, 1, -16)
topBarFix.BackgroundColor3 = THEME.Panel
topBarFix.BackgroundTransparency = 0.3
topBarFix.BorderSizePixel = 0
topBarFix.Parent = TopBar

-- Accent line
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 1, -2)
accentLine.BackgroundColor3 = Color3.new(1, 1, 1)
accentLine.BorderSizePixel = 0
accentLine.Parent = TopBar
CreateGradient(accentLine, THEME.Accent, THEME.AccentSecondary, 0)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 200, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚔️ WEAPON EDITOR"
titleLabel.TextSize = 17
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = THEME.Text
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = TopBar

local toolNameLabel = Instance.new("TextLabel")
toolNameLabel.Name = "ToolName"
toolNameLabel.Size = UDim2.new(0, 180, 0, 20)
toolNameLabel.Position = UDim2.new(0, 16, 0, 34)
toolNameLabel.BackgroundTransparency = 1
toolNameLabel.Text = "No tool equipped"
toolNameLabel.TextSize = 11
toolNameLabel.Font = Enum.Font.Gotham
toolNameLabel.TextColor3 = THEME.AccentTertiary
toolNameLabel.TextXAlignment = Enum.TextXAlignment.Left
toolNameLabel.Parent = TopBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -46, 0, 10)
closeBtn.BackgroundColor3 = THEME.Error
closeBtn.BackgroundTransparency = 0.85
closeBtn.Text = "✕"
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = THEME.Error
closeBtn.Parent = TopBar
CreateCorner(closeBtn, 8)

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 36, 0, 36)
minimizeBtn.Position = UDim2.new(1, -86, 0, 10)
minimizeBtn.BackgroundColor3 = THEME.Warning
minimizeBtn.BackgroundTransparency = 0.85
minimizeBtn.Text = "—"
minimizeBtn.TextSize = 16
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextColor3 = THEME.Warning
minimizeBtn.Parent = TopBar
CreateCorner(minimizeBtn, 8)

-- Undo button
local undoBtn = Instance.new("TextButton")
undoBtn.Name = "UndoBtn"
undoBtn.Size = UDim2.new(0, 36, 0, 36)
undoBtn.Position = UDim2.new(1, -126, 0, 10)
undoBtn.BackgroundColor3 = THEME.AccentTertiary
undoBtn.BackgroundTransparency = 0.85
undoBtn.Text = "↩"
undoBtn.TextSize = 18
undoBtn.Font = Enum.Font.GothamBold
undoBtn.TextColor3 = THEME.AccentTertiary
undoBtn.Parent = TopBar
CreateCorner(undoBtn, 8)

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -20, 0, 38)
TabBar.Position = UDim2.new(0, 10, 0, 62)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = TabBar

local TABS = {"Transform", "Appearance", "Effects", "Animation", "Presets"}
local TAB_ICONS = {
	Transform = "📐",
	Appearance = "🎨",
	Effects = "✨",
	Animation = "🔄",
	Presets = "💾"
}
local tabButtons = {}

-- Content Area
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -20, 1, -110)
ContentArea.Position = UDim2.new(0, 10, 0, 105)
ContentArea.BackgroundColor3 = THEME.Panel
ContentArea.BackgroundTransparency = 0.5
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 4
ContentArea.ScrollBarImageColor3 = THEME.Accent
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = MainFrame
CreateCorner(ContentArea, 10)
CreatePadding(ContentArea, 10)

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = ContentArea

-- ============================================================
-- UI COMPONENT BUILDERS
-- ============================================================

local function CreateSectionHeader(parent, text, order)
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.LayoutOrder = order or 0
	header.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "  " .. text
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = THEME.Accent
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -10, 0, 1)
	line.Position = UDim2.new(0, 5, 1, -1)
	line.BackgroundColor3 = THEME.Accent
	line.BackgroundTransparency = 0.7
	line.BorderSizePixel = 0
	line.Parent = header

	return header
end

local function CreateSlider(parent, label, min, max, default, increment, order, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 52)
	container.BackgroundColor3 = THEME.PanelLight
	container.BackgroundTransparency = 0.4
	container.LayoutOrder = order or 0
	container.Parent = parent
	CreateCorner(container, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 12, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = label
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextColor3 = THEME.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = container

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.5, -12, 0, 20)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 4)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default)
	valueLabel.TextSize = 12
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextColor3 = THEME.AccentTertiary
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = container

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 8)
	track.Position = UDim2.new(0, 12, 0, 32)
	track.BackgroundColor3 = THEME.SliderTrack
	track.BorderSizePixel = 0
	track.Parent = container
	CreateCorner(track, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = track
	CreateCorner(fill, 4)
	CreateGradient(fill, THEME.Accent, THEME.AccentSecondary, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
	knob.BackgroundColor3 = THEME.Text
	knob.ZIndex = 5
	knob.Parent = track
	CreateCorner(knob, 8)
	CreateStroke(knob, THEME.Accent, 2, 0)

	local dragging = false
	local currentValue = default

	local function updateSlider(input)
		local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local rawValue = Lerp(min, max, relX)
		if increment then
			rawValue = math.floor(rawValue / increment + 0.5) * increment
		end
		rawValue = math.clamp(rawValue, min, max)
		currentValue = rawValue

		local frac = (rawValue - min) / (max - min)
		fill.Size = UDim2.new(frac, 0, 1, 0)
		knob.Position = UDim2.new(frac, -8, 0.5, -8)

		if increment and increment >= 1 then
			valueLabel.Text = tostring(math.floor(rawValue))
		else
			valueLabel.Text = string.format("%.2f", rawValue)
		end

		if callback then
			callback(rawValue)
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			SaveState()
			updateSlider(input)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			SaveState()
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return container, function() return currentValue end
end

local function CreateColorPicker(parent, label, default, order, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 130)
	container.BackgroundColor3 = THEME.PanelLight
	container.BackgroundTransparency = 0.4
	container.LayoutOrder = order or 0
	container.Parent = parent
	CreateCorner(container, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 0, 24)
	nameLabel.Position = UDim2.new(0, 12, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = label
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextColor3 = THEME.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = container

	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(0, 30, 0, 18)
	preview.Position = UDim2.new(1, -44, 0, 6)
	preview.BackgroundColor3 = default or Color3.new(1, 1, 1)
	preview.Parent = container
	CreateCorner(preview, 4)
	CreateStroke(preview, THEME.Border, 1, 0.3)

	-- RGB Sliders
	local currentColor = default or Color3.new(1, 1, 1)
	local sliders = {}
	local channelNames = {"R", "G", "B"}
	local channelColors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(80, 255, 80),
		Color3.fromRGB(80, 120, 255)
	}

	for i, channel in ipairs(channelNames) do
		local yPos = 28 + (i - 1) * 32

		local cLabel = Instance.new("TextLabel")
		cLabel.Size = UDim2.new(0, 20, 0, 20)
		cLabel.Position = UDim2.new(0, 12, 0, yPos)
		cLabel.BackgroundTransparency = 1
		cLabel.Text = channel
		cLabel.TextSize = 11
		cLabel.Font = Enum.Font.GothamBold
		cLabel.TextColor3 = channelColors[i]
		cLabel.Parent = container

		local cTrack = Instance.new("Frame")
		cTrack.Size = UDim2.new(1, -80, 0, 8)
		cTrack.Position = UDim2.new(0, 36, 0, yPos + 6)
		cTrack.BackgroundColor3 = THEME.SliderTrack
		cTrack.BorderSizePixel = 0
		cTrack.Parent = container
		CreateCorner(cTrack, 4)

		local defaultVal = ({currentColor.R, currentColor.G, currentColor.B})[i]

		local cFill = Instance.new("Frame")
		cFill.Size = UDim2.new(defaultVal, 0, 1, 0)
		cFill.BackgroundColor3 = channelColors[i]
		cFill.BorderSizePixel = 0
		cFill.Parent = cTrack
		CreateCorner(cFill, 4)

		local cVal = Instance.new("TextLabel")
		cVal.Size = UDim2.new(0, 36, 0, 20)
		cVal.Position = UDim2.new(1, -40, 0, yPos)
		cVal.BackgroundTransparency = 1
		cVal.Text = tostring(math.floor(defaultVal * 255))
		cVal.TextSize = 11
		cVal.Font = Enum.Font.GothamMedium
		cVal.TextColor3 = THEME.TextDim
		cVal.TextXAlignment = Enum.TextXAlignment.Right
		cVal.Parent = container

		sliders[i] = {track = cTrack, fill = cFill, valueLabel = cVal, value = defaultVal}

		local isDragging = false

		cTrack.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				SaveState()
				local relX = math.clamp((input.Position.X - cTrack.AbsolutePosition.X) / cTrack.AbsoluteSize.X, 0, 1)
				sliders[i].value = relX
				cFill.Size = UDim2.new(relX, 0, 1, 0)
				cVal.Text = tostring(math.floor(relX * 255))
				currentColor = Color3.new(sliders[1].value, sliders[2].value, sliders[3].value)
				preview.BackgroundColor3 = currentColor
				if callback then callback(currentColor) end
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local relX = math.clamp((input.Position.X - cTrack.AbsolutePosition.X) / cTrack.AbsoluteSize.X, 0, 1)
				sliders[i].value = relX
				cFill.Size = UDim2.new(relX, 0, 1, 0)
				cVal.Text = tostring(math.floor(relX * 255))
				currentColor = Color3.new(sliders[1].value, sliders[2].value, sliders[3].value)
				preview.BackgroundColor3 = currentColor
				if callback then callback(currentColor) end
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = false
			end
		end)
	end

	return container
end

local function CreateToggle(parent, label, default, order, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 38)
	container.BackgroundColor3 = THEME.PanelLight
	container.BackgroundTransparency = 0.4
	container.LayoutOrder = order or 0
	container.Parent = parent
	CreateCorner(container, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -70, 1, 0)
	nameLabel.Position = UDim2.new(0, 12, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = label
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextColor3 = THEME.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = container

	local toggleBG = Instance.new("Frame")
	toggleBG.Size = UDim2.new(0, 44, 0, 22)
	toggleBG.Position = UDim2.new(1, -56, 0.5, -11)
	toggleBG.BackgroundColor3 = default and THEME.Accent or THEME.SliderTrack
	toggleBG.Parent = container
	CreateCorner(toggleBG, 11)

	local toggleKnob = Instance.new("Frame")
	toggleKnob.Size = UDim2.new(0, 18, 0, 18)
	toggleKnob.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
	toggleKnob.BackgroundColor3 = THEME.Text
	toggleKnob.Parent = toggleBG
	CreateCorner(toggleKnob, 9)

	local isOn = default or false

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = container

	btn.MouseButton1Click:Connect(function()
		isOn = not isOn
		TweenElement(toggleBG, {BackgroundColor3 = isOn and THEME.Accent or THEME.SliderTrack}, 0.25)
		TweenElement(toggleKnob, {Position = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.25)
		if callback then
			callback(isOn)
		end
	end)

	return container, function() return isOn end
end

local function CreateDropdown(parent, label, options, default, order, callback)
	local isExpanded = false
	local container = Instance.new("Frame")
	container.Name = "Dropdown_" .. label
	container.Size = UDim2.new(1, 0, 0, 42)
	container.BackgroundColor3 = THEME.PanelLight
	container.BackgroundTransparency = 0.4
	container.LayoutOrder = order or 0
	container.ClipsDescendants = true
	container.Parent = parent
	CreateCorner(container, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 0, 42)
	nameLabel.Position = UDim2.new(0, 12, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = label
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextColor3 = THEME.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = container

	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(0.4, -20, 0, 42)
	selectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text = default or options[1]
	selectedLabel.TextSize = 12
	selectedLabel.Font = Enum.Font.GothamBold
	selectedLabel.TextColor3 = THEME.AccentTertiary
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
	selectedLabel.Parent = container

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 20, 0, 42)
	arrow.Position = UDim2.new(1, -24, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▼"
	arrow.TextSize = 10
	arrow.Font = Enum.Font.GothamBold
	arrow.TextColor3 = THEME.TextDim
	arrow.Parent = container

	local headerBtn = Instance.new("TextButton")
	headerBtn.Size = UDim2.new(1, 0, 0, 42)
	headerBtn.BackgroundTransparency = 1
	headerBtn.Text = ""
	headerBtn.Parent = container

	local optionsContainer = Instance.new("Frame")
	optionsContainer.Size = UDim2.new(1, -16, 0, #options * 30 + 4)
	optionsContainer.Position = UDim2.new(0, 8, 0, 44)
	optionsContainer.BackgroundColor3 = THEME.Background
	optionsContainer.BackgroundTransparency = 0.3
	optionsContainer.Parent = container
	CreateCorner(optionsContainer, 6)

	local optLayout = Instance.new("UIListLayout")
	optLayout.Padding = UDim.new(0, 2)
	optLayout.Parent = optionsContainer
	CreatePadding(optionsContainer, 2)

	for _, opt in ipairs(options) do
		local optBtn = Instance.new("TextButton")
		optBtn.Size = UDim2.new(1, 0, 0, 28)
		optBtn.BackgroundColor3 = THEME.PanelLight
		optBtn.BackgroundTransparency = 0.6
		optBtn.Text = opt
		optBtn.TextSize = 11
		optBtn.Font = Enum.Font.Gotham
		optBtn.TextColor3 = THEME.Text
		optBtn.Parent = optionsContainer
		CreateCorner(optBtn, 4)

		optBtn.MouseEnter:Connect(function()
			TweenElement(optBtn, {BackgroundTransparency = 0.2, BackgroundColor3 = THEME.Accent}, 0.15)
		end)
		optBtn.MouseLeave:Connect(function()
			TweenElement(optBtn, {BackgroundTransparency = 0.6, BackgroundColor3 = THEME.PanelLight}, 0.15)
		end)

		optBtn.MouseButton1Click:Connect(function()
			selectedLabel.Text = opt
			isExpanded = false
			TweenElement(container, {Size = UDim2.new(1, 0, 0, 42)}, 0.25)
			arrow.Text = "▼"
			SaveState()
			if callback then callback(opt) end
		end)
	end

	headerBtn.MouseButton1Click:Connect(function()
		isExpanded = not isExpanded
		local totalH = isExpanded and (42 + #options * 30 + 16) or 42
		TweenElement(container, {Size = UDim2.new(1, 0, 0, totalH)}, 0.3)
		arrow.Text = isExpanded and "▲" or "▼"
	end)

	return container
end

local function CreateButton(parent, label, order, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = THEME.Accent
	btn.BackgroundTransparency = 0.3
	btn.Text = label
	btn.TextSize = 13
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = THEME.Text
	btn.LayoutOrder = order or 0
	btn.Parent = parent
	CreateCorner(btn, 8)

	btn.MouseEnter:Connect(function()
		TweenElement(btn, {BackgroundTransparency = 0.1}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		TweenElement(btn, {BackgroundTransparency = 0.3}, 0.15)
	end)
	btn.MouseButton1Click:Connect(function()
		TweenElement(btn, {Size = UDim2.new(0.98, 0, 0, 34)}, 0.05)
		wait(0.05)
		TweenElement(btn, {Size = UDim2.new(1, 0, 0, 36)}, 0.1)
		if callback then callback() end
	end)

	return btn
end

-- ============================================================
-- PART SELECTOR
-- ============================================================
local PartSelector = Instance.new("Frame")
PartSelector.Name = "PartSelector"
PartSelector.Size = UDim2.new(1, -20, 0, 44)
PartSelector.Position = UDim2.new(0, 10, 0, 58)
PartSelector.BackgroundTransparency = 1
PartSelector.Parent = MainFrame
PartSelector.Visible = false

local partSelectorScroll = Instance.new("ScrollingFrame")
partSelectorScroll.Size = UDim2.new(1, 0, 1, 0)
partSelectorScroll.BackgroundTransparency = 1
partSelectorScroll.ScrollBarThickness = 0
partSelectorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
partSelectorScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
partSelectorScroll.ScrollingDirection = Enum.ScrollingDirection.X
partSelectorScroll.Parent = PartSelector

local partSelectorLayout = Instance.new("UIListLayout")
partSelectorLayout.FillDirection = Enum.FillDirection.Horizontal
partSelectorLayout.Padding = UDim.new(0, 4)
partSelectorLayout.Parent = partSelectorScroll

-- ============================================================
-- APPLY TO PARTS HELPER
-- ============================================================
local function GetTargetParts()
	if not State.currentTool then return {} end
	local parts = {}
	for _, child in ipairs(State.currentTool:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	-- Also check handle
	local handle = State.currentTool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		local found = false
		for _, p in ipairs(parts) do
			if p == handle then found = true break end
		end
		if not found then
			table.insert(parts, 1, handle)
		end
	end
	return parts
end

local function GetSelectedPart()
	local parts = GetTargetParts()
	if #parts == 0 then return nil end
	if State.selectedPartIndex == 0 then return nil end -- "All" selected
	return parts[math.clamp(State.selectedPartIndex, 1, #parts)]
end

local function ApplyToParts(func)
	local parts = GetTargetParts()
	if State.selectedPartIndex == 0 then
		-- Apply to all
		for _, part in ipairs(parts) do
			func(part)
		end
	else
		local part = GetSelectedPart()
		if part then func(part) end
	end
end

-- ============================================================
-- TAB CONTENT BUILDERS
-- ============================================================

local function ClearContent()
	for _, child in ipairs(ContentArea:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function BuildTransformTab()
	ClearContent()

	CreateSectionHeader(ContentArea, "SCALE", 1)

	CreateSlider(ContentArea, "Size X Multiplier", 0.1, 5, 1, 0.05, 2, function(val)
		ApplyToParts(function(part)
			local original = part:GetAttribute("OrigSizeX") or part.Size.X
			part:SetAttribute("OrigSizeX", original)
			part.Size = Vector3.new(original * val, part.Size.Y, part.Size.Z)
		end)
	end)

	CreateSlider(ContentArea, "Size Y Multiplier", 0.1, 5, 1, 0.05, 3, function(val)
		ApplyToParts(function(part)
			local original = part:GetAttribute("OrigSizeY") or part.Size.Y
			part:SetAttribute("OrigSizeY", original)
			part.Size = Vector3.new(part.Size.X, original * val, part.Size.Z)
		end)
	end)

	CreateSlider(ContentArea, "Size Z Multiplier", 0.1, 5, 1, 0.05, 4, function(val)
		ApplyToParts(function(part)
			local original = part:GetAttribute("OrigSizeZ") or part.Size.Z
			part:SetAttribute("OrigSizeZ", original)
			part.Size = Vector3.new(part.Size.X, part.Size.Y, original * val)
		end)
	end)

	CreateSlider(ContentArea, "Uniform Scale", 0.1, 5, 1, 0.05, 5, function(val)
		ApplyToParts(function(part)
			local ox = part:GetAttribute("OrigSizeX") or part.Size.X
			local oy = part:GetAttribute("OrigSizeY") or part.Size.Y
			local oz = part:GetAttribute("OrigSizeZ") or part.Size.Z
			part:SetAttribute("OrigSizeX", ox)
			part:SetAttribute("OrigSizeY", oy)
			part:SetAttribute("OrigSizeZ", oz)
			part.Size = Vector3.new(ox * val, oy * val, oz * val)
		end)
	end)

	CreateSectionHeader(ContentArea, "PROPERTIES", 6)

	CreateSlider(ContentArea, "Transparency", 0, 1, 0, 0.01, 7, function(val)
		ApplyToParts(function(part)
			part.Transparency = val
		end)
	end)

	CreateSlider(ContentArea, "Reflectance", 0, 1, 0, 0.01, 8, function(val)
		ApplyToParts(function(part)
			part.Reflectance = val
		end)
	end)

	CreateToggle(ContentArea, "🔒 Anchored", false, 9, function(val)
		ApplyToParts(function(part)
			part.Anchored = val
		end)
	end)

	CreateToggle(ContentArea, "👻 CanCollide", true, 10, function(val)
		ApplyToParts(function(part)
			part.CanCollide = val
		end)
	end)

	CreateToggle(ContentArea, "🌫️ CastShadow", true, 11, function(val)
		ApplyToParts(function(part)
			part.CastShadow = val
		end)
	end)

	CreateSectionHeader(ContentArea, "MASS OPERATIONS", 12)

	CreateButton(ContentArea, "🔄 Reset All Sizes", 13, function()
		ApplyToParts(function(part)
			local ox = part:GetAttribute("OrigSizeX")
			local oy = part:GetAttribute("OrigSizeY")
			local oz = part:GetAttribute("OrigSizeZ")
			if ox and oy and oz then
				part.Size = Vector3.new(ox, oy, oz)
			end
		end)
	end)
end

local function BuildAppearanceTab()
	ClearContent()

	CreateSectionHeader(ContentArea, "COLOR", 1)

	CreateColorPicker(ContentArea, "Part Color", Color3.fromRGB(255, 255, 255), 2, function(color)
		ApplyToParts(function(part)
			part.Color = color
		end)
	end)

	CreateSectionHeader(ContentArea, "QUICK COLORS", 3)

	local quickColorFrame = Instance.new("Frame")
	quickColorFrame.Size = UDim2.new(1, 0, 0, 40)
	quickColorFrame.BackgroundTransparency = 1
	quickColorFrame.LayoutOrder = 4
	quickColorFrame.Parent = ContentArea

	local quickColorLayout = Instance.new("UIListLayout")
	quickColorLayout.FillDirection = Enum.FillDirection.Horizontal
	quickColorLayout.Padding = UDim.new(0, 4)
	quickColorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	quickColorLayout.Parent = quickColorFrame

	local quickColors = {
		{Color3.fromRGB(255, 0, 0), "Red"},
		{Color3.fromRGB(255, 100, 0), "Orange"},
		{Color3.fromRGB(255, 255, 0), "Yellow"},
		{Color3.fromRGB(0, 255, 0), "Green"},
		{Color3.fromRGB(0, 200, 255), "Cyan"},
		{Color3.fromRGB(0, 100, 255), "Blue"},
		{Color3.fromRGB(150, 0, 255), "Purple"},
		{Color3.fromRGB(255, 0, 150), "Pink"},
		{Color3.fromRGB(255, 255, 255), "White"},
		{Color3.fromRGB(30, 30, 30), "Black"},
		{Color3.fromRGB(255, 215, 0), "Gold"},
	}

	for _, data in ipairs(quickColors) do
		local colorBtn = Instance.new("TextButton")
		colorBtn.Size = UDim2.new(0, 32, 0, 32)
		colorBtn.BackgroundColor3 = data[1]
		colorBtn.Text = ""
		colorBtn.Parent = quickColorFrame
		CreateCorner(colorBtn, 6)
		CreateStroke(colorBtn, THEME.Border, 1, 0.5)

		colorBtn.MouseButton1Click:Connect(function()
			SaveState()
			ApplyToParts(function(part)
				part.Color = data[1]
			end)
		end)
	end

	CreateSectionHeader(ContentArea, "MATERIAL", 5)

	CreateDropdown(ContentArea, "Material", MATERIALS_LIST, "SmoothPlastic", 6, function(mat)
		ApplyToParts(function(part)
			part.Material = Enum.Material[mat]
		end)
	end)

	CreateSectionHeader(ContentArea, "TEXTURES & DECALS", 7)

	CreateToggle(ContentArea, "🧱 Remove All Textures", false, 8, function(val)
		if val then
			ApplyToParts(function(part)
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("Texture") or child:IsA("Decal") then
						child:Destroy()
					end
				end
			end)
		end
	end)

	CreateToggle(ContentArea, "🔍 Remove All Meshes", false, 9, function(val)
		if val then
			ApplyToParts(function(part)
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
						child:Destroy()
					end
				end
			end)
		end
	end)

	CreateSectionHeader(ContentArea, "SURFACE", 10)

	local surfaceTypes = {"Smooth", "Glue", "Weld", "Studs", "Inlet", "Universal", "Hinge", "Motor"}

	CreateDropdown(ContentArea, "Top Surface", surfaceTypes, "Smooth", 11, function(s)
		ApplyToParts(function(part) part.TopSurface = Enum.SurfaceType[s] end)
	end)

	CreateDropdown(ContentArea, "Bottom Surface", surfaceTypes, "Smooth", 12, function(s)
		ApplyToParts(function(part) part.BottomSurface = Enum.SurfaceType[s] end)
	end)
end

local function BuildEffectsTab()
	ClearContent()

	CreateSectionHeader(ContentArea, "PARTICLE EFFECTS", 1)

	CreateToggle(ContentArea, "🔥 Fire", false, 2, function(val)
		State.fireEnabled = val
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_Fire")
			if val then
				if not existing then
					local fire = Instance.new("Fire")
					fire.Name = "WE_Fire"
					fire.Size = 5
					fire.Heat = 10
					fire.Color = Color3.fromRGB(255, 100, 0)
					fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
					fire.Parent = part
				end
			else
				if existing then existing:Destroy() end
			end
		end)
	end)

	CreateSlider(ContentArea, "Fire Size", 1, 30, 5, 0.5, 3, function(val)
		ApplyToParts(function(part)
			local fire = part:FindFirstChild("WE_Fire")
			if fire then fire.Size = val end
		end)
	end)

	CreateToggle(ContentArea, "✨ Sparkles", false, 4, function(val)
		State.sparklesEnabled = val
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_Sparkles")
			if val then
				if not existing then
					local s = Instance.new("Sparkles")
					s.Name = "WE_Sparkles"
					s.SparkleColor = Color3.fromRGB(255, 255, 100)
					s.Parent = part
				end
			else
				if existing then existing:Destroy() end
			end
		end)
	end)

	CreateToggle(ContentArea, "💨 Smoke", false, 5, function(val)
		State.smokeEnabled = val
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_Smoke")
			if val then
				if not existing then
					local smoke = Instance.new("Smoke")
					smoke.Name = "WE_Smoke"
					smoke.Size = 2
					smoke.Opacity = 0.3
					smoke.RiseVelocity = 2
					smoke.Color = Color3.fromRGB(200, 200, 200)
					smoke.Parent = part
				end
			else
				if existing then existing:Destroy() end
			end
		end)
	end)

	CreateSlider(ContentArea, "Smoke Opacity", 0, 1, 0.3, 0.01, 6, function(val)
		ApplyToParts(function(part)
			local smoke = part:FindFirstChild("WE_Smoke")
			if smoke then smoke.Opacity = val end
		end)
	end)

	CreateSectionHeader(ContentArea, "LIGHT EFFECTS", 7)

	CreateToggle(ContentArea, "💡 Point Light", false, 8, function(val)
		State.lightEnabled = val
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_PointLight")
			if val then
				if not existing then
					local light = Instance.new("PointLight")
					light.Name = "WE_PointLight"
					light.Brightness = 2
					light.Range = 20
					light.Color = Color3.fromRGB(255, 255, 255)
					light.Parent = part
				end
			else
				if existing then existing:Destroy() end
			end
		end)
	end)

	CreateSlider(ContentArea, "Light Brightness", 0, 10, 2, 0.1, 9, function(val)
		ApplyToParts(function(part)
			local light = part:FindFirstChild("WE_PointLight")
			if light then light.Brightness = val end
		end)
	end)

	CreateSlider(ContentArea, "Light Range", 1, 60, 20, 1, 10, function(val)
		ApplyToParts(function(part)
			local light = part:FindFirstChild("WE_PointLight")
			if light then light.Range = val end
		end)
	end)

	CreateColorPicker(ContentArea, "Light Color", Color3.new(1, 1, 1), 11, function(color)
		ApplyToParts(function(part)
			local light = part:FindFirstChild("WE_PointLight")
			if light then light.Color = color end
		end)
	end)

	CreateSectionHeader(ContentArea, "TRAIL", 12)

	CreateToggle(ContentArea, "🌈 Trail", false, 13, function(val)
		State.trailEnabled = val
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_Trail")
			local a0 = part:FindFirstChild("WE_Attachment0")
			local a1 = part:FindFirstChild("WE_Attachment1")
			if val then
				if not existing then
					if not a0 then
						a0 = Instance.new("Attachment")
						a0.Name = "WE_Attachment0"
						a0.Position = Vector3.new(0, part.Size.Y / 2, 0)
						a0.Parent = part
					end
					if not a1 then
						a1 = Instance.new("Attachment")
						a1.Name = "WE_Attachment1"
						a1.Position = Vector3.new(0, -part.Size.Y / 2, 0)
						a1.Parent = part
					end
					local trail = Instance.new("Trail")
					trail.Name = "WE_Trail"
					trail.Attachment0 = a0
					trail.Attachment1 = a1
					trail.Lifetime = 0.5
					trail.MinLength = 0.05
					trail.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 60, 120)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 220, 255)),
					})
					trail.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
					trail.WidthScale = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					})
					trail.LightEmission = 0.5
					trail.Parent = part
				end
			else
				if existing then existing:Destroy() end
				if a0 then a0:Destroy() end
				if a1 then a1:Destroy() end
			end
		end)
	end)

	CreateSlider(ContentArea, "Trail Lifetime", 0.1, 3, 0.5, 0.05, 14, function(val)
		ApplyToParts(function(part)
			local trail = part:FindFirstChild("WE_Trail")
			if trail then trail.Lifetime = val end
		end)
	end)

	CreateSectionHeader(ContentArea, "PARTICLE EMITTER", 15)

	CreateToggle(ContentArea, "🎆 Particles", false, 16, function(val)
		State.particlesEnabled = val
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_Particles")
			if val then
				if not existing then
					local pe = Instance.new("ParticleEmitter")
					pe.Name = "WE_Particles"
					pe.Rate = 30
					pe.Speed = NumberRange.new(2, 6)
					pe.Lifetime = NumberRange.new(0.5, 1.5)
					pe.Size = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.5),
						NumberSequenceKeypoint.new(1, 0),
					})
					pe.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, THEME.Accent),
						ColorSequenceKeypoint.new(1, THEME.AccentSecondary),
					})
					pe.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
					pe.LightEmission = 0.8
					pe.SpreadAngle = Vector2.new(360, 360)
					pe.Parent = part
				end
			else
				if existing then existing:Destroy() end
			end
		end)
	end)

	CreateSlider(ContentArea, "Particle Rate", 1, 200, 30, 1, 17, function(val)
		ApplyToParts(function(part)
			local pe = part:FindFirstChild("WE_Particles")
			if pe then pe.Rate = val end
		end)
	end)

	CreateSlider(ContentArea, "Particle Speed", 0, 20, 4, 0.5, 18, function(val)
		ApplyToParts(function(part)
			local pe = part:FindFirstChild("WE_Particles")
			if pe then pe.Speed = NumberRange.new(val * 0.5, val) end
		end)
	end)

	CreateSlider(ContentArea, "Particle Size", 0.1, 5, 0.5, 0.1, 19, function(val)
		ApplyToParts(function(part)
			local pe = part:FindFirstChild("WE_Particles")
			if pe then
				pe.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, val),
					NumberSequenceKeypoint.new(1, 0),
				})
			end
		end)
	end)

	CreateSectionHeader(ContentArea, "GLOW & AURA", 20)

	CreateToggle(ContentArea, "💎 Neon Glow (SelectionBox)", false, 21, function(val)
		State.glowEnabled = val
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_SelectionBox")
			if val then
				if not existing then
					local sb = Instance.new("SelectionBox")
					sb.Name = "WE_SelectionBox"
					sb.Adornee = part
					sb.Color3 = THEME.Accent
					sb.LineThickness = 0.03
					sb.Transparency = 0.3
					sb.SurfaceTransparency = 0.85
					sb.SurfaceColor3 = THEME.Accent
					sb.Parent = part
				end
			else
				if existing then existing:Destroy() end
			end
		end)
	end)

	CreateSectionHeader(ContentArea, "BEAM EFFECT", 22)

	CreateToggle(ContentArea, "⚡ Electric Beam", false, 23, function(val)
		ApplyToParts(function(part)
			local existing = part:FindFirstChild("WE_Beam")
			local a0 = part:FindFirstChild("WE_BeamA0")
			local a1 = part:FindFirstChild("WE_BeamA1")
			if val then
				if not existing then
					if not a0 then
						a0 = Instance.new("Attachment")
						a0.Name = "WE_BeamA0"
						a0.Position = Vector3.new(0, part.Size.Y / 2, 0)
						a0.Parent = part
					end
					if not a1 then
						a1 = Instance.new("Attachment")
						a1.Name = "WE_BeamA1"
						a1.Position = Vector3.new(0, -part.Size.Y / 2, 0)
						a1.Parent = part
					end
					local beam = Instance.new("Beam")
					beam.Name = "WE_Beam"
					beam.Attachment0 = a0
					beam.Attachment1 = a1
					beam.Width0 = 0.3
					beam.Width1 = 0.3
					beam.LightEmission = 1
					beam.FaceCamera = true
					beam.Segments = 20
					beam.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255)),
					})
					beam.Transparency = NumberSequence.new(0.2)
					beam.CurveSize0 = 2
					beam.CurveSize1 = -2
					beam.Parent = part
				end
			else
				if existing then existing:Destroy() end
				if a0 then a0:Destroy() end
				if a1 then a1:Destroy() end
			end
		end)
	end)

	CreateSectionHeader(ContentArea, "CLEANUP", 24)

	CreateButton(ContentArea, "🗑️ Remove ALL Effects", 25, function()
		ApplyToParts(function(part)
			local prefixes = {"WE_Fire", "WE_Sparkles", "WE_Smoke", "WE_PointLight", "WE_Trail",
				"WE_Attachment0", "WE_Attachment1", "WE_Particles", "WE_SelectionBox",
				"WE_Beam", "WE_BeamA0", "WE_BeamA1", "WE_Highlight"}
			for _, child in ipairs(part:GetChildren()) do
				for _, prefix in ipairs(prefixes) do
					if child.Name == prefix then
						child:Destroy()
						break
					end
				end
			end
		end)
		-- Also remove tool-level highlight
		if State.currentTool then
			local h = State.currentTool:FindFirstChild("WE_Highlight")
			if h then h:Destroy() end
		end
		State.fireEnabled = false
		State.sparklesEnabled = false
		State.smokeEnabled = false
		State.lightEnabled = false
		State.trailEnabled = false
		State.particlesEnabled = false
		State.glowEnabled = false
	end)
end

local function BuildAnimationTab()
	ClearContent()

	CreateSectionHeader(ContentArea, "COLOR ANIMATIONS", 1)

	CreateToggle(ContentArea, "🌈 Rainbow Cycle", false, 2, function(val)
		State.rainbowEnabled = val
	end)

	CreateSlider(ContentArea, "Rainbow Speed", 0.1, 5, 1, 0.1, 3, function(val)
		State.rainbowSpeed = val
	end)
	State.rainbowSpeed = 1

	CreateToggle(ContentArea, "💓 Color Pulse", false, 4, function(val)
		State.pulseEnabled = val
	end)

	CreateColorPicker(ContentArea, "Pulse Color A", THEME.Accent, 5, function(c)
		State.pulseColorA = c
	end)
	State.pulseColorA = THEME.Accent

	CreateColorPicker(ContentArea, "Pulse Color B", THEME.AccentSecondary, 6, function(c)
		State.pulseColorB = c
	end)
	State.pulseColorB = THEME.AccentSecondary

	CreateSlider(ContentArea, "Pulse Speed", 0.1, 5, 1, 0.1, 7, function(val)
		State.pulseSpeed = val
	end)
	State.pulseSpeed = 1

	CreateSectionHeader(ContentArea, "MOVEMENT ANIMATIONS", 8)

	CreateToggle(ContentArea, "🔄 Spin Effect", false, 9, function(val)
		State.spinEnabled = val
	end)

	CreateSlider(ContentArea, "Spin Speed", 0.5, 20, 3, 0.5, 10, function(val)
		State.spinSpeed = val
	end)
	State.spinSpeed = 3

	CreateToggle(ContentArea, "🫧 Float / Bob", false, 11, function(val)
		State.floatEnabled = val
	end)

	CreateSectionHeader(ContentArea, "TRANSPARENCY ANIMATION", 12)

	CreateToggle(ContentArea, "👻 Flicker / Phase", false, 13, function(val)
		State.flickerEnabled = val
	end)

	CreateSlider(ContentArea, "Flicker Speed", 0.5, 10, 3, 0.5, 14, function(val)
		State.flickerSpeed = val
	end)
	State.flickerSpeed = 3

	CreateSectionHeader(ContentArea, "SIZE ANIMATION", 15)

	CreateToggle(ContentArea, "📏 Breathe (Size Pulse)", false, 16, function(val)
		State.breatheEnabled = val
	end)

	CreateSlider(ContentArea, "Breathe Amount", 0.01, 0.5, 0.1, 0.01, 17, function(val)
		State.breatheAmount = val
	end)
	State.breatheAmount = 0.1

	CreateSectionHeader(ContentArea, "HIGHLIGHT EFFECT", 18)

	CreateToggle(ContentArea, "🔆 Outline Highlight", false, 19, function(val)
		if not State.currentTool then return end
		local existing = State.currentTool:FindFirstChild("WE_Highlight")
		if val then
			if not existing then
				local h = Instance.new("Highlight")
				h.Name = "WE_Highlight"
				h.FillTransparency = 0.7
				h.OutlineTransparency = 0
				h.FillColor = THEME.Accent
				h.OutlineColor = THEME.AccentTertiary
				h.Adornee = State.currentTool
				h.Parent = State.currentTool
			end
		else
			if existing then existing:Destroy() end
		end
	end)

	CreateSlider(ContentArea, "Highlight Fill Opacity", 0, 1, 0.3, 0.01, 20, function(val)
		if State.currentTool then
			local h = State.currentTool:FindFirstChild("WE_Highlight")
			if h then h.FillTransparency = 1 - val end
		end
	end)

	CreateColorPicker(ContentArea, "Highlight Fill Color", THEME.Accent, 21, function(c)
		if State.currentTool then
			local h = State.currentTool:FindFirstChild("WE_Highlight")
			if h then h.FillColor = c end
		end
	end)

	CreateColorPicker(ContentArea, "Highlight Outline Color", THEME.AccentTertiary, 22, function(c)
		if State.currentTool then
			local h = State.currentTool:FindFirstChild("WE_Highlight")
			if h then h.OutlineColor = c end
		end
	end)
end

local function BuildPresetsTab()
	ClearContent()

	CreateSectionHeader(ContentArea, "WEAPON PRESETS", 1)

	CreateButton(ContentArea, "🔥 Inferno Blade", 2, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(180, 30, 0)
			part.Material = Enum.Material.Neon

			local fire = part:FindFirstChild("WE_Fire") or Instance.new("Fire")
			fire.Name = "WE_Fire"
			fire.Size = 8
			fire.Heat = 15
			fire.Color = Color3.fromRGB(255, 80, 0)
			fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
			fire.Parent = part

			local light = part:FindFirstChild("WE_PointLight") or Instance.new("PointLight")
			light.Name = "WE_PointLight"
			light.Color = Color3.fromRGB(255, 100, 0)
			light.Brightness = 3
			light.Range = 25
			light.Parent = part
		end)
	end)

	CreateButton(ContentArea, "❄️ Frost Edge", 3, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(150, 220, 255)
			part.Material = Enum.Material.Ice
			part.Reflectance = 0.5

			local sparkles = part:FindFirstChild("WE_Sparkles") or Instance.new("Sparkles")
			sparkles.Name = "WE_Sparkles"
			sparkles.SparkleColor = Color3.fromRGB(200, 240, 255)
			sparkles.Parent = part

			local light = part:FindFirstChild("WE_PointLight") or Instance.new("PointLight")
			light.Name = "WE_PointLight"
			light.Color = Color3.fromRGB(150, 200, 255)
			light.Brightness = 2
			light.Range = 20
			light.Parent = part
		end)
	end)

	CreateButton(ContentArea, "⚡ Lightning Strike", 4, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(200, 200, 255)
			part.Material = Enum.Material.Neon

			local pe = part:FindFirstChild("WE_Particles") or Instance.new("ParticleEmitter")
			pe.Name = "WE_Particles"
			pe.Rate = 60
			pe.Speed = NumberRange.new(4, 8)
			pe.Lifetime = NumberRange.new(0.2, 0.5)
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Color = ColorSequence.new(Color3.fromRGB(150, 180, 255))
			pe.LightEmission = 1
			pe.SpreadAngle = Vector2.new(360, 360)
			pe.Parent = part

			local light = part:FindFirstChild("WE_PointLight") or Instance.new("PointLight")
			light.Name = "WE_PointLight"
			light.Color = Color3.fromRGB(180, 200, 255)
			light.Brightness = 4
			light.Range = 30
			light.Parent = part
		end)
		State.flickerEnabled = true
		State.flickerSpeed = 8
	end)

	CreateButton(ContentArea, "🌑 Shadow Blade", 5, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(20, 0, 30)
			part.Material = Enum.Material.ForceField
			part.Transparency = 0.3

			local smoke = part:FindFirstChild("WE_Smoke") or Instance.new("Smoke")
			smoke.Name = "WE_Smoke"
			smoke.Color = Color3.fromRGB(30, 0, 50)
			smoke.Opacity = 0.4
			smoke.Size = 3
			smoke.RiseVelocity = 1
			smoke.Parent = part
		end)
		if State.currentTool then
			local h = State.currentTool:FindFirstChild("WE_Highlight") or Instance.new("Highlight")
			h.Name = "WE_Highlight"
			h.FillTransparency = 0.6
			h.OutlineTransparency = 0.2
			h.FillColor = Color3.fromRGB(50, 0, 80)
			h.OutlineColor = Color3.fromRGB(120, 0, 200)
			h.Adornee = State.currentTool
			h.Parent = State.currentTool
		end
	end)

	CreateButton(ContentArea, "🌟 Holy Radiance", 6, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(255, 245, 200)
			part.Material = Enum.Material.Neon
			part.Reflectance = 0.8

			local sparkles = part:FindFirstChild("WE_Sparkles") or Instance.new("Sparkles")
			sparkles.Name = "WE_Sparkles"
			sparkles.SparkleColor = Color3.fromRGB(255, 255, 200)
			sparkles.Parent = part

			local light = part:FindFirstChild("WE_PointLight") or Instance.new("PointLight")
			light.Name = "WE_PointLight"
			light.Color = Color3.fromRGB(255, 240, 180)
			light.Brightness = 5
			light.Range = 40
			light.Parent = part

			local pe = part:FindFirstChild("WE_Particles") or Instance.new("ParticleEmitter")
			pe.Name = "WE_Particles"
			pe.Rate = 40
			pe.Speed = NumberRange.new(1, 3)
			pe.Lifetime = NumberRange.new(1, 2)
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.6),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100)),
			})
			pe.LightEmission = 1
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Parent = part
		end)
	end)

	CreateButton(ContentArea, "💀 Cursed Edge", 7, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(50, 180, 50)
			part.Material = Enum.Material.Neon

			local pe = part:FindFirstChild("WE_Particles") or Instance.new("ParticleEmitter")
			pe.Name = "WE_Particles"
			pe.Rate = 25
			pe.Speed = NumberRange.new(1, 3)
			pe.Lifetime = NumberRange.new(0.8, 1.5)
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 120)),
			})
			pe.LightEmission = 0.6
			pe.SpreadAngle = Vector2.new(360, 360)
			pe.Parent = part

			local smoke = part:FindFirstChild("WE_Smoke") or Instance.new("Smoke")
			smoke.Name = "WE_Smoke"
			smoke.Color = Color3.fromRGB(0, 100, 0)
			smoke.Opacity = 0.2
			smoke.Size = 2
			smoke.Parent = part
		end)
		State.pulseEnabled = true
		State.pulseColorA = Color3.fromRGB(0, 255, 0)
		State.pulseColorB = Color3.fromRGB(100, 0, 200)
		State.pulseSpeed = 2
	end)

	CreateButton(ContentArea, "🌊 Ocean Depths", 8, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(0, 80, 180)
			part.Material = Enum.Material.Glass
			part.Transparency = 0.2
			part.Reflectance = 0.4

			local pe = part:FindFirstChild("WE_Particles") or Instance.new("ParticleEmitter")
			pe.Name = "WE_Particles"
			pe.Rate = 15
			pe.Speed = NumberRange.new(0.5, 2)
			pe.Lifetime = NumberRange.new(1, 3)
			pe.Size = NumberSequence.new(0.3)
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200)),
			})
			pe.LightEmission = 0.4
			pe.SpreadAngle = Vector2.new(360, 360)
			pe.Parent = part
		end)
	end)

	CreateButton(ContentArea, "🪐 Void Walker", 9, function()
		SaveState()
		ApplyToParts(function(part)
			part.Color = Color3.fromRGB(10, 0, 20)
			part.Material = Enum.Material.ForceField
			part.Transparency = 0.15

			local pe = part:FindFirstChild("WE_Particles") or Instance.new("ParticleEmitter")
			pe.Name = "WE_Particles"
			pe.Rate = 50
			pe.Speed = NumberRange.new(0.5, 1.5)
			pe.Lifetime = NumberRange.new(0.5, 1)
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.5, 0.3),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 0, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255)),
			})
			pe.LightEmission = 1
			pe.SpreadAngle = Vector2.new(360, 360)
			pe.Parent = part
		end)
		State.rainbowEnabled = false
		State.pulseEnabled = true
		State.pulseColorA = Color3.fromRGB(60, 0, 120)
		State.pulseColorB = Color3.fromRGB(0, 150, 255)
		State.pulseSpeed = 0.5
	end)

	CreateSectionHeader(ContentArea, "UTILITY", 10)

	CreateButton(ContentArea, "♻️ Reset to Default", 11, function()
		-- Clear all effects
		if State.currentTool then
			for _, desc in ipairs(State.currentTool:GetDescendants()) do
				if string.sub(desc.Name, 1, 3) == "WE_" then
					desc:Destroy()
				end
			end
		end
		State.rainbowEnabled = false
		State.pulseEnabled = false
		State.spinEnabled = false
		State.floatEnabled = false
		State.flickerEnabled = false
		State.breatheEnabled = false
		State.fireEnabled = false
		State.sparklesEnabled = false
		State.smokeEnabled = false
		State.lightEnabled = false
		State.trailEnabled = false
		State.particlesEnabled = false
		State.glowEnabled = false

		-- Restore from history
		Undo()
	end)

	CreateButton(ContentArea, "🎲 Random Preset", 12, function()
		SaveState()
		local randomColor = Color3.fromHSV(math.random(), math.random() * 0.5 + 0.5, math.random() * 0.5 + 0.5)
		local randomMat = MATERIALS_LIST[math.random(1, #MATERIALS_LIST)]
		ApplyToParts(function(part)
			part.Color = randomColor
			part.Material = Enum.Material[randomMat]
			part.Reflectance = math.random() * 0.5
			part.Transparency = math.random() * 0.3
		end)
		-- Random effect
		local effectRoll = math.random(1, 5)
		if effectRoll == 1 then
			State.rainbowEnabled = true
		elseif effectRoll == 2 then
			State.pulseEnabled = true
			State.pulseColorA = randomColor
			State.pulseColorB = Color3.fromHSV(math.random(), 1, 1)
		elseif effectRoll == 3 then
			ApplyToParts(function(part)
				local fire = Instance.new("Fire")
				fire.Name = "WE_Fire"
				fire.Size = math.random(3, 15)
				fire.Parent = part
			end)
		elseif effectRoll == 4 then
			ApplyToParts(function(part)
				local sparkles = Instance.new("Sparkles")
				sparkles.Name = "WE_Sparkles"
				sparkles.SparkleColor = Color3.fromHSV(math.random(), 1, 1)
				sparkles.Parent = part
			end)
		elseif effectRoll == 5 then
			ApplyToParts(function(part)
				local light = Instance.new("PointLight")
				light.Name = "WE_PointLight"
				light.Color = randomColor
				light.Brightness = math.random(2, 5)
				light.Range = math.random(15, 40)
				light.Parent = part
			end)
		end
	end)
end

-- ============================================================
-- TAB SWITCHING
-- ============================================================

local function SwitchTab(tabName)
	State.selectedTab = tabName

	for name, btn in pairs(tabButtons) do
		if name == tabName then
			TweenElement(btn, {BackgroundColor3 = THEME.Accent, BackgroundTransparency = 0.2}, 0.2)
			btn.TextColor3 = THEME.Text
		else
			TweenElement(btn, {BackgroundColor3 = THEME.PanelLight, BackgroundTransparency = 0.6}, 0.2)
			btn.TextColor3 = THEME.TextDim
		end
	end

	if tabName == "Transform" then
		BuildTransformTab()
	elseif tabName == "Appearance" then
		BuildAppearanceTab()
	elseif tabName == "Effects" then
		BuildEffectsTab()
	elseif tabName == "Animation" then
		BuildAnimationTab()
	elseif tabName == "Presets" then
		BuildPresetsTab()
	end
end

-- Create tab buttons
for _, tabName in ipairs(TABS) do
	local btn = Instance.new("TextButton")
	btn.Name = tabName
	btn.Size = UDim2.new(0, 80, 0, 32)
	btn.BackgroundColor3 = THEME.PanelLight
	btn.BackgroundTransparency = 0.6
	btn.Text = (TAB_ICONS[tabName] or "") .. " " .. tabName
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = THEME.TextDim
	btn.Parent = TabBar
	CreateCorner(btn, 8)

	tabButtons[tabName] = btn

	btn.MouseButton1Click:Connect(function()
		SwitchTab(tabName)
	end)

	btn.MouseEnter:Connect(function()
		if State.selectedTab ~= tabName then
			TweenElement(btn, {BackgroundTransparency = 0.4}, 0.15)
		end
	end)
	btn.MouseLeave:Connect(function()
		if State.selectedTab ~= tabName then
			TweenElement(btn, {BackgroundTransparency = 0.6}, 0.15)
		end
	end)
end

-- ============================================================
-- PART SELECTOR UPDATE
-- ============================================================

local function UpdatePartSelector()
	for _, child in ipairs(partSelectorScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local parts = GetTargetParts()
	if #parts == 0 then
		PartSelector.Visible = false
		return
	end
	PartSelector.Visible = true

	-- "All" button
	local allBtn = Instance.new("TextButton")
	allBtn.Size = UDim2.new(0, 50, 0, 30)
	allBtn.BackgroundColor3 = State.selectedPartIndex == 0 and THEME.Accent or THEME.PanelLight
	allBtn.BackgroundTransparency = State.selectedPartIndex == 0 and 0.2 or 0.5
	allBtn.Text = "All"
	allBtn.TextSize = 11
	allBtn.Font = Enum.Font.GothamBold
	allBtn.TextColor3 = THEME.Text
	allBtn.Parent = partSelectorScroll
	CreateCorner(allBtn, 6)

	allBtn.MouseButton1Click:Connect(function()
		State.selectedPartIndex = 0
		UpdatePartSelector()
	end)

	for i, part in ipairs(parts) do
		local partBtn = Instance.new("TextButton")
		partBtn.Size = UDim2.new(0, 80, 0, 30)
		partBtn.BackgroundColor3 = State.selectedPartIndex == i and THEME.Accent or THEME.PanelLight
		partBtn.BackgroundTransparency = State.selectedPartIndex == i and 0.2 or 0.5
		partBtn.Text = part.Name
		partBtn.TextSize = 10
		partBtn.Font = Enum.Font.GothamMedium
		partBtn.TextColor3 = THEME.Text
		partBtn.TextTruncate = Enum.TextTruncate.AtEnd
		partBtn.Parent = partSelectorScroll
		CreateCorner(partBtn, 6)

		partBtn.MouseButton1Click:Connect(function()
			State.selectedPartIndex = i
			UpdatePartSelector()
		end)
	end
end

-- ============================================================
-- TOOL DETECTION
-- ============================================================

local function OnToolEquipped(tool)
	if not tool:IsA("Tool") then return end

	State.currentTool = tool
	State.currentParts = GetTargetParts()
	State.selectedPartIndex = 0
	State.history = {}
	State.historyIndex = 0

	-- Store original sizes
	for _, part in ipairs(State.currentParts) do
		if part:IsA("BasePart") then
			part:SetAttribute("OrigSizeX", part.Size.X)
			part:SetAttribute("OrigSizeY", part.Size.Y)
			part:SetAttribute("OrigSizeZ", part.Size.Z)
		end
	end

	SaveState()

	-- Update UI
	toolNameLabel.Text = "🔧 " .. tool.Name .. " (" .. #State.currentParts .. " parts)"
	WaitingFrame.Visible = false
	MainFrame.Visible = true

	-- Animate in
	MainFrame.Position = UDim2.new(1, 0, 0.5, -310)
	TweenElement(MainFrame, {Position = UDim2.new(1, -460, 0.5, -310)}, 0.5, Enum.EasingStyle.Back)

	UpdatePartSelector()
	SwitchTab("Transform")
end

local function OnToolUnequipped()
	-- Don't hide immediately - let user keep editing if they want
	toolNameLabel.Text = "⚠️ Tool unequipped - re-equip to continue"
	toolNameLabel.TextColor3 = THEME.Warning

	wait(3)
	if not State.currentTool or not State.currentTool.Parent or State.currentTool.Parent ~= character then
		State.currentTool = nil
		State.currentParts = {}

		TweenElement(MainFrame, {Position = UDim2.new(1, 0, 0.5, -310)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		wait(0.4)
		MainFrame.Visible = false
		WaitingFrame.Visible = true
		toolNameLabel.TextColor3 = THEME.AccentTertiary
	end
end

-- ============================================================
-- CHARACTER CONNECTION
-- ============================================================

local function SetupCharacter(char)
	character = char

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			OnToolEquipped(child)
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == State.currentTool then
			OnToolUnequipped()
		end
	end)

	-- Check if already holding a tool
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			OnToolEquipped(child)
			break
		end
	end
end

SetupCharacter(character)
player.CharacterAdded:Connect(SetupCharacter)

-- ============================================================
-- BUTTON CONNECTIONS
-- ============================================================

closeBtn.MouseButton1Click:Connect(function()
	TweenElement(MainFrame, {Position = UDim2.new(1, 0, 0.5, -310)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	wait(0.4)
	MainFrame.Visible = false
	WaitingFrame.Visible = true
end)

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		TweenElement(MainFrame, {Size = UDim2.new(0, 440, 0, 56)}, 0.3)
		ContentArea.Visible = false
		TabBar.Visible = false
		PartSelector.Visible = false
	else
		TweenElement(MainFrame, {Size = UDim2.new(0, 440, 0, 620)}, 0.3)
		wait(0.3)
		ContentArea.Visible = true
		TabBar.Visible = true
		UpdatePartSelector()
	end
end)

undoBtn.MouseButton1Click:Connect(function()
	Undo()
end)

-- Hover effects for top bar buttons
for _, btn in ipairs({closeBtn, minimizeBtn, undoBtn}) do
	btn.MouseEnter:Connect(function()
		TweenElement(btn, {BackgroundTransparency = 0.5}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		TweenElement(btn, {BackgroundTransparency = 0.85}, 0.15)
	end)
end

-- ============================================================
-- DRAGGABLE MAIN FRAME
-- ============================================================
do
	local dragging = false
	local dragStart = nil
	local startPos = nil

	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			-- Don't drag if clicking buttons
			local pos = input.Position
			for _, btn in ipairs({closeBtn, minimizeBtn, undoBtn}) do
				local absPos = btn.AbsolutePosition
				local absSize = btn.AbsoluteSize
				if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and
					pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
					return
				end
			end
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- ============================================================
-- ANIMATION LOOP (RunService)
-- ============================================================
local animTime = 0
RunService.Heartbeat:Connect(function(dt)
	animTime = animTime + dt

	if not State.currentTool then return end
	local parts = GetTargetParts()
	if #parts == 0 then return end

	-- Rainbow
	if State.rainbowEnabled then
		local speed = State.rainbowSpeed or 1
		local hue = (animTime * speed * 0.1) % 1
		for _, part in ipairs(parts) do
			part.Color = Color3.fromHSV(hue, 1, 1)
		end
	end

	-- Color Pulse
	if State.pulseEnabled and not State.rainbowEnabled then
		local speed = State.pulseSpeed or 1
		local t = (math.sin(animTime * speed * math.pi) + 1) / 2
		local colorA = State.pulseColorA or THEME.Accent
		local colorB = State.pulseColorB or THEME.AccentSecondary
		local r = Lerp(colorA.R, colorB.R, t)
		local g = Lerp(colorA.G, colorB.G, t)
		local b = Lerp(colorA.B, colorB.B, t)
		for _, part in ipairs(parts) do
			part.Color = Color3.new(r, g, b)
		end
	end

	-- Flicker
	if State.flickerEnabled then
		local speed = State.flickerSpeed or 3
		local flicker = math.abs(math.sin(animTime * speed * math.pi))
		for _, part in ipairs(parts) do
			part.Transparency = Lerp(0, 0.6, 1 - flicker)
		end
	end

	-- Breathe (size pulse)
	if State.breatheEnabled then
		local amount = State.breatheAmount or 0.1
		local pulse = math.sin(animTime * 2) * amount
		for _, part in ipairs(parts) do
			local ox = part:GetAttribute("OrigSizeX") or part.Size.X
			local oy = part:GetAttribute("OrigSizeY") or part.Size.Y
			local oz = part:GetAttribute("OrigSizeZ") or part.Size.Z
			part.Size = Vector3.new(ox * (1 + pulse), oy * (1 + pulse), oz * (1 + pulse))
		end
	end

	-- Beam jitter for electric effect
	for _, part in ipairs(parts) do
		local beam = part:FindFirstChild("WE_Beam")
		if beam then
			beam.CurveSize0 = math.sin(animTime * 15) * 3
			beam.CurveSize1 = math.cos(animTime * 12) * -3
		end
	end

	-- Highlight animation
	if State.currentTool then
		local h = State.currentTool:FindFirstChild("WE_Highlight")
		if h then
			local pulse = (math.sin(animTime * 3) + 1) / 2
			h.OutlineTransparency = Lerp(0, 0.5, pulse)
		end
	end
end)

-- ============================================================
-- KEYBIND INFO
-- ============================================================
local keybindInfo = Instance.new("TextLabel")
keybindInfo.Size = UDim2.new(0, 200, 0, 20)
keybindInfo.Position = UDim2.new(0.5, -100, 1, -30)
keybindInfo.BackgroundTransparency = 1
keybindInfo.Text = "Press [F7] to toggle editor"
keybindInfo.TextSize = 11
keybindInfo.Font = Enum.Font.Gotham
keybindInfo.TextColor3 = THEME.TextDim
keybindInfo.TextTransparency = 0.3
keybindInfo.Parent = ScreenGui

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F7 then
		if MainFrame.Visible then
			TweenElement(MainFrame, {Position = UDim2.new(1, 0, 0.5, -310)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			wait(0.4)
			MainFrame.Visible = false
			WaitingFrame.Visible = true
		else
			if State.currentTool then
				MainFrame.Visible = true
				WaitingFrame.Visible = false
				MainFrame.Position = UDim2.new(1, 0, 0.5, -310)
				TweenElement(MainFrame, {Position = UDim2.new(1, -460, 0.5, -310)}, 0.5, Enum.EasingStyle.Back)
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Z and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		Undo()
	end
end)

-- ============================================================
-- STARTUP
-- ============================================================
print("═══════════════════════════════════════")
print("  ⚔️  WEAPON EDITOR v1.0 LOADED  ⚔️")
print("  Equip any tool to start editing!")
print("  Press F7 to toggle | Ctrl+Z to undo")
print("═══════════════════════════════════════") 
