local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- ==========================================
-- ⚙️ CONFIGURACIÓN DEL EFECTO SAO
-- ==========================================
local COLOR_CRISTAL = Color3.fromRGB(0, 200, 255) 
local DURACION_EFECTO = 3 

-- ==========================================
-- 💎 CREAR CRISTALES ROTOS (POLÍGONOS)
-- ==========================================
local function crearFragmento(partOriginal)
	local shard = Instance.new("WedgePart")
	shard.Name = "SAO_Shard"
	shard.Material = Enum.Material.Neon
	shard.Color = COLOR_CRISTAL
	shard.Transparency = 0.2

	local sizeX = partOriginal.Size.X * math.random(20, 50) / 100
	local sizeY = partOriginal.Size.Y * math.random(20, 50) / 100
	local sizeZ = partOriginal.Size.Z * math.random(20, 50) / 100
	shard.Size = Vector3.new(sizeX, sizeY, sizeZ)

	shard.CanCollide = false 
	shard.Anchored = false

	local offset = Vector3.new(math.random(-10,10)/20, math.random(-10,10)/20, math.random(-10,10)/20)
	shard.CFrame = partOriginal.CFrame * CFrame.new(offset) * CFrame.Angles(math.rad(math.random(0,360)), math.rad(math.random(0,360)), math.rad(math.random(0,360)))

	local rootPos = character.PrimaryPart and character.PrimaryPart.Position or partOriginal.Position
	local outwardDir = (shard.Position - rootPos).Unit

	-- Evitar error si outwardDir es NaN (si están en la misma posición exacta)
	if outwardDir.X ~= outwardDir.X then outwardDir = Vector3.new(0,1,0) end

	shard.AssemblyLinearVelocity = (outwardDir * math.random(10, 25)) + Vector3.new(0, math.random(5, 15), 0) 

	local bodyForce = Instance.new("BodyForce")
	bodyForce.Force = Vector3.new(0, shard:GetMass() * workspace.Gravity * 1.05, 0)
	bodyForce.Parent = shard

	shard.Parent = workspace
	Debris:AddItem(shard, DURACION_EFECTO)

	task.delay(DURACION_EFECTO * 0.4, function()
		if shard and shard.Parent then
			local tweenInfo = TweenInfo.new(DURACION_EFECTO * 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			TweenService:Create(shard, tweenInfo, {Transparency = 1, Size = Vector3.new(0,0,0)}):Play()
		end
	end)
end

-- ==========================================
-- 💀 EVENTO DE MUERTE
-- ==========================================
humanoid.Died:Connect(function()
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	-- 1️⃣ FASE 1: EL CUERPO CAE Y SE CONGELA
	task.wait(0.8)
	if rootPart then rootPart.Anchored = true end

	-- 2️⃣ FASE 2: CRISTALIZACIÓN
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Material = Enum.Material.Neon
			part.Color = COLOR_CRISTAL
			part.Transparency = 0.4

			-- FIX: Quitar texturas de avatares R15 (MeshParts)
			if part:IsA("MeshPart") then part.TextureID = "" end

		elseif part:IsA("Decal") or part:IsA("Texture") or part:IsA("Clothing") or part:IsA("ShirtGraphic") then
			part:Destroy()
		elseif part:IsA("SpecialMesh") then
			part.TextureId = ""
		end
	end

	-- Micro-segundo de tensión...
	task.wait(0.4)

	-- Ocultar el cuerpo original
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then 
			part.Transparency = 1 
			part.CanCollide = false
		end
	end

	-- Generar fragmentos
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local cantidadFragmentos = math.random(4, 6)
			if part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" then 
				cantidadFragmentos = 10 
			end
			for i = 1, cantidadFragmentos do crearFragmento(part) end
		end
	end

	Debris:AddItem(character, DURACION_EFECTO)
end)
