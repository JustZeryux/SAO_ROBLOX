local ForgeLogic = {}

-- 📊 1. DICCIONARIO DE MATERIALES (Afinidades y Poder)
local Materiales = {
	["Hierro"] = { Tier = 1, Tipo = "Fisico", Valor = 10 },
	["Acero Estelar"] = { Tier = 3, Tipo = "Fisico", Valor = 35 },
	["Cristal de Fuego"] = { Tier = 2, Tipo = "Magico_Fuego", Valor = 20 },
	["Esencia Abisal"] = { Tier = 5, Tipo = "Magico_Oscuro", Valor = 100 },
	["Hueso de Dragon"] = { Tier = 4, Tipo = "Fisico_Pesado", Valor = 60 }
}

local Rarezas = {
	{Nombre = "Común", Color = Color3.fromRGB(150, 150, 150), Multiplicador = 1, MinPoder = 0},
	{Nombre = "Raro", Color = Color3.fromRGB(0, 150, 255), Multiplicador = 1.5, MinPoder = 50},
	{Nombre = "Épico", Color = Color3.fromRGB(200, 0, 255), Multiplicador = 2.5, MinPoder = 150},
	{Nombre = "Legendario", Color = Color3.fromRGB(255, 200, 0), Multiplicador = 4, MinPoder = 300},
	{Nombre = "Mítico (ÚNICA)", Color = Color3.fromRGB(255, 50, 50), Multiplicador = 7, MinPoder = 500}
}

-- ✨ 2. GENERADOR DE HABILIDADES ÚNICAS PROCEDURALES
local function GenerarHabilidadUnica(elementoDominante, nivelForgador)
	local prefijos = {"Corte", "Resonancia", "Estallido", "Danza", "Ira"}
	local sufijos = {
		["Fisico"] = {"Desgarrador", "Implacable", "del Titán"},
		["Magico_Fuego"] = {"Llamarada", "Calcinante", "del Fénix"},
		["Magico_Oscuro"] = {"del Vacío", "Devora-Almas", "Umbrío"},
		["Fisico_Pesado"] = {"Quebrantahuesos", "Colosal", "Terremoto"}
	}

	local pre = prefijos[math.random(1, #prefijos)]
	local listaSufijos = sufijos[elementoDominante] or sufijos["Fisico"]
	local suf = listaSufijos[math.random(1, #listaSufijos)]

	local danoBaseHabilidad = math.random(50, 100) * (1 + (nivelForgador / 50))

	return {
		Nombre = pre .. " " .. suf,
		Descripcion = "Libera un ataque de tipo " .. elementoDominante .. " que inflige " .. math.floor(danoBaseHabilidad) .. " de daño adicional.",
		DanoEspecial = math.floor(danoBaseHabilidad)
	}
end

-- 🛠️ 3. EL ALGORITMO PRINCIPAL DE CREACIÓN
function ForgeLogic.ForjarArma(nombresMateriales, nivelForgador, precisionMinijuego)
	local poderTotal = 0
	local conteoTipos = {}
	local elementoDominante = "Fisico"
	local maxCount = 0

	-- Analizar materiales
	for _, nombre in ipairs(nombresMateriales) do
		local mat = Materiales[nombre]
		if mat then
			poderTotal = poderTotal + mat.Valor
			conteoTipos[mat.Tipo] = (conteoTipos[mat.Tipo] or 0) + 1
			if conteoTipos[mat.Tipo] > maxCount then
				maxCount = conteoTipos[mat.Tipo]
				elementoDominante = mat.Tipo
			end
		end
	end

	-- Aplicar SAO Stats (Nivel del jugador y su habilidad en el minijuego)
	-- precisionMinijuego es un valor del 0.1 al 1.0 (qué tan bien golpeaste el yunque)
	local multiplicadorNivel = 1 + (nivelForgador / 100) -- Ej: Lvl 50 = 50% más de stats
	poderTotal = poderTotal * multiplicadorNivel * precisionMinijuego

	-- Determinar Rareza
	local rarezaFinal = Rarezas[1]
	for i = #Rarezas, 1, -1 do
		if poderTotal >= Rarezas[i].MinPoder then
			rarezaFinal = Rarezas[i]
			break
		end
	end

	-- Calcular Stats Finales
	local danoFinal = math.floor(math.random(10, 20) * rarezaFinal.Multiplicador * multiplicadorNivel)
	local durabilidad = math.floor(math.random(50, 100) * rarezaFinal.Multiplicador)

	-- ¿Tiene habilidad única? (Solo si es Épico o superior)
	local habilidad = nil
	if poderTotal >= Rarezas[3].MinPoder and math.random(1, 100) <= (20 + nivelForgador) then
		habilidad = GenerarHabilidadUnica(elementoDominante, nivelForgador)
	end

	return {
		Nombre = "Espada " .. rarezaFinal.Nombre,
		Rareza = rarezaFinal.Nombre,
		ColorRareza = rarezaFinal.Color,
		Dano = danoFinal,
		Durabilidad = durabilidad,
		Elemento = elementoDominante,
		HabilidadUnica = habilidad,
		Creador = "Tú"
	}
end

return ForgeLogic
