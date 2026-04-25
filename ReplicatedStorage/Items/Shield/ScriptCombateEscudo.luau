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
local camera = workspace.CurrentCamera

-- 📡 EVENTOS SAO
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local SyncBlockEvent = SAO_Events:WaitForChild("SyncBlock")

-- 🦴 PROCEDURAL
local rootPart, lowerTorso, upperTorso, rootJoint, waist
local originalRootC0, originalWaistC0
local renderConnection = nil

-- ⚙️ CONFIGURACIÓN
local config = {
	velocidadCaminar = 16,
	velocidadSprint = 42, 
	ventanaParry = 0.25,  
	reproduccion = {
		Idle = 1, Caminar = 1, Correr = 1.3,
		Slash = 1.35,              
		AtaqueCaminando = 1.2, 
		AtaqueCorriendo = 1.5,     
		AtaquesSaltando = 1.4, 
		Blocked = 1, WhileBlocking = 1, Contradefensa = 1.2, Saltar = 1
	}
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, isBlocking = false }
local connections = {}
local slashTrail = nil

-- 🛡️ ESCUDO FALSO
local fakeShield = nil
local hitboxConnection = nil -- Para desconectar el hitbox al desequipar

-- ==========================================
-- ✨ TRAIL Y VFX
-- ==========================================
local function setupTrail()
	-- 🛠️ FIX: Conectamos el trail al arma falsa animada, no al Tool original
	if not fakeShield then return end
	local handle = fakeShield:IsA("BasePart") and fakeShield or fakeShield:FindFirstChild("Handle")
	if not handle then return end

	if handle:FindFirstChild("SlashTrail") then slashTrail = handle.SlashTrail return end

	local att0 = Instance.new("Attachment", handle); att0.Name = "TrailStart"; att0.Position = Vector3.new(0, -1, 0)
	local att1 = Instance.new("Attachment", handle); att1.Name = "TrailEnd"; att1.Position = Vector3.new(0, 3, 0)

	local trail = Instance.new("Trail", handle)
	trail.Name = "SlashTrail"; trail.Attachment0 = att0; trail.Attachment1 = att1
	trail.Lifetime = 0.12 
	trail.MinLength = 0.1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 80, 0)) 
	trail.LightEmission = 1
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

	local animFolder = Tool:FindFirstChild("Animation") or ReplicatedStorage:FindFirstChild("Animation")
	if not animFolder then return end

	for _, item in ipairs(animFolder:GetChildren()) do
		if item:IsA("Animation") and item.AnimationId ~= "" then
			local track = animator:LoadAnimation(item)

			if item.Name == "Idle" or item.Name == "WhileBlocking" then
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
-- 🛡️ DEFENSA (Bloqueo con Escudo)
-- ==========================================
local function EmpezarBloqueo()
	if not states.isEquipped or character:GetAttribute("IsAttacking") or states.isBlocking then return end
	states.isBlocking = true
	character:SetAttribute("IsBlocking", true)
	character:SetAttribute("IsParrying", true) 

	SyncBlockEvent:FireServer(true, true)

	local blockStartTrack = playAnim("Blocked", 0.1)
	humanoid.WalkSpeed = 10 

	if blockStartTrack then
		blockStartTrack.Stopped:Connect(function()
			if states.isBlocking then
				playAnim("WhileBlocking", 0.1)
			end
		end)
	else
		playAnim("WhileBlocking", 0.1)
	end

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

	if tracks["Blocked"] then tracks["Blocked"]:Stop(0.2) end
	if tracks["WhileBlocking"] then tracks["WhileBlocking"]:Stop(0.2) end

	humanoid.WalkSpeed = states.isSprinting and config.velocidadSprint or config.velocidadCaminar 
end

