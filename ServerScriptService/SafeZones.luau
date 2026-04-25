local Players = game:GetService("Players")
local SafeZonesFolder = workspace:WaitForChild("SafeZones")

-- Función para verificar si una posición está dentro de alguna SafeZone
local function EstaEnZonaSegura(personaje)
	local hrp = personaje:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local pos = hrp.Position
	for _, zona in ipairs(SafeZonesFolder:GetChildren()) do
		if zona:IsA("BasePart") then
			-- Cálculo matemático de caja (AABB)
			local min = zona.Position - (zona.Size / 2)
			local max = zona.Position + (zona.Size / 2)

			if (pos.X >= min.X and pos.X <= max.X) and
				(pos.Z >= min.Z and pos.Z <= max.Z) then
				return true
			end
		end
	end
	return false
end

-- Bucle para proteger a los jugadores
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local hum = char:FindFirstChild("Humanoid")
				if EstaEnZonaSegura(char) then
					-- Aplicamos protección
					char:SetAttribute("InSafeZone", true)
					if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
				else
					-- Quitamos protección
					char:SetAttribute("InSafeZone", false)
					if hum and hum.MaxHealth == math.huge then
						hum.MaxHealth = 100 -- O tu vida base
						hum.Health = 100
					end
				end
			end
		end
		task.wait(0.5)
	end
end)
