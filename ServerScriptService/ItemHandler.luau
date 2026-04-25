local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") 
local Debris = game:GetService("Debris") 

-- Referencias basadas en tu cliente
local SAO_Modules = ReplicatedStorage:WaitForChild("SAO_Modules")
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local ConsumeItemEvent = SAO_Events:WaitForChild("ConsumeItem")
local VoiceCommandEvent = SAO_Events:WaitForChild("VoiceCommandEvent") 
local ItemDatabase = require(SAO_Modules:WaitForChild("ItemDatabase"))

-- =========================================================
-- 1. FUNCIÓN AUXILIAR: BUSCAR Y DESTRUIR ÍTEM
-- =========================================================
local function ConsumeTool(player, itemName)
	local tool = player.Character and player.Character:FindFirstChild(itemName)
	if not tool then
		tool = player.Backpack:FindFirstChild(itemName)
	end

	if tool then
		tool:Destroy() 
		return true
	else
		warn("❌ ERROR: No se encontró '" .. itemName .. "'. Asegúrate de tenerlo equipado o en el inventario.")
	end

	return false
end

-- =========================================================
-- ✨ 2. EFECTOS ÉPICOS DE LOS CRISTALES
-- =========================================================

-- 🔵 CRISTAL AZUL (Teletransporte)
local function PlaySAOTeleportFX(character, rootPart, destinationCFrame)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or not rootPart then return end

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	local originalTransparencies = {}

	local hand = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand") or rootPart
	local shatterSound = Instance.new("Sound", hand)
	shatterSound.SoundId = "rbxassetid://169440624"
	shatterSound.Volume = 1
	shatterSound:Play()
	Debris:AddItem(shatterSound, 1)

	local pilarAtt = Instance.new("Attachment", rootPart)
	pilarAtt.Position = Vector3.new(0, -2, 0)

	local particles = Instance.new("ParticleEmitter", pilarAtt)
	particles.Texture = "rbxassetid://5860841663" 
	particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
	particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0.5)})
	particles.Lifetime = NumberRange.new(0.8, 1.2)
	particles.Rate = 200
	particles.Speed = NumberRange.new(25, 40)
	particles.VelocitySpread = 10
	particles.EmissionDirection = Enum.NormalId.Top
	particles.LightEmission = 1

	local chargeSound = Instance.new("Sound", rootPart)
	chargeSound.SoundId = "rbxassetid://2868118652"
	chargeSound.Volume = 1.5
	chargeSound:Play()
	Debris:AddItem(chargeSound, 3)

	task.wait(2) 

	if character.Parent and rootPart.Parent then 
		particles.Rate = 0
		local flash = Instance.new("PointLight", rootPart)
		flash.Color = Color3.fromRGB(150, 255, 255)
		flash.Range = 20; flash.Brightness = 10
		Debris:AddItem(flash, 0.5)

		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				originalTransparencies[part] = part.Transparency
				part.Transparency = 1 
			end
		end

		rootPart.CFrame = destinationCFrame * CFrame.new(0, 3, 0) 
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		pilarAtt:Destroy()
		table.clear(originalTransparencies) 
		return 
	end

	local arrivalAtt = Instance.new("Attachment", rootPart)
	local arrivalParticles = particles:Clone()
	arrivalParticles.Parent = arrivalAtt
	arrivalParticles.Speed = NumberRange.new(30, 60)
	arrivalParticles.VelocitySpread = 360
	arrivalParticles:Emit(100) 

	local arrivalSound = Instance.new("Sound", rootPart)
	arrivalSound.SoundId = "rbxassetid://6093393963" 
	arrivalSound.Volume = 1
	arrivalSound:Play()
	Debris:AddItem(arrivalSound, 2)

	task.wait(0.2)

	for part, originalTransp in pairs(originalTransparencies) do
		if part and part.Parent then 
			part.Transparency = originalTransp
		end
	end

	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	pilarAtt:Destroy()
	arrivalAtt:Destroy()
	table.clear(originalTransparencies)
end

