local TAG = "inventory_drag"
local PANEL = {}

--Bugs:
--Tile spots don't get occupied properly when swapping tile positions
--needs more testing

--Todo:
--Alot
--Character view

function PANEL:Init()
	self.TileSpots = setmetatable({}, {
		__index = function(tab, key)
			local t = {}
			tab[key] = t

			return t
		end,
	})

	self.Tiles = {}
	--self.TileSpots = {}
	self.TileSize = 64
	self.m_Inventory = true
	self.GridSize = Vector(5, 5)
	self:SetSize(64 * 5, 64 * 5) -- Grid size
end

function PANEL:SetTileSize(size)
	self.TileSize = size
end

function PANEL:SetGridSize(x, y)
	self.GridSize = Vector(x, y)
	self:SetSize(x * self.TileSize, y * self.TileSize)
end

function PANEL:CheckIsInGridRange(gridX, gridY)
	if gridX < 0 or gridY < 0 then return false end
	if gridX > (self.GridSize.x - 1) * self.TileSize then return false end
	if gridY > (self.GridSize.y - 1) * self.TileSize then return false end

	return true
end

function PANEL:IsOccupied(gridX, gridY)
	return not self:CheckIsInGridRange(gridX, gridY) or IsValid(self.TileSpots[gridX][gridY])
end

function PANEL:GetTile(gridX, gridY)
	return self.TileSpots[gridX][gridY]
end

function PANEL:GetGridSpot(x, y)
	local size = self.TileSize
	local gridX = math.Round(x / size) * size
	local gridY = math.Round(y / size) * size

	return gridX, gridY
end

-- drop logic 
function PANEL:TileDropped(tile, panel, x, y, mouseCode)
	if not panel.m_Inventory then
		if panel:GetClassName() == "CGModBase" then
			self:OnTileDroppedInWorld(tile)
		end

		self:OnTileDroppedOutsideGrid(tile)
		return
	end
	if tile == panel then return end

	if panel.m_InvTile then -- if its a tile try combine it
		--self:SwapTiles(tile, panel)
		return self:CombineStack(tile, panel)
	end

	if panel ~= self then -- another tile container
		self:SwapTilePanel(tile, panel, x, y)
		return
	end
	--MOUSE_LEFT	107	Left mouse button MOUSE_RIGHT
	if mouseCode == MOUSE_RIGHT then -- split the stack in 2
		local gridX, gridY = self:GetGridSpot(x - self.TileSize / 2, y - self.TileSize / 2)
		self:SplitStack(tile, gridX, gridY)
		return
	end

	-- try to place tile if no checks above returned
	self:TryPlaceTile(tile, x - self.TileSize / 2, y - self.TileSize / 2)
end

--mark tile for this panel
function PANEL:SetTileSpot(tile, gridX, gridY)
	local curSpot = self.Tiles[tile]
	if curSpot then
		self.TileSpots[curSpot.x][curSpot.y] = nil
	end

	self.TileSpots[gridX][gridY] = tile
	self.Tiles[tile] = {x = gridX, y = gridY}
end

--unmark tile from this panel
function PANEL:RemoveTile(tile)
	local tileSpot = self.Tiles[tile]
	if tileSpot then
		self.TileSpots[tileSpot.x][tileSpot.y] = nil
	end

	self.Tiles[tile] = nil
end

function PANEL:SplitStack(tile, gridX, gridY, amount)
	if self:IsOccupied(gridX, gridY) then return end
	local count = tile:GetItemCount()
	if not amount then amount = math.Round(count / 2, 0) end

	local splice = math.Round(count - amount, 0)

	if splice < 1 then return end --always keep at least 1 item left since we try to split the stack
	local oldX, oldY = tile:GetPos()

	local class = tile:GetItemClass()
	tile:SetItemCount(splice)

	local tile2 = self:AddTile(gridX, gridY, "DPanel")
	tile2:SetItemClass(class)
	tile2:SetItemCount(amount)

	self:OnTileMoved(tile2, oldX, oldY, gridX, gridY, self)
	return true
end

function PANEL:CombineStack(tile, tile2)
	if tile2:GetItemClass() ~= tile:GetItemClass() then return end
	local newCount = tile:GetItemCount() + tile2:GetItemCount()
	if newCount > tile2:GetItemMaxCount() then return end

	tile2:SetItemCount(newCount)
	self:RemoveTile(tile)
	tile:Remove()

	return true
end

function PANEL:PlaceTile(tile, gridX, gridY)
	local oldParent = tile:GetParent()
	--swapping between different panels
	if tile:GetParent() ~= self then
		tile:GetParent():RemoveTile(tile)
		tile:SetParent(self)
	end

	local oldX, oldY = tile:GetPos()

	self:SetTileSpot(tile, gridX, gridY)
	tile:SetPos(gridX, gridY)

	self:OnTileMoved(tile, oldX, oldY, gridX, gridY, oldParent)
	--print(self.TileSpots[gridX][gridY])
