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
-- ☄️ MOTOR DE VFX: APLASTAMIENTO DE MAZA
-- ==========================================
local function SpawnSkillEffect(skillData, posBaseCFrame)
	local c1 = skillData.ColorPrimario; local c2 = skillData.ColorSecundario

	if skillData.Nombre == "Sledge Hammer" then
		-- Onda sísmica en el suelo
		local sueloPos = posBaseCFrame * CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
		crearFormaPesada(Enum.PartType.Cylinder, c1, sueloPos, Vector3.new(1, 1, 1), Vector3.new(40, 0.5, 40), 0.5)
		task.delay(0.1, function() crearFormaPesada(Enum.PartType.Cylinder, c2, sueloPos, Vector3.new(1, 1, 1), Vector3.new(25, 0.5, 25), 0.4) end)

		-- Pilar de energía central
		crearFormaPesada(Enum.PartType.Cylinder, c1, posBaseCFrame, Vector3.new(5, 0.1, 5), Vector3.new(1, 40, 1), 0.4)
		applyCameraShake(0.8, 25) -- Super terremoto

	elseif skillData.Nombre == "Power Strike" then
		-- Golpe descendente en picada
		crearFormaPesada(Enum.PartType.Block, c1, posBaseCFrame * CFrame.Angles(math.rad(-45), 0, 0), Vector3.new(1, 15, 3), Vector3.new(0.5, 25, 6), 0.3)
		-- Mini cráter
		local sueloPos = posBaseCFrame * CFrame.new(0, -3, 3) * CFrame.Angles(math.rad(90), 0, 0)
		crearFormaPesada(Enum.PartType.Cylinder, c2, sueloPos, Vector3.new(2, 0.2, 2), Vector3.new(15, 0.2, 15), 0.4)
		applyCameraShake(0.4, 15)

	elseif skillData.Nombre == "Heart Strike" then
		-- Explosión concentrada tipo bomba en un punto
		crearFormaPesada(Enum.PartType.Ball, c1, posBaseCFrame, Vector3.new(2, 2, 2), Vector3.new(20, 20, 20), 0.5)
		local ring = crearFormaPesada(Enum.PartType.Cylinder, c2, posBaseCFrame * CFrame.Angles(math.rad(90), 0, 0), Vector3.new(1, 0.5, 1), Vector3.new(25, 0.5, 25), 0.4)
		applyCameraShake(0.6, 20)
	end
end

-- ==========================================
-- ⚔️ EJECUCIÓN DINÁMICA DE HABILIDAD (MAZA)
-- ==========================================
local function UseSwordSkill()
	if isUsingSkill or character:GetAttribute("IsAttacking") or character:GetAttribute("IsBlocking") then return end

	local equippedSkillID = character:GetAttribute("EquippedSkill") or "SledgeHammer"
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

	track:Play(); task.wait(0.3); track:AdjustSpeed(0) 

	local worldFilter = Instance.new("ColorCorrectionEffect", Lighting); worldFilter.TintColor = skillData.ColorPrimario; worldFilter.Saturation = -0.4; worldFilter.Contrast = 0.2
	tweenFOV(55, 1.0); applyCameraShake(1.0, 5) 

	spawnChargeImplosion(skillData.ColorSecundario) 

	local flash = Instance.new("ColorCorrectionEffect", Lighting); flash.Brightness = 1; TweenService:Create(flash, TweenInfo.new(0.2), {Brightness = 0}):Play(); Debris:AddItem(flash, 0.2)
	tweenFOV(90, 0.2); track:AdjustSpeed(0.6) -- Se siente pesado 

	-- Dash contundente
	if skillData.VelocidadDash ~= 0 then
		local bv = Instance.new("BodyVelocity", rootPart); bv.MaxForce = Vector3.new(1e6, 0, 1e6); bv.Velocity = rootPart.CFrame.LookVector * skillData.VelocidadDash; Debris:AddItem(bv, 0.3)
	end

	-- Lanza la geometría frente al jugador pero en el suelo
	local posEfecto = rootPart.CFrame * CFrame.new(0, 0, -5)
	SpawnSkillEffect(skillData, posEfecto)

	local hitEnemies = {}; local tickCounter = 0
	local dashConn = RunService.Heartbeat:Connect(function(dt)
		-- Hitbox de la Maza: Corto pero muy ancho (X=15) para atrapar a varios
		local params = OverlapParams.new(); params.FilterDescendantsInstances = {character}
		local parts = workspace:GetPartBoundsInBox(rootPart.CFrame * CFrame.new(0,0,-4), Vector3.new(15,8,8), params)

		for _, p in ipairs(parts) do
			local h = p.Parent:FindFirstChild("Humanoid")
			if h and not hitEnemies[h] then
				hitEnemies[h] = true
				damageEvent:FireServer(h, p, p.Position, skillData.Dano)

				-- Explosiones esféricas en los enemigos golpeados
				local impact = Instance.new("Part", workspace)
				impact.Shape = Enum.PartType.Ball; impact.Material = Enum.Material.Neon; impact.Color = skillData.ColorSecundario
				impact.Anchored = true; impact.CanCollide = false; impact.CFrame = p.CFrame; impact.Size = Vector3.new(3,3,3)
				TweenService:Create(impact, TweenInfo.new(0.4), {Size = Vector3.new(15,15,15), Transparency = 1}):Play()
				Debris:AddItem(impact, 0.5)
			end
		end
	end)

	task.wait(0.5); dashConn:Disconnect()

	track:AdjustSpeed(0); TweenService:Create(worldFilter, TweenInfo.new(1), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0, Contrast = 0}):Play()
	tweenFOV(70, 0.8); task.wait(0.6) 

	if movementLock then movementLock:Disconnect(); movementLock = nil end
	humanoid.WalkSpeed = 15; humanoid.JumpPower = 50
	Debris:AddItem(worldFilter, 1); character:SetAttribute("IsAttacking", false); track:Stop(0.3)

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
