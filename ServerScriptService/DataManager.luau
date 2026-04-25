local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = DataStoreService:GetDataStore("SAO_PlayerData_V1")

-- ==========================================
-- 📂 CARPETAS, MÓDULOS Y EVENTOS
-- ==========================================
local SAO_Events = ReplicatedStorage:FindFirstChild("SAO_Events") or Instance.new("Folder", ReplicatedStorage)
SAO_Events.Name = "SAO_Events"

local modulosFolder = ReplicatedStorage:WaitForChild("SAO_Modules")
local Habilidades = require(modulosFolder:WaitForChild("Habilidades"))

-- 🔥 El servidor crea los BindableEvents globales para que los clientes no se confundan
if not SAO_Events:FindFirstChild("OpenAvatarCreator") then 
	Instance.new("BindableEvent", SAO_Events).Name = "OpenAvatarCreator" 
end
if not SAO_Events:FindFirstChild("OpenClassMenu") then Instance.new("BindableEvent", SAO_Events).Name = "OpenClassMenu" end
local ItemsFolder = ReplicatedStorage:FindFirstChild("Items") or modulosFolder:FindFirstChild("Items")

local function getEvent(name)
	local ev = SAO_Events:FindFirstChild(name) or Instance.new("RemoteEvent", SAO_Events)
	ev.Name = name
	return ev
end

local LevelUpEvent = getEvent("SAO_LevelUpEvent")
local BuySkillEvent = getEvent("BuySkill")
local EquipSkillEvent = getEvent("EquipSkill")
local CastSkillEvent = getEvent("CastSkill")
local SyncBlockEvent = getEvent("SyncBlock")
local ConsumeItemEvent = getEvent("ConsumeItem")
local ChooseClassEvent = getEvent("ChooseClassEvent")
local VoiceCommandEvent = getEvent("VoiceCommandEvent")
local EquipOffhandEvent = getEvent("EquipOffhand")
local UnequipOffhandEvent = getEvent("UnequipOffhand")

-- ==========================================
-- 📊 DATOS POR DEFECTO
-- ==========================================
local DEFAULT_DATA = {
	Class = "Novato",
	Coins = 0,
	Level = 1,
	EXP = 0,
	MaxHP = 500, 
	MaxSP = 100,
	MaxMP = 100,
	STR = 10,
	AGI = 10,
	SIG = 5,
	StatPoints = 5,
	SkillPoints = 5,
	Inventory = {},
	IsInmortal = false,
	EquippedSkill = "",
	InDuel = false,
	RememberWeapon = true
	-- 📍 No definimos la posición aquí para que los jugadores nuevos usen el Spawn normal
}

local function GetMaxExpForLevel(level)
	return math.floor(1000 * (1.5 ^ (level - 1)))
end

-- ==========================================
-- 🧠 SISTEMA DE COMANDOS ADMIN (SYSTEM CALL)
-- ==========================================
local Admins = { ["IsaielmachetYT"] = true, ["OtroAmigoDesarrollador"] = true }

