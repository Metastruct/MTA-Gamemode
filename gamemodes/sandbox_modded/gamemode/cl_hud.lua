MTAHud = {}

MTAHud.Config = {
	ScrRatio = ScrH() / 1080,
	HudPos = CreateClientConVar("mta_hud_pos", "0", true, false),
	MapPos = CreateClientConVar("mta_hud_map_pos", "0", true, false),
	HudMovement = CreateClientConVar("mta_hud_movement", "1", true, false)
}

MTAHud.Vars = {
	LastAngs = EyeAngles(),
	AngDeltaP = 0,
	AngDeltaY = 0,
	LastTranslateP = 0,
	LastTranslateY = 0
}

MTAHud.UpdateVars = function(self)
	local vel = LocalPlayer():GetAbsVelocity()

	local curAngs = EyeAngles()

	self.Vars.AngDeltaP = math.AngleDifference(self.Vars.LastAngs.p, curAngs.p)
	self.Vars.AngDeltaY = math.AngleDifference(self.Vars.LastAngs.y, curAngs.y)

	self.Vars.LastAngs = curAngs

	self.Vars.LastTranslateP = Lerp(FrameTime() * 5, self.Vars.LastTranslateP, self.Vars.AngDeltaP)
	self.Vars.LastTranslateY = Lerp(FrameTime() * 5, self.Vars.LastTranslateY, self.Vars.AngDeltaY)

	if vel.z ~= 0 then
		self.Vars.LastTranslateP = self.Vars.LastTranslateP + (math.Clamp(vel.z, -100, 100) * FrameTime() * 0.2)
	end
end

MTAHud.Components = {}
MTAHud.DrawComponents = function(self)
	for k, v in pairs(self.Components) do
		v:Draw()
	end
end
MTAHud.AddComponent = function(self, name, tbl)
	self.Components[name] = tbl
end
MTAHud.RemoveComponent = function(self, name)
	self.Components[name] = nil
end

hook.Add("HUDPaint", "mta_hud", function()
	MTAHud:UpdateVars()
	MTAHud:DrawComponents()
end)

local elements_to_hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true
}

-- Hide default hud
hook.Add("HUDShouldDraw", "mta_hud", function(element)
	if elements_to_hide[element] then
		return false
	end
end)

MTAHud:AddComponent("hud", include("mta_hud/hud.lua"))
MTAHud:AddComponent("map", include("mta_hud/map.lua"))
MTAHud:AddComponent("daily_missions", include("mta_hud/daily_challenges.lua"))
MTAHud:AddComponent("vault", include("mta/hud/vault.lua"))