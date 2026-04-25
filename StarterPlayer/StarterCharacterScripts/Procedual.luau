local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local rootJoint = rootPart:WaitForChild("RootJoint")

local originalRootC0 = rootJoint.C0

-- ⚙️ CONFIGURACIÓN CALIBRADA (Ajustes más suaves para SAO)
local INTENSIDAD_INCLINACION = 0.015 -- ⚠️ Bajado de 0.05 a 0.015 (Mucho más sutil)
local VELOCIDAD_BOBBING = 10         -- Un poco más lento para que no vibre tanto
local ALTURA_BOBBING = 0.04          -- Menos salto vertical

RunService.RenderStepped:Connect(function(deltaTime)
	if not character or humanoid.Health <= 0 then return end

	-- ⚔️ DETECCIÓN DE COMBATE/ACCIONES ESPECIALES
	-- Si tu sistema de combate pone un Atributo como "Attacking" o "IsSliding", lo respetamos.
	local estaAtacando = character:GetAttribute("Attacking") or character:GetAttribute("IsSliding")

	if estaAtacando then
		-- Si ataca, regresamos al C0 original para que la animación se vea 100% como la hiciste
		rootJoint.C0 = rootJoint.C0:Lerp(originalRootC0, 10 * deltaTime)
		return
	end

	local estado = humanoid:GetState()
	local enElSuelo = (estado == Enum.HumanoidStateType.Running or estado == Enum.HumanoidStateType.RunningNoPhysics or estado == Enum.HumanoidStateType.Landed)

	-- Calculamos velocidad local
	local velocidadLocal = rootPart.CFrame:VectorToObjectSpace(rootPart.Velocity)
	local velocidadPlana = Vector3.new(velocidadLocal.X, 0, velocidadLocal.Z)

	local targetC0 = originalRootC0

	if enElSuelo and velocidadPlana.Magnitude > 1 then
		-- 1. Inclinación MUY sutil
		-- Dividimos por un factor extra para que el ángulo no sea exagerado al correr rápido
		local leanAdelante = math.clamp(velocidadLocal.Z * INTENSIDAD_INCLINACION, -0.15, 0.15)
		local leanLados = math.clamp(-velocidadLocal.X * INTENSIDAD_INCLINACION, -0.15, 0.15)

		-- 2. Rebote (Solo si no va excesivamente rápido para no romper la estética)
		local bobbingY = math.sin(tick() * VELOCIDAD_BOBBING) * ALTURA_BOBBING

		-- Sprint boost (Si corre, inclinamos un pelín más pero sin pasarnos)
		if humanoid.WalkSpeed > 18 then
			bobbingY = math.sin(tick() * (VELOCIDAD_BOBBING * 1.1)) * (ALTURA_BOBBING * 0.8)
			leanAdelante = math.clamp(velocidadLocal.Z * (INTENSIDAD_INCLINACION * 1.2), -0.2, 0.2)
		end

		targetC0 = originalRootC0 * CFrame.new(0, bobbingY, 0) * CFrame.Angles(leanAdelante, 0, leanLados)
	else
		-- Efecto de respiración suave cuando está quieto
		local respiracion = enElSuelo and (math.sin(tick() * 1.5) * 0.01) or 0
		targetC0 = originalRootC0 * CFrame.new(0, respiracion, 0)
	end

	-- Aplicamos el movimiento suavemente
	rootJoint.C0 = rootJoint.C0:Lerp(targetC0, 8 * deltaTime)
end)
