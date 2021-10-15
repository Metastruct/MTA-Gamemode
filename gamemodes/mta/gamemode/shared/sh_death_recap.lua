local tag = "mta_death_recap"

if SERVER then
	util.AddNetworkString(tag)

	local function try_with_weapon(original_atck, original_inflictor)
		local wep
		if original_atck:IsWeapon() then
			wep = original_atck
		elseif original_inflictor:IsWeapon() then
			wep = original_inflictor
		elseif original_atck:IsPlayer() or original_atck:IsNPC() then
			wep = original_atck:GetActiveWeapon()
		elseif original_inflictor:IsPlayer() or original_inflictor:IsNPC() then
			wep = original_inflictor:GetActiveWeapon()
		end

		if IsValid(wep) then
			-- if we have a weapon great we know how to deal with it
			local owner = wep:GetOwner()
			if not IsValid(owner) then
				owner = wep:GetPhysicsAttacker(5)
			end

			return true, IsValid(owner) and owner or "Unknown", wep
		end

		return false
	end

	local function get_first_passenger(veh)
		if veh.GetPassengerSeats then
			for _, seat in pairs(veh:GetPassengerSeats()) do
				local passenger = seat:GetDriver()
				if IsValid(passenger) then return passenger end
			end
		elseif veh.GetPassenger then
			for i = 1, 10 do
				local passenger = veh:GetPassenger(i)
				if IsValid(passenger) then return passenger end
			end
		end

		return nil
	end

	local function try_with_vehicle(original_atck, original_inflictor)
		local veh
		if original_atck:IsVehicle() then
			veh = original_atck
		elseif original_inflictor:IsVehicle() then
			veh = original_inflictor
		elseif original_atck:IsPlayer() and original_atck:InVehicle() then
			veh = original_atck:GetVehicle()
		elseif original_inflictor:IsPlayer() and original_inflictor:InVehicle() then
			veh = original_inflictor:GetVehicle()
		end

		if IsValid(veh) then
			local driver = veh:GetDriver()
			if not IsValid(driver) then
				local owner = veh.CPPIGetOwner and veh:CPPIGetOwner()
				if not IsValid(owner) then
					owner = get_first_passenger(veh)
				end

				return true, IsValid(owner) and owner or "Unknown", veh
			end
		end

		return false
	end

	local owner_methods = { "GetOwner", "GetCreator", "CPPIGetOwner" }
	local function try_with_entity(original_atck, original_inflictor)
		if original_atck:CreatedByMap() then return true, "Unknown", original_atck end
		if original_inflictor:CreatedByMap() then return true, "Unknown", original_inflictor end

		local ent
		local owner
		for _, method in ipairs(owner_methods) do
			if original_atck[method] then
				local tmp_owner = original_atck[method](original_atck)
				if IsValid(tmp_owner) then
					owner = tmp_owner
					ent = original_atck
					break
				end
			end
		end

		if not IsValid(owner) then
			for _, method in ipairs(owner_methods) do
				if original_inflictor[method] then
					local tmp_owner = original_inflictor[method](original_atck)
					if IsValid(tmp_owner) then
						owner = tmp_owner
						ent = original_inflictor
						break
					end
				end
			end
		end

		if not IsValid(owner) then
			owner = original_atck:GetPhysicsAttacker(5)
			ent = original_atck
			if not IsValid(owner) then
				owner = original_inflictor:GetPhysicsAttacker(5)
				ent = original_inflictor
			end
		end

		return true, IsValid(owner) and owner or "Unknown", ent
	end

	hook.Add("PostEntityTakeDamage", tag, function(ent, dmg_info, dmg_applied)
		if not dmg_applied then return end
		if not ent:IsPlayer() then return end

		ent.DeathRecap = ent.DeathRecap or {}
		if #ent.DeathRecap > 6 then
			table.remove(ent.DeathRecap, 1)
		end

		local atck = dmg_info:GetAttacker()
		local inflictor = dmg_info:GetInflictor()

		-- attacker and inflictor are unreliable in this hook
		-- lets try figuring out whats happening ourselves
		local succ, owner, wep = try_with_weapon(atck, inflictor)
		if succ then
			atck = owner
			inflictor = wep
		else
			local succ, owner, veh = try_with_vehicle(atck, inflictor)
			if succ then
				atck = owner
				inflictor = veh
			else
				local succ, owner, entity = try_with_entity(atck, inflictor)
				if succ then
					atck = owner
					inflictor = entity
				end
			end
		end

		if isentity(atck) then
			if atck:IsPlayer() then
				atck = UndecorateNick(atck:Nick())
			else
				atck = atck:GetClass()
			end
		end

		inflictor = isentity(inflictor) and inflictor:GetClass() or inflictor

		table.insert(ent.DeathRecap, {
			Inflictor = inflictor,
			Attacker = atck,
			Damage = math.Round(dmg_info:GetDamage()),
		})

		if not ent:Alive() then
			net.Start(tag)
			net.WriteTable(ent.DeathRecap)
			net.WriteEntity(atck)
			net.Send(ent)

			ent.DeathRecap = nil
		end
	end)
