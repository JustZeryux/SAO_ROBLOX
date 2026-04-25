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

-- 📡 EVENTOS DE DAÑO Y SAO
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local SyncBlockEvent = SAO_Events:WaitForChild("SyncBlock")
local damageEvent = Tool:WaitForChild("DamageEvent") -- Tu evento de daño

-- 🦴 PROCEDURAL
local rootPart, lowerTorso, upperTorso, rootJoint, waist
local originalRootC0, originalWaistC0
local renderConnection = nil

-- ⚙️ CONFIGURACIÓN ESTILO KATANA
local config = {
	velocidadCaminar = 16,
	velocidadSprint = 42,
	ventanaParry = 0.25,
	reproduccion = {
		Idle = 1, Caminar = 1, Correr = 1.3,
		FristSlash = 1.3, ["Second Slash"] = 1.3, 
		AtaqueCaminando = 1.2, AtaqueCorriendo = 1.5, AtaquesSaltando = 1.4,
		FristBlock = 1.2, Blocking = 1, RepelingHits = 1.5, Parry = 1.6,
		Contraataque = 1.5, Saltar = 1, Equip = 1.2
	}
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, isBlocking = false, isRepelling = false }
local connections = {}
local slashTrail = nil
local fakeKatana = nil

-- ⏱️ SISTEMA DE COMBOS
local comboStep = 1
local lastAttackTime = 0
local spamMultiplier = 1

-- ==========================================
-- ✨ TRAIL Y VFX
-- ==========================================
local function setupTrail()
	if not fakeKatana then return end
	local handle = fakeKatana:IsA("BasePart") and fakeKatana or fakeKatana:FindFirstChild("Handle")
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

-- 🌟 FIX VFX: Ahora puedes elegir exactamente dónde salen las chispas
local function DispararVFX(nombreVFX, objetivoVFX)
	local contenedor = Tool:FindFirstChild(nombreVFX, true) or character:FindFirstChild(nombreVFX, true)
	if contenedor then
		-- Si le pasamos el cuerpo del enemigo, salen ahí. Si no, en nuestra espada/cuerpo.
		local objetivo = objetivoVFX or rootPart 
		local vfxClon = contenedor:Clone()
		vfxClon.Parent = objetivo 
		
		

		if vfxClon:IsA("Attachment") then 
			-- Vector3.new(X, Y, Z) en grados. 
			-- Prueba math.rad(90) en diferentes ejes hasta que quede como quieres.
			vfxClon.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(90), 0, 0) 
		end

		for _, particula in pairs(vfxClon:GetDescendants()) do
			if particula:IsA("ParticleEmitter") then
				particula.EmissionDirection = Enum.NormalId.Front
				particula.LockedToPart = true 
				particula:Emit(particula:GetAttribute("EmitCount") or 15)
			end
		end
		Debris:AddItem(vfxClon, 1)
	end
end

-- ==========================================
-- 🎬 CONTROL DE ANIMACIONES
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
	if name == "Caminar" or name == "Correr" then
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

			if item.Name == "Caminar" or item.Name == "Correr" then
				track.Priority = Enum.AnimationPriority.Movement; track.Looped = true
			elseif item.Name == "Idle" or item.Name == "Blocking" then
				track.Priority = Enum.AnimationPriority.Action; track.Looped = true
			elseif item.Name == "Saltar" or item.Name == "FristBlock" then
				track.Priority = Enum.AnimationPriority.Action3; track.Looped = false
			else
				track.Priority = Enum.AnimationPriority.Action4; track.Looped = false 
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
-- 🛡️ DEFENSA Y RECHAZO PERFECTO
-- ==========================================
local function EmpezarBloqueo()
	if not states.isEquipped or character:GetAttribute("IsAttacking") or states.isBlocking then return end
	states.isBlocking = true; character:SetAttribute("IsBlocking", true); character:SetAttribute("IsParrying", true) 

	SyncBlockEvent:FireServer(true, true)
	humanoid.WalkSpeed = 10 

	if tracks["Idle"] then tracks["Idle"]:Stop(0.1) end

	local prepTrack = playAnim("FristBlock", 0.1)
	if prepTrack then
		prepTrack.Stopped:Connect(function()
			if states.isBlocking and not states.isRepelling then playAnim("Blocking", 0.1) end
		end)
	else
		playAnim("Blocking", 0.1)
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
	states.isBlocking = false; states.isRepelling = false
	if character then
		character:SetAttribute("IsBlocking", false)
		character:SetAttribute("IsParrying", false)
		SyncBlockEvent:FireServer(false, false)
	end

	if tracks["FristBlock"] then tracks["FristBlock"]:Stop(0.2) end
	if tracks["Blocking"] then tracks["Blocking"]:Stop(0.2) end
	if tracks["RepelingHits"] then tracks["RepelingHits"]:Stop(0.2) end

	humanoid.WalkSpeed = states.isSprinting and config.velocidadSprint or config.velocidadCaminar 
	if states.isEquipped and not character:GetAttribute("IsAttacking") then playAnim("Idle", 0.2) end
