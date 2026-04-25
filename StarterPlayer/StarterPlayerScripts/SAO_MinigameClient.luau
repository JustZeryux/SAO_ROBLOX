local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local armWrestleEvent = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes"):WaitForChild("ArmWrestleEvent")

-- =========================================================
-- 🎨 1. GENERACIÓN DE INTERFAZ (UI)
-- =========================================================
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_ArmWrestleUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 400, 0, 150)
mainPanel.Position = UDim2.new(0.5, -200, 0.8, -75) -- Abajo, sobre la hotbar
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainPanel.BackgroundTransparency = 0.1
mainPanel.Visible = false
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", mainPanel).Color = Color3.fromRGB(150, 150, 150)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "¡SPAMEA EL CLIC IZQUIERDO!"
title.TextColor3 = Color3.fromRGB(255, 200, 0)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.Parent = mainPanel

-- Barra de Fuerza
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0.9, 0, 0, 30)
barBg.Position = UDim2.new(0.05, 0, 0.5, 0)
barBg.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Fondo Rojo (P2)
barBg.Parent = mainPanel
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0.5, 0)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0.5, 0, 1, 0) -- Empieza a la mitad (50%)
barFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Relleno Azul (P1)
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0.5, 0)

local marker = Instance.new("Frame")
marker.Size = UDim2.new(0, 4, 1.5, 0)
marker.Position = UDim2.new(0.5, -2, -0.25, 0)
marker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
marker.Parent = barBg

local resultText = Instance.new("TextLabel")
resultText.Size = UDim2.new(1, 0, 1, 0)
resultText.BackgroundTransparency = 1
resultText.Text = ""
resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
resultText.Font = Enum.Font.GothamBlack
resultText.TextSize = 40
resultText.Visible = false
resultText.Parent = screenGui

-- =========================================================
-- 🎮 2. LÓGICA DE JUEGO
-- =========================================================
local isPlaying = false
local myRole = ""

armWrestleEvent.OnClientEvent:Connect(function(action, data)
	if action == "Start" then
		myRole = data -- "P1" o "P2"
		isPlaying = true
		mainPanel.Visible = true
		barFill.Size = UDim2.new(0.5, 0, 1, 0)

		-- Efecto de Pop
		mainPanel.Size = UDim2.new(0, 380, 0, 130)
		TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 400, 0, 150)}):Play()

	elseif action == "Update" then
		-- data es el Score (0 a 100)
		local percent = math.clamp(data / 100, 0, 1)

		-- Animación suave para que la barra no se vea robótica
		TweenService:Create(barFill, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.new(percent, 0, 1, 0)}):Play()

	elseif action == "End" then
		isPlaying = false
		mainPanel.Visible = false

		-- Mostrar resultado ("¡GANASTE!" o "¡PERDISTE!")
		resultText.Text = data
		resultText.Visible = true
		if data == "¡GANASTE!" then
			resultText.TextColor3 = Color3.fromRGB(0, 255, 100)
		else
			resultText.TextColor3 = Color3.fromRGB(255, 50, 50)
		end

		task.wait(2.5)
		resultText.Visible = false
	end
end)

-- Capturar los clics súper rápido
UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end

	if isPlaying and input.UserInputType == Enum.UserInputType.MouseButton1 then
		armWrestleEvent:FireServer("Click")
	end
end)
