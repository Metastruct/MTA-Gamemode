-- DB SCHEME
--[[
CREATE TABLE mta_user_blueprints (
	id INTEGER NOT NULL PRIMARY KEY,
	classes TEXT NOT NULL DEFAULT ''
)
]]--

local tag = "mta_crafting"
local craft = MTA_TABLE("Crafting")
local inventory = MTA_TABLE("Inventory")

local MAX_INVENTORY_WIDTH = 9
local MAX_INVENTORY_HEIGHT = 4
local MTA_CRAFT_REQUEST = "MTA_CRAFTING_REQ"
local NET_BLUEPRINTS_TRANSMIT = "MTA_BLUEPRINTS_TRANSMIT"

local function can_db()
	return _G.db and _G.co
end

local function clear_empty_blueprints(tbl)
	for i, blueprint in pairs(tbl) do
		if blueprint:Trim() == "" then
			table.remove(tbl, i)
		end
	end
end

function craft.CanCraft(ply, item_class, amount)
	if SERVER and not can_db() then return false end
	if not IsValid(ply) then return false end

	local item = inventory.Items[item_class]
	if not item or not istable(item.Craft) then return false end

	if SERVER and not craft.Blueprints.Instances[ply][item_class] then return false end
	if CLIENT and not craft.Blueprints[item_class] then return false end

	amount = amount or 1
	if amount < 1 then return false end

	for _, craft_data in ipairs(item.Craft) do
		if not inventory.HasItem(ply, craft_data.Resource, craft_data.Amount * amount) then return false end
	end

	return true
end

if SERVER then
	util.AddNetworkString(NET_BLUEPRINTS_TRANSMIT)
	util.AddNetworkString(MTA_CRAFT_REQUEST)

	craft.Blueprints = {}
	craft.Blueprints.Instances = {}

	function craft.Blueprints.Save(ply, blueprints)
		clear_empty_blueprints(blueprints)

		local str_blueprints = table.concat(blueprints, ";")
		net.Start(NET_BLUEPRINTS_TRANSMIT)
		net.WriteString(str_blueprints)
		net.Send(ply)

		MTA.Blueprints.Instances[ply] = {}
		for _, blueprint in pairs(ret.blueprints:Split(";")) do
			MTA.Blueprints.Instances[blueprint] = true
		end

		if not can_db() then return end
		co(function()
			db.Query(("UPDATE mta_user_blueprints SET blueprints = '%s' WHERE id = %d;"):format(str_blueprints, ply:AccountID()))
		end)
	end

	function craft.Blueprints.Init(ply)
		if not can_db() then return {} end

		co(function()
			local ret = db.Query(("SELECT * FROM mta_user_blueprints WHERE id = %d;"):format(ply:AccountID()))[1]
			if ret and ret.blueprints then
				MTA.Blueprints.Instances[ply] = {}
				for _, blueprint in pairs(ret.blueprints:Split(";")) do
					MTA.Blueprints.Instances[blueprint] = true
				end

				net.Start(NET_BLUEPRINTS_TRANSMIT)
				net.WriteString(ret.blueprints)
				net.Send(ply)
			else
				db.Query(("INSERT INTO mta_user_blueprints(id, blueprints) VALUES(%d, '');"):format(ply:AccountID()))
			end
		end)
	end

	function craft.Blueprints.Get(ply)
		return craft.Blueprints.Instances[ply] or {}
	end

	hook.Add("MTAPlayerStatsInitialized", tag, craft.Blueprints.Init)
	hook.Add("PlayerDisconnected", tag, function(ply) craft.Blueprints.Instances[ply] = nil end)

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

	function craft.GiveBlueprint(ply, blueprint)
		if blueprint:Trim() == "" then return end

		local cur_blueprints = craft.Blueprints.Get(ply)
		cur_blueprints[blueprint] = true
		craft.Blueprints.Save(ply, table.GetKeys(cur_blueprints))
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
	craft.Blueprints = craft.Blueprints or {}

	net.Receive(NET_BLUEPRINTS_TRANSMIT, function()
		local blueprints = net.ReadString():Split(";")
		clear_empty_blueprints(blueprints)

		craft.Blueprints = {}
		for _, blueprint in pairs(blueprints) do
			craft.Blueprints[blueprint] = true
		end
	end)

	function craft.CraftItem(item_class, amount)
		net.Start(MTA_CRAFT_REQUEST)
		net.WriteString(item_class)
		net.WriteInt(amount, 32)
		net.SendToServer()
	end
end