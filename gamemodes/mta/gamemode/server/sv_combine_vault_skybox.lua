local tag = "MTACombineVault"

--[[local vol_light, light
local function spawn_light()
	vol_light = ents.Create("prop_physics")
	vol_light:SetModel("models/effects/vol_light128x512.mdl")
	vol_light:SetModelScale(2.5)
	vol_light:SetColor(Color(255, 0, 0))
	vol_light:DrawShadow(false)
	vol_light:Spawn()

	light = ents.Create("gmod_lamp")
	light:SetAngles(Angle(90, 0, 0))
	light:SetFlashlightTexture("effects/flashlight/hard")
	light:SetLightFOV(50)
	light:SetColor(Color(255, 0, 0))
	light:SetDistance(999999999)
	light:SetBrightness(999999999)
	light:SetOn(true)
	light:DrawShadow(false)
end

local cached
local next_cache = 0
local function get_most_wanted()
	if next_cache < CurTime() or (IsValid(cached) and not MTA.IsWanted(cached)) then
		local max_factor = 0
		local max_ply
		for ply, factor in pairs(MTA.Factors) do
			if factor > max_factor then
				max_factor = factor
				max_ply = ply
			end
		end

		cached = max_ply
		next_cache = CurTime() + 1
	end

	return cached
end

hook.Add("Think", tag, function()
	if not IsValid(vol_light) or not IsValid(light) then
		spawn_light()
		return
	end

	local ply = get_most_wanted()
	local valid = IsValid(ply)
	vol_light:SetNoDraw(not valid)
	light:SetOn(valid)

	if not valid  then return end

	local tr = util.TraceLine({
		start = ply:GetPos(),
		endpos = ply:GetPos() + Vector(0, 0, 400),
		filter = ply,
	})

	if tr.Hit then return end

	local pos = ply:GetPos()
	local offset = 1000
	local light_pos = pos + Vector(0, 0, math.sin(CurTime()) * 10 + offset)

	vol_light:SetPos(light_pos)
	light:SetLocalPos(light_pos - Vector(0, 0, 400))
end)]]--

local function skyboxize(ent)
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableCollisions(false)
		phys:EnableMotion(false)
	end
end

local COMBINE_VAULT_POS = Vector (1380, 3994, -277)
local COMBINE_VAULT_LIGHT_POS = Vector (1380, 4044, -277)
local COMBINE_VAULT_LIGHT_REV_POS = Vector (1380, 4044, -800)
local function populate_skybox()
	local combine_vault = ents.Create("prop_physics")
	combine_vault:SetModel("models/plcombine/combine_vault.mdl")
	combine_vault:SetPos(COMBINE_VAULT_POS)
	combine_vault:Spawn()
	skyboxize(combine_vault)

	local vol_light = ents.Create("prop_physics")
	vol_light:SetModel("models/effects/vol_light128x512.mdl")
	vol_light:SetPos(COMBINE_VAULT_LIGHT_POS)
	vol_light:SetColor(Color(255, 0, 0))
	vol_light:Spawn()
	vol_light:SetParent(combine_vault)
	skyboxize(vol_light)

	local light_source = ents.Create("gmod_lamp")
	light_source:SetPos(COMBINE_VAULT_LIGHT_POS)
	light_source:Spawn()
	light_source:SetParent(combine_vault)

	light_source:SetFlashlightTexture("effects/flashlight001")
	light_source:SetOn(true)
	light_source:SetColor(Color(255, 0, 0))
	light_source:SetDistance(200)
	light_source:SetBrightness(99999)
	light_source:SetLightFOV(9999)
	skyboxize(light_source)

	local light_source_rev = ents.Create("gmod_lamp")
	light_source_rev:SetPos(COMBINE_VAULT_LIGHT_REV_POS)
	light_source_rev:Spawn()
	light_source_rev:SetParent(combine_vault)

	light_source_rev:SetAngles(Angle(-90,0,0))
	light_source_rev:SetFlashlightTexture("effects/flashlight001")
	light_source_rev:SetOn(true)
	light_source_rev:SetColor(Color(255, 255, 255))
	light_source_rev:SetDistance(99999)
	light_source_rev:SetBrightness(200)
	light_source_rev:SetLightFOV(9999)
	skyboxize(light_source)

	hook.Add("Think", combine_vault, function()
		if not IsValid(combine_vault) then return end
		combine_vault:SetPos(combine_vault:GetPos() + Vector(0, 0, math.sin(CurTime()) * 0.1))
	end)
end

hook.Add("PostCleanupMap", tag, populate_skybox)
hook.Add("InitPostEntity", tag, populate_skybox)