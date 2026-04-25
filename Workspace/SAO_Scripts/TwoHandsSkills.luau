local Tool = script.Parent
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character, humanoid, animator, rootPart
local camera = workspace.CurrentCamera
local damageEvent = Tool:WaitForChild("DamageEvent")

local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))
local isUsingSkill = false
local movementLock = nil 
local skillConfig = { maxSP = 100, chargeTime = 1.8, colorDark = Color3.fromRGB(20, 10, 0) } -- Carga lenta

local function updateSPBar(newSP)
	local playerGui = player:FindFirstChild("PlayerGui"); if not playerGui then return end
	local saoHUD = playerGui:FindFirstChild("SAO_HologramSystem")
	if saoHUD and saoHUD:FindFirstChild("HUD_Container") and saoHUD.HUD_Container:FindFirstChild("SP_Bar") then
		local fill = saoHUD.HUD_Container.SP_Bar:FindFirstChild("Fill")
		local percentage = math.clamp(newSP / skillConfig.maxSP, 0, 1)
		if fill then TweenService:Create(fill, TweenInfo.new(0.3), {Size = UDim2.new(percentage, 0, 1, 0)}):Play() end
	end
end

local function applyCameraShake(duration, intensity)
	local startTime = tick()
	local conn; conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration or not isUsingSkill then conn:Disconnect(); return end
		camera.CFrame = camera.CFrame * CFrame.new(Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10)) * (intensity / 300))
	end)
end

local function crearTajoGeometrico(color, posicionCFrame, sizeInicial, sizeFinal, duracion)
	local t = Instance.new("Part")
	t.Anchored = true; t.CanCollide = false; t.Material = Enum.Material.Neon; t.Color = color; t.CFrame = posicionCFrame; t.Size = sizeInicial; t.Parent = workspace
	TweenService:Create(t, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = sizeFinal, Transparency = 1}):Play()
	Debris:AddItem(t, duracion + 0.1); return t
end

-- ☄️ MOTOR DE VFX UNICO: ARMAS A DOS MANOS 🪓
local function SpawnSkillEffect(skillData, posBaseCFrame)
	local c1 = skillData.ColorPrimario; local c2 = skillData.ColorSecundario

	if skillData.Nombre == "Avalanche" then
		-- Impacto masivo descendente
		crearTajoGeometrico(c1, posBaseCFrame, Vector3.new(1, 15, 3), Vector3.new(0.2, 25, 8), 0.4)
		local ground = crearTajoGeometrico(c2, posBaseCFrame * CFrame.new(0,-10,0) * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(2, 0.2, 2), Vector3.new(35, 0.2, 35), 0.5)
		ground.Shape = Enum.PartType.Cylinder
	elseif skillData.Nombre == "Cyclone" then
		-- Giro 360 naranja
		local gyro = crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(2, 2, 2), Vector3.new(40, 0.5, 40), 0.4)
		gyro.Shape = Enum.PartType.Cylinder; crearTajoGeometrico(c2, posBaseCFrame, Vector3.new(2,2,2), Vector3.new(20,20,20), 0.4).Shape = Enum.PartType.Ball
	elseif skillData.Nombre == "Back Rush" then
		-- Giro de barrido rojo
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(math.rad(90), math.rad(math.random(0,360)), 0), Vector3.new(1, 2, 2), Vector3.new(1, 35, 35), 0.4).Shape = Enum.PartType.Cylinder
	end
end

local function UseSwordSkill()
	if isUsingSkill or character:GetAttribute("IsAttacking") or character:GetAttribute("IsBlocking") then return end
	local skillData = HabilidadesData[character:GetAttribute("EquippedSkill") or "Avalanche"]
	if not skillData or skillData.Para ~= "Arma a Dos Manos" then return end

	local currentSP = character:GetAttribute("SP") or 100 
	if currentSP < skillData.CostoSP then return end
	character:SetAttribute("SP", currentSP - skillData.CostoSP); updateSPBar(currentSP - skillData.CostoSP) 

	local animObj = Tool:FindFirstChild(skillData.Animacion) or script:FindFirstChild(skillData.Animacion)
	if not animObj then return end
	local track = animator:LoadAnimation(animObj); track.Priority = Enum.AnimationPriority.Action4; track.Looped = false

	isUsingSkill = true; character:SetAttribute("IsAttacking", true)
	movementLock = RunService.RenderStepped:Connect(function() if humanoid then humanoid.WalkSpeed = 0; humanoid.JumpPower = 0 end end)

	track:Play(); task.wait(0.5); track:AdjustSpeed(0) 
	local worldFilter = Instance.new("ColorCorrectionEffect", Lighting); worldFilter.TintColor = skillData.ColorPrimario; worldFilter.Saturation = -0.6; worldFilter.Contrast = 0.3
	TweenService:Create(camera, TweenInfo.new(1.8, Enum.EasingStyle.Cubic), {FieldOfView = 55}):Play()

	task.wait(skillConfig.chargeTime) 

	worldFilter:Destroy(); TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 120}):Play()
	track:AdjustSpeed(0.3); applyCameraShake(0.8, 18) -- Tiembla fuerte

	if skillData.VelocidadDash ~= 0 then
		local bv = Instance.new("BodyVelocity", rootPart); bv.MaxForce = Vector3.new(1e6, 0, 1e6); bv.Velocity = rootPart.CFrame.LookVector * skillData.VelocidadDash; Debris:AddItem(bv, 0.5)
	end

	SpawnSkillEffect(skillData, rootPart.CFrame * CFrame.new(0, 0, -8))

	local hitEnemies = {}; local tickCounter = 0
	local dashConn = RunService.Heartbeat:Connect(function(dt)
		local params = OverlapParams.new(); params.FilterDescendantsInstances = {character}
		local parts = workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0,0,-4), Vector3.new(10,10,12), params) -- Hitbox mas grande
		for _, p in ipairs(parts) do
			local h = p.Parent:FindFirstChild("Humanoid")
			if h and not hitEnemies[h] then
				hitEnemies[h] = true; damageEvent:FireServer(h, p, p.Position, skillData.Dano)
				local impact = crearTajoGeometrico(skillData.ColorSecundario, p.CFrame, Vector3.new(3,3,3), Vector3.new(12,12,12), 0.3); impact.Shape = Enum.PartType.Ball
			end
		end
	end)

	task.wait(0.8); dashConn:Disconnect()
	humanoid.WalkSpeed = 16; humanoid.JumpPower = 50; character:SetAttribute("IsAttacking", false); track:Stop(0.3)
	TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = 70}):Play()
	task.wait(skillData.Cooldown); isUsingSkill = false; if movementLock then movementLock:Disconnect() end
end

Tool.Equipped:Connect(function()
	character = player.Character or player.CharacterAdded:Wait(); humanoid = character:WaitForChild("Humanoid"); rootPart = character:WaitForChild("HumanoidRootPart"); animator = humanoid:WaitForChild("Animator")
	if not character:GetAttribute("SP") then character:SetAttribute("SP", skillConfig.maxSP); updateSPBar(skillConfig.maxSP) end
end)
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and Tool.Parent == character and input.KeyCode == Enum.KeyCode.E then UseSwordSkill() end
end)
