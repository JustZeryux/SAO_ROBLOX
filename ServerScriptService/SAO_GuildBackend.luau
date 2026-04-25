local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local guildRequest = Remotes:WaitForChild("GuildRequest")

-- Base de datos en memoria (En un juego final, esto se conecta a DataStoreService)
local ActiveGuilds = {} -- Formato: { ["Nights of Blood"] = { Leader = "Player1", Members = {"Player1"} } }
local PlayerGuilds = {} -- Búsqueda rápida: { ["Player1"] = "Nights of Blood" }

-- =========================================================
-- 🏷️ GENERADOR DE ETIQUETA SOBRE LA CABEZA (Overhead UI)
-- =========================================================
local function UpdateOverheadTag(character, playerName, guildName)
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	-- Limpiar etiqueta anterior si existe
	if head:FindFirstChild("SAO_Overhead") then
		head.SAO_Overhead:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SAO_Overhead"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0) -- Flota arriba de la cabeza
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	-- Nombre del Jugador
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = playerName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboard

	-- Nombre del Gremio (Si tiene)
	if guildName then
		local guildLabel = Instance.new("TextLabel")
		guildLabel.Size = UDim2.new(1, 0, 0.5, 0)
		guildLabel.Position = UDim2.new(0, 0, 0.5, 0)
		guildLabel.BackgroundTransparency = 1
		guildLabel.Text = "<" .. guildName .. ">"
		guildLabel.TextColor3 = Color3.fromRGB(255, 170, 0) -- Color dorado/naranja típico de gremios
		guildLabel.Font = Enum.Font.GothamSemibold
		guildLabel.TextSize = 12
		guildLabel.TextStrokeTransparency = 0.5
		guildLabel.Parent = billboard
	end
end

-- Asignar etiqueta cuando el jugador aparece
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local currentGuild = PlayerGuilds[player.Name]
		UpdateOverheadTag(character, player.Name, currentGuild)
	end)
end)

-- Base de datos en memoria 
local ActiveGuilds = {} 
local PlayerGuilds = {} 
local PendingInvites = {} -- 🔥 NUEVO: Guarda quién invitó a quién

-- =========================================================
-- 🛡️ API DEL GREMIO COMPLETA (Crear / Invitar / Aceptar)
-- =========================================================
local guildInviteEvent = Remotes:WaitForChild("GuildInviteEvent")

guildRequest.OnServerInvoke = function(player, action, data)
	-- 1. CREAR GREMIO
	if action == "Create" then
		if PlayerGuilds[player.Name] then return false, "Ya estás en un gremio." end
		if string.len(data) < 3 or string.len(data) > 20 then return false, "Nombre inválido." end
		if ActiveGuilds[data] then return false, "El nombre del gremio ya existe." end

		ActiveGuilds[data] = { Leader = player.Name, Members = {player.Name} }
		PlayerGuilds[player.Name] = data

		if player.Character then UpdateOverheadTag(player.Character, player.Name, data) end
		return true, "¡Gremio creado exitosamente!"
	end

	-- 2. INVITAR JUGADOR (Solo el líder puede)
	if action == "Invite" then
		local targetName = data
		local myGuild = PlayerGuilds[player.Name]

		if not myGuild then return false, "No estás en ningún gremio." end
		if ActiveGuilds[myGuild].Leader ~= player.Name then return false, "Solo el líder puede invitar." end

		local targetPlayer = Players:FindFirstChild(targetName)
		if not targetPlayer then return false, "El jugador no está en el servidor." end
		if PlayerGuilds[targetName] then return false, "Ese jugador ya tiene un gremio." end

		-- Guardamos la invitación y le disparamos el popup al otro jugador
		PendingInvites[targetName] = myGuild
		guildInviteEvent:FireClient(targetPlayer, myGuild, player.Name)

		return true, "Invitación enviada a " .. targetName
	end

	-- 3. ACEPTAR INVITACIÓN
	if action == "Accept" then
		local guildToJoin = PendingInvites[player.Name]
		if not guildToJoin then return false, "No tienes invitaciones pendientes." end
		if PlayerGuilds[player.Name] then return false, "Ya estás en un gremio." end
		if not ActiveGuilds[guildToJoin] then return false, "Este gremio ya no existe." end

		-- Lo agregamos a la base de datos
		PlayerGuilds[player.Name] = guildToJoin
		table.insert(ActiveGuilds[guildToJoin].Members, player.Name)
		PendingInvites[player.Name] = nil -- Borramos la invitación

		if player.Character then UpdateOverheadTag(player.Character, player.Name, guildToJoin) end
		return true, "Te has unido a " .. guildToJoin
	end

	return false, "Acción desconocida."
end
