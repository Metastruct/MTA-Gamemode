local ITEM = {}

ITEM.Name = "Eye Implant"
ITEM.Description = "An eye implant, lets you see enemies through walls."
ITEM.Model = "models/gibs/gunship_gibs_eye.mdl"
ITEM.StackLimit = 1
ITEM.Usable = true
ITEM.Craft = {
	{ Resource = "combine_core", Amount = 1 },
	{ Resource = "biomass", Amount = 10 },
	{ Resource = "metal_part", Amount = 1 },
}

if SERVER then
	function ITEM:OnUse(ply, _)
		ply:SetNWBool("MTAEyeImplant", true)
		MTA.Statuses.AddStatus(ply, "eye_implant", "Eye Implant", Color(0, 255, 0))
	end

	hook.Add("PlayerDeath", "mta_eye_implant", function(ply)
		ply:SetNWBool("MTAEyeImplant", false)
		MTA.Statuses.RemoveStatus(ply, "eye_implant")
	end)
end

if CLIENT then
	local wireframe = Material("models/wireframe")
	local function mta_render_override(self)
		if not LocalPlayer():GetNWBool("MTAEyeImplant") then
			self:DrawModel()
			return
		end

		cam.IgnoreZ(true)
			render.SetLightingMode(2)
			render.SetColorModulation(0, 1, 0)
				render.MaterialOverride(wireframe)
					self:DrawModel()
				render.MaterialOverride()
			render.SetColorModulation(0, 0, 0)
			render.SetLightingMode(0)
		cam.IgnoreZ(false)

		self:DrawModel()
	end

	local mta_classes = {
		npc_metropolice = true,
		npc_manhack = true,
		npc_combine_s = true,
		npc_hunter = true,
	}
	hook.Add("OnEntityCreated", "mta_eye_implant", function(ent)
		if mta_classes[ent:GetClass()] then
			ent.RenderOverride = mta_render_override
		end
	end)
end

MTA.Inventory.RegisterItem("eye_implant", ITEM)