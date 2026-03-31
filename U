--[[
    VENOM MOVESET - StarterPlayerScript
    The Strongest Battlegrounds Custom Moveset
    
    Moveset:
    M1 Combo (4 hits) - Symbiote Strikes
    E - Tendril Lash
    R - Symbiote Slam  
    T - Lethal Protector (Counter)
    F - Venom Barrage
    G - Ultimate: "We Are Venom" Transformation + Ult Combo
    
    VFX: Black tendrils, symbiote particles, screen effects
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Animator = Humanoid:WaitForChild("Animator")
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

-- ============================================
-- CONFIGURATION
-- ============================================
local Config = {
    -- Cooldowns
    Cooldowns = {
        M1 = 0.35,
        E = 4,
        R = 6,
        T = 8,
        F = 10,
        G = 60,
    },
    
    -- Damage values
    Damage = {
        M1 = {8, 8, 10, 15},
        E = 25,
        R = 35,
        T = 30,
        F = 50,
        G = 150,
    },
    
    -- Colors
    VenomBlack = Color3.fromRGB(15, 15, 15),
    VenomPurple = Color3.fromRGB(80, 0, 120),
    VenomDarkPurple = Color3.fromRGB(40, 0, 60),
    SymbioteGreen = Color3.fromRGB(0, 180, 80),
    TendrilColor = Color3.fromRGB(20, 20, 25),
    EyeWhite = Color3.fromRGB(255, 255, 255),
    TongueRed = Color3.fromRGB(200, 0, 30),
    
    -- Hit ranges
    M1Range = 8,
    ERange = 25,
    RRange = 15,
    FRange = 12,
    GRange = 40,
    
    -- Ultimate duration
    UltDuration = 15,
    UltTransitionTime = 3,
}

-- ============================================
-- STATE MANAGEMENT
-- ============================================
local State = {
    M1Count = 0,
    M1LastTime = 0,
    IsAttacking = false,
    IsBlocking = false,
    IsInUlt = false,
    UltActive = false,
    Cooldowns = {},
    Stunned = false,
    ComboTimer = nil,
}

-- Initialize cooldowns
for key, _ in pairs(Config.Cooldowns) do
    State.Cooldowns[key] = 0
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local Util = {}

function Util.IsOnCooldown(key)
    return tick() - (State.Cooldowns[key] or 0) < Config.Cooldowns[key]
end

function Util.SetCooldown(key)
    State.Cooldowns[key] = tick()
end

function Util.CanAttack()
    return not State.IsAttacking and not State.Stunned and Humanoid.Health > 0
end

function Util.GetNearestEnemy(range)
    local nearest = nil
    local nearestDist = range
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
            if otherHRP and otherHum and otherHum.Health > 0 then
                local dist = (HumanoidRootPart.Position - otherHRP.Position).Magnitude
                if dist < nearestDist then
                    nearest = otherPlayer.Character
                    nearestDist = dist
                end
            end
        end
    end
    
    return nearest, nearestDist
end

function Util.GetEnemiesInRange(range)
    local enemies = {}
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
            if otherHRP and otherHum and otherHum.Health > 0 then
                local dist = (HumanoidRootPart.Position - otherHRP.Position).Magnitude
                if dist < range then
                    table.insert(enemies, {Character = otherPlayer.Character, Distance = dist})
                end
            end
        end
    end
    return enemies
end

function Util.FaceTarget(targetPos)
    local lookVector = (targetPos - HumanoidRootPart.Position) * Vector3.new(1, 0, 1)
    if lookVector.Magnitude > 0 then
        HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + lookVector.Unit)
    end
end

-- ============================================
-- VFX MODULE
-- ============================================
local VFX = {}

function VFX.CreateSymbioteParticle(parent, duration)
    local attachment = Instance.new("Attachment")
    attachment.Parent = parent
    
    local particles = Instance.new("ParticleEmitter")
    particles.Parent = attachment
    particles.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Config.VenomBlack),
        ColorSequenceKeypoint.new(0.5, Config.VenomPurple),
        ColorSequenceKeypoint.new(1, Config.VenomDarkPurple),
    }
    particles.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 1.5),
        NumberSequenceKeypoint.new(1, 0),
    }
    particles.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.7, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    }
    particles.Lifetime = NumberRange.new(0.3, 0.8)
    particles.Rate = 80
    particles.Speed = NumberRange.new(2, 6)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.RotSpeed = NumberRange.new(-180, 180)
    particles.Texture = "rbxassetid://6049995673" -- smoke texture
    
    Debris:AddItem(attachment, duration or 2)
    
    task.delay(duration and duration - 0.5 or 1.5, function()
        particles.Enabled = false
    end)
    
    return attachment
end

function VFX.CreateTendril(startPos, endPos, duration)
    local distance = (endPos - startPos).Magnitude
    local midPoint = (startPos + endPos) / 2
    
    local tendril = Instance.new("Part")
    tendril.Name = "VenomTendril"
    tendril.Anchored = true
    tendril.CanCollide = false
    tendril.Material = Enum.Material.SmoothPlastic
    tendril.Color = Config.TendrilColor
    tendril.Size = Vector3.new(0.5, 0.5, distance)
    tendril.CFrame = CFrame.lookAt(midPoint, endPos)
    tendril.Parent = workspace
    
    -- Add glow
    local highlight = Instance.new("SurfaceLight")
    highlight.Color = Config.VenomPurple
    highlight.Brightness = 2
    highlight.Range = 8
    highlight.Parent = tendril
    
    -- Animate tendril
    local tween = TweenService:Create(tendril, TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0, 0, 0),
        Transparency = 1
    })
    
    task.delay((duration or 0.5) * 0.3, function()
        tween:Play()
    end)
    
    Debris:AddItem(tendril, duration or 0.5)
    return tendril
end

function VFX.CreateMultipleTendrils(origin, targetPos, count, spread)
    count = count or 5
    spread = spread or 30
    
    for i = 1, count do
        local randomOffset = Vector3.new(
            math.random(-spread, spread) / 10,
            math.random(-spread, spread) / 10,
            math.random(-spread, spread) / 10
        )
        local endPoint = targetPos + randomOffset
        
        task.delay(i * 0.05, function()
            VFX.CreateTendril(origin, endPoint, 0.6)
        end)
    end
end

function VFX.CreateHitEffect(position)
    -- Impact sphere
    local sphere = Instance.new("Part")
    sphere.Name = "VenomHitEffect"
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Shape = Enum.PartType.Ball
    sphere.Material = Enum.Material.Neon
    sphere.Color = Config.VenomPurple
    sphere.Size = Vector3.new(1, 1, 1)
    sphere.Position = position
    sphere.Transparency = 0.3
    sphere.Parent = workspace
    
    TweenService:Create(sphere, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(6, 6, 6),
        Transparency = 1
    }):Play()
    
    Debris:AddItem(sphere, 0.4)
    
    -- Symbiote splash particles
    VFX.CreateSymbioteParticle(sphere, 0.5)
    
    -- Dark ring
    local ring = Instance.new("Part")
    ring.Name = "HitRing"
    ring.Anchored = true
    ring.CanCollide = false
    ring.Material = Enum.Material.Neon
    ring.Color = Config.VenomBlack
    ring.Size = Vector3.new(2, 0.1, 2)
    ring.Position = position
    ring.Transparency = 0.5
    ring.Shape = Enum.PartType.Cylinder
    ring.Parent = workspace
    
    TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(10, 0.1, 10),
        Transparency = 1
    }):Play()
    
    Debris:AddItem(ring, 0.5)
end

