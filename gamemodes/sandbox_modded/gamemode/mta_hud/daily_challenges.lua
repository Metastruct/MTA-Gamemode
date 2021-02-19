local tag = "mta_daily_missions"

local selected_mission_ids = {}
local all_done = false
local function check_completed_state()
	all_done = true
	for _, mission_id in pairs(selected_mission_ids) do
		local mission = MTADailyChallenges.BaseChallenges[mission_id]
		local progress = MTADailyChallenges.GetProgress(LocalPlayer(), mission_id)
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
	size = 20 * MTAHud.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

surface.CreateFont("MTAMissionsFontDesc", {
	font = "Alte Haas Grotesk",
	size = 20 * MTAHud.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

surface.CreateFont("MTAMissionsFontTitle", {
	font = "Alte Haas Grotesk",
	size = 30 * MTAHud.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

local orange_color = Color(244, 135, 2)
local white_color = Color(255, 255, 255)
local mat_vec = Vector()
local mat = Matrix()

local next_check = 0
return function()
	if all_done then return end

	if CurTime() >= next_check then
		check_completed_state()
		next_check = CurTime() + 2
	end

	local offset_x = 300 * MTAHud.Config.ScrRatio
	local width = 280 * MTAHud.Config.ScrRatio

	mat:SetField(2, 1, 0.10)

	mat_vec.x = (-25 * MTAHud.Config.ScrRatio) + (MTAHud.Vars.LastTranslateY * 2)
	mat_vec.y = (-25 * MTAHud.Config.ScrRatio) + (MTAHud.Vars.LastTranslateP * 3)

	mat:SetTranslation(mat_vec)

	cam.PushModelMatrix(mat)
		local margin = 5 * MTAHud.Config.ScrRatio
		local title_x, title_y = ScrW() - offset_x, ScrH() / 2 - 50 * MTAHud.Config.ScrRatio
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(title_x - margin, title_y - margin, width, 40 * MTAHud.Config.ScrRatio)

		surface.SetDrawColor(orange_color)
		surface.DrawOutlinedRect(title_x - margin, title_y - margin, width, 40 * MTAHud.Config.ScrRatio, 2)

		surface.SetTextColor(color_white)
		surface.SetTextPos(title_x + margin, title_y)
		surface.SetFont("MTAMissionsFontTitle")
		surface.DrawText("DAILY CHALLENGES")

		local i = 1
		for _, mission_id in pairs(selected_mission_ids) do
			local mission = MTADailyChallenges.BaseChallenges[mission_id]
			local progress = MTADailyChallenges.GetProgress(LocalPlayer(), mission_id)
			if progress < mission.Completion then
				surface.SetFont("MTAMissionsFontDesc")
				local desc = mission.Description:upper()
				local x, y = ScrW() - offset_x, ScrH() / 2 + (60 * (i -1) * MTAHud.Config.ScrRatio)
				surface.SetDrawColor(0, 0, 0, 150)
				surface.DrawRect(x - margin, y - margin, width, 50 * MTAHud.Config.ScrRatio)

				surface.SetTextColor(white_color)
				surface.SetTextPos(x, y)
				surface.DrawText(desc)

				surface.SetFont("MTAMissionsFont")
				surface.SetTextColor(orange_color)
				surface.SetTextPos(x, y + 20 * MTAHud.Config.ScrRatio)
				surface.DrawText(("%d/%d"):format(progress, mission.Completion))

				local points = mission.Reward .. "pts"
				local tw, _ = surface.GetTextSize(points)
				surface.SetTextPos(x + width - (tw + 10 * MTAHud.Config.ScrRatio), y + 20 * MTAHud.Config.ScrRatio)
				surface.DrawText(points)

				surface.SetDrawColor(orange_color)
				surface.DrawLine(x - margin, y + 45 * MTAHud.Config.ScrRatio, x + width - margin, y + 45 * MTAHud.Config.ScrRatio)

				i = i + 1
			end
		end
	cam.PopModelMatrix()
end