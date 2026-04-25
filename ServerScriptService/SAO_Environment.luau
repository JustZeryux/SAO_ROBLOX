local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local camera = Workspace.CurrentCamera

-- ==========================================
-- ⚙️ CONFIGURACIÓN DEL MUNDO
-- ==========================================
local DURACION_DIA_MINUTOS = 24 
local VELOCIDAD_TIEMPO = 24 / DURACION_DIA_MINUTOS

local noiseScale = 0.05
local timeScale = 0.5
local baseWindPower = 15
local gustMultiplier = 30 

-- ==========================================
-- 🎨 INYECCIÓN DE GRÁFICOS NEXT-GEN (SAO VIBES)
-- ==========================================
local function inyectarEfectos()
	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds", Workspace.Terrain)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)

	-- Corrección de color para que los tonos se vean vivos como en un RPG
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	cc.Brightness = 0.05; cc.Contrast = 0.1; cc.Saturation = 0.2

	-- Brillo de luz (Glow/Bloom)
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.3; bloom.Size = 24; bloom.Threshold = 2

	-- Rayos de sol épicos
	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
	sunRays.Intensity = 0.05; sunRays.Spread = 0.8

	return clouds, atmosphere, cc
end

local clouds, atmosphere, colorCorrection = inyectarEfectos()

-- ==========================================
-- 🌪️ SISTEMA DE VFX DE VIENTO (VISUAL Y AUDIO)
-- ==========================================
-- Contenedor que seguirá a la cámara
local windAttachment = Instance.new("Attachment", Workspace.Terrain)

-- Líneas de Viento (Estilo Anime)
local windLines = Instance.new("ParticleEmitter", windAttachment)
windLines.Texture = "rbxassetid://7148566336" -- Textura afilada
windLines.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
windLines.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 1)})
windLines.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 4), NumberSequenceKeypoint.new(1, 0)})
windLines.Lifetime = NumberRange.new(0.5, 1)
windLines.Speed = NumberRange.new(80, 120)
windLines.SpreadAngle = Vector2.new(10, 10)
windLines.EmissionDirection = Enum.NormalId.Front
windLines.LockedToPart = false
windLines.Rate = 0

-- Hojas volando
local leaves = Instance.new("ParticleEmitter", windAttachment)
leaves.Texture = "rbxassetid://1432168940" -- Textura de hoja
leaves.Color = ColorSequence.new(Color3.fromRGB(120, 160, 80))
leaves.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1)})
leaves.Size = NumberSequence.new(0.8)
leaves.Lifetime = NumberRange.new(2, 4)
leaves.Speed = NumberRange.new(40, 60)
leaves.Rotation = NumberRange.new(0, 360)
leaves.RotSpeed = NumberRange.new(-200, 200)
leaves.SpreadAngle = Vector2.new(30, 30)
leaves.EmissionDirection = Enum.NormalId.Front
leaves.Rate = 0

-- Audio Dinámico (ID Oficial de Roblox sin problemas de permisos)
local windSound = Instance.new("Sound", windAttachment)
windSound.SoundId = "rbxassetid://6003728639" -- Viento oficial de Roblox
windSound.Looped = true
windSound.Volume = 0
windSound:Play()

-- ==========================================
-- 🌩️ PERFILES CLIMÁTICOS (AHORA CON VFX)
-- ==========================================
local Climas = {
	["Despejado"] = {
		CloudCover = 0.3, CloudDensity = 0.2, CloudColor = Color3.fromRGB(255, 255, 255),
		WindBase = 5, AtmosphereDensity = 0.2, FogEnd = 10000,
		VFX_Lines = 0, VFX_Leaves = 5, AmbientTint = Color3.fromRGB(255, 255, 255)
	},
	["Nublado"] = {
		CloudCover = 0.8, CloudDensity = 0.8, CloudColor = Color3.fromRGB(150, 150, 160),
		WindBase = 15, AtmosphereDensity = 0.4, FogEnd = 2000,
		VFX_Lines = 10, VFX_Leaves = 15, AmbientTint = Color3.fromRGB(220, 220, 230)
	},
	["Tormenta de Viento"] = {
		CloudCover = 0.95, CloudDensity = 0.9, CloudColor = Color3.fromRGB(80, 85, 95),
		WindBase = 45, AtmosphereDensity = 0.6, FogEnd = 800,
		VFX_Lines = 60, VFX_Leaves = 40, AmbientTint = Color3.fromRGB(180, 180, 200)
	}
}

