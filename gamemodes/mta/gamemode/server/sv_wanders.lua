local tag = "mta_wanders"

local MAX_WANDERS = 40
local SUBWAY_Z = 5000
local stuck_poses = {
	Vector (-2228, 3881, 5416)
}

local function explode(wander)
	local skull = ents.Create("prop_physics")
	skull:SetPos(wander:WorldSpaceCenter())
	skull:SetModel("models/Gibs/HGIBS.mdl")
	skull:Spawn()
	skull:EmitSound("garrysmod/balloon_pop_cute.wav", 100)

	SafeRemoveEntity(wander)
	SafeRemoveEntityDelayed(skull, 5)
end

local function init_wanders()
	local nodes = {}
	local node_poses = {}
	timer.Create(tag, 1, 0, function()
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
				explode(self)
			end

			local old_think = wander.Think
			local next_door_check = 0
			function wander:Think()
				if self:GetPos().z < SUBWAY_Z then
					explode(self)
					return
				end

				local phys = self:GetPhysicsObject()
				if IsValid(phys) and phys:IsPenetrating() then
					explode(self)
					return
				end

				if CurTime() >= next_door_check then
					local pos = self:GetPos()
					for _, stuck_pos in ipairs(stuck_poses) do
						if pos:Distance(stuck_pos) < 100 then
							explode(self)
							return
						end
					end

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
end

--[[
	METROPOLICE WANDERS
]]--

local tracks = {
	-- around the map
	{
		[ 1] = Vector (-5294.42578125    , - 695.78918457031 ,  5416.03125       ),
		[ 2] = Vector (-5285.5615234375  , -3684.6794433594  ,  5416.03125       ),
		[ 3] = Vector (-3209.3063964844  , -3636.5949707031  ,  5416.03125       ),
		[ 4] = Vector (-2873.09765625    , -3479.3129882812  ,  5416.03125       ),
		[ 5] = Vector (  272.73065185547 , -3533.2043457031  ,  5416.0317382812  ),
		[ 6] = Vector ( 3350.1594238281  , -3528.7976074219  ,  5416.0317382812  ),
		[ 7] = Vector ( 5415.5766601562  , -3425.4548339844  ,  5504.03125       ),
		[ 8] = Vector ( 5416.74609375    , -1311.0197753906  ,  5504.03125       ),
		[ 9] = Vector ( 5474.6401367188  , -1140.474609375   ,  5504.03125       ),
		[10] = Vector ( 5459.5727539062  , -  75.853736877441,  5504.03125       ),
		[11] = Vector ( 4672.8256835938  ,    62.684017181396,  5499.0317382812  ),
		[12] = Vector ( 1628.0352783203  ,    84.54419708252 ,  5416.03125       ),
		[13] = Vector ( 1771.3532714844  ,  1614.9538574219  ,  5416.03125       ),
		[14] = Vector ( 1756.3143310547  ,  4232.078125      ,  5440.03125       ),
		[15] = Vector ( 2245.7263183594  ,  4198.9204101562  ,  5440.03125       ),
		[16] = Vector ( 3689.6721191406  ,  4190.3017578125  ,  5440.03125       ),
		[17] = Vector ( 3694.6333007812  ,  4877.7202148438  ,  5435.03125       ),
		[18] = Vector ( 3708.943359375   ,  6905.0786132812  ,  5496.03125       ),
		[19] = Vector ( 3733.9802246094  ,  8807.4287109375  ,  5600.03125       ),
		[20] = Vector ( 3453.2900390625  ,  9405.28125       ,  5592.03125       ),
		[21] = Vector ( 2367.7810058594  ,  9564.7265625     ,  5600.03125       ),
		[22] = Vector (- 508.5837097168  ,  9565.71484375    ,  5600.03125       ),
		[23] = Vector (- 536.25787353516 ,  8239.4599609375  ,  5558.3334960938  ),
		[24] = Vector (- 613.84240722656 ,  7865.5708007812  ,  5520.7041015625  ),
		[25] = Vector (- 594.64282226562 ,  6736.126953125   ,  5491.0395507812  ),
		[26] = Vector (-1491.1737060547  ,  6715.34375       ,  5496.03125       ),
		[27] = Vector (-2355.685546875   ,  6761.1284179688  ,  5496.03125       ),
		[28] = Vector (-4562.22265625    ,  6735.1069335938  ,  5496.03125       ),
		[29] = Vector (-4645.5668945312  ,  5230.44140625    ,  5435.7768554688  ),
		[30] = Vector (-4652.6118164062  ,  2533.2822265625  ,  5408.03125       ),
		[31] = Vector (-4612.5375976562  ,  1283.1967773438  ,  5416.03125       ),
		[32] = Vector (-4390.82421875    ,   506.91415405273 ,  5416.03125       ),
		[33] = Vector (-4295.2690429688  ,    83.339599609375,  5414.9995117188  ),
		[34] = Vector (-5302.6142578125  ,    23.63081741333 ,  5416.03125       ),
		[35] = Vector (-5317.52734375    , - 832.62109375    ,  5416.03125       )
	},

	-- around park
	{
		[ 1] = Vector (-3671.2749023438  ,    45.317756652832,  5411.0322265625  ),
		[ 2] = Vector (-2944.9914550781  ,   213.33261108398 ,  5416.03125       ),
		[ 3] = Vector (-1687.6351318359  ,   201.90701293945 ,  5416.03125       ),
		[ 4] = Vector (-1324.4327392578  ,   230.20837402344 ,  5416.03125       ),
		[ 5] = Vector (-1215.7194824219  ,   485.91018676758 ,  5413.2177734375  ),
		[ 6] = Vector (  759.49731445312 ,   505.14144897461 ,  5416.03125       ),
		[ 7] = Vector (  796.18542480469 ,  4144.6938476562  ,  5440.03125       ),
		[ 8] = Vector (-2500.3598632812  ,  4219.46484375    ,  5416.03125       ),
		[ 9] = Vector (-3951.6362304688  ,  4178.64453125    ,  5413.9692382812  ),
		[10] = Vector (-3991.8803710938  ,  3925.0615234375  ,  5416.03125       ),
		[11] = Vector (-3966.4855957031  ,  3448.2583007812  ,  5416.03125       ),
		[12] = Vector (-3999.818359375   ,  2518.4860839844  ,  5416.03125       ),
		[13] = Vector (-3964.7990722656  ,  2034.8547363281  ,  5416.03125       ),
		[14] = Vector (-3967.2783203125  ,   910.53485107422 ,  5416.03125       ),
		[15] = Vector (-3751.1086425781  ,   388.59942626953 ,  5416.03125       ),
		[16] = Vector (-3657.955078125   ,    45.920764923096,  5411.0327148438  ),
		[17] = Vector (-3094.7998046875  ,    64.104713439941,  5416.03125       )
	}
}

local function spawn_metro_wander()
	local npc = ents.Create("npc_metropolice")
	npc:Give(math.random() > 0.5 and "weapon_stunstick" or "weapon_pistol")
	npc:AddRelationship("player D_NU 99")
	npc:SetMaterial("models/mta/police_skins/metrocop_sheet_police")
	npc:Spawn()
	npc:SetCollisionBounds(Vector(-20, -20, 0), Vector(20, 20, 72))

	local track = tracks[math.random(#tracks)]
	local cur_index = math.random(#track)
	local init_pos = track[cur_index]
	local mult = math.random() > 0.5 and -1 or 1

	npc:SetPos(init_pos)

	local target_pos = nil
	local function move_to_next_node(no_increment)
		if not no_increment then
			cur_index = cur_index + (1 * mult)
			if cur_index >= #track then
				cur_index = 0
			end

			if cur_index < 1 then
				cur_index = #track
			end
		end

		local pos = track[cur_index]
		if not pos then return end -- somehow???

		npc:SetLastPosition(pos)
		npc:SetSchedule(SCHED_FORCED_GO)

		target_pos = pos
	end

	local next_wanted_check = 0
	hook.Add("Think", npc, function(self)
		if self:GetNWBool("MTACombine") then
			hook.Remove("Think", npc)
			return
		end

		if not target_pos or target_pos:Distance(self:GetPos()) < 100 then
			move_to_next_node()
		end

		if next_wanted_check < CurTime() then
			for _, ent in ipairs(ents.FindInSphere(self:GetPos(), 1000)) do
				if ent:IsPlayer() and MTA.IsWanted(ent) then
					MTA.EnrollNPC(self, ent)
				end
			end

			next_wanted_check = CurTime() + 1
		end
	end)

	local move_sounds = {
		"npc/metropolice/vo/moveit.wav",
		"npc/metropolice/vo/moveit2.wav",
		"npc/metropolice/vo/movealong.wav",
		"npc/metropolice/vo/movealong3.wav",
		"npc/metropolice/vo/move.wav",
	}

	local idle_count = 0
	local last_pos
	local timer_name = "MTAMetropoliceWander_" .. npc:EntIndex()
	timer.Create(timer_name, 1, 0, function()
		if not IsValid(npc) or npc:GetNWBool("MTACombine") then
			timer.Remove(timer_name)
			return
		end

		if last_pos == npc:GetPos() then
			idle_count = idle_count + 1
			if idle_count > 3 then
				local tr = util.TraceHull({
					start = npc:GetPos(),
					endpos = npc:GetPos() + npc:GetForward() * 100,
					maxs = npc:OBBMaxs(),
					mins = npc:OBBMins(),
					filter = npc,
				})

				if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
					npc:EmitSound(move_sounds[math.random(#move_sounds)])
				end

				move_to_next_node(true)
				idle_count = 0
			end
		else
			last_pos = npc:GetPos()
			idle_count = 0
		end
	end)

	hook.Add("EntityTakeDamage", npc, function(self, ent, dmg_info)
		if self ~= ent then return end
		local atck = dmg_info:GetAttacker()
		if IsValid(atck) and atck:IsPlayer() then
			MTA.IncreasePlayerFactor(atck, 5)
			MTA.EnrollNPC(self, atck)

			hook.Remove("EntityTakeDamage", self)
			hook.Remove("PlayerUse", self)
		end
	end)

	local sounds = {
		"npc/metropolice/vo/chuckle.wav",
		"npc/metropolice/vo/citizen.wav",
	}
	local next_sound = 0
	hook.Add("PlayerUse", npc, function(self, _, ent)
		if self == ent and next_sound < CurTime() then
			self:EmitSound(sounds[math.random(#sounds)])
			next_sound = CurTime() + 5
		end
	end)

	return npc
end

local MAX_METROPOLICE = 10
local spawned_metropolice = {}
local function init_metropolices()
	timer.Create(tag, 3, 0, function()
		if not navmesh.IsLoaded() then return end

		-- check if npc is still around
		for i, npc in ipairs(spawned_metropolice) do
			if not IsValid(npc) then
				table.remove(spawned_metropolice, i)
			end
		end

		if #spawned_metropolice >= MAX_METROPOLICE then return end

		local npc = spawn_metro_wander()
		table.insert(spawned_metropolice, npc)
	end)
end

hook.Add("InitPostEntity", tag, function()
	init_wanders()
	init_metropolices()
end)