local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- Para generar IDs únicos
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local partyRequest = Remotes:WaitForChild("PartyRequest")
local partyInviteEvent = Remotes:WaitForChild("PartyInviteEvent")

local ActiveParties = {} -- [PartyID] = {Leader, Members = {}}
local PendingInvites = {} 

-- =========================================================
-- 🛡️ LÓGICA DE PARTY Y FUEGO AMIGO
-- =========================================================
partyRequest.OnServerInvoke = function(player, action, targetName)
	-- 1. INVITAR A UN JUGADOR
	if action == "Invite" then
		if player.Name == targetName then return false, "No puedes invitarte a ti mismo." end

		local targetPlayer = Players:FindFirstChild(targetName)
		if not targetPlayer then return false, "Jugador no encontrado." end

		if targetPlayer:GetAttribute("PartyID") then return false, "Ese jugador ya está en un grupo." end

		-- Crear la invitación
		PendingInvites[targetName] = player.Name
		partyInviteEvent:FireClient(targetPlayer, player.Name)
		return true, "Invitación enviada."
	end

	-- 2. ACEPTAR INVITACIÓN
	if action == "Accept" then
		local leaderName = PendingInvites[player.Name]
		if not leaderName then return false, "No tienes invitaciones." end

		local leaderPlayer = Players:FindFirstChild(leaderName)
		if not leaderPlayer then return false, "El líder se desconectó." end

		-- Si el líder no tiene grupo aún, creamos uno nuevo
		local partyID = leaderPlayer:GetAttribute("PartyID")
		if not partyID then
			partyID = HttpService:GenerateGUID(false) -- Crea un ID único
			ActiveParties[partyID] = {Leader = leaderName, Members = {leaderName}}
			leaderPlayer:SetAttribute("PartyID", partyID)
		end

		-- Verificamos el límite del grupo (Ej: Máximo 4 jugadores)
		if #ActiveParties[partyID].Members >= 4 then return false, "El grupo está lleno." end

		-- Agregar al nuevo jugador
		table.insert(ActiveParties[partyID].Members, player.Name)
		player:SetAttribute("PartyID", partyID)
		PendingInvites[player.Name] = nil

		-- Avisar a todos los miembros que alguien entró para actualizar sus pantallas
		for _, memberName in ipairs(ActiveParties[partyID].Members) do
			local member = Players:FindFirstChild(memberName)
			if member then partyInviteEvent:FireClient(member, "UpdateUI", ActiveParties[partyID].Members) end
		end

		return true, "Te has unido al grupo."
	end

	-- 3. SALIR DEL GRUPO
	if action == "Leave" then
		local partyID = player:GetAttribute("PartyID")
		if not partyID or not ActiveParties[partyID] then return false, "No estás en un grupo." end

		-- Remover de la tabla
		local members = ActiveParties[partyID].Members
		for i, memberName in ipairs(members) do
			if memberName == player.Name then table.remove(members, i) break end
		end

		player:SetAttribute("PartyID", nil)
		partyInviteEvent:FireClient(player, "UpdateUI", {}) -- Limpiar su pantalla

		-- Si el grupo se quedó vacío, lo borramos
		if #members == 0 then
			ActiveParties[partyID] = nil
		else
			-- Avisar a los que se quedaron
			for _, memberName in ipairs(members) do
				local member = Players:FindFirstChild(memberName)
				if member then partyInviteEvent:FireClient(member, "UpdateUI", members) end
			end
		end
		return true, "Has salido del grupo."
	end
end

-- Limpiar si un jugador se sale del juego
Players.PlayerRemoving:Connect(function(player)
	local partyID = player:GetAttribute("PartyID")
	if partyID then
		-- Misma lógica que "Leave" pero automática
		local members = ActiveParties[partyID].Members
		for i, memberName in ipairs(members) do
			if memberName == player.Name then table.remove(members, i) break end
		end
		if #members == 0 then ActiveParties[partyID] = nil end
	end
end)
