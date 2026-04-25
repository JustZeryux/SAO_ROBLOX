local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local partyRequest = Remotes:WaitForChild("PartyRequest")
local partyInviteEvent = Remotes:WaitForChild("PartyInviteEvent")

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_PartyUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- =========================================================
-- 👥 1. LISTA DE MIEMBROS (Esquina Superior Izquierda)
-- =========================================================
local partyContainer = Instance.new("Frame")
partyContainer.Size = UDim2.new(0, 250, 0.5, 0)
partyContainer.Position = UDim2.new(0, 20, 0, 20)
partyContainer.BackgroundTransparency = 1
partyContainer.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = partyContainer

local function UpdatePartyList(membersList)
	-- Limpiar UI anterior
	for _, child in ipairs(partyContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, memberName in ipairs(membersList) do
		-- No nos mostramos a nosotros mismos en la lista lateral
		if memberName ~= player.Name then
			local memberCard = Instance.new("Frame")
			memberCard.Size = UDim2.new(1, 0, 0, 40)
			memberCard.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			memberCard.BackgroundTransparency = 0.2
			memberCard.Parent = partyContainer
			Instance.new("UICorner", memberCard).CornerRadius = UDim.new(0, 8)

			local nameText = Instance.new("TextLabel")
			nameText.Size = UDim2.new(1, -10, 0, 20)
			nameText.Position = UDim2.new(0, 10, 0, 0)
			nameText.BackgroundTransparency = 1
			nameText.Text = memberName
			nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameText.Font = Enum.Font.GothamBold
			nameText.TextXAlignment = Enum.TextXAlignment.Left
			nameText.Parent = memberCard

			-- Barra de Vida (Verde SAO)
			local hpBg = Instance.new("Frame")
			hpBg.Size = UDim2.new(1, -20, 0, 5)
			hpBg.Position = UDim2.new(0, 10, 1, -10)
			hpBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			hpBg.Parent = memberCard

			local hpFill = Instance.new("Frame")
			hpFill.Size = UDim2.new(1, 0, 1, 0)
			hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
			hpFill.Parent = hpBg

			-- Lógica para ver su vida real
			local memberPlayer = Players:FindFirstChild(memberName)
			if memberPlayer then
				local function updateHP()
					if memberPlayer.Character and memberPlayer.Character:FindFirstChild("Humanoid") then
						local hum = memberPlayer.Character.Humanoid
						local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
						TweenService:Create(hpFill, TweenInfo.new(0.3), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
					end
				end
				-- Un bucle ligero para actualizar la vida visualmente
				task.spawn(function()
					while memberCard.Parent do
						updateHP()
						task.wait(0.5)
					end
				end)
			end
		end
	end
end

-- =========================================================
-- 💌 2. POPUP DE INVITACIÓN
-- =========================================================
local invitePanel = Instance.new("Frame")
invitePanel.Size = UDim2.new(0, 280, 0, 120)
invitePanel.Position = UDim2.new(0.5, -140, 0.2, -60)
invitePanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
invitePanel.Visible = false
invitePanel.Parent = screenGui
Instance.new("UICorner", invitePanel).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", invitePanel).Color = Color3.fromRGB(0, 255, 100) -- Borde Verde Party

local inviteText = Instance.new("TextLabel")
inviteText.Size = UDim2.new(1, -20, 0, 50)
inviteText.Position = UDim2.new(0, 10, 0, 10)
inviteText.BackgroundTransparency = 1
inviteText.Text = ""
inviteText.TextColor3 = Color3.fromRGB(255, 255, 255)
inviteText.Font = Enum.Font.GothamSemibold
inviteText.TextWrapped = true
inviteText.Parent = invitePanel

local acceptBtn = Instance.new("TextButton")
acceptBtn.Size = UDim2.new(0.4, 0, 0, 35)
acceptBtn.Position = UDim2.new(0.05, 0, 1, -45)
acceptBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
acceptBtn.Text = "UNIRSE"
acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
acceptBtn.Font = Enum.Font.GothamBold
acceptBtn.Parent = invitePanel
Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 8)

local declineBtn = Instance.new("TextButton")
declineBtn.Size = UDim2.new(0.4, 0, 0, 35)
declineBtn.Position = UDim2.new(0.55, 0, 1, -45)
declineBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
declineBtn.Text = "RECHAZAR"
declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
declineBtn.Font = Enum.Font.GothamBold
declineBtn.Parent = invitePanel
Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 8)

partyInviteEvent.OnClientEvent:Connect(function(actionOrLeader, membersList)
	if actionOrLeader == "UpdateUI" then
		UpdatePartyList(membersList)
	else
		-- Es una invitación
		inviteText.Text = actionOrLeader .. " te invita a su Grupo."
		invitePanel.Visible = true
		invitePanel.Size = UDim2.new(0, 260, 0, 100)
		TweenService:Create(invitePanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 120)}):Play()
	end
end)

acceptBtn.MouseButton1Click:Connect(function()
	invitePanel.Visible = false
	partyRequest:InvokeServer("Accept")
end)

declineBtn.MouseButton1Click:Connect(function()
	invitePanel.Visible = false
end)
