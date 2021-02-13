AddCSLuaFile()

ENT.Base       = "base_anim"
ENT.PrintName  = ""
ENT.Author     = "Henke"
ENT.Spawnable  = false

--Basic box trigger
function ENT:SetupTriggerBox(mins, maxs)
	self:SetSolid(SOLID_BBOX)
	self:SetSolidFlags(12)
	self:SetCollisionBounds(mins, maxs)
	self:SetRenderMode(RENDERMODE_TRANSTEXTURE)
	self:DrawShadow(false)

	if CLIENT then --This is for drawing
		local mins, maxs = self:GetCollisionBounds()
		self:SetRenderBounds(mins, maxs)
	end

	if SERVER then
		self:SetTrigger(true)
	end
end

local TRIGGER_MAXS = Vector(72, 128, 64)
local TRIGGER_MINS = Vector(72, 128, 0)

function ENT:Initialize()
	self:SetupTriggerBox(TRIGGER_MINS, TRIGGER_MAXS)

	if SERVER then --to make it easier for cars to stand on the platform
		local platform = ents.Create("prop_physics")
		platform:SetModel("models/props_phx/construct/metal_plate2x4.mdl")
		platform:SetPos(self:GetPos())
		platform:Spawn()
		platform:SetNoDraw(true)

		local phys = platform:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end

		platform.PhysgunDisabled = true
		function platform:CanProperty() return false end
		function platform:CanTool() return false end

		self:DeleteOnRemove(platform)
	end
end

local function StartRepair(ent)
	net.Start("simfphys_lightsfixall")
		net.WriteEntity(ent)
	net.Broadcast()

	for _, wheel in ipairs(ent.Wheels) do
		if IsValid(wheel) then
			wheel:SetDamaged(false)
		end
	end

	ent:SetOnFire(false)
	ent:SetOnSmoke(false)
end

function ENT:RepairCar(ent, howMuch)

	local health    = ent:GetCurHealth()
	local maxHealth = ent:GetMaxHealth()

	if health < maxHealth then
		ent:SetCurHealth(health + howMuch)

		local effect = ents.Create("env_spark")
		effect:SetKeyValue("targetname", "target")
		effect:SetPos(ent:GetPos())
		effect:SetAngles(ent:GetAngles())
		effect:Spawn()
		effect:SetKeyValue("spawnflags","128")
		effect:SetKeyValue("Magnitude",1)
		effect:SetKeyValue("TrailLength",0.2)
		effect:Fire("SparkOnce")
		effect:Fire("kill","",0.08)
	elseif health > maxHealth then
		ent:SetCurHealth(maxHealth)
	end
end

local function IsValidCar(ent)
	return IsValid(ent) and ent:GetClass() == "gmod_sent_vehicle_fphysics_base"
end

function ENT:StartTouch(ent)
	if IsValidCar(ent) then
		StartRepair(ent)
	end
end

function ENT:EndTouch(ent)
end

function ENT:Touch(ent)
	if IsValidCar(ent) then
		self:RepairCar(ent, 10)
	end
end

function ENT:OnRemove()
end

if CLIENT then

	function ENT:Draw()
	end

--Debug
--[[
	local mat = CreateMaterial("render_test1", "UnlitGeneric", {
		["$basetexture"] = "tools/toolstrigger",
		["$model"]       = 0,
		["$translucent"] = 1,
		["$vertexalpha"] = 1,
		["$vertexcolor"] = 1
	})

	function ENT:Draw()
		self:SetRenderBounds(self:GetCollisionBounds()) --TESTING ONLY

		render.SetMaterial(mat)
		local mins, maxs = self:GetCollisionBounds()
		render.DrawBox(self:GetPos(), self:GetAngles(), mins, maxs, Color(255, 255, 255))
	end
]]
end