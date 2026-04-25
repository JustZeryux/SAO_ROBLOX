local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local ItemsFolder = ReplicatedStorage.SAO_Survival:WaitForChild("Items")

-- Variables de Estado
local isBuilding = false
local ghostModel = nil
local currentItemData = nil
local rotation = 0
local loadedItems = {}
local activeCategory = "All"

-- =========================================================
-- 🎨 1. GENERADOR DE INTERFAZ DINÁMICA (Estética del Video)
-- =========================================================
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurvivalUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Panel Principal
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 800, 0, 500)
mainPanel.Position = UDim2.new(0.5, -400, 0.5, -250)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainPanel.BackgroundTransparency = 0.05
mainPanel.Visible = false
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 15)

-- 1A. Barra Lateral Izquierda (Categorías)
local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(0, 180, 1, -40)
sidebar.Position = UDim2.new(0, 20, 0, 20)
sidebar.BackgroundTransparency = 1
sidebar.ScrollBarThickness = 2
sidebar.Parent = mainPanel

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 10)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

-- 1B. Panel Central (Cuadrícula de Items)
local itemGridFrame = Instance.new("ScrollingFrame")
itemGridFrame.Size = UDim2.new(1, -450, 1, -40)
itemGridFrame.Position = UDim2.new(0, 220, 0, 20)
itemGridFrame.BackgroundTransparency = 1
itemGridFrame.ScrollBarThickness = 4
itemGridFrame.Parent = mainPanel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 100, 0, 100)
gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = itemGridFrame

-- 1C. Panel de Detalles (Derecha)
local detailPanel = Instance.new("Frame")
detailPanel.Size = UDim2.new(0, 200, 1, -40)
detailPanel.Position = UDim2.new(1, -220, 0, 20)
detailPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
detailPanel.Parent = mainPanel
Instance.new("UICorner", detailPanel).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 30)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Selecciona un item"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = detailPanel

local descLabel = Instance.new("TextLabel")
descLabel.Size = UDim2.new(1, -20, 0, 60)
descLabel.Position = UDim2.new(0, 10, 0, 45)
descLabel.BackgroundTransparency = 1
descLabel.Text = ""
descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
descLabel.Font = Enum.Font.Gotham
descLabel.TextSize = 14
descLabel.TextWrapped = true
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.TextYAlignment = Enum.TextYAlignment.Top
descLabel.Parent = detailPanel

local reqLabel = Instance.new("TextLabel")
reqLabel.Size = UDim2.new(1, -20, 0, 150)
reqLabel.Position = UDim2.new(0, 10, 0, 120)
reqLabel.BackgroundTransparency = 1
reqLabel.Text = ""
reqLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
reqLabel.Font = Enum.Font.Gotham
reqLabel.TextSize = 14
reqLabel.TextXAlignment = Enum.TextXAlignment.Left
reqLabel.TextYAlignment = Enum.TextYAlignment.Top
reqLabel.Parent = detailPanel

local buildBtn = Instance.new("TextButton")
buildBtn.Size = UDim2.new(1, -20, 0, 45)
buildBtn.Position = UDim2.new(0, 10, 1, -55)
buildBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45) -- Desactivado por defecto
buildBtn.Text = "BUILD"
buildBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
buildBtn.Font = Enum.Font.GothamBold
buildBtn.TextSize = 18
buildBtn.AutoButtonColor = false
buildBtn.Parent = detailPanel
Instance.new("UICorner", buildBtn).CornerRadius = UDim.new(0, 8)

