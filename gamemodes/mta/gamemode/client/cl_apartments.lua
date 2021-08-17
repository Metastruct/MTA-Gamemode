
local Tag = "MTA_Apartments"
local APT_INIT = 1
local APT_RENT = 2
local APT_INVITE = 3

local MTA_Apartments = MTA.Apartments

local function IsInvited(ply, apt)
	if not apt.Invitees then return end

	for _, invitee in ipairs(apt.Invitees) do
		if ply == invitee then return true end
	end

	return false
end

local function RefreshEntranceHighlight(apt)
	if not apt.Entrance then return end

	local str = ""
	str = apt.Renter and
	"Rented by " .. UndecorateNick(apt.Renter:Nick()) .. (IsInvited(LocalPlayer(), apt) and " (Invited!)" or "") or
	"(R) Available for rent!"

	local color = apt.Renter and
	((apt.Renter == LocalPlayer() or IsInvited(LocalPlayer(), apt)) and Color(50, 255, 50) or Color(255, 0, 0))
	or color_white

	MTA.RegisterEntityForHighlight(apt.Entrance, str, color)
end

net.Receive(Tag, function()
	local id = net.ReadInt(32)

	local apt_name = net.ReadString()
	local apt = MTA.Apartments.List[apt_name]

	if id == APT_INIT then
		local clientdata = net.ReadTable()
		for _, apt_table in ipairs(clientdata) do
			local apt = MTA_Apartments.List[apt_table.apt_name]

			apt.Invitees = apt_table.apt_invitees

			local possible_ent = Entity(apt_table.entrance_index)
			if IsValid(possible_ent) then
				apt.Entrance = possible_ent
				RefreshEntranceHighlight(apt)
			else
				apt.entrance_index = apt_table.entrance_index
			end
		end

		return
	end

	if id == APT_RENT then
		apt.Invitees = {}

		local new_renter = net.ReadEntity()
		apt.Renter = IsValid(new_renter) and new_renter or nil
	end

	if id == APT_INVITE then
		local new_invitees = net.ReadTable()

		apt.Invitees = new_invitees
	end

	RefreshEntranceHighlight(apt)
end)

hook.Add("OnEntityCreated", Tag, function(ent)
	if not MTA.Apartments or not MTA.Apartments.List then return end

	for _, apt in pairs(MTA_Apartments.List) do
		if apt.entrance_index and apt.entrance_index == ent:EntIndex() then
			apt.Entrance = ent
			apt.entrance_index = nil

			RefreshEntranceHighlight(apt)
		end
	end
end)

local function CreateEntranceGui(apt)
	local RENTED_BY_LP = apt.Renter == LocalPlayer()

	local FRAME
	local FRAME_W, FRAME_H = 200, 100
	local ELEMENT_W, ELEMENT_H = FRAME_W - 20, 30

	local RENT_BTN
	local RENT_BTN_TXT

	local INVITE_BTN
	local INVITE_BTN_TXT

	local INVITE_GUI
	local INVITE_GUI_LIST
	local INVITE_GUI_BTN

	FRAME = vgui.Create("DFrame")
	FRAME:SetTitle("Rent an apartment!")
	FRAME:SetSize(FRAME_W, FRAME_H)
	FRAME:Center()

	RENT_BTN = FRAME:Add("DButton")
	RENT_BTN_TXT = RENTED_BY_LP and "Abandon apartment" or "Rent me! (" .. apt.Data.price .. " points)"
	RENT_BTN:SetText(RENT_BTN_TXT)
	RENT_BTN:SetSize(ELEMENT_W, ELEMENT_H)
	RENT_BTN:Dock(TOP)
	function RENT_BTN:DoClick()
		FRAME:Remove()

		net.Start(Tag)
			net.WriteInt(APT_RENT, 32)
			net.WriteTable(apt)
		net.SendToServer()
	end

	INVITE_BTN = FRAME:Add("DButton")
	INVITE_BTN_TXT = RENTED_BY_LP and "Invite/Kick" or "#####"
	INVITE_BTN:SetText(INVITE_BTN_TXT)
	INVITE_BTN:SetSize(ELEMENT_W, ELEMENT_H)
	INVITE_BTN:Dock(BOTTOM)
	INVITE_BTN:SetDisabled(not RENTED_BY_LP)
	function INVITE_BTN:DoClick()
		FRAME:Remove()

		INVITE_GUI = vgui.Create("DFrame")
		INVITE_GUI:SetTitle("Invite/Kick")
		INVITE_GUI:SetSize(FRAME_W, FRAME_H)
		INVITE_GUI:Center()

		INVITE_GUI_LIST = INVITE_GUI:Add("DComboBox")
		INVITE_GUI_LIST:SetValue("Choose a player")
		INVITE_GUI_LIST:SetSize(ELEMENT_W, ELEMENT_H)
		INVITE_GUI_LIST:Dock(TOP)
		function INVITE_GUI_LIST:OnSelect()
			local _, ply = self:GetSelected()

			if ply then
				local str = IsInvited(ply, apt) and "Kick" or "Invite"
				INVITE_GUI_BTN:SetText(str)
				INVITE_GUI_BTN:SetDisabled(false)
			end
		end
		for _, ply in ipairs(player.GetAll()) do
			if ply ~= LocalPlayer() then
				local nick = UndecorateNick(ply:Nick())
				INVITE_GUI_LIST:AddChoice(nick, ply)
			end
		end

		INVITE_GUI_BTN = INVITE_GUI:Add("DButton")
		INVITE_GUI_BTN:SetText("#####")
		INVITE_GUI_BTN:SetSize(ELEMENT_W, ELEMENT_H)
		INVITE_GUI_BTN:Dock(BOTTOM)
		INVITE_GUI_BTN:SetDisabled(true)
		function INVITE_GUI_BTN:DoClick()
			local _, ply = INVITE_GUI_LIST:GetSelected()

			net.Start(Tag)
				net.WriteInt(APT_INVITE, 32)
				net.WriteString(apt.Data.name)
				net.WriteEntity(ply)
			net.SendToServer()

			INVITE_GUI:Remove()
		end

		INVITE_GUI:MakePopup()
	end

	FRAME:MakePopup()
end

local last_press = RealTime()
hook.Add("KeyPress", Tag, function(ply, key)
	if not MTA.Apartments or not MTA.Apartments.List then return end
	if ply ~= LocalPlayer() or last_press + 1 > RealTime() then return end

	for _, apt in pairs(MTA_Apartments.List) do
		if key == IN_RELOAD and ply:GetEyeTrace().Entity == apt.Entrance then
			CreateEntranceGui(apt)

			last_press = RealTime()
		end
	end
end)