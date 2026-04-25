local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Configuración del Dash
local DASH_COOLDOWN = 1.5 -- Segundos para volver a usarlo
local DASH_SPEED = 75     -- Qué tan rápido sales disparado
local DASH_DURATION = 0.2 -- Cuánto dura el impulso
local lastDashTime = 0

-- Color de la estela (Estilo SAO, un azul brillante eléctrico)
local TRAIL_COLOR = Color3.fromRGB(0, 150, 255) 

-- =========================================================
-- ✨ FUNCIÓN PARA CREAR EL RASTRO "FANTASMA" (VFX)
-- =========================================================
local function CreateGhostTrail()
	-- Clonamos el cuerpo del personaje (ignorando accesorios complejos para no dar lag)
	for characterPart in pairs(character:GetDescendants()) do
		if characterPart:IsA("BasePart") and characterPart.Name ~= "HumanoidRootPart" then
			local ghostPart = characterPart:Clone()
			ghostPart.Parent = workspace
			ghostPart.Anchored = true
			ghostPart.CanCollide = false
			ghostPart.Massless = true

			-- Aplicar estética de energía
			ghostPart.Material = Enum.Material.Neon
			ghostPart.Color = TRAIL_COLOR
			ghostPart.Transparency = 0.5

			-- Limpiar scripts internos clonados por accidente
			for _, child in ipairs(ghostPart:GetChildren()) do
				if not child:IsA("SpecialMesh") then child:Destroy() end
			end

			-- Desaparecer suavemente
			local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(ghostPart, tweenInfo, {Transparency = 1, Size = ghostPart.Size * 0.8})
			tween:Play()

			-- Eliminar la pieza del juego después de la animación
			Debris:AddItem(ghostPart, 0.5)
		end
	end
end

-- =========================================================
-- 🚀 FÍSICAS DEL DASH
-- =========================================================
local function PerformDash()
	-- 1. Determinar hacia dónde se mueve el jugador (o hacia dónde mira si está quieto)
	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude == 0 then
		moveDirection = rootPart.CFrame.LookVector
	end

	-- 2. Crear un anclaje para la fuerza
	local attachment = Instance.new("Attachment")
	attachment.Parent = rootPart

	-- 3. Usamos LinearVelocity (El método moderno y suave de Roblox para impulsos)
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 100000 -- Fuerza suficiente para mover el peso del personaje
	linearVelocity.VectorVelocity = moveDirection * DASH_SPEED
	linearVelocity.Parent = attachment

	-- 4. Reproducir el rastro visual varias veces durante el dash
	task.spawn(function()
		for i = 1, 3 do
			CreateGhostTrail()
			task.wait(DASH_DURATION / 3)
		end
	end)

	-- 5. Terminar el impulso después de la duración
	task.delay(DASH_DURATION, function()
		linearVelocity:Destroy()
		attachment:Destroy()
	end)
end

-- =========================================================
-- 🎮 CONTROLES
-- =========================================================
UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end -- Ignorar si está escribiendo en el chat

	if input.KeyCode == Enum.KeyCode.Q then
		local currentTime = tick()
		if currentTime - lastDashTime >= DASH_COOLDOWN then
			-- Verifica que no esté aturdido o muerto
			if humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
				lastDashTime = currentTime
				PerformDash()
			end
		end
	end
end)
