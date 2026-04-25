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

-- ⚙️ CONFIGURACIÓN ESTILO LANZA (Largo alcance, rítmica)
local config = {
	velocidadCaminar = 15, 
	velocidadSprint = 36,  
	ventanaParry = 0.3,   
	reproduccion = {
		Idle = 1, Caminar = 1, Correr = 1.1,
		Slash = 1.1,               -- Estocadas rítmicas
		AtaqueCaminando = 1.0, 
		AtaqueCorriendo = 1.2,     
		AtaquesSaltando = 1.2, 
		Bloqueo = 1, Parry = 1.3,  
		Contraataque = 1.3, Saltar = 1
	}
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, isBlocking = false }
local connections = {}
local slashTrail = nil

-- ==========================================
-- ✨ TRAIL Y VFX (Plata/Azul en la punta)
-- ==========================================
local function setupTrail()
	local handle = Tool:WaitForChild("Handle")
	if handle:FindFirstChild("SlashTrail") then slashTrail = handle.SlashTrail return end

	-- El trail de la lanza va solo en la punta (muy arriba en Y)
	local att0 = Instance.new("Attachment", handle); att0.Name = "TrailStart"; att0.Position = Vector3.new(0, 2, 0)
	local att1 = Instance.new("Attachment", handle); att1.Name = "TrailEnd"; att1.Position = Vector3.new(0, 4.5, 0)

	local trail = Instance.new("Trail", handle)
	trail.Name = "SlashTrail"; trail.Attachment0 = att0; trail.Attachment1 = att1
	trail.Lifetime = 0.15 
	trail.MinLength = 0.1
	trail.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255)) -- Azul claro acero
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
		for _, myTrack in pairs(tracks) do if track == myTrack then esNuestra = true; break end end
		if not esNuestra then track:Stop(0.1) end
	end
end

local function playAnim(name, fadeTime)
	if name == "Idle" then
		if tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end; if tracks["Correr"] then tracks["Correr"]:Stop(0.2) end
	elseif name == "Caminar" or name == "Correr" then
		if tracks["Idle"] then tracks["Idle"]:Stop(0.2) end
		if name == "Caminar" and tracks["Correr"] then tracks["Correr"]:Stop(0.2) end
		if name == "Correr" and tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end
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
			track:GetMarkerReachedSignal("EmitirVFX"):Connect(function(vfxName) DispararVFX(vfxName) end)
			track:GetMarkerReachedSignal("TrailOn"):Connect(function() if slashTrail then slashTrail.Enabled = true end end)
			track:GetMarkerReachedSignal("TrailOff"):Connect(function() if slashTrail then slashTrail.Enabled = false end end)
			track.Name = item.Name; tracks[item.Name] = track
		end
	end
end

-- ==========================================
-- 🛡️ DEFENSA (Guardia con el Asta)
-- ==========================================
local function EmpezarBloqueo()
	if not states.isEquipped or character:GetAttribute("IsAttacking") or states.isBlocking then return end
	states.isBlocking = true; character:SetAttribute("IsBlocking", true); character:SetAttribute("IsParrying", true) 
	SyncBlockEvent:FireServer(true, true); playAnim("Bloqueo", 0.1); humanoid.WalkSpeed = 10 
	task.delay(config.ventanaParry, function()
		if character and states.isBlocking then character:SetAttribute("IsParrying", false); SyncBlockEvent:FireServer(true, false) end
	end)
end

local function TerminarBloqueo()
	if not states.isBlocking then return end
	states.isBlocking = false; if character then character:SetAttribute("IsBlocking", false); character:SetAttribute("IsParrying", false); SyncBlockEvent:FireServer(false, false) end
	if tracks["Bloqueo"] then tracks["Bloqueo"]:Stop(0.2) end; humanoid.WalkSpeed = states.isSprinting and config.velocidadSprint or config.velocidadCaminar 
end

