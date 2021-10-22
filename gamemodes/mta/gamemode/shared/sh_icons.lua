local tag = "MTAIcons"
local icons = MTA_TABLE("Icons")

if SERVER then
	-- load all the icons
	local path = "materials/vgui/mta_hud/"
	local files = file.Find(path .. "*_icon.png", "GAME")
	for _, f in ipairs(files) do
		resource.AddFile(path .. f)
	end
end

-- other icons
local vault_icon = Material("vgui/mta_hud/vault_icon.png")
local vehicle_icon = Material("vgui/mta_hud/vehicle_icon.png")

-- npc dealer stuff
local dealer_icon = Material("vgui/mta_hud/dealer_icon.png")
local car_dealer_icon = Material("vgui/mta_hud/garage_icon.png")
local hardware_icon = Material("vgui/mta_hud/hardware_icon.png")
local hotdog_icon = Material("vgui/mta_hud/hotdog_icon.png")
local unknown_icon = Material("vgui/mta_hud/business_icon.png")
icons.RoleLookup = {
	["dealer"] = dealer_icon,
	["car_dealer"] = car_dealer_icon,
	["hardware_dealer"] = hardware_icon,
	["hotdog_dealer"] = hotdog_icon,
}

icons.RoleBlacklist = {
	["_bad"] = true,
}

function icons.GetIconMaterial(ent)
	if not IsValid(ent) then return end

	local classname = ent:GetClass()
	if classname == "lua_npc" then
		local role = ent:GetNWString("npc_role", "_bad")
		if icons.RoleBlacklist[role] then return end
		return icons.RoleLookup[role] or unknown_icon
	end

	if classname == "mta_vault" then
		return vault_icon
	end

	if MTA.Cars and MTA.Cars.CurrentVehicle == ent then
		return vehicle_icon
	end
end

if CLIENT then
	local offset = Vector(0, 0, 10)
	local white_color = Color(255, 255, 255)
	local max_dist = 2000

	local distance = FindMetaTable("Vector").Distance
	local find_by_class = ents.FindByClass
	hook.Add("HUDPaint", tag, function()
		local old_mult = surface.GetAlphaMultiplier()
		local bind = MTA.GetBindKey("+use") or "/"
		local text = ("/// Talk [%s] ///"):format(bind)

		for _, npc in ipairs(find_by_class("lua_npc")) do
			local mat = icons.GetIconMaterial(npc)
			if mat then
				local dist = math.min(max_dist, distance(LocalPlayer():EyePos(), npc:EyePos()))
				if dist >= max_dist then continue end

				local alpha = (max_dist - dist) / max_dist
				local screen_pos = (npc:EyePos() + offset):ToScreen()

				surface.SetAlphaMultiplier(alpha)
				surface.SetDrawColor(white_color)
				surface.SetMaterial(mat)
				surface.DrawTexturedRect(screen_pos.x - 25, screen_pos.y - 25, 50, 50)
			end

			MTA.ManagedHighlightEntity(npc, text, white_color)
		end

		surface.SetAlphaMultiplier(old_mult)
	end)
end