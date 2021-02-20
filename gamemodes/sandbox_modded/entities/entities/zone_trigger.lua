AddCSLuaFile()
ENT.Base       = "base_anim"
ENT.PrintName  = ""
ENT.Author     = "Henke"
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

local TRIGGER_MAXS = Vector(1, 1, 1)
local TRIGGER_MINS = Vector(-1, -1, -1)
function ENT:Initialize()
	self:SetupTriggerBox(TRIGGER_MINS, TRIGGER_MAXS)
end

function ENT:StartTouch(ent)
	MTA.Zones.ZoneUpdate(self.Zone, ent, true)
end

function ENT:EndTouch(ent)
	MTA.Zones.ZoneUpdate(self.Zone, ent, false)
end

function ENT:Touch(ent)
end

function ENT:OnRemove()
end

--[[ --debug
function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end
]]

if CLIENT then

	function ENT:Draw()
	end

--[[ --Debug
	local mat = CreateMaterial("render_test1", "UnlitGeneric", {
		["$basetexture"] = "tools/toolstrigger",
		["$model"]       = 0,
		["$translucent"] = 1,
		["$vertexalpha"] = 1,
		["$vertexcolor"] = 1
	})

	function ENT:DrawTranslucent()
		self:SetRenderBounds(self:GetCollisionBounds()) --TESTING ONLY

		render.SetMaterial(mat)
		local mins, maxs = self:GetCollisionBounds()
		render.DrawBox(self:GetPos(), self:GetAngles(), mins, maxs, Color(255, 255, 255))
	end
--]]
end
