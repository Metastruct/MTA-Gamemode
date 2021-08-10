local tag = "mta_statuses"
local statuses = MTA_TABLE("Statuses")

util.AddNetworkString(tag)

function statuses.AddStatus(ply, name, text, color, expire_time)
	net.Start(tag)
	net.WriteBool(true)
	net.WriteString(name)
	net.WriteString(text)
	net.WriteColor(color)
	if expire_time then
		net.WriteBool(true)
		net.WriteInt(expire_time, 32)
	else
		net.WriteBool(false)
	end
	net.Send(ply)
end

function statuses.RemoveStatus(ply, name)
	net.Start(tag)
	net.WriteBool(false)
	net.WriteString(name)
	net.Send(ply)
end