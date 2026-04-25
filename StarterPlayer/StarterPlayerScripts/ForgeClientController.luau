local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local ForgeSystem = ReplicatedStorage:WaitForChild("ForgeSystem")
local EventoAbrirMenu = ForgeSystem:WaitForChild("AbrirMenuForja")
local EventoAccion = ForgeSystem:WaitForChild("AccionForja")

local enModoForja = false
local yunqueActual = nil
local originalCameraCFrame = nil
local guiMaestra = nil
local bloqueClient = nil

local golpesHechos = 0
local golpesMeta = 10

-- Sonidos Épicos
local sfxClang = Instance.new("Sound", workspace); sfxClang.SoundId = "rbxassetid://8141687884"; sfxClang.Volume = 1
local sfxStart = Instance.new("Sound", workspace); sfxStart.SoundId = "rbxassetid://6895079853"; sfxStart.Volume = 0.8; sfxStart.Pitch = 0.8
local sfxUI = Instance.new("Sound", workspace); sfxUI.SoundId = "rbxassetid://6114983058"; sfxUI.Volume = 0.5

-- ==========================================
-- 🎥 CAMERA SHAKE
-- ==========================================
local function CameraShake(intensidad)
	local startTime = os.clock()
	local duration = 0.2
	local originalShakeCFrame = camera.CFrame

	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed > duration or not enModoForja then
			connection:Disconnect() 
			return
		end
		local progreso = 1 - (elapsed / duration)
		local randomOffset = Vector3.new(
			math.random(-10, 10), 
			math.random(-10, 10), 
			math.random(-5, 5)
		) * 0.005 * progreso * intensidad

		camera.CFrame = originalShakeCFrame * CFrame.new(randomOffset)
	end)
end

-- ==========================================
-- ✨ EFECTO DE IMPACTO
-- ==========================================
local function EfectoImpacto(posicion)
	sfxClang:Play()

	if bloqueClient then
		local progresoMetal = golpesHechos / golpesMeta
		local colorCaliente = Color3.fromRGB(255, 60, 0)
		local colorFrio = Color3.fromRGB(80, 80, 90)
		local colorActual = colorCaliente:Lerp(colorFrio, progresoMetal)

		bloqueClient.Color = Color3.fromRGB(255, 255, 200)
		TweenService:Create(bloqueClient, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = colorActual}):Play()

		local sX = math.max(0.15, bloqueClient.Size.X - 0.08) 
		local sY = math.max(0.1, bloqueClient.Size.Y - 0.05)    
		local sZ = math.min(6, bloqueClient.Size.Z + 0.2)      
		TweenService:Create(bloqueClient, TweenInfo.new(0.15, Enum.EasingStyle.Bounce), {Size = Vector3.new(sX, sY, sZ)}):Play()
	end

	local att = Instance.new("Attachment", workspace.Terrain)
	att.Position = posicion

	local sparks = Instance.new("ParticleEmitter", att)
	sparks.Texture = "rbxassetid://7148566336"
	sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
	sparks.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 0))})
	sparks.Speed = NumberRange.new(20, 60)
	sparks.SpreadAngle = Vector2.new(60, 60)
	sparks.Lifetime = NumberRange.new(0.2, 0.5)
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.LightEmission = 1
	sparks.Rate = 0

	sparks:Emit(35)
	game.Debris:AddItem(att, 1)
end

