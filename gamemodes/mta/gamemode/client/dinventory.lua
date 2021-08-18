local TAG = "inventory_drag"
local PANEL = {}

--Known Bugs:
--Grid does not scale properly to grid size, hardcoded margin fixed for 9x4

--Notes:
--Some unused stuff and overhead, does not affect anything, just cluttered code
--Untested bugs due to how the Inventory backend handle stuff and will not be affected by this

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
	self:PostInit()
end

function PANEL:PostInit()
end

function PANEL:Reset()
	for tile, _ in pairs(self.Tiles) do
		self:RemoveTile(tile)
		if IsValid(tile) then
			tile:Remove()
		end
	end
end

function PANEL:SetTileSize(size)
	self.TileSize = size
end

function PANEL:SetGridSize(x, y)
	self.GridSize = Vector(x, y)
	self:SetSize(x * self.TileSize, y * self.TileSize)
end

function PANEL:SetTileSpot(tile, gridX, gridY)
	local curSpot = self.Tiles[tile]
	if curSpot then
		self.TileSpots[curSpot.x][curSpot.y] = nil
	end

	self.TileSpots[gridX][gridY] = tile
	self.Tiles[tile] = {x = gridX, y = gridY}
end

function PANEL:GetGridSpot(x, y)
	local size = self.TileSize
	local gridX = math.Round(x / size) * size
	local gridY = math.Round(y / size) * size

	return gridX, gridY
end

function PANEL:GetTile(gridX, gridY)
	return self.TileSpots[gridX][gridY]
end

function PANEL:RemoveTile(tile)
	local tileSpot = self.Tiles[tile]
	if tileSpot then
		self.TileSpots[tileSpot.x][tileSpot.y] = nil
	end

	self.Tiles[tile] = nil
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

function PANEL:TileDropped(tile, panel, x, y, mouseCode)
	if not panel.m_Inventory then
		if panel:GetClassName() == "CGModBase" then
			self:OnTileDroppedInWorld(tile, panel)
		end

		self:OnTileDroppedOutsideGrid(tile, panel)
		return
	end
	if tile == panel then return end

	if panel.m_InvTile then

		if not self:OnTileDropOnTile(tile, panel) then
			return
		end

		local gridX, gridY = panel:GetPos()

		if panel:GetItemClass() == tile:GetItemClass() and panel:GetItemCount() < tile:GetItemMaxCount() then
			self:CombineStack(tile, panel, gridX, gridY)
			return
		end

		self:SwapTiles(tile, panel)
		return
	end

	if panel ~= self then
		self:SwapTilePanel(tile, panel, x, y)
		return
	end
	--MOUSE_LEFT	107	Left mouse button MOUSE_RIGHT
	if mouseCode == MOUSE_RIGHT then

		self:SplitStack(tile, x, y)
		return
	end

	self:TryPlaceTile(tile, x - self.TileSize / 2, y - self.TileSize / 2)
end

function PANEL:SplitStack(tile, x, y, amount, isCombine, pnl)
	--if self:IsOccupied(gridX, gridY) then return end

	local gridX, gridY = self:GetGridSpot(x - self.TileSize / 2, y - self.TileSize / 2)

	local count = tile:GetItemCount()
	if not amount then amount = math.Round(count / 2, 0) end

	local splice = math.Round(count - amount, 0)

	if splice < 1 then return end --always keep at least 1 item left since we try to split the stack
	local oldX, oldY = tile:GetPos()

	tile:SetItemCount(splice)

	local oldSlotX, oldSlotY = self:TranslateGridToSlot(oldX, oldY)
	local slotX, slotY = self:TranslateGridToSlot(gridX, gridY)
	local tile2 = self:AddTile(gridX, gridY, "DPanel")

	tile2:CopyData(tile)
	tile2:SetItemCount(amount)

	if isCombine then
		self:TileDropped(tile2, pnl, x, y)
	else
		self:OnTileSlotChanged(tile2, oldSlotX, oldSlotY, slotX, slotY)
		self:OnTileMoved(til2, oldX, oldY, gridX, gridY, self)
	end

	return true
end

function PANEL:CombineStack(tile, tile2, gridX, gridY)
	if tile2:GetItemClass() ~= tile:GetItemClass() then return end

	local newCount = tile:GetItemCount() + tile2:GetItemCount()

	local countLeft = 0
	if newCount > tile:GetItemMaxCount() then
		local splice = newCount - tile:GetItemMaxCount()
		newCount = tile:GetItemMaxCount()
		--currently moved tile
		tile:SetItemCount(tile:GetItemCount() - splice)
		countLeft = splice
	end

	local oldX, oldY = tile:GetPos()
	local oldSlotX, oldSlotY = self:TranslateGridToSlot(oldX, oldY)
	local slotX, slotY = self:TranslateGridToSlot(gridX, gridY)

	self:OnTileMoved(tile, oldX, oldY, gridX, gridY, self)
	self:OnTileSlotChanged(tile, oldSlotX, oldSlotY, slotX, slotY)
	tile2:SetItemCount(newCount)
	if countLeft > 0 then
		-- set count back
		tile:SetItemCount(countLeft)
	else
		self:RemoveTile(tile)
		tile:Remove()
	end

