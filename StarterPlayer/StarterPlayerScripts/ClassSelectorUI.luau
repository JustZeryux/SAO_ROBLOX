local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ==========================================
-- 🔗 CONEXIÓN AL SERVIDOR
-- ==========================================
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events", 5)
local ChooseClassEvent = SAO_Events:WaitForChild("ChooseClassEvent", 5)

-- ==========================================
-- 🔊 SISTEMA DE AUDIO (SFX)
-- ==========================================
local SFX = {
	Hover = "rbxassetid://6069724108",    -- Click ligero de menú
	Select = "rbxassetid://6895056262",   -- Tono tecnológico SAO
	Confirm = "rbxassetid://2868155854",  -- Sonido de advertencia/cuestionamiento
	Success = "rbxassetid://2868156158",  -- "Link Start" / Éxito
}

local function playSound(id, vol, pitch)
	local sound = Instance.new("Sound", workspace)
	sound.SoundId = id
	sound.Volume = vol or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound:Play()
	game.Debris:AddItem(sound, 2)
end

-- ==========================================
-- 📜 DATOS ULTRA MEJORADOS DE CLASES
-- ==========================================
local infoClases = {
	["Asesino"] = {
		Rol = "🗡️ DPS Físico / Sigilo",
		Desc = "Especialistas en la sombra y ataques letales. Sus dagas con veneno debilitan a los enemigos antes de dar el golpe final. Prefieren evitar el daño a resistirlo.",
		Stats = "🔥 STR: +5\n💨 AGI: +15\n👻 SIG: +25",
		Velocidad = "Rápida (18)",
		Color = Color3.fromRGB(155, 89, 182) -- Morado
	},
	["Tanque"] = {
		Rol = "🛡️ Primera Línea / Defensa",
		Desc = "La muralla inquebrantable de la party. Sacrifican movilidad para proteger a sus aliados, absorbiendo cantidades masivas de daño frontal.",
		Stats = "❤️ HP: +150\n🔥 STR: +20\n👻 SIG: 0",
		Velocidad = "Lenta (12)",
		Color = Color3.fromRGB(52, 152, 219) -- Azul
	},
	["Espadachin"] = {
		Rol = "⚔️ DPS Físico / Balanceado",
		Desc = "El núcleo de cualquier equipo de asalto. Manejan espadas rápidas y ofrecen un equilibrio perfecto entre ataque, defensa y agilidad.",
		Stats = "❤️ HP: +50\n🔥 STR: +15\n💨 AGI: +10",
		Velocidad = "Normal (16)",
		Color = Color3.fromRGB(46, 204, 113) -- Verde
	},
	["Herrero"] = {
		Rol = "⚒️ Soporte / Creación",
		Desc = "Maestros del martillo y el yunque. Vitales para forjar el mejor equipamiento del juego. En combate, sus golpes son lentos pero contundentes.",
		Stats = "🔥 STR: +5\n💨 AGI: +5\n🛠️ CRAFTING: Alto",
		Velocidad = "Normal (16)",
		Color = Color3.fromRGB(230, 126, 34) -- Naranja
	},
	["Domador"] = {
		Rol = "🐾 Soporte / Control",
		Desc = "Tienen una conexión profunda con la naturaleza. Pueden domar bestias y monstruos de nivel inferior para que peleen a su lado y reciban el daño.",
		Stats = "❤️ HP: +30\n💨 AGI: +5\n👻 SIG: +10",
		Velocidad = "Normal (16)",
		Color = Color3.fromRGB(26, 188, 156) -- Turquesa
	},
	["Esgrimidor Ligero"] = {
		Rol = "⚡ DPS Físico / Velocidad",
		Desc = "Usuarios de estoques (Rapier). Su velocidad de ataque no tiene rival y pueden penetrar armaduras, pero un mal cálculo los dejará vulnerables.",
		Stats = "🔥 STR: +10\n💨 AGI: +20\n👻 SIG: +5",
		Velocidad = "Muy Rápida (18)",
		Color = Color3.fromRGB(241, 196, 15) -- Amarillo
	},
	["Lancero"] = {	
		Rol = "🔱 DPS Físico / Distancia Media",
		Desc = "Especialistas en control de áreas. Mantienen a raya a múltiples enemigos al mismo tiempo, atacando desde una distancia segura sin perder letalidad.",
		Stats = "❤️ HP: +50\n🔥 STR: +15\n💨 AGI: +10",
		Velocidad = "Normal (16)",
		Color = Color3.fromRGB(52, 73, 94) -- Gris Azulado
	},
	["Guerrero Pesado"] = {
		Rol = "🪓 DPS Físico / Rompedor",
		Desc = "Utilizan hachas gigantes y mazos de asedio. Su daño por impacto es devastador y rompen las defensas de los jefes, pero quedan expuestos entre ataques.",
		Stats = "❤️ HP: +150\n🔥 STR: +20\n👻 SIG: 0",
		Velocidad = "Lenta (12)",
		Color = Color3.fromRGB(192, 57, 43) -- Rojo Oscuro
	},
	["Comerciante"] = {
		Rol = "💰 Soporte / Economía",
		Desc = "El motor económico del juego. Tienen la habilidad de tasación para ver atributos ocultos y dominar los mercados entre jugadores.",
		Stats = "🔥 STR: +5\n💨 AGI: +5\n👁️ TASACIÓN: Alta",
		Velocidad = "Normal (16)",
		Color = Color3.fromRGB(211, 84, 0) -- Naranja Oscuro
	}
}

