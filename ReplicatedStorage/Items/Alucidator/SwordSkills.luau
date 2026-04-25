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

-- ==========================================
-- ⚙️ CONFIGURACIÓN OVERDRIVE Y SP
-- ==========================================
local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))

local isUsingSkill = false
local movementLock = nil 
local skillConfig = { maxSP = 100, chargeTime = 1.5, colorDark = Color3.fromRGB(20, 20, 20) }

-- ==========================================
-- 📊 INTEGRACIÓN DE HUD (SP BAR)
-- ==========================================
local function updateSPBar(newSP)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local saoHUD = playerGui:FindFirstChild("SAO_HologramSystem")
	if saoHUD then
		local spBarContainer = saoHUD:FindFirstChild("HUD_Container") and saoHUD.HUD_Container:FindFirstChild("SP_Bar")
		if spBarContainer then
			local fill = spBarContainer:FindFirstChild("Fill")
			local textLabel = spBarContainer:FindFirstChild("SP_Bar")
			local percentage = math.clamp(newSP / skillConfig.maxSP, 0, 1)

			if fill then
				TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
			end
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = tostring(math.floor(newSP)) .. " / " .. tostring(skillConfig.maxSP)
			end
		end
	end
end

-- ==========================================
-- 🎥 EFECTOS DE CÁMARA Y PANTALLA
-- ==========================================
local function applyCameraShake(duration, intensity)
	local startTime = tick()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration or not isUsingSkill then connection:Disconnect() return end
		local offset = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10)) * (intensity / 300)
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	end)
end

local function tweenFOV(targetFOV, duration)
	TweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {FieldOfView = targetFOV}):Play()
end

local function applyScreenDistortion(color)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.TintColor = Color3.fromRGB(255, 255, 255)
	cc.Saturation = 0
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(1), {
		TintColor = color or Color3.fromRGB(150, 120, 255), Saturation = -0.4, Contrast = 0.2
	}):Play()
	return cc
end

local function flashScreen()
	local flash = Instance.new("ColorCorrectionEffect")
	flash.Brightness = 1
	flash.Parent = Lighting
	TweenService:Create(flash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play()
	Debris:AddItem(flash, 0.3)
end

local function spawnChargeImplosion(colorSecundario)
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball; sphere.Material = Enum.Material.ForceField
	sphere.Color = skillConfig.colorDark; sphere.Anchored = true; sphere.CanCollide = false
	sphere.Size = Vector3.new(30, 30, 30); sphere.CFrame = rootPart.CFrame; sphere.Parent = workspace

	local tween = TweenService:Create(sphere, TweenInfo.new(skillConfig.chargeTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
		Size = Vector3.new(1, 1, 1), Color = colorSecundario
	})
	tween:Play()

	local conn = RunService.RenderStepped:Connect(function()
		if sphere.Parent then sphere.CFrame = rootPart.CFrame end
	end)
	tween.Completed:Wait()
	conn:Disconnect(); sphere:Destroy()
end

local function spawnAfterimage(colorSecundario)
	character.Archivable = true
	local clone = character:Clone()
	for _, v in pairs(clone:GetDescendants()) do
		if v:IsA("Humanoid") or v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Sound") or v:IsA("Decal") then v:Destroy()
		elseif v:IsA("BasePart") or v:IsA("MeshPart") then
			v.Anchored = true; v.CanCollide = false; v.CanQuery = false; v.CanTouch = false
			v.Material = Enum.Material.ForceField; v.Color = colorSecundario; v.Transparency = 0.2
			TweenService:Create(v, TweenInfo.new(0.4), {Transparency = 1}):Play()
		end
	end
	clone.Parent = workspace; Debris:AddItem(clone, 0.4)
end

-- ==========================================
-- ☄️ MOTOR DE VFX: FORMAS GEOMÉTRICAS DE SAO
-- ==========================================
-- Función auxiliar para crear tajos limpios
local function crearTajoGeometrico(color, posicionCFrame, sizeInicial, sizeFinal, duracion)
	local tajo = Instance.new("Part")
	tajo.Anchored = true; tajo.CanCollide = false
	tajo.Material = Enum.Material.Neon
	tajo.Color = color
	tajo.CFrame = posicionCFrame
	tajo.Size = sizeInicial
	tajo.Parent = workspace

	TweenService:Create(tajo, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Size = sizeFinal, Transparency = 1
	}):Play()

	Debris:AddItem(tajo, duracion + 0.1)
	return tajo
