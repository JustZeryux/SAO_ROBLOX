local Tool = script.Parent
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local character
local humanoid
local animator

-- 📡 EVENTOS SAO
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local SyncBlockEvent = SAO_Events:WaitForChild("SyncBlock")

-- 🦴 PROCEDURAL
local rootPart, lowerTorso, upperTorso, rootJoint, waist
local originalRootC0, originalWaistC0
local renderConnection = nil

-- ⚙️ CONFIGURACIÓN ESTILO ARMA PESADA (Fuerza bruta, lenta pero devastadora)
local config = {
	velocidadCaminar = 14, -- Movimiento base más lento
	velocidadSprint = 32,  -- Sprint pesado
	ventanaParry = 0.35,   -- Ventana de parry más generosa por ser un bloque grande de metal
	reproduccion = {
		Idle = 0.9, Caminar = 0.9, Correr = 1.0,
		Slash = 0.75,              -- Tajos pesados y lentos
		AtaqueCaminando = 0.7, 
		AtaqueCorriendo = 0.6,     -- Impacto con mucha inercia
		AtaquesSaltando = 0.8, 
		Bloqueo = 1, Parry = 1.2,  -- Desvío tosco y fuerte
		Contraataque = 0.8, Saltar = 0.9
	}
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, isBlocking = false }
local connections = {}
local slashTrail = nil

-- ==========================================
-- ✨ TRAIL Y VFX (Fuego Tierra / Naranja Pesado)
-- ==========================================
local function setupTrail()
	local handle = Tool:WaitForChild("Handle")
	if handle:FindFirstChild("SlashTrail") then slashTrail = handle.SlashTrail return end

	-- Armas pesadas dejan estelas anchas
	local att0 = Instance.new("Attachment", handle); att0.Name = "TrailStart"; att0.Position = Vector3.new(0, -1.5, 0)
	local att1 = Instance.new("Attachment", handle); att1.Name = "TrailEnd"; att1.Position = Vector3.new(0, 4, 0)

	local trail = Instance.new("Trail", handle)
	trail.Name = "SlashTrail"; trail.Attachment0 = att0; trail.Attachment1 = att1
	trail.Lifetime = 0.25 -- El arco de luz dura más en el aire por la fuerza del golpe
	trail.MinLength = 0.1
	-- Color estilo Agil (Naranja forja / Tierra)
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 20)) 
	trail.LightEmission = 0.8
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	trail.Enabled = false
	slashTrail = trail
end

local function DispararVFX(nombreVFX)
	local contenedor = Tool:FindFirstChild(nombreVFX, true) or character:FindFirstChild(nombreVFX, true)
	if contenedor then
		for _, particula in pairs(contenedor:GetDescendants()) do
			if particula:IsA("ParticleEmitter") then
				local cantidad = particula:GetAttribute("EmitCount") or 15
				particula:Emit(cantidad)
			end
		end
	end
end

-- ==========================================
-- 🎬 CONTROL DE ANIMACIONES SUPERIOR
-- ==========================================
local function detenerAnimacionesAjenas()
	if not animator then return end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		local name = track.Name:lower()
		if name == "slide" or name == "rolling" then continue end

		local esNuestra = false
		for _, myTrack in pairs(tracks) do
			if track == myTrack then esNuestra = true; break end
		end
		if not esNuestra then track:Stop(0.1) end
	end
end

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

			if item.Name == "Idle" then
				track.Priority = Enum.AnimationPriority.Action2 
				track.Looped = true
			elseif item.Name == "Caminar" or item.Name == "Correr" then
				track.Priority = Enum.AnimationPriority.Action3 
				track.Looped = true
			elseif item.Name == "Saltar" then
				track.Priority = Enum.AnimationPriority.Action3 
				track.Looped = false
			else
				track.Priority = Enum.AnimationPriority.Action4 
				track.Looped = false 
			end

			track:GetMarkerReachedSignal("EmitirVFX"):Connect(function(vfxName) DispararVFX(vfxName) end)
			track:GetMarkerReachedSignal("TrailOn"):Connect(function() if slashTrail then slashTrail.Enabled = true end end)
			track:GetMarkerReachedSignal("TrailOff"):Connect(function() if slashTrail then slashTrail.Enabled = false end end)

			track.Name = item.Name
			tracks[item.Name] = track
		end
	end
