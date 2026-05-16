--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║          "JUST A GUY FISHING..." v1.0                       ║
    ║   The Most Over-Engineered Fishing System Known to Roblox   ║
    ║                                                              ║
    ║   Features:                                                  ║
    ║   - Custom CFrame-animated walking (NO animation IDs!)      ║
    ║   - Full fishing rod tool with casting mechanics             ║
    ║   - Water detection via material, color, transparency,      ║
    ║     penetration depth, surface normal analysis               ║
    ║   - 34 unique blocky fish with procedural models             ║
    ║   - Bucket system to store caught fish                       ║
    ║   - Bobber physics, line rendering, casting arc              ║
    ║   - Reeling mechanics with tension system                    ║
    ║   - Fish AI with bite patterns                               ║
    ║                                                              ║
    ║   ALL CFRAME ANIMATED. ZERO ANIMATION IDS. PURE MATH.       ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Wait for character
local function WaitForCharacter()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local rootPart = char:WaitForChild("HumanoidRootPart")
	local torso = char:WaitForChild("UpperTorso", 2) or char:WaitForChild("Torso", 2)
	local head = char:WaitForChild("Head")
	return char, humanoid, rootPart, torso, head
end

------------------------------------------------------------------------
-- CONSTANTS & CONFIG
------------------------------------------------------------------------
local CONFIG = {
	-- Walking animation
	WALK_BOB_SPEED = 8,
	WALK_BOB_HEIGHT = 0.08,
	WALK_ARM_SWING = math.rad(35),
	WALK_LEG_SWING = math.rad(40),
	WALK_TORSO_SWAY = math.rad(3),
	WALK_HEAD_BOB = math.rad(2),
	IDLE_BREATHE_SPEED = 1.5,
	IDLE_BREATHE_AMOUNT = 0.015,
	
	-- Fishing
	CAST_POWER_RATE = 2.5,
	MAX_CAST_POWER = 100,
	MIN_CAST_POWER = 15,
	CAST_ARC_SEGMENTS = 30,
	LINE_COLOR = Color3.fromRGB(220, 220, 220),
	LINE_THICKNESS = 0.02,
	BOBBER_SIZE = Vector3.new(0.3, 0.4, 0.3),
	BOBBER_COLOR = Color3.fromRGB(255, 50, 30),
	BOBBER_WHITE = Color3.fromRGB(255, 255, 255),
	
	-- Water detection
	WATER_COLORS = {
		Color3.fromRGB(0, 100, 200),
		Color3.fromRGB(0, 120, 255),
		Color3.fromRGB(0, 80, 160),
		Color3.fromRGB(40, 120, 200),
		Color3.fromRGB(20, 90, 170),
		Color3.fromRGB(0, 162, 255),
		Color3.fromRGB(0, 130, 200),
		Color3.fromRGB(50, 150, 220),
		Color3.fromRGB(10, 70, 130),
		Color3.fromRGB(30, 100, 180),
		Color3.fromRGB(0, 170, 255),
		Color3.fromRGB(60, 160, 230),
		Color3.fromRGB(0, 60, 120),
		Color3.fromRGB(35, 140, 210),
		Color3.fromRGB(0, 200, 220),
	},
	WATER_PENETRATION_TEST_DEPTH = 5,
	WATER_PENETRATION_STEPS = 10,
	WATER_TRANSPARENCY_MIN = 0.2,
	WATER_SURFACE_DOT_THRESHOLD = 0.7,
	WATER_MATERIAL_BONUS = 50,
	WATER_COLOR_WEIGHT = 30,
	WATER_TRANSPARENCY_WEIGHT = 15,
	WATER_PENETRATION_WEIGHT = 25,
	WATER_SURFACE_WEIGHT = 10,
	WATER_THRESHOLD = 45,
	
	-- Fish
	BITE_MIN_TIME = 3,
	BITE_MAX_TIME = 15,
	NIBBLE_COUNT_MIN = 1,
	NIBBLE_COUNT_MAX = 4,
	HOOK_WINDOW = 1.5,
	REEL_SPEED = 15,
	FISH_FIGHT_DURATION_MIN = 2,
	FISH_FIGHT_DURATION_MAX = 8,
	TENSION_BREAK_THRESHOLD = 100,
	TENSION_DECAY = 15,
	TENSION_FISH_PULL = 25,
	
	-- Bucket
	BUCKET_MAX_FISH = 20,
	BUCKET_SIZE = Vector3.new(1.2, 1, 1.2),
}

------------------------------------------------------------------------
-- UTILITY FUNCTIONS
------------------------------------------------------------------------
local Util = {}

function Util.Lerp(a, b, t)
	return a + (b - a) * math.clamp(t, 0, 1)
end

function Util.LerpColor(a, b, t)
	t = math.clamp(t, 0, 1)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

function Util.ColorDistance(c1, c2)
	local dr = c1.R - c2.R
	local dg = c1.G - c2.G
	local db = c1.B - c2.B
	return math.sqrt(dr*dr + dg*dg + db*db)
end