function VFX.CreateSlamEffect(position)
    -- Ground crack effect
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        local crackPart = Instance.new("Part")
        crackPart.Name = "SlamCrack"
        crackPart.Anchored = true
        crackPart.CanCollide = false
        crackPart.Material = Enum.Material.SmoothPlastic
        crackPart.Color = Config.VenomBlack
        crackPart.Size = Vector3.new(0.5, 0.3, 3)
        crackPart.Position = position + Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
        crackPart.CFrame = CFrame.lookAt(crackPart.Position, position) * CFrame.Angles(0, 0, math.rad(math.random(-15, 15)))
        crackPart.Parent = workspace
        
        TweenService:Create(crackPart, TweenInfo.new(0.5, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.8, 0.3, 8),
            Position = crackPart.Position + (crackPart.Position - position).Unit * 5
        }):Play()
        
        task.delay(1.5, function()
            TweenService:Create(crackPart, TweenInfo.new(0.5), {Transparency = 1}):Play()
        end)
        
        Debris:AddItem(crackPart, 2.5)
    end
    
    -- Shockwave ring
    local shockwave = Instance.new("Part")
    shockwave.Name = "Shockwave"
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Material = Enum.Material.Neon
    shockwave.Color = Config.VenomPurple
    shockwave.Size = Vector3.new(2, 1, 2)
    shockwave.Position = position
    shockwave.Transparency = 0.4
    shockwave.Parent = workspace
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://3270017" -- ring mesh
    mesh.Scale = Vector3.new(1, 1, 1)
    mesh.Parent = shockwave
    
    TweenService:Create(mesh, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Scale = Vector3.new(30, 30, 30)
    }):Play()
    
    TweenService:Create(shockwave, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1
    }):Play()
    
    Debris:AddItem(shockwave, 0.7)
    
    -- Debris particles
    for i = 1, 8 do
        local debris = Instance.new("Part")
        debris.Name = "SlamDebris"
        debris.Anchored = false
        debris.CanCollide = true
        debris.Material = Enum.Material.Slate
        debris.Color = Color3.fromRGB(80, 80, 80)
        debris.Size = Vector3.new(
            math.random(5, 15) / 10,
            math.random(5, 15) / 10,
            math.random(5, 15) / 10
        )
        debris.Position = position + Vector3.new(math.random(-3, 3), 1, math.random(-3, 3))
        debris.Parent = workspace
        
        debris:ApplyImpulse(Vector3.new(
            math.random(-50, 50),
            math.random(80, 150),
            math.random(-50, 50)
        ))
        
        task.delay(2, function()
            TweenService:Create(debris, TweenInfo.new(0.5), {Transparency = 1}):Play()
        end)
        
        Debris:AddItem(debris, 3)
    end
end

function VFX.CreateBarrageLines(origin, direction, count)
    for i = 1, count do
        task.delay(i * 0.04, function()
            local offset = Vector3.new(
                math.random(-20, 20) / 10,
                math.random(-20, 20) / 10,
                0
            )
            
            local line = Instance.new("Part")
            line.Name = "BarrageLine"
            line.Anchored = true
            line.CanCollide = false
            line.Material = Enum.Material.Neon
            line.Color = i % 3 == 0 and Config.VenomPurple or Config.VenomBlack
            line.Size = Vector3.new(0.15, 0.15, 4)
            line.Transparency = 0.3
            
            local startP = origin + offset
            line.CFrame = CFrame.lookAt(startP, startP + direction) * CFrame.new(0, 0, -2)
            line.Parent = workspace
            
            TweenService:Create(line, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {
                CFrame = line.CFrame * CFrame.new(0, 0, -8),
                Transparency = 1,
                Size = Vector3.new(0.05, 0.05, 8)
            }):Play()
            
            Debris:AddItem(line, 0.2)
        end)
    end
end

function VFX.ScreenShake(intensity, duration)
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > duration then
            connection:Disconnect()
            Camera.CFrame = Camera.CFrame -- reset
            return
        end
        
        local decay = 1 - (elapsed / duration)
        local shakeX = math.random(-100, 100) / 100 * intensity * decay
        local shakeY = math.random(-100, 100) / 100 * intensity * decay
        
        Camera.CFrame = Camera.CFrame * CFrame.new(shakeX, shakeY, 0)
    end)
end

function VFX.FlashScreen(color, duration)
    local gui = Instance.new("ScreenGui")
    gui.Name = "VenomFlash"
    gui.IgnoreGuiInset = true
    gui.Parent = Player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = color or Config.VenomBlack
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    TweenService:Create(frame, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()
    
    Debris:AddItem(gui, duration or 0.3)
end

function VFX.CreateSymbioteAura(character, duration)
    local parts = {}
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local aura = Instance.new("ParticleEmitter")
            aura.Name = "SymbioteAura"
            aura.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Config.VenomBlack),
                ColorSequenceKeypoint.new(0.5, Config.VenomDarkPurple),
                ColorSequenceKeypoint.new(1, Config.VenomPurple),
            }
            aura.Size = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.3),
                NumberSequenceKeypoint.new(0.5, 0.8),
                NumberSequenceKeypoint.new(1, 0),
            }
            aura.Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(1, 1),
            }
            aura.Lifetime = NumberRange.new(0.4, 0.8)
            aura.Rate = 30
            aura.Speed = NumberRange.new(1, 3)
            aura.SpreadAngle = Vector2.new(180, 180)
            aura.Texture = "rbxassetid://6049995673"
            aura.Parent = part
            
            table.insert(parts, aura)
        end
    end
    
    if duration then
        task.delay(duration, function()
            for _, aura in ipairs(parts) do
                if aura and aura.Parent then
                    aura.Enabled = false
                    Debris:AddItem(aura, 1)
                end
            end
        end)
    end
    
    return parts
end

function VFX.CreateVenomEyes(head)
    -- Create glowing Venom eyes on character's head
    local leftEye = Instance.new("Part")
    leftEye.Name = "VenomEyeL"
    leftEye.Anchored = false
    leftEye.CanCollide = false
    leftEye.Material = Enum.Material.Neon
    leftEye.Color = Config.EyeWhite
    leftEye.Size = Vector3.new(0.4, 0.25, 0.1)
    leftEye.Parent = head
    
    local weldL = Instance.new("Weld")
    weldL.Part0 = head
    weldL.Part1 = leftEye
    weldL.C0 = CFrame.new(-0.25, 0.1, -0.55) * CFrame.Angles(0, 0, math.rad(20))
    weldL.Parent = leftEye
    
    local rightEye = Instance.new("Part")
    rightEye.Name = "VenomEyeR"
    rightEye.Anchored = false
    rightEye.CanCollide = false
    rightEye.Material = Enum.Material.Neon
    rightEye.Color = Config.EyeWhite
    rightEye.Size = Vector3.new(0.4, 0.25, 0.1)
    rightEye.Parent = head
    
    local weldR = Instance.new("Weld")
    weldR.Part0 = head
    weldR.Part1 = rightEye
    weldR.C0 = CFrame.new(0.25, 0.1, -0.55) * CFrame.Angles(0, 0, math.rad(-20))
    weldR.Parent = rightEye
    
    -- Add glow
    for _, eye in ipairs({leftEye, rightEye}) do
        local light = Instance.new("PointLight")
        light.Color = Config.EyeWhite
        light.Brightness = 3
        light.Range = 4
        light.Parent = eye
    end
    
    return {leftEye, rightEye}
end

-- ============================================
-- SOUND MODULE
-- ============================================
local SFX = {}

function SFX.Play(soundId, parent, volume, pitch)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    sound.Volume = volume or 1
    sound.PlaybackSpeed = pitch or 1
    sound.Parent = parent or HumanoidRootPart
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

-- Sound IDs (using Roblox library sounds)
local SoundIds = {
    Hit = 5528822843,        -- punch hit
    Whoosh = 2785493,        -- whoosh/swing
    Slam = 5528816913,       -- heavy impact
    Tendril = 2785493,       -- stretchy sound
    Symbiote = 9125402735,   -- gooey/symbiote
    Roar = 8139510053,       -- monster roar
    Charge = 9125836059,     -- power charge
    Explosion = 5528816913,  -- explosion
    Counter = 9125402735,    -- block/counter
    UltTheme = 9125836059,   -- dramatic music
}

-- ============================================
-- ANIMATION MODULE
-- ============================================
local Anim = {}

-- Custom animation creation using CFrame manipulation
-- Since we can't upload custom animations, we'll create procedural ones

