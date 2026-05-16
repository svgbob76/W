-- StarterPlayerScripts > WEAPON EDITOR v2.0
-- Full Rebuild - Fixed Input, New Theme, Upgraded Everything

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

------------------------------------------------------------------------
-- THEME - Dark Industrial / Cyberpunk feel, NOT generic AI pastels
------------------------------------------------------------------------
local T = {
	Bg          = Color3.fromRGB(12, 12, 16),
	Surface     = Color3.fromRGB(20, 20, 28),
	Surface2    = Color3.fromRGB(28, 28, 38),
	Surface3    = Color3.fromRGB(36, 35, 48),
	Raised      = Color3.fromRGB(44, 42, 58),
	Primary     = Color3.fromRGB(255, 62, 62),     -- aggressive red
	PrimaryDim  = Color3.fromRGB(160, 35, 35),
	Secondary   = Color3.fromRGB(255, 160, 40),     -- warm amber
	Cyan        = Color3.fromRGB(0, 210, 210),
	Green       = Color3.fromRGB(40, 220, 100),
	Text        = Color3.fromRGB(225, 220, 215),
	TextSub     = Color3.fromRGB(130, 125, 135),
	TextDark    = Color3.fromRGB(70, 68, 78),
	Divider     = Color3.fromRGB(50, 48, 62),
	Danger      = Color3.fromRGB(220, 50, 50),
	Slider      = Color3.fromRGB(38, 36, 50),
}

------------------------------------------------------------------------
-- STATE
------------------------------------------------------------------------
local State = {
	tool = nil,
	parts = {},
	partIndex = 0,   -- 0 = ALL
	tab = "SCALE",
	history = {},
	histIdx = 0,
	-- animation flags
	rainbow = false, rainbowSpd = 1,
	pulse = false, pulseA = T.Primary, pulseB = T.Cyan, pulseSpd = 1,
	flicker = false, flickerSpd = 3,
	breathe = false, breatheAmt = 0.08,
	-- effect flags
	fireOn = false, sparkOn = false, smokeOn = false,
	lightOn = false, trailOn = false, particleOn = false,
	glowOn = false, beamOn = false, highlightOn = false,
}

------------------------------------------------------------------------
-- UTILITY
------------------------------------------------------------------------
local function Lerp(a,b,t) return a+(b-a)*t end

local function Corner(p,r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,r or 6); c.Parent = p; return c
end

local function Stroke(p,col,th,tr)
	local s = Instance.new("UIStroke"); s.Color = col or T.Divider; s.Thickness = th or 1; s.Transparency = tr or 0.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

local function Pad(p,n)
	local pd = Instance.new("UIPadding"); pd.PaddingTop=UDim.new(0,n); pd.PaddingBottom=UDim.new(0,n); pd.PaddingLeft=UDim.new(0,n); pd.PaddingRight=UDim.new(0,n); pd.Parent=p; return pd
end

local function Tw(obj,props,dur,style)
	local tw = TweenService:Create(obj, TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play(); return tw
end

local function SaveState()
	if not State.tool then return end
	local snap = {}
	for _,p in ipairs(State.parts) do
		if p:IsA("BasePart") then
			table.insert(snap,{P=p,S=p.Size,C=p.Color,M=p.Material,Tr=p.Transparency,Re=p.Reflectance})
		end
	end
	State.histIdx += 1
	State.history[State.histIdx] = snap
	for i = State.histIdx+1, #State.history do State.history[i]=nil end
end

local function Undo()
	if State.histIdx < 1 then return end
	local snap = State.history[State.histIdx]
	if snap then
		for _,d in ipairs(snap) do
			if d.P and d.P.Parent then
				d.P.Size=d.S; d.P.Color=d.C; d.P.Material=d.M; d.P.Transparency=d.Tr; d.P.Reflectance=d.Re
			end
		end
	end
	State.histIdx = math.max(0, State.histIdx-1)
end

local function GetParts()
	if not State.tool then return {} end
	local t = {}
	for _,c in ipairs(State.tool:GetDescendants()) do
		if c:IsA("BasePart") then table.insert(t,c) end
	end
	return t
end

local function Apply(fn)
	if State.partIndex == 0 then
		for _,p in ipairs(State.parts) do if p:IsA("BasePart") then fn(p) end end
	else
		local p = State.parts[State.partIndex]
		if p and p:IsA("BasePart") then fn(p) end
	end
end

------------------------------------------------------------------------
-- SCREEN GUI - DisplayOrder high, IgnoreGuiInset, Modal where needed
------------------------------------------------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "WeaponEditorV2"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 100
Gui.IgnoreGuiInset = true
Gui.Parent = player.PlayerGui

------------------------------------------------------------------------
-- WAITING INDICATOR
------------------------------------------------------------------------
local WaitFrame = Instance.new("Frame")
WaitFrame.Size = UDim2.new(0,280,0,52)
WaitFrame.Position = UDim2.new(0.5,-140,0,16)
WaitFrame.BackgroundColor3 = T.Surface
WaitFrame.Parent = Gui
Corner(WaitFrame,8)
Stroke(WaitFrame, T.Primary, 1, 0.6)

local waitBar = Instance.new("Frame")
waitBar.Size = UDim2.new(1,0,0,2)
waitBar.Position = UDim2.new(0,0,1,-2)
waitBar.BackgroundColor3 = T.Primary
waitBar.BorderSizePixel = 0
waitBar.Parent = WaitFrame

local waitText = Instance.new("TextLabel")
waitText.Size = UDim2.new(1,-16,1,0)
waitText.Position = UDim2.new(0,8,0,0)
waitText.BackgroundTransparency = 1
waitText.Text = "⚔  WEAPON EDITOR  —  equip a tool"
waitText.Font = Enum.Font.GothamBold
waitText.TextSize = 13
waitText.TextColor3 = T.TextSub
waitText.TextXAlignment = Enum.TextXAlignment.Left
waitText.Parent = WaitFrame

-- pulse the bar
spawn(function()
	while Gui.Parent do
		Tw(waitBar,{BackgroundTransparency=0.7},0.8)
		task.wait(0.8)
		Tw(waitBar,{BackgroundTransparency=0},0.8)
		task.wait(0.8)
	end
end)

------------------------------------------------------------------------
-- MAIN FRAME
------------------------------------------------------------------------
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0,390,0,560)
Main.Position = UDim2.new(1,-410,0.5,-280)
Main.BackgroundColor3 = T.Bg
Main.Visible = false
Main.Active = true           -- *** BLOCKS INPUT FROM GOING THROUGH ***
Main.Parent = Gui
Corner(Main,10)
Stroke(Main, T.Divider, 1, 0.3)

-- Clip children so nothing leaks
Main.ClipsDescendants = true

------------------------------------------------------------------------
-- TOP BAR (draggable)
------------------------------------------------------------------------
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1,0,0,42)
TopBar.BackgroundColor3 = T.Surface
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.Parent = Main
Corner(TopBar,10)

-- bottom fix for rounded corners
local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1,0,0,12)
tbFix.Position = UDim2.new(0,0,1,-12)
tbFix.BackgroundColor3 = T.Surface
tbFix.BorderSizePixel = 0
tbFix.Parent = TopBar

-- red accent line
local redLine = Instance.new("Frame")
redLine.Size = UDim2.new(1,0,0,2)
redLine.Position = UDim2.new(0,0,1,-2)
redLine.BackgroundColor3 = T.Primary
redLine.BorderSizePixel = 0
redLine.Parent = TopBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-120,1,0)
title.Position = UDim2.new(0,14,0,0)
title.BackgroundTransparency = 1
title.RichText = true
title.Text = '<font color="#ff3e3e">⚔</font>  WEAPON EDITOR'
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.TextColor3 = T.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = TopBar

