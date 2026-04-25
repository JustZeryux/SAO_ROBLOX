local Tool = script.Parent
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local animator = nil
local rootPart = nil
local camera = workspace.CurrentCamera

local damageEvent = Tool:WaitForChild("DamageEvent")
local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))

local isUsingSkill = false
local movementLock = nil 
-- Carga explosiva
local skillConfig = { maxSP = 100, chargeTime = 1.0, colorDark = Color3.fromRGB(0, 0, 50) }

local function updateSPBar(newSP)
	local playerGui = player:FindFirstChild("PlayerGui"); if not playerGui then return end
	local saoHUD = playerGui:FindFirstChild("SAO_HologramSystem")
	if saoHUD and saoHUD:FindFirstChild("HUD_Container") and saoHUD.HUD_Container:FindFirstChild("SP_Bar") then
		local fill = saoHUD.HUD_Container.SP_Bar:FindFirstChild("Fill")
		local percentage = math.clamp(newSP / skillConfig.maxSP, 0, 1)
		if fill then TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percentage, 0, 1, 0)}):Play() end
	end
end

local function applyCameraShake(duration, intensity)
	local startTime = tick()
	local connection; connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration or not isUsingSkill then connection:Disconnect() return end
		camera.CFrame = camera.CFrame * CFrame.new(Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10)) * (intensity / 300))
	end)
end

local function tweenFOV(targetFOV, duration)
	TweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {FieldOfView = targetFOV}):Play()
end

local function spawnChargeImplosion(colorSecundario)
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball; sphere.Material = Enum.Material.ForceField
	sphere.Color = skillConfig.colorDark; sphere.Anchored = true; sphere.CanCollide = false
	sphere.Size = Vector3.new(20, 20, 20); sphere.CFrame = rootPart.CFrame; sphere.Parent = workspace
	TweenService:Create(sphere, TweenInfo.new(skillConfig.chargeTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Size = Vector3.new(1, 1, 1), Color = colorSecundario}):Play()
	local conn = RunService.RenderStepped:Connect(function() if sphere.Parent then sphere.CFrame = rootPart.CFrame end end)
	task.wait(skillConfig.chargeTime); conn:Disconnect(); sphere:Destroy()
end

local function crearTajoGeometrico(forma, color, posicionCFrame, sizeInicial, sizeFinal, duracion)
	local tajo = Instance.new("Part")
	tajo.Shape = forma; tajo.Anchored = true; tajo.CanCollide = false; tajo.Material = Enum.Material.Neon; tajo.Color = color
	tajo.CFrame = posicionCFrame; tajo.Size = sizeInicial; tajo.Parent = workspace
	TweenService:Create(tajo, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = sizeFinal, Transparency = 1}):Play()
	Debris:AddItem(tajo, duracion + 0.1); return tajo
end

-- ==========================================
-- ☄️ MOTOR DE VFX: MAGIA DE ARTES MARCIALES
-- ==========================================
local function SpawnSkillEffect(skillData, posBaseCFrame)
	local c1 = skillData.ColorPrimario; local c2 = skillData.ColorSecundario

	if skillData.Nombre == "Embracer" then
		-- Una lanza de Ki (Energía) concentrada desde los dedos
		crearTajoGeometrico(Enum.PartType.Cylinder, c1, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(0.5, 2, 0.5), Vector3.new(3, 20, 3), 0.3)
		crearTajoGeometrico(Enum.PartType.Ball, c2, posBaseCFrame, Vector3.new(1,1,1), Vector3.new(12,12,12), 0.3)

	elseif skillData.Nombre == "Flash Flurry" then
		-- Simula docenas de puñetazos de viento
		for i = 1, 15 do
			task.delay((i-1)*0.03, function()
				local offset = CFrame.new(math.random(-3,3), math.random(-3,3), math.random(-3,0))
				crearTajoGeometrico(Enum.PartType.Ball, (i%2==0 and c1 or c2), posBaseCFrame * offset, Vector3.new(1,1,1), Vector3.new(5,5,5), 0.15)
			end)
		end

	elseif skillData.Nombre == "Meteor Fall" then
		-- Impacto masivo en el suelo
		local sueloPos = posBaseCFrame * CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
		crearTajoGeometrico(Enum.PartType.Cylinder, c1, sueloPos, Vector3.new(1, 1, 1), Vector3.new(35, 0.5, 35), 0.5)
		crearTajoGeometrico(Enum.PartType.Ball, c2, posBaseCFrame, Vector3.new(3,3,3), Vector3.new(20,20,20), 0.4)
		applyCameraShake(0.8, 20)
	end
end

