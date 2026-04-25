local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService") 
local GuiService = game:GetService("GuiService") 
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting") 
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local BuySkillEvent = SAO_Events:WaitForChild("BuySkill")
local EquipOffhandEvent = SAO_Events:WaitForChild("EquipOffhand")
local UnequipOffhandEvent = SAO_Events:WaitForChild("UnequipOffhand")
local UpgradeStatEvent = SAO_Events:WaitForChild("UpgradeStat")
local ConsumeItemEvent = SAO_Events:WaitForChild("ConsumeItem")
local QuestEvent = SAO_Events:WaitForChild("QuestEvent")
local SocialEvent = SAO_Events:WaitForChild("SocialEvent")

local EquipItemEvent = SAO_Events:FindFirstChild("EquipItem") or Instance.new("RemoteEvent", SAO_Events)
EquipItemEvent.Name = "EquipItem"
local UnequipItemEvent = SAO_Events:FindFirstChild("UnequipItem") or Instance.new("RemoteEvent", SAO_Events)
UnequipItemEvent.Name = "UnequipItem"

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)

local sfxOpen = Instance.new("Sound", workspace); sfxOpen.SoundId = "rbxassetid://8503522619"; sfxOpen.Volume = 0.8
local sfxClick = Instance.new("Sound", workspace); sfxClick.SoundId = "rbxassetid://6895079853"; sfxClick.Volume = 0.5
local sfxUpgrade = Instance.new("Sound", workspace); sfxUpgrade.SoundId = "rbxassetid://6895079853"; sfxUpgrade.Volume = 0.9; sfxUpgrade.Pitch = 1.2
local sfxHeal = Instance.new("Sound", workspace); sfxHeal.SoundId = "rbxassetid://8141443690"; sfxHeal.Volume = 1
local sfxQuest = Instance.new("Sound", workspace); sfxQuest.SoundId = "rbxassetid://6114983058"; sfxQuest.Volume = 1

-- =========================================================
-- ✨ SISTEMA DE EFECTOS VISUALES ("JUICE")
-- =========================================================
local saoBlur = Lighting:FindFirstChild("SAO_Blur") or Instance.new("DepthOfFieldEffect", Lighting)
saoBlur.Name = "SAO_Blur"; saoBlur.FocusDistance = 0.5; saoBlur.InFocusRadius = 10; saoBlur.NearIntensity = 0; saoBlur.FarIntensity = 0

local function AplicaJuice(boton)
	if not boton:IsA("GuiButton") and not boton:IsA("GuiObject") then return end
	local scale = boton:FindFirstChild("JuicyScale") or Instance.new("UIScale", boton)
	scale.Name = "JuicyScale"

	boton.MouseEnter:Connect(function() TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.05}):Play() end)
	boton.MouseLeave:Connect(function() TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play() end)
	if boton:IsA("GuiButton") then
		boton.MouseButton1Down:Connect(function() TweenService:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.95}):Play() end)
		boton.MouseButton1Up:Connect(function() TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.05}):Play() end)
	end
end

-- =========================================================
-- SECUENCIA DE INICIO: SAO "FULL DIVE"
-- =========================================================
local Debris = game:GetService("Debris") 
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "SAO_FullDive_Screen"; loadingGui.DisplayOrder = 9999; loadingGui.IgnoreGuiInset = true; loadingGui.Parent = player:WaitForChild("PlayerGui")

local bg = Instance.new("Frame", loadingGui); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.new(0,0,0); bg.BorderSizePixel = 0
local warpContainer = Instance.new("Frame", bg); warpContainer.Size = UDim2.new(1,0,1,0); warpContainer.BackgroundTransparency = 1; warpContainer.ZIndex = 1
local uiContainer = Instance.new("CanvasGroup", bg); uiContainer.Size = UDim2.new(1,0,1,0); uiContainer.BackgroundTransparency = 1; uiContainer.ZIndex = 2; uiContainer.BorderSizePixel = 0

local isWarping = false

local function createWarpEffect(container, duration, isBlue)
	local colors = {Color3.fromRGB(255, 100, 100), Color3.fromRGB(100, 255, 100), Color3.fromRGB(100, 100, 255), Color3.fromRGB(255, 255, 100), Color3.fromRGB(255, 100, 255), Color3.fromRGB(100, 255, 255)}
	if isBlue then colors = {Color3.fromRGB(100, 180, 255), Color3.fromRGB(180, 230, 255), Color3.new(1,1,1)} end
	isWarping = true; local endT = tick() + duration
	task.spawn(function()
		while isWarping and tick() < endT do
			for i = 1, 2 do 
				local pivot = Instance.new("Frame", container); pivot.Size = UDim2.new(0, 0, 0, 0); pivot.Position = UDim2.new(0.5, 0, 0.5, 0); pivot.BackgroundTransparency = 1; pivot.Rotation = math.random(0, 360) 
				local line = Instance.new("Frame", pivot); line.BorderSizePixel = 0; line.BackgroundColor3 = colors[math.random(1, #colors)]; line.AnchorPoint = Vector2.new(0.5, 1); line.Position = UDim2.new(0, 0, 0, -math.random(20, 60)); line.Size = UDim2.new(0, math.random(2, 6), 0, 30)
				local grad = Instance.new("UIGradient", line); grad.Rotation = 90; grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 0)})
				local tw = TweenService:Create(line, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, 0, -1500), Size = UDim2.new(0, 18, 0, 1000)}); tw:Play()
				task.delay(0.35, function() if pivot then pivot:Destroy() end end)
			end
			task.wait(0.02) 
		end
	end)
end

local function typeWriter(lbl, text, speed)
	lbl.Text = ""; for i = 1, #text do lbl.Text = string.sub(text, 1, i); if sfxClick then sfxClick:Play() end; task.wait(speed) end
end

local function createHolographicPanel(parent, size, pos, bgColor, strokeColor)
	local panel = Instance.new("CanvasGroup", parent); panel.Size = size; panel.Position = pos; panel.BackgroundColor3 = bgColor or Color3.fromRGB(30, 30, 35); panel.BackgroundTransparency = 1; panel.GroupTransparency = 1; Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", panel); stroke.Color = strokeColor or Color3.new(1,1,1); stroke.Thickness = 1.5; return panel
end

local skipBtn = Instance.new("TextButton", loadingGui)
skipBtn.Size = UDim2.new(0, 120, 0, 40); skipBtn.Position = UDim2.new(1, -140, 1, -60); skipBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25); skipBtn.BackgroundTransparency = 0.3; skipBtn.Text = "SKIP >>"; skipBtn.Font = Enum.Font.GothamBold; skipBtn.TextColor3 = Color3.fromRGB(200, 200, 200); skipBtn.TextSize = 16; skipBtn.ZIndex = 100; Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 6)
local skipStroke = Instance.new("UIStroke", skipBtn); skipStroke.Color = Color3.fromRGB(150, 150, 150); skipStroke.Thickness = 1
AplicaJuice(skipBtn)

skipBtn.MouseEnter:Connect(function() TweenService:Create(skipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 153, 0), TextColor3 = Color3.new(1,1,1)}):Play(); TweenService:Create(skipStroke, TweenInfo.new(0.2), {Color = Color3.new(1,1,1)}):Play() end)
skipBtn.MouseLeave:Connect(function() TweenService:Create(skipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 25), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play(); TweenService:Create(skipStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(150, 150, 150)}):Play() end)