-- tool name
local toolLabel = Instance.new("TextLabel")
toolLabel.Name = "ToolLabel"
toolLabel.Size = UDim2.new(1,-120,0,14)
toolLabel.Position = UDim2.new(0,28,0,26)
toolLabel.BackgroundTransparency = 1
toolLabel.Text = ""
toolLabel.Font = Enum.Font.Gotham
toolLabel.TextSize = 10
toolLabel.TextColor3 = T.TextSub
toolLabel.TextXAlignment = Enum.TextXAlignment.Left
toolLabel.Parent = TopBar

-- top bar buttons
local function TopBtn(name,txt,col,xOff)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.new(0,28,0,28)
	b.Position = UDim2.new(1,xOff,0,7)
	b.BackgroundColor3 = col
	b.BackgroundTransparency = 0.85
	b.Text = txt
	b.TextSize = 14
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = col
	b.Active = true
	b.Parent = TopBar
	Corner(b,6)
	b.MouseEnter:Connect(function() Tw(b,{BackgroundTransparency=0.6},0.12) end)
	b.MouseLeave:Connect(function() Tw(b,{BackgroundTransparency=0.85},0.12) end)
	return b
end

local btnClose = TopBtn("Close","✕",T.Danger,-38)
local btnMin   = TopBtn("Min","—",T.Secondary,-70)
local btnUndo  = TopBtn("Undo","↩",T.Cyan,-102)

------------------------------------------------------------------------
-- DRAGGING
------------------------------------------------------------------------
do
	local dragging,dragStart,startPos = false,nil,nil
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local pos = input.Position
			for _,b in ipairs({btnClose,btnMin,btnUndo}) do
				local ap,as = b.AbsolutePosition, b.AbsoluteSize
				if pos.X>=ap.X and pos.X<=ap.X+as.X and pos.Y>=ap.Y and pos.Y<=ap.Y+as.Y then return end
			end
			dragging=true; dragStart=pos; startPos=Main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)
end

------------------------------------------------------------------------
-- PART SELECTOR BAR
------------------------------------------------------------------------
local PartBar = Instance.new("Frame")
PartBar.Name = "PartBar"
PartBar.Size = UDim2.new(1,-16,0,30)
PartBar.Position = UDim2.new(0,8,0,46)
PartBar.BackgroundTransparency = 1
PartBar.Active = true
PartBar.Parent = Main

local partScroll = Instance.new("ScrollingFrame")
partScroll.Size = UDim2.new(1,0,1,0)
partScroll.BackgroundTransparency = 1
partScroll.ScrollBarThickness = 0
partScroll.CanvasSize = UDim2.new(0,0,0,0)
partScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
partScroll.ScrollingDirection = Enum.ScrollingDirection.X
partScroll.Active = true
partScroll.Parent = PartBar

local partLayout = Instance.new("UIListLayout")
partLayout.FillDirection = Enum.FillDirection.Horizontal
partLayout.Padding = UDim.new(0,3)
partLayout.Parent = partScroll

------------------------------------------------------------------------
-- TAB BAR
------------------------------------------------------------------------
local TabFrame = Instance.new("Frame")
TabFrame.Name = "TabFrame"
TabFrame.Size = UDim2.new(1,-16,0,28)
TabFrame.Position = UDim2.new(0,8,0,80)
TabFrame.BackgroundTransparency = 1
TabFrame.Active = true
TabFrame.Parent = Main

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Size = UDim2.new(1,0,1,0)
tabScroll.BackgroundTransparency = 1
tabScroll.ScrollBarThickness = 0
tabScroll.CanvasSize = UDim2.new(0,0,0,0)
tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabScroll.Active = true
tabScroll.Parent = TabFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,2)
tabLayout.Parent = tabScroll

-- divider under tabs
local tabDiv = Instance.new("Frame")
tabDiv.Size = UDim2.new(1,-16,0,1)
tabDiv.Position = UDim2.new(0,8,0,111)
tabDiv.BackgroundColor3 = T.Divider
tabDiv.BackgroundTransparency = 0.5
tabDiv.BorderSizePixel = 0
tabDiv.Parent = Main

------------------------------------------------------------------------
-- CONTENT SCROLL
------------------------------------------------------------------------
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1,-16,1,-120)
Content.Position = UDim2.new(0,8,0,116)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = T.Primary
Content.ScrollBarImageTransparency = 0.3
Content.CanvasSize = UDim2.new(0,0,0,0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Active = true
Content.Parent = Main
Pad(Content, 4)

local cLayout = Instance.new("UIListLayout")
cLayout.Padding = UDim.new(0,5)
cLayout.SortOrder = Enum.SortOrder.LayoutOrder
cLayout.Parent = Content

------------------------------------------------------------------------
-- WIDGET BUILDERS
------------------------------------------------------------------------

local MATS = {"Plastic","SmoothPlastic","Neon","Glass","ForceField","Metal","DiamondPlate",
	"Foil","CorrodedMetal","Wood","WoodPlanks","Marble","Granite","Brick","Cobblestone",
	"Slate","Concrete","Sand","Pebble","Grass","Ice","Fabric"}

local function Header(text, ord)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,22)
	f.BackgroundTransparency = 1
	f.LayoutOrder = ord or 0
	f.Parent = Content

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,0,1,0)
	l.BackgroundTransparency = 1
	l.Text = string.upper(text)
	l.Font = Enum.Font.GothamBlack
	l.TextSize = 10
	l.TextColor3 = T.Primary
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1,0,0,1)
	line.Position = UDim2.new(0,0,1,-1)
	line.BackgroundColor3 = T.Primary
	line.BackgroundTransparency = 0.75
	line.BorderSizePixel = 0
	line.Parent = f
	return f
end

local function Slider(label,min,max,def,step,ord,cb)
	local c = Instance.new("Frame")
	c.Size = UDim2.new(1,0,0,42)
	c.BackgroundColor3 = T.Surface2
	c.LayoutOrder = ord or 0
	c.Active = true
	c.Parent = Content
	Corner(c,6)

	local nm = Instance.new("TextLabel")
	nm.Size = UDim2.new(0.55,0,0,18)
	nm.Position = UDim2.new(0,10,0,2)
	nm.BackgroundTransparency = 1
	nm.Text = label
	nm.Font = Enum.Font.GothamMedium
	nm.TextSize = 11
	nm.TextColor3 = T.Text
	nm.TextXAlignment = Enum.TextXAlignment.Left
	nm.Parent = c

	local vl = Instance.new("TextLabel")
	vl.Name = "Val"
	vl.Size = UDim2.new(0.44,-10,0,18)
	vl.Position = UDim2.new(0.55,0,0,2)
	vl.BackgroundTransparency = 1
	vl.Text = tostring(def)
	vl.Font = Enum.Font.GothamBold
	vl.TextSize = 11
	vl.TextColor3 = T.Secondary
	vl.TextXAlignment = Enum.TextXAlignment.Right
	vl.Parent = c

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1,-20,0,6)
	track.Position = UDim2.new(0,10,0,26)
	track.BackgroundColor3 = T.Slider
	track.BorderSizePixel = 0
	track.Active = true
	track.Parent = c
	Corner(track,3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(math.clamp((def-min)/(max-min),0,1),0,1,0)
	fill.BackgroundColor3 = T.Primary
	fill.BorderSizePixel = 0
	fill.Parent = track
	Corner(fill,3)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0,12,0,12)
	knob.AnchorPoint = Vector2.new(0.5,0.5)
	knob.Position = UDim2.new(math.clamp((def-min)/(max-min),0,1),0,0.5,0)
	knob.BackgroundColor3 = T.Text
	knob.Active = true
	knob.ZIndex = 3
	knob.Parent = track
	Corner(knob,6)

	local dragging = false
	local val = def

	local function update(input)
		local rx = math.clamp((input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
		local raw = Lerp(min,max,rx)
		if step then raw = math.floor(raw/step+0.5)*step end
		raw = math.clamp(raw,min,max)
		val = raw
		local frac = (raw-min)/(max-min)
		fill.Size = UDim2.new(frac,0,1,0)
		knob.Position = UDim2.new(frac,0,0.5,0)
		vl.Text = step and step>=1 and tostring(math.floor(raw)) or string.format("%.2f",raw)
		if cb then cb(raw) end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true; SaveState(); update(input)
		end
	end)
	knob.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true; SaveState()
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			update(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)

	return c
end

local function Toggle(label, def, ord, cb)
	local c = Instance.new("Frame")
	c.Size = UDim2.new(1,0,0,32)
	c.BackgroundColor3 = T.Surface2
	c.LayoutOrder = ord or 0
	c.Active = true
	c.Parent = Content
	Corner(c,6)

	local nm = Instance.new("TextLabel")
	nm.Size = UDim2.new(1,-60,1,0)
	nm.Position = UDim2.new(0,10,0,0)
	nm.BackgroundTransparency = 1
	nm.Text = label
	nm.Font = Enum.Font.GothamMedium
	nm.TextSize = 11
	nm.TextColor3 = T.Text
	nm.TextXAlignment = Enum.TextXAlignment.Left
	nm.Parent = c

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0,36,0,18)
	bg.Position = UDim2.new(1,-46,0.5,-9)
	bg.BackgroundColor3 = def and T.Primary or T.Slider
	bg.Parent = c
	Corner(bg,9)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0,14,0,14)
	dot.Position = def and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
	dot.BackgroundColor3 = T.Text
	dot.Parent = bg
	Corner(dot,7)

	local on = def or false
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,0,1,0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Active = true
	btn.Parent = c

	btn.MouseButton1Click:Connect(function()
		on = not on
		Tw(bg,{BackgroundColor3 = on and T.Primary or T.Slider},0.2)
		Tw(dot,{Position = on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)},0.2)
		if cb then cb(on) end
	end)

	return c
