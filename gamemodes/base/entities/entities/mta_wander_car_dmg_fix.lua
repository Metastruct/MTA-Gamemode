AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Author = "Earu"
ENT.PrintName = "Vehicle"
ENT.Spawnable = false

if CLIENT then
	language.Add("mta_wander_car_dmg_fix", "Vehicle")
end

if SERVER then
	local fix
	local function get_fix()
		if not IsValid(fix) then
			fix = ents.Create("mta_wander_car_dmg_fix")
			fix:SetPos(Vector(0, 0, 0))
			fix:Spawn()
		end

		return fix
	end

	local function apply_dmg(car, npc)
		if npc.rolled_over then return end

		local phys = car:GetPhysicsObject()
		if not IsValid(phys) then return end

		local vel = phys:GetVelocity()
		if vel:Length() < 50 then return end

		local hurting_obj = get_fix()
		npc:TakeDamage(150, hurting_obj, hurting_obj)

		npc.rolled_over = true
	end

	hook.Add("ShouldCollide", "fuck", function(ent1, ent2)
		if ent1:IsVehicle() and ent2:GetClass() == "lua_npc_wander" then
			apply_dmg(ent1, ent2)
			return true
		end
		if ent2:IsVehicle() and ent1:GetClass() == "lua_npc_wander" then
			apply_dmg(ent2, ent1)
			return true
		end
	end)
end