function Anim.PlayM1(comboCount)
    local tracks = {}
    
    -- Create animation through motor6D manipulation
    local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
    local rightArm = Character:FindFirstChild("RightUpperArm") or Character:FindFirstChild("Right Arm")
    local leftArm = Character:FindFirstChild("LeftUpperArm") or Character:FindFirstChild("Left Arm")
    
    if comboCount == 1 then
        -- Right jab - tendril enhanced
        Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(-90), 0, math.rad(20)), 0.08)
        task.delay(0.08, function()
            Anim.TweenMotor("RightShoulder", CFrame.Angles(0, 0, 0), 0.15)
        end)
    elseif comboCount == 2 then
        -- Left hook
        Anim.TweenMotor("LeftShoulder", CFrame.Angles(math.rad(-80), math.rad(40), 0), 0.08)
        task.delay(0.08, function()
            Anim.TweenMotor("LeftShoulder", CFrame.Angles(0, 0, 0), 0.15)
        end)
    elseif comboCount == 3 then
        -- Uppercut with symbiote arm
        Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(-120), 0, math.rad(-10)), 0.1)
        task.delay(0.1, function()
            Anim.TweenMotor("RightShoulder", CFrame.Angles(0, 0, 0), 0.15)
        end)
    elseif comboCount == 4 then
        -- Double slam - both arms with tendrils
        Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(-150), 0, math.rad(20)), 0.08)
        Anim.TweenMotor("LeftShoulder", CFrame.Angles(math.rad(-150), 0, math.rad(-20)), 0.08)
        task.delay(0.12, function()
            Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(30), 0, 0), 0.1)
            Anim.TweenMotor("LeftShoulder", CFrame.Angles(math.rad(30), 0, 0), 0.1)
        end)
        task.delay(0.3, function()
            Anim.TweenMotor("RightShoulder", CFrame.Angles(0, 0, 0), 0.2)
            Anim.TweenMotor("LeftShoulder", CFrame.Angles(0, 0, 0), 0.2)
        end)
    end
end

function Anim.TweenMotor(motorName, targetC1, duration)
    -- Find motor6D
    for _, desc in ipairs(Character:GetDescendants()) do
        if desc:IsA("Motor6D") and desc.Name == motorName then
            local originalC1 = desc.C1
            local startTime = tick()
            local conn
            conn = RunService.RenderStepped:Connect(function()
                local elapsed = tick() - startTime
                local alpha = math.min(elapsed / duration, 1)
                desc.C1 = originalC1:Lerp(originalC1 * targetC1, alpha)
                if alpha >= 1 then
                    conn:Disconnect()
                end
            end)
            break
        end
    end
end

function Anim.DashForward(distance, duration)
    local direction = HumanoidRootPart.CFrame.LookVector
    local startPos = HumanoidRootPart.Position
    local endPos = startPos + direction * distance
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    bodyVelocity.Velocity = direction * (distance / duration)
    bodyVelocity.Parent = HumanoidRootPart
    
    Debris:AddItem(bodyVelocity, duration)
end

-- ============================================
-- COMBAT MOVES
-- ============================================
local Combat = {}

-- ========================
-- M1 COMBO - Symbiote Strikes
-- ========================
function Combat.M1()
    if not Util.CanAttack() then return end
    if Util.IsOnCooldown("M1") then return end
    
    -- Combo management
    local now = tick()
    if now - State.M1LastTime > 1.5 then
        State.M1Count = 0
    end
    
    State.M1Count = State.M1Count + 1
    if State.M1Count > 4 then
        State.M1Count = 1
    end
    
    State.M1LastTime = now
    State.IsAttacking = true
    Util.SetCooldown("M1")
    
    local comboNum = State.M1Count
    
    -- Face nearest enemy
    local enemy, dist = Util.GetNearestEnemy(Config.M1Range + 5)
    if enemy then
        Util.FaceTarget(enemy:FindFirstChild("HumanoidRootPart").Position)
    end
    
    -- Play animation
    Anim.PlayM1(comboNum)
    
    -- Sound
    SFX.Play(SoundIds.Whoosh, HumanoidRootPart, 0.5, 0.8 + comboNum * 0.1)
    
    -- Dash forward slightly
    Anim.DashForward(3, 0.1)
    
    -- Hitbox check
    task.delay(0.05, function()
        local target, targetDist = Util.GetNearestEnemy(Config.M1Range)
        
        if target then
            local targetHRP = target:FindFirstChild("HumanoidRootPart")
            local targetHum = target:FindFirstChild("Humanoid")
            
            if targetHRP and targetHum then
                -- Apply damage
                local damage = Config.Damage.M1[comboNum]
                if State.UltActive then damage = damage * 1.8 end
                targetHum:TakeDamage(damage)
                
                -- Hit VFX
                VFX.CreateHitEffect(targetHRP.Position)
                SFX.Play(SoundIds.Hit, targetHRP, 0.8, 1 + comboNum * 0.05)
                VFX.ScreenShake(0.3 + comboNum * 0.1, 0.1)
                
                -- Symbiote tendril on hit
                if comboNum >= 3 then
                    VFX.CreateMultipleTendrils(HumanoidRootPart.Position + HumanoidRootPart.CFrame.LookVector * 2, targetHRP.Position, 3, 15)
                end
                
                -- Last hit knockback
                if comboNum == 4 then
                    local knockDir = (targetHRP.Position - HumanoidRootPart.Position).Unit
                    local knockback = Instance.new("BodyVelocity")
                    knockback.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    knockback.Velocity = knockDir * 60 + Vector3.new(0, 30, 0)
                    knockback.Parent = targetHRP
                    Debris:AddItem(knockback, 0.3)
                    
                    VFX.ScreenShake(0.8, 0.2)
                    VFX.FlashScreen(Config.VenomPurple, 0.15)
                    SFX.Play(SoundIds.Slam, targetHRP, 1, 0.8)
                    
                    -- Symbiote splash on final hit
                    VFX.CreateSymbioteParticle(targetHRP, 1)
                    VFX.CreateMultipleTendrils(HumanoidRootPart.Position, targetHRP.Position, 6, 20)
                end
            end
        end
    end)
    
    -- Attack duration
    local attackDuration = comboNum == 4 and 0.4 or 0.25
    task.delay(attackDuration, function()
        State.IsAttacking = false
    end)
end

-- ========================
-- E SKILL - Tendril Lash
-- ========================
function Combat.TendrilLash()
    if not Util.CanAttack() then return end
    if Util.IsOnCooldown("E") then return end
    
    State.IsAttacking = true
    Util.SetCooldown("E")
    
    -- Wind up animation
    Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(-100), math.rad(-30), 0), 0.15)
    SFX.Play(SoundIds.Tendril, HumanoidRootPart, 0.7, 1.2)
    
    -- Symbiote arm stretch effect
    task.delay(0.15, function()
        local direction = HumanoidRootPart.CFrame.LookVector
        local startPos = HumanoidRootPart.Position + direction * 2 + Vector3.new(0, 1, 0)
        
        -- Create extending tendril arm
        local tendrilArm = Instance.new("Part")
        tendrilArm.Name = "TendrilArm"
        tendrilArm.Anchored = true
        tendrilArm.CanCollide = false
        tendrilArm.Material = Enum.Material.SmoothPlastic
        tendrilArm.Color = Config.TendrilColor
        tendrilArm.Size = Vector3.new(0.8, 0.8, 1)
        tendrilArm.CFrame = CFrame.lookAt(startPos, startPos + direction)
        tendrilArm.Parent = workspace
        
        -- Extend the tendril
        TweenService:Create(tendrilArm, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.6, 0.6, Config.ERange),
            CFrame = CFrame.lookAt(startPos + direction * Config.ERange / 2, startPos + direction * Config.ERange)
        }):Play()
        
        -- Add symbiote particles along tendril
        VFX.CreateSymbioteParticle(tendrilArm, 0.8)
        
        -- Purple glow trail
        for i = 1, 5 do
            task.delay(i * 0.03, function()
                local glowPos = startPos + direction * (Config.ERange * i / 5)
                local glow = Instance.new("Part")
                glow.Anchored = true
                glow.CanCollide = false
                glow.Material = Enum.Material.Neon
                glow.Color = Config.VenomPurple
                glow.Size = Vector3.new(1.5, 1.5, 1.5)
                glow.Shape = Enum.PartType.Ball
                glow.Transparency = 0.5
                glow.Position = glowPos
                glow.Parent = workspace
                
                TweenService:Create(glow, TweenInfo.new(0.3), {
                    Size = Vector3.new(0.1, 0.1, 0.1),
                    Transparency = 1
                }):Play()
                
                Debris:AddItem(glow, 0.4)
            end)
        end
        
        -- Retract animation
        task.delay(0.3, function()
            TweenService:Create(tendrilArm, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = Vector3.new(0.1, 0.1, 0.1),
                Transparency = 1
            }):Play()
            Debris:AddItem(tendrilArm, 0.3)
        end)
        
        -- Hit detection along the tendril path
        local enemies = Util.GetEnemiesInRange(Config.ERange)
        for _, enemyData in ipairs(enemies) do
            local enemyChar = enemyData.Character
            local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemyChar:FindFirstChild("Humanoid")
            
            if enemyHRP and enemyHum then
                -- Check if enemy is in front
                local toEnemy = (enemyHRP.Position - HumanoidRootPart.Position).Unit
                local dot = toEnemy:Dot(direction)
                
                if dot > 0.5 then -- roughly in front
                    local damage = Config.Damage.E
                    if State.UltActive then damage = damage * 1.5 end
                    enemyHum:TakeDamage(damage)
                    
                    -- Pull enemy towards player
                    local pullDir = (HumanoidRootPart.Position - enemyHRP.Position).Unit
                    local pull = Instance.new("BodyVelocity")
                    pull.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    pull.Velocity = pullDir * 80 + Vector3.new(0, 20, 0)
                    pull.Parent = enemyHRP
                    Debris:AddItem(pull, 0.25)
                    
                    VFX.CreateHitEffect(enemyHRP.Position)
                    VFX.CreateMultipleTendrils(startPos, enemyHRP.Position, 4, 10)
                    VFX.ScreenShake(0.5, 0.15)
                    SFX.Play(SoundIds.Hit, enemyHRP, 1, 0.7)
                end
            end
        end
    end)
    
    -- Reset
    task.delay(0.6, function()
        Anim.TweenMotor("RightShoulder", CFrame.Angles(0, 0, 0), 0.2)
        State.IsAttacking = false
    end)
