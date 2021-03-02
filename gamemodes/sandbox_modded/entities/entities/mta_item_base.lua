AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Author = "Earu"
ENT.PrintName = "Item"
ENT.Spawnable = false

function ENT:GetItemClass()
	return self:GetNWString("MTAItemClass")
end

function ENT:GetItem(input_item_class)
	local item_class = input_item_class or self:GetItemClass()
	if MTA and MTA.Inventory then
		return MTA.Inventory.Items[item_class]
	end

	return nil
end

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/props_junk/PopCan01a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
		self:SetNotSolid(false)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
		end

		self:Activate()
	end

	function ENT:SetItemClass(item_class)
		local item = self:GetItem(item_class)
		if item then
			self:SetNWString("MTAItemClass", item_class)
			if isstring(item.Model) then self:SetModel(item.Model) end
			if isstring(item.Material) then self:SetMaterial(item.Material) end
			if IsColor(item.Color) then self:SetColor(item.Color) end

			if item.OnItemEntitySet then
				item:OnItemEntitySet(self)
			end
		end
	end

	function ENT:Use(activator)
		if not activator:IsPlayer() then return end
		if MTA and MTA.Inventory then
			local item_class = self:GetItemClass()
			MTA.Inventory.AddItem(activator, item_class, 1)
		end

		self:Remove()
	end
end

if CLIENT then
	pcall(include, "autorun/translation.lua")
	local L = translation and translation.L or function(s) return s end

	language.Add("mta_item_base", "Item")

	function ENT:Draw()
		local item = self:GetItem()
		if item and item.OnItemEntityDraw then
			item:OnItemEntityDraw(self)
		else
			self:DrawModel()
		end
	end

	local color_white = Color(255, 255, 255)
	local verb = L"Collect"
	hook.Add("HUDPaint", "mta_item_base", function()
		local bind = MTA.GetBindKey("+use")
		if not bind then return end

		for _, item_base in ipairs(ents.FindByClass("mta_item_base")) do
			local item = item_base:GetItem()
			if item then
				if item.OnItemEntityPaint then
					item:OnItemEntityPaint(item_base)
				else
					local text = ("/// %s %s [%s] ///"):format(verb, item.Name or item.ClassName, bind)
					MTA.ManagedHighlightEntity(item_base, text, color_white, true)
				end
			end
		end
	end)

	hook.Add("PreDrawOutlines", "mta_item_base", function()
		for _, item_base in ipairs(ents.FindByClass("mta_item_base")) do
			if item_base.ShouldHighlight then
				outline.Add(item_base, color_white, OUTLINE_MODE_BOTH, 3)
			end
		end
	end)
end