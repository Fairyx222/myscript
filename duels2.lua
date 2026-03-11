-- ============================================================
-- AQUA HUB v4 - WITH VYSE AIMBOT (FPS UNCAPPED) + ULTRA FAST STEAL + FLOAT (FIXED)
-- ============================================================

repeat task.wait() until game:IsLoaded()

pcall(function() setfpscap(999) end)

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local SoundService   = game:GetService("SoundService")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")
local LocalPlayer    = Players.LocalPlayer

local NORMAL_SPEED   = 60
local CARRY_SPEED    = 30
local FOV_VALUE      = 70
local UI_SCALE       = 1.0
local speedToggled   = false
local autoBatToggled = false
local hittingCooldown = false

local Keybinds = {
    AutoBat = Enum.KeyCode.E,
    SpeedToggle = Enum.KeyCode.Q,
    AutoLeft = Enum.KeyCode.Z,
    AutoRight = Enum.KeyCode.C,
    InfiniteJump = Enum.KeyCode.M,
    UIToggle = Enum.KeyCode.U,
    Float = Enum.KeyCode.F
}

local AutoLeftEnabled  = false
local AutoRightEnabled = false
local autoLeftConnection  = nil
local autoRightConnection = nil
local autoLeftPhase  = 1
local autoRightPhase = 1

local POSITION_L1 = Vector3.new(-476.48, -6.28,  92.73)
local POSITION_L2 = Vector3.new(-483.12, -4.95,  94.80)
local POSITION_R1 = Vector3.new(-476.16, -6.52,  25.62)
local POSITION_R2 = Vector3.new(-483.04, -5.09,  23.14)

local isStealing   = false
local stealStartTime = nil
local Values = {
    STEAL_RADIUS       = 20,
    STEAL_DURATION     = 0.02,
    DEFAULT_GRAVITY    = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER          = 35,
    HOP_COOLDOWN       = 0.08,
}

local Enabled = {
    AntiRagdoll    = false,
    AutoSteal      = false,
    InfiniteJump   = false,
    ShinyGraphics  = false,
    Optimizer      = false,
    Unwalk         = false,
    AutoLeftEnabled  = false,
    AutoRightEnabled = false,
}

local Connections          = {}
local galaxyVectorForce    = nil
local galaxyAttachment     = nil
local galaxyEnabled        = false
local hopsEnabled          = false
local lastHopTime          = 0
local spaceHeld            = false
local originalJumpPower    = 50
local originalTransparency = {}
local xrayEnabled          = false
local savedAnimations      = {}
local originalSkybox       = nil
local shinyGraphicsSky     = nil
local shinyGraphicsConn    = nil
local shinyPlanets         = {}
local shinyBloom           = nil
local shinyCC              = nil
local h, hrp, speedLbl
local progressConnection   = nil

local gui = nil
local main = nil
local speedSwBg, speedSwCircle = nil, nil
local batSwBg, batSwCircle = nil, nil
local waitingForKey = nil

-- ===== FLOAT VARIABLES (OPTIMIZED) =====
local floatEnabled    = false
local floatHeight     = 10
local floatConn       = nil
local floatAttachment = nil
local floatForce      = nil
local floatVisualSetter = nil
local cachedMass      = 0
local lastMassUpdate  = 0

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ===== AUTO STEAL (ego duels engine - animal cache + prompt cache) =====
local animalCache  = {}
local promptCache  = {}
local stealCache   = {}

local AnimalsData = {}
pcall(function()
    local rep    = game:GetService("ReplicatedStorage")
    local datas  = rep:FindFirstChild("Datas")
    if datas then
        local animals = datas:FindFirstChild("Animals")
        if animals then AnimalsData = require(animals) end
    end
end)

local function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled end
    end
    return false
end

local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyPlotByName(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return end
    for _, pod in ipairs(podiums:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name = "Unknown"
            local spawn = pod.Base:FindFirstChild("Spawn")
            if spawn then
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "PromptAttachment" then
                        name = child.Name
                        local info = AnimalsData[name]
                        if info and info.DisplayName then name = info.DisplayName end
                        break
                    end
                end
            end
            table.insert(animalCache, {
                name           = name,
                plot           = plot.Name,
                slot           = pod.Name,
                worldPosition  = pod:GetPivot().Position,
                uid            = plot.Name .. "_" .. pod.Name,
            })
        end
    end
end

local function findPromptForAnimal(ad)
    if not ad then return nil end
    local cp = promptCache[ad.uid]
    if cp and cp.Parent then return cp end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot  = plots:FindFirstChild(ad.plot);    if not plot  then return nil end
    local pods  = plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end
    local pod   = pods:FindFirstChild(ad.slot);     if not pod   then return nil end
    local base  = pod:FindFirstChild("Base");        if not base  then return nil end
    local sp    = base:FindFirstChild("Spawn");      if not sp    then return nil end
    local att   = sp:FindFirstChild("PromptAttachment"); if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then promptCache[ad.uid] = p; return p end
    end
end

local function buildStealCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then table.insert(data.holdCallbacks, conn.Function) end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then table.insert(data.triggerCallbacks, conn.Function) end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then
        stealCache[prompt] = data
    end
end

local function nearestAnimal()
    local hrp = getHRP(); if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, ad in ipairs(animalCache) do
        if not isMyPlotByName(ad.plot) and ad.worldPosition then
            local d = (hrp.Position - ad.worldPosition).Magnitude
            if d < bestD then bestD = d; best = ad end
        end
    end
    return best, bestD
end

local ProgressLabel, ProgressPercentLabel, ProgressBarFill, RadiusInput, DurationInput

local function ResetProgressBar()
    if ProgressLabel        then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(0,0,1,0) end
end

local function executeSteal(prompt, animalName)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    isStealing = true
    stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = animalName or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect() return end
        local prog = math.clamp((tick()-stealStartTime)/Values.STEAL_DURATION, 0, 1)
        if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(prog,0,1,0) end
        if ProgressPercentLabel then ProgressPercentLabel.Text = math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks)    do task.spawn(fn) end
        local elapsed = 0
        while elapsed < Values.STEAL_DURATION do elapsed = elapsed + task.wait(0) end
        for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        task.wait(0.01); data.ready = true
        task.wait(0.01); isStealing = false
    end)
    return true
end

-- initialise animal cache on load + refresh every 5s
task.spawn(function()
    task.wait(2)
    local plots = workspace:WaitForChild("Plots", 10); if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then scanPlot(plot) end
    end
    plots.ChildAdded:Connect(function(plot)
        if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end
    end)
    task.spawn(function()
        while task.wait(5) do
            animalCache = {}
            for _, plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then scanPlot(plot) end
            end
        end
    end)
end)

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local target, dist = nearestAnimal()
        if not target then return end
        local hrp = getHRP(); if not hrp then return end
        if dist > Values.STEAL_RADIUS then return end
        local prompt = promptCache[target.uid]
        if not prompt or not prompt.Parent then prompt = findPromptForAnimal(target) end
        if prompt then
            buildStealCallbacks(prompt)
            executeSteal(prompt, target.name)
        end
    end)
end
local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect() Connections.autoSteal=nil end
    isStealing = false
    ResetProgressBar()
end

local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local st = hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
                if root then root.Velocity=Vector3.new(0,0,0) root.RotVelocity=Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
        end
    end)
end
local function stopAntiRagdoll()
    if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect() Connections.antiRagdoll=nil end
end

local function captureJumpPower()
    local c = LocalPlayer.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower>0 then originalJumpPower=hum.JumpPower end
    end
end
task.spawn(function() task.wait(1) captureJumpPower() end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(1) captureJumpPower() end)

local function setupGalaxyForce()
    pcall(function()
        local c  = LocalPlayer.Character; if not c then return end
        local rp = c:FindFirstChild("HumanoidRootPart"); if not rp then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment  then galaxyAttachment:Destroy()  end
        galaxyAttachment = Instance.new("Attachment"); galaxyAttachment.Parent = rp
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0         = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo          = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force               = Vector3.new(0,0,0)
        galaxyVectorForce.Parent              = rp
    end)
end
local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c = LocalPlayer.Character; if not c then return end
    local mass = 0
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end
    local tg = Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100)
    galaxyVectorForce.Force = Vector3.new(0, mass*(Values.DEFAULT_GRAVITY-tg)*0.95, 0)
end
local function adjustGalaxyJump()
    pcall(function()
        local c   = LocalPlayer.Character; if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if not galaxyEnabled then hum.JumpPower=originalJumpPower return end
        local ratio = math.sqrt((Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100))/Values.DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower*ratio
    end)
end
local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c   = LocalPlayer.Character; if not c then return end
        local rp  = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        if tick()-lastHopTime < Values.HOP_COOLDOWN then return end
        lastHopTime = tick()
        if hum.FloorMaterial==Enum.Material.Air then
            rp.AssemblyLinearVelocity = Vector3.new(rp.AssemblyLinearVelocity.X, Values.HOP_POWER, rp.AssemblyLinearVelocity.Z)
        end
    end)
end
local function startInfiniteJump()
    galaxyEnabled=true hopsEnabled=true setupGalaxyForce() adjustGalaxyJump()
end
local function stopInfiniteJump()
    galaxyEnabled=false hopsEnabled=false
    if galaxyVectorForce then galaxyVectorForce:Destroy() galaxyVectorForce=nil end
    if galaxyAttachment  then galaxyAttachment:Destroy()  galaxyAttachment=nil  end
    adjustGalaxyJump()
end
RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then doMiniHop() end
    if galaxyEnabled then updateGalaxyForce() end
end)

local function startUnwalk()
    local c = LocalPlayer.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = c:FindFirstChild("Animate")
    if anim then savedAnimations.Animate=anim:Clone() anim:Destroy() end
end
local function stopUnwalk()
    local c = LocalPlayer.Character
    if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent=c savedAnimations.Animate=nil end
end

-- ===== FLOAT (ego duels - teleport up then lock Y) =====
local function startFloat()
    floatEnabled = true
    local char = LocalPlayer.Character
    if char then
        local rp = char:FindFirstChild("HumanoidRootPart")
        if rp then
            rp.CFrame = CFrame.new(rp.Position.X, rp.Position.Y + floatHeight, rp.Position.Z)
            rp.AssemblyLinearVelocity = Vector3.new(rp.AssemblyLinearVelocity.X, 0, rp.AssemblyLinearVelocity.Z)
        end
    end
    if floatConn then floatConn:Disconnect() end
    floatConn = RunService.Heartbeat:Connect(function()
        if not floatEnabled then floatConn:Disconnect(); floatConn = nil; return end
        local c = LocalPlayer.Character; if not c then return end
        local rp = c:FindFirstChild("HumanoidRootPart"); if not rp then return end
        rp.AssemblyLinearVelocity = Vector3.new(rp.AssemblyLinearVelocity.X, 0, rp.AssemblyLinearVelocity.Z)
    end)
