local Tool = script.Parent
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local character
local humanoid
local animator

-- 📡 EVENTO AL SERVIDOR
local eventoDisparo = Tool:WaitForChild("DispararFlecha")

-- 🦴 PROCEDURAL
local rootPart, lowerTorso, upperTorso, rootJoint, waist
local originalRootC0, originalWaistC0
local renderConnection = nil

-- ⚙️ CONFIGURACIÓN DEL ARCO
local config = {
	velocidadCaminar = 16,
	velocidadSprint = 38, -- Los arqueros son ágiles
	velocidadApuntar = 6, -- Caminas muy lento al tensar
	FOV_Normal = 70,
	FOV_Zoom = 40,        -- Zoom de francotirador/arquero
	TiempoMaxCarga = 1.5,
	PotenciaMin = 50,
	PotenciaMax = 300,    -- Flechas súper veloces si cargas al máximo
	reproduccion = { Idle = 1, Caminar = 1, Correr = 1.2, Tensar = 1, Saltar = 1 }
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, isAiming = false }
local connections = {}
local tiempoInicioCarga = 0

-- ==========================================
-- 🎬 CONTROL DE ANIMACIONES
-- ==========================================
local function playAnim(name, fadeTime)
	if name == "Idle" then
		if tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end
		if tracks["Correr"] then tracks["Correr"]:Stop(0.2) end
	elseif name == "Caminar" or name == "Correr" then
		if tracks["Idle"] then tracks["Idle"]:Stop(0.2) end
		if name == "Caminar" and tracks["Correr"] then tracks["Correr"]:Stop(0.2) end
		if name == "Correr" and tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end
	end

	local track = tracks[name]
	if track and not track.IsPlaying then
		track:Play(fadeTime or 0.1)
		track:AdjustSpeed(config.reproduccion[name] or 1)
	end
	return track
end

local function loadAnimations()
	if not animator then return end
	tracks = {}
	for _, item in ipairs(script:GetChildren()) do
		if item:IsA("Animation") and item.AnimationId ~= "" then
			local track = animator:LoadAnimation(item)
			if item.Name == "Idle" then track.Priority = Enum.AnimationPriority.Action2; track.Looped = true
			elseif item.Name == "Caminar" or item.Name == "Correr" then track.Priority = Enum.AnimationPriority.Action3; track.Looped = true
			elseif item.Name == "Saltar" then track.Priority = Enum.AnimationPriority.Action3; track.Looped = false
			elseif item.Name == "Tensar" then track.Priority = Enum.AnimationPriority.Action4; track.Looped = false end
			track.Name = item.Name; tracks[item.Name] = track
		end
	end
end

-- ==========================================
-- ⚙️ PROCEDURAL (APUNTADO DINÁMICO Y BOBBING)
-- ==========================================
local function updateProceduralTorso(deltaTime)
	if not rootJoint or not waist or not rootPart or humanoid.Health <= 0 then return end

	-- ✨ LA MAGIA DEL ARCO: Si estás apuntando, tu torso mira hacia la cámara
	if states.isAiming then
		local camLook = camera.CFrame.LookVector
		local charLook = rootPart.CFrame.LookVector

		-- Calcular cuánto debe girar la cintura arriba/abajo e izquierda/derecha
		local relativeDir = rootPart.CFrame:VectorToObjectSpace(camLook)
		local yaw = math.asin(relativeDir.X)
		local pitch = math.asin(relativeDir.Y)

		-- Limitar para que no se rompa la espalda (60 grados max)
		yaw = math.clamp(yaw, -math.rad(60), math.rad(60))
		pitch = math.clamp(pitch, -math.rad(60), math.rad(60))

		-- Aplicar rotación a la cintura (Apuntado en tiempo real)
		waist.C0 = waist.C0:Lerp(originalWaistC0 * CFrame.Angles(pitch, yaw, 0), 15 * deltaTime)
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0, 15 * deltaTime)
		return
	end

	-- Procedural Normal de Movimiento (Idéntico a las espadas)
	local state = humanoid:GetState()
	local enElSuelo = (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	local currentTime = tick()
	if enElSuelo and isMoving then
		local bobSpeed = states.isSprinting and 15 or 10
		local bobbingY = math.sin(currentTime * bobSpeed) * 0.05
		local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local giroPiernas = math.atan2(-moveDirLocal.X, -moveDirLocal.Z)

		local leanMulti = states.isSSprint and 1.2 or 0.8
		local leanAdelante = math.rad(moveDirLocal.Z * 10 * leanMulti)
		local leanLados = math.rad(-moveDirLocal.X * 8 * leanMulti)

		local tRoot = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(0, giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)
		local tWaist = originalWaistC0 * CFrame.Angles(0, -giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)

		rootJoint.C0 = rootJoint.C0:Lerp(tRoot, 12 * deltaTime)
		waist.C0 = waist.C0:Lerp(tWaist, 12 * deltaTime)
	else
		local bobbingY = enElSuelo and (math.sin(currentTime * 2) * 0.02) or 0
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, bobbingY, 0), 8 * deltaTime)
		waist.C0 = waist.C0:Lerp(originalWaistC0, 8 * deltaTime)
	end
