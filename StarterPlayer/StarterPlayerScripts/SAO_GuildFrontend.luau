local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local guildRequest = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes"):WaitForChild("GuildRequest")

-- =========================================================
-- 🎨 GENERACIÓN DE INTERFAZ (Estilo App Moderna)
-- =========================================================
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_GuildUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 400, 0, 300)
mainPanel.Position = UDim2.new(0.5, -200, 0.5, -150)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainPanel.BackgroundTransparency = 0.05
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", mainPanel).Color = Color3.fromRGB(50, 50, 55)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundTransparency = 1
title.Text = "CREAR GREMIO"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = mainPanel

local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(1, -60, 0, 50)
inputFrame.Position = UDim2.new(0, 30, 0, 100)
inputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
inputFrame.Parent = mainPanel
Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 8)

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, -20, 1, 0)
nameInput.Position = UDim2.new(0, 10, 0, 0)
nameInput.BackgroundTransparency = 1
nameInput.Text = ""
nameInput.PlaceholderText = "Nombre del Gremio..."
nameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
nameInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
nameInput.Font = Enum.Font.Gotham
nameInput.TextSize = 16
nameInput.TextXAlignment = Enum.TextXAlignment.Left
nameInput.ClearTextOnFocus = false
nameInput.Parent = inputFrame

local createBtn = Instance.new("TextButton")
createBtn.Size = UDim2.new(1, -60, 0, 50)
createBtn.Position = UDim2.new(0, 30, 1, -80)
createBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
createBtn.Text = "FUNDAR"
createBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
createBtn.Font = Enum.Font.GothamBold
createBtn.TextSize = 18
createBtn.Parent = mainPanel
Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = mainPanel

-- =========================================================
-- 🚀 LÓGICA DE INTERACCIÓN
-- =========================================================
-- Abrir/Cerrar menú con la tecla G
UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	if input.KeyCode == Enum.KeyCode.G then
		mainPanel.Visible = not mainPanel.Visible
		if mainPanel.Visible then
			statusLabel.Text = ""
			nameInput.Text = ""

			-- Animación de entrada suave
			mainPanel.Size = UDim2.new(0, 380, 0, 280)
			TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 400, 0, 300)}):Play()
		end
	end
end)

-- Enviar petición al servidor
createBtn.MouseButton1Click:Connect(function()
	local desiredName = nameInput.Text
	if desiredName == "" then return end

	createBtn.Text = "PROCESANDO..."
	createBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

	-- Llamada asíncrona al backend
	local success, message = guildRequest:InvokeServer("Create", desiredName)

	if success then
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		statusLabel.Text = message
		task.wait(1)
		mainPanel.Visible = false
	else
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		statusLabel.Text = message
		createBtn.Text = "FUNDAR"
		createBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	end
end)

-- =========================================================
-- 💌 SISTEMA DE INVITACIONES (Popup UI)
-- =========================================================
local guildInviteEvent = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes"):WaitForChild("GuildInviteEvent")

-- Crear la alerta de invitación dinámica
local invitePanel = Instance.new("Frame")
invitePanel.Size = UDim2.new(0, 300, 0, 150)
invitePanel.Position = UDim2.new(0.5, -150, 0.2, -75) -- Arriba al centro
invitePanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
invitePanel.Visible = false
invitePanel.Parent = screenGui
Instance.new("UICorner", invitePanel).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", invitePanel).Color = Color3.fromRGB(255, 170, 0) -- Borde dorado

local inviteText = Instance.new("TextLabel")
inviteText.Size = UDim2.new(1, -20, 0, 60)
inviteText.Position = UDim2.new(0, 10, 0, 10)
inviteText.BackgroundTransparency = 1
inviteText.Text = ""
inviteText.TextColor3 = Color3.fromRGB(255, 255, 255)
inviteText.Font = Enum.Font.GothamSemibold
inviteText.TextSize = 14
inviteText.TextWrapped = true
inviteText.Parent = invitePanel

local acceptBtn = Instance.new("TextButton")
acceptBtn.Size = UDim2.new(0.4, 0, 0, 40)
acceptBtn.Position = UDim2.new(0.05, 0, 1, -50)
acceptBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
acceptBtn.Text = "ACEPTAR"
acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
acceptBtn.Font = Enum.Font.GothamBold
acceptBtn.Parent = invitePanel
Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 8)

local declineBtn = Instance.new("TextButton")
declineBtn.Size = UDim2.new(0.4, 0, 0, 40)
declineBtn.Position = UDim2.new(0.55, 0, 1, -50)
declineBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
declineBtn.Text = "RECHAZAR"
declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
declineBtn.Font = Enum.Font.GothamBold
declineBtn.Parent = invitePanel
Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 8)

-- Recibir invitación del servidor
guildInviteEvent.OnClientEvent:Connect(function(guildName, inviterName)
	inviteText.Text = "¡" .. inviterName .. " te ha invitado a unirte a <" .. guildName .. ">!"
	invitePanel.Visible = true

	-- Animación pop
	invitePanel.Size = UDim2.new(0, 280, 0, 130)
	TweenService:Create(invitePanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 150)}):Play()
end)

acceptBtn.MouseButton1Click:Connect(function()
	invitePanel.Visible = false
	local success, msg = guildRequest:InvokeServer("Accept")
	if success then
		print("Unido al gremio exitosamente.")
	end
end)

declineBtn.MouseButton1Click:Connect(function()
	invitePanel.Visible = false
	-- Solo la ignoramos, el servidor la borrará cuando el jugador acepte otra cosa o se desconecte
end)

-- MOCKUP PARA PROBAR INVITAR A ALGUIEN (En consola)
-- Para que tú como líder puedas invitar, por ahora puedes usar la consola (F9) o crear un botón extra en tu menú.
-- Ejemplo de uso: guildRequest:InvokeServer("Invite", "NombreDelJugador")
