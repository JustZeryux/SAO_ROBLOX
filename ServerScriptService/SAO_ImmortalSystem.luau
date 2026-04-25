local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

-- ==========================================
-- 🔮 GENERADOR DEL PANEL "IMMORTAL OBJECT"
-- ==========================================
local function SpawnImmortalPanel(posicion)
	local panelBase = Instance.new("Part")
	panelBase.Size = Vector3.new(0.1, 0.1, 0.1)
	panelBase.Position = posicion + Vector3.new(0, 1, 0)
	panelBase.Anchored = true
	panelBase.CanCollide = false
	panelBase.Transparency = 1
	panelBase.Parent = Workspace

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(5, 0, 1.2, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 100
	bg.Parent = panelBase

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(130, 30, 200)
	frame.BackgroundTransparency = 0.2
	frame.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "IMMORTAL OBJECT"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.SciFi
	textLabel.TextScaled = true
	textLabel.Parent = frame

	local tweenFlotar = TweenService:Create(panelBase, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = panelBase.Position + Vector3.new(0, 2.5, 0)
	})
	local tweenDesaparecer = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1
	})
	local textDesaparecer = TweenService:Create(textLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1
	})
	local strokeDesaparecer = TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Transparency = 1
	})

	tweenFlotar:Play()

	task.delay(1, function()
		tweenDesaparecer:Play()
		textDesaparecer:Play()
		strokeDesaparecer:Play()
	end)

	Debris:AddItem(panelBase, 2)
end

-- ==========================================
-- 🛡️ SISTEMA DE DETECCIÓN (NPCS Y ESTRUCTURAS)
-- ==========================================
local hitCooldowns = {}

local function ConectarGolpes(objeto, partesArray)
	for _, parte in ipairs(partesArray) do
		parte.Touched:Connect(function(hit)
			if hitCooldowns[objeto] then return end

			-- Detecta si lo que golpeó fue una espada (Tool) o el Handle
			if hit.Parent:IsA("Tool") or hit.Name == "Handle" then
				hitCooldowns[objeto] = true

				-- Genera el panel exactamente donde la espada tocó la estructura
				SpawnImmortalPanel(hit.Position)

				task.delay(1, function()
					hitCooldowns[objeto] = nil
				end)
			end
		end)
	end
end

local function RegistrarInmortal(objeto)
	-- 1. CASO NPC: Tiene Humanoid y vida infinita
	local humanoid = objeto:FindFirstChildWhichIsA("Humanoid")
	if humanoid and humanoid.MaxHealth == math.huge then
		humanoid.Health = math.huge
		local partesNPC = {}
		for _, p in pairs(objeto:GetDescendants()) do
			if p:IsA("BasePart") then table.insert(partesNPC, p) end
		end
		ConectarGolpes(objeto, partesNPC)

		-- Forzamos a que su vida no baje
		humanoid.HealthChanged:Connect(function()
			if humanoid.Health < math.huge then humanoid.Health = math.huge end
		end)
		return -- Terminamos con este objeto
	end

	-- 2. CASO ESTRUCTURA: No tiene Humanoid, pero tiene el Atributo "IsImmortal"
	if objeto:GetAttribute("IsImmortal") == true then
		local partesEstructura = {}
		if objeto:IsA("BasePart") then
			table.insert(partesEstructura, objeto)
		else
			for _, p in pairs(objeto:GetDescendants()) do
				if p:IsA("BasePart") then table.insert(partesEstructura, p) end
			end
		end
		ConectarGolpes(objeto, partesEstructura)
	end
end

-- Escanear todo el mapa al inicio
for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("Model") or obj:IsA("BasePart") then
		RegistrarInmortal(obj)
	end
end

-- Escuchar si metes algo nuevo al mapa durante el juego
Workspace.DescendantAdded:Connect(function(obj)
	task.wait(0.1)
	if obj:IsA("Model") or obj:IsA("BasePart") then
		RegistrarInmortal(obj)
	end
end)
