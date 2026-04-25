local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("SAO_Survival"):WaitForChild("Remotes")
local Items = ReplicatedStorage.SAO_Survival.Items

local ServerInventories = {}
local TreeData = {} 
local ActiveFirepits = {} 

local TREE_MAX_HEALTH = 5
local RESPAWN_TIME = 30 -- Segundos que tarda en reaparecer un árbol

-- =========================================================
-- 🌳 GENERADOR DE BARRA SAO (Igual que antes)
-- =========================================================
local function CreateTreeHealthBar(tree)
	local bg = Instance.new("BillboardGui")
	bg.Name = "SAO_TreeBar"
	bg.Size = UDim2.new(4, 0, 0.4, 0)
	bg.StudsOffset = Vector3.new(0, 5, 0)
	bg.AlwaysOnTop = true
	bg.Parent = tree

	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Background"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bgFrame.BackgroundTransparency = 0.4
	bgFrame.Parent = bg
	Instance.new("UICorner", bgFrame).CornerRadius = UDim.new(0.5, 0)

	local fillFrame = Instance.new("Frame")
	fillFrame.Name = "Fill"
	fillFrame.Size = UDim2.new(1, 0, 1, 0)
	fillFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	fillFrame.BorderSizePixel = 0
	fillFrame.Parent = bgFrame
	Instance.new("UICorner", fillFrame).CornerRadius = UDim.new(0.5, 0)

	return fillFrame
end

-- =========================================================
-- 🪓 SISTEMA DE RECOLECCIÓN, DROPS Y RESPAWN
-- =========================================================
Remotes.HarvestEvent.OnServerEvent:Connect(function(player, itemName, amount, targetNode)
	local character = player.Character
	if not character or not targetNode or targetNode.Name ~= "Tree" then return end

	local equippedTool = character:FindFirstChildOfClass("Tool")
	if not equippedTool or equippedTool.Name ~= "Axe" then return end
	if (character.HumanoidRootPart.Position - targetNode.Position).Magnitude > 20 then return end

	if not TreeData[targetNode] then
		TreeData[targetNode] = TREE_MAX_HEALTH
		CreateTreeHealthBar(targetNode)
	end

	TreeData[targetNode] = TreeData[targetNode] - 1
	local currentHealth = TreeData[targetNode]
	local healthPercent = math.clamp(currentHealth / TREE_MAX_HEALTH, 0, 1)

	local treeBar = targetNode:FindFirstChild("SAO_TreeBar")
	if treeBar and treeBar:FindFirstChild("Background") then
		local fill = treeBar.Background.Fill
		TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(healthPercent, 0, 1, 0)}):Play()

		local targetColor = Color3.fromRGB(0, 255, 0)
		if healthPercent <= 0.5 then targetColor = Color3.fromRGB(255, 200, 0) end
		if healthPercent <= 0.2 then targetColor = Color3.fromRGB(255, 0, 0) end
		TweenService:Create(fill, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
	end

	-- Destrucción, Drops Físicos y Respawn
	if currentHealth <= 0 then
		TreeData[targetNode] = nil

		-- 1. Generar Drop Físico
		local woodDropModel = ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("WoodDrop")
		if woodDropModel then
			local drop = woodDropModel:Clone()
			drop:PivotTo(targetNode.CFrame * CFrame.new(0, 1, 0)) -- Aparece justo donde estaba el árbol
			drop.Parent = workspace

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Recoger Madera"
			prompt.ObjectText = "Wood legs"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.Parent = drop:IsA("BasePart") and drop or drop.PrimaryPart

			-- Evento al recoger el drop físico
			prompt.Triggered:Connect(function(interactPlayer)
				if not ServerInventories[interactPlayer.Name] then ServerInventories[interactPlayer.Name] = {} end
				ServerInventories[interactPlayer.Name]["Wood legs"] = (ServerInventories[interactPlayer.Name]["Wood legs"] or 0) + 1
				Remotes.UpdateInventory:FireClient(interactPlayer, ServerInventories[interactPlayer.Name])
				drop:Destroy()
			end)
		end

		-- 2. Sistema de Respawn (Ocultamos el árbol en vez de destruirlo)
		targetNode.Transparency = 1
		targetNode.CanCollide = false
		if treeBar then treeBar:Destroy() end

		task.delay(RESPAWN_TIME, function()
			targetNode.Transparency = 0
			targetNode.CanCollide = true
			TreeData[targetNode] = TREE_MAX_HEALTH
		end)
	end
end)

