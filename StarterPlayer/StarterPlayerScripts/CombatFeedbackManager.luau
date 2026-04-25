local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events", 5)
local HitFeedbackEvent = SAO_Events:WaitForChild("HitFeedback", 5)

-- ==========================================
-- 🎥 FUNCIÓN DE CAMERA SHAKE (Segura)
-- ==========================================
-- En lugar de pelear con el CFrame de la cámara, movemos el CameraOffset del Humanoid.
-- Es 1000 veces más suave y nunca rompe la cámara.
local function ShakeCamera(intensity)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if not hum then return end

	-- Movimiento violento aleatorio
	local shakeX = (math.random() - 0.5) * intensity
	local shakeY = (math.random() - 0.5) * intensity
	local shakeZ = (math.random() - 0.5) * intensity

	hum.CameraOffset = Vector3.new(shakeX, shakeY, shakeZ)

	-- Regresar a la normalidad súper rápido
	TweenService:Create(hum, TweenInfo.new(0.15, Enum.EasingStyle.Bounce), {CameraOffset = Vector3.new(0,0,0)}):Play()
end

-- ==========================================
-- 💨 FUNCIÓN DE FOV PUNCH (Compatible con nuestro sistema)
-- ==========================================
local function FOVPunch(amount)
	-- USAMOS EL ATRIBUTO QUE CREAMOS ANTES, NUNCA TWEEN DIRECTO
	local currentFOV = camera:GetAttribute("TargetFOV") or 90
	camera.FieldOfView = currentFOV + amount -- Golpe instantáneo
	-- El RunService de tu otro script lo devolverá a la normalidad suavemente
end

-- ==========================================
-- ✨ EFECTOS VISUALES (SAO IMPACT)
-- ==========================================
local function CreateHitVFX(position, isCritical)
	local hitColor = isCritical and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 255)

	-- 1. Destello esférico expansivo (El clásico "Pop" de SAO)
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 255, 255)
	flash.Size = Vector3.new(0.5, 0.5, 0.5)
	flash.Position = position
	flash.Anchored = true
	flash.CanCollide = false
	flash.Parent = workspace

	TweenService:Create(flash, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(4, 4, 4),
		Transparency = 1,
		Color = hitColor
	}):Play()
	Debris:AddItem(flash, 0.2)

	-- 2. Partículas de corte digital
	local attachment = Instance.new("Attachment", workspace.Terrain)
	attachment.Position = position

	local sparks = Instance.new("ParticleEmitter", attachment)
	sparks.Texture = "rbxassetid://7148566336" -- Textura afilada
	sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
	sparks.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, hitColor)})
	sparks.Speed = NumberRange.new(40, 80)
	sparks.Drag = 4
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Lifetime = NumberRange.new(0.2, 0.4)
	sparks.LightEmission = 1
	sparks.Rate = 0

	sparks:Emit(isCritical and 25 or 12)
	Debris:AddItem(attachment, 1)

	-- 3. Sonido
	local sound = Instance.new("Sound", attachment)
	sound.SoundId = isCritical and "rbxassetid://6114983058" or "rbxassetid://6895079853"
	sound.Volume = isCritical and 1.5 or 0.8
	sound.Pitch = math.random(90, 110) / 100 
	sound:Play()
end

-- ==========================================
-- 💥 RECEPTOR DE IMPACTOS
-- ==========================================
HitFeedbackEvent.OnClientEvent:Connect(function(victimChar, attackerPlayer, hitPosition, damageAmount)
	local distance = (camera.CFrame.Position - hitPosition).Magnitude
	if distance > 100 then return end -- No renderizar peleas a 100 metros de ti

	local isMe = (localPlayer.Character == victimChar)
	local iAmAttacking = (attackerPlayer == localPlayer)
	local isCritical = damageAmount > 50 

	-- Efectos visuales para todos los que estén cerca
	CreateHitVFX(hitPosition, isCritical)

	-- Retroalimentación táctil/visual de impacto
	if isMe then
		-- Me pegaron: Temblor fuerte y distorsión de visión
		ShakeCamera(1.5)
		FOVPunch(8) 
	elseif iAmAttacking then
		-- Yo pegué: Temblor satisfactorio y Hit-Stop (Pausa épica)
		ShakeCamera(0.6)

		-- HIT-STOP: Congelamos TUS animaciones una fracción de segundo para darle "peso" al golpe
		local myHum = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")
		local myAnimator = myHum and myHum:FindFirstChildOfClass("Animator")

		if myAnimator then
			for _, track in ipairs(myAnimator:GetPlayingAnimationTracks()) do
				track:AdjustSpeed(0.0) -- Congelar
			end

			task.delay(0.08, function() -- 0.08 segundos de pausa (perfecto para combos)
				if myAnimator then
					for _, track in ipairs(myAnimator:GetPlayingAnimationTracks()) do
						track:AdjustSpeed(1.0) -- Descongelar
					end
				end
			end)
		end
	end
end)
