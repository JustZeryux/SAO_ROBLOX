local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris") 
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator", 5) or Humanoid:WaitForChild("Animator")
local rootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera

-- ==========================================
-- ⚙️ CONFIGURACIÓN GENERAL
-- ==========================================
local NORMAL_SPEED = 16
local SPRINT_SPEED = 40
local NORMAL_FOV = 95
local SPRINT_FOV = 140 

local SLIDE_SPEED = 65  
local SLIDE_DURATION = 0.6  
local SLIDE_COOLDOWN = 1.2  

local isSliding = false
local canSlide = true
local isSprinting = false

-- ⏱️ VELOCIDADES DE ANIMACIÓN
local animSpeeds = {
	Idle = 1, Walking = 1, Run = 1.5, 
	Jump = 1, JumpRun = 1, Falling = 1,
	Slide = 1.2, Rolling = 1.45
}

-- ==========================================
-- 🏃 CARGA DE ANIMACIONES
-- ==========================================
local function loadAnimSeguro(animName, priority, looped)
	local animObject = script:WaitForChild(animName, 3)
	if not animObject then return nil end
	local track = Animator:LoadAnimation(animObject)
	track.Priority = priority; track.Looped = looped
	return track
end

local runTrack = loadAnimSeguro("Run", Enum.AnimationPriority.Movement, true)
local walkTrack = loadAnimSeguro("Walking", Enum.AnimationPriority.Movement, true)
local idleTrack = loadAnimSeguro("Idle", Enum.AnimationPriority.Idle, true)
local jumpTrack = loadAnimSeguro("Jump", Enum.AnimationPriority.Action, false)
local jumpRunTrack = loadAnimSeguro("JumpRun", Enum.AnimationPriority.Action, false)
local slideTrack = loadAnimSeguro("Slide", Enum.AnimationPriority.Action4, false)
local fallingTrack = loadAnimSeguro("Falling", Enum.AnimationPriority.Action, true)
local rollTrack = loadAnimSeguro("Rolling", Enum.AnimationPriority.Action4, false)

local function playTrack(track, speedName, fadeTime, forceRestart)
	if track then
		if forceRestart or not track.IsPlaying then
			-- Aumentamos el fadeTime por defecto a 0.25 para que Roblox mezcle mejor los huesos
			track:Play(fadeTime or 0.25) 
			track:AdjustSpeed(animSpeeds[speedName] or 1)
			if forceRestart then
				track.TimePosition = 0 -- Si spameas, reinicia la pose suavemente sin trabarse
			end
		end
	end
end

-- 🛑 FIX: Carga segura para evitar que la reversa falle si el juego tiene lag
local function playTrackBackward(track, speedName, fadeTime)
	if track and not track.IsPlaying then
		track:Play(fadeTime or 0.1, 1, 0) 
		task.spawn(function()
			-- Obligamos a esperar que Roblox registre la duración de la animación
			while track.Length == 0 do task.wait() end 
			track.TimePosition = track.Length * 0.99 
			track:AdjustSpeed(-(animSpeeds[speedName] or 1)) 
		end)
	end
end

if idleTrack then playTrack(idleTrack, "Idle", 0.2) end

-- ==========================================
-- 📐 PROCEDURAL MOVEMENT Y LEANING SUAVE
-- ==========================================
local lowerTorso = Character:FindFirstChild("LowerTorso")
local upperTorso = Character:FindFirstChild("UpperTorso")

