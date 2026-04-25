local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "BossRaidUI"

-- Contenedor principal
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 600, 0, 40)
mainFrame.Position = UDim2.new(0.5, -300, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.3
mainFrame.Visible = false
Instance.new("UICorner", mainFrame)

-- Capas de Colores (SAO Style)
local colors = {
	Color3.fromRGB(255, 50, 50),   -- Roja (Última)
	Color3.fromRGB(255, 200, 0),  -- Amarilla
	Color3.fromRGB(0, 255, 100),  -- Verde
	Color3.fromRGB(0, 150, 255)   -- Azul (Primera)
}

local bars = {}
for i = 1, #colors do
	local bar = Instance.new("Frame", mainFrame)
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3 = colors[i]
	bar.BorderSizePixel = 0
	bar.ZIndex = i + 1
	Instance.new("UICorner", bar)
	bars[i] = bar
end

local bossName = Instance.new("TextLabel", mainFrame)
bossName.Size = UDim2.new(1, 0, 0, 30)
bossName.Position = UDim2.new(0, 0, -1, 0)
bossName.Text = "ILFANG THE KOBOLD LORD"
bossName.TextColor3 = Color3.fromRGB(255, 255, 255)
bossName.Font = Enum.Font.GothamBlack
bossName.TextSize = 24
bossName.BackgroundTransparency = 1

-- Lógica para actualizar las barras
_G.UpdateBossHP = function(currentHP, maxHP)
	mainFrame.Visible = true
	local totalPercent = currentHP / maxHP
	local numBars = #colors
	local percentPerBar = 1 / numBars

	for i = numBars, 1, -1 do
		local barMin = (i - 1) * percentPerBar
		local barMax = i * percentPerBar
		local barPercent = math.clamp((totalPercent - barMin) / percentPerBar, 0, 1)

		TweenService:Create(bars[i], TweenInfo.new(0.3), {Size = UDim2.new(barPercent, 0, 1, 0)}):Play()
	end

	if currentHP <= 0 then 
		task.wait(2)
		mainFrame.Visible = false 
	end
end
