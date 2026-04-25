local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local roomRequest = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes"):WaitForChild("GuildRoomRequest")

-- =========================================================
-- 🎨 INTERFAZ DE GESTIÓN (Holográfica)
-- =========================================================
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_GuildManageUI"
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 300, 0, 400)
mainPanel.Position = UDim2.new(0.5, -150, 0.5, -200)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainPanel.BackgroundTransparency = 0.1
mainPanel.Visible = false
mainPanel.Parent = screenGui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 15)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "GESTIÓN DE SEDE"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.Parent = mainPanel

-- Lista de botones de salas disponibles
local rooms = {"Blacksmith", "WarRoom", "Treasury"}
local currentSlotSelected = 1 -- Por ahora lo dejamos fijo o lo pasas al abrir el menú

for i, rName in ipairs(rooms) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 50)
	btn.Position = UDim2.new(0.05, 0, 0, 60 + (i-1)*60)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	btn.Text = "Instalar " .. rName
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.Parent = mainPanel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		local success, msg = roomRequest:InvokeServer("UpdateRoom", currentSlotSelected, rName)
		if success then
			print(msg)
			mainPanel.Visible = false
		end
	end)
end

-- =========================================================
-- 🖱️ ABRIR EL MENÚ (Usando el ProximityPrompt del Slot)
-- =========================================================
task.spawn(function()
	while task.wait(1) do
		for _, s in ipairs(workspace:GetDescendants()) do
			if s.Name == "RoomSlot" and not s:FindFirstChild("ManagePrompt") then
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "ManagePrompt"
				prompt.ActionText = "Gestionar Sala"
				prompt.ObjectText = "Slot #" .. (s:FindFirstChild("SlotID") and s.SlotID.Value or "?")
				prompt.Parent = s

				prompt.Triggered:Connect(function()
					currentSlotSelected = s.SlotID.Value
					mainPanel.Visible = true
				end)
			end
		end
	end
end)