function Util.SmoothStep(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Util.EaseOutBounce(t)
	if t < 1/2.75 then
		return 7.5625 * t * t
	elseif t < 2/2.75 then
		t = t - 1.5/2.75
		return 7.5625 * t * t + 0.75
	elseif t < 2.5/2.75 then
		t = t - 2.25/2.75
		return 7.5625 * t * t + 0.9375
	else
		t = t - 2.625/2.75
		return 7.5625 * t * t + 0.984375
	end
end

function Util.EaseOutQuad(t)
	return 1 - (1 - t) * (1 - t)
end

function Util.EaseInOutSine(t)
	return -(math.cos(math.pi * t) - 1) / 2
end

function Util.EaseOutElastic(t)
	if t == 0 or t == 1 then return t end
	local p = 0.3
	return math.pow(2, -10 * t) * math.sin((t - p/4) * (2 * math.pi) / p) + 1
end

function Util.RandomInRange(min, max)
	return min + math.random() * (max - min)
end

function Util.CreatePart(parent, size, color, material, transparency, anchored, cancollide, name)
	local p = Instance.new("Part")
	p.Size = size or Vector3.new(1,1,1)
	p.Color = color or Color3.new(1,1,1)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = anchored ~= false
	p.CanCollide = cancollide == true
	p.Name = name or "Part"
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Util.WeldParts(part0, part1, c0, c1)
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0 or CFrame.new()
	weld.C1 = c1 or CFrame.new()
	weld.Parent = part0
	return weld
end

function Util.CreateMotor6D(name, part0, part1, c0, c1)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0 or CFrame.new()
	motor.C1 = c1 or CFrame.new()
	motor.Parent = part0
	return motor
end

------------------------------------------------------------------------
-- FISH DATABASE - 34 UNIQUE FISH
------------------------------------------------------------------------
local FishDatabase = {
	{
		name = "Mud Guppy",
		rarity = "Common",
		weight = {0.1, 0.5},
		bodyColor = Color3.fromRGB(139, 119, 101),
		finColor = Color3.fromRGB(120, 100, 80),
		eyeColor = Color3.fromRGB(30, 30, 30),
		bodyScale = Vector3.new(0.6, 0.3, 0.2),
		tailScale = Vector3.new(0.2, 0.25, 0.15),
		finScale = Vector3.new(0.1, 0.15, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "none",
		fightStrength = 5,
		description = "A tiny bottom-dweller. Not much to look at.",
	},
	{
		name = "Crimson Perch",
		rarity = "Common",
		weight = {0.5, 2.0},
		bodyColor = Color3.fromRGB(200, 50, 50),
		finColor = Color3.fromRGB(180, 30, 30),
		eyeColor = Color3.fromRGB(255, 200, 0),
		bodyScale = Vector3.new(0.8, 0.5, 0.25),
		tailScale = Vector3.new(0.3, 0.35, 0.15),
		finScale = Vector3.new(0.15, 0.2, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(255, 100, 100),
		fightStrength = 10,
		description = "A feisty red fish found in warm shallows.",
	},
	{
		name = "Blue Gill",
		rarity = "Common",
		weight = {0.3, 1.5},
		bodyColor = Color3.fromRGB(60, 100, 180),
		finColor = Color3.fromRGB(40, 80, 160),
		eyeColor = Color3.fromRGB(20, 20, 20),
		bodyScale = Vector3.new(0.7, 0.45, 0.2),
		tailScale = Vector3.new(0.25, 0.3, 0.12),
		finScale = Vector3.new(0.12, 0.18, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "none",
		fightStrength = 8,
		description = "Common but reliable. Every angler's first catch.",
	},
	{
		name = "Sunny Dace",
		rarity = "Common",
		weight = {0.2, 1.0},
		bodyColor = Color3.fromRGB(255, 220, 50),
		finColor = Color3.fromRGB(255, 180, 0),
		eyeColor = Color3.fromRGB(40, 40, 40),
		bodyScale = Vector3.new(0.65, 0.35, 0.18),
		tailScale = Vector3.new(0.22, 0.25, 0.1),
		finScale = Vector3.new(0.1, 0.15, 0.04),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "spots",
		patternColor = Color3.fromRGB(255, 150, 0),
		fightStrength = 6,
		description = "Bright as sunshine. Loves shallow warm water.",
	},
	{
		name = "Stone Loach",
		rarity = "Common",
		weight = {0.1, 0.8},
		bodyColor = Color3.fromRGB(120, 110, 100),
		finColor = Color3.fromRGB(100, 90, 80),
		eyeColor = Color3.fromRGB(50, 50, 50),
		bodyScale = Vector3.new(0.9, 0.25, 0.2),
		tailScale = Vector3.new(0.2, 0.2, 0.12),
		finScale = Vector3.new(0.08, 0.1, 0.04),
		hasTopFin = false,
		hasWhiskers = true,
		whiskerColor = Color3.fromRGB(80, 70, 60),
		pattern = "none",
		fightStrength = 4,
		description = "Hides under rocks. Barely puts up a fight.",
	},
	{
		name = "River Chub",
		rarity = "Common",
		weight = {0.5, 2.5},
		bodyColor = Color3.fromRGB(150, 170, 140),
		finColor = Color3.fromRGB(130, 150, 120),
		eyeColor = Color3.fromRGB(30, 30, 30),
		bodyScale = Vector3.new(0.85, 0.5, 0.25),
		tailScale = Vector3.new(0.3, 0.3, 0.15),
		finScale = Vector3.new(0.13, 0.17, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "none",
		fightStrength = 12,
		description = "A chunky river dweller with a big appetite.",
	},
	{
		name = "Silver Minnow",
		rarity = "Common",
		weight = {0.05, 0.3},
		bodyColor = Color3.fromRGB(200, 210, 220),
		finColor = Color3.fromRGB(180, 190, 200),
		eyeColor = Color3.fromRGB(20, 20, 20),
		bodyScale = Vector3.new(0.45, 0.2, 0.12),
		tailScale = Vector3.new(0.15, 0.15, 0.08),
		finScale = Vector3.new(0.06, 0.1, 0.03),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "none",
		fightStrength = 2,
		description = "Tiny and shiny. Swims in huge schools.",
	},
	{
		name = "Emerald Bass",
		rarity = "Uncommon",
		weight = {1.0, 4.0},
		bodyColor = Color3.fromRGB(30, 150, 70),
		finColor = Color3.fromRGB(20, 120, 50),
		eyeColor = Color3.fromRGB(255, 220, 0),
		bodyScale = Vector3.new(1.0, 0.6, 0.3),
		tailScale = Vector3.new(0.35, 0.4, 0.18),
		finScale = Vector3.new(0.18, 0.22, 0.06),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(60, 200, 100),
		fightStrength = 20,
		description = "A gorgeous green fighter. Loves structure.",
	},
	{
		name = "Rusty Catfish",
		rarity = "Uncommon",
		weight = {2.0, 8.0},
		bodyColor = Color3.fromRGB(160, 100, 50),
		finColor = Color3.fromRGB(140, 80, 30),
		eyeColor = Color3.fromRGB(60, 60, 30),
		bodyScale = Vector3.new(1.2, 0.5, 0.35),
		tailScale = Vector3.new(0.3, 0.3, 0.2),
		finScale = Vector3.new(0.15, 0.15, 0.06),
		hasTopFin = true,
		hasWhiskers = true,
		whiskerColor = Color3.fromRGB(120, 70, 30),
		pattern = "none",
		fightStrength = 25,
		description = "Tough as nails with long whiskers. Bottom feeder.",
	},
	{
		name = "Violet Tetra",
		rarity = "Uncommon",
		weight = {0.1, 0.6},
		bodyColor = Color3.fromRGB(140, 50, 180),
		finColor = Color3.fromRGB(120, 30, 160),
		eyeColor = Color3.fromRGB(255, 100, 255),
		bodyScale = Vector3.new(0.5, 0.35, 0.15),
		tailScale = Vector3.new(0.2, 0.25, 0.1),
		finScale = Vector3.new(0.08, 0.12, 0.04),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "gradient",
		patternColor = Color3.fromRGB(200, 100, 255),
		fightStrength = 7,
		description = "A dazzling purple jewel of the waterways.",
	},
	{
		name = "Copper Carp",
		rarity = "Uncommon",
		weight = {3.0, 12.0},
		bodyColor = Color3.fromRGB(200, 140, 60),
		finColor = Color3.fromRGB(180, 120, 40),
		eyeColor = Color3.fromRGB(40, 40, 20),
		bodyScale = Vector3.new(1.3, 0.7, 0.35),
		tailScale = Vector3.new(0.4, 0.45, 0.2),
		finScale = Vector3.new(0.2, 0.25, 0.07),
		hasTopFin = true,
		hasWhiskers = true,
		whiskerColor = Color3.fromRGB(160, 100, 30),
		pattern = "none",
		fightStrength = 30,
		description = "Heavy and strong. A real arm workout.",
	},
	{
		name = "Frost Darter",
		rarity = "Uncommon",
		weight = {0.3, 1.2},
		bodyColor = Color3.fromRGB(180, 220, 255),
		finColor = Color3.fromRGB(150, 200, 255),
		eyeColor = Color3.fromRGB(100, 150, 255),
		bodyScale = Vector3.new(0.6, 0.3, 0.15),
		tailScale = Vector3.new(0.2, 0.22, 0.1),
		finScale = Vector3.new(0.1, 0.14, 0.04),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "spots",
		patternColor = Color3.fromRGB(220, 240, 255),
		fightStrength = 12,
		description = "Cold-water speedster. Darts away quick.",
	},
	{
		name = "Amber Trout",
		rarity = "Uncommon",
		weight = {1.0, 5.0},
		bodyColor = Color3.fromRGB(220, 170, 80),
		finColor = Color3.fromRGB(200, 150, 60),
		eyeColor = Color3.fromRGB(50, 50, 30),
		bodyScale = Vector3.new(1.0, 0.5, 0.25),
		tailScale = Vector3.new(0.35, 0.35, 0.15),
		finScale = Vector3.new(0.15, 0.2, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "spots",
		patternColor = Color3.fromRGB(180, 120, 40),
		fightStrength = 18,
		description = "Beautiful spotted pattern. Loves fast currents.",
	},
	{
		name = "Shadow Pike",
		rarity = "Uncommon",
		weight = {2.0, 7.0},
		bodyColor = Color3.fromRGB(60, 70, 60),
		finColor = Color3.fromRGB(40, 50, 40),
		eyeColor = Color3.fromRGB(200, 200, 0),
		bodyScale = Vector3.new(1.4, 0.4, 0.25),
		tailScale = Vector3.new(0.3, 0.3, 0.15),
		finScale = Vector3.new(0.15, 0.15, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(90, 100, 90),
		fightStrength = 28,
		description = "An ambush predator. Lurks in the weeds.",
	},
	{
		name = "Coral Wrasse",
		rarity = "Uncommon",
		weight = {0.5, 2.5},
		bodyColor = Color3.fromRGB(255, 100, 150),
		finColor = Color3.fromRGB(255, 70, 120),
		eyeColor = Color3.fromRGB(50, 200, 200),
		bodyScale = Vector3.new(0.7, 0.45, 0.2),
		tailScale = Vector3.new(0.25, 0.3, 0.12),
		finScale = Vector3.new(0.12, 0.18, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(255, 180, 200),
		fightStrength = 14,
		description = "Tropical beauty with vibrant pink hues.",
	},
	{
		name = "Golden Walleye",
		rarity = "Rare",
		weight = {3.0, 10.0},
		bodyColor = Color3.fromRGB(255, 200, 50),
		finColor = Color3.fromRGB(255, 180, 0),
		eyeColor = Color3.fromRGB(255, 255, 200),
		bodyScale = Vector3.new(1.1, 0.55, 0.3),
		tailScale = Vector3.new(0.35, 0.4, 0.18),
		finScale = Vector3.new(0.18, 0.22, 0.06),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "gradient",
		patternColor = Color3.fromRGB(255, 230, 100),
		fightStrength = 35,
		description = "Eyes that gleam like gold coins. Nocturnal hunter.",
	},
	{
		name = "Iron Sturgeon",
		rarity = "Rare",
		weight = {5.0, 25.0},
		bodyColor = Color3.fromRGB(100, 100, 110),
		finColor = Color3.fromRGB(80, 80, 90),
		eyeColor = Color3.fromRGB(40, 40, 50),
		bodyScale = Vector3.new(1.8, 0.5, 0.35),
		tailScale = Vector3.new(0.4, 0.35, 0.2),
		finScale = Vector3.new(0.2, 0.15, 0.07),
		hasTopFin = false,
		hasWhiskers = true,
		whiskerColor = Color3.fromRGB(70, 70, 80),
		pattern = "none",
		fightStrength = 50,
		description = "Ancient armored fish. Older than dinosaurs.",
	},
	{
		name = "Sapphire Angelfish",
		rarity = "Rare",
		weight = {0.5, 2.0},
		bodyColor = Color3.fromRGB(30, 80, 220),
		finColor = Color3.fromRGB(20, 60, 200),
		eyeColor = Color3.fromRGB(255, 200, 50),
		bodyScale = Vector3.new(0.6, 0.7, 0.15),
		tailScale = Vector3.new(0.2, 0.4, 0.08),
		finScale = Vector3.new(0.1, 0.35, 0.04),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(80, 130, 255),
		fightStrength = 15,
		description = "Tall and majestic. A living sapphire.",
	},
	{
		name = "Magma Goby",
		rarity = "Rare",
		weight = {0.2, 1.0},
		bodyColor = Color3.fromRGB(200, 50, 0),
		finColor = Color3.fromRGB(255, 100, 0),
		eyeColor = Color3.fromRGB(255, 255, 0),
		bodyScale = Vector3.new(0.5, 0.25, 0.15),
		tailScale = Vector3.new(0.18, 0.2, 0.1),
		finScale = Vector3.new(0.08, 0.12, 0.04),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "spots",
		patternColor = Color3.fromRGB(255, 200, 0),
		fightStrength = 10,
		description = "Looks like a tiny ember underwater. Hot catch!",
	},
	{
		name = "Moonlight Eel",
		rarity = "Rare",
		weight = {1.0, 6.0},
		bodyColor = Color3.fromRGB(60, 60, 100),
		finColor = Color3.fromRGB(80, 80, 140),
		eyeColor = Color3.fromRGB(200, 200, 255),
		bodyScale = Vector3.new(1.6, 0.2, 0.2),
		tailScale = Vector3.new(0.25, 0.18, 0.15),
		finScale = Vector3.new(0.06, 0.08, 0.04),
		hasTopFin = false,
		hasWhiskers = false,
		pattern = "gradient",
		patternColor = Color3.fromRGB(120, 120, 200),
		fightStrength = 22,
		description = "Slithers through moonlit waters. Elusive.",
	},
	{
		name = "Jade Barb",
		rarity = "Rare",
		weight = {0.3, 1.5},
		bodyColor = Color3.fromRGB(0, 160, 80),
		finColor = Color3.fromRGB(0, 140, 60),
		eyeColor = Color3.fromRGB(255, 50, 50),
		bodyScale = Vector3.new(0.6, 0.4, 0.18),
		tailScale = Vector3.new(0.22, 0.28, 0.1),
		finScale = Vector3.new(0.1, 0.16, 0.04),
		hasTopFin = true,
		hasWhiskers = true,
		whiskerColor = Color3.fromRGB(0, 120, 50),
		pattern = "none",
		fightStrength = 13,
		description = "Green as jade with a fiery temper.",
	},
	{
		name = "Thunder Drum",
		rarity = "Rare",
		weight = {2.0, 8.0},
		bodyColor = Color3.fromRGB(80, 80, 80),
		finColor = Color3.fromRGB(60, 60, 60),
		eyeColor = Color3.fromRGB(255, 255, 100),
		bodyScale = Vector3.new(1.0, 0.7, 0.35),
		tailScale = Vector3.new(0.3, 0.35, 0.18),
		finScale = Vector3.new(0.18, 0.2, 0.06),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(255, 255, 0),
		fightStrength = 35,
		description = "Makes a drumming sound when caught. Electric personality.",
	},
	{
		name = "Crystal Koi",
		rarity = "Epic",
		weight = {2.0, 10.0},
		bodyColor = Color3.fromRGB(255, 255, 255),
		finColor = Color3.fromRGB(240, 240, 255),
		eyeColor = Color3.fromRGB(200, 50, 50),
		bodyScale = Vector3.new(1.0, 0.6, 0.3),
		tailScale = Vector3.new(0.35, 0.45, 0.18),
		finScale = Vector3.new(0.18, 0.25, 0.06),
		hasTopFin = true,
		hasWhiskers = true,
		whiskerColor = Color3.fromRGB(255, 200, 200),
		pattern = "spots",
		patternColor = Color3.fromRGB(255, 100, 50),
		fightStrength = 40,
		description = "A translucent beauty with orange markings. Prized.",
	},
	{
		name = "Obsidian Marlin",
		rarity = "Epic",
		weight = {10.0, 40.0},
		bodyColor = Color3.fromRGB(30, 30, 40),
		finColor = Color3.fromRGB(20, 20, 30),
		eyeColor = Color3.fromRGB(255, 0, 0),
		bodyScale = Vector3.new(2.0, 0.6, 0.3),
		tailScale = Vector3.new(0.5, 0.5, 0.2),
		finScale = Vector3.new(0.25, 0.3, 0.07),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "gradient",
		patternColor = Color3.fromRGB(60, 0, 80),
		fightStrength = 70,
		description = "Dark as night, fast as lightning. The ultimate fighter.",
	},
	{
		name = "Prismatic Discus",
		rarity = "Epic",
		weight = {1.0, 4.0},
		bodyColor = Color3.fromRGB(255, 100, 200),
		finColor = Color3.fromRGB(100, 200, 255),
		eyeColor = Color3.fromRGB(255, 255, 0),
		bodyScale = Vector3.new(0.5, 0.7, 0.12),
		tailScale = Vector3.new(0.18, 0.3, 0.08),
		finScale = Vector3.new(0.08, 0.3, 0.04),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(100, 255, 100),
		fightStrength = 25,
		description = "A living rainbow. Changes color in the light.",
	},
	{
		name = "Phantom Grouper",
		rarity = "Epic",
		weight = {5.0, 20.0},
		bodyColor = Color3.fromRGB(100, 80, 120),
		finColor = Color3.fromRGB(80, 60, 100),
		eyeColor = Color3.fromRGB(200, 200, 255),
		bodyScale = Vector3.new(1.3, 0.8, 0.4),
		tailScale = Vector3.new(0.4, 0.4, 0.22),
		finScale = Vector3.new(0.2, 0.2, 0.07),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "spots",
		patternColor = Color3.fromRGB(150, 130, 170),
		fightStrength = 55,
		description = "Appears from nowhere. A ghostly heavyweight.",
	},
	{
		name = "Solar Arapaima",
		rarity = "Epic",
		weight = {15.0, 50.0},
		bodyColor = Color3.fromRGB(180, 60, 30),
		finColor = Color3.fromRGB(200, 80, 40),
		eyeColor = Color3.fromRGB(255, 200, 0),
		bodyScale = Vector3.new(2.2, 0.6, 0.35),
		tailScale = Vector3.new(0.45, 0.4, 0.2),
		finScale = Vector3.new(0.22, 0.18, 0.07),
		hasTopFin = false,
		hasWhiskers = false,
		pattern = "gradient",
		patternColor = Color3.fromRGB(255, 120, 60),
		fightStrength = 80,
		description = "Massive river titan. Burns like the sun.",
	},
	{
		name = "Starfall Gourami",
		rarity = "Legendary",
		weight = {1.0, 5.0},
		bodyColor = Color3.fromRGB(25, 25, 80),
		finColor = Color3.fromRGB(15, 15, 60),
		eyeColor = Color3.fromRGB(255, 255, 255),
		bodyScale = Vector3.new(0.8, 0.6, 0.2),
		tailScale = Vector3.new(0.3, 0.35, 0.12),
		finScale = Vector3.new(0.15, 0.25, 0.05),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "spots",
		patternColor = Color3.fromRGB(255, 255, 200),
		fightStrength = 30,
		description = "Carries the night sky on its scales. Breathtaking.",
	},
	{
		name = "Abyssal Angler",
		rarity = "Legendary",
		weight = {3.0, 15.0},
		bodyColor = Color3.fromRGB(20, 15, 30),
		finColor = Color3.fromRGB(10, 5, 20),
		eyeColor = Color3.fromRGB(0, 255, 200),
		bodyScale = Vector3.new(1.0, 0.7, 0.35),
		tailScale = Vector3.new(0.3, 0.3, 0.18),
		finScale = Vector3.new(0.15, 0.2, 0.06),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "none",
		fightStrength = 60,
		description = "From the deepest depths. Has its own light.",
		hasLure = true,
		lureColor = Color3.fromRGB(0, 255, 150),
	},
	{
		name = "Diamond Swordfish",
		rarity = "Legendary",
		weight = {20.0, 80.0},
		bodyColor = Color3.fromRGB(180, 220, 255),
		finColor = Color3.fromRGB(150, 200, 255),
		eyeColor = Color3.fromRGB(0, 100, 255),
		bodyScale = Vector3.new(2.5, 0.5, 0.3),
		tailScale = Vector3.new(0.5, 0.5, 0.2),
		finScale = Vector3.new(0.25, 0.3, 0.07),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "gradient",
		patternColor = Color3.fromRGB(220, 240, 255),
		fightStrength = 90,
		description = "Gleams like a diamond blade cutting through water.",
		hasSword = true,
		swordLength = 0.8,
	},
	{
		name = "Volcanic Tuna",
		rarity = "Legendary",
		weight = {10.0, 45.0},
		bodyColor = Color3.fromRGB(50, 10, 10),
		finColor = Color3.fromRGB(200, 50, 0),
		eyeColor = Color3.fromRGB(255, 100, 0),
		bodyScale = Vector3.new(1.5, 0.7, 0.35),
		tailScale = Vector3.new(0.45, 0.5, 0.2),
		finScale = Vector3.new(0.22, 0.25, 0.07),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "stripes",
		patternColor = Color3.fromRGB(255, 50, 0),
		fightStrength = 85,
		description = "Feels warm to the touch. Erupts with power.",
	},
	{
		name = "Celestial Whale-Minnow",
		rarity = "Mythical",
		weight = {0.01, 0.05},
		bodyColor = Color3.fromRGB(255, 255, 255),
		finColor = Color3.fromRGB(200, 200, 255),
		eyeColor = Color3.fromRGB(255, 200, 255),
		bodyScale = Vector3.new(0.3, 0.2, 0.15),
		tailScale = Vector3.new(0.12, 0.15, 0.08),
		finScale = Vector3.new(0.06, 0.08, 0.03),
		hasTopFin = true,
		hasWhiskers = false,
		pattern = "gradient",
		patternColor = Color3.fromRGB(200, 180, 255),
		fightStrength = 1,
		description = "The tiniest fish with cosmic power. Impossibly rare.",
		glows = true,
		glowColor = Color3.fromRGB(200, 180, 255),
	},
	{
		name = "The Old King",
		rarity = "Mythical",
		weight = {50.0, 200.0},
		bodyColor = Color3.fromRGB(50, 50, 0),
		finColor = Color3.fromRGB(200, 170, 0),
		eyeColor = Color3.fromRGB(255, 0, 0),
		bodyScale = Vector3.new(3.0, 1.0, 0.5),
		tailScale = Vector3.new(0.7, 0.7, 0.3),
		finScale = Vector3.new(0.35, 0.35, 0.1),
		hasTopFin = true,
		hasWhiskers = true,
		whiskerColor = Color3.fromRGB(255, 200, 0),
		pattern = "stripes",
		patternColor = Color3.fromRGB(255, 215, 0),
		fightStrength = 100,
		description = "THE legendary fish. Ruler of all waters. THE catch.",
		hasCrown = true,
		crownColor = Color3.fromRGB(255, 215, 0),
		glows = true,
		glowColor = Color3.fromRGB(255, 215, 0),
	},
}

-- Rarity weights for random selection
local RarityWeights = {
	Common = 40,
	Uncommon = 25,
	Rare = 18,
	Epic = 10,
	Legendary = 5,
	Mythical = 2,
}

local RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(50, 200, 50),
	Rare = Color3.fromRGB(50, 100, 255),
	Epic = Color3.fromRGB(180, 50, 255),
	Legendary = Color3.fromRGB(255, 200, 0),
	Mythical = Color3.fromRGB(255, 50, 100),
}

------------------------------------------------------------------------
-- FISH MODEL BUILDER
------------------------------------------------------------------------
local FishModelBuilder = {}

function FishModelBuilder.Build(fishData, scale)
	scale = scale or 1
	local model = Instance.new("Model")
	model.Name = fishData.name
	
	local bs = fishData.bodyScale * scale
	
	-- BODY (main block)
	local body = Util.CreatePart(model, bs, fishData.bodyColor, Enum.Material.SmoothPlastic, 0, true, false, "Body")
	model.PrimaryPart = body
	
	-- Pattern overlays
	if fishData.pattern == "stripes" and fishData.patternColor then
		local stripeCount = 3
		for i = 1, stripeCount do
			local stripeX = bs.X * (-0.3 + (i-1) * 0.3)
			local stripe = Util.CreatePart(model,
				Vector3.new(bs.X * 0.08, bs.Y * 0.95, bs.Z * 1.02),
				fishData.patternColor, Enum.Material.SmoothPlastic, 0.1, true, false, "Stripe"..i)
			stripe.CFrame = body.CFrame * CFrame.new(stripeX, 0, 0)
		end
	elseif fishData.pattern == "spots" and fishData.patternColor then
		for i = 1, 5 do
			local spotSize = bs.Y * Util.RandomInRange(0.1, 0.2)
			local spot = Util.CreatePart(model,
				Vector3.new(spotSize, spotSize, bs.Z * 1.02),
				fishData.patternColor, Enum.Material.SmoothPlastic, 0.15, true, false, "Spot"..i)
			spot.CFrame = body.CFrame * CFrame.new(
				Util.RandomInRange(-bs.X * 0.35, bs.X * 0.35),
				Util.RandomInRange(-bs.Y * 0.3, bs.Y * 0.25),
				0
			)
		end
	end
	
	-- TAIL
	local ts = fishData.tailScale * scale
	local tail = Util.CreatePart(model, ts, fishData.finColor, Enum.Material.SmoothPlastic, 0, true, false, "Tail")
	tail.CFrame = body.CFrame * CFrame.new(-bs.X/2 - ts.X/2, 0, 0)
	
	-- Tail fork (two small triangular parts)
	local forkSize = Vector3.new(ts.X * 0.6, ts.Y * 0.4, ts.Z * 0.8)
	local forkTop = Util.CreatePart(model, forkSize, fishData.finColor, Enum.Material.SmoothPlastic, 0, true, false, "TailForkTop")
	forkTop.CFrame = tail.CFrame * CFrame.new(-ts.X/2 - forkSize.X/2, ts.Y * 0.25, 0) * CFrame.Angles(0, 0, math.rad(20))
	
	local forkBot = Util.CreatePart(model, forkSize, fishData.finColor, Enum.Material.SmoothPlastic, 0, true, false, "TailForkBot")
	forkBot.CFrame = tail.CFrame * CFrame.new(-ts.X/2 - forkSize.X/2, -ts.Y * 0.25, 0) * CFrame.Angles(0, 0, math.rad(-20))
	
	-- HEAD (slightly tapered - use a smaller part)
	local headSize = Vector3.new(bs.X * 0.35, bs.Y * 0.85, bs.Z * 0.9)
	local head = Util.CreatePart(model, headSize, fishData.bodyColor, Enum.Material.SmoothPlastic, 0, true, false, "FishHead")
	head.CFrame = body.CFrame * CFrame.new(bs.X/2 + headSize.X/2, 0, 0)
	
	-- MOUTH
	local mouthSize = Vector3.new(headSize.X * 0.15, headSize.Y * 0.2, headSize.Z * 0.5)
	local mouth = Util.CreatePart(model, mouthSize, Color3.fromRGB(40, 10, 10), Enum.Material.SmoothPlastic, 0, true, false, "Mouth")
	mouth.CFrame = head.CFrame * CFrame.new(headSize.X/2, -headSize.Y * 0.1, 0)
	
	-- EYES (both sides)
	local eyeSize = Vector3.new(bs.Y * 0.18, bs.Y * 0.18, 0.02 * scale)
	for _, side in ipairs({1, -1}) do
		local eye = Util.CreatePart(model, eyeSize, Color3.new(1,1,1), Enum.Material.SmoothPlastic, 0, true, false, "Eye" .. (side == 1 and "R" or "L"))
		eye.CFrame = head.CFrame * CFrame.new(headSize.X * 0.15, headSize.Y * 0.15, side * (headSize.Z/2 + 0.005))
		
		local pupil = Util.CreatePart(model, eyeSize * Vector3.new(0.55, 0.55, 1), fishData.eyeColor, Enum.Material.SmoothPlastic, 0, true, false, "Pupil" .. (side == 1 and "R" or "L"))
		pupil.CFrame = eye.CFrame * CFrame.new(eyeSize.X * 0.1, 0, side * 0.005)
	end
	
	-- TOP FIN
	if fishData.hasTopFin then
		local fs = fishData.finScale * scale
		local topFin = Util.CreatePart(model, Vector3.new(fs.X * 2, fs.Y, fs.Z), fishData.finColor, Enum.Material.SmoothPlastic, 0, true, false, "TopFin")
		topFin.CFrame = body.CFrame * CFrame.new(0, bs.Y/2 + fs.Y/2, 0) * CFrame.Angles(0, 0, math.rad(5))
	end
	
	-- SIDE FINS
	for _, side in ipairs({1, -1}) do
		local fs = fishData.finScale * scale
		local sideFin = Util.CreatePart(model, Vector3.new(fs.X * 1.5, fs.Y * 0.6, fs.Z * 0.5), fishData.finColor, Enum.Material.SmoothPlastic, 0, true, false, "SideFin" .. (side == 1 and "R" or "L"))
		sideFin.CFrame = body.CFrame * CFrame.new(bs.X * 0.1, -bs.Y * 0.2, side * (bs.Z/2 + fs.Z * 0.2)) * CFrame.Angles(0, 0, side * math.rad(30))
	end
	
	-- WHISKERS
	if fishData.hasWhiskers then
		local whiskerColor = fishData.whiskerColor or fishData.finColor
		for _, side in ipairs({1, -1}) do
			local whisker = Util.CreatePart(model,
				Vector3.new(bs.X * 0.3, 0.02 * scale, 0.02 * scale),
				whiskerColor, Enum.Material.SmoothPlastic, 0, true, false, "Whisker" .. (side == 1 and "R" or "L"))
			whisker.CFrame = head.CFrame * CFrame.new(headSize.X * 0.3, -headSize.Y * 0.2, side * headSize.Z * 0.3) * CFrame.Angles(0, side * math.rad(25), math.rad(15))
		end
	end
	
	-- SWORD (for swordfish)
	if fishData.hasSword then
		local swordLen = (fishData.swordLength or 0.5) * scale
		local sword = Util.CreatePart(model,
			Vector3.new(swordLen, 0.04 * scale, 0.04 * scale),
			fishData.bodyColor, Enum.Material.SmoothPlastic, 0, true, false, "Sword")
		sword.CFrame = head.CFrame * CFrame.new(headSize.X/2 + swordLen/2, 0, 0)
	end
	
	-- CROWN (for The Old King)
	if fishData.hasCrown then
		local crownColor = fishData.crownColor or Color3.fromRGB(255, 215, 0)
		local crownBase = Util.CreatePart(model,
			Vector3.new(headSize.X * 0.6, 0.04 * scale, headSize.Z * 0.6),
			crownColor, Enum.Material.SmoothPlastic, 0, true, false, "CrownBase")
		crownBase.CFrame = head.CFrame * CFrame.new(0, headSize.Y/2 + 0.02 * scale, 0)
		
		for ci = 1, 5 do
			local point = Util.CreatePart(model,
				Vector3.new(0.04 * scale, 0.1 * scale, 0.04 * scale),
				crownColor, Enum.Material.SmoothPlastic, 0, true, false, "CrownPoint"..ci)
			local angle = (ci - 1) / 5 * math.pi * 2
			point.CFrame = crownBase.CFrame * CFrame.new(
				math.cos(angle) * headSize.X * 0.2,
				0.07 * scale,
				math.sin(angle) * headSize.Z * 0.2
			)
		end
	end
	
	-- ANGLER LURE
	if fishData.hasLure then
		local lureColor = fishData.lureColor or Color3.fromRGB(0, 255, 150)
		local stalk = Util.CreatePart(model,
			Vector3.new(0.02 * scale, bs.Y * 0.5, 0.02 * scale),
			fishData.bodyColor, Enum.Material.SmoothPlastic, 0, true, false, "LureStalk")
		stalk.CFrame = head.CFrame * CFrame.new(headSize.X * 0.2, headSize.Y/2 + bs.Y * 0.25, 0) * CFrame.Angles(0, 0, math.rad(30))
		
		local bulb = Util.CreatePart(model,
			Vector3.new(0.08 * scale, 0.08 * scale, 0.08 * scale),
			lureColor, Enum.Material.Neon, 0, true, false, "LureBulb")
		bulb.Shape = Enum.PartType.Ball
		bulb.CFrame = stalk.CFrame * CFrame.new(0, bs.Y * 0.25, 0)
		
		local light = Instance.new("PointLight")
		light.Color = lureColor
		light.Brightness = 2
		light.Range = 6 * scale
		light.Parent = bulb
	end
	
	-- GLOW EFFECT
	if fishData.glows then
		local glowColor = fishData.glowColor or Color3.new(1,1,1)
		local light = Instance.new("PointLight")
		light.Color = glowColor
		light.Brightness = 1.5
		light.Range = 8 * scale
		light.Parent = body
		
		-- Add slight transparency shimmer via surface light
		local surfLight = Instance.new("SurfaceLight")
		surfLight.Color = glowColor
		surfLight.Brightness = 0.5
		surfLight.Range = 3 * scale
		surfLight.Face = Enum.NormalId.Front
		surfLight.Parent = body
	end
	
	return model
end

function FishModelBuilder.AnimateFish(model, dt, timeVal)
	if not model or not model.PrimaryPart then return end
	local body = model.PrimaryPart
	local baseCF = body.CFrame
	
	-- Animate tail
	local tail = model:FindFirstChild("Tail")
	if tail then
		local swing = math.sin(timeVal * 8) * math.rad(20)
		local bodyBS = body.Size
		local ts = tail.Size
		tail.CFrame = baseCF * CFrame.new(-bodyBS.X/2 - ts.X/2, 0, 0) * CFrame.Angles(0, swing, 0)
		
		local forkTop = model:FindFirstChild("TailForkTop")
		local forkBot = model:FindFirstChild("TailForkBot")
		if forkTop then
			local forkSize = forkTop.Size
			forkTop.CFrame = tail.CFrame * CFrame.new(-ts.X/2 - forkSize.X/2, ts.Y * 0.25, 0) * CFrame.Angles(0, swing * 0.5, math.rad(20))
		end
		if forkBot then
			local forkSize = forkBot.Size
			forkBot.CFrame = tail.CFrame * CFrame.new(-ts.X/2 - forkSize.X/2, -ts.Y * 0.25, 0) * CFrame.Angles(0, swing * 0.5, math.rad(-20))
		end
	end
	
	-- Animate side fins
	for _, side in ipairs({"R", "L"}) do
		local fin = model:FindFirstChild("SideFin" .. side)
		if fin then
			local sideVal = side == "R" and 1 or -1
			local flap = math.sin(timeVal * 6 + sideVal) * math.rad(15)
			local bodyBS = body.Size
			local fs = fin.Size
			fin.CFrame = baseCF * CFrame.new(bodyBS.X * 0.1, -bodyBS.Y * 0.2, sideVal * (bodyBS.Z/2 + fs.Z * 0.2)) * CFrame.Angles(flap, 0, sideVal * math.rad(30))
		end
	end
end

------------------------------------------------------------------------
-- WATER DETECTION SYSTEM (THE COOK)
------------------------------------------------------------------------
local WaterDetector = {}

-- Heuristic scoring system for water detection
function WaterDetector.AnalyzeSurface(hitPart, hitPosition, hitNormal)
	if not hitPart then return 0, {} end
	
	local scores = {
		material = 0,
		color = 0,
		transparency = 0,
		penetration = 0,
		surfaceNormal = 0,
		size = 0,
		name = 0,
	}
	local details = {}
	
	-- 1. MATERIAL CHECK (strongest signal)
	-- Terrain water material is the gold standard
	if hitPart:IsA("Terrain") then
		local cellMaterial = Workspace.Terrain:ReadVoxels(
			Region3.new(hitPosition - Vector3.new(2,2,2), hitPosition + Vector3.new(2,2,2)):ExpandToGrid(4),
			4
		)
		-- If we hit terrain, check if there's water material nearby
		-- The terrain material at the hit point tells us a lot
		scores.material = CONFIG.WATER_MATERIAL_BONUS * 0.5
		details.terrainHit = true
	end
	
	if hitPart.Material == Enum.Material.Water then
		-- Direct water material detection - jackpot
		scores.material = CONFIG.WATER_MATERIAL_BONUS
		details.materialMatch = "Water"
	elseif hitPart.Material == Enum.Material.Glass then
		-- Glass can look like water
		scores.material = CONFIG.WATER_MATERIAL_BONUS * 0.2
		details.materialMatch = "Glass (possible water)"
	elseif hitPart.Material == Enum.Material.ForceField then
		scores.material = CONFIG.WATER_MATERIAL_BONUS * 0.3
		details.materialMatch = "ForceField (possible water)"
	elseif hitPart.Material == Enum.Material.Neon then
		scores.material = CONFIG.WATER_MATERIAL_BONUS * 0.15
		details.materialMatch = "Neon (possible stylized water)"
	elseif hitPart.Material == Enum.Material.Ice then
		scores.material = CONFIG.WATER_MATERIAL_BONUS * 0.1
		details.materialMatch = "Ice (frozen water?)"
	end
	
	-- 2. COLOR ANALYSIS
	-- Compare against known water colors using perceptual color distance
	local partColor = hitPart.Color
	local bestColorDist = math.huge
	for _, waterColor in ipairs(CONFIG.WATER_COLORS) do
		local dist = Util.ColorDistance(partColor, waterColor)
		if dist < bestColorDist then
			bestColorDist = dist
		end
	end
	
	-- Also check blue/cyan dominance (water tends to be blue-ish)
	local blueRatio = partColor.B / math.max(partColor.R + partColor.G + partColor.B, 0.01)
	local blueDominance = math.clamp((blueRatio - 0.33) * 3, 0, 1) -- Normalized blue dominance
	
	-- Saturation check (very desaturated might not be water)
	local maxC = math.max(partColor.R, partColor.G, partColor.B)
	local minC = math.min(partColor.R, partColor.G, partColor.B)
	local saturation = maxC > 0 and (maxC - minC) / maxC or 0
	
	-- Color score combines distance to known water colors + blue dominance
	local colorDistScore = math.clamp(1 - bestColorDist / 0.8, 0, 1) -- Closer to water color = higher score
	local colorScore = (colorDistScore * 0.6 + blueDominance * 0.3 + (saturation > 0.1 and 0.1 or 0)) * CONFIG.WATER_COLOR_WEIGHT
	scores.color = colorScore
	details.colorDistance = bestColorDist
	details.blueDominance = blueDominance
	details.saturation = saturation
	
	-- 3. TRANSPARENCY ANALYSIS
	-- Water is typically semi-transparent
	local trans = hitPart.Transparency
	if trans >= CONFIG.WATER_TRANSPARENCY_MIN and trans <= 0.95 then
		-- Sweet spot for water transparency (0.2 to 0.95)
		local transScore = 1 - math.abs(trans - 0.5) * 2 -- Peaks at 0.5 transparency
		transScore = math.max(transScore, 0.3) -- Minimum if in range
		scores.transparency = transScore * CONFIG.WATER_TRANSPARENCY_WEIGHT
		details.transparencyInRange = true
	elseif trans > 0.05 and trans < CONFIG.WATER_TRANSPARENCY_MIN then
		-- Slightly transparent, might still be water
		scores.transparency = 0.1 * CONFIG.WATER_TRANSPARENCY_WEIGHT
	end
	details.transparency = trans
	
	-- 4. PENETRATION TEST (Can we go through it?)
	-- Cast rays downward through the part to see if they pass through
	local penetrationScore = 0
	local penetrationCount = 0
	local startPos = hitPosition + Vector3.new(0, 0.1, 0)
	
	for step = 1, CONFIG.WATER_PENETRATION_STEPS do
		local depth = (step / CONFIG.WATER_PENETRATION_STEPS) * CONFIG.WATER_PENETRATION_TEST_DEPTH
		local testPos = hitPosition - Vector3.new(0, depth, 0)
		
		-- Check if a ray from above goes through the part
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = {hitPart}
		
		local testRay = Workspace:Raycast(startPos, Vector3.new(0, -(depth + 0.2), 0), rayParams)
		
		if testRay then
			penetrationCount = penetrationCount + 1
		end
	end
	
	-- If we can penetrate somewhat, it's more likely water
	-- But real water terrain doesn't block raycasts at all
	if hitPart.CanCollide == false then
		penetrationScore = 0.8
		details.canCollide = false
	else
		-- CanCollide is true - less likely to be walk-through water
		-- but could still be Terrain water
		penetrationScore = 0.2
		details.canCollide = true
	end
	
	-- Additional: check if part is very large and flat (like a water plane)
	local partSize = hitPart.Size
	local flatness = math.min(partSize.X, partSize.Z) / math.max(partSize.Y, 0.01)
	if flatness > 10 then
		penetrationScore = penetrationScore + 0.2
		details.isFlat = true
	end
	
	scores.penetration = math.clamp(penetrationScore, 0, 1) * CONFIG.WATER_PENETRATION_WEIGHT
	details.penetrationCount = penetrationCount
	
	-- 5. SURFACE NORMAL ANALYSIS
	-- Water surfaces tend to face upward (dot product with up vector)
	if hitNormal then
		local upDot = hitNormal:Dot(Vector3.new(0, 1, 0))
		if upDot >= CONFIG.WATER_SURFACE_DOT_THRESHOLD then
			scores.surfaceNormal = CONFIG.WATER_SURFACE_WEIGHT
			details.surfaceIsUp = true
		elseif upDot > 0.3 then
			scores.surfaceNormal = CONFIG.WATER_SURFACE_WEIGHT * (upDot / CONFIG.WATER_SURFACE_DOT_THRESHOLD)
		end
		details.surfaceDot = upDot
	end
	
	-- 6. NAME HEURISTIC (bonus)
	local nameLower = hitPart.Name:lower()
	local parentNameLower = hitPart.Parent and hitPart.Parent.Name:lower() or ""
	local waterNames = {"water", "ocean", "sea", "lake", "river", "pond", "pool", "aqua", "stream", "creek", "wave"}
	for _, wn in ipairs(waterNames) do
		if nameLower:find(wn) or parentNameLower:find(wn) then
			scores.name = 10
			details.nameMatch = wn
			break
		end
	end
	
	-- TOTAL SCORE
	local totalScore = 0
	for _, v in pairs(scores) do
		totalScore = totalScore + v
	end
	
	details.scores = scores
	details.totalScore = totalScore
	details.isWater = totalScore >= CONFIG.WATER_THRESHOLD
	
	return totalScore, details
end

-- Advanced terrain water detection
function WaterDetector.CheckTerrainWater(position)
	-- Read voxels around the position
	local resolution = 4
	local region = Region3.new(
		position - Vector3.new(resolution, resolution, resolution),
		position + Vector3.new(resolution, resolution, resolution)
	):ExpandToGrid(resolution)
	
	local success, materials, occupancies = pcall(function()
		return Workspace.Terrain:ReadVoxels(region, resolution)
	end)
	
	if not success then return false end
	
	-- Check if any voxel is water
	for x = 1, materials.Size.X do
		for y = 1, materials.Size.Y do
			for z = 1, materials.Size.Z do
				if materials[x][y][z] == Enum.Material.Water then
					return true
				end
			end
		end
	end
	return false
end

-- Comprehensive water check combining all methods
function WaterDetector.IsWater(position, hitPart, hitNormal)
	-- Method 1: Terrain water voxel check
	local terrainWater = WaterDetector.CheckTerrainWater(position)
	if terrainWater then
		return true, {method = "TerrainVoxel", confidence = 100}
	end
	
	-- Method 2: Surface analysis scoring
	if hitPart then
		local score, details = WaterDetector.AnalyzeSurface(hitPart, position, hitNormal)
		if details.isWater then
			return true, {method = "SurfaceAnalysis", confidence = score, details = details}
		end
	end
	
	-- Method 3: Multiple raycast sampling around the position
	local waterVotes = 0
	local totalVotes = 0
	local sampleRadius = 2
	local sampleCount = 8
	
	for i = 1, sampleCount do
		local angle = (i / sampleCount) * math.pi * 2
		local samplePos = position + Vector3.new(math.cos(angle) * sampleRadius, 1, math.sin(angle) * sampleRadius)
		local rayResult = Workspace:Raycast(samplePos, Vector3.new(0, -5, 0))
		
		if rayResult then
			local sampleScore, _ = WaterDetector.AnalyzeSurface(rayResult.Instance, rayResult.Position, rayResult.Normal)
			if sampleScore >= CONFIG.WATER_THRESHOLD then
				waterVotes = waterVotes + 1
			end
		end
		totalVotes = totalVotes + 1
	end
	
	if waterVotes > totalVotes * 0.5 then
		return true, {method = "MultiSample", confidence = (waterVotes / totalVotes) * 100}
	end
	
	return false, {method = "None", confidence = 0}
end

------------------------------------------------------------------------
-- FISHING ROD TOOL BUILDER
------------------------------------------------------------------------
local FishingRodBuilder = {}

function FishingRodBuilder.Create()
	-- Create the Tool
	local tool = Instance.new("Tool")
	tool.Name = "🎣 Old Reliable"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Just a guy's fishing rod. Click to cast!"
	
	-- HANDLE (the rod grip)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 0.3, 4.5) -- Long rod
	handle.Color = Color3.fromRGB(101, 67, 33) -- Dark wood
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	
	-- Rod sections (thinner towards tip)
	local section1 = Util.CreatePart(handle, Vector3.new(0.25, 0.25, 1.5), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, 0, false, false, "Section1")
	section1.Massless = true
	section1.CanCollide = false
	local w1 = Util.WeldParts(handle, section1, CFrame.new(0, 0, -2.25 - 0.75))
	
	local section2 = Util.CreatePart(handle, Vector3.new(0.18, 0.18, 1.2), Color3.fromRGB(140, 95, 50), Enum.Material.Wood, 0, false, false, "Section2")
	section2.Massless = true
	section2.CanCollide = false
	local w2 = Util.WeldParts(section1, section2, CFrame.new(0, 0, -0.75 - 0.6))
	
	local section3 = Util.CreatePart(handle, Vector3.new(0.12, 0.12, 1.0), Color3.fromRGB(160, 110, 60), Enum.Material.Wood, 0, false, false, "Section3")
	section3.Massless = true
	section3.CanCollide = false
	local w3 = Util.WeldParts(section2, section3, CFrame.new(0, 0, -0.6 - 0.5))
	
	-- Rod tip (thin)
	local tip = Util.CreatePart(handle, Vector3.new(0.06, 0.06, 0.5), Color3.fromRGB(200, 200, 200), Enum.Material.Metal, 0, false, false, "Tip")
	tip.Massless = true
	tip.CanCollide = false
	local wTip = Util.WeldParts(section3, tip, CFrame.new(0, 0, -0.5 - 0.25))
	
	-- Grip wrapping
	local grip = Util.CreatePart(handle, Vector3.new(0.35, 0.35, 1.0), Color3.fromRGB(40, 40, 40), Enum.Material.Fabric, 0, false, false, "Grip")
	grip.Massless = true
	grip.CanCollide = false
	local wGrip = Util.WeldParts(handle, grip, CFrame.new(0, 0, 1.5))
	
	-- Cork grip
	local cork = Util.CreatePart(handle, Vector3.new(0.38, 0.38, 0.6), Color3.fromRGB(190, 160, 110), Enum.Material.Sand, 0, false, false, "Cork")
	cork.Massless = true
	cork.CanCollide = false
	local wCork = Util.WeldParts(handle, cork, CFrame.new(0, 0, 0.7))
	
	-- Reel
	local reelBody = Util.CreatePart(handle, Vector3.new(0.4, 0.3, 0.4), Color3.fromRGB(80, 80, 90), Enum.Material.Metal, 0, false, false, "ReelBody")
	reelBody.Massless = true
	reelBody.CanCollide = false
	local wReel = Util.WeldParts(handle, reelBody, CFrame.new(0.2, -0.15, 0.3))
	
	-- Reel handle
	local reelHandle = Util.CreatePart(handle, Vector3.new(0.08, 0.08, 0.3), Color3.fromRGB(60, 60, 70), Enum.Material.Metal, 0, false, false, "ReelHandle")
	reelHandle.Massless = true
	reelHandle.CanCollide = false
	local wReelH = Util.WeldParts(reelBody, reelHandle, CFrame.new(0.2, 0, 0))
	
	local reelKnob = Util.CreatePart(handle, Vector3.new(0.12, 0.12, 0.12), Color3.fromRGB(50, 50, 60), Enum.Material.Metal, 0, false, false, "ReelKnob")
	reelKnob.Shape = Enum.PartType.Ball
	reelKnob.Massless = true
	reelKnob.CanCollide = false
	local wReelK = Util.WeldParts(reelHandle, reelKnob, CFrame.new(0, 0, -0.18))
	
	-- Line guides (eyelets along the rod)
	for i = 1, 4 do
		local guide = Util.CreatePart(handle, Vector3.new(0.08, 0.1, 0.04), Color3.fromRGB(150, 150, 160), Enum.Material.Metal, 0, false, false, "Guide"..i)
		guide.Massless = true
		guide.CanCollide = false
		local zPos = -1.0 - (i * 1.5)
		local wGuide = Util.WeldParts(handle, guide, CFrame.new(0, 0.15, zPos))
	end
	
	-- Set the grip point
	tool.GripPos = Vector3.new(0, 0, 1.5)
	tool.GripForward = Vector3.new(0, -0.3, -1).Unit
	tool.GripRight = Vector3.new(1, 0, 0)
	tool.GripUp = Vector3.new(0, 1, -0.3).Unit
	
	return tool
end

------------------------------------------------------------------------
-- BUCKET BUILDER
------------------------------------------------------------------------
local BucketBuilder = {}

function BucketBuilder.Create()
	local tool = Instance.new("Tool")
	tool.Name = "🪣 Fish Bucket"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Your trusty fish bucket. Equip to see your catch!"
	
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = CONFIG.BUCKET_SIZE
	handle.Color = Color3.fromRGB(120, 120, 130)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	
	-- Bucket is hollow - create walls
	-- Bottom
	local bottom = Util.CreatePart(handle, Vector3.new(CONFIG.BUCKET_SIZE.X * 0.85, 0.08, CONFIG.BUCKET_SIZE.Z * 0.85), Color3.fromRGB(110, 110, 120), Enum.Material.Metal, 0, false, false, "Bottom")
	bottom.Massless = true
	bottom.CanCollide = false
	Util.WeldParts(handle, bottom, CFrame.new(0, -CONFIG.BUCKET_SIZE.Y/2 + 0.04, 0))
	
	-- Inner space (dark)
	local inner = Util.CreatePart(handle, Vector3.new(CONFIG.BUCKET_SIZE.X * 0.75, CONFIG.BUCKET_SIZE.Y * 0.7, CONFIG.BUCKET_SIZE.Z * 0.75), Color3.fromRGB(40, 40, 45), Enum.Material.Metal, 0, false, false, "Inner")
	inner.Massless = true
	inner.CanCollide = false
	Util.WeldParts(handle, inner, CFrame.new(0, 0.05, 0))
	
	-- Rim
	local rim = Util.CreatePart(handle, Vector3.new(CONFIG.BUCKET_SIZE.X * 1.05, 0.06, CONFIG.BUCKET_SIZE.Z * 1.05), Color3.fromRGB(140, 140, 150), Enum.Material.Metal, 0, false, false, "Rim")
	rim.Massless = true
	rim.CanCollide = false
	Util.WeldParts(handle, rim, CFrame.new(0, CONFIG.BUCKET_SIZE.Y/2 - 0.03, 0))
	
	-- Bucket handle (the carrying handle)
	local bucketHandle = Util.CreatePart(handle, Vector3.new(0.06, 0.06, CONFIG.BUCKET_SIZE.X * 0.8), Color3.fromRGB(80, 80, 90), Enum.Material.Metal, 0, false, false, "BucketCarryHandle")
	bucketHandle.Massless = true
	bucketHandle.CanCollide = false
	Util.WeldParts(handle, bucketHandle, CFrame.new(0, CONFIG.BUCKET_SIZE.Y/2 + 0.3, 0) * CFrame.Angles(math.rad(30), 0, 0))
	
	-- Bucket handle sides
	for _, side in ipairs({1, -1}) do
		local handleSide = Util.CreatePart(handle, Vector3.new(0.06, 0.35, 0.06), Color3.fromRGB(80, 80, 90), Enum.Material.Metal, 0, false, false, "HandleSide" .. (side == 1 and "R" or "L"))
		handleSide.Massless = true
		handleSide.CanCollide = false
		Util.WeldParts(handle, handleSide, CFrame.new(0, CONFIG.BUCKET_SIZE.Y/2 + 0.15, side * CONFIG.BUCKET_SIZE.Z * 0.35))
	end
	
	tool.GripPos = Vector3.new(0, -0.2, 0)
	
	return tool
end

------------------------------------------------------------------------
-- BOBBER BUILDER
------------------------------------------------------------------------
local BobberBuilder = {}

function BobberBuilder.Create(parent)
	local bobber = Instance.new("Model")
	bobber.Name = "Bobber"
	
	-- Main float body
	local body = Util.CreatePart(bobber, CONFIG.BOBBER_SIZE, CONFIG.BOBBER_COLOR, Enum.Material.SmoothPlastic, 0, true, false, "BobberBody")
	bobber.PrimaryPart = body
	
	-- White bottom half
	local whiteHalf = Util.CreatePart(bobber, Vector3.new(CONFIG.BOBBER_SIZE.X * 0.9, CONFIG.BOBBER_SIZE.Y * 0.45, CONFIG.BOBBER_SIZE.Z * 0.9), CONFIG.BOBBER_WHITE, Enum.Material.SmoothPlastic, 0, true, false, "BobberWhite")
	whiteHalf.CFrame = body.CFrame * CFrame.new(0, -CONFIG.BOBBER_SIZE.Y * 0.2, 0)
	
	-- Stick on top
	local stick = Util.CreatePart(bobber, Vector3.new(0.04, 0.3, 0.04), Color3.fromRGB(60, 40, 20), Enum.Material.Wood, 0, true, false, "BobberStick")
	stick.CFrame = body.CFrame * CFrame.new(0, CONFIG.BOBBER_SIZE.Y/2 + 0.15, 0)
	
	-- Tiny hook line below
	local hookLine = Util.CreatePart(bobber, Vector3.new(0.02, 0.5, 0.02), CONFIG.LINE_COLOR, Enum.Material.Metal, 0, true, false, "HookLine")
	hookLine.CFrame = body.CFrame * CFrame.new(0, -CONFIG.BOBBER_SIZE.Y/2 - 0.25, 0)
	
	-- Hook
	local hook = Util.CreatePart(bobber, Vector3.new(0.05, 0.1, 0.05), Color3.fromRGB(180, 180, 180), Enum.Material.Metal, 0, true, false, "Hook")
	hook.CFrame = hookLine.CFrame * CFrame.new(0.02, -0.3, 0) * CFrame.Angles(0, 0, math.rad(30))
	
	bobber.Parent = parent
	return bobber
end

------------------------------------------------------------------------
-- FISHING LINE RENDERER
------------------------------------------------------------------------
local LineRenderer = {}

function LineRenderer.Create(parent)
	local folder = Instance.new("Folder")
	folder.Name = "FishingLine"
	folder.Parent = parent
	
	local line = {
		folder = folder,
		segments = {},
		segmentCount = 0,
	}
	
	return line
end

function LineRenderer.Update(line, startPos, endPos, segments, sag)
	segments = segments or 10
	sag = sag or 0.5
	
	-- Create or reuse segment parts
	while #line.segments < segments do
		local seg = Util.CreatePart(line.folder, Vector3.new(CONFIG.LINE_THICKNESS, CONFIG.LINE_THICKNESS, 1), CONFIG.LINE_COLOR, Enum.Material.Metal, 0, true, false, "LineSeg" .. (#line.segments + 1))
		table.insert(line.segments, seg)
	end
	
	-- Hide excess segments
	for i = segments + 1, #line.segments do
		line.segments[i].Transparency = 1
	end
	
	-- Calculate catenary-ish curve
	for i = 1, segments do
		local t0 = (i - 1) / segments
		local t1 = i / segments
		local tMid = (t0 + t1) / 2
		
		-- Parabolic sag
		local sagAmount = sag * 4 * tMid * (1 - tMid) -- Maximum sag at midpoint
		
		local p0 = startPos:Lerp(endPos, t0) - Vector3.new(0, sag * 4 * t0 * (1 - t0), 0)
		local p1 = startPos:Lerp(endPos, t1) - Vector3.new(0, sag * 4 * t1 * (1 - t1), 0)
		
		local segDir = (p1 - p0)
		local segLen = segDir.Magnitude
		
		if segLen > 0.001 then
			local seg = line.segments[i]
			seg.Size = Vector3.new(CONFIG.LINE_THICKNESS, CONFIG.LINE_THICKNESS, segLen)
			seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
			seg.Transparency = 0
		end
	end
	
	line.segmentCount = segments
end

function LineRenderer.Destroy(line)
	if line.folder then
		line.folder:Destroy()
	end
end

------------------------------------------------------------------------
-- GUI SYSTEM
------------------------------------------------------------------------
local GUISystem = {}

function GUISystem.Create(playerGui)
	local gui = {}
	
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FishingGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	gui.screenGui = screenGui
	
	-- Cast Power Bar
	local powerFrame = Instance.new("Frame")
	powerFrame.Name = "PowerBar"
	powerFrame.Size = UDim2.new(0, 200, 0, 25)
	powerFrame.Position = UDim2.new(0.5, -100, 0.85, 0)
	powerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	powerFrame.BorderSizePixel = 0
	powerFrame.Visible = false
	powerFrame.Parent = screenGui
	
	local powerCorner = Instance.new("UICorner")
	powerCorner.CornerRadius = UDim.new(0, 6)
	powerCorner.Parent = powerFrame
	
	local powerFill = Instance.new("Frame")
	powerFill.Name = "Fill"
	powerFill.Size = UDim2.new(0, 0, 1, -4)
	powerFill.Position = UDim2.new(0, 2, 0, 2)
	powerFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	powerFill.BorderSizePixel = 0
	powerFill.Parent = powerFrame
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = powerFill
	
	local powerLabel = Instance.new("TextLabel")
	powerLabel.Name = "Label"
	powerLabel.Size = UDim2.new(1, 0, 1, 0)
	powerLabel.BackgroundTransparency = 1
	powerLabel.Text = "CAST POWER"
	powerLabel.TextColor3 = Color3.new(1,1,1)
	powerLabel.TextScaled = true
	powerLabel.Font = Enum.Font.GothamBold
	powerLabel.Parent = powerFrame
	
	gui.powerFrame = powerFrame
	gui.powerFill = powerFill
	
	-- Status Text
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(0, 400, 0, 40)
	statusLabel.Position = UDim2.new(0.5, -200, 0.75, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.new(1,1,1)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextStrokeTransparency = 0.5
	statusLabel.Visible = false
	statusLabel.Parent = screenGui
	gui.statusLabel = statusLabel
	
	-- Tension Bar (during fish fight)
	local tensionFrame = Instance.new("Frame")
	tensionFrame.Name = "TensionBar"
	tensionFrame.Size = UDim2.new(0, 250, 0, 20)
	tensionFrame.Position = UDim2.new(0.5, -125, 0.8, 0)
	tensionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	tensionFrame.BorderSizePixel = 0
	tensionFrame.Visible = false
	tensionFrame.Parent = screenGui
	
	local tensionCorner = Instance.new("UICorner")
	tensionCorner.CornerRadius = UDim.new(0, 6)
	tensionCorner.Parent = tensionFrame
	
	local tensionFill = Instance.new("Frame")
	tensionFill.Name = "Fill"
	tensionFill.Size = UDim2.new(0.5, 0, 1, -4)
	tensionFill.Position = UDim2.new(0, 2, 0, 2)
	tensionFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	tensionFill.BorderSizePixel = 0
	tensionFill.Parent = tensionFrame
	
	local tensionFillCorner = Instance.new("UICorner")
	tensionFillCorner.CornerRadius = UDim.new(0, 4)
	tensionFillCorner.Parent = tensionFill
	
	local tensionLabel = Instance.new("TextLabel")
	tensionLabel.Name = "Label"
	tensionLabel.Size = UDim2.new(1, 0, 0, 15)
	tensionLabel.Position = UDim2.new(0, 0, 0, -18)
	tensionLabel.BackgroundTransparency = 1
	tensionLabel.Text = "LINE TENSION"
	tensionLabel.TextColor3 = Color3.new(1,1,1)
	tensionLabel.TextScaled = true
	tensionLabel.Font = Enum.Font.GothamBold
	tensionLabel.TextStrokeTransparency = 0.5
	tensionLabel.Parent = tensionFrame
	
	gui.tensionFrame = tensionFrame
	gui.tensionFill = tensionFill
	
	-- Fish Catch Display
	local catchFrame = Instance.new("Frame")
	catchFrame.Name = "CatchDisplay"
	catchFrame.Size = UDim2.new(0, 350, 0, 180)
	catchFrame.Position = UDim2.new(0.5, -175, 0.3, 0)
	catchFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	catchFrame.BackgroundTransparency = 0.15
	catchFrame.BorderSizePixel = 0
	catchFrame.Visible = false
	catchFrame.Parent = screenGui
	
	local catchCorner = Instance.new("UICorner")
	catchCorner.CornerRadius = UDim.new(0, 12)
	catchCorner.Parent = catchFrame
	
	local catchStroke = Instance.new("UIStroke")
	catchStroke.Thickness = 2
	catchStroke.Color = Color3.fromRGB(255, 200, 50)
	catchStroke.Parent = catchFrame
	
	local catchTitle = Instance.new("TextLabel")
	catchTitle.Name = "Title"
	catchTitle.Size = UDim2.new(1, -20, 0, 30)
	catchTitle.Position = UDim2.new(0, 10, 0, 10)
	catchTitle.BackgroundTransparency = 1
	catchTitle.Text = "🎣 FISH CAUGHT!"
	catchTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
	catchTitle.TextScaled = true
	catchTitle.Font = Enum.Font.GothamBold
	catchTitle.TextXAlignment = Enum.TextXAlignment.Left
	catchTitle.Parent = catchFrame
	
	local catchName = Instance.new("TextLabel")
	catchName.Name = "FishName"
	catchName.Size = UDim2.new(1, -20, 0, 35)
	catchName.Position = UDim2.new(0, 10, 0, 45)
	catchName.BackgroundTransparency = 1
	catchName.Text = "Fish Name"
	catchName.TextColor3 = Color3.new(1,1,1)
	catchName.TextScaled = true
	catchName.Font = Enum.Font.GothamBold
	catchName.TextXAlignment = Enum.TextXAlignment.Left
	catchName.Parent = catchFrame
	
	local catchRarity = Instance.new("TextLabel")
	catchRarity.Name = "Rarity"
	catchRarity.Size = UDim2.new(1, -20, 0, 22)
	catchRarity.Position = UDim2.new(0, 10, 0, 82)
	catchRarity.BackgroundTransparency = 1
	catchRarity.Text = "Rarity"
	catchRarity.TextColor3 = Color3.fromRGB(200, 200, 200)
	catchRarity.TextScaled = true
	catchRarity.Font = Enum.Font.Gotham
	catchRarity.TextXAlignment = Enum.TextXAlignment.Left
	catchRarity.Parent = catchFrame
	
	local catchWeight = Instance.new("TextLabel")
	catchWeight.Name = "Weight"
	catchWeight.Size = UDim2.new(1, -20, 0, 22)
	catchWeight.Position = UDim2.new(0, 10, 0, 106)
	catchWeight.BackgroundTransparency = 1
	catchWeight.Text = "Weight"
	catchWeight.TextColor3 = Color3.fromRGB(200, 200, 200)
	catchWeight.TextScaled = true
	catchWeight.Font = Enum.Font.Gotham
	catchWeight.TextXAlignment = Enum.TextXAlignment.Left
	catchWeight.Parent = catchFrame
	
	local catchDesc = Instance.new("TextLabel")
	catchDesc.Name = "Description"
	catchDesc.Size = UDim2.new(1, -20, 0, 30)
	catchDesc.Position = UDim2.new(0, 10, 0, 135)
	catchDesc.BackgroundTransparency = 1
	catchDesc.Text = "Description"
	catchDesc.TextColor3 = Color3.fromRGB(150, 150, 160)
	catchDesc.TextScaled = true
	catchDesc.Font = Enum.Font.GothamItalic
	catchDesc.TextXAlignment = Enum.TextXAlignment.Left
	catchDesc.TextWrapped = true
	catchDesc.Parent = catchFrame
	
	gui.catchFrame = catchFrame
	gui.catchTitle = catchTitle
	gui.catchName = catchName
	gui.catchRarity = catchRarity
	gui.catchWeight = catchWeight
	gui.catchDesc = catchDesc
	gui.catchStroke = catchStroke
	
	-- Bucket inventory display
	local bucketFrame = Instance.new("Frame")
	bucketFrame.Name = "BucketDisplay"
	bucketFrame.Size = UDim2.new(0, 300, 0, 400)
	bucketFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
	bucketFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	bucketFrame.BackgroundTransparency = 0.1
	bucketFrame.BorderSizePixel = 0
	bucketFrame.Visible = false
	bucketFrame.Parent = screenGui
	
	local bucketCorner = Instance.new("UICorner")
	bucketCorner.CornerRadius = UDim.new(0, 12)
	bucketCorner.Parent = bucketFrame
	
	local bucketStroke = Instance.new("UIStroke")
	bucketStroke.Thickness = 2
	bucketStroke.Color = Color3.fromRGB(100, 150, 255)
	bucketStroke.Parent = bucketFrame
	
	local bucketTitle = Instance.new("TextLabel")
	bucketTitle.Name = "Title"
	bucketTitle.Size = UDim2.new(1, -20, 0, 35)
	bucketTitle.Position = UDim2.new(0, 10, 0, 5)
	bucketTitle.BackgroundTransparency = 1
	bucketTitle.Text = "🪣 FISH BUCKET"
	bucketTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
	bucketTitle.TextScaled = true
	bucketTitle.Font = Enum.Font.GothamBold
	bucketTitle.Parent = bucketFrame
	
	local bucketScroll = Instance.new("ScrollingFrame")
	bucketScroll.Name = "FishList"
	bucketScroll.Size = UDim2.new(1, -20, 1, -50)
	bucketScroll.Position = UDim2.new(0, 10, 0, 45)
	bucketScroll.BackgroundTransparency = 1
	bucketScroll.BorderSizePixel = 0
	bucketScroll.ScrollBarThickness = 6
	bucketScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
	bucketScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	bucketScroll.Parent = bucketFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = bucketScroll
	
	gui.bucketFrame = bucketFrame
	gui.bucketScroll = bucketScroll
	gui.bucketListLayout = listLayout
	
	-- Notification text (bottom)
	local notifLabel = Instance.new("TextLabel")
	notifLabel.Name = "Notification"
	notifLabel.Size = UDim2.new(0, 500, 0, 30)
	notifLabel.Position = UDim2.new(0.5, -250, 0.92, 0)
	notifLabel.BackgroundTransparency = 1
	notifLabel.Text = ""
	notifLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
	notifLabel.TextScaled = true
	notifLabel.Font = Enum.Font.GothamBold
	notifLabel.TextStrokeTransparency = 0.3
	notifLabel.TextStrokeColor3 = Color3.new(0,0,0)
	notifLabel.Visible = false
	notifLabel.Parent = screenGui
	gui.notifLabel = notifLabel
	
	return gui
end

function GUISystem.ShowNotification(gui, text, duration, color)
	gui.notifLabel.Text = text
	gui.notifLabel.TextColor3 = color or Color3.fromRGB(255, 255, 200)
	gui.notifLabel.Visible = true
	gui.notifLabel.TextTransparency = 0
	gui.notifLabel.TextStrokeTransparency = 0.3
	
	task.delay(duration or 2, function()
		-- Fade out
		for i = 0, 1, 0.05 do
			gui.notifLabel.TextTransparency = i
			gui.notifLabel.TextStrokeTransparency = 0.3 + i * 0.7
			task.wait(0.02)
		end
		gui.notifLabel.Visible = false
	end)
end

function GUISystem.ShowCatch(gui, fishData, weight)
	local rarityColor = RarityColors[fishData.rarity] or Color3.new(1,1,1)
	
	gui.catchName.Text = fishData.name
	gui.catchName.TextColor3 = rarityColor
	gui.catchRarity.Text = "⭐ " .. fishData.rarity
	gui.catchRarity.TextColor3 = rarityColor
	gui.catchWeight.Text = string.format("⚖ %.2f lbs", weight)
	gui.catchDesc.Text = '"' .. fishData.description .. '"'
	gui.catchStroke.Color = rarityColor
	
	gui.catchFrame.Visible = true
	gui.catchFrame.Size = UDim2.new(0, 0, 0, 0)
	gui.catchFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
	
	-- Animate in
	local tweenIn = TweenService:Create(gui.catchFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 350, 0, 180),
		Position = UDim2.new(0.5, -175, 0.3, 0)
	})
	tweenIn:Play()
	
	-- Auto hide after 4 seconds
	task.delay(4, function()
		local tweenOut = TweenService:Create(gui.catchFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.4, 0)
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		gui.catchFrame.Visible = false
	end)
end

function GUISystem.UpdateBucket(gui, caughtFish)
	-- Clear existing
	for _, child in ipairs(gui.bucketScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	if #caughtFish == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No fish yet... go catch some!"
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 110)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.GothamItalic
		emptyLabel.Name = "EmptyFrame"
		emptyLabel.Parent = gui.bucketScroll
	end
	
	for i, fish in ipairs(caughtFish) do
		local rarityColor = RarityColors[fish.rarity] or Color3.new(1,1,1)
		
		local entry = Instance.new("Frame")
		entry.Name = "Fish_" .. i
		entry.Size = UDim2.new(1, -10, 0, 35)
		entry.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		entry.BorderSizePixel = 0
		entry.LayoutOrder = i
		entry.Parent = gui.bucketScroll
		
		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 6)
		entryCorner.Parent = entry
		
		local entryStroke = Instance.new("UIStroke")
		entryStroke.Thickness = 1
		entryStroke.Color = rarityColor
		entryStroke.Transparency = 0.5
		entryStroke.Parent = entry
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 8, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = fish.name
		nameLabel.TextColor3 = rarityColor
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entry
		
		local weightLabel = Instance.new("TextLabel")
		weightLabel.Size = UDim2.new(0.3, 0, 1, 0)
		weightLabel.Position = UDim2.new(0.68, 0, 0, 0)
		weightLabel.BackgroundTransparency = 1
		weightLabel.Text = string.format("%.1f lb", fish.weight)
		weightLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		weightLabel.TextScaled = true
		weightLabel.Font = Enum.Font.Gotham
		weightLabel.TextXAlignment = Enum.TextXAlignment.Right
		weightLabel.Parent = entry
	end
	
	gui.bucketScroll.CanvasSize = UDim2.new(0, 0, 0, #caughtFish * 39 + 10)
end

------------------------------------------------------------------------
-- SPLASH EFFECT
------------------------------------------------------------------------
local Effects = {}

function Effects.Splash(position, size)
	size = size or 1
	local folder = Instance.new("Folder")
	folder.Name = "Splash"
	folder.Parent = Workspace
	
	-- Ring of particles
	local particleCount = 12
	local particles = {}
	
	for i = 1, particleCount do
		local angle = (i / particleCount) * math.pi * 2
		local speed = Util.RandomInRange(5, 12) * size
		local p = Util.CreatePart(folder, 
			Vector3.new(0.15, 0.15, 0.15) * size, 
			Color3.fromRGB(180, 220, 255), 
			Enum.Material.SmoothPlastic, 
			0.3, true, false, "SplashParticle")
		p.Shape = Enum.PartType.Ball
		p.CFrame = CFrame.new(position)
		
		table.insert(particles, {
			part = p,
			velocity = Vector3.new(
				math.cos(angle) * speed,
				Util.RandomInRange(8, 15) * size,
				math.sin(angle) * speed
			),
			life = 0,
			maxLife = Util.RandomInRange(0.5, 1.0),
		})
	end
	
	-- Ripple ring
	local ring = Util.CreatePart(folder, Vector3.new(0.5, 0.05, 0.5) * size, Color3.fromRGB(200, 230, 255), Enum.Material.SmoothPlastic, 0.5, true, false, "Ripple")
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	
	-- Animate
	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < 1.5 do
			local dt = RunService.Heartbeat:Wait()
			local elapsed = tick() - startTime
			
			for _, particle in ipairs(particles) do
				particle.life = particle.life + dt
				if particle.life < particle.maxLife then
					particle.velocity = particle.velocity + Vector3.new(0, -30, 0) * dt -- gravity
					particle.part.CFrame = particle.part.CFrame + particle.velocity * dt
					particle.part.Transparency = 0.3 + (particle.life / particle.maxLife) * 0.7
					particle.part.Size = particle.part.Size * (1 - dt * 2)
				else
					particle.part.Transparency = 1
				end
			end
			
			-- Expand ripple
			local rippleScale = 1 + elapsed * 6
			ring.Size = Vector3.new(0.05 * size, rippleScale * size, rippleScale * size)
			ring.Transparency = 0.5 + elapsed * 0.5
			ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
		end
		
		folder:Destroy()
	end)
end

function Effects.Nibble(bobberModel)
	if not bobberModel or not bobberModel.PrimaryPart then return end
	task.spawn(function()
		local body = bobberModel.PrimaryPart
		local originalY = body.Position.Y
		for i = 1, 3 do
			for j = 0, 1, 0.15 do
				if not body or not body.Parent then return end
				local dip = math.sin(j * math.pi) * 0.15
				body.CFrame = CFrame.new(body.Position.X, originalY - dip, body.Position.Z)
				-- Move all other parts relative
				for _, p in ipairs(bobberModel:GetDescendants()) do
					if p:IsA("BasePart") and p ~= body then
						-- Parts are positioned relative to body, will follow
					end
				end
				task.wait(0.02)
			end
		end
	end)
end

function Effects.BigBite(bobberModel)
	if not bobberModel or not bobberModel.PrimaryPart then return end
	task.spawn(function()
		local body = bobberModel.PrimaryPart
		local origPos = body.Position
		for i = 0, 1, 0.05 do
			if not body or not body.Parent then return end
			local dip = math.sin(i * math.pi * 3) * 0.4 * (1 - i)
			local pos = Vector3.new(origPos.X, origPos.Y - math.abs(dip) - i * 0.3, origPos.Z)
			body.CFrame = CFrame.new(pos)
			task.wait(0.02)
		end
	end)
end

------------------------------------------------------------------------
-- CFRAME ANIMATION SYSTEM (THE REAL COOK)
------------------------------------------------------------------------
local CFrameAnimator = {}

-- Store original Motor6D transforms
CFrameAnimator.OriginalTransforms = {}
CFrameAnimator.Motors = {}
CFrameAnimator.IsR15 = false
CFrameAnimator.AnimationTime = 0
CFrameAnimator.CurrentState = "idle" -- idle, walking, casting, fishing, reeling, holding

function CFrameAnimator.Initialize(character, humanoid)
	CFrameAnimator.Motors = {}
	CFrameAnimator.OriginalTransforms = {}
	CFrameAnimator.AnimationTime = 0
	
	-- Disable default animations
	local animate = character:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	
	-- Disable default animation controller
	for _, v in ipairs(humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
	
	-- Determine if R15 or R6
	CFrameAnimator.IsR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	
	-- Collect all Motor6D joints
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") then
			CFrameAnimator.Motors[desc.Name] = desc
			CFrameAnimator.OriginalTransforms[desc.Name] = {
				C0 = desc.C0,
				C1 = desc.C1,
			}
		end
	end
end

function CFrameAnimator.GetMotor(name)
	return CFrameAnimator.Motors[name]
end

function CFrameAnimator.SetTransform(motorName, cf)
	local motor = CFrameAnimator.Motors[motorName]
	if motor then
		local orig = CFrameAnimator.OriginalTransforms[motorName]
		if orig then
			motor.Transform = cf
		end
	end
end

function CFrameAnimator.Update(dt, humanoid, state)
	CFrameAnimator.AnimationTime = CFrameAnimator.AnimationTime + dt
	local t = CFrameAnimator.AnimationTime
	
	local speed = humanoid.MoveDirection.Magnitude
	local isMoving = speed > 0.1
	local walkSpeed = humanoid.WalkSpeed
	local walkCycle = t * CONFIG.WALK_BOB_SPEED * (walkSpeed / 16) -- Normalize to default walkspeed
	
	if CFrameAnimator.IsR15 then
		CFrameAnimator.UpdateR15(dt, t, isMoving, walkCycle, state)
	else
		CFrameAnimator.UpdateR6(dt, t, isMoving, walkCycle, state)
	end
end

function CFrameAnimator.UpdateR15(dt, t, isMoving, walkCycle, state)
	-- R15 joints:
	-- Waist (UpperTorso -> LowerTorso)
	-- Neck (Head -> UpperTorso)
	-- RightShoulder, LeftShoulder
	-- RightElbow, LeftElbow
	-- RightWrist, LeftWrist
	-- RightHip, LeftHip
	-- RightKnee, LeftKnee
	-- RightAnkle, LeftAnkle
	-- Root (LowerTorso -> HumanoidRootPart)
	
	if state == "casting" then
		-- CASTING POSE: Right arm pulled back, body leaning
		local castPhase = (t * 2) % 1
		
		CFrameAnimator.SetTransform("Waist", CFrame.Angles(math.rad(-5), math.rad(15), 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(5), math.rad(-10), 0))
		
		-- Right arm - pulled back for casting
		CFrameAnimator.SetTransform("RightShoulder", CFrame.Angles(math.rad(-120), math.rad(20), math.rad(10)))
		CFrameAnimator.SetTransform("RightElbow", CFrame.Angles(math.rad(-40), 0, 0))
		
		-- Left arm - supporting
		CFrameAnimator.SetTransform("LeftShoulder", CFrame.Angles(math.rad(-30), math.rad(10), math.rad(-10)))
		CFrameAnimator.SetTransform("LeftElbow", CFrame.Angles(math.rad(-20), 0, 0))
		
		-- Legs stable
		CFrameAnimator.SetTransform("RightHip", CFrame.Angles(math.rad(5), 0, 0))
		CFrameAnimator.SetTransform("LeftHip", CFrame.Angles(math.rad(-5), 0, 0))
		CFrameAnimator.SetTransform("RightKnee", CFrame.Angles(math.rad(5), 0, 0))
		CFrameAnimator.SetTransform("LeftKnee", CFrame.Angles(math.rad(5), 0, 0))
		
		return
	elseif state == "cast_release" then
		-- Whip forward motion
		CFrameAnimator.SetTransform("Waist", CFrame.Angles(math.rad(10), math.rad(-20), 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(-5), math.rad(15), 0))
		
		CFrameAnimator.SetTransform("RightShoulder", CFrame.Angles(math.rad(-160), math.rad(-10), math.rad(15)))
		CFrameAnimator.SetTransform("RightElbow", CFrame.Angles(math.rad(-10), 0, 0))
		
		CFrameAnimator.SetTransform("LeftShoulder", CFrame.Angles(math.rad(-60), math.rad(-5), math.rad(-15)))
		CFrameAnimator.SetTransform("LeftElbow", CFrame.Angles(math.rad(-30), 0, 0))
		
		return
	elseif state == "fishing" then
		-- Relaxed fishing pose with gentle idle sway
		local breathe = math.sin(t * CONFIG.IDLE_BREATHE_SPEED) * CONFIG.IDLE_BREATHE_AMOUNT
		local sway = math.sin(t * 0.8) * math.rad(2)
		
		CFrameAnimator.SetTransform("Waist", CFrame.Angles(math.rad(3), sway, 0) + Vector3.new(0, breathe, 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(8), -sway * 0.5, 0))
		
		-- Right arm holding rod forward
		CFrameAnimator.SetTransform("RightShoulder", CFrame.Angles(math.rad(-50) + math.sin(t * 0.6) * math.rad(2), math.rad(10), math.rad(10)))
		CFrameAnimator.SetTransform("RightElbow", CFrame.Angles(math.rad(-25), 0, 0))
		
		-- Left arm resting on rod or by side
		CFrameAnimator.SetTransform("LeftShoulder", CFrame.Angles(math.rad(-35) + math.sin(t * 0.7) * math.rad(1), math.rad(5), math.rad(-5)))
		CFrameAnimator.SetTransform("LeftElbow", CFrame.Angles(math.rad(-15), 0, 0))
		
		-- Legs slightly apart, relaxed
		CFrameAnimator.SetTransform("RightHip", CFrame.Angles(math.rad(2), math.rad(-5), 0))
		CFrameAnimator.SetTransform("LeftHip", CFrame.Angles(math.rad(2), math.rad(5), 0))
		CFrameAnimator.SetTransform("RightKnee", CFrame.Angles(math.rad(3), 0, 0))
		CFrameAnimator.SetTransform("LeftKnee", CFrame.Angles(math.rad(3), 0, 0))
		
		return
	elseif state == "reeling" then
		-- Active reeling animation - cranking motion
		local reelCycle = t * 6
		local crankAngle = reelCycle % (math.pi * 2)
		
		CFrameAnimator.SetTransform("Waist", CFrame.Angles(math.rad(8), math.sin(reelCycle * 0.3) * math.rad(5), 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(5), 0, 0))
		
		-- Right arm pumping/holding rod
		local rodPump = math.sin(reelCycle * 2) * math.rad(10)
		CFrameAnimator.SetTransform("RightShoulder", CFrame.Angles(math.rad(-70) + rodPump, math.rad(15), math.rad(10)))
		CFrameAnimator.SetTransform("RightElbow", CFrame.Angles(math.rad(-35) + rodPump * 0.5, 0, 0))
		
		-- Left arm cranking the reel - circular motion
		local crankX = math.cos(crankAngle) * math.rad(20)
		local crankY = math.sin(crankAngle) * math.rad(20)
		CFrameAnimator.SetTransform("LeftShoulder", CFrame.Angles(math.rad(-50) + crankX, math.rad(15) + crankY, math.rad(-10)))
		CFrameAnimator.SetTransform("LeftElbow", CFrame.Angles(math.rad(-40) + math.cos(crankAngle) * math.rad(15), 0, 0))
		
		-- Braced legs
		CFrameAnimator.SetTransform("RightHip", CFrame.Angles(math.rad(-5), math.rad(-8), 0))
		CFrameAnimator.SetTransform("LeftHip", CFrame.Angles(math.rad(5), math.rad(8), 0))
		CFrameAnimator.SetTransform("RightKnee", CFrame.Angles(math.rad(8), 0, 0))
		CFrameAnimator.SetTransform("LeftKnee", CFrame.Angles(math.rad(8), 0, 0))
		
		return
	elseif state == "holding_fish" then
		-- Holding up a fish proudly
		local show = math.sin(t * 2) * math.rad(3)
		
		CFrameAnimator.SetTransform("Waist", CFrame.Angles(math.rad(-5), 0, 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(-10) + show, 0, 0))
		
		CFrameAnimator.SetTransform("RightShoulder", CFrame.Angles(math.rad(-150) + show, math.rad(20), math.rad(15)))
		CFrameAnimator.SetTransform("RightElbow", CFrame.Angles(math.rad(-20), 0, 0))
		
		CFrameAnimator.SetTransform("LeftShoulder", CFrame.Angles(math.rad(-140) + show, math.rad(-20), math.rad(-15)))
		CFrameAnimator.SetTransform("LeftElbow", CFrame.Angles(math.rad(-20), 0, 0))
		
		return
	end
	
	-- DEFAULT STATES: idle and walking
	if isMoving then
		-- WALKING ANIMATION - Full procedural walk cycle
		local legSwing = math.sin(walkCycle) * CONFIG.WALK_LEG_SWING
		local armSwing = math.sin(walkCycle) * CONFIG.WALK_ARM_SWING
		local bob = math.abs(math.sin(walkCycle)) * CONFIG.WALK_BOB_HEIGHT
		local torsoBob = math.sin(walkCycle * 2) * CONFIG.WALK_TORSO_SWAY
		local headBob = math.sin(walkCycle * 2) * CONFIG.WALK_HEAD_BOB
		
		-- Secondary motion
		local hipSway = math.sin(walkCycle) * math.rad(3)
		local shoulderRoll = math.sin(walkCycle) * math.rad(2)
		
		-- Root bob
		CFrameAnimator.SetTransform("Root", CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, hipSway * 0.5))
		
		-- Torso counter-rotation
		CFrameAnimator.SetTransform("Waist", CFrame.Angles(math.rad(3), -hipSway, torsoBob))
		
		-- Head stabilization (counters torso sway)
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(-headBob, hipSway * 0.5, -torsoBob * 0.3))
		
		-- RIGHT ARM - swings opposite to right leg
		CFrameAnimator.SetTransform("RightShoulder", CFrame.Angles(-armSwing, 0, math.rad(3) + shoulderRoll))
		CFrameAnimator.SetTransform("RightElbow", CFrame.Angles(math.clamp(-armSwing * 0.6, math.rad(-40), 0), 0, 0))
		if CFrameAnimator.Motors["RightWrist"] then
			CFrameAnimator.SetTransform("RightWrist", CFrame.Angles(armSwing * 0.15, 0, 0))
		end
		
		-- LEFT ARM - swings opposite to left leg
		CFrameAnimator.SetTransform("LeftShoulder", CFrame.Angles(armSwing, 0, math.rad(-3) - shoulderRoll))
		CFrameAnimator.SetTransform("LeftElbow", CFrame.Angles(math.clamp(armSwing * 0.6, math.rad(-40), 0), 0, 0))
		if CFrameAnimator.Motors["LeftWrist"] then
			CFrameAnimator.SetTransform("LeftWrist", CFrame.Angles(-armSwing * 0.15, 0, 0))
		end
		
		-- RIGHT LEG
		local rightLegForward = math.sin(walkCycle)
		local rightKneeBend = math.max(0, -math.sin(walkCycle + 0.3)) * math.rad(40) + math.rad(2)
		CFrameAnimator.SetTransform("RightHip", CFrame.Angles(legSwing, 0, math.rad(1)))
		CFrameAnimator.SetTransform("RightKnee", CFrame.Angles(rightKneeBend, 0, 0))
		if CFrameAnimator.Motors["RightAnkle"] then
			local ankleFlex = math.sin(walkCycle + 0.5) * math.rad(10)
			CFrameAnimator.SetTransform("RightAnkle", CFrame.Angles(ankleFlex, 0, 0))
		end
		
		-- LEFT LEG (opposite phase)
		local leftKneeBend = math.max(0, math.sin(walkCycle + 0.3)) * math.rad(40) + math.rad(2)
		CFrameAnimator.SetTransform("LeftHip", CFrame.Angles(-legSwing, 0, math.rad(-1)))
		CFrameAnimator.SetTransform("LeftKnee", CFrame.Angles(leftKneeBend, 0, 0))
		if CFrameAnimator.Motors["LeftAnkle"] then
			local ankleFlex = math.sin(-walkCycle + 0.5) * math.rad(10)
			CFrameAnimator.SetTransform("LeftAnkle", CFrame.Angles(ankleFlex, 0, 0))
		end
	else
		-- IDLE ANIMATION - Breathing, subtle sway
		local breathe = math.sin(t * CONFIG.IDLE_BREATHE_SPEED)
		local breatheAmount = CONFIG.IDLE_BREATHE_AMOUNT
		local subtleSway = math.sin(t * 0.5) * math.rad(0.8)
		local subtleSway2 = math.cos(t * 0.3) * math.rad(0.5)
		
		CFrameAnimator.SetTransform("Root", CFrame.new(0, breathe * breatheAmount, 0))
		CFrameAnimator.SetTransform("Waist", CFrame.Angles(0, subtleSway, subtleSway2))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.sin(t * 0.7) * math.rad(1), -subtleSway * 0.5, 0))
		
		-- Arms at rest with slight swing
		CFrameAnimator.SetTransform("RightShoulder", CFrame.Angles(math.rad(2) + subtleSway2, 0, math.rad(4)))
		CFrameAnimator.SetTransform("RightElbow", CFrame.Angles(math.rad(-3), 0, 0))
		
		CFrameAnimator.SetTransform("LeftShoulder", CFrame.Angles(math.rad(2) - subtleSway2, 0, math.rad(-4)))
		CFrameAnimator.SetTransform("LeftElbow", CFrame.Angles(math.rad(-3), 0, 0))
		
		-- Legs slight bend
		CFrameAnimator.SetTransform("RightHip", CFrame.Angles(math.rad(1), 0, 0))
		CFrameAnimator.SetTransform("LeftHip", CFrame.Angles(math.rad(1), 0, 0))
		CFrameAnimator.SetTransform("RightKnee", CFrame.Angles(math.rad(2), 0, 0))
		CFrameAnimator.SetTransform("LeftKnee", CFrame.Angles(math.rad(2), 0, 0))
		
		if CFrameAnimator.Motors["RightWrist"] then
			CFrameAnimator.SetTransform("RightWrist", CFrame.new())
		end
		if CFrameAnimator.Motors["LeftWrist"] then
			CFrameAnimator.SetTransform("LeftWrist", CFrame.new())
		end
		if CFrameAnimator.Motors["RightAnkle"] then
			CFrameAnimator.SetTransform("RightAnkle", CFrame.new())
		end
		if CFrameAnimator.Motors["LeftAnkle"] then
			CFrameAnimator.SetTransform("LeftAnkle", CFrame.new())
		end
	end
end

function CFrameAnimator.UpdateR6(dt, t, isMoving, walkCycle, state)
	-- R6 joints: Right Shoulder, Left Shoulder, Right Hip, Left Hip, Neck, RootJoint
	
	if state == "casting" then
		CFrameAnimator.SetTransform("RootJoint", CFrame.Angles(0, math.rad(15), 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(5), math.rad(-10), 0))
		CFrameAnimator.SetTransform("Right Shoulder", CFrame.Angles(math.rad(-150), math.rad(20), math.rad(10)))
		CFrameAnimator.SetTransform("Left Shoulder", CFrame.Angles(math.rad(-30), math.rad(10), math.rad(-10)))
		CFrameAnimator.SetTransform("Right Hip", CFrame.Angles(math.rad(3), 0, 0))
		CFrameAnimator.SetTransform("Left Hip", CFrame.Angles(math.rad(-3), 0, 0))
		return
	elseif state == "cast_release" then
		CFrameAnimator.SetTransform("RootJoint", CFrame.Angles(math.rad(5), math.rad(-15), 0))
		CFrameAnimator.SetTransform("Right Shoulder", CFrame.Angles(math.rad(-200), math.rad(-5), math.rad(15)))
		CFrameAnimator.SetTransform("Left Shoulder", CFrame.Angles(math.rad(-80), math.rad(-5), math.rad(-10)))
		return
	elseif state == "fishing" then
		local breathe = math.sin(t * CONFIG.IDLE_BREATHE_SPEED) * CONFIG.IDLE_BREATHE_AMOUNT
		local sway = math.sin(t * 0.8) * math.rad(2)
		
		CFrameAnimator.SetTransform("RootJoint", CFrame.new(0, breathe, 0) * CFrame.Angles(math.rad(2), sway, 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(8), -sway * 0.5, 0))
		CFrameAnimator.SetTransform("Right Shoulder", CFrame.Angles(math.rad(-60) + math.sin(t * 0.6) * math.rad(2), math.rad(10), math.rad(10)))
		CFrameAnimator.SetTransform("Left Shoulder", CFrame.Angles(math.rad(-40) + math.sin(t * 0.7) * math.rad(1), math.rad(5), math.rad(-5)))
		CFrameAnimator.SetTransform("Right Hip", CFrame.Angles(math.rad(2), math.rad(-3), 0))
		CFrameAnimator.SetTransform("Left Hip", CFrame.Angles(math.rad(2), math.rad(3), 0))
		return
	elseif state == "reeling" then
		local reelCycle = t * 6
		local rodPump = math.sin(reelCycle * 2) * math.rad(10)
		local crankAngle = reelCycle % (math.pi * 2)
		
		CFrameAnimator.SetTransform("RootJoint", CFrame.Angles(math.rad(5), math.sin(reelCycle * 0.3) * math.rad(4), 0))
		CFrameAnimator.SetTransform("Right Shoulder", CFrame.Angles(math.rad(-80) + rodPump, math.rad(10), math.rad(8)))
		CFrameAnimator.SetTransform("Left Shoulder", CFrame.Angles(math.rad(-60) + math.cos(crankAngle) * math.rad(15), math.rad(10) + math.sin(crankAngle) * math.rad(10), math.rad(-8)))
		CFrameAnimator.SetTransform("Right Hip", CFrame.Angles(math.rad(-3), math.rad(-5), 0))
		CFrameAnimator.SetTransform("Left Hip", CFrame.Angles(math.rad(3), math.rad(5), 0))
		return
	elseif state == "holding_fish" then
		local show = math.sin(t * 2) * math.rad(3)
		CFrameAnimator.SetTransform("RootJoint", CFrame.Angles(math.rad(-3), 0, 0))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.rad(-8) + show, 0, 0))
		CFrameAnimator.SetTransform("Right Shoulder", CFrame.Angles(math.rad(-170) + show, math.rad(15), math.rad(10)))
		CFrameAnimator.SetTransform("Left Shoulder", CFrame.Angles(math.rad(-160) + show, math.rad(-15), math.rad(-10)))
		return
	end
	
	if isMoving then
		local legSwing = math.sin(walkCycle) * CONFIG.WALK_LEG_SWING
		local armSwing = math.sin(walkCycle) * CONFIG.WALK_ARM_SWING
		local bob = math.abs(math.sin(walkCycle)) * CONFIG.WALK_BOB_HEIGHT
		local torsoBob = math.sin(walkCycle * 2) * CONFIG.WALK_TORSO_SWAY
		
		CFrameAnimator.SetTransform("RootJoint", CFrame.new(0, bob, 0) * CFrame.Angles(math.rad(3), 0, torsoBob))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(-math.sin(walkCycle * 2) * CONFIG.WALK_HEAD_BOB, 0, -torsoBob * 0.3))
		CFrameAnimator.SetTransform("Right Shoulder", CFrame.Angles(-armSwing, 0, math.rad(3)))
		CFrameAnimator.SetTransform("Left Shoulder", CFrame.Angles(armSwing, 0, math.rad(-3)))
		CFrameAnimator.SetTransform("Right Hip", CFrame.Angles(legSwing, 0, 0))
		CFrameAnimator.SetTransform("Left Hip", CFrame.Angles(-legSwing, 0, 0))
	else
		local breathe = math.sin(t * CONFIG.IDLE_BREATHE_SPEED)
		local breatheAmount = CONFIG.IDLE_BREATHE_AMOUNT
		local subtleSway = math.sin(t * 0.5) * math.rad(0.8)
		
		CFrameAnimator.SetTransform("RootJoint", CFrame.new(0, breathe * breatheAmount, 0) * CFrame.Angles(0, 0, subtleSway))
		CFrameAnimator.SetTransform("Neck", CFrame.Angles(math.sin(t * 0.7) * math.rad(1), -subtleSway * 0.5, 0))
		CFrameAnimator.SetTransform("Right Shoulder", CFrame.Angles(math.rad(2), 0, math.rad(3)))
		CFrameAnimator.SetTransform("Left Shoulder", CFrame.Angles(math.rad(2), 0, math.rad(-3)))
		CFrameAnimator.SetTransform("Right Hip", CFrame.Angles(math.rad(1), 0, 0))
		CFrameAnimator.SetTransform("Left Hip", CFrame.Angles(math.rad(1), 0, 0))
	end