end

-- ========================
-- R SKILL - Symbiote Slam
-- ========================
function Combat.SymbioteSlam()
    if not Util.CanAttack() then return end
    if Util.IsOnCooldown("R") then return end
    
    State.IsAttacking = true
    Util.SetCooldown("R")
    
    -- Jump up
    local jumpForce = Instance.new("BodyVelocity")
    jumpForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    jumpForce.Velocity = Vector3.new(0, 50, 0) + HumanoidRootPart.CFrame.LookVector * 15
    jumpForce.Parent = HumanoidRootPart
    Debris:AddItem(jumpForce, 0.3)
    
    -- Raise arms animation
    Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(-170), 0, math.rad(15)), 0.15)
    Anim.TweenMotor("LeftShoulder", CFrame.Angles(math.rad(-170), 0, math.rad(-15)), 0.15)
    
    SFX.Play(SoundIds.Whoosh, HumanoidRootPart, 0.6, 0.6)
    
    -- Growing symbiote arms during jump
    local symbioteGrowth = {}
    for _, armName in ipairs({"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand", "Right Arm", "Left Arm"}) do
        local arm = Character:FindFirstChild(armName)
        if arm and arm:IsA("BasePart") then
            local originalColor = arm.Color
            arm.Color = Config.TendrilColor
            arm.Material = Enum.Material.SmoothPlastic
            table.insert(symbioteGrowth, {Part = arm, OriginalColor = originalColor})
            VFX.CreateSymbioteParticle(arm, 1.5)
        end
    end
    
    -- Slam down after delay
    task.delay(0.4, function()
        -- Slam velocity
        local slamForce = Instance.new("BodyVelocity")
        slamForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        slamForce.Velocity = Vector3.new(0, -120, 0) + HumanoidRootPart.CFrame.LookVector * 20
        slamForce.Parent = HumanoidRootPart
        Debris:AddItem(slamForce, 0.3)
        
        -- Slam arms down
        Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(40), 0, math.rad(30)), 0.1)
        Anim.TweenMotor("LeftShoulder", CFrame.Angles(math.rad(40), 0, math.rad(-30)), 0.1)
        
        SFX.Play(SoundIds.Whoosh, HumanoidRootPart, 0.8, 0.4)
    end)
    
    -- Impact on landing
    task.delay(0.7, function()
        local impactPos = HumanoidRootPart.Position - Vector3.new(0, 3, 0)
        
        VFX.CreateSlamEffect(impactPos)
        VFX.ScreenShake(1.2, 0.3)
        VFX.FlashScreen(Config.VenomBlack, 0.2)
        SFX.Play(SoundIds.Slam, HumanoidRootPart, 1.2, 0.5)
        
        -- Tendril eruption from ground
        for i = 1, 8 do
            task.delay(i * 0.03, function()
                local angle = (i / 8) * math.pi * 2
                local groundPos = impactPos + Vector3.new(math.cos(angle) * 4, 0, math.sin(angle) * 4)
                local skyPos = groundPos + Vector3.new(0, 12, 0)
                VFX.CreateTendril(groundPos, skyPos, 0.8)
            end)
        end
        
        -- AOE damage
        local enemies = Util.GetEnemiesInRange(Config.RRange)
        for _, enemyData in ipairs(enemies) do
            local enemyChar = enemyData.Character
            local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemyChar:FindFirstChild("Humanoid")
            
            if enemyHRP and enemyHum then
                local damage = Config.Damage.R
                if State.UltActive then damage = damage * 1.5 end
                enemyHum:TakeDamage(damage)
                
                -- Launch enemy
                local launchDir = (enemyHRP.Position - HumanoidRootPart.Position).Unit
                local launch = Instance.new("BodyVelocity")
                launch.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                launch.Velocity = launchDir * 50 + Vector3.new(0, 60, 0)
                launch.Parent = enemyHRP
                Debris:AddItem(launch, 0.3)
                
                VFX.CreateHitEffect(enemyHRP.Position)
                VFX.CreateSymbioteParticle(enemyHRP, 1)
            end
        end
        
        -- Restore arm colors
        task.delay(0.5, function()
            for _, data in ipairs(symbioteGrowth) do
                if data.Part and data.Part.Parent then
                    data.Part.Color = data.OriginalColor
                    data.Part.Material = Enum.Material.SmoothPlastic
                end
            end
        end)
    end)
    
    -- Reset
    task.delay(1.2, function()
        Anim.TweenMotor("RightShoulder", CFrame.Angles(0, 0, 0), 0.3)
        Anim.TweenMotor("LeftShoulder", CFrame.Angles(0, 0, 0), 0.3)
        State.IsAttacking = false
    end)
end

