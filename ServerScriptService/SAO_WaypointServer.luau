local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")

-- Creamos el RemoteEvent dinámicamente si no existe
local teleportEvent = Remotes:FindFirstChild("TeleportEvent")
if not teleportEvent then
	teleportEvent = Instance.new("RemoteEvent")
	teleportEvent.Name = "TeleportEvent"
	teleportEvent.Parent = Remotes
end

local waypointsFolder = workspace:WaitForChild("Waypoints")

-- 1. Añadir interacción a todos los cristales
for _, waypoint in ipairs(waypointsFolder:GetChildren()) do
	if waypoint:IsA("BasePart") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Interconectar"
		prompt.ObjectText = waypoint.Name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 1 -- Un segundo para activar
		prompt.RequiresLineOfSight = false
		prompt.Parent = waypoint

		prompt.Triggered:Connect(function(player)
			-- Enviamos al jugador la lista de todos los otros destinos disponibles
			local destinationList = {}
			for _, wp in ipairs(waypointsFolder:GetChildren()) do
				if wp ~= waypoint then
					table.insert(destinationList, wp.Name)
				end
			end
			teleportEvent:FireClient(player, "OpenMenu", destinationList)
		end)
	end
end

-- 2. Recibir la orden de viaje del jugador
teleportEvent.OnServerEvent:Connect(function(player, action, destinationName)
	if action == "Teleport" then
		local dest = waypointsFolder:FindFirstChild(destinationName)
		if dest and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			-- Teletransportamos al jugador un poco por encima del cristal destino
			player.Character:PivotTo(dest.CFrame * CFrame.new(0, 3, 0))
		end
	end
end)