-- ==========================================
-- 🎨 TEMA UI (Estilo Cyberpunk/SAO)
-- ==========================================
local THEME = {
	Background = Color3.fromRGB(10, 10, 15),
	PanelInfo = Color3.fromRGB(18, 18, 24),
	Borders = Color3.fromRGB(0, 170, 255),
	BorderGlow = Color3.fromRGB(0, 255, 255),
	TextWhite = Color3.fromRGB(240, 240, 240),
	TextMuted = Color3.fromRGB(150, 150, 160),
	BtnIdle = Color3.fromRGB(25, 25, 35),
	BtnHover = Color3.fromRGB(40, 40, 55),
	ConfirmReady = Color3.fromRGB(255, 140, 0),
	WarningRed = Color3.fromRGB(220, 50, 50)
}

local function tweenObj(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

-- ==========================================
-- 🖥️ GENERACIÓN DE LA INTERFAZ
-- ==========================================
local function abrirMenuClases()
	-- VALIDACIÓN DE SEGURIDAD
	local miClase = player:GetAttribute("Class")
	if miClase and miClase ~= "Novato" then return end
	if player.PlayerGui:FindFirstChild("ClassSelectionGUI") then return end

	-- 1. EFECTO DE DESENFOQUE (BLUR)
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting
	tweenObj(blur, {Size = 24}, 0.5)

	-- 2. GUI BASE
	local gui = Instance.new("ScreenGui")
	gui.Name = "ClassSelectionGUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local fondoVignette = Instance.new("Frame")
	fondoVignette.Size = UDim2.new(1, 0, 1, 0)
	fondoVignette.BackgroundColor3 = Color3.new(0, 0, 0)
	fondoVignette.BackgroundTransparency = 1
	fondoVignette.Parent = gui
	tweenObj(fondoVignette, {BackgroundTransparency = 0.4}, 0.5)

	-- 3. PANEL PRINCIPAL
	local mainPanel = Instance.new("Frame")
	mainPanel.Size = UDim2.new(0, 750, 0, 500)
	mainPanel.Position = UDim2.new(0.5, 0, 0.45, 0) -- Ligeramente más arriba por la perspectiva
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = THEME.Background
	mainPanel.BackgroundTransparency = 1
	mainPanel.ClipsDescendants = false
	Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 16)

	local mainStroke = Instance.new("UIStroke", mainPanel)
	mainStroke.Color = THEME.Borders
	mainStroke.Thickness = 1.5
	mainStroke.Transparency = 1
	mainPanel.Parent = fondoVignette

	-- Animación de entrada
	mainPanel.Position = UDim2.new(0.5, 0, 0.55, 0)
	tweenObj(mainPanel, {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.05}, 0.6)
	tweenObj(mainStroke, {Transparency = 0.2}, 0.6)

	-- 4. TITULO
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 70)
	header.BackgroundTransparency = 1
	header.Parent = mainPanel

	local titulo = Instance.new("TextLabel")
	titulo.Size = UDim2.new(1, 0, 1, 0)
	titulo.BackgroundTransparency = 1
	titulo.Text = "SELECCIONA TU DESTINO"
	titulo.TextColor3 = THEME.Borders
	titulo.Font = Enum.Font.GothamBlack
	titulo.TextSize = 26
	titulo.Parent = header

	local subtitulo = Instance.new("TextLabel", header)
	subtitulo.Size = UDim2.new(1, 0, 0, 20)
	subtitulo.Position = UDim2.new(0, 0, 0, 45)
	subtitulo.BackgroundTransparency = 1
	subtitulo.Text = "Tu elección de clase definirá tus habilidades futuras."
	subtitulo.TextColor3 = THEME.TextMuted
	subtitulo.Font = Enum.Font.GothamMedium
	subtitulo.TextSize = 13

	-- 5. LISTA DE CLASES (IZQUIERDA)
	local listaBotones = Instance.new("ScrollingFrame")
	listaBotones.Size = UDim2.new(0, 240, 0, 400)
	listaBotones.Position = UDim2.new(0, 25, 0, 75)
	listaBotones.BackgroundTransparency = 1
	listaBotones.ScrollBarThickness = 2
	listaBotones.ScrollBarImageColor3 = THEME.Borders
	listaBotones.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listaBotones.CanvasSize = UDim2.new(0, 0, 0, 0)
	listaBotones.Parent = mainPanel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listaBotones

	-- 6. PANEL DE INFORMACIÓN (DERECHA)
	local infoPanel = Instance.new("Frame")
	infoPanel.Size = UDim2.new(0, 430, 0, 330)
	infoPanel.Position = UDim2.new(0, 290, 0, 75)
	infoPanel.BackgroundColor3 = THEME.PanelInfo
	Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 10)
	local infoStroke = Instance.new("UIStroke", infoPanel)
	infoStroke.Color = Color3.fromRGB(40, 40, 50)
	infoPanel.Parent = mainPanel

	local lblClase = Instance.new("TextLabel")
	lblClase.Size = UDim2.new(1, -40, 0, 40)
	lblClase.Position = UDim2.new(0, 20, 0, 15)
	lblClase.BackgroundTransparency = 1
	lblClase.Text = "ESPERANDO SELECCIÓN..."
	lblClase.TextColor3 = THEME.TextWhite
	lblClase.Font = Enum.Font.GothamBlack
	lblClase.TextSize = 24
	lblClase.TextXAlignment = Enum.TextXAlignment.Left
	lblClase.Parent = infoPanel

	local lblRol = Instance.new("TextLabel")
	lblRol.Size = UDim2.new(1, -40, 0, 20)
	lblRol.Position = UDim2.new(0, 20, 0, 50)
	lblRol.BackgroundTransparency = 1
	lblRol.Text = ""
	lblRol.TextColor3 = THEME.TextMuted
	lblRol.Font = Enum.Font.GothamBold
	lblRol.TextSize = 14
	lblRol.TextXAlignment = Enum.TextXAlignment.Left
	lblRol.Parent = infoPanel

	local divLine = Instance.new("Frame")
	divLine.Size = UDim2.new(1, -40, 0, 1)
	divLine.Position = UDim2.new(0, 20, 0, 80)
	divLine.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	divLine.BorderSizePixel = 0
	divLine.Parent = infoPanel

	local lblDesc = Instance.new("TextLabel")
	lblDesc.Size = UDim2.new(1, -40, 0, 90)
	lblDesc.Position = UDim2.new(0, 20, 0, 95)
	lblDesc.BackgroundTransparency = 1
	lblDesc.Text = "Selecciona una clase del menú izquierdo para analizar sus ventajas tácticas."
	lblDesc.TextColor3 = THEME.TextWhite
	lblDesc.Font = Enum.Font.Gotham
	lblDesc.TextSize = 14
	lblDesc.TextWrapped = true
	lblDesc.TextYAlignment = Enum.TextYAlignment.Top
	lblDesc.TextXAlignment = Enum.TextXAlignment.Left
	lblDesc.Parent = infoPanel

	local panelStats = Instance.new("Frame")
	panelStats.Size = UDim2.new(1, -40, 0, 110)
	panelStats.Position = UDim2.new(0, 20, 0, 200)
	panelStats.BackgroundColor3 = THEME.Background
	Instance.new("UICorner", panelStats).CornerRadius = UDim.new(0, 6)
	panelStats.Parent = infoPanel

	local lblStats = Instance.new("TextLabel")
	lblStats.Size = UDim2.new(0.5, -20, 1, -20)
	lblStats.Position = UDim2.new(0, 15, 0, 10)
	lblStats.BackgroundTransparency = 1
	lblStats.Text = "ESTADÍSTICAS BASE\n---\n---\n---"
	lblStats.TextColor3 = THEME.Borders
	lblStats.Font = Enum.Font.Code
	lblStats.TextSize = 14
	lblStats.TextYAlignment = Enum.TextYAlignment.Top
	lblStats.TextXAlignment = Enum.TextXAlignment.Left
	lblStats.Parent = panelStats

	local lblVelocidad = Instance.new("TextLabel")
	lblVelocidad.Size = UDim2.new(0.5, -20, 1, -20)
	lblVelocidad.Position = UDim2.new(0.5, 5, 0, 10)
	lblVelocidad.BackgroundTransparency = 1
	lblVelocidad.Text = "MOVIMIENTO\n---\n\n"
	lblVelocidad.TextColor3 = THEME.TextMuted
	lblVelocidad.Font = Enum.Font.Code
	lblVelocidad.TextSize = 14
	lblVelocidad.TextYAlignment = Enum.TextYAlignment.Top
	lblVelocidad.TextXAlignment = Enum.TextXAlignment.Right
	lblVelocidad.Parent = panelStats

	-- 7. BOTÓN DE SELECCIÓN PRINCIPAL
	local btnConfirmar = Instance.new("TextButton")
	btnConfirmar.Size = UDim2.new(0, 430, 0, 55)
	btnConfirmar.Position = UDim2.new(0, 290, 0, 420)
	btnConfirmar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btnConfirmar.Text = "ESCANEO REQUERIDO"
	btnConfirmar.TextColor3 = Color3.fromRGB(100, 100, 100)
	btnConfirmar.Font = Enum.Font.GothamBlack
	btnConfirmar.TextSize = 18
	btnConfirmar.AutoButtonColor = false
	Instance.new("UICorner", btnConfirmar).CornerRadius = UDim.new(0, 8)
	local confirmStroke = Instance.new("UIStroke", btnConfirmar)
	confirmStroke.Color = Color3.fromRGB(50, 50, 50)
	btnConfirmar.Parent = mainPanel

	-- 8. VENTANA DE ADVERTENCIA (DOBLE CONFIRMACIÓN)
	local alertOverlay = Instance.new("Frame")
	alertOverlay.Size = UDim2.new(1, 0, 1, 0)
	alertOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	alertOverlay.BackgroundTransparency = 1
	alertOverlay.Visible = false
	alertOverlay.ZIndex = 10
	alertOverlay.Parent = mainPanel

	local alertBox = Instance.new("Frame")
	alertBox.Size = UDim2.new(0, 450, 0, 250)
	alertBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	alertBox.AnchorPoint = Vector2.new(0.5, 0.5)
	alertBox.BackgroundColor3 = Color3.fromRGB(20, 15, 15)
	alertBox.ZIndex = 11
	Instance.new("UICorner", alertBox).CornerRadius = UDim.new(0, 12)
	local alertStroke = Instance.new("UIStroke", alertBox)
	alertStroke.Color = THEME.WarningRed
	alertStroke.Thickness = 2
	alertBox.Parent = alertOverlay

	local alertTitle = Instance.new("TextLabel", alertBox)
	alertTitle.Size = UDim2.new(1, 0, 0, 60)
	alertTitle.BackgroundTransparency = 1
	alertTitle.Text = "⚠️ ADVERTENCIA DEL SISTEMA"
	alertTitle.TextColor3 = THEME.WarningRed
	alertTitle.Font = Enum.Font.GothamBlack
	alertTitle.TextSize = 22
	alertTitle.ZIndex = 12

	local alertDesc = Instance.new("TextLabel", alertBox)
	alertDesc.Size = UDim2.new(1, -40, 0, 80)
	alertDesc.Position = UDim2.new(0, 20, 0, 70)
	alertDesc.BackgroundTransparency = 1
	alertDesc.Text = "¿Estás completamente seguro?\nTu progreso como [Clase] será irreversible y definirá permanentemente tu estilo de combate."
	alertDesc.TextColor3 = THEME.TextWhite
	alertDesc.Font = Enum.Font.GothamMedium
	alertDesc.TextSize = 15
	alertDesc.TextWrapped = true
	alertDesc.ZIndex = 12

	local btnAlertYes = Instance.new("TextButton", alertBox)
	btnAlertYes.Size = UDim2.new(0, 180, 0, 50)
	btnAlertYes.Position = UDim2.new(0, 30, 0, 170)
	btnAlertYes.BackgroundColor3 = THEME.WarningRed
	btnAlertYes.Text = "ACEPTAR DESTINO"
	btnAlertYes.TextColor3 = Color3.new(1,1,1)
	btnAlertYes.Font = Enum.Font.GothamBold
	btnAlertYes.TextSize = 14
	btnAlertYes.ZIndex = 12
	Instance.new("UICorner", btnAlertYes).CornerRadius = UDim.new(0, 6)

	local btnAlertNo = Instance.new("TextButton", alertBox)
	btnAlertNo.Size = UDim2.new(0, 180, 0, 50)
	btnAlertNo.Position = UDim2.new(0, 240, 0, 170)
	btnAlertNo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btnAlertNo.Text = "CANCELAR"
	btnAlertNo.TextColor3 = THEME.TextWhite
	btnAlertNo.Font = Enum.Font.GothamBold
	btnAlertNo.TextSize = 14
	btnAlertNo.ZIndex = 12
	Instance.new("UICorner", btnAlertNo).CornerRadius = UDim.new(0, 6)

	-- ==========================================
	-- 🧠 LÓGICA DE INTERACCIÓN
	-- ==========================================
	local claseSeleccionada = nil
	local botonesUI = {}
	local typeWriterCoroutine = nil

	-- Efecto de Máquina de Escribir
	local function TypeText(label, text)
		if typeWriterCoroutine then coroutine.close(typeWriterCoroutine) end
		label.Text = ""
		typeWriterCoroutine = coroutine.create(function()
			for i = 1, #text do
				label.Text = string.sub(text, 1, i)
				RunService.RenderStepped:Wait()
			end
		end)
		coroutine.resume(typeWriterCoroutine)
	end

	-- Generar Lista de Clases
	for nombreClase, data in pairs(infoClases) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 55)
		btn.BackgroundColor3 = THEME.BtnIdle
		btn.Text = "  " .. nombreClase
		btn.TextColor3 = THEME.TextMuted
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 16
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.AutoButtonColor = false
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		local classIndicator = Instance.new("Frame", btn)
		classIndicator.Size = UDim2.new(0, 4, 1, -20)
		classIndicator.Position = UDim2.new(0, 10, 0, 10)
		classIndicator.BackgroundColor3 = data.Color
		classIndicator.BorderSizePixel = 0
		classIndicator.BackgroundTransparency = 0.7
		Instance.new("UICorner", classIndicator).CornerRadius = UDim.new(1, 0)

		btn.Text = "       " .. nombreClase -- Espacio para el indicador
		btn.Parent = listaBotones

		table.insert(botonesUI, {ui = btn, indicator = classIndicator, name = nombreClase})

		btn.MouseEnter:Connect(function()
			if claseSeleccionada ~= nombreClase then
				playSound(SFX.Hover, 0.2)
				tweenObj(btn, {BackgroundColor3 = THEME.BtnHover, TextColor3 = THEME.TextWhite}, 0.2)
			end
		end)

		btn.MouseLeave:Connect(function()
			if claseSeleccionada ~= nombreClase then
				tweenObj(btn, {BackgroundColor3 = THEME.BtnIdle, TextColor3 = THEME.TextMuted}, 0.2)
			end
		end)

		btn.MouseButton1Click:Connect(function()
			if claseSeleccionada == nombreClase then return end
			playSound(SFX.Select, 0.5, 1.2)
			claseSeleccionada = nombreClase

			-- Resetear botones
			for _, obj in ipairs(botonesUI) do
				tweenObj(obj.ui, {BackgroundColor3 = THEME.BtnIdle, TextColor3 = THEME.TextMuted})
				tweenObj(obj.indicator, {BackgroundTransparency = 0.7})
			end

			-- Activar botón actual
			tweenObj(btn, {BackgroundColor3 = THEME.BtnActive, TextColor3 = Color3.new(0,0,0)})
			tweenObj(classIndicator, {BackgroundTransparency = 0})

			-- Actualizar Información Panel Derecho
			lblClase.Text = nombreClase:upper()
			lblClase.TextColor3 = data.Color
			lblRol.Text = data.Rol

			lblStats.Text = "ESTADÍSTICAS BASE\n\n" .. data.Stats
			lblVelocidad.Text = "MOVIMIENTO\n\n⚡ " .. data.Velocidad

			TypeText(lblDesc, data.Desc)
			infoStroke.Color = data.Color

			-- Activar el Gran Botón de Confirmar
			btnConfirmar.Text = "ESTABLECER COMO CLASE PRINCIPAL"
			tweenObj(btnConfirmar, {BackgroundColor3 = THEME.ConfirmReady, TextColor3 = Color3.new(0,0,0)})
			tweenObj(confirmStroke, {Color = THEME.ConfirmReady})
		end)
	end

	-- Lógica Confirmar Principal (Abre el aviso rojo)
	btnConfirmar.MouseButton1Click:Connect(function()
		if claseSeleccionada then
			playSound(SFX.Confirm, 0.8)
			alertDesc.Text = "¿Estás completamente seguro?\nTu progreso como <font color='rgb(255,140,0)'><b>" .. claseSeleccionada:upper() .. "</b></font> será irreversible y definirá permanentemente tu estilo de combate."
			alertDesc.RichText = true

			alertOverlay.Visible = true
			tweenObj(alertOverlay, {BackgroundTransparency = 0.6})

			alertBox.Size = UDim2.new(0, 400, 0, 200)
			tweenObj(alertBox, {Size = UDim2.new(0, 450, 0, 250)}, 0.4)
		end
	end)

	-- Cancelar Alerta
	btnAlertNo.MouseButton1Click:Connect(function()
		playSound(SFX.Hover, 0.4)
		tweenObj(alertOverlay, {BackgroundTransparency = 1}, 0.2)
		task.wait(0.2)
		alertOverlay.Visible = false
	end)

	-- ACEPTAR FINAL
	btnAlertYes.MouseButton1Click:Connect(function()
		if claseSeleccionada then
			playSound(SFX.Success, 0.8, 0.9)

			-- 1. Enviar al Servidor
			ChooseClassEvent:FireServer(claseSeleccionada)

			-- 2. Secuencia Épica de Cierre
			btnAlertYes.Text = "ESTABLECIENDO CONEXIÓN..."
			btnAlertYes.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			task.wait(0.5)

			tweenObj(alertOverlay, {BackgroundTransparency = 1}, 0.3)
			tweenObj(fondoVignette, {BackgroundTransparency = 1}, 0.5)
			tweenObj(mainPanel, {Position = UDim2.new(0.5, 0, 0.6, 0), BackgroundTransparency = 1}, 0.5)
			tweenObj(blur, {Size = 0}, 0.8)

			task.wait(0.6)
			gui:Destroy()
			blur:Destroy()
		end
	end)
