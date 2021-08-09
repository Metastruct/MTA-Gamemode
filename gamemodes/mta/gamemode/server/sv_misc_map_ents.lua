local tag = "misc_map_ents"
local hospitalChargers = {
	{ pos = Vector(-6540, -2225, 5500), ang = Angle(0, -90, 0) },
	{ pos = Vector(-7030, -2225, 5500), ang = Angle(0, -90, 0) },
	{ pos = Vector(-7280, -1710, 5500), ang = Angle(0, -180, 0) },
	{ pos = Vector(-7025, -1330, 5500), ang = Angle(0, -180, 0) },
	{ pos = Vector(-6495, -1610, 5500), ang = Angle() },
	{ pos = Vector(-6705, -1390, 5500), ang = Angle(0, 90, 0) },
}
local randomChargers = {
	{ pos = Vector(1105, -4365, 5485), ang = Angle(0, 180, 0) },
	{ pos = Vector(3635, -1555, 5565), ang = Angle(0, 180, 0) },
	{ pos = Vector(1170, -1145, 5475), ang = Angle(0, -90, 0) },

	{ pos = Vector(3170, 2345, 5475), ang = Angle(0, 0, 0) },
	{ pos = Vector(675, 7555, 5565),  ang = Angle(0, 0, 0) },
	{ pos = Vector(1615, 8435, 5880), ang = Angle(0, 90, 0) },

	{ pos = Vector(-1345, 5635, 5560), ang = Angle(0, 180, 0) },
	{ pos = Vector(-3030, 8275, 5875), ang = Angle(0, 90, 0) },
	{ pos = Vector(-5255, 2495, 5505), ang = Angle(0, 0, 0) },
	{ pos = Vector(-5256, 2880, 5505), ang = Angle(0, 0, 0) },
}

local specialItems = {
	"nextbot_chicken",
	"npc_headcrab",
	"npc_grenade_frag",
	"npc_seagull",
	"npc_pigeon",
	"npc_crow",
	"npc_cscanner",
	"npc_manhack"
}

local itemList = {
	--"item_dynamic_resupply",
	"item_ammo_pistol",
	"item_ammo_smg1",
	"item_ammo_ar2",
	"item_box_buckshot",
	"item_ammo_357",
	"item_ammo_crossbow",

	"item_healthvial",
	"item_battery",

	"weapon_slam",
	"weapon_frag",
	"item_rpg_round",
	"item_ammo_smg1_grenade",
	"item_ammo_ar2_altfire",
}

local randomSupplyCrates = {
	Vector(-393,  3003,  5418),
	Vector(3300,  1537,  5435),
	Vector(5989,  -2435, 5504),
	Vector(-4239, -4473, 5296),
	Vector(2794,  756,   5430),
	Vector(4182,  2473,  5432),
	Vector(4785,  7315,  5508),
	Vector(3985,  6461,  5511),
	Vector(2388,  10662, 5600),
	Vector(1693,  8672,  5820),
	Vector(-3025, 8582,  5816),
	Vector(-4032, 7841,  5528),
	Vector(-4573, 5352,  4784),
	Vector(-4931, 3229,  4754),
	Vector(-6552, 3877,  5120),
	Vector(-6234, 1449,  5416),
	Vector(-4410, -2216, 5428),
	Vector(-4485, -2791, 5243),
	Vector(-3370, 5662,  5496),
}

--10 to 15 minutes
local respawnTime = {600, 900}
local specialPercent = 5
local boomPercent = 10

local function CreateCrate(pos)
	local ent = ents.Create("item_item_crate")

	if math.random(0, 100) <= specialPercent then
		local item = specialItems[math.random(1, #specialItems)]

		ent:SetKeyValue("ItemClass", item)
		ent:SetKeyValue("ItemCount", 1)
	else
		local item = itemList[math.random(1, #itemList)]

		ent:SetKeyValue("ItemClass", item)
		ent:SetKeyValue("ItemCount", 2)
	end

	-- separate calculation for boom, or it will explode everytime we get a special item lol
	if math.random(0, 100) <= boomPercent then
		ent:SetKeyValue("ExplodeDamage", 25)
		ent:SetKeyValue("ExplodeRadius", 64)
	end

	ent:SetKeyValue("spawnflags", 8)
	ent:SetPos(pos)
	ent:Spawn()
	ent.doRespawn = true

	ent:CallOnRemove("crate_gone", function(self)
		if self.doRespawn then
			timer.Simple(math.Rand(respawnTime[1], respawnTime[2]), function()
				CreateCrate(pos)
			end)
		end
	end)
end

local function CreateCharger(pos, angle)
	local ent = ents.Create("item_suitcharger")
	ent:SetPos(pos)
	ent:SetAngles(angle)
	ent:SetKeyValue("spawnflags", "8192")
	ent:Spawn()
	ent:Activate()
	ent.PhysgunDisabled = true
	ent:SetModel("models/props_combine/health_charger001.mdl")

	function ent:CanProperty() return false end
	function ent:CanTool() return false end

	return ent
end

local function SetupCrates()
	for _, pos in ipairs(randomSupplyCrates) do
		CreateCrate(pos)
	end
end

local function SetupChargers()
	for _, data in ipairs(hospitalChargers) do
		CreateCharger(data.pos, data.ang)
	end

	for _, data in ipairs(randomChargers) do
		CreateCharger(data.pos, data.ang)
	end
end

hook.Add("InitPostEntity", tag, function()
	SetupCrates()
	SetupChargers()
end)

hook.Add("PostCleanupMap", tag, function()
	SetupChargers()
end)
