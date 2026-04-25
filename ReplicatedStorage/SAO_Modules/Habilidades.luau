local Habilidades = {
	-- ==========================================
	-- 🗡️ ESPADA DE UNA MANO (1-Handed Straight Sword)
	-- ==========================================
	["Slant"] = {
		Nombre = "Slant",
		Para = "Espada de Una Mano",
		Costo = 2, NivelReq = 1, Icono = "rbxassetid://0",
		Desc = "Tajo diagonal básico.",
		Animacion = "SlantAnim", CostoSP = 10, Dano = 25, VelocidadDash = 40, Cooldown = 3,
		ColorPrimario = Color3.fromRGB(100, 200, 255), ColorSecundario = Color3.fromRGB(200, 240, 255)
	},
	["Vertical"] = {
		Nombre = "Vertical",
		Para = "Espada de Una Mano",
		Costo = 2, NivelReq = 1, Icono = "rbxassetid://0",
		Desc = "Tajo vertical simple.",
		Animacion = "VerticalAnim", CostoSP = 10, Dano = 25, VelocidadDash = 30, Cooldown = 3,
		ColorPrimario = Color3.fromRGB(100, 200, 255), ColorSecundario = Color3.fromRGB(200, 240, 255)
	},
	["Horizontal"] = {
		Nombre = "Horizontal",
		Para = "Espada de Una Mano",
		Costo = 2, NivelReq = 2, Icono = "rbxassetid://0",
		Desc = "Tajo horizontal para golpear en área estrecha.",
		Animacion = "HorizontalAnim", CostoSP = 12, Dano = 25, VelocidadDash = 35, Cooldown = 3,
		ColorPrimario = Color3.fromRGB(100, 200, 255), ColorSecundario = Color3.fromRGB(200, 240, 255)
	},
	["Uppercut"] = {
		Nombre = "Uppercut",
		Para = "Espada de Una Mano",
		Costo = 4, NivelReq = 3, Icono = "rbxassetid://0",
		Desc = "Gancho ascendente para lanzar enemigos por los aires.",
		Animacion = "UppercutAnim", CostoSP = 15, Dano = 30, VelocidadDash = 20, Cooldown = 4,
		ColorPrimario = Color3.fromRGB(255, 180, 50), ColorSecundario = Color3.fromRGB(255, 220, 100)
	},
	["RageSpike"] = {
		Nombre = "Rage Spike",
		Para = "Espada de Una Mano",
		Costo = 6, NivelReq = 4, Icono = "rbxassetid://0",
		Desc = "Estocada frontal rápida para acortar distancia.",
		Animacion = "RageSpikeAnim", CostoSP = 20, Dano = 40, VelocidadDash = 90, Cooldown = 5,
		ColorPrimario = Color3.fromRGB(255, 50, 50), ColorSecundario = Color3.fromRGB(255, 150, 150)
	},
	["SonicLeap"] = {
		Nombre = "Sonic Leap",
		Para = "Espada de Una Mano",
		Costo = 8, NivelReq = 5, Icono = "rbxassetid://0",
		Desc = "Salto a gran velocidad seguido de un tajo descendente.",
		Animacion = "SonicLeapAnim", CostoSP = 30, Dano = 55, VelocidadDash = 85, Cooldown = 7,
		ColorPrimario = Color3.fromRGB(50, 255, 100), ColorSecundario = Color3.fromRGB(150, 255, 150)
	},
	["VerticalArc"] = {
		Nombre = "Vertical Arc",
		Para = "Espada de Una Mano",
		Costo = 10, NivelReq = 7, Icono = "rbxassetid://0",
		Desc = "Tajo en forma de V (baja y sube inmediatamente).",
		Animacion = "VerticalArcAnim", CostoSP = 35, Dano = 65, VelocidadDash = 40, Cooldown = 8,
		ColorPrimario = Color3.fromRGB(0, 255, 200), ColorSecundario = Color3.fromRGB(150, 255, 255)
	},
	["SnakeBite"] = {
		Nombre = "Snake Bite",
		Para = "Espada de Una Mano",
		Costo = 12, NivelReq = 9, Icono = "rbxassetid://0",
		Desc = "Dos tajos horizontales enfocados en desarmar o romper guardia.",
		Animacion = "SnakeBiteAnim", CostoSP = 35, Dano = 70, VelocidadDash = 50, Cooldown = 8,
		ColorPrimario = Color3.fromRGB(150, 255, 50), ColorSecundario = Color3.fromRGB(200, 255, 150)
	},
	["SavageFulcrum"] = {
		Nombre = "Savage Fulcrum",
		Para = "Espada de Una Mano",
		Costo = 15, NivelReq = 12, Icono = "rbxassetid://0",
		Desc = "Dibuja un 4 en el aire con tajos de hielo.",
		Animacion = "SavageFulcrumAnim", CostoSP = 45, Dano = 90, VelocidadDash = 30, Cooldown = 10,
		ColorPrimario = Color3.fromRGB(0, 100, 255), ColorSecundario = Color3.fromRGB(150, 200, 255)
	},
	["HorizontalSquare"] = {
		Nombre = "Horizontal Square",
		Para = "Espada de Una Mano",
		Costo = 18, NivelReq = 14, Icono = "rbxassetid://0",
		Desc = "Dibuja un rombo de luz golpeando 4 veces.",
		Animacion = "HSquareAnim", CostoSP = 50, Dano = 100, VelocidadDash = 50, Cooldown = 12,
		ColorPrimario = Color3.fromRGB(0, 150, 255), ColorSecundario = Color3.fromRGB(100, 200, 255)
	},
	["MeteorBreak"] = {
		Nombre = "Meteor Break",
		Para = "Espada de Una Mano",
		Costo = 25, NivelReq = 18, Icono = "rbxassetid://0",
		Desc = "Combo de 7 golpes que mezcla tajos y un empujón de artes marciales.",
		Animacion = "MeteorBreakAnim", CostoSP = 70, Dano = 150, VelocidadDash = 60, Cooldown = 16,
		ColorPrimario = Color3.fromRGB(255, 100, 0), ColorSecundario = Color3.fromRGB(255, 200, 100)
	},
	["VorpalStrike"] = {
		Nombre = "Vorpal Strike",
		Para = "Espada de Una Mano",
		Costo = 30, NivelReq = 22, Icono = "rbxassetid://0",
		Desc = "Estocada masiva de largo alcance.",
		Animacion = "VorpalAnim", CostoSP = 80, Dano = 180, VelocidadDash = 150, Cooldown = 20,
		ColorPrimario = Color3.fromRGB(255, 20, 20), ColorSecundario = Color3.fromRGB(255, 100, 100)
	},
	["NovaAscension"] = {
		Nombre = "Nova Ascension",
		Para = "Espada de Una Mano",
		Costo = 60, NivelReq = 40, Icono = "rbxassetid://0",
		Desc = "Habilidad máxima. Ráfaga de 10 tajos de luz letales.",
		Animacion = "NovaAscensionAnim", CostoSP = 120, Dano = 300, VelocidadDash = 50, Cooldown = 45,
		ColorPrimario = Color3.fromRGB(255, 255, 255), ColorSecundario = Color3.fromRGB(150, 200, 255)
	},

	-- ==========================================
	-- ⚔️ DOBLE EMPUÑADURA (Dual Blades)
	-- ==========================================
	["DoubleCircular"] = {
		Nombre = "Double Circular",
		Para = "Doble Empuñadura",
		Costo = 30, NivelReq = 25, Icono = "rbxassetid://0",
		Desc = "Estocada simultánea con dos espadas (2 golpes).",
		Animacion = "DoubleCAnim", CostoSP = 55, Dano = 110, VelocidadDash = 100, Cooldown = 15,
		ColorPrimario = Color3.fromRGB(255, 150, 0), ColorSecundario = Color3.fromRGB(255, 255, 0)
	},
	["CrossBlock"] = {
		Nombre = "Cross Block",
		Para = "Doble Empuñadura",
		Costo = 20, NivelReq = 20, Icono = "rbxassetid://0",
		Desc = "Cruza ambas espadas para detener ataques de monstruos gigantes.",
		Animacion = "CrossBlockAnim", CostoSP = 40, Dano = 0, VelocidadDash = 0, Cooldown = 10,
		ColorPrimario = Color3.fromRGB(200, 200, 200), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	["StarburstStream"] = {
		Nombre = "Starburst Stream",
		Para = "Doble Empuñadura",
		Costo = 100, NivelReq = 50, Icono = "rbxassetid://0",
		Desc = "Lluvia de 16 golpes que acelera gradualmente.",
		Animacion = "StarburstAnim", CostoSP = 150, Dano = 380, VelocidadDash = 60, Cooldown = 60,
		ColorPrimario = Color3.fromRGB(0, 255, 255), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	["TheEclipse"] = {
		Nombre = "The Eclipse",
		Para = "Doble Empuñadura",
		Costo = 150, NivelReq = 75, Icono = "rbxassetid://0",
		Desc = "Habilidad máxima. 27 golpes sin punto ciego.",
		Animacion = "EclipseAnim", CostoSP = 200, Dano = 600, VelocidadDash = 80, Cooldown = 90,
		ColorPrimario = Color3.fromRGB(255, 255, 50), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},

	-- ==========================================
	-- 🤺 ESTOQUE (Rapier)
	-- ==========================================
	["Linear"] = {
		Nombre = "Linear",
		Para = "Estoque",
		Costo = 2, NivelReq = 1, Icono = "rbxassetid://0",
		Desc = "Estocada frontal ultra rápida.",
		Animacion = "LinearAnim", CostoSP = 10, Dano = 20, VelocidadDash = 60, Cooldown = 2,
		ColorPrimario = Color3.fromRGB(200, 255, 255), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	["Oblique"] = {
		Nombre = "Oblique",
		Para = "Estoque",
		Costo = 5, NivelReq = 4, Icono = "rbxassetid://0",
		Desc = "Estocada baja para evadir ataques altos.",
		Animacion = "ObliqueAnim", CostoSP = 15, Dano = 30, VelocidadDash = 40, Cooldown = 4,
		ColorPrimario = Color3.fromRGB(150, 200, 255), ColorSecundario = Color3.fromRGB(200, 255, 255)
	},
	["ShootingStar"] = {
		Nombre = "Shooting Star",
		Para = "Estoque",
		Costo = 20, NivelReq = 15, Icono = "rbxassetid://0",
		Desc = "Carga que te dispara hacia adelante como láser.",
		Animacion = "ShootingStarAnim", CostoSP = 40, Dano = 75, VelocidadDash = 180, Cooldown = 10,
		ColorPrimario = Color3.fromRGB(255, 255, 255), ColorSecundario = Color3.fromRGB(255, 255, 100)
	},
	["StarSplash"] = {
		Nombre = "Star Splash",
		Para = "Estoque",
		Costo = 40, NivelReq = 30, Icono = "rbxassetid://0",
		Desc = "8 estocadas frontales simultáneas.",
		Animacion = "StarSplashAnim", CostoSP = 70, Dano = 160, VelocidadDash = 30, Cooldown = 18,
		ColorPrimario = Color3.fromRGB(150, 255, 255), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	["FlashingPenetrator"] = {
		Nombre = "Flashing Penetrator",
		Para = "Estoque",
		Costo = 50, NivelReq = 45, Icono = "rbxassetid://0",
		Desc = "Estocada supercargada que deja estela brillante.",
		Animacion = "FlashingPenetratorAnim", CostoSP = 90, Dano = 220, VelocidadDash = 200, Cooldown = 25,
		ColorPrimario = Color3.fromRGB(255, 255, 200), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},

	-- ==========================================
	-- 🌙 KATANA / ESPADA CURVA (Curved Sword)
	-- ==========================================
	["Reaver"] = {
		Nombre = "Reaver",
		Para = "Katana",
		Costo = 5, NivelReq = 3, Icono = "rbxassetid://0",
		Desc = "Tajo giratorio veloz.",
		Animacion = "ReaverAnim", CostoSP = 15, Dano = 35, VelocidadDash = 30, Cooldown = 4,
		ColorPrimario = Color3.fromRGB(200, 100, 255), ColorSecundario = Color3.fromRGB(255, 150, 255)
	},
	["FellCrescent"] = {
		Nombre = "Fell Crescent",
		Para = "Katana",
		Costo = 8, NivelReq = 8, Icono = "rbxassetid://0",
		Desc = "Ataque descendente en forma de media luna.",
		Animacion = "FellCrescentAnim", CostoSP = 25, Dano = 55, VelocidadDash = 40, Cooldown = 6,
		ColorPrimario = Color3.fromRGB(150, 0, 255), ColorSecundario = Color3.fromRGB(200, 100, 255)
	},
	["Tsujikaze"] = {
		Nombre = "Tsujikaze",
		Para = "Katana",
		Costo = 15, NivelReq = 15, Icono = "rbxassetid://0",
		Desc = "Ataque recto que corta el aire.",
		Animacion = "TsujikazeAnim", CostoSP = 40, Dano = 80, VelocidadDash = 100, Cooldown = 10,
		ColorPrimario = Color3.fromRGB(50, 255, 150), ColorSecundario = Color3.fromRGB(150, 255, 200)
	},
	["Gengetsu"] = {
		Nombre = "Gengetsu",
		Para = "Katana",
		Costo = 20, NivelReq = 20, Icono = "rbxassetid://0",
		Desc = "Voltereta hacia atrás y onda de energía a distancia.",
		Animacion = "GengetsuAnim", CostoSP = 50, Dano = 90, VelocidadDash = -50, -- Ojo aquí: Va hacia atrás para evadir
		Cooldown = 12,
		ColorPrimario = Color3.fromRGB(100, 50, 255), ColorSecundario = Color3.fromRGB(200, 150, 255)
	},
	["Zekku"] = {
		Nombre = "Zekku",
		Para = "Katana",
		Costo = 30, NivelReq = 35, Icono = "rbxassetid://0",
		Desc = "Desenfundado extremo desde abajo para romper guardias.",
		Animacion = "ZekkuAnim", CostoSP = 70, Dano = 160, VelocidadDash = 120, Cooldown = 20,
		ColorPrimario = Color3.fromRGB(255, 0, 100), ColorSecundario = Color3.fromRGB(255, 100, 150)
	},

	-- ==========================================
	-- 🪓 ARMAS A DOS MANOS (2-Handed Weapon)
	-- ==========================================
	["Avalanche"] = {
		Nombre = "Avalanche",
		Para = "Arma a Dos Manos",
		Costo = 18, NivelReq = 10, Icono = "rbxassetid://0",
		Desc = "Golpe descendente con inercia imparable.",
		Animacion = "AvalancheAnim", CostoSP = 50, Dano = 110, VelocidadDash = 15, Cooldown = 14,
		ColorPrimario = Color3.fromRGB(150, 75, 0), ColorSecundario = Color3.fromRGB(255, 120, 50)
	},
	["Cyclone"] = {
		Nombre = "Cyclone",
		Para = "Arma a Dos Manos",
		Costo = 25, NivelReq = 18, Icono = "rbxassetid://0",
		Desc = "Giro de 360 grados golpeando a todos alrededor.",
		Animacion = "CycloneAnim", CostoSP = 65, Dano = 130, VelocidadDash = 0, Cooldown = 16,
		ColorPrimario = Color3.fromRGB(255, 150, 50), ColorSecundario = Color3.fromRGB(255, 200, 100)
	},
	["BackRush"] = {
		Nombre = "Back Rush",
		Para = "Arma a Dos Manos",
		Costo = 35, NivelReq = 25, Icono = "rbxassetid://0",
		Desc = "Ataque giratorio para barrer enemigos por la espalda.",
		Animacion = "BackRushAnim", CostoSP = 80, Dano = 160, VelocidadDash = 20, Cooldown = 20,
		ColorPrimario = Color3.fromRGB(200, 50, 0), ColorSecundario = Color3.fromRGB(255, 100, 50)
	},
	-- ==========================================
	-- 🏹 ARCO (Bow - Sinon Style)
	-- ==========================================
	["QuickDraw"] = {
		Nombre = "Quick Draw", Para = "Arco", Costo = 5, NivelReq = 2, Icono = "rbxassetid://0", Desc = "Disparo veloz que no requiere cargar.", Animacion = "QuickDrawAnim", CostoSP = 15, Dano = 45, VelocidadDash = -15, -- Pequeño salto hacia atrás
		Cooldown = 3, ColorPrimario = Color3.fromRGB(150, 255, 150), ColorSecundario = Color3.fromRGB(200, 255, 200)
	},
	["FixPierce"] = {
		Nombre = "Fix Pierce", Para = "Arco", Costo = 15, NivelReq = 10, Icono = "rbxassetid://0", Desc = "Flecha perforante de altísima velocidad tipo francotirador.", Animacion = "FixPierceAnim", CostoSP = 35, Dano = 85, VelocidadDash = -25, 
		Cooldown = 8, ColorPrimario = Color3.fromRGB(0, 200, 255), ColorSecundario = Color3.fromRGB(150, 255, 255)
	},
	["StrikeNova"] = {
		Nombre = "Strike Nova", Para = "Arco", Costo = 25, NivelReq = 20, Icono = "rbxassetid://0", Desc = "Lanza una flecha inestable que explota al impactar (Daño en Área).", Animacion = "StrikeNovaAnim", CostoSP = 50, Dano = 130, VelocidadDash = -40, -- Gran evasión hacia atrás
		Cooldown = 12, ColorPrimario = Color3.fromRGB(255, 80, 0), ColorSecundario = Color3.fromRGB(255, 200, 50)
	},
	["StarTear"] = {
		Nombre = "Star Tear", Para = "Arco", Costo = 50, NivelReq = 35, Icono = "rbxassetid://0", Desc = "Dispara una flecha al cielo que hace llover energía sobre el enemigo.", Animacion = "StarTearAnim", CostoSP = 90, Dano = 250, VelocidadDash = 0, 
		Cooldown = 25, ColorPrimario = Color3.fromRGB(255, 255, 100), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	-- ==========================================
	-- 🗡️ DAGAS (Dagger - Silica Style)
	-- ==========================================
	["FadingEdge"] = {
		Nombre = "Fading Edge", Para = "Daga", Costo = 8, NivelReq = 5, Icono = "rbxassetid://0", Desc = "Combo de 4 cortes tan rápido que te vuelve casi invisible.", Animacion = "FadingEdgeAnim", CostoSP = 25, Dano = 60, VelocidadDash = 80, 
		Cooldown = 6, ColorPrimario = Color3.fromRGB(100, 255, 150), ColorSecundario = Color3.fromRGB(200, 255, 200)
	},
	["RapidBite"] = {
		Nombre = "Rapid Bite", Para = "Daga", Costo = 15, NivelReq = 12, Icono = "rbxassetid://0", Desc = "Doble estocada paralizante al cuello.", Animacion = "RapidBiteAnim", CostoSP = 35, Dano = 90, VelocidadDash = 100, 
		Cooldown = 8, ColorPrimario = Color3.fromRGB(50, 200, 100), ColorSecundario = Color3.fromRGB(150, 255, 150)
	},
	["ArmorPierce"] = {
		Nombre = "Armor Pierce", Para = "Daga", Costo = 25, NivelReq = 20, Icono = "rbxassetid://0", Desc = "Un golpe de precisión milimétrica que ignora bloqueos.", Animacion = "ArmorPierceAnim", CostoSP = 50, Dano = 150, VelocidadDash = 130, 
		Cooldown = 15, ColorPrimario = Color3.fromRGB(0, 255, 50), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	-- ==========================================
	-- 🔱 LANZAS Y ALABARDAS (Spear - Sachi Style)
	-- ==========================================
	["TripSwipe"] = {
		Nombre = "Trip Swipe", Para = "Lanza", Costo = 8, NivelReq = 5, Icono = "rbxassetid://0", Desc = "Un barrido bajo a las piernas con gran alcance horizontal.", Animacion = "TripSwipeAnim", CostoSP = 25, Dano = 50, VelocidadDash = 20, 
		Cooldown = 5, ColorPrimario = Color3.fromRGB(150, 200, 255), ColorSecundario = Color3.fromRGB(200, 230, 255)
	},
	["HelicalThrust"] = {
		Nombre = "Helical Thrust", Para = "Lanza", Costo = 18, NivelReq = 12, Icono = "rbxassetid://0", Desc = "Estocada giratoria como taladro que atraviesa enemigos.", Animacion = "HelicalThrustAnim", CostoSP = 40, Dano = 95, VelocidadDash = 80, 
		Cooldown = 9, ColorPrimario = Color3.fromRGB(50, 150, 255), ColorSecundario = Color3.fromRGB(150, 255, 255)
	},
	["SonicCharge"] = {
		Nombre = "Sonic Charge", Para = "Lanza", Costo = 30, NivelReq = 25, Icono = "rbxassetid://0", Desc = "Carga frontal imparable envuelta en energía sónica.", Animacion = "SonicChargeAnim", CostoSP = 65, Dano = 160, VelocidadDash = 150, 
		Cooldown = 15, ColorPrimario = Color3.fromRGB(0, 100, 255), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	-- ==========================================
	-- 🔨 MAZAS Y MARTILLOS (Mace - Lisbeth Style)
	-- ==========================================
	["PowerStrike"] = {
		Nombre = "Power Strike", Para = "Maza", Costo = 8, NivelReq = 5, Icono = "rbxassetid://0", Desc = "Un golpe descendente brutal que rompe la guardia enemiga.", Animacion = "PowerStrikeAnim", CostoSP = 30, Dano = 75, VelocidadDash = 25, 
		Cooldown = 6, ColorPrimario = Color3.fromRGB(255, 200, 50), ColorSecundario = Color3.fromRGB(255, 255, 150)
	},
	["SledgeHammer"] = {
		Nombre = "Sledge Hammer", Para = "Maza", Costo = 20, NivelReq = 14, Icono = "rbxassetid://0", Desc = "Golpea el suelo creando una onda sísmica a tu alrededor.", Animacion = "SledgeHammerAnim", CostoSP = 50, Dano = 120, VelocidadDash = 0, 
		Cooldown = 10, ColorPrimario = Color3.fromRGB(200, 80, 0), ColorSecundario = Color3.fromRGB(255, 150, 50)
	},
	["HeartStrike"] = {
		Nombre = "Heart Strike", Para = "Maza", Costo = 35, NivelReq = 25, Icono = "rbxassetid://0", Desc = "Impacto directo al pecho con fuerza explosiva. Daño masivo.", Animacion = "HeartStrikeAnim", CostoSP = 80, Dano = 200, VelocidadDash = 60, 
		Cooldown = 18, ColorPrimario = Color3.fromRGB(255, 50, 50), ColorSecundario = Color3.fromRGB(255, 150, 100)
	},
	-- ==========================================
	-- 🛡️ ESPADA Y ESCUDO (Holy Sword - Heathcliff Style)
	-- ==========================================
	["ShieldBash"] = {
		Nombre = "Shield Bash", Para = "Escudo", Costo = 10, NivelReq = 5, Icono = "rbxassetid://0", Desc = "Embiste con el escudo creando un muro de luz que aturde al enemigo.", Animacion = "ShieldBashAnim", CostoSP = 30, Dano = 45, VelocidadDash = 40, 
		Cooldown = 8, ColorPrimario = Color3.fromRGB(255, 255, 200), ColorSecundario = Color3.fromRGB(255, 200, 50)
	},
	["DivineSpear"] = {
		Nombre = "Divine Spear", Para = "Escudo", Costo = 25, NivelReq = 18, Icono = "rbxassetid://0", Desc = "Una estocada penetrante con luz sagrada de rango medio.", Animacion = "DivineSpearAnim", CostoSP = 55, Dano = 110, VelocidadDash = 60, 
		Cooldown = 12, ColorPrimario = Color3.fromRGB(255, 255, 255), ColorSecundario = Color3.fromRGB(255, 255, 100)
	},
	["HolyCross"] = {
		Nombre = "Holy Cross", Para = "Escudo", Costo = 45, NivelReq = 30, Icono = "rbxassetid://0", Desc = "Dibuja una cruz gigante de energía dorada que castiga en área.", Animacion = "HolyCrossAnim", CostoSP = 85, Dano = 180, VelocidadDash = 15, 
		Cooldown = 20, ColorPrimario = Color3.fromRGB(255, 215, 0), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	-- ==========================================
	-- 👊 ARTES MARCIALES (Extra Skill - Kirito/Gremio)
	-- ==========================================
	["Embracer"] = {
		Nombre = "Embracer", Para = "Artes Marciales", Costo = 12, NivelReq = 8, Icono = "rbxassetid://0", Desc = "Una estocada con los dedos envueltos en energía que perfora armaduras.", Animacion = "EmbracerAnim", CostoSP = 35, Dano = 85, VelocidadDash = 50, 
		Cooldown = 8, ColorPrimario = Color3.fromRGB(100, 100, 255), ColorSecundario = Color3.fromRGB(200, 200, 255)
	},
	["FlashFlurry"] = {
		Nombre = "Flash Flurry", Para = "Artes Marciales", Costo = 20, NivelReq = 15, Icono = "rbxassetid://0", Desc = "Una ráfaga de puñetazos a la velocidad de la luz.", Animacion = "FlashFlurryAnim", CostoSP = 50, Dano = 110, VelocidadDash = 30, 
		Cooldown = 12, ColorPrimario = Color3.fromRGB(255, 255, 255), ColorSecundario = Color3.fromRGB(150, 255, 255)
	},
	["MeteorFall"] = {
		Nombre = "Meteor Fall", Para = "Artes Marciales", Costo = 40, NivelReq = 30, Icono = "rbxassetid://0", Desc = "Agarre seguido de un impacto devastador contra el suelo.", Animacion = "MeteorFallAnim", CostoSP = 80, Dano = 190, VelocidadDash = 20, 
		Cooldown = 18, ColorPrimario = Color3.fromRGB(255, 100, 50), ColorSecundario = Color3.fromRGB(255, 200, 100)
	},
	-- ==========================================
	-- 🪃 ARMAS ARROJADIZAS (Throwing Picks - Kirito Style)
	-- ==========================================
	["PhantomNeedle"] = {
		Nombre = "Phantom Needle", Para = "Arrojadiza", Costo = 5, NivelReq = 3, Icono = "rbxassetid://0", Desc = "Lanza una púa a velocidad supersónica que es casi invisible.", Animacion = "PhantomNeedleAnim", CostoSP = 15, Dano = 45, VelocidadDash = 0, 
		Cooldown = 3, ColorPrimario = Color3.fromRGB(200, 200, 200), ColorSecundario = Color3.fromRGB(255, 255, 255)
	},
	["SpreadIllusion"] = {
		Nombre = "Spread Illusion", Para = "Arrojadiza", Costo = 18, NivelReq = 12, Icono = "rbxassetid://0", Desc = "Lanza 5 púas venenosas en forma de abanico frente a ti.", Animacion = "SpreadIllusionAnim", CostoSP = 40, Dano = 35, VelocidadDash = -20, -- Salto evasivo hacia atrás
		Cooldown = 8, ColorPrimario = Color3.fromRGB(50, 255, 100), ColorSecundario = Color3.fromRGB(150, 255, 150)
	}
}

return Habilidades