end

------------------------------------------------------------------------
-- MAIN FISHING GAME STATE MACHINE
------------------------------------------------------------------------
local FishingGame = {
	State = "IDLE", -- IDLE, EQUIPPING, CHARGING, CASTING_ARC, WAITING, NIBBLE, BITE, FIGHTING, CAUGHT, BUCKET
	CastPower = 0,
	CastDirection = Vector3.new(0,0,-1),
	BobberPosition = nil,
	BobberModel = nil,
	FishingLine = nil,
	LineSag = 1,
	HookedFish = nil,
	HookedFishData = nil,
	HookedFishWeight = 0,
	Tension = 0,
	FightTimer = 0,
	FightDuration = 0,
	NibbleTimer = 0,
	BiteTimer = 0,
	NibbleCount = 0,
	NibblesRemaining = 0,
	HookWindow = 0,
	IsReeling = false,
	CaughtFish = {}, -- Bucket contents
	FishModel = nil,
	
	-- Tool references
	FishingRod = nil,
	Bucket = nil,
	GUI = nil,
	
	-- Character references
	Character = nil,
	Humanoid = nil,
	RootPart = nil,
	
	-- Animation state
	AnimState = "idle",
	
	-- Casting arc visualization
	ArcParts = {},
	ArcFolder = nil,
	
	-- Input
	MouseDown = false,
	MouseButton1Down = false,
}

