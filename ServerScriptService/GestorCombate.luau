-- GestorCombate (Actualizado con Cooldowns)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Diccionario = require(ReplicatedStorage:WaitForChild("DiccionarioHabilidades"))
local EventoPeticion = ReplicatedStorage.EventosCombate:WaitForChild("PeticionHabilidad")

-- Tabla para guardar los tiempos de cada jugador
-- Estructura: [UserId] = { ["NombreHabilidad"] = TiempoUltimoUso }
local cooldownsBaseDeDatos = {}

local function ProcesarHabilidad(jugador, nombreHabilidadID)
	local userId = jugador.UserId
	local datos = Diccionario.ObtenerHabilidad(nombreHabilidadID)

	if not datos then return end

	-- Inicializar tabla de cooldowns para el jugador si es nuevo
	if not cooldownsBaseDeDatos[userId] then
		cooldownsBaseDeDatos[userId] = {}
	end

	local tiempoAhora = tick() -- Tiempo actual en segundos
	local ultimoUso = cooldownsBaseDeDatos[userId][nombreHabilidadID] or 0

	-- VALIDACIÓN: ¿Ya pasó el tiempo de recarga?
	if tiempoAhora - ultimoUso >= datos.Cooldown then
		-- ÉXITO: Actualizamos el tiempo y ejecutamos
		cooldownsBaseDeDatos[userId][nombreHabilidadID] = tiempoAhora
		print("¡Habilidad " .. datos.Nombre .. " ejecutada!")

		-- Aquí iría la animación y el daño
	else
		-- ERROR: Aún está en cooldown
		local faltan = math.ceil(datos.Cooldown - (tiempoAhora - ultimoUso))
		print("Espera " .. faltan .. " segundos para usar " .. datos.Nombre)
	end
end

EventoPeticion.OnServerEvent:Connect(ProcesarHabilidad)
