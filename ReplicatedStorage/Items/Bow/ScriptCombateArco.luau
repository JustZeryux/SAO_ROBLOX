local Tool = script.Parent
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local character
local humanoid
local rootPart
local animator

local eventoDisparo = Tool:WaitForChild("DispararPua")

local lowerTorso, upperTorso, rootJoint, waist
local originalRootC0, originalWaistC0
local renderConnection = nil

local config = {
	velocidadCaminar = 16,
	velocidadSprint = 38,
	velocidadApuntar = 6,
	FOV_Normal = 70,
	FOV_Zoom = 40,
	TiempoMaxCarga = 1.5,
	PotenciaMin = 50,
	PotenciaMax = 300,
	reproduccion = { Idle = 1, Caminar = 1, Correr = 1.2, Charge = 1, Hold = 1, Shoot = 1, Equip = 1, Saltar = 1 }
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, isAiming = false }
local connections = {}
local tiempoInicioCarga = 0
local isUsingSkill = false

-- ==========================================
-- 🎨 ELEMENTOS DE UX Y OBJETOS FALSOS
-- ==========================================
local crosshairUI = nil
local fakeArrow = nil
local fakeBow = nil 
local trajectoryBeam = nil
local attStart = nil
local attEnd = nil

local function setupUX()
	local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	gui.Name = "ArcoCrosshair"

	crosshairUI = Instance.new("Frame", gui)
	crosshairUI.Size = UDim2.new(0, 6, 0, 6)
	crosshairUI.Position = UDim2.new(0.5, -3, 0.5, -3)
	crosshairUI.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	crosshairUI.BackgroundTransparency = 1 
	Instance.new("UICorner", crosshairUI).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", crosshairUI)
	stroke.Color = Color3.new(0,0,0); stroke.Thickness = 1; stroke.Transparency = 1

	attStart = Instance.new("Attachment", workspace.Terrain)
	attEnd = Instance.new("Attachment", workspace.Terrain)

	trajectoryBeam = Instance.new("Beam", workspace.Terrain)
	trajectoryBeam.Attachment0 = attStart
	trajectoryBeam.Attachment1 = attEnd
	trajectoryBeam.Width0 = 0.4 
	trajectoryBeam.Width1 = 0.1 
	trajectoryBeam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
	trajectoryBeam.LightEmission = 1
	trajectoryBeam.Transparency = NumberSequence.new(1) 
	trajectoryBeam.FaceCamera = true
	trajectoryBeam.Segments = 40 
	trajectoryBeam.Texture = ""
end

local function cleanUX()
	if crosshairUI and crosshairUI.Parent then crosshairUI.Parent:Destroy() end
	if trajectoryBeam then trajectoryBeam:Destroy() end
	if attStart then attStart:Destroy() end
	if attEnd then attEnd:Destroy() end
	if fakeArrow then fakeArrow:Destroy() end
end

-- ==========================================
-- 🎬 CONTROL DE ANIMACIONES
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

	local animFolder = ReplicatedStorage:WaitForChild("Animation")

	for _, item in ipairs(animFolder:GetChildren()) do
		if item:IsA("Animation") and item.AnimationId ~= "" then
			local track = animator:LoadAnimation(item)

			if item.Name == "Idle" then track.Priority = Enum.AnimationPriority.Action2; track.Looped = true
			elseif item.Name == "Caminar" or item.Name == "Correr" then track.Priority = Enum.AnimationPriority.Action3; track.Looped = true
			elseif item.Name == "Saltar" then track.Priority = Enum.AnimationPriority.Action3; track.Looped = false
			elseif item.Name == "Equip" then track.Priority = Enum.AnimationPriority.Action4; track.Looped = false
			elseif item.Name == "Charge" then track.Priority = Enum.AnimationPriority.Action4; track.Looped = false
			elseif item.Name == "Hold" then track.Priority = Enum.AnimationPriority.Action4; track.Looped = true
			elseif item.Name == "Shoot" then track.Priority = Enum.AnimationPriority.Action4; track.Looped = false
			end

			track.Name = item.Name; tracks[item.Name] = track
		end
	end