-- ==========================================
-- ⚙️ PROCEDURAL
-- ==========================================
local function updateProceduralTorso(deltaTime)
	if not rootJoint or not waist or not rootPart or humanoid.Health <= 0 then return end

	local partesVisibles = {
		fakeShield,
		character:FindFirstChild("Left Arm"), character:FindFirstChild("Right Arm"),
		character:FindFirstChild("LeftHand"), character:FindFirstChild("RightHand")
	}
	for _, obj in pairs(partesVisibles) do
		if obj then
			if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end
			for _, child in pairs(obj:GetDescendants()) do
				if child:IsA("BasePart") then child.LocalTransparencyModifier = 0 end
			end
		end
	end

	local isAttacking = character:GetAttribute("IsAttacking")

	if isAttacking then
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0, 18 * deltaTime)
		waist.C0 = waist.C0:Lerp(originalWaistC0, 18 * deltaTime)
		return
	end

	local state = humanoid:GetState()
	local enElSuelo = (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	local currentTime = tick()
	if enElSuelo and isMoving then
		local bobSpeed = states.isSprinting and 16 or 11
		local bobbingY = math.sin(currentTime * bobSpeed) * 0.04 
		local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local giroPiernas = math.atan2(-moveDirLocal.X, -moveDirLocal.Z)

		local leanMulti = states.isSprinting and 1.9 or 0.9 
		local leanAdelante = math.rad(moveDirLocal.Z * 14 * leanMulti)
		local leanLados = math.rad(-moveDirLocal.X * 12 * leanMulti)

		local tRoot = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(0, giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)
		local tWaist = originalWaistC0 * CFrame.Angles(0, -giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)

		rootJoint.C0 = rootJoint.C0:Lerp(tRoot, 14 * deltaTime)
		waist.C0 = waist.C0:Lerp(tWaist, 14 * deltaTime)
	else
		local bobbingY = enElSuelo and (math.sin(currentTime * 2) * 0.02) or 0
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, bobbingY, 0), 10 * deltaTime)
		waist.C0 = waist.C0:Lerp(originalWaistC0, 10 * deltaTime)
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
-- ⚔️ COMBATE Y CONTRAATAQUE
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

	if isCountering and tracks["Contradefensa"] then
		attackName = "Contradefensa"
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

		if isMidAir and tracks["Saltar"] then tracks["Saltar"]:Stop(0.1) end

		playAnim(trackToPlay.Name, 0.1)

		if slashTrail then 
			slashTrail.Enabled = true 
			task.delay(0.25, function() if slashTrail then slashTrail.Enabled = false end end)
		end

		task.wait(trackToPlay.Length - 0.2)
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
-- 💥 DETECCIÓN DE GOLPES
-- ==========================================
local hitDebounce = false

local function conectarHitbox()
	-- 🛠️ FIX: Ahora el TouchEvent persigue a tu arma falsa animada, no a la herramienta estática
	if not fakeShield then return end
	local handle = fakeShield:IsA("BasePart") and fakeShield or fakeShield:FindFirstChild("Handle")

	if handle then
		hitboxConnection = handle.Touched:Connect(function(hit)
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
							local cantidad = particula:GetAttribute("EmitCount") or 15
							particula:Emit(cantidad)
						end
					end

					Debris:AddItem(hitClon, 2)
				end

				task.delay(0.25, function() hitDebounce = false end)
			end
		end)
	end
end