local introThread 
skipBtn.MouseButton1Click:Connect(function()
	if introThread then task.cancel(introThread) end
	isWarping = false; if sfxClick then sfxClick:Play() end; skipBtn.Visible = false
	TweenService:Create(bg, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	TweenService:Create(uiContainer, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
	task.delay(0.5, function() if loadingGui then loadingGui:Destroy() end end)
end)

introThread = task.spawn(function()
	local linkLbl = Instance.new("TextLabel", uiContainer); linkLbl.Size = UDim2.new(1, 0, 0, 100); linkLbl.Position = UDim2.new(0, 0, 0.45, 0); linkLbl.BackgroundTransparency = 1; linkLbl.Text = "LINK START"; linkLbl.TextColor3 = Color3.fromRGB(0, 255, 255); linkLbl.Font = Enum.Font.GothamBlack; linkLbl.TextSize = 0; linkLbl.TextTransparency = 0; linkLbl.ZIndex = 10
	if sfxOpen then sfxOpen:Play() end; TweenService:Create(linkLbl, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextSize = 85}):Play(); task.wait(1.6); TweenService:Create(linkLbl, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextSize = 300, TextTransparency = 1}):Play(); task.wait(0.4); linkLbl:Destroy()

	bg.BackgroundColor3 = Color3.new(1,1,1); createWarpEffect(warpContainer, 1.8, false); task.wait(1.8); isWarping = false; warpContainer:ClearAllChildren()
	TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(235, 235, 240)}):Play()
	local senses = {"Sight", "Hearing", "Taste", "Touch", "Smell"}; local sensePanels = {}

	for i, sense in ipairs(senses) do
		local panel = Instance.new("Frame", uiContainer); panel.Size = UDim2.new(0, 320, 0, 50); panel.Position = UDim2.new(1.2, 0, 0.2 + (i * 0.11), 0); panel.BackgroundColor3 = Color3.new(1,1,1); panel.BackgroundTransparency = 0.3; Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 4); local stroke = Instance.new("UIStroke", panel); stroke.Color = Color3.fromRGB(160, 160, 170); stroke.Thickness = 1
		local circle = Instance.new("Frame", panel); circle.Size = UDim2.new(0, 28, 0, 28); circle.Position = UDim2.new(0, 10, 0.5, -14); circle.BackgroundTransparency = 1; Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0); local cStroke = Instance.new("UIStroke", circle); cStroke.Color = Color3.fromRGB(160, 160, 170); cStroke.Thickness = 2
		local sTxt = Instance.new("TextLabel", panel); sTxt.Size = UDim2.new(1, -60, 1, 0); sTxt.Position = UDim2.new(0, 50, 0, 0); sTxt.BackgroundTransparency = 1; sTxt.TextXAlignment = Enum.TextXAlignment.Left; sTxt.Text = sense .. " Check"; sTxt.Font = Enum.Font.GothamMedium; sTxt.TextSize = 20; sTxt.TextColor3 = Color3.fromRGB(70, 70, 70)
		local okLbl = Instance.new("TextLabel", panel); okLbl.Size = UDim2.new(0, 60, 1, 0); okLbl.Position = UDim2.new(1, -65, 0, 0); okLbl.BackgroundTransparency = 1; okLbl.Text = "OK"; okLbl.Font = Enum.Font.GothamBold; okLbl.TextSize = 22; okLbl.TextColor3 = Color3.fromRGB(50, 220, 50); okLbl.TextTransparency = 1
		if sfxClick then sfxClick.Pitch = 1.2; sfxClick:Play() end
		TweenService:Create(panel, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0.65, 0, 0.2 + (i * 0.11), 0)}):Play(); table.insert(sensePanels, {f=panel, c=circle, cs=cStroke, o=okLbl}); task.wait(0.12)
	end
	task.wait(0.8)

	for i, ui in ipairs(sensePanels) do
		if sfxUpgrade then sfxUpgrade.Pitch = 1.5; sfxUpgrade:Play() end
		TweenService:Create(ui.c, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 220, 50), BackgroundTransparency = 0}):Play(); TweenService:Create(ui.cs, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 180, 0)}):Play(); TweenService:Create(ui.o, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play(); task.wait(0.08)
	end

	task.wait(1.5); TweenService:Create(uiContainer, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {GroupTransparency = 1}):Play(); task.wait(0.6); uiContainer:ClearAllChildren(); uiContainer.GroupTransparency = 0

	local langPanel = createHolographicPanel(uiContainer, UDim2.new(0, 380, 0, 65), UDim2.new(0.5, -190, 0.42, 0), Color3.fromRGB(25, 25, 30), Color3.fromRGB(100, 100, 110)); langPanel.BackgroundTransparency = 0.3
	TweenService:Create(langPanel, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
	local lTxt = Instance.new("TextLabel", langPanel); lTxt.Size = UDim2.new(1, -20, 1, 0); lTxt.Position = UDim2.new(0, 10, 0, 0); lTxt.BackgroundTransparency = 1; lTxt.TextXAlignment = Enum.TextXAlignment.Left; lTxt.Font = Enum.Font.Code; lTxt.TextSize = 22; lTxt.TextColor3 = Color3.new(1,1,1)
	typeWriter(lTxt, "Language", 0.04); task.wait(0.2); typeWriter(lTxt, "Language             [English]", 0.015); task.wait(1.2)
	TweenService:Create(langPanel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1, Size = UDim2.new(0, 390, 0, 70)}):Play(); task.wait(0.4); langPanel:Destroy()

	local loginPanel = createHolographicPanel(uiContainer, UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(0, 115, 185), Color3.new(1,1,1)); loginPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	TweenService:Create(loginPanel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 380, 0, 180), GroupTransparency = 0, BackgroundTransparency = 0}):Play(); task.wait(0.5)

	local title = Instance.new("TextLabel", loginPanel); title.Size = UDim2.new(1, -20, 0, 30); title.Position = UDim2.new(0, 10, 0, 10); title.BackgroundTransparency = 1; title.Text = "Log in_::"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.Code; title.TextSize = 26; title.TextXAlignment = Enum.TextXAlignment.Left
	local uLabel = Instance.new("TextLabel", loginPanel); uLabel.Size = UDim2.new(0.35, 0, 0, 25); uLabel.Position = UDim2.new(0.05, 0, 0.42, 0); uLabel.BackgroundTransparency = 1; uLabel.Text = "account:"; uLabel.TextColor3 = Color3.new(1,1,1); uLabel.Font = Enum.Font.Code; uLabel.TextSize = 18; uLabel.TextXAlignment = Enum.TextXAlignment.Right
	local pLabel = Instance.new("TextLabel", loginPanel); pLabel.Size = UDim2.new(0.35, 0, 0, 25); pLabel.Position = UDim2.new(0.05, 0, 0.68, 0); pLabel.BackgroundTransparency = 1; pLabel.Text = "password:"; pLabel.TextColor3 = Color3.new(1,1,1); pLabel.Font = Enum.Font.Code; pLabel.TextSize = 18; pLabel.TextXAlignment = Enum.TextXAlignment.Right
	local uBox = Instance.new("TextLabel", loginPanel); uBox.Size = UDim2.new(0.5, 0, 0, 26); uBox.Position = UDim2.new(0.42, 0, 0.42, 0); uBox.BackgroundColor3 = Color3.new(1,1,1); uBox.Text = ""; uBox.Font = Enum.Font.Code; uBox.TextSize = 18; uBox.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", uBox).CornerRadius = UDim.new(0, 3)
	local pBox = Instance.new("TextLabel", loginPanel); pBox.Size = UDim2.new(0.5, 0, 0, 26); pBox.Position = UDim2.new(0.42, 0, 0.68, 0); pBox.BackgroundColor3 = Color3.new(1,1,1); pBox.Text = ""; pBox.Font = Enum.Font.Code; pBox.TextSize = 18; pBox.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", pBox).CornerRadius = UDim.new(0, 3)

	task.wait(0.3); typeWriter(uBox, " " .. player.Name, 0.05); task.wait(0.2); typeWriter(pBox, " ************", 0.04)
	TweenService:Create(pBox, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()

	local startSynch = tick(); local dots = {"", ".", "..", "..."}; local dotIndex = 1
	while not player:GetAttribute("Level") and tick() - startSynch < 5 do 
		if pLabel and pLabel.Parent then pLabel.Text = "authenticating" .. dots[dotIndex]; dotIndex = (dotIndex % 4) + 1 end
		task.wait(0.25) 
	end

	if pLabel and pLabel.Parent then pLabel.Text = "authenticating [OK]" end; task.wait(0.6)
	TweenService:Create(loginPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), GroupTransparency = 1}):Play(); task.wait(0.4); loginPanel:Destroy()

	local welcomeLbl = Instance.new("TextLabel", uiContainer); welcomeLbl.Size = UDim2.new(1, 0, 0, 100); welcomeLbl.Position = UDim2.new(0, 0, 0.46, 0); welcomeLbl.BackgroundTransparency = 1; welcomeLbl.Text = "Welcome to Sword Art Online !"; welcomeLbl.TextColor3 = Color3.fromRGB(20, 20, 20); welcomeLbl.Font = Enum.Font.SciFi; welcomeLbl.TextSize = 48; welcomeLbl.TextTransparency = 1
	TweenService:Create(welcomeLbl, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0, TextSize = 58}):Play(); task.wait(2.5); TweenService:Create(welcomeLbl, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1, TextSize = 65}):Play(); task.wait(0.5); welcomeLbl:Destroy()
	if skipBtn then skipBtn:Destroy() end

	TweenService:Create(bg, TweenInfo.new(0.3), {BackgroundColor3 = Color3.new(0,0,0)}):Play(); createWarpEffect(warpContainer, 1.4, true); task.wait(1.4); isWarping = false 
	warpContainer:Destroy(); bg.BackgroundColor3 = Color3.new(1,1,1); 
	TweenService:Create(bg, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play(); 
	task.wait(2); 
	loadingGui:Destroy()

	local miClase = player:GetAttribute("Class")
	if miClase == "Novato" or miClase == nil then
		-- 🔥 AQUÍ ESTÁ EL CAMBIO: El cliente solo espera el evento, ya no lo crea.
		-- Esto evita que se duplique y rompa la cadena.
		local OpenAvatarEvent = SAO_Events:WaitForChild("OpenAvatarCreator")
		OpenAvatarEvent:Fire()
	end
end)

-- =========================================================
-- CONFIGURACIÓN PRINCIPAL DE UI=======================
-- CONFIGURACIÓN PRINCIPAL DE UI
-- =========================================================
local gui = script.Parent
local unlocker = gui:WaitForChild("MouseUnlocker")

