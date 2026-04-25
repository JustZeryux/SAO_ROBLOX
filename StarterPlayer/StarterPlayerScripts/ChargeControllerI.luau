local Tool = script.Parent
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local event = Tool:WaitForChild("DispararPua")

-- ==========================================
-- ⚙️ CONFIGURACIÓN DE CARGA
-- ==========================================
local isCharging = false
local chargeTime = 0
local chargeLevel = 0
local MAX_LEVEL = 3
local TIME_PER_LEVEL = 1.2 -- Lo bajé un poco para que sea más dinámico

local BASE_POWER = 60
local POWER_PER_LEVEL = 50

-- Colores por nivel (Estilo SAO Sword Skills)
local LevelColors = {
	[0] = Color3.fromRGB(0, 255, 255),   -- Cian (Inicio)
	[1] = Color3.fromRGB(0, 100, 255),   -- Azul
	[2] = Color3.fromRGB(170, 0, 255),   -- Morado
	[3] = Color3.fromRGB(255, 30, 30)    -- Rojo (Máximo)
}

-- ==========================================
-- 🎨 UI "SAO TILTED BAR" MEJORADA
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "SAO_ThrowGUI"
gui.ResetOnSpawn = false

local container = Instance.new("CanvasGroup", gui)
container.Size = UDim2.new(0, 45, 0, 220)
container.Position = UDim2.new(1, -120, 1, -280)
container.BackgroundTransparency = 1
container.Rotation = -15
container.Visible = false

local bgBar = Instance.new("Frame", container)
bgBar.Size = UDim2.new(1, 0, 1, 0)
bgBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
bgBar.BackgroundTransparency = 0.4
Instance.new("UICorner", bgBar).CornerRadius = UDim.new(0.5, 0)

-- Borde brillante
local bgStroke = Instance.new("UIStroke", bgBar)
bgStroke.Color = Color3.fromRGB(150, 150, 160)
bgStroke.Thickness = 1.5

local fill = Instance.new("Frame", bgBar)
fill.Size = UDim2.new(1, 0, 0, 0)
fill.Position = UDim2.new(0, 0, 1, 0)
fill.AnchorPoint = Vector2.new(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0)

-- Gradiente para que la barra parezca energía líquida
local fillGradient = Instance.new("UIGradient", fill)
fillGradient.Rotation = 90
fillGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, LevelColors[0])
})

local txt = Instance.new("TextLabel", container)
txt.Size = UDim2.new(2, 0, 0, 30)
txt.Position = UDim2.new(-0.5, 0, 1, 5)
txt.BackgroundTransparency = 1
txt.Text = "CHARGE"
txt.TextColor3 = Color3.new(1,1,1)
txt.Font = Enum.Font.GothamBlack
txt.TextSize = 16
txt.Rotation = 15 -- Enderezamos el texto

local txtStroke = Instance.new("UIStroke", txt)
txtStroke.Color = Color3.fromRGB(0, 0, 0)
txtStroke.Thickness = 2

-- ==========================================
-- ✨ SISTEMA DE VFX (Partículas y Luz)
-- ==========================================
local currentAura = nil
local currentLight = nil

local function CreateChargeVFX(handle)
	-- Borramos anteriores si existen
	if currentAura then currentAura:Destroy() end
	if currentLight then currentLight:Destroy() end

	local attachment = Instance.new("Attachment", handle)

	-- Luz dinámica que ilumina al personaje
	currentLight = Instance.new("PointLight", handle)
	currentLight.Brightness = 2
	currentLight.Range = 6
	currentLight.Color = LevelColors[0]
	currentLight.Shadows = true

	-- Partículas de energía acumulándose
	currentAura = Instance.new("ParticleEmitter", attachment)
	currentAura.Texture = "rbxassetid://7148566336" -- Textura de chispa
	currentAura.Color = ColorSequence.new(LevelColors[0])
	currentAura.LightEmission = 1
	currentAura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	currentAura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(1, 1)})
	currentAura.Lifetime = NumberRange.new(0.4, 0.8)
	currentAura.Speed = NumberRange.new(2, 5)
	currentAura.EmissionDirection = Enum.NormalId.Top
	currentAura.SpreadAngle = Vector2.new(45, 45)
	currentAura.Rate = 20 -- Sube con los niveles
end