end

-- ==========================================
-- 🔌 EVENTOS DE MOVIMIENTO
-- ==========================================
local function conectarEventosHumanoid()
	table.insert(connections, humanoid.Running:Connect(function(speed)
		if not states.isEquipped or states.isAiming then return end
		local inAir = (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping)
		if inAir then return end

		states.isSprinting = (humanoid.WalkSpeed >= config.velocidadSprint - 2)

		if speed > 0.1 then 
			if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end
		else 
			playAnim("Idle", 0.2)
		end
	end))

	table.insert(connections, humanoid.StateChanged:Connect(function(oldState, newState)
		if not states.isEquipped or states.isAiming then return end
		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			if tracks["Idle"] then tracks["Idle"]:Stop(0.1) end; if tracks["Caminar"] then tracks["Caminar"]:Stop(0.1) end; if tracks["Correr"] then tracks["Correr"]:Stop(0.1) end
			playAnim("Saltar", 0.1)
		elseif newState == Enum.HumanoidStateType.Landed then
			if tracks["Saltar"] then tracks["Saltar"]:Stop(0.15) end
			if humanoid.MoveDirection.Magnitude > 0.1 then if states.isSprinting then playAnim("Correr", 0.15) else playAnim("Caminar", 0.15) end else playAnim("Idle", 0.15) end
		end
	end))
end

-- ==========================================
-- 🏹 SISTEMA DE TIRO (Carga y Disparo)
-- ==========================================
Tool.Activated:Connect(function()
	if states.isAiming or not states.isEquipped then return end
	states.isAiming = true
	tiempoInicioCarga = tick()

	-- Zoom Dinámico
	TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {FieldOfView = config.FOV_Zoom}):Play()
	humanoid.WalkSpeed = config.velocidadApuntar

	-- Animación de Tensar (Se queda congelada al final hasta que sueltes)
	if tracks["Tensar"] then 
		tracks["Tensar"]:Play(0.1) 
		-- Opcional: Si tu animación no es de loop, usa track:AdjustSpeed(0) justo antes de que acabe
	end
end)

Tool.Deactivated:Connect(function()
	if not states.isAiming then return end
	states.isAiming = false

	local tiempoCargado = tick() - tiempoInicioCarga
	local porcentajeCarga = math.clamp(tiempoCargado / config.TiempoMaxCarga, 0, 1)
	local potenciaFinal = config.PotenciaMin + ((config.PotenciaMax - config.PotenciaMin) * porcentajeCarga)

	-- Disparar evento al Servidor
	eventoDisparo:FireServer(mouse.Hit.Position, potenciaFinal)

	-- Restaurar Estado
	TweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {FieldOfView = config.FOV_Normal}):Play()
	humanoid.WalkSpeed = states.isSprinting and config.velocidadSprint or config.velocidadCaminar

	if tracks["Tensar"] then tracks["Tensar"]:Stop(0.2) end

	-- Restaurar animación de movimiento
	if humanoid.MoveDirection.Magnitude > 0.1 then
		if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end
	else playAnim("Idle", 0.2) end