-- ==========================================
-- 🔌 EQUIPAR / DESEQUIPAR (VERSIÓN OFFHAND)
-- ==========================================
local function EquiparEscudo()
	states.isEquipped = true
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	rootPart = character:WaitForChild("HumanoidRootPart")

	character:SetAttribute("EscudoEquipado", true)

	lowerTorso = character:FindFirstChild("LowerTorso"); upperTorso = character:FindFirstChild("UpperTorso")
	if lowerTorso and upperTorso then
		rootJoint = lowerTorso:WaitForChild("Root"); waist = upperTorso:WaitForChild("Waist")
		originalRootC0 = rootJoint.C0; originalWaistC0 = waist.C0
	end

	-- 🛠️ FIX MÁXIMO: Ocultar y hacer "fantasmas" las partes originales para NO VOLAR
	for _, part in pairs(Tool:GetDescendants()) do
		if part:IsA("BasePart") then 
			part.Transparency = 1 
			part.CanCollide = false 
			part.Massless = true 
		end
	end

	-- 🛡️ RIGGEO DEL ESCUDO (A PRUEBA DE FALLOS FÍSICOS)
	local animFolder = Tool:FindFirstChild("Animation") or ReplicatedStorage:FindFirstChild("Animation")

	if animFolder and animFolder:FindFirstChild("Shield") then
		if fakeShield then fakeShield:Destroy() end
		fakeShield = animFolder.Shield:Clone()

		local piezaEscudo = fakeShield:IsA("BasePart") and fakeShield or fakeShield:FindFirstChild("Handle")
		local LeftArm = character:FindFirstChild("Left Arm")

		if LeftArm and piezaEscudo then

			-- 1️⃣ AUTO-SOLDADURA Y MODO FANTASMA AL ESCUDO CLONADO
			local partes = fakeShield:GetDescendants()
			table.insert(partes, fakeShield) -- Incluimos el modelo base por si acaso

			for _, parte in pairs(partes) do
				if parte:IsA("BasePart") then
					parte.CanCollide = false
					parte.Massless = true
					parte.Anchored = false

					-- Soldamos todo al Handle para que no se desarme
					if parte ~= piezaEscudo then
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = piezaEscudo
						weld.Part1 = parte
						weld.Parent = piezaEscudo
					end
				end
			end

			-- 2️⃣ CREAMOS EL MOTOR6D DESDE CERO (Para que no desaparezca)
			local Joint = Instance.new("Motor6D")
			Joint.Name = "Joint" -- Vital para que Moon Animator lo reconozca
			Joint.Part0 = LeftArm
			Joint.Part1 = piezaEscudo
			Joint.Parent = LeftArm

			-- ⚙️ CALIBRACIÓN: Gíralo hacia la izquierda
			-- Si X = 90 lo acuesta, Y o Z lo girarán como un volante.

			local rotX = 90
			local rotY = 90  -- Prueba con 90 o -90 para que mire a la izquierda
			local rotZ = 0   -- Si rotY no funciona, déjalo en 0 y ponle 90 o -90 a este

			-- Si el escudo queda muy metido en tu brazo, puedes moverlo con estos (usa números como 0.5 o -0.5)
			local moverX = 0
			local moverY = 0
			local moverZ = 0

			Joint.C0 = CFrame.new(moverX, moverY, moverZ) * CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))

			fakeShield.Parent = character
			print("✅ Escudo equipado en modo fantasma. Adiós a los vuelos.")
		else
			warn("❌ ERROR: No se encontró el 'Left Arm' o el 'Handle'.")
		end
	end

	character:SetAttribute("IsAttacking", false)
	character:SetAttribute("IsBlocking", false)
	character:SetAttribute("IsParrying", false)
	character:SetAttribute("CanCounterattack", false)

	-- 🛠️ FIX: Cargar hitboxes y trails DESPUÉS del riggeo
	loadAnimations()
	setupTrail() 
	conectarHitbox()
	conectarEventosHumanoid()
	detenerAnimacionesAjenas()

	if humanoid.MoveDirection.Magnitude < 0.1 then playAnim("Idle", 0.1) end

	table.insert(connections, character:GetAttributeChangedSignal("CanCounterattack"):Connect(function()
		if character:GetAttribute("CanCounterattack") == true then playAnim("Contradefensa", 0.1) end
	end))

	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)

	-- Inputs PC (Clic Derecho para Bloquear)
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then EmpezarBloqueo() end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then TerminarBloqueo() end
	end))
end

local function DesequiparEscudo()
	states.isEquipped = false; states.isSprinting = false; TerminarBloqueo()
	if character then 
		character:SetAttribute("EscudoEquipado", false) 
	end

	-- 🛠️ FIX: Limpieza de modelo falso y hitboxes
	if hitboxConnection then hitboxConnection:Disconnect(); hitboxConnection = nil end
	if fakeShield then fakeShield:Destroy() end

	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end
	if waist and originalWaistC0 then waist.C0 = originalWaistC0 end

	for _, t in pairs(tracks) do t:Stop() end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
end

-- 🔥 EL HACK: En lugar de usar Tool.Equipped, detectamos a qué carpeta se movió el escudo
Tool.AncestryChanged:Connect(function(_, newParent)
	if newParent then
		if newParent.Name == "EquipoSeguro" or newParent == player.Character then
			EquiparEscudo()
		elseif newParent == player.Backpack then
			DesequiparEscudo()
		end
	end
end)