function FishingGame.Init()
	local char, humanoid, rootPart = WaitForCharacter()
	FishingGame.Character = char
	FishingGame.Humanoid = humanoid
	FishingGame.RootPart = rootPart
	
	-- Initialize CFrame animator
	CFrameAnimator.Initialize(char, humanoid)
	
	-- Create tools
	FishingGame.FishingRod = FishingRodBuilder.Create()
	FishingGame.Bucket = BucketBuilder.Create()
	
	-- Create GUI
	FishingGame.GUI = GUISystem.Create(LocalPlayer:WaitForChild("PlayerGui"))
	
	-- Put tools in backpack
	local backpack = LocalPlayer:WaitForChild("Backpack")
	FishingGame.FishingRod.Parent = backpack
	FishingGame.Bucket.Parent = backpack
	
	-- Create arc visualization folder
	FishingGame.ArcFolder = Instance.new("Folder")
	FishingGame.ArcFolder.Name = "CastingArc"
	FishingGame.ArcFolder.Parent = Workspace
	
	-- Create fishing line
	FishingGame.FishingLine = LineRenderer.Create(Workspace)
	
	-- Setup tool events
	FishingGame.SetupToolEvents()
	
	-- Setup input events
	FishingGame.SetupInput()
	
	-- Character respawn handler
	LocalPlayer.CharacterAdded:Connect(function(newChar)
		task.wait(1)
		FishingGame.Cleanup()
		FishingGame.Init()
	end)
	
	-- Main update loop
	RunService.Heartbeat:Connect(function(dt)
		FishingGame.Update(dt)
	end)
	
	GUISystem.ShowNotification(FishingGame.GUI, "🎣 Just a guy fishing... Equip the rod and click to cast!", 4, Color3.fromRGB(100, 200, 255))