-- ==========================================
-- ⚙️ PROCEDURAL (POSTURA DE LANCERO LADO)
-- ==========================================
local function updateProceduralTorso(deltaTime)
	if not rootJoint or not waist or not rootPart or humanoid.Health <= 0 then return end
	if character:GetAttribute("IsAttacking") then
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0, 15 * deltaTime) 
		waist.C0 = waist.C0:Lerp(originalWaistC0, 15 * deltaTime)
		return
	end

	local state = humanoid:GetState()
	local enElSuelo = (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	if enElSuelo and isMoving then
		local bobSpeed = states.isSprinting and 14 or 10
		local bobbingY = math.sin(tick() * bobSpeed) * 0.04 
		local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)

		-- ✨ LA MAGIA DE LA LANZA: Gira la cintura casi 40 grados para ponerse de lado
		local giroPiernas = math.atan2(-moveDirLocal.X, -moveDirLocal.Z)
		local posturaLateral = math.rad(40) 

		local leanMulti = states.isSprinting and 1.2 or 0.8 
		local leanAdelante = math.rad(moveDirLocal.Z * 12 * leanMulti)

		local tRoot = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(0, giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, 0)
		local tWaist = originalWaistC0 * CFrame.Angles(0, -giroPiernas * 0.6 + posturaLateral, 0) * CFrame.Angles(leanAdelante * 0.5, 0, 0)

		rootJoint.C0 = rootJoint.C0:Lerp(tRoot, 12 * deltaTime)
		waist.C0 = waist.C0:Lerp(tWaist, 12 * deltaTime)
	else
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, (enElSuelo and math.sin(tick() * 2) * 0.02 or 0), 0), 8 * deltaTime)
		waist.C0 = waist.C0:Lerp(originalWaistC0 * CFrame.Angles(0, math.rad(30), 0), 8 * deltaTime) -- Mantiene un poco la postura en Idle
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
			if states.isSprinting then playAnim("Correr", 0.2) else
				local dir = (rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection).Z > 0.1) and -1 or 1
				local t = playAnim("Caminar", 0.2); if t then t:AdjustSpeed(config.reproduccion["Caminar"] * dir) end
			end
		else playAnim("Idle", 0.2) end
	end))

	table.insert(connections, humanoid.StateChanged:Connect(function(oldState, newState)
		if not states.isEquipped then return end
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
-- ⚔️ COMBATE (ESTOCADAS DE LARGO ALCANCE)
-- ==========================================
Tool.Activated:Connect(function()
	if not states.isEquipped or character:GetAttribute("IsAttacking") then return end
	local isCountering = false
	if states.isBlocking then
		if character:GetAttribute("CanCounterattack") then isCountering = true; TerminarBloqueo(); character:SetAttribute("CanCounterattack", false) else return end
	end

	character:SetAttribute("IsAttacking", true)
	local state = humanoid:GetState()
	local isMidAir = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	local attackName = "Slash"
	if isCountering and tracks["Contraataque"] then attackName = "Contraataque"
	elseif isMidAir and tracks["AtaquesSaltando"] then attackName = "AtaquesSaltando"
	elseif isMoving and states.isSprinting and tracks["AtaqueCorriendo"] then attackName = "AtaqueCorriendo"
	elseif isMoving and tracks["AtaqueCaminando"] then attackName = "AtaqueCaminando" end

	local trackToPlay = tracks[attackName] or tracks["Slash"]
	if trackToPlay then
		detenerAnimacionesAjenas()
		if isMidAir and tracks["Saltar"] then tracks["Saltar"]:Stop(0.1) end
		playAnim(trackToPlay.Name, 0.1)

		if slashTrail then slashTrail.Enabled = true; task.delay(0.2, function() if slashTrail then slashTrail.Enabled = false end end) end

		-- ✨ MAGIA DE LA LANZA: Rango de ataque larguísimo
		pcall(function()
			local vfxContenedorOriginal = Tool:FindFirstChild("Slash", true)
			if vfxContenedorOriginal and rootPart then
				local vfxClon = vfxContenedorOriginal:Clone()
				vfxClon.Parent = rootPart 
				if vfxClon:IsA("Attachment") then
					-- ¡Llega hasta 6 studs hacia adelante!
					vfxClon.Position = Vector3.new(0, 0, -6) 
				end
				for _, particula in pairs(vfxClon:GetDescendants()) do
					if particula:IsA("ParticleEmitter") then
						particula.EmissionDirection = Enum.NormalId.Front
						particula.LockedToPart = true 
						particula:Emit(particula:GetAttribute("EmitCount") or 15)
					end
				end
				game:GetService("Debris"):AddItem(vfxClon, 1)
			end
		end)
		task.wait(trackToPlay.Length - 0.2)
	end

	character:SetAttribute("IsAttacking", false)
	if states.isEquipped then
		if isMidAir then playAnim("Saltar", 0.2)
		elseif humanoid.MoveDirection.Magnitude > 0.1 then
			if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end
		else playAnim("Idle", 0.2) end
	end
end)

-- ==========================================
-- 💥 DETECCIÓN DE GOLPES
-- ==========================================
local hitDebounce = false
local handle = Tool:WaitForChild("Handle")

handle.Touched:Connect(function(hit)
	if not states.isEquipped or not character:GetAttribute("IsAttacking") or hitDebounce or hit:IsDescendantOf(character) then return end
	local enemigo = hit.Parent:FindFirstChild("Humanoid")
	if enemigo then
		hitDebounce = true
		local hitOriginal = Tool:FindFirstChild("Hit", true)
		if hitOriginal and hitOriginal:IsA("Attachment") then
			local hitClon = hitOriginal:Clone(); hitClon.Parent = workspace.Terrain; hitClon.WorldPosition = handle.Position 
			for _, particula in pairs(hitClon:GetChildren()) do
				if particula:IsA("ParticleEmitter") then particula:Emit(particula:GetAttribute("EmitCount") or 15) end
			end
			Debris:AddItem(hitClon, 2)
		end
		task.delay(0.3, function() hitDebounce = false end) -- Ritmo constante de ataque
	end
end)

-- SETUP Y UN-EQUIP (Omitido por espacio, usa el mismo de tus otros scripts para conectar los inputs PC/Móvil)
Tool.Equipped:Connect(function()
	states.isEquipped = true; character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid"); rootPart = character:WaitForChild("HumanoidRootPart"); animator = humanoid:WaitForChild("Animator")
	character:SetAttribute("ArmaEquipada", true)
	lowerTorso = character:FindFirstChild("LowerTorso"); upperTorso = character:FindFirstChild("UpperTorso")
	if lowerTorso and upperTorso then rootJoint = lowerTorso:WaitForChild("Root"); waist = upperTorso:WaitForChild("Waist"); originalRootC0 = rootJoint.C0; originalWaistC0 = waist.C0 end
	character:SetAttribute("IsAttacking", false); character:SetAttribute("IsBlocking", false); character:SetAttribute("IsParrying", false); character:SetAttribute("CanCounterattack", false)
	loadAnimations(); setupTrail(); conectarEventosHumanoid(); detenerAnimacionesAjenas()
	if humanoid.MoveDirection.Magnitude < 0.1 then playAnim("Idle", 0.1) end
	table.insert(connections, character:GetAttributeChangedSignal("CanCounterattack"):Connect(function() if character:GetAttribute("CanCounterattack") == true then playAnim("Parry", 0.1) end end))
	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe) if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then EmpezarBloqueo() end end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton2 then TerminarBloqueo() end end))
end)

Tool.Unequipped:Connect(function()
	states.isEquipped = false; states.isSprinting = false; TerminarBloqueo()
	if character then character:SetAttribute("IsAttacking", false); character:SetAttribute("ArmaEquipada", false) end
	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end; if waist and originalWaistC0 then waist.C0 = originalWaistC0 end
	for _, t in pairs(tracks) do t:Stop() end; for _, c in ipairs(connections) do c:Disconnect() end; table.clear(connections)
end)