-- 🟡 CRISTAL AMARILLO (Corredor / Portal)
local function CreateCorridorPortal(rootPart, destinationCFrame)
	local portal = Instance.new("Part")
	portal.Size = Vector3.new(8, 10, 1)
	portal.Position = rootPart.Position + (rootPart.CFrame.LookVector * 6)
	portal.CFrame = CFrame.lookAt(portal.Position, rootPart.Position)
	portal.Anchored = true
	portal.CanCollide = false
	portal.Material = Enum.Material.Neon
	portal.Color = Color3.fromRGB(255, 255, 100) -- Amarillo brillante
	portal.Transparency = 0.2
	portal.Name = "Portal_Corredor"
	portal.Parent = workspace

	-- Efecto de sonido del portal
	local openSound = Instance.new("Sound", portal)
	openSound.SoundId = "rbxassetid://2868118652"
	openSound.Volume = 2
	openSound:Play()

	-- Lógica de Teletransporte para quien lo toque
	local debounce = {}
	portal.Touched:Connect(function(hit)
		local char = hit.Parent
		local hum = char:FindFirstChild("Humanoid")
		local hitRoot = char:FindFirstChild("HumanoidRootPart")

		if hum and hum.Health > 0 and hitRoot and not debounce[char] then
			debounce[char] = true

			local teleportSound = Instance.new("Sound", hitRoot)
			teleportSound.SoundId = "rbxassetid://6093393963"
			teleportSound:Play()
			Debris:AddItem(teleportSound, 2)

			hitRoot.CFrame = destinationCFrame * CFrame.new(0, 3, 0)

			task.wait(1)
			debounce[char] = nil
		end
	end)

	-- El portal dura 15 segundos antes de desaparecer
	Debris:AddItem(portal, 15)
end

-- 🟢 CRISTAL VERDE (Antídoto / Purificar)
local function PurifyArea(character)
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		local targetChar = targetPlayer.Character
		local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")

		if targetHum and targetHum.Health > 0 and character.PrimaryPart and targetChar.PrimaryPart then
			local distance = (character.PrimaryPart.Position - targetChar.PrimaryPart.Position).Magnitude
			if distance <= 40 then
				-- Limpiar estados alterados (Ajusta estos atributos según tu sistema de combate)
				targetPlayer:SetAttribute("IsPoisoned", false)
				targetPlayer:SetAttribute("IsBurning", false)
				targetPlayer:SetAttribute("IsSlowed", false)

				-- Efecto visual de curación verde
				local flash = Instance.new("PointLight", targetChar.PrimaryPart)
				flash.Color = Color3.fromRGB(50, 255, 100)
				flash.Range = 15; flash.Brightness = 8
				Debris:AddItem(flash, 1)

				local purifySound = Instance.new("Sound", targetChar.PrimaryPart)
				purifySound.SoundId = "rbxassetid://169440624" -- Reemplazar con un sonido de "burbuja" o magia si tienes
				purifySound.PlaybackSpeed = 1.5
				purifySound:Play()
				Debris:AddItem(purifySound, 1)
			end
		end
	end
end

-- =========================================================
-- 🎙️ 3. FUNCIONALIDAD POR CHAT DE VOZ (Micrófono)
-- =========================================================
VoiceCommandEvent.OnServerEvent:Connect(function(player, commandStr)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local comandoLimpio = string.lower(commandStr)
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	-- 🔴 CURACIÓN
	if string.match(comandoLimpio, "heal") then
		if ConsumeTool(player, "Cristal_Curacion") then
			for _, targetPlayer in ipairs(Players:GetPlayers()) do
				local targetChar = targetPlayer.Character
				local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")
				if targetHum and targetHum.Health > 0 and character.PrimaryPart and targetChar.PrimaryPart then
					if (character.PrimaryPart.Position - targetChar.PrimaryPart.Position).Magnitude <= 40 then
						local healAmount = targetHum.MaxHealth * 0.80
						targetHum.Health = math.clamp(targetHum.Health + healAmount, 0, targetHum.MaxHealth)
					end
				end
			end
			print("✨ " .. player.Name .. " usó cristal de curación (VOZ).")
		end

		-- 🔵 TELETRANSPORTE
	elseif string.match(comandoLimpio, "teleport") then
		local destino = workspace:FindFirstChild("Destino_Teleport")
		if destino and ConsumeTool(player, "Cristal_Teletransporte") and rootPart then
			PlaySAOTeleportFX(character, rootPart, destino.CFrame)
		end

		-- 🟢 ANTÍDOTO
	elseif string.match(comandoLimpio, "purify") or string.match(comandoLimpio, "cure") then
		if ConsumeTool(player, "Cristal_Antidoto") then
			PurifyArea(character)
			print("🌿 " .. player.Name .. " usó cristal antídoto (VOZ).")
		end

		-- 🟡 CORREDOR
	elseif string.match(comandoLimpio, "corridor") then
		local destino = workspace:FindFirstChild("Destino_Teleport")
		if destino and ConsumeTool(player, "Cristal_Corredor") and rootPart then
			CreateCorridorPortal(rootPart, destino.CFrame)
			print("🚪 " .. player.Name .. " abrió un portal corredor (VOZ).")
		end
	end
end)

