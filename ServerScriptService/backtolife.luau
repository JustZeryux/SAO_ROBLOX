local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("RequestRespawn")

remote.OnServerEvent:Connect(function(player, spawnName)
	player:LoadCharacter() -- Esto revive al jugador físicamente

	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local spawnPoint = workspace:FindFirstChild(spawnName, true)

	if spawnPoint and spawnPoint:IsA("SpawnLocation") then
		hrp.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
	end
end)

-- Esto asegura que aparezcas la primera vez que entras al juego
game.Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end)