end

local function ObtenerAGI()
	local agi = player:GetAttribute("AGI")
	return agi and agi or 0
end

local function ConectarRechazoDeGolpes()
	local repelDebounce = false

	local function IntentarBloqueoPerfecto(enemigoModel)
		local agi = ObtenerAGI()
		local probabilidad = 30 + (agi * 0.25)
		local dado = math.random(1, 10000) / 100 

		if dado <= probabilidad then
			character:SetAttribute("IsRepelling", true)
			states.isRepelling = true
			if tracks["Blocking"] then tracks["Blocking"]:Stop(0.1) end

			local repelTrack = playAnim("RepelingHits", 0.05)
			if repelTrack then
				repelTrack.Stopped:Connect(function()
					states.isRepelling = false; character:SetAttribute("IsRepelling", false)
					if states.isBlocking then playAnim("Blocking", 0.1) end
				end)
			else
				task.delay(0.5, function() states.isRepelling = false; character:SetAttribute("IsRepelling", false) end)
			end

			local handlePart = fakeKatana and (fakeKatana:IsA("BasePart") and fakeKatana or fakeKatana:FindFirstChild("Handle"))
			if handlePart then DispararVFX("HitImpact", handlePart) end

			if enemigoModel then
				local hrpEnemigo = enemigoModel:FindFirstChild("HumanoidRootPart")
				if hrpEnemigo and rootPart then
					hrpEnemigo:ApplyImpulse((hrpEnemigo.Position - rootPart.Position).Unit * 750) 
				end
			end
			SyncBlockEvent:FireServer("PerfectBlock", enemigoModel)
			return true
		end
		return false
	end

	local partesDefensivas = {character:WaitForChild("Torso")}
	if fakeKatana then 
		local katanaPart = fakeKatana:IsA("BasePart") and fakeKatana or fakeKatana:FindFirstChild("Handle")
		if katanaPart then table.insert(partesDefensivas, katanaPart) end
	end

	for _, parte in pairs(partesDefensivas) do
		table.insert(connections, parte.Touched:Connect(function(hit)
			if not states.isBlocking or repelDebounce or hit:IsDescendantOf(character) then return end
			local enemigoModel = hit:FindFirstAncestorOfClass("Model")
			if enemigoModel and enemigoModel:FindFirstChild("Humanoid") and enemigoModel:FindFirstChild("Humanoid").Health > 0 then
				if hit.Name == "Handle" or hit:FindFirstAncestorOfClass("Tool") or hit.Name:find("Arm") or hit.Name:find("Leg") then
					repelDebounce = true
					IntentarBloqueoPerfecto(enemigoModel)
					task.delay(0.4, function() repelDebounce = false end)
				end
			end
		end))
	end
end

-- ==========================================
-- ⚙️ PROCEDURAL (🌟 FIX PIERNAS TIESAS)
-- ==========================================
local function updateProceduralTorso(deltaTime)
	if not rootJoint or not rootPart or humanoid.Health <= 0 then return end

	-- 🌟 Al quitar el "return" que bloqueaba esto al atacar, 
	-- ahora tus piernas y tu caminar seguirán funcionando incluso mientras cortas.

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
		rootJoint.C0 = rootJoint.C0:Lerp(tRoot, 14 * deltaTime)

		if waist and originalWaistC0 then
			local tWaist = originalWaistC0 * CFrame.Angles(0, -giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)
			waist.C0 = waist.C0:Lerp(tWaist, 14 * deltaTime)
		end
	else
		local bobbingY = enElSuelo and (math.sin(currentTime * 2) * 0.02) or 0
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, bobbingY, 0), 10 * deltaTime)
		if waist and originalWaistC0 then waist.C0 = waist.C0:Lerp(originalWaistC0, 10 * deltaTime) end
	end