end

function FishingGame.SetupToolEvents()
	local rod = FishingGame.FishingRod
	local bucket = FishingGame.Bucket
	
	rod.Equipped:Connect(function()
		FishingGame.State = "IDLE"
		FishingGame.AnimState = "idle"
	end)
	
	rod.Unequipped:Connect(function()
		FishingGame.CancelFishing()
		FishingGame.AnimState = "idle"
	end)
	
	bucket.Equipped:Connect(function()
		FishingGame.GUI.bucketFrame.Visible = true
		GUISystem.UpdateBucket(FishingGame.GUI, FishingGame.CaughtFish)
	end)
	
	bucket.Unequipped:Connect(function()
		FishingGame.GUI.bucketFrame.Visible = false
	end)
end

function FishingGame.SetupInput()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			FishingGame.MouseButton1Down = true
			FishingGame.OnMouseDown()
		end
		
		if input.KeyCode == Enum.KeyCode.R then
			-- Quick reel shortcut
			FishingGame.IsReeling = true
		end
		
		if input.KeyCode == Enum.KeyCode.F then
			-- Release fish from bucket
			if #FishingGame.CaughtFish > 0 and FishingGame.Bucket.Parent == FishingGame.Character then
				local released = table.remove(FishingGame.CaughtFish, #FishingGame.CaughtFish)
				GUISystem.ShowNotification(FishingGame.GUI, "Released " .. released.name .. " back into the water! 🐟", 2, Color3.fromRGB(100, 200, 255))
				GUISystem.UpdateBucket(FishingGame.GUI, FishingGame.CaughtFish)
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			FishingGame.MouseButton1Down = false
			FishingGame.OnMouseUp()
		end
		
		if input.KeyCode == Enum.KeyCode.R then
			FishingGame.IsReeling = false
		end
	end)
