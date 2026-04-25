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
local skillConfig = { maxSP = 100, chargeTime = 1.0, colorDark = Color3.fromRGB(30, 15, 0) }

-- ==========================================
-- 📊 INTEGRACIÓN DE HUD (SP BAR)
-- ==========================================
local function updateSPBar(newSP)
	local playerGui = player:FindFirstChild("PlayerGui"); if not playerGui then return end
	local saoHUD = playerGui:FindFirstChild("SAO_HologramSystem")
	if saoHUD and saoHUD:FindFirstChild("HUD_Container") and saoHUD.HUD_Container:FindFirstChild("SP_Bar") then
		local fill = saoHUD.HUD_Container.SP_Bar:FindFirstChild("Fill")
		local percentage = math.clamp(newSP / skillConfig.maxSP, 0, 1)
		if fill then TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percentage, 0, 1, 0)}):Play() end
	end
end

local function crearTajoGeometrico(color, posicionCFrame, sizeInicial, sizeFinal, duracion)
	local t = Instance.new("Part")
	t.Anchored = true; t.CanCollide = false; t.Material = Enum.Material.Neon; t.Color = color; t.CFrame = posicionCFrame; t.Size = sizeInicial; t.Parent = workspace
	TweenService:Create(t, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = sizeFinal, Transparency = 1}):Play()
	Debris:AddItem(t, duracion + 0.1); return t
end

-- ==========================================
-- 🎥 EFECTOS SÍSMICOS (CÁMARA MÁS AGRESIVA)
-- ==========================================
local function applyCameraShake(duration, intensity)
	local startTime = tick()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration or not isUsingSkill then connection:Disconnect() return end
		-- Tiembla mucho más duro en el eje Y (impacto al suelo)
		camera.CFrame = camera.CFrame * CFrame.new(Vector3.new(math.random(-5,5), math.random(-20,20), math.random(-5,5)) * (intensity / 300))
	end)
end

local function tweenFOV(targetFOV, duration)
	TweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {FieldOfView = targetFOV}):Play()
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

local function crearFormaPesada(forma, color, posicionCFrame, sizeInicial, sizeFinal, duracion)
	local obj = Instance.new("Part")
	obj.Shape = forma; obj.Anchored = true; obj.CanCollide = false; obj.Material = Enum.Material.Neon; obj.Color = color
	obj.CFrame = posicionCFrame; obj.Size = sizeInicial; obj.Parent = workspace
	TweenService:Create(obj, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = sizeFinal, Transparency = 1}):Play()
	Debris:AddItem(obj, duracion + 0.1); return obj
end

-- ==========================================
-- ☄️ MOTOR DE VFX: MAGIA DUAL WIELD (ACTUALIZADO)
-- ==========================================
local function SpawnSkillEffect(skillData, posBaseCFrame)
	local cRight = skillData.ColorPrimario
	local cLeft = skillData.ColorSecundario

	if skillData.Nombre == "Double Circular" then
		-- Estocada simultánea con dos espadas (2 cilindros perforantes rápidos)
		local spear1 = crearTajoGeometrico(cRight, posBaseCFrame * CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(0.5, 2, 0.5), Vector3.new(1.5, 25, 1.5), 0.3)
		spear1.Shape = Enum.PartType.Cylinder

		local spear2 = crearTajoGeometrico(cLeft, posBaseCFrame * CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(0.5, 2, 0.5), Vector3.new(1.5, 25, 1.5), 0.3)
		spear2.Shape = Enum.PartType.Cylinder
		applyCameraShake(0.3, 10)

	elseif skillData.Nombre == "Cross Block" then
		-- Una "X" defensiva gigante que se queda en el aire por un segundo
		crearTajoGeometrico(cRight, posBaseCFrame * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(1, 10, 1), Vector3.new(2, 15, 2), 1)
		crearTajoGeometrico(cLeft, posBaseCFrame * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(1, 10, 1), Vector3.new(2, 15, 2), 1)

	elseif skillData.Nombre == "Starburst Stream" then
		-- Lluvia de 16 golpes (Acelerando)
		applyCameraShake(1.5, 15)
		local delayTime = 0.12
		for i = 1, 16 do
			-- Acelera gradualmente reduciendo el tiempo entre golpes
			delayTime = math.clamp(delayTime - 0.005, 0.04, 0.12)
			task.delay(i * delayTime, function()
				if not rootPart then return end
				local colorTajo = (i % 2 == 0) and cRight or cLeft
				local anguloRandom = math.rad(math.random(-180, 180))
				local offsetRandom = CFrame.new(math.random(-4, 4), math.random(-3, 4), -5)

				crearTajoGeometrico(colorTajo, rootPart.CFrame * offsetRandom * CFrame.Angles(0, 0, anguloRandom), Vector3.new(0.2, 1, 1), Vector3.new(0.1, 22, 2.5), 0.2)
			end)
		end

	elseif skillData.Nombre == "The Eclipse" then
		-- 27 golpes a una velocidad absurda formando una esfera/eclipse
		applyCameraShake(2, 20)
		for i = 1, 27 do
			task.delay(i * 0.06, function()
				if not rootPart then return end
				local colorTajo = (i % 2 == 0) and cRight or cLeft
				local anguloX = math.rad(math.random(-180, 180))
				local anguloZ = math.rad(math.random(-180, 180))

				crearTajoGeometrico(colorTajo, rootPart.CFrame * CFrame.Angles(anguloX, 0, anguloZ) * CFrame.new(0,0,-6), Vector3.new(0.5, 2, 2), Vector3.new(0.1, 30, 4), 0.15)
			end)
		end
	end
