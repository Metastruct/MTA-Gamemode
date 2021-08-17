
local Tag = "MTA_Apartments"
local APT_INIT = 1
local APT_RENT = 2
local APT_INVITE = 3

local MTA_Apartments = MTA.Apartments

util.AddNetworkString(Tag)

local function SendDataToClient(ply)
	-- Send entrance ids and whateversefsf<s to client
	local clientdata = {}
	for apt_name, apt in pairs(MTA_Apartments.List) do
		local entrance = ents.GetMapCreatedEntity(apt.Data.entrance_id)

		local apt_table = {
			entrance_index = entrance:EntIndex(),
			apt_invitees = apt.Invitees,
			apt_name = apt_name
		}

		table.insert(clientdata, apt_table)
	end

	net.Start(Tag)
		net.WriteInt(APT_INIT, 32)
		net.WriteTable(clientdata)
	net.Send(ply)
end

hook.Add("PlayerFullyConnected", Tag, SendDataToClient)

net.Receive(Tag, function(l, ply)
	local id = net.ReadInt(32)

	local apt = net.ReadTable()
	local apt_name = apt.Data.name

	if id == APT_RENT then
		if apt.Renter and ply ~= apt.Renter then
			apt.Entrance:EmitSound("vo/Citadel/br_youfool.wav")
			ply:ChatPrint("This apartment is already rented!")

			return
		end

		if apt.Renter and ply == apt.Renter then
			MTA_Apartments.ClearRent(apt_name)
			ply:EmitSound("plats/elevator_stop2.wav")

			return
		end

		if MTA_Apartments.GetPlayerApartment(ply) then
			apt.Entrance:EmitSound("vo/Citadel/br_youfool.wav")
			ply:ChatPrint("You already have an apartment!")

			return
		end

		local paid = MTA.PayPoints(ply, apt.Data.price)
		if not paid then
			ply:ChatPrint("You do not have enough points!")
			ply:EmitSound("doors/door_locked2.wav")

			return
		end

		MTA_Apartments.SetRenter(ply, apt_name)
		ply:EmitSound("doors/wood_stop1.wav")

		return
	end

	if id == APT_INVITE then
		local invitee = net.ReadEntity()

		if IsInvited(invitee, MTA_Apartments.List[apt_name]) then
			MTA_Apartments.KickPlayerFrom(invitee, ply)

			return
		end

		MTA_Apartments.InvitePlayerTo(invitee, ply)
	end
end)

local function IsInvited(ply, apt)
	if not apt.Invitees then return end

	for _, invitee in ipairs(apt.Invitees) do
		if ply == invitee then return true end
	end

	return false
end

-- Disallow door opening on apartments that are rented
local last_use = RealTime()
hook.Add("PlayerUse", Tag, function(ply, ent)
	for _, apt in pairs(MTA_Apartments.List) do
		if apt.Renter and apt.Renter ~= ply and not IsInvited(ply, apt) and apt.Entrance == ent then
			if last_use + 1 < RealTime() then
				apt.Entrance:EmitSound("vo/Citadel/br_no.wav")
				ply:ChatPrint("You do not own this apartment!")

				last_use = RealTime()
			end

			return false
		end
	end

	return true
end)

local function LookupApartment(apt_lookup)
	apt_lookup = string.lower(apt_lookup)
	local matched

	local apts = MTA_Apartments.List

	for apt, _ in pairs(apts) do
		if string.lower(apt):match(apt_lookup) == apt_lookup then
			matched = apts[apt]
			if matched then return matched end
		end
	end

	return nil
end

local function KickPlayerFromApt(ent, apt, str)
	ent:SetPos(apt.Data.travel_pos)
	ent:SetVelocity(-ent:GetVelocity())

	if not ent._mta_lastkick then
		ent._mta_lastkick = RealTime() - .6
	end

	if ent._mta_lastkick + .5 < RealTime() then
		apt.Entrance:EmitSound("vo/Citadel/br_youfool.wav")
		ent:ChatPrint(str)

		ent._mta_lastkick = RealTime()
	end
end

function MTA_Apartments.LookupApartment(apt_lookup)
	local apt = LookupApartment(apt_lookup)

	if not apt then
		return "Couldn't find " .. apt_lookup .. "."
	end

	return apt
end

function MTA_Apartments.GetPlayerApartment(ply)
	for _, apt in pairs(MTA_Apartments.List) do
		if apt.Renter == ply then return apt end
	end

	return false