end

local function stopFloat()
    floatEnabled = false
    if floatConn then floatConn:Disconnect(); floatConn = nil end
end

-- ===== XRAY =====
local xrayDescendantConn = nil
local function isXrayTarget(obj)
    if not obj:IsA("BasePart") then return false end
    if not obj.Anchored then return false end
    local nameLower = obj.Name:lower()
    local parentNameLower = (obj.Parent and obj.Parent.Name:lower()) or ""
    return nameLower:find("base") ~= nil or parentNameLower:find("base") ~= nil
end
local function applyXrayToPart(obj)
    pcall(function()
        if isXrayTarget(obj) and originalTransparency[obj] == nil then
            originalTransparency[obj] = obj.LocalTransparencyModifier
            obj.LocalTransparencyModifier = 0.85
        end
    end)
end
local function applyXrayToAll()
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do applyXrayToPart(obj) end
    end)
end
local function startXrayWatcher()
    if xrayDescendantConn then return end
    xrayDescendantConn = workspace.DescendantAdded:Connect(function(obj)
        if not xrayEnabled then return end
        task.defer(function() if xrayEnabled then applyXrayToPart(obj) end end)
    end)
end
local function stopXrayWatcher()
    if xrayDescendantConn then xrayDescendantConn:Disconnect() xrayDescendantConn = nil end
end

local function enableOptimizer()
    if getgenv and getgenv().OPTIMIZER_ACTIVE then return end
    if getgenv then getgenv().OPTIMIZER_ACTIVE=true end
    pcall(function() setfpscap(999) end)
    pcall(function()
        Lighting.GlobalShadows=false Lighting.Brightness=3 Lighting.FogEnd=9e9
    end)
    pcall(function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj:Destroy()
                elseif obj:IsA("BasePart") then obj.CastShadow=false obj.Material=Enum.Material.Plastic end
            end)
        end
    end)
    xrayEnabled = true
    applyXrayToAll()
    startXrayWatcher()
end
local function disableOptimizer()
    if getgenv then getgenv().OPTIMIZER_ACTIVE=false end
    stopXrayWatcher()
    if xrayEnabled then
        for part, val in pairs(originalTransparency) do
            if part and part.Parent then part.LocalTransparencyModifier = val end
        end
        originalTransparency = {}
        xrayEnabled = false
    end
end

local function enableShinyGraphics()
    if shinyGraphicsSky then return end
    originalSkybox=Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent=nil end

    -- Ciel nocturne étoilé profond
    shinyGraphicsSky=Instance.new("Sky")
    shinyGraphicsSky.StarCount=5000
    shinyGraphicsSky.CelestialBodiesShown=true
    for _,prop in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do
        shinyGraphicsSky[prop]="rbxassetid://6444884337"
    end
    shinyGraphicsSky.Parent=Lighting

    -- Eclairage ambiant nocturne bleu-violet profond
    Lighting.Ambient          = Color3.fromRGB(10, 15, 40)
    Lighting.OutdoorAmbient   = Color3.fromRGB(20, 25, 70)
    Lighting.Brightness       = 1.2
    Lighting.ClockTime        = 0
    Lighting.GlobalShadows    = true
    Lighting.FogEnd           = 9e9

    -- Atmosphere brumeuse
    local atmo = Instance.new("Atmosphere")
    atmo.Density     = 0.35
    atmo.Offset      = 0.1
    atmo.Color       = Color3.fromRGB(8, 10, 30)
    atmo.Decay       = Color3.fromRGB(40, 20, 80)
    atmo.Glare       = 0.1
    atmo.Haze        = 1.5
    atmo.Parent      = Lighting
    table.insert(shinyPlanets, atmo)

    -- Bloom intense
    shinyBloom = Instance.new("BloomEffect")
    shinyBloom.Intensity  = 2.5
    shinyBloom.Size       = 56
    shinyBloom.Threshold  = 0.55
    shinyBloom.Parent     = Lighting

    -- Color correction pour look cinema
    shinyCC = Instance.new("ColorCorrectionEffect")
    shinyCC.Saturation  = 0.6
    shinyCC.Contrast    = 0.25
    shinyCC.Brightness  = -0.04
    shinyCC.TintColor   = Color3.fromRGB(160, 180, 255)
    shinyCC.Parent      = Lighting

    -- Sun rays subtils
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity  = 0.08
    sunRays.Spread     = 0.5
    sunRays.Parent     = Lighting
    table.insert(shinyPlanets, sunRays)

    -- Depth of field léger
    local dof = Instance.new("DepthOfFieldEffect")
    dof.FarIntensity  = 0.0
    dof.NearIntensity = 0.0
    dof.FocusDistance = 50
    dof.InFocusRadius = 30
    dof.Parent        = Lighting
    table.insert(shinyPlanets, dof)

    -- Planètes néon distantes (plus subtiles)
    local planetColors = {
        Color3.fromRGB(80, 60, 200),
        Color3.fromRGB(0, 180, 255),
        Color3.fromRGB(140, 0, 220),
    }
    for i=1,3 do
        local p=Instance.new("Part")
        p.Shape=Enum.PartType.Ball
        local sz = 600 + i*180
        p.Size=Vector3.new(sz,sz,sz)
        p.Anchored=true p.CanCollide=false p.CastShadow=false
        p.Material=Enum.Material.Neon
        p.Color=planetColors[i]
        p.Transparency=0.55
        local angle = (i-1) * (math.pi*2/3)
        p.Position=Vector3.new(math.cos(angle)*4000, 1200+i*250, math.sin(angle)*4000)
        p.Parent=workspace
        table.insert(shinyPlanets,p)
    end

    -- Loop animé
    shinyGraphicsConn=RunService.Heartbeat:Connect(function()
        if not Enabled.ShinyGraphics then return end
        local t=tick()
        -- Pulsation bloom douce
        if shinyBloom then
            shinyBloom.Intensity = 2.2 + math.sin(t*1.1)*0.5
        end
        -- Ambient qui respire légèrement
        local r = 10 + math.sin(t*0.4)*4
        local g = 15 + math.sin(t*0.3)*5
        local b = 40 + math.sin(t*0.5)*12
        Lighting.Ambient = Color3.fromRGB(r,g,b)
        -- Rotation lente des planètes
        for i,p in ipairs(shinyPlanets) do
            if p:IsA("Part") then
                local angle = t*0.06 + (i-1)*(math.pi*2/3)
                local dist = 3800 + i*200
                local h = p.Position.Y
                p.Position = Vector3.new(math.cos(angle)*dist, h, math.sin(angle)*dist)
            end
        end
    end)
end
local function disableShinyGraphics()
    if shinyGraphicsConn then shinyGraphicsConn:Disconnect() shinyGraphicsConn=nil end
    if shinyGraphicsSky  then shinyGraphicsSky:Destroy()     shinyGraphicsSky=nil  end
    if originalSkybox    then originalSkybox.Parent=Lighting  end
    if shinyBloom        then shinyBloom:Destroy() shinyBloom=nil end
    if shinyCC           then shinyCC:Destroy()    shinyCC=nil    end
    for _,obj in ipairs(shinyPlanets) do if obj then obj:Destroy() end end
    shinyPlanets={}
    Lighting.Ambient=Color3.fromRGB(127,127,127) Lighting.Brightness=2 Lighting.ClockTime=14
end

local function faceSouth()
    local c=LocalPlayer.Character; if not c then return end
    local rp=c:FindFirstChild("HumanoidRootPart"); if not rp then return end
    rp.CFrame=CFrame.new(rp.Position)*CFrame.Angles(0,0,0)
    local cam=workspace.CurrentCamera
    if cam then local cp=rp.Position cam.CFrame=CFrame.new(cp.X,cp.Y+5,cp.Z-12)*CFrame.Angles(math.rad(-15),0,0) end
end
local function faceNorth()
    local c=LocalPlayer.Character; if not c then return end
    local rp=c:FindFirstChild("HumanoidRootPart"); if not rp then return end
    rp.CFrame=CFrame.new(rp.Position)*CFrame.Angles(0,math.rad(180),0)
    local cam=workspace.CurrentCamera
    if cam then local cp=rp.Position cam.CFrame=CFrame.new(cp.X,cp.Y+2,cp.Z+12)*CFrame.Angles(0,math.rad(180),0) end
end

local _G_AL_swBg, _G_AL_swCircle = nil, nil
local _G_AR_swBg, _G_AR_swCircle = nil, nil

