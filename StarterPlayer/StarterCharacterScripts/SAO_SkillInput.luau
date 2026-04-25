local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local CastSkillEvent = SAO_Events:WaitForChild("CastSkill") -- Crearemos esto ahora

local COOLDOWN_HABILIDAD = 1.5 -- Segundos de espera entre habilidades
local enCooldown = false

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		local char = player.Character
		if not char then return end

		-- 1. Validar que tiene un arma equipada (en la mano)
		local toolEquipado = char:FindFirstChildWhichIsA("Tool")
		if not toolEquipado then return end

		-- 2. Validar que tiene una habilidad seleccionada en la UI
		local habilidadEquipada = player:GetAttribute("EquippedSkill")
		if not habilidadEquipada or habilidadEquipada == "" then return end

		-- 3. Ejecutar si no está en cooldown
		if not enCooldown then
			enCooldown = true

			-- Opcional: Una animación de preparación aquí
			CastSkillEvent:FireServer() 

			task.wait(COOLDOWN_HABILIDAD)
			enCooldown = false
		end
	end
end)
