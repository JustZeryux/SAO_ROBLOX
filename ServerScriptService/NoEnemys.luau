local PhysicsService = game:GetService("PhysicsService")

-- 1. Crear los grupos
PhysicsService:RegisterCollisionGroup("Mobs")
PhysicsService:RegisterCollisionGroup("SafeBarriers")

-- 2. Configurar la colisión: Mobs CHOCAN con Barreras, pero nada más lo hace.
PhysicsService:CollisionGroupSetCollidable("Mobs", "SafeBarriers", true)
PhysicsService:CollisionGroupSetCollidable("Default", "SafeBarriers", false)
PhysicsService:CollisionGroupSetCollidable("Players", "SafeBarriers", false)

-- 3. Asignar las zonas seguras al grupo de barreras
for _, zona in ipairs(workspace.SafeZones:GetChildren()) do
	if zona:IsA("BasePart") then
		zona.CollisionGroup = "SafeBarriers"
	end
end

-- 4. Función para etiquetar a los mobs (llámala cuando spawnees un mob)
workspace.ChildAdded:Connect(function(child)
	-- Esperamos un poco para asegurar que el mob cargó
	task.wait(0.1)
	-- Si el objeto es un mob (puedes checar si está en tu carpeta de mobs o por nombre)
	if child:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(child) then
		for _, part in ipairs(child:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Mobs"
			end
		end
	end
end)
