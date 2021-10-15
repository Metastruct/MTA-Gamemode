local tag = "mta_daily_missions"

local MAX_CHALLENGES = 3
local MTADailyChallenges = MTA_TABLE("DailyChallenges")

MTADailyChallenges.BaseChallenges = {}
MTADailyChallenges.CurrentChallenges = MTADailyChallenges.CurrentChallenges or {}

function MTADailyChallenges.GetProgress(ply, mission_id)
	local nw_var_name = tag .. "_" .. mission_id
	return ply:GetNWInt(nw_var_name)
end

if SERVER then
	function MTADailyChallenges.UpgradeBadge(ply)
		local succ, err = pcall(function()
			if MetaBadges and MetaBadges.IsValidBadge("daily_commitment") then
				local cur_lvl = MetaBadges.GetBadgeLevel(ply, "daily_commitment") or 0
				MetaBadges.UpgradeBadge(ply, "daily_commitment", cur_lvl + 1)
			end
		end)

		if not succ then
			MTA.Print("Failed to update badge for:", ply, err)
		end
	end
end

function MTADailyChallenges.AddProgress(ply, mission_id, amount)
	if CLIENT then return end
	if not MTADailyChallenges.CurrentChallenges[mission_id] then return end

	local mission = MTADailyChallenges.BaseChallenges[mission_id]
	if not mission then return end

	local state = MTADailyChallenges.CurrentChallenges[mission_id][ply:SteamID()] or { Progress = 0, Completed = false }
	if state.Completed then return end

	state.Progress = state.Progress + amount
	MTADailyChallenges.CurrentChallenges[mission_id][ply:SteamID()] = state

	local nw_var_name = tag .. "_" .. mission_id
	ply:SetNWInt(nw_var_name, state.Progress)

	if state.Progress >= mission.Completion then
		MTA.GivePoints(ply, mission.Reward)
		MTADailyChallenges.CurrentChallenges[mission_id][ply:SteamID()].Completed = true
		MTADailyChallenges.UpgradeBadge(ply)
	end
end

MTADailyChallenges.BaseChallenges.kill_shotgunners = {
	Description = "Kill 10 shotgunners",
	Completion = 10,
	Reward = 20,
	Execute = function()
		hook.Add("OnNPCKilled", tag .. "_kill_shotgunners", function(npc, attacker)
			if not attacker:IsPlayer() then return end
			if npc:GetNWBool("MTACombine") then
				local wep = npc:GetActiveWeapon()
				if IsValid(wep) and wep:GetClass() == "weapon_shotgun" then
					MTADailyChallenges.AddProgress(attacker, "kill_shotgunners", 1)
				end
			end
		end)
	end,
	Finish = function()
		hook.Remove("OnNPCKilled", tag .. "_kill_shotgunners")
	end
}

MTADailyChallenges.BaseChallenges.kill_metropolice = {
	Description = "Kill 25 metropolice agents",
	Completion = 25,
	Reward = 20,
	Execute = function()
		hook.Add("OnNPCKilled", tag .. "_kill_metropolice", function(npc, attacker)
			if not attacker:IsPlayer() then return end
			if npc:GetNWBool("MTACombine") and npc:GetClass() == "npc_metropolice" then
				MTADailyChallenges.AddProgress(attacker, "kill_metropolice", 1)
			end
		end)
	end,
	Finish = function()
		hook.Remove("OnNPCKilled", tag .. "_kill_metropolice")
	end
}

MTADailyChallenges.BaseChallenges.drill_vaults = {
	Description = "Drill 3 vaults successfully",
	Completion = 3,
	Reward = 100,
	Execute = function()
		hook.Add("MTADrillSuccess", tag .. "_drill_vaults", function(ply)
			MTADailyChallenges.AddProgress(ply, "drill_vaults", 1)
		end)
	end,
	Finish = function()
		hook.Remove("MTADrillSuccess", tag .. "_drill_vaults")
	end,
}