-- =========================================================
-- 💬 4. FUNCIONALIDADES DE CONSUMIBLES (UI)
-- =========================================================
ConsumeItemEvent.OnServerEvent:Connect(function(player, itemName)
	local itemData = ItemDatabase[itemName]
	if not itemData then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if not ConsumeTool(player, itemName) then return end

	local effect = itemData.Efecto
	if not effect then return end

	if itemData.Tipo == "Consumible" then
		if effect.Stat == "HP" then
			humanoid.Health = math.clamp(humanoid.Health + effect.Valor, 0, humanoid.MaxHealth)
		elseif effect.Stat == "SP" then
			local currentSP = player:GetAttribute("SP") or 100
			local maxSP = player:GetAttribute("MaxSP") or 100
			player:SetAttribute("SP", math.clamp(currentSP + effect.Valor, 0, maxSP))
		elseif effect.CuraEstado == "Veneno" then
			player:SetAttribute("IsPoisoned", false)
		elseif effect.Buff == "RegenHP" then
			task.spawn(function()
				local duration = effect.Duracion
				local amount = effect.Valor
				for i = 1, duration do
					if not humanoid or humanoid.Health <= 0 then break end
					humanoid.Health = math.clamp(humanoid.Health + amount, 0, humanoid.MaxHealth)
					task.wait(1)
				end
			end)
		elseif effect.Stat == "HP_Max" and effect.Buff == "Inmune" then
			humanoid.Health = humanoid.MaxHealth
			local ff = Instance.new("ForceField")
			ff.Visible = true
			ff.Parent = character
			task.delay(effect.Duracion, function()
				if ff then ff:Destroy() end
			end)
		end
	elseif itemData.Tipo == "Herramienta" then
		if effect.Buff == "DanoFisico" then
			player:SetAttribute("DamageBuff", (effect.Porcentaje / 100))
			task.delay(effect.Duracion, function()
				if player then player:SetAttribute("DamageBuff", 0) end
			end)
		end
	end
end)

-- =========================================================
-- 💬 5. FUNCIONALIDADES DE CRISTALES (Chat de Texto)
-- =========================================================
local function ConectarChat(player)
	player.Chatted:Connect(function(message)
		local msgLower = string.lower(message)
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local rootPart = character:FindFirstChild("HumanoidRootPart")

		-- 🔴 CRISTAL DE CURACIÓN
		if string.match(msgLower, "heal") then
			if ConsumeTool(player, "Cristal_Curacion") then
				local effect = ItemDatabase["Cristal_Curacion"] and ItemDatabase["Cristal_Curacion"].Efecto or {Porcentaje = 80}
				for _, targetPlayer in ipairs(Players:GetPlayers()) do
					local targetChar = targetPlayer.Character
					local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")
					if targetHum and targetHum.Health > 0 and character.PrimaryPart and targetChar.PrimaryPart then
						if (character.PrimaryPart.Position - targetChar.PrimaryPart.Position).Magnitude <= 40 then 
							local healAmount = targetHum.MaxHealth * (effect.Porcentaje / 100)
							targetHum.Health = math.clamp(targetHum.Health + healAmount, 0, targetHum.MaxHealth)
						end
					end
				end
			end
		end

		-- 🔵 CRISTAL DE TELETRANSPORTE
		if string.match(msgLower, "teleport") then
			local destino = workspace:FindFirstChild("Destino_Teleport")
			if destino and ConsumeTool(player, "Cristal_Teletransporte") and rootPart then
				PlaySAOTeleportFX(character, rootPart, destino.CFrame)
			end
		end

		-- 🟢 CRISTAL ANTÍDOTO
		if string.match(msgLower, "purify") or string.match(msgLower, "cure") then
			if ConsumeTool(player, "Cristal_Antidoto") then
				PurifyArea(character)
			end
		end

		-- 🟡 CRISTAL CORREDOR
		if string.match(msgLower, "corridor") then
			local destino = workspace:FindFirstChild("Destino_Teleport")
			if destino and ConsumeTool(player, "Cristal_Corredor") and rootPart then
				CreateCorridorPortal(rootPart, destino.CFrame)
			end
		end
	end)
end

Players.PlayerAdded:Connect(ConectarChat)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function() ConectarChat(player) end)
end
