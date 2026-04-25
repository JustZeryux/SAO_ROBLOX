local Tool = script.Parent
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local character, humanoid, animator

local eventoDisparo = Tool:WaitForChild("DispararPua")

-- 🦴 PROCEDURAL
local rootPart, lowerTorso, upperTorso, rootJoint, waist
local originalRootC0, originalWaistC0
local renderConnection = nil

-- ⚙️ CONFIGURACIÓN ESTILO ARROJADIZA (Súper ágil, disparo instantáneo)
local config = {
	velocidadCaminar = 20,
	velocidadSprint = 45,
	cooldownM1 = 0.4, -- Puedes lanzar una púa cada 0.4 segundos
	reproduccion = { Idle = 1, Caminar = 1.2, Correr = 1.3, Lanzar = 1.5, Saltar = 1 }
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, canThrow = true }
local connections = {}

-- ==========================================
-- 🎬 CONTROL DE ANIMACIONES SUPERIOR
-- ==========================================
local function playAnim(name, fadeTime)
	if name == "Idle" then
		if tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end; if tracks["Correr"] then tracks["Correr"]:Stop(0.2) end
	elseif name == "Caminar" or name == "Correr" then
		if tracks["Idle"] then tracks["Idle"]:Stop(0.2) end; if name == "Caminar" and tracks["Correr"] then tracks["Correr"]:Stop(0.2) end; if name == "Correr" and tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end
	end
	local track = tracks[name]
	if track and not track.IsPlaying then track:Play(fadeTime or 0.1); track:AdjustSpeed(config.reproduccion[name] or 1) end
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
			else track.Priority = Enum.AnimationPriority.Action4; track.Looped = false end
			track.Name = item.Name; tracks[item.Name] = track
		end
	end
end

-- ==========================================
-- ⚙️ PROCEDURAL (APUNTADO CONSTANTE AL MOUSE)
-- ==========================================
local function updateProceduralTorso(deltaTime)
	if not rootJoint or not waist or not rootPart or humanoid.Health <= 0 then return end

	-- Un lanzador siempre está mirando hacia donde apunta para reaccionar rápido
	local camLook = camera.CFrame.LookVector
	local relativeDir = rootPart.CFrame:VectorToObjectSpace(camLook)
	local yaw = math.clamp(math.asin(relativeDir.X), -math.rad(50), math.rad(50))
	local pitch = math.clamp(math.asin(relativeDir.Y), -math.rad(50), math.rad(50))

	local state = humanoid:GetState()
	local enElSuelo = (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	if enElSuelo and isMoving then
		local bobSpeed = states.isSprinting and 18 or 12
		local bobbingY = math.sin(tick() * bobSpeed) * 0.04 
		local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)

		local leanMulti = states.isSprinting and 1.2 or 0.8 
		local leanAdelante = math.rad(moveDirLocal.Z * 10 * leanMulti)

		local tRoot = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(0, 0, 0) * CFrame.Angles(leanAdelante * 0.5, 0, 0)
		local tWaist = originalWaistC0 * CFrame.Angles(pitch, yaw, 0) * CFrame.Angles(leanAdelante * 0.5, 0, 0)

		rootJoint.C0 = rootJoint.C0:Lerp(tRoot, 15 * deltaTime)
		waist.C0 = waist.C0:Lerp(tWaist, 15 * deltaTime)
	else
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, (enElSuelo and math.sin(tick() * 2) * 0.02 or 0), 0), 12 * deltaTime)
		waist.C0 = waist.C0:Lerp(originalWaistC0 * CFrame.Angles(pitch, yaw, 0), 12 * deltaTime)
	end
end

-- ==========================================
-- 🔌 EVENTOS DE MOVIMIENTO
-- ==========================================
local function conectarEventosHumanoid()
	table.insert(connections, humanoid.Running:Connect(function(speed)
		if not states.isEquipped then return end
		local inAir = (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping)
		if inAir then return end
		states.isSprinting = (humanoid.WalkSpeed >= config.velocidadSprint - 2)
		if speed > 0.1 then 
			if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end
		else playAnim("Idle", 0.2) end
	end))
end

-- ==========================================
-- 🪃 DISPARO INSTANTÁNEO (M1)
-- ==========================================
Tool.Activated:Connect(function()
	if not states.isEquipped or not states.canThrow then return end
	states.canThrow = false

	if tracks["Lanzar"] then 
		tracks["Lanzar"]:Play(0.05) 
	end

	-- Potencia fija porque es un arma arrojadiza ligera
	local potencia = 120 
	eventoDisparo:FireServer(mouse.Hit.Position, potencia, nil) -- nil indica que es un ataque normal (M1)

	task.wait(config.cooldownM1)
	states.canThrow = true
end)

-- SETUP Y UN-EQUIP
Tool.Equipped:Connect(function()
	states.isEquipped = true; character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid"); rootPart = character:WaitForChild("HumanoidRootPart"); animator = humanoid:WaitForChild("Animator")
	lowerTorso = character:FindFirstChild("LowerTorso"); upperTorso = character:FindFirstChild("UpperTorso")
	if lowerTorso and upperTorso then rootJoint = lowerTorso:WaitForChild("Root"); waist = upperTorso:WaitForChild("Waist"); originalRootC0 = rootJoint.C0; originalWaistC0 = waist.C0 end

	loadAnimations(); conectarEventosHumanoid()
	if humanoid.MoveDirection.Magnitude < 0.1 then playAnim("Idle", 0.1) end
	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)
end)

Tool.Unequipped:Connect(function()
	states.isEquipped = false
	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end; if waist and originalWaistC0 then waist.C0 = originalWaistC0 end
	for _, t in pairs(tracks) do t:Stop() end; for _, c in ipairs(connections) do c:Disconnect() end; table.clear(connections)
end)
