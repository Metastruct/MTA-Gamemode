local crafting = MTA_TABLE("Crafting")
local inventory = MTA_TABLE("Inventory")
local tag = "MTA_Crafting_UI"

local function GetItemName(class)
	return inventory.Items[class] and inventory.Items[class].Name or ""
end

local function GetItemModel(class)
	return inventory.Items[class] and inventory.Items[class].Model or ""
end

local PANEL = {}
function PANEL:Init()
	self.CraftAmount = 1

	self.CraftButton = self:Add("DButton")
	self.CraftButton:SetSize(96, 48)
	self.CraftButton:SetText("Craft Item")
	self.CraftButton:SetPos(468, 460)
	self.CraftButton:SetDisabled(true)
	self.CraftButton.DoClick = function(button)
		if not self.SelectedBlueprint then return end

		crafting.CraftItem(self.SelectedBlueprint, self.CraftAmount)
		notification.AddLegacy("Crafted " .. self.CraftAmount .. "x " .. self.SelectedBlueprint, NOTIFY_HINT, 2)
	end

	local Panel
	local Label
	local NumSlider

	Panel = self:Add("DPanel")
	Panel:SetSize(256, 64)
	Panel:SetPos(200, 455)

	Label = Panel:Add("DLabel")
	Label:SetSize(128, 32)
	Label:SetText("Amount to craft: ")
	Label:SetPos(8,0)

	NumSlider = Panel:Add("DNumSlider")
	NumSlider:Dock(BOTTOM)

	NumSlider:DockMargin(-Panel:GetWide() / 2 + 16, 0, 0, 10) --wang and scratch fucks up the docking
	NumSlider.Wang:Hide()
	NumSlider.Scratch:Hide()
	NumSlider.TextArea:SetTextColor(Color(255, 255, 255))
	NumSlider:SetMinMax(1, 10)
	NumSlider:SetDefaultValue(1)
	NumSlider:SetDecimals(0)
	NumSlider:SetValue(1)

	function NumSlider.OnValueChanged(slider, val)
		val = math.round(val, 0)
		if self.CraftAmount == val then return end -- Don't update if the value is same as last

		self.CraftAmount = val
		slider:SetValue(self.CraftAmount) --makes it snap to numbers instead of decimals
		self:UpdateCraftingInfo()
	end

	local notches = 10
	function NumSlider.Slider:Paint(w, h)

		surface.SetDrawColor(255, 255, 255)
		for i = 1, notches do
			local x = i * (w / notches) + 1
			local y = h / 2 + h / 10

			surface.DrawRect(x, y, 1, h / 2)
		end
	end

	self.BlueprintList = self:Add("DListView")
	self.BlueprintList:SetWide(200)
	self.BlueprintList:Dock(LEFT)
	self.BlueprintList.OnRowSelected = function(list, index, row)
		self.SelectedBlueprint = row.class
		self:UpdateCraftingInfo()

		self.ItemViewIcon:SetModel(GetItemModel(row.class))
		self:UpdateItemView()
	end
	--self.BlueprintList.DoDoubleClick
	--self.BlueprintList.OnRowRightClick

	self.BlueprintList:AddColumn("Blueprints")
	for k, v in pairs(crafting.Blueprints) do
		local line = self.BlueprintList:AddLine(GetItemName(k))
		line.class = k
	end

	hook.Add("MTABlueprintsUpdated", tag, function()
		self.BlueprintList:Clear()

		for k, v in pairs(crafting.Blueprints) do
			local line = self.BlueprintList:AddLine(GetItemName(k))
			line.class = k
		end
	end)

	local function InventoryUpdate()
		self:UpdateCraftingInfo()
	end

	hook.Add("MTAInventoryItemAdded", tag, InventoryUpdate)
	hook.Add("MTAInventoryItemRemoved", tag, InventoryUpdate)

	local panel = self:Add("DPanel")
	panel:Dock(TOP)
	panel:SetHeight(300)
	local mat = Material("gui/dupe_bg.png")
	function panel:Paint(w, h)
		surface.SetMaterial(mat)
		surface.DrawTexturedRect(0, 0, w, h)
	end
	self.ItemViewIcon = panel:Add("DModelPanel")
	self.ItemViewIcon:Dock(FILL)
	self.ItemViewIcon:SetMouseInputEnabled(false)
	self.ItemViewIcon:SetKeyboardInputEnabled(false)

	self.CraftInfo = self:Add("RichText")
	self.CraftInfo:Dock(TOP)
	self.CraftInfo:SetHeight(128)

	function self.CraftInfo:PerformLayout()
		self:SetFontInternal("CreditsText")
		self:SetFGColor(255, 255, 255, 255)
	end
end

function PANEL:UpdateCraftingInfo()
	local item_class = self.SelectedBlueprint
	if not item_class then return end

	local canCraft = crafting.CanCraft(LocalPlayer(), item_class, self.CraftAmount)
	if not canCraft then
		self.CraftButton:SetDisabled(true)
	else
		self.CraftButton:SetEnabled(true)
	end

	local item = inventory.Items[item_class]

	self.CraftInfo:SetText(GetItemName(item_class) .. "\n")
	if not item.Craft then return end

	for _, craft_data in ipairs(item.Craft) do
		local resourceAmount = craft_data.Amount * self.CraftAmount
		local item_class = craft_data.Resource
		local itemCount = inventory.GetTotalItemCount(LocalPlayer(), item_class)

		local text = resourceAmount .. " / " .. itemCount .. " " .. GetItemName(item_class) .. "\n"

		if not canCraft and not inventory.HasItem(LocalPlayer(), item_class, resourceAmount) then
			self.CraftInfo:InsertColorChange(255, 50, 50, 255)
		else
			self.CraftInfo:InsertColorChange(255, 255, 255, 255)
		end

		self.CraftInfo:AppendText(text)
	end
end

function PANEL:UpdateItemView()
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

vgui.Register("mta_crafting", PANEL, "DPanel")