end

-- ==========================================
-- 🛡️ DEFENSA (Muro Inamovible)
-- ==========================================
local function EmpezarBloqueo()
	if not states.isEquipped or character:GetAttribute("IsAttacking") or states.isBlocking then return end
	states.isBlocking = true
	character:SetAttribute("IsBlocking", true)
	character:SetAttribute("IsParrying", true) 

	SyncBlockEvent:FireServer(true, true)
	playAnim("Bloqueo", 0.1)
	humanoid.WalkSpeed = 6 -- Te vuelves súper lento, un verdadero tanque

	task.delay(config.ventanaParry, function()
		if character and states.isBlocking then
			character:SetAttribute("IsParrying", false)
			SyncBlockEvent:FireServer(true, false)
		end
	end)
end

local function TerminarBloqueo()
	if not states.isBlocking then return end
	states.isBlocking = false
	if character then
		character:SetAttribute("IsBlocking", false)
		character:SetAttribute("IsParrying", false)
		SyncBlockEvent:FireServer(false, false)
	end
	if tracks["Bloqueo"] then tracks["Bloqueo"]:Stop(0.2) end
	humanoid.WalkSpeed = states.isSprinting and config.velocidadSprint or config.velocidadCaminar 
end

-- ==========================================
-- ⚙️ PROCEDURAL (POSTURA PESADA)
-- ==========================================
local function updateProceduralTorso(deltaTime)
	if not rootJoint or not waist or not rootPart or humanoid.Health <= 0 then return end
	local isAttacking = character:GetAttribute("IsAttacking")

	if isAttacking then
		-- El arma jala el torso, la recuperación es lenta
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0, 8 * deltaTime) 
		waist.C0 = waist.C0:Lerp(originalWaistC0, 8 * deltaTime)
		return
	end

	local state = humanoid:GetState()
	local enElSuelo = (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	local currentTime = tick()
	if enElSuelo and isMoving then
		-- Rebote más lento pero más profundo
		local bobSpeed = states.isSprinting and 12 or 8
		local bobbingY = math.sin(currentTime * bobSpeed) * 0.06 
		local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local giroPiernas = math.atan2(-moveDirLocal.X, -moveDirLocal.Z)

		-- Inclinación rígida
		local leanMulti = states.isSprinting and 1.2 or 0.6 
		local leanAdelante = math.rad(moveDirLocal.Z * 15 * leanMulti)
		local leanLados = math.rad(-moveDirLocal.X * 10 * leanMulti)

		local tRoot = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(0, giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)
		local tWaist = originalWaistC0 * CFrame.Angles(0, -giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)

		-- Interpolación pesada y lenta
		rootJoint.C0 = rootJoint.C0:Lerp(tRoot, 10 * deltaTime)
		waist.C0 = waist.C0:Lerp(tWaist, 10 * deltaTime)
	else
		local bobbingY = enElSuelo and (math.sin(currentTime * 2) * 0.02) or 0
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, bobbingY, 0), 6 * deltaTime)
		waist.C0 = waist.C0:Lerp(originalWaistC0, 6 * deltaTime)
	end
end

