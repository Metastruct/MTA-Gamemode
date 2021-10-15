local inventory = MTA_TABLE("Inventory")
local TILE_SIZE = 64

local function GetItemData(class)
	return inventory.Items[class]
end

local PANEL = {}
function PANEL:Init()
	self:SetTileSize(TILE_SIZE)
	self:SetGridSize(9, 4)

	self.TrashCan = self:Add("DInventory")
	self.TrashCan:SetTileSize(TILE_SIZE / 1.5)
	self.TrashCan:SetGridSize(1, 1)
	self.TrashCan.isTrash = true

	local trashMat = Material("icon16/bin_empty.png")
	function self.TrashCan:Paint(w, h)
		surface.SetDrawColor(255, 255, 255)
		if self:IsHovered() then
			surface.SetDrawColor(MTA.DangerColor)
		end

		surface.SetMaterial(trashMat)
		surface.DrawTexturedRect(w / 4, h / 2, w / 2, h / 2)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		local tx = "Trash"
		surface.SetFont("Default")
		local tW, _ = surface.GetTextSize(tx)
		surface.SetTextColor(255, 255, 255)
		surface.SetTextPos(w / 2 - tW / 2, 0)
		surface.DrawText(tx)
	end

	self.ItemView = self:Add("DPanel")
	self.ItemView:SetSize(self:GetSize())

	self.ViewDocker = self.ItemView:Add("Panel")
	self.ViewDocker:SetPos(128 + 16)
	self.ViewDocker:SetSize(self:GetWide(), self:GetTall())

	self.ItemViewHeader = self.ViewDocker:Add("DLabel")
	self.ItemViewHeader:Dock(TOP)
	self.ItemViewHeader:SetColor(MTA.NewValueColor)
	self.ItemViewHeader:SetText("BASE_ITEM")
	self.ItemViewHeader:SetFont("ScoreboardDefault")
	self.ItemViewHeader:DockMargin(2, 4, 0, 4)
	self.ItemViewHeader:SetPos(0, 128)
	self.ItemViewHeader:SetSize(128, 32)

	--[=[
	self.HelpText = self.ViewDocker:Add("DLabel")
	self.HelpText:Dock(BOTTOM)
	self.HelpText:SetTall(64)
	local helpText = [[Drag an item outside the inventory to drop it.
The trashcan will remove any item you drop in it.
Right click drag an item to split the stack.]]
	self.HelpText:SetText(helpText)
	]=]

	self.ItemViewInfo = self.ViewDocker:Add("RichText")
	self.ItemViewInfo:Dock(FILL)
	function self.ItemViewInfo:PerformLayout()
		self:SetFontInternal("CreditsText")
		self:SetFGColor(255, 255, 255, 255)
	end

	self.ItemViewIcon = self.ItemView:Add("DModelPanel")
	self.ItemViewIcon:SetSize(128, 128)
	self.ItemViewIcon:SetMouseInputEnabled(false)
	self.ItemViewIcon:SetKeyboardInputEnabled(false)

	self.ItemViewButton = self.ItemView:Add("DButton")
	self.ItemViewButton:SetSize(128, 24)
	self.ItemViewButton:SetPos(8, self:GetTall() - 32)
	self.ItemViewButton:SetText("Use Item")
	self.ItemViewButton:SetTextColor(MTA.TextColor)

	function self.ItemViewButton.DoClick(this)
		if IsValid(self) then
			self:UseActiveItem(1)
		end
	end

	-- populate
	local selected
	for slotX, slotData in pairs(inventory.GetInventory(LocalPlayer())) do
		for slotY, item in pairs(slotData) do

			local x = slotY
			local y = slotX

			local tile = self:AddItem(item.Class, item.Amount, x, y)

			if not selected then
				self:SelectTile(tile)
				selected = true
			end
		end
	end

	local GM = gmod.GetGamemode() or GAMEMODE or GM
	function GM.MTAInventoryItemAdded(_, ply, class, amount, x, y)
		if IsValid(self) then
			self:ItemAdded(ply, class, amount, x, y)
		end
	end

	function GM.MTAInventoryItemRemoved(_, ply, class, amount, x, y)
		if IsValid(self) then
			self:ItemRemove(ply, class, amount, x, y)
		end
	end

	function GM.MTAInventoryModified(_, ply, class, amount, oldX, oldY, x, y)
		if IsValid(self) then
			self:ItemModified(ply, class, amount, oldX, oldY, x, y)
		end
	end
end

function PANEL:UseActiveItem(amount)
	if IsValid(self.ActiveItem) then
		local x, y = self.ActiveItem:GetSlotPos()
		local class = self.ActiveItem:GetItemClass()
		if not inventory.IsUsable(class) then return end

		inventory.UseItem(class, x, y, amount)
	end
end

function PANEL:ItemAmountPopup(amount, callback)
	local FRAME_WIDTH, FRAME_HEIGHT = 256, 64

	local Frame = vgui.Create("DMenu")

	local Panel
	local Label
	local Button
	local NumSlider

	Panel = vgui.Create("DPanel")
	Panel:SetSize(FRAME_WIDTH, FRAME_HEIGHT)

	Label = Panel:Add("DLabel")
	Label:SetSize(128, 32)
	Label:SetText("Amount to drop: ")
	Label:SetPos(8,0)

	Button = Panel:Add("DButton")
	Button:Dock(RIGHT)
	Button:SetText("Drop")
	Button:DockMargin(8, 8, 8, 8)
	function Button:DoClick()
		CloseDermaMenus()
		if not callback then return end
		callback(math.round(NumSlider:GetValue(), 0))
	end
	NumSlider = Panel:Add("DNumSlider")
	NumSlider:Dock(BOTTOM)

	NumSlider:DockMargin(-Panel:GetWide() / 2 + 16, 0, 0, 10) --wang and scratch fucks up the docking
	NumSlider.Wang:Hide()
	NumSlider.Scratch:Hide()
	NumSlider.TextArea:SetTextColor(Color(255, 255, 255))
	NumSlider:SetMinMax(1, amount)
	NumSlider:SetDefaultValue(1)
	NumSlider:SetDecimals(0)
	NumSlider:SetValue(1)

	local notches = math.Clamp(amount, 1, 15)
	function NumSlider.Slider:Paint(w, h)

		surface.SetDrawColor(255, 255, 255)
		for i = 1, notches do
			local x = i * (w / notches) + 1
			local y = h / 2 + h / 10

			surface.DrawRect(x, y, 1, h / 2)
		end
	end

	Frame:AddPanel(Panel)
	Frame:Open()
