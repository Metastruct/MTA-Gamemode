local tag = "mta_hacked_turret"
local TURRET_DURATION = 8 * 60
local TURRET_IGNITE_DURATION = 20
local TURRET_HEALTH = 500
local TURRET_IGNITE_HEALTH = 40
local ITEM = {}

ITEM.Name = "Hacked Turret"
ITEM.Description = "A hacked turret, will attack any enemy in sight."
ITEM.Model = "models/combine_turrets/floor_turret.mdl"
ITEM.StackLimit = 1
ITEM.Usable = true
ITEM.Craft = {
	{ Resource = "combine_core", Amount = 3 },
	{ Resource = "mh_debris", Amount = 3 },
	{ Resource = "metal_part", Amount = 10 },
	{ Resource = "combine_shell", Amount = 20 },
	{ Resource = "mh_engine", Amount = 1 }
}

if SERVER then
	function ITEM:OnUse(ply, amount)
		for i = 1, amount do
			local tr = util.TraceLine({
				start = ply:EyePos(),
				endpos = ply:EyePos() + ply:GetAimVector() * 200,
				filter = ply
			})

			local pos = tr.HitPos
			local turret = ents.Create("npc_turret_floor")
			turret:SetPos(pos)
			turret:SetAngles(ply:GetAngles())
			turret:Spawn()
			turret:Activate()
			turret:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
			turret:DropToFloor()

			local phys = turret:GetPhysicsObject()
			if IsValid(phys) then
				phys:Wake()
				phys:EnableMotion(false)
			end

			turret:AddRelationship("npc_metropolice D_HT 99")
			turret:AddRelationship("npc_hunter D_HT 99")
			turret:AddRelationship("npc_combine_s D_HT 99")
			turret:AddRelationship("npc_manhack D_HT 99")
			turret:AddRelationship("player D_NU 99")

			turret:AddEntityRelationship(ply, D_LI, 99)

			turret:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_PERFECT)
			turret:SetHealth(TURRET_HEALTH)
			turret:SetOwner(ply)
			if turret.CPPISetOwner then
				turret:CPPISetOwner(ply)
			end

			turret.MTAHackedTurret = true

			timer.Simple(TURRET_DURATION, function()
				if not IsValid(turret) then return end

				turret:Fire("ignite")
				timer.Simple(TURRET_IGNITE_DURATION, function()
					if not IsValid(turret) then return end

					local expl = ents.Create("env_explosion")
					expl:SetPos(turret:WorldSpaceCenter())
					expl:Spawn()
					expl:Fire("explode")

					turret:Remove()
				end)
			end)
		end
	end

	hook.Add("ScaleNPCDamage", tag, function(_, _, dmg_info)
		local atck = dmg_info:GetAttacker()
		if not IsValid(atck) then return end

		if atck.MTAHackedTurret then
			dmg_info:SetAttacker(atck:GetOwner())
			dmg_info:SetInflictor(atck)
			dmg_info:ScaleDamage(3)
		end
	end)

	hook.Add("EntityTakeDamage", tag, function(ent, dmg_info)
		if not ent.MTAHackedTurret then return end

		local atck = dmg_info:GetAttacker()
		if atck == ent:GetOwner() then return end

		ent:SetHealth(math.max(ent:Health() - dmg_info:GetDamage(), 0))
		ent:AddEntityRelationship(atck, D_HT, 99)

		if atck:IsNPC() then
			atck:AddEntityRelationship(ent, D_HT, 99)
		end

		if ent:Health() < TURRET_IGNITE_HEALTH then
			ent:Fire("ignite")
		end

		if ent:Health() <= 0 then
			local expl = ents.Create("env_explosion")
			expl:SetPos(ent:WorldSpaceCenter())
			expl:Spawn()
			expl:Fire("explode")

			ent:Remove()
		end
	end)

	local function remove_player_turrets(ply)
		for _, turret in ipairs(ents.FindByClass("npc_turret_floor")) do
			if turret:GetOwner() == ply then
				turret:Remove()
			end
		end
	end

	hook.Add("MTAPlayerFailed", tag, function(ply)
		if is_wanted then return end
		remove_player_turrets(ply)
	end)
end

MTA.Inventory.RegisterItem("hacked_turret", ITEM)