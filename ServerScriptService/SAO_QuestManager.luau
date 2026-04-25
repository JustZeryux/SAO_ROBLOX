local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Eventos = ReplicatedStorage:WaitForChild("SAO_Events")
local QuestEvent = Instance.new("RemoteEvent", Eventos)
QuestEvent.Name = "QuestEvent"

-- Base de datos de Misiones (Puedes añadir más después)
local Misiones = {
	["Caza de Lobos"] = {
		ObjetivoName = "Lobo Nefasto",
		CantidadRequerida = 5,
		RecompensaExp = 300,
		RecompensaCol = 50 -- Col (Dinero de SAO)
	}
}

-- Inicializar la misión al entrar
Players.PlayerAdded:Connect(function(player)
	-- Atributos de la misión activa
	if not player:GetAttribute("ActiveQuest") then player:SetAttribute("ActiveQuest", "Caza de Lobos") end
	if not player:GetAttribute("QuestProgress") then player:SetAttribute("QuestProgress", 0) end
	if not player:GetAttribute("Col") then player:SetAttribute("Col", 0) end -- Moneda base
end)

-- Sistema para detectar cuando muere un monstruo
workspace.DescendantAdded:Connect(function(descendant)
	-- Asumimos que los monstruos son Modelos con un Humanoid
	if descendant:IsA("Model") and descendant:FindFirstChild("Humanoid") then
		local humanoid = descendant.Humanoid

		-- Solo nos interesan los NPCs, no los jugadores
		if not Players:GetPlayerFromCharacter(descendant) then
			humanoid.Died:Connect(function()
				-- Buscar la etiqueta "creator" que pusimos en tu espada para saber quién lo mató
				local tag = humanoid:FindFirstChild("creator")
				if tag and tag.Value and tag.Value:IsA("Player") then
					local killer = tag.Value
					local questName = killer:GetAttribute("ActiveQuest")

					if questName and Misiones[questName] then
						local questData = Misiones[questName]

						-- Si mató al objetivo correcto
						if descendant.Name == questData.ObjetivoName then
							local progreso = killer:GetAttribute("QuestProgress") or 0
							progreso = progreso + 1
							killer:SetAttribute("QuestProgress", progreso)

							print("[SAO Quests]: " .. killer.Name .. " mató un " .. descendant.Name .. " (" .. progreso .. "/" .. questData.CantidadRequerida .. ")")

							-- Comprobar si completó la misión
							if progreso >= questData.CantidadRequerida then
								print("[SAO Quests]: ¡" .. killer.Name .. " completó la misión!")

								-- Dar recompensas
								if _G.DarExp then _G.DarExp(killer, questData.RecompensaExp) end
								killer:SetAttribute("Col", (killer:GetAttribute("Col") or 0) + questData.RecompensaCol)

								-- Limpiar la misión (En un juego real aquí le darías la siguiente)
								killer:SetAttribute("ActiveQuest", "Completada")
								killer:SetAttribute("QuestProgress", 0)

								-- Enviar aviso visual al cliente
								QuestEvent:FireClient(killer, "QuestComplete", questName)
							end
						end
					end
				end
			end)
		end
	end
end)