local loadingFrame = Instance.new("Frame", gui); loadingFrame.Size = UDim2.new(1,0,1,0); loadingFrame.BackgroundColor3 = Color3.fromRGB(15,15,20); loadingFrame.ZIndex = 100
local loadTxt = Instance.new("TextLabel", loadingFrame); loadTxt.Size = UDim2.new(1,0,1,0); loadTxt.BackgroundTransparency = 1; loadTxt.TextColor3 = Color3.fromRGB(200,200,200); loadTxt.Text = "LINK START...\nSincronizando datos de usuario..."; loadTxt.Font = Enum.Font.GothamBlack; loadTxt.TextSize = 24
task.spawn(function()
	local start = tick()
	while not player:GetAttribute("Level") and tick() - start < 6 do task.wait(0.1) end
	TweenService:Create(loadingFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play(); TweenService:Create(loadTxt, TweenInfo.new(0.8), {TextTransparency = 1}):Play(); task.wait(1); loadingFrame:Destroy()
end)

local sRight = gui:WaitForChild("Surface_Right"); local sLeft = gui:WaitForChild("Surface_Left"); local containerHUD = gui:WaitForChild("HUD_Container")
local mainRight = sRight:WaitForChild("Main_Right"); local mainLeft = sLeft:WaitForChild("Main_Left")
local btnContainer = mainRight:WaitForChild("BtnContainer"); local optionsPanel = mainRight:WaitForChild("SAO_Detailed_Options")
local optionsList = optionsPanel:WaitForChild("OptionsList"); local tabContainer = mainLeft:WaitForChild("TabContainer")

sRight.AlwaysOnTop = true
sLeft.AlwaysOnTop = true
sRight.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sLeft.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if unlocker:IsA("GuiObject") then unlocker.Active = false end

local VELOCIDAD_SUAVE = 35; local isMenuOpen = false; local menuOpenTime = 0; local activeCategory = nil; local slotSeleccionado = nil
local SAO_BG = Color3.fromRGB(245, 245, 250); local SAO_BG_ALPHA = 0.55; local SAO_TEXT = Color3.fromRGB(40, 40, 40); local SAO_HOVER = Color3.fromRGB(255, 153, 0); local SAO_STROKE = Color3.fromRGB(180, 180, 190)

local function getOrCreateTab(tabName)
	local tab = tabContainer:FindFirstChild(tabName)
	if not tab then tab = Instance.new("ScrollingFrame", tabContainer); tab.Name = tabName; tab.Size = UDim2.new(1,0,1,0); tab.BackgroundTransparency = 1; tab.ScrollBarThickness = 0; tab.Visible = false end
	return tab
end

local aRight = workspace:FindFirstChild("SAO_AnchorRight") or Instance.new("Part"); aRight.Name = "SAO_AnchorRight"; aRight.Size = Vector3.new(3.2, 4.5, 0.1); aRight.Transparency = 1; aRight.CanCollide = false; aRight.Anchored = true; aRight.Parent = workspace
local aLeft = workspace:FindFirstChild("SAO_AnchorLeft") or Instance.new("Part"); aLeft.Name = "SAO_AnchorLeft"; aLeft.Size = Vector3.new(5.5, 4.5, 0.1); aLeft.Transparency = 1; aLeft.CanCollide = false; aLeft.Anchored = true; aLeft.Parent = workspace
sRight.Adornee = aRight; sLeft.Adornee = aLeft

local armParts = {["Right Arm"] = true, ["Left Arm"] = true, ["RightUpperArm"] = true, ["RightLowerArm"] = true, ["RightHand"] = true, ["LeftUpperArm"] = true, ["LeftLowerArm"] = true, ["LeftHand"] = true}

local function actualizarBarrasHUD()
	local char = player.Character; if not char then return end
	local humanoid = char:FindFirstChild("Humanoid"); if not humanoid then return end
	local currentHp = humanoid.Health; local maxHp = humanoid.MaxHealth; local hpPercent = math.clamp(currentHp / maxHp, 0, 1)

	if containerHUD:FindFirstChild("HP_Bar") then
		local hpBar = containerHUD.HP_Bar; local textLabel = hpBar:FindFirstChildWhichIsA("TextLabel")
		if textLabel then textLabel.Text = "HP " .. math.floor(currentHp) .. "/" .. math.floor(maxHp) end
		if hpBar:FindFirstChild("Fill") then
			local fill = hpBar.Fill; TweenService:Create(fill, TweenInfo.new(0.25), {Size = UDim2.new(hpPercent, 0, 1, 0)}):Play()
			local targetColor = Color3.fromRGB(100, 255, 120); if hpPercent <= 0.25 then targetColor = Color3.fromRGB(255, 50, 50) elseif hpPercent <= 0.5 then targetColor = Color3.fromRGB(255, 200, 50) end 
			TweenService:Create(fill, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
		end
	end

	local playerInfoLbl = containerHUD:FindFirstChild("PlayerName")
	if playerInfoLbl then playerInfoLbl.Text = "Lv. " .. (player:GetAttribute("Level") or 1) .. "   " .. player.Name end

	local stats = {{n="SP", c=player:GetAttribute("SP") or 100, m=player:GetAttribute("MaxSP") or 100}, {n="MP", c=player:GetAttribute("MP") or 100, m=player:GetAttribute("MaxMP") or 100}}
	for _, s in ipairs(stats) do
		if containerHUD:FindFirstChild(s.n .. "_Bar") then
			local bar = containerHUD[s.n .. "_Bar"]; local txt = bar:FindFirstChildWhichIsA("TextLabel")
			if txt then txt.Text = s.n .. " " .. math.floor(s.c) .. "/" .. math.floor(s.m) end
			if bar:FindFirstChild("Fill") then TweenService:Create(bar.Fill, TweenInfo.new(0.25), {Size = UDim2.new(math.clamp(s.c/s.m,0,1), 0, 1, 0)}):Play() end
		end
	end
end

-- =========================================================
-- LOGICA DE ITEMS Y EQUIPAMIENTO 
-- =========================================================
local function FixToolPhysics(tool)
	for _, obj in ipairs(tool:GetDescendants()) do if obj:IsA("BasePart") then obj.Anchored = false; obj.CanCollide = false; obj.Massless = true end end
end

local function EsConsumible(toolName)
	local lower = string.lower(toolName)
	return string.find(lower, "potion") or string.find(lower, "heal") or string.find(lower, "cristal")
end

local function ActualizarEquipamiento() end

-- [CORREGIDO] Creador de Botones (Los Consumibles ahora se equipan normal)
-- [CORREGIDO] Creador de Botones (Restaura la lógica de Off Hand y Click Derecho)
local function CrearBotonItem(contenedorGrid, tool, slotType)
	local btn = Instance.new("TextButton", contenedorGrid); btn.Name = tool.Name; btn.Text = ""; btn.BackgroundColor3 = SAO_BG; btn.BackgroundTransparency = SAO_BG_ALPHA; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 2); local stroke = Instance.new("UIStroke", btn); stroke.Color = SAO_STROKE
	AplicaJuice(btn)

	local iconoEncontrado = false
	if tool:FindFirstChild("Icon") and tool.Icon:IsA("Texture") then
		local img = Instance.new("ImageLabel", btn); img.Size = UDim2.new(1,0,0.6,0); img.BackgroundTransparency = 1; img.Image = tool.Icon.Texture; iconoEncontrado = true
	end

	if not iconoEncontrado then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			local vp = Instance.new("ViewportFrame", btn); vp.Size = UDim2.new(1, 0, 0.6, 0); vp.BackgroundTransparency = 1; vp.LightColor = Color3.fromRGB(255,255,255); local cam = Instance.new("Camera", vp); vp.CurrentCamera = cam
			local cloneTool = tool:Clone(); for _, obj in ipairs(cloneTool:GetDescendants()) do if obj:IsA("Script") or obj:IsA("LocalScript") then obj.Disabled = true end end
			local model = Instance.new("Model", vp); local cloneHandle = cloneTool:FindFirstChild("Handle")
			if cloneHandle then model.PrimaryPart = cloneHandle; model:PivotTo(CFrame.new(0,0,0)); cam.CFrame = CFrame.new(Vector3.new(0, 0, math.max(cloneHandle.Size.X, cloneHandle.Size.Y, cloneHandle.Size.Z) * 2.5), Vector3.new(0,0,0)) end
		end
	end

	local nameLabel = Instance.new("TextLabel", btn); nameLabel.Size = UDim2.new(1, 0, 0.2, 0); nameLabel.Position = UDim2.new(0, 0, 0.55, 0); nameLabel.BackgroundTransparency = 1; nameLabel.TextColor3 = SAO_TEXT; nameLabel.TextScaled = true; nameLabel.Text = tool.Name; nameLabel.Font = Enum.Font.GothamMedium

	btn.MouseEnter:Connect(function() TweenService:Create(stroke, TweenInfo.new(0.15), {Color = SAO_HOVER, Thickness = 2}):Play(); TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = SAO_HOVER, BackgroundTransparency = 0.3}):Play(); TweenService:Create(nameLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play() end)
	btn.MouseLeave:Connect(function() TweenService:Create(stroke, TweenInfo.new(0.25), {Color = SAO_STROKE, Thickness = 1}):Play(); TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundColor3 = SAO_BG, BackgroundTransparency = SAO_BG_ALPHA}):Play(); TweenService:Create(nameLabel, TweenInfo.new(0.25), {TextColor3 = SAO_TEXT}):Play() end)

	-- CLICK IZQUIERDO NORMAL
	btn.MouseButton1Click:Connect(function() 
		sfxClick:Play(); FixToolPhysics(tool)

		-- 🔥 PRIORIDAD 1: Si el jugador seleccionó un slot específico en la rueda
		if slotSeleccionado == "Off Hand" then
			EquipOffhandEvent:FireServer(tool)
		elseif slotSeleccionado == "Main Hand" then
			if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid:EquipTool(tool) end

			-- 🔥 PRIORIDAD 2: Si el jugador equipa directo desde el inventario libre
		else
			if slotType == "Consumable" or slotType == "Main Hand" or slotType == "Weapon" then
				if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid:EquipTool(tool) end
			elseif slotType == "Off Hand" then
				EquipOffhandEvent:FireServer(tool)
			else
				EquipItemEvent:FireServer(slotType, tool.Name)
			end
		end

		slotSeleccionado = nil; 
		if tabContainer:FindFirstChild("Tab_Equip") then 
			for _, t in ipairs(tabContainer:GetChildren()) do if t:IsA("ScrollingFrame") or t:IsA("Frame") then t.Visible = false end end
			tabContainer.Tab_Equip.Visible = true; ActualizarEquipamiento() 
		end
	end)

	-- 🔥 RESTAURADO: CLICK DERECHO PARA OFF-HAND RÁPIDO
	btn.MouseButton2Click:Connect(function()
		if slotType ~= "Consumable" then
			sfxClick:Play(); FixToolPhysics(tool)
			EquipOffhandEvent:FireServer(tool)
			slotSeleccionado = nil 
			if tabContainer:FindFirstChild("Tab_Equip") then 
				for _, t in ipairs(tabContainer:GetChildren()) do if t:IsA("ScrollingFrame") or t:IsA("Frame") then t.Visible = false end end
				tabContainer.Tab_Equip.Visible = true; ActualizarEquipamiento() 
			end
		end
	end)
end

