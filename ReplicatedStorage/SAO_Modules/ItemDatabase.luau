-- Ubicación: ReplicatedStorage/SAO_Modules/ItemDatabase
local ItemDatabase = {

	-- ==========================================
	-- 🧪 CONSUMIBLES (Pociones y Buffs)
	-- ==========================================
	["Pocion_Vida_Basica"] = {
		Nombre = "Poción de Vida Básica", Tipo = "Consumible", Rareza = "Común", Precio = 50, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "Un frasco con líquido rojo pálido. Restaura 250 HP al instante.",
		Efecto = {Stat = "HP", Valor = 250}
	},
	["Pocion_Vida_Alta"] = {
		Nombre = "Poción de Vida Alta", Tipo = "Consumible", Rareza = "Raro", Precio = 300, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "Líquido rojo brillante que burbujea. Restaura 1500 HP.",
		Efecto = {Stat = "HP", Valor = 1500}
	},
	["Pocion_SP"] = {
		Nombre = "Poción de Energía (SP)", Tipo = "Consumible", Rareza = "Poco Común", Precio = 120, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "Restaura 50 puntos de SP para usar Sword Skills.",
		Efecto = {Stat = "SP", Valor = 50}
	},
	["Antidoto"] = {
		Nombre = "Antídoto", Tipo = "Consumible", Rareza = "Común", Precio = 80, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "Líquido verde amargo. Cura el estado de Envenenamiento.",
		Efecto = {CuraEstado = "Veneno"}
	},
	["Carne_Asada"] = {
		Nombre = "Carne de Jabalí Asada", Tipo = "Consumible", Rareza = "Común", Precio = 30, MaxStack = 20, Icono = "rbxassetid://0",
		Desc = "Comida básica. Regenera 10 HP por segundo durante 1 minuto.",
		Efecto = {Buff = "RegenHP", Valor = 10, Duracion = 60}
	},
	["Ragout_Rabbit"] = {
		Nombre = "Estofado de Ragout Rabbit", Tipo = "Consumible", Rareza = "Legendario", Precio = 15000, MaxStack = 5, Icono = "rbxassetid://0",
		Desc = "El manjar supremo. Restaura todo el HP y otorga inmunidad por 10 segundos.",
		Efecto = {Stat = "HP_Max", Buff = "Inmune", Duracion = 10}
	},

	-- ==========================================
	-- 💎 CRISTALES DE UTILIDAD
	-- ==========================================
	["Cristal_Teletransporte"] = {
		Nombre = "Cristal de Teletransporte", Tipo = "Cristal", Rareza = "Épico", Precio = 2500, MaxStack = 10, Icono = "rbxassetid://0",
		Desc = "Grita 'Teleport' y el nombre de la ciudad para escapar instantáneamente.",
		Efecto = {Comando = "Teleport_City"}
	},
	["Cristal_Curacion"] = {
		Nombre = "Cristal de Curación", Tipo = "Cristal", Rareza = "Épico", Precio = 3000, MaxStack = 10, Icono = "rbxassetid://0",
		Desc = "Grita 'Heal' para restaurar 80% del HP a todo tu grupo (Party) en área.",
		Efecto = {Comando = "Heal_AoE", Porcentaje = 80}
	},

	-- ==========================================
	-- 🐺 LOOT DE MONSTRUOS (Materiales de crafteo)
	-- ==========================================
	["Gelatina_Slime"] = {
		Nombre = "Gelatina de Slime", Tipo = "Material", Rareza = "Común", Precio = 5, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Sustancia pegajosa. Se usa como base en alquimia."
	},
	["Colmillo_Lobo"] = {
		Nombre = "Colmillo de Lobo", Tipo = "Material", Rareza = "Común", Precio = 12, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Afilado pero frágil. Útil para forjar dagas de novato."
	},
	["Polvo_Hada"] = {
		Nombre = "Polvo de Hada", Tipo = "Material", Rareza = "Poco Común", Precio = 45, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Brilla suavemente. Se usa para añadir atributos mágicos a las armas."
	},
	["Nucleo_Golem"] = {
		Nombre = "Núcleo de Golem", Tipo = "Material", Rareza = "Raro", Precio = 200, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "Una piedra ultra densa. Necesaria para forjar mazas pesadas."
	},
	["Cristal_Demoniaco"] = {
		Nombre = "Cristal Demoníaco", Tipo = "Material", Rareza = "Épico", Precio = 5000, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "Drop de Jefe. Palpita con energía oscura. Requerido para forjar equipo Legendario."
	},

	-- ==========================================
	-- ⛏️ MINERALES Y HERRERÍA
	-- ==========================================
	["Mena_Cobre"] = {
		Nombre = "Mineral de Cobre", Tipo = "Mineral", Rareza = "Común", Precio = 8, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Metal blando. Tier 1 de herrería."
	},
	["Mena_Hierro"] = {
		Nombre = "Mineral de Hierro", Tipo = "Mineral", Rareza = "Común", Precio = 20, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Metal estándar para equipo resistente. Tier 2."
	},
	["Mena_Acero"] = {
		Nombre = "Lingote de Acero", Tipo = "Mineral", Rareza = "Poco Común", Precio = 55, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Aleación purificada. Tier 3."
	},
	["Mena_Mithril"] = {
		Nombre = "Mineral de Mithril", Tipo = "Mineral", Rareza = "Épico", Precio = 800, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "Extremadamente ligero y afilado. Tier 5."
	},
	["Mena_Oricalco"] = {
		Nombre = "Oricalco", Tipo = "Mineral", Rareza = "Legendario", Precio = 4000, MaxStack = 99, Icono = "rbxassetid://0",
		Desc = "El metal definitivo. Imposible de fundir para herreros normales."
	},

	-- ==========================================
	-- 🌿 BOTÁNICA Y TEXTILES
	-- ==========================================
	["Hierba_Curativa"] = {
		Nombre = "Hierba Curativa", Tipo = "Botánica", Rareza = "Común", Precio = 2, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Ingrediente base para Pociones de Vida Básicas."
	},
	["Hongo_Luminoso"] = {
		Nombre = "Hongo Luminoso", Tipo = "Botánica", Rareza = "Poco Común", Precio = 15, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Crece en zonas oscuras. Sirve para hacer tintes brillantes o pociones de visión."
	},
	["Madera_Fresno"] = {
		Nombre = "Madera de Fresno", Tipo = "Botánica", Rareza = "Común", Precio = 10, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Madera flexible. Ideal para craftear Arcos largos."
	},
	["Cuero_Curtido"] = {
		Nombre = "Cuero Curtido", Tipo = "Textil", Rareza = "Común", Precio = 18, MaxStack = 999, Icono = "rbxassetid://0",
		Desc = "Piel procesada. Base para la armadura ligera de asesinos y arqueros."
	},

	-- ==========================================
	-- 🔑 OBJETOS CLAVE Y HERRAMIENTAS
	-- ==========================================
	["Cor"] = {
		Nombre = "Cor", Tipo = "Moneda", Rareza = "Común", Precio = 1, MaxStack = 999999999, Icono = "rbxassetid://0",
		Desc = "Moneda oficial del juego."
	},
	["Piedra_Afilar"] = {
		Nombre = "Piedra de Afilar", Tipo = "Herramienta", Rareza = "Común", Precio = 150, MaxStack = 50, Icono = "rbxassetid://0",
		Desc = "Aumenta el daño del arma equipada un 10% durante 15 minutos.",
		Efecto = {Buff = "DanoFisico", Porcentaje = 10, Duracion = 900}
	},
	["Pico_Minero"] = {
		Nombre = "Pico de Minero", Tipo = "Herramienta", Rareza = "Común", Precio = 500, MaxStack = 1, Icono = "rbxassetid://0",
		Desc = "Equípalo para poder extraer minerales de las vetas de roca en el mundo."
	},
	["Llave_Boss_Piso1"] = {
		Nombre = "Llave del Cuarto del Jefe (Piso 1)", Tipo = "Clave", Rareza = "Épico", Precio = 0, MaxStack = 1, Icono = "rbxassetid://0",
		Desc = "Una llave enorme y ornamentada. Abre las puertas gigantes del laberinto principal."
	}
}

return ItemDatabase
