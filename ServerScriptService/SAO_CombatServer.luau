local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local meleeEvent = Remotes:WaitForChild("MeleeHit")

-- Configuración de Daño Base
local BASE_DAMAGE = 10
-- Obtener los IDs de grupo de quien ataca y quien recibe el golpe
local myPartyID = player:GetAttribute("PartyID")

-- Verificar si el objetivo es otro jugador
local enemyPlayer = game:GetService("Players"):GetPlayerFromCharacter(enemy)

local isFriendly = false
if enemyPlayer then
	local enemyPartyID = enemyPlayer:GetAttribute("PartyID")
	-- Si ambos tienen el mismo ID de grupo, son amigos
	if myPartyID and enemyPartyID and myPartyID == enemyPartyID then
		isFriendly = true
	end
end

-- Solo hacemos daño si NO es amigable
if not isFriendly then
	local finalDamage = BASE_DAMAGE
	if comboHit == 3 then finalDamage = BASE_DAMAGE * 2 end

	enemyHum:TakeDamage(finalDamage)
end
meleeEvent.OnServerEvent:Connect(function(player, hitEnemies, comboHit)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	local rootPart = character.HumanoidRootPart

	-- Verificar que sí tenga el arma equipada
	local weapon = character:FindFirstChild("Sword")
	if not weapon then return end

	for _, enemy in ipairs(hitEnemies) do
		-- Validar que el enemigo siga vivo y tenga Humanoid
		local enemyHum = enemy:FindFirstChild("Humanoid")
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

		if enemyHum and enemyRoot and enemyHum.Health > 0 then
			-- Anti-Cheat: Verificar distancia en el servidor (Tolerancia de 10 studs por latencia)
			local distance = (rootPart.Position - enemyRoot.Position).Magnitude
			if distance <= 10 then

				-- Calcular daño: El último golpe del combo (el #3) hace el doble de daño
				local finalDamage = BASE_DAMAGE
				if comboHit == 3 then
					finalDamage = BASE_DAMAGE * 2
				end

				enemyHum:TakeDamage(finalDamage)

				-- Efecto de retroceso (Knockback) en el último golpe
				if comboHit == 3 then
					local knockbackForce = (enemyRoot.Position - rootPart.Position).Unit * 50

					local attachment = Instance.new("Attachment")
					attachment.Parent = enemyRoot

					local linearVelocity = Instance.new("LinearVelocity")
					linearVelocity.Attachment0 = attachment
					linearVelocity.MaxForce = 50000
					linearVelocity.VectorVelocity = knockbackForce + Vector3.new(0, 10, 0) -- Lo empuja hacia atrás y un poco arriba
					linearVelocity.Parent = attachment

					-- Limpiar el knockback
					task.delay(0.2, function()
						linearVelocity:Destroy()
						attachment:Destroy()
					end)
				end

			end
		end
	end
end)