end

local function ColorPick(label, def, ord, cb)
	local c = Instance.new("Frame")
	c.Size = UDim2.new(1,0,0,110)
	c.BackgroundColor3 = T.Surface2
	c.LayoutOrder = ord or 0
	c.Active = true
	c.Parent = Content
	Corner(c,6)

	local nm = Instance.new("TextLabel")
	nm.Size = UDim2.new(0.6,0,0,20)
	nm.Position = UDim2.new(0,10,0,3)
	nm.BackgroundTransparency = 1
	nm.Text = label
	nm.Font = Enum.Font.GothamMedium
	nm.TextSize = 11
	nm.TextColor3 = T.Text
	nm.TextXAlignment = Enum.TextXAlignment.Left
	nm.Parent = c

	local prev = Instance.new("Frame")
	prev.Size = UDim2.new(0,24,0,14)
	prev.Position = UDim2.new(1,-36,0,5)
	prev.BackgroundColor3 = def or Color3.new(1,1,1)
	prev.Parent = c
	Corner(prev,4)
	Stroke(prev,T.Divider,1,0.3)

	local cur = def or Color3.new(1,1,1)
	local chNames = {"R","G","B"}
	local chCols = {Color3.fromRGB(220,60,60), Color3.fromRGB(60,200,80), Color3.fromRGB(60,100,220)}
	local sliders = {}

	for i=1,3 do
		local y = 24 + (i-1)*28
		local defV = ({cur.R,cur.G,cur.B})[i]

		local cl = Instance.new("TextLabel")
		cl.Size=UDim2.new(0,14,0,16); cl.Position=UDim2.new(0,10,0,y)
		cl.BackgroundTransparency=1; cl.Text=chNames[i]; cl.Font=Enum.Font.GothamBold
		cl.TextSize=10; cl.TextColor3=chCols[i]; cl.Parent=c

		local tr = Instance.new("Frame")
		tr.Size=UDim2.new(1,-70,0,6); tr.Position=UDim2.new(0,28,0,y+5)
		tr.BackgroundColor3=T.Slider; tr.BorderSizePixel=0; tr.Active=true; tr.Parent=c
		Corner(tr,3)

		local fl = Instance.new("Frame")
		fl.Size=UDim2.new(defV,0,1,0); fl.BackgroundColor3=chCols[i]; fl.BorderSizePixel=0; fl.Parent=tr
		Corner(fl,3)

		local vl = Instance.new("TextLabel")
		vl.Size=UDim2.new(0,30,0,16); vl.Position=UDim2.new(1,-34,0,y)
		vl.BackgroundTransparency=1; vl.Text=tostring(math.floor(defV*255))
		vl.Font=Enum.Font.GothamMedium; vl.TextSize=10; vl.TextColor3=T.TextSub
		vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=c

		sliders[i] = {track=tr, fill=fl, val=defV, label=vl}

		local isDrag = false
		tr.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
				isDrag=true; SaveState()
				local rx = math.clamp((input.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
				sliders[i].val=rx; fl.Size=UDim2.new(rx,0,1,0); vl.Text=tostring(math.floor(rx*255))
				cur=Color3.new(sliders[1].val,sliders[2].val,sliders[3].val); prev.BackgroundColor3=cur
				if cb then cb(cur) end
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if isDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
				local rx = math.clamp((input.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
				sliders[i].val=rx; fl.Size=UDim2.new(rx,0,1,0); vl.Text=tostring(math.floor(rx*255))
				cur=Color3.new(sliders[1].val,sliders[2].val,sliders[3].val); prev.BackgroundColor3=cur
				if cb then cb(cur) end
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then isDrag=false end
		end)
	end
	return c
end

local function Dropdown(label, opts, def, ord, cb)
	local expanded = false
	local c = Instance.new("Frame")
	c.Size = UDim2.new(1,0,0,34)
	c.BackgroundColor3 = T.Surface2
	c.LayoutOrder = ord or 0
	c.ClipsDescendants = true
	c.Active = true
	c.Parent = Content
	Corner(c,6)

	local nm = Instance.new("TextLabel")
	nm.Size=UDim2.new(0.5,0,0,34); nm.Position=UDim2.new(0,10,0,0)
	nm.BackgroundTransparency=1; nm.Text=label; nm.Font=Enum.Font.GothamMedium
	nm.TextSize=11; nm.TextColor3=T.Text; nm.TextXAlignment=Enum.TextXAlignment.Left; nm.Parent=c

	local sel = Instance.new("TextLabel")
	sel.Size=UDim2.new(0.4,-16,0,34); sel.Position=UDim2.new(0.5,0,0,0)
	sel.BackgroundTransparency=1; sel.Text=def or opts[1]; sel.Font=Enum.Font.GothamBold
	sel.TextSize=11; sel.TextColor3=T.Secondary; sel.TextXAlignment=Enum.TextXAlignment.Right; sel.Parent=c

	local arr = Instance.new("TextLabel")
	arr.Size=UDim2.new(0,16,0,34); arr.Position=UDim2.new(1,-20,0,0)
	arr.BackgroundTransparency=1; arr.Text="▾"; arr.Font=Enum.Font.GothamBold
	arr.TextSize=12; arr.TextColor3=T.TextDark; arr.Parent=c

	local optFrame = Instance.new("ScrollingFrame")
	optFrame.Size = UDim2.new(1,-12,0, math.min(#opts*26+4, 180))
	optFrame.Position = UDim2.new(0,6,0,36)
	optFrame.BackgroundColor3 = T.Bg
	optFrame.ScrollBarThickness = 2
	optFrame.ScrollBarImageColor3 = T.Primary
	optFrame.CanvasSize = UDim2.new(0,0,0, #opts*26+4)
	optFrame.Active = true
	optFrame.Parent = c
	Corner(optFrame,4)
	Pad(optFrame,2)

	local oLayout = Instance.new("UIListLayout")
	oLayout.Padding = UDim.new(0,2)
	oLayout.Parent = optFrame

	for _,opt in ipairs(opts) do
		local ob = Instance.new("TextButton")
		ob.Size = UDim2.new(1,0,0,22)
		ob.BackgroundColor3 = T.Surface3
		ob.BackgroundTransparency = 0.5
		ob.Text = opt
		ob.TextSize = 10
		ob.Font = Enum.Font.Gotham
		ob.TextColor3 = T.Text
		ob.Active = true
		ob.Parent = optFrame
		Corner(ob,4)

		ob.MouseEnter:Connect(function() Tw(ob,{BackgroundColor3=T.Primary, BackgroundTransparency=0.3},0.1) end)
		ob.MouseLeave:Connect(function() Tw(ob,{BackgroundColor3=T.Surface3, BackgroundTransparency=0.5},0.1) end)
		ob.MouseButton1Click:Connect(function()
			sel.Text=opt; expanded=false
			Tw(c,{Size=UDim2.new(1,0,0,34)},0.2); arr.Text="▾"
			SaveState()
			if cb then cb(opt) end
		end)
	end

	local hdr = Instance.new("TextButton")
	hdr.Size=UDim2.new(1,0,0,34); hdr.BackgroundTransparency=1; hdr.Text=""; hdr.Active=true; hdr.Parent=c
	hdr.MouseButton1Click:Connect(function()
		expanded = not expanded
		local h = expanded and (34 + math.min(#opts*26+8, 184)) or 34
		Tw(c,{Size=UDim2.new(1,0,0,h)},0.25)
		arr.Text = expanded and "▴" or "▾"
	end)

	return c
end

local function Btn(label, ord, col, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,32)
	b.BackgroundColor3 = col or T.Primary
	b.BackgroundTransparency = 0.25
	b.Text = label
	b.TextSize = 12
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = T.Text
	b.LayoutOrder = ord or 0
	b.Active = true
	b.Parent = Content
	Corner(b,6)

	b.MouseEnter:Connect(function() Tw(b,{BackgroundTransparency=0.05},0.1) end)
	b.MouseLeave:Connect(function() Tw(b,{BackgroundTransparency=0.25},0.1) end)
	b.MouseButton1Click:Connect(function()
		Tw(b,{BackgroundTransparency=0.5},0.05)
		task.wait(0.06)
		Tw(b,{BackgroundTransparency=0.25},0.1)
		if cb then cb() end
	end)
	return b
end

-- quick color row builder
local function QuickColors(ord)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,30)
	f.BackgroundTransparency = 1
	f.LayoutOrder = ord or 0
	f.Active = true
	f.Parent = Content

	local fl = Instance.new("UIListLayout")
	fl.FillDirection = Enum.FillDirection.Horizontal
	fl.Padding = UDim.new(0,3)
	fl.HorizontalAlignment = Enum.HorizontalAlignment.Left
	fl.Parent = f

	local colors = {
		Color3.fromRGB(220,30,30),  Color3.fromRGB(255,120,0),  Color3.fromRGB(255,220,0),
		Color3.fromRGB(30,200,60),  Color3.fromRGB(0,180,220),  Color3.fromRGB(40,80,220),
		Color3.fromRGB(130,40,200), Color3.fromRGB(220,40,130), Color3.fromRGB(240,240,240),
		Color3.fromRGB(20,20,20),   Color3.fromRGB(200,170,50), Color3.fromRGB(100,100,100),
	}
	for _,col in ipairs(colors) do
		local cb = Instance.new("TextButton")
		cb.Size = UDim2.new(0,26,0,26)
		cb.BackgroundColor3 = col
		cb.Text = ""
		cb.Active = true
		cb.Parent = f
		Corner(cb,4)
		Stroke(cb, T.Divider, 1, 0.6)
		cb.MouseButton1Click:Connect(function()
			SaveState()
			Apply(function(p) p.Color = col end)
		end)
	end
	return f
end

------------------------------------------------------------------------
-- TAB CONTENT BUILDERS
------------------------------------------------------------------------

local function Clear()
	for _,ch in ipairs(Content:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
	end
end

local function BuildScale()
	Clear()
	Header("INDIVIDUAL AXIS", 1)
	Slider("X Scale", 0.1, 8, 1, 0.05, 2, function(v) Apply(function(p) local o=p:GetAttribute("OX") or p.Size.X; p:SetAttribute("OX",o); p.Size=Vector3.new(o*v,p.Size.Y,p.Size.Z) end) end)
	Slider("Y Scale", 0.1, 8, 1, 0.05, 3, function(v) Apply(function(p) local o=p:GetAttribute("OY") or p.Size.Y; p:SetAttribute("OY",o); p.Size=Vector3.new(p.Size.X,o*v,p.Size.Z) end) end)
	Slider("Z Scale", 0.1, 8, 1, 0.05, 4, function(v) Apply(function(p) local o=p:GetAttribute("OZ") or p.Size.Z; p:SetAttribute("OZ",o); p.Size=Vector3.new(p.Size.X,p.Size.Y,o*v) end) end)
	Header("UNIFORM", 5)
	Slider("All Axes", 0.1, 8, 1, 0.05, 6, function(v)
		Apply(function(p)
			local ox=p:GetAttribute("OX") or p.Size.X; local oy=p:GetAttribute("OY") or p.Size.Y; local oz=p:GetAttribute("OZ") or p.Size.Z
			p:SetAttribute("OX",ox); p:SetAttribute("OY",oy); p:SetAttribute("OZ",oz)
			p.Size = Vector3.new(ox*v,oy*v,oz*v)
		end)
	end)
	Header("PROPERTIES", 7)
	Slider("Transparency", 0, 1, 0, 0.01, 8, function(v) Apply(function(p) p.Transparency=v end) end)
	Slider("Reflectance", 0, 1, 0, 0.01, 9, function(v) Apply(function(p) p.Reflectance=v end) end)
	Toggle("Anchored", false, 10, function(v) Apply(function(p) p.Anchored=v end) end)
	Toggle("CanCollide", true, 11, function(v) Apply(function(p) p.CanCollide=v end) end)
	Toggle("CastShadow", true, 12, function(v) Apply(function(p) p.CastShadow=v end) end)
	Btn("↩  Reset Sizes", 13, T.Raised, function()
		Apply(function(p) local ox,oy,oz=p:GetAttribute("OX"),p:GetAttribute("OY"),p:GetAttribute("OZ"); if ox and oy and oz then p.Size=Vector3.new(ox,oy,oz) end end)
	end)
end

local function BuildLook()
	Clear()
	Header("QUICK COLORS", 1)
	QuickColors(2)
	Header("CUSTOM COLOR", 3)
	ColorPick("Part Color", Color3.new(1,1,1), 4, function(c) Apply(function(p) p.Color=c end) end)
	Header("MATERIAL", 5)
	Dropdown("Material", MATS, "SmoothPlastic", 6, function(m) Apply(function(p) p.Material=Enum.Material[m] end) end)
	Header("SURFACE TYPE", 7)
	local surfs = {"Smooth","Glue","Weld","Studs","Inlet","Universal","Hinge","Motor"}
	Dropdown("Top Surface", surfs, "Smooth", 8, function(s) Apply(function(p) p.TopSurface=Enum.SurfaceType[s] end) end)
	Dropdown("Bottom Surface", surfs, "Smooth", 9, function(s) Apply(function(p) p.BottomSurface=Enum.SurfaceType[s] end) end)
	Header("CLEANUP", 10)
	Toggle("Remove Textures/Decals", false, 11, function(v) if v then Apply(function(p) for _,ch in ipairs(p:GetChildren()) do if ch:IsA("Texture") or ch:IsA("Decal") then ch:Destroy() end end end) end end)
	Toggle("Remove Meshes", false, 12, function(v) if v then Apply(function(p) for _,ch in ipairs(p:GetChildren()) do if ch:IsA("DataModelMesh") then ch:Destroy() end end end) end end)
end

local function BuildFX()
	Clear()
	Header("FIRE", 1)
	Toggle("Enable Fire", false, 2, function(v) State.fireOn=v; Apply(function(p) local e=p:FindFirstChild("WE_Fire"); if v then if not e then e=Instance.new("Fire"); e.Name="WE_Fire"; e.Size=6; e.Heat=12; e.Color=Color3.fromRGB(255,100,0); e.SecondaryColor=Color3.fromRGB(255,200,0); e.Parent=p end else if e then e:Destroy() end end end) end)
	Slider("Fire Size", 1, 40, 6, 0.5, 3, function(v) Apply(function(p) local e=p:FindFirstChild("WE_Fire"); if e then e.Size=v end end) end)
	Slider("Fire Heat", 0, 30, 12, 1, 4, function(v) Apply(function(p) local e=p:FindFirstChild("WE_Fire"); if e then e.Heat=v end end) end)
	ColorPick("Fire Color", Color3.fromRGB(255,100,0), 5, function(c) Apply(function(p) local e=p:FindFirstChild("WE_Fire"); if e then e.Color=c end end) end)

	Header("SPARKLES", 6)
	Toggle("Enable Sparkles", false, 7, function(v) State.sparkOn=v; Apply(function(p) local e=p:FindFirstChild("WE_Spark"); if v then if not e then e=Instance.new("Sparkles"); e.Name="WE_Spark"; e.SparkleColor=Color3.fromRGB(255,255,100); e.Parent=p end else if e then e:Destroy() end end end) end)
	ColorPick("Sparkle Color", Color3.fromRGB(255,255,100), 8, function(c) Apply(function(p) local e=p:FindFirstChild("WE_Spark"); if e then e.SparkleColor=c end end) end)

	Header("SMOKE", 9)
	Toggle("Enable Smoke", false, 10, function(v) State.smokeOn=v; Apply(function(p) local e=p:FindFirstChild("WE_Smoke"); if v then if not e then e=Instance.new("Smoke"); e.Name="WE_Smoke"; e.Size=2; e.Opacity=0.3; e.RiseVelocity=2; e.Parent=p end else if e then e:Destroy() end end end) end)
	Slider("Smoke Size", 0.5, 20, 2, 0.5, 11, function(v) Apply(function(p) local e=p:FindFirstChild("WE_Smoke"); if e then e.Size=v end end) end)
	Slider("Smoke Opacity", 0, 1, 0.3, 0.01, 12, function(v) Apply(function(p) local e=p:FindFirstChild("WE_Smoke"); if e then e.Opacity=v end end) end)
	ColorPick("Smoke Color", Color3.fromRGB(180,180,180), 13, function(c) Apply(function(p) local e=p:FindFirstChild("WE_Smoke"); if e then e.Color=c end end) end)

	Header("LIGHT", 14)
	Toggle("Point Light", false, 15, function(v) State.lightOn=v; Apply(function(p) local e=p:FindFirstChild("WE_Light"); if v then if not e then e=Instance.new("PointLight"); e.Name="WE_Light"; e.Brightness=2; e.Range=20; e.Parent=p end else if e then e:Destroy() end end end) end)
	Slider("Brightness", 0, 10, 2, 0.1, 16, function(v) Apply(function(p) local e=p:FindFirstChild("WE_Light"); if e then e.Brightness=v end end) end)
	Slider("Range", 1, 80, 20, 1, 17, function(v) Apply(function(p) local e=p:FindFirstChild("WE_Light"); if e then e.Range=v end end) end)
	ColorPick("Light Color", Color3.new(1,1,1), 18, function(c) Apply(function(p) local e=p:FindFirstChild("WE_Light"); if e then e.Color=c end end) end)

	Header("TRAIL", 19)
	Toggle("Enable Trail", false, 20, function(v) State.trailOn=v
		Apply(function(p)
			local t=p:FindFirstChild("WE_Trail"); local a0=p:FindFirstChild("WE_A0"); local a1=p:FindFirstChild("WE_A1")
			if v then
				if not a0 then a0=Instance.new("Attachment"); a0.Name="WE_A0"; a0.Position=Vector3.new(0,p.Size.Y/2,0); a0.Parent=p end
				if not a1 then a1=Instance.new("Attachment"); a1.Name="WE_A1"; a1.Position=Vector3.new(0,-p.Size.Y/2,0); a1.Parent=p end
				if not t then
					t=Instance.new("Trail"); t.Name="WE_Trail"; t.Attachment0=a0; t.Attachment1=a1
					t.Lifetime=0.5; t.MinLength=0.05; t.LightEmission=0.6
					t.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.Primary),ColorSequenceKeypoint.new(1,T.Cyan)})
					t.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
					t.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
					t.Parent=p
				end
			else
				if t then t:Destroy() end; if a0 then a0:Destroy() end; if a1 then a1:Destroy() end
			end
		end)
	end)
	Slider("Trail Lifetime", 0.05, 4, 0.5, 0.05, 21, function(v) Apply(function(p) local e=p:FindFirstChild("WE_Trail"); if e then e.Lifetime=v end end) end)

	Header("PARTICLES", 22)
	Toggle("Particle Emitter", false, 23, function(v) State.particleOn=v
		Apply(function(p)
			local e=p:FindFirstChild("WE_PE")
			if v then
				if not e then
					e=Instance.new("ParticleEmitter"); e.Name="WE_PE"; e.Rate=30
					e.Speed=NumberRange.new(2,5); e.Lifetime=NumberRange.new(0.5,1.5)
					e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,0)})
					e.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.Primary),ColorSequenceKeypoint.new(1,T.Secondary)})
					e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
					e.LightEmission=0.7; e.SpreadAngle=Vector2.new(360,360)
					e.Parent=p
				end
			else if e then e:Destroy() end end
		end)
	end)
	Slider("Rate", 1, 300, 30, 1, 24, function(v) Apply(function(p) local e=p:FindFirstChild("WE_PE"); if e then e.Rate=v end end) end)
	Slider("Speed", 0, 30, 4, 0.5, 25, function(v) Apply(function(p) local e=p:FindFirstChild("WE_PE"); if e then e.Speed=NumberRange.new(v*0.4,v) end end) end)
	Slider("Part Size", 0.05, 5, 0.4, 0.05, 26, function(v) Apply(function(p) local e=p:FindFirstChild("WE_PE"); if e then e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,v),NumberSequenceKeypoint.new(1,0)}) end end) end)

	Header("BEAM", 27)
	Toggle("Electric Beam", false, 28, function(v) State.beamOn=v
		Apply(function(p)
			local b=p:FindFirstChild("WE_Beam"); local a0=p:FindFirstChild("WE_BA0"); local a1=p:FindFirstChild("WE_BA1")
			if v then
				if not a0 then a0=Instance.new("Attachment"); a0.Name="WE_BA0"; a0.Position=Vector3.new(0,p.Size.Y/2,0); a0.Parent=p end
				if not a1 then a1=Instance.new("Attachment"); a1.Name="WE_BA1"; a1.Position=Vector3.new(0,-p.Size.Y/2,0); a1.Parent=p end
				if not b then
					b=Instance.new("Beam"); b.Name="WE_Beam"; b.Attachment0=a0; b.Attachment1=a1
					b.Width0=0.3; b.Width1=0.3; b.LightEmission=1; b.FaceCamera=true; b.Segments=20
					b.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(100,200,255)),ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,200,255))})
					b.Transparency=NumberSequence.new(0.2); b.CurveSize0=2; b.CurveSize1=-2; b.Parent=p
				end
			else
				if b then b:Destroy() end; if a0 then a0:Destroy() end; if a1 then a1:Destroy() end
			end
		end)
	end)

	Header("SELECTION BOX", 29)
	Toggle("Glow Outline", false, 30, function(v) State.glowOn=v
		Apply(function(p)
			local e=p:FindFirstChild("WE_SB")
			if v then
				if not e then e=Instance.new("SelectionBox"); e.Name="WE_SB"; e.Adornee=p; e.Color3=T.Primary; e.LineThickness=0.03; e.Transparency=0.3; e.SurfaceTransparency=0.85; e.SurfaceColor3=T.Primary; e.Parent=p end
			else if e then e:Destroy() end end
		end)
	end)

	Header("HIGHLIGHT", 31)
	Toggle("Tool Highlight", false, 32, function(v) State.highlightOn=v
		if not State.tool then return end
		local e=State.tool:FindFirstChild("WE_HL")
		if v then
			if not e then e=Instance.new("Highlight"); e.Name="WE_HL"; e.FillTransparency=0.7; e.OutlineTransparency=0; e.FillColor=T.Primary; e.OutlineColor=T.Cyan; e.Adornee=State.tool; e.Parent=State.tool end
		else if e then e:Destroy() end end
	end)
	Slider("Fill Opacity", 0, 1, 0.3, 0.01, 33, function(v) if State.tool then local e=State.tool:FindFirstChild("WE_HL"); if e then e.FillTransparency=1-v end end end)
	ColorPick("Fill Color", T.Primary, 34, function(c) if State.tool then local e=State.tool:FindFirstChild("WE_HL"); if e then e.FillColor=c end end end)
	ColorPick("Outline Color", T.Cyan, 35, function(c) if State.tool then local e=State.tool:FindFirstChild("WE_HL"); if e then e.OutlineColor=c end end end)

	Header("NUKE", 36)
	Btn("🗑  Remove ALL Effects", 37, T.Danger, function()
		local prefixes = {"WE_"}
		if State.tool then
			for _,d in ipairs(State.tool:GetDescendants()) do
				if string.sub(d.Name,1,3)=="WE_" then d:Destroy() end
			end
		end
		State.fireOn=false; State.sparkOn=false; State.smokeOn=false; State.lightOn=false
		State.trailOn=false; State.particleOn=false; State.glowOn=false; State.beamOn=false; State.highlightOn=false
	end)
