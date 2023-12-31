local ITEM = {}

ITEM.Name = "Drill"
ITEM.Description = "A drill, allows you to break into vaults."
ITEM.Model = "models/props_combine/combine_mine01.mdl"
ITEM.StackLimit = 12
ITEM.Usable = false
ITEM.Craft = {
	{ Resource = "combine_core", Amount = 1 },
	{ Resource = "mh_debris", Amount = 3 },
	{ Resource = "biomass", Amount = 4 },
}

MTA.Inventory.RegisterItem("drill", ITEM)