-- [CORREGIDO] Inventario con UI de Filtros Internos
local function ActualizarInventario(filtroDirecto)
	local invTab = getOrCreateTab("Tab_Inventory")

	-- Barra de Filtros Superior
	local filterBar = invTab:FindFirstChild("FilterBar")
	if not filterBar then
		filterBar = Instance.new("Frame", invTab); filterBar.Name = "FilterBar"; filterBar.Size = UDim2.new(1, -20, 0, 40); filterBar.Position = UDim2.new(0, 10, 0, 0); filterBar.BackgroundTransparency = 1
		local hLayout = Instance.new("UIListLayout", filterBar); hLayout.FillDirection = Enum.FillDirection.Horizontal; hLayout.Padding = UDim.new(0, 10); hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local categorias = {"All", "Weapon", "Armor", "Accessory"}
		for _, cat in ipairs(categorias) do
			local btnFiltro = Instance.new("TextButton", filterBar); btnFiltro.Size = UDim2.new(0, 80, 1, 0); btnFiltro.BackgroundColor3 = Color3.fromRGB(30, 30, 40); btnFiltro.Text = cat; btnFiltro.TextColor3 = Color3.new(1,1,1); btnFiltro.Font = Enum.Font.GothamBold; btnFiltro.TextSize = 12; Instance.new("UICorner", btnFiltro).CornerRadius = UDim.new(0, 4)
			AplicaJuice(btnFiltro)
			btnFiltro.MouseButton1Click:Connect(function() sfxClick:Play(); ActualizarInventario(cat == "All" and nil or cat) end)
		end
	end

	-- Contenedor de Items (Para que el Grid no rompa la barra de filtros)
	local itemContainer = invTab:FindFirstChild("ItemContainer")
	if not itemContainer then
		itemContainer = Instance.new("ScrollingFrame", invTab); itemContainer.Name = "ItemContainer"; itemContainer.Size = UDim2.new(1, 0, 1, -50); itemContainer.Position = UDim2.new(0, 0, 0, 50); itemContainer.BackgroundTransparency = 1; itemContainer.ScrollBarThickness = 0
		local grid = Instance.new("UIGridLayout", itemContainer); grid.CellSize = UDim2.new(0, 110, 0, 130); grid.CellPadding = UDim2.new(0, 10, 0, 10); grid.SortOrder = Enum.SortOrder.Name
	end

	for _, child in ipairs(itemContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	for _, tool in ipairs(player.Backpack:GetChildren()) do 
		if tool:IsA("Tool") and not EsConsumible(tool.Name) then 
			-- IMPORTANTE: El script busca un atributo "ItemType". Si tu tool de pecho no lo tiene, ponlo en Roblox Studio.
			local itemType = tool:GetAttribute("ItemType") or "Weapon" 
			if not filtroDirecto or itemType == filtroDirecto then
				CrearBotonItem(itemContainer, tool, itemType) 
			end
		end 
	end
end

local function ActualizarConsumibles()
	local consTab = getOrCreateTab("Tab_Consumables")
	if not consTab:FindFirstChild("UIGridLayout") then local grid = Instance.new("UIGridLayout", consTab); grid.CellSize = UDim2.new(0, 110, 0, 130); grid.CellPadding = UDim2.new(0, 10, 0, 10); grid.SortOrder = Enum.SortOrder.Name end
	for _, child in ipairs(consTab:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _, tool in ipairs(player.Backpack:GetChildren()) do if tool:IsA("Tool") and EsConsumible(tool.Name) then CrearBotonItem(consTab, tool, "Consumable") end end
end

local charClone_Equip = nil

function ActualizarEquipamiento()
	local equipTab = getOrCreateTab("Tab_Equip")
	local viewport = equipTab:FindFirstChild("3D_Mirror")
	if not viewport then viewport = Instance.new("ViewportFrame", equipTab); viewport.Name = "3D_Mirror"; viewport.Size = UDim2.new(0.6, 0, 0.8, 0); viewport.AnchorPoint = Vector2.new(0.5, 0.5); viewport.Position = UDim2.new(0.5, 0, 0.5, 0); viewport.BackgroundTransparency = 1; viewport.ZIndex = 1 end
	local vCam = viewport:FindFirstChildOfClass("Camera") or Instance.new("Camera", viewport); viewport.CurrentCamera = vCam

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		if charClone_Equip then charClone_Equip:Destroy(); charClone_Equip = nil end
		player.Character.Archivable = true; charClone_Equip = player.Character:Clone(); player.Character.Archivable = false
		if charClone_Equip then charClone_Equip.Parent = viewport; local hrpClone = charClone_Equip:FindFirstChild("HumanoidRootPart"); if hrpClone then vCam.CFrame = CFrame.new(hrpClone.Position + Vector3.new(0, 0.5, -6.5), hrpClone.Position) end end
	end

	local visualLayer = equipTab:FindFirstChild("SAO_Visual_Layer")
	if not visualLayer then visualLayer = Instance.new("Frame", equipTab); visualLayer.Name = "SAO_Visual_Layer"; visualLayer.Size = UDim2.new(1,0,1,0); visualLayer.BackgroundTransparency = 1; visualLayer.ZIndex = 5 end
	for _, c in ipairs(visualLayer:GetChildren()) do c:Destroy() end

	local mainWeapon = "None"; local offWeapon = "None"
	if player.Character then
		local tool = player.Character:FindFirstChildWhichIsA("Tool"); if tool then mainWeapon = tool.Name end
		local leftHand = player.Character:FindFirstChild("LeftHand") or player.Character:FindFirstChild("Left Arm")
		if leftHand then for _, obj in ipairs(leftHand:GetChildren()) do if (obj:IsA("WeldConstraint") or obj:IsA("Motor6D")) and obj.Part1 and obj.Part1.Parent then offWeapon = obj.Part1.Parent.Name end end end
	end

	local slots = {
		[1] = {name = "Necklace", val = player:GetAttribute("Equip_Necklace") or "Empty", filter = "Accessory"}, 
		[2] = {name = "Head", val = player:GetAttribute("Equip_Head") or "Empty", filter = "Armor"}, 
		[3] = {name = "Ring", val = player:GetAttribute("Equip_Ring") or "Empty", filter = "Accessory"}, 
		[4] = {name = "Main Hand", val = mainWeapon, filter = "Weapon"}, 
		[5] = {name = "Chest", val = player:GetAttribute("Equip_Chest") or "Empty", filter = "Armor"}, 
		[6] = {name = "Gloves", val = player:GetAttribute("Equip_Gloves") or "Empty", filter = "Armor"}, 
		[7] = {name = "Boots", val = player:GetAttribute("Equip_Boots") or "Empty", filter = "Armor"}, 
		[8] = {name = "Legs", val = player:GetAttribute("Equip_Legs") or "Empty", filter = "Armor"}, 
		[9] = {name = "Accessory", val = player:GetAttribute("Equip_Acc1") or "Empty", filter = "Accessory"}, 
		[10] = {name = "Off Hand", val = offWeapon, filter = "Weapon"}, 
		[11] = {name = "Cape", val = player:GetAttribute("Equip_Cape") or "Empty", filter = "Armor"}, 
		[12] = {name = "Belt", val = player:GetAttribute("Equip_Belt") or "Empty", filter = "Armor"}
	}

	for i = 1, 12 do
		local ang = math.rad((i-1)*30 - 90); local x = 0.5 + math.cos(ang)*0.25; local y = 0.5 + math.sin(ang)*0.4 
		local node = Instance.new("TextButton", visualLayer); node.Name = "Node_" .. i; node.Text = ""; node.Size = UDim2.new(0,16,0,16); node.Position = UDim2.new(x, -8, y, -8); node.ZIndex = 10; Instance.new("UICorner", node).CornerRadius = UDim.new(1,0)
		AplicaJuice(node)
		local data = slots[i]

		if data then
			node.BackgroundColor3 = (data.val == "Empty" or data.val == "None") and Color3.fromRGB(180,180,190) or SAO_HOVER
			local lbl = Instance.new("TextLabel", visualLayer); lbl.Size = UDim2.new(0, 100, 0, 20); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = SAO_TEXT; lbl.Text = data.name .. ": " .. data.val; lbl.ZIndex = 10
			if x > 0.5 then lbl.Position = UDim2.new(x, 20, y, -10); lbl.TextXAlignment = Enum.TextXAlignment.Left else lbl.Position = UDim2.new(x, -120, y, -10); lbl.TextXAlignment = Enum.TextXAlignment.Right end

			node.MouseButton1Click:Connect(function()
				sfxClick:Play()
				if data.val ~= "Empty" and data.val ~= "None" then
					if i == 4 then player.Character.Humanoid:UnequipTools() 
					elseif i == 10 then UnequipOffhandEvent:FireServer() 
					else UnequipItemEvent:FireServer(data.name) end

					TweenService:Create(node, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play(); task.wait(0.2); TweenService:Create(node, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180,180,190)}):Play()
					ActualizarEquipamiento()
				else
					slotSeleccionado = data.name
					local titleLbl = mainLeft:FindFirstChild("Title") or mainLeft:FindFirstChildOfClass("TextLabel"); if titleLbl then titleLbl.Text = "SELECT: " .. string.upper(slotSeleccionado) end
					for _, t in ipairs(tabContainer:GetChildren()) do if t:IsA("ScrollingFrame") or t:IsA("Frame") then t.Visible = false end end
					local targetTab = getOrCreateTab("Tab_Inventory"); targetTab.Visible = true; 

					ActualizarInventario(data.filter) 

					if not mainLeft.Visible then mainLeft.Visible = true; mainLeft.Size = UDim2.new(1,0,0,0); TweenService:Create(mainLeft, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,1,0)}):Play() end
				end
			end)
		end
	end
end