end

local function SpawnSkillEffect(skillData, posBaseCFrame)
	local c1 = skillData.ColorPrimario
	local c2 = skillData.ColorSecundario

	-- 🔹 TAJOS SIMPLES 🔹
	if skillData.Nombre == "Slant" then
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(0.2, 2, 2), Vector3.new(0.05, 18, 5), 0.3)

	elseif skillData.Nombre == "Vertical" then
		crearTajoGeometrico(c1, posBaseCFrame, Vector3.new(0.2, 2, 2), Vector3.new(0.05, 20, 5), 0.3)

	elseif skillData.Nombre == "Horizontal" then
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.2, 2, 2), Vector3.new(0.05, 20, 5), 0.3)

	elseif skillData.Nombre == "Uppercut" then
		local tajo = crearTajoGeometrico(c1, posBaseCFrame, Vector3.new(0.2, 5, 2), Vector3.new(0.1, 15, 6), 0.3)
		-- Animamos hacia arriba simulando el gancho
		TweenService:Create(tajo, TweenInfo.new(0.3), {CFrame = tajo.CFrame * CFrame.new(0, 10, 0)}):Play()

	elseif skillData.Nombre == "Rage Spike" then
		-- Una estocada frontal cilíndrica tipo láser corto
		local spike = crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(1, 2, 1), Vector3.new(3, 25, 3), 0.4)
		spike.Shape = Enum.PartType.Cylinder

	elseif skillData.Nombre == "Sonic Leap" then
		-- Impacto masivo contra el suelo
		local shockwave = crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(2, 0.2, 2), Vector3.new(30, 0.2, 30), 0.5)
		shockwave.Shape = Enum.PartType.Cylinder
		crearTajoGeometrico(c2, posBaseCFrame, Vector3.new(0.5, 20, 5), Vector3.new(0.1, 25, 8), 0.4)

		-- 🔹 FORMAS GEOMÉTRICAS COMPLEJAS 🔹
	elseif skillData.Nombre == "Vertical Arc" then
		-- Una "V" en el aire
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 18, 4), 0.3)
		task.delay(0.15, function()
			crearTajoGeometrico(c2, posBaseCFrame * CFrame.Angles(0, 0, math.rad(35)), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 18, 4), 0.3)
		end)

	elseif skillData.Nombre == "Snake Bite" then
		-- Dos colmillos horizontales
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 15, 3), 0.3)
		task.delay(0.1, function()
			crearTajoGeometrico(c2, posBaseCFrame * CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 15, 3), 0.3)
		end)

	elseif skillData.Nombre == "Horizontal Square" then
		-- Dibuja un rombo (4 lados)
		local duracion = 0.3
		local sizeFinal = Vector3.new(0.1, 12, 2)
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.new(-4, 4, 0) * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(0.2, 2, 2), sizeFinal, duracion)
		task.delay(0.1, function() crearTajoGeometrico(c1, posBaseCFrame * CFrame.new(4, 4, 0) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.2, 2, 2), sizeFinal, duracion) end)
		task.delay(0.2, function() crearTajoGeometrico(c1, posBaseCFrame * CFrame.new(4, -4, 0) * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(0.2, 2, 2), sizeFinal, duracion) end)
		task.delay(0.3, function() crearTajoGeometrico(c2, posBaseCFrame * CFrame.new(-4, -4, 0) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.2, 2, 2), sizeFinal, duracion) end)

	elseif skillData.Nombre == "Savage Fulcrum" then
		-- Dibuja un "4" de hielo
		local duracion = 0.3
		local sizeFinal = Vector3.new(0.1, 14, 3)
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.new(-2, 2, 0) * CFrame.Angles(0, 0, math.rad(-30)), Vector3.new(0.2, 2, 2), sizeFinal, duracion)
		task.delay(0.15, function() crearTajoGeometrico(c1, posBaseCFrame * CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.2, 2, 2), sizeFinal, duracion) end)
		task.delay(0.3, function() crearTajoGeometrico(c2, posBaseCFrame * CFrame.new(2, 0, 0), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 18, 4), duracion) end)

		-- 🔹 HABILIDADES SUPREMAS 🔹
	elseif skillData.Nombre == "Vorpal Strike" then
		-- Láser penetrante extremo rojo sangre
		local laser = crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(1, 5, 1), Vector3.new(4, 100, 4), 0.6)
		laser.Shape = Enum.PartType.Cylinder
		applyCameraShake(0.6, 20) -- Tiembla mucho la cámara

	elseif skillData.Nombre == "Meteor Break" then
		-- Una ráfaga de explosiones seguidas de tajos
		for i = 1, 7 do
			task.delay((i-1)*0.1, function()
				local tajoCFrame = posBaseCFrame * CFrame.new(math.random(-5,5), math.random(-5,5), 0) * CFrame.Angles(0, 0, math.rad(math.random(-180, 180)))
				crearTajoGeometrico((i%2==0 and c1 or c2), tajoCFrame, Vector3.new(0.2, 5, 2), Vector3.new(0.1, 15, 4), 0.2)
			end)
		end

	elseif skillData.Nombre == "Nova Ascension" then
		-- 10 tajos radiantes tipo estrella
		for i = 1, 10 do
			task.delay((i-1)*0.08, function()
				local tajoCFrame = posBaseCFrame * CFrame.Angles(0, 0, math.rad(i * 36))
				crearTajoGeometrico((i%3==0 and c2 or c1), tajoCFrame, Vector3.new(0.5, 2, 2), Vector3.new(0.1, 30, 5), 0.3)
			end)
		end

		-- 🔹 DOBLE ESPADA Y GENÉRICOS 🔹
	elseif string.match(skillData.Nombre, "Double") or string.match(skillData.Nombre, "Cross") then
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 20, 5), 0.3)
		crearTajoGeometrico(c2, posBaseCFrame * CFrame.Angles(0, 0, math.rad(-45)), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 20, 5), 0.3)

	elseif string.match(skillData.Nombre, "Starburst") or string.match(skillData.Nombre, "Eclipse") then
		-- Lluvia masiva de tajos locos
		for i = 1, 16 do
			task.delay((i-1)*0.05, function()
				local tajoCFrame = posBaseCFrame * CFrame.new(math.random(-3,3), math.random(-3,3), math.random(-5, 0)) * CFrame.Angles(0, 0, math.rad(math.random(-180, 180)))
				crearTajoGeometrico((math.random(1,2)==1 and c1 or c2), tajoCFrame, Vector3.new(0.2, 5, 2), Vector3.new(0.1, 25, 4), 0.2)
			end)
		end
	else
		-- Fallback genérico
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(0, 0, math.rad(math.random(-30, 30))), Vector3.new(0.2, 2, 2), Vector3.new(0.1, 25, 5), 0.3)
	end