end)

-- ==========================================
-- 🔌 EQUIPAR / DESEQUIPAR
-- ==========================================
Tool.Equipped:Connect(function()
	states.isEquipped = true
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	rootPart = character:WaitForChild("HumanoidRootPart")

	lowerTorso = character:FindFirstChild("LowerTorso"); upperTorso = character:FindFirstChild("UpperTorso")
	if lowerTorso and upperTorso then
		rootJoint = lowerTorso:WaitForChild("Root"); waist = upperTorso:WaitForChild("Waist")
		originalRootC0 = rootJoint.C0; originalWaistC0 = waist.C0
	end

	loadAnimations(); conectarEventosHumanoid()
	if humanoid.MoveDirection.Magnitude < 0.1 then playAnim("Idle", 0.1) end
	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)
end)

Tool.Unequipped:Connect(function()
	states.isEquipped = false; states.isAiming = false
	TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = config.FOV_Normal}):Play()
	if humanoid then humanoid.WalkSpeed = config.velocidadCaminar end

	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end
	if waist and originalWaistC0 then waist.C0 = originalWaistC0 end

	for _, t in pairs(tracks) do t:Stop() end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
end)

-- Pon esto debajo de tu variables iniciales (requiere el módulo de habilidades)
local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))
local isUsingSkill = false

-- ==========================================
-- ☄️ SISTEMA DE HABILIDADES DEL ARCO
-- ==========================================
local function UseBowSkill()
	if states.isAiming or isUsingSkill or not states.isEquipped then return end

	local equippedSkillID = character:GetAttribute("EquippedSkill") or "StrikeNova"
	local skillData = HabilidadesData[equippedSkillID]
	if not skillData or skillData.Para ~= "Arco" then return end

	local currentSP = character:GetAttribute("SP") or 100 
	if currentSP < skillData.CostoSP then return end
	character:SetAttribute("SP", currentSP - skillData.CostoSP)

	isUsingSkill = true
	humanoid.WalkSpeed = 0 -- Se ancla para canalizar el tiro

	-- Efecto visual de carga del arco
	local worldFilter = Instance.new("ColorCorrectionEffect", workspace.CurrentCamera)
	worldFilter.TintColor = skillData.ColorPrimario
	worldFilter.Saturation = -0.3
	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {FieldOfView = 50}):Play()

	-- Animación de la habilidad
	local animObj = Tool:FindFirstChild(skillData.Animacion) or script:FindFirstChild(skillData.Animacion)
	if animObj then
		local track = animator:LoadAnimation(animObj)
		track.Priority = Enum.AnimationPriority.Action4
		track:Play()
	end

	-- Espera dramática para cargar poder
	task.wait(0.6) 

	-- Impulso Evasivo (Si la habilidad tiene Dash negativo, el arquero salta hacia atrás)
	if skillData.VelocidadDash ~= 0 then
		local bv = Instance.new("BodyVelocity", rootPart)
		bv.MaxForce = Vector3.new(1e6, 0, 1e6)
		bv.Velocity = rootPart.CFrame.LookVector * skillData.VelocidadDash -- Dash hacia atrás
		game:GetService("Debris"):AddItem(bv, 0.3)
	end

	-- 💥 DISPARO ESPECIAL AL SERVIDOR
	-- Modificamos el evento para enviarle al servidor qué habilidad usamos
	eventoDisparo:FireServer(mouse.Hit.Position, 350, equippedSkillID)

	-- Restaurar cámara y movimiento
	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.3), {FieldOfView = config.FOV_Normal}):Play()
	TweenService:Create(worldFilter, TweenInfo.new(0.5), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0}):Play()
	game:GetService("Debris"):AddItem(worldFilter, 0.6)

	humanoid.WalkSpeed = config.velocidadCaminar
	task.wait(skillData.Cooldown)
	isUsingSkill = false
end

-- Añade la detección de la tecla E al final de tu script local:
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and Tool.Parent == character and input.KeyCode == Enum.KeyCode.E then
		UseBowSkill()
	end
end)
