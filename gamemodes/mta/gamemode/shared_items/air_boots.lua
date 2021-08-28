local EFFECT_DURATION = 20
local EFFECT_RUN_SPEED = 1000
local EFFECT_WALK_SPEED = 600
local DEFAULT_RUN_SPEED = 400
local DEFAULT_WALK_SPEED = 200
local ITEM = {}

ITEM.Name = "Air Boots"
ITEM.Description = ("A pair of boots, they increase your speed for %d seconds."):format(EFFECT_DURATION)
ITEM.Model = "models/props_junk/shoe001a.mdl"
ITEM.Material = "models/combine_helicopter/helicopter_bomb_off01"
ITEM.StackLimit = 4
ITEM.Usable = true
ITEM.Craft = {
	{ Resource = "combine_core", Amount = 1 },
	{ Resource = "mh_debris", Amount = 4 },
	{ Resource = "metal_part", Amount = 5 },
}

if SERVER then
	local statuses = MTA_TABLE("Statuses")
	function ITEM:OnUse(ply, amount)
		local duration = EFFECT_DURATION * amount
		ply.MTAAirBoots = true
		timer.Simple(duration, function()
			if not IsValid(ply) then return end
			ply.MTAAirBoots = nil

			if ply:GetRunSpeed() > DEFAULT_RUN_SPEED then
				ply:SetRunSpeed(DEFAULT_RUN_SPEED)
			end

			if ply:GetWalkSpeed() > DEFAULT_WALK_SPEED then
				ply:SetWalkSpeed(DEFAULT_WALK_SPEED)
			end
		end)

		ply:SetRunSpeed(EFFECT_RUN_SPEED)
		ply:SetWalkSpeed(EFFECT_WALK_SPEED)
		statuses.AddStatus(ply, "air_boots", "Air Boots", Color(109, 169, 214), CurTime() + duration)
	end

	hook.Add("MTAPlayerConstraintUpdate", "mta_air_boots", function(ply, state)
		if ply.MTAAirBoots then
			ply:SetRunSpeed(EFFECT_RUN_SPEED)
			ply:SetWalkSpeed(EFFECT_WALK_SPEED)
		end
	end)
end

MTA.Inventory.RegisterItem("air_boots", ITEM)