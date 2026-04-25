local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Eventos = ReplicatedStorage:WaitForChild("SAO_Events")
local SocialEvent = Eventos:WaitForChild("SocialEvent")

local MENU_OPEN = false
local currentMenu = nil
local targetJugadorActual = nil
local currentPartyUI = nil
local partyConnections = {} 

-- ==========================================
-- 🎵 SONIDOS SAO
-- ==========================================
local sfxPop = Instance.new("Sound", workspace); sfxPop.SoundId = "rbxassetid://8503522619"; sfxPop.Volume = 0.8
local sfxClick = Instance.new("Sound", workspace); sfxClick.SoundId = "rbxassetid://6895079853"; sfxClick.Volume = 0.6
local sfxAlert = Instance.new("Sound", workspace); sfxAlert.SoundId = "rbxassetid://6114983058"; sfxAlert.Volume = 1
local sfxClose = Instance.new("Sound", workspace); sfxClose.SoundId = "rbxassetid://6895079853"; sfxClose.Volume = 0.5; sfxClose.Pitch = 0.8
local sfxDuelBeep = Instance.new("Sound", workspace); sfxDuelBeep.SoundId = "rbxassetid://155202884"; sfxDuelBeep.Volume = 1
local sfxDuelStart = Instance.new("Sound", workspace); sfxDuelStart.SoundId = "rbxassetid://155202874"; sfxDuelStart.Volume = 1

local SAO_BG = Color3.fromRGB(15, 15, 20)
local SAO_ORANGE = Color3.fromRGB(255, 153, 0)
local SAO_BLUE = Color3.fromRGB(0, 150, 255)
local SAO_GREEN = Color3.fromRGB(50, 200, 50)
local SAO_RED = Color3.fromRGB(255, 50, 50)

-- ==========================================
-- 🪟 1. MENÚ VERTICAL SAO (IDÉNTICO AL ANIME)
-- ==========================================
local function CerrarMenu()
	if currentMenu then
		sfxClose:Play()
		local container = currentMenu:FindFirstChild("MenuContainer")
		if container then
			TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 200, 0, 0)}):Play()
			task.wait(0.15)
		end
		currentMenu:Destroy()
		currentMenu = nil
		targetJugadorActual = nil
		MENU_OPEN = false
	end
end

local function AbrirMenuInteract(targetPlayer)
	if MENU_OPEN then CerrarMenu() end
	if targetPlayer == player then return end

	MENU_OPEN = true
	targetJugadorActual = targetPlayer
	sfxPop:Play()

	local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui")); sg.Name = "SAO_InteractMenu"; currentMenu = sg

	-- El contenedor principal que actúa como "máscara" para el despliegue
	local clipFrame = Instance.new("Frame", sg)
	clipFrame.Name = "MenuContainer"
	clipFrame.Size = UDim2.new(0, 200, 0, 0) -- Inicia cerrado
	clipFrame.Position = UDim2.new(0.5, 40, 0.5, -80)
	clipFrame.BackgroundTransparency = 1
	clipFrame.ClipsDescendants = true

	local mainPanel = Instance.new("Frame", clipFrame)
	mainPanel.Size = UDim2.new(1, 0, 0, 220)
	mainPanel.BackgroundColor3 = SAO_BG
	mainPanel.BackgroundTransparency = 0.2
	Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 4)
	local stroke = Instance.new("UIStroke", mainPanel); stroke.Color = SAO_ORANGE; stroke.Thickness = 1.5

	local header = Instance.new("TextLabel", mainPanel)
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Text = "  " .. targetPlayer.Name
	header.TextColor3 = SAO_ORANGE
	header.Font = Enum.Font.GothamBlack
	header.TextSize = 14
	header.TextXAlignment = Enum.TextXAlignment.Left

	local div = Instance.new("Frame", mainPanel)
	div.Size = UDim2.new(0.9, 0, 0, 1)
	div.Position = UDim2.new(0.05, 0, 0, 30)
	div.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
	div.BorderSizePixel = 0

	local listFrame = Instance.new("Frame", mainPanel)
	listFrame.Size = UDim2.new(1, 0, 1, -35)
	listFrame.Position = UDim2.new(0, 0, 0, 35)
	listFrame.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout", listFrame)
	layout.Padding = UDim.new(0, 2)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local opciones = {
		{nombre = "Party Invite", color = SAO_BLUE, action = function() SocialEvent:FireServer("InviteParty", targetPlayer) end},
		{nombre = "Trade Request", color = SAO_GREEN, action = function() SocialEvent:FireServer("RequestTrade", targetPlayer) end},
		{nombre = "Duel Challenge", color = SAO_RED, action = function() SocialEvent:FireServer("RequestDuel", targetPlayer) end},
		{nombre = "Close Menu", color = Color3.fromRGB(150,150,150), action = function() CerrarMenu() end}
	}

	for i, opt in ipairs(opciones) do
		local btn = Instance.new("TextButton", listFrame)
		btn.Size = UDim2.new(0.95, 0, 0, 40)
		btn.BackgroundColor3 = SAO_BG
		btn.BackgroundTransparency = 1
		btn.Text = "    " .. opt.nombre
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.new(1,1,1)
		btn.TextSize = 14
		btn.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 2)

		-- Ícono de color a la izquierda (Estilo SAO)
		local iconMark = Instance.new("Frame", btn)
		iconMark.Size = UDim2.new(0, 4, 0.6, 0)
		iconMark.Position = UDim2.new(0, 4, 0.2, 0)
		iconMark.BackgroundColor3 = opt.color
		Instance.new("UICorner", iconMark)

		btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, BackgroundColor3 = opt.color}):Play() end)
		btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1, BackgroundColor3 = SAO_BG}):Play() end)

		btn.MouseButton1Click:Connect(function() 
			sfxClick:Play()
			opt.action()
			if opt.nombre ~= "Close Menu" then CerrarMenu() end 
		end)
	end

	-- Animación SAO de despliegue hacia abajo
	TweenService:Create(clipFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 200, 0, 220)}):Play()