MTADailyChallenges.BaseChallenges.wanted_lvl_75 = {
	Description = "Get up to wanted level 75",
	Completion = 75,
	Reward = 100,
	Execute = function()
		hook.Add("MTAPlayerWantedLevelIncreased", tag .. "_wanted_lvl_75", function(ply, wanted_level)
			local progress = MTADailyChallenges.GetProgress(ply, "wanted_lvl_75")
			if progress < wanted_level then
				MTADailyChallenges.AddProgress(ply, "wanted_lvl_75", 1)
			end
		end)
	end,
	Finish = function()
		hook.Remove("MTAPlayerWantedLevelIncreased", tag .. "_wanted_lvl_75")
	end,
}

MTADailyChallenges.BaseChallenges.survive_2500_dmg = {
	Description = "Take 2500dmg while wanted",
	Completion = 2500,
	Reward = 75,
	Execute = function()
		hook.Add("EntityTakeDamage", tag .. "_survive_2500_dmg", function(target, dmg_info)
			if target:IsPlayer() and MTA.IsWanted(target) then
				local atck = dmg_info:GetAttacker()
				if IsValid(atck) and atck:GetNWBool("MTACombine") then
					MTADailyChallenges.AddProgress(target, "survive_2500_dmg", dmg_info:GetDamage())
				end
			end
		end)

		hook.Add("MTAPlayerFailed", tag .. "_survive_2500_dmg", function(ply)
			local progress = MTADailyChallenges.GetProgress(ply, "survive_2500_dmg")
			MTADailyChallenges.AddProgress(ply, "survive_2500_dmg", -progress)
		end)
	end,
	Finish = function()
		hook.Remove("EntityTakeDamage", tag .. "_survive_2500_dmg")
		hook.Remove("MTAPlayerFailed", tag .. "_survive_2500_dmg")
	end,
}

if SERVER then
	util.AddNetworkString(tag)

	function MTADailyChallenges.SelectDailyChallenges()
		for mission_id, _ in pairs(MTADailyChallenges.CurrentChallenges) do
			MTADailyChallenges.BaseChallenges[mission_id].Finish()
			MTADailyChallenges.CurrentChallenges[mission_id] = nil
		end

		local keys = table.GetKeys(MTADailyChallenges.BaseChallenges)
		local selected_mission_ids = {}
		for i = 1, MAX_CHALLENGES do
			local rand = math.random(#keys)
			table.insert(selected_mission_ids, keys[rand])
			table.remove(keys, rand)
		end

		for _, mission_id in pairs(selected_mission_ids) do
			MTADailyChallenges.CurrentChallenges[mission_id] = {}
			MTADailyChallenges.BaseChallenges[mission_id].Execute()
		end

		net.Start(tag)
		net.WriteTable(selected_mission_ids)
		net.Broadcast()
	end

	hook.Add("PlayerFullyConnected", tag, function(ply)
		for mission_id, data in pairs(MTADailyChallenges.CurrentChallenges) do
			local ply_data = data[ply:SteamID()] or { Progress = 0, Completed = false }
			ply:SetNWInt(tag .. "_" .. mission_id, ply_data.Progress)
		end

		net.Start(tag)
		net.WriteTable(table.GetKeys(MTADailyChallenges.CurrentChallenges))
		net.Send(ply)
	end)

	local data_file_name = tag .. ".json"
	local last_day_component = os.date("%d")
	timer.Create(tag, 60, 0, function()
		local day_component = os.date("%d")
		if last_day_component ~= day_component then
			MTADailyChallenges.SelectDailyChallenges()
			last_day_component = day_component
		end

		local prev_data = util.JSONToTable(file.Read(data_file_name, "DATA") or "")
		file.Write(data_file_name, util.TableToJSON({
			date = prev_data and prev_data.date or os.date("%d/%m/%Y"),
			challenges = MTADailyChallenges.CurrentChallenges,
		}))
	end)

	local data = util.JSONToTable(file.Read(data_file_name, "DATA") or "")
	if data and data.date == os.date("%d/%m/%Y") and table.Count(data.challenges) == MAX_CHALLENGES then
		MTADailyChallenges.CurrentChallenges = data.challenges
		for mission_id, _ in pairs(MTADailyChallenges.CurrentChallenges) do
			MTADailyChallenges.BaseChallenges[mission_id].Execute()
		end
	else
		MTADailyChallenges.SelectDailyChallenges()
	end
end