-- =========================================================
-- 🗃️ 2. LÓGICA DE DATOS Y POBLACIÓN DE UI
-- =========================================================
local function PopulateUI()
	-- Limpiar UI existente
	for _, child in ipairs(sidebar:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _, child in ipairs(itemGridFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	loadedItems = {}

	local categories = {["All"] = true}

	-- Cargar datos de los módulos
	for _, module in ipairs(ItemsFolder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local data = require(module)
			table.insert(loadedItems, data)
			categories[data.Category] = true
		end
	end

	-- Crear botones de categoría
	for cat, _ in pairs(categories) do
		local catBtn = Instance.new("TextButton")
		catBtn.Size = UDim2.new(1, 0, 0, 40)
		catBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		catBtn.Text = cat
		catBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		catBtn.Font = Enum.Font.GothamSemibold
		catBtn.TextSize = 16
		catBtn.Parent = sidebar
		Instance.new("UICorner", catBtn).CornerRadius = UDim.new(0, 6)

		catBtn.MouseButton1Click:Connect(function()
			activeCategory = cat
			RefreshGrid()
			-- Resaltar botón seleccionado
			for _, btn in ipairs(sidebar:GetChildren()) do
				if btn:IsA("TextButton") then btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40) end
			end
			catBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
		end)
	end
end

function RefreshGrid()
	for _, child in ipairs(itemGridFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	for _, item in ipairs(loadedItems) do
		if activeCategory == "All" or item.Category == activeCategory then
			local itemBtn = Instance.new("TextButton")
			itemBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
			itemBtn.Text = item.Name
			itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemBtn.Font = Enum.Font.GothamBold
			itemBtn.TextSize = 14
			itemBtn.Parent = itemGridFrame
			Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 10)

			itemBtn.MouseButton1Click:Connect(function()
				SelectDetailedItem(item)
			end)
		end
	end
end

function SelectDetailedItem(item)
	currentItemData = item
	titleLabel.Text = item.Name
	descLabel.Text = item.Description or "Sin descripción."

	local reqText = "Requisitos:\n"
	for mat, amt in pairs(item.Ingredients) do
		reqText = reqText .. "- " .. mat .. ": " .. amt .. "\n"
	end
	reqLabel.Text = reqText

	-- Activar botón de construcción
	buildBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	buildBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- =========================================================
-- 🔨 3. LÓGICA DE CONSTRUCCIÓN Y HOLOGRAMA
-- =========================================================
local function StartBuilding()
	if not currentItemData then return end
	if ghostModel then ghostModel:Destroy() end

	local originalModel = ReplicatedStorage:FindFirstChild(currentItemData.ModelName)
	if not originalModel then warn("Falta el modelo 3D en ReplicatedStorage: " .. currentItemData.ModelName) return end

	ghostModel = originalModel:Clone()
	for _, part in ipairs(ghostModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.5
			part.CanCollide = false
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(0, 255, 150)
		end
	end

	ghostModel.Parent = workspace
	isBuilding = true
	mainPanel.Visible = false 
end

buildBtn.MouseButton1Click:Connect(function()
	if currentItemData then StartBuilding() end
end)

RunService.RenderStepped:Connect(function()
	if isBuilding and ghostModel and ghostModel.PrimaryPart then
		mouse.TargetFilter = ghostModel
		local cframe = CFrame.new(mouse.Hit.Position) * CFrame.Angles(0, math.rad(rotation), 0)
		ghostModel:PivotTo(cframe)
	end
end)

UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end

	if input.KeyCode == Enum.KeyCode.B and not isBuilding then
		mainPanel.Visible = not mainPanel.Visible
		if mainPanel.Visible then
			PopulateUI()
			RefreshGrid()
		end
	end

	if input.KeyCode == Enum.KeyCode.R and isBuilding then
		rotation = rotation + 45
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and isBuilding then
		Remotes.CraftEvent:FireServer(currentItemData.Name, ghostModel:GetPivot())
		ghostModel:Destroy()
		ghostModel = nil
		isBuilding = false
	end
end)

-- =========================================================
-- 🪓 4. SISTEMA DE RECOLECCIÓN (Game Feel: Animación y Sonido)
-- =========================================================
local lastHarvestTime = 0
local HARVEST_COOLDOWN = 0.6 

-- 🔥 IMPORTANTE: Reemplaza los 0000000 con el ID de tu animación de hachazo
local swingAnimation = Instance.new("Animation")
swingAnimation.AnimationId = "rbxassetid://0000000" 
local loadedAnim = nil

mouse.Button1Down:Connect(function()
	if isBuilding or mainPanel.Visible then return end
	if tick() - lastHarvestTime < HARVEST_COOLDOWN then return end

	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")

	local equippedTool = character:FindFirstChildOfClass("Tool")
	if not equippedTool or equippedTool.Name ~= "Axe" then return end

	local target = mouse.Target
	if target and target.Name == "Tree" then
		if (character.HumanoidRootPart.Position - target.Position).Magnitude < 15 then
			lastHarvestTime = tick() 

			-- 1. Reproducir Animación
			if humanoid then
				if not loadedAnim then loadedAnim = humanoid:LoadAnimation(swingAnimation) end
				loadedAnim:Play()
			end

			-- 2. Reproducir Sonido
			local handle = equippedTool:FindFirstChild("Handle")
			if handle and handle:FindFirstChild("ChopSound") then
				handle.ChopSound:Play()
			end

			-- 3. Efecto Visual de Impacto
			local oldColor = target.Color
			target.Color = Color3.fromRGB(255, 100, 100)
			task.delay(0.1, function()
				if target then target.Color = oldColor end
			end)

			-- 4. Enviar al Servidor
			Remotes.HarvestEvent:FireServer("Wood legs", 1, target)
		end
	end
end)
-- =========================================================
-- 🎒 5. HOTBAR (INVENTARIO VISUAL INFERIOR)
-- =========================================================
local hotbarPanel = Instance.new("Frame")
hotbarPanel.Name = "Hotbar"
hotbarPanel.Size = UDim2.new(0, 500, 0, 60)
hotbarPanel.Position = UDim2.new(0.5, -250, 1, -80) -- Abajo al centro
hotbarPanel.BackgroundTransparency = 1
hotbarPanel.Parent = screenGui

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 10)
hotbarLayout.Parent = hotbarPanel

-- Crear 5 casillas vacías por defecto
local slots = {}
for i = 1, 5 do
	local slot = Instance.new("Frame")
	slot.Size = UDim2.new(0, 60, 0, 60)
	slot.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	slot.BackgroundTransparency = 0.2
	slot.Parent = hotbarPanel
	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 10)

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(60, 60, 65)
	uiStroke.Thickness = 2
	uiStroke.Parent = slot

	local amountLabel = Instance.new("TextLabel")
	amountLabel.Name = "Amount"
	amountLabel.Size = UDim2.new(1, -5, 0, 20)
	amountLabel.Position = UDim2.new(0, 0, 1, -20)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = ""
	amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	amountLabel.Font = Enum.Font.GothamBold
	amountLabel.TextSize = 14
	amountLabel.TextXAlignment = Enum.TextXAlignment.Right
	amountLabel.Parent = slot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 0, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ""
	nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 10
	nameLabel.Parent = slot

	slots[i] = slot
end

-- Escuchar cuando el servidor nos mande el inventario actualizado
Remotes:WaitForChild("UpdateInventory").OnClientEvent:Connect(function(inventoryData)
	-- Limpiar visualmente todas las casillas primero
	for _, slot in ipairs(slots) do
		slot.Amount.Text = ""
		slot.ItemName.Text = ""
	end

	-- Llenar las casillas con lo que tenemos
	local slotIndex = 1
	for itemName, amount in pairs(inventoryData) do
		if amount > 0 and slotIndex <= 5 then
			slots[slotIndex].ItemName.Text = itemName
			slots[slotIndex].Amount.Text = "x" .. amount
			slotIndex = slotIndex + 1
		end
	end

	-- Actualizar la UI de construcción si está abierta (para ver si ya podemos construir)
	if mainPanel.Visible and currentItemData then
		SelectDetailedItem(currentItemData) 
	end
end)

PopulateUI()
RefreshGrid()