local function startAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect() end
    autoLeftPhase=1
    autoLeftConnection=RunService.Heartbeat:Connect(function()
        if not AutoLeftEnabled then return end
        local c=LocalPlayer.Character; if not c then return end
        local rp=c:FindFirstChild("HumanoidRootPart")
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        local spd=NORMAL_SPEED
        if autoLeftPhase==1 then
            local tgt=Vector3.new(POSITION_L1.X,rp.Position.Y,POSITION_L1.Z)
            if (tgt-rp.Position).Magnitude<1 then
                autoLeftPhase=2
                local d=(POSITION_L2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd) return
            end
            local d=(POSITION_L1-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif autoLeftPhase==2 then
            local tgt=Vector3.new(POSITION_L2.X,rp.Position.Y,POSITION_L2.Z)
            if (tgt-rp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false) rp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoLeftEnabled=false Enabled.AutoLeftEnabled=false
                if autoLeftConnection then autoLeftConnection:Disconnect() autoLeftConnection=nil end
                autoLeftPhase=1
                if _G_AL_swBg and _G_AL_swCircle then
                    _G_AL_swBg.BackgroundColor3 = Color3.fromRGB(28,28,28)
                    _G_AL_swCircle.Position = UDim2.new(0,3,0.5,-8)
                end
                faceSouth() return
            end
            local d=(POSITION_L2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
local function stopAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect() autoLeftConnection=nil end
    autoLeftPhase=1
    local c=LocalPlayer.Character
    if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
end

local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end
    autoRightPhase=1
    autoRightConnection=RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local c=LocalPlayer.Character; if not c then return end
        local rp=c:FindFirstChild("HumanoidRootPart")
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        local spd=NORMAL_SPEED
        if autoRightPhase==1 then
            local tgt=Vector3.new(POSITION_R1.X,rp.Position.Y,POSITION_R1.Z)
            if (tgt-rp.Position).Magnitude<1 then
                autoRightPhase=2
                local d=(POSITION_R2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd) return
            end
            local d=(POSITION_R1-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif autoRightPhase==2 then
            local tgt=Vector3.new(POSITION_R2.X,rp.Position.Y,POSITION_R2.Z)
            if (tgt-rp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false) rp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoRightEnabled=false Enabled.AutoRightEnabled=false
                if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection=nil end
                autoRightPhase=1
                if _G_AR_swBg and _G_AR_swCircle then
                    _G_AR_swBg.BackgroundColor3 = Color3.fromRGB(28,28,28)
                    _G_AR_swCircle.Position = UDim2.new(0,3,0.5,-8)
                end
                faceNorth() return
            end
            local d=(POSITION_R2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection=nil end
    autoRightPhase=1
    local c=LocalPlayer.Character
    if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
end

local SAFE_DELAY = 0.08
local function getBat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        tool = backpack:FindFirstChild("Bat")
        if tool then tool.Parent = char return tool end
    end
    return nil
end
local function tryHitBat()
    if hittingCooldown then return end
    hittingCooldown = true
    local bat = getBat()
    if bat then
        pcall(function()
            bat:Activate()
            local evt = bat:FindFirstChildWhichIsA("RemoteEvent")
            if evt then evt:FireServer() end
        end)
    end
    task.delay(SAFE_DELAY, function() hittingCooldown = false end)
end

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDist = math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = plr.Character.HumanoidRootPart
            local dist = (hrp.Position - targetHRP.Position).Magnitude
            if dist < closestDist then closestDist = dist closestPlayer = plr end
        end
    end
    return closestPlayer, closestDist
end
local function flyToFrontOfTarget(targetHRP)
    if not hrp then return end
    local forward = targetHRP.CFrame.LookVector
    local frontPos = targetHRP.Position + forward * 1.5
    local direction = (frontPos - hrp.Position).Unit
    hrp.Velocity = Vector3.new(direction.X * 56.5, direction.Y * 56.5, direction.Z * 56.5)
end

local function applyFOV(value)
    FOV_VALUE = value
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = FOV_VALUE end
end

local uiScaleInstance = nil
local lastScaleUpdate = 0
local scaleTween = nil
local targetScale = 1.0
local function applyUIScale(value)
    targetScale = value
    local now = tick()
    if now - lastScaleUpdate < 0.08 then return end
    lastScaleUpdate = now
    UI_SCALE = value
    if main and not uiScaleInstance then
        uiScaleInstance = Instance.new("UIScale")
        uiScaleInstance.Parent = main
    end
    if uiScaleInstance then
        if scaleTween then scaleTween:Cancel() end
        scaleTween = TweenService:Create(uiScaleInstance, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = UI_SCALE})
        scaleTween:Play()
    end
end

local saveConfigBtn
local function saveConfig()
    local cfg={
        normalSpeed=NORMAL_SPEED, carrySpeed=CARRY_SPEED,
        fovValue=FOV_VALUE, uiScale=UI_SCALE,
        autoBatKey=Keybinds.AutoBat.Name, speedToggleKey=Keybinds.SpeedToggle.Name,
        autoLeftKey=Keybinds.AutoLeft.Name, autoRightKey=Keybinds.AutoRight.Name,
        infiniteJumpKey=Keybinds.InfiniteJump.Name,
        floatKey=Keybinds.Float.Name,
        autoStealEnabled=Enabled.AutoSteal, grabRadius=Values.STEAL_RADIUS,
        stealDuration=Values.STEAL_DURATION,
        antiRagdoll=Enabled.AntiRagdoll, infiniteJump=Enabled.InfiniteJump,
        galaxyGravity=Values.GalaxyGravityPercent, hopPower=Values.HOP_POWER,
        optimizer=Enabled.Optimizer, unwalk=Enabled.Unwalk,
        shinyGraphics=Enabled.ShinyGraphics,
        autoLeftEnabled=Enabled.AutoLeftEnabled, autoRightEnabled=Enabled.AutoRightEnabled,
        floatEnabled=floatEnabled,
        floatHeight=floatHeight,
    }
    local ok=false
    if writefile then pcall(function() writefile("AquaHubConfig.json",HttpService:JSONEncode(cfg)) ok=true end) end
    if saveConfigBtn then
        local prev=saveConfigBtn.Text
        saveConfigBtn.Text = ok and "Saved!" or "Failed!"
        task.wait(1.5)
        saveConfigBtn.Text = prev
    end
    return ok
end
local function loadConfig()
    if not (isfile and isfile("AquaHubConfig.json")) then return end
    local ok,cfg=pcall(function() return HttpService:JSONDecode(readfile("AquaHubConfig.json")) end)
    if not ok or not cfg then return end
    if cfg.normalSpeed  then NORMAL_SPEED=cfg.normalSpeed end
    if cfg.carrySpeed   then CARRY_SPEED=cfg.carrySpeed   end
    if cfg.fovValue     then FOV_VALUE=cfg.fovValue       end
    if cfg.uiScale      then UI_SCALE=cfg.uiScale         end
    if cfg.autoBatKey   and Enum.KeyCode[cfg.autoBatKey]    then Keybinds.AutoBat=Enum.KeyCode[cfg.autoBatKey]       end
    if cfg.speedToggleKey and Enum.KeyCode[cfg.speedToggleKey] then Keybinds.SpeedToggle=Enum.KeyCode[cfg.speedToggleKey] end
    if cfg.autoLeftKey  and Enum.KeyCode[cfg.autoLeftKey]   then Keybinds.AutoLeft=Enum.KeyCode[cfg.autoLeftKey]     end
    if cfg.autoRightKey and Enum.KeyCode[cfg.autoRightKey]  then Keybinds.AutoRight=Enum.KeyCode[cfg.autoRightKey]   end
    if cfg.infiniteJumpKey and Enum.KeyCode[cfg.infiniteJumpKey] then Keybinds.InfiniteJump=Enum.KeyCode[cfg.infiniteJumpKey] end
    if cfg.floatKey and Enum.KeyCode[cfg.floatKey] then Keybinds.Float=Enum.KeyCode[cfg.floatKey] end
    if cfg.grabRadius   then Values.STEAL_RADIUS=cfg.grabRadius end
    if cfg.stealDuration then Values.STEAL_DURATION=cfg.stealDuration end
    if cfg.antiRagdoll  ~=nil then Enabled.AntiRagdoll=cfg.antiRagdoll   end
    if cfg.autoStealEnabled~=nil then Enabled.AutoSteal=cfg.autoStealEnabled end
    if cfg.infiniteJump ~=nil then Enabled.InfiniteJump=cfg.infiniteJump  end
    if cfg.optimizer    ~=nil then Enabled.Optimizer=cfg.optimizer        end
    if cfg.unwalk       ~=nil then Enabled.Unwalk=cfg.unwalk              end
    if cfg.shinyGraphics~=nil then Enabled.ShinyGraphics=cfg.shinyGraphics end
    if cfg.galaxyGravity then Values.GalaxyGravityPercent=cfg.galaxyGravity end
    if cfg.hopPower      then Values.HOP_POWER=cfg.hopPower                end
    if cfg.autoLeftEnabled  ~=nil then Enabled.AutoLeftEnabled=cfg.autoLeftEnabled   end
    if cfg.autoRightEnabled ~=nil then Enabled.AutoRightEnabled=cfg.autoRightEnabled end
    if cfg.floatEnabled ~=nil then floatEnabled=cfg.floatEnabled end
    if cfg.floatHeight then floatHeight=cfg.floatHeight end
end
loadConfig()

-- =============================================================
--  GUI
-- =============================================================

-- CYAN COLOR PALETTE (replaces purple/violet)
local C_BG     = Color3.fromRGB(0,   0,   0)
local C_CYAN   = Color3.fromRGB(0,   210, 230)   -- was C_PURPLE  (178,0,255)
local C_CYAN2  = Color3.fromRGB(80,  240, 255)   -- was C_PURPLE2 (215,90,255)
local C_DIM    = Color3.fromRGB(0,   120, 140)   -- was C_DIM     (100,0,145)
local C_SW_OFF = Color3.fromRGB(28,  28,  28)
local C_WHITE  = Color3.fromRGB(255, 255, 255)
local C_ROW_BG = Color3.fromRGB(0,   10,  16)    -- was (10,0,16)

local lastTickTime = 0
local tickSound = Instance.new("Sound")
tickSound.SoundId  = "rbxassetid://9119734881"
tickSound.Volume   = 0.22
tickSound.RollOffMaxDistance = 0
tickSound.Parent   = SoundService
local function playTick()
    local now = tick()
    if now - lastTickTime < 0.08 then return end
    lastTickTime = now
    tickSound:Play()
end

gui = Instance.new("ScreenGui")
gui.Name         = "AquaHubGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent       = LocalPlayer:WaitForChild("PlayerGui")

main = Instance.new("Frame")
main.Name             = "Main"
main.Size             = UDim2.new(0, 560, 0, 540)
main.Position         = UDim2.new(0, 20, 0, 20)
main.BackgroundColor3 = C_BG
main.BorderSizePixel  = 0
main.Active           = true
main.ClipsDescendants = true
main.Parent           = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 24)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color     = Color3.fromRGB(0, 60, 90)
mainStroke.Thickness = 1.5

do
    local drag = false; local ds, sp
    main.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=true ds=inp.Position sp=main.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

local batEmoji = Instance.new("TextLabel")
batEmoji.Size=UDim2.new(0,40,0,40) batEmoji.Position=UDim2.new(0,14,0,8)
batEmoji.BackgroundTransparency=1 batEmoji.Text="💧" batEmoji.TextColor3=C_CYAN
batEmoji.Font=Enum.Font.GothamBlack batEmoji.TextSize=32 batEmoji.ZIndex=4 batEmoji.Parent=main

local titleLbl = Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,0,0,36) titleLbl.Position=UDim2.new(0,0,0,12)
titleLbl.BackgroundTransparency=1 titleLbl.Text="AQUA HUB" titleLbl.TextColor3=C_CYAN
titleLbl.Font=Enum.Font.GothamBlack titleLbl.TextSize=28 titleLbl.TextXAlignment=Enum.TextXAlignment.Center
titleLbl.ZIndex=4 titleLbl.Parent=main

local byLbl = Instance.new("TextLabel")
byLbl.Size=UDim2.new(1,0,0,14) byLbl.Position=UDim2.new(0,0,0,50)
byLbl.BackgroundTransparency=1 byLbl.Text="fairyx" byLbl.TextColor3=C_DIM
byLbl.Font=Enum.Font.GothamBold byLbl.TextSize=11 byLbl.TextXAlignment=Enum.TextXAlignment.Center
byLbl.ZIndex=4 byLbl.Parent=main

local closeBtn = Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,28,0,28) closeBtn.Position=UDim2.new(1,-38,0,12)
closeBtn.BackgroundTransparency=1 closeBtn.Text="x" closeBtn.TextColor3=C_DIM
closeBtn.Font=Enum.Font.GothamBold closeBtn.TextSize=18 closeBtn.ZIndex=6 closeBtn.Parent=main
closeBtn.MouseButton1Click:Connect(function() main.Visible=false end)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.12),{TextColor3=Color3.fromRGB(255,60,60)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.12),{TextColor3=C_DIM}):Play() end)

