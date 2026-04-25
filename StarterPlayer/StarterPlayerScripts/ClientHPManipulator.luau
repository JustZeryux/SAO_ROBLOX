local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local updateHPRemote = ReplicatedStorage:WaitForChild("UpdateHP")
local attachHPRemote = ReplicatedStorage:WaitForChild("AttachHPBar")

local playerMeshCache = {}
local activePlayerAccessories = {} 

local function CreateEditableMeshForPlayerBar(player, barMeshPart)
	if playerMeshCache[player] and playerMeshCache[player][barMeshPart] then return end

	local success, result = pcall(function()
		local meshContent = Content.fromUri(barMeshPart.MeshId)
		return AssetService:CreateEditableMeshAsync(meshContent)
	end)

	if not success or not result then return end

	local editableMesh = result
	print("✅ EditableMesh cargado para", player.Name)

	local originalVertices = {}
	local minX = math.huge
	local maxX = -math.huge
	local anchorVertexId = nil

	for _, vid in ipairs(editableMesh:GetVertices()) do
		local pos = editableMesh:GetPosition(vid)
		originalVertices[vid] = pos
		if pos.X < minX then minX = pos.X end
		if pos.X > maxX then 
			maxX = pos.X 
			anchorVertexId = vid -- Guardamos el ID del vértice que servirá de ancla derecha
		end
	end

	playerMeshCache[player] = {}
	playerMeshCache[player][barMeshPart] = {
		editableMesh = editableMesh,
		originalVertices = originalVertices,
		minX = minX, 
		maxX = maxX,
		anchorVertexId = anchorVertexId
	}
end

attachHPRemote.OnClientEvent:Connect(function(barOwnerPlayer)
	local character = barOwnerPlayer.Character
	if not character then return end

	if activePlayerAccessories[barOwnerPlayer.Name] then
		local oldAcc = activePlayerAccessories[barOwnerPlayer.Name]
		if oldAcc and oldAcc.Parent then oldAcc:Destroy() end
	end

	local accessory = character:WaitForChild("SAO_HealthBarAccessory", 10)
	if not accessory then return end
	activePlayerAccessories[barOwnerPlayer.Name] = accessory

	local handle = accessory:WaitForChild("Handle", 5)
	local greenBarPart = handle:WaitForChild("GreenBar", 5)

	CreateEditableMeshForPlayerBar(barOwnerPlayer, greenBarPart)

	local partsOffsets = {}
	for _, obj in pairs(accessory:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true 
			partsOffsets[obj] = handle.CFrame:ToObjectSpace(obj.CFrame)
		end
	end

	local torso = character:WaitForChild("HumanoidRootPart")
	local initialTorsoOffset = torso.CFrame:ToObjectSpace(handle.CFrame)

	for _, obj in pairs(accessory:GetDescendants()) do
		if obj:IsA("Weld") or obj:IsA("WeldConstraint") then obj:Destroy() end
	end

	local loopName = "SAO_HUD_" .. barOwnerPlayer.Name
	RunService:BindToRenderStep(loopName, Enum.RenderPriority.Camera.Value + 1, function()
		if not character or not character:FindFirstChild("HumanoidRootPart") then return end
		local basePosition = character.HumanoidRootPart.CFrame * initialTorsoOffset

		for part, offset in pairs(partsOffsets) do
			part.LocalTransparencyModifier = 0 
			-- No aplicamos NINGÚN shift. La pieza es una estatua.
			part.CFrame = basePosition * offset
		end
	end)
end)

updateHPRemote.OnClientEvent:Connect(function(healthUpdatePlayer, currentHP, maxHP)
	local playerData = playerMeshCache[healthUpdatePlayer]
	if not playerData then return end

	for barMeshPart, data in pairs(playerData) do
		local editableMesh = data.editableMesh
		local originalVertices = data.originalVertices
		local percent = math.clamp(currentHP / maxHP, 0.01, 1)

		if percent > 0.5 then barMeshPart.Color = Color3.fromRGB(85, 255, 0)
		elseif percent > 0.2 then barMeshPart.Color = Color3.fromRGB(255, 170, 0)
		else barMeshPart.Color = Color3.fromRGB(255, 0, 0) end

		local targetX = data.minX + ((data.maxX - data.minX) * percent)

		local bestX = -math.huge
		for _, pos in pairs(originalVertices) do
			if pos.X <= targetX and pos.X > bestX then bestX = pos.X end
		end

		local crossSection = {}
		for _, pos in pairs(originalVertices) do
			if math.abs(pos.X - bestX) < 0.1 then table.insert(crossSection, pos) end
		end

		for vid, origPos in pairs(originalVertices) do
			-- ✨ EL TRUCO DEL ANCLA:
			-- Si es el vértice más a la derecha, JAMÁS lo movemos.
			-- Esto engaña a Roblox para que crea que la pieza sigue midiendo lo mismo.
			if vid == data.anchorVertexId then 
				continue 
			end

			local newPos = origPos
			if origPos.X > targetX then
				if #crossSection > 0 then
					local closestCS
					local minDist = math.huge
					for _, csPos in ipairs(crossSection) do
						local dist = (Vector2.new(origPos.Y, origPos.Z) - Vector2.new(csPos.Y, csPos.Z)).Magnitude
						if dist < minDist then
							minDist = dist
							closestCS = csPos
						end
					end
					newPos = Vector3.new(targetX, closestCS.Y, closestCS.Z)
				else
					newPos = Vector3.new(targetX, origPos.Y, origPos.Z)
				end
			end
			editableMesh:SetPosition(vid, newPos)
		end

		task.spawn(function()
			local success, tempMeshPart = pcall(function()
				return AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh))
			end)
			if success and tempMeshPart then
				barMeshPart:ApplyMesh(tempMeshPart)
				-- YA NO TOCAMOS EL SIZE. Se queda con el tamaño original de Studio.
				tempMeshPart:Destroy()
			end
		end)
	end
end)
