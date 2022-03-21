local barricades = {
	-- right barricades
	{
		mdl = "models/props_combine/combine_barricade_med01a.mdl",
		ang = Angle(0, 45, 0),
		pos = Vector(952, 5550, 5526),
	},
	{
		mdl = "models/props_combine/combine_barricade_med01a.mdl",
		ang = Angle(0, 67, 0),
		pos = Vector(905, 5575, 5526),
	},
	{
		mdl = "models/props_combine/combine_barricade_med01a.mdl",
		ang = Angle(0, 90, 0),
		pos = Vector (856, 5587, 5526),
	},


	-- left barricade
	{
		mdl = "models/props_combine/combine_barricade_tall03a.mdl",
		ang = Angle(0, 0, 0),
		pos = Vector(1064, 5329, 5526),
	},

	-- small barricades center
	{
		mdl = "models/props_combine/combine_barricade_short02a.mdl",
		ang = Angle(0, 5, 0),
		pos = Vector(937, 5513, 5526),
	},
	{
		mdl = "models/props_combine/combine_barricade_short02a.mdl",
		ang = Angle(0, 5, 0),
		pos = Vector(992, 5406, 5526),
	}
}

local function spawn_rebel_base()
	for _, barricade_data in pairs(barricades) do
		local barricade = ents.Create("prop_physics")
		barricade:SetModel(barricade_data.mdl)
		barricade:SetAngles(barricade_data.ang)
		barricade:SetPos(barricade_data.pos)
		barricade:Spawn()

		local phys = barricade:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end

		barricade.ms_notouch = true
		barricade.stand_antenna = true
	end
end

local stands = {
	{
		pos = Vector (806, 5108, 5516),
		ang = Angle(0, 90, 0),
		role = "",
	},
	{
		pos = Vector(559, 5112, 5516),
		ang = Angle(0, 90, 0),
		role = "",
	}
}

local function spawn_rebel_stand(pos, ang, role)
	local antenna_mdl = "models/combine_turrets/combine_cannon_stand.mdl"
	local stand_mdl = "models/props_junk/wood_crate002a.mdl"

	local stand = ents.Create("prop_physics")
	stand:SetModel(stand_mdl)
	stand:SetPos(pos)
	stand:Spawn()
	stand.ms_notouch = true
	stand.stand_antenna = true

	hook.Add("EntityTakeDamage", stand, function(self, ent)
		if ent == self then return true end
	end)

	local phys = stand:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	local stand_antenna = ents.Create("prop_physics")
	stand_antenna:SetModel(antenna_mdl)
	stand_antenna:SetPos(stand:GetPos() + -stand:GetRight() * 50 + Vector(0, 0, 120))
	stand_antenna:SetAngles(Angle(0, 180, -90))
	stand_antenna:SetParent(stand)
	stand_antenna:Spawn()
	stand_antenna.ms_notouch = true
	stand_antenna.no_door_explode = true

	phys = stand_antenna:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:EnableCollisions(false)
	end

	local vendor = ents.Create("lua_npc")
	vendor:SetPos(stand:GetPos() + -stand:GetForward() * 30 - Vector(0, 0, 20))
	vendor:Spawn()
	vendor:SetParent(stand)
	vendor.ms_notouch = true
	vendor.role = role

	stand:SetAngles(ang)
end

local function spawn_stands()
	for _, stand_data in ipairs(stands) do
		spawn_rebel_stand(stand_data.pos, stand_data.ang, stand_data.role)
	end
end

local guard_models = {
	"models/humans/group03/female_01.mdl",
	"models/humans/group03/female_02.mdl",
	"models/humans/group03/female_03.mdl",
	"models/humans/group03/female_04.mdl",
	"models/humans/group03/female_06.mdl",
	"models/humans/group03/female_07.mdl",

	"models/humans/group03/male_01.mdl",
	"models/humans/group03/male_02.mdl",
	"models/humans/group03/male_03.mdl",
	"models/humans/group03/male_04.mdl",
	"models/humans/group03/male_05.mdl",
	"models/humans/group03/male_06.mdl",
	"models/humans/group03/male_07.mdl",
	"models/humans/group03/male_08.mdl",
	"models/humans/group03/male_09.mdl",
}

local guards = {}
local function spawn_guard(pos, ang)
	local guard = ents.Create("npc_citizen")
	guard:Give("weapon_smg1")
	guard:SetPos(pos)
	guard:SetAngles(ang)
	guard:Spawn()
	guard:SetModel(guard_models[math.random(#guard_models)])
	guard:SetKeyValue("classname", "Rebel")
	guard:SetHealth(5000)
	guard:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_PERFECT)
	guard.ms_notouch = true

	table.insert(guards, { npc = guard, pos = pos, ang = ang })
end

hook.Add("Think", "rebel_guards", function()
	for i, guard_data in pairs(guards) do
		if not IsValid(guard_data.npc) then
			table.remove(guards, i)
			timer.Simple(20, function()
				spawn_guard(guard_data.pos, guard_data.ang)
			end)

			continue
		end

		if IsValid(guard_data.npc:GetEnemy()) and guard_data.npc:GetEnemy():Health() > 0 then continue end

		if guard_data.pos:DistToSqr(guard_data.npc:GetPos()) < 25 * 25 then
			guard_data.npc:SetAngles(guard_data.ang)
			guard_data.npc:SetPos(guard_data.pos)
			guard_data.npc:ClearSchedule()
			guard_data.npc:StopMoving()
		else
			guard_data.npc:SetLastPosition(guard_data.pos)
			guard_data.npc:SetSchedule(SCHED_FORCED_GO)
		end
	end
end)

hook.Add("ScaleNPCDamage", "rebel_guards", function(npc, _, dmg_info)
	local attacker = dmg_info:GetAttacker()
	if not IsValid(attacker) then return end

	if npc:GetNWBool("MTANPC") and attacker:GetClass() == "Rebel" then
		dmg_info:SetDamage(1000)
	end
end)

hook.Add("InitPostEntity", "mta_rebel_camp", function()
	spawn_rebel_base()

	spawn_guard(Vector(980, 5388, 5496), Angle(0, 90, 0))
	spawn_guard(Vector(906, 5496, 5496), Angle(0, 0, 0))
	spawn_guard(Vector(313, 5393, 5496), Angle(0, 0, 0))

	spawn_stands()
end)

hook.Add("PostCleanupMap", "mta_rebel_camp", function()
	spawn_rebel_base()
	spawn_stands()
end)