local tag = "bank"
local ALARM_BTN_ID = 4100
local alarm_state = false
hook.Add("PlayerUse", tag, function(ply, ent)
	if ent:MapCreationID() == ALARM_BTN_ID then return false end
end)

local alarm_btn
local function get_alarm_btn()
	if not IsValid(alarm_btn) then
		alarm_btn = ents.GetMapCreatedEntity(ALARM_BTN_ID)
	end
	if not IsValid(alarm_btn) then return end

	return alarm_btn
end

local BANK_VAULT_DISTANCE = 1400
hook.Add("MTADrillStart", tag, function(_, vault)
	if alarm_state then return end

	local btn = get_alarm_btn()
	if not btn then return end

	if vault:GetPos():Distance(btn:GetPos()) <= BANK_VAULT_DISTANCE then
		if not alarm_state then
			btn:Fire("Use")
			alarm_state = true
		end
	end
end)

hook.Add("MTADrillFailed", tag, function(_, vault)
	if not alarm_state then return end

	local btn = get_alarm_btn()
	if not btn then return end

	if vault:GetPos():Distance(btn:GetPos()) <= BANK_VAULT_DISTANCE then
		for _, v in ipairs(ents.FindInSphere(btn:GetPos(), BANK_VAULT_DISTANCE)) do
			if v:GetNWBool("Drilling") then return end
		end

		if alarm_state then
			btn:Fire("Use")
			alarm_state = false
		end
	end
end)