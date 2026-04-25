local Tool = script.Parent
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))

local event = Tool:WaitForChild("DispararPua")
local DANO_BASE = 15

local function CrearPua(origenCFrame, direccion, potencia, jugador, skillID)
	local pua = Instance.new("Part")
	pua.Name = "Projectile"
	pua.Size = Vector3.new(0.2, 0.2, 1.8)
	pua.CFrame = CFrame.lookAt(origenCFrame.Position, origenCFrame.Position + direccion)
	pua.Material = Enum.Material.Metal
	pua.Color = Color3.fromRGB(180, 180, 180)
	pua.CanCollide = false
	pua.Massless = true
	pua.Anchored = true 

	local dano = DANO_BASE
	local trailColor = Color3.fromRGB(200, 200, 200)

	-- ⚡ Ajustes por Skill
	if skillID and HabilidadesData[skillID] then
		local data = HabilidadesData[skillID]
		dano = data.Dano or dano
		trailColor = data.ColorPrimario or trailColor
		pua.Material = Enum.Material.Neon
		pua.Color = data.ColorSecundario or pua.Color
		if skillID == "PhantomNeedle" then pua.Transparency = 0.7; potencia *= 1.5 end
	end

	-- Trail VFX
	local a0 = Instance.new("Attachment", pua); a0.Position = Vector3.new(0,0,-0.8)
	local a1 = Instance.new("Attachment", pua); a1.Position = Vector3.new(0,0,0.8)
	local trail = Instance.new("Trail", pua); trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Lifetime = 0.15; trail.Color = ColorSequence.new(trailColor); trail.LightEmission = 1
	pua.Parent = workspace

	local velocidad = direccion * potencia
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {jugador.Character, Tool, pua}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not pua.Parent then connection:Disconnect(); return end

		local posAnterior = pua.Position
		local distanciaPaso = velocidad * dt
		local result = workspace:Raycast(posAnterior, distanciaPaso, params)

		if result then
			connection:Disconnect()
			trail.Enabled = false
			pua.CFrame = CFrame.lookAt(result.Position, result.Position + velocidad)
			
			local hitPart = result.Instance
			local weld = Instance.new("WeldConstraint", pua)
			weld.Part0 = pua; weld.Part1 = hitPart
			pua.Anchored = false

			local hum = hitPart.Parent:FindFirstChild("Humanoid") or hitPart.Parent.Parent:FindFirstChild("Humanoid")
			if hum then
				hum:TakeDamage(dano)
				-- Feedback visual de golpe
				local hitVFX = Instance.new("Part", workspace)
				hitVFX.Shape = Enum.PartType.Ball; hitVFX.Size = Vector3.new(1,1,1)
				hitVFX.Material = Enum.Material.Neon; hitVFX.Color = trailColor
				hitVFX.Anchored = true; hitVFX.CanCollide = false; hitVFX.CFrame = pua.CFrame
				game:GetService("TweenService"):Create(hitVFX, TweenInfo.new(0.2), {Size = Vector3.new(4,4,4), Transparency = 1}):Play()
				Debris:AddItem(hitVFX, 0.2)
			end
			Debris:AddItem(pua, 3)
		else
			pua.CFrame = CFrame.lookAt(pua.Position + distanciaPaso, pua.Position + distanciaPaso + velocidad)
		end
	end)
	Debris:AddItem(pua, 5)
end

event.OnServerEvent:Connect(function(jugador, targetPos, potencia, skillID)
	local handle = Tool:FindFirstChild("Handle")
	if not handle or not jugador.Character then return end

	local origen = handle.Position
	
	if skillID == "SpreadIllusion" then
		for i = -2, 2 do
			local angle = math.rad(i * 12)
			local dir = CFrame.lookAt(origen, targetPos) * CFrame.Angles(0, angle, 0)
			CrearPua(handle.CFrame, dir.LookVector, potencia, jugador, skillID)
		end
	else
		local dir = (targetPos - origen).Unit
		CrearPua(handle.CFrame, dir, potencia, jugador, skillID)
	end
end)