-- =========================================================
-- FUNCIONES RESTAURADAS: STATUS, SKILLS, MAP, QUESTS, SOCIAL
-- =========================================================
local function ActualizarStatus()
	local statTab = getOrCreateTab("Tab_Status")
	for _, c in ipairs(statTab:GetChildren()) do if c:IsA("Frame") or c:IsA("UIListLayout") then c:Destroy() end end
	local list = Instance.new("UIListLayout", statTab); list.Padding = UDim.new(0, 10); list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local statPoints = player:GetAttribute("StatPoints") or 0

	local function addStat(name, val, statId)
		local f = Instance.new("Frame", statTab); f.Size = UDim2.new(0.9, 0, 0, 40); f.BackgroundColor3 = SAO_BG; f.BackgroundTransparency = SAO_BG_ALPHA; Instance.new("UICorner", f).CornerRadius = UDim.new(0,4); Instance.new("UIStroke", f).Color = SAO_STROKE
		local nLbl = Instance.new("TextLabel", f); nLbl.Size = UDim2.new(0.5,0,1,0); nLbl.Position = UDim2.new(0.05,0,0,0); nLbl.BackgroundTransparency = 1; nLbl.Text = name; nLbl.Font = Enum.Font.GothamBold; nLbl.TextSize = 16; nLbl.TextColor3 = Color3.fromRGB(80,80,80); nLbl.TextXAlignment = Enum.TextXAlignment.Left
		local vLbl = Instance.new("TextLabel", f); vLbl.Size = UDim2.new(0.3,0,1,0); vLbl.Position = UDim2.new(0.5,0,0,0); vLbl.BackgroundTransparency = 1; vLbl.Text = tostring(val); vLbl.Font = Enum.Font.GothamMedium; vLbl.TextSize = 16; vLbl.TextColor3 = SAO_TEXT; vLbl.TextXAlignment = Enum.TextXAlignment.Right

		if statId and statPoints > 0 then
			local btnPlus = Instance.new("TextButton", f); btnPlus.Size = UDim2.new(0, 26, 0, 26); btnPlus.Position = UDim2.new(1, -35, 0.5, -13); btnPlus.BackgroundColor3 = SAO_HOVER; btnPlus.Text = "+"; btnPlus.Font = Enum.Font.GothamBlack; btnPlus.TextSize = 18; btnPlus.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0,4)
			AplicaJuice(btnPlus)
			btnPlus.MouseButton1Click:Connect(function() sfxUpgrade:Play(); UpgradeStatEvent:FireServer(statId) end)
		end
	end

	local char = player.Character; local hum = char and char:FindFirstChild("Humanoid")
	local expActual = player:GetAttribute("EXP") or 0; local nivelActual = player:GetAttribute("Level") or 1
	local expMaxima = math.floor(1000 * (1.5 ^ (nivelActual - 1)))

	addStat("Level", nivelActual); addStat("Class", player:GetAttribute("Class") or "Novato")
	addStat("HP", hum and math.floor(hum.Health).." / "..math.floor(hum.MaxHealth) or "0/0"); addStat("SP", math.floor(player:GetAttribute("SP") or 100))

	local fPoints = Instance.new("Frame", statTab); fPoints.Size = UDim2.new(0.9, 0, 0, 30); fPoints.BackgroundTransparency = 1; fPoints.LayoutOrder = 3
	local pLbl = Instance.new("TextLabel", fPoints); pLbl.Size = UDim2.new(1,0,1,0); pLbl.BackgroundTransparency = 1; pLbl.Text = "Stat Points Disponibles: " .. statPoints; pLbl.Font = Enum.Font.GothamBold; pLbl.TextSize = 14; pLbl.TextColor3 = SAO_HOVER; pLbl.TextXAlignment = Enum.TextXAlignment.Center

	addStat("STR (Strength)", player:GetAttribute("STR") or 10, "STR"); addStat("AGI (Agility)", player:GetAttribute("AGI") or 10, "AGI"); addStat("SIG (Stealth)", player:GetAttribute("SIG") or 5, "SIG")
	addStat("EXP to Next Lvl", math.floor(expActual) .. " / " .. expMaxima)
end

player:GetAttributeChangedSignal("StatPoints"):Connect(function() local t = getOrCreateTab("Tab_Status"); if t.Visible then ActualizarStatus() end end)
player:GetAttributeChangedSignal("STR"):Connect(function() local t = getOrCreateTab("Tab_Status"); if t.Visible then ActualizarStatus() end end)
player:GetAttributeChangedSignal("AGI"):Connect(function() local t = getOrCreateTab("Tab_Status"); if t.Visible then ActualizarStatus() end end)
player:GetAttributeChangedSignal("SIG"):Connect(function() local t = getOrCreateTab("Tab_Status"); if t.Visible then ActualizarStatus() end end)
player:GetAttributeChangedSignal("Level"):Connect(function() local t = getOrCreateTab("Tab_Status"); if t.Visible then ActualizarStatus(); actualizarBarrasHUD() end end)


-- [CORREGIDO] Habilidades Estrictas y Mejoradas Visualmente
local function ActualizarArbolHabilidades()
	local skillTab = getOrCreateTab("Tab_Skills")
	local scrollList = skillTab:FindFirstChild("SkillsScroll")
	local headerText = skillTab:FindFirstChild("Header") or skillTab:FindFirstChildOfClass("TextLabel")
	if not headerText then headerText = Instance.new("TextLabel", skillTab); headerText.Name = "Header"; headerText.Size = UDim2.new(1, -20, 0, 30); headerText.Position = UDim2.new(0, 10, 0, 10); headerText.BackgroundTransparency = 1; headerText.TextColor3 = SAO_TEXT; headerText.Font = Enum.Font.GothamBlack; headerText.TextScaled = true; headerText.TextXAlignment = Enum.TextXAlignment.Left end

	local miClase = player:GetAttribute("Class") or "Novato"
	headerText.Text = "Clase: " .. miClase .. " | SPts Disponibles: " .. (player:GetAttribute("SkillPoints") or 0)

	if not scrollList then
		scrollList = Instance.new("ScrollingFrame", skillTab); scrollList.Name = "SkillsScroll"; scrollList.Size = UDim2.new(1, -20, 1, -50); scrollList.Position = UDim2.new(0, 10, 0, 45); scrollList.BackgroundTransparency = 1; scrollList.ScrollBarThickness = 4; scrollList.ScrollBarImageColor3 = SAO_TEXT
		local listLayout = Instance.new("UIListLayout", scrollList); listLayout.Padding = UDim.new(0, 15); listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	end

	for _, child in ipairs(scrollList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	local count = 1
	for id, data in pairs(HabilidadesData) do
		-- 🔥 CORRECCIÓN: Tu módulo usa 'Para', no 'ClaseReq'
		-- Si el jugador es "Novato", le mostramos TODAS para que vea qué puede elegir en el futuro.
		-- Si ya tiene una clase asignada, solo le mostramos las de su arma.
		if data.Para == miClase or miClase == "Novato" or data.Para == "Todas" then
			local frame = Instance.new("Frame", scrollList); frame.Size = UDim2.new(1, -10, 0, 85); frame.LayoutOrder = count; frame.BackgroundColor3 = SAO_BG; frame.BackgroundTransparency = 0.2; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", frame).Color = SAO_STROKE

			local iconBg = Instance.new("Frame", frame); iconBg.Size = UDim2.new(0, 60, 0, 60); iconBg.Position = UDim2.new(0, 10, 0.5, -30); iconBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40); Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 4)
			local icon = Instance.new("ImageLabel", iconBg); icon.Size = UDim2.new(0.8, 0, 0.8, 0); icon.Position = UDim2.new(0.1, 0, 0.1, 0); icon.BackgroundTransparency = 1; icon.Image = data.Icono or "rbxassetid://13160395276"; icon.ImageColor3 = SAO_HOVER -- Ahora usa el icono de tu módulo si lo tiene

			local isUnlocked = player:GetAttribute("Skill_" .. id)
			local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(0.5, 0, 0, 25); title.Position = UDim2.new(0, 85, 0, 10); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 18; title.TextXAlignment = Enum.TextXAlignment.Left; title.TextColor3 = SAO_TEXT; title.Text = data.Nombre
			local desc = Instance.new("TextLabel", frame); desc.Size = UDim2.new(0.5, 0, 0, 20); desc.Position = UDim2.new(0, 85, 0, 35); desc.BackgroundTransparency = 1; desc.Font = Enum.Font.GothamMedium; desc.TextSize = 14; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.TextColor3 = Color3.fromRGB(80, 80, 90); desc.Text = data.Desc or "Habilidad de combate."
			local reqInfo = Instance.new("TextLabel", frame); reqInfo.Size = UDim2.new(0.5, 0, 0, 15); reqInfo.Position = UDim2.new(0, 85, 0, 60); reqInfo.BackgroundTransparency = 1; reqInfo.Font = Enum.Font.Gotham; reqInfo.TextSize = 12; reqInfo.TextXAlignment = Enum.TextXAlignment.Left; reqInfo.TextColor3 = Color3.fromRGB(200, 50, 50); reqInfo.Text = "Req: Nvl " .. (data.NivelReq or 1) .. " | Costo: " .. (data.Costo or 1) .. " SP"

			local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0, 110, 0, 40); btn.Position = UDim2.new(1, -125, 0.5, -20); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
			AplicaJuice(btn)

			if isUnlocked then 
				reqInfo.Text = "Desbloqueado"
				reqInfo.TextColor3 = Color3.fromRGB(50, 200, 50)
				local equippedSkill = player:GetAttribute("EquippedSkill")
				if equippedSkill == id then btn.Text = "EQUIPPED"; btn.BackgroundColor3 = Color3.fromRGB(0, 200, 255) else btn.Text = "EQUIP"; btn.BackgroundColor3 = SAO_HOVER end
			else 
				btn.Text = "LEARN"; btn.BackgroundColor3 = Color3.fromRGB(180, 180, 190) 
			end

			btn.MouseButton1Click:Connect(function() 
				if not isUnlocked then sfxClick:Play(); BuySkillEvent:FireServer(id); task.wait(0.2); ActualizarArbolHabilidades() 
				else sfxClick:Play(); SAO_Events:WaitForChild("EquipSkill"):FireServer(id); task.wait(0.1); ActualizarArbolHabilidades() end
			end)
			count = count + 1
		end
	end
end

