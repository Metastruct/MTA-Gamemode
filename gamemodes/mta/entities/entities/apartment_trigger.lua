AddCSLuaFile()
ENT.Base       = "base_anim"
ENT.PrintName  = ""
ENT.Author     = "Henke & Jule"
ENT.Spawnable  = false
ENT.Zone       = ""

--Basic box trigger
function ENT:SetupTriggerBox(mins, maxs)
	self:SetSolid(SOLID_BBOX)
	self:SetSolidFlags(12)
	self:SetCollisionBounds(mins, maxs)
	self:SetRenderMode(RENDERMODE_TRANSTEXTURE)
	self:DrawShadow(false)

	if SERVER then
		self:SetTrigger(true)
	end
end

function ENT:SetParentApt(apt)
	self.APARTMENT = apt
end

local TRIGGER_MAXS = Vector(1, 1, 1)
local TRIGGER_MINS = Vector(-1, -1, -1)
function ENT:Initialize()
	self:SetupTriggerBox(TRIGGER_MINS, TRIGGER_MAXS)
end

function ENT:StartTouch(ent)
end

function ENT:EndTouch(ent)
end

function ENT:Touch(ent)
	if not MTA.Apartments or not MTA.Apartments.EntityUpdate then return end

	MTA.Apartments.EntityUpdate(self, ent)
end

function ENT:OnRemove()
end