local sep = Instance.new("Frame")
sep.Size=UDim2.new(1,-40,0,1) sep.Position=UDim2.new(0,20,0,68)
sep.BackgroundColor3=Color3.fromRGB(0,30,45) sep.BorderSizePixel=0 sep.ZIndex=3 sep.Parent=main

local scroll = Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,0,1,-74) scroll.Position=UDim2.new(0,0,0,74)
scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=3
scroll.ScrollBarImageColor3=C_DIM scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(0,0,0,0) scroll.ZIndex=2 scroll.Parent=main

local vstack = Instance.new("Frame")
vstack.Size=UDim2.new(1,0,0,0) vstack.AutomaticSize=Enum.AutomaticSize.Y
vstack.BackgroundTransparency=1 vstack.BorderSizePixel=0 vstack.Parent=scroll
local vstackLayout = Instance.new("UIListLayout")
vstackLayout.SortOrder=Enum.SortOrder.LayoutOrder vstackLayout.Padding=UDim.new(0,0) vstackLayout.Parent=vstack
local vstackPad = Instance.new("UIPadding")
vstackPad.PaddingLeft=UDim.new(0,18) vstackPad.PaddingRight=UDim.new(0,18)
vstackPad.PaddingTop=UDim.new(0,8) vstackPad.PaddingBottom=UDim.new(0,14) vstackPad.Parent=vstack

local VisualSetters = {}

local function makeSwitch(parent, enabledKey, defaultOn)
    local swBg = Instance.new("Frame")
    swBg.Size=UDim2.new(0,44,0,22) swBg.Position=UDim2.new(1,-48,0.5,-11)
    swBg.BackgroundColor3=defaultOn and C_CYAN or C_SW_OFF swBg.BorderSizePixel=0 swBg.ZIndex=5 swBg.Parent=parent
    Instance.new("UICorner",swBg).CornerRadius=UDim.new(1,0)
    local swCircle = Instance.new("Frame")
    swCircle.Size=UDim2.new(0,16,0,16)
    swCircle.Position=defaultOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    swCircle.BackgroundColor3=C_WHITE swCircle.BorderSizePixel=0 swCircle.ZIndex=6 swCircle.Parent=swBg
    Instance.new("UICorner",swCircle).CornerRadius=UDim.new(1,0)
    if enabledKey=="AutoLeftEnabled"  then _G_AL_swBg=swBg  _G_AL_swCircle=swCircle end
    if enabledKey=="AutoRightEnabled" then _G_AR_swBg=swBg  _G_AR_swCircle=swCircle end
    local isOn = defaultOn
    local function setVisual(state)
        isOn=state
        TweenService:Create(swBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=isOn and C_CYAN or C_SW_OFF}):Play()
        TweenService:Create(swCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=isOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
    end
    VisualSetters[enabledKey]=setVisual
    return swBg,swCircle,setVisual
end

local radiusDropOpen=nil
local KeybindDisplayLabels={}

local function makeRow(keybindRefName, labelTxt, enabledKey, order, onToggle)
    local container=Instance.new("Frame")
    container.BackgroundTransparency=1 container.BorderSizePixel=0 container.LayoutOrder=order
    container.AutomaticSize=Enum.AutomaticSize.Y container.Size=UDim2.new(1,0,0,0)
    container.ClipsDescendants=false container.Parent=vstack
    local containerList=Instance.new("UIListLayout")
    containerList.SortOrder=Enum.SortOrder.LayoutOrder containerList.Padding=UDim.new(0,0) containerList.Parent=container
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,44) row.BackgroundColor3=C_ROW_BG row.BorderSizePixel=0
    row.LayoutOrder=1 row.ZIndex=3 row.Parent=container
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    if keybindRefName~="" then
        local kbBox=Instance.new("Frame")
        kbBox.Size=UDim2.new(0,30,0,18) kbBox.Position=UDim2.new(0,10,0.5,-9)
        kbBox.BackgroundColor3=C_CYAN kbBox.BackgroundTransparency=0.5 kbBox.BorderSizePixel=0 kbBox.ZIndex=5 kbBox.Parent=row
        Instance.new("UICorner",kbBox).CornerRadius=UDim.new(0,5)
        local kbTxt=Instance.new("TextLabel")
        kbTxt.Size=UDim2.new(1,0,1,0) kbTxt.BackgroundTransparency=1
        kbTxt.Text=Keybinds[keybindRefName] and Keybinds[keybindRefName].Name or keybindRefName
        kbTxt.TextColor3=C_WHITE kbTxt.Font=Enum.Font.GothamBold kbTxt.TextSize=10
        kbTxt.TextXAlignment=Enum.TextXAlignment.Center kbTxt.ZIndex=6 kbTxt.Parent=kbBox
        KeybindDisplayLabels[keybindRefName]=kbTxt
    end
    local nameX=keybindRefName~="" and 48 or 14
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-(nameX+60),1,0) nameLbl.Position=UDim2.new(0,nameX,0,0)
    nameLbl.BackgroundTransparency=1 nameLbl.Text=labelTxt nameLbl.TextColor3=C_CYAN
    nameLbl.Font=Enum.Font.GothamBold nameLbl.TextSize=13 nameLbl.TextXAlignment=Enum.TextXAlignment.Left
    nameLbl.ZIndex=5 nameLbl.Parent=row
    local defaultOn=Enabled[enabledKey] or false
    local _,_,setVisual=makeSwitch(row,enabledKey,defaultOn)
    local isOn=defaultOn
    local dropPanel=nil local dropInput=nil
    if enabledKey=="AutoSteal" then
        dropPanel=Instance.new("Frame")
        dropPanel.Size=UDim2.new(1,0,0,0) dropPanel.BackgroundTransparency=1 dropPanel.BorderSizePixel=0
        dropPanel.ClipsDescendants=true dropPanel.LayoutOrder=2 dropPanel.ZIndex=4 dropPanel.Parent=container
        local dropInner=Instance.new("Frame")
        dropInner.Size=UDim2.new(1,0,1,0) dropInner.BackgroundColor3=Color3.fromRGB(0,10,16)
        dropInner.BorderSizePixel=0 dropInner.ZIndex=4 dropInner.Parent=dropPanel
        Instance.new("UICorner",dropInner).CornerRadius=UDim.new(0,10)
        local dropList=Instance.new("UIListLayout")
        dropList.SortOrder=Enum.SortOrder.LayoutOrder dropList.Padding=UDim.new(0,4) dropList.Parent=dropInner
        local dropPad=Instance.new("UIPadding")
        dropPad.PaddingLeft=UDim.new(0,14) dropPad.PaddingRight=UDim.new(0,14)
        dropPad.PaddingTop=UDim.new(0,8) dropPad.PaddingBottom=UDim.new(0,8) dropPad.Parent=dropInner
        local radiusRow=Instance.new("Frame")
        radiusRow.Size=UDim2.new(1,0,0,24) radiusRow.BackgroundTransparency=1
        radiusRow.BorderSizePixel=0 radiusRow.LayoutOrder=1 radiusRow.Parent=dropInner
        local radiusLbl=Instance.new("TextLabel")
        radiusLbl.Size=UDim2.new(0.5,0,1,0) radiusLbl.Position=UDim2.new(0,0,0,0)
        radiusLbl.BackgroundTransparency=1 radiusLbl.Text="Steal Radius" radiusLbl.TextColor3=C_DIM
        radiusLbl.Font=Enum.Font.GothamBold radiusLbl.TextSize=12 radiusLbl.TextXAlignment=Enum.TextXAlignment.Left
        radiusLbl.ZIndex=5 radiusLbl.Parent=radiusRow
        dropInput=Instance.new("TextBox")
        dropInput.Size=UDim2.new(0,58,0,24) dropInput.Position=UDim2.new(1,-58,0,0)
        dropInput.BackgroundColor3=Color3.fromRGB(0,20,30) dropInput.BorderSizePixel=0
        dropInput.Text=tostring(Values.STEAL_RADIUS) dropInput.TextColor3=C_CYAN
        dropInput.Font=Enum.Font.GothamBold dropInput.TextSize=13 dropInput.ZIndex=5 dropInput.Parent=radiusRow
        Instance.new("UICorner",dropInput).CornerRadius=UDim.new(0,7)
        local rStr=Instance.new("UIStroke",dropInput) rStr.Color=C_DIM rStr.Thickness=1
        dropInput.Focused:Connect(function() TweenService:Create(rStr,TweenInfo.new(0.15),{Color=C_CYAN}):Play() end)
        dropInput.FocusLost:Connect(function()
            local n=tonumber(dropInput.Text)
            if n then Values.STEAL_RADIUS=math.clamp(math.floor(n),1,500) dropInput.Text=tostring(Values.STEAL_RADIUS)
                if RadiusInput then RadiusInput.Text=tostring(Values.STEAL_RADIUS) end
            else dropInput.Text=tostring(Values.STEAL_RADIUS) end
            TweenService:Create(rStr,TweenInfo.new(0.15),{Color=C_DIM}):Play()
        end)
        local durationRow=Instance.new("Frame")
        durationRow.Size=UDim2.new(1,0,0,24) durationRow.BackgroundTransparency=1
        durationRow.BorderSizePixel=0 durationRow.LayoutOrder=2 durationRow.Parent=dropInner
        local durationLbl=Instance.new("TextLabel")
        durationLbl.Size=UDim2.new(0.5,0,1,0) durationLbl.Position=UDim2.new(0,0,0,0)
        durationLbl.BackgroundTransparency=1 durationLbl.Text="Steal Duration (s)" durationLbl.TextColor3=C_DIM
        durationLbl.Font=Enum.Font.GothamBold durationLbl.TextSize=12 durationLbl.TextXAlignment=Enum.TextXAlignment.Left
        durationLbl.ZIndex=5 durationLbl.Parent=durationRow
        local durationInput=Instance.new("TextBox")
        durationInput.Size=UDim2.new(0,58,0,24) durationInput.Position=UDim2.new(1,-58,0,0)
        durationInput.BackgroundColor3=Color3.fromRGB(0,20,30) durationInput.BorderSizePixel=0
        durationInput.Text=tostring(Values.STEAL_DURATION) durationInput.TextColor3=C_CYAN
        durationInput.Font=Enum.Font.GothamBold durationInput.TextSize=13 durationInput.ZIndex=5 durationInput.Parent=durationRow
        Instance.new("UICorner",durationInput).CornerRadius=UDim.new(0,7)
        local dStr=Instance.new("UIStroke",durationInput) dStr.Color=C_DIM dStr.Thickness=1
        DurationInput=durationInput
        durationInput.Focused:Connect(function() TweenService:Create(dStr,TweenInfo.new(0.15),{Color=C_CYAN}):Play() end)
        durationInput.FocusLost:Connect(function()
            local n=tonumber(durationInput.Text)
            if n then Values.STEAL_DURATION=math.clamp(n,0.1,10) durationInput.Text=tostring(Values.STEAL_DURATION)
                if DurationInput then DurationInput.Text=tostring(Values.STEAL_DURATION) end
            else durationInput.Text=tostring(Values.STEAL_DURATION) end
            TweenService:Create(dStr,TweenInfo.new(0.15),{Color=C_DIM}):Play()
        end)
    end
    local clk=Instance.new("TextButton")
    clk.Size=UDim2.new(1,0,0,44) clk.BackgroundTransparency=1 clk.Text="" clk.ZIndex=7 clk.Parent=row
    local pressStartTime=nil local pressConnection=nil local longPressTriggered=false
    clk.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            pressStartTime=tick() longPressTriggered=false
            if pressConnection then pressConnection:Disconnect() end
            pressConnection=RunService.Heartbeat:Connect(function()
                if pressStartTime and tick()-pressStartTime>=0.5 then
                    if dropPanel and not longPressTriggered then
                        longPressTriggered=true
                        if radiusDropOpen and radiusDropOpen~=dropPanel then
                            TweenService:Create(radiusDropOpen,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
                            task.delay(0.2,function() if radiusDropOpen then radiusDropOpen.Visible=false end end)
                            radiusDropOpen=nil
                        end
                        if dropPanel.Visible then
                            TweenService:Create(dropPanel,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
                            task.delay(0.22,function() dropPanel.Visible=false end)
                            radiusDropOpen=nil
                        else
                            if dropInput then dropInput.Text=tostring(Values.STEAL_RADIUS) end
                            if DurationInput then DurationInput.Text=tostring(Values.STEAL_DURATION) end
                            dropPanel.Size=UDim2.new(1,0,0,0) dropPanel.Visible=true
                            TweenService:Create(dropPanel,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,72)}):Play()
                            radiusDropOpen=dropPanel
                        end
                    end
                    if pressConnection then pressConnection:Disconnect() pressConnection=nil end
                end
            end)
        end
    end)
    clk.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            local pressDuration=pressStartTime and (tick()-pressStartTime) or 0
            pressStartTime=nil
            if pressConnection then pressConnection:Disconnect() pressConnection=nil end
            if pressDuration<0.5 and not longPressTriggered then
                isOn=not isOn Enabled[enabledKey]=isOn setVisual(isOn)
                if onToggle then onToggle(isOn) end
            end
        end
    end)
    clk.MouseButton2Click:Connect(function()
        if not dropPanel then return end
        if radiusDropOpen and radiusDropOpen~=dropPanel then
            TweenService:Create(radiusDropOpen,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
            task.delay(0.2,function() if radiusDropOpen then radiusDropOpen.Visible=false end end)
            radiusDropOpen=nil
        end
        if dropPanel.Visible then
            TweenService:Create(dropPanel,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
            task.delay(0.22,function() dropPanel.Visible=false end) radiusDropOpen=nil
        else
            if dropInput then dropInput.Text=tostring(Values.STEAL_RADIUS) end
            if DurationInput then DurationInput.Text=tostring(Values.STEAL_DURATION) end
            dropPanel.Size=UDim2.new(1,0,0,0) dropPanel.Visible=true
            TweenService:Create(dropPanel,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,72)}):Play()
            radiusDropOpen=dropPanel
        end
    end)
    clk.MouseEnter:Connect(function()
        playTick()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_CYAN2}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(0,18,26)}):Play()
    end)
    clk.MouseLeave:Connect(function()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_CYAN}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=C_ROW_BG}):Play()
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.LayoutOrder=3 gap.Parent=container
    return container,setVisual