end

local function drop(x, y, class, amount)
	local pos = LocalPlayer():GetShootPos()
	local ang = LocalPlayer():EyeAngles()
	ang.p = 0
	pos = pos + ang:Forward() * 42

	inventory.DropItem(class, x, y, amount, pos)
end

function PANEL:DropItem(tile, amount)
	local x, y = tile:GetSlotPos()
	local class = tile:GetItemClass()

	if amount > 1 then
		self:ItemAmountPopup(amount, function(amnt)
			drop(x, y, class, amnt)
		end)
	else
		drop(x, y, class, amount)
	end
end

function PANEL:UpdateItemView(tile)
	self.ItemViewHeader:SetText(tile:GetItemName())
	self.ItemViewInfo:SetText(tile:GetItemDescription())
	self.ItemViewIcon:SetModel(tile:GetModelIcon())
	-- ty gmod for this usefulness
	local icon = self.ItemViewIcon
	local ent = self.ItemViewIcon:GetEntity()
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

function PANEL:SelectTile(tile)
	if IsValid(self.ActiveItem) then
		self.ActiveItem.isActive = false
	end
	tile.isActive = true
	self.ActiveItem = tile
	self:UpdateItemView(tile)
end

function PANEL:AddItem(class, amount, x, y)
	local t = self:AddTileInSlot(x, y)
	if not t then return end -- ILLEGAL or bug?!

	local data = GetItemData(class)
	if not data then
		data = {
			Name = "Nothing",
			Description = "There was once something, it is now nothing...",
			Model = "models/Gibs/HGIBS.mdl",
		}
	end

	t:SetItemClass(class)
	t:SetItemCount(amount)
	t:SetItemMaxCount(inventory.GetStackLimit(class))
	t:SetItemName(data.Name)
	t:SetModelIcon(data.Model, data.Material)
	t:SetItemDescription(data.Description)

	return t
end

function PANEL:OnTileDroppedInWorld(tile)
	local amount = math.Clamp(tile:GetItemCount(), 1, 16)
	self:DropItem(tile, amount)
end

function PANEL:OnTileSlotChanged(tile, oldSlotX, oldSlotY, slotX, slotY, swapOrder)
	if slotX == oldSlotX and slotY == oldSlotY then return end

	local class = tile:GetItemClass()
	local amount = tile:GetItemCount()

	if swapOrder == 1 then
		inventory.SwapItems(oldSlotX, oldSlotY, slotX, slotY)
		return
	elseif swapOrder == 2 then
		--we swapped it already
		return
	end

	print("old " .. oldSlotX .. ", " .. oldSlotY .. " -> " .. slotX .. ", " .. slotY)
	inventory.MoveItem(class, oldSlotX, oldSlotY, slotX, slotY, amount)
end

function PANEL:OnTileChangedPanel(tile, toPanel, x, y)
	if toPanel.isTrash then
		local class = tile:GetItemClass()
		local amount = tile:GetItemCount()

		inventory.RemoveItem(class, x, y, amount)

		tile:Remove()
		self:RemoveTile(tile)
	elseif toPanel.QuickItems and toPanel.OnReceiveItem then -- add item class to quick items
		local class = tile:GetItemClass()
		toPanel:OnReceiveItem(class, input.GetCursorPos())

		local old_tile = self:AddTileInSlot(x, y)
		old_tile:CopyData(tile)
		tile:Remove()
	end
end

function PANEL:OnTileClick(tile, code)
	self:SelectTile(tile)

	if code == MOUSE_RIGHT then
		local menu = DermaMenu()
		menu.noDrop = true

		if IsValid(self.ActiveItem) then
			local class = self.ActiveItem:GetItemClass()
			if inventory.IsUsable(class) then
				menu:AddOption("Use", function()
					self:UseActiveItem(1)
				end)
			end

			menu:AddOption("Drop 1 item", function()
				self:DropItem(tile, 1)
			end)
		end

		menu:Open()
	end
end

function PANEL:ItemAdded(ply, class, amount, x, y)
	local tile = self:GetTileInSlot(x, y)
	if IsValid(tile) then
		tile:SetItemCount(amount)
	else
		self:AddItem(class, amount, x, y)
	end
end

function PANEL:ItemRemove(ply, class, amount, x, y)
	local tile = self:GetTileInSlot(x, y)
	if IsValid(tile) and tile:GetItemClass() == class then
		if amount <= 0 then
			self:RemoveTile(tile)
			tile:Remove()
			return
		end

		tile:SetItemCount(amount)
	end
end

function PANEL:ItemModified(ply, class, amount, oldX, oldY, x, y)
	local tile = self:GetTileInSlot(x, y)
	if IsValid(tile) and tile:GetItemClass() == class then
		tile:SetItemCount(amount)
	end
end

vgui.Register("mta_inventory", PANEL, "DInventory")
