local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local NormalDropEvent = SAO_Events:WaitForChild("Loot_Normal")
local BossDropEvent = SAO_Events:WaitForChild("Loot_Boss")

-- 📦 CARGAMOS EL MÓDULO DE DROPS
local DropData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Drops"))

-- Sonidos (Cámbialos si tienes unos mejores)
local sfxNormal = Instance.new("Sound", workspace); sfxNormal.SoundId = "rbxassetid://6895079853"; sfxNormal.Volume = 0.5
local sfxBoss = Instance.new("Sound", workspace); sfxBoss.SoundId = "rbxassetid://6114983058"; sfxBoss.Volume = 1
local sfxPop = Instance.new("Sound", workspace); sfxPop.SoundId = "rbxassetid://6895079853"; sfxPop.Volume = 0.3; sfxPop.Pitch = 1.5

-- Contenedor principal
local LootScreen = Instance.new("ScreenGui")
LootScreen.Name = "SAO_LootScreen"
LootScreen.DisplayOrder = 100
LootScreen.IgnoreGuiInset = true
LootScreen.Parent = PlayerGui

-- Contenedor para notificaciones normales (Lado izquierdo al estilo SAO)
local SideContainer = Instance.new("Frame", LootScreen)
SideContainer.Size = UDim2.new(0, 280, 0.7, 0)
SideContainer.Position = UDim2.new(0, 20, 0.2, 0) -- Cambiado al lado izquierdo para no tapar menús
SideContainer.BackgroundTransparency = 1

local listLayout = Instance.new("UIListLayout", SideContainer)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- ==========================================
-- 🛠️ FUNCIÓN: PARTÍCULAS DE ÉXITO (JEFE)
-- ==========================================
local function emitVictoryParticles(parentFrame)
	for i = 1, 30 do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(5, 15), 0, math.random(5, 15))
		particle.Position = UDim2.new(0.5, 0, 0.5, 0)
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.BackgroundColor3 = (math.random(1,2)==1) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
		particle.Rotation = math.random(0, 360)
		particle.BorderSizePixel = 0
		particle.ZIndex = 0
		particle.Parent = parentFrame

		local angle = math.rad(math.random(0, 360))
		local distance = math.random(150, 400)
		local targetX = 0.5 + (math.cos(angle) * (distance / parentFrame.AbsoluteSize.X))
		local targetY = 0.5 + (math.sin(angle) * (distance / parentFrame.AbsoluteSize.Y))

		local duration = math.random(50, 100) / 100
		TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(targetX, 0, targetY, 0),
			Size = UDim2.new(0, 0, 0, 0),
			Rotation = particle.Rotation + 180,
			BackgroundTransparency = 1
		}):Play()
		task.delay(duration, function() particle:Destroy() end)
	end
end

-- ==========================================
-- 🌿 NOTIFICACIÓN DE ENEMIGO NORMAL
-- ==========================================
NormalDropEvent.OnClientEvent:Connect(function(itemsObtained)
	sfxNormal:Play()

	for _, item in ipairs(itemsObtained) do
		local data = DropData[item.Nombre]

		local dropFrame = Instance.new("CanvasGroup", SideContainer)
		dropFrame.Size = UDim2.new(1, 0, 0, 45)
		dropFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		dropFrame.BackgroundTransparency = 0.3
		dropFrame.GroupTransparency = 1
		Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 4)
		Instance.new("UIStroke", dropFrame).Color = Color3.fromRGB(100, 100, 110)

		-- Línea de color indicando rareza
		local rarityLine = Instance.new("Frame", dropFrame)
		rarityLine.Size = UDim2.new(0, 4, 1, 0)
		rarityLine.BackgroundColor3 = data.Color
		rarityLine.BorderSizePixel = 0

		-- Texto
		local txt = Instance.new("TextLabel", dropFrame)
		txt.Size = UDim2.new(1, -20, 1, 0)
		txt.Position = UDim2.new(0, 15, 0, 0)
		txt.BackgroundTransparency = 1
		txt.Text = "Obtenido: <font color='#FFFFFF'>" .. item.Nombre .. "</font> x" .. item.Cantidad
		txt.RichText = true
		txt.Font = Enum.Font.GothamMedium
		txt.TextSize = 14
		txt.TextColor3 = data.Color
		txt.TextXAlignment = Enum.TextXAlignment.Left

		-- Animación
		dropFrame.Position = UDim2.new(-1, -50, 0, 0) -- Entra desde la izquierda
		TweenService:Create(dropFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0}):Play()

		task.delay(3.5, function()
			local fadeOut = TweenService:Create(dropFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
			fadeOut:Play()
			fadeOut.Completed:Wait()
			dropFrame:Destroy()
		end)
		task.wait(0.15)
	end
end)