-- ==========================================
-- 🔌 EVENTOS DE MOVIMIENTO
-- ==========================================
local function conectarEventosHumanoid()
	table.insert(connections, humanoid.Running:Connect(function(speed)
		if not states.isEquipped or character:GetAttribute("IsAttacking") then return end
		local inAir = (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping)
		if inAir then return end

		states.isSprinting = (humanoid.WalkSpeed >= config.velocidadSprint - 2) and not states.isBlocking

		if speed > 0.1 then 
			if states.isSprinting then
				playAnim("Correr", 0.2)
			else
				local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
				local dir = (moveDirLocal.Z > 0.1) and -1 or 1
				local track = playAnim("Caminar", 0.2)
				if track then track:AdjustSpeed(config.reproduccion["Caminar"] * dir) end
			end
		else 
			playAnim("Idle", 0.2)
		end
	end))

	table.insert(connections, humanoid.StateChanged:Connect(function(oldState, newState)
		if not states.isEquipped then return end

		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			if tracks["Idle"] then tracks["Idle"]:Stop(0.1) end
			if tracks["Caminar"] then tracks["Caminar"]:Stop(0.1) end
			if tracks["Correr"] then tracks["Correr"]:Stop(0.1) end
			playAnim("Saltar", 0.1)
		elseif newState == Enum.HumanoidStateType.Landed then
			if tracks["Saltar"] then tracks["Saltar"]:Stop(0.15) end
			if humanoid.MoveDirection.Magnitude > 0.1 then
				if states.isSprinting then playAnim("Correr", 0.15) else playAnim("Caminar", 0.15) end
			else
				playAnim("Idle", 0.15)
			end
		end
	end))
end

-- ==========================================
-- ⚔️ COMBATE (GOLPES DEVASTADORES)
-- ==========================================
Tool.Activated:Connect(function()
	if not states.isEquipped or character:GetAttribute("IsAttacking") then return end

	local isCountering = false
	if states.isBlocking then
		if character:GetAttribute("CanCounterattack") then
			isCountering = true; TerminarBloqueo(); character:SetAttribute("CanCounterattack", false) 
		else return end
	end

	character:SetAttribute("IsAttacking", true)

	local state = humanoid:GetState()
	local isMidAir = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	local attackName = "Slash"

	if isCountering and tracks["Contraataque"] then
		attackName = "Contraataque"
	elseif isMidAir and tracks["AtaquesSaltando"] then
		attackName = "AtaquesSaltando"
	elseif isMoving and states.isSprinting and tracks["AtaqueCorriendo"] then
		attackName = "AtaqueCorriendo"
	elseif isMoving and tracks["AtaqueCaminando"] then
		attackName = "AtaqueCaminando"
	end

	local trackToPlay = tracks[attackName] or tracks["Slash"]
	if trackToPlay then
		detenerAnimacionesAjenas()

		if isMidAir and tracks["Saltar"] then
			tracks["Saltar"]:Stop(0.1)
		end

		playAnim(trackToPlay.Name, 0.1)

		if slashTrail then 
			slashTrail.Enabled = true 
			task.delay(0.4, function() if slashTrail then slashTrail.Enabled = false end end)
		end

		-- ==========================================
		-- ✨ IMPACTO PESADO (VFX)
		-- ==========================================
		pcall(function()
			local vfxContenedorOriginal = Tool:FindFirstChild("Slash", true)
			if vfxContenedorOriginal and rootPart then
				local vfxClon = vfxContenedorOriginal:Clone()
				vfxClon.Parent = rootPart 

				if vfxClon:IsA("Attachment") then
					-- El arco de un hacha/espadón es más amplio y pesado
					vfxClon.Position = Vector3.new(0, 0, -3.5) 
				end

				for _, particula in pairs(vfxClon:GetDescendants()) do
					if particula:IsA("ParticleEmitter") then
						particula.EmissionDirection = Enum.NormalId.Front
						particula.LockedToPart = true 
						local cantidad = particula:GetAttribute("EmitCount") or 25 -- Más partículas por el impacto
						particula:Emit(cantidad)
					end
				end
				game:GetService("Debris"):AddItem(vfxClon, 1)
			end
		end)

		-- Recuperación larga por el peso del arma
		task.wait(trackToPlay.Length - 0.1)
	end

	character:SetAttribute("IsAttacking", false)

	if states.isEquipped then
		if isMidAir then
			playAnim("Saltar", 0.2)
		elseif humanoid.MoveDirection.Magnitude > 0.1 then
			if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end
		else
			playAnim("Idle", 0.2)
		end
	end
end)