-- ==========================================
-- ⚔️ EJECUCIÓN DINÁMICA DE HABILIDAD (ARTES MARCIALES)
-- ==========================================
local function UseSwordSkill()
	if isUsingSkill or character:GetAttribute("IsAttacking") or character:GetAttribute("IsBlocking") then return end

	local equippedSkillID = character:GetAttribute("EquippedSkill") or "Embracer"
	local skillData = HabilidadesData[equippedSkillID]
	if not skillData then return end

	local currentSP = character:GetAttribute("SP") or 100 
	if currentSP < skillData.CostoSP then return end

	character:SetAttribute("SP", currentSP - skillData.CostoSP)
	updateSPBar(currentSP - skillData.CostoSP)

	local animObj = Tool:FindFirstChild(skillData.Animacion) or script:FindFirstChild(skillData.Animacion)
	if not animObj then return end
	local track = animator:LoadAnimation(animObj)
	track.Priority = Enum.AnimationPriority.Action4; track.Looped = false

	isUsingSkill = true; character:SetAttribute("IsAttacking", true)
	movementLock = RunService.RenderStepped:Connect(function() if humanoid then humanoid.WalkSpeed = 0; humanoid.JumpPower = 0 end end)

	track:Play(); task.wait(0.2); track:AdjustSpeed(0) 

	local worldFilter = Instance.new("ColorCorrectionEffect", Lighting); worldFilter.TintColor = skillData.ColorPrimario; worldFilter.Saturation = -0.3
	tweenFOV(60, 1.0); applyCameraShake(1.0, 3) 

	spawnChargeImplosion(skillData.ColorSecundario) 

	local flash = Instance.new("ColorCorrectionEffect", Lighting); flash.Brightness = 1; TweenService:Create(flash, TweenInfo.new(0.2), {Brightness = 0}):Play(); Debris:AddItem(flash, 0.2)
	tweenFOV(100, 0.2); track:AdjustSpeed(0.5); applyCameraShake(0.5, 10) 

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 0, 1e6)
	bv.Velocity = rootPart.CFrame.LookVector * skillData.VelocidadDash
	bv.Parent = rootPart

	-- VFX (Pegado al cuerpo para Artes Marciales)
	local posEfecto = camera.CFrame * CFrame.new(0, 0, -4)
	SpawnSkillEffect(skillData, posEfecto)

	local hitEnemies = {}; local tickCounter = 0
	local dashConn = RunService.Heartbeat:Connect(function(dt)
		-- Hitbox CORTA
		local params = OverlapParams.new(); params.FilterDescendantsInstances = {character}
		local parts = workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0,0,-3), Vector3.new(6,6,6), params)

		for _, p in ipairs(parts) do
			local h = p.Parent:FindFirstChild("Humanoid")
			if h and not hitEnemies[h] then
				hitEnemies[h] = true
				damageEvent:FireServer(h, p, p.Position, skillData.Dano)

				-- Impactos de Ki
				local impact = Instance.new("Part", workspace)
				impact.Shape = Enum.PartType.Ball; impact.Material = Enum.Material.Neon; impact.Color = skillData.ColorSecundario
				impact.Anchored = true; impact.CanCollide = false; impact.CFrame = p.CFrame; impact.Size = Vector3.new(1,1,1)
				TweenService:Create(impact, TweenInfo.new(0.3), {Size = Vector3.new(10,10,10), Transparency = 1}):Play()
				Debris:AddItem(impact, 0.4)
			end
		end
	end)

	task.wait(0.4); dashConn:Disconnect(); bv:Destroy()

	track:AdjustSpeed(0); TweenService:Create(worldFilter, TweenInfo.new(0.5), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0}):Play()
	tweenFOV(70, 0.5); task.wait(0.4) 

	if movementLock then movementLock:Disconnect(); movementLock = nil end
	humanoid.WalkSpeed = config.velocidadCaminar; humanoid.JumpPower = 50
	Debris:AddItem(worldFilter, 0.5); character:SetAttribute("IsAttacking", false); track:Stop(0.3)

	task.wait(skillData.Cooldown)
	isUsingSkill = false
end

-- ==========================================
-- 🛠️ SETUP Y CONTROLES
-- ==========================================
local mobileSkillConnection = nil 

Tool.Equipped:Connect(function()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid"); rootPart = character:WaitForChild("HumanoidRootPart"); animator = humanoid:WaitForChild("Animator")
	if not character:GetAttribute("SP") then character:SetAttribute("SP", skillConfig.maxSP); updateSPBar(skillConfig.maxSP) end

	local playerGui = player:WaitForChild("PlayerGui"); local mobileGui = playerGui:WaitForChild("MobileControls", 3)
	if mobileGui then
		local btnSkill = mobileGui:FindFirstChild("BtnSkill") 
		if btnSkill then mobileSkillConnection = btnSkill.Activated:Connect(function() UseSwordSkill() end) end
	end
end)

Tool.Unequipped:Connect(function()
	if movementLock then movementLock:Disconnect(); movementLock = nil end
	if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
	isUsingSkill = false
	if mobileSkillConnection then mobileSkillConnection:Disconnect(); mobileSkillConnection = nil end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and Tool.Parent == character and input.KeyCode == Enum.KeyCode.E then UseSwordSkill() end
end)
