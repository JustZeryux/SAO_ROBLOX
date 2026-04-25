local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local SAO_HitEvent = ReplicatedStorage:WaitForChild("SAO_HitEvent")

local marksData = {}

-- ==========================================
-- 💯 SISTEMA DE NÚMEROS DE DAÑO (SAO STYLE)
-- ==========================================
local function createDamageNumber(hitPart, swordPos, damageAmount)
	damageAmount = damageAmount or math.random(30, 60) 

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = hitPart
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(math.random(-15, 15)/10, math.random(0, 10)/10, math.random(-15, 15)/10)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = tostring(math.floor(damageAmount))
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeColor3 = Color3.fromRGB(255, 30, 30)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	billboard.Parent = workspace

	local targetOffset = billboard.StudsOffset + Vector3.new(0, 2.5, 0)
	TweenService:Create(billboard, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {StudsOffset = targetOffset}):Play()

	task.delay(0.4, function()
		TweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)

	Debris:AddItem(billboard, 0.8)
end

-- ==========================================
-- 💥 EFECTO DE CRISTALIZACIÓN (DESMEMBRAMIENTO SAO)
-- ==========================================
local function createShatterEffect(part)
	if not part or not part.Parent then return end

	-- Efecto de sonido de cristal rompiéndose (Opcional, pon tu ID)
	local sfx = Instance.new("Sound", workspace)
	sfx.SoundId = "rbxassetid://6008652438" -- Sonido de cristal
	sfx.Volume = 1
	sfx:Play()
	Debris:AddItem(sfx, 2)

	-- Volvemos la parte de color rojo neón como en el anime antes de romperse
	local originalColor = part.Color
	local originalMaterial = part.Material
	part.Material = Enum.Material.ForceField
	part.Color = Color3.fromRGB(255, 50, 50)

	task.wait(0.1)

	-- Creamos los polígonos
	local shards = 15
	for i = 1, shards do
		local shard = Instance.new("Part")
		shard.Size = Vector3.new(math.random(2, 5)/10, math.random(2, 5)/10, math.random(2, 5)/10)
		shard.Position = part.Position + Vector3.new(math.random(-10,10)/20, math.random(-10,10)/20, math.random(-10,10)/20)
		shard.Color = (math.random(1,2) == 1) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
		shard.Material = Enum.Material.Neon
		shard.CanCollide = false
		shard.Parent = workspace

		-- Física explosiva
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(math.random(-20,20), math.random(10,30), math.random(-20,20))
		bv.MaxForce = Vector3.new(1e4, 1e4, 1e4)
		bv.Parent = shard
		Debris:AddItem(bv, 0.1)

		-- Desvanecimiento
		TweenService:Create(shard, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1, Size = Vector3.new(0,0,0)}):Play()
		Debris:AddItem(shard, 0.5)
	end

	-- Destruimos la parte visualmente
	part:Destroy()
end

