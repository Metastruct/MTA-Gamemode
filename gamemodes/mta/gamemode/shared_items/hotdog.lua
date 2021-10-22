
local FULL_EXPIRE = 10

local ITEM = {}

ITEM.Name = "Hotdog"
ITEM.Description = "A hotdog! Restores 10 health."
ITEM.Model = "models/food/hotdog.mdl"
ITEM.StackLimit = 32
ITEM.Usable = true

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

		local hp = math.min(ply:Health() + 10, 100)
		ply:SetHealth(hp)
	end
end

MTA.Inventory.RegisterItem("hotdog", ITEM)