end

-- ==========================================
-- 🎯 PROCEDURAL (TRAYECTORIA Y MOVIMIENTO)
-- ==========================================
local function updateProceduralTorso(deltaTime)
	if not rootJoint or not rootPart or humanoid.Health <= 0 then return end

	-- 👁️ FIX PRIMERA PERSONA: Forzamos a Roblox a que no te vuelva invisible
	local partesVisibles = {
		fakeBow, fakeArrow,
		character:FindFirstChild("Right Arm"), character:FindFirstChild("Left Arm"),
		character:FindFirstChild("RightHand"), character:FindFirstChild("LeftHand"),
		character:FindFirstChild("RightLowerArm"), character:FindFirstChild("LeftLowerArm"),
		character:FindFirstChild("RightUpperArm"), character:FindFirstChild("LeftUpperArm")
	}

	for _, obj in pairs(partesVisibles) do
		if obj then
			if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end
			for _, child in pairs(obj:GetDescendants()) do
				if child:IsA("BasePart") then child.LocalTransparencyModifier = 0 end
			end
		end
	end

	if states.isAiming and not isUsingSkill then
		local camLook = camera.CFrame.LookVector
		local pitch = math.asin(math.clamp(camLook.Y, -1, 1))
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.Angles(0, 0, -pitch * 0.5), 15 * deltaTime)

		local tiempoCargado = tick() - tiempoInicioCarga
		local porcentajeCarga = math.clamp(tiempoCargado / config.TiempoMaxCarga, 0, 1)

		if crosshairUI then
			crosshairUI.BackgroundColor3 = Color3.fromRGB(255, 255 - (200 * porcentajeCarga), 255 - (255 * porcentajeCarga))
		end

		if trajectoryBeam then
			local origenPart = (fakeBow and (fakeBow:IsA("BasePart") and fakeBow or fakeBow:FindFirstChild("Handle"))) or character:FindFirstChild("Left Arm")
			local startPos = origenPart and origenPart.Position or rootPart.Position

			local rayOrigin = camera.CFrame.Position
			local rayDirection = camera.CFrame.LookVector * 500 
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {character, Tool, fakeArrow, fakeBow}

			local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
			local targetPos = rayResult and rayResult.Position or (rayOrigin + rayDirection)

			if (targetPos - startPos).Magnitude < 10 then targetPos = startPos + (camera.CFrame.LookVector * 50) end

			local distanciaReal = (targetPos - startPos).Magnitude
			if distanciaReal > 300 then
				targetPos = startPos + ((targetPos - startPos).Unit * 300)
				distanciaReal = 300
			end

			trajectoryBeam.Transparency = NumberSequence.new(0)
			local potenciaActual = config.PotenciaMin + ((config.PotenciaMax - config.PotenciaMin) * porcentajeCarga)
			local tiempoDeVuelo = distanciaReal / math.max(potenciaActual, 1) 
			local gravedad = workspace.Gravity
			local caidaFisica = 0.5 * gravedad * (tiempoDeVuelo ^ 2)
			local dropPosition = targetPos - Vector3.new(0, caidaFisica, 0)

			local baseCFrame = CFrame.lookAt(startPos, dropPosition, Vector3.new(0, 1, 0))

			attStart.WorldCFrame = baseCFrame
			attEnd.WorldCFrame = baseCFrame

			local alturaCurva = caidaFisica + (distanciaReal * 0.05)
			trajectoryBeam.CurveSize0 = alturaCurva 
			trajectoryBeam.CurveSize1 = alturaCurva 

			trajectoryBeam.Color = ColorSequence.new(Color3.fromRGB(0 + (255 * porcentajeCarga), 255 - (200 * porcentajeCarga), 255 - (255 * porcentajeCarga)))
		end
		return
	end

	local state = humanoid:GetState()
	local enElSuelo = (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	if enElSuelo and isMoving and not isUsingSkill then
		local bobSpeed = states.isSprinting and 15 or 10
		local bobbingY = math.sin(tick() * bobSpeed) * 0.05
		local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local leanMulti = states.isSprinting and 1.2 or 0.8
		local leanAdelante = math.rad(moveDirLocal.Z * 10 * leanMulti)
		local leanLados = math.rad(-moveDirLocal.X * 8 * leanMulti)
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, 0, -bobbingY) * CFrame.Angles(leanAdelante, leanLados, 0), 12 * deltaTime)
	else
		local bobbingIdle = enElSuelo and (math.sin(tick() * 2) * 0.02) or 0
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, 0, -bobbingIdle), 8 * deltaTime)
	end
