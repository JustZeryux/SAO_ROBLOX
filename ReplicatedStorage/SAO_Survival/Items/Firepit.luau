-- ReplicatedStorage > SAO_Modules > Items > Firepit
local Item = {
	Name = "Firepit",
	Category = "Crafting",
	Description = "You can heal around it quicker or cook any meats",
	Ingredients = {
		["Wood legs"] = 3
	},
	Placeable = true,
	Model = "FirepitModel" -- Asegúrate de tener un modelo con este nombre en ReplicatedStorage.Models
}

return Item
