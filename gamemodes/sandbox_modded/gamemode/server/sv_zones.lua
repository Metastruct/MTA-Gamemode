local tag = "MTAZones"
MTAZones = MTAZones or {
	Players = {},
	Zones = {},
}

local zones = {
	hospital = {
		mins = Vector(-890, -890, -48),
		maxs = Vector(890, 890, 174),
		pos  = Vector(-6848.03125, -1822.390625, 5450.0561523438),
		limiters = {
			{
				pos = Vector(-5966.96875, -1484.2528076172, 5480.2080078125),
				ang = Angle(0, 90, 90),
			},
		}
	},
	gunstore = {
		mins = Vector(-368, -272, 0),
		maxs = Vector(368, 272, 128),
		pos  = Vector(600.35116577148, 7350.8725585938, 5506.03125),
		limiters = {
			{
				pos = Vector(219.95001220703, 7326.2094726563, 5562.3706054688),
				ang = Angle(0, -90, 90),
			},
			{
				pos = Vector(880.13647460938, 7674.5073242188, 5578.03125),
				ang = Angle(0, 180, 90),
			}
		},
	}
}

local function ZoneCheck(ply, zone)
	local limiter = MTAZones.Zones[zone].limiters[1]
	if IsValid(limiter) then
		limiter:Touch(ply)
	end
end

MTAZones.ZoneUpdate = function(zone, ent, entered)
	if ent:IsPlayer() then
		if entered then
			if zone == "" then return end --Default zone name

			ZoneCheck(ent, zone)
			MTAZones.Players[ent] = zone
		else
			--print(ent, zone, "exit")
			MTAZones.Players[ent] = nil
		end
	end
end

local function SpawnZone(name, data)
	if MTAZones.Zones[name] then return end

	local ent = ents.Create("zone_trigger")
	ent:SetPos(data.pos)
	ent:Spawn()

	ent.Zone = name
	ent:SetupTriggerBox(data.mins, data.maxs)
	MTAZones.Zones[name] = {
		ent = ent,
		limiters = {},
	}

	for _, ldata in ipairs(data.limiters) do
		local limit = ents.Create("mta_area_limiter")
		limit:SetPos(ldata.pos)
		limit:SetAngles(ldata.ang)
		limit:Spawn()
		table.insert(MTAZones.Zones[name].limiters, limit)
	end
end

local function SpawnZones()
	for zone, data in pairs(zones) do
		SpawnZone(zone, data)
	end
end

hook.Add("PlayerShouldTakeDamage", tag, function(ply, attacker)
	if attacker:IsPlayer() and MTAZones.Players[ply] then return false end
end)

hook.Add("MTAWantedStateUpdate", tag, function(ply, is_wanted)
	if not is_wanted then return end
	local zone = MTAZones.Players[ply]
	if not zone then return end

	ZoneCheck(ply, zone)
end)

hook.Add("InitPostEntity", tag, function()
	SpawnZones()
end)

hook.Add("PostCleanupMap", tag, function()
	SpawnZones()
end)