-- ==========================================
-- 🎯 ZONAS DE GOLPE (CORREGIDO)
-- ==========================================
local function GenerarPuntoGolpe()
	-- FIX 1: Limpiar el aro viejo correctamente desde PlayerGui, no desde guiMaestra
	if player.PlayerGui:FindFirstChild("SAO_HitTarget") then
		player.PlayerGui.SAO_HitTarget:Destroy()
	end

	if not enModoForja then return end

	-- FIX 2: Validar si el bloque llegó correctamente desde el servidor
	if not bloqueClient then 
		warn("SISTEMA DE FORJA: No se puede generar el punto porque bloqueClient es nil. Revisa el task.wait() en el servidor.")
		return 
	end

	local randomX = math.random(-8, 8) * 0.1
	local randomZ = math.random(-8, 8) * 0.1

	local bg = Instance.new("BillboardGui")
	bg.Name = "SAO_HitTarget"
	bg.Adornee = bloqueClient
	bg.Size = UDim2.new(5, 0, 5, 0)
	bg.StudsOffset = Vector3.new(randomX, 0.5, randomZ)
	bg.AlwaysOnTop = true
	bg.LightInfluence = 0
	bg.Parent = player.PlayerGui

	local ring = Instance.new("Frame", bg)
	ring.Size = UDim2.new(0, 0, 0, 0)
	ring.Position = UDim2.new(0.5, 0, 0.5, 0)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	ring.BackgroundTransparency = 0.5
	ring.ZIndex = 1 -- Para que quede detrás del botón
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", ring)
	stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Thickness = 3

	local btnTap = Instance.new("TextButton", bg)
	btnTap.Size = UDim2.new(1.5, 0, 1.5, 0)
	btnTap.Position = UDim2.new(-0.25, 0, -0.25, 0)
	btnTap.BackgroundTransparency = 1
	btnTap.Text = ""
	btnTap.Active = true
	btnTap.ZIndex = 10 -- FIX 3: Garantiza que absorba el click por encima del aro visual

	TweenService:Create(ring, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.6, 0, 0.6, 0)}):Play()

	btnTap.MouseButton1Click:Connect(function()
		if not enModoForja then return end
		btnTap.Active = false 
		bg:Destroy() 

		CameraShake(12)
		EventoAccion:FireServer("Golpear")
		EfectoImpacto(bloqueClient.Position + Vector3.new(randomX, 0.5, randomZ))

		golpesHechos += 1

		if guiMaestra and guiMaestra:FindFirstChild("HitCounter") then
			guiMaestra.HitCounter.Text = "STRIKES: " .. golpesHechos .. " / " .. golpesMeta
			guiMaestra.HitCounter.TextColor3 = Color3.fromRGB(255, 200, 0)
			TweenService:Create(guiMaestra.HitCounter, TweenInfo.new(0.2), {TextColor3 = Color3.new(1,1,1)}):Play()
		end

		if golpesHechos < golpesMeta then
			GenerarPuntoGolpe() 
		end
	end)
end