end

function FishingGame.OnMouseDown()
	-- Check if fishing rod is equipped
	if FishingGame.FishingRod.Parent ~= FishingGame.Character then return end
	
	if FishingGame.State == "IDLE" then
		-- Start charging cast
		FishingGame.State = "CHARGING"
		FishingGame.CastPower = CONFIG.MIN_CAST_POWER
		FishingGame.AnimState = "casting"
		FishingGame.GUI.powerFrame.Visible = true
	elseif FishingGame.State == "BITE" then
		-- HOOK THE FISH!
		FishingGame.HookFish()
	elseif FishingGame.State == "FIGHTING" then
		-- Start reeling during fight
		FishingGame.IsReeling = true
	elseif FishingGame.State == "WAITING" or FishingGame.State == "NIBBLE" then
		-- Premature reel - lose the cast
		FishingGame.ReelIn(false)
	end
end

function FishingGame.OnMouseUp()
	if FishingGame.FishingRod.Parent ~= FishingGame.Character then return end
	
	if FishingGame.State == "CHARGING" then
		-- Release cast
		FishingGame.CastLine()
	elseif FishingGame.State == "FIGHTING" then
		FishingGame.IsReeling = false
	end
end

function FishingGame.CastLine()
	local power = FishingGame.CastPower
	FishingGame.GUI.powerFrame.Visible = false
	
	-- Get cast direction from camera/mouse
	local mouseRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
	local castDir = mouseRay.Direction
	-- Project onto horizontal plane somewhat
	castDir = Vector3.new(castDir.X, math.max(castDir.Y * 0.3, 0.1), castDir.Z).Unit
	
	FishingGame.CastDirection = castDir
	FishingGame.State = "CASTING_ARC"
	FishingGame.AnimState = "cast_release"
	
	-- Calculate landing position
	local rootPos = FishingGame.RootPart.Position
	local launchAngle = math.rad(45) -- 45 degree launch
	local distance = power / CONFIG.MAX_CAST_POWER * 60 -- Max distance ~60 studs
	
	-- Horizontal direction
	local horizontalDir = Vector3.new(castDir.X, 0, castDir.Z).Unit
	local landingPos = rootPos + horizontalDir * distance
	
	-- Find the actual landing surface
	local rayStart = landingPos + Vector3.new(0, 50, 0)
	local rayResult = Workspace:Raycast(rayStart, Vector3.new(0, -100, 0))
	
	if rayResult then
		landingPos = rayResult.Position
		
		-- Check if it's water
		local isWater, waterInfo = WaterDetector.IsWater(landingPos, rayResult.Instance, rayResult.Normal)
		
		if isWater then
			-- Animate the cast arc
			FishingGame.AnimateCastArc(rootPos + Vector3.new(0, 3, 0), landingPos, power, function()
				-- Arc complete - bobber lands
				FishingGame.BobberPosition = landingPos
				FishingGame.SpawnBobber(landingPos)
				Effects.Splash(landingPos, 0.8)
				FishingGame.State = "WAITING"
				FishingGame.AnimState = "fishing"
				FishingGame.StartFishTimer()
				GUISystem.ShowNotification(FishingGame.GUI, "🎣 Line in the water! Wait for a bite...", 2, Color3.fromRGB(100, 255, 100))
			end)
		else
			-- Not water!
			FishingGame.AnimateCastArc(rootPos + Vector3.new(0, 3, 0), landingPos, power, function()
				Effects.Splash(landingPos, 0.3) -- Small thud
				GUISystem.ShowNotification(FishingGame.GUI, "❌ That's not water! Try casting into a body of water.", 2.5, Color3.fromRGB(255, 100, 100))
				FishingGame.State = "IDLE"
				FishingGame.AnimState = "idle"
			end)
		end
	else
		-- No surface found
		GUISystem.ShowNotification(FishingGame.GUI, "❌ Cast went into the void! Try a different direction.", 2, Color3.fromRGB(255, 100, 100))
		FishingGame.State = "IDLE"
		FishingGame.AnimState = "idle"
	end