end

-- ==========================================
-- 🎯 2. DETECCIÓN MULTIPLATAFORMA
-- ==========================================
local function GetPlayerFromPart(part)
	if not part then return nil end
	local character = part:FindFirstAncestorWhichIsA("Model")
	if character and character:FindFirstChild("Humanoid") then
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

local function HandleInteractInput(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		if MENU_OPEN then CerrarMenu(); return end
		local viewportSize = camera.ViewportSize
		local ray = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {player.Character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(ray.Origin, ray.Direction * 50, raycastParams)

		if result and result.Instance then
			local targetPlayer = GetPlayerFromPart(result.Instance)
			if targetPlayer then AbrirMenuInteract(targetPlayer) end
		end
	end
end

ContextActionService:BindAction("SAO_Interact", HandleInteractInput, false, Enum.KeyCode.V, Enum.KeyCode.ButtonY)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if MENU_OPEN then
			local mousePos = UserInputService:GetMouseLocation()
			local objectsAtMouse = player.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y - 36)
			local hitMenu = false
			for _, obj in ipairs(objectsAtMouse) do
				if obj.Name == "MenuContainer" or obj:IsDescendantOf(currentMenu) then hitMenu = true; break end
			end
			if not hitMenu then CerrarMenu(); return end
		else
			local pos = input.Position
			local ray = camera:ViewportPointToRay(pos.X, pos.Y)
			local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
			if result and result.Instance then
				local targetPlayer = GetPlayerFromPart(result.Instance)
				if targetPlayer then AbrirMenuInteract(targetPlayer) end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if MENU_OPEN and targetJugadorActual and targetJugadorActual.Character and player.Character then
		local dist = (player.Character:GetPivot().Position - targetJugadorActual.Character:GetPivot().Position).Magnitude
		if dist > 20 then CerrarMenu() end
	elseif MENU_OPEN and not targetJugadorActual then
		CerrarMenu()
	end
end)

-- ==========================================
-- ⚔️ 3. SISTEMA DE DUELOS (ANIMACIÓN Y UI)
-- ==========================================
local function IniciarSecuenciaDuelo(opponent)
	local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui")); sg.Name = "SAO_DuelHUD"

	local duelText = Instance.new("TextLabel", sg)
	duelText.Size = UDim2.new(1, 0, 0, 150)
	duelText.Position = UDim2.new(0, 0, 0.3, 0)
	duelText.BackgroundTransparency = 1
	duelText.Font = Enum.Font.GothamBlack
	duelText.TextSize = 100
	duelText.TextColor3 = SAO_ORANGE
	duelText.TextStrokeColor3 = Color3.new(0,0,0)
	duelText.TextStrokeTransparency = 0
	duelText.TextTransparency = 1
	duelText.Text = "VS " .. opponent.Name

	TweenService:Create(duelText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	task.wait(2)

	-- Cuenta regresiva
	for i = 3, 1, -1 do
		sfxDuelBeep:Play()
		duelText.Text = tostring(i)
		local origSize = duelText.TextSize
		duelText.TextSize = 150
		TweenService:Create(duelText, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = origSize}):Play()
		task.wait(1)
	end

	sfxDuelStart:Play()
	duelText.TextColor3 = SAO_RED
	duelText.Text = "DUEL!"
	duelText.TextSize = 180

	TweenService:Create(duelText, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1, TextSize = 200}):Play()
	task.wait(1)
	sg:Destroy()

	-- Aquí puedes agregar el HUD de vida del oponente del duelo arriba al centro (como en los bosses)
