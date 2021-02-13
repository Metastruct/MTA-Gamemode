local tag = "mta_daily_missions"
local selected_mission_ids = {}
net.Receive(tag, function()
	selected_mission_ids = net.ReadTable()
end)

local screen_ratio = ScrH() / 1080

surface.CreateFont("MTAMissionsFont", {
	font = "Orbitron",
	size = 20 * screen_ratio,
	weight = 600,
	shadow = false,
	extended = true,
})

surface.CreateFont("MTAMissionsFontDesc", {
	font = "Alte Haas Grotesk",
	size = 20 * screen_ratio,
	weight = 600,
	shadow = false,
	extended = true,
})

surface.CreateFont("MTAMissionsFontTitle", {
	font = "Alte Haas Grotesk",
	size = 30 * screen_ratio,
	weight = 600,
	shadow = false,
	extended = true,
})

local orange_color = Color(244, 135, 2)
local white_color = Color(255, 255, 255)
local mat_vec = Vector()
return {
	Draw = function()
		local screen_ratio = MTAHud.Config.ScrRatio
		local offset_x = 300 * screen_ratio
		local width = 280 * screen_ratio
		local yaw = -EyeAngles().y
		local mat = Matrix()
		mat:SetField(2, 1, 0.10)

		mat_vec.x = (-25 * screen_ratio) + (MTAHud.Vars.LastTranslateY * 2)
		mat_vec.y = (-25 * screen_ratio) + (MTAHud.Vars.LastTranslateP * 3)

		mat:SetTranslation(mat_vec)
		cam.PushModelMatrix(mat)

		local margin = 5 * screen_ratio
		local title_x, title_y = ScrW() - offset_x, ScrH() / 2 - 50 * screen_ratio
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(title_x - margin, title_y - margin, width, 40 * screen_ratio)

		surface.SetDrawColor(orange_color)
		surface.DrawOutlinedRect(title_x - margin, title_y - margin, width, 40 * screen_ratio, 2)

		surface.SetTextColor(color_white)
		surface.SetTextPos(title_x + margin, title_y)
		surface.SetFont("MTAMissionsFontTitle")
		surface.DrawText("DAILY CHALLENGES")

		for i, mission_id in pairs(selected_mission_ids) do
			local mission = MTADailyChallenges.BaseChallenges[mission_id]
			local progress = MTADailyChallenges.GetProgress(LocalPlayer(), mission_id)
			if progress < mission.Completion then
				surface.SetFont("MTAMissionsFontDesc")
				local desc = mission.Description:upper()
				local x, y = ScrW() - offset_x, ScrH() / 2 + (60 * (i -1) * screen_ratio)
				surface.SetDrawColor(0, 0, 0, 150)
				surface.DrawRect(x - margin, y - margin, width, 50 * screen_ratio)

				surface.SetTextColor(white_color)
				surface.SetTextPos(x, y)
				surface.DrawText(desc)

				surface.SetFont("MTAMissionsFont")
				surface.SetTextColor(orange_color)
				surface.SetTextPos(x, y + 20 * screen_ratio)
				surface.DrawText(("%d/%d"):format(progress, mission.Completion))

				local points = mission.Reward .. "pts"
				local tw, _ = surface.GetTextSize(points)
				surface.SetTextPos(x + width - (tw + 10 * screen_ratio), y + 20 * screen_ratio)
				surface.DrawText(points)

				surface.SetDrawColor(orange_color)
				surface.DrawLine(x - margin, y + 45 * screen_ratio, x + width - margin, y + 45 * screen_ratio)
			end
		end

		cam.PopModelMatrix()
	end
}