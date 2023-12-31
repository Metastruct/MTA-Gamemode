local crafts = {
	sawblade = {
		{ Resource = "metal_part", Amount = 4 }
	}
}

local function create_resource_item(item_class, item_name, item_mdl, item_stack_limit, item_rarity)
	MTA.Inventory.RegisterItem(item_class, {
		Name = item_name,
		Description = ("Just a %s, nothing special about it."):format(item_name),
		Model = item_mdl,
		StackLimit = item_stack_limit,
		Rarity = item_rarity,
		Usable = false,
		Craft = crafts[item_class],
	})
end

-- combine drops
do
	-- combines
	create_resource_item("combine_shell", "Shell", "models/items/ar2_grenade.mdl", 64, 20)
	create_resource_item("combine_core", "Combine Core", "models/items/combine_rifle_ammo01.mdl", 6, 5)
	create_resource_item("biomass", "Combine Biomass", "models/gibs/shield_scanner_gib6.mdl", 64, 30)

	-- manhacks
	create_resource_item("mh_debris", "Manhack Debris", "models/gibs/manhack_gib05.mdl", 64, 30)
	create_resource_item("mh_engine", "Manhack Engine", "models/gibs/manhack_gib02.mdl", 6, 5)
	create_resource_item("metal_part", "Metal Part", "models/gibs/manhack_gib03.mdl", 64, 40)

	-- helicopters
	create_resource_item("heli_rotor", "Rotor", "models/gibs/helicopter_brokenpiece_05_tailfan.mdl", 1, 100) -- always drop on helis
	create_resource_item("heli_metal_plate", "Big Metal Plate", "models/gibs/helicopter_brokenpiece_02.mdl", 3, 45)
end

-- car items drops
do
	create_resource_item("wheel", "Wheel", "models/props_vehicles/tire001c_car.mdl", 6, 50)
	create_resource_item("gear", "Gear", "models/props_wasteland/gear01.mdl", 1, 35)
	create_resource_item("muffler", "Muffler", "models/props_vehicles/carparts_muffler01a.mdl", 1, 15)
	create_resource_item("connector", "Connector", "models/props_c17/utilityconnecter006c.mdl", 12, 35)
end

-- map items
do
	create_resource_item("gas_can", "Gas Can", "models/props_junk/gascan001a.mdl", 12, 10)
	create_resource_item("brick", "Brick", "models/props_junk/cinderblock01a.mdl", 32, 30)
	create_resource_item("old_shoes", "Old Shoes", "models/props_junk/shoe001a.mdl", 2, 30)
	create_resource_item("empty_crate", "Empty Crate", "models/props_junk/wood_crate001a.mdl", 1, 10)
	create_resource_item("sawblade", "Sawblade", "models/props_junk/sawblade001a.mdl", 6, 5)
	create_resource_item("can", "Soda Can", "models/props_junk/popcan01a.mdl", 64, 40)
	create_resource_item("propane_tank", "Propane", "models/props_junk/propane_tank001a.mdl", 12, 10)
end

local tag = "resource_items"

if SERVER then
	local combine_soldier_drops = { "combine_shell", "combine_core", "biomass" }
	local combine_manhack_drops = { "mh_debris", "mh_engine", "metal_part" }
	local combine_helicopter_drops = { "heli_rotor", "heli_metal_plate" }
	local car_drops = { "wheel", "gear", "muffler", "connector" }

	local MAX_DROPPED_RESOURCES = 20
	local dropped_resources = {}
	local function handle_drops(drops, min_drops, max_drops, origin_pos)
		if #drops == 0 then return end

		local drop_count = math.random(min_drops, max_drops)
		for _ = 1, drop_count do
			local item_class = drops[math.random(#drops)]
			local item = MTA.Inventory.Items[item_class]
			if item and math.random(0, 100) < (item.Rarity or 100) then
				local item_ent = MTA.Inventory.CreateItemEntity(item_class, origin_pos)
				if IsValid(item_ent) then
					local phys = item_ent:GetPhysicsObject()
					if IsValid(phys) then
						phys:SetVelocity(VectorRand(-500, 500))
					end

					table.insert(dropped_resources, item_ent)
					if #dropped_resources >= MAX_DROPPED_RESOURCES then
						local oldest_item = dropped_resources[1]
						SafeRemoveEntity(oldest_item)
						table.remove(dropped_resources, 1)
					end
				end
			end
		end
	end

	hook.Add("OnNPCKilled", tag, function(npc)
		local drops = {}
		local max_drops = 5
		local min_drops = 0
		local class = npc:GetClass()
		if class == "npc_metropolice" or class == "npc_combine_s" then
			max_drops = 4
			drops = combine_soldier_drops
		elseif class == "npc_manhack" then
			max_drops = 6
			min_drops = 1
			drops = combine_manhack_drops
		elseif class == "npc_helicopter" then
			drops = combine_helicopter_drops
			max_drops = 10
			min_drops = 1
		end

		handle_drops(drops, min_drops, max_drops, npc:WorldSpaceCenter())
	end)

	hook.Add("OnEntityCreated", tag, function(ent)
		if ent:GetClass() ~= "gmod_sent_vehicle_fphysics_base" then return end

		local old_OnDestroyed = ent.OnDestroyed
		function ent:OnDestroyed()
			handle_drops(car_drops, 2, 10, ent:WorldSpaceCenter())
			old_OnDestroyed(self)
		end
	end)
end