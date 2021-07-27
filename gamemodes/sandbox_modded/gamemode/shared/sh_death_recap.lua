local tag = "mta_death_recap"

if SERVER then
	util.AddNetworkString(tag)

	hook.Add("PostEntityTakeDamage", tag, function(ent, dmg_info, dmg_applied)
		if not dmg_applied then return end
		if not ent:IsPlayer() then return end

		ent.DeathRecap = ent.DeathRecap or {}
		if #ent.DeathRecap > 6 then
			table.remove(ent.DeathRecap, 1)
		end

		local atck = dmg_info:GetAttacker()
		local inflictor = dmg_info:GetInflictor()
		if IsValid(atck) and (atck:IsPlayer() or atck:IsNPC()) then
			atck = atck:GetActiveWeapon()
		end

		table.insert(ent.DeathRecap, {
			Inflictor = IsValid(atck) and atck:GetClass() or "nothing",
			Attacker = IsValid(inflictor) and inflictor:GetClass() or "Unknown",
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
		displayed_recap = false
	end)

	hook.Add("HUDShouldDraw", tag, function(name)
		if name == "CHudDamageIndicator" then
		   return false
		end
	end)

	local orange_color = Color(244, 135, 2)
	local white_color = Color(255, 255, 255)
	local red_color = Color(255, 0, 0)
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
		surface.SetTextColor(white_color)
		surface.SetTextPos(base_x, base_y - 75)
		surface.DrawText("DEATH RECAP")

		for i = 1, #recap do
			if i == 1 then
				surface.SetFont("MTADeathRecapKiller")
				surface.SetTextColor(white_color)
				surface.SetTextPos(base_x - 150, base_y + 5)
				surface.DrawText("KILLER")
			end

			local y = base_y + ((i - 1) * (h + 5))
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(base_x, y, w, h)
			surface.SetDrawColor(orange_color)
			surface.DrawOutlinedRect(base_x, y, w, h, 2)

			local atck_text = language.GetPhrase(recap[i].Attacker)
			local infl_text = "with " .. language.GetPhrase(recap[i].Inflictor)
			local dmg_text = tostring(recap[i].Damage) .. " DMG"
			local tw = 100

			surface.SetFont("MTADeathRecapNameFont")
			surface.SetTextColor(white_color)
			surface.SetTextPos(base_x + 5, y + 5)
			surface.DrawText(atck_text)
			local atck_tw, _ = surface.GetTextSize(atck_text)

			surface.SetFont("DermaDefaultBold")
			surface.SetTextColor(orange_color)
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

			surface.SetTextColor(red_color)
			surface.SetTextPos(tw, y + 10)
			surface.DrawText(dmg_text)
		end
	end)
end