-- ========================
-- T SKILL - Lethal Protector (Counter)
-- ========================
function Combat.LethalProtector()
    if not Util.CanAttack() then return end
    if Util.IsOnCooldown("T") then return end
    
    State.IsAttacking = true
    State.IsBlocking = true
    Util.SetCooldown("T")
    
    -- Counter stance - cross arms with symbiote shield
    Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(-60), math.rad(30), 0), 0.1)
    Anim.TweenMotor("LeftShoulder", CFrame.Angles(math.rad(-60), math.rad(-30), 0), 0.1)
    
    -- Create symbiote shield
    local shield = Instance.new("Part")
    shield.Name = "SymbioteShield"
    shield.Anchored = false
    shield.CanCollide = false
    shield.Material = Enum.Material.SmoothPlastic
    shield.Color = Config.TendrilColor
    shield.Size = Vector3.new(5, 6, 0.5)
    shield.Transparency = 0.3
    shield.Parent = workspace
    
    local shieldWeld = Instance.new("Weld")
    shieldWeld.Part0 = HumanoidRootPart
    shieldWeld.Part1 = shield
    shieldWeld.C0 = CFrame.new(0, 0, -2)
    shieldWeld.Parent = shield
    
    -- Shield particles
    VFX.CreateSymbioteParticle(shield, 2)
    
    -- Shield glow
    local shieldGlow = Instance.new("SurfaceLight")
    shieldGlow.Color = Config.VenomPurple
    shieldGlow.Brightness = 3
    shieldGlow.Range = 10
    shieldGlow.Face = Enum.NormalId.Front
    shieldGlow.Parent = shield
    
    SFX.Play(SoundIds.Counter, HumanoidRootPart, 0.8, 1)
    
    -- Moving tendrils on shield surface
    for i = 1, 6 do
        local tendrilPart = Instance.new("Part")
        tendrilPart.Anchored = false
        tendrilPart.CanCollide = false
        tendrilPart.Material = Enum.Material.Neon
        tendrilPart.Color = Config.VenomPurple
        tendrilPart.Size = Vector3.new(0.2, 0.2, 2)
        tendrilPart.Transparency = 0.5
        tendrilPart.Parent = shield
        
        local tWeld = Instance.new("Weld")
        tWeld.Part0 = shield
        tWeld.Part1 = tendrilPart
        tWeld.C0 = CFrame.new(math.random(-20, 20)/10, math.random(-25, 25)/10, 0)
            * CFrame.Angles(0, 0, math.rad(math.random(-90, 90)))
        tWeld.Parent = tendrilPart
        
        Debris:AddItem(tendrilPart, 2)
    end
    
    -- Counter window (1.5 seconds)
    local counterActive = true
    local counterConnection
    
    counterConnection = RunService.Heartbeat:Connect(function()
        if not counterActive then return end
        
        -- Check if any enemy attacks during counter window
        local enemies = Util.GetEnemiesInRange(Config.M1Range + 2)
        for _, enemyData in ipairs(enemies) do
            local enemyChar = enemyData.Character
            local enemyHRP = enemyChar:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemyChar:FindFirstChild("Humanoid")
            
            -- Simple counter check: if enemy is close and facing us
            if enemyHRP and enemyHum and enemyData.Distance < 6 then
                local toUs = (HumanoidRootPart.Position - enemyHRP.Position).Unit
                local enemyLook = enemyHRP.CFrame.LookVector
                local dot = toUs:Dot(enemyLook)
                
                if dot > 0.7 then -- enemy is facing us and close
                    counterActive = false
                    counterConnection:Disconnect()
                    
                    -- COUNTER ACTIVATED!
                    VFX.FlashScreen(Config.VenomPurple, 0.3)
                    VFX.ScreenShake(1.5, 0.3)
                    SFX.Play(SoundIds.Roar, HumanoidRootPart, 1.2, 0.8)
                    
                    -- Destroy shield
                    shield:Destroy()
                    
                    -- Symbiote eruption counter attack
                    local damage = Config.Damage.T
                    if State.UltActive then damage = damage * 1.5 end
                    enemyHum:TakeDamage(damage)
                    
                    -- Tendril grab and throw
                    VFX.CreateMultipleTendrils(HumanoidRootPart.Position, enemyHRP.Position, 8, 20)
                    VFX.CreateHitEffect(enemyHRP.Position)
                    VFX.CreateSymbioteParticle(enemyHRP, 1.5)
                    
                    -- Stun and throw enemy
                    local throwDir = HumanoidRootPart.CFrame.LookVector
                    local throwForce = Instance.new("BodyVelocity")
                    throwForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    throwForce.Velocity = throwDir * 100 + Vector3.new(0, 40, 0)
                    throwForce.Parent = enemyHRP
                    Debris:AddItem(throwForce, 0.4)
                    
                    -- Symbiote wrap effect on enemy
                    for _, part in ipairs(enemyChar:GetDescendants()) do
                        if part:IsA("BasePart") then
                            local wrapEffect = Instance.new("ParticleEmitter")
                            wrapEffect.Color = ColorSequence.new(Config.VenomBlack)
                            wrapEffect.Size = NumberSequence.new(0.5)
                            wrapEffect.Lifetime = NumberRange.new(0.5, 1)
                            wrapEffect.Rate = 50
                            wrapEffect.Speed = NumberRange.new(0, 1)
                            wrapEffect.Parent = part
                            Debris:AddItem(wrapEffect, 1)
                            task.delay(0.7, function()
                                wrapEffect.Enabled = false
                            end)
                        end
                    end
                    
                    break
                end
            end
        end
    end)
    
    -- Counter window timeout
    task.delay(1.5, function()
        counterActive = false
        if counterConnection then
            counterConnection:Disconnect()
        end
        
        if shield and shield.Parent then
            TweenService:Create(shield, TweenInfo.new(0.3), {Transparency = 1}):Play()
            Debris:AddItem(shield, 0.4)
        end
    end)
    
    -- Reset
    task.delay(2, function()
        Anim.TweenMotor("RightShoulder", CFrame.Angles(0, 0, 0), 0.2)
        Anim.TweenMotor("LeftShoulder", CFrame.Angles(0, 0, 0), 0.2)
        State.IsAttacking = false
        State.IsBlocking = false
    end)
end

-- ========================
-- F SKILL - Venom Barrage
-- ========================
function Combat.VenomBarrage()
    if not Util.CanAttack() then return end
    if Util.IsOnCooldown("F") then return end
    
    State.IsAttacking = true
    Util.SetCooldown("F")
    
    local enemy, dist = Util.GetNearestEnemy(Config.FRange + 5)
    
    if enemy then
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        if enemyHRP then
            Util.FaceTarget(enemyHRP.Position)
        end
    end
    
    SFX.Play(SoundIds.Charge, HumanoidRootPart, 0.8, 1.2)
    
    -- Charge animation - symbiote gathers
    VFX.CreateSymbioteAura(Character, 2.5)
    
    -- Wind up
    Anim.TweenMotor("RightShoulder", CFrame.Angles(math.rad(-90), 0, 0), 0.15)
    Anim.TweenMotor("LeftShoulder", CFrame.Angles(math.rad(-90), 0, 0), 0.15)
    
    task.delay(0.3, function()
        -- BARRAGE!
        local direction = HumanoidRootPart.CFrame.LookVector
        
        -- Rapid tendril punches
        local barrageCount = 15
        for i = 1, barrageCount do
            task.delay(i * 0.06, function()
                if not Character or not Character.Parent then return end
                
                -- Alternate arms
                local isRight = i % 2 == 1
                local motorName = isRight and "RightShoulder" or "LeftShoulder"
                local side = isRight and 1 or -1
                
                -- Quick punch animation
                Anim.TweenMotor(motorName, CFrame.Angles(
                    math.rad(-90 + math.random(-20, 20)),
                    math.rad(math.random(-10, 10)),
                    math.rad(side * math.random(5, 15))
                ), 0.03)
                
                -- Tendril lines
                VFX.CreateBarrageLines(
                    HumanoidRootPart.Position + Vector3.new(side * 0.8, 1.5, 0),
                    direction,
                    3
                )
                
                SFX.Play(SoundIds.Whoosh, HumanoidRootPart, 0.3, 1 + math.random(-10, 10) / 50)
                
                -- Hit check
                local target, tDist = Util.GetNearestEnemy(Config.FRange)
                if target then
                    local tHRP = target:FindFirstChild("HumanoidRootPart")
                    local tHum = target:FindFirstChild("Humanoid")
                    
                    if tHRP and tHum then
                        local toEnemy = (tHRP.Position - HumanoidRootPart.Position).Unit
                        if toEnemy:Dot(direction) > 0.3 then
                            local damage = Config.Damage.F / barrageCount * 2
                            if State.UltActive then damage = damage * 1.5 end
                            tHum:TakeDamage(damage)
                            
                            VFX.CreateHitEffect(tHRP.Position + Vector3.new(
                                math.random(-10, 10) / 10,
                                math.random(-10, 10) / 10,
                                math.random(-10, 10) / 10
                            ))
                            
                            -- Keep enemy in place during barrage
                            local hold = Instance.new("BodyVelocity")
                            hold.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            hold.Velocity = Vector3.new(0, 0, 0)
                            hold.Parent = tHRP
                            Debris:AddItem(hold, 0.08)
                            
                            if i % 3 == 0 then
                                VFX.ScreenShake(0.3, 0.05)
                            end
                            
                            SFX.Play(SoundIds.Hit, tHRP, 0.4, 1 + math.random(-5, 5) / 20)
                        end
                    end
                end
                
                -- Final hit - big knockback
                if i == barrageCount then
                    task.delay(0.1, function()
                        local finalTarget, _ = Util.GetNearestEnemy(Config.FRange)
                        if finalTarget then
                            local fHRP = finalTarget:FindFirstChild("HumanoidRootPart")
                            local fHum = finalTarget:FindFirstChild("Humanoid")
                            
                            if fHRP and fHum then
                                fHum:TakeDamage(Config.Damage.F * 0.3)
                                
                                local finishDir = (fHRP.Position - HumanoidRootPart.Position).Unit
                                local finishForce = Instance.new("BodyVelocity")
                                finishForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                finishForce.Velocity = finishDir * 90 + Vector3.new(0, 25, 0)
                                finishForce.Parent = fHRP
                                Debris:AddItem(finishForce, 0.35)
                                
                                VFX.ScreenShake(1.5, 0.25)
                                VFX.FlashScreen(Config.VenomPurple, 0.2)
                                VFX.CreateMultipleTendrils(HumanoidRootPart.Position, fHRP.Position, 10, 30)
                                VFX.CreateSlamEffect(fHRP.Position)
                                SFX.Play(SoundIds.Slam, fHRP, 1.2, 0.6)
                            end
                        end
                    end)
                end
            end)
        end
    end)
    
    -- Reset
    task.delay(1.5, function()
        Anim.TweenMotor("RightShoulder", CFrame.Angles(0, 0, 0), 0.3)
        Anim.TweenMotor("LeftShoulder", CFrame.Angles(0, 0, 0), 0.3)
        State.IsAttacking = false
    end)
