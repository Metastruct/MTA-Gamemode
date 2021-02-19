local tag = "mta_intro"
local is_playing = false
local phases = {
	{
		duration = 30,
		lines = {
			"Welcome to MTA (Meta Theft Auto), in this gamemode your primary objective is to acquire reputation within the underworld of Union City.",
			"This reputation will essentially be your currency to purchase about everything here, it is commonly called \"Criminal Points\".",
			"Criminal points can be obtained in many ways, although almost all of them involve illegal activities.",
		},
		start = function()
			local points = {
				Vector (1202, 4556, 5653),
				Vector (1194, -317, 5653),
				Vector (-3996, -276, 5653),
				Vector (-4289, 1278, 5653),
				Vector (-4298, 4596, 5653),
			}

			local cur_index = 5
			local progress = 0
			hook.Add("CalcView", tag, function(ply, pos, angles, fov)
				local next_index = cur_index + 1 > #points and 1 or cur_index + 1
				local cur_point = points[cur_index]
				local next_point = points[next_index]

				local dir = (next_point - cur_point):GetNormalized()
				local cur_pos = cur_point + (dir * progress)

				local diff = next_point - cur_pos
				if math.abs(diff.x) < 100 and math.abs(diff.y) < 100 then
					cur_index = next_index
					progress = 0
				end

				local view = {
					origin = cur_pos,
					angles = dir:Angle(),
					fov = fov,
					drawviewer = true
				}

				progress = progress + 200 * FrameTime()
				return view
			end)

			hook.Add("MTAHUDShouldDraw", tag, function(element) return false end)
			hook.Add("HUDShouldDraw", tag, function(element) if element == "CHudChat" then return false end end)
			hook.Add("DeathNotice", tag, function() return false end)
			hook.Add("Move", tag, function() return true end)
		end,
		finish = function()
			hook.Remove("CalcView", tag)
		end
	},
	{
		duration = 20,
		lines = {
			"Among all the methods to get points, the most common one is breaking into safes.",
			"Safes are scattered around the map, and successfully breaking them will get you a whole lot of points.",
		},
		start = function()
			local vaults = ents.FindByClass("mta_vault")
			local cur_vault = vaults[math.random(#vaults)]
			if not IsValid(cur_vault) then return end

			timer.Create(tag, 5, 0, function()
				local vault = vaults[math.random(#vaults)]
				if IsValid(vault) then cur_vault = vault end
			end)

			hook.Add("CalcView", tag, function(ply, pos, angles, fov)
				local pos = cur_vault:GetPos() + cur_vault:GetForward() * 200 + cur_vault:GetUp() * 100
				local tr = {
					start = cur_vault:GetPos(),
					endpos = pos,
					filter = cur_vault,
				}

				return {
					origin = tr.Hit and tr.HitPos or pos,
					angles = (cur_vault:GetPos() - pos):Angle(),
					fov = fov,
					drawviewer = true
				}
			end)

			local red_color = Color(255, 0, 0)
			hook.Add("PreDrawOutlines", tag, function()
				red_color.a = 200 + math.sin(CurTime() * 5) * 150
				outline.Add(cur_vault, red_color, OUTLINE_MODE_BOTH, 4)
			end)
		end,
		finish = function()
			hook.Remove("CalcView", tag)
			hook.Remove("PreDrawOutlines", tag)
			timer.Remove(tag)
		end
	},
	{
		lines = {
			"Here's the gun dealer.",
		},
		start = function()
			local dealer_front = Vector (-142, 6986, 5634)
			local dealer_font_ang = Angle (0, 30, 0)
			hook.Add("CalcView", tag, function(ply, pos, angles, fov)
				return {
					origin = dealer_front,
					angles = dealer_font_ang,
					fov = fov,
					drawviewer = true
				}
			end)
		end,
		finish = function()
			hook.Remove("CalcView", tag)
		end
	},
	{
		lines = {
			"Here you can buy all kind of things with your acquired points such as guns, upgrades and skills.",
			"Weapons you buy are saved permanently, except if you choose to get a prestige.",
		},
		start = function()
			local dealer_inside = Vector (584, 7529, 5571)
			local dealer_inside_ang = Angle (0, -130, 0)
			local jukebox = ents.FindByClass("mta_jukebox")[1]
			local computer = ents.FindByClass("mta_skills_computer")[1]
			local dealer
			for _, ent in pairs(ents.FindByClass("lua_npc")) do
				if ent:GetNWBool("MTADealer") then
					dealer = ent
					break
				end
			end

			local red_color = Color(255, 0, 0)
			hook.Add("PreDrawOutlines", tag, function()
				red_color.a = 200 + math.sin(CurTime() * 5) * 150
				outline.Add({ jukebox, computer, dealer }, red_color, OUTLINE_MODE_BOTH, 4)
			end)

			hook.Add("CalcView", tag, function(ply, pos, angles, fov)
				return {
					origin = dealer_inside,
					angles = dealer_inside_ang,
					fov = fov,
					drawviewer = true
				}
			end)
		end,
		finish = function()
			hook.Remove("CalcView", tag)
			hook.Remove("PreDrawOutlines", tag)
		end
	},
	{
		duration = 10,
		lines = {
			"You're all set now. Good luck!",
		},
		start = function()
			hook.Add("CalcView", tag, function(ply, pos, angles, fov)
				local eye_pos = ply:EyePos()
				return {
					origin = eye_pos + ply:GetForward() * 50,
					angles = (eye_pos - (eye_pos + ply:GetForward())):Angle(),
					fov = fov,
					drawviewer = true
				}
			end)
		end,
		finish = function()
			hook.Remove("CalcView", tag)
			hook.Remove("MTAHUDShouldDraw", tag)
			hook.Remove("HUDShouldDraw", tag)
			hook.Remove("DeathNotice", tag)
			hook.Remove("Move", tag)
			is_playing = false
		end
	}
}

local cur_phase = phases[1]
local cur_index = 1

local cur_subtitle = phases[1].lines[1]
local cur_index_subtitle = 1

local subtitles_panel
local function create_subtitles()
	local panel = vgui.Create("DPanel")
	panel:Dock(BOTTOM)

	local margin = 10 * MTAHud.Config.ScrRatio
	local label = panel:Add("DLabel")
	label:SetTextColor(Color(255, 255, 255))
	label:SetFont("MTAIntroFont")
	label:SetText("")
	label:Dock(FILL)
	label:DockMargin(margin, margin, margin, margin)
	label:SetWrap(true)
	label:SetAutoStretchVertical(true)
	panel.Label = label

	local space_notif = vgui.Create("DLabel")
	space_notif:SetTextColor(Color(244, 135, 2))
	space_notif:SetFont("MTAIntroFont")
	space_notif:SetText("Press space to continue...")
	space_notif:SetTall(32 * MTAHud.Config.ScrRatio)

	function panel:Think()
		self:SetTall(self.Label:GetTall() + margin * 4)

		surface.SetFont("MTAIntroFont")
		local tw = surface.GetTextSize(space_notif:GetText())
		space_notif:SetWide(tw + margin * 2)
		space_notif:SetPos(self:GetWide() - (space_notif:GetWide() + margin), ScrH() - (self:GetTall() + (space_notif:GetTall() + margin)))
	end

	function panel:OnRemove()
		space_notif:Remove()
	end

	function panel:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 220)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(244, 135, 2)
		surface.DrawRect(0, 1, w, 3)
	end

	subtitles_panel = panel
end

local next_space = 0
local station
local url = "https://cdn.zeni.space/meta/song_8%2eogg"
local function init_intro()
	if is_playing then return end
	is_playing = true

	surface.CreateFont("MTAIntroFont", {
		font = "Alte Haas Grotesk",
		size = 32 * MTAHud.Config.ScrRatio,
		weight = 600,
		shadow = false,
		extended = true,
	})

	cur_phase.start() -- first one

	sound.PlayURL(url, "noblock", function(music)
		if IsValid(music) then
			station = music
			station:EnableLooping(true)
			station:Play()
		end
	end)

	hook.Add("Think", tag, function()
		if not IsValid(subtitles_panel) then
			create_subtitles()
		end

		subtitles_panel.Label:SetText(cur_subtitle or "")
		if input.IsKeyDown(KEY_SPACE) and CurTime() >= next_space then
			next_space = CurTime() + 0.5

			cur_index_subtitle = cur_index_subtitle + 1
			if cur_index_subtitle > #cur_phase.lines then
				cur_phase.finish()
				cur_index = cur_index + 1
				cur_phase = phases[cur_index]
				if not cur_phase then
					if IsValid(subtitles_panel) then
						subtitles_panel:Remove()
					end

					if IsValid(station) then
						station:Stop()
					end

					hook.Remove("Think", tag)
					return
				end

				cur_phase.start()
				cur_index_subtitle = 1
				cur_subtitle = cur_phase.lines[cur_index_subtitle]
			else
				cur_subtitle = cur_phase.lines[cur_index_subtitle]
			end
		end
	end)
end

hook.Add("InitPostEntity", tag, function()
	if cookie.GetString(tag, "0") == "0" then
		init_intro()
		cookie.Set(tag, "1")
	end
end)

concommand.Add("mta_intro", init_intro, nil, "Plays the MTA intro / tutorial")