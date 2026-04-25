local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SAO_Modules = ReplicatedStorage:WaitForChild("SAO_Modules")
local SAO_Events = ReplicatedStorage:WaitForChild("SAO_Events")
local NormalDropEvent = SAO_Events:WaitForChild("Loot_Normal")
local BossDropEvent = SAO_Events:WaitForChild("Loot_Boss")
local ItemDatabase = require(SAO_Modules:WaitForChild("ItemDatabase"))

-- ==========================================
-- 🐺 TABLAS DE LOOT (Configuración)
-- ==========================================
local LootTables = {
	["Javali_Frenetico"] = {
		IsBoss = false,
		Drops = {
			{Item = "Carne_Asada", Chance = 60, Cantidad = 1},
			{Item = "Gelatina_Slime", Chance = 30, Cantidad = 2},
			{Item = "Cor", Chance = 100, Cantidad = 15}
		}
	},
	["Illfang_The_Kobold_Lord"] = {
		IsBoss = true,
		Drops = {
			{Item = "Cristal_Demoniaco", Chance = 100, Cantidad = 1},
			{Item = "Llave_Boss_Piso1", Chance = 100, Cantidad = 1},
			{Item = "Mena_Oricalco", Chance = 40, Cantidad = 3},
			{Item = "Cor", Chance = 100, Cantidad = 5000}
		}
	}
}

-- ==========================================
-- ⚙️ LÓGICA DE MUERTE Y DROPS
-- ==========================================
local function processLoot(humanoid, enemyName)
	local lootData = LootTables[enemyName]
	if not lootData then return end

	-- Buscar quién dio el último golpe
	local attackerName = humanoid:GetAttribute("LastAttacker")
	if not attackerName then return end

	local player = Players:FindFirstChild(attackerName)
	if not player then return end

	local itemsObtained = {}

	-- Tirar los dados para cada ítem
	for _, dropInfo in ipairs(lootData.Drops) do
		local roll = math.random(1, 100)
		if roll <= dropInfo.Chance then
			table.insert(itemsObtained, {
				ID = dropInfo.Item,
				Nombre = ItemDatabase[dropInfo.Item].Nombre,
				Cantidad = dropInfo.Cantidad,
				Icono = ItemDatabase[dropInfo.Item].Icono
			})

			-- AQUÍ: Lógica para agregar a la base de datos/Backpack del jugador
			-- Ejemplo: if ItemDatabase[dropInfo.Item].Tipo == "Tool" then ...
			print("Se otorgó " .. dropInfo.Cantidad .. "x " .. dropInfo.Item .. " a " .. player.Name)
		end
	end

	-- Si consiguió algo, avisar a la interfaz del jugador
	if #itemsObtained > 0 then
		if lootData.IsBoss then
			BossDropEvent:FireClient(player, enemyName, itemsObtained)
		else
			NormalDropEvent:FireClient(player, itemsObtained)
		end
	end
end

-- ==========================================
-- 📡 INYECTOR PARA ENEMIGOS NUEVOS
-- ==========================================
-- Esta función vigila cuando se añade un NPC al mapa
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Humanoid") and descendant.Parent:FindFirstChild("HumanoidRootPart") then
		-- Si es un jugador, lo ignoramos
		if Players:GetPlayerFromCharacter(descendant.Parent) then return end

		descendant.Died:Connect(function()
			-- Asume que el nombre del Modelo es el nombre del enemigo (ej. "Javali_Frenetico")
			processLoot(descendant, descendant.Parent.Name)
		end)
	end
end)
