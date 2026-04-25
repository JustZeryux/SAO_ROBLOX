local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local interiorFade = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes"):WaitForChild("InteriorFade")

-- Crear la pantalla negra
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAO_SeamlessTransition"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100 -- Para que cubra toda la UI
screenGui.Parent = playerGui

local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackFrame.BackgroundTransparency = 1 -- Empieza invisible
blackFrame.Visible = false
blackFrame.Parent = screenGui

local currentTween = nil

interiorFade.OnClientEvent:Connect(function(action)
	if currentTween then currentTween:Cancel() end

	if action == "FadeOut" then
		blackFrame.Visible = true
		-- Transición súper rápida (0.2s) para no aburrir al jugador
		currentTween = TweenService:Create(blackFrame, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {BackgroundTransparency = 0})
		currentTween:Play()

	elseif action == "FadeIn" then
		-- Devuelve la visión al jugador
		currentTween = TweenService:Create(blackFrame, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
		currentTween:Play()

		currentTween.Completed:Connect(function()
			blackFrame.Visible = false
		end)
	end
end)
