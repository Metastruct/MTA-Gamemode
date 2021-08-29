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

local function init()
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

hook.Add("InitPostEntity", tag, init)