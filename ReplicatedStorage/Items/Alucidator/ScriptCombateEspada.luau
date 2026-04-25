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

local config = {
	velocidadCaminar = 16,
	velocidadSprint = 40,
	ventanaParry = 0.3, 
	reproduccion = {
		Idle = 1, Caminar = 1, Correr = 1.3,
		Slash = 1.2, AtaqueCaminando = 1.1, AtaqueCorriendo = 0.6,
		AtaquesSaltando = 1.4, Bloqueo = 1, Parry = 1.5, Contraataque = 1.4, Saltar = 1,
		DualSlash1 = 1.3, DualSlash2 = 1.3, DualCross = 1.1, DualIdle = 1
	}
}

local tracks = {}
local states = { isEquipped = false, isSprinting = false, isBlocking = false }
local connections = {}
local slashTrailMain = nil
local slashTrailOff = nil
local comboStep = 1 
local usandoEscudo = false -- Variable de control maestro

-- ==========================================
-- 🔍 DETECCIÓN DE OFF-HAND (Mano Secundaria)
-- ==========================================
local function GetOffhandType()
	if not character then return "None" end

	-- 🌟 TRUCO MAESTRO: Usamos el atributo "EscudoEquipado" que creamos en tu script del escudo
	if character:GetAttribute("EscudoEquipado") == true then
		return "Shield"
	end

	-- Por si luego agregas una segunda espada en vez de escudo
	if character:FindFirstChild("OffhandItem") then
		return "Sword"
	end

	return "None"
end
-- ==========================================
-- ✨ TRAIL Y VFX (AHORA PARA 2 ESPADAS)
-- ==========================================
local function crearTrail(handle, color)
	if not handle or handle:FindFirstChild("SlashTrail") then return handle and handle:FindFirstChild("SlashTrail") end
	local att0 = Instance.new("Attachment", handle); att0.Name = "TrailStart"; att0.Position = Vector3.new(0, -1, 0)
	local att1 = Instance.new("Attachment", handle); att1.Name = "TrailEnd"; att1.Position = Vector3.new(0, 3, 0)
	local trail = Instance.new("Trail", handle)
	trail.Name = "SlashTrail"; trail.Attachment0 = att0; trail.Attachment1 = att1
	trail.Lifetime = 0.15; trail.MinLength = 0.1
	trail.Color = ColorSequence.new(color); trail.LightEmission = 1
	trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	trail.Enabled = false
	return trail
end

local function setupTrails()
	slashTrailMain = crearTrail(Tool:WaitForChild("Handle"), Color3.fromRGB(255, 30, 30)) 

	local offType, offModel = GetOffhandType()
	if offType == "Sword" and offModel then
		local offHandle = offModel:FindFirstChildWhichIsA("BasePart")
		if offHandle then
			slashTrailOff = crearTrail(offHandle, Color3.fromRGB(30, 200, 255)) 
		end
	else
		slashTrailOff = nil
	end
end

local function DispararVFX(nombreVFX)
	local contenedor = Tool:FindFirstChild(nombreVFX, true) or character:FindFirstChild(nombreVFX, true)
	if contenedor then
		for _, particula in pairs(contenedor:GetDescendants()) do
			if particula:IsA("ParticleEmitter") then particula:Emit(particula:GetAttribute("EmitCount") or 15) end
		end
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
			if string.match(item.Name, "Idle") then track.Priority = Enum.AnimationPriority.Action2; track.Looped = true
			elseif string.match(item.Name, "Caminar") or string.match(item.Name, "Correr") then track.Priority = Enum.AnimationPriority.Action3; track.Looped = true
			elseif item.Name == "Saltar" then track.Priority = Enum.AnimationPriority.Action3; track.Looped = false
			else track.Priority = Enum.AnimationPriority.Action4; track.Looped = false end

			track:GetMarkerReachedSignal("EmitirVFX"):Connect(function(vfxName) DispararVFX(vfxName) end)
			track:GetMarkerReachedSignal("TrailOn"):Connect(function() 
				if slashTrailMain then slashTrailMain.Enabled = true end 
				if slashTrailOff then slashTrailOff.Enabled = true end 
			end)
			track:GetMarkerReachedSignal("TrailOff"):Connect(function() 
				if slashTrailMain then slashTrailMain.Enabled = false end 
				if slashTrailOff then slashTrailOff.Enabled = false end 
			end)
			track.Name = item.Name; tracks[item.Name] = track
		end
	end
end

