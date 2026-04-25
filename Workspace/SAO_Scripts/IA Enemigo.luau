local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- NECESARIO PARA EL DIAMANTE 3D

local mob = script.Parent
local humanoid = mob:WaitForChild("Humanoid")
local rootPart = mob:WaitForChild("HumanoidRootPart")
local head = mob:WaitForChild("Head")
local animator = humanoid:WaitForChild("Animator")

-- ==========================================
-- ⚙️ CONFIGURACIÓN DEL MOB
-- ==========================================
local NOMBRE_MOB = "Lobo Nefasto"
local VIDA_MAXIMA = 200
local DANO_BASICO = 10
local RANGO_AGGRO = 80
local DISTANCIA_ATAQUE = 6
local COOLDOWN_ATAQUE = 1.5
local COLOR_CRISTAL = Color3.fromRGB(0, 255, 255)
-- COLORES DEL DIAMANTE DEL MOB:
local COLOR_MOB_NORMAL = Color3.fromRGB(255, 170, 0) -- Naranja clásico de SAO para mobs
local COLOR_MOB_AGRESIVO = Color3.fromRGB(255, 50, 50) -- Rojo si quieres hacerlo "PK" o Jefe

humanoid.MaxHealth = VIDA_MAXIMA
humanoid.Health = VIDA_MAXIMA
humanoid.WalkSpeed = 14

-- ✨ VARIABLES DE ESTADO CORREGIDAS
local isDead = false
local atacando = false

-- 🎬 CARGA DE ANIMACIÓN DE ATAQUE (Pon tu ID aquí)
local animAtaque = Instance.new("Animation")
animAtaque.AnimationId = "rbxassetid://0000000" -- <--- PON TU ID AQUÍ
local trackAtaque = animator:LoadAnimation(animAtaque)

-- ==========================================
-- 💎 CONFIGURACIÓN DEL DIAMANTE 3D
-- ==========================================
-- Buscamos tu modelo en ReplicatedStorage
local diamondPrefab = ReplicatedStorage:WaitForChild("SAO Diamond")
local diamond3D = diamondPrefab:Clone()
diamond3D.Name = "SAO_Diamond_3D"

-- Le quitamos anclajes y colisiones para que no afecte el movimiento del mob
diamond3D.Anchored = false
diamond3D.CanCollide = false
diamond3D.Massless = true
diamond3D.Parent = mob

-- Lo "soldamos" a la cabeza
local weld = Instance.new("Weld")
weld.Part0 = head
weld.Part1 = diamond3D
-- Altura sobre el mob (ajusta si el lobo es muy alto o bajo)
weld.C0 = CFrame.new(0, 3.0, 0) 
weld.Parent = diamond3D

-- Configuramos el color inicial del mob (Naranja)
diamond3D.Color = COLOR_MOB_NORMAL

-- ==========================================
-- 📊 INTERFAZ DE SAO (HOMOLOGADA)
-- ==========================================
local function crearUI()
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local bg = Instance.new("BillboardGui")
	bg.Name = "SAO_HUD"
	bg.Adornee = head
	-- Hicimos el BillboardGui más ancho para las barras largas de jefe/mob
	bg.Size = UDim2.new(4.5, 0, 1.5, 0)
	-- Desplazamos las barras hacia arriba para dejar espacio al diamante 3D
	bg.StudsOffset = Vector3.new(0, 5.0, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 150 
	bg.Parent = head

	-- 🔠 NOMBRE
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = NOMBRE_MOB
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.Jura
	nameLabel.TextScaled = true
	nameLabel.Parent = bg

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Thickness = 1
	nameStroke.Parent = nameLabel

	-- 📦 BARRAS
	local barsContainer = Instance.new("Frame")
	barsContainer.Size = UDim2.new(0.8, 0, 0.5, 0)
	barsContainer.Position = UDim2.new(0.1, 0, 0.5, 0)
	barsContainer.BackgroundTransparency = 1
	barsContainer.Parent = bg

	local capas = math.clamp(math.ceil(VIDA_MAXIMA / 100), 1, 5)
	local hpBars = {}

	for i = 1, capas do
		local bgBar = Instance.new("Frame")
		bgBar.Size = UDim2.new(1 - (i * 0.05), 0, 0, 6)
		bgBar.Position = UDim2.new((i * 0.025), 0, 0, (i - 1) * 6)
		bgBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		bgBar.BackgroundTransparency = 0.2
		bgBar.BorderSizePixel = 0

		local corner = Instance.new("UICorner", bgBar)
		corner.CornerRadius = UDim.new(0, 2)
		bgBar.Parent = barsContainer

		local fillBar = Instance.new("Frame")
		fillBar.Size = UDim2.new(1, 0, 1, 0)
		fillBar.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
		fillBar.BorderSizePixel = 0

		local fillCorner = Instance.new("UICorner", fillBar)
		fillCorner.CornerRadius = UDim.new(0, 2)
		fillBar.Parent = bgBar

		hpBars[i] = fillBar
	end

	humanoid.HealthChanged:Connect(function(health)
		-- Opcional: Cambiar el diamante a rojo si está muy lastimado (como señal de enojo)
		if health < (VIDA_MAXIMA * 0.3) then
			diamond3D.Color = COLOR_MOB_AGRESIVO
		else
			diamond3D.Color = COLOR_MOB_NORMAL
		end

		local hpPorBarra = VIDA_MAXIMA / capas
		for i = 1, capas do
			local barraMin = (capas - i) * hpPorBarra
			local barraMax = (capas - i + 1) * hpPorBarra
			if health >= barraMax then
				hpBars[i].Size = UDim2.new(1, 0, 1, 0)
				hpBars[i].BackgroundColor3 = Color3.fromRGB(85, 255, 127)
			elseif health <= barraMin then
				TweenService:Create(hpBars[i], TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 1, 0)}):Play()
			else
				local porcentaje = (health - barraMin) / hpPorBarra
				TweenService:Create(hpBars[i], TweenInfo.new(0.15), {Size = UDim2.new(porcentaje, 0, 1, 0)}):Play()

				if porcentaje < 0.25 then hpBars[i].BackgroundColor3 = Color3.fromRGB(255, 50, 50)
				elseif porcentaje < 0.5 then hpBars[i].BackgroundColor3 = Color3.fromRGB(255, 170, 0)
				else hpBars[i].BackgroundColor3 = Color3.fromRGB(85, 255, 127) end
			end
		end
	end)