local function EjecutarSystemCall(player, mensaje)
	if not Admins[player.Name] then return end
	local args = string.split(mensaje, " ")
	local comando = string.lower(args[1])

	if comando == "system_call:itemadd" then
		if not ItemsFolder then warn("No Items folder") return end
		local nombreItem = table.concat(args, " ", 2)
		local item = ItemsFolder:FindFirstChild(nombreItem)
		if item and item:IsA("Tool") then
			item:Clone().Parent = player.Backpack
			print("✨ ADMIN: " .. player.Name .. " generó " .. nombreItem)
		end
	elseif comando == "system_call:unlockallskills" then
		for id, _ in pairs(Habilidades) do player:SetAttribute("Skill_" .. id, true) end
		print("✨ ADMIN: Habilidades desbloqueadas para " .. player.Name)
	elseif comando == "system_call:upgrade" then
		local cant = tonumber(args[2])
		if cant then
			player:SetAttribute("StatPoints", (player:GetAttribute("StatPoints") or 0) + cant)
			player:SetAttribute("SkillPoints", (player:GetAttribute("SkillPoints") or 0) + cant)
			print("✨ ADMIN: Puntos añadidos.")
		end
	elseif comando == "system_call:setlevel" then
		local lvl = tonumber(args[2])
		if lvl then
			player:SetAttribute("Level", lvl)
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.MaxHealth = 100 + (lvl * 20)
				player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
			end
		end
	elseif comando == "system_call:setsp" then
		local cant = tonumber(args[2])
		if cant then
			player:SetAttribute("MaxSP", cant); player:SetAttribute("SP", cant)
		end
	elseif comando == "system_call:sethp" then
		local cant = tonumber(args[2])
		if cant then
			player:SetAttribute("MaxHP", cant)
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.MaxHealth = cant
				player.Character.Humanoid.Health = cant
			end
		end
	elseif comando == "system_call:inmortal" then
		local esInmortal = player:GetAttribute("IsInmortal")
		player:SetAttribute("IsInmortal", not esInmortal)
		if player:GetAttribute("IsInmortal") then
			if player.Character then
				local ff = Instance.new("ForceField"); ff.Name = "EscudoAdmin"; ff.Visible = false; ff.Parent = player.Character
			end
			print("✨ ADMIN: INMORTAL activado.")
		else
			if player.Character and player.Character:FindFirstChild("EscudoAdmin") then player.Character.EscudoAdmin:Destroy() end
			print("✨ ADMIN: INMORTAL desactivado.")
		end
	end
end

-- ==========================================
-- ⚔️ FUNCIONES GLOBALES DE COMBATE Y EXP
-- ==========================================
_G.AplicarDanoSAO = function(victimHumanoid, damageAmount, attackerPlayer)
	local victimPlayer = Players:GetPlayerFromCharacter(victimHumanoid.Parent)
	if victimPlayer and victimPlayer:GetAttribute("IsInmortal") then return end

	if victimPlayer and victimPlayer:GetAttribute("InDuel") then
		if victimHumanoid.Health - damageAmount <= 1 then
			victimHumanoid.Health = 1
			victimPlayer:SetAttribute("InDuel", false)
			if attackerPlayer then attackerPlayer:SetAttribute("InDuel", false) end
			local msg = Instance.new("Message", workspace); msg.Text = "¡DUELO TERMINADO! Ganador: " .. (attackerPlayer and attackerPlayer.Name or "Desconocido")
			game.Debris:AddItem(msg, 4)
		else
			victimHumanoid:TakeDamage(damageAmount)
		end
	else
		victimHumanoid:TakeDamage(damageAmount)
	end

	local HitFeedbackEvent = ReplicatedStorage.SAO_Events:FindFirstChild("HitFeedback")
	if HitFeedbackEvent then
		HitFeedbackEvent:FireAllClients(victimHumanoid.Parent, attackerPlayer, victimHumanoid.Parent.HumanoidRootPart.Position, damageAmount)
	end
end

_G.DarExp = function(player, expGained)
	local currentExp = player:GetAttribute("EXP") or 0
	local currentLevel = player:GetAttribute("Level") or 1
	local maxExpRequired = GetMaxExpForLevel(currentLevel)

	currentExp += expGained

	if currentExp >= maxExpRequired then
		local expSobrante = currentExp - maxExpRequired
		local newLevel = currentLevel + 1

		player:SetAttribute("Level", newLevel)
		player:SetAttribute("EXP", expSobrante)

		player:SetAttribute("MaxHP", (player:GetAttribute("MaxHP") or 500) + 50)
		player:SetAttribute("STR", (player:GetAttribute("STR") or 10) + 2)
		player:SetAttribute("SkillPoints", (player:GetAttribute("SkillPoints") or 0) + 1)
		player:SetAttribute("StatPoints", (player:GetAttribute("StatPoints") or 0) + 3)

		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.MaxHealth = player:GetAttribute("MaxHP")
			player.Character.Humanoid.Health = player:GetAttribute("MaxHP")

			local highlight = Instance.new("Highlight", player.Character)
			highlight.FillColor = Color3.fromRGB(0, 255, 255)
			game.Debris:AddItem(highlight, 2)
		end

		print("🌟 LEVEL UP! " .. player.Name .. " es ahora nivel " .. newLevel)
		LevelUpEvent:FireClient(player, newLevel)

		_G.DarExp(player, 0)
	else
		player:SetAttribute("EXP", currentExp)
	end