end

-- ==========================================
-- ⚔️ EJECUCIÓN DINÁMICA DE HABILIDAD
-- ==========================================
local function UseSwordSkill()
	if isUsingSkill or character:GetAttribute("IsAttacking") or character:GetAttribute("IsBlocking") then return end

	local equippedSkillID = character:GetAttribute("EquippedSkill") or "StarburstStream"
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

	local worldFilter = Instance.new("ColorCorrectionEffect", Lighting); worldFilter.TintColor = skillData.ColorPrimario; worldFilter.Saturation = -0.5
	tweenFOV(55, skillConfig.chargeTime); applyCameraShake(skillConfig.chargeTime, 5) 

	spawnChargeImplosion(skillData.ColorSecundario) 

	local flash = Instance.new("ColorCorrectionEffect", Lighting); flash.Brightness = 1.5; TweenService:Create(flash, TweenInfo.new(0.15), {Brightness = 0}):Play(); Debris:AddItem(flash, 0.2)
	tweenFOV(110, 0.15); track:AdjustSpeed(1.5); applyCameraShake(0.6, 15) 

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 0, 1e6)
	bv.Velocity = rootPart.CFrame.LookVector * (skillData.VelocidadDash or 100)
	bv.Parent = rootPart

	local posEfecto = camera.CFrame * CFrame.new(0, 0, -6)
	SpawnSkillEffect(skillData, posEfecto)

	local hitEnemies = {}
	local tickCounter = 0

	-- Calculamos cuánto durará el dash dependiendo de la habilidad (Combos largos duran más)
	local dashDuration = 0.4
	if skillData.Nombre == "Starburst Stream" then dashDuration = 1.5 
	elseif skillData.Nombre == "The Eclipse" then dashDuration = 1.8 
	elseif skillData.Nombre == "Cross Block" then dashDuration = 0.1 end -- El bloqueo casi no avanza

	local dashConn = RunService.Heartbeat:Connect(function(dt)
		tickCounter = tickCounter + dt

		-- ✨ MAGIA DE MULTI-HITS: Si es un combo de muchos golpes, limpiamos el historial de enemigos golpeados cada 0.15s
		-- Esto permite que The Eclipse y Starburst Stream golpeen al mismo jefe 16 o 27 veces!
		if (skillData.Nombre == "Starburst Stream" or skillData.Nombre == "The Eclipse") and tickCounter > 0.15 then
			hitEnemies = {}
			tickCounter = 0
		end

		local params = OverlapParams.new(); params.FilterDescendantsInstances = {character}
		local parts = workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0,0,-5), Vector3.new(10, 8, 12), params)

		for _, p in ipairs(parts) do
			local h = p.Parent:FindFirstChild("Humanoid")
			-- En Cross Block no hacemos daño
			if h and not hitEnemies[h] and skillData.Nombre ~= "Cross Block" then
				hitEnemies[h] = true

				-- Calculamos el daño real. Si el ataque dice "380 de daño" y son 16 hits, cada hit hace daño fraccionado
				local multiHitDivider = 1
				if skillData.Nombre == "Starburst Stream" then multiHitDivider = 16
				elseif skillData.Nombre == "The Eclipse" then multiHitDivider = 27
				elseif skillData.Nombre == "Double Circular" then multiHitDivider = 2 end

				local finalDamage = skillData.Dano / multiHitDivider
				damageEvent:FireServer(h, p, p.Position, finalDamage)

				-- Impactos Duales Neón
				local impact = Instance.new("Part", workspace)
				impact.Shape = Enum.PartType.Ball; impact.Material = Enum.Material.Neon
				impact.Color = (math.random(1,2) == 1) and skillData.ColorPrimario or skillData.ColorSecundario
				impact.Anchored = true; impact.CanCollide = false; impact.CFrame = p.CFrame * CFrame.new(math.random(-1,1), math.random(-1,1), 0); impact.Size = Vector3.new(1,1,1)
				TweenService:Create(impact, TweenInfo.new(0.2), {Size = Vector3.new(6,6,6), Transparency = 1}):Play()
				Debris:AddItem(impact, 0.25)
			end
		end
	end)

	task.wait(dashDuration); dashConn:Disconnect(); bv:Destroy()

	track:AdjustSpeed(0); TweenService:Create(worldFilter, TweenInfo.new(0.8), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0}):Play()
	tweenFOV(70, 0.6); task.wait(0.4) 

	if movementLock then movementLock:Disconnect(); movementLock = nil end
	humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 
	Debris:AddItem(worldFilter, 1); character:SetAttribute("IsAttacking", false); track:Stop(0.2)

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
