local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local bountyRequest = Remotes:WaitForChild("BountyRequest")

-- Base de datos de criminales: { ["Nombre"] = Cantidad_De_Recompensa }
local ActiveBounties = {}

-- =========================================================
-- 🔴 1. SISTEMA DE PLAYER KILLERS (PK) Y ETIQUETAS ROJAS
-- =========================================================
local function MarkAsPKer(player, amount)
	ActiveBounties[player.Name] = (ActiveBounties[player.Name] or 0) + amount
	print(player.Name .. " ahora es un Jugador Rojo. Recompensa: " .. ActiveBounties[player.Name])

	-- Actualizar su Overhead Tag (El texto sobre su cabeza) para que sea Rojo SAO
	if player.Character and player.Character:FindFirstChild("Head") then
		local overhead = player.Character.Head:FindFirstChild("SAO_Overhead")
		if overhead and overhead:FindFirstChild("TextLabel") then
			overhead.TextLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- ROJO CRIMINAL
		end
	end
end

-- =========================================================
-- ⚔️ 2. DETECCIÓN DE ASESINATOS
-- =========================================================
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- Si este jugador entra y ya era criminal, lo volvemos a pintar de rojo
		if ActiveBounties[player.Name] then
			task.delay(1, function() MarkAsPKer(player, 0) end)
		end

		humanoid.Died:Connect(function()
			-- Detectar quién lo mató usando un "creator tag" que pondremos en el combate
			local tag = humanoid:FindFirstChild("creator")
			if tag and tag.Value then
				local killer = tag.Value

				-- 1. Si el asesinado era un PKer (Rojo) y el asesino es alguien más
				if ActiveBounties[player.Name] and killer ~= player then
					local reward = ActiveBounties[player.Name]
					-- Aquí le darías el dinero al asesino (Ej: _G.PlayerMoney[killer.Name] += reward)
					print(killer.Name .. " cobró la recompensa de " .. reward .. " Col por matar a " .. player.Name)

					-- Limpiamos al criminal
					ActiveBounties[player.Name] = nil

					-- 2. Si el asesinado era Inocente (Verde) y lo mató un jugador
				elseif not ActiveBounties[player.Name] and killer ~= player then
					-- El asesino se vuelve rojo y gana 1000 de Bounty
					MarkAsPKer(killer, 1000)
				end
			end
		end)
	end)
end)

-- =========================================================
-- 📋 3. ENVIAR DATOS AL TABLERO
-- =========================================================
bountyRequest.OnServerInvoke = function(player)
	-- Para el tablero de recompensas, no solo enviamos los nombres, 
	-- sino la instancia del personaje para que el cliente calcule la distancia real
	local boardData = {}
	for pkName, amount in pairs(ActiveBounties) do
		local pkPlayer = Players:FindFirstChild(pkName)
		if pkPlayer and pkPlayer.Character and pkPlayer.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(boardData, {
				Name = pkName,
				Bounty = amount,
				RootPart = pkPlayer.Character.HumanoidRootPart
			})
		end
	end
	return boardData
end

-- MOCKUP: Tecla para auto-volverte rojo y probar el sistema (Borrar en versión final)
-- Si abres la consola y pones: game.Players.TuNombre.Character.Humanoid:TakeDamage(100) no pasará nada a menos que haya un tag.
