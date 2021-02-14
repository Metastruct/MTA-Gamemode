local NET_LEADERBOARD = "MTA_LEADERBOARD"

if SERVER then
	local top_20 = {}

	util.AddNetworkString(NET_LEADERBOARD)

	local function send_top_20(ply)
		net.Start(NET_LEADERBOARD)
		net.WriteTable(top_20)
		net.Send(ply)
	end

	net.Receive(NET_LEADERBOARD, function(_, ply)
		timer.Simple(0, function() send_top_20(ply) end)
	end)

	local function refresh_top_20()
		if not _G.co or not _G.db then return end

		co(function()
			local ret = db([[SELECT * FROM mta_stats ORDER BY prestige_level DESC LIMIT 20]])
			if not ret then return end

			top_20 = {}
			for _, data in pairs(ret) do
				table.insert(top_20, { Id = data.id, Level = data.prestige_level })
			end
		end)
	end

	timer.Create(NET_LEADERBOARD, 25, 0, refresh_top_20)
	hook.Add("InitPostEntity", NET_LEADERBOARD, refresh_top_20)
end

if CLIENT then
	local top_20 = {
		{ Name = "Loading...", Level = 0 }
	}

	local function get_player_name(account_id, callback)
		local steamid_64 = util.SteamID64FromAccountID(tonumber(account_id))
		local ply = player.GetBySteamID64(steamid_64)
		if IsValid(ply) then
			local name = UndecorateNick and UndecorateNick(ply:Nick()) or ply:Nick()
			callback(name)
			return
		end

		steamworks.RequestPlayerInfo(steamid_64, callback)
	end

	net.Receive(NET_LEADERBOARD, function()
		local tbl = net.ReadTable()
		top_20 = {}

		local count = table.Count(tbl)
		local req_count = 0
		for _, data in pairs(tbl) do
			get_player_name(data.Id, function(name)
				table.insert(top_20, { Name = name, Level = tostring(data.Level) })
				req_count = req_count + 1
				if req_count == count then
					table.sort(top_20, function(a, b) return tonumber(a.Level) > tonumber(b.Level) end)
				end
			end)
		end
	end)

	timer.Create(NET_LEADERBOARD, 60, 0, function()
		net.Start(NET_LEADERBOARD)
		net.SendToServer()
	end)

	hook.Add("InitPostEntity", NET_LEADERBOARD, function()
		net.Start(NET_LEADERBOARD)
		net.SendToServer()
	end)

	local orange_color = Color(244, 135, 2)
	local black_color = Color(0, 0, 0, 150)
	local orange_color = Color(244, 135, 2)
	local white_color = Color(255, 255, 255)
	local ratio_w, ratio_h = ScrW() / 2560, ScrH() / 1440

	local DealerIcon = Material("vgui/mta_hud/dealer_icon.png")
	local VaultIcon = Material("vgui/mta_hud/vault_icon.png")
	local CarDealerIcon = Material("vgui/mta_hud/garage_icon.png")
	local VehicleIcon = Material("vgui/mta_hud/vehicle_icon.png")
	local UnknownRoleIcon = Material("vgui/mta_hud/business_icon.png")

	local IconSize = 30 * ratio_h
	local IconOffset = IconSize * 0.5

	-- Scale it up a bit since it looks smaller then the other icons
	local VehicleIconSize = IconSize * 1.5
	local VehicleIconOffset = IconOffset * 1.5
	local PlayerTriangle = {
		{ x = 0, y = 13 },
		{ x = -7, y = 18 },
		{ x = 0, y = 0 },
		{ x = 7, y = 18 }
	}

	surface.CreateFont("MTAMenuPlayerFont", {
		font = "Alte Haas Grotesk",
		size = 40 * ratio_h,
		weight = 600,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTALegendFont", {
		font = "Alte Haas Grotesk",
		size = 25 * ratio_h,
		weight = 600,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTALeaderboardFont", {
		font = "Orbitron",
		size = 13,
		weight = 300,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTAMenuHeaderFont", {
		font = "Orbitron",
		size = 40 * ratio_h,
		weight = 600,
		shadow = false,
		extended = true,
	})

	-- MAP TAB
	do
		local MAP_TAB = {}
		function MAP_TAB:Init() end

		local MapZoom = 400 * ratio_h
		local MapImage = Material("vgui/mta_hud/maps/rp_unioncity")
		function MAP_TAB:GetMapTexturePos(pos)
			local pxD = 1024 / 2
			local pyD = 1024 / 2

			local rx = -pos.y * (-pxD / -16384) + pxD
			local ry = pos.x * ((1024 - pyD) / -16384) + pyD

			return rx, ry
		end

		function MAP_TAB:GetMapDrawPos(origin, pos)
			local scale = MapZoom / 512

			local diff = (origin - pos) / scale

			local pxD = self:GetTall() / 2
			local pyD = self:GetTall() / 2

			local rx = diff.y * (-pxD / -16384) + pxD
			local ry = -diff.x * ((self:GetTall() - pyD) / -16384) + pyD

			return rx, ry
		end

		function MAP_TAB:Rotate(ox, oy, px, py, angle)
			local qx = ox + math.cos(angle) * (px - ox) - math.sin(angle) * (py - oy)
			local qy = oy + math.sin(angle) * (px - ox) + math.cos(angle) * (py - oy)
			return qx, qy
		end

		function MAP_TAB:RotatePoly(poly, angle, ox, oy)
			local rotated = {}

			for k, v in pairs(poly) do
				local rx, ry = self:Rotate(ox, oy, v.x, v.y, math.rad(angle))

				rotated[k] = { x = rx, y = ry }
			end

			return rotated
		end

		function MAP_TAB:TranslatePoly(poly, ox, oy)
			local translated = {}

			for k, v in pairs(poly) do
				translated[k] = { x = ox + v.x, y = oy + v.y }
			end

			return translated
		end

		local FindByClass = ents.FindByClass

		-- This is icons based of the npc role
		local KnownNpcIcons = {
			["dealer"] = DealerIcon,
			["car_dealer"] = CarDealerIcon,
		}

		-- If you want to blacklist your npc from the map, perhaps "secret" npc
		local NpcBlacklist = {
			["_bad"] = true, -- Default return for npc without role
		}

		function MAP_TAB:DrawMapObjects(origin)
			surface.SetMaterial(VaultIcon)
			for _, vault in ipairs(FindByClass("mta_vault")) do
				if IsValid(vault) then
					local px, py = self:GetMapDrawPos(origin, vault:GetPos())
					surface.DrawTexturedRect(px - IconOffset, py - IconOffset, IconSize, IconSize)
				end
			end

			for _, npc in ipairs(FindByClass("lua_npc")) do
				if IsValid(npc) then
					local role = npc:GetNWString("npc_role", "_bad")
					if not NpcBlacklist[role] then
						-- Grab the npc role icon or default to "unknown role" to always display an npc with a role
						local icon = KnownNpcIcons[role] or UnknownRoleIcon
						local px, py = self:GetMapDrawPos(origin, npc:GetPos())
						surface.SetMaterial(icon)
						surface.DrawTexturedRect(px - IconOffset, py - IconOffset, IconSize, IconSize)
					end
				end
			end

			surface.SetDrawColor(orange_color)
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() then
					local yaw = ply:EyeAngles().yaw
					local px, py = self:GetMapDrawPos(origin, ply:GetPos())
					local tri = self:TranslatePoly(PlayerTriangle, px, py - 10)
					tri = self:RotatePoly(tri, -yaw, px, py)
					draw.NoTexture()
					surface.DrawPoly(tri)
				end
			end
			surface.SetDrawColor(white_color)

			-- Draw your vehicle on the map
			if MTACars then
				local curVehicle = MTACars.CurrentVehicle
				if IsValid(curVehicle) and curVehicle:GetDriver() ~= LocalPlayer() then
					local px, py = self:GetMapDrawPos(origin, curVehicle:GetPos())
					surface.SetMaterial(VehicleIcon)
					surface.DrawTexturedRect(px - VehicleIconOffset, py - VehicleIconOffset, VehicleIconSize, VehicleIconSize)
				end
			end
		end

		function MAP_TAB:Paint(w, h)
			local lp_pos = LocalPlayer():GetPos()
			local yaw = -EyeAngles().y

			local rx, ry = self:GetMapTexturePos(lp_pos)
			local startU = (rx - MapZoom) / 1024
			local startV = (ry - MapZoom) / 1024
			local endU = (rx + MapZoom) / 1024
			local endV = (ry + MapZoom) / 1024

			surface.SetMaterial(MapImage)
			surface.SetDrawColor(255, 255, 255, 180)
			surface.DrawTexturedRectUV(0, 0, h, h, startU, startV, endU, endV)

			self:DrawMapObjects(lp_pos)

			local tri = self:TranslatePoly(PlayerTriangle, h / 2, h / 2 - 10)
			tri = self:RotatePoly(tri, yaw, h / 2, h / 2)
			draw.NoTexture()
			surface.DrawPoly(tri)

			surface.SetDrawColor(244, 135, 2)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
		end

		vgui.Register("mta_map", MAP_TAB, "DPanel")
	end

	-- leaderboard
	do
		local LEADERBOARD_TAB = {}
		function LEADERBOARD_TAB:Init() end

		function LEADERBOARD_TAB:Paint(w, h)
			surface.SetDrawColor(black_color)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(orange_color)
			surface.DrawOutlinedRect(0, 0, w, h)

			-- header
			do
				surface.DrawRect(0, 0, w, 25)

				surface.SetTextColor(white_color)
				surface.SetFont("DermaLarge")
				surface.SetTextPos(7, -2)
				surface.DrawText("LEADERBOARD")
			end

			do -- column headers
				surface.DrawLine(0, 45, w, 45)
				surface.DrawLine(w / 3 * 2, 25, w / 3 * 2, h)

				surface.SetFont("MTALeaderboardFont")

				surface.SetTextPos(7, 28)
				surface.DrawText("Name")

				surface.SetTextPos(w / 3 * 2 + 10, 28)
				surface.DrawText("Prestige")
			end

			do -- columns
				for i, data in ipairs(top_20 or {}) do
					surface.SetTextPos(7, 40 + (12 * i))
					surface.DrawText(data.Name)

					surface.SetTextPos(w / 3 * 2 + 10, 40 + (12 * i))
					surface.DrawText(data.Level)
				end
			end
		end

		vgui.Register("mta_leaderboard", LEADERBOARD_TAB, "DPanel")
	end

	local PANEL = {}
	function PANEL:Init()
		self:SetSize(ScrW() - 200 * ratio_w, ScrH() - 200 * ratio_h)
		self:SetPos(100 * ratio_w, 100 * ratio_h)

		-- ply stuff
		do
			local ply_panel = self:Add("DPanel")
			ply_panel:Dock(LEFT)
			ply_panel:SetWide(250 * ratio_w)
			function ply_panel:Paint(w, h)
				surface.SetDrawColor(orange_color)
				surface.DrawRect(w - 2, 0, w, h)
			end

			local av = ply_panel:Add("AvatarImage")
			av:Dock(TOP)
			av:DockMargin(10 * ratio_w, 10 * ratio_h, 10 * ratio_w, 10 * ratio_h)
			av:SetSize(ply_panel:GetWide() - 20 * ratio_w, ply_panel:GetWide() - 20 * ratio_h)
			av:SetPlayer(LocalPlayer(), 512)

			local sep = ply_panel:Add("DPanel")
			sep:Dock(TOP)
			sep:SetTall(2)
			function sep:Paint(w, h)
				surface.SetDrawColor(orange_color)
				surface.DrawRect(0, 0, w, h)
			end

			local function add_ply_info(text)
				local lbl = ply_panel:Add("DLabel")
				lbl:Dock(TOP)
				lbl:DockMargin(10 * ratio_w, 10 * ratio_h, 10 * ratio_w, 0 * ratio_h)
				lbl:SetTall(35 * ratio_h)
				lbl:SetFont("MTAMenuPlayerFont")
				lbl:SetTextColor(white_color)
				lbl:SetText(text)
			end

			add_ply_info(EasyChat and EasyChat.GetProperNick(LocalPlayer()) or LocalPlayer():Nick())
			add_ply_info(("Prestige %d"):format(MTA.GetPlayerStat("prestige_level")))
			add_ply_info(("%d CPs"):format(MTA.GetPlayerStat("points")))

			if LocalPlayer().GetCoins then
				add_ply_info(("%d c"):format(LocalPlayer():GetCoins()))
			end
		end

		local sheet = self:Add("DPropertySheet")
		sheet:Dock(FILL)
		sheet:DockMargin(0, 50 * ratio_h, 5 * ratio_w, 5 * ratio_h)
		function sheet:Paint() end

		do
			local map_panel = vgui.Create("DPanel")
			local map = map_panel:Add("mta_map")
			function map_panel:Paint(w, h)
				surface.SetDrawColor(0, 0, 0, 150)
				surface.DrawRect(0, 0, w, h)
			end

			function map_panel:DrawLegend(icon, text, y)
				local base_x = map:GetWide()
				surface.SetDrawColor(white_color)
				surface.SetMaterial(icon)
				surface.DrawTexturedRect(base_x + (10 * ratio_w), y * ratio_h, IconSize, IconSize)

				surface.SetFont("MTALegendFont")
				local _, th = surface.GetTextSize(text)

				surface.SetTextColor(white_color)
				surface.SetTextPos(base_x + IconSize + (20 * ratio_w), (y * ratio_h) + (IconSize / 2 - th / 2))
				surface.DrawText(text)
			end

			function map_panel:DrawArrowLegend(text, color, y)
				local base_x = map:GetWide()
				local tri = map:TranslatePoly(PlayerTriangle, base_x + (25 * ratio_w), (y * ratio_h) + (10 * ratio_h))

				surface.SetDrawColor(color)
				draw.NoTexture()
				surface.DrawPoly(tri)

				surface.SetFont("MTALegendFont")
				local _, th = surface.GetTextSize(text)

				surface.SetTextColor(white_color)
				surface.SetTextPos(base_x + IconSize + (20 * ratio_w), (y * ratio_h) + (IconSize / 2 - th / 2))
				surface.DrawText(text)
			end

			function map_panel:PaintOver(w, h)
				self:DrawArrowLegend("You", white_color, 0)
				self:DrawArrowLegend("Other Players", orange_color, 60)
				self:DrawLegend(DealerIcon, "Gun Dealer", 120)
				self:DrawLegend(CarDealerIcon, "Car Dealer", 180)
				self:DrawLegend(VehicleIcon, "Your Vehicle", 240)
				self:DrawLegend(VaultIcon, "Vault", 300)
				self:DrawLegend(UnknownRoleIcon, "Unknown Business", 360)
			end

			function map_panel:Think()
				map:SetWide(self:GetWide() / 2)
				map:SetTall(self:GetTall())
				map:SetPos(0, 0)
			end

			local sheet_data = sheet:AddSheet("Map", map_panel)
			sheet_data.Panel:SetWide(sheet:GetWide())
		end

		--sheet:AddSheet("Inventory", vgui.Create("DPanel"))
		sheet:AddSheet("Leaderboard", vgui.Create("mta_leaderboard"))
	end

	function PANEL:Think()
		if input.IsMouseDown(MOUSE_RIGHT) then
			gui.EnableScreenClicker(true)
		end
	end

	function PANEL:Paint(w, h)
		Derma_DrawBackgroundBlur(self, 0)

		surface.SetDrawColor(0, 0, 0, 220)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(orange_color)
		surface.DrawOutlinedRect(0, 0, w, h, 2)

		local header_text = GetHostName()
		local ply_info_panel_width = 250 * ratio_w
		surface.SetFont("MTAMenuHeaderFont")
		surface.SetTextColor(255, 255, 255, 255)
		local tw, th = surface.GetTextSize(header_text)
		surface.SetTextPos(ply_info_panel_width + ((self:GetWide() - ply_info_panel_width) / 2 - tw / 2), 15 * ratio_h)
		surface.DrawText(header_text)
	end

	vgui.Register("mta_menu", PANEL, "DPanel")

	local menu
	function GM:OnSpawnMenuOpen()
		if IsValid(menu) then
			menu:Remove()
			menu = nil
		end
		menu = vgui.Create("mta_menu")
		return false
	end

	function GM:OnSpawnMenuClose()
		gui.EnableScreenClicker(false)
		if IsValid(menu) then
			menu:Remove()
			menu = nil
		end
		return false
	end

	function GM:MTAHUDShouldDraw(element)
		if menu then return false end
	end
end