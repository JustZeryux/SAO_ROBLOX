local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")

local EquipOffhandEvent = SAO_Events:WaitForChild("EquipOffhand")
local UnequipOffhandEvent = SAO_Events:WaitForChild("UnequipOffhand")

-- =========================================================
-- FUNCIÓN: DESEQUIPAR OFF-HAND
-- =========================================================
local function UnequipOffhand(player)
	local character = player.Character
	if not character then return end

	local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	local equipoSeguro = character:FindFirstChild("EquipoSeguro")

	if leftHand then
		for _, obj in ipairs(leftHand:GetChildren()) do
			if obj:IsA("Motor6D") and obj.Name == "MotorOffhand" then
				obj:Destroy()
			end
		end
	end

	if equipoSeguro then
		for _, tool in ipairs(equipoSeguro:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = player.Backpack
			end
		end
	end
end

-- =========================================================
-- FUNCIÓN: EQUIPAR OFF-HAND
-- =========================================================
EquipOffhandEvent.OnServerEvent:Connect(function(player, toolInstance)
	if not toolInstance or not toolInstance:IsA("Tool") then return end

	local character = player.Character
	if not character then return end

	UnequipOffhand(player)

	local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	if not leftHand then return end

	local handle = toolInstance:FindFirstChild("Handle") or toolInstance:FindFirstChild("ShieldHandle")
	if not handle then return end

	local equipoSeguro = character:FindFirstChild("EquipoSeguro")
	if not equipoSeguro then
		equipoSeguro = Instance.new("Folder")
		equipoSeguro.Name = "EquipoSeguro"
		equipoSeguro.Parent = character
	end

	toolInstance.Parent = equipoSeguro

	local motor = Instance.new("Motor6D")
	motor.Name = "MotorOffhand"
	motor.Part0 = leftHand
	motor.Part1 = handle

	-- 🔥 AQUÍ VOLTEAMOS EL ESCUDO PARA QUE NO QUEDE AL REVÉS
	-- CFrame.Angles( X, Y, Z )
	motor.C0 = CFrame.new(-0.2, 0, 0) * CFrame.Angles(0, math.rad(-90), 0)

	motor.Parent = leftHand
end)

UnequipOffhandEvent.OnServerEvent:Connect(function(player)
	UnequipOffhand(player)
end)
