local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local teleportEvent = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes"):WaitForChild("TeleportEvent")

-- =========================================================
-- 🎨 1. GENERACIÓN DEL MENÚ Y TRANSICIÓN
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_TeleportUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Pantalla de Fade to Black (Transición)
local fadeFrame = Instance.new("Frame")
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fadeFrame.BackgroundTransparency = 1
fadeFrame.Visible = false
fadeFrame.ZIndex = 10
fadeFrame.Parent = screenGui

-- Menú Principal
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 350, 0, 450)
menuFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
menuFrame.BackgroundTransparency = 0.1
menuFrame.Visible = false
menuFrame.Parent = screenGui
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 15)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "TELEPORT GATE"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.Parent = menuFrame

local listContainer = Instance.new("ScrollingFrame")
listContainer.Size = UDim2.new(1, -20, 1, -70)
listContainer.Position = UDim2.new(0, 10, 0, 50)
listContainer.BackgroundTransparency = 1
listContainer.ScrollBarThickness = 4
listContainer.Parent = menuFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = listContainer

-- Botón de Cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = menuFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.5, 0)

closeBtn.MouseButton1Click:Connect(function()
	menuFrame.Visible = false
end)

-- =========================================================
-- 🚀 2. LÓGICA DE VIAJE
-- =========================================================
local function PerformTeleport(destinationName)
	menuFrame.Visible = false
	fadeFrame.Visible = true

	-- Fade In (Se pone negro)
	local fadeOutTween = TweenService:Create(fadeFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 0})
	fadeOutTween:Play()
	fadeOutTween.Completed:Wait()

	-- Notificamos al servidor que haga el viaje
	teleportEvent:FireServer("Teleport", destinationName)
	task.wait(0.5) -- Pequeña pausa para cargar el mapa

	-- Fade Out (Vuelve la visión)
	local fadeInTween = TweenService:Create(fadeFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
	fadeInTween:Play()
	fadeInTween.Completed:Wait()

	fadeFrame.Visible = false
end

-- Escuchar cuando el servidor nos manda los destinos
teleportEvent.OnClientEvent:Connect(function(action, destinations)
	if action == "OpenMenu" then
		-- Limpiar botones anteriores
		for _, child in ipairs(listContainer:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		-- Crear botones dinámicos
		for _, destName in ipairs(destinations) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -20, 0, 45)
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
			btn.Text = destName
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Font = Enum.Font.GothamSemibold
			btn.TextSize = 16
			btn.Parent = listContainer
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

			btn.MouseButton1Click:Connect(function()
				PerformTeleport(destName)
			end)
		end

		menuFrame.Visible = true
	end
end)