end

local function makeManualRow(keybindRefName, labelTxt, order)
    local container=Instance.new("Frame")
    container.BackgroundTransparency=1 container.BorderSizePixel=0 container.LayoutOrder=order
    container.AutomaticSize=Enum.AutomaticSize.Y container.Size=UDim2.new(1,0,0,0) container.Parent=vstack
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,44) row.BackgroundColor3=C_ROW_BG row.BorderSizePixel=0 row.ZIndex=3 row.Parent=container
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    if keybindRefName~="" then
        local kbBox=Instance.new("Frame")
        kbBox.Size=UDim2.new(0,30,0,18) kbBox.Position=UDim2.new(0,10,0.5,-9)
        kbBox.BackgroundColor3=C_CYAN kbBox.BackgroundTransparency=0.5 kbBox.BorderSizePixel=0 kbBox.ZIndex=5 kbBox.Parent=row
        Instance.new("UICorner",kbBox).CornerRadius=UDim.new(0,5)
        local kbTxt=Instance.new("TextLabel")
        kbTxt.Size=UDim2.new(1,0,1,0) kbTxt.BackgroundTransparency=1
        kbTxt.Text=Keybinds[keybindRefName] and Keybinds[keybindRefName].Name or keybindRefName
        kbTxt.TextColor3=C_WHITE kbTxt.Font=Enum.Font.GothamBold kbTxt.TextSize=10
        kbTxt.TextXAlignment=Enum.TextXAlignment.Center kbTxt.ZIndex=6 kbTxt.Parent=kbBox
        KeybindDisplayLabels[keybindRefName]=kbTxt
    end
    local nameX=keybindRefName~="" and 48 or 14
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-(nameX+60),1,0) nameLbl.Position=UDim2.new(0,nameX,0,0)
    nameLbl.BackgroundTransparency=1 nameLbl.Text=labelTxt nameLbl.TextColor3=C_CYAN
    nameLbl.Font=Enum.Font.GothamBold nameLbl.TextSize=13 nameLbl.TextXAlignment=Enum.TextXAlignment.Left
    nameLbl.ZIndex=5 nameLbl.Parent=row
    local swBg=Instance.new("Frame")
    swBg.Size=UDim2.new(0,44,0,22) swBg.Position=UDim2.new(1,-48,0.5,-11)
    swBg.BackgroundColor3=C_SW_OFF swBg.BorderSizePixel=0 swBg.ZIndex=5 swBg.Parent=row
    Instance.new("UICorner",swBg).CornerRadius=UDim.new(1,0)
    local swCircle=Instance.new("Frame")
    swCircle.Size=UDim2.new(0,16,0,16) swCircle.Position=UDim2.new(0,3,0.5,-8)
    swCircle.BackgroundColor3=C_WHITE swCircle.BorderSizePixel=0 swCircle.ZIndex=6 swCircle.Parent=swBg
    Instance.new("UICorner",swCircle).CornerRadius=UDim.new(1,0)
    local clk=Instance.new("TextButton")
    clk.Size=UDim2.new(1,0,0,44) clk.BackgroundTransparency=1 clk.Text="" clk.ZIndex=7 clk.Parent=row
    clk.MouseEnter:Connect(function()
        playTick()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_CYAN2}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(0,18,26)}):Play()
    end)
    clk.MouseLeave:Connect(function()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_CYAN}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=C_ROW_BG}):Play()
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.Parent=container
    return clk,swBg,swCircle,nameLbl,row
end

local function makeSectionLbl(txt, order)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,24) f.BackgroundTransparency=1 f.BorderSizePixel=0 f.LayoutOrder=order f.Parent=vstack
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0) l.BackgroundTransparency=1 l.Text=txt:upper()
    l.TextColor3=Color3.fromRGB(0,55,80) l.Font=Enum.Font.GothamBold l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left l.ZIndex=4 l.Parent=f
end

local o=0
local function O() o=o+1 return o end

makeSectionLbl("Features", O())
local _,setAutoSteal   = makeRow("",  "Auto Steal",       "AutoSteal",        O(), function(s) if s then startAutoSteal()      else stopAutoSteal()      end end)
local _,setAntiRagdoll = makeRow("",  "Anti Ragdoll",     "AntiRagdoll",      O(), function(s) if s then startAntiRagdoll()    else stopAntiRagdoll()    end end)
local _,setInfJump     = makeRow("InfiniteJump","Infinite Jump","InfiniteJump",O(), function(s) if s then startInfiniteJump()  else stopInfiniteJump()   end end)
local _,setShiny       = makeRow("",  "Shiny Graphics",   "ShinyGraphics",    O(), function(s) if s then enableShinyGraphics() else disableShinyGraphics() end end)
local _,setOptimizer   = makeRow("",  "Optimizer + XRay", "Optimizer",        O(), function(s) if s then enableOptimizer()    else disableOptimizer()    end end)
local _,setUnwalk      = makeRow("",  "Unwalk",           "Unwalk",           O(), function(s) if s then startUnwalk()        else stopUnwalk()          end end)

makeSectionLbl("Movement", O())
local _,setAutoLeft  = makeRow("AutoLeft",  "Auto Left",  "AutoLeftEnabled",  O(), function(s) AutoLeftEnabled=s  Enabled.AutoLeftEnabled=s  if s then startAutoLeft()  else stopAutoLeft()  end end)
local _,setAutoRight = makeRow("AutoRight", "Auto Right", "AutoRightEnabled", O(), function(s) AutoRightEnabled=s Enabled.AutoRightEnabled=s if s then startAutoRight() else stopAutoRight() end end)