local function UpgradeVFX()
	local handle = Tool:FindFirstChild("Handle")
	if not handle then return end

	local color = LevelColors[chargeLevel] or LevelColors[MAX_LEVEL]

	-- Efecto de sonido al subir de nivel
	local bling = Instance.new("Sound", handle)
	bling.SoundId = "rbxassetid://6895079853"
	bling.Pitch = 0.8 + (chargeLevel * 0.2)
	bling.Volume = 1
	bling:Play()
	game.Debris:AddItem(bling, 1)

	-- Actualizar UI
	fillGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1, color) })
	bgStroke.Color = color
	txt.TextColor3 = color

	-- Animar Texto (Pop)
	txt.UIScale = Instance.new("UIScale", txt)
	txt.UIScale.Scale = 1.5
	TweenService:Create(txt.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

	-- Actualizar VFX de Arma
	if currentAura and currentLight then
		TweenService:Create(currentLight, TweenInfo.new(0.2), {Color = color, Range = 6 + (chargeLevel * 2)}):Play()
		currentAura.Color = ColorSequence.new(color)
		currentAura.Rate = 20 + (chargeLevel * 30) -- Más partículas entre más carga
		currentAura.Speed = NumberRange.new(2 + chargeLevel, 5 + chargeLevel)
	end
end

local function CleanupVFX()
	if currentAura then currentAura.Rate = 0; game.Debris:AddItem(currentAura.Parent, 1); currentAura = nil end
	if currentLight then TweenService:Create(currentLight, TweenInfo.new(0.2), {Brightness = 0}); game.Debris:AddItem(currentLight, 0.2); currentLight = nil end
	Camera:SetAttribute("TargetFOV", 95) -- Restauramos el FOV usando el script que hicimos antes
end

-- ==========================================
-- ⚙️ LÓGICA DE CARGA
-- ==========================================
local chargeConn

local function StartCharge()
	if isCharging then return end
	isCharging = true
	chargeTime = 0
	chargeLevel = 0

	local handle = Tool:FindFirstChild("Handle")
	if handle then CreateChargeVFX(handle) end

	gui.Parent = player.PlayerGui
	container.GroupTransparency = 1
	container.Visible = true
	fill.Size = UDim2.new(1, 0, 0, 0)
	UpgradeVFX() -- Set inicial

	TweenService:Create(container, TweenInfo.new(0.3), {GroupTransparency = 0}):Play()

	chargeConn = RunService.RenderStepped:Connect(function(dt)
		chargeTime += dt
		local newLevel = math.floor(chargeTime / TIME_PER_LEVEL)

		if newLevel > chargeLevel and newLevel <= MAX_LEVEL then
			chargeLevel = newLevel
			UpgradeVFX()

			if chargeLevel == MAX_LEVEL then
				txt.Text = "MAX"
				-- Efecto de temblor en el texto
				txt.Position = UDim2.new(-0.5, math.random(-2,2), 1, 5 + math.random(-2,2))
			end
		end

		local progress = math.clamp(chargeTime / (MAX_LEVEL * TIME_PER_LEVEL), 0, 1)
		fill.Size = fill.Size:Lerp(UDim2.new(1, 0, progress, 0), 0.3)

		-- 🎥 INTEGRACIÓN DE FOV: Se aleja la cámara mientras cargas (Super épico)
		Camera:SetAttribute("TargetFOV", 95 + (progress * 15))
	end)
end

local function Release()
	if not isCharging then return end
	isCharging = false
	if chargeConn then chargeConn:Disconnect() end

	TweenService:Create(container, TweenInfo.new(0.2), {GroupTransparency = 1}):Play()
	task.delay(0.2, function() container.Visible = false end)
	CleanupVFX()

	local finalPower = BASE_POWER + (chargeLevel * POWER_PER_LEVEL)
	local skillID = player:GetAttribute("EquippedSkill") or ""

	event:FireServer(mouse.Hit.Position, finalPower, skillID)
end

-- ==========================================
-- 🎮 CONTROLES
-- ==========================================
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Q and Tool.Parent == player.Character then
		StartCharge()
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Q and isCharging then
		Release()
	end
end)

Tool.Unequipped:Connect(function()
	isCharging = false
	if chargeConn then chargeConn:Disconnect() end
	container.Visible = false
	CleanupVFX()
end)
