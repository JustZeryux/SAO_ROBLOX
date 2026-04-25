local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local UpgradeStatEvent = SAO_Events:WaitForChild("UpgradeStat")

-- ==========================================
-- 🏃‍♂️ CONFIGURACIÓN DE AGILIDAD (AGI)
-- ==========================================
local BASE_WALKSPEED = 16
local AGI_MULTIPLIER = 0.4 -- Cuánta velocidad extra te da cada punto de AGI

local function updateCharacterStats(player)
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum then
		local agi = player:GetAttribute("AGI") or 10
		-- Actualizamos la velocidad en tiempo real
		hum.WalkSpeed = BASE_WALKSPEED + (agi * AGI_MULTIPLIER)
	end
end

-- 1. Dar atributos base al unirse
Players.PlayerAdded:Connect(function(player)
	-- Atributos base si el jugador es nuevo
	if not player:GetAttribute("STR") then player:SetAttribute("STR", 10) end
	if not player:GetAttribute("AGI") then player:SetAttribute("AGI", 10) end
	if not player:GetAttribute("StatPoints") then player:SetAttribute("StatPoints", 5) end

	-- Aplicar velocidad cada vez que el personaje aparece/respawnea
	player.CharacterAdded:Connect(function(char)
		task.wait(0.1) -- Esperamos a que el Humanoid cargue correctamente
		updateCharacterStats(player)
	end)
end)

-- 2. Escuchar la petición de mejora desde la UI
UpgradeStatEvent.OnServerEvent:Connect(function(player, statName)
	local puntosActuales = player:GetAttribute("StatPoints") or 0

	-- Seguridad anti-exploits: Verificar que el jugador realmente tenga puntos
	if puntosActuales > 0 then
		-- Verificar que están pidiendo una estadística válida
		if statName == "STR" or statName == "AGI" then
			local valorStat = player:GetAttribute(statName) or 10

			-- Restamos 1 punto disponible y sumamos 1 al atributo
			player:SetAttribute("StatPoints", puntosActuales - 1)
			player:SetAttribute(statName, valorStat + 1)

			-- Si lo que mejoró fue la agilidad, lo hacemos correr más rápido al instante
			if statName == "AGI" then
				updateCharacterStats(player)
			end

			print("[SAO System]: " .. player.Name .. " ha mejorado " .. statName .. " a " .. (valorStat + 1))
		end
	else
		warn("[SAO Anti-Cheat]: " .. player.Name .. " intentó mejorar una estadística sin StatPoints.")
	end
end)
