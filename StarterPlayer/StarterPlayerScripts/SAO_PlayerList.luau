local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerCards = {} -- Guarda las tarjetas UI de cada jugador
local healthConnections = {} -- Guarda las conexiones para no dar lag

-- =========================================================
-- 🎨 1. CREACIÓN DEL CONTENEDOR PRINCIPAL
-- =========================================================
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_PlayerListHUD"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local listContainer = Instance.new("Frame")
listContainer.Name = "Container"
listContainer.Size = UDim2.new(0, 250, 0.6, 0)
listContainer.Position = UDim2.new(1, -20, 0.2, 0) -- Lado derecho de la pantalla
listContainer.AnchorPoint = Vector2.new(1, 0)
listContainer.BackgroundTransparency = 1
listContainer.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.Name -- Orden alfabético
layout.Parent = listContainer

-- =========================================================
-- ✨ 2. ANIMACIONES SMOOTH
-- =========================================================
local function TweenFade(guiObject, targetTransparency, targetSize)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local goals = {BackgroundTransparency = targetTransparency}
	if targetSize then goals.Size = targetSize end

	local tween = TweenService:Create(guiObject, tweenInfo, goals)
	tween:Play()
	return tween
end

-- =========================================================
-- 🗂️ 3. CREAR TARJETA DE JUGADOR (Diseño SAO Pro)
-- =========================================================
local function CreatePlayerCard(player)
	if playerCards[player] then return end

	-- Contenedor de la tarjeta
	local card = Instance.new("Frame")
	card.Name = player.Name
	card.Size = UDim2.new(1, 50, 0, 60) -- Empieza un poco más grande para el efecto de entrada
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	card.BackgroundTransparency = 1 -- Empieza invisible
	card.Parent = listContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	-- Avatar del Jugador
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Size = UDim2.new(0, 46, 0, 46)
	avatarImage.Position = UDim2.new(0, 7, 0.5, -23)
	avatarImage.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	avatarImage.BackgroundTransparency = 1
	avatarImage.ImageTransparency = 1
	avatarImage.Parent = card
	Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(1, 0) -- Circular

	-- Cargar el Avatar Real (Smooth)
	task.spawn(function()
		local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		if isReady then 
			avatarImage.Image = content 
			TweenService:Create(avatarImage, TweenInfo.new(0.5), {ImageTransparency = 0, BackgroundTransparency = 0}):Play()
		end
	end)

	-- Nombre y Nivel
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -70, 0, 20)
	nameLabel.Position = UDim2.new(0, 60, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.TextTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local lvlLabel = Instance.new("TextLabel")
	lvlLabel.Size = UDim2.new(0, 50, 0, 20)
	lvlLabel.Position = UDim2.new(1, -55, 0, 8)
	lvlLabel.BackgroundTransparency = 1
	lvlLabel.Text = "Lv.1" -- Aquí luego conectaremos tus leaderstats de nivel
	lvlLabel.TextTransparency = 1
	lvlLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	lvlLabel.Font = Enum.Font.GothamBold
	lvlLabel.TextSize = 12
	lvlLabel.TextXAlignment = Enum.TextXAlignment.Right
	lvlLabel.Parent = card

	-- Barra de Vida (SAO Style)
	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -70, 0, 6)
	hpBg.Position = UDim2.new(0, 60, 1, -18)
	hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	hpBg.BackgroundTransparency = 1
	hpBg.BorderSizePixel = 0
	hpBg.Parent = card
	Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	hpFill.BackgroundTransparency = 1
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

	-- Efecto de Entrada (Slide In y Fade)
	TweenFade(card, 0.3, UDim2.new(1, 0, 0, 60))
	TweenService:Create(nameLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	TweenService:Create(lvlLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	TweenService:Create(hpBg, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
	TweenService:Create(hpFill, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()

	playerCards[player] = card

	-- =========================================================
	-- ❤️ 4. RASTREO DE VIDA EN TIEMPO REAL (Smooth)
	-- =========================================================
	local function UpdateHealth(humanoid)
		if not humanoid then return end
		local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

		-- Tween suave para el tamaño
		local info = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(hpFill, info, {Size = UDim2.new(percent, 0, 1, 0)}):Play()

		-- Cambio de color SAO
		local color = Color3.fromRGB(0, 255, 100)
		if percent <= 0.5 then color = Color3.fromRGB(255, 200, 0) end
		if percent <= 0.2 then color = Color3.fromRGB(255, 50, 50) end
		TweenService:Create(hpFill, info, {BackgroundColor3 = color}):Play()
	end

	local function ConnectCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			UpdateHealth(humanoid)
			-- Desconectar el anterior si existe
			if healthConnections[player] then healthConnections[player]:Disconnect() end

			healthConnections[player] = humanoid.HealthChanged:Connect(function()
				UpdateHealth(humanoid)
			end)
		end
	end

	if player.Character then ConnectCharacter(player.Character) end
	player.CharacterAdded:Connect(ConnectCharacter)
end

-- =========================================================
-- 🗑️ 5. REMOVER TARJETA (Efecto de Salida)
-- =========================================================
local function RemovePlayerCard(player)
	if healthConnections[player] then
		healthConnections[player]:Disconnect()
		healthConnections[player] = nil
	end

	local card = playerCards[player]
	if card then
		playerCards[player] = nil
		-- Efecto de salida (Se desliza hacia la derecha y desaparece)
		local fadeOut = TweenFade(card, 1, UDim2.new(1, 50, 0, 60))
		for _, child in ipairs(card:GetDescendants()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			elseif child:IsA("ImageLabel") or child:IsA("Frame") then
				TweenService:Create(child, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
				if child:IsA("ImageLabel") then
					TweenService:Create(child, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
				end
			end
		end

		fadeOut.Completed:Connect(function()
			card:Destroy()
		end)
	end
end

-- =========================================================
-- 🚀 6. INICIALIZACIÓN DE EVENTOS
-- =========================================================
Players.PlayerAdded:Connect(CreatePlayerCard)
Players.PlayerRemoving:Connect(RemovePlayerCard)

-- Agregar a los jugadores que ya están en el server
for _, player in ipairs(Players:GetPlayers()) do
	CreatePlayerCard(player)
end
