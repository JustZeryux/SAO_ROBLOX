local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local armWrestleEvent = Remotes:WaitForChild("ArmWrestleEvent")

-- Estado de las mesas: { [table] = { P1 = player, P2 = player, Score = 50, Active = false } }
local Tables = {}

-- =========================================================
-- 🪑 1. SENTARSE Y EMPAREJAR
-- =========================================================
local function SetupTables()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "ArmWrestlingTable" then
			Tables[obj] = { P1 = nil, P2 = nil, Score = 50, Active = false }

			local s1 = obj:FindFirstChild("Seat1")
			local s2 = obj:FindFirstChild("Seat2")

			if s1 and s1:FindFirstChild("SitPrompt") then
				s1.SitPrompt.Triggered:Connect(function(player)
					if not Tables[obj].P1 and not Tables[obj].Active then
						Tables[obj].P1 = player
						s1.SitPrompt.Enabled = false
						print(player.Name .. " se sentó en el Asiento 1")
						CheckStartMatch(obj)
					end
				end)
			end

			if s2 and s2:FindFirstChild("SitPrompt") then
				s2.SitPrompt.Triggered:Connect(function(player)
					if not Tables[obj].P2 and not Tables[obj].Active then
						Tables[obj].P2 = player
						s2.SitPrompt.Enabled = false
						print(player.Name .. " se sentó en el Asiento 2")
						CheckStartMatch(obj)
					end
				end)
			end
		end
	end
end

-- =========================================================
-- 🏁 2. INICIAR PARTIDA
-- =========================================================
function CheckStartMatch(tableObj)
	local tData = Tables[tableObj]
	if tData.P1 and tData.P2 and not tData.Active then
		tData.Active = true
		tData.Score = 50 -- 50 es el centro perfecto. 100 gana P1, 0 gana P2.

		-- Le avisamos a las pantallas de ambos que empiece la masacre de clics
		armWrestleEvent:FireClient(tData.P1, "Start", "P1")
		armWrestleEvent:FireClient(tData.P2, "Start", "P2")

		print("¡Inicia Vencidas entre " .. tData.P1.Name .. " y " .. tData.P2.Name .. "!")
	end
end

-- =========================================================
-- 💪 3. LÓGICA DE FUERZA (Mashing)
-- =========================================================
armWrestleEvent.OnServerEvent:Connect(function(player, action)
	if action == "Click" then
		-- Buscar en qué mesa está el jugador
		for tableObj, tData in pairs(Tables) do
			if tData.Active then
				if player == tData.P1 then
					tData.Score = tData.Score + 2 -- P1 empuja hacia 100
				elseif player == tData.P2 then
					tData.Score = tData.Score - 2 -- P2 empuja hacia 0
				end

				-- Actualizar la UI de ambos
				armWrestleEvent:FireClient(tData.P1, "Update", tData.Score)
				armWrestleEvent:FireClient(tData.P2, "Update", tData.Score)

				-- Verificar si alguien ganó
				if tData.Score >= 100 then
					EndMatch(tableObj, tData.P1, tData.P2)
				elseif tData.Score <= 0 then
					EndMatch(tableObj, tData.P2, tData.P1)
				end
				break
			end
		end
	end
end)

function EndMatch(tableObj, winner, loser)
	local tData = Tables[tableObj]
	tData.Active = false

	armWrestleEvent:FireClient(winner, "End", "¡GANASTE!")
	armWrestleEvent:FireClient(loser, "End", "¡PERDISTE!")

	-- Reiniciar la mesa
	task.wait(2)
	tData.P1 = nil
	tData.P2 = nil
	tData.Score = 50
	tableObj.Seat1.SitPrompt.Enabled = true
	tableObj.Seat2.SitPrompt.Enabled = true
end

SetupTables()
