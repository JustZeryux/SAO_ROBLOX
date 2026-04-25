local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local mob = script.Parent
local humanoid = mob:WaitForChild("Humanoid")
local rootPart = mob:WaitForChild("HumanoidRootPart")
local head = mob:WaitForChild("Head")
local animator = humanoid:WaitForChild("Animator")

-- ⚔️ EL ARMA DEL TRYHARD
local espada = mob:WaitForChild("Alucinator")
local handle = espada:WaitForChild("Handle")

-- ==========================================
-- ⚙️ CONFIGURACIÓN DEL MOB (ULTRA SWEAT IA)
-- ==========================================
local NOMBRE_MOB = "Xx_DemonSlayer_xX"
local VIDA_MAXIMA = 900 
local DANO_BASICO = 70
local RANGO_AGGRO = 270 
local DISTANCIA_ATAQUE = 8 -- ESTRICTO: Si no estás a esta distancia, no ataca.

humanoid.MaxHealth = VIDA_MAXIMA
humanoid.Health = VIDA_MAXIMA

local NORMAL_SPEED = 22 -- Más rápido por defecto
local SPRINT_SPEED = 45 -- Vuela hacia ti
local SLIDE_SPEED = 45  -- Dash rapidísimo
local SLIDE_DURATION = 0.35 -- Dash corto y preciso, no se queda atorado rodando

-- Estados del NPC
local isDead = false
local isAttacking = false
local isRolling = false
local isSprinting = false
local isBlocking = false
local isParrying = false

-- ==========================================
-- 🏃 CARGA DE ANIMACIONES COMPLETAS
-- ==========================================
local function loadAnimSeguro(animName, priority)
	local animObject = script:FindFirstChild(animName)
	if not animObject then warn("Falta animación en el NPC: " .. animName) return nil end
	local track = animator:LoadAnimation(animObject)
	track.Priority = priority
	return track
end

local runTrack = loadAnimSeguro("Run", Enum.AnimationPriority.Movement)
local walkTrack = loadAnimSeguro("Walking", Enum.AnimationPriority.Movement)
local rollTrack = loadAnimSeguro("Rolling", Enum.AnimationPriority.Action)

local slashTrack = loadAnimSeguro("Slash", Enum.AnimationPriority.Action3)
local slashCorriendoTrack = loadAnimSeguro("AtaqueCorriendo", Enum.AnimationPriority.Action3)
local contraataqueTrack = loadAnimSeguro("Contraataque", Enum.AnimationPriority.Action4)

local bloqueoTrack = loadAnimSeguro("Bloqueo", Enum.AnimationPriority.Action2)
local parryTrack = loadAnimSeguro("Parry", Enum.AnimationPriority.Action3)

if runTrack then runTrack.Looped = true end
if walkTrack then walkTrack.Looped = true end
if bloqueoTrack then bloqueoTrack.Looped = true end