local function ActualizarPanelAmigos()
	local friendsTab = getOrCreateTab("Tab_Friends")
	for _, c in ipairs(friendsTab:GetChildren()) do if c:IsA("Frame") or c:IsA("UIListLayout") or c:IsA("TextLabel") then c:Destroy() end end
	local list = Instance.new("UIListLayout", friendsTab); list.Padding = UDim.new(0, 10); list.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local header = Instance.new("TextLabel", friendsTab); header.Size = UDim2.new(0.9, 0, 0, 30); header.Text = "PLAYERS ONLINE"; header.Font = Enum.Font.GothamBlack; header.TextColor3 = SAO_HOVER; header.BackgroundTransparency = 1; header.TextScaled = true

	local playersOnline = Players:GetPlayers()
	local foundOthers = false

	for _, p in ipairs(playersOnline) do
		if p ~= player then
			foundOthers = true
			local f = Instance.new("Frame", friendsTab); f.Size = UDim2.new(0.9, 0, 0, 45); f.BackgroundColor3 = SAO_BG; f.BackgroundTransparency = 0.4; Instance.new("UICorner", f)
			local n = Instance.new("TextLabel", f); n.Size = UDim2.new(0.6, 0, 1, 0); n.Position = UDim2.new(0.05, 0, 0, 0); n.Text = p.Name; n.Font = Enum.Font.GothamBold; n.TextColor3 = SAO_TEXT; n.TextXAlignment = Enum.TextXAlignment.Left; n.BackgroundTransparency = 1; n.TextSize = 16

			local inviteBtn = Instance.new("TextButton", f); inviteBtn.Size = UDim2.new(0, 80, 0, 30); inviteBtn.Position = UDim2.new(1, -90, 0.5, -15); inviteBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); inviteBtn.Text = "INVITE"; inviteBtn.TextColor3 = Color3.new(1,1,1); inviteBtn.Font = Enum.Font.GothamBold; inviteBtn.TextSize = 12; Instance.new("UICorner", inviteBtn)
			AplicaJuice(inviteBtn)
			inviteBtn.MouseButton1Click:Connect(function() sfxClick:Play(); SocialEvent:FireServer("InviteParty", p) end)
		end
	end

	if not foundOthers then
		local empty = Instance.new("TextLabel", friendsTab); empty.Size = UDim2.new(1,0,0,100); empty.Text = "No other players online."; empty.TextColor3 = Color3.fromRGB(150,150,150); empty.BackgroundTransparency = 1; empty.Font = Enum.Font.GothamMedium; empty.TextSize = 16
	end
end

local function ActualizarPanelSocial()
	local partyTab = getOrCreateTab("Tab_Party")
	for _, c in ipairs(partyTab:GetChildren()) do if c:IsA("Frame") or c:IsA("UIListLayout") or c:IsA("TextLabel") or c:IsA("TextButton") then c:Destroy() end end
	local list = Instance.new("UIListLayout", partyTab); list.Padding = UDim.new(0, 10); list.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local header = Instance.new("TextLabel", partyTab); header.Size = UDim2.new(0.9, 0, 0, 30); header.Text = "CURRENT PARTY MEMBERS"; header.Font = Enum.Font.GothamBlack; header.TextColor3 = SAO_HOVER; header.BackgroundTransparency = 1; header.TextScaled = true

	local partyList = player:GetAttribute("MyPartyMembers")

	if not partyList or partyList == "" then
		local empty = Instance.new("TextLabel", partyTab); empty.Size = UDim2.new(1,0,0,100); empty.Text = "You are not in a party."; empty.TextColor3 = Color3.fromRGB(150,150,150); empty.BackgroundTransparency = 1; empty.Font = Enum.Font.GothamMedium; empty.TextSize = 16
	else
		local names = string.split(partyList, ",")
		for _, name in ipairs(names) do
			if name ~= "" then
				local f = Instance.new("Frame", partyTab); f.Size = UDim2.new(0.9, 0, 0, 45); f.BackgroundColor3 = SAO_BG; f.BackgroundTransparency = 0.4; Instance.new("UICorner", f)
				local n = Instance.new("TextLabel", f); n.Size = UDim2.new(0.7, 0, 1, 0); n.Position = UDim2.new(0.05, 0, 0, 0); n.Text = name; n.Font = Enum.Font.GothamBold; n.TextColor3 = SAO_TEXT; n.TextXAlignment = Enum.TextXAlignment.Left; n.BackgroundTransparency = 1; n.TextSize = 16
			end
		end

		local leaveBtn = Instance.new("TextButton", partyTab); leaveBtn.Size = UDim2.new(0.5, 0, 0, 40); leaveBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); leaveBtn.Text = "LEAVE PARTY"; leaveBtn.TextColor3 = Color3.new(1,1,1); leaveBtn.Font = Enum.Font.GothamBold; leaveBtn.TextSize = 14; Instance.new("UICorner", leaveBtn)
		AplicaJuice(leaveBtn)
		leaveBtn.MouseButton1Click:Connect(function() sfxClick:Play(); SocialEvent:FireServer("LeaveParty") end)
	end
end

SocialEvent.OnClientEvent:Connect(function(action, type, data)
	if action == "UpdateSocialUI" and type == "Party" then
		local nameString = ""
		for i, p in ipairs(data) do nameString = nameString .. p.Name .. (i < #data and "," or "") end
		player:SetAttribute("MyPartyMembers", nameString)
		if tabContainer:FindFirstChild("Tab_Party") and tabContainer.Tab_Party.Visible then ActualizarPanelSocial() end
	end
end)

local mapConnection = nil

local function getMapTargets()
	local targets = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then table.insert(targets, p.Character) end
	end
	local MobsFolder = workspace:FindFirstChild("Mobs")
	if MobsFolder then
		for _, mob in ipairs(MobsFolder:GetChildren()) do
			table.insert(targets, mob)
		end
	end
	return targets
end

-- [CORREGIDO] Radar SIN Scroll y con Terreno Configurable
local function ActualizarMapa()
	local mapTab = getOrCreateTab("Tab_Map")
	-- Apagamos el scroll para que siempre quede a la vista
	mapTab.ScrollingEnabled = false
	mapTab.CanvasSize = UDim2.new(0, 0, 0, 0)

	for _, c in ipairs(mapTab:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
	if mapConnection then mapConnection:Disconnect(); mapConnection = nil end

	local container = Instance.new("Frame", mapTab); container.Size = UDim2.new(1, 0, 1, 0); container.BackgroundTransparency = 1

	local mapBG = Instance.new("Frame", container); mapBG.Size = UDim2.new(0, 300, 0, 300); mapBG.Position = UDim2.new(0.5, 0, 0.5, 0); mapBG.AnchorPoint = Vector2.new(0.5, 0.5); mapBG.BackgroundColor3 = Color3.fromRGB(20, 25, 30); mapBG.ClipsDescendants = true; Instance.new("UICorner", mapBG).CornerRadius = UDim.new(1, 0); local stroke = Instance.new("UIStroke", mapBG); stroke.Color = SAO_STROKE; stroke.Thickness = 3

	-- 🗺️ REEMPLAZA ESTE ID DE IMAGEN con la captura desde arriba de TU mapa
	local terrainMap = Instance.new("ImageLabel", mapBG); terrainMap.Size = UDim2.new(3, 0, 3, 0); terrainMap.AnchorPoint = Vector2.new(0.5, 0.5); terrainMap.Position = UDim2.new(0.5, 0, 0.5, 0); terrainMap.BackgroundTransparency = 1; terrainMap.Image = "rbxassetid://16128886"; terrainMap.ImageTransparency = 0.3; terrainMap.ZIndex = 1

	local grid = Instance.new("ImageLabel", mapBG); grid.Size = UDim2.new(1, 0, 1, 0); grid.BackgroundTransparency = 1; grid.Image = "rbxassetid://4576405022"; grid.ImageTransparency = 0.7; grid.ImageColor3 = Color3.fromRGB(0, 255, 150); grid.ZIndex = 2

	local title = Instance.new("TextLabel", mapTab); title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.new(0,0,0,10); title.BackgroundTransparency = 1; title.Text = " AINCRAD - FLOOR 1 RADAR"; title.TextColor3 = SAO_TEXT; title.Font = Enum.Font.GothamBlack; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Center; title.ZIndex = 5

	local centerContainer = Instance.new("Frame", mapBG); centerContainer.Size = UDim2.new(1,0,1,0); centerContainer.BackgroundTransparency = 1; centerContainer.ZIndex = 5
	local playerDot = Instance.new("Frame", mapBG); playerDot.Size = UDim2.new(0, 12, 0, 12); playerDot.Position = UDim2.new(0.5, -6, 0.5, -6); playerDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100); playerDot.ZIndex = 10; Instance.new("UICorner", playerDot).CornerRadius = UDim.new(1,0)

	local pulse = Instance.new("UIStroke", playerDot); pulse.Color = Color3.fromRGB(0, 255, 100); pulse.Thickness = 1
	task.spawn(function() while playerDot do TweenService:Create(pulse, TweenInfo.new(1), {Thickness = 10, Transparency = 1}):Play(); task.wait(1); pulse.Thickness = 1; pulse.Transparency = 0 end end)

	local mapScale = 1.2; local enemyDots = {}

	mapConnection = RunService.RenderStepped:Connect(function()
		if not mapTab.Visible then if mapConnection then mapConnection:Disconnect(); mapConnection = nil end; return end
		local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local myPos = hrp.Position; local foundTargets = {}

		-- El terreno se mueve contrario al jugador para dar efecto de avance
		terrainMap.Position = UDim2.new(0.5, (-myPos.X * 0.005), 0.5, (-myPos.Z * 0.005))

		local activeTargets = getMapTargets()
		for _, targetObj in ipairs(activeTargets) do
			local hum = targetObj:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				local targetHrp = targetObj:FindFirstChild("HumanoidRootPart")
				if targetHrp and (targetHrp.Position - myPos).Magnitude <= 120 then 
					foundTargets[targetObj] = targetHrp 
				end
			end
		end

		for targetChar, targetHrp in pairs(foundTargets) do
			if not enemyDots[targetChar] then
				local dot = Instance.new("Frame", centerContainer); dot.Size = UDim2.new(0, 8, 0, 8)
				if Players:GetPlayerFromCharacter(targetChar) then dot.BackgroundColor3 = Color3.fromRGB(50, 150, 255) else dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50) end
				Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0); enemyDots[targetChar] = dot
			end
			local dot = enemyDots[targetChar]; local offsetX = (targetHrp.Position.X - myPos.X) * mapScale; local offsetZ = (targetHrp.Position.Z - myPos.Z) * mapScale
			dot.Position = UDim2.new(0.5, offsetX - 4, 0.5, offsetZ - 4)
		end
		for targetChar, dot in pairs(enemyDots) do if not foundTargets[targetChar] then dot:Destroy(); enemyDots[targetChar] = nil end end
	end)
