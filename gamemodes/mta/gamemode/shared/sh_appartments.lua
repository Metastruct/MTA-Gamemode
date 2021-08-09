local ROOM_HEIGHT = 160 -- hammer units
local APPARTMENTS = {
	-- home residency thing
	{
		name = "Apt. Complex Room A",
		bounds = {
			Vector(6551, -2543, 5720),
			Vector(6032, -2120, 5720),
		},
		entrance_id = 2569,
	},
	{
		name = "Apt. Complex Room B",
		bounds = {
			Vector(6551, -2120, 5520),
			Vector(6014, -2622, 5520),
		},
		entrance_id = 2567,
	},
	{
		name = "Apt. Complex Room C",
		bounds = {
			Vector(6551, -1879, 5520),
			Vector(6050, -1381, 5520),
		},
		entrance_id = 2568,
	},
	{
		name = "Apt. Complex Room D",
		bounds = {
			Vector(6551, -1456, 5720),
			Vector(6032, -1878, 5720),
		},
		entrance_id = 2570,
	},

	-- hotel
	{
		name = "Hotel Room A",
		bounds = {
			Vector(5976, 1891, 6072),
			Vector(6470, 1413, 6072),
		},
		entrance_id = 2560,
	},
	{
		name = "Hotel Room B",
		bounds = {
			Vector(5737, 2462, 6072),
			Vector(6126, 1973, 6072),
		},
		entrance_id = 2562,
	},
	{
		name = "Hotel Room C",
		bounds = {
			Vector(4906, 1617, 6072),
			Vector(5404, 2012, 6072),
		},
		entrance_id = 2559,
	},

	-- restaurant
	{
		name = "Restaurant Room",
		bounds = {
			Vector(1842, 225, 5632),
			Vector(2334, 774, 5632),
		},
		entrance_id = 2636,
	},

	-- big hotel
	{
		name = "Hotel Room D",
		bounds = {
			Vector(2162, 3421, 6112),
			Vector(2510, 2737, 6112),
		},
		entrance_id = 2868,
	},
	{
		name = "Hotel Room E",
		bounds = {
			Vector(2542, 2419, 6112),
			Vector(2017, 2071, 6112),
		},
		entrance_id = 2872,
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
	},

	-- abandonned house
	{
		name = "Abandonned House",
		bounds = {
			Vector(3794, 2829, 5432),
			Vector(4211, 2375, 5857),
		},
		entrance_id = 2609,
	},

	-- store (twelve 7)
	{
		name = "Twelve 7 Apt.",
		bounds = {
			Vector(4590, 6665, 5752),
			Vector(3793, 7252, 5752),
		},
		entrance_id = 2446,
	},
}