-- ==========================================
-- 📊 INTERFAZ DE SAO (HUD)
-- ==========================================
local function crearUI()
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	local bg = Instance.new("BillboardGui", head)
	bg.Name = "SAO_HUD"; bg.Size = UDim2.new(4.5, 0, 3, 0); bg.StudsOffset = Vector3.new(0, 3.5, 0); bg.AlwaysOnTop = true; bg.MaxDistance = 150 

	local nameLabel = Instance.new("TextLabel", bg)
	nameLabel.Size = UDim2.new(1, 0, 0, 18); nameLabel.Position = UDim2.new(0, 0, 0, 25); nameLabel.BackgroundTransparency = 1
	nameLabel.Text = NOMBRE_MOB; nameLabel.TextColor3 = Color3.new(1, 1, 1); nameLabel.Font = Enum.Font.Jura; nameLabel.TextScaled = true
	Instance.new("UIStroke", nameLabel).Thickness = 1

	local barsContainer = Instance.new("Frame", bg)
	barsContainer.Size = UDim2.new(0.8, 0, 0, 30); barsContainer.Position = UDim2.new(0.1, 0, 0, 45); barsContainer.BackgroundTransparency = 1

	local capas = math.clamp(math.ceil(VIDA_MAXIMA / 100), 1, 5)
	local hpBars = {}

	for i = 1, capas do
		local bgBar = Instance.new("Frame", barsContainer); bgBar.Size = UDim2.new(1 - (i * 0.05), 0, 0, 6); bgBar.Position = UDim2.new((i * 0.025), 0, 0, (i - 1) * 6); bgBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); bgBar.BackgroundTransparency = 0.2; bgBar.BorderSizePixel = 0; Instance.new("UICorner", bgBar).CornerRadius = UDim.new(0, 2)
		local fillBar = Instance.new("Frame", bgBar); fillBar.Size = UDim2.new(1, 0, 1, 0); fillBar.BackgroundColor3 = Color3.fromRGB(255, 0, 50); fillBar.BorderSizePixel = 0; Instance.new("UICorner", fillBar).CornerRadius = UDim.new(0, 2); hpBars[i] = fillBar
	end

	humanoid.HealthChanged:Connect(function(health)
		local hpPorBarra = VIDA_MAXIMA / capas
		for i = 1, capas do
			local barraMin = (capas - i) * hpPorBarra; local barraMax = (capas - i + 1) * hpPorBarra
			if health >= barraMax then hpBars[i].Size = UDim2.new(1, 0, 1, 0)
			elseif health <= barraMin then hpBars[i].Size = UDim2.new(0, 0, 1, 0)
			else hpBars[i].Size = UDim2.new((health - barraMin) / hpPorBarra, 0, 1, 0) end
		end
	end)
end
crearUI()

-- ==========================================
-- 🛡️ SISTEMA DEFENSIVO DEL NPC
-- ==========================================
local function DetenerBloqueo()
	if not isBlocking then return end
	isBlocking = false
	isParrying = false
	mob:SetAttribute("IsBlocking", false)
	mob:SetAttribute("IsParrying", false)
	if bloqueoTrack then bloqueoTrack:Stop(0.1) end
	humanoid.WalkSpeed = NORMAL_SPEED
end

local function EjecutarBloqueo()
	if isAttacking or isRolling or isBlocking then return end
	isBlocking = true
	isParrying = true 

	mob:SetAttribute("IsBlocking", true)
	mob:SetAttribute("IsParrying", true)
	humanoid.WalkSpeed = 4 

	if bloqueoTrack then bloqueoTrack:Play(0.1) end

	-- Un pro hace parry y suelta la guardia rápido, no se queda de tortuga
	task.delay(0.35, function()
		if isBlocking then 
			DetenerBloqueo() -- Suelta el bloqueo casi al instante
		end
	end)
end

-- ==========================================
-- ✨ SISTEMA DE COMBATE OFENSIVO
-- ==========================================
local slashTrail = handle:FindFirstChild("SlashTrail")

local function EjecutarAtaque(trackAUsar)
	if isAttacking or isRolling then return end
	DetenerBloqueo() 

	isAttacking = true
	mob:SetAttribute("IsAttacking", true)

	if trackAUsar then trackAUsar:Play(0.1) end
	if slashTrail then slashTrail.Enabled = true end

	pcall(function()
		local vfxContenedorOriginal = espada:FindFirstChild("Slash", true)
		if vfxContenedorOriginal then
			local vfxClon = vfxContenedorOriginal:Clone()
			vfxClon.Parent = rootPart 
			if vfxClon:IsA("Attachment") then vfxClon.Position = Vector3.new(0, 0, -3) end
			for _, particula in pairs(vfxClon:GetDescendants()) do
				if particula:IsA("ParticleEmitter") then
					particula.EmissionDirection = Enum.NormalId.Front
					particula.LockedToPart = true 
					particula:Emit(particula:GetAttribute("EmitCount") or 15)
				end
			end
			Debris:AddItem(vfxClon, 0.5)
		end
	end)

	task.wait(0.3) -- Ataque más rápido
	if slashTrail then slashTrail.Enabled = false end
	isAttacking = false
	mob:SetAttribute("IsAttacking", false)
