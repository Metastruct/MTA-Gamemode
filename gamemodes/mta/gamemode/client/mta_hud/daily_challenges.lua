local tag = "mta_daily_missions"

local selected_mission_ids = {}
local all_done = false
local function check_completed_state()
	all_done = true
	for _, mission_id in pairs(selected_mission_ids) do
		local mission = MTA.DailyChallenges.BaseChallenges[mission_id]
		local progress = MTA.DailyChallenges.GetProgress(LocalPlayer(), mission_id)
		if progress < mission.Completion then
			all_done = false
			return
		end
	end
end

net.Receive(tag, function()
	selected_mission_ids = net.ReadTable()
	check_completed_state()
end)

surface.CreateFont("MTAMissionsFont", {
	font = "Orbitron",
	size = 20 * MTA.HUD.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

surface.CreateFont("MTAMissionsFontDesc", {
	font = "Alte Haas Grotesk",
	size = 20 * MTA.HUD.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

surface.CreateFont("MTAMissionsFontTitle", {
	font = "Alte Haas Grotesk",
	size = 30 * MTA.HUD.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

local mat_vec = Vector()
local mat = Matrix()

local next_check = 0
return function()
	if all_done then return end

	if CurTime() >= next_check then
		check_completed_state()
		next_check = CurTime() + 2
	end

	local offset_x = 300 * MTA.HUD.Config.ScrRatio
	local width = 280 * MTA.HUD.Config.ScrRatio

	mat:SetField(2, 1, 0.10)

	mat_vec.x = (-25 * MTA.HUD.Config.ScrRatio) + (MTA.HUD.Vars.LastTranslateY * 2)
	mat_vec.y = (-25 * MTA.HUD.Config.ScrRatio) + (MTA.HUD.Vars.LastTranslateP * 3)

	mat:SetTranslation(mat_vec)

	cam.PushModelMatrix(mat)
		local margin = 5 * MTA.HUD.Config.ScrRatio
		local title_x, title_y = ScrW() - offset_x, ScrH() / 2 - 50 * MTA.HUD.Config.ScrRatio
		surface.SetDrawColor(MTA.BackgroundColor)
		surface.DrawRect(title_x - margin, title_y - margin, width, 40 * MTA.HUD.Config.ScrRatio)

		surface.SetDrawColor(MTA.PrimaryColor)
		surface.DrawOutlinedRect(title_x - margin, title_y - margin, width, 40 * MTA.HUD.Config.ScrRatio, 2)

		surface.SetTextColor(MTA.TextColor)
		surface.SetTextPos(title_x + margin, title_y)
		surface.SetFont("MTAMissionsFontTitle")
		surface.DrawText("DAILY CHALLENGES")

		local i = 1
		for _, mission_id in pairs(selected_mission_ids) do
			local mission = MTA.DailyChallenges.BaseChallenges[mission_id]
			local progress = MTA.DailyChallenges.GetProgress(LocalPlayer(), mission_id)
			if progress < mission.Completion then
				surface.SetFont("MTAMissionsFontDesc")
				local desc = mission.Description:upper()
				local x, y = ScrW() - offset_x, ScrH() / 2 + (60 * (i -1) * MTA.HUD.Config.ScrRatio)
				surface.SetDrawColor(MTA.BackgroundColor)
				surface.DrawRect(x - margin, y - margin, width, 50 * MTA.HUD.Config.ScrRatio)

				surface.SetTextColor(MTA.TextColor)
				surface.SetTextPos(x, y)
				surface.DrawText(desc)

				surface.SetFont("MTAMissionsFont")
				surface.SetTextColor(MTA.PrimaryColor)
				surface.SetTextPos(x, y + 20 * MTA.HUD.Config.ScrRatio)
				surface.DrawText(("%d/%d"):format(progress, mission.Completion))

				local points = mission.Reward .. "pts"
				local tw, _ = surface.GetTextSize(points)
				surface.SetTextPos(x + width - (tw + 10 * MTA.HUD.Config.ScrRatio), y + 20 * MTA.HUD.Config.ScrRatio)
				surface.DrawText(points)

				surface.SetDrawColor(MTA.PrimaryColor)
				surface.DrawLine(x - margin, y + 45 * MTA.HUD.Config.ScrRatio, x + width - margin, y + 45 * MTA.HUD.Config.ScrRatio)

				i = i + 1
			end
		end
	cam.PopModelMatrix()
end