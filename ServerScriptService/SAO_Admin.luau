local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ultimoTextoRecibido = {}	
local Admins = {
	["IsaielmachetYT"] = true,
	["Kilevn"] = true
}

local modulosFolder = ReplicatedStorage:WaitForChild("SAO_Modules")
local HabilidadesData = require(modulosFolder:WaitForChild("Habilidades"))
local ItemsFolder = ReplicatedStorage:FindFirstChild("Items") or modulosFolder:FindFirstChild("Items")
local MobsFolder = ReplicatedStorage:FindFirstChild("Mobs") 

local SAO_Events = ReplicatedStorage:FindFirstChild("SAO_Events") or Instance.new("Folder", ReplicatedStorage)
SAO_Events.Name = "SAO_Events"

-- Eventos Remotos
local AdminPanelEvent = SAO_Events:FindFirstChild("AdminPanelEvent") or Instance.new("RemoteEvent", SAO_Events)
AdminPanelEvent.Name = "AdminPanelEvent"

local GlobalAlertEvent = SAO_Events:FindFirstChild("GlobalAlertEvent") or Instance.new("RemoteEvent", SAO_Events)
GlobalAlertEvent.Name = "GlobalAlertEvent"

-- Usamos esta variable si tuvieras un evento remoto exclusivo para la voz
local VoiceCommandEvent = SAO_Events:FindFirstChild("VoiceCommandEvent")

local ultimoComando = {}

local function BuscarItemSuperInteligente(frase)
	if not ItemsFolder then return nil end
	local palabrasFrase = string.split(frase, " ")
	for _, item in ipairs(ItemsFolder:GetChildren()) do
		local nombreLimpio = string.lower(string.gsub(item.Name, "[%_%s+]", ""))
		for _, palabra in ipairs(palabrasFrase) do
			if #palabra > 3 and string.find(nombreLimpio, palabra) then return item end
		end
	end
	return nil
end

local function EnviarNotificacionSAO(player, titulo, mensajeTexto)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local screenGui = Instance.new("ScreenGui", playerGui); screenGui.Name = "SAO_Alert"
	local frame = Instance.new("Frame", screenGui)
	frame.Size = UDim2.new(0, 300, 0, 80); frame.Position = UDim2.new(1, 350, 0, 20)
	frame.AnchorPoint = Vector2.new(1, 0); frame.BackgroundColor3 = Color3.fromRGB(130, 0, 0)
	frame.BorderColor3 = Color3.fromRGB(255, 50, 50); frame.BorderSizePixel = 2
	local t = Instance.new("TextLabel", frame)
	t.Size = UDim2.new(1, -10, 0, 25); t.Position = UDim2.new(0, 5, 0, 5); t.BackgroundTransparency = 1
	t.Text = "⚠️ " .. titulo; t.TextColor3 = Color3.new(1, 1, 1); t.Font = Enum.Font.Code; t.TextScaled = true
	local d = Instance.new("TextLabel", frame)
	d.Size = UDim2.new(1, -10, 0, 40); d.Position = UDim2.new(0, 5, 0, 35); d.BackgroundTransparency = 1
	d.Text = mensajeTexto; d.TextColor3 = Color3.fromRGB(255, 200, 200); d.TextWrapped = true; d.Font = Enum.Font.Gotham
	TweenService:Create(frame, TweenInfo.new(0.5), {Position = UDim2.new(1, -20, 0, 20)}):Play()
	task.delay(4, function()
		local out = TweenService:Create(frame, TweenInfo.new(0.5), {Position = UDim2.new(1, 350, 0, 20)})
		out:Play(); out.Completed:Connect(function() screenGui:Destroy() end)
	end)
end

