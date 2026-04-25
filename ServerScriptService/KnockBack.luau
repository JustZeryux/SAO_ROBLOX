-- === SCRIPT DE SERVIDOR (Pon esto en ServerScriptService) === --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ParryEvent = ReplicatedStorage:WaitForChild("ParryEvent")

ParryEvent.OnServerEvent:Connect(function(player, enemyCharacter, knockbackDir, dodgeAnimId)
	local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
	local enemyRoot = enemyCharacter:FindFirstChild("HumanoidRootPart")

	if enemyHumanoid and enemyRoot then
		-- 1. SOLTAR LA ESPADA (Unequip)
		for _, tool in pairs(enemyCharacter:GetChildren()) do
			if tool:IsA("Tool") then
				enemyHumanoid:UnequipTools()
			end
		end

		-- 2. CONGELAR AL ENEMIGO
		local oldSpeed = enemyHumanoid.WalkSpeed
		local oldJump = enemyHumanoid.JumpPower
		enemyHumanoid.WalkSpeed = 0
		enemyHumanoid.JumpPower = 0

		-- 3. EMPUJAR AL ENEMIGO (Knockback)
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(100000, 100000, 100000)
		bv.Velocity = (knockbackDir * 50) + Vector3.new(0, 15, 0)
		bv.Parent = enemyRoot
		game.Debris:AddItem(bv, 0.2)

		-- 4. REPRODUCIR ANIMACIÓN DE DODGE
		local animator = enemyHumanoid:FindFirstChild("Animator")
		if animator then
			local animToPlay = Instance.new("Animation")
			animToPlay.AnimationId = dodgeAnimId
			local track = animator:LoadAnimation(animToPlay)

			track.Looped = false -- 🛑 ESTA ES LA MAGIA QUE DETIENE EL BUCLE
			track:Play()
		end

		-- 5. ESPERAR A QUE RECOJA LA ESPADA (1.3 SEGS)
		task.wait(1.3)

		-- 6. DEVOLVER EL MOVIMIENTO
		enemyHumanoid.WalkSpeed = oldSpeed
		enemyHumanoid.JumpPower = oldJump
	end
end)