end

function PANEL:AddTile(x, y, type)
	if not x or not y then
		local size = self.TileSize
		local foundSpot = false

		for gX = 0, self:GetWide() do
			for gY = 0, self:GetTall() do
				local gridX = gX * size
				local gridY = gY * size

				if not self:IsOccupied(gridX, gridY) then
					x = gridX
					y = gridY
					foundSpot = true
					goto END
				end
			end
		end

		::END::
		if not foundSpot then
			return false -- can't fit
		end
	end

	local tile = self:Add("DInventoryTile")
	tile:SetSize(self.TileSize, self.TileSize)
	self:PlaceTile(tile, x, y)

	return tile
end

-- swap bug, doesn't occupy properly??
function PANEL:SwapTiles(tileA, tileB)
	local xA, yA = tileA:GetPos()
	local xB, yB = tileB:GetPos()

	local panelA = tileA:GetParent()
	local panelB = tileB:GetParent()

	panelB:PlaceTile(tileA, xB, yB)
	panelA:PlaceTile(tileB, xA, yA)
end

function PANEL:TryPlaceTile(tile, x, y)
	local gridX, gridY = self:GetGridSpot(x, y)
	if self:IsOccupied(gridX, gridY) then
		return
	end

	self:PlaceTile(tile, gridX, gridY)
end

function PANEL:SwapTilePanel(tile, toPanel, x, y)
	toPanel:TileDropped(tile, toPanel, x, y)

	self:OnTileChangedPanel(tile, toPanel)
	toPanel:OnTileChangedPanel(tile, self)
end

local png = "gui/contenticon-hovered.png"
local mat = Material(png, "noclamp")

function PANEL:Paint(w, h)
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(mat)
	surface.DrawTexturedRectUV(0, 0, w, h, 0, 0, self.GridSize.x, self.GridSize.y)

	surface.SetDrawColor(255, 0, 0) --, g, b, a=255)
	for x = 0, self.GridSize.x do
		for y = 0, self.GridSize.y do
			if self:IsOccupied(x * self.TileSize, y * self.TileSize) then
				surface.DrawOutlinedRect(x * self.TileSize, y * self.TileSize, self.TileSize, self.TileSize, 10)
			end
		end
	end
end

--callbacks
function PANEL:OnTileMoved(tile, oldX, oldY, posX, posY, oldParent)
end
function PANEL:OnTileDroppedInWorld()
end
function PANEL:OnTileChangedPanel(tile, toPanel)
end
function PANEL:OnTileDroppedOutsideGrid(tile)
end

vgui.Register("DInventory", PANEL, "Panel")

-- Tile vgui, mostly just a container for an item
local TILE = {}
function TILE:Init()
	self:Droppable(TAG)
	self:SetSize(64, 64)
	self.m_MaxCount = 2 -- stack size
	self.m_Inventory = true -- droppable panel
	self.m_InvTile = true -- is tile
	self.m_ItemClass = ""
	self.m_ItemCount = 0
	self.clr = Color(50, 50, 50, 200) --debug
end

function TILE:GetItemMaxCount()
	return self.m_MaxCount
end
function TILE:GetItemClass()
	return self.m_ItemClass
end
function TILE:GetItemCount()
	return self.m_ItemCount
end
function TILE:SetItemClass(class)
	self.m_ItemClass = class
end
function TILE:SetItemCount(count)
	self.m_ItemCount = count
end
function TILE:SetItemMaxCount(count)
	self.m_MaxCount = count
end

function TILE:Paint(w, h)
	--if not inventory.CallItem(this:GetItem(), "Paint", w, h)
	surface.SetDrawColor(self.clr)
	surface.DrawRect(0, 0, w, h)

	if self:IsHovered() then
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	surface.SetTextColor(255, 255, 255)
	local tx = self:GetItemCount()
	surface.SetFont("Default")
	local tW, tH = surface.GetTextSize(tx)
	surface.SetTextPos(w - tW, h - tH)
	surface.DrawText(tx)
end

function TILE:OnMouseReleased(code)
	self:MouseCapture(false)
	local panel = vgui.GetHoveredPanel()
	if IsValid(panel) then
		local mX, mY = panel:LocalCursorPos()
		self:GetParent():TileDropped(self, panel, mX, mY, code) --call drop on inventory panel
	end

	if self:DragMouseRelease(code) then
		return
	end
end

vgui.Register("DInventoryTile", TILE, "DPanel")