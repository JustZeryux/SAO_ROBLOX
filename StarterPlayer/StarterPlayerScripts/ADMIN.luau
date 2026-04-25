local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local AdminPanelEvent = SAO_Events:WaitForChild("AdminPanelEvent")
local GlobalAlertEvent = SAO_Events:WaitForChild("GlobalAlertEvent")

local panelAbierto = false

-- ==========================================
-- 📖 DICCIONARIO DE COMANDOS (Español / Inglés)
-- ==========================================
local commandList = {
	"📢 Anuncio Global: system call announce [msg] | llamado al sistema anuncio [msg]",
	"🗡️ Dar Item: system call add [item] | llamado al sistema dar [item]",
	"🐉 Invocar Mob: system call summon [mob] | llamado al sistema invocar [mob]",
	"✨ Desbloquear Skills: system call unlock skills | llamado al sistema desbloquear habilidades",
	"👢 Expulsar: system call kick [jugador] | llamado al sistema expulsar [jugador]",
	"☠️ Matar: system call kill [jugador] | llamado al sistema matar [jugador]",
	"⏰ Hora: system call time [numero] | llamado al sistema tiempo [numero]",
	"❤️ Modificar HP: system call set hp [num] | llamado al sistema set vida [num]",
	"🌟 Modificar Nivel: system call set level [num] | llamado al sistema set nivel [num]",
	"🏥 Curar 100%: system call heal | llamado al sistema curar",
	"🏃‍♂️ Velocidad: system call speed [num] | llamado al sistema velocidad [num]",
	"🛡️ Modo Dios: system call god | llamado al sistema inmortal"
}

-- ==========================================
-- 🪟 GENERADOR DEL PANEL DE AYUDA SAO
-- ==========================================
local function toggleAdminPanel()
	if panelAbierto then
		local gui = player.PlayerGui:FindFirstChild("AdminHelpPanel")
		if gui then gui:Destroy() end
		panelAbierto = false
		return
	end

	panelAbierto = true

	local gui = Instance.new("ScreenGui", player.PlayerGui)
	gui.Name = "AdminHelpPanel"

	local bg = Instance.new("Frame", gui)
	bg.Size = UDim2.new(0, 500, 0, 400)
	bg.Position = UDim2.new(0.5, 0, 0.5, 0)
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	bg.BackgroundTransparency = 0.1
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", bg)
	stroke.Color = Color3.fromRGB(200, 50, 255) -- Morado de Admin
	stroke.Thickness = 2

	local title = Instance.new("TextLabel", bg)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "SYSTEM COMMAND DIRECTORY"
	title.TextColor3 = Color3.fromRGB(200, 50, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18

	local scroll = Instance.new("ScrollingFrame", bg)
	scroll.Size = UDim2.new(1, -20, 1, -60)
	scroll.Position = UDim2.new(0, 10, 0, 50)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 255)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, 5)

	for _, cmd in ipairs(commandList) do
		local t = Instance.new("TextLabel", scroll)
		t.Size = UDim2.new(1, -10, 0, 30)
		t.BackgroundTransparency = 1
		t.Text = " " .. cmd
		t.TextColor3 = Color3.fromRGB(220, 220, 220)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Font = Enum.Font.GothamMedium
		t.TextSize = 13
		t.TextWrapped = true
	end
end

-- ==========================================
-- 📢 SISTEMA DE ANUNCIOS GLOBALES (Pantalla Completa)
-- ==========================================
GlobalAlertEvent.OnClientEvent:Connect(function(titulo, mensaje)
	local gui = Instance.new("ScreenGui", player.PlayerGui)

	local f = Instance.new("Frame", gui)
	f.Size = UDim2.new(1, 0, 0, 150)
	f.Position = UDim2.new(0.5, 0, 0.3, 0)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
	f.BackgroundTransparency = 0.2

	local t = Instance.new("TextLabel", f)
	t.Size = UDim2.new(1, 0, 0, 60)
	t.BackgroundTransparency = 1
	t.Text = "⚠️ " .. titulo .. " ⚠️"
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 40

	local d = Instance.new("TextLabel", f)
	d.Size = UDim2.new(1, 0, 0, 50)
	d.Position = UDim2.new(0, 0, 0, 60)
	d.BackgroundTransparency = 1
	d.Text = mensaje
	d.TextColor3 = Color3.new(1, 1, 1)
	d.Font = Enum.Font.GothamBold
	d.TextSize = 24

	-- Efecto de parpadeo SAO
	for i = 1, 6 do
		f.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		task.wait(0.1)
		f.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		task.wait(0.1)
	end

	task.wait(4)
	TweenService:Create(f, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(t, TweenInfo.new(1), {TextTransparency = 1}):Play()
	TweenService:Create(d, TweenInfo.new(1), {TextTransparency = 1}):Play()
	task.wait(1)
	gui:Destroy()
end)

-- Detectar la tecla 'H'
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.H then
		AdminPanelEvent:FireServer() -- Pedimos permiso al servidor
	end
end)

-- Si el servidor dice "Sí, eres admin", lo abrimos
AdminPanelEvent.OnClientEvent:Connect(function()
	toggleAdminPanel()
end)