end

function MTA_Apartments.InApartment(ply, apt_lookup)
	local apt = LookupApartment(apt_lookup)

	if not apt then
		return "Invalid apartment!"
	end

	for _, ent in ipairs(apt.Trigger.Entities) do
		if ent:IsPlayer() and ent == ply then return true end
	end

	return false
end

function MTA_Apartments.GetRenter(apt_lookup)
	local apt = LookupApartment(apt_lookup)

	if not apt then
		return "Invalid apartment!"
	end

	return apt.Renter
end

function MTA_Apartments.SetRenter(ply, apt_lookup)
	local apt = LookupApartment(apt_lookup)

	if not apt then
		return "Invalid apartment!"
	end

	MTA_Apartments.ClearRent(apt_lookup)

	apt.Renter = ply

	net.Start(Tag)
		net.WriteInt(APT_RENT, 32)
		net.WriteString(apt.Data.name)
		net.WriteEntity(ply)
	net.Broadcast()

	return "Success!"
end

function MTA_Apartments.ClearRent(apt_lookup)
	local apt = LookupApartment(apt_lookup)

	if not apt then
		return "Invalid apartment!"
	end

	apt.Renter = nil
	apt.Invitees = {}

	net.Start(Tag)
		net.WriteInt(APT_RENT, 32)
		net.WriteString(apt.Data.name)
	net.Broadcast()

	return "Success!"
end

function MTA_Apartments.SendPlayerTo(ply, apt_lookup)
	local apt = LookupApartment(apt_lookup)

	if not apt or not apt.Data.travel_pos then
		return "Invalid apartment!"
	end

	ply:SetPos(apt.Data.travel_pos)
	ply:SetEyeAngles((apt.Entrance:WorldSpaceCenter() - me:WorldSpaceCenter()):Angle())

	timer.Simple(.5, function()
		if not apt.Renter or apt.Renter == ply or IsInvited(ply) then
			apt.Entrance:Fire("Open")
			apt.Entrance:EmitSound("vo/NovaProspekt/al_comeonin02.wav")
		end
	end)

	return "Success!"
end

function MTA_Apartments.InvitePlayerTo(invitee, owner)
	local apt = MTA_Apartments.GetPlayerApartment(owner)

	if IsInvited(invitee, apt) then return end

	if MTA.IsWanted(invitee) then
		owner:ChatPrint("The person you're trying to invite is currently wanted!")

		return
	end

	if not apt then
		return "Player does not own an apartment!"
	end

	table.insert(apt.Invitees, invitee)

	invitee:EmitSound("vo/Streetwar/Alyx_gate/al_hey.wav")
	invitee:ChatPrint("You have been invited to " .. UndecorateNick(owner:Nick()) .. "'s apartment!"
	.. "\nApartment name: " .. apt.Data.name)

	net.Start(Tag)
		net.WriteInt(APT_INVITE, 32)
		net.WriteString(apt.Data.name)
		net.WriteTable(apt.Invitees)
	net.Broadcast()

	return "Success!"
end

function MTA_Apartments.KickPlayerFrom(invitee, owner)
	local apt = MTA_Apartments.GetPlayerApartment(owner)

	if not apt then
		return "Player does not own an apartment!"
	end

	table.RemoveByValue(apt.Invitees, invitee)

	invitee:EmitSound("ambient/creatures/teddy.wav") -- :D
	invitee:ChatPrint(UndecorateNick(owner:Nick()) .. " kicked you out of their apartment!")

	net.Start(Tag)
		net.WriteInt(APT_INVITE, 32)
		net.WriteString(apt.Data.name)
		net.WriteTable(apt.Invitees)
	net.Broadcast()

	return "Success!"
end

function MTA_Apartments.EntityUpdate(trigger, ent)
	if not ent:IsPlayer() then return end

	local apt = trigger.APARTMENT

	if MTA.IsWanted(ent) then
		KickPlayerFromApt(ent, apt, "You can't enter an apartment while wanted!")

		return
	end

	if not IsInvited(ent, apt) and apt.Renter and apt.Renter ~= ent then
		KickPlayerFromApt(ent, apt, "You do not own this apartment!")
	end
end

hook.Add("PlayerDisconnected", Tag, function(ply)
	local apt = MTA_Apartments.GetPlayerApartment(ply)

	if apt then
		MTA_Apartments.ClearRent(apt.Data.name)
	end
end)