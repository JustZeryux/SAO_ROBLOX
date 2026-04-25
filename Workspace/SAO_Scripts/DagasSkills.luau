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
-- ⚙️ CONFIGURACIÓN OVERDRIVE Y SP (DAGA)
-- ==========================================
local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))

local isUsingSkill = false
local movementLock = nil 
-- ⚡ Carga híper rápida para el estilo Asesino
local skillConfig = { maxSP = 100, chargeTime = 0.8, colorDark = Color3.fromRGB(10, 30, 10) }

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

			if fill then TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percentage, 0, 1, 0)}):Play() end
			if textLabel and textLabel:IsA("TextLabel") then textLabel.Text = tostring(math.floor(newSP)) .. " / " .. tostring(skillConfig.maxSP) end
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
		camera.CFrame = camera.CFrame * CFrame.new(Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10)) * (intensity / 300))
	end)
end

local function tweenFOV(targetFOV, duration)
	TweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {FieldOfView = targetFOV}):Play()
end

local function applyScreenDistortion(color)
	local cc = Instance.new("ColorCorrectionEffect", Lighting)
	cc.TintColor = Color3.fromRGB(255, 255, 255); cc.Saturation = 0
	-- Dagas dan un efecto visual de "invisibilidad" o velocidad desaturada
	TweenService:Create(cc, TweenInfo.new(0.5), {TintColor = color or Color3.fromRGB(150, 255, 150), Saturation = -0.6, Contrast = 0.3}):Play()
	return cc
end

local function flashScreen()
	local flash = Instance.new("ColorCorrectionEffect", Lighting)
	flash.Brightness = 1
	TweenService:Create(flash, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0}):Play()
	Debris:AddItem(flash, 0.2)
end

local function spawnChargeImplosion(colorSecundario)
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball; sphere.Material = Enum.Material.ForceField
	sphere.Color = skillConfig.colorDark; sphere.Anchored = true; sphere.CanCollide = false
	sphere.Size = Vector3.new(20, 20, 20); sphere.CFrame = rootPart.CFrame; sphere.Parent = workspace

	local tween = TweenService:Create(sphere, TweenInfo.new(skillConfig.chargeTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
		Size = Vector3.new(0.5, 0.5, 0.5), Color = colorSecundario
	})
	tween:Play()

	local conn = RunService.RenderStepped:Connect(function() if sphere.Parent then sphere.CFrame = rootPart.CFrame end end)
	tween.Completed:Wait(); conn:Disconnect(); sphere:Destroy()
end

local function spawnAfterimage(colorSecundario)
	character.Archivable = true
	local clone = character:Clone()
	for _, v in pairs(clone:GetDescendants()) do
		if v:IsA("Humanoid") or v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Sound") or v:IsA("Decal") then v:Destroy()
		elseif v:IsA("BasePart") or v:IsA("MeshPart") then
			v.Anchored = true; v.CanCollide = false; v.CanQuery = false; v.CanTouch = false
			v.Material = Enum.Material.ForceField; v.Color = colorSecundario; v.Transparency = 0.3
			TweenService:Create(v, TweenInfo.new(0.3), {Transparency = 1}):Play()
		end
	end
	clone.Parent = workspace; Debris:AddItem(clone, 0.3)
end

-- ==========================================
-- ☄️ MOTOR DE VFX: FORMAS GEOMÉTRICAS DE DAGA
-- ==========================================
local function crearTajoGeometrico(color, posicionCFrame, sizeInicial, sizeFinal, duracion)
	local tajo = Instance.new("Part")
	tajo.Anchored = true; tajo.CanCollide = false; tajo.Material = Enum.Material.Neon; tajo.Color = color
	tajo.CFrame = posicionCFrame; tajo.Size = sizeInicial; tajo.Parent = workspace

	TweenService:Create(tajo, TweenInfo.new(duracion, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = sizeFinal, Transparency = 1}):Play()
	Debris:AddItem(tajo, duracion + 0.1)
	return tajo
end