-- ==========================================
-- 🎨 INTERFAZ Y CINEMÁTICA
-- ==========================================
local function MostrarMenu()
	if guiMaestra then guiMaestra:Destroy() end
	guiMaestra = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	guiMaestra.Name = "SAO_ForgeMenu"
	guiMaestra.IgnoreGuiInset = true

	local screenDim = Instance.new("Frame", guiMaestra)
	screenDim.Size = UDim2.new(1, 0, 1, 0)
	screenDim.BackgroundColor3 = Color3.new(0, 0, 0)
	screenDim.BackgroundTransparency = 1
	screenDim.Active = false -- Asegura que no bloquee clicks al fondo 3D

	TweenService:Create(screenDim, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()

	local panel = Instance.new("Frame", guiMaestra)
	panel.Size = UDim2.new(0, 450, 0, 250)
	panel.Position = UDim2.new(0.5, -225, 0.5, 500)
	panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	panel.BackgroundTransparency = 0.2
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(0, 200, 255); stroke.Thickness = 2

	TweenService:Create(panel, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -225, 0.5, -125)}):Play()

	local titulo = Instance.new("TextLabel", panel)
	titulo.Size = UDim2.new(1, 0, 0, 60)
	titulo.Text = "FORGE SYSTEM"
	titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
	titulo.Font = Enum.Font.Oswald; titulo.TextSize = 35; titulo.BackgroundTransparency = 1
	local tituloStroke = Instance.new("UIStroke", titulo); tituloStroke.Color = Color3.fromRGB(0, 200, 255); tituloStroke.Thickness = 1

	local btnCerrar = Instance.new("TextButton", panel)
	btnCerrar.Size = UDim2.new(0, 40, 0, 40); btnCerrar.Position = UDim2.new(1, -45, 0, 10)
	btnCerrar.Text = "X"; btnCerrar.Font = Enum.Font.GothamBold; btnCerrar.TextSize = 20
	btnCerrar.BackgroundTransparency = 1; btnCerrar.TextColor3 = Color3.fromRGB(255, 80, 80)

	btnCerrar.MouseButton1Click:Connect(function()
		sfxUI:Play()
		TweenService:Create(panel, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -225, 0.5, 500)}):Play()
		TweenService:Create(screenDim, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		task.delay(0.3, function() guiMaestra:Destroy(); enModoForja = false end)
		EventoAccion:FireServer("Cancelar")
	end)

	local btnComenzar = Instance.new("TextButton", panel)
	btnComenzar.Size = UDim2.new(0.7, 0, 0, 55); btnComenzar.Position = UDim2.new(0.15, 0, 0.6, 0)
	btnComenzar.Text = "INITIATE CRAFTING"; btnComenzar.Font = Enum.Font.GothamBold; btnComenzar.TextSize = 22
	btnComenzar.BackgroundColor3 = Color3.fromRGB(0, 150, 255); btnComenzar.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", btnComenzar).CornerRadius = UDim.new(0, 6)

	btnComenzar.MouseButton1Click:Connect(function()
		sfxStart:Play()
		panel:Destroy() 

		-- 👇 ESTA ES LA LÍNEA CLAVE QUE FALTABA 👇
		screenDim:Destroy() 

		enModoForja = true
		originalCameraCFrame = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable

		local posYunque = yunqueActual.Position
		camera.CFrame = CFrame.lookAt(posYunque + Vector3.new(8, 6, 8), posYunque)
		local metaCamara = CFrame.lookAt(posYunque + Vector3.new(0, 5, 4), posYunque)

		TweenService:Create(camera, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {CFrame = metaCamara}):Play()

		local contadorUI = Instance.new("TextLabel", guiMaestra)
		contadorUI.Name = "HitCounter"
		contadorUI.Size = UDim2.new(1, 0, 0, 80); contadorUI.Position = UDim2.new(0, 0, 0.8, 0)
		contadorUI.Text = "STRIKES: 0 / ?"; contadorUI.Font = Enum.Font.Oswald; contadorUI.TextSize = 40
		contadorUI.TextColor3 = Color3.new(1, 1, 1); contadorUI.BackgroundTransparency = 1
		local str = Instance.new("UIStroke", contadorUI); str.Thickness = 2.5

		EventoAccion:FireServer("EmpezarMinijuego", {"Hierro", "Esencia Abisal"})
	end)
end

-- ==========================================
-- 🔌 CONEXIONES DEL SERVIDOR
-- ==========================================
EventoAbrirMenu.OnClientEvent:Connect(function(yunqueEnviado)
	if enModoForja then return end
	yunqueActual = yunqueEnviado
	MostrarMenu()
end)

EventoAccion.OnClientEvent:Connect(function(comando, param1, param2)
	print("Recibido comando del server:", comando) -- Para depuración

	if comando == "IniciarMinijuego3D" then
		bloqueClient = param1

		if bloqueClient then 
			bloqueClient.Color = Color3.fromRGB(255, 60, 0)
			bloqueClient.Material = Enum.Material.Neon 
		else
			warn("ERROR: El servidor envió el evento IniciarMinijuego3D, pero param1 (bloqueClient) llegó como nil.")
		end

		golpesMeta = param2 or 10
		golpesHechos = 0

		if guiMaestra and guiMaestra:FindFirstChild("HitCounter") then
			guiMaestra.HitCounter.Text = "STRIKES: 0 / " .. golpesMeta
		end

		task.wait(1.5) 
		GenerarPuntoGolpe() 

	elseif comando == "Terminar" then
		enModoForja = false

		local flash = Instance.new("Frame", player.PlayerGui)
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		flash.BorderSizePixel = 0
		TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		task.delay(0.5, function() flash:Destroy() end)

		if guiMaestra then guiMaestra:Destroy() end
		if player.PlayerGui:FindFirstChild("SAO_HitTarget") then player.PlayerGui.SAO_HitTarget:Destroy() end

		bloqueClient = nil

		TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Cubic), {CFrame = originalCameraCFrame}):Play()
		task.wait(1)
		camera.CameraType = Enum.CameraType.Custom
	end
end)
