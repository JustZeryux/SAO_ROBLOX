local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local function PlayShatterEffect(model)
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
	if not root then return end

	-- 1. Congelar al enemigo y ocultar sus partes originales
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
			part.CanCollide = false
			part.Anchored = true
		elseif part:IsA("Decal") then
			part.Transparency = 1
		end
	end

	-- 2. Crear los fragmentos de cristal (Polígonos)
	local numShards = 15 -- Cantidad de cristales
	for i = 1, numShards do
		local shard = Instance.new("Part")
		shard.Size = Vector3.new(math.random(5, 12)/10, math.random(5, 12)/10, math.random(5, 12)/10)
		shard.Shape = Enum.PartType.Block -- Puedes usar meshes de triángulos si tienes
		shard.Color = Color3.fromRGB(0, 180, 255) -- Azul SAO
		shard.Material = Enum.Material.Glass
		shard.Transparency = 0.3
		shard.Reflectance = 0.5
		shard.CanCollide = false
		shard.Position = root.Position + Vector3.new(math.random(-2,2), math.random(-2,2), math.random(-2,2))
		shard.Parent = workspace

		-- Agregar un brillo Neon suave
		local attachment = Instance.new("Attachment", shard)
		local sparkle = Instance.new("Sparkles", attachment)
		sparkle.SparkleColor = Color3.fromRGB(150, 230, 255)

		-- 3. Física de explosión (Hacia afuera y hacia arriba)
		local velocity = Vector3.new(math.random(-15, 15), math.random(10, 25), math.random(-15, 15))
		shard.Velocity = velocity

		-- 4. Animación de desvanecimiento (Fade Out)
		task.delay(0.5, function()
			local tween = TweenService:Create(shard, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
				Transparency = 1,
				Size = Vector3.new(0,0,0)
			})
			tween:Play()
			tween.Completed:Connect(function() shard:Destroy() end)
		end)
	end

	-- Borrar el modelo original después del efecto
	Debris:AddItem(model, 2)
end

-- Conectar con tus enemigos existentes
game.Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Humanoid") then
		desc.Died:Connect(function()
			PlayShatterEffect(desc.Parent)
		end)
	end
end)
