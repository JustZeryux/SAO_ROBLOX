local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Asegúrate de tener un Dummy R6 en ReplicatedStorage con este nombre exacto
local R6DummyTemplate = ReplicatedStorage:WaitForChild("R6Dummy")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Esperamos a que el personaje cargue por completo
		task.wait(0.1)

		-- Si ya es R6, cancelamos para no hacer un bucle infinito
		if humanoid.RigType == Enum.HumanoidRigType.R6 then return end

		-- Evitamos que el script se ejecute múltiples veces de golpe
		if player:GetAttribute("ConvirtiendoR6") then return end
		player:SetAttribute("ConvirtiendoR6", true)

		-- Clonamos nuestro modelo R6 base
		local nuevoCuerpoR6 = R6DummyTemplate:Clone()
		nuevoCuerpoR6.Name = player.Name

		-- Obtenemos la ropa, caras y accesorios del jugador actual
		local currentDescription = humanoid:GetAppliedDescription()
		local nuevoHumanoid = nuevoCuerpoR6:WaitForChild("Humanoid")

		-- Le aplicamos su ropa al cuerpo cuadrado
		nuevoHumanoid:ApplyDescription(currentDescription)

		-- Posicionamos el nuevo cuerpo donde estaba el viejo
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			nuevoCuerpoR6:SetPrimaryPartCFrame(rootPart.CFrame)
		end

		-- Reemplazamos el personaje del jugador
		player.Character = nuevoCuerpoR6
		nuevoCuerpoR6.Parent = workspace

		-- Liberamos el candado
		player:SetAttribute("ConvirtiendoR6", false)
	end)
end)