end

local function BuildAnim()
	Clear()
	Header("COLOR CYCLE", 1)
	Toggle("Rainbow", false, 2, function(v) State.rainbow=v end)
	Slider("Rainbow Speed", 0.1, 8, 1, 0.1, 3, function(v) State.rainbowSpd=v end)

	Header("COLOR PULSE", 4)
	Toggle("Pulse", false, 5, function(v) State.pulse=v end)
	Slider("Pulse Speed", 0.1, 8, 1, 0.1, 6, function(v) State.pulseSpd=v end)
	ColorPick("Color A", T.Primary, 7, function(c) State.pulseA=c end)
	ColorPick("Color B", T.Cyan, 8, function(c) State.pulseB=c end)

	Header("TRANSPARENCY", 9)
	Toggle("Flicker", false, 10, function(v) State.flicker=v end)
	Slider("Flicker Speed", 0.5, 15, 3, 0.5, 11, function(v) State.flickerSpd=v end)

	Header("SIZE PULSE", 12)
	Toggle("Breathe", false, 13, function(v) State.breathe=v end)
	Slider("Amount", 0.01, 0.4, 0.08, 0.01, 14, function(v) State.breatheAmt=v end)

	Header("STOP ALL", 15)
	Btn("⏹  Stop All Animations", 16, T.Raised, function()
		State.rainbow=false; State.pulse=false; State.flicker=false; State.breathe=false
	end)
