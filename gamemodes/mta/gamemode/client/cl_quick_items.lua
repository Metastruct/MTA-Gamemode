local tag = "mta_quick_item_use"
local inventory = MTA_TABLE("Inventory")

local PATH = "mta_quick_items.json"
local TILE_SIZE = 64
local X_OFFSET = 475
local Y_POS = 500
local TILE_COUNT = 6

local inv
local function create_menu()
	inv = vgui.Create("DInventory")
	inv:SetTileSize(TILE_SIZE)
	inv:SetGridSize(1, TILE_COUNT)
	inv:SetPos(ScrW() / 2 + X_OFFSET, Y_POS)
	inv:SetDrawOnTop(true)
	inv.QuickItems = true

	function inv:SaveQuickItems()
		local items = {}
		for y = 1, TILE_COUNT do
			local t = self.TileSpots[0][(y - 1) * self.TileSize]
			if not IsValid(t) then continue end

			table.insert(items, { index = y, item_class = t:GetItemClass() })
		end

		file.Write(PATH, util.TableToJSON(items))
	end

	function inv:AddQuickItem(item_class, y)
		local t = self:AddTileInSlot(1, y)
		if not t then return false end

		t:SetItemClass(item_class)
		t:SetItemCount(inventory.GetTotalItemCount(LocalPlayer(), item_class))
		t:SetItemMaxCount(9999)

		local data = inventory.Items[item_class] or {
			Name = "Nothing",
			Description = "There was once something, it is now nothing...",
			Model = "models/Gibs/HGIBS.mdl",
		}

		t:SetItemName(data.Name)
		t:SetModelIcon(data.Model, data.Material)
		t:SetItemDescription(data.Description)

		self:SaveQuickItems()
		return true
	end

	function inv:OnReceiveItem(item_class, x, y)
		local base_x, _ = self:GetPos()
		if x < base_x or x > base_x + self:GetWide() then return end
		if y < Y_POS or y > Y_POS + self:GetTall() then return end

		local diff = y - Y_POS
		for i = 1, TILE_COUNT do
			if diff > (i - 1) * self.TileSize and diff < i * self.TileSize then
				self:AddQuickItem(item_class, i)
				return
			end
		end
	end

	local function remove_quick_item(self, tile)
		self:RemoveTile(tile)
		tile:Remove()
	end

	inv.OnTileDroppedInWorld = remove_quick_item
	inv.OnTileChangedPanel = remove_quick_item

	if file.Exists(PATH, "DATA") then
		local items = util.JSONToTable(file.Read(PATH, "DATA"))
		for _, item in pairs(items) do
			inv:AddQuickItem(item.item_class, item.index)
		end
	end
end

local function update_counts()
	for y = 1, TILE_COUNT do
		local t = inv.TileSpots[0][(y - 1) * inv.TileSize]
		if not IsValid(t) then continue end

		local item_class = t:GetItemClass()
		t:SetItemCount(inventory.GetTotalItemCount(LocalPlayer(), item_class))
	end
end

local function check_hover_use()
	for y = 1, TILE_COUNT do
		local t = inv.TileSpots[0][(y - 1) * inv.TileSize]
		if not IsValid(t) then continue end

		if t:IsHovered() then
			local item_class = t:GetItemClass()
			local succ, x, y = inventory.FindItemSlot(LocalPlayer(), item_class)
			if not succ then return end

			inventory.UseItem(item_class, x, y, 1)
			return
		end
	end
end

hook.Add("OnSpawnMenuOpen", tag, function()
	if not IsValid(inv) then
		create_menu()
	end

	update_counts()
	inv:Show()
end)

hook.Add("OnSpawnMenuClose", tag, function()
	if not IsValid(inv) then
		create_menu()
	end

	check_hover_use()
	inv:Hide()
end)