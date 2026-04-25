local Tool = script.Parent
local eventoDisparo = Tool:WaitForChild("DispararPua") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
-- ✨ DECLARAR EL EVENTO DE IMPACTO AQUÍ
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local HitFeedbackEvent = SAO_Events:WaitForChild("HitFeedback")
local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))
local DANO_BASE = 20

-- 🛠️ CORRECCIÓN DE FLECHA CHUECA
-- Si la flecha vuela de lado, aquí lo corregimos rotándola 90 grados.
local CORRECCION_ROTACION = CFrame.Angles(0, math.rad(-90), 0)
-- ==========================================
-- 🏹 LÓGICA DE DAÑO Y CORTES GLOBALES
-- ==========================================
-- ==========================================
-- 🏹 LÓGICA DE DAÑO Y CORTES GLOBALES
-- ==========================================
local function AplicarDanoFlecha(hitPart, humanoid, danoFinal, jugador)
	-- Evitar hacer el efecto si el enemigo ya estaba muerto
	if humanoid.Health <= 0 then return end 

	humanoid:SetAttribute("LastAttacker", jugador.Name)

	if _G.RegisterHit then
		_G.RegisterHit(humanoid, hitPart, danoFinal)
	else
		humanoid:TakeDamage(danoFinal)
	end

	-- ✨ LA REGLA DE ORO ✨
	-- Le gritamos a todos los clientes que la flecha conectó un golpe.
	-- Esto hará que salgan chispas y tiemble la pantalla.
	local enemigoCharacter = humanoid.Parent
	local hitPosition = hitPart.Position
	HitFeedbackEvent:FireAllClients(enemigoCharacter, jugador, hitPosition, danoFinal)
end

