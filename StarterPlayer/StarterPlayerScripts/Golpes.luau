-- StarterPlayerScripts > CombatVFXController
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CombatEvent = ReplicatedStorage:WaitForChild("CombatEvent")

-- Función para crear la marca roja de impacto
local function createSAOMark(hitPart, position)
	local mark = Instance.new("Part")
	mark.Size = Vector3.new(0.2, 0.8, 0.2)
	mark.Material = Enum.Material.Neon
	mark.Color = Color3.fromRGB(255, 0, 0) -- Rojo brillante
	mark.CanCollide = false
	mark.Anchored = true
	mark.CFrame = CFrame.new(position) * CFrame.Angles(math.random(-1,1), math.random(-1,1), math.random(-1,1))
	mark.Parent = workspace.Terrain -- Terrain ignora ciertas físicas

	-- Soldar la marca al cuerpo del enemigo para que se mueva con él
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = mark
	weld.Part1 = hitPart
	weld.Parent = mark
	mark.Anchored = false

	-- Animación épica: La marca se expande y se desvanece
	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Size = Vector3.new(0, 2, 0), Transparency = 1}
	local tween = TweenService:Create(mark, tweenInfo, goal)

	tween:Play()
	tween.Completed:Wait()
	mark:Destroy()
end

CombatEvent.OnClientEvent:Connect(function(actionType, hitPart, position)
	if actionType == "RenderSAOMark" then
		createSAOMark(hitPart, position)
	end
end)
