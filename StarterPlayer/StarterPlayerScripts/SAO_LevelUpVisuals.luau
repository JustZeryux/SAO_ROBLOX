local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Buscar el evento de Level Up
local SAO_Events = ReplicatedStorage:FindFirstChild("SAO_Events")
local LevelUpEvent = (SAO_Events and SAO_Events:WaitForChild("SAO_LevelUpEvent", 5)) or ReplicatedStorage:WaitForChild("SAO_LevelUpEvent", 5)

-- Sonido (Puedes poner un sfx épico aquí)
local sfxLevelUp = Instance.new("Sound")
sfxLevelUp.SoundId = "rbxassetid://7435216616" 
sfxLevelUp.Volume = 1
sfxLevelUp.Parent = workspace

-- ==========================================
-- 🛠️ FUNCIÓN: PARTÍCULAS DIGITALES UI
-- ==========================================
local function emitUIParticles(parentFrame)
	local colors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 170, 0)}

	for i = 1, 20 do
		local particle = Instance.new("Frame")
		local size = math.random(4, 12)
		particle.Size = UDim2.new(0, size, 0, size)
		particle.Position = UDim2.new(0.5, 0, 0.5, 0)
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.BackgroundColor3 = colors[math.random(1, #colors)]
		particle.Rotation = math.random(0, 360)
		particle.BorderSizePixel = 0
		particle.ZIndex = 0
		particle.Parent = parentFrame

		-- Calcular dirección aleatoria
		local angle = math.rad(math.random(0, 360))
		local distance = math.random(100, 300)
		local targetX = 0.5 + (math.cos(angle) * (distance / parentFrame.AbsoluteSize.X))
		local targetY = 0.5 + (math.sin(angle) * (distance / parentFrame.AbsoluteSize.Y))

		local duration = math.random(40, 80) / 100

		-- Animar partícula (moverse, encogerse y girar)
		TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(targetX, 0, targetY, 0),
			Size = UDim2.new(0, 0, 0, 0),
			Rotation = particle.Rotation + math.random(90, 180),
			BackgroundTransparency = 1
		}):Play()

		task.delay(duration, function() particle:Destroy() end)
	end
end

-- ==========================================
-- ✨ EFECTO HOLOGRÁFICO DE LEVEL UP (SAO STYLE)
-- ==========================================
LevelUpEvent.OnClientEvent:Connect(function(newLevel)
	sfxLevelUp:Play()

	-- 1️⃣ LIENZO PRINCIPAL
	local gui = Instance.new("ScreenGui")
	gui.Name = "SAO_LevelUpGui"
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Destello Blanco a pantalla completa
	local screenFlash = Instance.new("Frame")
	screenFlash.Size = UDim2.new(1, 0, 1, 0)
	screenFlash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	screenFlash.BackgroundTransparency = 0
	screenFlash.BorderSizePixel = 0
	screenFlash.Parent = gui

	-- Contenedor del anuncio
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 600, 0, 120)
	container.Position = UDim2.new(0.5, -300, 0.4, -60)
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	container.BackgroundTransparency = 1 -- Empieza invisible
	container.BorderSizePixel = 0
	container.ClipsDescendants = false
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container

	-- 2️⃣ LÍNEAS DE EXPANSIÓN (Top y Bottom)
	local topLine = Instance.new("Frame")
	topLine.Size = UDim2.new(0, 0, 0, 2)
	topLine.Position = UDim2.new(0.5, 0, 0, 0)
	topLine.AnchorPoint = Vector2.new(0.5, 0.5)
	topLine.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	topLine.BorderSizePixel = 0
	topLine.Parent = container

	local bottomLine = topLine:Clone()
	bottomLine.Position = UDim2.new(0.5, 0, 1, 0)
	bottomLine.Parent = container

	-- 3️⃣ TEXTO PRINCIPAL Y SUBTEXTO
	local mainText = Instance.new("TextLabel")
	mainText.Size = UDim2.new(1, 0, 0.6, 0)
	mainText.Position = UDim2.new(0, 0, 0.1, 0)
	mainText.BackgroundTransparency = 1
	mainText.Text = "L E V E L   U P"
	mainText.Font = Enum.Font.GothamBlack -- Más imponente que Jura para títulos grandes
	mainText.TextColor3 = Color3.fromRGB(255, 255, 255)
	mainText.TextScaled = true
	mainText.TextTransparency = 1
	mainText.ZIndex = 2
	mainText.Parent = container

	local textGradient = Instance.new("UIGradient")
	textGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 0))
	})
	textGradient.Rotation = 90
	textGradient.Parent = mainText

	local subText = Instance.new("TextLabel")
	subText.Size = UDim2.new(1, 0, 0.3, 0)
	subText.Position = UDim2.new(0, 0, 0.65, 0)
	subText.BackgroundTransparency = 1
	subText.Text = "NUEVO NIVEL ALCANZADO: <font color='#FFD700'>" .. tostring(newLevel) .. "</font>"
	subText.RichText = true
	subText.Font = Enum.Font.GothamMedium
	subText.TextColor3 = Color3.fromRGB(200, 200, 200)
	subText.TextScaled = true
	subText.TextTransparency = 1
	subText.ZIndex = 2
	subText.Parent = container

	-- ==========================================
	-- 🎬 LÍNEA DE TIEMPO DE ANIMACIÓN
	-- ==========================================

	-- 1. Desvanecer el destello instantáneamente
	TweenService:Create(screenFlash, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	task.delay(0.5, function() screenFlash:Destroy() end)

	-- 2. Las líneas se expanden desde el centro
	TweenService:Create(topLine, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2)}):Play()
	TweenService:Create(bottomLine, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2)}):Play()

	task.wait(0.2)

	-- 3. El panel de cristal aparece y las letras hacen "Pop"
	TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.3}):Play()

	mainText.UIScale = Instance.new("UIScale", mainText)
	mainText.UIScale.Scale = 2 -- Empieza gigante
	TweenService:Create(mainText.UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(mainText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	TweenService:Create(subText, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

	-- 4. Explosión de partículas UI
	emitUIParticles(container)

	-- 5. Suspense suave (El cuadro flota muy lentamente)
	TweenService:Create(container, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Position = container.Position - UDim2.new(0, 0, 0.02, 0)
	}):Play()

	task.wait(2.5)

	-- 6. Cierre (Se encoge rápidamente y desaparece)
	TweenService:Create(mainText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
	TweenService:Create(subText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
	TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()

	task.wait(0.4)
	gui:Destroy()
end)