end

-- ==========================================
-- ⚖️ 4. SISTEMA DE TRADEO (UI DE INTERCAMBIO)
-- ==========================================
local function AbrirVentanaTradeo(partner)
	local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui")); sg.Name = "SAO_TradeWindow"

	-- Fondo oscuro
	local bg = Instance.new("Frame", sg)
	bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.new(0,0,0); bg.BackgroundTransparency = 0.5

	local mainPanel = Instance.new("Frame", bg)
	mainPanel.Size = UDim2.new(0, 700, 0, 450); mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0); mainPanel.AnchorPoint = Vector2.new(0.5, 0.5); mainPanel.BackgroundColor3 = SAO_BG; mainPanel.BackgroundTransparency = 0.1; Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", mainPanel); stroke.Color = SAO_GREEN; stroke.Thickness = 2

	local header = Instance.new("TextLabel", mainPanel)
	header.Size = UDim2.new(1, 0, 0, 40); header.BackgroundTransparency = 1; header.Text = " SECURE TRADE"; header.TextColor3 = SAO_GREEN; header.Font = Enum.Font.GothamBlack; header.TextSize = 20

	-- Lado Izquierdo (Tú)
	local leftPanel = Instance.new("Frame", mainPanel)
	leftPanel.Size = UDim2.new(0.45, 0, 0.7, 0); leftPanel.Position = UDim2.new(0.025, 0, 0.1, 0); leftPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Instance.new("UICorner", leftPanel)
	local leftTitle = Instance.new("TextLabel", leftPanel); leftTitle.Size = UDim2.new(1,0,0,30); leftTitle.BackgroundTransparency=1; leftTitle.Text = player.Name; leftTitle.TextColor3=SAO_BLUE; leftTitle.Font=Enum.Font.GothamBold; leftTitle.TextSize=16

	-- Lado Derecho (El Otro)
	local rightPanel = Instance.new("Frame", mainPanel)
	rightPanel.Size = UDim2.new(0.45, 0, 0.7, 0); rightPanel.Position = UDim2.new(0.525, 0, 0.1, 0); rightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Instance.new("UICorner", rightPanel)
	local rightTitle = Instance.new("TextLabel", rightPanel); rightTitle.Size = UDim2.new(1,0,0,30); rightTitle.BackgroundTransparency=1; rightTitle.Text = partner.Name; rightTitle.TextColor3=SAO_ORANGE; rightTitle.Font=Enum.Font.GothamBold; rightTitle.TextSize=16

	-- Botones Inferiores
	local btnAccept = Instance.new("TextButton", mainPanel)
	btnAccept.Size = UDim2.new(0, 200, 0, 45); btnAccept.Position = UDim2.new(0.5, 20, 0.85, 0); btnAccept.BackgroundColor3 = SAO_GREEN; btnAccept.Text = "ACCEPT TRADE"; btnAccept.Font = Enum.Font.GothamBlack; btnAccept.TextColor3 = Color3.new(1,1,1); btnAccept.TextSize=16; Instance.new("UICorner", btnAccept)

	local btnCancel = Instance.new("TextButton", mainPanel)
	btnCancel.Size = UDim2.new(0, 200, 0, 45); btnCancel.Position = UDim2.new(0.5, -220, 0.85, 0); btnCancel.BackgroundColor3 = SAO_RED; btnCancel.Text = "CANCEL"; btnCancel.Font = Enum.Font.GothamBlack; btnCancel.TextColor3 = Color3.new(1,1,1); btnCancel.TextSize=16; Instance.new("UICorner", btnCancel)

	btnCancel.MouseButton1Click:Connect(function()
		sfxClick:Play()
		SocialEvent:FireServer("CancelTrade")
		sg:Destroy()
	end)

	btnAccept.MouseButton1Click:Connect(function()
		sfxClick:Play()
		btnAccept.Text = "WAITING FOR PARTNER..."
		btnAccept.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		SocialEvent:FireServer("ConfirmTrade")
	end)
