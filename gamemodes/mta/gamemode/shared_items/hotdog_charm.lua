
local ITEM = {}
local DROP_CHANCE = 30

ITEM.Name = "Hotdog Charm"
ITEM.Description = "May the hotdog be with you!\nCitizens have a low chance of dropping hotdogs!"
ITEM.Model = "models/maxofs2d/balloon_mossman.mdl"
ITEM.StackLimit = 1
ITEM.Usable = false
ITEM.Craft = {
	{ Resource = "biomass", Amount = 5 },
	{ Resource = "hotdog", Amount = 10 },
}

local Tag = "hotdog_charm"

if SERVER then
	hook.Add("OnNPCKilled", Tag, function(npc, attacker, inflictor)
		if not MTA.Inventory.HasItem(attacker, "hotdog_charm") then return end

		local class = npc:GetClass()
		if class == "lua_npc_wander" then
			local roll = math.random(0, 100)
			if roll < DROP_CHANCE then
				MTA.Inventory.CreateItemEntity("hotdog", npc:WorldSpaceCenter())
			end
		end
	end)
end

MTA.Inventory.RegisterItem("hotdog_charm", ITEM)