if lowerTorso and upperTorso then
	local rootJoint = lowerTorso:WaitForChild("Root")
	local waist = upperTorso:WaitForChild("Waist")
	local originalRootC0 = rootJoint.C0; local originalWaistC0 = waist.C0
	local currentLeanAdelante = 0; local currentLeanLados = 0

	RunService.RenderStepped:Connect(function(deltaTime)
		if Humanoid.Health <= 0 then return end
		if Character:GetAttribute("ArmaEquipada") then return end

		if isSliding then 
			rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0, 15 * deltaTime)
			waist.C0 = waist.C0:Lerp(originalWaistC0, 15 * deltaTime)
			return 
		end

		local velocity = rootPart.AssemblyLinearVelocity.Magnitude
		local isMoving = velocity > 1 and Humanoid.FloorMaterial ~= Enum.Material.Air
		local currentTime = tick()
		local bobbingY = 0

		if isMoving then
			local bobSpeed = isSprinting and 16 or 10
			local bobIntensity = isSprinting and 0.08 or 0.04
			bobbingY = math.sin(currentTime * bobSpeed) * bobIntensity

			local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
			if walkTrack and walkTrack.IsPlaying and not isSprinting then
				if moveDirLocal.Z > 0.1 then walkTrack:AdjustSpeed(-animSpeeds.Walking) else walkTrack:AdjustSpeed(animSpeeds.Walking) end
			end

			local leanMulti = isSprinting and 1.2 or 0.6
			local targetLeanAdelante = math.rad(moveDirLocal.Z * 15 * leanMulti)
			local targetLeanLados = math.rad(-moveDirLocal.X * 12 * leanMulti)

			currentLeanAdelante = currentLeanAdelante + (targetLeanAdelante - currentLeanAdelante) * (10 * deltaTime)
			currentLeanLados = currentLeanLados + (targetLeanLados - currentLeanLados) * (10 * deltaTime)

			local targetRootC0 = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(currentLeanAdelante * 0.5, 0, currentLeanLados * 0.5)
			local targetWaistC0 = originalWaistC0 * CFrame.Angles(currentLeanAdelante * 0.5, 0, currentLeanLados * 0.5)

			rootJoint.C0 = rootJoint.C0:Lerp(targetRootC0, 15 * deltaTime)
			waist.C0 = waist.C0:Lerp(targetWaistC0, 15 * deltaTime)
		else
			bobbingY = math.sin(currentTime * 2.5) * 0.02
			currentLeanAdelante = 0; currentLeanLados = 0
			rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, bobbingY, 0), 8 * deltaTime)
			waist.C0 = waist.C0:Lerp(originalWaistC0, 8 * deltaTime)
		end
	end)
end

-- ==========================================
-- 🎥 CÁMARA FOV
-- ==========================================
local function tweenFOV(targetFOV)
	TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = targetFOV}):Play()
end

-- ==========================================
-- ☁️ DETECTAR ESTADOS DE AIRE (FIXED SMOOTH)
-- ==========================================
local AIR_TRANSITION_FADE = 0.35 

Humanoid.StateChanged:Connect(function(oldState, newState)
	-- Si está rodando, ignoramos por completo
	if isSliding then return end

	if newState == Enum.HumanoidStateType.Jumping then
		if fallingTrack and fallingTrack.IsPlaying then fallingTrack:Stop(0.2) end

		-- Le pasamos "true" al final para forzar el reinicio suave si spameas el salto
		if isSprinting then 
			playTrack(jumpRunTrack, "JumpRun", 0.2, true) 
		else 
			playTrack(jumpTrack, "Jump", 0.2, true) 
		end

	elseif newState == Enum.HumanoidStateType.Freefall then
		task.delay(0.15, function() -- Un poco más de delay para evitar que se active en desniveles pequeños
			if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and not isSliding then
				playTrack(fallingTrack, "Falling", AIR_TRANSITION_FADE)
			end
		end)

	elseif newState == Enum.HumanoidStateType.Landed then
		if jumpTrack and jumpTrack.IsPlaying then jumpTrack:Stop(0.25) end
		if jumpRunTrack and jumpRunTrack.IsPlaying then jumpRunTrack:Stop(0.25) end
		if fallingTrack and fallingTrack.IsPlaying then fallingTrack:Stop(0.25) end

		-- FIX: Reanudamos la animación de correr/caminar de inmediato al tocar el suelo
		-- (Esto evita que el personaje se deslice estático al aterrizar)
		local currentSpeed = rootPart.AssemblyLinearVelocity.Magnitude
		if currentSpeed > 1 then
			if isSprinting then
				playTrack(runTrack, "Run", 0.2)
			else
				playTrack(walkTrack, "Walking", 0.2)
			end
		else
			playTrack(idleTrack, "Idle", 0.2)
		end
	end
end)

-- ==========================================
-- ⚙️ LÓGICA DE EVASIÓN (DASH/ROLL)
-- ==========================================
local function EjecutarEvasion(isBackward)
	if not canSlide or isSliding then return end
	if Humanoid.MoveDirection.Magnitude == 0 or Humanoid.FloorMaterial == Enum.Material.Air then return end

	canSlide = false
	isSliding = true

	-- 🛑 FIX: Creamos un Atributo Global para callar a las espadas
	Character:SetAttribute("IsSliding", true)

	local slideForce = Instance.new("BodyVelocity")
	slideForce.MaxForce = Vector3.new(100000, 0, 100000)

	if isBackward then
		playTrackBackward(rollTrack, "Rolling", 0.1)
		slideForce.Velocity = rootPart.CFrame.LookVector * -SLIDE_SPEED
	else
		playTrack(slideTrack, "Slide", 0.1)
		slideForce.Velocity = rootPart.CFrame.LookVector * SLIDE_SPEED
	end

	slideForce.Parent = rootPart
	Debris:AddItem(slideForce, SLIDE_DURATION) 

	task.delay(SLIDE_DURATION, function()
		isSliding = false
		Character:SetAttribute("IsSliding", false) -- Apagamos el comunicador
		if slideTrack and slideTrack.IsPlaying then slideTrack:Stop(0.2) end
		if rollTrack and rollTrack.IsPlaying then rollTrack:Stop(0.2) end
		Humanoid.WalkSpeed = isSprinting and SPRINT_SPEED or NORMAL_SPEED
	end)

	task.delay(SLIDE_COOLDOWN, function()
		canSlide = true
	end)