local function SpawnSkillEffect(skillData, posBaseCFrame)
	local c1 = skillData.ColorPrimario
	local c2 = skillData.ColorSecundario

	if skillData.Nombre == "Fading Edge" then
		-- 4 Cortes en zigzag rapidísimos (Ilusión óptica)
		for i = 1, 4 do
			task.delay((i-1)*0.08, function()
				local angle = (i%2 == 0) and 45 or -45
				local offset = CFrame.new(math.random(-2,2), math.random(-2,2), 0)
				-- Los tajos de daga son finos (0.05 grosor)
				crearTajoGeometrico((i%2==0 and c1 or c2), posBaseCFrame * offset * CFrame.Angles(0, 0, math.rad(angle)), Vector3.new(0.1, 2, 1), Vector3.new(0.02, 15, 3), 0.2)
			end)
		end

	elseif skillData.Nombre == "Rapid Bite" then
		-- Dos estocadas colmillo paralelas
		local colmillo1 = crearTajoGeometrico(c1, posBaseCFrame * CFrame.new(-1, 0, 0) * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(0.2, 2, 0.2), Vector3.new(0.5, 12, 0.5), 0.2)
		local colmillo2 = crearTajoGeometrico(c2, posBaseCFrame * CFrame.new(1, 0, 0) * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(0.2, 2, 0.2), Vector3.new(0.5, 12, 0.5), 0.2)
		colmillo1.Shape = Enum.PartType.Cylinder; colmillo2.Shape = Enum.PartType.Cylinder

	elseif skillData.Nombre == "Armor Pierce" then
		-- Estocada súper fina y concentrada estilo aguja
		local aguja = crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(0.5, 5, 0.5), Vector3.new(0.1, 40, 0.1), 0.3)
		aguja.Shape = Enum.PartType.Cylinder
		-- Anillo de energía al romper la armadura
		local ring = crearTajoGeometrico(c2, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(0.2, 0.2, 0.2), Vector3.new(15, 0.2, 15), 0.3)
		ring.Shape = Enum.PartType.Cylinder
		applyCameraShake(0.3, 15)

	else
		-- Tajo básico hiperveloz
		crearTajoGeometrico(c1, posBaseCFrame * CFrame.Angles(0, 0, math.rad(math.random(-45, 45))), Vector3.new(0.1, 2, 1), Vector3.new(0.02, 18, 2), 0.2)
	end
end

-- ==========================================
-- ⚔️ EJECUCIÓN DINÁMICA DE HABILIDAD
-- ==========================================
local function UseSwordSkill()
	if isUsingSkill or character:GetAttribute("IsAttacking") or character:GetAttribute("IsBlocking") then return end

	local equippedSkillID = character:GetAttribute("EquippedSkill") or "FadingEdge"
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

	track:Play(0.1)
	task.wait(0.2) -- Mucho más rápido, casi instantáneo
	track:AdjustSpeed(0) 

	local worldFilter = applyScreenDistortion(skillData.ColorPrimario) 
	tweenFOV(55, 0.8) 
	applyCameraShake(0.8, 2) 

	spawnChargeImplosion(skillData.ColorSecundario) 
	task.wait(skillConfig.chargeTime) 

	flashScreen()
	tweenFOV(120, 0.1) -- Efecto túnel extremo de velocidad

	track:AdjustSpeed(0.5) 
	applyCameraShake(0.4, 12) 

	-- Dash ultra rápido
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 0, 1e6)
	bv.Velocity = rootPart.CFrame.LookVector * skillData.VelocidadDash
	bv.Parent = rootPart

	-- VFX de la habilidad generado frente al jugador
	local posEfecto = camera.CFrame * CFrame.new(0, 0, -4)
	SpawnSkillEffect(skillData, posEfecto)

	local hitEnemies = {}
	local tickCounter = 0
	local dashConn = RunService.Heartbeat:Connect(function(dt)
		tickCounter += dt
		if tickCounter >= 0.02 then -- Crea fantasmas (Afterimages) más rápido
			task.spawn(function() spawnAfterimage(skillData.ColorSecundario) end)
			tickCounter = 0
		end

		-- Hitbox más pequeño y cercano (rango de daga)
		local params = OverlapParams.new()
		params.FilterDescendantsInstances = {character}
		local parts = workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0,0,-3), Vector3.new(6,6,8), params)

		for _, p in ipairs(parts) do
			local h = p.Parent:FindFirstChild("Humanoid")
			if h and not hitEnemies[h] then
				hitEnemies[h] = true
				damageEvent:FireServer(h, p, p.Position, skillData.Dano)
				applyCameraShake(0.1, 10) 

				-- Chispa de impacto veloz
				local impact = Instance.new("Part", workspace)
				impact.Shape = Enum.PartType.Ball; impact.Material = Enum.Material.Neon
				impact.Color = skillData.ColorSecundario; impact.Anchored = true; impact.CanCollide = false
				impact.CFrame = p.CFrame
				impact.Size = Vector3.new(1,1,1)
				TweenService:Create(impact, TweenInfo.new(0.2, Enum.EasingStyle.Cubic), {Size = Vector3.new(8,8,8), Transparency = 1}):Play()
				Debris:AddItem(impact, 0.3)
			end
		end
	end)

	task.wait(0.3) -- El ataque termina muy rápido
	bv:Destroy()
	dashConn:Disconnect()

	track:AdjustSpeed(0) 

	TweenService:Create(worldFilter, TweenInfo.new(0.5), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0, Contrast = 0}):Play()
	tweenFOV(70, 0.5) 

	task.wait(0.3) 

	if movementLock then movementLock:Disconnect(); movementLock = nil end
	humanoid.WalkSpeed = 20 -- Regresa a velocidad de asesino
	humanoid.JumpPower = 50
	Debris:AddItem(worldFilter, 0.5)
	character:SetAttribute("IsAttacking", false)
	track:Stop(0.2)

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