end

local function conectarEventosHumanoid()
	table.insert(connections, humanoid.Running:Connect(function(speed)
		if not states.isEquipped or states.isAiming or isUsingSkill then return end
		local inAir = (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping)
		if inAir then return end
		states.isSprinting = (humanoid.WalkSpeed >= config.velocidadSprint - 2)
		if speed > 0.1 then if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end else playAnim("Idle", 0.2) end
	end))
end

-- ==========================================
-- 🏹 SISTEMA DE TIRO (M1 NORMAL)
-- ==========================================
Tool.Activated:Connect(function()
	if states.isAiming or not states.isEquipped or isUsingSkill then return end
	states.isAiming = true
	tiempoInicioCarga = tick()

	if crosshairUI then 
		TweenService:Create(crosshairUI, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
		TweenService:Create(crosshairUI.UIStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
	end
	if trajectoryBeam then trajectoryBeam.Transparency = NumberSequence.new(0.2) end

	-- 🔥 RIGGEO DE LA FLECHA (EN LA IZQUIERDA)
	local animFolder = ReplicatedStorage:FindFirstChild("Animation")
	if animFolder and animFolder:FindFirstChild("FlechaBase") then
		if fakeArrow then fakeArrow:Destroy() end
		fakeArrow = animFolder.FlechaBase:Clone()

		local piezaFlecha = fakeArrow:IsA("BasePart") and fakeArrow or fakeArrow:FindFirstChild("Handle")
		-- 🛠️ FIX: Espacio añadido en "Left Arm"
		local LeftArm = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")

		if LeftArm and piezaFlecha then
			local Joint = piezaFlecha:FindFirstChild("Joint") or fakeArrow:FindFirstChild("Joint", true)

			if Joint then
				-- 🛠️ FIX: Forzamos Part0 a ti, y Part1 a la flecha CLONADA
				Joint.Part0 = LeftArm
				Joint.Part1 = piezaFlecha
				Joint.Parent = LeftArm
			else
				warn("⚠️ No se encontró el 'Joint' dentro de la flecha.")
			end

			if fakeArrow:IsA("BasePart") then
				fakeArrow.CanCollide = false; fakeArrow.Massless = true; fakeArrow.Anchored = false
			end
			for _, parte in pairs(fakeArrow:GetDescendants()) do
				if parte:IsA("BasePart") then
					parte.CanCollide = false; parte.Massless = true; parte.Anchored = false
				end
			end

			fakeArrow.Parent = character
		end
	end

	TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {FieldOfView = config.FOV_Zoom}):Play()
	humanoid.WalkSpeed = config.velocidadApuntar

	-- 🎬 REPRODUCCIÓN LENTA Y CONGELAMIENTO (HOLD)
	if tracks["Charge"] then 
		local chargeTrack = playAnim("Charge", 0.1)
		chargeTrack:AdjustSpeed(0.5) -- Mitad de velocidad

		-- 🛠️ FIX: Congelar en el último frame sin que se rompa la lógica
		task.delay((chargeTrack.Length / 0.5) - 0.05, function()
			if states.isAiming and chargeTrack.IsPlaying then
				chargeTrack:AdjustSpeed(0)
				chargeTrack.TimePosition = chargeTrack.Length - 0.01 -- Clavarlo al final
			end
		end)
	end
end)

Tool.Deactivated:Connect(function()
	if not states.isAiming or isUsingSkill then return end
	states.isAiming = false

	local tiempoCargado = tick() - tiempoInicioCarga
	local porcentajeCarga = math.clamp(tiempoCargado / config.TiempoMaxCarga, 0, 1)
	local potenciaFinal = config.PotenciaMin + ((config.PotenciaMax - config.PotenciaMin) * porcentajeCarga)

	if trajectoryBeam then trajectoryBeam.Transparency = NumberSequence.new(1) end
	if crosshairUI then 
		TweenService:Create(crosshairUI, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		TweenService:Create(crosshairUI.UIStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
	end

	TweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {FieldOfView = config.FOV_Normal}):Play()
	humanoid.WalkSpeed = states.isSprinting and config.velocidadSprint or config.velocidadCaminar

	if tracks["Charge"] then tracks["Charge"]:Stop(0.1) end
	if tracks["Hold"] then tracks["Hold"]:Stop(0.1) end

	if tracks["Shoot"] then playAnim("Shoot", 0.05) end

	-- 🛠️ FIX: Ahora sí desaparece, aunque sea una sola pieza de Unión pura
	task.delay(0.25, function()
		if not states.isEquipped then return end
		if fakeArrow then
			-- Atacamos directamente a la pieza principal por si es una Union
			if fakeArrow:IsA("BasePart") then
				fakeArrow.Transparency = 1
			end
			-- Y atacamos a los hijos por si es un Modelo
			for _, part in pairs(fakeArrow:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		end

		-- Disparo (Respetando tu arquitectura Client-Server actual)
		eventoDisparo:FireServer(mouse.Hit.Position, potenciaFinal)
	end)

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

	mouse.TargetFilter = character 
	rootJoint = rootPart:FindFirstChild("RootJoint")
	if rootJoint then originalRootC0 = rootJoint.C0 end

	for _, part in pairs(Tool:GetChildren()) do
		if part:IsA("BasePart") then part.Transparency = 1 end
	end

	-- 🏹 RIGGEO DEL ARCO (EN LA DERECHA)
	local animFolder = ReplicatedStorage:FindFirstChild("Animation")
	if animFolder and animFolder:FindFirstChild("Bow") then
		if fakeBow then fakeBow:Destroy() end
		fakeBow = animFolder.Bow:Clone()

		local piezaArco = fakeBow:IsA("BasePart") and fakeBow or fakeBow:FindFirstChild("Handle")
		-- 🛠️ FIX: Espacio añadido en "Right Arm"
		local RightArm = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")

		if RightArm and piezaArco then
			local Joint = piezaArco:FindFirstChild("Joint") or fakeBow:FindFirstChild("Joint", true)

			if Joint then
				-- 🛠️ FIX: Forzamos Part0 a ti, y Part1 al arma CLONADA
				Joint.Part0 = RightArm
				Joint.Part1 = piezaArco 
				Joint.Parent = RightArm
			else
				warn("⚠️ No se encontró el 'Joint' dentro del arco clonado.")
			end

			if fakeBow:IsA("BasePart") then
				fakeBow.CanCollide = false; fakeBow.Massless = true; fakeBow.Anchored = false
			end
			for _, parte in pairs(fakeBow:GetDescendants()) do
				if parte:IsA("BasePart") then
					parte.CanCollide = false; parte.Massless = true; parte.Anchored = false
				end
			end

			fakeBow.Parent = character
		end
	end

	setupUX()
	loadAnimations(); conectarEventosHumanoid()

	if tracks["Equip"] then
		playAnim("Equip", 0.1)
		tracks["Equip"].Stopped:Connect(function()
			if humanoid.MoveDirection.Magnitude < 0.1 and not states.isAiming then playAnim("Idle", 0.2) end
		end)
	elseif humanoid.MoveDirection.Magnitude < 0.1 then 
		playAnim("Idle", 0.1) 
	end

	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)
end)

Tool.Unequipped:Connect(function()
	states.isEquipped = false; states.isAiming = false; isUsingSkill = false
	TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = config.FOV_Normal}):Play()
	if humanoid then humanoid.WalkSpeed = config.velocidadCaminar end

	cleanUX()
	if fakeBow then fakeBow:Destroy() end
	if fakeArrow then fakeArrow:Destroy() end

	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end

	for _, t in pairs(tracks) do t:Stop() end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
end)
