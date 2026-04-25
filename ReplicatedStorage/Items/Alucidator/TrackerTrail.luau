local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SAO_HitEvent = ReplicatedStorage:WaitForChild("SAO_HitEvent")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players") 
local Debris = game:GetService("Debris") 

-- Attachments de la hoja
local basePosAtt = Handle:WaitForChild("Base")
local tipPosAtt = Handle:WaitForChild("Punta")

local lastBasePos = nil
local lastTipPos = nil
local lastMidPos = nil 
local raycastConnection = nil

local character = nil
local humanoid = nil
local isAttacking = false
local hitCharacters = {} 

-- ==========================================
-- 📊 ATRIBUTOS DE DAÑO
-- ==========================================
local BASE_DAMAGE = 15
local STR_MULTIPLIER = 1.5 -- Cuánto daño extra otorga cada punto de STR. ¡Súbelo si quieres golpes más devastadores!

-- ==========================================
-- 🛡️ ESCÁNER DE DAÑO PROYECTIVO (Actualizado con Sistemas SAO)
-- ==========================================
local function escanearCorte()
	if not character or not humanoid then return end

	local currentBasePos = basePosAtt.WorldPosition
	local currentTipPos = tipPosAtt.WorldPosition
	local currentMidPos = (currentBasePos + currentTipPos) / 2

	if lastBasePos and lastTipPos and lastMidPos then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character, Tool}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local rayoBase = currentBasePos - lastBasePos
		local rayoMid = currentMidPos - lastMidPos
		local rayoTip = currentTipPos - lastTipPos

		local function checkHit(startPos, direction)
			local result = workspace:Raycast(startPos, direction, raycastParams)
			if result and result.Instance then
				local victimChar = result.Instance.Parent
				local victimHumanoid = victimChar:FindFirstChild("Humanoid")

				if victimHumanoid and victimHumanoid.Health > 0 and victimChar ~= character then
					if not hitCharacters[victimChar] then
						hitCharacters[victimChar] = true

						local attackerPlayer = Players:GetPlayerFromCharacter(character)

						-- 🧮 CÁLCULO DE DAÑO CON FUERZA (STR)
						local currentSTR = 10 -- Base por defecto
						if attackerPlayer then
							currentSTR = attackerPlayer:GetAttribute("STR") or 10
						end
						local danoCalculado = BASE_DAMAGE + (currentSTR * STR_MULTIPLIER)

						-- 1. 🏷️ ETIQUETA DE LAST ATTACK (Para Loot y XP)
						if attackerPlayer then
							-- Etiqueta clásica de Roblox
							local tag = victimHumanoid:FindFirstChild("creator")
							if not tag then
								tag = Instance.new("ObjectValue")
								tag.Name = "creator"
								tag.Parent = victimHumanoid
							end
							tag.Value = attackerPlayer
							Debris:AddItem(tag, 2) 

							-- ✨ NUEVA ETIQUETA PARA EL SISTEMA DE LOOT
							victimHumanoid:SetAttribute("LastAttacker", attackerPlayer.Name)
						end

						-- 2. 🛡️ SISTEMA DE DEFENSA (PvP)
						if victimChar:GetAttribute("IsParrying") then
							-- PARRY PERFECTO: Cero daño.
							print("¡Parry perfecto de " .. victimChar.Name .. "!")
							return 
						end

						local danoFinal = danoCalculado

						if victimChar:GetAttribute("IsBlocking") then
							-- BLOQUEO NORMAL: Se traga solo el 30% del daño
							print(victimChar.Name .. " bloqueó parte del corte.")
							danoFinal = danoCalculado * 0.3 
						end

						-- 3. 💥 APLICAR DAÑO Y DESMEMBRAMIENTO
						-- Llamamos a la función global del servidor que instalamos antes
						if _G.RegisterHit then
							_G.RegisterHit(victimHumanoid, result.Instance, danoFinal)
						else
							-- RESPALDO: Si por alguna razón el sistema global no está listo
							victimHumanoid:TakeDamage(danoFinal)

							-- ENVIAR HITMARKER SOLO AL ATACANTE
							if attackerPlayer then
								SAO_HitEvent:FireClient(attackerPlayer, result.Instance, result.Position, danoFinal, false)
							end

							-- ENVIAR HITMARKER SOLO A LA VÍCTIMA
							local victimPlayer = Players:GetPlayerFromCharacter(victimChar)
							if victimPlayer then
								SAO_HitEvent:FireClient(victimPlayer, result.Instance, result.Position, danoFinal, false)
							end
						end
					end
				end
			end
		end

		checkHit(lastBasePos, rayoBase)
		checkHit(lastMidPos, rayoMid)
		checkHit(lastTipPos, rayoTip)
	end

	lastBasePos = currentBasePos
	lastTipPos = currentTipPos
	lastMidPos = currentMidPos
end

-- ==========================================
-- ⚔️ ATAQUE CON DOBLE GOLPE
-- ==========================================
Tool.Activated:Connect(function()
	-- 🛠️ LA SOLUCIÓN ESTÁ AQUÍ: Primero definimos character, lueeeego revisamos sus atributos
	character = Tool.Parent
	if not character or not character:FindFirstChild("Humanoid") then return end

	if isAttacking or character:GetAttribute("IsBlocking") then return end
	isAttacking = true

	humanoid = character:FindFirstChild("Humanoid")

	table.clear(hitCharacters)
	lastBasePos = nil
	lastTipPos = nil
	lastMidPos = nil

	-- Prendemos el escáner
	raycastConnection = RunService.Heartbeat:Connect(escanearCorte)

	task.delay(0.3, function()
		if isAttacking then
			table.clear(hitCharacters) 
		end
	end)

	task.wait(0.6) 

	if raycastConnection then raycastConnection:Disconnect() end
	isAttacking = false
end)

Tool.Unequipped:Connect(function()
	if raycastConnection then raycastConnection:Disconnect() end
	isAttacking = false
	table.clear(hitCharacters)
end)
