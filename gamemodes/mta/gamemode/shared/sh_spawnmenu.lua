local NET_LEADERBOARD = "MTA_LEADERBOARD"

local NET_APARTMENTS = "MTA_APARTMENTS_MENU"

if SERVER then
	local top_20 = {}

	util.AddNetworkString(NET_LEADERBOARD)
	util.AddNetworkString(NET_APARTMENTS)

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

	net.Receive(NET_APARTMENTS, function(_, ply)
		if MTA.IsWanted(ply) then
			return
		end

		local apt = net.ReadString()
		MTA.Apartments.SendPlayerTo(ply, apt)
	end)
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

	local DealerIcon = Material("vgui/mta_hud/dealer_icon.png")
	local VaultIcon = Material("vgui/mta_hud/vault_icon.png")
	local CarDealerIcon = Material("vgui/mta_hud/garage_icon.png")
	local VehicleIcon = Material("vgui/mta_hud/vehicle_icon.png")
	local HardwareIcon = Material("vgui/mta_hud/hardware_icon.png")
	local HotdogIcon = Material("vgui/mta_hud/hotdog_icon.png")
	local UnknownRoleIcon = Material("vgui/mta_hud/business_icon.png")

	local IconSize = 30
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
		font = "Open Sans",
		size = 20,
		weight = 500,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTAMenuPlayerFont2", {
		font = "Alte Haas Grotesk",
		size = 20,
		weight = 500,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTALegendFont", {
		font = "Open Sans",
		size = 15,
		weight = 500,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTALeaderboardFont", {
		font = "Open Sans",
		size = 20,
		weight = 300,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTAMenuHeaderFont", {
		font = "Orbitron",
		size = 40,
		weight = 600,
		shadow = false,
		extended = true,
	})

	-- MAP TAB
	do
		local MAP_TAB = {}
		function MAP_TAB:Init() end

		local MapZoom = 200
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
					local icon = MTA.Icons.GetIconMaterial(npc)
					if not icon then continue end

					local px, py = self:GetMapDrawPos(origin, npc:GetPos())
					surface.SetMaterial(icon)
					surface.DrawTexturedRect(px - IconOffset, py - IconOffset, IconSize, IconSize)
				end
			end

			surface.SetDrawColor(MTA.PrimaryColor)
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					local yaw = ply:EyeAngles().yaw
					local px, py = self:GetMapDrawPos(origin, ply:GetPos())
					local tri = self:TranslatePoly(PlayerTriangle, px, py - 10)
					tri = self:RotatePoly(tri, -yaw, px, py)
					draw.NoTexture()
					surface.DrawPoly(tri)
				end
			end
			surface.SetDrawColor(MTA.TextColor)

			-- Draw your vehicle on the map
			if MTA.Cars then
				local curVehicle = MTA.Cars.CurrentVehicle
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

			surface.SetDrawColor(MTA.PrimaryColor)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
		end

		vgui.Register("mta_map", MAP_TAB, "DPanel")
	end

	-- leaderboard
	do
		local LEADERBOARD_TAB = {}
		function LEADERBOARD_TAB:Init() end

		function LEADERBOARD_TAB:Paint(w, h)
			surface.SetDrawColor(MTA.BackgroundColor)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(MTA.PrimaryColor)
			surface.DrawOutlinedRect(0, 0, w, h)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

			-- header
			do
				surface.DrawRect(0, 0, w, 32)

				surface.SetTextColor(MTA.TextColor)
				surface.SetFont("DermaLarge")
				surface.SetTextPos(7, 1)
				surface.DrawText("LEADERBOARD")
			end

			do -- column headers
				surface.DrawLine(0, 59, w, 59)
				surface.DrawLine(0, 60, w, 60)
				surface.DrawLine(w / 3 * 2, 25, w / 3 * 2, h)
				surface.DrawLine(w / 3 * 2 + 1, 25, w / 3 * 2 + 1, h)

				surface.SetFont("MTALeaderboardFont")

				surface.SetTextPos(7, 36)
				surface.DrawText("Name")

				surface.SetTextPos(w / 3 * 2 + 10, 36)
				surface.DrawText("Prestige")
			end

			do -- columns
				for i, data in ipairs(top_20 or {}) do
					surface.SetTextPos(7, 45 + (19 * i))
					surface.DrawText(data.Name)

					surface.SetTextPos(w / 3 * 2 + 10, 45 + (19 * i))
					surface.DrawText(data.Level)
				end
			end
		end

		vgui.Register("mta_leaderboard", LEADERBOARD_TAB, "DPanel")
	end

	-- Apartments tab
	do
		local APARTMENTS_TAB = {}
		function APARTMENTS_TAB:Init() end

		function APARTMENTS_TAB:Paint(w, h)
			surface.SetDrawColor(MTA.BackgroundColor)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(MTA.PrimaryColor)
			surface.DrawOutlinedRect(0, 0, w, h)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2)

			surface.SetDrawColor(MTA.TextColor)
			surface.SetFont("MTAMenuHeaderFont")
			surface.SetTextPos(15, 15)
			surface.DrawText("Apartments")
		end

		vgui.Register("mta_apartments_tab", APARTMENTS_TAB, "DPanel")
	end

	local PANEL = {}
	function PANEL:Init()
		self.NoCleanup = true -- for vgui_cleanup

		local width, height = 900, 600
		self:SetSize(width, height)
		self:SetPos(ScrW() / 2 - width / 2, ScrH() / 2 - height / 2)

		-- ply stuff
		do
			local ply_panel = self:Add("DPanel")
			ply_panel:Dock(LEFT)
			ply_panel:SetWide(165)
			function ply_panel:Paint(w, h)
				surface.SetDrawColor(MTA.PrimaryColor)
				surface.DrawRect(w - 2, 0, w, h)
			end

			local av = ply_panel:Add("AvatarImage")
			av:Dock(TOP)
			av:DockMargin(2, 2, 2, 2)
			av:SetSize(ply_panel:GetWide(), ply_panel:GetWide())
			av:SetPlayer(LocalPlayer(), 512)

			local function add_sep(margin_top)
				local sep = ply_panel:Add("DPanel")
				sep:Dock(TOP)
				sep:SetTall(2)

				if margin_top then
					sep:DockMargin(0, margin_top, 0, 0)
				end

				function sep:Paint(w, h)
					surface.SetDrawColor(MTA.PrimaryColor)
					surface.DrawRect(0, 0, w, h)
				end
			end

			local function add_ply_info(text, font)
				local lbl = ply_panel:Add("DLabel")
				lbl:Dock(TOP)
				lbl:DockMargin(10, 5, 10, 0)
				lbl:SetTall(20)
				lbl:SetFont(font)
				lbl:SetTextColor(MTA.TextColor)
				lbl:SetText(text)
			end

			add_sep()

			local nick = EasyChat and EasyChat.GetProperNick(LocalPlayer()) or LocalPlayer():Nick()
			add_ply_info(("%s / PRTG  %d"):format(nick, MTA.GetPlayerStat("prestige_level")), "MTAMenuPlayerFont2")

			local wealth = ("%d CPs"):format(MTA.GetPlayerStat("points"))
			add_ply_info(wealth, "MTAMenuPlayerFont")

			if LocalPlayer().GetCoins then
				wealth = ("%s coins"):format(string.NiceNumber(LocalPlayer():GetCoins()))
				add_ply_info(wealth, "MTAMenuPlayerFont")
			end

			add_sep(10)

			add_ply_info("DAMAGE", "MTAMenuPlayerFont2")
			local multiplier = MTA.GetPlayerStat("damage_multiplier")
			add_ply_info(("lvl. %d"):format(multiplier), "MTAMenuPlayerFont")
			add_ply_info(("%d%%"):format((100 + multiplier) * 2), "MTAMenuPlayerFont")

			add_sep(10)

			add_ply_info("RESISTANCE", "MTAMenuPlayerFont2")
			multiplier = MTA.GetPlayerStat("defense_multiplier")
			add_ply_info(("lvl. %d"):format(multiplier), "MTAMenuPlayerFont")
			add_ply_info(("%.2f%%"):format(multiplier * 0.75), "MTAMenuPlayerFont")

			add_sep(10)

			add_ply_info("HEALING", "MTAMenuPlayerFont2")
			multiplier = MTA.GetPlayerStat("healing_multiplier")
			add_ply_info(("lvl. %d"):format(multiplier), "MTAMenuPlayerFont")
			add_ply_info(("%dHPs / 10s"):format(math.ceil((multiplier * 1.6) / 2)), "MTAMenuPlayerFont")
		end

		local sheet = self:Add("DPropertySheet")
		sheet:Dock(FILL)
		sheet:DockMargin(0, 0, 0, 0)
		function sheet:Paint(w) end
		self.Sheets = sheet

		local function tab_paint(self, w, h)
			if sheet:GetActiveTab() ~= self then return end

			surface.SetDrawColor(MTA.BackgroundColor)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(MTA.TextColor)
			surface.DrawLine(0, 0, w, 0)
			surface.DrawLine(0, 1, w, 1)
		end

		do
			local map_panel = vgui.Create("DPanel")
			local map = map_panel:Add("mta_map")
			function map_panel:Paint(w, h)
				surface.SetDrawColor(MTA.BackgroundColor)
				surface.DrawRect(0, 0, w, h)
			end

			function map_panel:DrawLegend(icon, text, y)
				local base_x = map:GetWide()
				surface.SetDrawColor(MTA.TextColor)
				surface.SetMaterial(icon)
				surface.DrawTexturedRect(base_x + 10, y, IconSize, IconSize)

				surface.SetFont("MTALegendFont")
				local _, th = surface.GetTextSize(text)

				surface.SetTextColor(MTA.TextColor)
				surface.SetTextPos(base_x + IconSize + 20, y + (IconSize / 2 - th / 2))
				surface.DrawText(text)
			end

			function map_panel:DrawArrowLegend(text, color, y)
				local base_x = map:GetWide()
				local tri = map:TranslatePoly(PlayerTriangle, base_x + 25, y)

				surface.SetDrawColor(color)
				draw.NoTexture()
				surface.DrawPoly(tri)

				surface.SetFont("MTALegendFont")
				local _, th = surface.GetTextSize(text)

				surface.SetTextColor(MTA.TextColor)
				surface.SetTextPos(base_x + IconSize + 20, y + (IconSize / 2 - th / 2))
				surface.DrawText(text)
			end

			function map_panel:PaintOver(w, h)
				self:DrawArrowLegend("You", MTA.TextColor, 0)
				self:DrawArrowLegend("Other Players", MTA.PrimaryColor, 40)
				self:DrawLegend(DealerIcon, "Gun Dealer", 80)
				self:DrawLegend(VaultIcon, "Vault", 120)
				self:DrawLegend(HardwareIcon, "Hardware Store", 160)

				self:DrawLegend(CarDealerIcon, "Car Dealer", 200)
				self:DrawLegend(VehicleIcon, "Your Vehicle", 240)

				self:DrawLegend(HotdogIcon, "Hotdog Stand", 280)
				self:DrawLegend(UnknownRoleIcon, "Unknown Business", 320)
			end

			function map_panel:Think()
				map:SetWide(565)
				map:SetTall(564)
				map:SetPos(0, 0)
			end

			local sheet_data = sheet:AddSheet("Map", map_panel)
			sheet_data.Tab.Paint = tab_paint
			sheet_data.Panel.Paint = function() end
			sheet_data.Panel:SetWide(sheet:GetWide())
		end

		local margin = 8
		local inv_panel = vgui.Create("DPanel")
		local inv = inv_panel:Add("mta_inventory")
		inv:SetPos(64 + margin, 300)

		local trash = inv.TrashCan
		trash:SetParent(inv_panel)
		trash:SetPos(664, 508)

		local item_view = inv.ItemView
		item_view:SetParent(inv_panel)
		item_view:SetPos(64 + margin, 32)

		-- Crafting panel
		local crafting = inv_panel:Add("mta_crafting")
		crafting:SetPos(64 + margin, 32)
		crafting:SetSize(inv:GetWide(), inv:GetTall() * 2 + margin)
		crafting:Hide()

		local craft_button = vgui.Create("DButton")
		craft_button:SetParent(inv_panel)
		craft_button:SetSize(40, 520)
		craft_button:SetPos(15, 32)
		craft_button:SetText("")
		function craft_button:DoClick()
			self.isToggled = not self.isToggled

			if self.isToggled then
				inv:Hide()
				item_view:Hide()
				trash:Hide()

				crafting:Show()
			else
				crafting:Hide()

				inv:Show()
				item_view:Show()
				trash:Show()
			end
		end

		function craft_button:Paint(w, h)
			local col = self:IsHovered() and MTA.TextColor or MTA.PrimaryColor

			surface.SetDrawColor(col)
			surface.DrawOutlinedRect(0, 0, w, h)

			surface.SetFont("MTAMenuHeaderFont")
			surface.SetTextColor(col)

			local arrow = self.isToggled and "<<" or ">>"
			surface.SetTextPos(5, -5)
			surface.DrawText(arrow)

			local str = self.isToggled and "INVENTORY" or "CRAFTING"
			local total_height = draw.GetFontHeight("MTAMenuHeaderFont") * #str - 40
			for i = 1, #str do
				local char = str[i]
				local cw, _ = surface.GetTextSize(char)
				surface.SetTextPos(w / 2 - cw / 2, h / 2 - total_height / 2 + (i - 1) * 30)
				surface.DrawText(char)
			end

			surface.SetTextPos(5, h - 45)
			surface.DrawText(arrow)
		end

		local tab = sheet:AddSheet("Inventory", inv_panel)
		tab.Tab.Paint = tab_paint

		tab = sheet:AddSheet("Leaderboard", vgui.Create("mta_leaderboard"))
		tab.Tab.Paint = tab_paint

		do
			local APTS_RENTED = Color(255, 50, 50)
			local APTS_OWNED = Color(100, 255, 100)
			local APTS_INVITED = Color(255, 150, 100)

			local function get_apartment_status(apt)
				local col

				if apt.Renter then
					col = apt.Renter == LocalPlayer() and APTS_OWNED or APTS_RENTED
				end

				if #apt.Invitees > 0 then
					for _, invitee in ipairs(apt.Invitees) do
						if invitee == LocalPlayer() then
							col = APTS_INVITED
						end
					end
				end

				return col
			end

			local apt_panel = vgui.Create("mta_apartments_tab")

			local apt_list = apt_panel:Add("DListView")
			apt_list:Dock(LEFT)
			apt_list:DockMargin(20, 75, 20, 20)
			apt_list:SetWide(200)
			apt_list:SetDataHeight(30)

			function apt_list:Paint(w, h)
				surface.SetDrawColor(MTA.PrimaryColor)
				surface.DrawOutlinedRect(0, 0, w, h)
			end

			apt_list:SetMultiSelect(false)
			apt_list:SetSortable(false)

			apt_list:AddColumn("Apartment")
			local price = apt_list:AddColumn("Price")
			price:SetFixedWidth(40)

			local apt_list_data = MTA.Apartments.List
			for name, data in pairs(apt_list_data) do
				local added = apt_list:AddLine(name, data.Data.price)
				function added:Paint(w, h)
					local status = get_apartment_status(data)

					surface.SetDrawColor(status or Color(50, 50, 50))
					if added:IsHovered() then
						surface.DrawRect(0, 0, w, h)
					else
						surface.DrawOutlinedRect(0, 0, w, h, 1)
					end
				end
			end

			apt_list:SortByColumn(2, true)

			local apt_showcase = apt_panel:Add("DPanel")
			apt_showcase:Dock(RIGHT)
			apt_showcase:DockMargin(20, 20, 20, 20)
			apt_showcase:SetWide(450)

			function apt_showcase:Paint(w, h)
				surface.SetDrawColor(MTA.PrimaryColor)
				surface.DrawOutlinedRect(0, 0, w, h)
			end

			local apt_showcase_label = apt_showcase:Add("DLabel")
			apt_showcase_label:Dock(TOP)
			apt_showcase_label:DockMargin(20, 20, 20, 0)

			apt_showcase_label:SetFont("MTAMenuPlayerFont")
			apt_showcase_label:SetTextColor(MTA.TextColor)

			function apt_showcase_label:Think()
				local apts = MTA.Apartments.List

				local _, selected = apt_list:GetSelectedLine()

				local apt
				local desc
				local status
				if selected then
					apt = apts[selected:GetColumnText(1)]
					desc = apt.Data.desc or "No description found!"
					status = get_apartment_status(apt)
				end

				local txt = selected and selected:GetColumnText(1) .. "\n" or "Pick an apartment!\n"
				txt = txt .. (selected and "Price: " .. selected:GetColumnText(2) .. "\n\n" or "")
				txt = txt .. (selected and "Description: " .. desc .. "\n\n" or "")
				txt = txt .. ((selected and status) and (
					status == APTS_RENTED and "This apartment is already rented!" or
					status == APTS_OWNED and "You own this apartment!" or
					status == APTS_INVITED and "You are invited to this apartment!"
				) or "")
				self:SetText(txt)

				self:SizeToContents()
			end

			local apt_showcase_travel = apt_showcase:Add("DButton")
			apt_showcase_travel:Dock(BOTTOM)

			apt_showcase_travel:SetText("Fast Travel")
			apt_showcase_travel:SetTall(50)

			function apt_showcase_travel:Paint(w, h)
				surface.SetDrawColor(
					(self:IsEnabled() and self:IsHovered()) and MTA.TextColor or MTA.PrimaryColor
				)
				surface.DrawOutlinedRect(0, 0, w, h)
			end

			function apt_showcase_travel:Think()
				local _, selected = apt_list:GetSelectedLine()
				local enabled = (not MTA.IsWanted(LocalPlayer()) and tobool(selected))

				self:SetEnabled(enabled)
			end

			function apt_showcase_travel:DoClick()
				local _, selected = apt_list:GetSelectedLine()

				net.Start(NET_APARTMENTS)
					net.WriteString(selected:GetColumnText(1))
				net.SendToServer()
			end

			local sheet_data = sheet:AddSheet("Apartments", apt_panel)
			sheet_data.Tab.Paint = tab_paint
		end
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

		surface.SetDrawColor(MTA.PrimaryColor)
		surface.DrawOutlinedRect(0, 0, w, h, 2)

		local header_text = GetHostName()
		surface.SetFont("MTAMenuHeaderFont")
		surface.SetTextColor(255, 255, 255, 255)
		local tw, _ = surface.GetTextSize(header_text)
		surface.SetTextPos(self:GetWide() / 2 - tw / 2, -50)

		surface.DisableClipping(true)
		surface.DrawText(header_text)
		surface.DisableClipping(false)
	end

	vgui.Register("mta_menu", PANEL, "DPanel")

	local menu
	function GM:OnSpawnMenuOpen()
		if IsValid(menu) then
			menu:Show()
			return false
		end

		menu = vgui.Create("mta_menu")
		menu:Show()
		return false
	end

	function GM:OnSpawnMenuClose()
		gui.EnableScreenClicker(false)
		if IsValid(menu) then
			menu:Hide()
		end

		return false
	end

	function GM:PlayerBindPress(_, bind, pressed)
		if bind:match("gm_showspare1") and pressed then
			if not IsValid(menu) then
				menu = vgui.Create("mta_menu")
				menu = pressed and menu:Show() or menu:Hide()
				gui.EnableScreenClicker(pressed)

				return
			end

			if menu:IsVisible() then
				menu:Hide()
				gui.EnableScreenClicker(false)
			else
				menu:Show()
				menu.Sheets:SwitchToName("Inventory")
				gui.EnableScreenClicker(true)
			end
		end
	end

	function GM:MTAHUDShouldDraw(element)
		if IsValid(menu) and menu:IsVisible() then return false end
	end
end
