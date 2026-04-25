-- ReplicatedStorage > SAO_Modules > Items > Firepit
local Item = {
	Name = "Tent",
	Category = "Camping",
	Description = "You can heal around it quicker or cook any meats",
	Ingredients = {
		["Wood legs"] = 19
	},
	Placeable = true,
	Model = "TentModel" -- Asegúrate de tener un modelo con este nombre en ReplicatedStorage.Models
}

return Item