local speedClk,_speedSwBg,_speedSwCircle = makeManualRow("SpeedToggle","Carry Mode",O())
speedSwBg=_speedSwBg speedSwCircle=_speedSwCircle
speedClk.MouseButton1Click:Connect(function()
    speedToggled=not speedToggled
    TweenService:Create(speedSwBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=speedToggled and C_CYAN or C_SW_OFF}):Play()
    TweenService:Create(speedSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=speedToggled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
end)

local batClk,_batSwBg,_batSwCircle = makeManualRow("AutoBat","Auto-Bat",O())
batSwBg=_batSwBg batSwCircle=_batSwCircle
batClk.MouseButton1Click:Connect(function()
    autoBatToggled=not autoBatToggled
    TweenService:Create(batSwBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=autoBatToggled and C_CYAN or C_SW_OFF}):Play()
    TweenService:Create(batSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=autoBatToggled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
end)

local function makeInputBox(parent, lbl, defaultTxt, onDone)
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,44) wrap.BackgroundColor3=C_ROW_BG wrap.BorderSizePixel=0 wrap.ZIndex=3 wrap.Parent=parent
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,10)
    local lbTxt=Instance.new("TextLabel")
    lbTxt.Size=UDim2.new(0.58,0,1,0) lbTxt.Position=UDim2.new(0,14,0,0) lbTxt.BackgroundTransparency=1
    lbTxt.Text=lbl lbTxt.TextColor3=C_DIM lbTxt.Font=Enum.Font.GothamBold lbTxt.TextSize=12
    lbTxt.TextXAlignment=Enum.TextXAlignment.Left lbTxt.ZIndex=4 lbTxt.Parent=wrap
    local box=Instance.new("TextBox")
    box.Size=UDim2.new(0,70,0,26) box.Position=UDim2.new(1,-80,0.5,-13) box.BackgroundColor3=Color3.fromRGB(0,14,22)
    box.BorderSizePixel=0 box.Text=defaultTxt box.TextColor3=C_CYAN box.Font=Enum.Font.GothamBold
    box.TextSize=13 box.ClearTextOnFocus=false box.ZIndex=4 box.Parent=wrap
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,8)
    local bs=Instance.new("UIStroke",box) bs.Color=C_DIM bs.Thickness=1
    box.Focused:Connect(function() TweenService:Create(bs,TweenInfo.new(0.15),{Color=C_CYAN}):Play() end)
    box.FocusLost:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.15),{Color=C_DIM}):Play()
        if onDone then onDone(box.Text,box) end
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.Parent=parent
    return box
end

local function makeSlider(parent, lbl, minVal, maxVal, defaultVal, onChanged)
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,44) wrap.BackgroundColor3=C_ROW_BG wrap.BorderSizePixel=0 wrap.ZIndex=3 wrap.Parent=parent
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,10)
    local lbTxt=Instance.new("TextLabel")
    lbTxt.Size=UDim2.new(0.35,0,1,0) lbTxt.Position=UDim2.new(0,14,0,0) lbTxt.BackgroundTransparency=1
    lbTxt.Text=lbl lbTxt.TextColor3=C_DIM lbTxt.Font=Enum.Font.GothamBold lbTxt.TextSize=12
    lbTxt.TextXAlignment=Enum.TextXAlignment.Left lbTxt.ZIndex=4 lbTxt.Parent=wrap
    local valTxt=Instance.new("TextLabel")
    valTxt.Size=UDim2.new(0,50,0,20) valTxt.Position=UDim2.new(1,-60,0.5,-10) valTxt.BackgroundTransparency=1
    valTxt.Text=tostring(math.floor(defaultVal)) valTxt.TextColor3=C_CYAN valTxt.Font=Enum.Font.GothamBold
    valTxt.TextSize=13 valTxt.TextXAlignment=Enum.TextXAlignment.Right valTxt.ZIndex=5 valTxt.Parent=wrap
    local trackBg=Instance.new("Frame")
    trackBg.Size=UDim2.new(0,200,0,6) trackBg.Position=UDim2.new(0.38,0,0.5,-3)
    trackBg.BackgroundColor3=Color3.fromRGB(0,14,22) trackBg.BorderSizePixel=0 trackBg.ZIndex=4 trackBg.Parent=wrap
    Instance.new("UICorner",trackBg).CornerRadius=UDim.new(1,0)
    local trackFill=Instance.new("Frame")
    trackFill.Size=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    trackFill.BackgroundColor3=C_CYAN trackFill.BorderSizePixel=0 trackFill.ZIndex=5 trackFill.Parent=trackBg
    Instance.new("UICorner",trackFill).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("TextButton")
    thumb.Size=UDim2.new(0,14,0,14) thumb.Position=UDim2.new((defaultVal-minVal)/(maxVal-minVal),-7,0.5,-7)
    thumb.BackgroundColor3=C_WHITE thumb.BorderSizePixel=0 thumb.ZIndex=6 thumb.Text=""
    thumb.AutoButtonColor=false thumb.Parent=trackBg
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local dragging=false local dragConnection=nil local lastUpdate=0
    local function updateSlider(inputPos)
        local relX=math.clamp((inputPos.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
        local value=minVal+(maxVal-minVal)*relX
        trackFill.Size=UDim2.new(relX,0,1,0) thumb.Position=UDim2.new(relX,-7,0.5,-7)
        if lbl=="FOV" then valTxt.Text=tostring(math.floor(value))
        elseif lbl=="UI Scale" then valTxt.Text=string.format("%.1f",value)
        else valTxt.Text=tostring(math.floor(value)) end
        if lbl=="UI Scale" then
            local now=tick()
            if now-lastUpdate>=0.08 or not dragging then lastUpdate=now if onChanged then onChanged(value) end end
        else if onChanged then onChanged(value) end end
    end
    thumb.MouseButton1Down:Connect(function()
        dragging=true
        if dragConnection then dragConnection:Disconnect() end
        dragConnection=UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseMovement then updateSlider(inp.Position) end
        end)
    end)
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            if dragConnection then dragConnection:Disconnect() end
            dragConnection=inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then
                    dragging=false if dragConnection then dragConnection:Disconnect() dragConnection=nil end return
                end
                updateSlider(inp.Position)
            end)
        end
    end)
    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true updateSlider(inp.Position)
            if dragConnection then dragConnection:Disconnect() end
            dragConnection=inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then
                    dragging=false if dragConnection then dragConnection:Disconnect() dragConnection=nil end return
                end
                updateSlider(inp.Position)
            end)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false if dragConnection then dragConnection:Disconnect() dragConnection=nil end
        end
    end)
    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then updateSlider(inp.Position) end
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.Parent=parent
    return wrap
end

local function makeKeybindRow(parent, lbl, keybindRefName, onChanged)
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,44) wrap.BackgroundColor3=C_ROW_BG wrap.BorderSizePixel=0 wrap.ZIndex=3 wrap.Parent=parent
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,10)
    local lbTxt=Instance.new("TextLabel")
    lbTxt.Size=UDim2.new(0.58,0,1,0) lbTxt.Position=UDim2.new(0,14,0,0) lbTxt.BackgroundTransparency=1
    lbTxt.Text=lbl lbTxt.TextColor3=C_DIM lbTxt.Font=Enum.Font.GothamBold lbTxt.TextSize=12
    lbTxt.TextXAlignment=Enum.TextXAlignment.Left lbTxt.ZIndex=4 lbTxt.Parent=wrap
    local kbBtn=Instance.new("TextButton")
    kbBtn.Size=UDim2.new(0,70,0,26) kbBtn.Position=UDim2.new(1,-80,0.5,-13) kbBtn.BackgroundColor3=Color3.fromRGB(0,14,22)
    kbBtn.BorderSizePixel=0 kbBtn.Text=Keybinds[keybindRefName].Name kbBtn.TextColor3=C_CYAN
    kbBtn.Font=Enum.Font.GothamBold kbBtn.TextSize=11 kbBtn.ZIndex=4 kbBtn.Parent=wrap
    Instance.new("UICorner",kbBtn).CornerRadius=UDim.new(0,8)
    local ks=Instance.new("UIStroke",kbBtn) ks.Color=C_DIM ks.Thickness=1
    kbBtn.MouseButton1Click:Connect(function()
        if waitingForKey==kbBtn then
            waitingForKey=nil kbBtn.Text=Keybinds[keybindRefName].Name kbBtn.TextColor3=C_CYAN
            TweenService:Create(ks,TweenInfo.new(0.15),{Color=C_DIM}):Play() return
        end
        if waitingForKey then waitingForKey.TextColor3=C_CYAN end
        waitingForKey=kbBtn kbBtn.Text="..." kbBtn.TextColor3=C_CYAN2
        TweenService:Create(ks,TweenInfo.new(0.15),{Color=C_CYAN}):Play()
    end)
    UserInputService.InputBegan:Connect(function(inp,gpe)
        if waitingForKey~=kbBtn then return end
        if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
        local kc=inp.KeyCode
        if kc==Enum.KeyCode.Escape then
            kbBtn.Text=Keybinds[keybindRefName].Name kbBtn.TextColor3=C_CYAN
            TweenService:Create(ks,TweenInfo.new(0.15),{Color=C_DIM}):Play() waitingForKey=nil return
        end
        Keybinds[keybindRefName]=kc kbBtn.Text=kc.Name kbBtn.TextColor3=C_CYAN
        TweenService:Create(ks,TweenInfo.new(0.15),{Color=C_DIM}):Play() waitingForKey=nil
        if KeybindDisplayLabels[keybindRefName] then KeybindDisplayLabels[keybindRefName].Text=kc.Name end
        if onChanged then onChanged(kc) end
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.Parent=parent
    return kbBtn
end

makeSectionLbl("Speed", O())
local settingsWrap=Instance.new("Frame")
settingsWrap.Size=UDim2.new(1,0,0,0) settingsWrap.AutomaticSize=Enum.AutomaticSize.Y
settingsWrap.BackgroundTransparency=1 settingsWrap.BorderSizePixel=0 settingsWrap.LayoutOrder=O() settingsWrap.Parent=vstack
local swList=Instance.new("UIListLayout")
swList.SortOrder=Enum.SortOrder.LayoutOrder swList.Padding=UDim.new(0,0) swList.Parent=settingsWrap

makeInputBox(settingsWrap,"Normal Speed",tostring(NORMAL_SPEED),function(v,b)
    local n=tonumber(v) if n then NORMAL_SPEED=math.clamp(n,0.1,500) b.Text=tostring(NORMAL_SPEED) else b.Text=tostring(NORMAL_SPEED) end
end)
makeInputBox(settingsWrap,"Carry Speed",tostring(CARRY_SPEED),function(v,b)
    local n=tonumber(v) if n then CARRY_SPEED=math.clamp(n,0.1,500) b.Text=tostring(CARRY_SPEED) else b.Text=tostring(CARRY_SPEED) end
end)
makeSlider(settingsWrap,"FOV",30,120,FOV_VALUE,function(val) applyFOV(val) end)
makeSlider(settingsWrap,"UI Scale",0.5,2.0,UI_SCALE,function(val) applyUIScale(val) end)

-- ===== FLOAT UI =====
do
    local floatRow=Instance.new("Frame")
    floatRow.Size=UDim2.new(1,0,0,44) floatRow.BackgroundColor3=C_ROW_BG floatRow.BorderSizePixel=0
    floatRow.ZIndex=3 floatRow.Parent=settingsWrap
    Instance.new("UICorner",floatRow).CornerRadius=UDim.new(0,10)

    local floatLbl=Instance.new("TextLabel",floatRow)
    floatLbl.Size=UDim2.new(0.6,0,1,0) floatLbl.Position=UDim2.new(0,14,0,0)
    floatLbl.BackgroundTransparency=1 floatLbl.Text="Float" floatLbl.TextColor3=C_CYAN
    floatLbl.Font=Enum.Font.GothamBold floatLbl.TextSize=13 floatLbl.TextXAlignment=Enum.TextXAlignment.Left floatLbl.ZIndex=5

    local fSwBg=Instance.new("Frame",floatRow)
    fSwBg.Size=UDim2.new(0,44,0,22) fSwBg.Position=UDim2.new(1,-48,0.5,-11)
    fSwBg.BackgroundColor3=C_SW_OFF fSwBg.BorderSizePixel=0 fSwBg.ZIndex=5
    Instance.new("UICorner",fSwBg).CornerRadius=UDim.new(1,0)

    local fSwCircle=Instance.new("Frame",fSwBg)
    fSwCircle.Size=UDim2.new(0,16,0,16) fSwCircle.Position=UDim2.new(0,3,0.5,-8)
    fSwCircle.BackgroundColor3=C_WHITE fSwCircle.BorderSizePixel=0 fSwCircle.ZIndex=6
    Instance.new("UICorner",fSwCircle).CornerRadius=UDim.new(1,0)

    local fClk=Instance.new("TextButton",floatRow)
    fClk.Size=UDim2.new(1,0,0,44) fClk.BackgroundTransparency=1 fClk.Text="" fClk.ZIndex=7

    local function setFloatVisual(on)
        floatEnabled = on
        TweenService:Create(fSwBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=on and C_CYAN or C_SW_OFF}):Play()
        TweenService:Create(fSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        TweenService:Create(floatLbl, TweenInfo.new(0.1),{TextColor3=on and C_CYAN2 or C_CYAN}):Play()
    end
    floatVisualSetter = setFloatVisual
    local function toggleFloat()
        floatEnabled=not floatEnabled
        if floatVisualSetter then floatVisualSetter(floatEnabled) end
        if floatEnabled then startFloat() else stopFloat() end
    end
    fClk.MouseButton1Click:Connect(toggleFloat)
    fClk.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then toggleFloat() end
    end)
    fClk.MouseEnter:Connect(function()
        playTick()
        TweenService:Create(floatLbl,TweenInfo.new(0.1),{TextColor3=C_CYAN2}):Play()
        TweenService:Create(floatRow,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(0,18,26)}):Play()
    end)
    fClk.MouseLeave:Connect(function()
        if not floatEnabled then TweenService:Create(floatLbl,TweenInfo.new(0.1),{TextColor3=C_CYAN}):Play() end
        TweenService:Create(floatRow,TweenInfo.new(0.12),{BackgroundColor3=C_ROW_BG}):Play()
    end)

    local fGap=Instance.new("Frame",settingsWrap)
    fGap.Size=UDim2.new(1,0,0,5) fGap.BackgroundTransparency=1 fGap.BorderSizePixel=0