-- ==========================================
-- 🛡️ DEFENSA 
-- ==========================================
local function EmpezarBloqueo()
	if not states.isEquipped or character:GetAttribute("IsAttacking") or states.isBlocking then return end
	states.isBlocking = true; character:SetAttribute("IsBlocking", true); character:SetAttribute("IsParrying", true) 
	SyncBlockEvent:FireServer(true, true)

	local offType = GetOffhandType()
	if offType == "Sword" and tracks["DualBlock"] then playAnim("DualBlock", 0.1) else playAnim("Bloqueo", 0.1) end
	humanoid.WalkSpeed = 8 

	task.delay(config.ventanaParry, function()
		if character and states.isBlocking then character:SetAttribute("IsParrying", false); SyncBlockEvent:FireServer(true, false) end
	end)
end

local function TerminarBloqueo()
	if not states.isBlocking then return end
	states.isBlocking = false; if character then character:SetAttribute("IsBlocking", false); character:SetAttribute("IsParrying", false); SyncBlockEvent:FireServer(false, false) end
	if tracks["Bloqueo"] then tracks["Bloqueo"]:Stop(0.2) end
	if tracks["DualBlock"] then tracks["DualBlock"]:Stop(0.2) end
	humanoid.WalkSpeed = states.isSprinting and config.velocidadSprint or config.velocidadCaminar 
end

-- ==========================================
-- ⚙️ PROCEDURAL
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
		local bobSpeed = states.isSprinting and 15 or 10
		local bobbingY = math.sin(tick() * bobSpeed) * 0.05
		local moveDirLocal = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local giroPiernas = math.atan2(-moveDirLocal.X, -moveDirLocal.Z)

		local offType = GetOffhandType()
		local offsetDoble = (offType == "Sword" and not states.isSprinting) and math.rad(15) or 0

		local leanMulti = states.isSprinting and 1.5 or 0.8
		local leanAdelante = math.rad(moveDirLocal.Z * 12 * leanMulti)
		local leanLados = math.rad(-moveDirLocal.X * 10 * leanMulti)

		local tRoot = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(0, giroPiernas * 0.6, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)
		local tWaist = originalWaistC0 * CFrame.Angles(0, -giroPiernas * 0.6 + offsetDoble, 0) * CFrame.Angles(leanAdelante * 0.5, 0, leanLados * 0.5)

		rootJoint.C0 = rootJoint.C0:Lerp(tRoot, 12 * deltaTime)
		waist.C0 = waist.C0:Lerp(tWaist, 12 * deltaTime)
	else
		local bobbingY = enElSuelo and (math.sin(tick() * 2) * 0.02) or 0
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0 * CFrame.new(0, bobbingY, 0), 8 * deltaTime)
		waist.C0 = waist.C0:Lerp(originalWaistC0, 8 * deltaTime)
	end
end

-- ==========================================
-- 🔌 EVENTOS DE MOVIMIENTO
-- ==========================================
local function manejarMovimiento()
	local inAir = (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping)
	if inAir then return end

	if tracks["Idle"] then tracks["Idle"]:Stop(0.2) end
	if tracks["DualIdle"] then tracks["DualIdle"]:Stop(0.2) end
	if tracks["Caminar"] then tracks["Caminar"]:Stop(0.2) end
	if tracks["Correr"] then tracks["Correr"]:Stop(0.2) end

	local offType = GetOffhandType()
	local isDual = (offType == "Sword")

	if humanoid.MoveDirection.Magnitude > 0.1 then 
		if states.isSprinting then playAnim("Correr", 0.2) else playAnim("Caminar", 0.2) end
	else 
		if isDual and tracks["DualIdle"] then playAnim("DualIdle", 0.2) else playAnim("Idle", 0.2) end
	end
end

local function conectarEventosHumanoid()
	table.insert(connections, humanoid.Running:Connect(function(speed)
		if not states.isEquipped or character:GetAttribute("IsAttacking") then return end
		states.isSprinting = (humanoid.WalkSpeed >= config.velocidadSprint - 2) and not states.isBlocking
		manejarMovimiento()
	end))

	table.insert(connections, humanoid.StateChanged:Connect(function(oldState, newState)
		if not states.isEquipped then return end
		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
			manejarMovimiento() 
			playAnim("Saltar", 0.1)
		elseif newState == Enum.HumanoidStateType.Landed then
			if tracks["Saltar"] then tracks["Saltar"]:Stop(0.15) end
			manejarMovimiento()
		end
	end))
