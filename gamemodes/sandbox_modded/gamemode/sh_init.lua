include ("cl_targetid.lua")

DeriveGamemode("sandbox")

GM.Name = "MTA"
GM.Author = "Meta Construct"
GM.Email = ""
GM.Website = "http://metastruct.net"

team.SetUp(6669, "Wanted", Color(244, 135, 2), false)
team.SetUp(6668, "Bounty Hunters", Color(255, 0, 0), false)

if SERVER then
	resource.AddWorkshop("372740052") -- synthetik health bars

	function GM:pac_Initialized()
		game.ConsoleCommand("pac_modifier_size 0\n")
		game.ConsoleCommand("pac_modifier_model 0\n")
		game.ConsoleCommand("pac_sv_projectiles 0\n")
	end

	game.ConsoleCommand("sbox_godmode 0\n")
	game.ConsoleCommand("sv_allowcslua 0\n")

	local hooks = {
		"PlayerSpawnEffect", "PlayerSpawnNPC", "PlayerSpawnObject", "PlayerSpawnProp",
		"PlayerSpawnSENT", "PlayerSpawnSWEP", "PlayerSpawnVehicle", "PlayerNoClip", "PlayerGiveSWEP",
		"CanSSJump", "AowlGiveAmmo"
	}

	for _, hook_name in pairs(hooks) do
		GM[hook_name] = function(gm, ply)
			return ply:IsAdmin()
		end
	end

	function GM:PlayerLoadout(ply)
		if ply:IsAdmin() then
			ply:Give("weapon_physgun")
		end

		ply:Give("weapon_crowbar")
		ply:Give("none")
		ply:Give("gmod_camera")

		ply:SelectWeapon("none")

		return true
	end

	function GM:EntityTakeDamage(target, dmg)
		if target:GetClass() == "lua_npc" then return true end
	end

	local mta_ents = {
		{
			["ang"] = Angle(0, 0, 0),
			["pos"] = Vector(840, -4237, 5498),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(446, 7486, 5510),
			["class"] = "lua_npc",
			["role"] = "dealer",
		},
		{
			["ang"] = Angle(0, 0, 0),
			["pos"] = Vector(3904, 7282, 5510),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, -180, 0),
			["pos"] = Vector(645, 7245, 5506),
			["class"] = "mta_skills_computer",
		},
		{
			["ang"] = Angle(0, 0, 0),
			["pos"] = Vector(6048, -362, 555),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(-6702, 2956, 5449),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, 0, 0),
			["pos"] = Vector(237, 7539, 5547),
			["class"] = "mta_jukebox",
		},
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(-2242, 5527, 5507),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(-6368, 2949, 5449),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(2267, 1183, 5425),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, 90, 0),
			["pos"] = Vector(-6345, 2462, 5449),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, 90, 0),
			["pos"] = Vector(-6678, 2445, 5449),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(89, -6, 94),
			["pos"] = Vector(966, 7508, 5550),
			["class"] = "mta_riot_shield_table",
		},
	}

	local function spawn_ents()
		if not game.GetMap():match("^rp%_unioncity") then return end

		for _, data in pairs(mta_ents) do
			local ent = ents.Create(data.class)
			ent:SetPos(data.pos)
			ent:SetAngles(data.ang)
			ent.role = data.role
			ent:Spawn()
			--ent:DropToFloor()
		end
	end

	function GM:PostCleanupMap()
		spawn_ents()
	end

	local max_wanders = 40
	function GM:InitPostEntity()
		spawn_ents()

		if not navmesh.IsLoaded() then return end
		local nodes = navmesh.GetAllNavAreas()
		local node_poses = {}
		for _, node in pairs(nodes) do
			table.insert(node_poses, node:GetCenter())
		end

		ms = ms or {}
		ms.mapdata = ms.mapdata or {}
		ms.mapdata.w_walktable = node_poses

		timer.Create("mta_wanders", 1, 0, function()
			local wanders = ents.FindByClass("lua_npc_wander")
			if #wanders < max_wanders then
				local node = nodes[math.random(#nodes)]
				local wander = ents.Create("lua_npc_wander")
				wander:SetPos(node:GetCenter())
				wander:Spawn()
			end
		end)
	end

	function GM:PlayerCanHearPlayersVoice(listener, speaker)
		return true, true
	end

	local jail_spots = {
		Vector(1870, -974, 5416),
		Vector(2124, -985, 5416),
		Vector(2112, -1329, 5416),
		Vector(1999, -1317, 5416),
		Vector(1888, -1331, 5416)
	}
	function GM:MTAPlayerFailed(ply, max_factor, old_factor, is_death)
		local spot = jail_spots[math.random(#jail_spots)]
		timer.Simple(0.5, function()
			if not IsValid(ply) then return end
			ply:Spawn()
			ply:SetPos(spot)
		end)
	end

	local function handle_mta_team(ply, state, mta_id)
		if state then
			ply:SetTeam(mta_id)
		elseif aowl then
			ply:SetTeam(ply:IsAdmin() and 2 or 1) -- aowl compat?
		else
			ply:SetTeam(1)
		end
	end

	function GM:MTAWantedStateUpdate(ply, is_wanted)
		handle_mta_team(ply, is_wanted, 6669)
	end

	function GM:MTABountyHunterStateUpdate(ply, is_bounty_hunter)
		handle_mta_team(ply, is_wanted, 6668)
	end
end