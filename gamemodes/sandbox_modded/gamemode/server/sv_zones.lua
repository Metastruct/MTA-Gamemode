local tag = "MTAZones"
local MTAZones = MTA_TABLE("Zones")
MTAZones.Players = MTAZones.Players or {}
MTAZones.Zones = MTAZones.Zones or {}

local zones = {
	hospital = {
		mins = Vector(-890, -890, -48),
		maxs = Vector(890, 890, 174),
		pos  = Vector(-6848.03125, -1822.390625, 5450.0561523438),
		limiters = {
			{
				pos = Vector(-5967, -1484.2, 5480.2),
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
				pos = Vector(220, 7326.2, 5562.4),
				ang = Angle(0, -90, 90),
			},
			{
				pos = Vector(880.1, 7674.5, 5578),
				ang = Angle(0, 180, 90),
			}
		},
	},
	spawnArea = {
		zones = {
			{
				mins = Vector(-600, -500, 0),
				maxs = Vector(500, 500, 450),
				pos  = Vector(5622.3896484375, 1560, 5025),
			},
			{
				mins = Vector(-500, -500, -50),
				maxs =  Vector(500, 550, 256),
				pos = Vector(5584.6279296875, -1560, 4800),
			},
		},
		limiters = {
			{
				pos = Vector(5335, -1175, 5435),
				ang = Angle(0, 180, 90),
			},
		},
	},
	misc = {
		onlyLimiter = true,
		limiters = {
			--Sewers
			{
				pos = Vector(-5663.4, 3444.4, 5370.2),
				ang = Angle(25, 0, 0),
			},
			{
				pos = Vector(-6890, 3235, 5508.2),
				ang = Angle(0, -90, 90),
			},
			--Ladder to roof at pool
			{
				pos = Vector(-3371.5, 5601.5, 5600),
				ang = Angle(0, 0, 90),
			},
		},
	},
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
	--if MTAZones.Zones[name] then return end

	local ent
	if not data.onlyLimiter then

		if data.zones then
			ent = {}
			for _, zdata in ipairs(data.zones) do
				local _ent = ents.Create("zone_trigger")
				_ent:SetPos(zdata.pos)
				_ent:Spawn()

				_ent.Zone = name
				_ent:SetupTriggerBox(zdata.mins, zdata.maxs)
				table.insert(ent, _ent)
			end
		else
			ent = ents.Create("zone_trigger")
			ent:SetPos(data.pos)
			ent:Spawn()

			ent.Zone = name
			ent:SetupTriggerBox(data.mins, data.maxs)
		end
	end

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
