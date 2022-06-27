local tag = "MTA_Gas_Explosions"

local gasPumpModels = {
	["models/uc/props_gasstation/gas_pump_old.mdl"] = true,
	["models/uc/props_gasstation/gas_pump_old_single.mdl"] = true
}

local function CreateExplosion(owner, inflictor, pos, dmg, radius, force, ignore)
	local ent = ents.Create("env_explosion")
	ent:SetPos(pos)
	ent:Spawn()
	ent:Activate()

	ent:SetKeyValue("iRadiusOverride", radius)
	ent:SetKeyValue("iMagnitude", dmg)
	ent:SetKeyValue("DamageForce", force)

	ent:SetSaveValue("ignoredEntity", ignore)
	ent:SetSaveValue("m_hOwnerEntity", owner)
	ent:SetSaveValue("m_hInflictor", inflictor)

	ent:Fire("Explode")
end

local gasPump = MTA.GasPump or NULL
hook.Add("EntityTakeDamage", tag, function(ent, dmg)
	if not gasPump:IsValid() then
		local gas = ents.Create("prop_dynamic")
		gas:SetKeyValue("classname", "Gas Pump")
		gas:SetModel("models/Gibs/HGIBS.mdl")
		gas:Spawn()

		MTA.GasPump = gas
		gasPump = gas
	end

	local attacker = dmg:GetAttacker()

	if attacker == ent then -- little bit hacky to override the anti suicide behaviour of mta
		if dmg:GetInflictor() == gasPump then
			dmg:SetAttacker(gasPump)
		end
		return
	end

	if not ent.doorexploding and gasPumpModels[ent:GetModel()] and ent:CreatedByMap() then
		if not ent.gasPump then
			ent:SetHealth(100)
			ent.gasPump = true
		end

		local hp
		if dmg:IsExplosionDamage() then
			hp = -1
		else
			hp = ent:Health() - dmg:GetDamage()
		end

		if hp > 0 then
			ent:SetHealth(hp)
		else -- GO BOOM!
			local force = VectorRand() * 10000
			ent:PropDoorRotatingExplode(force, 15, true, true)
			CreateExplosion(attacker, gasPump, ent:GetPos(), 200, 512, 200, ent)
			ent:SetHealth(100)
		end
	end
end)