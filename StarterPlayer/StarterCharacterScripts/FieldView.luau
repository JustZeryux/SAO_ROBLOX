local RunService = game:GetService("RunService")
local camera = game:GetService("Workspace").CurrentCamera

-- 1. Definimos el FOV base
local BASE_FOV = 95

-- 2. Creamos un atributo en la cámara para guardar a qué FOV queremos ir
if not camera:GetAttribute("TargetFOV") then
	camera:SetAttribute("TargetFOV", BASE_FOV)
end

-- Lo seteamos a 95 de golpe la primera vez que cargas
camera.FieldOfView = BASE_FOV

-- 3. El ciclo que suaviza TODO automáticamente
RunService.RenderStepped:Connect(function(deltaTime)
	local target = camera:GetAttribute("TargetFOV")

	-- Si por alguna razón se borra el atributo, regresamos al base
	if not target then target = BASE_FOV end

	-- Lerp (Interpolación). Esto hace que la cámara viaje suavemente hacia el TargetFOV
	-- El número '12' es la velocidad de transición. Si quieres que sea más lento y cinematográfico, bájalo a 8.
	camera.FieldOfView = camera.FieldOfView + (target - camera.FieldOfView) * (12 * deltaTime)
end)