end

-- ==========================================
-- 🔌 EVENTOS DE MOVIMIENTO
-- ==========================================
local function conectarEventosHumanoid()
	table.insert(connections, humanoid.Running:Connect(function(speed)
		if not states.isEquipped or character:GetAttribute("IsAttacking") or character:GetAttribute("IsSliding") then return end
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
			if tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end
			if tracks["Correr"] then tracks["Correr"]:Stop(0.2) end
			if not states.isBlocking and not character:GetAttribute("IsAttacking") then playAnim("Idle", 0.2) end
		end
	end))

	table.insert(connections, humanoid.StateChanged:Connect(function(oldState, newState)
		if not states.isEquipped or character:GetAttribute("IsSliding") then return end

		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			if tracks["Caminar"] then tracks["Caminar"]:Stop(0.1) end; if tracks["Correr"] then tracks["Correr"]:Stop(0.1) end
			if tracks["Blocking"] then tracks["Blocking"]:Stop(0.1) end
			playAnim("Saltar", 0.1)
		elseif newState == Enum.HumanoidStateType.Landed then
			if tracks["Saltar"] then tracks["Saltar"]:Stop(0.15) end
			if humanoid.MoveDirection.Magnitude > 0.1 then
				if states.isSprinting then playAnim("Correr", 0.15) else playAnim("Caminar", 0.15) end
			else
				if states.isBlocking then playAnim("Blocking", 0.15) else playAnim("Idle", 0.15) end
			end
		end
	end))
end

-- ==========================================
-- 💥 ESCÁNER DE DAÑO RAYCAST (FUSIONADO)
-- ==========================================
local raycastScanConnection = nil
local hitCharacters = {}
local lastBasePos, lastTipPos, lastMidPos = nil, nil, nil

local function IniciarHitbox()
	table.clear(hitCharacters)
	local handle = fakeKatana:IsA("BasePart") and fakeKatana or fakeKatana:FindFirstChild("Handle")
	if not handle then return end

	-- Crea Attachments si no los pusiste
	local baseAtt = handle:FindFirstChild("Base") or Instance.new("Attachment", handle)
	if baseAtt.Name ~= "Base" then baseAtt.Name = "Base"; baseAtt.Position = Vector3.new(0, -1, 0) end
	local tipAtt = handle:FindFirstChild("Punta") or Instance.new("Attachment", handle)
	if tipAtt.Name ~= "Punta" then tipAtt.Name = "Punta"; tipAtt.Position = Vector3.new(0, 3, 0) end

	lastBasePos = baseAtt.WorldPosition
	lastTipPos = tipAtt.WorldPosition
	lastMidPos = (lastBasePos + lastTipPos) / 2

	raycastScanConnection = RunService.Heartbeat:Connect(function()
		if not states.isEquipped or not character:GetAttribute("IsAttacking") then return end

		local currentBase = baseAtt.WorldPosition
		local currentTip = tipAtt.WorldPosition
		local currentMid = (currentBase + currentTip) / 2

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character, Tool, fakeKatana}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local function checkHit(startPos, endPos)
			local direction = endPos - startPos
			local result = workspace:Raycast(startPos, direction, raycastParams)

			if result and result.Instance then
				local victimChar = result.Instance.Parent
				local victimHumanoid = victimChar:FindFirstChild("Humanoid")

				if victimHumanoid and victimHumanoid.Health > 0 and victimChar ~= character then
					if not hitCharacters[victimChar] then
						hitCharacters[victimChar] = true

						-- 1. 🌟 VFX EN EL CUERPO DEL ENEMIGO
						local rootEnemigo = victimChar:FindFirstChild("HumanoidRootPart") or result.Instance
						DispararVFX("Hit", rootEnemigo)

						-- 2. 🧮 CALCULAR DAÑO
						local str = player:GetAttribute("STR") or 10
						local danoCalculado = 15 + (str * 1.5)

						-- 3. 🛡️ VERIFICAR BLOQUEO ENEMIGO
						if victimChar:GetAttribute("IsParrying") then return end -- Parry anula el daño
						if victimChar:GetAttribute("IsBlocking") then danoCalculado = danoCalculado * 0.3 end

						-- 4. 🩸 MANDAR EL DAÑO SEGURO AL SERVER (Tu script "senal")
						if damageEvent then
							damageEvent:FireServer(victimHumanoid, result.Instance, result.Position, danoCalculado)
						end
					end
				end
			end
		end

		checkHit(lastBasePos, currentBase)
		checkHit(lastMidPos, currentMid)
		checkHit(lastTipPos, currentTip)

		lastBasePos = currentBase; lastTipPos = currentTip; lastMidPos = currentMid
	end)
