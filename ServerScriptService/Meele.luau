-- ServerScriptService > CombatHandler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatEvent = ReplicatedStorage:WaitForChild("CombatEvent")

-- Diccionario básico para validar tiempos de ataque (Evitar auto-clickers)
local cooldowns = {}

CombatEvent.OnServerEvent:Connect(function(player, actionType, targetHumanoid, hitPart, hitPosition)
	if actionType == "MeleeHit" then
		local currentTime = os.clock()
		-- Validar Cooldown (Ejemplo: 0.5 segundos por golpe)
		if cooldowns[player] and currentTime - cooldowns[player] < 0.5 then return end
		cooldowns[player] = currentTime

		-- Validar distancia (Seguridad básica)
		local distance = (player.Character.HumanoidRootPart.Position - hitPart.Position).Magnitude
		if distance > 10 then return end -- ¡Muy lejos para una espada!

		-- Aplicar daño
		targetHumanoid:TakeDamage(15)

		-- Ordenar a TODOS los clientes que dibujen la marca de daño de SAO
		CombatEvent:FireAllClients("RenderSAOMark", hitPart, hitPosition)
	end
end)
