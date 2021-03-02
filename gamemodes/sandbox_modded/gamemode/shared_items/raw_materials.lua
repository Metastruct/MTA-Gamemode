local function create_raw_material(item_class, item_name, item_mdl, item_stack_limit, item_rarity)
	MTA.Inventory.RegisterItem(item_class, {
		Name = item_name,
		Model = item_mdl,
		StackLimit = item_stack_limit,
		Rarity = item_rarity
	})
end

-- combine drops
do
	-- combines
	create_raw_material("combine_shell", "Shell", "models/items/ar2_grenade.mdl", 64, 20)
	create_raw_material("combine_core", "Combine Core", "models/items/combine_rifle_ammo01.mdl", 6, 5)
	create_raw_material("biomass", "Combine Biomass", "models/gibs/shield_scanner_gib6.mdl", 64, 30)

	-- manhacks
	create_raw_material("mh_debris", "Manhack Debris", "models/gibs/manhack_gib05.mdl", 64, 30)
	create_raw_material("mh_engine", "Manhack Engine", "models/gibs/manhack_gib02.mdl", 6, 5)
	create_raw_material("metal_part", "Metal Part", "models/gibs/manhack_gib03.mdl", 32, 15)

	-- helicopters
	create_raw_material("heli_rotor", "Rotor", "models/gibs/helicopter_brokenpiece_05_tailfan.mdl", 1, 100) -- always drop on helis
	create_raw_material("heli_metal_plate", "Big Metal Plate", "models/gibs/helicopter_brokenpiece_02.mdl", 3, 45)
end

-- car items drops
do
	create_raw_material("wheel", "Wheel", "models/props_vehicles/tire001c_car.mdl", 6, 50)
	create_raw_material("gear", "Gear", "models/props_wasteland/gear01.mdl", 1, 35)
	create_raw_material("muffler", "Muffler", "models/props_vehicles/carparts_muffler01a.mdl", 1, 15)
	create_raw_material("connector", "Connector", "models/props_c17/utilityconnecter006c.mdl", 12, 35)
end

-- map items
do
	create_raw_material("gas_can", "Gas Can", "models/props_junk/gascan001a.mdl", 12, 10)
	create_raw_material("brick", "Brick", "models/props_junk/cinderblock01a.mdl", 32, 30)
	create_raw_material("old_shoes", "Old Shoes", "models/props_junk/shoe001a.mdl", 2, 30)
	create_raw_material("empty_create", "Empty Create", "models/props_junk/wood_crate001a.mdl", 1, 10)
	create_raw_material("sawblade", "Sawblade", "models/props_junk/sawblade001a.mdl", 6, 5)
	create_raw_material("can", "Soda Can", "models/props_junk/popcan01a.mdl", 64, 40)
	create_raw_material("propane_tank", "Propane", "models/props_junk/propane_tank001a.mdl", 12, 10)
end