end

-- ==========================================
-- ⌨️ INPUTS PC (SHIFT / C / G)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end 

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		if not isSliding then Humanoid.WalkSpeed = SPRINT_SPEED end
		tweenFOV(SPRINT_FOV)

		if Humanoid.MoveDirection.Magnitude > 0 and not isSliding then
			if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(0.3) end
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.3) end
			playTrack(runTrack, "Run", 0.3)
		end
	end

	if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
		local intentandoIrAtras = UserInputService:IsKeyDown(Enum.KeyCode.S)
		EjecutarEvasion(intentandoIrAtras)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		if not isSliding then Humanoid.WalkSpeed = NORMAL_SPEED end
		tweenFOV(NORMAL_FOV)

		if Humanoid.MoveDirection.Magnitude > 0 and not isSliding then
			if runTrack and runTrack.IsPlaying then runTrack:Stop(0.3) end
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.3) end
			playTrack(walkTrack, "Walking", 0.3)
		end
	end
end)

-- ==========================================
-- 🏃 CONTROL DE ANIMACIONES AL MOVERSE
-- ==========================================
Humanoid.Running:Connect(function(speed)
	if isSliding or Humanoid.FloorMaterial == Enum.Material.Air then return end 

	if speed > 0.1 then 
		if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.3) end

		if isSprinting then
			if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(0.3) end
			playTrack(runTrack, "Run", 0.3)
		else
			if runTrack and runTrack.IsPlaying then runTrack:Stop(0.3) end
			playTrack(walkTrack, "Walking", 0.3)
		end
	else 
		if runTrack and runTrack.IsPlaying then runTrack:Stop(0.3) end
		if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(0.3) end
		playTrack(idleTrack, "Idle", 0.3)
	end
end)

Humanoid.Died:Connect(function()
	isSprinting = false; isSliding = false
	tweenFOV(NORMAL_FOV)
end)

-- ==========================================
-- 📱 SOPORTE PARA CELULARES (BOTONES GUI)
-- ==========================================
local mobileGui = Player:WaitForChild("PlayerGui"):WaitForChild("MobileControls", 3)
if mobileGui then
	if not UserInputService.TouchEnabled then mobileGui.Enabled = false end
	local btnSprint = mobileGui:FindFirstChild("BtnSprint"); local btnDash = mobileGui:FindFirstChild("BtnDash"); local btnMenu = mobileGui:FindFirstChild("BtnMenu")

	if btnSprint then
		btnSprint.MouseButton1Click:Connect(function()
			isSprinting = not isSprinting 
			if isSprinting then
				btnSprint.BackgroundColor3 = Color3.fromRGB(100, 255, 100) 
				if not isSliding then Humanoid.WalkSpeed = SPRINT_SPEED end
				tweenFOV(SPRINT_FOV)
				if Humanoid.MoveDirection.Magnitude > 0 and not isSliding then
					if walkTrack and walkTrack.IsPlaying then walkTrack:Stop(0.3) end; if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.3) end; playTrack(runTrack, "Run", 0.3)
				end
			else
				btnSprint.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
				if not isSliding then Humanoid.WalkSpeed = NORMAL_SPEED end
				tweenFOV(NORMAL_FOV)
				if Humanoid.MoveDirection.Magnitude > 0 and not isSliding then
					if runTrack and runTrack.IsPlaying then runTrack:Stop(0.3) end; if idleTrack and idleTrack.IsPlaying then idleTrack:Stop(0.3) end; playTrack(walkTrack, "Walking", 0.3)
				end
			end
		end)
	end

	if btnDash then
		btnDash.MouseButton1Click:Connect(function()
			local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
			local intentandoIrAtras = moveDirLocal.Z > 0.1 
			EjecutarEvasion(intentandoIrAtras)
		end)
	end

	if btnMenu then
		btnMenu.MouseButton1Click:Connect(function()
			local toggle = Player:GetAttribute("MobileToggleMenu") or false
			Player:SetAttribute("MobileToggleMenu", not toggle)
		end)
	end
end