local nombresClimas = {"Despejado", "Nublado", "Tormenta de Viento"}
local climaActual = "Despejado"
local targetVFXLines = 0
local targetVFXLeaves = 0

-- ==========================================
-- 🌀 TRANSICIÓN DE CLIMA
-- ==========================================
local function CambiarClima()
	local nuevoClima
	repeat nuevoClima = nombresClimas[math.random(1, #nombresClimas)] until nuevoClima ~= climaActual
	climaActual = nuevoClima

	local datos = Climas[climaActual]
	baseWindPower = datos.WindBase
	targetVFXLines = datos.VFX_Lines
	targetVFXLeaves = datos.VFX_Leaves

	local tweenInfo = TweenInfo.new(30, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	TweenService:Create(clouds, tweenInfo, {Cover = datos.CloudCover, Density = datos.CloudDensity, Color = datos.CloudColor}):Play()
	TweenService:Create(atmosphere, tweenInfo, {Density = datos.AtmosphereDensity}):Play()
	TweenService:Create(Lighting, tweenInfo, {FogEnd = datos.FogEnd}):Play()
	TweenService:Create(colorCorrection, tweenInfo, {TintColor = datos.AmbientTint}):Play()
end

task.spawn(function()
	while true do
		task.wait(math.random(200, 400))
		CambiarClima()
	end
end)

-- ==========================================
-- 🌍 BUCLE PRINCIPAL (Físicas, Audio y VFX)
-- ==========================================
local timeElapsed = 0

RunService.Heartbeat:Connect(function(deltaTime)
	timeElapsed += deltaTime

	-- ☀️ 1. CICLO DÍA/NOCHE
	Lighting.ClockTime += ((deltaTime / 60) * VELOCIDAD_TIEMPO)

	-- 🌪️ 2. CÁLCULO DEL VIENTO (Perlin Noise)
	local noiseX = math.noise(timeElapsed * noiseScale, 0, 0)
	local noiseZ = math.noise(0, timeElapsed * noiseScale, 0)
	local intensityNoise = math.noise(timeElapsed * timeScale, 100, 100) 

	local windDirection = Vector3.new(noiseX, 0, noiseZ)
	if windDirection.Magnitude > 0 then windDirection = windDirection.Unit else windDirection = Vector3.new(1, 0, 0) end

	local currentWindSpeed = baseWindPower + (intensityNoise * gustMultiplier)
	Workspace.GlobalWind = windDirection * math.max(1, currentWindSpeed)

	-- ✨ 3. ACTUALIZAR VFX Y AUDIO
	if camera then
		-- Movemos el emisor lejos de la cámara, "contra" el viento, para que las partículas vuelen hacia nosotros/alrededor
		local spawnPos = camera.CFrame.Position - (windDirection * 60) + Vector3.new(0, 20, 0)

		-- El Attachment debe mirar en la dirección del viento para que las partículas salgan por el "Front"
		windAttachment.WorldCFrame = CFrame.lookAt(spawnPos, spawnPos + windDirection)

		-- Modificamos la cantidad de partículas según las ráfagas
		local windIntensityRatio = math.clamp(currentWindSpeed / 60, 0, 1)

		windLines.Rate = targetVFXLines * windIntensityRatio
		leaves.Rate = targetVFXLeaves * windIntensityRatio

		-- Modificamos el sonido para que aúlle en las ráfagas fuertes
		windSound.Volume = math.clamp(currentWindSpeed / 80, 0, 1.2)
		windSound.Pitch = 0.8 + (windIntensityRatio * 0.4)
	end
end)
