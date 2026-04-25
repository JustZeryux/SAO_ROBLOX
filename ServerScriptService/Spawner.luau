local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Buscamos el evento que tu LocalScript está disparando
local respawnEvent = ReplicatedStorage:WaitForChild("RespawnEvent")

respawnEvent.OnServerEvent:Connect(function(player, locationName)
	-- 1. Revivimos al jugador (esto crea un nuevo personaje)
	player:LoadCharacter()

	-- 2. Esperamos a que el personaje cargue en el mundo
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- 3. Buscamos el punto de aparición (Spawn) en el Workspace
	-- NOTA: Asegúrate de tener partes o SpawnLocations en tu Workspace 
	-- que se llamen EXACTAMENTE igual que locationName (ej. "Ciudad", "Bosque")
	local spawnPoint = Workspace:FindFirstChild(locationName)

	if spawnPoint then
		-- Si existe, lo teletransportamos ahí (le sumamos 5 en Y para que no se atore en el piso)
		-- Añadimos un pequeño retraso (task.wait) para asegurarnos de que el motor físico lo mueva bien
		task.wait(0.1) 
		rootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
	else
		warn("⚠️ El servidor no encontró un punto de aparición llamado: " .. tostring(locationName))
	end
end)
