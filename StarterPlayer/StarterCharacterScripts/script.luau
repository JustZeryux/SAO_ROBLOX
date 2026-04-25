local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- Crear partícula
local dust = Instance.new("ParticleEmitter")
dust.Texture = "rbxassetid://258128463" -- textura de polvo incluida
dust.Rate = 0
dust.Speed = NumberRange.new(3,6)
dust.Lifetime = NumberRange.new(0.4,0.8)
dust.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1.5),
	NumberSequenceKeypoint.new(1, 0)
})
dust.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 1)
})
dust.Rotation = NumberRange.new(0, 360)
dust.RotSpeed = NumberRange.new(-90, 90)
dust.EmissionDirection = Enum.NormalId.Top
dust.Parent = root

-- Raycast para detectar el suelo
local function estaEnElSuelo()
	local rayOrigin = root.Position
	local rayDirection = Vector3.new(0, -3, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	return result ~= nil
end

-- Loop principal
while true do
	task.wait(0.1)

	local moviendose = humanoid.MoveDirection.Magnitude > 0
	local enSuelo = estaEnElSuelo()

	if moviendose and enSuelo then
		dust.Rate = 35
	else
		dust.Rate = 0
	end
end