end

if CLIENT then
	surface.CreateFont("MTADeathRecapNameFont", {
		font = "Orbitron",
		size = 25,
		weight = 800,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTADeathRecapDamageFont", {
		font = "Orbitron",
		size = 30,
		weight = 800,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTADeathRecapTitle", {
		font = "Orbitron",
		size = 72,
		weight = 800,
		shadow = false,
		extended = true,
	})

	surface.CreateFont("MTADeathRecapKiller", {
		font = "Orbitron",
		size = 40,
		weight = 800,
		shadow = false,
		extended = true,
	})

	local displayed_recap = false
	local recap = {}
	net.Receive(tag, function()
		recap = net.ReadTable()
		recap = table.Reverse(recap)

		local total_dmg = 0
		for _, recap_data in ipairs(recap) do
			total_dmg = total_dmg + recap_data.Damage
		end

		if total_dmg < 100 then
			table.insert(recap, {
				Inflictor = "Others",
				Attacker = "Others",
				Damage = 100 - total_dmg,
			})
		end

		displayed_recap = false
	end)

	hook.Add("HUDShouldDraw", tag, function(name)
		if name == "CHudDamageIndicator" then
		   return false
		end
	end)

	hook.Add("HUDPaint", tag, function()
		if LocalPlayer():Alive() and displayed_recap then
			recap = {}
			return
		end

		displayed_recap = true
		Derma_DrawBackgroundBlur(vgui.GetWorldPanel(), 0)
		if #recap == 0 then return end

		local w, h = 500, 50
		local base_x, base_y = ScrW() / 2 - w / 2, ScrH() / 3

		surface.SetFont("MTADeathRecapTitle")
		surface.SetTextColor(MTA.TextColor)
		surface.SetTextPos(base_x, base_y - 75)
		surface.DrawText("DEATH RECAP")

		for i = 1, #recap do
			if i == 1 then
				surface.SetFont("MTADeathRecapKiller")
				surface.SetTextColor(MTA.TextColor)
				surface.SetTextPos(base_x - 150, base_y + 5)
				surface.DrawText("KILLER")
			end

			local y = base_y + ((i - 1) * (h + 5))
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(base_x, y, w, h)
			surface.SetDrawColor(MTA.PrimaryColor)
			surface.DrawOutlinedRect(base_x, y, w, h, 2)

			local atck_text = language.GetPhrase(recap[i].Attacker)
			local infl_text = "with " .. language.GetPhrase(recap[i].Inflictor)
			local dmg_text = tostring(recap[i].Damage) .. " DMG"
			local tw = 100

			surface.SetFont("MTADeathRecapNameFont")
			surface.SetTextColor(MTA.TextColor)
			surface.SetTextPos(base_x + 5, y + 5)
			surface.DrawText(atck_text)
			local atck_tw, _ = surface.GetTextSize(atck_text)

			surface.SetFont("DermaDefaultBold")
			surface.SetTextColor(MTA.PrimaryColor)
			surface.SetTextPos(base_x + 5, y + 30)
			surface.DrawText(infl_text)
			local infl_tw, _ = surface.GetTextSize(atck_text)

			if atck_tw >= infl_tw then tw = atck_tw else tw = infl_tw end

			surface.SetFont("MTADeathRecapDamageFont")
			local dmg_tw, _ = surface.GetTextSize(dmg_text)
			dmg_tw = dmg_tw + 10

			if base_x + w - dmg_tw > base_x + tw then
				tw = base_x + w - dmg_tw
			else
				tw = base_x + tw
			end

			surface.SetTextColor(MTA.DangerColor)
			surface.SetTextPos(tw, y + 10)
			surface.DrawText(dmg_text)
		end
	end)
end