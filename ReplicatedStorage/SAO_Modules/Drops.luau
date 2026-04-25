-- ReplicatedStorage/SAO_Modules/Drops
local Drops = {
	-- ⚪ COMÚN
	["Poción de Vida"] = {
		Rareza = "Comun",
		Color = Color3.fromRGB(200, 200, 200),
		Icono = "rbxassetid://6023565651",
		Enemigo = "Cualquiera" -- Un drop global
	},
	["Cuero de Jabalí"] = {
		Rareza = "Comun",
		Color = Color3.fromRGB(200, 200, 200),
		Icono = "rbxassetid://6023565651",
		Enemigo = "Frenzy Boar"
	},

	-- 🔵 RARO
	["Cristal de Teletransporte"] = {
		Rareza = "Raro",
		Color = Color3.fromRGB(50, 150, 255),
		Icono = "rbxassetid://6023565651",
		Enemigo = "Guardia de Élite"
	},

	-- 🟣 ÉPICO
	["Abrigo de Medianoche"] = {
		Rareza = "Epico",
		Color = Color3.fromRGB(170, 0, 255),
		Icono = "rbxassetid://6023565651",
		Enemigo = "Illfang the Kobold Lord"
	},

	-- 🟡 LEGENDARIO (BOSS DROPS)
	["Elucidator"] = {
		Rareza = "Legendario",
		Color = Color3.fromRGB(255, 215, 0),
		Icono = "rbxassetid://6023565651",
		Enemigo = "The Gleam Eyes"
	},
	["Dark Repulser"] = {
		Rareza = "Legendario",
		Color = Color3.fromRGB(85, 255, 255),
		Icono = "rbxassetid://6023565651",
		Enemigo = "Dragón de Cristal"
	}
}

-- Datos por defecto por si olvidaste registrar un ítem
local FallbackDrop = {
	Rareza = "Desconocido",
	Color = Color3.fromRGB(255, 255, 255),
	Icono = "rbxassetid://0",
	Enemigo = "Desconocido"
}

return setmetatable(Drops, {
	__index = function() return FallbackDrop end
})
