local ReplicatedStorage = game:GetService("ReplicatedStorage")
local respawnEvent = ReplicatedStorage:WaitForChild("RespawnRequest")

respawnEvent.OnServerEvent:Connect(function(player, spawnName)
	local spawnPoint = workspace:FindFirstChild(spawnName, true)

	if spawnPoint and spawnPoint:IsA("SpawnLocation") then
		player:LoadCharacter() -- Revive al jugador
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:WaitForChild("HumanoidRootPart")

		-- Teletransporte inmediato al spawn elegido
		root.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
	end
end)
