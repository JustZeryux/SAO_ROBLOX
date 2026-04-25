local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local remote = ReplicatedStorage:WaitForChild("RequestRespawn")

-- Sonido de glitch épico
local sfxGlitch = Instance.new("Sound", workspace)
sfxGlitch.SoundId = "rbxassetid://8742261623" -- Sonido digital de sistema roto
sfxGlitch.Volume = 1

local function showEpicDeathMenu()
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	sfxGlitch:Play()

	local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	gui.IgnoreGuiInset = true
	gui.Name = "SAO_EpicDeath"
	gui.DisplayOrder = 1000

	-- ==========================================
	-- 🌌 FONDO: VACÍO DIGITAL
	-- ==========================================
	local bg = Instance.new("Frame", gui)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(3, 5, 12) -- Azul ultra oscuro (Espacio)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0

	TweenService:Create(bg, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05}):Play()

	-- ==========================================
	-- 💻 DECORACIÓN: SISTEMA CORRUPTO (Para no verse vacío)
	-- ==========================================
	local sysText1 = Instance.new("TextLabel", bg)
	sysText1.Size = UDim2.new(0, 300, 0, 100)
	sysText1.Position = UDim2.new(0, 20, 0, 20)
	sysText1.BackgroundTransparency = 1
	sysText1.Text = "ERR_CONNECTION_LOST\nAVATAR_DATA: DESTROYED\nLINK: SEVERED\n\n> REBOOTING NEURAL NETWORK..."
	sysText1.TextColor3 = Color3.fromRGB(0, 255, 255)
	sysText1.Font = Enum.Font.Code
	sysText1.TextSize = 14
	sysText1.TextXAlignment = Enum.TextXAlignment.Left
	sysText1.TextYAlignment = Enum.TextYAlignment.Top
	sysText1.TextTransparency = 0.5

	-- Barras de Glitch horizontales que cruzan la pantalla
	local glitchBar = Instance.new("Frame", bg)
	glitchBar.Size = UDim2.new(1, 0, 0, 4)
	glitchBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glitchBar.BackgroundTransparency = 0.9
	glitchBar.BorderSizePixel = 0

	-- ==========================================
	-- 💀 TEXTO PRINCIPAL CON EFECTO RGB SPLIT (GLITCH)
	-- ==========================================
	local textContainer = Instance.new("Frame", bg)
	textContainer.Size = UDim2.new(1, 0, 0, 150)
	textContainer.Position = UDim2.new(0, 0, 0.35, 0)
	textContainer.BackgroundTransparency = 1

	-- Textos base
	local txtFormat = {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "YOU ARE DEAD", Font = Enum.Font.GothamBlack, TextSize = 110, TextTransparency = 1}

	-- Capa Cyan (Fondo Izquierda)
	local txtCyan = Instance.new("TextLabel", textContainer)
	for k, v in pairs(txtFormat) do txtCyan[k] = v end
	txtCyan.TextColor3 = Color3.fromRGB(0, 255, 255)
	txtCyan.ZIndex = 1

	-- Capa Magenta (Fondo Derecha)
	local txtMagenta = Instance.new("TextLabel", textContainer)
	for k, v in pairs(txtFormat) do txtMagenta[k] = v end
	txtMagenta.TextColor3 = Color3.fromRGB(255, 0, 80)
	txtMagenta.ZIndex = 1

	-- Capa Blanca (Frente)
	local txtWhite = Instance.new("TextLabel", textContainer)
	for k, v in pairs(txtFormat) do txtWhite[k] = v end
	txtWhite.TextColor3 = Color3.fromRGB(255, 255, 255)
	txtWhite.ZIndex = 2

	-- Animación de entrada dramática
	TweenService:Create(txtWhite, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
	TweenService:Create(txtCyan, TweenInfo.new(0.5), {TextTransparency = 0.3}):Play()
	TweenService:Create(txtMagenta, TweenInfo.new(0.5), {TextTransparency = 0.3}):Play()

	-- ==========================================
	-- 🔘 BOTÓN DE RESPAWN CENTRAL Y ÉPICO
	-- ==========================================
	local btnContainer = Instance.new("Frame", bg)
	btnContainer.Size = UDim2.new(0, 350, 0, 60)
	btnContainer.Position = UDim2.new(0.5, -175, 0.65, 0)
	btnContainer.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
	btnContainer.BackgroundTransparency = 1 -- Inicia invisible
	Instance.new("UICorner", btnContainer).CornerRadius = UDim.new(0, 4)

	local stroke = Instance.new("UIStroke", btnContainer)
	stroke.Color = Color3.fromRGB(0, 255, 255)
	stroke.Thickness = 2
	stroke.Transparency = 1

	local respawnBtn = Instance.new("TextButton", btnContainer)
	respawnBtn.Size = UDim2.new(1, 0, 1, 0)
	respawnBtn.BackgroundTransparency = 1
	respawnBtn.Text = "INITIATE REVIVAL"
	respawnBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
	respawnBtn.Font = Enum.Font.GothamBold
	respawnBtn.TextSize = 22
	respawnBtn.TextTransparency = 1

	-- Aparece el botón después de 1.5 segundos
	task.delay(1.5, function()
		TweenService:Create(btnContainer, TweenInfo.new(1), {BackgroundTransparency = 0.5}):Play()
		TweenService:Create(stroke, TweenInfo.new(1), {Transparency = 0.2}):Play()
		TweenService:Create(respawnBtn, TweenInfo.new(1), {TextTransparency = 0}):Play()
	end)

	-- Hover Effect del botón
	respawnBtn.MouseEnter:Connect(function()
		TweenService:Create(btnContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 255)}):Play()
		TweenService:Create(respawnBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(5, 5, 12)}):Play()
	end)
	respawnBtn.MouseLeave:Connect(function()
		TweenService:Create(btnContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(10, 15, 25)}):Play()
		TweenService:Create(respawnBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(0, 255, 255)}):Play()
	end)

	-- ==========================================
	-- 🌀 CÓDIGO DEL EFECTO GLITCH (EL MOTOR MAGICO)
	-- ==========================================
	local isDead = true
	local glitchConnection = RunService.RenderStepped:Connect(function()
		if not isDead then return end

		-- 1. Vibración extrema de los colores (Efecto Cromático)
		if math.random(1, 10) > 2 then
			txtCyan.Position = UDim2.new(0, math.random(-8, 8), 0, math.random(-3, 3))
			txtMagenta.Position = UDim2.new(0, math.random(-8, 8), 0, math.random(-3, 3))
			txtWhite.Position = UDim2.new(0, math.random(-2, 2), 0, math.random(-2, 2))
		else
			-- Pequeñas pausas para que se lea bien el texto
			txtCyan.Position = UDim2.new(0, 3, 0, 0)
			txtMagenta.Position = UDim2.new(0, -3, 0, 0)
			txtWhite.Position = UDim2.new(0, 0, 0, 0)
		end

		-- 2. Barra de estática bajando por la pantalla
		glitchBar.Position = UDim2.new(0, 0, math.random(0, 100)/100, 0)
		glitchBar.Size = UDim2.new(1, 0, 0, math.random(1, 10))

		-- 3. Parpadeo del texto decorativo
		sysText1.TextTransparency = math.random(40, 80) / 100
	end)

	-- ==========================================
	-- 🖱️ FUNCIÓN DE CLICK (REVIVIR)
	-- ==========================================
	respawnBtn.MouseButton1Click:Connect(function()
		isDead = false
		glitchConnection:Disconnect()

		-- Buscamos el primer spawn disponible, si no hay, enviamos nil (tu server lo debe manejar)
		local targetSpawn = nil
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("SpawnLocation") then
				targetSpawn = obj.Name
				break
			end
		end

		remote:FireServer(targetSpawn)

		-- Desvanecer épicamente
		local fade = TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		TweenService:Create(txtWhite, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(txtCyan, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(txtMagenta, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(btnContainer, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
		TweenService:Create(respawnBtn, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		sysText1:Destroy()
		glitchBar:Destroy()

		fade:Play()
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
		fade.Completed:Wait()
		gui:Destroy()
	end)
end

-- Conexiones
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(showEpicDeathMenu)
end)

if player.Character then
	player.Character:WaitForChild("Humanoid").Died:Connect(showEpicDeathMenu)
end
