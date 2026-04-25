-- ============================================================
-- ⚔️ SAO AVATAR CREATOR  •  VERSIÓN ÉPICA (LINK START)
-- ============================================================

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera
local mouse   = player:GetMouse()

-- ==========================================
-- 📡 EVENTOS
-- ==========================================
local SAO_Events      = ReplicatedStorage:WaitForChild("SAO_Events")
local OpenAvatarEvent = SAO_Events:WaitForChild("OpenAvatarCreator")
local OpenClassEvent  = SAO_Events:WaitForChild("OpenClassMenu")

-- ==========================================
-- 🔊 SONIDOS Y ASSETS
-- ==========================================
local sfxOpen  = Instance.new("Sound", workspace); sfxOpen.SoundId = "rbxassetid://8503522619"; sfxOpen.Volume = 0.8
local sfxClick = Instance.new("Sound", workspace); sfxClick.SoundId = "rbxassetid://6895079853"; sfxClick.Volume = 0.5
local sfxEquip = Instance.new("Sound", workspace); sfxEquip.SoundId = "rbxassetid://6895056262"; sfxEquip.Volume = 0.8; sfxEquip.Pitch = 1.2

local AvatarAssets = {
	Cara = {
		["Decidido (Anime)"]  = "rbxassetid://7074749",
		["Serio"]             = "rbxassetid://8560971",
		["Sonrisa Confiada"]  = "rbxassetid://12145366",
		["Misterioso"]        = "rbxassetid://634032049",
	},
	Camisa = {
		["Espadachín Negro"] = "rbxassetid://1063618683",
		["Caballero Sangre"] = "rbxassetid://237446698",
		["Traje Novato"]     = "rbxassetid://308805725",
		["Supervivencia"]    = "rbxassetid://5590924190",
	},
	Pantalon = {
		["Espadachín Negro"] = "rbxassetid://1063622432",
		["Caballero Sangre"] = "rbxassetid://237448375",
		["Pantalón Novato"]  = "rbxassetid://308805971",
		["Botas Combate"]    = "rbxassetid://5590926830",
	},
}

-- ==========================================
-- 🌌 CREADOR DEL CUARTO DIGITAL 3D
-- ==========================================
local avatarRoom = nil
local charClone  = nil
local hrpClone   = nil
local renderConn = nil

local function BuildDigitalRoom()
	local room = Instance.new("Model", workspace)
	room.Name = "SAO_DigitalRoom"

	local centerPos = Vector3.new(0, 10000, 0) -- Lejos del mapa real

	-- Plataforma de cristal
	local pad = Instance.new("Part", room)
	pad.Size = Vector3.new(12, 0.5, 12)
	pad.Position = centerPos - Vector3.new(0, 3, 0)
	pad.Anchored = true
	pad.Material = Enum.Material.Glass
	pad.Color = Color3.fromRGB(0, 20, 40)
	pad.Transparency = 0.5

	-- Anillo Neón brillante
	local ring = Instance.new("Part", room)
	ring.Size = Vector3.new(13, 0.2, 13)
	ring.Position = pad.Position
	ring.Anchored = true
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(0, 200, 255)
	ring.Orientation = Vector3.new(0, 0, 90)

	-- Luces
	local light = Instance.new("PointLight", pad)
	light.Color = Color3.fromRGB(0, 255, 255)
	light.Brightness = 3
	light.Range = 20
	light.Shadows = true

	return room, centerPos
end

-- Efecto de "Glitch de Datos" al cambiar ropa
local function DataEquipEffect()
	if not charClone then return end
	sfxEquip:Play()

	for _, part in ipairs(charClone:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local oldMat = part.Material
			local oldCol = part.Color
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(0, 255, 255)

			TweenService:Create(part, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = oldCol}):Play()
			task.delay(0.3, function() part.Material = oldMat end)
		end
	end
end