-- ==========================================
-- ☄️ CREADOR DE FLECHAS Y MAGIA
-- ==========================================
local function CrearFlecha(origenCFrame, direccion, potencia, jugador, skillID, objetivoPos)
	local skillData = skillID and HabilidadesData[skillID] or nil

	if skillID == "StarTear" then
		-- Lógica original de StarTear restaurada
		local flechaAscenso = Instance.new("Part")
		flechaAscenso.Size = Vector3.new(1, 1, 6)
		flechaAscenso.CFrame = CFrame.lookAt(origenCFrame.Position, origenCFrame.Position + Vector3.new(0, 1, 0))
		flechaAscenso.Material = Enum.Material.Neon
		flechaAscenso.Color = skillData.ColorPrimario
		flechaAscenso.CanCollide = false
		flechaAscenso.Parent = workspace
		flechaAscenso.AssemblyLinearVelocity = Vector3.new(0, 300, 0)
		Debris:AddItem(flechaAscenso, 1)

		task.delay(0.8, function()
			for i = 1, 15 do
				task.delay(math.random() * 1.5, function()
					local randomOffset = Vector3.new(math.random(-15, 15), 60, math.random(-15, 15))
					local posCaida = objetivoPos + randomOffset
					CrearFlecha(CFrame.new(posCaida), Vector3.new(0, -1, 0), 200, jugador, "StarTear_Rain", objetivoPos)
				end)
			end
		end)
		return 
	end

	-- ================== CREACIÓN DE TU FLECHA 3D ==================
	local flecha
	if ReplicatedStorage:FindFirstChild("FlechaBase") then
		flecha = ReplicatedStorage.FlechaBase:Clone()
	else
		flecha = Instance.new("Part")
		flecha.Size = Vector3.new(0.15, 0.15, 3.5)
	end

	flecha.Name = "Flecha"
	-- ✨ APLICAMOS LA CORRECCIÓN DE ROTACIÓN AQUÍ
	flecha.CFrame = CFrame.lookAt(origenCFrame.Position, origenCFrame.Position + direccion) * CORRECCION_ROTACION
	flecha.CanCollide = false 
	flecha.Massless = true

	-- 🛠️ CORRECCIÓN DE COLISIÓN PARA QUE NO TE MANDE A VOLAR
	for _, parte in pairs(flecha:GetDescendants()) do
		if parte:IsA("BasePart") then
			parte.CanCollide = false
			parte.Massless = true
		end
	end

	local trailColor = Color3.fromRGB(0, 255, 255)
	local danoFlecha = DANO_BASE

	if skillData then
		danoFlecha = skillData.Dano
		trailColor = skillData.ColorPrimario

		if flecha:IsA("BasePart") then
			flecha.Color = skillData.ColorSecundario
			flecha.Material = Enum.Material.Neon
		end

		if skillID == "FixPierce" then
			flecha.Size = flecha.Size * 2 
		elseif skillID == "StrikeNova" then
			flecha:Destroy()
			flecha = Instance.new("Part"); flecha.Shape = Enum.PartType.Ball; flecha.Size = Vector3.new(1.5, 1.5, 1.5)
			flecha.Material = Enum.Material.Neon; flecha.Color = skillData.ColorSecundario
			flecha.CanCollide = false; flecha.Massless = true
			flecha.CFrame = CFrame.lookAt(origenCFrame.Position, origenCFrame.Position + direccion)
		elseif skillID == "StarTear_Rain" then
			-- Restaurado el daño de lluvia
			danoFlecha = HabilidadesData["StarTear"].Dano / 10 
			trailColor = HabilidadesData["StarTear"].ColorSecundario
		end
	end

	local a0 = Instance.new("Attachment", flecha); a0.Position = Vector3.new(0,0,-1.5)
	local a1 = Instance.new("Attachment", flecha); a1.Position = Vector3.new(0,0,1.5)
	local trail = Instance.new("Trail", flecha)
	trail.Attachment0 = a0; trail.Attachment1 = a1
	trail.Lifetime = skillData and 0.4 or 0.15
	trail.Color = ColorSequence.new(trailColor)
	trail.LightEmission = 1
	flecha.Parent = workspace

	flecha.AssemblyLinearVelocity = direccion * potencia

	local rotacionConexion
	rotacionConexion = RunService.Heartbeat:Connect(function()
		if not flecha or not flecha.Parent then rotacionConexion:Disconnect() return end
		if flecha.AssemblyLinearVelocity.Magnitude > 2 then
			-- ✨ MANTENEMOS LA CORRECCIÓN MIENTRAS VUELA
			flecha.CFrame = CFrame.lookAt(flecha.Position, flecha.Position + flecha.AssemblyLinearVelocity) * CORRECCION_ROTACION
		end
	end)

	-- ================== IMPACTO ==================
	local debounce = false
	flecha.Touched:Connect(function(hit)
		if debounce or hit:IsDescendantOf(jugador.Character) or hit:IsDescendantOf(Tool) or hit.Name == "Flecha" then return end
		debounce = true
		rotacionConexion:Disconnect()

		flecha.Anchored = true
		trail.Enabled = false

		if skillID == "StrikeNova" or skillID == "StarTear_Rain" then
			local radioExplosion = (skillID == "StrikeNova") and 20 or 10
			local explosion = Instance.new("Part", workspace)
			explosion.Shape = Enum.PartType.Ball; explosion.Material = Enum.Material.Neon
			explosion.Color = trailColor; explosion.Anchored = true; explosion.CanCollide = false
			explosion.CFrame = flecha.CFrame; explosion.Size = Vector3.new(2,2,2)

			TweenService:Create(explosion, TweenInfo.new(0.4), {Size = Vector3.new(radioExplosion, radioExplosion, radioExplosion), Transparency = 1}):Play()

			-- 🧹 BORRADO ESTRICTO DE LA BOLA AZUL
			task.delay(0.45, function() if explosion then explosion:Destroy() end end)

			local params = OverlapParams.new(); params.FilterDescendantsInstances = {jugador.Character}
			local parts = workspace:GetPartBoundsInBox(flecha.CFrame, Vector3.new(radioExplosion, radioExplosion, radioExplosion), params)
			local hitChars = {}
			for _, p in pairs(parts) do
				local h = p.Parent:FindFirstChild("Humanoid")
				if h and not hitChars[h] then
					hitChars[h] = true
					AplicarDanoFlecha(p, h, danoFlecha, jugador)
				end
			end
			flecha:Destroy()
			return 
		end

		local humanoid = hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChild("Humanoid")
		if humanoid then
			local multiplicador = (potencia > 200) and 1.5 or 1
			local danoFinal = danoFlecha * (skillData and 1 or multiplicador)
			AplicarDanoFlecha(hit, humanoid, danoFinal, jugador)

			local impactoVFX = Instance.new("Part", workspace)
			impactoVFX.Shape = Enum.PartType.Ball; impactoVFX.Material = Enum.Material.Neon
			impactoVFX.Color = trailColor; impactoVFX.Anchored = true; impactoVFX.CanCollide = false
			impactoVFX.CFrame = flecha.CFrame; impactoVFX.Size = Vector3.new(1,1,1)
			TweenService:Create(impactoVFX, TweenInfo.new(0.25), {Size = Vector3.new(5,5,5), Transparency = 1}):Play()

			-- 🧹 BORRADO ESTRICTO DE LA BOLA AZUL
			task.delay(0.3, function() if impactoVFX then impactoVFX:Destroy() end end)
		end

		Debris:AddItem(flecha, 2)
	end)
end

-- ==========================================
-- 📡 RECIBIR LA ORDEN DEL CLIENTE
-- ==========================================
eventoDisparo.OnServerEvent:Connect(function(jugador, posicionObjetivo, potencia, skillID)
	local handle = Tool:FindFirstChild("Handle")
	if not handle or not jugador.Character then return end

	local origen = handle.Position
	local direccion = (posicionObjetivo - origen).Unit

	CrearFlecha(handle.CFrame, direccion, potencia, jugador, skillID, posicionObjetivo)

	local sonido = Instance.new("Sound", handle)
	sonido.SoundId = skillID and "rbxassetid://1312384661" or "rbxassetid://16211041" 
	sonido.Volume = 0.8
	sonido.PlayOnRemove = true; sonido:Destroy()
end)
