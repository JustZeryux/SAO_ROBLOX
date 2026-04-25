local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local bountyRequest = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes"):WaitForChild("BountyRequest")
local boardModel = workspace:WaitForChild("BountyBoard")
local prompt = boardModel:WaitForChild("BoardPrompt")

-- =========================================================
-- 🎨 1. GENERACIÓN DE INTERFAZ DEL TABLERO
-- =========================================================
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_BountyBoardUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 500, 0, 400)
mainPanel.Position = UDim2.new(0.5, -250, 0.5, -200)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainPanel.BackgroundTransparency = 0.1
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", mainPanel).Color = Color3.fromRGB(255, 50, 50) -- Borde rojo sangre

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "WANTED PLAYERS"
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.Parent = mainPanel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainPanel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.5, 0)

local listContainer = Instance.new("ScrollingFrame")
listContainer.Size = UDim2.new(1, -20, 1, -60)
listContainer.Position = UDim2.new(0, 10, 0, 50)
listContainer.BackgroundTransparency = 1
listContainer.ScrollBarThickness = 4
listContainer.Parent = mainPanel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = listContainer

-- =========================================================
-- 🧭 2. MATEMÁTICAS DE NAVEGACIÓN (GPS)
-- =========================================================
local function GetCompassDirection(myPos, targetPos)
	local dir = (targetPos - myPos).Unit
	local angle = math.atan2(dir.X, dir.Z)
	local deg = math.deg(angle)

	if deg >= -45 and deg <= 45 then return "Sur"
	elseif deg > 45 and deg < 135 then return "Este"
	elseif deg >= 135 or deg <= -135 then return "Norte"
	else return "Oeste"
	end
end

-- =========================================================
-- 🚀 3. LÓGICA DE ACTUALIZACIÓN
-- =========================================================
local updateConnection = nil

local function OpenBoard()
	mainPanel.Visible = true
	mainPanel.Size = UDim2.new(0, 480, 0, 380)
	TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 400)}):Play()

	-- Ciclo de actualización en tiempo real mientras el tablero esté abierto
	updateConnection = RunService.Heartbeat:Connect(function()
		-- No pedimos datos al servidor cada frame (daría lag), pero sí actualizamos 
		-- la brújula visualmente basándonos en los datos del último segundo.
	end)

	-- Bucle para actualizar la base de datos del tablero cada 1 segundo
	task.spawn(function()
		while mainPanel.Visible do
			local bountyData = bountyRequest:InvokeServer()

			-- Limpiar lista
			for _, child in ipairs(listContainer:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end

			-- Población dinámica
			if #bountyData == 0 then
				local emptyLbl = Instance.new("TextLabel")
				emptyLbl.Size = UDim2.new(1, 0, 0, 50)
				emptyLbl.BackgroundTransparency = 1
				emptyLbl.Text = "La ciudad está en paz. No hay criminales."
				emptyLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
				emptyLbl.Font = Enum.Font.Gotham
				emptyLbl.Parent = listContainer
			else
				local myPos = player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position

				for _, criminal in ipairs(bountyData) do
					local card = Instance.new("Frame")
					card.Size = UDim2.new(1, -10, 0, 60)
					card.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
					card.Parent = listContainer
					Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

					local nameLbl = Instance.new("TextLabel")
					nameLbl.Size = UDim2.new(0.5, 0, 0.5, 0)
					nameLbl.Position = UDim2.new(0, 10, 0, 5)
					nameLbl.BackgroundTransparency = 1
					nameLbl.Text = criminal.Name
					nameLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
					nameLbl.Font = Enum.Font.GothamBold
					nameLbl.TextXAlignment = Enum.TextXAlignment.Left
					nameLbl.Parent = card

					local bountyLbl = Instance.new("TextLabel")
					bountyLbl.Size = UDim2.new(0.5, 0, 0.5, 0)
					bountyLbl.Position = UDim2.new(0, 10, 0.5, 0)
					bountyLbl.BackgroundTransparency = 1
					bountyLbl.Text = criminal.Bounty .. " Col"
					bountyLbl.TextColor3 = Color3.fromRGB(255, 200, 0) -- Dorado
					bountyLbl.Font = Enum.Font.GothamSemibold
					bountyLbl.TextXAlignment = Enum.TextXAlignment.Left
					bountyLbl.Parent = card

					-- Tracker GPS
					local gpsLbl = Instance.new("TextLabel")
					gpsLbl.Size = UDim2.new(0.5, -10, 1, 0)
					gpsLbl.Position = UDim2.new(0.5, 0, 0, 0)
					gpsLbl.BackgroundTransparency = 1

					if myPos and criminal.RootPart then
						local distance = math.floor((criminal.RootPart.Position - myPos).Magnitude)
						local direction = GetCompassDirection(myPos, criminal.RootPart.Position)
						gpsLbl.Text = distance .. " studs al " .. direction
					else
						gpsLbl.Text = "Ubicación desconocida"
					end

					gpsLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
					gpsLbl.Font = Enum.Font.Gotham
					gpsLbl.TextXAlignment = Enum.TextXAlignment.Right
					gpsLbl.Parent = card
				end
			end

			task.wait(1.5) -- Refresca los datos cada 1.5s
		end
	end)
end

prompt.Triggered:Connect(function()
	if not mainPanel.Visible then OpenBoard() end
end)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	if updateConnection then updateConnection:Disconnect() end
end)