end

function PANEL:PlaceTile(tile, gridX, gridY, isInit, swapOrder)
	local oldParent = tile:GetParent()
	if tile:GetParent() ~= self then
		tile:GetParent():RemoveTile(tile)
		tile:SetParent(self)
	end

	if isnumber(swapOrder) then
		self.Tiles[tile] = {x = gridX, y = gridY}
		self.TileSpots[gridX][gridY] = tile
	else
		self:SetTileSpot(tile, gridX, gridY)
	end

	local oldX, oldY = tile:GetPos()
	tile:SetPos(gridX, gridY)

	local slotX, slotY = self:TranslateGridToSlot(gridX, gridY)
	local oldSlotX, oldSlotY = self:TranslateGridToSlot(oldX, oldY)

	tile.m_SlotX, tile.m_SlotY = slotX, slotY
	tile.m_OldSlotX, tile.m_OldSlotY = oldSlotX, oldSlotY

	if isInit then return end
	self:OnTileMoved(tile, oldX, oldY, gridX, gridY, oldParent)
	self:OnTileSlotChanged(tile, oldSlotX, oldSlotY, slotX, slotY, swapOrder)
end

function PANEL:AddTile(x, y)
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
	self:PlaceTile(tile, x, y, true)

	return tile
end

function PANEL:SwapTiles(tileA, tileB)
	local xA, yA = tileA:GetPos()
	local xB, yB = tileB:GetPos()

	local panelA = tileA:GetParent()
	local panelB = tileB:GetParent()

	panelB:PlaceTile(tileA, xB, yB, nil, 1)
	panelA:PlaceTile(tileB, xA, yA, nil, 2)
end

function PANEL:TryPlaceTile(tile, x, y, swappedPanel)
	local gridX, gridY = self:GetGridSpot(x, y)
	if self:IsOccupied(gridX, gridY) then
		return
	end

	self:PlaceTile(tile, gridX, gridY, swappedPanel)
end

function PANEL:SwapTilePanel(tile, toPanel, x, y)
	local oldX, oldY = tile:GetSlotPos()
	toPanel:TileDropped(tile, toPanel, x, y, true)

	self:OnTileChangedPanel(tile, toPanel, oldX, oldY)
	--toPanel:OnTileChangedPanel(tile, self)
end

-- Tile slot bindings for simplicity sake
-- I made everything tileSize based, but let's translate it over to slots (1, 2, 3, 4)
function PANEL:TranslateSlotToGrid(slotX, slotY)
	return (slotX - 1) * self.TileSize, (slotY - 1) * self.TileSize
end

function PANEL:TranslateGridToSlot(gridX, gridY)
	return (self.TileSize + gridX) / self.TileSize, (self.TileSize + gridY) / self.TileSize
end

function PANEL:AddTileInSlot(slotX, slotY)
	local x, y = self:TranslateSlotToGrid(slotX, slotY)
	return self:AddTile(x, y)
end

function PANEL:GetTileInSlot(slotX, slotY)
	local x, y = self:TranslateSlotToGrid(slotX, slotY)
	return self:GetTile(x, y)
end

local png = "gui/sm_hover.png"
local mat = Material(png, "noclamp")

--not sure what I need the margin for, and what to base it off..
local marginW, marginH = 0.128, 0.048
function PANEL:Paint(w, h)
	surface.SetDrawColor(64, 64, 64, 128)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(255, 100, 0)
	surface.SetMaterial(mat)
	surface.DrawTexturedRectUV(0, 0, w, h, 0, 0, self.GridSize.x + marginW, self.GridSize.y + marginH)
end

--override, default behaviour allows for swapping tiles
function PANEL:OnTileDropOnTile(tile, tile)
	return true
end

--callbacks
function PANEL:OnTileSlotChanged(tile, oldSlotX, oldSlotY, slotX, slotY)
end
function PANEL:OnTileMoved(tile, oldX, oldY, posX, posY, oldParent)
end
function PANEL:OnTileDroppedInWorld()
end
function PANEL:OnTileChangedPanel(tile, toPanel, oldX, oldy)
end
function PANEL:OnTileDroppedOutsideGrid(tile)
end
function PANEL:OnTileClick(tile, mouseCode)
end

vgui.Register("DInventory", PANEL, "Panel")

local templateText = "Base Item"
local lastTileID = 0 --always increment the id's of tiles to always be unique

