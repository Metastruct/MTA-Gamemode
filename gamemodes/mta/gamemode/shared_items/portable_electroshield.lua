local EFFECT_DURATION = 20
local ITEM = {}

ITEM.Name = "Portable Electro-Shield"
ITEM.Description = ("A portable electro-shield. Halves the damages received for %d seconds."):format(EFFECT_DURATION)
ITEM.Model = "models/roller_spikes.mdl"
ITEM.StackLimit = 4
ITEM.Craft = {
	{ Resource = "metal_part", Amount = 10 },
	{ Resource = "combine_core", Amount = 2 },
	{ Resource = "biomass", Amount = 8 },
}

if SERVER then
	local statuses = MTA_TABLE("Statuses")
	function ITEM:OnUse(ply, amount)
		local expire_time = CurTime() + EFFECT_DURATION * amount
		ply.MTAPortableShield = expire_time
		statuses.AddStatus(ply, "electro_shield", "Electro-Shield", Color(36, 179, 226), expire_time)
	end

	hook.Add("ScalePlayerDamage", "mta_portable_electroshield", function(ply, _, dmg_info)
		if ply.MTAPortableShield and ply.MTAPortableShield > CurTime() then
			dmg_info:ScaleDamage(0.5)
		end
	end)
end

MTA.Inventory.RegisterItem("portable_electroshield", ITEM)