end

local function DetenerHitbox()
	if raycastScanConnection then raycastScanConnection:Disconnect() end
	table.clear(hitCharacters)
end

-- ==========================================
-- ⚔️ COMBATE Y ATAQUES
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
	if tracks["Idle"] then tracks["Idle"]:Stop(0.1) end 

	local state = humanoid:GetState()
	local isMidAir = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1
	local attackName = "FristSlash"
	local currentSpeed = config.reproduccion.FristSlash
	local now = tick()
	local timeSinceLastAttack = now - lastAttackTime

	if isCountering and tracks["Contraataque"] then
		attackName = "Contraataque"
	elseif isMidAir and tracks["AtaquesSaltando"] then
		attackName = "AtaquesSaltando"
	elseif isMoving and states.isSprinting and tracks["AtaqueCorriendo"] then
		attackName = "AtaqueCorriendo"
	elseif isMoving and tracks["AtaqueCaminando"] then
		attackName = "AtaqueCaminando"
	else
		if timeSinceLastAttack < 0.85 then
			spamMultiplier = math.clamp(spamMultiplier + 0.15, 1, 1.6)
			comboStep = comboStep == 1 and 2 or 1
		else
			spamMultiplier = 1; comboStep = 1
		end

		attackName = comboStep == 1 and "FristSlash" or "Second Slash"
		if not tracks[attackName] then attackName = "FristSlash" end
		currentSpeed = (config.reproduccion[attackName] or 1.3) * spamMultiplier
	end

	lastAttackTime = now
	local trackToPlay = tracks[attackName] or tracks["FristSlash"]

	if trackToPlay then
		detenerAnimacionesAjenas()
		if isMidAir and tracks["Saltar"] then tracks["Saltar"]:Stop(0.1) end

		playAnim(trackToPlay.Name, 0.1)
		trackToPlay:AdjustSpeed(currentSpeed)

		-- Prende los efectos y el escáner de daño
		if slashTrail then 
			slashTrail.Enabled = true 
			task.delay(0.25 / spamMultiplier, function() if slashTrail then slashTrail.Enabled = false end end)
		end
		DispararVFX("Slash") 

		-- 🩸 ENCENDER DAÑO
		IniciarHitbox()

		task.wait(trackToPlay.Length / currentSpeed - 0.15)
		DetenerHitbox() -- APAGAR DAÑO AL TERMINAR
	end

	character:SetAttribute("IsAttacking", false)

	if states.isEquipped then
		if isMidAir then playAnim("Saltar", 0.2)
		elseif humanoid.MoveDirection.Magnitude > 0.1 then
			if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end
			playAnim("Idle", 0.2) 
		else playAnim("Idle", 0.2) end
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
	character:SetAttribute("IsAttacking", false); character:SetAttribute("IsBlocking", false)
	character:SetAttribute("IsParrying", false); character:SetAttribute("CanCounterattack", false)

	-- 1. Ocultar la Tool original
	for _, part in ipairs(Tool:GetChildren()) do
		if part:IsA("BasePart") then part.Transparency = 1 end
	end

	local animFolder = Tool:FindFirstChild("Animation") or ReplicatedStorage:FindFirstChild("Animation")
	local modeloPlantilla = animFolder and animFolder:FindFirstChild("Katana") 

	if fakeKatana then fakeKatana:Destroy() end

	-- 2. Clonar la Katana Visual
	if modeloPlantilla then
		fakeKatana = modeloPlantilla:Clone()
	else
		fakeKatana = Tool:FindFirstChild("Handle"):Clone()
		fakeKatana.Transparency = 0
	end

	local piezaKatana = fakeKatana:IsA("BasePart") and fakeKatana or fakeKatana:FindFirstChild("Handle")
	local RightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")

	if RightArm and piezaKatana then
		local partes = fakeKatana:GetDescendants()
		if not fakeKatana:IsA("BasePart") then table.insert(partes, fakeKatana) end

		-- 3. Preparar soldaduras y forzar transparencia = 0
		for _, parte in pairs(partes) do
			if parte:IsA("BasePart") then
				parte.Transparency = 0
				parte.CanCollide = false; parte.Massless = true; parte.Anchored = false
				if parte ~= piezaKatana then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = piezaKatana; weld.Part1 = parte; weld.Parent = piezaKatana
				end
			end
		end

		-- 4. TU LÓGICA ORIGINAL DE POSICIONAMIENTO (Intacta)
		local motor = piezaKatana:FindFirstChild("Handle") or fakeKatana:FindFirstChild("Handle", true)
		if not motor or not motor:IsA("Motor6D") then
			motor = Instance.new("Motor6D")
			motor.Name = "Handle"
		end

		motor.Part0 = RightArm; motor.Part1 = piezaKatana; motor.Parent = RightArm

		if fakeKatana:IsA("Folder") then
			piezaKatana.Parent = character
			fakeKatana:Destroy()
			fakeKatana = piezaKatana 
		else
			fakeKatana.Parent = character
		end

		-- 🔥 5. FIX PRIMERA PERSONA (El truco para que Roblox no la oculte al hacer zoom)
		local fpvConnection = RunService.RenderStepped:Connect(function()
			if fakeKatana and fakeKatana.Parent then
				-- Esto le dice a la cámara: "No la vuelvas invisible nunca"
				if fakeKatana:IsA("BasePart") then
					fakeKatana.LocalTransparencyModifier = 0
				end
				for _, part in ipairs(fakeKatana:GetDescendants()) do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier = 0
					end
				end
			end
		end)
		table.insert(connections, fpvConnection)

	else
		warn("❌ ERROR: No se encontró el Brazo o el 'Handle'.")
	end

	loadAnimations(); setupTrail(); conectarEventosHumanoid(); detenerAnimacionesAjenas(); ConectarRechazoDeGolpes()

	if tracks["Equip"] then
		local eqTrack = playAnim("Equip", 0.1)
		if eqTrack then
			eqTrack.Stopped:Connect(function()
				if states.isEquipped and not character:GetAttribute("IsAttacking") and not states.isBlocking then 
					playAnim("Idle", 0.2) 
				end
			end)
		end
	else
		playAnim("Idle", 0.1) 
	end

	table.insert(connections, character:GetAttributeChangedSignal("CanCounterattack"):Connect(function()
		if character:GetAttribute("CanCounterattack") == true then playAnim("Parry", 0.1) end
	end))

	lowerTorso = character:FindFirstChild("Torso") or character:FindFirstChild("LowerTorso")
	if lowerTorso then
		rootJoint = lowerTorso:FindFirstChild("RootJoint") or lowerTorso:FindFirstChild("Root")
		if rootJoint then originalRootC0 = rootJoint.C0 end
	end
	upperTorso = character:FindFirstChild("UpperTorso")
	if upperTorso then
		waist = upperTorso:FindFirstChild("Waist")
		if waist then originalWaistC0 = waist.C0 end
	end

	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then EmpezarBloqueo() end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then TerminarBloqueo() end
	end))
end)

Tool.Unequipped:Connect(function()
	states.isEquipped = false; states.isSprinting = false; states.isRepelling = false; comboStep = 1; spamMultiplier = 1; TerminarBloqueo()
	DetenerHitbox()
	if character then character:SetAttribute("IsAttacking", false); character:SetAttribute("ArmaEquipada", false) end
	if fakeKatana then fakeKatana:Destroy() end
	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end
	if waist and originalWaistC0 then waist.C0 = originalWaistC0 end

	for _, t in pairs(tracks) do t:Stop() end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
end)