-- ==========================================
-- 🪞 INICIAR EL CREADOR DE AVATAR
-- ==========================================
local function abrirCreadorAvatar()
	if player.PlayerGui:FindFirstChild("SAO_AvatarCreator_GUI") then return end

	sfxOpen:Play()

	-- 1. PREPARAR ESCENARIO
	local room, centerPos = BuildDigitalRoom()
	avatarRoom = room

	-- 2. CLONAR PERSONAJE
	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart")

	character.Archivable = true
	charClone = character:Clone()
	charClone.Parent = avatarRoom
	character.Archivable = false

	hrpClone = charClone:WaitForChild("HumanoidRootPart")
	hrpClone.CFrame = CFrame.new(centerPos)

	for _, part in ipairs(charClone:GetDescendants()) do
		if part:IsA("BasePart") then part.Anchored = true end
	end

	-- 3. CÁMARA ÉPICA (Parallax Effect)
	camera.CameraType = Enum.CameraType.Scriptable
	local baseCamCFrame = CFrame.new(centerPos + Vector3.new(0, 1, -10), centerPos + Vector3.new(0, 0.5, 0))
	camera.CFrame = baseCamCFrame

	local blur = Instance.new("BlurEffect", Lighting)
	blur.Size = 0
	TweenService:Create(blur, TweenInfo.new(1), {Size = 15}):Play()

	-- Movimiento sutil del ratón
	renderConn = RunService.RenderStepped:Connect(function()
		local mousePos = UserInputService:GetMouseLocation()
		local screenH = camera.ViewportSize.Y
		local screenW = camera.ViewportSize.X

		local offsetX = ((mousePos.X / screenW) - 0.5) * 2 -- Rango de -1 a 1
		local offsetY = ((mousePos.Y / screenH) - 0.5) * -1

		local targetCFrame = baseCamCFrame * CFrame.new(offsetX * 1.5, offsetY * 1.5, 0)
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.05)
	end)

	-- 4. CONSTRUIR UI ESTILO SAO (Glassmorphism)
	local gui = Instance.new("ScreenGui", player.PlayerGui)
	gui.Name = "SAO_AvatarCreator_GUI"
	gui.IgnoreGuiInset = true

	-- Panel Transparente para rotar (Arrastrar para girar)
	local dragArea = Instance.new("TextButton", gui)
	dragArea.Size = UDim2.new(1, 0, 1, 0)
	dragArea.BackgroundTransparency = 1
	dragArea.Text = ""

	local isDragging = false
	local lastMouseX = 0

	dragArea.MouseButton1Down:Connect(function()
		isDragging = true
		lastMouseX = mouse.X
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
	end)
	dragArea.MouseMoved:Connect(function(x, y)
		if isDragging and hrpClone then
			local delta = x - lastMouseX
			hrpClone.CFrame = hrpClone.CFrame * CFrame.Angles(0, math.rad(delta * 0.5), 0)
			lastMouseX = x
		end
	end)

	-- Panel Derecho (Opciones)
	local rightPanel = Instance.new("Frame", gui)
	rightPanel.Size = UDim2.new(0, 350, 1, -100)
	rightPanel.Position = UDim2.new(1, 100, 0, 50) -- Empieza fuera de la pantalla
	rightPanel.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
	rightPanel.BackgroundTransparency = 0.2
	rightPanel.BorderSizePixel = 0
	Instance.new("UICorner", rightPanel).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", rightPanel); stroke.Color = Color3.fromRGB(0, 200, 255); stroke.Thickness = 1.5

	-- Titulo
	local title = Instance.new("TextLabel", rightPanel)
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundTransparency = 1
	title.Text = "SYSTEM // AVATAR"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 24

	local uiList = Instance.new("UIListLayout", rightPanel)
	uiList.Padding = UDim.new(0, 15)
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- Truco para que el título respete el padding
	local padding = Instance.new("UIPadding", rightPanel)
	padding.PaddingTop = UDim.new(0, 20)

	-- Creador de Categorías
	local function CreateCategory(name, items, assetType)
		local cat = Instance.new("Frame", rightPanel)
		cat.Size = UDim2.new(0.9, 0, 0, 80)
		cat.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
		cat.BackgroundTransparency = 0.5
		Instance.new("UICorner", cat).CornerRadius = UDim.new(0, 8)

		local lbl = Instance.new("TextLabel", cat)
		lbl.Size = UDim2.new(1, -15, 0, 25)
		lbl.Position = UDim2.new(0, 15, 0, 5)
		lbl.BackgroundTransparency = 1
		lbl.Text = name
		lbl.TextColor3 = Color3.fromRGB(0, 200, 255)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		local scroll = Instance.new("ScrollingFrame", cat)
		scroll.Size = UDim2.new(1, -20, 0, 40)
		scroll.Position = UDim2.new(0, 10, 0, 30)
		scroll.BackgroundTransparency = 1
		scroll.ScrollingDirection = Enum.ScrollingDirection.X
		scroll.ScrollBarThickness = 0

		local hLayout = Instance.new("UIListLayout", scroll)
		hLayout.FillDirection = Enum.FillDirection.Horizontal
		hLayout.Padding = UDim.new(0, 10)

		for _, itemName in ipairs(items) do
			local btn = Instance.new("TextButton", scroll)
			btn.Size = UDim2.new(0, 120, 1, 0)
			btn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
			btn.Text = itemName
			btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			btn.Font = Enum.Font.GothamMedium
			btn.TextSize = 12
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

			btn.MouseButton1Click:Connect(function()
				sfxClick:Play()
				DataEquipEffect()

				-- Aplicar Ropa
				local id = AvatarAssets[assetType][itemName]
				if assetType == "Cara" then
					local face = charClone.Head:FindFirstChildOfClass("Decal") or Instance.new("Decal", charClone.Head)
					face.Name = "face"; face.Texture = id
				elseif assetType == "Camisa" then
					local shirt = charClone:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", charClone)
					shirt.Name = "Shirt"; shirt.ShirtTemplate = id
				elseif assetType == "Pantalon" then
					local pants = charClone:FindFirstChildOfClass("Pants") or Instance.new("Pants", charClone)
					pants.Name = "Pants"; pants.PantsTemplate = id
				end
			end)
		end
		scroll.CanvasSize = UDim2.new(0, #items * 130, 0, 0)
	end

	CreateCategory("EXPRESIÓN FACIAL", {"Decidido (Anime)", "Serio", "Sonrisa Confiada", "Misterioso"}, "Cara")
	CreateCategory("ATUENDO - CAMISA", {"Traje Novato", "Espadachín Negro", "Caballero Sangre", "Supervivencia"}, "Camisa")
	CreateCategory("ATUENDO - PANTALÓN", {"Pantalón Novato", "Espadachín Negro", "Caballero Sangre", "Botas Combate"}, "Pantalon")

	-- Botón LINK START
	local confirmBtn = Instance.new("TextButton", rightPanel)
	confirmBtn.Size = UDim2.new(0.8, 0, 0, 50)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	confirmBtn.Text = "LINK START"
	confirmBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	confirmBtn.Font = Enum.Font.GothamBlack
	confirmBtn.TextSize = 20
	Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 8)

	confirmBtn.MouseButton1Click:Connect(function()
		sfxClick:Play()
		-- Animación de Cierre
		TweenService:Create(rightPanel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 100, 0, 50)}):Play()
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()

		task.wait(0.5)

		if renderConn then renderConn:Disconnect() end
		camera.CameraType = Enum.CameraType.Custom
		avatarRoom:Destroy()
		blur:Destroy()
		gui:Destroy()

		OpenClassEvent:Fire()
	end)

	-- Animación de Entrada UI
	TweenService:Create(rightPanel, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -380, 0, 50)}):Play()
end

OpenAvatarEvent.Event:Connect(abrirCreadorAvatar)
