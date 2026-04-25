local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage") -- Opcional, pero recomendado para mobs

-- 📁 CONFIGURACIÓN DE CARPETAS
local MobsFolder = ReplicatedStorage:WaitForChild("Mobs")
local SpawnArea = workspace:WaitForChild("SpawnRegion") -- Un bloque transparente que define el área

-- ⚙️ AJUSTES
local CONFIG = {
	MAX_MOBS = 10,          -- Cantidad máxima de mobs vivos en el área
	SPAWN_INTERVAL = 15,    -- Cada cuántos segundos intenta spawnear
	MOBS_PER_CYCLE = 2,     -- Cuántos intenta spawnear en cada ciclo
}

-- Lista para rastrear los mobs vivos
local mobsVivos = {}

-- Función para obtener una posición aleatoria dentro del bloque "SpawnArea"
local function GetRandomPointInPart(part)
	local size = part.Size
	local cframe = part.CFrame

	local randomX = math.random(-size.X/2, size.X/2)
	local randomZ = math.random(-size.Z/2, size.Z/2)

	-- Retorna la posición transformada al mundo (Y está un poco arriba para que no se atasquen)
	return (cframe * CFrame.new(randomX, 3, randomZ)).Position
end

local function SpawnMob()
	-- 1. Verificar si hay espacio para más mobs
	if #mobsVivos >= CONFIG.MAX_MOBS then return end

	-- 2. Elegir un mob aleatorio de la carpeta
	local modelosDisponibles = MobsFolder:GetChildren()
	if #modelosDisponibles == 0 then warn("No hay mobs en ReplicatedStorage > Mobs") return end

	local mobElegido = modelosDisponibles[math.random(1, #modelosDisponibles)]

	-- 3. Clonar y posicionar
	local nuevoMob = mobElegido:Clone()
	local spawnPos = GetRandomPointInPart(SpawnArea)

	nuevoMob:PivotTo(CFrame.new(spawnPos))
	nuevoMob.Parent = workspace

	-- 4. Registrar en la lista
	table.insert(mobsVivos, nuevoMob)
	print("⚔️ Mob spawneado: " .. nuevoMob.Name .. " | Vivos: " .. #mobsVivos)

	-- 5. Detectar cuando muera para sacarlo de la lista
	local humanoid = nuevoMob:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			-- Esperar unos segundos antes de limpiar el cuerpo
			task.wait(3) 

			-- Buscar y eliminar de la tabla de vivos
			for i, v in ipairs(mobsVivos) do
				if v == nuevoMob then
					table.remove(mobsVivos, i)
					break
				end
			end
			nuevoMob:Destroy()
		end)
	end
end

-- 🔄 BUCLE INFINITO DE SPAWN
print("🚀 Sistema de Spawning Iniciado...")

while true do
	task.wait(CONFIG.SPAWN_INTERVAL)

	-- Intentar spawnear la cantidad por ciclo
	for i = 1, CONFIG.MOBS_PER_CYCLE do
		SpawnMob()
	end
end
