DeriveGamemode("sandbox")

GM.Name = "MTA"
GM.Author = "Meta Construct"
GM.Email = ""
GM.Website = "http://metastruct.net"

team.SetUp(6669, "Wanted", Color(244, 135, 2), false)
team.SetUp(6668, "Bounty Hunters", Color(255, 0, 0), false)

GM["PlayerNoClip"] = function(gm, ply) return ply:IsAdmin() end

if SERVER then
	resource.AddWorkshop("372740052") -- synthetik health bars
	resource.AddWorkshop("2061960116") -- vault model

	function GM:pac_Initialized()
		game.ConsoleCommand("pac_modifier_size 0\n")
		game.ConsoleCommand("pac_modifier_model 0\n")
		game.ConsoleCommand("pac_sv_projectiles 0\n")
	end

	local DENIED_HOOKS = {
		"PlayerSpawnEffect", "PlayerSpawnNPC", "PlayerSpawnObject", "PlayerSpawnProp",
		"PlayerSpawnSENT", "PlayerSpawnSWEP", "PlayerSpawnVehicle", "PlayerNoClip", "PlayerGiveSWEP",
		"CanSSJump", "AowlGiveAmmo", "CanPlyTeleport", "CanBoxify", "PlayerFly", "CanPlyGoBack",
		"Watt.CanPerformAction",
	}

	for _, hook_name in pairs(DENIED_HOOKS) do
		GM[hook_name] = function(gm, ply)
			return ply:IsAdmin()
		end
	end

	function GM:CanPlyGoto(ply, line)
		local dest = (line or ""):Trim():lower()
		if aowl and aowl.GotoLocations and aowl.GotoLocations[dest] then return end

		return ply:IsAdmin()
	end

	-- hack to spawn people in the hospital
	local HOSPITAL_ENTRY_POS = Vector (-5716, -1462, 5416)
	function GM:CanPlyRespawn(ply, transition)
		player_manager.SetPlayerClass(ply, "player_sandbox")
		self.BaseClass.PlayerSpawn(self, ply, transition)

		local rand_pos = HOSPITAL_ENTRY_POS + Vector(0, math.random(-500, 500), 0)
		ply:SetPos(rand_pos)
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

	function GM:CanDrive(ply, ent)
		if not ply:IsAdmin() then return false end
	end

	function GM:EntityTakeDamage(target, dmg)
		if target:GetClass() == "lua_npc" then return true end
	end

	local MAP_ENTS = {
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(533, 7463, 5510),
			["class"] = "lua_npc",
			["role"] = "dealer",
		},
		{
			["ang"] = Angle(0, -180, 0),
			["pos"] = Vector (5942, -390, 5508),
			["class"] = "lua_npc",
			["role"] = "hardware_dealer"
		},
		{
			["ang"] = Angle(0, -63, 0),
			["pos"] = Vector(-1586, 5550, 5416),
			["class"] = "lua_npc",
			["role"] = "car_dealer",
			["model"] = "models/odessa.mdl",
		},
		{
			["ang"] = Angle(0, -180, 0),
			["pos"] = Vector(645, 7245, 5506),
			["class"] = "mta_skills_computer",
		},
		{
			["ang"] = Angle(0, 0, 0),
			["pos"] = Vector(237, 7539, 5547),
			["class"] = "mta_jukebox",
		},
		{
			["ang"] = Angle(89, -6, 94),
			["pos"] = Vector(966, 7508, 5550),
			["class"] = "mta_riot_shield_table",
		},
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(-6702, 2956, 5449),
			["class"] = "mta_vault",
		},
		{
			["ang"] = Angle(0, -90, 0),
			["pos"] = Vector(-6368, 2949, 5449),
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
	}

	local function spawn_ents()
		if not game.GetMap():match("^rp%_unioncity") then return end

		for _, data in pairs(MAP_ENTS) do
			local ent = ents.Create(data.class)

			function ent:UpdateTransmitState()
				return TRANSMIT_ALWAYS
			end

			ent:SetPos(data.pos)
			ent:SetAngles(data.ang)
			ent.role = data.role
			ent:Spawn()

			-- not allowed to set before npc spawn, after it works though
			if data.model then
				ent:SetModel(data.model)
			end

			if data.role and data.class == "lua_npc" then
				ent:SetNWString("npc_role", data.role)
			end
			--ent:DropToFloor()
		end

		local vault_doors = ents.FindByModel("models/uc/props_unioncity/safe_door.mdl")
		for _, door in ipairs(vault_doors) do
			local pos = door:WorldSpaceCenter() - door:GetRight() * 20 - Vector(0, 0, 35)
			local ang = door:GetAngles()
			ang.y = ang.y - 90

			local vault = ents.Create("mta_vault")
			vault:Spawn()
			vault:SetPos(pos)
			vault:SetAngles(ang)

			function ent:UpdateTransmitState()
				return TRANSMIT_ALWAYS
			end
		end
	end

	function GM:PostCleanupMap()
		spawn_ents()
	end

	-- the gamemode config isnt enough to set these sadly
	local cvars_to_set = {
		sv_gamename_override = "MTA",
		sv_allowcslua = "0",
		sbox_maxnpcs = "1000",
		sbox_godmode = "0",
		sv_loadingurl = "\"http://3kv.in/~earu/mta-loadingscreen/\""
	}
	local function set_cvars()
		for cvar_name, value in pairs(cvars_to_set) do
			game.ConsoleCommand(("%s %s\n"):format(cvar_name, value))
		end
	end

	function GM:Initialize()
		set_cvars()
	end

	function GM:PlayerInitialSpawn(ply, transiton)
		self.BaseClass.PlayerInitialSpawn(self, ply, transiton)
		ply.noleap = true
	end

	local JAIL_SPOTS = {
		Vector(1870, -974, 5416),
		Vector(2124, -985, 5416),
		Vector(2112, -1329, 5416),
		Vector(1999, -1317, 5416),
		Vector(1888, -1331, 5416)
	}
	function GM:PlayerSpawn(ply)
		self.BaseClass.PlayerSpawn(self, ply)
		if ply.MTACaught then
			ply.MTACaught = nil
			ply:SetPos(JAIL_SPOTS[math.random(#JAIL_SPOTS)])
		end
	end

	local HOSTNAMES = {
		"Almost like DarkRP",
		"PayDay 3",
		"Bootleg GTA",
		"Grand Theft Rip-off",
		"It's crime time",
		"Low budget San Andreas",
		"Construct with blackjacks and hookers",
		"Admin, I didn't fail RP",
		"Would like a stove?",
		"RDM RDM RDM"
	}
	local function set_custom_hostname()
		set_cvars()
		if not _G.hostname then return end
		local slogan = HOSTNAMES[math.random(#HOSTNAMES)]
		_G.hostname(("Meta Theft Auto WIP - %s"):format(slogan))
	end

	local function get_rid_of_bank_vault()
		local entities = ents.FindByModel("models/uc/props_unioncity/bankvault_door.mdl")
		for _, ent in pairs(entities) do
			local door = ent:GetParent()
			if ent:CreatedByMap() and IsValid(door) then
				door:Fire("open")
				SafeRemoveEntityDelayed(door, 0.5)
			end
		end
	end

	local MAX_WANDERS = 40
	local SUBWAY_Z = 5000
	function GM:InitPostEntity()
		spawn_ents()

		local nodes = {}
		local node_poses = {}
		timer.Create("mta_wanders", 1, 0, function()
			if not navmesh.IsLoaded() then return end

			if #nodes < 1 then
				nodes = navmesh.GetAllNavAreas()
				node_poses = {}
				for _, node in pairs(nodes) do
					local pos = node:GetCenter()
					if pos.z > SUBWAY_Z then
						table.insert(node_poses, pos)
					end
				end
			end

			ms = ms or {}
			ms.mapdata = ms.mapdata or {}
			ms.mapdata.w_walktable = node_poses

			local wanders = ents.FindByClass("lua_npc_wander")
			if #wanders < MAX_WANDERS then
				local node = nodes[math.random(#nodes)]
				local wander = ents.Create("lua_npc_wander")
				wander:SetPos(node:GetCenter())
				wander:Spawn()

				function wander:OnStuck()
					SafeRemoveEntity(self)
				end

				local old_think = wander.Think
				local next_door_check = 0
				function wander:Think()
					if self:GetPos().z < SUBWAY_Z then
						SafeRemoveEntity(self)
						return
					end

					local phys = self:GetPhysicsObject()
					if IsValid(phys) and phys:IsPenetrating() then
						SafeRemoveEntity(self)
						return
					end

					if CurTime() >= next_door_check then
						for _, ent in ipairs(ents.FindInSphere(wander:GetPos(), 75)) do
							if ent:GetClass():match("door") and not ent.wander_toggle then
								ent:Fire("open")

								ent:SetNotSolid(true)
								ent.wander_toggle = true
								timer.Simple(5, function()
									if IsValid(ent) then
										ent:Fire("close")
										ent:SetNotSolid(false)
										ent.wander_toggle = nil
									end
								end)
							end
						end
						next_door_check = CurTime() + 1
					end

					old_think(self)
				end
			end
		end)

		timer.Create("DynHostname", 10, 0, set_custom_hostname)
		get_rid_of_bank_vault()
	end

	function GM:PlayerCanHearPlayersVoice(listener, speaker)
		return true, true
	end


	function GM:MTAPlayerFailed(ply, max_factor, old_factor, is_death)
		ply.MTACaught = true
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
