local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer

ReplicatedStorage.Remotes.LootObtained.OnClientEvent:Connect(function(itemName, amount)
	local lootFrame = Instance.new("Frame")
	lootFrame.Size = UDim2.new(0, 200, 0, 50)
	lootFrame.Position = UDim2.new(0.5, -100, 0.7, 0) -- Aparece en el centro bajo
	lootFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lootFrame.BackgroundTransparency = 0.5
	lootFrame.Parent = player.PlayerGui:WaitForChild("ScreenGui")

	local text = Instance.new("TextLabel", lootFrame)
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Text = "ITEM OBTENIDO: " .. itemName .. " x" .. amount
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.BackgroundTransparency = 1

	-- Animación: Sube y se desvanece (Estilo SAO)
	lootFrame:TweenPosition(UDim2.new(0.5, -100, 0.4, 0), "Out", "Quart", 1.5)
	task.wait(1)
	TweenService:Create(lootFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

	task.wait(0.5)
	lootFrame:Destroy()
end)