end

-- 💥 Detectar golpes
local hitDebounce = {}
handle.Touched:Connect(function(hit)
	if not isAttacking or isDead then return end
	if hit:IsDescendantOf(mob) then return end

	local enemigoHum = hit.Parent:FindFirstChild("Humanoid")
	local charJugador = hit.Parent

	if enemigoHum and not hitDebounce[enemigoHum] then
		hitDebounce[enemigoHum] = true

		local hizoParry = charJugador:GetAttribute("IsParrying")
		local estaBloqueando = charJugador:GetAttribute("IsBlocking")

		if hizoParry then
			isAttacking = false
			mob:SetAttribute("IsAttacking", false)
			rootPart.AssemblyLinearVelocity = rootPart.CFrame.LookVector * -35
			task.wait(0.5) -- Se recupera más rápido del aturdimiento
		elseif estaBloqueando then
			enemigoHum:TakeDamage(DANO_BASICO * 0.15) 
		else
			enemigoHum:TakeDamage(DANO_BASICO) 
			local hitOriginal = espada:FindFirstChild("Hit", true)
			if hitOriginal and hitOriginal:IsA("Attachment") then
				local hitClon = hitOriginal:Clone()
				hitClon.Parent = workspace.Terrain 
				hitClon.WorldPosition = handle.Position 
				for _, p in pairs(hitClon:GetChildren()) do
					if p:IsA("ParticleEmitter") then p:Emit(p:GetAttribute("EmitCount") or 15) end
				end
				Debris:AddItem(hitClon, 1.5)
			end
		end

		task.delay(0.3, function() hitDebounce[enemigoHum] = nil end)
	end
end)

-- ==========================================
-- 💨 MOVIMIENTO SWEAT (DASH/ROLL)
-- ==========================================
local function EjecutarEvasion(direccionType)
	if isRolling or isAttacking then return end
	DetenerBloqueo()

	isRolling = true
	if rollTrack then rollTrack:Play(0.1) end

	local slideForce = Instance.new("BodyVelocity")
	slideForce.MaxForce = Vector3.new(100000, 0, 100000)

	local direccion = rootPart.CFrame.LookVector
	if direccionType == "Atras" then
		direccion = rootPart.CFrame.LookVector * -1
	elseif direccionType == "Lado" then
		direccion = rootPart.CFrame.RightVector * (math.random(1,2)==1 and 1 or -1)
	elseif direccionType == "Adelante" then
		direccion = rootPart.CFrame.LookVector
	end

	slideForce.Velocity = direccion * SLIDE_SPEED
	slideForce.Parent = rootPart
	Debris:AddItem(slideForce, SLIDE_DURATION) 

	task.delay(SLIDE_DURATION, function()
		isRolling = false
	end)
end

-- ==========================================
-- 🧠 INTELIGENCIA ARTIFICIAL "ULTRA INSTINTO"
-- ==========================================
local function buscarObjetivo()
	local objetivo = nil; local distMin = RANGO_AGGRO
	for _, jugador in pairs(Players:GetPlayers()) do
		local char = jugador.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (rootPart.Position - hrp.Position).Magnitude
				if dist < distMin then distMin = dist; objetivo = hrp end
			end
		end
	end
	return objetivo, distMin
end

humanoid:EquipTool(espada)