end

-- ==========================================
-- 📥 CARGAR DATOS Y CONFIGURAR JUGADOR
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg) EjecutarSystemCall(player, msg) end)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"; leaderstats.Parent = player

	local coins = Instance.new("IntValue"); coins.Name = "Coins"; coins.Parent = leaderstats
	local level = Instance.new("IntValue"); level.Name = "Level"; level.Parent = leaderstats
	local playerClass = Instance.new("StringValue"); playerClass.Name = "Class"; playerClass.Parent = leaderstats

	-- Cargar DataStore de forma Segura
	local success, savedData = pcall(function() 
		return PlayerData:GetAsync(tostring(player.UserId)) 
	end)

	local data = {}
	for k, v in pairs(DEFAULT_DATA) do 
		if type(v) == "table" then data[k] = table.clone(v) else data[k] = v end 
	end

	if success and savedData then
		for k, v in pairs(savedData) do data[k] = v end

		-- 📍 Cargar coordenadas guardadas
		if savedData.LastPosX then
			player:SetAttribute("LastPosX", savedData.LastPosX)
			player:SetAttribute("LastPosY", savedData.LastPosY)
			player:SetAttribute("LastPosZ", savedData.LastPosZ)
		end
	end

	coins.Value = data.Coins
	level.Value = data.Level
	playerClass.Value = data.Class 

	-- Asignar Atributos
	for key, value in pairs(data) do
		if type(value) ~= "table" and key ~= "LastPosX" and key ~= "LastPosY" and key ~= "LastPosZ" then 
			player:SetAttribute(key, value) 
		end
	end

	player:SetAttribute("SP", player:GetAttribute("MaxSP"))
	player:SetAttribute("MP", player:GetAttribute("MaxMP"))

	for id, _ in pairs(Habilidades) do
		if player:GetAttribute("Skill_" .. id) == nil then player:SetAttribute("Skill_" .. id, false) end
	end

	-- 🛠️ FUNCIÓN PARA CARGAR EL PERSONAJE FÍSICO
	local function cargarPersonaje(character)
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 5)
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			if not humanoid or not hrp then return end

			task.wait(0.2) 

			-- 📍 TELETRANSPORTE A LA ÚLTIMA UBICACIÓN GUARDADA
			local lastX = player:GetAttribute("LastPosX")
			local lastY = player:GetAttribute("LastPosY")
			local lastZ = player:GetAttribute("LastPosZ")

			if lastX and lastY and lastZ then
				hrp.CFrame = CFrame.new(lastX, lastY, lastZ)

				-- Borramos las coordenadas temporales. 
				-- Así, si muere, reaparecerá en un SpawnLocation normal de la ciudad.
				player:SetAttribute("LastPosX", nil)
				player:SetAttribute("LastPosY", nil)
				player:SetAttribute("LastPosZ", nil)
			end

			if player:GetAttribute("IsInmortal") then
				local ff = Instance.new("ForceField"); ff.Name = "EscudoAdmin"; ff.Visible = false; ff.Parent = character
			end

			humanoid.MaxHealth = player:GetAttribute("MaxHP") or 500
			humanoid.Health = player:GetAttribute("MaxHP") or 500

			local currentClass = player:GetAttribute("Class") or "Novato"
			if currentClass == "Tanque" or currentClass == "Guerrero Pesado" then 
				humanoid.WalkSpeed = 12
			elseif currentClass == "Asesino" or currentClass == "Esgrimidor Ligero" then 
				humanoid.WalkSpeed = 18
			else 
				humanoid.WalkSpeed = 16 
			end

			-- 🗡️ DETECTAR ARMA EQUIPADA
			character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") then
					local weaponClass = child:GetAttribute("WeaponClass")
					if weaponClass then
						player:SetAttribute("CurrentWeaponClass", weaponClass)
					else
						player:SetAttribute("CurrentWeaponClass", "Desconocida")
					end
				end
			end)

			character.ChildRemoved:Connect(function(child)
				if child:IsA("Tool") then
					player:SetAttribute("CurrentWeaponClass", "Ninguna")
				end
			end)

			-- 🔥 REGENERACIÓN DE SP
			while character and character.Parent and humanoid.Health > 0 and player and player.Parent do
				task.wait(1)
				local curSP = player:GetAttribute("SP") or 0
				local maxSP = player:GetAttribute("MaxSP") or 100
				if curSP < maxSP then player:SetAttribute("SP", math.min(curSP + 5, maxSP)) end
			end
		end)
	end

	player.CharacterAdded:Connect(cargarPersonaje)

	if player.Character then
		cargarPersonaje(player.Character)
	end