end

makeSlider(settingsWrap,"Float Ht",2,80,floatHeight,function(val) floatHeight=math.floor(val) end)

makeSectionLbl("Keybinds", O())
local kbWrap=Instance.new("Frame")
kbWrap.Size=UDim2.new(1,0,0,0) kbWrap.AutomaticSize=Enum.AutomaticSize.Y
kbWrap.BackgroundTransparency=1 kbWrap.BorderSizePixel=0 kbWrap.LayoutOrder=O() kbWrap.Parent=vstack
local kbList=Instance.new("UIListLayout")
kbList.SortOrder=Enum.SortOrder.LayoutOrder kbList.Padding=UDim.new(0,0) kbList.Parent=kbWrap

makeKeybindRow(kbWrap,"Speed Toggle","SpeedToggle",function(kc) Keybinds.SpeedToggle=kc end)
makeKeybindRow(kbWrap,"Auto-Bat",   "AutoBat",    function(kc) Keybinds.AutoBat=kc     end)
makeKeybindRow(kbWrap,"Auto Left",  "AutoLeft",   function(kc) Keybinds.AutoLeft=kc    end)
makeKeybindRow(kbWrap,"Auto Right", "AutoRight",  function(kc) Keybinds.AutoRight=kc   end)
makeKeybindRow(kbWrap,"Infinite Jump","InfiniteJump",function(kc) Keybinds.InfiniteJump=kc end)
makeKeybindRow(kbWrap,"Float",      "Float",      function(kc) Keybinds.Float=kc       end)

local saveGap=Instance.new("Frame")
saveGap.Size=UDim2.new(1,0,0,6) saveGap.BackgroundTransparency=1 saveGap.BorderSizePixel=0 saveGap.LayoutOrder=O() saveGap.Parent=vstack

saveConfigBtn=Instance.new("TextButton")
saveConfigBtn.Size=UDim2.new(1,0,0,32) saveConfigBtn.BackgroundTransparency=1
saveConfigBtn.Text="Save Config" saveConfigBtn.TextColor3=C_DIM
saveConfigBtn.Font=Enum.Font.GothamBold saveConfigBtn.TextSize=13 saveConfigBtn.LayoutOrder=O()
saveConfigBtn.ZIndex=4 saveConfigBtn.Parent=vstack
saveConfigBtn.MouseButton1Click:Connect(function() saveConfig() end)
saveConfigBtn.MouseEnter:Connect(function() TweenService:Create(saveConfigBtn,TweenInfo.new(0.1),{TextColor3=C_CYAN}):Play() end)
saveConfigBtn.MouseLeave:Connect(function() TweenService:Create(saveConfigBtn,TweenInfo.new(0.1),{TextColor3=C_DIM}):Play() end)


-- ── REOPEN BUTTON ───────────────────────────────────
-- conteneur rond avec glow
local reopenWrap = Instance.new("Frame")
reopenWrap.Size = UDim2.new(0, 64, 0, 64)
reopenWrap.Position = UDim2.new(0, 14, 0.5, -32)
reopenWrap.BackgroundTransparency = 1
reopenWrap.BorderSizePixel = 0
reopenWrap.ZIndex = 20
reopenWrap.Visible = false
reopenWrap.Parent = gui

-- cercle glow (plus grand, très transparent)
local reopenGlow = Instance.new("Frame")
reopenGlow.Size = UDim2.new(0, 80, 0, 80)
reopenGlow.Position = UDim2.new(0.5, -40, 0.5, -40)
reopenGlow.BackgroundColor3 = Color3.fromRGB(0, 210, 230)
reopenGlow.BackgroundTransparency = 0.82
reopenGlow.BorderSizePixel = 0
reopenGlow.ZIndex = 19
reopenGlow.Parent = reopenWrap
Instance.new("UICorner", reopenGlow).CornerRadius = UDim.new(1, 0)

-- cercle principal
local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0, 64, 0, 64)
reopenBtn.Position = UDim2.new(0, 0, 0, 0)
reopenBtn.BackgroundColor3 = Color3.fromRGB(4, 14, 22)
reopenBtn.BorderSizePixel = 0
reopenBtn.Text = "O"
reopenBtn.TextColor3 = Color3.fromRGB(0, 210, 230)
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 28
reopenBtn.ZIndex = 21
reopenBtn.Parent = reopenWrap
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(1, 0)

-- bordure cyan néon
local reopenStroke = Instance.new("UIStroke", reopenBtn)
reopenStroke.Color = Color3.fromRGB(0, 210, 230)
reopenStroke.Transparency = 0.3
reopenStroke.Thickness = 2

-- label "AQUA" en dessous
local reopenLbl = Instance.new("TextLabel")
reopenLbl.Size = UDim2.new(0, 64, 0, 16)
reopenLbl.Position = UDim2.new(0, 0, 1, 4)
reopenLbl.BackgroundTransparency = 1
reopenLbl.Text = "AQUA"
reopenLbl.TextColor3 = Color3.fromRGB(0, 140, 160)
reopenLbl.Font = Enum.Font.GothamBold
reopenLbl.TextSize = 10
reopenLbl.TextXAlignment = Enum.TextXAlignment.Center
reopenLbl.ZIndex = 21
reopenLbl.Parent = reopenWrap

-- animations
local isHovered = false
local glowPulseConn = nil
local function startGlowPulse()
    glowPulseConn = RunService.Heartbeat:Connect(function()
        if not reopenWrap.Visible then return end
        local t = tick()
        local alpha = 0.75 + math.sin(t * 2.5) * 0.1
        reopenGlow.BackgroundTransparency = alpha
        reopenStroke.Transparency = 0.1 + math.sin(t * 2.5) * 0.15
    end)
end
local function stopGlowPulse()
    if glowPulseConn then glowPulseConn:Disconnect(); glowPulseConn = nil end
end

reopenBtn.MouseButton1Click:Connect(function()
    stopGlowPulse()
    TweenService:Create(reopenWrap, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, 46, 0.5, 0)
    }):Play()
    task.delay(0.2, function()
        main.Visible = true
        reopenWrap.Visible = false
        reopenWrap.Size = UDim2.new(0, 64, 0, 64)
        reopenWrap.Position = UDim2.new(0, 14, 0.5, -32)
    end)
