local GUILT_TIME = 20

local function can_ent_be_guilty(ent)
	if not ent:IsPlayer() then return false end
	if MTA.IsWanted(ent) then return false end
	if MTA.Zones.Players[ent] then return false end

	return true
end

local trigger_cache = {}
local TRIGGER_BOUNDS = Vector(1000, 1000, 1000)
local function attach_trigger(ply)
	SafeRemoveEntity(ply.MTAWantedTrigger)

	local trigger = ents.Create("base_brush")
	trigger:SetPos(ply:GetPos())
	trigger:SetParent(ply)
	trigger:SetTrigger(true)
	trigger:SetSolid(SOLID_BBOX)
	trigger:SetNotSolid(true)
	trigger:SetCollisionBounds(-TRIGGER_BOUNDS, TRIGGER_BOUNDS)
	trigger:SetPos(ply:WorldSpaceCenter())
	trigger.MTAWantedPlayer = ply

	trigger.Touch = function(_, ent)
		if not can_ent_be_guilty(ent) then return end

		if not trigger_cache[ent] then
			trigger_cache[ent] = {
				Triggers = { [trigger] = true },
				TimeInTriggers = 0,
				NextCheck = CurTime() + 1,
			}
		else
			local cache = trigger_cache[ent]
			cache.Triggers[trigger] = true

			if CurTime() > cache.NextCheck then
				cache.NextCheck = CurTime() + 1
				cache.TimeInTriggers = cache.TimeInTriggers + 1
			end

			MTA.Statuses.AddStatus(ent, "wanted_area", "LEAVE CRIMINAL AREA NOW",
				MTA.DangerColor, CurTime() + ((GUILT_TIME + 1) - cache.TimeInTriggers))

			if cache.TimeInTriggers > GUILT_TIME then
				local trigger_count = 0
				local avg = 0
				for tr, _ in pairs(cache.Triggers) do
					if not IsValid(tr) then continue end

					trigger_count = trigger_count + 1
					avg = avg + tr.MTAWantedPlayer:GetNWInt("MTAFactor")
				end

				avg = avg / trigger_count

				MTA.IncreasePlayerFactor(ent, math.ceil(avg / 4))
				ent.MTALeaveWarned = true
				trigger_cache[ent] = nil
			end
		end
	end

	trigger.EndTouch = function(_, ent)
		local cache = trigger_cache[ent]
		if not cache then return end

		cache.Triggers[trigger] = nil
		if table.Count(cache.Triggers) == 0 then
			MTA.Statuses.RemoveStatus(ent, "wanted_area")
			trigger_cache[ent] = nil
		end
	end

	ply.MTAWantedTrigger = trigger
end

hook.Add("MTAWantedStateUpdate", "mta_guilty_by_association", function(ply, is_wanted)
	if is_wanted then
		attach_trigger(ply)
	else
		SafeRemoveEntity(ply.MTAWantedTrigger)
	end
end)

hook.Add("EntityRemoved", "mta_guilty_by_association", function(ent)
	if ent.MTAWantedPlayer then
		for ply, cache in pairs(trigger_cache) do
			cache.Triggers[ent] = nil
			if table.Count(cache.Triggers) == 0 then
				MTA.Statuses.RemoveStatus(ply, "wanted_area")
				trigger_cache[ply] = nil
			end
		end
	end
end)