end

-- ============================================
-- ULTIMATE: "WE ARE VENOM"
-- ============================================
function Combat.Ultimate()
    if not Util.CanAttack() then return end
    if Util.IsOnCooldown("G") then return end
    if State.IsInUlt then return end
    
    State.IsAttacking = true
    State.IsInUlt = true
    Util.SetCooldown("G")
    
    -- ============ PHASE 1: TRANSITION ============
    
    -- Lock player in place
    Humanoid.WalkSpeed = 0
    Humanoid.JumpPower = 0
    
    local bodyPos = Instance.new("BodyPosition")
    bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyPos.Position = HumanoidRootPart.Position + Vector3.new(0, 5, 0)
    bodyPos.P = 10000
    bodyPos.D = 1000
    bodyPos.Parent = HumanoidRootPart
    
    -- Dramatic camera zoom
    local originalFOV = Camera.FieldOfView
    TweenService:Create(Camera, TweenInfo.new(1, Enum.EasingStyle.Quad), {
        FieldOfView = 30
    }):Play()
    
    -- Screen goes dark
    local darkOverlay = Instance.new("ScreenGui")
    darkOverlay.Name = "VenomTransition"
    darkOverlay.IgnoreGuiInset = true
    darkOverlay.DisplayOrder = 100
    darkOverlay.Parent = Player.PlayerGui
    
    local darkFrame = Instance.new("Frame")
    darkFrame.Size = UDim2.new(1, 0, 1, 0)
    darkFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    darkFrame.BackgroundTransparency = 1
    darkFrame.BorderSizePixel = 0
    darkFrame.Parent = darkOverlay
    
    TweenService:Create(darkFrame, TweenInfo.new(1.5), {
        BackgroundTransparency = 0.6
    }):Play()
    
    -- "WE ARE VENOM" text
    task.delay(0.5, function()
        local textLabel = Instance.new("TextLabel")
        textLabel.Text = "W E   A R E   V E N O M"
        textLabel.Font = Enum.Font.GothamBlack
        textLabel.TextSize = 0
        textLabel.TextColor3 = Config.EyeWhite
        textLabel.TextStrokeColor3 = Config.VenomPurple
        textLabel.TextStrokeTransparency = 0
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, 0, 0.3, 0)
        textLabel.Position = UDim2.new(0, 0, 0.35, 0)
        textLabel.Parent = darkOverlay
        
        TweenService:Create(textLabel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextSize = 72
        }):Play()
        
        task.delay(2, function()
            TweenService:Create(textLabel, TweenInfo.new(0.3), {
                TextTransparency = 1,
                TextStrokeTransparency = 1
            }):Play()
        end)
    end)
    
    -- Symbiote crawl effect
    SFX.Play(SoundIds.Symbiote, HumanoidRootPart, 1.5, 0.5)
    
    -- Symbiote covers body from feet up
    local bodyParts = {}
    local partOrder = {"LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg",
                       "LowerTorso", "UpperTorso", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm",
                       "LeftHand", "RightHand", "Head",
                       -- R6 fallback
                       "Left Leg", "Right Leg", "Torso", "Left Arm", "Right Arm", "Head"}
    
    for i, partName in ipairs(partOrder) do
        local part = Character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            task.delay(i * 0.1, function()
                local originalColor = part.Color
                local originalMaterial = part.Material
                table.insert(bodyParts, {Part = part, Color = originalColor, Material = originalMaterial})
                
                -- Symbiote crawl particle
                VFX.CreateSymbioteParticle(part, 1)
                
                -- Color transition
                TweenService:Create(part, TweenInfo.new(0.3), {
                    Color = Config.TendrilColor
                }):Play()
                part.Material = Enum.Material.SmoothPlastic
            end)
        end
    end
    
    -- Create Venom eyes
    task.delay(1.5, function()
        local head = Character:FindFirstChild("Head")
        if head then
            -- Hide face
            for _, decal in ipairs(head:GetDescendants()) do
                if decal:IsA("Decal") then
                    decal.Transparency = 1
                end
            end
            
            local eyes = VFX.CreateVenomEyes(head)
            
            -- Eyes appear with flash
            VFX.FlashScreen(Config.EyeWhite, 0.3)
            VFX.ScreenShake(2, 0.5)
            SFX.Play(SoundIds.Roar, HumanoidRootPart, 2, 0.5)
        end
    end)
    
    -- Massive symbiote aura explosion
    task.delay(2, function()
        -- Aura burst
        local auraBurst = Instance.new("Part")
        auraBurst.Anchored = true
        auraBurst.CanCollide = false
        auraBurst.Material = Enum.Material.Neon
        auraBurst.Color = Config.VenomPurple
        auraBurst.Shape = Enum.PartType.Ball
        auraBurst.Size = Vector3.new(2, 2, 2)
        auraBurst.Position = HumanoidRootPart.Position
        auraBurst.Transparency = 0.3
        auraBurst.Parent = workspace
        
        TweenService:Create(auraBurst, TweenInfo.new(0.8, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
            Size = Vector3.new(60, 60, 60),
            Transparency = 1
        }):Play()
        
        Debris:AddItem(auraBurst, 1)
        
        -- Tendrils explode outward
        for i = 1, 16 do
            local angle = (i / 16) * math.pi * 2
            local dir = Vector3.new(math.cos(angle), 0.3, math.sin(angle))
            VFX.CreateTendril(
                HumanoidRootPart.Position,
                HumanoidRootPart.Position + dir * 20,
                1.2
            )
        end
        
        -- Ground eruption
        VFX.CreateSlamEffect(HumanoidRootPart.Position - Vector3.new(0, 3, 0))
        VFX.ScreenShake(3, 0.5)
        
        -- AOE damage from transformation
        local enemies = Util.GetEnemiesInRange(20)
        for _, enemyData in ipairs(enemies) do
            local eHum = enemyData.Character:FindFirstChild("Humanoid")
            local eHRP = enemyData.Character:FindFirstChild("HumanoidRootPart")
            if eHum and eHRP then
                eHum:TakeDamage(20)
                local pushDir = (eHRP.Position - HumanoidRootPart.Position).Unit
                local push = Instance.new("BodyVelocity")
                push.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                push.Velocity = pushDir * 60 + Vector3.new(0, 30, 0)
                push.Parent = eHRP
                Debris:AddItem(push, 0.3)
            end
        end
    end)
    
    -- ============ PHASE 2: TRANSFORMATION COMPLETE ============
    task.delay(Config.UltTransitionTime, function()
        -- Remove body lock
        bodyPos:Destroy()
        
        -- Restore movement with buffs
        Humanoid.WalkSpeed = 24 -- increased from 16
        Humanoid.JumpPower = 65 -- increased from 50
        
        -- Restore camera
        TweenService:Create(Camera, TweenInfo.new(0.5), {
            FieldOfView = originalFOV
        }):Play()
        
        -- Fade overlay
        TweenService:Create(darkFrame, TweenInfo.new(0.5), {
            BackgroundTransparency = 1
        }):Play()
        Debris:AddItem(darkOverlay, 1)
        
        State.UltActive = true
        State.IsAttacking = false
        
        -- Permanent aura during ult
        local ultAura = VFX.CreateSymbioteAura(Character)
        
        -- Venom size increase
        if Character:FindFirstChild("Humanoid") then
            local bodyScale = Character.Humanoid:FindFirstChildOfClass("NumberValue")
            -- Try to scale character
            local headScale = Character.Humanoid:FindFirstChild("HeadScale")
            local bodyWidth = Character.Humanoid:FindFirstChild("BodyWidthScale")
            local bodyHeight = Character.Humanoid:FindFirstChild("BodyHeightScale")
            local bodyDepth = Character.Humanoid:FindFirstChild("BodyDepthScale")
            
            if bodyWidth then
                TweenService:Create(bodyWidth, TweenInfo.new(0.5), {Value = bodyWidth.Value * 1.3}):Play()
            end
            if bodyHeight then
                TweenService:Create(bodyHeight, TweenInfo.new(0.5), {Value = bodyHeight.Value * 1.2}):Play()
            end
            if bodyDepth then
                TweenService:Create(bodyDepth, TweenInfo.new(0.5), {Value = bodyDepth.Value * 1.3}):Play()
            end
        end
        
        -- ============ PHASE 3: ULTIMATE MOVE (auto-targets) ============
        task.delay(0.5, function()
            Combat.UltimateAttack()
        end)
        
        -- ============ PHASE 4: ULT TIMER EXPIRES ============
        task.delay(Config.UltDuration, function()
            State.UltActive = false
            State.IsInUlt = false
            
            -- De-transform
            Humanoid.WalkSpeed = 16
            Humanoid.JumpPower = 50
            
            -- Remove aura
            for _, aura in ipairs(ultAura) do
                if aura and aura.Parent then
                    aura.Enabled = false
                    Debris:AddItem(aura, 1)
                end
            end
            
            -- Restore body colors
            for _, data in ipairs(bodyParts) do
                if data.Part and data.Part.Parent then
                    TweenService:Create(data.Part, TweenInfo.new(0.5), {
                        Color = data.Color
                    }):Play()
                    data.Part.Material = data.Material
                end
            end
            
            -- Remove venom eyes
            local head = Character:FindFirstChild("Head")
            if head then
                for _, child in ipairs(head:GetChildren()) do
                    if child.Name == "VenomEyeL" or child.Name == "VenomEyeR" then
                        child:Destroy()
                    end
                end
                -- Restore face
                for _, decal in ipairs(head:GetDescendants()) do
                    if decal:IsA("Decal") then
                        decal.Transparency = 0
                    end
                end
            end
            
            -- Restore body scale
            local bodyWidth = Humanoid:FindFirstChild("BodyWidthScale")
            local bodyHeight = Humanoid:FindFirstChild("BodyHeightScale")
            local bodyDepth = Humanoid:FindFirstChild("BodyDepthScale")
            if bodyWidth then TweenService:Create(bodyWidth, TweenInfo.new(0.5), {Value = 1}):Play() end
            if bodyHeight then TweenService:Create(bodyHeight, TweenInfo.new(0.5), {Value = 1}):Play() end
            if bodyDepth then TweenService:Create(bodyDepth, TweenInfo.new(0.5), {Value = 1}):Play() end
            
            -- De-transform VFX
            VFX.FlashScreen(Config.VenomBlack, 0.5)
            VFX.CreateSymbioteParticle(HumanoidRootPart, 1.5)
            SFX.Play(SoundIds.Symbiote, HumanoidRootPart, 1, 1.5)
        end)
    end)