end

-- ==========================================
-- ⚔️ COMBATE 
-- ==========================================
Tool.Activated:Connect(function()
	-- Si el escudo está equipado, este script de espada entra en reposo absoluto
	if usandoEscudo then return end
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

	local offType = GetOffhandType()
	local attackName = "Slash"

	if offType == "Sword" then
		if isCountering and tracks["Contraataque"] then attackName = "Contraataque"
		elseif isMidAir and tracks["AtaquesSaltando"] then attackName = "AtaquesSaltando"
		elseif isMoving and states.isSprinting and tracks["AtaqueCorriendo"] then attackName = "AtaqueCorriendo"
		else
			if comboStep == 1 and tracks["DualSlash1"] then attackName = "DualSlash1"; comboStep = 2
			elseif comboStep == 2 and tracks["DualSlash2"] then attackName = "DualSlash2"; comboStep = 3
			elseif comboStep == 3 and tracks["DualCross"] then attackName = "DualCross"; comboStep = 1
			else attackName = "Slash" end
		end
	else
		if isCountering and tracks["Contraataque"] then attackName = "Contraataque"
		elseif isMidAir and tracks["AtaquesSaltando"] then attackName = "AtaquesSaltando"
		elseif isMoving and states.isSprinting and tracks["AtaqueCorriendo"] then attackName = "AtaqueCorriendo"
		elseif isMoving and tracks["AtaqueCaminando"] then attackName = "AtaqueCaminando"
		end
	end

	local trackToPlay = tracks[attackName] or tracks["Slash"]
	if trackToPlay then
		detenerAnimacionesAjenas()
		if isMidAir and tracks["Saltar"] then tracks["Saltar"]:Stop(0.1) end

		playAnim(trackToPlay.Name, 0.1)

		if slashTrailMain then slashTrailMain.Enabled = true end
		if slashTrailOff then slashTrailOff.Enabled = true end
		task.delay(0.3, function() 
			if slashTrailMain then slashTrailMain.Enabled = false end 
			if slashTrailOff then slashTrailOff.Enabled = false end 
		end)

		pcall(function()
			local vfxContenedorOriginal = Tool:FindFirstChild("Slash", true)
			if vfxContenedorOriginal and rootPart then
				local vfxClon = vfxContenedorOriginal:Clone()
				vfxClon.Parent = rootPart 
				if vfxClon:IsA("Attachment") then vfxClon.Position = Vector3.new(0, 0, -3) end
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

		task.wait(trackToPlay.Length - 0.15)
	end

	character:SetAttribute("IsAttacking", false)
	manejarMovimiento() 
end)

-- ==========================================
-- 💥 DETECCIÓN DE GOLPES
-- ==========================================
local hitDebounce = false

local function conectarGolpe(handleParte)
	if not handleParte then return end

	table.insert(connections, handleParte.Touched:Connect(function(hit)
		-- Si se usa escudo, este script ignora el Touch
		if usandoEscudo then return end
		if not states.isEquipped or not character:GetAttribute("IsAttacking") then return end
		if hitDebounce or hit:IsDescendantOf(character) then return end

		local enemigo = hit.Parent:FindFirstChild("Humanoid")
		if enemigo then
			hitDebounce = true

			if _G.RegisterHit then
				_G.RegisterHit(enemigo, hit, 15)
			else
				enemigo:TakeDamage(15)
			end

			local hitOriginal = Tool:FindFirstChild("Hit", true)
			if hitOriginal and hitOriginal:IsA("Attachment") then
				local hitClon = hitOriginal:Clone()
				hitClon.Parent = workspace.Terrain 
				hitClon.WorldPosition = handleParte.Position 

				for _, particula in pairs(hitClon:GetChildren()) do
					if particula:IsA("ParticleEmitter") then particula:Emit(particula:GetAttribute("EmitCount") or 15) end
				end
				Debris:AddItem(hitClon, 2)
			end
			task.delay(0.25, function() hitDebounce = false end)
		end
	end))
end

-- ==========================================
-- 🔌 EQUIPAR / DESEQUIPAR (Y CONTROL DE SCRIPTS)
-- ==========================================
Tool.Equipped:Connect(function()
	character = player.Character or player.CharacterAdded:Wait()

	-- 🔄 EL CONMUTADOR MAESTRO DE ESTILOS
	local scriptSwordSkills = Tool:FindFirstChild("swordskills")
	local scriptEscudoSkills = Tool:FindFirstChild("EspadaYEscudoSkills")
	local scriptCombateEscudo = Tool:FindFirstChild("ScriptCombateEspadaYEscudo")

	if GetOffhandType() == "Shield" then
		usandoEscudo = true

		-- Apagamos espada pura
		if scriptSwordSkills then scriptSwordSkills.Disabled = true end
		-- Encendemos escudo
		if scriptEscudoSkills then scriptEscudoSkills.Disabled = false end
		if scriptCombateEscudo then scriptCombateEscudo.Disabled = false end

		print("🛡️ Modo Espada y Escudo Activado")
		return -- Detenemos ESTE script para que el de Escudo tome el control
	else
		usandoEscudo = false

		-- Encendemos espada pura
		if scriptSwordSkills then scriptSwordSkills.Disabled = false end
		-- Apagamos escudo
		if scriptEscudoSkills then scriptEscudoSkills.Disabled = true end
		if scriptCombateEscudo then scriptCombateEscudo.Disabled = true end

		print("⚔️ Modo Espada Pura Activado")
	end

	-- 📡 OYENTE DINÁMICO: Por si te pones el escudo MIENTRAS ya tienes la espada en la mano
	-- Esto forzará a la espada a "recargar" para activar el otro script correctamente.
	table.insert(connections, character:GetAttributeChangedSignal("EscudoEquipado"):Connect(function()
		if character:GetAttribute("EscudoEquipado") == true then
			print("🔄 Recargando arma para fusionar estilos...")
			Tool.Parent = player.Backpack
			task.wait(0.05)
			Tool.Parent = character
		end
	end))

	-- Continuación normal si NO hay escudo equipado
	states.isEquipped = true
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	rootPart = character:WaitForChild("HumanoidRootPart")

	character:SetAttribute("ArmaEquipada", true)

	lowerTorso = character:FindFirstChild("LowerTorso"); upperTorso = character:FindFirstChild("UpperTorso")
	if lowerTorso and upperTorso then
		rootJoint = lowerTorso:WaitForChild("Root"); waist = upperTorso:WaitForChild("Waist")
		originalRootC0 = rootJoint.C0; originalWaistC0 = waist.C0
	end

	character:SetAttribute("IsAttacking", false); character:SetAttribute("IsBlocking", false); character:SetAttribute("IsParrying", false); character:SetAttribute("CanCounterattack", false)

	loadAnimations(); setupTrails(); conectarEventosHumanoid(); detenerAnimacionesAjenas()

	conectarGolpe(Tool:WaitForChild("Handle"))

	local _, offModel = GetOffhandType()
	if offModel then
		conectarGolpe(offModel:FindFirstChildWhichIsA("BasePart"))
	end

	manejarMovimiento()

	table.insert(connections, character:GetAttributeChangedSignal("CanCounterattack"):Connect(function()
		if character:GetAttribute("CanCounterattack") == true then playAnim("Parry", 0.1) end
	end))

	renderConnection = RunService.RenderStepped:Connect(updateProceduralTorso)

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then EmpezarBloqueo() end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then TerminarBloqueo() end
	end))

	local playerGui = player:WaitForChild("PlayerGui")
	local mobileGui = playerGui:WaitForChild("MobileControls", 3)
	if mobileGui then
		local btnBlock = mobileGui:FindFirstChild("BtnBlock"); local btnCombat = mobileGui:FindFirstChild("BtnCombat")
		if btnBlock then
			table.insert(connections, btnBlock.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then EmpezarBloqueo() end end))
			table.insert(connections, btnBlock.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then TerminarBloqueo() end end))
		end
		if btnCombat then table.insert(connections, btnCombat.Activated:Connect(function() Tool:Activate() end)) end
	end
end)

Tool.Unequipped:Connect(function()
	if usandoEscudo then 
		-- Solo reseteamos el switch, el "ScriptCombateEspadaYEscudo" 
		-- se encargará de hacer su propio Unequip.
		usandoEscudo = false 
		return 
	end

	states.isEquipped = false; states.isSprinting = false; comboStep = 1; TerminarBloqueo()
	if character then character:SetAttribute("IsAttacking", false); character:SetAttribute("ArmaEquipada", false) end
	if renderConnection then renderConnection:Disconnect() end
	if rootJoint and originalRootC0 then rootJoint.C0 = originalRootC0 end
	if waist and originalWaistC0 then waist.C0 = originalWaistC0 end

	for _, t in pairs(tracks) do t:Stop() end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
end)
