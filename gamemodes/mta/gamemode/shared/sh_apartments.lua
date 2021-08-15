
local ROOM_HEIGHT = 160 -- hammer units
local APARTMENT_DATA = {
	-- home residency thing
	{
		name = "Apt. Complex Room A",
		bounds = {
			Vector(6551, -2543, 5720),
			Vector(6032, -2120, 5720),
		},
		entrance_id = 2569,
		price = 10,
		travel_pos = Vector(6634, -2483, 5736)
	},
	{
		name = "Apt. Complex Room B",
		bounds = {
			Vector(6551, -2120, 5520),
			Vector(6014, -2622, 5520),
		},
		entrance_id = 2567,
		price = 10,
		travel_pos = Vector(6366, -2065, 5536)
	},
	{
		name = "Apt. Complex Room C",
		bounds = {
			Vector(6551, -1879, 5520),
			Vector(6050, -1381, 5520),
		},
		entrance_id = 2568,
		price = 10,
		travel_pos = Vector(6367, -1933, 5548)
	},
	{
		name = "Apt. Complex Room D",
		bounds = {
			Vector(6551, -1456, 5720),
			Vector(6032, -1878, 5720),
		},
		entrance_id = 2570,
		price = 10,
		travel_pos = Vector(6593, -1517, 5733)
	},

	-- hotel
	{
		name = "Hotel Room A",
		bounds = {
			Vector(5976, 1891, 6072),
			Vector(6470, 1413, 6072),
		},
		entrance_id = 2560,
		price = 10,
		travel_pos = Vector(5923, 1779, 6095)
	},
	{
		name = "Hotel Room B",
		bounds = {
			Vector(5737, 2462, 6072),
			Vector(6126, 1973, 6072),
		},
		entrance_id = 2562,
		price = 10,
		travel_pos = Vector(5848, 1911, 6090)
	},
	{
		name = "Hotel Room C",
		bounds = {
			Vector(4906, 1617, 6072),
			Vector(5404, 2012, 6072),
		},
		entrance_id = 2559,
		price = 10,
		travel_pos = Vector(5451, 1728, 6091)
	},

	-- restaurant
	{
		name = "Restaurant Room",
		bounds = {
			Vector(1842, 225, 5632),
			Vector(2334, 774, 5632),
		},
		entrance_id = 2636,
		price = 15,
		travel_pos = Vector(2389, 700, 5646)
	},

	-- big hotel
	{
		name = "Hotel Room D",
		bounds = {
			Vector(2162, 3421, 6112),
			Vector(2510, 2737, 6112),
		},
		entrance_id = 2868,
		price = 10,
		travel_pos = Vector(2542, 3038, 6119)
	},
	{
		name = "Hotel Room E",
		bounds = {
			Vector(2542, 2419, 6112),
			Vector(2017, 2071, 6112),
		},
		entrance_id = 2872,
		price = 10,
		travel_pos = Vector(2479, 2385, 6133)
	},
	{
		name = "Hotel Room F",
		convex_bounds = true,
		bounds = {
			{
				Vector(2609, 2486, 6112),
				Vector(2934, 2129, 6112),
			},
			{
				Vector(2689, 2488, 6112),
				Vector(2918, 2791, 6112),
			}
		},
		entrance_id = 2870,
		price = 10,
		travel_pos = Vector(2625, 2588, 6123)
	},
	{
		name = "Hotel Room G",
		convex_bounds = true,
		bounds = {
			{
				Vector(2538, 3365, 6112),
				Vector(3118, 3169, 6112),
			},
			{
				Vector(2953, 3158, 6112),
				Vector(3119, 3004, 6112),
			}
		},
		entrance_id = 2874,
		price = 10,
		travel_pos = Vector(2611, 3142, 6130)
	},

	-- abandoned house
	{
		name = "Abandoned House",
		bounds = {
			Vector(3794, 2829, 5432),
			Vector(4211, 2375, 5857),
		},
		entrance_id = 2609,
		price = 30,
		travel_pos = Vector(3692, 2769, 5454)
	},

	-- store (twelve 7)
	{
		name = "Twelve 7 Apt.",
		bounds = {
			Vector(4590, 6665, 5752),
			Vector(3793, 7252, 5752),
		},
		entrance_id = 2446,
		price = 30,
		travel_pos = Vector(4510, 6608, 5781)
	},
}

local MTA_Apartments = MTA_TABLE("Apartments")
local Tag = "MTA_Apartments"

local function SetupApartments()
	local apts = {}
	local apt_data = APARTMENT_DATA

	for _, data in ipairs(apt_data) do
		local apt_table = {
			Data = data,
			Renter = nil,
			Invitees = {}
		}

		if SERVER then
			apt_table.Entrance = ents.GetMapCreatedEntity(data.entrance_id)

			local apt_bounds = data.bounds
			if not data.convex_bounds then apt_bounds = {apt_bounds} end

			local triggers = {}
			for _, bounds in ipairs(apt_bounds) do
				local mins = bounds[1]
				local maxs = bounds[2] + Vector(0, 0, ROOM_HEIGHT)

				local trigger = ents.Create("apartment_trigger")
				trigger:SetupTriggerBox(mins, maxs)
				trigger:SetParentApt(apt_table)

				table.insert(triggers, trigger)
			end

			apt_table.TRIGGERS = triggers
		end

		apts[data.name] = apt_table
	end

	return apts
end

hook.Add("InitPostEntity", Tag, function()
	MTA_Apartments.List = SetupApartments()
end)

hook.Add("PostCleanupMap", Tag, function()
	MTA_Apartments.List = SetupApartments()
end)