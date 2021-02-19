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

local function SetupChargers()
	for _, data in ipairs(hospitalChargers) do
		CreateCharger(data.pos, data.ang)
	end

	for _, data in ipairs(randomChargers) do
		CreateCharger(data.pos, data.ang)
	end
end

hook.Add("InitPostEntity", tag, function()
	SetupChargers()
end)

hook.Add("PostCleanupMap", tag, function()
	SetupChargers()
end)
