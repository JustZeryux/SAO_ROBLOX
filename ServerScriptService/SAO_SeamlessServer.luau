local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local interiorFade = Remotes:WaitForChild("InteriorFade")

local doorsFolder = workspace:WaitForChild("SeamlessDoors")

-- Evitar que el jugador se teletransporte infinitamente si toca la puerta 2 veces rápido
local debounceCooldowns = {}

for _, door in ipairs(doorsFolder:GetChildren()) do
	if door:IsA("BasePart") then
		door.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character:FindFirstChild("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoid and rootPart and humanoid.Health > 0 then
				local player = Players:GetPlayerFromCharacter(character)
				if player then
					-- Verificamos el Debounce
					if debounceCooldowns[player.Name] and tick() - debounceCooldowns[player.Name] < 2 then
						return -- Aún está en cooldown
					end
					debounceCooldowns[player.Name] = tick()

					-- Buscamos el destino
					local targetName = door:FindFirstChild("Target")
					if targetName and targetName.Value ~= "" then
						local destinationDoor = doorsFolder:FindFirstChild(targetName.Value)

						if destinationDoor then
							-- 1. Le decimos al cliente que oscurezca la pantalla
							interiorFade:FireClient(player, "FadeOut")

							-- 2. Esperamos un instante (0.3s) a que la pantalla esté negra
							task.wait(0.3)

							-- 3. Movemos al personaje físicamente al destino (ligeramente al frente para que no toque la otra puerta)
							local destCFrame = destinationDoor.CFrame * CFrame.new(0, 0, -4)
							character:PivotTo(destCFrame)

							-- 4. Le decimos al cliente que quite la pantalla negra
							interiorFade:FireClient(player, "FadeIn")
						end
					end
				end
			end
		end)
	end
end