task.spawn(function()
	-- BUCLE ULTRA RÁPIDO (0.05s) PARA REACCIONES INSTANTÁNEAS
	while task.wait(0.05) do
		if isDead then break end
		if espada.Parent ~= mob then humanoid:EquipTool(espada) end

		local objetivo, distancia = buscarObjetivo()

		if objetivo and not isRolling then
			rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(objetivo.Position.X, rootPart.Position.Y, objetivo.Position.Z))

			local jugadorAtacando = objetivo.Parent:GetAttribute("IsAttacking")

			-- 🔥 REACCIÓN DEFENSIVA SUPREMA (Instinto puro)
			if jugadorAtacando and distancia <= DISTANCIA_ATAQUE + 4 and not isAttacking and not isBlocking then
				local suerte = math.random(1, 100)
				if suerte <= 60 then
					-- 60% Hace Parry Perfecto
					EjecutarBloqueo()
					if parryTrack then parryTrack:Play() end
					continue -- Salta el resto del código para enfocarse en defender
				elseif suerte <= 90 then
					-- 30% Rueda hacia un lado o atrás para esquivar
					EjecutarEvasion(math.random(1,2)==1 and "Lado" or "Atras")
					continue
				end
				-- 10% de probabilidad de equivocarse y comerse el golpe
			end

			-- === DISTANCIA LEJANA: ACERCARSE ===
			if distancia > 35 then
				DetenerBloqueo()
				humanoid.WalkSpeed = SPRINT_SPEED
				humanoid:MoveTo(objetivo.Position)
				if runTrack and not runTrack.IsPlaying then runTrack:Play() end
				if walkTrack then walkTrack:Stop() end

				-- Dash hacia adelante para cerrar brecha más rápido (Sweat move)
				if math.random(1, 20) == 1 then EjecutarEvasion("Adelante") end

				-- === DISTANCIA MEDIA: ORBITAR ===
			elseif distancia > DISTANCIA_ATAQUE then
				humanoid.WalkSpeed = NORMAL_SPEED
				if walkTrack and not walkTrack.IsPlaying and not isBlocking then walkTrack:Play() end
				if runTrack then runTrack:Stop() end

				-- Orbita al jugador perfectamente de lado a lado
				local sentido = math.random(1, 2) == 1 and 1 or -1
				local posicionOrbita = objetivo.Position + (objetivo.CFrame.RightVector * (10 * sentido)) + (objetivo.CFrame.LookVector * math.random(-5, 5))
				humanoid:MoveTo(posicionOrbita)

				if math.random(1, 15) == 1 then humanoid.Jump = true end

				-- === DISTANCIA DE COMBATE (CERRADA) ===
			else
				humanoid.WalkSpeed = NORMAL_SPEED

				-- Se mueve todo el tiempo intentando ir a tus espaldas
				humanoid:MoveTo(objetivo.Position + (objetivo.CFrame.RightVector * math.random(-12, 12)))

				-- Salta en tu cara molestando
				if math.random(1, 8) == 1 then humanoid.Jump = true end

				-- ⚔️ LÓGICA DE ATAQUE ESTRICTA
				if not isAttacking and not isBlocking and not isRolling then
					-- Solo ataca si DEFINITIVAMENTE estás cerca
					if distancia <= DISTANCIA_ATAQUE then
						-- Si acaba de soltar un parry exitoso, usa el Contraataque
						if isParrying and contraataqueTrack then
							EjecutarAtaque(contraataqueTrack)
						else
							-- Mezcla ataques normales
							local velocidadRaiz = rootPart.AssemblyLinearVelocity.Magnitude
							if velocidadRaiz > 15 and slashCorriendoTrack then
								EjecutarAtaque(slashCorriendoTrack)
							else
								EjecutarAtaque(slashTrack)
							end

							-- SWEAT MOVE: Ataca e inmediatamente rueda hacia atrás a veces para que no le pegues
							if math.random(1, 4) == 1 then
								task.delay(0.4, function()
									EjecutarEvasion("Atras")
								end)
							end
						end
					end
				end
			end
		elseif not objetivo then
			DetenerBloqueo()
			humanoid.WalkSpeed = NORMAL_SPEED
			if runTrack then runTrack:Stop() end
			if walkTrack then walkTrack:Stop() end
		end
	end
end)

-- ==========================================
-- 💀 MUERTE DEL NPC
-- ==========================================
humanoid.Died:Connect(function()
	isDead = true
	if runTrack then runTrack:Stop() end
	if walkTrack then walkTrack:Stop() end
	if bloqueoTrack then bloqueoTrack:Stop() end
	for _, p in ipairs(mob:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
	TweenService:Create(rootPart, TweenInfo.new(1), {Transparency = 1}):Play()
	Debris:AddItem(mob, 2)
end)
