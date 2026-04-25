local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local dungeon = workspace:WaitForChild("Dungeon_1")
local trigger = dungeon:WaitForChild("EntranceTrigger")
local door = dungeon:WaitForChild("BossDoor")
local spawnPoint = dungeon:WaitForChild("BossSpawnPoint")

local isBossFightActive = false
local currentBoss = nil

-- =========================================================
-- 🛑 1. ACTIVAR LA BARRERA (Efecto Área Anti-Cristal)
-- =========================================================
local function LockRoom()
	door.Material = Enum.Material.ForceField
	door.Color = Color3.fromRGB(255, 0, 0) -- Rojo SAO
	door.CanCollide = true

	-- Aparece suavemente
	local tween = TweenService:Create(door, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 0.2})
	tween:Play()
end

local function UnlockRoom()
	local tween = TweenService:Create(door, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {Transparency = 1})
	tween:Play()
	tween.Completed:Connect(function()
		door.CanCollide = false
	end)
end

-- =========================================================
-- 🎁 2. RECOMPENSA (Conectar con tu sistema de cofres)
-- =========================================================
local function SpawnReward()
	local chestTemplate = ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("TreasureChest")
	if chestTemplate then
		local newChest = chestTemplate:Clone()
		-- Aparece en el centro de la sala
		newChest:PivotTo(spawnPoint.CFrame)

		-- Lo metemos en la carpeta "Chests" para que tu script 'SAO_ChestSystem' 
		-- lo detecte y le ponga automáticamente la animación y el botín
		local chestsFolder = workspace:FindFirstChild("Chests")
		if not chestsFolder then
			chestsFolder = Instance.new("Folder")
			chestsFolder.Name = "Chests"
			chestsFolder.Parent = workspace
		end

		newChest.Parent = chestsFolder

		-- Efecto de aparición divina
		for _, part in ipairs(newChest:GetDescendants()) do
			if part:IsA("BasePart") then
				local originalTrans = part.Transparency
				part.Transparency = 1
				TweenService:Create(part, TweenInfo.new(2), {Transparency = originalTrans}):Play()
			end
		end
	end
end

-- =========================================================
-- ⚔️ 3. LÓGICA DEL JEFE Y LA SALA
-- =========================================================
local function StartBossFight()
	if isBossFightActive then return end
	isBossFightActive = true

	-- 1. Cerramos la puerta
	LockRoom()

	-- 2. Spawneamos al Jefe
	local bossTemplate = ReplicatedStorage.Models:FindFirstChild("BossModel")
	if not bossTemplate then 
		warn("Falta el BossModel en ReplicatedStorage.Models")
		return 
	end

	currentBoss = bossTemplate:Clone()
	currentBoss:PivotTo(spawnPoint.CFrame)
	currentBoss.Parent = workspace

	-- 3. Monitorear la vida del Jefe
	local bossHumanoid = currentBoss:WaitForChild("Humanoid")

	bossHumanoid.Died:Connect(function()
		-- ¡El Jefe ha muerto!
		task.wait(3) -- Esperar a que termine la animación de muerte/partículas

		if currentBoss then currentBoss:Destroy() end

		-- Abrir la sala y dar botín
		UnlockRoom()
		SpawnReward()

		-- Reiniciar la sala después de un tiempo (Respawn de Mazmorra)
		task.delay(60, function()
			isBossFightActive = false
		end)
	end)
end

-- =========================================================
-- 🏃‍♂️ 4. DETECTAR JUGADORES ENTRANDO
-- =========================================================
trigger.Touched:Connect(function(hit)
	if isBossFightActive then return end

	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")

	if humanoid and humanoid.Health > 0 then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			StartBossFight()
		end
	end
end)