-- =========================================================
-- ✨ FUNCIÓN MAESTRA DEL SYSTEM CALL
-- =========================================================
local function EjecutarSystemCall(player, mensaje)
	if not Admins[player.Name] then return end

	-- PARCHE PARA EL MICRÓFONO ACUMULATIVO:
	-- Si el mensaje nuevo contiene el mensaje anterior, le restamos la parte vieja
	local msgProcesar = mensaje
	local textoAnterior = ultimoTextoRecibido[player.UserId]

	if textoAnterior and string.sub(mensaje, 1, #textoAnterior) == textoAnterior then
		msgProcesar = string.sub(mensaje, #textoAnterior + 1) -- Nos quedamos solo con lo nuevo
	end

	ultimoTextoRecibido[player.UserId] = mensaje -- Guardamos el historial completo actual

	-- Ahora usamos 'msgProcesar' en lugar de 'mensaje' para todo lo demás
	local m = string.lower(msgProcesar)
	m = string.gsub(m, "[%.,!%?]", "") 

	print("🔍 Analizando comando limpio: '" .. m .. "'")

	-- 2. Validación de Activación (Soporta múltiples errores comunes del micrófono)
	local isEng = string.find(m, "system call") or string.find(m, "call the system") or string.find(m, "system code")
	local isSpa = string.find(m, "llamado al sistema") or string.find(m, "llamar al sistema")

	if not isEng and not isSpa then return end
	ultimoComando[player.UserId] = t
	print("📡 System Call validado de " .. player.Name .. " | Comando interpretado: " .. m)

	-- 📢 ANUNCIO GLOBAL
	if string.match(m, "announce") or string.match(m, "anuncio") then
		local splitStr = isEng and "announce" or "anuncio"
		local parts = string.split(m, splitStr)
		if parts[2] then
			GlobalAlertEvent:FireAllClients("ANUNCIO DEL SISTEMA", parts[2]:upper())
			return
		end
	end

	-- ⏰ CAMBIAR TIEMPO
	if string.match(m, "time") or string.match(m, "tiempo") then
		local num = tonumber(string.match(m, "%d+"))
		if num then
			Lighting.ClockTime = num
			EnviarNotificacionSAO(player, "WORLD OVERRIDE", "Hora cambiada a " .. num .. ":00")
			return
		end
	end

	-- ☠️ KILL (Busca el nombre del jugador en cualquier parte de la frase)
	if string.match(m, "kill") or string.match(m, "matar") then
		for _, v in ipairs(Players:GetPlayers()) do
			if string.find(m, string.lower(v.Name)) and v.Character and v.Character:FindFirstChild("Humanoid") then
				v.Character.Humanoid.Health = 0
				EnviarNotificacionSAO(player, "EXECUTION", "Jugador " .. v.Name .. " eliminado.")
				return
			end
		end
	end

	-- 👢 KICK
	if string.match(m, "kick") or string.match(m, "expulsar") then
		for _, v in ipairs(Players:GetPlayers()) do
			if string.find(m, string.lower(v.Name)) then
				v:Kick("Has sido expulsado por un Administrador del Sistema.")
				EnviarNotificacionSAO(player, "BANISHMENT", "Jugador " .. v.Name .. " expulsado.")
				return
			end
		end
	end

	-- 🧲 BRING
	if string.match(m, "bring") or string.match(m, "traer") then
		for _, v in ipairs(Players:GetPlayers()) do
			if string.find(m, string.lower(v.Name)) and v.Character and player.Character then
				v.Character:PivotTo(player.Character.PrimaryPart.CFrame * CFrame.new(0, 0, -5))
				EnviarNotificacionSAO(player, "TELEPORTATION", "Jugador " .. v.Name .. " traído a ti.")
				return
			end
		end
	end

	-- ❄️ FREEZE
	if string.match(m, "freeze") or string.match(m, "congelar") then
		for _, v in ipairs(Players:GetPlayers()) do
			if string.find(m, string.lower(v.Name)) and v.Character then
				local hum = v.Character:FindFirstChild("Humanoid")
				if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
				EnviarNotificacionSAO(player, "PARALYSIS EFFECT", "Jugador " .. v.Name .. " inmovilizado.")
				return
			end
		end
	end

	-- 🔥 UNFREEZE
	if string.match(m, "unfreeze") or string.match(m, "liberar") then
		for _, v in ipairs(Players:GetPlayers()) do
			if string.find(m, string.lower(v.Name)) and v.Character then
				local hum = v.Character:FindFirstChild("Humanoid")
				if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
				EnviarNotificacionSAO(player, "STATUS CLEARED", "Jugador " .. v.Name .. " liberado.")
				return
			end
		end
	end

	-- 👻 INVISIBLE
	if string.match(m, "invisible") or string.match(m, "fantasma") then
		for _, part in ipairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 1
			elseif part:IsA("Decal") then
				part.Transparency = 1
			end
		end
		EnviarNotificacionSAO(player, "STEALTH MODE", "Invisibilidad ACTIVADA.")
	end

	-- 🧹 WIPE
	if string.match(m, "wipe") or string.match(m, "limpiar") then
		local contador = 0
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
				obj:Destroy()
				contador = contador + 1
			end
		end
		EnviarNotificacionSAO(player, "WORLD PURGE", "Eliminadas " .. contador .. " entidades.")
		return
	end

	-- 🗡️ ITEM ADD
	if string.match(m, "item") or string.match(m, "add") or string.match(m, "give") then
		local item = BuscarItemSuperInteligente(m)
		if item then
			item:Clone().Parent = player.Backpack
			EnviarNotificacionSAO(player, "SYSTEM OVERRIDE", "Item añadido: " .. item.Name)
			return
		else
			print("❌ Item no encontrado en ReplicatedStorage")
		end
	end

	-- 🐉 SUMMON (Busca el nombre del mob en cualquier parte de la frase)
	if string.match(m, "summon") or string.match(m, "invocar") then
		if MobsFolder then
			for _, mob in ipairs(MobsFolder:GetChildren()) do
				local mobLimpio = string.lower(string.gsub(mob.Name, "[%_%s+]", ""))
				if string.find(m, mobLimpio) then
					local clon = mob:Clone()
					clon:PivotTo(player.Character.PrimaryPart.CFrame * CFrame.new(0, 0, -10))
					clon.Parent = workspace
					EnviarNotificacionSAO(player, "ENTITY SUMMONED", "Invocado: " .. mob.Name)
					return
				end
			end
			print("❌ Mob no encontrado en la carpeta Mobs")
		else
			warn("❌ ERROR: No existe la carpeta 'Mobs' en ReplicatedStorage")
		end
	end

	-- ✨ UNLOCK SKILLS
	if string.match(m, "unlock") or string.match(m, "habilidad") then
		for id, _ in pairs(HabilidadesData) do player:SetAttribute("Skill_" .. id, true) end
		EnviarNotificacionSAO(player, "SYSTEM OVERRIDE", "Habilidades desbloqueadas.")

		-- 📊 ESTADÍSTICAS
	elseif string.match(m, "set") then
		local num = tonumber(string.match(m, "%d+"))
		if num then
			if string.match(m, "hp") or string.match(m, "vida") then
				player.Character.Humanoid.MaxHealth = num; player.Character.Humanoid.Health = num
			elseif string.match(m, "sp") then
				player:SetAttribute("MaxSP", num); player:SetAttribute("SP", num)
			elseif string.match(m, "level") or string.match(m, "nivel") then
				player:SetAttribute("Level", num)
			end
			EnviarNotificacionSAO(player, "STAT OVERRIDE", "Estadística actualizada a " .. num)
		end

		-- 💚 UTLIDADES BÁSICAS
	elseif string.match(m, "heal") or string.match(m, "curar") then
		player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
		player:SetAttribute("SP", player:GetAttribute("MaxSP") or 100)
		EnviarNotificacionSAO(player, "RECOVERY", "Restaurado al 100%.")
	elseif string.match(m, "speed") or string.match(m, "velocidad") then
		local s = tonumber(string.match(m, "%d+")) or 50
		player.Character.Humanoid.WalkSpeed = s
		EnviarNotificacionSAO(player, "PHYSICS OVERRIDE", "Velocidad: " .. s)
	elseif string.match(m, "inmortal") or string.match(m, "god") then
		local s = not player:GetAttribute("IsInmortal")
		player:SetAttribute("IsInmortal", s)
		if s then Instance.new("ForceField", player.Character).Name = "EscudoAdmin"
		elseif player.Character:FindFirstChild("EscudoAdmin") then player.Character.EscudoAdmin:Destroy() end
		EnviarNotificacionSAO(player, "GOD MODE", s and "ACTIVADO" or "DESACTIVADO")
	end
end

-- =========================================================
-- CONEXIONES DE EVENTOS
-- =========================================================

-- Conexión para el Chat de Texto normal
Players.PlayerAdded:Connect(function(p)
	p.Chatted:Connect(function(msg) 
		EjecutarSystemCall(p, msg) 
	end)
end)

-- Conexión para el Chat de Voz (Opcional: Si este script maneja la voz)
if VoiceCommandEvent then
	VoiceCommandEvent.OnServerEvent:Connect(function(player, commandStr)
		-- Ejecutamos la misma función maestra, el servidor no discrimina si viene de voz o texto
		EjecutarSystemCall(player, commandStr)
	end)
end

-- Conexión para el Panel de Administrador (UI)
AdminPanelEvent.OnServerEvent:Connect(function(player)
	if Admins[player.Name] then
		AdminPanelEvent:FireClient(player)
	end
end)