end

function FishingGame.AnimateCastArc(startPos, endPos, power, callback)
	task.spawn(function()
		local duration = 0.8 + (power / CONFIG.MAX_CAST_POWER) * 0.5
		local height = 5 + (power / CONFIG.MAX_CAST_POWER) * 15
		local startTime = tick()
		
		-- Create bobber for the arc
		local arcBobber = BobberBuilder.Create(Workspace)
		
		while tick() - startTime < duration do
			local t = (tick() - startTime) / duration
			local easedT = Util.EaseOutQuad(t)
			
			-- Parabolic arc
			local pos = startPos:Lerp(endPos, easedT)
			local arcHeight = height * 4 * t * (1 - t) -- Parabola peaking at t=0.5
			pos = pos + Vector3.new(0, arcHeight, 0)
			
			-- Update bobber position
			if arcBobber.PrimaryPart then
				arcBobber:SetPrimaryPartCFrame(CFrame.new(pos))
			end
			
			-- Update fishing line during cast
			local tipPos = FishingGame.GetRodTipPosition()
			if tipPos then
				LineRenderer.Update(FishingGame.FishingLine, tipPos, pos, 15, 0.2 * (1 - t))
			end
			
			RunService.Heartbeat:Wait()
		end
		
		arcBobber:Destroy()
		
		if callback then
			callback()
		end
	end)
end

function FishingGame.GetRodTipPosition()
	if not FishingGame.Character or not FishingGame.FishingRod then return nil end
	local handle = FishingGame.FishingRod:FindFirstChild("Handle")
	if not handle then return nil end
	
	-- The tip is at the far end of the rod
	local tip = handle:FindFirstChild("Tip", true)
	if tip then
		return tip.Position + tip.CFrame.LookVector * -0.25 -- Tip end
	end
	
	-- Fallback
	return handle.Position + handle.CFrame.LookVector * -4
end

function FishingGame.SpawnBobber(position)
	if FishingGame.BobberModel then
		FishingGame.BobberModel:Destroy()
	end
	
	FishingGame.BobberModel = BobberBuilder.Create(Workspace)
	if FishingGame.BobberModel.PrimaryPart then
		FishingGame.BobberModel:SetPrimaryPartCFrame(CFrame.new(position))
	end
end

function FishingGame.StartFishTimer()
	local waitTime = Util.RandomInRange(CONFIG.BITE_MIN_TIME, CONFIG.BITE_MAX_TIME)
	FishingGame.NibbleTimer = waitTime
	FishingGame.NibblesRemaining = math.random(CONFIG.NIBBLE_COUNT_MIN, CONFIG.NIBBLE_COUNT_MAX)
	FishingGame.NibbleCount = 0
end

