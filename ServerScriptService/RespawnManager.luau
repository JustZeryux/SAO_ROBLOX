local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Apagamos el respawn automático de Roblox
Players.CharacterAutoLoads = false

-- 2. Creamos el Evento para que los botones se comuniquen con el servidor
local respawnEvent = Instance.new("RemoteEvent")
respawnEvent.Name = "RespawnEvent"
respawnEvent.Parent = ReplicatedStorage

-- 3. Cuando un jugador entra al juego, lo spawneamos por primera vez
Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end)

-- 4. Cuando el jugador le da click a un botón en la UI de muerte
respawnEvent.OnServerEvent:Connect(function(player, location)
	-- Revivimos al jugador
	player:LoadCharacter()

	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		-- Aquí puedes teletransportarlo dependiendo del botón que tocó
		if location == "RespawnHere" then
			print(player.Name .. " revivió en su lugar de muerte.")
			-- Nota: Para esto necesitarías guardar la posición de su muerte antes
		elseif location == "Lobby" then
			print(player.Name .. " revivió en el Lobby.")
			-- char.HumanoidRootPart.CFrame = workspace.LobbySpawn.CFrame
		end
	end
end)