end

-- ==========================================
-- 💌 5. RECEPCIÓN DE EVENTOS DEL SERVIDOR
-- ==========================================
SocialEvent.OnClientEvent:Connect(function(action, data1, data2)

	-- RECIBIR INVITACIÓN (Círculos SAO)
	if action == "ReceiveInvite" then
		sfxAlert:Play()
		local inviter = data1
		local type = data2 -- "Party", "Trade", o "Duel"

		local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui")); sg.Name = "SAO_PartyInvite"

		local frame = Instance.new("CanvasGroup", sg)
		frame.Size = UDim2.new(0, 0, 0, 130)
		frame.Position = UDim2.new(0.5, 0, 0.25, 0)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = SAO_BG
		frame.BackgroundTransparency = 0.1
		frame.GroupTransparency = 1
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
		local stroke = Instance.new("UIStroke", frame); stroke.Color = SAO_ORANGE; stroke.Thickness = 2

		TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 130), GroupTransparency = 0}):Play()

		local t = Instance.new("TextLabel", frame); t.Size = UDim2.new(1, 0, 0.5, 0); t.Position = UDim2.new(0,0,0,5)
		t.Text = "REQUEST: " .. string.upper(type) .. "\n<font color='rgb(255,153,0)'>" .. inviter.Name .. "</font>"
		t.RichText = true; t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.GothamBlack; t.TextSize = 16; t.BackgroundTransparency = 1

		-- Botones Circulares Estilo SAO
		local bA = Instance.new("TextButton", frame); bA.Size = UDim2.new(0, 50, 0, 50); bA.Position = UDim2.new(0.25, -25, 0.6, 0); bA.BackgroundColor3 = SAO_BG; bA.Text = "O"; bA.Font = Enum.Font.GothamBlack; bA.TextColor3 = SAO_GREEN; bA.TextSize=24; Instance.new("UICorner", bA).CornerRadius = UDim.new(1,0); local sA = Instance.new("UIStroke", bA); sA.Color = SAO_GREEN; sA.Thickness=2
		local bD = Instance.new("TextButton", frame); bD.Size = UDim2.new(0, 50, 0, 50); bD.Position = UDim2.new(0.75, -25, 0.6, 0); bD.BackgroundColor3 = SAO_BG; bD.Text = "X"; bD.Font = Enum.Font.GothamBlack; bD.TextColor3 = SAO_RED; bD.TextSize=24; Instance.new("UICorner", bD).CornerRadius = UDim.new(1,0); local sD = Instance.new("UIStroke", bD); sD.Color = SAO_RED; sD.Thickness=2

		bA.MouseEnter:Connect(function() TweenService:Create(bA, TweenInfo.new(0.2), {BackgroundColor3 = SAO_GREEN, TextColor3 = Color3.new(1,1,1)}):Play() end)
		bA.MouseLeave:Connect(function() TweenService:Create(bA, TweenInfo.new(0.2), {BackgroundColor3 = SAO_BG, TextColor3 = SAO_GREEN}):Play() end)

		bD.MouseEnter:Connect(function() TweenService:Create(bD, TweenInfo.new(0.2), {BackgroundColor3 = SAO_RED, TextColor3 = Color3.new(1,1,1)}):Play() end)
		bD.MouseLeave:Connect(function() TweenService:Create(bD, TweenInfo.new(0.2), {BackgroundColor3 = SAO_BG, TextColor3 = SAO_RED}):Play() end)

		local function destroyInvite()
			TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 130), GroupTransparency = 1}):Play()
			task.wait(0.2); sg:Destroy()
		end

		bA.MouseButton1Click:Connect(function() sfxClick:Play(); SocialEvent:FireServer("Accept"..type, inviter); destroyInvite() end)
		bD.MouseButton1Click:Connect(function() sfxClick:Play(); SocialEvent:FireServer("Decline"..type, inviter); destroyInvite() end)
		task.delay(10, function() if sg and sg.Parent then destroyInvite() end end)

		-- EVENTOS DE TRADEO Y DUELO DIRECTOS
	elseif action == "StartDuel" then
		local opponent = data1
		IniciarSecuenciaDuelo(opponent)

	elseif action == "StartTrade" then
		local partner = data1
		AbrirVentanaTradeo(partner)

	elseif action == "CloseTrade" then
		if player.PlayerGui:FindFirstChild("SAO_TradeWindow") then
			player.PlayerGui.SAO_TradeWindow:Destroy()
		end

		-- ACTUALIZAR HUD DEL GRUPO (Estilo Auténtico SAO)
	elseif action == "UpdateSocialUI" and data1 == "Party" then
		local partyList = data2

		for _, conn in ipairs(partyConnections) do conn:Disconnect() end
		table.clear(partyConnections)
		if currentPartyUI then currentPartyUI:Destroy() end

		if #partyList <= 0 then return end

		currentPartyUI = Instance.new("ScreenGui", player:WaitForChild("PlayerGui")); currentPartyUI.Name = "SAO_PartyHUD"
		local container = Instance.new("Frame", currentPartyUI); container.Size = UDim2.new(0, 200, 1, 0); container.Position = UDim2.new(0, 20, 0.25, 0); container.BackgroundTransparency = 1
		local listLayout = Instance.new("UIListLayout", container); listLayout.Padding = UDim.new(0, 15)

		for _, member in ipairs(partyList) do
			if member ~= player then 
				local pFrame = Instance.new("Frame", container); pFrame.Size = UDim2.new(1, 0, 0, 45); pFrame.BackgroundTransparency = 1

				local lvl = member:GetAttribute("Level") or 1
				local nameLbl = Instance.new("TextLabel", pFrame); nameLbl.Size = UDim2.new(1, 0, 0, 15); nameLbl.BackgroundTransparency = 1; nameLbl.Text = "Lv." .. lvl .. "  " .. member.Name; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 13; nameLbl.TextColor3 = Color3.new(1,1,1); nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextStrokeTransparency = 0.5

				local barBG = Instance.new("Frame", pFrame); barBG.Size = UDim2.new(1, 0, 0, 12); barBG.Position = UDim2.new(0, 0, 0, 20); barBG.BackgroundColor3 = Color3.fromRGB(20, 20, 25); barBG.BackgroundTransparency = 0.3; Instance.new("UICorner", barBG).CornerRadius = UDim.new(0, 2)
				local stroke = Instance.new("UIStroke", barBG); stroke.Color = Color3.fromRGB(150, 150, 160); stroke.Thickness = 1

				local barFill = Instance.new("Frame", barBG); barFill.Size = UDim2.new(1, 0, 1, 0); barFill.BackgroundColor3 = SAO_GREEN; Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 2)

				local hpText = Instance.new("TextLabel", barBG); hpText.Size = UDim2.new(1, -5, 1, 0); hpText.BackgroundTransparency = 1; hpText.Text = "HP"; hpText.Font = Enum.Font.GothamBold; hpText.TextSize = 10; hpText.TextColor3 = Color3.new(1,1,1); hpText.TextXAlignment = Enum.TextXAlignment.Right; hpText.TextStrokeTransparency = 0.5; hpText.ZIndex = 2

				local function updateHealth()
					local char = member.Character
					local hum = char and char:FindFirstChild("Humanoid")
					if hum then
						local maxHp = member:GetAttribute("MaxHP") or hum.MaxHealth
						local hpPercent = math.clamp(hum.Health / maxHp, 0, 1)
						TweenService:Create(barFill, TweenInfo.new(0.25), {Size = UDim2.new(hpPercent, 0, 1, 0)}):Play()

						if hpPercent <= 0.25 then barFill.BackgroundColor3 = SAO_RED
						elseif hpPercent <= 0.5 then barFill.BackgroundColor3 = SAO_ORANGE
						else barFill.BackgroundColor3 = SAO_GREEN end
					end
				end

				if member.Character and member.Character:FindFirstChild("Humanoid") then
					updateHealth()
					local conn = member.Character.Humanoid.HealthChanged:Connect(updateHealth)
					table.insert(partyConnections, conn)
				end

				local respawnConn = member.CharacterAdded:Connect(function(newChar)
					task.wait(0.5)
					updateHealth()
					local conn = newChar:WaitForChild("Humanoid").HealthChanged:Connect(updateHealth)
					table.insert(partyConnections, conn)
				end)
				table.insert(partyConnections, respawnConn)
			end
		end
	end
end)
