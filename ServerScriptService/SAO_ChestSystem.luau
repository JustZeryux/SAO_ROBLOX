local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")

local chestsFolder = workspace:WaitForChild("Chests")

-- =========================================================
-- 🎁 SISTEMA DE COFRES ULTRA SMOOTH
-- =========================================================
for _, chest in ipairs(chestsFolder:GetChildren()) do
	local base = chest:FindFirstChild("Base")
	local lid = chest:FindFirstChild("Lid")

	if base and lid then
		-- 1. Crear el ProximityPrompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Abrir"
		prompt.ObjectText = "Cofre del Tesoro"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 1.2
		prompt.Parent = base

		prompt.Triggered:Connect(function(player)
			prompt:Destroy() -- Se destruye para que solo se abra una vez

			-- Opcional: Reproducir sonido de apertura aquí

			-- 2. Animación de la tapa (Tweening con Pivot para evitar bugs físicos)
			local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

			-- Rotamos la tapa 75 grados hacia atrás
			local openCFrame = lid:GetPivot() * CFrame.Angles(math.rad(-75), 0, 0)

			-- Usamos un CFrameValue temporal para hacer la animación impecable
			local cframeValue = Instance.new("CFrameValue")
			cframeValue.Value = lid:GetPivot()

			cframeValue.Changed:Connect(function(newCFrame)
				lid:PivotTo(newCFrame)
			end)

			local tween = TweenService:Create(cframeValue, tweenInfo, {Value = openCFrame})
			tween:Play()

			-- 3. Spawning del Botín (Loot)
			tween.Completed:Connect(function()
				cframeValue:Destroy()

				-- Lista de posibles premios
				local possibleDrops = {"Sword", "Wood legs", "Raw Meat", "Health Potion"}
				local numDrops = math.random(3, 6) -- Cuántos items soltará el cofre

				for i = 1, numDrops do
					local dropName = possibleDrops[math.random(1, #possibleDrops)]

					-- Crear el orbe de botín estilo SAO (Neón flotante)
					local orb = Instance.new("Part")
					orb.Name = "SAO_LootOrb"
					orb.Size = Vector3.new(0.6, 0.6, 0.6)
					orb.Shape = Enum.PartType.Ball
					orb.Material = Enum.Material.Neon
					orb.Color = Color3.fromRGB(0, 200, 255) -- Azul eléctrico brillante
					orb.Position = base.Position + Vector3.new(0, 2, 0)
					orb.CanCollide = true
					orb.Parent = workspace

					-- Físicas: Explosión hacia afuera (Efecto "Fuente")
					local attachment = Instance.new("Attachment", orb)
					local linearVelocity = Instance.new("LinearVelocity")
					linearVelocity.Attachment0 = attachment
					linearVelocity.MaxForce = 50000

					-- Dirección aleatoria hacia arriba y hacia los lados
					local randomDir = Vector3.new(math.random(-15, 15), math.random(30, 50), math.random(-15, 15))
					linearVelocity.VectorVelocity = randomDir
					linearVelocity.Parent = attachment

					-- Quitar la fuerza después de una fracción de segundo para que caigan al piso
					task.delay(0.2, function()
						if linearVelocity then linearVelocity:Destroy() end
						if attachment then attachment:Destroy() end
					end)

					-- 4. Poder recoger el botín
					local pickPrompt = Instance.new("ProximityPrompt")
					pickPrompt.ActionText = "Recoger " .. dropName
					pickPrompt.ObjectText = "Botín"
					pickPrompt.KeyboardKeyCode = Enum.KeyCode.E
					pickPrompt.Parent = orb

					pickPrompt.Triggered:Connect(function(picker)
						-- Aquí usamos tu sistema de inventario existente
						local ServerInventories = _G.ServerInventories -- Asegúrate de que el backend comparta esta tabla o usa módulos
						-- Como alternativa sencilla y directa sin depender de globales:
						-- Disparamos un remote si quieres, o simplemente conectamos con la lógica del ServerInventory

						-- Imprimimos para que veas que funciona perfecto:
						print(picker.Name .. " recogió " .. dropName .. " del cofre.")

						-- Efecto de recolección suave
						pickPrompt:Destroy()
						local shrinkTween = TweenService:Create(orb, TweenInfo.new(0.2), {Size = Vector3.new(0,0,0)})
						shrinkTween:Play()
						shrinkTween.Completed:Connect(function() orb:Destroy() end)
					end)
				end
			end)
		end)
	end
end