-- ==========================================
-- 💥 DETECCIÓN DE GOLPES (DEBOUNCE LENTO)
-- ==========================================
local hitDebounce = false
local handle = Tool:WaitForChild("Handle")

handle.Touched:Connect(function(hit)
	if not states.isEquipped or not character:GetAttribute("IsAttacking") then return end
	if hitDebounce then return end
	if hit:IsDescendantOf(character) then return end

	local enemigo = hit.Parent:FindFirstChild("Humanoid")
	if enemigo then
		hitDebounce = true

		local hitOriginal = Tool:FindFirstChild("Hit", true)
		if hitOriginal and hitOriginal:IsA("Attachment") then
			local hitClon = hitOriginal:Clone()
			hitClon.Parent = workspace.Terrain 
			hitClon.WorldPosition = handle.Position 

			for _, particula in pairs(hitClon:GetChildren()) do
				if particula:IsA("ParticleEmitter") then
					local cantidad = particula:GetAttribute("EmitCount") or 20
					particula:Emit(cantidad)
				end
			end

			Debris:AddItem(hitClon, 2)
		end

		-- ✨ LA MAGIA: Hit debounce LENTO (0.5s). Los golpes son pesados, no se spamean.
		task.delay(0.5, function() 
			hitDebounce = false
		end)
	end
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

	character:SetAttribute("ArmaEquipada", true)

	lowerTorso = character:FindFirstChild("LowerTorso"); upperTorso = character:FindFirstChild("UpperTorso")
	if lowerTorso and upperTorso then
		rootJoint = lowerTorso:WaitForChild("Root"); waist = upperTorso:WaitForChild("Waist")
		originalRootC0 = rootJoint.C0; originalWaistC0 = waist.C0
	end

	character:SetAttribute("IsAttacking", false)
	character:SetAttribute("IsBlocking", false)
	character:SetAttribute("IsParrying", false)
	character:SetAttribute("CanCounterattack", false)

	loadAnimations(); setupTrail(); conectarEventosHumanoid(); detenerAnimacionesAjenas()

	if humanoid.MoveDirection.Magnitude < 0.1 then playAnim("Idle", 0.1) end

	table.insert(connections, character:GetAttributeChangedSignal("CanCounterattack"):Connect(function()
		if character:GetAttribute("CanCounterattack") == true then playAnim("Parry", 0.1) end
	end))

	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)

	-- Inputs PC
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then EmpezarBloqueo() end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then TerminarBloqueo() end
	end))

	-- Inputs Móvil
	local playerGui = player:WaitForChild("PlayerGui")
	local mobileGui = playerGui:WaitForChild("MobileControls", 3)

	if mobileGui then
		local btnBlock = mobileGui:FindFirstChild("BtnBlock")
		local btnCombat = mobileGui:FindFirstChild("BtnCombat")

		if btnBlock then
			table.insert(connections, btnBlock.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then EmpezarBloqueo() end
			end))
			table.insert(connections, btnBlock.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then TerminarBloqueo() end
			end))
		end
		if btnCombat then
			table.insert(connections, btnCombat.Activated:Connect(function() Tool:Activate() end))
		end
	end
end)

Tool.Unequipped:Connect(function()
	states.isEquipped = false; states.isSprinting = false; TerminarBloqueo()
	if character then 
		character:SetAttribute("IsAttacking", false) 
		character:SetAttribute("ArmaEquipada", false) 
	end
	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end
	if waist and originalWaistC0 then waist.C0 = originalWaistC0 end

	for _, t in pairs(tracks) do t:Stop() end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
end)