end

local function ActualizarQuests()
	local questTab = getOrCreateTab("Tab_Quests")
	for _, c in ipairs(questTab:GetChildren()) do if c:IsA("Frame") or c:IsA("UIListLayout") then c:Destroy() end end
	local list = Instance.new("UIListLayout", questTab); list.Padding = UDim.new(0, 15); list.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local activeQuest = player:GetAttribute("ActiveQuest")
	local frame = Instance.new("Frame", questTab); frame.Size = UDim2.new(0.9, 0, 0, 110); frame.BackgroundColor3 = SAO_BG; frame.BackgroundTransparency = SAO_BG_ALPHA; Instance.new("UICorner", frame).CornerRadius = UDim.new(0,4); Instance.new("UIStroke", frame).Color = SAO_STROKE

	if not activeQuest or activeQuest == "Completada" or activeQuest == "Ninguna" then
		local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(1, 0, 1, 0); title.BackgroundTransparency = 1; title.Text = "No tienes misiones activas en este momento."; title.Font = Enum.Font.GothamMedium; title.TextSize = 16; title.TextColor3 = Color3.fromRGB(150,150,150)
	else
		local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(0.9, 0, 0, 25); title.Position = UDim2.new(0.05, 0, 0.1, 0); title.BackgroundTransparency = 1; title.Text = "Misión: " .. activeQuest; title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.TextColor3 = SAO_HOVER; title.TextXAlignment = Enum.TextXAlignment.Left

		local progreso = player:GetAttribute("QuestProgress") or 0; local total = (activeQuest == "Caza de Lobos") and 5 or 10 
		local desc = Instance.new("TextLabel", frame); desc.Size = UDim2.new(0.9, 0, 0, 20); desc.Position = UDim2.new(0.05, 0, 0.4, 0); desc.BackgroundTransparency = 1; desc.Text = "Progreso: " .. progreso .. " / " .. total; desc.Font = Enum.Font.GothamMedium; desc.TextSize = 14; desc.TextColor3 = SAO_TEXT; desc.TextXAlignment = Enum.TextXAlignment.Left

		local barBG = Instance.new("Frame", frame); barBG.Size = UDim2.new(0.9, 0, 0, 10); barBG.Position = UDim2.new(0.05, 0, 0.65, 0); barBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40); Instance.new("UICorner", barBG).CornerRadius = UDim.new(1,0)
		local barFill = Instance.new("Frame", barBG); barFill.Size = UDim2.new(math.clamp(progreso/total, 0, 1), 0, 1, 0); barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255); Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)

		local btnAbandon = Instance.new("TextButton", frame); btnAbandon.Size = UDim2.new(0, 100, 0, 25); btnAbandon.Position = UDim2.new(1, -110, 0.1, 0); btnAbandon.BackgroundColor3 = Color3.fromRGB(200, 50, 50); btnAbandon.Text = "ABANDONAR"; btnAbandon.TextColor3 = Color3.new(1,1,1); btnAbandon.Font = Enum.Font.GothamBold; btnAbandon.TextSize = 12; Instance.new("UICorner", btnAbandon).CornerRadius = UDim.new(0, 4)
		AplicaJuice(btnAbandon)

		btnAbandon.MouseButton1Click:Connect(function()
			sfxClick:Play()
			QuestEvent:FireServer("Abandon", activeQuest)
			player:SetAttribute("ActiveQuest", "Ninguna")
			ActualizarQuests()
		end)
	end
end

local function ActualizarSettings()
	local setTab = getOrCreateTab("Tab_Settings")
	for _, c in ipairs(setTab:GetChildren()) do if c:IsA("Frame") or c:IsA("UIListLayout") then c:Destroy() end end
	local list = Instance.new("UIListLayout", setTab); list.Padding = UDim.new(0, 10); list.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function addToggle(name, attrName)
		local f = Instance.new("Frame", setTab); f.Size = UDim2.new(0.9, 0, 0, 50); f.BackgroundColor3 = SAO_BG; f.BackgroundTransparency = SAO_BG_ALPHA; Instance.new("UICorner", f).CornerRadius = UDim.new(0,4); Instance.new("UIStroke", f).Color = SAO_STROKE
		local nLbl = Instance.new("TextLabel", f); nLbl.Size = UDim2.new(0.7,0,1,0); nLbl.Position = UDim2.new(0.05,0,0,0); nLbl.BackgroundTransparency = 1; nLbl.Text = name; nLbl.Font = Enum.Font.GothamMedium; nLbl.TextSize = 16; nLbl.TextColor3 = SAO_TEXT; nLbl.TextXAlignment = Enum.TextXAlignment.Left
		local btnToggle = Instance.new("TextButton", f); btnToggle.Size = UDim2.new(0, 60, 0, 30); btnToggle.Position = UDim2.new(1, -75, 0.5, -15); btnToggle.Font = Enum.Font.GothamBold; btnToggle.TextSize = 14; Instance.new("UICorner", btnToggle).CornerRadius = UDim.new(0,4)
		AplicaJuice(btnToggle)

		local isOn = player:GetAttribute(attrName)
		if isOn == nil then isOn = true; player:SetAttribute(attrName, true) end

		if isOn then btnToggle.Text = "ON"; btnToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50); btnToggle.TextColor3 = Color3.new(1,1,1) else btnToggle.Text = "OFF"; btnToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50); btnToggle.TextColor3 = Color3.new(1,1,1) end

		btnToggle.MouseButton1Click:Connect(function()
			sfxClick:Play(); isOn = not isOn; player:SetAttribute(attrName, isOn)
			if isOn then btnToggle.Text = "ON"; btnToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50) else btnToggle.Text = "OFF"; btnToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50) end
		end)
	end

	addToggle("Show Hitmarkers", "Set_Hitmarkers")
	addToggle("BGM Music", "Set_BGM")
	addToggle("SFX Sounds", "Set_SFX")
	addToggle("Low Graphics Mode", "Set_LowGFX")
	addToggle("Hide Player Names", "Set_HideNames")
	addToggle("UI Background Blur", "Set_UIBlur")
end

player:GetAttributeChangedSignal("Set_BGM"):Connect(function()
	local bgm = workspace:FindFirstChild("BGM") or workspace:FindFirstChildOfClass("Sound")
	if bgm then bgm.Volume = player:GetAttribute("Set_BGM") and 0.5 or 0 end
end)
player:GetAttributeChangedSignal("Set_LowGFX"):Connect(function()
	Lighting.GlobalShadows = not player:GetAttribute("Set_LowGFX")
end)
player:GetAttributeChangedSignal("Set_HideNames"):Connect(function()
	local hide = player:GetAttribute("Set_HideNames")
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local head = p.Character:FindFirstChild("Head")
			if head then
				for _, gui in ipairs(head:GetChildren()) do
					if gui:IsA("BillboardGui") then gui.Enabled = not hide end
				end
			end
		end
	end
end)


local function MostrarPlaceholder(nombreTab)
	local tab = getOrCreateTab(nombreTab)
	for _, c in ipairs(tab:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
	local lbl = Instance.new("TextLabel", tab); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 24; lbl.TextColor3 = Color3.fromRGB(150,150,160)
	lbl.Text = "Sección en Desarrollo: " .. nombreTab
end

-- [CORREGIDO] Agregadas las pestañas faltantes
local saoMenuData = {
	["Btn_Equip"] = {
		title = "PLAYER", 
		opts = {
			{txt="Equipment", tab="Tab_Equip", f=ActualizarEquipamiento}, 
			{txt="Status", tab="Tab_Status", f=ActualizarStatus}, 
			{txt="Weapons & Armor", tab="Tab_Inventory", f=function() ActualizarInventario(nil) end}, 
			{txt="Consumables", tab="Tab_Consumables", f=ActualizarConsumibles}, 
			{txt="Materials", tab="Tab_Materials", f=function() MostrarPlaceholder("Materials") end},
			{txt="Combat Skills", tab="Tab_Skills", f=ActualizarArbolHabilidades}, 
			{txt="Passive/Utility", tab="Tab_Passives", f=function() MostrarPlaceholder("Passives") end}
		}
	},
	["Btn_Map"] = {
		title = "MAP", 
		opts = {
			{txt="Field Map", tab="Tab_Map", f=ActualizarMapa}, 
			{txt="Quest Log", tab="Tab_Quests", f=ActualizarQuests}
		}
	},
	["Btn_Party"] = {
		title = "SOCIAL", 
		opts = {
			{txt="Friends", tab="Tab_Friends", f=ActualizarPanelAmigos}, 
			{txt="Party / Guild", tab="Tab_Party", f=ActualizarPanelSocial}
		}
	},
	["Btn_Settings"] = {
		title = "SYSTEM", 
		opts = {
			{txt="Settings", tab="Tab_Settings", f=ActualizarSettings}, 
			{txt="Log Out", tab="Tab_LogOut", f=function() player:Kick("\n\n=== SYSTEM LOG OUT ===\nHas cerrado sesión en SAO.") end}
		}
	}
}

if not btnContainer:FindFirstChild("Btn_Map") then
	local mapBtn = btnContainer:FindFirstChild("Btn_Equip"):Clone(); mapBtn.Name = "Btn_Map"; mapBtn.Icon.Image = "rbxassetid://13160395276"; mapBtn.Parent = btnContainer
	AplicaJuice(mapBtn)
end

-- =========================================================
-- CONTROLES DEL MENÚ Y MULTIPLATAFORMA
-- =========================================================
local function closeMainPanel()
	if not mainLeft.Visible then return end
	slotSeleccionado = nil 
	local tw = TweenService:Create(mainLeft, TweenInfo.new(0.2), {Size = UDim2.new(1,0,0,0)}); tw:Play(); tw.Completed:Connect(function() mainLeft.Visible = false end)
end

local function closeOptionsPanel()
	if not optionsPanel.Visible then return end
	local tw = TweenService:Create(optionsPanel, TweenInfo.new(0.2), {Size = UDim2.new(0,320,0,0)}); tw:Play(); tw.Completed:Connect(function() optionsPanel.Visible = false end)
end

local function closeAll()
	isMenuOpen = false; unlocker.Visible = false; player:SetAttribute("MenuOpen", false); activeCategory = nil
	closeMainPanel(); closeOptionsPanel()
	TweenService:Create(saoBlur, TweenInfo.new(0.4), {FarIntensity = 0}):Play()
	for _, b in ipairs(btnContainer:GetChildren()) do if b:IsA("TextButton") and b.Name ~= "CloseBtn" then b.BackgroundColor3 = Color3.fromRGB(45,45,45) end end
	local tw = TweenService:Create(mainRight, TweenInfo.new(0.3), {Size = UDim2.new(1,0,0,0)}); tw:Play(); tw.Completed:Connect(function() if not isMenuOpen then mainRight.Visible = false end end)
end

local function toggleMenu()
	if isMenuOpen then 
		closeAll() 
	else
		sfxOpen:Play(); isMenuOpen = true; unlocker.Visible = true; mainRight.Visible = true; player:SetAttribute("MenuOpen", true); menuOpenTime = tick() 
		mainRight.Size = UDim2.new(1,0,0,0); TweenService:Create(mainRight, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,1,0)}):Play()

		if player:GetAttribute("Set_UIBlur") ~= false then
			TweenService:Create(saoBlur, TweenInfo.new(0.4), {FarIntensity = 0.8}):Play()
		end

		task.delay(0.1, function()
			local lastInput = UIS:GetLastInputType()
			if lastInput.Name:find("Gamepad") then
				if btnContainer:FindFirstChild("Btn_Equip") then 
					GuiService.SelectedObject = btnContainer.Btn_Equip 
				end
			else
				GuiService.SelectedObject = nil 
			end
		end)
	end
