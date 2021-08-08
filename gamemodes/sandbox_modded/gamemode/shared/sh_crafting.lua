local craft = MTA_TABLE("Crafting")
local inventory = MTA_TABLE("Inventory")

local MAX_INVENTORY_WIDTH = 9
local MAX_INVENTORY_HEIGHT = 4
local MTA_CRAFT_REQUEST = "MTA_CRAFTING_REQ"

function craft.CanCraft(ply, item_class, amount)
	if not IsValid(ply) then return false end

	local item = inventory.Items[item_class]
	if not item or not istable(item.Craft) then return false end

	amount = amount or 1
	if amount < 1 then return false end

	for _, craft_data in ipairs(item.Craft) do
		if not inventory.HasItem(ply, craft_data.Resource, craft_data.Amount * amount) then return false end
	end

	return true
end

if SERVER then
	util.AddNetworkString(MTA_CRAFT_REQUEST)

	local function gather_material(ply, item_class, amount)
		local gathered = 0
		for y = 1, MAX_INVENTORY_HEIGHT do
			for x = 1, MAX_INVENTORY_WIDTH do
				local slot = inventory.GetInventorySlot(ply, x, y)
				if slot and slot.Class == item_class then
					local to_take = amount > slot.Amount and slot.Amount or amount
					if not inventory.RemoveItem(ply, item_class, x, y, to_take) then
						return false
					end

					gathered = gathered + to_take
					if gathered >= amount then return true end
				end
			end
		end

		return false
	end

	function craft.CraftItem(ply, item_class, amount)
		local item = inventory.Items[item_class]
		for _, craft_data in ipairs(item.Craft) do
			if not gather_material(ply, craft_data.Resource, craft_data.Amount * amount) then
				return false
			end
		end

		return inventory.AddItem(ply, item_class, amount)
	end

	net.Receive(MTA_CRAFT_REQUEST, function(_, ply)
		local item_class = net.ReadString()
		local amount = net.ReadInt(32)
		if not craft.CanCraft(ply, item_class, amount) then return end

		craft.CraftItem(ply, item_class, amount)
	end)
end

if CLIENT then
	function craft.CraftItem(item_class, amount)
		net.Start(MTA_CRAFT_REQUEST)
		net.WriteString(item_class)
		net.WriteInt(amount, 32)
		net.SendToServer()
	end
end