end)
reopenBtn.MouseEnter:Connect(function()
    isHovered = true
    TweenService:Create(reopenBtn,  TweenInfo.new(0.18, Enum.EasingStyle.Back), {Size=UDim2.new(0,72,0,72), Position=UDim2.new(0,-4,0,-4)}):Play()
    TweenService:Create(reopenGlow, TweenInfo.new(0.18), {BackgroundTransparency=0.6, Size=UDim2.new(0,92,0,92), Position=UDim2.new(0.5,-46,0.5,-46)}):Play()
    TweenService:Create(reopenBtn,  TweenInfo.new(0.18), {BackgroundColor3=Color3.fromRGB(0,30,45)}):Play()
end)
reopenBtn.MouseLeave:Connect(function()
    isHovered = false
    TweenService:Create(reopenBtn,  TweenInfo.new(0.18, Enum.EasingStyle.Back), {Size=UDim2.new(0,64,0,64), Position=UDim2.new(0,0,0,0)}):Play()
    TweenService:Create(reopenGlow, TweenInfo.new(0.18), {Size=UDim2.new(0,80,0,80), Position=UDim2.new(0.5,-40,0.5,-40)}):Play()
    TweenService:Create(reopenBtn,  TweenInfo.new(0.18), {BackgroundColor3=Color3.fromRGB(4,14,22)}):Play()
end)

-- show/hide avec animation pop
main:GetPropertyChangedSignal("Visible"):Connect(function()
    if not main.Visible then
        reopenWrap.Size = UDim2.new(0, 0, 0, 0)
        reopenWrap.Position = UDim2.new(0, 46, 0.5, 0)
        reopenWrap.Visible = true
        TweenService:Create(reopenWrap, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 64, 0, 64),
            Position = UDim2.new(0, 14, 0.5, -32)
        }):Play()
        startGlowPulse()
    else
        stopGlowPulse()
        reopenWrap.Visible = false
    end
end)

-- ── PROGRESS BAR ─────────────────────────────────────
local progressBar=Instance.new("Frame",gui)
progressBar.Size=UDim2.new(0,460,0,72) progressBar.Position=UDim2.new(0.5,-230,1,-90)
progressBar.BackgroundColor3=C_BG progressBar.BorderSizePixel=0 progressBar.Active=true
Instance.new("UICorner",progressBar).CornerRadius=UDim.new(0,20)
local pbStroke=Instance.new("UIStroke",progressBar)
pbStroke.Color=Color3.fromRGB(0,40,60) pbStroke.Thickness=1.5
do
    local drag=false local ds,sp
    progressBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=inp.Position sp=progressBar.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            progressBar.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end
ProgressLabel=Instance.new("TextLabel",progressBar)
ProgressLabel.Size=UDim2.new(0.55,0,0,22) ProgressLabel.Position=UDim2.new(0,14,0,8)
ProgressLabel.BackgroundTransparency=1 ProgressLabel.Text="READY" ProgressLabel.TextColor3=C_CYAN
ProgressLabel.Font=Enum.Font.GothamBlack ProgressLabel.TextSize=16 ProgressLabel.TextXAlignment=Enum.TextXAlignment.Left ProgressLabel.ZIndex=3
ProgressPercentLabel=Instance.new("TextLabel",progressBar)
ProgressPercentLabel.Size=UDim2.new(1,-14,0,22) ProgressPercentLabel.Position=UDim2.new(0,0,0,8)
ProgressPercentLabel.BackgroundTransparency=1 ProgressPercentLabel.Text="" ProgressPercentLabel.TextColor3=C_CYAN
ProgressPercentLabel.Font=Enum.Font.GothamBlack ProgressPercentLabel.TextSize=18 ProgressPercentLabel.TextXAlignment=Enum.TextXAlignment.Right ProgressPercentLabel.ZIndex=3
local radLbl=Instance.new("TextLabel",progressBar)
radLbl.Size=UDim2.new(0,55,0,18) radLbl.Position=UDim2.new(0,14,0,34) radLbl.BackgroundTransparency=1
radLbl.Text="Radius:" radLbl.TextColor3=C_DIM radLbl.Font=Enum.Font.GothamBold radLbl.TextSize=11
radLbl.TextXAlignment=Enum.TextXAlignment.Left radLbl.ZIndex=3
RadiusInput=Instance.new("TextBox",progressBar)
RadiusInput.Size=UDim2.new(0,48,0,20) RadiusInput.Position=UDim2.new(0,68,0,32)
RadiusInput.BackgroundColor3=Color3.fromRGB(0,14,20) RadiusInput.BorderSizePixel=0
RadiusInput.Text=tostring(Values.STEAL_RADIUS) RadiusInput.TextColor3=C_CYAN
RadiusInput.Font=Enum.Font.GothamBold RadiusInput.TextSize=12 RadiusInput.ZIndex=4
Instance.new("UICorner",RadiusInput).CornerRadius=UDim.new(0,6)
local rStr=Instance.new("UIStroke",RadiusInput) rStr.Color=C_DIM rStr.Thickness=1
RadiusInput.FocusLost:Connect(function()
    local n=tonumber(RadiusInput.Text)
    if n then Values.STEAL_RADIUS=math.clamp(math.floor(n),1,500) RadiusInput.Text=tostring(Values.STEAL_RADIUS) end
end)
local pTrack=Instance.new("Frame",progressBar)
pTrack.Size=UDim2.new(1,-20,0,8) pTrack.Position=UDim2.new(0,10,1,-16)
pTrack.BackgroundColor3=Color3.fromRGB(0,14,20) pTrack.BorderSizePixel=0 pTrack.ZIndex=2
Instance.new("UICorner",pTrack).CornerRadius=UDim.new(1,0)
ProgressBarFill=Instance.new("Frame",pTrack)
ProgressBarFill.Size=UDim2.new(0,0,1,0) ProgressBarFill.BackgroundColor3=C_CYAN ProgressBarFill.BorderSizePixel=0 ProgressBarFill.ZIndex=3
Instance.new("UICorner",ProgressBarFill).CornerRadius=UDim.new(1,0)

-- ===== INPUT HANDLER =====
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if waitingForKey then return end
    if input.KeyCode==Keybinds.UIToggle then main.Visible=not main.Visible end
    -- sync reopen button handled via GetPropertyChangedSignal
    if input.KeyCode==Keybinds.SpeedToggle then
        speedToggled=not speedToggled
        if speedSwBg and speedSwCircle then
            TweenService:Create(speedSwBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=speedToggled and C_CYAN or C_SW_OFF}):Play()
            TweenService:Create(speedSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=speedToggled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        end
    end
    if input.KeyCode==Keybinds.AutoBat then
        autoBatToggled=not autoBatToggled
        if batSwBg and batSwCircle then
            TweenService:Create(batSwBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=autoBatToggled and C_CYAN or C_SW_OFF}):Play()
            TweenService:Create(batSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=autoBatToggled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        end
    end
    if input.KeyCode==Keybinds.AutoLeft then
        AutoLeftEnabled=not AutoLeftEnabled Enabled.AutoLeftEnabled=AutoLeftEnabled
        if VisualSetters.AutoLeftEnabled then VisualSetters.AutoLeftEnabled(AutoLeftEnabled) end
        if AutoLeftEnabled then startAutoLeft() else stopAutoLeft() end
    end
    if input.KeyCode==Keybinds.AutoRight then
        AutoRightEnabled=not AutoRightEnabled Enabled.AutoRightEnabled=AutoRightEnabled
        if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(AutoRightEnabled) end
        if AutoRightEnabled then startAutoRight() else stopAutoRight() end
    end
    if input.KeyCode==Keybinds.InfiniteJump then
        Enabled.InfiniteJump=not Enabled.InfiniteJump
        if VisualSetters.InfiniteJump then VisualSetters.InfiniteJump(Enabled.InfiniteJump) end
        if Enabled.InfiniteJump then startInfiniteJump() else stopInfiniteJump() end
    end
    if input.KeyCode==Keybinds.Float then
        floatEnabled=not floatEnabled
        if floatVisualSetter then floatVisualSetter(floatEnabled) end
        if floatEnabled then startFloat() else stopFloat() end
    end
    if input.KeyCode==Enum.KeyCode.Space then spaceHeld=true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.Space then spaceHeld=false end
end)

-- ===== MOVEMENT LOOP =====
RunService.RenderStepped:Connect(function()
    if not (h and hrp) then return end
    if not (AutoLeftEnabled or AutoRightEnabled) then
        local md=h.MoveDirection
        local spd=speedToggled and CARRY_SPEED or NORMAL_SPEED
        if md.Magnitude>0 then hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd) end
    end
    if speedLbl then speedLbl.Text="Speed: "..string.format("%.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)

RunService.Heartbeat:Connect(function()
    if autoBatToggled and h and hrp then
        local target,dist=getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            flyToFrontOfTarget(target.Character.HumanoidRootPart)
            if dist<=5 then tryHitBat() end
        end
    end
end)

task.spawn(function()
    task.wait(2)
    if Enabled.AutoSteal     then setAutoSteal(true)    startAutoSteal()      end
    if Enabled.AntiRagdoll   then setAntiRagdoll(true)  startAntiRagdoll()    end
    if Enabled.InfiniteJump  then setInfJump(true)      startInfiniteJump()   end
    if Enabled.Unwalk        then setUnwalk(true)       startUnwalk()         end
    if Enabled.Optimizer     then setOptimizer(true)    enableOptimizer()     end
    if Enabled.ShinyGraphics then setShiny(true)        enableShinyGraphics() end
    if Enabled.AutoLeftEnabled then
        AutoLeftEnabled=true Enabled.AutoLeftEnabled=true
        if VisualSetters.AutoLeftEnabled then VisualSetters.AutoLeftEnabled(true) end
        startAutoLeft()
    end
    if Enabled.AutoRightEnabled then
        AutoRightEnabled=true Enabled.AutoRightEnabled=true
        if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(true) end
        startAutoRight()
    end
    if floatEnabled then
        if floatVisualSetter then floatVisualSetter(true) end
        startFloat()
    end
    applyFOV(FOV_VALUE)
    applyUIScale(UI_SCALE)
end)

local function setupChar(char)
    h   = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
    local head=char:FindFirstChild("Head")
    if head then
        local bb=Instance.new("BillboardGui",head)
        bb.Size=UDim2.new(0,140,0,25) bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true
        speedLbl=Instance.new("TextLabel",bb)
        speedLbl.Size=UDim2.new(1,0,1,0) speedLbl.BackgroundTransparency=1 speedLbl.TextColor3=C_CYAN
        speedLbl.Font=Enum.Font.GothamBold speedLbl.TextScaled=true
        speedLbl.TextStrokeTransparency=0 speedLbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
    end
    if floatEnabled then setupFloatForce() end
end
LocalPlayer.CharacterAdded:Connect(setupChar)
if LocalPlayer.Character then setupChar(LocalPlayer.Character) end

print("AQUA HUB v4 - Loaded! Press U to toggle UI")