end)

-- ==========================================
-- 📤 GUARDAR DATOS (AL SALIR)
-- ==========================================
local function savePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	-- 📍 OBTENER POSICIÓN AL DESCONECTARSE
	local posX = player:GetAttribute("LastPosX")
	local posY = player:GetAttribute("LastPosY")
	local posZ = player:GetAttribute("LastPosZ")

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hum = player.Character:FindFirstChild("Humanoid")
		-- Solo guardamos la posición si está vivo al salir
		if hum and hum.Health > 0 then
			local pos = player.Character.HumanoidRootPart.Position
			posX = pos.X
			posY = pos.Y
			posZ = pos.Z
		end
	end

	local dataToSave = {
		Class = player:GetAttribute("Class"), Coins = leaderstats.Coins.Value,
		Level = leaderstats.Level.Value, IsPK = player:GetAttribute("IsPK"),
		EXP = player:GetAttribute("EXP"), MaxHP = player:GetAttribute("MaxHP"),
		SP = player:GetAttribute("SP"), MaxSP = player:GetAttribute("MaxSP"),
		MP = player:GetAttribute("MP"), MaxMP = player:GetAttribute("MaxMP"),
		STR = player:GetAttribute("STR"), AGI = player:GetAttribute("AGI"),
		SIG = player:GetAttribute("SIG"), StatPoints = player:GetAttribute("StatPoints") or 0,
		SkillPoints = player:GetAttribute("SkillPoints") or 0, Inventory = player:GetAttribute("Inventory") or {},
		IsInmortal = player:GetAttribute("IsInmortal") or false,

		-- 📍 Guardamos coordenadas en el DataStore
		LastPosX = posX,
		LastPosY = posY,
		LastPosZ = posZ
	}
	pcall(function() PlayerData:SetAsync(tostring(player.UserId), dataToSave) end)
end

Players.PlayerRemoving:Connect(savePlayerData)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do savePlayerData(p) end; task.wait(2) end)

-- ==========================================
-- 📡 EVENTOS REMOTOS Y COMBATE
-- ==========================================
VoiceCommandEvent.OnServerEvent:Connect(function(player, textoReconocido)
	EjecutarSystemCall(player, textoReconocido)
end)

EquipSkillEvent.OnServerEvent:Connect(function(player, skillId)
	if player:GetAttribute("Skill_" .. skillId) then player:SetAttribute("EquippedSkill", skillId) end
end)

BuySkillEvent.OnServerEvent:Connect(function(player, skillId)
	local data = Habilidades[skillId]; if not data then return end
	local currentSPts = player:GetAttribute("SkillPoints") or 0; local level = player:GetAttribute("Level") or 1
	if not player:GetAttribute("Skill_" .. skillId) and currentSPts >= data.Costo and level >= data.NivelReq then
		player:SetAttribute("SkillPoints", currentSPts - data.Costo)
		player:SetAttribute("Skill_" .. skillId, true)
	end
end)

SyncBlockEvent.OnServerEvent:Connect(function(player, isBlocking, isParrying)
	if player.Character then player.Character:SetAttribute("IsBlocking", isBlocking); player.Character:SetAttribute("IsParrying", isParrying) end
end)

