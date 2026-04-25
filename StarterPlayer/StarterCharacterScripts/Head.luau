local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Al estar en StarterCharacterScripts, esto siempre agarra el cuerpo vivo
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")

local isR6 = (humanoid.RigType == Enum.HumanoidRigType.R6)

-- Detección segura R6 / R15
local torso = isR6 and character:WaitForChild("Torso") or character:WaitForChild("UpperTorso")
local neck = isR6 and torso:WaitForChild("Neck") or head:WaitForChild("Neck")
local originalNeckC0 = neck.C0

local LIMITE_ARRIBA_ABAJO = 60 
local LIMITE_LADOS = 70
local INTENSIDAD_REBOTE = 0.05 
local VELOCIDAD_REBOTE = 0.6    

local isDead = false
humanoid.Died:Connect(function()
	isDead = true
	neck.C0 = originalNeckC0
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if isDead or not character or not rootPart or humanoid.Health <= 0 then return end

	local lookVector = camera.CFrame.LookVector
	local localLook = torso.CFrame:VectorToObjectSpace(lookVector)

	-- 🛠️ FIX CLAVE: math.clamp salva a math.asin de crashear el cuello
	local safeX = math.clamp(-localLook.X, -1, 1)
	local safeY = math.clamp(localLook.Y, -1, 1)

	local yaw = math.clamp(math.asin(safeX), math.rad(-LIMITE_LADOS), math.rad(LIMITE_LADOS))
	local pitch = math.clamp(math.asin(safeY), math.rad(-LIMITE_ARRIBA_ABAJO), math.rad(LIMITE_ARRIBA_ABAJO))

	local velocidadActual = rootPart.AssemblyLinearVelocity.Magnitude
	local reboteY = 0
	local reboteX = 0

	-- Rebote solo si te mueves y tocas el suelo
	if velocidadActual > 1 and humanoid.FloorMaterial ~= Enum.Material.Air then
		local tiempoMoviendose = tick() * (velocidadActual * VELOCIDAD_REBOTE)
		reboteY = math.sin(tiempoMoviendose) * INTENSIDAD_REBOTE
		reboteX = math.cos(tiempoMoviendose * 0.5) * (INTENSIDAD_REBOTE * 0.5)
	end

	local targetC0
	if isR6 then
		targetC0 = originalNeckC0 * CFrame.Angles(-pitch + reboteY, 0, -yaw + reboteX)
	else
		targetC0 = originalNeckC0 * CFrame.Angles(pitch + reboteY, yaw + reboteX, 0)
	end

	-- Suavizado constante independiente de los FPS
	neck.C0 = neck.C0:Lerp(targetC0, 15 * deltaTime)
end)
