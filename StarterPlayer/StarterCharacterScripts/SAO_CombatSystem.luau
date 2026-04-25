local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local meleeEvent = Remotes:WaitForChild("MeleeHit")

-- Configuración de Combos
local currentCombo = 0
local maxCombo = 3
local lastAttackTime = 0
local comboResetTime = 1.2 -- Si no atacas en 1.2s, el combo vuelve a 0
local isAttacking = false

-- 🔥 IDs de tus animaciones de espada (Cámbialos por los tuyos)
local animIds = {
	"rbxassetid://000000000", -- Golpe 1 (Ej. Derecha a Izquierda)
	"rbxassetid://000000000", -- Golpe 2 (Ej. Izquierda a Derecha)
	"rbxassetid://000000000"  -- Golpe 3 (Ej. Tajo vertical pesado)
}
local loadedAnims = {}


local function ShakeCamera(intensity)
	local cam = workspace.CurrentCamera
	local startCFrame = cam.CFrame
	for i = 1, 10 do
		local offset = Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1)) * intensity
		cam.CFrame = cam.CFrame * CFrame.new(offset)
		task.wait(0.05)
	end
end

-- Escuchar el rugido desde el servidor
game.ReplicatedStorage.SAO_Survival.Remotes.BossRoar.OnClientEvent:Connect(function()
	ShakeCamera(2)
end)

-- =========================================================
-- 🎨 1. GENERAR INTERFAZ DE COMBO (Estilo SAO)
-- =========================================================
local playerGui = player:WaitForChild("PlayerGui")
local comboGui = Instance.new("ScreenGui")
comboGui.Name = "SAO_ComboUI"
comboGui.Parent = playerGui

local comboLabel = Instance.new("TextLabel")
comboLabel.Size = UDim2.new(0, 200, 0, 50)
comboLabel.Position = UDim2.new(0, 50, 0.4, 0) -- Lado izquierdo
comboLabel.BackgroundTransparency = 1
comboLabel.Text = ""
comboLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
comboLabel.Font = Enum.Font.GothamBlack
comboLabel.TextSize = 40
comboLabel.TextXAlignment = Enum.TextXAlignment.Left
comboLabel.TextStrokeTransparency = 0.5
comboLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 50)
comboLabel.TextTransparency = 1
comboLabel.Parent = comboGui

-- Efecto de aparición del Combo
local function ShowComboUI(hits)
	comboLabel.Text = hits .. " HITS!"
	comboLabel.TextTransparency = 0

	-- Animación de "Pop" (Se hace grande y luego vuelve a su tamaño)
	comboLabel.TextSize = 60
	comboLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(comboLabel, tweenInfo, {
		TextSize = 40, 
		TextColor3 = Color3.fromRGB(0, 200, 255)
	}):Play()
end

local function HideComboUI()
	TweenService:Create(comboLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
end

-- =========================================================
-- ⚔️ 2. DETECCIÓN DE IMPACTO FRONTAL (Hitbox Pro)
-- =========================================================
local function GetEnemiesInHitbox()
	local hitEnemies = {}
	local attackRange = 7 -- Alcance de la espada en studs

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= character and obj:FindFirstChild("Humanoid") then
			local enemyRoot = obj:FindFirstChild("HumanoidRootPart")
			if enemyRoot and obj.Humanoid.Health > 0 then
				local distance = (rootPart.Position - enemyRoot.Position).Magnitude
				if distance <= attackRange then
					-- Producto Punto (Dot Product) para saber si está EN FRENTE de ti (Visión de 120 grados)
					local directionToEnemy = (enemyRoot.Position - rootPart.Position).Unit
					local facingDirection = rootPart.CFrame.LookVector
					local angle = directionToEnemy:Dot(facingDirection)

					if angle > 0.5 then -- 0.5 equivale a estar más o menos frente al jugador
						table.insert(hitEnemies, obj)
					end
				end
			end
		end
	end
	return hitEnemies
end

-- =========================================================
-- 🚀 3. LÓGICA DEL ATAQUE
-- =========================================================
local function Attack()
	-- Verificar si tiene la espada equipada
	local equippedTool = character:FindFirstChildOfClass("Tool")
	if not equippedTool or equippedTool.Name ~= "Sword" then return end

	if isAttacking then return end
	isAttacking = true

	-- Manejo de Combos
	local currentTime = tick()
	if currentTime - lastAttackTime > comboResetTime then
		currentCombo = 1
	else
		currentCombo = currentCombo + 1
		if currentCombo > maxCombo then currentCombo = 1 end
	end
	lastAttackTime = currentTime

	-- Reproducir Animación
	local animId = animIds[currentCombo]
	if animId and animId ~= "rbxassetid://000000000" then
		if not loadedAnims[currentCombo] then
			local anim = Instance.new("Animation")
			anim.AnimationId = animId
			loadedAnims[currentCombo] = humanoid:LoadAnimation(anim)
		end
		loadedAnims[currentCombo]:Play()
	end

	-- Actualizar UI de Combo
	ShowComboUI(currentCombo)

	-- Detectar impactos en el momento exacto del swing (pequeño delay)
	task.delay(0.15, function()
		local enemies = GetEnemiesInHitbox()
		if #enemies > 0 then
			-- Enviar al servidor la lista de enemigos golpeados
			meleeEvent:FireServer(enemies, currentCombo)

			-- Efecto de sonido de golpe aquí (opcional)
		end
	end)

	-- Liberar el ataque
	task.wait(0.35) -- Tiempo que tarda el jugador en poder dar el siguiente clic
	isAttacking = false
end

UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Attack()
	end
end)

-- Bucle para esconder el combo si dejas de atacar
task.spawn(function()
	while task.wait(0.1) do
		if tick() - lastAttackTime > comboResetTime and comboLabel.TextTransparency == 0 then
			currentCombo = 0
			HideComboUI()
		end
	end
end)
