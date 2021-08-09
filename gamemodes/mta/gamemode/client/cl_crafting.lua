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
	self.CraftButton = self:Add("DButton")
	self.CraftButton:SetSize(96, 48)
	self.CraftButton:SetText("Craft Item")
	self.CraftButton:SetPos(468, 460)
	self.CraftButton:SetDisabled(true)
	self.CraftButton.DoClick = function(button)
		if not self.SelectedBlueprint then return end

		crafting.CraftItem(self.SelectedBlueprint, 1)
		notification.AddLegacy("Crafted " .. self.SelectedBlueprint, NOTIFY_HINT, 2)
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

	local canCraft = crafting.CanCraft(LocalPlayer(), item_class, 1)
	if not canCraft then
		self.CraftButton:SetDisabled(true)
	else
		self.CraftButton:SetEnabled(true)
	end

	local item = inventory.Items[item_class]

	self.CraftInfo:SetText(GetItemName(item_class) .. "\n")
	if not item.Craft then return end

	for _, craft_data in ipairs(item.Craft) do

		if not canCraft and not inventory.HasItem(LocalPlayer(), craft_data.Resource, craft_data.Amount) then
			self.CraftInfo:InsertColorChange(255, 50, 50, 255)
			self.CraftInfo:AppendText("Missing: " .. craft_data.Amount .. "x " .. GetItemName(craft_data.Resource) .. "\n")
		else
			self.CraftInfo:InsertColorChange(255, 255, 255, 255)
			self.CraftInfo:AppendText(craft_data.Amount .. "x " .. GetItemName(craft_data.Resource) .. "\n")
		end
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