end

crearUI()

-- ==========================================
-- 💀 MUERTE ESTILO SAO (Versión Ligera)
-- ==========================================
humanoid.Died:Connect(function()
	if isDead then return end
	isDead = true
	atacando = true

	if rootPart then rootPart.Anchored = true end
	for _, p in ipairs(mob:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end

	-- NUEVO: ENTREGAR EXPERIENCIA Y COR AL ASESINO
	local tag = humanoid:FindFirstChild("creator")
	if tag and tag.Value and tag.Value:IsA("Player") then
		local killer = tag.Value
		local expGanada = 35  -- Experiencia del lobo
		local corGanado = 5   -- Monedas del lobo

		-- Modificamos los ATRIBUTOS directamente. El script de LevelUp que acabamos de hacer lo detectará al instante.
		killer:SetAttribute("EXP", (killer:GetAttribute("EXP") or 0) + expGanada)
		killer:SetAttribute("Coins", (killer:GetAttribute("Coins") or 0) + corGanado)
	end

	local tInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, p in ipairs(mob:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			TweenService:Create(p, tInfo, {Transparency = 1}):Play()

			if math.random(1, 4) == 1 then
				local cristal = Instance.new("Part")
				cristal.Size = Vector3.new(0.4, 0.4, 0.4)
				cristal.CFrame = p.CFrame
				cristal.Material = Enum.Material.Neon
				cristal.Color = COLOR_CRISTAL
				cristal.CanCollide = false
				cristal.AssemblyLinearVelocity = Vector3.new(math.random(-15,15), math.random(10,20), math.random(-15,15))
				cristal.Parent = workspace
				Debris:AddItem(cristal, 2)
				TweenService:Create(cristal, TweenInfo.new(2), {Transparency = 1}):Play()
			end
		elseif p:IsA("Decal") or p:IsA("Texture") then
			TweenService:Create(p, tInfo, {Transparency = 1}):Play()
		end
	end
	Debris:AddItem(mob, 2)
end)

-- ==========================================
-- 🧠 INTELIGENCIA ARTIFICIAL
-- ==========================================
local function buscarObjetivo()
	local objetivo = nil
	local distMin = RANGO_AGGRO

	for _, jugador in pairs(Players:GetPlayers()) do
		local char = jugador.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (rootPart.Position - hrp.Position).Magnitude
				if dist < distMin then
					distMin = dist
					objetivo = hrp
				end
			end
		end
	end
	return objetivo, distMin
end

local function atacar(objetivo)
	atacando = true
	humanoid:MoveTo(rootPart.Position) 

	rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(objetivo.Position.X, rootPart.Position.Y, objetivo.Position.Z))

	if trackAtaque then trackAtaque:Play() end

	rootPart.AssemblyLinearVelocity = rootPart.CFrame.LookVector * 40

	task.wait(0.3) 

	if not isDead and objetivo and objetivo.Parent then
		local charJugador = objetivo.Parent
		local humJugador = charJugador:FindFirstChild("Humanoid")

		if (rootPart.Position - objetivo.Position).Magnitude <= DISTANCIA_ATAQUE + 2 then

			-- 🛡️ LECTURA DE PARRY Y BLOQUEO DEL JUGADOR (CORREGIDO)
			if charJugador:GetAttribute("IsParrying") then
				print("Bloqueaste perfecto al mob!")

				-- ✨ ACTIVAMOS EL CONTRAATAQUE AL JUGADOR
				charJugador:SetAttribute("CanCounterattack", true)
				task.delay(1.5, function()
					if charJugador then charJugador:SetAttribute("CanCounterattack", false) end
				end)

				-- El mob se aturde y se echa para atrás
				rootPart.AssemblyLinearVelocity = rootPart.CFrame.LookVector * -30

			elseif charJugador:GetAttribute("IsBlocking") then
				humJugador:TakeDamage(DANO_BASICO * 0.3)
			else
				humJugador:TakeDamage(DANO_BASICO)
			end
		end
	end

	task.wait(COOLDOWN_ATAQUE)
	atacando = false
end

-- ==========================================
-- 🔄 BUCLE PRINCIPAL
-- ==========================================
task.spawn(function()
	while task.wait(0.1) do
		if isDead then break end
		if not atacando and rootPart then
			local objetivo, distancia = buscarObjetivo()

			if objetivo then
				if distancia <= DISTANCIA_ATAQUE then
					atacar(objetivo)
				else
					humanoid:MoveTo(objetivo.Position)
				end
			end
		end
	end
end)
