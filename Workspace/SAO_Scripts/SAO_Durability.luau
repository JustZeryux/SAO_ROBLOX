local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local item = script.Parent

-- Nos aseguramos de que el objeto tenga el Atributo de Durabilidad. Si no lo tiene, se lo creamos por defecto.
if not item:GetAttribute("Durability") then
	item:SetAttribute("Durability", 100)
	item:SetAttribute("MaxDurability", 100)
end

-- ==========================================
-- 💎 EFECTO DE CRISTALES SAO
-- ==========================================
local function ShatterAndDestroy()
	-- Buscamos el centro físico del objeto (Handle en Tools, PrimaryPart en Modelos, o cualquier bloque)
	local centerPart = item:FindFirstChild("Handle") or item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")

	if centerPart then
		local pos = centerPart.Position

		-- Efecto de sonido de cristal rompiéndose
		local breakSound = Instance.new("Sound")
		breakSound.SoundId = "rbxassetid://2868266209" -- Sonido de ruptura estilo cristal
		breakSound.Volume = 1
		breakSound.Parent = workspace
		breakSound.PlayOnRemove = true
		breakSound:Destroy() -- Se destruye al instante pero PlayOnRemove hace que suene

		-- Si el ítem tiene un atributo "ShatterColor", usa ese color. Si no, usa el Azul SAO clásico.
		local colorCristal = item:GetAttribute("ShatterColor") or Color3.fromRGB(0, 200, 255)

		-- Generar 15 cristales volando por los aires
		for i = 1, 15 do
			local crystal = Instance.new("Part")
			crystal.Size = Vector3.new(0.6, 0.6, 0.6)
			crystal.Position = pos + Vector3.new(math.random(-10,10)/10, math.random(-10,10)/10, math.random(-10,10)/10)
			crystal.Material = Enum.Material.Neon
			crystal.Color = colorCristal
			crystal.CanCollide = false
			crystal.Parent = workspace

			-- Físicas para que exploten hacia afuera y giren
			crystal.AssemblyLinearVelocity = Vector3.new(math.random(-25,25), math.random(15,35), math.random(-25,25))
			crystal.AssemblyAngularVelocity = Vector3.new(math.random(-20,20), math.random(-20,20), math.random(-20,20))

			Debris:AddItem(crystal, 2)

			-- Animación: Se encogen hasta desaparecer (Típico de SAO)
			TweenService:Create(crystal, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = Vector3.new(0, 0, 0)
			}):Play()
		end
	end

	-- Destruimos el objeto original del juego
	item:Destroy()
end

-- ==========================================
-- 👁️ VIGILANTE DE DURABILIDAD
-- ==========================================
-- Este evento se dispara automáticamente cada vez que el valor "Durability" cambia
item:GetAttributeChangedSignal("Durability"):Connect(function()
	local currentDurability = item:GetAttribute("Durability")

	if currentDurability <= 0 then
		-- Desconectamos para que no se repita
		item:SetAttribute("Durability", 9999) 
		ShatterAndDestroy()
	end
end)
