--[[
local inv_queue = {
	pos = {},
}

for queue, data in inv_queue do
	if not table.IsEmpty(data) then
		inventory.MoveItem(item_class, old_pos_x, old_pos_y, new_pos_x, new_pos_y, amount)
	end
end

local function AddItem(pnl, item_class, count)
	local tile = pnl:AddTile()
	--tile:SetItemMaxCount(inventory.GetStackLimit(item_class))
	--tile:SetItemClass(item_class)
	--tike:SetItemCount(count)
end
]]

local FRAME
local INV
local TILE_SIZE = 64
local WIDTH, HEIGHT = ScrW(), ScrH()
FRAME = vgui.Create("DFrame")
FRAME:SetSize(WIDTH, HEIGHT)
FRAME:MakePopup()
FRAME:Center()
FRAME:SetTitle("Vininator :0")

INV = FRAME:Add("DInventory")
INV:SetTileSize(TILE_SIZE)
INV:SetGridSize(9, 4)
INV:SetPos(WIDTH / 2 - 9 * TILE_SIZE / 2, HEIGHT / 2)

--[[
function INV:OnTileMoved(tile, oldX, oldY, newX, newY, oldPanel)
	local item = tile:GetItemClass()
	local amount = tile:GetItemCount()
	inv_queue.pos[tile] = {oldX, oldY}
end
]]

function INV:OnTileDroppedOutsideGrid(tile)
	print("tile dropped out of inventory")
end

function INV:OnTileClicked(tile)
	print(tile)
end

for i = 1, 5 do
	local t = INV:AddTile()
	if not t then print("A")  return end
	local c = ColorRand()
	c.a = 80
	t.clr = c
	t:SetItemCount(20)
end

--no support
--[[
local HOT
HOT = FRAME:Add("DInventory")
HOT:SetTileSize(TILE_SIZE)
HOT:SetGridSize(5, 1)
HOT:SetPos(WIDTH / 2 - 5 * TILE_SIZE / 2, HEIGHT - TILE_SIZE)

function HOT:TileDroppedInWorld(tile)
	print(tile, "Dropped in world")
end

for i = 1,5 do
	local t = HOT:AddTile()
	t:SetText("b" .. i)
end

local PAN = FRAME:Add("DPanel")
PAN:Dock(LEFT)

]]