end

-- ========================
-- ULTIMATE ATTACK SEQUENCE
-- ========================
function Combat.UltimateAttack()
    local enemy, dist = Util.GetNearestEnemy(Config.GRange)
    if not enemy then
        return
    end
    
    local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
    local enemyHum = enemy:FindFirstChild("Humanoid")
    if not enemyHRP or not enemyHum then return end
    
    State.IsAttacking = true
    
    -- PHASE 1: Tendril Grab
    Util.FaceTarget(enemyHRP.Position)
    
    -- Launch tendrils to grab enemy
    VFX.CreateMultipleTendrils(HumanoidRootPart.Position, enemyHRP.Position, 12, 25)
    SFX.Play(SoundIds.Tendril, HumanoidRootPart, 1.2, 0.6)
    
    task.delay(0.3, function()
        if not enemyHRP or not enemyHRP.Parent then return end
        
        -- Pull enemy close
        local grab = Instance.new("BodyPosition")
        grab.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        grab.Position = HumanoidRootPart.Position + HumanoidRootPart.CFrame.LookVector * 5
        grab.P = 50000
        grab.D = 2000
        grab.Parent = enemyHRP
        
        VFX.ScreenShake(1, 0.2)
        
        -- PHASE 2: Brutal combo while grabbed
        task.delay(0.4, function()
            -- Rapid hits
            for i = 1, 8 do
                task.delay(i * 0.12, function()
                    if not enemyHRP or not enemyHRP.Parent then return end
                    
                    enemyHum:TakeDamage(Config.Damage.G / 10)
                    
                    VFX.CreateHitEffect(enemyHRP.Position + Vector3.new(
                        math.random(-15, 15) / 10,
                        math.random(-15, 15) / 10,
                        math.random(-15, 15) / 10
                    ))
                    
                    VFX.CreateBarrageLines(
                        HumanoidRootPart.Position + Vector3.new(0, 1.5, 0),
                        HumanoidRootPart.CFrame.LookVector,
                        4
                    )
                    
                    SFX.Play(SoundIds.Hit, enemyHRP, 0.8, 0.6 + i * 0.05)
                    VFX.ScreenShake(0.5, 0.08)
                end)
            end
            
            -- PHASE 3: Symbiote Devour (finisher)
            task.delay(1.2, function()
                if not enemyHRP or not enemyHRP.Parent then return end
                
                grab:Destroy()
                
                -- Dramatic pause
                VFX.FlashScreen(Config.VenomBlack, 0.1)
                
                task.delay(0.2, function()
                    if not enemyHRP or not enemyHRP.Parent then return end
                    
                    -- FINAL HIT
                    SFX.Play(SoundIds.Roar, HumanoidRootPart, 2, 0.4)
                    
                    -- Massive tendril explosion from player
                    for i = 1, 20 do
                        local randomDir = Vector3.new(
                            math.random(-100, 100) / 100,
                            math.random(0, 100) / 100,
                            math.random(-100, 100) / 100
                        ).Unit
                        VFX.CreateTendril(
                            HumanoidRootPart.Position,
                            HumanoidRootPart.Position + randomDir * math.random(10, 25),
                            1.5
                        )
                    end
                    
                    -- Apply massive damage
                    enemyHum:TakeDamage(Config.Damage.G * 0.5)
                    
                    -- Mega knockback
                    local finalDir = (enemyHRP.Position - HumanoidRootPart.Position).Unit
                    local megaKnock = Instance.new("BodyVelocity")
                    megaKnock.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    megaKnock.Velocity = finalDir * 200 + Vector3.new(0, 80, 0)
                    megaKnock.Parent = enemyHRP
                    Debris:AddItem(megaKnock, 0.5)
                    
                    -- Screen effects
                    VFX.ScreenShake(4, 0.8)
                    VFX.FlashScreen(Config.VenomPurple, 0.5)
                    
                    -- Massive ground slam effect
                    VFX.CreateSlamEffect(HumanoidRootPart.Position - Vector3.new(0, 3, 0))
                    
                    -- Symbiote explosion sphere
                    local sphere = Instance.new("Part")
                    sphere.Anchored = true
                    sphere.CanCollide = false
                    sphere.Material = Enum.Material.Neon
                    sphere.Color = Config.VenomPurple
                    sphere.Shape = Enum.PartType.Ball
                    sphere.Size = Vector3.new(3, 3, 3)
                    sphere.Position = enemyHRP.Position
                    sphere.Transparency = 0
                    sphere.Parent = workspace
                    
                    TweenService:Create(sphere, TweenInfo.new(1, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
                        Size = Vector3.new(80, 80, 80),
                        Transparency = 1
                    }):Play()
                    
                    Debris:AddItem(sphere, 1.2)
                    
                    -- Black sphere inside
                    local innerSphere = Instance.new("Part")
                    innerSphere.Anchored = true
                    innerSphere.CanCollide = false
                    innerSphere.Material = Enum.Material.SmoothPlastic
                    innerSphere.Color = Config.VenomBlack
                    innerSphere.Shape = Enum.PartType.Ball
                    innerSphere.Size = Vector3.new(2, 2, 2)
                    innerSphere.Position = enemyHRP.Position
                    innerSphere.Transparency = 0
                    innerSphere.Parent = workspace
                    
                    TweenService:Create(innerSphere, TweenInfo.new(0.8, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
                        Size = Vector3.new(50, 50, 50),
                        Transparency = 1
                    }):Play()
                    
                    Debris:AddItem(innerSphere, 1)
                    
                    -- Multiple shockwave rings
                    for j = 1, 3 do
                        task.delay(j * 0.15, function()
                            local ring = Instance.new("Part")
                            ring.Anchored = true
                            ring.CanCollide = false
                            ring.Material = Enum.Material.Neon
                            ring.Color = j == 2 and Config.VenomPurple or Config.VenomBlack
                            ring.Transparency = 0.3
                            ring.Size = Vector3.new(2, 0.2, 2)
                            ring.Position = enemyHRP.Position
                            ring.Parent = workspace
                            
                            local ringMesh = Instance.new("SpecialMesh")
                            ringMesh.MeshType = Enum.MeshType.FileMesh
                            ringMesh.MeshId = "rbxassetid://3270017"
                            ringMesh.Scale = Vector3.new(2, 2, 2)
                            ringMesh.Parent = ring
                            
                            TweenService:Create(ringMesh, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                Scale = Vector3.new(50, 50, 50)
                            }):Play()
                            
                            TweenService:Create(ring, TweenInfo.new(0.8), {Transparency = 1}):Play()
                            
                            Debris:AddItem(ring, 1)
                        end)
                    end
                    
                    -- AOE damage to nearby enemies
                    local nearbyEnemies = Util.GetEnemiesInRange(Config.GRange)
                    for _, eData in ipairs(nearbyEnemies) do
                        local eH = eData.Character:FindFirstChild("Humanoid")
                        local eR = eData.Character:FindFirstChild("HumanoidRootPart")
                        if eH and eR and eData.Character ~= enemy then
                            eH:TakeDamage(Config.Damage.G * 0.3)
                            local pushD = (eR.Position - HumanoidRootPart.Position).Unit
                            local pushF = Instance.new("BodyVelocity")
                            pushF.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            pushF.Velocity = pushD * 80 + Vector3.new(0, 40, 0)
                            pushF.Parent = eR
                            Debris:AddItem(pushF, 0.3)
                        end
                    end
                    
                    SFX.Play(SoundIds.Explosion, HumanoidRootPart, 2, 0.4)
                end)
            end)
        end)
    end)
    
    -- Reset attack state
    task.delay(2.5, function()
        State.IsAttacking = false
    end)
