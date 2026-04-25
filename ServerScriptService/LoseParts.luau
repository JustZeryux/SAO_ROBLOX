local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local SAO_HitEvent = ReplicatedStorage:WaitForChild("SAO_HitEvent") 

local LimbHealthData = {}

-- Bajamos la resistencia base para que sea posible cortar extremidades antes de que mueran
local BASE_LIMB_HP = 50

local function getLimbMaxHP(humanoid)
	return BASE_LIMB_HP + (humanoid.MaxHealth * 0.1)
end

-- Lista EXCLUSIVA para R6
local VulnerableParts = {
	["Head"] = "Instakill",
	["Right Arm"] = "NoWeapon", 
	["Left Arm"] = "NoOffhand", 
	["Right Leg"] = "Slow", 
	["Left Leg"] = "Slow"
}

-- ==========================================
-- ✨ MOTOR DE SHATTER DIGITAL (SAO STYLE)
-- ==========================================
local function CrearEfectoShatterSAO(originalPart)
	-- 1. Clonamos la parte para hacer el efecto visual
	local fakePart = originalPart:Clone()
	fakePart:ClearAllChildren() -- Borramos scripts, welds o decals viejos

	fakePart.Parent = workspace
	fakePart.CFrame = originalPart.CFrame
	fakePart.Anchored = true -- ¡Se congela en el aire al estilo anime!
	fakePart.CanCollide = false

	-- 2. Look Digital (Neón Rojo/Naranja de daño letal)
	fakePart.Material = Enum.Material.Neon
	fakePart.Color = Color3.fromRGB(255, 40, 40)

	-- 3. Partículas de Cristal de Datos (Polígonos rompiéndose)
	local emitter = Instance.new("ParticleEmitter", fakePart)
	emitter.Texture = "rbxassetid://7335110821" -- Textura de fragmentos
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 80, 80))
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
	emitter.Speed = NumberRange.new(15, 30)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.EmissionDirection = Enum.NormalId.Outward
	emitter.Lifetime = NumberRange.new(0.5, 0.8)
	emitter.Drag = 3
	emitter.LightEmission = 1
	emitter.Rate = 0

	-- 4. Sonido de cristal digital rompiéndose
	local shatterSound = Instance.new("Sound", fakePart)
	shatterSound.SoundId = "rbxassetid://8742261623" -- Sonido de Glitch/Rotura
	shatterSound.Volume = 1.5
	shatterSound:Play()

	-- EXPLOSIÓN DE POLÍGONOS
	emitter:Emit(60)

	-- 5. Implosión (Se encoge hasta desaparecer)
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	TweenService:Create(fakePart, tweenInfo, {Size = Vector3.new(0, 0, 0), Transparency = 1}):Play()

	Debris:AddItem(fakePart, 1)
end


-- ==========================================
-- 🩸 REGISTRO DE DAÑO Y CORTES
-- ==========================================
_G.RegisterHit = function(humanoid, hitPart, damageAmount)
	if not humanoid or humanoid.Health <= 0 then return end
	local character = humanoid.Parent
	local isSevered = false

	if hitPart and VulnerableParts[hitPart.Name] then
		local partName = hitPart.Name

		if not LimbHealthData[humanoid] then
			LimbHealthData[humanoid] = {}
			humanoid.Died:Connect(function()
				LimbHealthData[humanoid] = nil 
			end)
		end

		if not LimbHealthData[humanoid][partName] then
			LimbHealthData[humanoid][partName] = getLimbMaxHP(humanoid)
		end

		LimbHealthData[humanoid][partName] = LimbHealthData[humanoid][partName] - damageAmount

		-- 💥 ¡SE ROMPE LA EXTREMIDAD R6!
		if LimbHealthData[humanoid][partName] <= 0 then
			isSevered = true
			local consequence = VulnerableParts[partName]

			if consequence == "Instakill" then
				humanoid.Health = 0
			elseif consequence == "NoWeapon" then
				character:SetAttribute("CanAttack", false) 
				local tool = character:FindFirstChildWhichIsA("Tool")
				if tool then tool.Parent = workspace end
			elseif consequence == "NoOffhand" then
				character:SetAttribute("CanBlock", false)
				local offhand = character:FindFirstChild("OffhandItem")
				if offhand then offhand:Destroy() end
			elseif consequence == "Slow" then
				humanoid.WalkSpeed = humanoid.WalkSpeed * 0.4 
				humanoid.JumpPower = 0
			end

			-- ✨ FÍSICA R6: Destruimos el motor
			local torso = character:FindFirstChild("Torso")
			if torso then
				if partName == "Right Arm" and torso:FindFirstChild("Right Shoulder") then torso["Right Shoulder"]:Destroy() end
				if partName == "Left Arm" and torso:FindFirstChild("Left Shoulder") then torso["Left Shoulder"]:Destroy() end
				if partName == "Right Leg" and torso:FindFirstChild("Right Hip") then torso["Right Hip"]:Destroy() end
				if partName == "Left Leg" and torso:FindFirstChild("Left Hip") then torso["Left Hip"]:Destroy() end
				if partName == "Head" and torso:FindFirstChild("Neck") then torso["Neck"]:Destroy() end
			end

			-- 🎬 DISPARAR EL EFECTO CINEMÁTICO
			CrearEfectoShatterSAO(hitPart)

			-- 👇 ¡NUEVA LIMPIEZA SEGURA! 👇
			hitPart.Transparency = 1
			hitPart.CanCollide = false

			if partName == "Head" then
				local face = hitPart:FindFirstChildOfClass("Decal")
				if face then face:Destroy() end

				-- Destruimos los accesorios para que el pelo/sombrero no flote
				for _, accesorio in pairs(character:GetChildren()) do
					if accesorio:IsA("Accessory") then
						accesorio:Destroy()
					end
				end
			end

			Debris:AddItem(hitPart, 0.1)
		end
	end

	humanoid:TakeDamage(damageAmount)
	SAO_HitEvent:FireAllClients(hitPart, hitPart.Position, damageAmount, isSevered)
end