end

-- ==========================================
-- ⚔️ EJECUCIÓN DINÁMICA DE HABILIDAD
-- ==========================================
local function UseSwordSkill()
	if isUsingSkill or character:GetAttribute("IsAttacking") or character:GetAttribute("IsBlocking") then return end

	local equippedSkillID = character:GetAttribute("EquippedSkill") or "VorpalStrike" -- Cambia esto para probarlas
	local skillData = HabilidadesData[equippedSkillID]

	if not skillData then return end

	local currentSP = character:GetAttribute("SP") or 100 
	if currentSP < skillData.CostoSP then return end

	local nuevoSP = currentSP - skillData.CostoSP
	character:SetAttribute("SP", nuevoSP)
	updateSPBar(nuevoSP) 

	local animObj = Tool:FindFirstChild(skillData.Animacion) or script:FindFirstChild(skillData.Animacion)
	if not animObj then return end

	local track = animator:LoadAnimation(animObj)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false

	isUsingSkill = true
	character:SetAttribute("IsAttacking", true)

	movementLock = RunService.RenderStepped:Connect(function()
		if humanoid then humanoid.WalkSpeed = 0; humanoid.JumpPower = 0 end
	end)

	track:Play()
	task.wait(0.417)
	track:AdjustSpeed(0) 

	local worldFilter = applyScreenDistortion(skillData.ColorPrimario) 
	tweenFOV(60, 1.5) 
	applyCameraShake(1.5, 3) 

	spawnChargeImplosion(skillData.ColorSecundario) 
	task.wait(1.5) 

	flashScreen()
	tweenFOV(110, 0.2) 

	track:AdjustSpeed(0.35) 
	applyCameraShake(0.6, 10) 

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 0, 1e6)
	bv.Velocity = rootPart.CFrame.LookVector * skillData.VelocidadDash
	bv.Parent = rootPart

	-- 🔮 LA MAGIA VISUAL: Calculamos la posición frontal de la cámara y generamos la forma
	local posEfecto = camera.CFrame * CFrame.new(0, 0, -8)
	SpawnSkillEffect(skillData, posEfecto)

	local hitEnemies = {}
	local tickCounter = 0
	local dashConn = RunService.Heartbeat:Connect(function(dt)
		tickCounter = tickCounter + dt

		if (skillData.Nombre == "Starburst Stream" or skillData.Nombre == "The Eclipse") and tickCounter > 0.15 then
			hitEnemies = {}
			tickCounter = 0
		end

		local params = OverlapParams.new(); params.FilterDescendantsInstances = {character}
		local parts = workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0,0,-5), Vector3.new(10, 8, 12), params)

		for _, p in ipairs(parts) do
			local h = p.Parent:FindFirstChild("Humanoid")
			if h and not hitEnemies[h] and skillData.Nombre ~= "Cross Block" then
				hitEnemies[h] = true

				local multiHitDivider = 1
				if skillData.Nombre == "Starburst Stream" then multiHitDivider = 16
				elseif skillData.Nombre == "The Eclipse" then multiHitDivider = 27
				elseif skillData.Nombre == "Double Circular" then multiHitDivider = 2 end

				local finalDamage = skillData.Dano / multiHitDivider

				-- 🩸 AQUÍ VA EL SISTEMA DE DESMEMBRAMIENTO PARA LAS SKILLS
				if _G.RegisterHit then
					_G.RegisterHit(h, p, finalDamage)
				else
					-- Si el sistema falla, usamos tu evento original de daño como respaldo
					damageEvent:FireServer(h, p, p.Position, finalDamage)
				end

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

	task.wait(0.6)
	bv:Destroy()
	dashConn:Disconnect()

	track:AdjustSpeed(0) 
	applyCameraShake(0.4, 8) 

	TweenService:Create(worldFilter, TweenInfo.new(1), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0, Contrast = 0}):Play()
	tweenFOV(70, 1) 

	task.wait(0.6) 

	if movementLock then movementLock:Disconnect(); movementLock = nil end
	humanoid.WalkSpeed = 16 
	humanoid.JumpPower = 50
	Debris:AddItem(worldFilter, 1)
	character:SetAttribute("IsAttacking", false)
	track:Stop(0.3)

	task.wait(skillData.Cooldown)
	isUsingSkill = false
end

-- ==========================================
-- 🛠️ SETUP Y CONTROLES
-- ==========================================
local mobileSkillConnection = nil 

Tool.Equipped:Connect(function()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")

	if not character:GetAttribute("SP") then
		character:SetAttribute("SP", skillConfig.maxSP)
		updateSPBar(skillConfig.maxSP)
	end

	local playerGui = player:WaitForChild("PlayerGui")
	local mobileGui = playerGui:WaitForChild("MobileControls", 3)

	if mobileGui then
		local btnSkill = mobileGui:FindFirstChild("BtnSkill") 
		if btnSkill then
			mobileSkillConnection = btnSkill.Activated:Connect(function()
				UseSwordSkill()
			end)
		end
	end
end)

Tool.Unequipped:Connect(function()
	if movementLock then movementLock:Disconnect(); movementLock = nil end
	if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
	isUsingSkill = false
	if mobileSkillConnection then
		mobileSkillConnection:Disconnect()
		mobileSkillConnection = nil
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or not character then return end
	if Tool.Parent == character and input.KeyCode == Enum.KeyCode.E then
		UseSwordSkill()
	end
end)