-- ==========================================
-- 👑 PANTALLA GIGANTE DE JEFE
-- ==========================================
BossDropEvent.OnClientEvent:Connect(function(bossName, itemsObtained)
	sfxBoss:Play()

	local bossPanel = Instance.new("Frame", LootScreen)
	bossPanel.Size = UDim2.new(1, 0, 1, 0)
	bossPanel.BackgroundTransparency = 1

	local bg = Instance.new("Frame", bossPanel)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 1

	-- Título
	local title = Instance.new("TextLabel", bossPanel)
	title.Size = UDim2.new(1, 0, 0, 100)
	title.Position = UDim2.new(0, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text = "CONGRATULATIONS!!"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 75
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextTransparency = 1
	title.ZIndex = 2

	local gradient = Instance.new("UIGradient", title)
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))
	})
	gradient.Rotation = 90

	local glow = Instance.new("UIStroke", title)
	glow.Color = Color3.fromRGB(255, 100, 0); glow.Thickness = 4; glow.Transparency = 1

	-- Ventana SAO central
	local window = Instance.new("CanvasGroup", bossPanel)
	window.Size = UDim2.new(0, 500, 0, 0) -- Empieza cerrada
	window.Position = UDim2.new(0.5, -250, 0.35, 0)
	window.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	window.BackgroundTransparency = 0.2
	window.GroupTransparency = 1
	Instance.new("UICorner", window).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", window).Color = Color3.fromRGB(255, 215, 0)

	local grid = Instance.new("UIListLayout", window)
	grid.Padding = UDim.new(0, 10)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Center

	local padding = Instance.new("UIPadding", window)
	padding.PaddingTop = UDim.new(0, 20); padding.PaddingBottom = UDim.new(0, 20)

	-- Botón para cerrar
	local closeBtn = Instance.new("TextButton", bossPanel)
	closeBtn.Size = UDim2.new(1, 0, 1, 0); closeBtn.BackgroundTransparency = 1; closeBtn.Text = ""

	-- 🎬 ANIMACIÓN PRINCIPAL
	TweenService:Create(bg, TweenInfo.new(1), {BackgroundTransparency = 0.5}):Play()

	title.UIScale = Instance.new("UIScale", title)
	title.UIScale.Scale = 1.5
	TweenService:Create(title.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	TweenService:Create(glow, TweenInfo.new(0.5), {Transparency = 0.3}):Play()

	emitVictoryParticles(bossPanel)

	task.wait(0.6)

	-- Abrir ventana
	local targetHeight = (#itemsObtained * 60) + 40
	TweenService:Create(window, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, targetHeight), GroupTransparency = 0}):Play()

	task.wait(0.3)

	-- Generar items en cascada
	for _, item in ipairs(itemsObtained) do
		sfxPop:Play()
		local data = DropData[item.Nombre]

		local itemRow = Instance.new("CanvasGroup", window)
		itemRow.Size = UDim2.new(0.9, 0, 0, 50)
		itemRow.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		itemRow.BackgroundTransparency = 0.2
		itemRow.GroupTransparency = 1
		Instance.new("UICorner", itemRow).CornerRadius = UDim.new(0, 6)

		local stroke = Instance.new("UIStroke", itemRow)
		stroke.Color = data.Color; stroke.Thickness = 1.5

		local lbl = Instance.new("TextLabel", itemRow)
		lbl.Size = UDim2.new(1, -20, 1, 0)
		lbl.Position = UDim2.new(0, 10, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = data.Rareza .. " | <font color='#FFFFFF'>" .. item.Nombre .. "</font> x" .. item.Cantidad
		lbl.RichText = true
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 20
		lbl.TextColor3 = data.Color
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		itemRow.Position = UDim2.new(0, 50, 0, 0)
		TweenService:Create(itemRow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}):Play()

		task.wait(0.15) -- Retraso entre cada ítem (Efecto cascada)
	end

	-- Lógica para cerrar
	closeBtn.MouseButton1Click:Connect(function()
		closeBtn:Destroy()
		TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		TweenService:Create(glow, TweenInfo.new(0.3), {Transparency = 1}):Play()
		TweenService:Create(window, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 500, 0, 0), GroupTransparency = 1}):Play()
		local fadeOut = TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		fadeOut:Play()
		fadeOut.Completed:Wait()
		bossPanel:Destroy()
	end)
end)
