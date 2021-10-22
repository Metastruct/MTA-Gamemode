
local FULL_EXPIRE = 10

local ITEM = {}

ITEM.Name = "Armored Hotdog"
ITEM.Description = "An armored hotdog. Its armor is so thick it restores yours!"
ITEM.Model = "models/food/hotdog.mdl"
ITEM.Material = "models/gibs/metalgibs/metal_gibs"
ITEM.StackLimit = 32
ITEM.Usable = true
ITEM.Craft = {
	{ Resource = "mh_debris", Amount = 1 },
	{ Resource = "hotdog", Amount = 1 },
}

if SERVER then
	function ITEM:OnUse(ply, am)
		if ply._mtafull then
			ply:ChatPrint("You threw the hotdog away because your stomach is full, what a waste!")

			return
		end

		ply._mtafull = true
		timer.Simple(FULL_EXPIRE, function()
			ply._mtafull = nil
		end)

		MTA.Statuses.AddStatus(ply, "mtafull", "Well Fed", Color(255, 175, 100), CurTime() + FULL_EXPIRE)

		local arm = math.min(ply:Armor() + 10, 200)
		ply:SetArmor(arm)

		local roll = math.random(1, 100)
		if roll == 1 then
			local bps = MTA.Crafting.Blueprints.Get(ply)
			if bps["hotdog_charm"] then return end

			ply:EmitSound("vo/eli_lab/al_goodcatch.wav")
			ply:ChatPrint("There was something inside the hotdog!\n.. a blueprint??")
			MTA.Crafting.GiveBlueprint(ply, "hotdog_charm")
		end
	end
end

MTA.Inventory.RegisterItem("hotdog_armored", ITEM)