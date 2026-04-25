local Tool = script.Parent
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local animator = nil
local rootPart = nil
local mouse = player:GetMouse()

local eventoDisparo = Tool:WaitForChild("DispararPua") -- Asegúrate de que el RemoteEvent exista
local HabilidadesData = require(ReplicatedStorage:WaitForChild("SAO_Modules"):WaitForChild("Habilidades"))

local isUsingSkill = false
local skillConfig = { maxSP = 100 }

local function updateSPBar(newSP)
	local playerGui = player:FindFirstChild("PlayerGui"); if not playerGui then return end
	local saoHUD = playerGui:FindFirstChild("SAO_HologramSystem")
	if saoHUD and saoHUD:FindFirstChild("HUD_Container") and saoHUD.HUD_Container:FindFirstChild("SP_Bar") then
		local fill = saoHUD.HUD_Container.SP_Bar:FindFirstChild("Fill")
		local percentage = math.clamp(newSP / skillConfig.maxSP, 0, 1)
		if fill then TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percentage, 0, 1, 0)}):Play() end
	end
end

local function UseThrowSkill()
	if isUsingSkill or not Tool.Parent == character then return end

	-- Si no tiene nada equipado, usa QuickDraw por defecto
	local equippedSkillID = character:GetAttribute("EquippedSkill") or "QuickDraw"
	local skillData = HabilidadesData[equippedSkillID]
	if not skillData then return end

	local currentSP = character:GetAttribute("SP") or 100 
	if currentSP < skillData.CostoSP then return end

	character:SetAttribute("SP", currentSP - skillData.CostoSP)
	updateSPBar(currentSP - skillData.CostoSP)
	isUsingSkill = true

	local animObj = Tool:FindFirstChild(skillData.Animacion) or script:FindFirstChild(skillData.Animacion)
	if animObj then
		local track = animator:LoadAnimation(animObj)
		track.Priority = Enum.AnimationPriority.Action4
		track:Play(0.05)
	end

	-- Filtro visual de pantalla
	local flash = Instance.new("ColorCorrectionEffect", game.Lighting)
	flash.TintColor = skillData.ColorPrimario; flash.Saturation = -0.5
	TweenService:Create(flash, TweenInfo.new(0.3), {TintColor = Color3.fromRGB(255,255,255), Saturation = 0}):Play()
	Debris:AddItem(flash, 0.3)

	-- Evasión: El Dash hacia atrás (Valor negativo)
	if skillData.VelocidadDash ~= 0 then
		local bv = Instance.new("BodyVelocity", rootPart)
		bv.MaxForce = Vector3.new(1e6, 0, 1e6)
		-- Al ser negativo, lo empujará hacia atrás de donde esté mirando
		bv.Velocity = rootPart.CFrame.LookVector * skillData.VelocidadDash
		Debris:AddItem(bv, 0.25)
	end

	-- Mandar disparo al servidor (Calculamos potencia según la habilidad)
	local potenciaSkill = 150
	if equippedSkillID == "FixPierce" then potenciaSkill = 400 end -- Sniper súper rápido

	-- Enviamos la posición donde apunta el mouse
	eventoDisparo:FireServer(mouse.Hit.Position, potenciaSkill, equippedSkillID)

	task.wait(skillData.Cooldown)
	isUsingSkill = false
end

Tool.Equipped:Connect(function()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	animator = humanoid:WaitForChild("Animator")
	if not character:GetAttribute("SP") then character:SetAttribute("SP", skillConfig.maxSP); updateSPBar(skillConfig.maxSP) end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and Tool.Parent == character and input.KeyCode == Enum.KeyCode.E then UseThrowSkill() end
end)