-- =========================================================
-- 🔨 SISTEMA DE CONSTRUCCIÓN Y COCINA (Sin cambios)
-- =========================================================
Remotes.CraftEvent.OnServerEvent:Connect(function(player, itemName, cframe)
	local itemModule = Items:FindFirstChild(itemName)
	if not itemModule then return end
	local itemData = require(itemModule)
	local playerInv = ServerInventories[player.Name] or {}
	local canBuild = true

	for reqItem, reqAmount in pairs(itemData.Ingredients) do
		if (playerInv[reqItem] or 0) < reqAmount then canBuild = false break end
	end

	if canBuild then
		for reqItem, reqAmount in pairs(itemData.Ingredients) do
			playerInv[reqItem] = playerInv[reqItem] - reqAmount
		end
		Remotes.UpdateInventory:FireClient(player, ServerInventories[player.Name])

		local originalModel = ReplicatedStorage:FindFirstChild(itemData.ModelName)
		if originalModel then
			local newStructure = originalModel:Clone()
			newStructure:PivotTo(cframe)
			newStructure.Parent = workspace

			if itemName == "Firepit" then
				table.insert(ActiveFirepits, newStructure)
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Cocinar Carne"
				prompt.ObjectText = "Firepit"
				prompt.KeyboardKeyCode = Enum.KeyCode.E
				prompt.HoldDuration = 1.5
				prompt.Parent = newStructure.PrimaryPart or newStructure:FindFirstChildWhichIsA("BasePart")

				prompt.Triggered:Connect(function(interactPlayer)
					local inv = ServerInventories[interactPlayer.Name] or {}
					if (inv["Raw Meat"] or 0) > 0 then
						inv["Raw Meat"] = inv["Raw Meat"] - 1
						inv["Cooked Meat"] = (inv["Cooked Meat"] or 0) + 1
						Remotes.UpdateInventory:FireClient(interactPlayer, inv)
					end
				end)
			end
		end
	end
end)

-- =========================================================
-- ❤️ AURA DE CURACIÓN Y 🎣 SISTEMA DE PESCA
-- =========================================================
-- Curación
task.spawn(function()
	while task.wait(1) do
		for _, firepit in ipairs(ActiveFirepits) do
			if firepit and firepit.PrimaryPart then
				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
						if (char.HumanoidRootPart.Position - firepit.PrimaryPart.Position).Magnitude <= 15 then 
							local hum = char.Humanoid
							hum.Health = math.min(hum.MaxHealth, hum.Health + 5)
						end
					end
				end
			end
		end
	end
end)

-- Configurar todas las zonas de pesca al iniciar
for _, zone in ipairs(workspace:GetChildren()) do
	if zone.Name == "FishingZone" then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pescar"
		prompt.ObjectText = "Agua"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 3 -- Tarda 3 segundos en sacar algo
		prompt.Parent = zone

		prompt.Triggered:Connect(function(player)
			if not ServerInventories[player.Name] then ServerInventories[player.Name] = {} end

			-- Probabilidad: 70% pescado, 30% nada
			if math.random(1, 100) <= 70 then
				ServerInventories[player.Name]["Raw Meat"] = (ServerInventories[player.Name]["Raw Meat"] or 0) + 1
				Remotes.UpdateInventory:FireClient(player, ServerInventories[player.Name])
				print(player.Name .. " atrapó un pez.")
			else
				print(player.Name .. " no atrapó nada esta vez.")
			end
		end)
	end
end