end

-- [TU CÓDIGO ACTUAL AL FINAL DEL SCRIPT DE CLASES]
-- (Borra el task.spawn y el task.wait que tenías aquí y pega esto:)

-- ==========================================
-- 🚀 INICIALIZACIÓN (Conectado al Creador de Avatar)
-- ==========================================
local SAO_Events = game:GetService("ReplicatedStorage"):WaitForChild("SAO_Events")

-- Mantenemos esto por si algún NPC o Admin te fuerza a abrir el menú desde el servidor
local ChooseClassEvent = SAO_Events:WaitForChild("ChooseClassEvent", 5)
ChooseClassEvent.OnClientEvent:Connect(function()
	abrirMenuClases()
end)

-- 🔥 [NUEVA CONEXIÓN] 🔥
-- Escuchamos en silencio hasta que el script del Avatar termine su trabajo
local OpenClassEvent = SAO_Events:FindFirstChild("OpenClassMenu") or Instance.new("BindableEvent", SAO_Events)
OpenClassEvent.Name = "OpenClassMenu"

OpenClassEvent.Event:Connect(function()
	local miClase = player:GetAttribute("Class")
	if miClase == "Novato" or miClase == nil then
		print("⚠️ Avatar creado. Abriendo menú de selección de clase...")
		abrirMenuClases()
	end
end)