ConsumeItemEvent.OnServerEvent:Connect(function(player, itemName)
	local char = player.Character; if not char then return end
	local humanoid = char:FindFirstChild("Humanoid"); if not humanoid then return end
	local toolToConsume = player.Backpack:FindFirstChild(itemName)
	if toolToConsume then
		local maxHp = player:GetAttribute("MaxHP") or humanoid.MaxHealth
		humanoid.Health = math.clamp(humanoid.Health + (maxHp * 0.40), 0, maxHp)
		local torso = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		if torso then
			local emitter = Instance.new("ParticleEmitter", torso); emitter.Color = ColorSequence.new(Color3.fromRGB(50, 255, 100))
			emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
			emitter.Texture = "rbxassetid://5860841663"; emitter.EmissionDirection = Enum.NormalId.Top
			emitter.Speed = NumberRange.new(5, 10); emitter.Lifetime = NumberRange.new(1, 1.5); emitter.Rate = 100
			task.delay(0.5, function() emitter.Enabled = false; game.Debris:AddItem(emitter, 2) end)
		end
		toolToConsume:Destroy()
	end
end)

-- 🔥 CAST SKILL (ARREGLADO Y FUSIONADO)
CastSkillEvent.OnServerEvent:Connect(function(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local skillId = player:GetAttribute("EquippedSkill")
	if not skillId or skillId == "" then return end 

	local skillData = Habilidades[skillId]
	if not skillData then return end

	local currentWeaponClass = player:GetAttribute("CurrentWeaponClass") or "Ninguna"

	-- 🔒 VERIFICACIÓN DE ARMA
	if skillData.Para ~= "Artes Marciales" and skillData.Para ~= "Arrojadiza" and skillData.Para ~= "Todas" then
		if currentWeaponClass ~= skillData.Para then
			return 
		end
	end

	local currentSP = player:GetAttribute("SP") or 100
	local spCost = skillData.CostoSP or skillData.Costo or 30 

	if currentSP >= spCost then
		player:SetAttribute("SP", currentSP - spCost)

		local attachment = Instance.new("Attachment", hrp)
		local dashForce = Instance.new("LinearVelocity", attachment)
		dashForce.Attachment0 = attachment
		dashForce.MaxForce = math.huge

		local dashSpeed = skillData.VelocidadDash or 75
		dashForce.VectorVelocity = hrp.CFrame.LookVector * dashSpeed

		game.Debris:AddItem(attachment, 0.3)
		game.Debris:AddItem(dashForce, 0.3)

		local slashEmit = Instance.new("ParticleEmitter", hrp)
		slashEmit.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 50, 255))
		slashEmit.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)})
		slashEmit.Texture = "rbxassetid://5860841663"; slashEmit.EmissionDirection = Enum.NormalId.Back
		slashEmit.Rate = 800; slashEmit.Speed = NumberRange.new(15, 40); slashEmit.Lifetime = NumberRange.new(0.4, 0.8); slashEmit.Drag = 4
		game.Debris:AddItem(slashEmit, 0.5)

		local sfx = Instance.new("Sound", hrp); sfx.SoundId = "rbxassetid://6093393963"; sfx.Volume = 1.5; sfx:Play(); game.Debris:AddItem(sfx, 2)

		task.delay(0.3, function()
			local hitbox = Instance.new("Part")
			hitbox.Size = Vector3.new(12, 10, 12); hitbox.Position = hrp.Position + (hrp.CFrame.LookVector * 8)
			hitbox.Anchored = true; hitbox.CanCollide = false; hitbox.Transparency = 1; hitbox.Parent = workspace
			game.Debris:AddItem(hitbox, 1)

			local boomEmit = slashEmit:Clone(); boomEmit.Parent = hitbox; boomEmit.EmissionDirection = Enum.NormalId.Top
			boomEmit.Speed = NumberRange.new(20, 60); boomEmit.Rate = 0; boomEmit:Emit(150)

			local str = player:GetAttribute("STR") or 10; local damage = 40 + (str * 3.5)
			local params = OverlapParams.new(); params.FilterDescendantsInstances = {char}; params.FilterType = Enum.RaycastFilterType.Exclude

			local hitParts = workspace:GetPartsInPart(hitbox, params); local hitTargets = {}
			for _, part in ipairs(hitParts) do
				local targetHum = part.Parent:FindFirstChild("Humanoid")
				if targetHum and targetHum.Health > 0 and not hitTargets[part.Parent] then
					hitTargets[part.Parent] = true
					_G.AplicarDanoSAO(targetHum, damage, player)
					local hitEvent = ReplicatedStorage:FindFirstChild("SAO_HitEvent")
					if hitEvent then hitEvent:FireClient(player, part, part.Position, damage) end
				end
			end
		end)
	end
