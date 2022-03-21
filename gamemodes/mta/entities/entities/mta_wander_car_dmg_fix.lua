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
	resource.AddFile("sound/mta/wilhelmscream.ogg")
	util.PrecacheSound("mta/wilhelmscream.ogg")

	local fix
	local function get_fix()
		if not IsValid(fix) then
			fix = ents.Create("mta_wander_car_dmg_fix")
			fix:SetPos(Vector(0, 0, 0))
			fix:Spawn()
		end

		return fix
	end

	local function apply_dmg(car, ent)
		if ent.rolled_over then return end

		local phys = car:GetPhysicsObject()
		if not IsValid(phys) then return end

		local vel = phys:GetVelocity()
		if vel:Length() < 500 then return end

		local driver = car:GetDriver()
		if driver == ent then return end

		local hurting_obj = get_fix()
		local dmg_info = DamageInfo()
		dmg_info:SetAttacker(hurting_obj)
		dmg_info:SetInflictor(hurting_obj)
		dmg_info:SetDamageType(DMG_VEHICLE)
		dmg_info:SetDamage(150)
		dmg_info:SetDamageForce(vel * 100)

		if math.random(0, 100) < 10 then
			ent:EmitSound("mta/wilhelmscream.ogg", 100)
			dmg_info:SetDamageForce(vel * 100 + Vector(0, 0, 50000))
		end

		ent:TakeDamageInfo(dmg_info)
		ent.rolled_over = true
		timer.Simple(1, function()
			if not IsValid(ent) then return end
			ent.rolled_over = nil
		end)

		if MTA.ShouldIncreasePlayerFactor(driver) then
			local factor_amount = 1
			if MTA.HasCoeficients(ent) then
				factor_amount = MTA.Coeficients[ent:GetClass()].kill_coef
			end

			MTA.IncreasePlayerFactor(driver, factor_amount)
		end
	end

	local function is_damageable_ent(ent)
		if ent:GetClass() == "lua_npc_wander" then return true end
		if ent:IsNPC() and ent:GetNWBool("MTANPC") then return true end
		if ent:IsPlayer() then return true end

		return false
	end

	hook.Add("ShouldCollide", "fuck", function(ent1, ent2)
		if ent1:IsVehicle() and is_damageable_ent(ent2) then
			apply_dmg(ent1, ent2)
			return true
		end
		if ent2:IsVehicle() and is_damageable_ent(ent1) then
			apply_dmg(ent2, ent1)
			return true
		end
	end)

	hook.Add("EntityTakeDamage", "fuck", function(ent, dmg_info)
		local inflictor = dmg_info:GetInflictor()
		if not IsValid(inflictor) then return end
		if not inflictor:IsVehicle() then return end
		apply_dmg(inflictor, ent)
		return true
	end)
end