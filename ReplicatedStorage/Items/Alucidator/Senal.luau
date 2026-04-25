local Tool = script.Parent
local damageEvent = Tool:WaitForChild("DamageEvent")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 📡 EVENTOS SAO
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local SAO_HitEvent = SAO_Events:WaitForChild("SAO_HitEvent")
-- ✨ AQUÍ DEFINIMOS EL NUEVO EVENTO PARA EL TEMBLOR Y HIT-STOP
local HitFeedbackEvent = SAO_Events:WaitForChild("HitFeedback")

-- Diccionario para evitar que los hackers spameen el evento (Cooldown de seguridad)
local cooldowns = {}

damageEvent.OnServerEvent:Connect(function(player, humanoid, hitPart, hitPosition, incomingDamage)
	-- 1. VERIFICACIÓN: ¿El que disparó el evento es el dueño de la espada?
	if player.Character ~= Tool.Parent then return end

	-- 2. VERIFICACIÓN: Anti-Spam
	local currentTime = tick()
	if cooldowns[player] and currentTime - cooldowns[player] < 0.05 then
		return -- Ignoramos el ataque por spam
	end
	cooldowns[player] = currentTime

	-- 3. VERIFICACIÓN: Distancia
	local attackerRoot = player.Character:FindFirstChild("HumanoidRootPart")
	if attackerRoot and hitPart then
		local distance = (attackerRoot.Position - hitPart.Position).Magnitude
		if distance > 30 then 
			return 
		end
	end

	-- 4. APLICAR DAÑO SEGURO
	local damageAmount = incomingDamage or 45 

	if humanoid and humanoid.Health > 0 then
		-- 🏷️ Etiqueta para el Loot del Boss
		humanoid:SetAttribute("LastAttacker", player.Name)

		-- 🩸 APLICAR DAÑO
		if _G.RegisterHit then
			_G.RegisterHit(humanoid, hitPart, damageAmount)
		else
			humanoid:TakeDamage(damageAmount)

			-- Enviar marca visual (tajo rojo) si no hay sistema global
			SAO_HitEvent:FireClient(player, hitPart, hitPosition, damageAmount, false)
			local victimPlayer = game:GetService("Players"):GetPlayerFromCharacter(humanoid.Parent)
			if victimPlayer then
				SAO_HitEvent:FireClient(victimPlayer, hitPart, hitPosition, damageAmount, false)
			end
		end

		-- ✨ LA PIEZA FALTANTE ✨
		-- Disparamos el evento a TODOS los clientes para que vean el destello,
		-- y el atacante / víctima sientan el temblor de cámara y el Hit-Stop.
		local enemigoCharacter = humanoid.Parent
		HitFeedbackEvent:FireAllClients(enemigoCharacter, player, hitPosition, damageAmount)
	end
end)

-- Limpiar la memoria cuando un jugador se va
game:GetService("Players").PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)
