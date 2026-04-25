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

-- Configuración rápida y agresiva (colores oscuros base para resaltar el neón)
local skillConfig = { 
	maxSP = 100, 
	chargeTime = 0.8, -- Carga mucho más rápida que el tanque (era 1.3)
	colorDark = Color3.fromRGB(15, 15, 25) -- Azul muy oscuro/negro
}

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
	sphere.Size = Vector3.new(35, 35, 35); sphere.CFrame = rootPart.CFrame; sphere.Parent = workspace
	TweenService:Create(sphere, TweenInfo.new(skillConfig.chargeTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Size = Vector3.new(1, 1, 1), Color = colorSecundario}):Play()
	local conn = RunService.RenderStepped:Connect(function() if sphere.Parent then sphere.CFrame = rootPart.CFrame end end)
	task.wait(skillConfig.chargeTime); conn:Disconnect(); sphere:Destroy()
end

local function crearTajoGeometrico(color, posicionCFrame, sizeInicial, sizeFinal, duracion)
	local tajo = Instance.new("Part")
	tajo.Anchored = true; tajo.CanCollide = false; tajo.Material = Enum.Material.Neon; tajo.Color = color
	tajo.CFrame = posicionCFrame; tajo.Size = sizeInicial; tajo.Parent = workspace
	TweenService:Create(tajo, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = sizeFinal, Transparency = 1}):Play()
	Debris:AddItem(tajo, duracion + 0.1); return tajo
end

-- ==========================================
-- ☄️ MOTOR DE VFX: MAGIA DUAL WIELD
-- ==========================================
local function SpawnSkillEffect(skillData, posBaseCFrame)
	-- Asumimos que C1 es el color de tu espada derecha (ej. Rojo) y C2 el de la izquierda (ej. Celeste)
	local cRight = skillData.ColorPrimario or Color3.fromRGB(255, 30, 30)
	local cLeft = skillData.ColorSecundario or Color3.fromRGB(30, 200, 255)

	if skillData.Nombre == "Cross Edge" then
		-- Una X perfecta y simultánea
		crearTajoGeometrico(cRight, posBaseCFrame * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(0.5, 2, 2), Vector3.new(0.2, 25, 4), 0.3)
		crearTajoGeometrico(cLeft, posBaseCFrame * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.5, 2, 2), Vector3.new(0.2, 25, 4), 0.3)
		applyCameraShake(0.3, 12)

	elseif skillData.Nombre == "Double Circular" then
		-- Dos tajos curvos horizontales que se cruzan
		crearTajoGeometrico(cRight, posBaseCFrame * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(-15)), Vector3.new(0.5, 2, 2), Vector3.new(0.2, 30, 3), 0.35)
		task.delay(0.1, function()
			crearTajoGeometrico(cLeft, posBaseCFrame * CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(15)), Vector3.new(0.5, 2, 2), Vector3.new(0.2, 30, 3), 0.35)
			applyCameraShake(0.3, 10)
		end)

	elseif skillData.Nombre == "Starburst Stream" then
		-- Ráfaga de tajos caóticos (Simulación de los 16 hits)
		applyCameraShake(1.5, 15)
		for i = 1, 8 do
			task.delay(i * 0.1, function()
				if not rootPart then return end
				local colorTajo = (i % 2 == 0) and cRight or cLeft
				local anguloRandom = math.rad(math.random(-80, 80))
				local offsetRandom = CFrame.new(math.random(-3, 3), math.random(-3, 3), -6)

				crearTajoGeometrico(colorTajo, rootPart.CFrame * offsetRandom * CFrame.Angles(0, 0, anguloRandom), Vector3.new(0.2, 1, 1), Vector3.new(0.1, 20, 2), 0.2)
			end)
		end
	end
end

-- ==========================================
-- ⚔️ EJECUCIÓN DINÁMICA DE HABILIDAD (AGRESIVO)
-- ==========================================
local function UseSwordSkill()
	if isUsingSkill or character:GetAttribute("IsAttacking") or character:GetAttribute("IsBlocking") then return end

	-- Si no hay habilidad equipada, usa Cross Edge por defecto
	local equippedSkillID = character:GetAttribute("EquippedSkill") or "CrossEdge"
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
	tweenFOV(110, 0.15); track:AdjustSpeed(1.5); applyCameraShake(0.6, 15) -- Animación mucho más rápida que el tanque

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 0, 1e6)
	-- Dash más explosivo y rápido
	bv.Velocity = rootPart.CFrame.LookVector * (skillData.VelocidadDash or 120)
	bv.Parent = rootPart

	-- Dispara los VFX al inicio del dash
	local posEfecto = camera.CFrame * CFrame.new(0, 0, -6)
	SpawnSkillEffect(skillData, posEfecto)

	local hitEnemies = {}; local tickCounter = 0
	local dashConn = RunService.Heartbeat:Connect(function(dt)
		-- Hitbox Ajustada para 2 espadas (Más larga hacia adelante, no tan ancha como el escudo)
		local params = OverlapParams.new(); params.FilterDescendantsInstances = {character}
		local parts = workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0,0,-5), Vector3.new(8, 6, 12), params)

		for _, p in ipairs(parts) do
			local h = p.Parent:FindFirstChild("Humanoid")
			if h and not hitEnemies[h] then
				hitEnemies[h] = true
				-- Mandamos el daño al servidor
				damageEvent:FireServer(h, p, p.Position, skillData.Dano)

				-- Impactos Duales (Ráfaga de chispas dobles en el enemigo)
				local impact1 = Instance.new("Part", workspace)
				impact1.Shape = Enum.PartType.Ball; impact1.Material = Enum.Material.Neon; impact1.Color = skillData.ColorPrimario or Color3.new(1,0,0)
				impact1.Anchored = true; impact1.CanCollide = false; impact1.CFrame = p.CFrame * CFrame.new(1, 0, 0); impact1.Size = Vector3.new(1,1,1)
				TweenService:Create(impact1, TweenInfo.new(0.25), {Size = Vector3.new(8,8,8), Transparency = 1}):Play()
				Debris:AddItem(impact1, 0.3)

				local impact2 = impact1:Clone()
				impact2.Color = skillData.ColorSecundario or Color3.new(0,0.8,1)
				impact2.CFrame = p.CFrame * CFrame.new(-1, 0, 0)
				impact2.Parent = workspace
				TweenService:Create(impact2, TweenInfo.new(0.25), {Size = Vector3.new(8,8,8), Transparency = 1}):Play()
				Debris:AddItem(impact2, 0.3)
			end
		end
	end)

	-- El dash dura un poco más si es Starburst Stream
	local dashDuration = (skillData.Nombre == "Starburst Stream") and 1.2 or 0.4
	task.wait(dashDuration); dashConn:Disconnect(); bv:Destroy()

	track:AdjustSpeed(0); TweenService:Create(worldFilter, TweenInfo.new(0.8), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0}):Play()
	tweenFOV(70, 0.6); task.wait(0.4) 

	if movementLock then movementLock:Disconnect(); movementLock = nil end
	humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 -- Regresa a velocidad base
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