local TILE = {}
function TILE:Init()
	self:Droppable(TAG)
	self:SetSize(64, 64)

	self.m_ItemClass = ""
	self.m_ItemCount = 0
	self.m_MaxCount  = 2

	self.m_ItemName    = templateText
	self.m_Description = templateText

	self.m_Inventory = true
	self.m_InvTile   = true
	self.m_Mdl = ""
	self.m_Mat = nil

	self.m_SlotX = 0
	self.m_SlotY = 0
	self.m_OldSlotY = 0
	self.m_OldSlotX = 0

	self.Icon = vgui.Create("DModelPanel", self)
	self.Icon:Dock(FILL)
	self.Icon:SetMouseInputEnabled(false)
	self.Icon:SetKeyboardInputEnabled(false)

	-- Disable cam rotation
	function self.Icon:LayoutEntity(ent) return end

	function self.Icon:PreDrawModel(ent)
		local mat = self:GetParent().m_Mat
		if isstring(mat) then
			ent:SetMaterial(mat)
		end
	end

	self.isActive = false
	self.ID = lastTileID
	lastTileID = lastTileID + 1
end

function TILE:CopyData(tile)
	self.m_ItemClass = tile.m_ItemClass
	self.m_ItemCount = tile.m_ItemCount
	self.m_MaxCount  = tile.m_MaxCount
	self.m_ItemName  = tile.m_ItemName
	self.m_Description = tile.m_Description
	self.m_Mdl       = tile.m_Mdl

	self:SetModelIcon(tile.m_Mdl, tile.m_Mat)
end

function TILE:GetID()
	return self.ID
end
function TILE:SetItemClass(class)
	self.m_ItemClass = class
end
function TILE:GetItemClass()
	return self.m_ItemClass
end

function TILE:SetItemCount(count)
	self.m_ItemCount = count
end
function TILE:GetItemCount()
	return self.m_ItemCount
end
function TILE:SetItemMaxCount(count)
	self.m_MaxCount = count
end
function TILE:GetItemMaxCount()
	return self.m_MaxCount
end

function TILE:AddItemAmount(amount)
	self.m_ItemCount = self.m_ItemCount + amount
end
function TILE:TakeItemAmount(amount)
	if amount >= self.m_ItemCount then
		self:Remove()
		self:GetParent():RemoveTile(self)
	else
		self.m_ItemCount = self.m_ItemCount - amount
	end
end

function TILE:GetSlotPos()
	return self.m_SlotX, self.m_SlotY
end
function TILE:GetOldSlotPos()
	return self.m_OldSlotX, self.m_OldSlotY
end

function TILE:SetItemName(name)
	self:SetTooltip(name)
	self.m_ItemName = name
end
function TILE:GetItemName()
	return self.m_ItemName or templateText
end
function TILE:SetItemDescription(desc)
	self.m_Description = desc
end
function TILE:GetItemDescription()
	return self.m_Description or templateText
end

function TILE:SetModelIcon(mdl, mat)
	self.m_Mdl = mdl
	self.m_Mat = mat
	self.Icon:SetModel(mdl, 0, 0)

	-- ty gmod for this usefulness
	local icon = self.Icon
	local ent = self.Icon:GetEntity()
	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	local tab = PositionSpawnIcon(ent, pos, true)

	ent:SetAngles(ang)

	if tab then
		icon:SetCamPos(tab.origin)
		icon:SetFOV(tab.fov)
		icon:SetLookAng(tab.angles)
	end
end
function TILE:GetItemData()
	return self.m_OldSlotX, self.m_OldSlotY, self.m_SlotX, self.m_SlotY, self.m_ItemClass, self.m_ItemCount, self.m_MaxCount
end
function TILE:GetModelIcon()
	return self.m_Mdl
end

function TILE:Paint(w, h)
	--if not inventory.CallItem(this:GetItem(), "Paint", w, h)

	if self:IsHovered() then
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end

	if self.isActive then
		surface.SetDrawColor(0, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end

	surface.SetTextColor(255, 255, 255)
	surface.SetFont("Default")

	local tx = self:GetItemCount()
	local tW, tH = surface.GetTextSize(tx)
	surface.SetTextPos(w - tW-8, h - tH-8)
	surface.DrawText(tx)
end

function TILE:OnMouseReleased(code)
	self:MouseCapture(false)

	if not dragndrop.IsDragging() then
		self:GetParent():OnTileClick(self, code)
	end

	local panel = vgui.GetHoveredPanel()
	if IsValid(panel) then
		local mX, mY = panel:LocalCursorPos()
		self:GetParent():TileDropped(self, panel, mX, mY, code)
	end

	if self:DragMouseRelease(code) then
		gui.EnableScreenClicker(true)
		return
	end
end

vgui.Register("DInventoryTile", TILE, "DPanel")