end)

ChooseClassEvent.OnServerEvent:Connect(function(player, classChoice)
	local clasesValidas = { 
		["Asesino"] = true, ["Tanque"] = true, ["Espadachin"] = true, 
		["Herrero"] = true, ["Domador"] = true, ["Esgrimidor Ligero"] = true, 
		["Lancero"] = true, ["Guerrero Pesado"] = true, ["Comerciante"] = true 
	}

	if clasesValidas[classChoice] and player:GetAttribute("Class") == "Novato" then
		player:SetAttribute("Class", classChoice)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Class") then 
			leaderstats.Class.Value = classChoice 
		end

		local baseSTR = player:GetAttribute("STR") or 10
		local baseAGI = player:GetAttribute("AGI") or 10
		local baseSIG = player:GetAttribute("SIG") or 5
		local baseHP = player:GetAttribute("MaxHP") or 500
		local walkSpeed = 16 

		if classChoice == "Asesino" then 
			player:SetAttribute("STR", baseSTR + 5)
			player:SetAttribute("AGI", baseAGI + 15)
			player:SetAttribute("SIG", baseSIG + 25)
			walkSpeed = 18
		elseif classChoice == "Tanque" then 
			player:SetAttribute("MaxHP", baseHP + 150)
			player:SetAttribute("STR", baseSTR + 20)
			walkSpeed = 12
		elseif classChoice == "Espadachin" then 
			player:SetAttribute("MaxHP", baseHP + 50)
			player:SetAttribute("STR", baseSTR + 15)
			player:SetAttribute("AGI", baseAGI + 10)
		elseif classChoice == "Herrero" then 
			player:SetAttribute("STR", baseSTR + 5)
			player:SetAttribute("AGI", baseAGI + 5)
			player:SetAttribute("Crafting", 10)
		elseif classChoice == "Domador" then 
			player:SetAttribute("MaxHP", baseHP + 30)
			player:SetAttribute("AGI", baseAGI + 5)
			player:SetAttribute("SIG", baseSIG + 10)
		elseif classChoice == "Esgrimidor Ligero" then 
			player:SetAttribute("STR", baseSTR + 10)
			player:SetAttribute("AGI", baseAGI + 20)
			player:SetAttribute("SIG", baseSIG + 5)
			walkSpeed = 18
		elseif classChoice == "Lancero" then 
			player:SetAttribute("MaxHP", baseHP + 50)
			player:SetAttribute("STR", baseSTR + 15)
			player:SetAttribute("AGI", baseAGI + 10)
		elseif classChoice == "Guerrero Pesado" then 
			player:SetAttribute("MaxHP", baseHP + 150)
			player:SetAttribute("STR", baseSTR + 20)
			walkSpeed = 12
		elseif classChoice == "Comerciante" then 
			player:SetAttribute("STR", baseSTR + 5)
			player:SetAttribute("AGI", baseAGI + 5)
			player:SetAttribute("Tasacion", 10)
		end

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then 
				humanoid.WalkSpeed = walkSpeed
				humanoid.MaxHealth = player:GetAttribute("MaxHP")
				humanoid.Health = humanoid.MaxHealth

				local highlight = Instance.new("Highlight", character)
				highlight.FillColor = Color3.fromRGB(255, 140, 0)
				game.Debris:AddItem(highlight, 1.5)
			end
		end

		print("✅ SISTEMA: " .. player.Name .. " ha avanzado a la clase " .. classChoice)
	end	
end)