end

-- ============================================
-- COOLDOWN UI
-- ============================================
local function CreateCooldownUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "VenomMovesetUI"
    gui.ResetOnSpawn = false
    gui.Parent = Player.PlayerGui
    
    local container = Instance.new("Frame")
    container.Name = "CooldownContainer"
    container.Size = UDim2.new(0, 400, 0, 60)
    container.Position = UDim2.new(0.5, -200, 1, -80)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container
    
    local skills = {
        {Key = "M1", Name = "LMB", Label = "Strike"},
        {Key = "E", Name = "E", Label = "Tendril"},
        {Key = "R", Name = "R", Label = "Slam"},
        {Key = "T", Name = "T", Label = "Counter"},
        {Key = "F", Name = "F", Label = "Barrage"},
        {Key = "G", Name = "G", Label = "VENOM"},
    }
    
    local cdFrames = {}
    
    for _, skill in ipairs(skills) do
        local frame = Instance.new("Frame")
        frame.Name = skill.Key
        frame.Size = UDim2.new(0, 55, 0, 55)
        frame.BackgroundColor3 = Config.VenomBlack
        frame.BorderSizePixel = 0
        frame.Parent = container
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Config.VenomPurple
        stroke.Thickness = 2
        stroke.Parent = frame
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Text = skill.Name
        keyLabel.Font = Enum.Font.GothamBlack
        keyLabel.TextSize = 16
        keyLabel.TextColor3 = Config.EyeWhite
        keyLabel.BackgroundTransparency = 1
        keyLabel.Size = UDim2.new(1, 0, 0.5, 0)
        keyLabel.Position = UDim2.new(0, 0, 0, 0)
        keyLabel.Parent = frame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = skill.Label
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 9
        nameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.Position = UDim2.new(0, 0, 0.5, 0)
        nameLabel.Parent = frame
        
        local cdOverlay = Instance.new("Frame")
        cdOverlay.Name = "CooldownOverlay"
        cdOverlay.Size = UDim2.new(1, 0, 0, 0)
        cdOverlay.Position = UDim2.new(0, 0, 1, 0)
        cdOverlay.AnchorPoint = Vector2.new(0, 1)
        cdOverlay.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
        cdOverlay.BackgroundTransparency = 0.3
        cdOverlay.BorderSizePixel = 0
        cdOverlay.Parent = frame
        
        local cdCorner = Instance.new("UICorner")
        cdCorner.CornerRadius = UDim.new(0, 8)
        cdCorner.Parent = cdOverlay
        
        local cdText = Instance.new("TextLabel")
        cdText.Name = "CooldownText"
        cdText.Text = ""
        cdText.Font = Enum.Font.GothamBold
        cdText.TextSize = 14
        cdText.TextColor3 = Color3.new(1, 1, 1)
        cdText.BackgroundTransparency = 1
        cdText.Size = UDim2.new(1, 0, 1, 0)
        cdText.ZIndex = 5
        cdText.Parent = frame
        
        cdFrames[skill.Key] = {
            Frame = frame,
            Overlay = cdOverlay,
            Text = cdText,
            Stroke = stroke
        }
    end
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Text = "🕷 VENOM 🕷"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Config.EyeWhite
    title.TextStrokeColor3 = Config.VenomPurple
    title.TextStrokeTransparency = 0.3
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(0, 400, 0, 25)
    title.Position = UDim2.new(0.5, -200, 1, -110)
    title.Parent = gui
    
    -- Update loop
    RunService.Heartbeat:Connect(function()
        for key, data in pairs(cdFrames) do
            local elapsed = tick() - (State.Cooldowns[key] or 0)
            local maxCd = Config.Cooldowns[key]
            local remaining = maxCd - elapsed
            
            if remaining > 0 then
                local pct = remaining / maxCd
                data.Overlay.Size = UDim2.new(1, 0, pct, 0)
                data.Text.Text = string.format("%.1f", remaining)
                data.Stroke.Color = Color3.fromRGB(80, 80, 80)
            else
                data.Overlay.Size = UDim2.new(1, 0, 0, 0)
                data.Text.Text = ""
                data.Stroke.Color = State.UltActive and Config.SymbioteGreen or Config.VenomPurple
            end
            
            -- Highlight during ult
            if State.UltActive then
                data.Frame.BackgroundColor3 = Color3.fromRGB(20, 5, 30)
            else
                data.Frame.BackgroundColor3 = Config.VenomBlack
            end
        end
    end)
    
    return gui
end

-- ============================================
-- INPUT HANDLING
-- ============================================
local function SetupInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Combat.M1()
        end
        
        if input.KeyCode == Enum.KeyCode.E then
            Combat.TendrilLash()
        end
        
        if input.KeyCode == Enum.KeyCode.R then
            Combat.SymbioteSlam()
        end
        
        if input.KeyCode == Enum.KeyCode.T then
            Combat.LethalProtector()
        end
        
        if input.KeyCode == Enum.KeyCode.F then
            Combat.VenomBarrage()
        end
        
        if input.KeyCode == Enum.KeyCode.G then
            Combat.Ultimate()
        end
    end)
end

-- ============================================
-- CHARACTER RESPAWN HANDLING
-- ============================================
local function OnCharacterAdded(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    Animator = Humanoid:WaitForChild("Animator")
    
    -- Reset state
    State.M1Count = 0
    State.IsAttacking = false
    State.IsBlocking = false
    State.IsInUlt = false
    State.UltActive = false
    State.Stunned = false
    
    for key, _ in pairs(Config.Cooldowns) do
        State.Cooldowns[key] = 0
    end
end

Player.CharacterAdded:Connect(OnCharacterAdded)

-- ============================================
-- INITIALIZATION
-- ============================================
local function Init()
    print("========================================")
    print("  🕷 VENOM MOVESET LOADED 🕷")
    print("========================================")
    print("  LMB - Symbiote Strike (4-hit combo)")
    print("  E   - Tendril Lash")
    print("  R   - Symbiote Slam")
    print("  T   - Lethal Protector (Counter)")
    print("  F   - Venom Barrage")
    print("  G   - Ultimate: WE ARE VENOM")
    print("========================================")
    
    CreateCooldownUI()
    SetupInput()
end

Init() 
