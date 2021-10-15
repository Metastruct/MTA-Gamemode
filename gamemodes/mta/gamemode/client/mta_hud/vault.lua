local mat_vec = Vector()

local mat = Matrix()

surface.CreateFont("MTADrillFont", {
	font = "Orbitron",
	size = 26 * MTA.HUD.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

return function()
	local vault = LocalPlayer():GetNWEntity("MTAVault", NULL)
	if not IsValid(vault) then return end

	mat:SetField(2, 1, 0.05)

	mat_vec.x = (-30 * MTA.HUD.Config.ScrRatio) + (MTA.HUD.Vars.LastTranslateY * 2)
	mat_vec.y = (-100 * MTA.HUD.Config.ScrRatio) + (MTA.HUD.Vars.LastTranslateP * 3)

	mat:SetTranslation(mat_vec)
	cam.PushModelMatrix(mat)

	surface.SetDrawColor(MTA.BackgroundColor)
	local coef = ScrW() / 2560
	local x, y = ScrW() - 400 * coef, ScrH() / 2
	surface.DrawRect(x, y, 400 * coef, 55 * MTA.HUD.Config.ScrRatio)

	surface.SetDrawColor(MTA.PrimaryColor)
	surface.DrawOutlinedRect(x, y, 400 * coef, 55 * MTA.HUD.Config.ScrRatio, 2)

	surface.SetTextColor(MTA.TextColor)
	surface.SetTextPos(x + 10 * coef, y + (4 * MTA.HUD.Config.ScrRatio))
	surface.SetFont("MTADrillFont")
	surface.DrawText("/// DRILL PROGRESS ///")

	local perc = vault:GetNWInt("DrillingProgress", 0)
	local margin = ((300 * coef) * perc) / 100
	surface.SetDrawColor(MTA.PrimaryColor)
	surface.DrawRect(x + 10 * coef, y + (35 * MTA.HUD.Config.ScrRatio), margin, 10)

	surface.SetTextPos(x + 15 * coef + margin, y + (25 * MTA.HUD.Config.ScrRatio))
	surface.DrawText(perc .. "%")

	cam.PopModelMatrix()
end