-- ==========================================
-- ⚔️ CREADOR DE CORTES (FIXED & POLISHED)
-- ==========================================
local function createSaoMark(arg1, arg2, arg3, isSevered)
	local hitPart = nil
	local swordPos = nil
	local damageAmount = nil

	local args = {arg1, arg2, arg3}
	for _, arg in ipairs(args) do
		if typeof(arg) == "Instance" and arg:IsA("BasePart") then hitPart = arg
		elseif typeof(arg) == "Vector3" then swordPos = arg
		elseif type(arg) == "number" then damageAmount = arg end
	end

	if not hitPart then return end
	if not swordPos then swordPos = hitPart.Position end

	createDamageNumber(hitPart, swordPos, damageAmount)

	if isSevered then
		createShatterEffect(hitPart)
		return 
	end

	-- 1️⃣ OBTENER LA SUPERFICIE REAL (RAYCAST)
	-- Esto evita que el corte quede flotando o chueco. Detecta la inclinación exacta de la piel/armadura.
	local rayOrigin = swordPos + (swordPos - hitPart.Position).Unit * 2
	local rayDirection = (hitPart.Position - rayOrigin).Unit * 4
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {hitPart}
	rayParams.FilterType = Enum.RaycastFilterType.Include

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	local surfaceNormal = raycastResult and raycastResult.Normal or (swordPos - hitPart.Position).Unit

	-- 2️⃣ DESTELLO DE IMPACTO
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball; flash.Material = Enum.Material.Neon; flash.Color = Color3.fromRGB(255, 100, 100)
	flash.Anchored = true; flash.CanCollide = false; flash.Size = Vector3.new(0.5, 0.5, 0.5)
	flash.CFrame = CFrame.new(swordPos)
	flash.Parent = workspace
	TweenService:Create(flash, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(3, 3, 3), Transparency = 1}):Play()
	Debris:AddItem(flash, 0.2)

	-- 3️⃣ LA MARCA DEL CORTE (FORMA ELÍPTICA)
	local slash = Instance.new("Part")
	slash.Name = "SAO_Mark"; slash.Material = Enum.Material.Neon; slash.Color = Color3.fromRGB(255, 10, 10)
	slash.CanCollide = false; slash.CanQuery = false; slash.Massless = true
	-- Empezamos con tamaño 0 para que la animación lo abra
	slash.Size = Vector3.new(0, 0, 0.01) 

	-- Usamos un SpecialMesh tipo Esfera aplastada. Esto hace que el corte sea filoso en las puntas y ancho en el centro, no un bloque feo.
	local slashMesh = Instance.new("SpecialMesh")
	slashMesh.MeshType = Enum.MeshType.Sphere
	slashMesh.Parent = slash

	-- Lo alineamos perfectamente a la superficie calculada por el Raycast
	local randomAngle = math.rad(math.random(-80, 80))
	slash.CFrame = CFrame.lookAt(swordPos, swordPos + surfaceNormal) * CFrame.Angles(0, 0, randomAngle)
	slash.Parent = workspace

	-- Núcleo brillante (blanco/amarillento en el centro del tajo)
	local slashCore = Instance.new("Part")
	slashCore.Material = Enum.Material.Neon; slashCore.Color = Color3.fromRGB(255, 230, 200)
	slashCore.CanCollide = false; slashCore.CanQuery = false; slashCore.Massless = true
	slashCore.Size = Vector3.new(0, 0, 0.02)
	slashCore.CFrame = slash.CFrame; slashCore.Parent = slash

	local coreMesh = Instance.new("SpecialMesh")
	coreMesh.MeshType = Enum.MeshType.Sphere
	coreMesh.Parent = slashCore

	-- Luz dinámica para que el tajo ilumine al personaje
	local glowLight = Instance.new("PointLight")
	glowLight.Color = Color3.fromRGB(255, 30, 30)
	glowLight.Brightness = 1.5
	glowLight.Range = 4
	glowLight.Parent = slash

	local weldCore = Instance.new("WeldConstraint"); weldCore.Part0 = slash; weldCore.Part1 = slashCore; weldCore.Parent = slashCore
	local weld = Instance.new("WeldConstraint"); weld.Part0 = hitPart; weld.Part1 = slash; weld.Parent = slash

	-- 4️⃣ PARTÍCULAS SAO DIGITALES
	local attachment = Instance.new("Attachment", slash)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))})
	emitter.LightEmission = 1; emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Speed = NumberRange.new(8, 20)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.EmissionDirection = Enum.NormalId.Back -- Expulsa hacia afuera del corte
	-- Hacemos que parezcan polígonos/cuadros rompiéndose (efecto digital)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(100, 200)
	emitter.Parent = attachment
	emitter:Emit(20) 

	-- 5️⃣ ANIMACIÓN DE APARICIÓN (EL CORTE SE ABRE)
	local finalLength = math.random(15, 25) / 10
	local finalWidth = math.random(1, 2) / 10 
	TweenService:Create(slash, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(finalLength, finalWidth, 0.01)}):Play()
	TweenService:Create(slashCore, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(finalLength * 0.7, finalWidth * 0.3, 0.02)}):Play()

	-- 6️⃣ LÓGICA DE CURACIÓN (DESVANECIMIENTO SUAVE)
	local character = hitPart.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then character = hitPart.Parent.Parent; humanoid = character and character:FindFirstChild("Humanoid") end

	local function fadeOutMark(markData)
		if markData.slash and markData.slash.Parent then
			TweenService:Create(markData.slash, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = Vector3.new(0,0,0)}):Play()
			TweenService:Create(markData.slashCore, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = Vector3.new(0,0,0)}):Play()
			TweenService:Create(glowLight, TweenInfo.new(0.8), {Brightness = 0}):Play()
			task.delay(0.8, function() if markData.slash then markData.slash:Destroy() end end)
		end
	end

	if humanoid then
		if not marksData[humanoid] then
			marksData[humanoid] = {marks = {}, lastHealth = humanoid.Health, connection = nil}
			marksData[humanoid].connection = humanoid.HealthChanged:Connect(function(newHealth)
				local data = marksData[humanoid]
				if not data then return end
				if newHealth > data.lastHealth and #data.marks > 0 then
					local markToRemove = table.remove(data.marks, 1)
					fadeOutMark(markToRemove)
				end
				data.lastHealth = newHealth
			end)
			humanoid.Died:Connect(function()
				if marksData[humanoid] then marksData[humanoid].connection:Disconnect(); marksData[humanoid] = nil end
			end)
		end
		table.insert(marksData[humanoid].marks, {slash = slash, slashCore = slashCore})
	else
		task.delay(3.5, function()
			fadeOutMark({slash = slash, slashCore = slashCore})
		end)
	end
end

SAO_HitEvent.OnClientEvent:Connect(createSaoMark)
