local tag = "mta_statuses"
local statuses = MTA_TABLE("Statuses")

statuses.Current = {}

function statuses.AddStatus(name, text, color, expire_time)
	statuses.Current[name] = {
		text = text:upper(),
		color = color or MTA.PrimaryColor,
		expire_time = expire_time,
	}
end

function statuses.RemoveStatus(name)
	statuses.Current[name] = nil
end

net.Receive(tag, function()
	local is_add = net.ReadBool()
	if is_add then
		local name = net.ReadString()
		local text = net.ReadString()
		local color = net.ReadColor()

		local expires = net.ReadBool()
		local expire_time = nil
		if expires then expire_time = net.ReadInt(32) end

		statuses.AddStatus(name, text, color, expire_time)
	else
		local name = net.ReadString()
		statuses.RemoveStatus(name)
	end
end)

surface.CreateFont("MTAStatusFont", {
	font = "Orbitron",
	size = 20 * MTA.HUD.Config.ScrRatio,
	weight = 600,
	shadow = false,
	extended = true,
})

local mat_vec = Vector()
local mat = Matrix()
local base_x, base_y = ScrW() / 4, ScrH() / 3
local padding = 15
local margin = 5
return function()
	mat_vec.x = (-25 * MTA.HUD.Config.ScrRatio) + (MTA.HUD.Vars.LastTranslateY * 2)
	mat_vec.y = (-25 * MTA.HUD.Config.ScrRatio) + (MTA.HUD.Vars.LastTranslateP * 3)

	mat:SetTranslation(mat_vec)

	cam.PushModelMatrix(mat)

		local i = 0
		for status_name, status_data in pairs(statuses.Current) do
			surface.SetFont("MTAStatusFont")

			local time_left = ""
			if status_data.expire_time then
				local diff = math.max(status_data.expire_time - CurTime(), 0)
				local s, ms = math.floor(diff), math.Round(math.fmod(diff, 1) * 1000)
				time_left = ("%d:%d"):format(s, ms)
				if ms == 0 and s == 0 then
					statuses.Current[status_name] = nil
					continue
				end
			end

			local text = status_data.expire_time and ("%s %s"):format(status_data.text, time_left):Trim() or status_data.text
			local tw, th = surface.GetTextSize(text)
			local x, y = base_x, base_y + i * (th + padding + margin)

			surface.SetDrawColor(MTA.BackgroundColor)
			surface.DrawRect(x - padding / 2, y - padding / 2, tw + padding, th + padding)

			surface.SetTextColor(status_data.color)
			surface.SetTextPos(x, y)
			surface.DrawText(text)

			surface.SetDrawColor(status_data.color)
			surface.DrawOutlinedRect(x - padding / 2, y - padding / 2, tw + padding, th + padding, 2)

			i = i + 1
		end
	cam.PopModelMatrix()
end