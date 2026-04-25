local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")

-- RemoteFunction para que el líder pida cambiar una sala
local roomRequest = Instance.new("RemoteFunction")
roomRequest.Name = "GuildRoomRequest"
roomRequest.Parent = Remotes

local roomModels = ReplicatedStorage.Models:WaitForChild("GuildRooms")

-- Estado actual de las sedes (En un futuro esto iría a DataStores)
-- Formato: [GuildName] = { [SlotID] = "RoomName" }
local GuildHallStates = {}

-- =========================================================
-- ✨ EFECTO DE MATERIALIZACIÓN (Smooth Spawn)
-- =========================================================
local function SpawnRoomSmoothly(model, slotPart)
	local newRoom = model:Clone()
	newRoom:PivotTo(slotPart.CFrame)
	newRoom.Parent = slotPart

	-- Efecto de aparición: Todas las partes empiezan invisibles y se vuelven sólidas
	for _, part in ipairs(newRoom:GetDescendants()) do
		if part:IsA("BasePart") then
			local originalTransparency = part.Transparency
			part.Transparency = 1
			TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = originalTransparency}):Play()
		end
	end
	return newRoom
end

-- =========================================================
-- 🛠️ LÓGICA DE GESTIÓN DE SALAS
-- =========================================================
roomRequest.OnServerInvoke = function(player, action, slotID, roomName)
	-- 1. Verificar si el jugador es líder de gremio (Usando el sistema de Gremios anterior)
	-- Suponiendo que el Gremio se guarda en un Atributo del jugador
	local guildName = player:GetAttribute("GuildName")
	if not guildName then return false, "No perteneces a un gremio." end

	-- Aquí validarías si el jugador es el Leader en tu tabla de Gremios

	if action == "UpdateRoom" then
		-- 2. Buscar el Slot físico en el mundo
		local slot = nil
		for _, s in ipairs(workspace:GetDescendants()) do
			if s.Name == "RoomSlot" and s:FindFirstChild("SlotID") and s.SlotID.Value == slotID then
				slot = s
				break
			end
		end

		if not slot then return false, "Espacio de sala no encontrado." end

		-- 3. Limpiar sala anterior
		for _, child in ipairs(slot:GetChildren()) do
			if child:IsA("Model") then child:Destroy() end
		end

		-- 4. Spawnear la nueva
		local template = roomModels:FindFirstChild(roomName)
		if template then
			SpawnRoomSmoothly(template, slot)
			return true, "Sala actualizada: " .. roomName
		end
	end

	return false, "Error al actualizar."
end