end

local function BuildPresets()
	Clear()
	Header("WEAPON PRESETS", 1)

	Btn("🔥  Inferno Blade", 2, Color3.fromRGB(180,40,0), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(180,30,0); p.Material=Enum.Material.Neon
			local f=p:FindFirstChild("WE_Fire") or Instance.new("Fire"); f.Name="WE_Fire"; f.Size=10; f.Heat=18; f.Color=Color3.fromRGB(255,80,0); f.SecondaryColor=Color3.fromRGB(255,200,0); f.Parent=p
			local l=p:FindFirstChild("WE_Light") or Instance.new("PointLight"); l.Name="WE_Light"; l.Color=Color3.fromRGB(255,100,0); l.Brightness=4; l.Range=30; l.Parent=p
		end)
	end)

	Btn("❄  Frost Edge", 3, Color3.fromRGB(40,120,180), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(160,220,255); p.Material=Enum.Material.Ice; p.Reflectance=0.5
			local s=p:FindFirstChild("WE_Spark") or Instance.new("Sparkles"); s.Name="WE_Spark"; s.SparkleColor=Color3.fromRGB(200,240,255); s.Parent=p
			local l=p:FindFirstChild("WE_Light") or Instance.new("PointLight"); l.Name="WE_Light"; l.Color=Color3.fromRGB(150,200,255); l.Brightness=2; l.Range=20; l.Parent=p
		end)
	end)

	Btn("⚡  Lightning Strike", 4, Color3.fromRGB(60,80,200), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(200,200,255); p.Material=Enum.Material.Neon
			local pe=p:FindFirstChild("WE_PE") or Instance.new("ParticleEmitter"); pe.Name="WE_PE"; pe.Rate=80; pe.Speed=NumberRange.new(3,8); pe.Lifetime=NumberRange.new(0.15,0.4)
			pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(1,0)})
			pe.Color=ColorSequence.new(Color3.fromRGB(150,180,255)); pe.LightEmission=1; pe.SpreadAngle=Vector2.new(360,360); pe.Parent=p
			local l=p:FindFirstChild("WE_Light") or Instance.new("PointLight"); l.Name="WE_Light"; l.Color=Color3.fromRGB(180,200,255); l.Brightness=5; l.Range=35; l.Parent=p
		end)
		State.flicker=true; State.flickerSpd=10
	end)

	Btn("🌑  Shadow Blade", 5, Color3.fromRGB(40,10,60), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(20,0,30); p.Material=Enum.Material.ForceField; p.Transparency=0.25
			local sm=p:FindFirstChild("WE_Smoke") or Instance.new("Smoke"); sm.Name="WE_Smoke"; sm.Color=Color3.fromRGB(30,0,50); sm.Opacity=0.4; sm.Size=3; sm.RiseVelocity=1; sm.Parent=p
		end)
		if State.tool then
			local h=State.tool:FindFirstChild("WE_HL") or Instance.new("Highlight"); h.Name="WE_HL"; h.FillTransparency=0.6; h.OutlineTransparency=0.2; h.FillColor=Color3.fromRGB(50,0,80); h.OutlineColor=Color3.fromRGB(120,0,200); h.Adornee=State.tool; h.Parent=State.tool
		end
	end)

	Btn("🌟  Holy Radiance", 6, Color3.fromRGB(200,170,50), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(255,245,200); p.Material=Enum.Material.Neon; p.Reflectance=0.7
			local s=p:FindFirstChild("WE_Spark") or Instance.new("Sparkles"); s.Name="WE_Spark"; s.SparkleColor=Color3.fromRGB(255,255,200); s.Parent=p
			local l=p:FindFirstChild("WE_Light") or Instance.new("PointLight"); l.Name="WE_Light"; l.Color=Color3.fromRGB(255,240,180); l.Brightness=6; l.Range=50; l.Parent=p
			local pe=p:FindFirstChild("WE_PE") or Instance.new("ParticleEmitter"); pe.Name="WE_PE"; pe.Rate=35; pe.Speed=NumberRange.new(1,3); pe.Lifetime=NumberRange.new(1,2)
			pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(0.5,0.5),NumberSequenceKeypoint.new(1,0)})
			pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,200)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,200,100))})
			pe.LightEmission=1; pe.SpreadAngle=Vector2.new(180,180); pe.Parent=p
		end)
	end)

	Btn("💀  Cursed Edge", 7, Color3.fromRGB(40,140,40), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(50,180,50); p.Material=Enum.Material.Neon
			local pe=p:FindFirstChild("WE_PE") or Instance.new("ParticleEmitter"); pe.Name="WE_PE"; pe.Rate=25; pe.Speed=NumberRange.new(1,3); pe.Lifetime=NumberRange.new(0.8,1.5)
			pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,0)})
			pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(80,0,120))})
			pe.LightEmission=0.6; pe.SpreadAngle=Vector2.new(360,360); pe.Parent=p
			local sm=p:FindFirstChild("WE_Smoke") or Instance.new("Smoke"); sm.Name="WE_Smoke"; sm.Color=Color3.fromRGB(0,100,0); sm.Opacity=0.2; sm.Size=2; sm.Parent=p
		end)
		State.pulse=true; State.pulseA=Color3.fromRGB(0,255,0); State.pulseB=Color3.fromRGB(100,0,200); State.pulseSpd=2
	end)

	Btn("🌊  Ocean Depths", 8, Color3.fromRGB(0,60,140), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(0,80,180); p.Material=Enum.Material.Glass; p.Transparency=0.15; p.Reflectance=0.4
			local pe=p:FindFirstChild("WE_PE") or Instance.new("ParticleEmitter"); pe.Name="WE_PE"; pe.Rate=15; pe.Speed=NumberRange.new(0.5,2); pe.Lifetime=NumberRange.new(1,3)
			pe.Size=NumberSequence.new(0.3); pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(100,200,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,100,200))})
			pe.LightEmission=0.4; pe.SpreadAngle=Vector2.new(360,360); pe.Parent=p
		end)
	end)

	Btn("🪐  Void Walker", 9, Color3.fromRGB(30,0,50), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(10,0,20); p.Material=Enum.Material.ForceField; p.Transparency=0.1
			local pe=p:FindFirstChild("WE_PE") or Instance.new("ParticleEmitter"); pe.Name="WE_PE"; pe.Rate=60; pe.Speed=NumberRange.new(0.5,1.5); pe.Lifetime=NumberRange.new(0.5,1)
			pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(0.5,0.3),NumberSequenceKeypoint.new(1,0)})
			pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(120,0,255)),ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,200,255))})
			pe.LightEmission=1; pe.SpreadAngle=Vector2.new(360,360); pe.Parent=p
		end)
		State.pulse=true; State.pulseA=Color3.fromRGB(60,0,120); State.pulseB=Color3.fromRGB(0,150,255); State.pulseSpd=0.5
	end)

	Btn("🩸  Blood Moon", 10, Color3.fromRGB(120,0,0), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(80,0,0); p.Material=Enum.Material.Metal; p.Reflectance=0.3
			local pe=p:FindFirstChild("WE_PE") or Instance.new("ParticleEmitter"); pe.Name="WE_PE"; pe.Rate=20; pe.Speed=NumberRange.new(0.5,2); pe.Lifetime=NumberRange.new(0.5,1.5)
			pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0)})
			pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(180,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(60,0,0))})
			pe.LightEmission=0.2; pe.SpreadAngle=Vector2.new(360,360); pe.Parent=p
			local sm=p:FindFirstChild("WE_Smoke") or Instance.new("Smoke"); sm.Name="WE_Smoke"; sm.Color=Color3.fromRGB(80,0,0); sm.Opacity=0.15; sm.Size=1.5; sm.Parent=p
		end)
		State.pulse=true; State.pulseA=Color3.fromRGB(120,0,0); State.pulseB=Color3.fromRGB(40,0,0); State.pulseSpd=0.8
	end)

	Btn("💫  Starforged", 11, Color3.fromRGB(200,180,100), function()
		SaveState()
		Apply(function(p) p.Color=Color3.fromRGB(255,230,150); p.Material=Enum.Material.Neon; p.Reflectance=1
			local s=p:FindFirstChild("WE_Spark") or Instance.new("Sparkles"); s.Name="WE_Spark"; s.SparkleColor=Color3.new(1,1,1); s.Parent=p
			local l=p:FindFirstChild("WE_Light") or Instance.new("PointLight"); l.Name="WE_Light"; l.Color=Color3.fromRGB(255,240,200); l.Brightness=8; l.Range=60; l.Parent=p
		end)
		State.rainbow=true; State.rainbowSpd=0.3
	end)

	Header("UTILITY", 20)
	Btn("♻  Reset Everything", 21, T.Raised, function()
		if State.tool then
			for _,d in ipairs(State.tool:GetDescendants()) do if string.sub(d.Name,1,3)=="WE_" then d:Destroy() end end
		end
		State.rainbow=false; State.pulse=false; State.flicker=false; State.breathe=false
		State.fireOn=false; State.sparkOn=false; State.smokeOn=false; State.lightOn=false
		State.trailOn=false; State.particleOn=false; State.glowOn=false; State.beamOn=false; State.highlightOn=false
		Undo()
	end)

	Btn("🎲  Random Combo", 22, T.Secondary, function()
		SaveState()
		local rc = Color3.fromHSV(math.random(), math.random()*0.5+0.5, math.random()*0.5+0.5)
		local rm = MATS[math.random(1,#MATS)]
		Apply(function(p) p.Color=rc; p.Material=Enum.Material[rm]; p.Reflectance=math.random()*0.5; p.Transparency=math.random()*0.2 end)
		local roll = math.random(1,6)
		if roll==1 then State.rainbow=true; State.rainbowSpd=math.random()*3+0.5
		elseif roll==2 then State.pulse=true; State.pulseA=rc; State.pulseB=Color3.fromHSV(math.random(),1,1); State.pulseSpd=math.random()*2+0.5
		elseif roll==3 then Apply(function(p) local f=Instance.new("Fire"); f.Name="WE_Fire"; f.Size=math.random(3,15); f.Parent=p end)
		elseif roll==4 then Apply(function(p) local s=Instance.new("Sparkles"); s.Name="WE_Spark"; s.SparkleColor=Color3.fromHSV(math.random(),1,1); s.Parent=p end)
		elseif roll==5 then Apply(function(p) local l=Instance.new("PointLight"); l.Name="WE_Light"; l.Color=rc; l.Brightness=math.random(2,6); l.Range=math.random(15,50); l.Parent=p end)
		elseif roll==6 then State.flicker=true; State.flickerSpd=math.random(2,8)
		end
	end)
end

------------------------------------------------------------------------
-- TAB SYSTEM
------------------------------------------------------------------------
local TABS = {"SCALE","LOOK","FX","ANIM","PRESETS"}
local TAB_BUILDERS = {SCALE=BuildScale, LOOK=BuildLook, FX=BuildFX, ANIM=BuildAnim, PRESETS=BuildPresets}
local tabBtns = {}

local function SwitchTab(name)
	State.tab = name
	for n,b in pairs(tabBtns) do
		if n==name then
			Tw(b,{BackgroundColor3=T.Primary, BackgroundTransparency=0.15},0.15)
			b.TextColor3 = T.Text
		else
			Tw(b,{BackgroundColor3=T.Surface3, BackgroundTransparency=0.6},0.15)
			b.TextColor3 = T.TextSub
		end
	end
	Content.CanvasPosition = Vector2.new(0,0)
	if TAB_BUILDERS[name] then TAB_BUILDERS[name]() end
end

for _,name in ipairs(TABS) do
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.new(0,70,0,24)
	b.BackgroundColor3 = T.Surface3
	b.BackgroundTransparency = 0.6
	b.Text = name
	b.TextSize = 10
	b.Font = Enum.Font.GothamBlack
	b.TextColor3 = T.TextSub
	b.Active = true
	b.Parent = tabScroll
	Corner(b,6)
	tabBtns[name] = b
	b.MouseButton1Click:Connect(function() SwitchTab(name) end)
	b.MouseEnter:Connect(function() if State.tab~=name then Tw(b,{BackgroundTransparency=0.35},0.1) end end)
	b.MouseLeave:Connect(function() if State.tab~=name then Tw(b,{BackgroundTransparency=0.6},0.1) end end)
end

------------------------------------------------------------------------
-- PART SELECTOR
------------------------------------------------------------------------
local function UpdatePartBar()
	for _,ch in ipairs(partScroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
	if #State.parts == 0 then PartBar.Visible=false; return end
	PartBar.Visible = true

	-- ALL button
	local allB = Instance.new("TextButton")
	allB.Size = UDim2.new(0,40,0,22)
	allB.BackgroundColor3 = State.partIndex==0 and T.Primary or T.Surface3
	allB.BackgroundTransparency = State.partIndex==0 and 0.15 or 0.5
	allB.Text = "ALL"
	allB.TextSize = 9
	allB.Font = Enum.Font.GothamBlack
	allB.TextColor3 = T.Text
	allB.Active = true
	allB.Parent = partScroll
	Corner(allB,4)
	allB.MouseButton1Click:Connect(function() State.partIndex=0; UpdatePartBar() end)

	for i,p in ipairs(State.parts) do
		local pb = Instance.new("TextButton")
		pb.Size = UDim2.new(0,68,0,22)
		pb.BackgroundColor3 = State.partIndex==i and T.Primary or T.Surface3
		pb.BackgroundTransparency = State.partIndex==i and 0.15 or 0.5
		pb.Text = p.Name
		pb.TextSize = 9
		pb.Font = Enum.Font.GothamMedium
		pb.TextColor3 = T.Text
		pb.TextTruncate = Enum.TextTruncate.AtEnd
		pb.Active = true
		pb.Parent = partScroll
		Corner(pb,4)
		pb.MouseButton1Click:Connect(function() State.partIndex=i; UpdatePartBar() end)
	end
end

------------------------------------------------------------------------
-- TOOL DETECTION
------------------------------------------------------------------------
local character = player.Character or player.CharacterAdded:Wait()

local function OnEquip(tool)
	if not tool:IsA("Tool") then return end
	State.tool = tool
	State.parts = GetParts()
	State.partIndex = 0
	State.history = {}; State.histIdx = 0

	for _,p in ipairs(State.parts) do
		if p:IsA("BasePart") then
			p:SetAttribute("OX",p.Size.X); p:SetAttribute("OY",p.Size.Y); p:SetAttribute("OZ",p.Size.Z)
		end
	end
	SaveState()

	toolLabel.Text = tool.Name .. "  ·  " .. #State.parts .. " parts"
	WaitFrame.Visible = false
	Main.Visible = true
	Main.Position = UDim2.new(1,20,0.5,-280)
	Tw(Main, {Position=UDim2.new(1,-410,0.5,-280)}, 0.4, Enum.EasingStyle.Back)

	UpdatePartBar()
	SwitchTab("SCALE")
end

local function OnUnequip(tool)
	if tool ~= State.tool then return end
	toolLabel.Text = "unequipped — re-equip to continue"
	toolLabel.TextColor3 = T.Secondary

	task.delay(2.5, function()
		if not State.tool or not State.tool.Parent or State.tool.Parent ~= character then
			State.tool=nil; State.parts={}
			Tw(Main,{Position=UDim2.new(1,20,0.5,-280)},0.35,Enum.EasingStyle.Back)
			task.wait(0.35)
			Main.Visible=false; WaitFrame.Visible=true
			toolLabel.TextColor3=T.TextSub
		end
	end)
end

local function SetupChar(char)
	character = char
	char.ChildAdded:Connect(function(ch) if ch:IsA("Tool") then OnEquip(ch) end end)
	char.ChildRemoved:Connect(function(ch) if ch:IsA("Tool") then OnUnequip(ch) end end)
	for _,ch in ipairs(char:GetChildren()) do if ch:IsA("Tool") then OnEquip(ch); break end end
end

SetupChar(character)
player.CharacterAdded:Connect(SetupChar)

------------------------------------------------------------------------
-- BUTTON EVENTS
------------------------------------------------------------------------
btnClose.MouseButton1Click:Connect(function()
	Tw(Main,{Position=UDim2.new(1,20,0.5,-280)},0.35,Enum.EasingStyle.Back)
	task.wait(0.35)
	Main.Visible=false; WaitFrame.Visible=true
end)

local minimized = false
btnMin.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		Tw(Main,{Size=UDim2.new(0,390,0,42)},0.25)
		Content.Visible=false; TabFrame.Visible=false; PartBar.Visible=false; tabDiv.Visible=false
	else
		Tw(Main,{Size=UDim2.new(0,390,0,560)},0.25)
		task.wait(0.25)
		Content.Visible=true; TabFrame.Visible=true; tabDiv.Visible=true; UpdatePartBar()
	end
end)

btnUndo.MouseButton1Click:Connect(function() Undo() end)

------------------------------------------------------------------------
-- ANIMATION LOOP
------------------------------------------------------------------------
local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	if not State.tool then return end
	local parts = GetParts()
	if #parts == 0 then return end

	if State.rainbow then
		local h = (t * State.rainbowSpd * 0.1) % 1
		for _,p in ipairs(parts) do p.Color = Color3.fromHSV(h,1,1) end
	end

	if State.pulse and not State.rainbow then
		local frac = (math.sin(t * State.pulseSpd * math.pi)+1)/2
		local r = Lerp(State.pulseA.R, State.pulseB.R, frac)
		local g = Lerp(State.pulseA.G, State.pulseB.G, frac)
		local b = Lerp(State.pulseA.B, State.pulseB.B, frac)
		for _,p in ipairs(parts) do p.Color = Color3.new(r,g,b) end
	end

	if State.flicker then
		local f = math.abs(math.sin(t * State.flickerSpd * math.pi))
		for _,p in ipairs(parts) do p.Transparency = Lerp(0, 0.6, 1-f) end
	end

	if State.breathe then
		local pulse = math.sin(t*2) * State.breatheAmt
		for _,p in ipairs(parts) do
			local ox,oy,oz = p:GetAttribute("OX") or p.Size.X, p:GetAttribute("OY") or p.Size.Y, p:GetAttribute("OZ") or p.Size.Z
			p.Size = Vector3.new(ox*(1+pulse), oy*(1+pulse), oz*(1+pulse))
		end
	end

	-- beam jitter
	for _,p in ipairs(parts) do
		local beam = p:FindFirstChild("WE_Beam")
		if beam then beam.CurveSize0=math.sin(t*15)*3; beam.CurveSize1=math.cos(t*12)*-3 end
	end

	-- highlight pulse
	if State.tool then
		local h = State.tool:FindFirstChild("WE_HL")
		if h then h.OutlineTransparency = Lerp(0, 0.5, (math.sin(t*3)+1)/2) end
	end
end)

------------------------------------------------------------------------
-- KEYBINDS
------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F7 then
		if Main.Visible then
			Tw(Main,{Position=UDim2.new(1,20,0.5,-280)},0.35,Enum.EasingStyle.Back)
			task.wait(0.35); Main.Visible=false; WaitFrame.Visible=true
		elseif State.tool then
			Main.Visible=true; WaitFrame.Visible=false
			Main.Position=UDim2.new(1,20,0.5,-280)
			Tw(Main,{Position=UDim2.new(1,-410,0.5,-280)},0.4,Enum.EasingStyle.Back)
		end
	elseif input.KeyCode==Enum.KeyCode.Z and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		Undo()
	end
end)

------------------------------------------------------------------------
-- KEYBIND HINT
------------------------------------------------------------------------
local hint = Instance.new("TextLabel")
hint.Size=UDim2.new(0,180,0,18)
hint.Position=UDim2.new(0.5,-90,1,-24)
hint.BackgroundTransparency=1
hint.Text="F7 toggle  ·  Ctrl+Z undo"
hint.Font=Enum.Font.Gotham; hint.TextSize=10
hint.TextColor3=T.TextDark; hint.TextTransparency=0.2
hint.Parent=Gui

print("══════════════════════════════════")
print("  ⚔  WEAPON EDITOR v2.0 LOADED")
print("  Equip a tool · F7 toggle · Ctrl+Z undo")
print("══════════════════════════════════")