end

CAS:BindAction("ToggleSAOMenu", function(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then toggleMenu() end
end, false, Enum.KeyCode.G, Enum.KeyCode.DPadUp)

task.spawn(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local mobileControls = playerGui:WaitForChild("MobileControls", 10)
	if mobileControls then
		local btnMenuMobile = mobileControls:WaitForChild("BtnMenu", 5)
		if btnMenuMobile then
			btnMenuMobile.Activated:Connect(function()
				toggleMenu()
			end)
		end
	end
end)

for _, btn in ipairs(btnContainer:GetChildren()) do
	if btn:IsA("TextButton") and btn.Name ~= "CloseBtn" then
		AplicaJuice(btn)
		btn.MouseEnter:Connect(function() if activeCategory ~= btn.Name then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = SAO_HOVER}):Play() end end)
		btn.MouseLeave:Connect(function() if activeCategory ~= btn.Name then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play() end end)

		btn.MouseButton1Down:Connect(function()
			sfxClick:Play()
			if activeCategory == btn.Name then activeCategory = nil; btn.BackgroundColor3 = Color3.fromRGB(45,45,45); closeOptionsPanel(); closeMainPanel(); return end

			activeCategory = btn.Name
			for _, b in ipairs(btnContainer:GetChildren()) do if b:IsA("TextButton") and b.Name ~= "CloseBtn" then b.BackgroundColor3 = Color3.fromRGB(45,45,45) end end
			btn.BackgroundColor3 = SAO_HOVER

			local data = saoMenuData[btn.Name]
			if data then
				local headerLbl = optionsPanel:FindFirstChild("Header") or optionsPanel:FindFirstChildOfClass("TextLabel")
				if headerLbl then headerLbl.Text = data.title end

				for _, c in ipairs(optionsList:GetChildren()) do 
					if not c:IsA("UIListLayout") then 
						c:Destroy() 
					end 
				end

				for _, opt in ipairs(data.opts) do
					local sBtnBase = Instance.new("Frame", optionsList)
					sBtnBase.Size = UDim2.new(1,0,0,45)
					sBtnBase.BackgroundColor3 = SAO_BG
					sBtnBase.BackgroundTransparency = 0.2
					Instance.new("UICorner", sBtnBase).CornerRadius = UDim.new(0,4)
					local stroke = Instance.new("UIStroke", sBtnBase)
					stroke.Color = SAO_STROKE

					local btnText = Instance.new("TextLabel", sBtnBase)
					btnText.Size = UDim2.new(1,0,1,0)
					btnText.BackgroundTransparency = 1
					btnText.Text = "  "..opt.txt
					btnText.Font = Enum.Font.GothamMedium
					btnText.TextSize = 16
					btnText.TextColor3 = SAO_TEXT
					btnText.TextXAlignment = Enum.TextXAlignment.Left

					local sBtn = Instance.new("TextButton", sBtnBase)
					sBtn.Size = UDim2.new(1,0,1,0)
					sBtn.BackgroundTransparency = 1
					sBtn.Text = ""
					sBtn.ZIndex = 10

					AplicaJuice(sBtnBase)

					sBtn.MouseEnter:Connect(function() 
						TweenService:Create(sBtnBase, TweenInfo.new(0.1), {BackgroundColor3 = SAO_HOVER}):Play()
						TweenService:Create(btnText, TweenInfo.new(0.1), {TextColor3 = Color3.new(1,1,1)}):Play() 
					end)
					sBtn.MouseLeave:Connect(function() 
						TweenService:Create(sBtnBase, TweenInfo.new(0.1), {BackgroundColor3 = SAO_BG}):Play()
						TweenService:Create(btnText, TweenInfo.new(0.1), {TextColor3 = SAO_TEXT}):Play() 
					end)

					sBtn.MouseButton1Down:Connect(function()
						sfxClick:Play()
						local titleLbl = mainLeft:FindFirstChild("Title") or mainLeft:FindFirstChildOfClass("TextLabel")
						if titleLbl then titleLbl.Text = opt.txt:upper() end

						for _, t in ipairs(tabContainer:GetChildren()) do if t:IsA("ScrollingFrame") or t:IsA("Frame") then t.Visible = false end end
						local targetTab = getOrCreateTab(opt.tab); targetTab.Visible = true
						if opt.f then opt.f() end

						mainLeft.Visible = true; mainLeft.Size = UDim2.new(1,0,0,0)
						TweenService:Create(mainLeft, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,1,0)}):Play()
					end)
				end
				local alturaDinamica = 50 + (#data.opts * 55)
				optionsPanel.Visible = true; optionsPanel.Size = UDim2.new(0,320,0,0)
				TweenService:Create(optionsPanel, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = UDim2.new(0,320,0,alturaDinamica)}):Play()
				closeMainPanel()
			end
		end)
	end
end

if mainLeft:FindFirstChild("CloseBtn") then 
	AplicaJuice(mainLeft.CloseBtn)
	mainLeft.CloseBtn.MouseButton1Down:Connect(function() sfxClick:Play(); closeMainPanel() end) 
end
if btnContainer:FindFirstChild("CloseBtn") then 
	AplicaJuice(btnContainer.CloseBtn)
	btnContainer.CloseBtn.MouseButton1Down:Connect(function() sfxClick:Play(); closeAll() end) 
end

closeAll()

-- =========================================================
-- ROTACIÓN SUAVE Y RENDERIZADO
-- =========================================================
RunService.RenderStepped:Connect(function(dt)
	if charClone_Equip and tabContainer:FindFirstChild("Tab_Equip") and tabContainer.Tab_Equip.Visible then 
		local cloneHrp = charClone_Equip:FindFirstChild("HumanoidRootPart")
		if cloneHrp then cloneHrp.CFrame = cloneHrp.CFrame * CFrame.Angles(0, math.rad(0.5), 0) end
	end
	if skillViewportChar and tabContainer:FindFirstChild("Tab_Skills") and tabContainer.Tab_Skills.Visible then skillViewportChar.CFrame = skillViewportChar.CFrame * CFrame.Angles(0, math.rad(1.5), 0) end

	local cam = workspace.CurrentCamera
	if not cam or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	local lerpAlpha = 1 - math.exp(-VELOCIDAD_SUAVE * dt)
	aRight.CFrame = aRight.CFrame:Lerp(cam.CFrame * CFrame.new(3.2, 0, -4.5) * CFrame.Angles(0, math.rad(165), 0), lerpAlpha)
	aLeft.CFrame = aLeft.CFrame:Lerp(cam.CFrame * CFrame.new(-4, 0, -4.5) * CFrame.Angles(0, math.rad(-165), 0), lerpAlpha)

	local char = player.Character; local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"); local shoulder = nil
	if char:FindFirstChild("RightUpperArm") and char.RightUpperArm:FindFirstChild("RightShoulder") then shoulder = char.RightUpperArm.RightShoulder elseif torso and torso:FindFirstChild("Right Shoulder") then shoulder = torso["Right Shoulder"] end
	for _, part in ipairs(char:GetChildren()) do if part:IsA("BasePart") and armParts[part.Name] then part.LocalTransparencyModifier = isMenuOpen and 0.4 or 0 end end

	if shoulder and torso then
		pcall(function()
			if not shoulder:GetAttribute("OrigC0") then shoulder:SetAttribute("OrigC0", shoulder.C0) end
			local origC0 = shoulder:GetAttribute("OrigC0"); local origC1 = shoulder.C1 
			if isMenuOpen and tick() - menuOpenTime > 0.5 then
				local mouseLoc = UIS:GetMouseLocation(); local ray = cam:ScreenPointToRay(mouseLoc.X, mouseLoc.Y)
				local targetPoint = ray.Origin + (ray.Direction * 15)
				local lookCF = CFrame.lookAt((torso.CFrame * origC0).Position, targetPoint)
				shoulder.C0 = shoulder.C0:Lerp(CFrame.new(origC0.Position) * (torso.CFrame.Rotation:Inverse() * (lookCF * CFrame.Angles(math.rad(90), 0, 0)).Rotation * origC1.Rotation), 1 - math.exp(-20 * dt))
			else
				shoulder.C0 = shoulder.C0:Lerp(origC0, 1 - math.exp(-15 * dt))
			end
		end)
	end
end)

local function setupCharacter(char)
	local hum = char:WaitForChild("Humanoid")
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.HealthChanged:Connect(actualizarBarrasHUD)
	actualizarBarrasHUD()
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)