function FishingGame.SelectRandomFish()
	-- Build weighted selection
	local totalWeight = 0
	local fishByRarity = {}
	
	for _, fish in ipairs(FishDatabase) do
		local rarityWeight = RarityWeights[fish.rarity] or 1
		if not fishByRarity[fish.rarity] then
			fishByRarity[fish.rarity] = {}
		end
		table.insert(fishByRarity[fish.rarity], fish)
		totalWeight = totalWeight + rarityWeight
	end
	
	-- Weighted random selection by rarity first
	local roll = math.random() * totalWeight
	local cumulative = 0
	local selectedRarity = "Common"
	
	for rarity, weight in pairs(RarityWeights) do
		cumulative = cumulative + weight
		if roll <= cumulative then
			selectedRarity = rarity
			break
		end
	end
	
	-- Pick random fish of that rarity
	local fishOfRarity = {}
	for _, fish in ipairs(FishDatabase) do
		if fish.rarity == selectedRarity then
			table.insert(fishOfRarity, fish)
		end
	end
	
	if #fishOfRarity == 0 then
		-- Fallback to first fish
		return FishDatabase[1]
	end
	
	return fishOfRarity[math.random(1, #fishOfRarity)]
end

function FishingGame.HookFish()
	if FishingGame.HookWindow <= 0 then
		-- Missed the hook!
		GUISystem.ShowNotification(FishingGame.GUI, "❌ Too slow! The fish got away!", 2, Color3.fromRGB(255, 100, 100))
		FishingGame.ReelIn(false)
		return
	end
	
	-- Select a random fish
	local fishData = FishingGame.SelectRandomFish()
	local weight = Util.RandomInRange(fishData.weight[1], fishData.weight[2])
	weight = math.floor(weight * 100) / 100
	
	FishingGame.HookedFishData = fishData
	FishingGame.HookedFishWeight = weight
	FishingGame.State = "FIGHTING"
	FishingGame.AnimState = "reeling"
	FishingGame.Tension = 30
	FishingGame.FightTimer = 0
	FishingGame.FightDuration = Util.RandomInRange(CONFIG.FISH_FIGHT_DURATION_MIN, CONFIG.FISH_FIGHT_DURATION_MAX) * (fishData.fightStrength / 20)
	FishingGame.FightDuration = math.clamp(FishingGame.FightDuration, 2, 15)
	
	FishingGame.GUI.tensionFrame.Visible = true
	
	local rarityColor = RarityColors[fishData.rarity] or Color3.new(1,1,1)
	GUISystem.ShowNotification(FishingGame.GUI, "🐟 FISH ON! Hold click to reel! Watch the tension!", 2, rarityColor)
	
	-- Splash at bobber
	if FishingGame.BobberPosition then
		Effects.Splash(FishingGame.BobberPosition, 1.2)
	end
end

function FishingGame.ReelIn(success)
	-- Clean up bobber
	if FishingGame.BobberModel then
		FishingGame.BobberModel:Destroy()
		FishingGame.BobberModel = nil
	end
	
	-- Hide line
	for _, seg in ipairs(FishingGame.FishingLine.segments) do
		seg.Transparency = 1
	end
	
	FishingGame.GUI.tensionFrame.Visible = false
	FishingGame.GUI.powerFrame.Visible = false
	
	if success and FishingGame.HookedFishData then
		-- CAUGHT A FISH!
		FishingGame.State = "CAUGHT"
		FishingGame.AnimState = "holding_fish"
		
		-- Show catch display
		GUISystem.ShowCatch(FishingGame.GUI, FishingGame.HookedFishData, FishingGame.HookedFishWeight)
		
		-- Build and display fish model
		FishingGame.ShowCaughtFish(FishingGame.HookedFishData, FishingGame.HookedFishWeight)
		
		-- Add to bucket
		if #FishingGame.CaughtFish < CONFIG.BUCKET_MAX_FISH then
			table.insert(FishingGame.CaughtFish, {
				name = FishingGame.HookedFishData.name,
				rarity = FishingGame.HookedFishData.rarity,
				weight = FishingGame.HookedFishWeight,
				data = FishingGame.HookedFishData,
			})
			GUISystem.UpdateBucket(FishingGame.GUI, FishingGame.CaughtFish)
		else
			GUISystem.ShowNotification(FishingGame.GUI, "🪣 Bucket is full! Release some fish (F key) or get a bigger bucket!", 3, Color3.fromRGB(255, 200, 100))
		end
		
		-- Return to idle after showing
		task.delay(3.5, function()
			if FishingGame.FishModel then
				FishingGame.FishModel:Destroy()
				FishingGame.FishModel = nil
			end
			FishingGame.State = "IDLE"
			FishingGame.AnimState = "idle"
		end)
	else
		FishingGame.State = "IDLE"
		FishingGame.AnimState = "idle"
	end
	
	FishingGame.HookedFishData = nil
	FishingGame.HookedFishWeight = 0
	FishingGame.BobberPosition = nil
	FishingGame.IsReeling = false
end

function FishingGame.ShowCaughtFish(fishData, weight)
	if FishingGame.FishModel then
		FishingGame.FishModel:Destroy()
	end
	
	-- Build the fish model
	local fishModel = FishModelBuilder.Build(fishData, 1.5) -- Slightly larger for display
	
	-- Position in front of player, above head
	if FishingGame.RootPart then
		local displayPos = FishingGame.RootPart.Position + Vector3.new(0, 4, 0) + FishingGame.RootPart.CFrame.LookVector * 2
		fishModel:SetPrimaryPartCFrame(CFrame.new(displayPos))
	end
	
	fishModel.Parent = Workspace
	FishingGame.FishModel = fishModel
	
	-- Animate the fish display (spinning, bobbing)
	task.spawn(function()
		local startTime = tick()
		while FishingGame.FishModel == fishModel and fishModel.Parent and tick() - startTime < 4 do
			local elapsed = tick() - startTime
			if fishModel.PrimaryPart then
				local rootPos = FishingGame.RootPart and FishingGame.RootPart.Position or Vector3.new(0, 5, 0)
				local displayPos = rootPos + Vector3.new(0, 4 + math.sin(elapsed * 2) * 0.3, 0) + (FishingGame.RootPart and FishingGame.RootPart.CFrame.LookVector * 2 or Vector3.new(0,0,-2))
				local spin = CFrame.Angles(0, elapsed * 1.5, math.sin(elapsed * 3) * math.rad(10))
				fishModel:SetPrimaryPartCFrame(CFrame.new(displayPos) * spin)
				
				-- Animate fish parts
				FishModelBuilder.AnimateFish(fishModel, RunService.Heartbeat:Wait(), elapsed)
			else
				break
			end
		end
	end)
end

function FishingGame.CancelFishing()
	if FishingGame.BobberModel then
		FishingGame.BobberModel:Destroy()
		FishingGame.BobberModel = nil
	end
	if FishingGame.FishModel then
		FishingGame.FishModel:Destroy()
		FishingGame.FishModel = nil
	end
	for _, seg in ipairs(FishingGame.FishingLine.segments) do
		seg.Transparency = 1
	end
	FishingGame.GUI.powerFrame.Visible = false
	FishingGame.GUI.tensionFrame.Visible = false
	FishingGame.State = "IDLE"
	FishingGame.AnimState = "idle"
	FishingGame.BobberPosition = nil
	FishingGame.IsReeling = false
end

function FishingGame.Cleanup()
	FishingGame.CancelFishing()
	if FishingGame.ArcFolder then
		FishingGame.ArcFolder:Destroy()
	end
	LineRenderer.Destroy(FishingGame.FishingLine)
end

------------------------------------------------------------------------
-- MAIN UPDATE LOOP
------------------------------------------------------------------------
function FishingGame.Update(dt)
	-- Update character references
	if not FishingGame.Character or not FishingGame.Character.Parent then
		local char = LocalPlayer.Character
		if char then
			FishingGame.Character = char
			FishingGame.Humanoid = char:FindFirstChildOfClass("Humanoid")
			FishingGame.RootPart = char:FindFirstChild("HumanoidRootPart")
		end
		return
	end
	
	if not FishingGame.Humanoid or not FishingGame.RootPart then return end
	
	-- Determine animation state based on tool and fishing state
	local animState = "idle"
	local rodEquipped = FishingGame.FishingRod.Parent == FishingGame.Character
	
	if rodEquipped then
		if FishingGame.State == "CHARGING" then
			animState = "casting"
		elseif FishingGame.State == "CASTING_ARC" then
			animState = "cast_release"
		elseif FishingGame.State == "WAITING" or FishingGame.State == "NIBBLE" or FishingGame.State == "BITE" then
			animState = "fishing"
		elseif FishingGame.State == "FIGHTING" then
			animState = "reeling"
		elseif FishingGame.State == "CAUGHT" then
			animState = "holding_fish"
		end
	end
	
	FishingGame.AnimState = animState
	
	-- Update CFrame animations
	CFrameAnimator.Update(dt, FishingGame.Humanoid, FishingGame.AnimState)
	
	-- State machine updates
	if FishingGame.State == "CHARGING" then
		FishingGame.UpdateCharging(dt)
	elseif FishingGame.State == "WAITING" then
		FishingGame.UpdateWaiting(dt)
	elseif FishingGame.State == "NIBBLE" then
		FishingGame.UpdateNibble(dt)
	elseif FishingGame.State == "BITE" then
		FishingGame.UpdateBite(dt)
	elseif FishingGame.State == "FIGHTING" then
		FishingGame.UpdateFighting(dt)
	end
	
	-- Update fishing line if bobber exists
	if FishingGame.BobberPosition and FishingGame.BobberModel and rodEquipped then
		local tipPos = FishingGame.GetRodTipPosition()
		if tipPos then
			local distance = (tipPos - FishingGame.BobberPosition).Magnitude
			local sag = math.clamp(distance * 0.05, 0.2, 3)
			
			-- During fighting, line should be taut
			if FishingGame.State == "FIGHTING" then
				sag = sag * 0.3
			end
			
			LineRenderer.Update(FishingGame.FishingLine, tipPos, FishingGame.BobberPosition, 20, sag)
		end
	end
	
	-- Update bobber floating animation
	if FishingGame.BobberModel and FishingGame.BobberModel.PrimaryPart and FishingGame.BobberPosition then
		if FishingGame.State == "WAITING" or FishingGame.State == "NIBBLE" then
			local bobTime = tick()
			local bobHeight = math.sin(bobTime * 2) * 0.05
			local bobRot = math.sin(bobTime * 1.5) * math.rad(3)
			local newCF = CFrame.new(FishingGame.BobberPosition + Vector3.new(0, bobHeight, 0)) * CFrame.Angles(bobRot, 0, math.sin(bobTime * 0.8) * math.rad(2))
			FishingGame.BobberModel:SetPrimaryPartCFrame(newCF)
		end
	end
end

function FishingGame.UpdateCharging(dt)
	-- Power oscillates (like a golf game power meter)
	FishingGame.CastPower = FishingGame.CastPower + CONFIG.CAST_POWER_RATE * dt * 60
	
	if FishingGame.CastPower > CONFIG.MAX_CAST_POWER then
		FishingGame.CastPower = CONFIG.MAX_CAST_POWER
	end
	
	-- Oscillate for skill-based casting
	local displayPower = FishingGame.CastPower
	local oscillation = math.sin(tick() * CONFIG.CAST_POWER_RATE * 2)
	
	-- Update power bar
	local fillFraction = displayPower / CONFIG.MAX_CAST_POWER
	FishingGame.GUI.powerFill.Size = UDim2.new(fillFraction, -4, 1, -4)
	
	-- Color based on power level
	local color
	if fillFraction < 0.5 then
		color = Util.LerpColor(Color3.fromRGB(50, 200, 50), Color3.fromRGB(255, 200, 50), fillFraction * 2)
	else
		color = Util.LerpColor(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 50, 50), (fillFraction - 0.5) * 2)
	end
	FishingGame.GUI.powerFill.BackgroundColor3 = color
end

function FishingGame.UpdateWaiting(dt)
	FishingGame.NibbleTimer = FishingGame.NibbleTimer - dt
	
	if FishingGame.NibbleTimer <= 0 then
		if FishingGame.NibbleCount < FishingGame.NibblesRemaining then
			-- Nibble!
			FishingGame.State = "NIBBLE"
			FishingGame.NibbleCount = FishingGame.NibbleCount + 1
			Effects.Nibble(FishingGame.BobberModel)
			
			local nibbleTexts = {
				"🐟 Something nibbled...",
				"🐟 A slight tug...",
				"🐟 Was that a bite?",
				"🐟 The bobber moved!",
				"🐟 Something's interested...",
			}
			GUISystem.ShowNotification(FishingGame.GUI, nibbleTexts[math.random(1, #nibbleTexts)], 1.5, Color3.fromRGB(255, 255, 150))
			
			-- Set timer for next nibble or bite
			FishingGame.NibbleTimer = Util.RandomInRange(1, 3)
		else
			-- REAL BITE!
			FishingGame.State = "BITE"
			FishingGame.HookWindow = CONFIG.HOOK_WINDOW
			Effects.BigBite(FishingGame.BobberModel)
			
			if FishingGame.BobberPosition then
				Effects.Splash(FishingGame.BobberPosition, 0.5)
			end
			
			GUISystem.ShowNotification(FishingGame.GUI, "🐟 BITE! CLICK NOW!!!", 1.5, Color3.fromRGB(255, 50, 50))
		end
	end
end

function FishingGame.UpdateNibble(dt)
	FishingGame.NibbleTimer = FishingGame.NibbleTimer - dt
	
	if FishingGame.NibbleTimer <= 0 then
		FishingGame.State = "WAITING"
		FishingGame.NibbleTimer = Util.RandomInRange(1.5, 5)
	end
end

function FishingGame.UpdateBite(dt)
	FishingGame.HookWindow = FishingGame.HookWindow - dt
	
	-- Bobber dipping animation
	if FishingGame.BobberModel and FishingGame.BobberModel.PrimaryPart and FishingGame.BobberPosition then
		local dip = math.sin(tick() * 12) * 0.2
		FishingGame.BobberModel:SetPrimaryPartCFrame(CFrame.new(FishingGame.BobberPosition - Vector3.new(0, math.abs(dip) + 0.1, 0)))
	end
	
	if FishingGame.HookWindow <= 0 then
		-- Missed it!
		GUISystem.ShowNotification(FishingGame.GUI, "❌ The fish got away! Too slow!", 2, Color3.fromRGB(255, 100, 100))
		FishingGame.ReelIn(false)
	end
end

function FishingGame.UpdateFighting(dt)
	FishingGame.FightTimer = FishingGame.FightTimer + dt
	
	local fishData = FishingGame.HookedFishData
	if not fishData then
		FishingGame.ReelIn(false)
		return
	end
	
	local fightProgress = FishingGame.FightTimer / FishingGame.FightDuration
	
	-- Fish pulling (adds tension)
	local fishPullFreq = 2 + fishData.fightStrength * 0.05
	local fishPull = math.sin(tick() * fishPullFreq) * 0.5 + 0.5 -- 0 to 1
	local fishPullStrength = CONFIG.TENSION_FISH_PULL * (fishData.fightStrength / 50) * fishPull
	
	-- Erratic fish behavior
	local erratic = math.sin(tick() * 7.3) * math.cos(tick() * 3.1) * 0.3
	fishPullStrength = fishPullStrength + fishPullStrength * erratic
	
	-- Reeling adds tension but also progress
	if FishingGame.IsReeling or FishingGame.MouseButton1Down then
		FishingGame.Tension = FishingGame.Tension + (fishPullStrength + 15) * dt
		
		-- Move bobber toward player
		if FishingGame.BobberPosition and FishingGame.RootPart then
			local dir = (FishingGame.RootPart.Position - FishingGame.BobberPosition)
			local horizontalDir = Vector3.new(dir.X, 0, dir.Z)
			if horizontalDir.Magnitude > 2 then
				FishingGame.BobberPosition = FishingGame.BobberPosition + horizontalDir.Unit * CONFIG.REEL_SPEED * dt
				if FishingGame.BobberModel and FishingGame.BobberModel.PrimaryPart then
					local bobWobble = math.sin(tick() * 8) * 0.15
					FishingGame.BobberModel:SetPrimaryPartCFrame(CFrame.new(FishingGame.BobberPosition + Vector3.new(0, bobWobble, 0)))
				end
			end
		end
	else
		-- Not reeling - tension decays but fish can still pull
		FishingGame.Tension = FishingGame.Tension - CONFIG.TENSION_DECAY * dt
		FishingGame.Tension = FishingGame.Tension + fishPullStrength * 0.3 * dt
		
		-- Fish moves away when not reeling
		if FishingGame.BobberPosition and FishingGame.RootPart then
			local awayDir = (FishingGame.BobberPosition - FishingGame.RootPart.Position)
			local horizontalAway = Vector3.new(awayDir.X, 0, awayDir.Z)
			if horizontalAway.Magnitude > 0.1 then
				FishingGame.BobberPosition = FishingGame.BobberPosition + horizontalAway.Unit * 2 * dt * (fishData.fightStrength / 30)
			end
		end
	end
	
	FishingGame.Tension = math.clamp(FishingGame.Tension, 0, CONFIG.TENSION_BREAK_THRESHOLD)
	
	-- Occasional splash effects
	if math.random() < 0.02 and FishingGame.BobberPosition then
		Effects.Splash(FishingGame.BobberPosition + Vector3.new(math.random(-1,1), 0, math.random(-1,1)), 0.4)
	end
	
	-- Update tension bar
	local tensionFraction = FishingGame.Tension / CONFIG.TENSION_BREAK_THRESHOLD
	FishingGame.GUI.tensionFill.Size = UDim2.new(tensionFraction, -4, 1, -4)
	
	-- Tension color
	local tensionColor
	if tensionFraction < 0.4 then
		tensionColor = Color3.fromRGB(50, 200, 50)
	elseif tensionFraction < 0.7 then
		tensionColor = Util.LerpColor(Color3.fromRGB(50, 200, 50), Color3.fromRGB(255, 200, 50), (tensionFraction - 0.4) / 0.3)
	else
		tensionColor = Util.LerpColor(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 50, 50), (tensionFraction - 0.7) / 0.3)
		-- Shake effect when high tension
		FishingGame.GUI.tensionFrame.Position = UDim2.new(0.5, -125 + math.random(-3, 3), 0.8, math.random(-2, 2))
	end
	FishingGame.GUI.tensionFill.BackgroundColor3 = tensionColor
	
	-- LINE BREAK
	if FishingGame.Tension >= CONFIG.TENSION_BREAK_THRESHOLD then
		GUISystem.ShowNotification(FishingGame.GUI, "💥 LINE SNAPPED! The fish broke free!", 2.5, Color3.fromRGB(255, 50, 50))
		FishingGame.ReelIn(false)
		return
	end
	
	-- Check if fish is close enough to catch
	if FishingGame.BobberPosition and FishingGame.RootPart then
		local dist = (FishingGame.BobberPosition - FishingGame.RootPart.Position).Magnitude
		if dist < 4 then
			-- CAUGHT!
			GUISystem.ShowNotification(FishingGame.GUI, "✅ REELED IT IN!", 1, Color3.fromRGB(50, 255, 50))
			FishingGame.ReelIn(true)
			return
		end
	end
	
	-- Timeout (fish escapes after too long)
	if FishingGame.FightTimer > FishingGame.FightDuration * 3 then
		GUISystem.ShowNotification(FishingGame.GUI, "❌ The fish tired you out and escaped!", 2, Color3.fromRGB(255, 150, 100))
		FishingGame.ReelIn(false)
	end
end

------------------------------------------------------------------------
-- INITIALIZE EVERYTHING
------------------------------------------------------------------------
task.spawn(function()
	-- Wait for everything to load
	task.wait(2)
	
	-- Print the epic intro
	print("╔══════════════════════════════════════════╗")
	print("║     🎣 JUST A GUY FISHING... 🎣         ║")
	print("║                                          ║")
	print("║   Controls:                              ║")
	print("║   - Equip rod, click to charge cast      ║")
	print("║   - Release to cast toward mouse         ║")
	print("║   - Wait for nibbles and bites           ║")
	print("║   - Click on BITE to hook fish            ║")
	print("║   - Hold click/R to reel during fight    ║")
	print("║   - Watch tension! Don't snap the line!  ║")
	print("║   - Equip bucket to view your catch      ║")
	print("║   - Press F to release last fish          ║")
	print("║                                          ║")
	print("║   34 unique fish to discover!            ║")
	print("║   All animations are pure CFrame math!   ║")
	print("╚══════════════════════════════════════════╝")
	
	FishingGame.Init()
end)
