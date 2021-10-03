local red_color = Color(255, 0, 0)
local white_color = Color(255, 255, 255)
local TAG = "MTAGoliath"
local NET_GOLIATH = "mta_goliath"
local GOLIATH_MAX_HEALTH = 10000
local DIST_THRESHOLD = 1500
local RESPAWN_TIME = 300 -- 5 mins

if SERVER then
	util.AddNetworkString(NET_GOLIATH)

	local SPAWN_POS = Vector (-2108, 2889, 5416)
	local function spawn_goliath()
		local npc = ents.Create("npc_hunter")
		npc:Give("")
		npc:SetModelScale(3)
		npc:SetPos(SPAWN_POS + Vector(0,0,100))
		npc:Spawn()
		npc:Activate()
		npc:SetMaterial("models/xqm/lightlinesred")
		npc:SetHealth(GOLIATH_MAX_HEALTH)
		npc:DropToFloor()
		npc.PhysgunDisabled = true
		npc.dont_televate = true
		npc.ms_notouch = true
		npc.Targets = {}
		npc.IsGoliath = true

		local phys = npc:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableCollisions(false)
		end

		timer.Create(TAG, 10, 0, function()
			if not IsValid(npc) then return end
			if not IsValid(npc:GetEnemy()) then return end
			npc:ShockWave()
		end)

		npc:AddRelationship("player D_NU 99")

		timer.Simple(1, function()
			net.Start(NET_GOLIATH)
				net.WriteBool(true)
				net.WriteEntity(npc)
			net.Broadcast()
		end)

		function npc:ShockWave()
			util.ScreenShake(self:GetPos(), 5, 5, 10, DIST_THRESHOLD)

			local shockwave = ents.Create("mta_mobile_emp")
			shockwave:SetPos(self:GetPos())
			shockwave:Spawn()

			SafeRemoveEntityDelayed(shockwave, 2)
			shockwave:SetColor(red_color)
			shockwave:SetModelScale(1000, 2)

			local dmg_info = DamageInfo()
			dmg_info:SetInflictor(shockwave)
			dmg_info:SetAttacker(self)
			dmg_info:SetDamage(25)
			dmg_info:SetDamageType(DMG_SHOCK)

			for _, ent in ipairs(ents.FindInSphere(shockwave:GetPos(), DIST_THRESHOLD)) do
				if (ent:IsPlayer() or ent:IsNPC()) and ent ~= self then
					ent:TakeDamageInfo(dmg_info)
				end
			end
		end

		function npc:Obliterate(ent)
			if not IsValid(ent) then return end
			if not ent:IsPlayer() and not ent:IsNPC() then return end

			local dmg = DamageInfo()
			dmg:SetDamage(10)
			dmg:SetDamageForce(VectorRand() * 100)
			dmg:SetDamageType(DMG_DISSOLVE)
			dmg:SetAttacker(self)
			dmg:SetInflictor(self)

			local old_health = ent:Health()
			ent:TakeDamageInfo(dmg)

			timer.Simple(0, function()
				if not IsValid(ent) then return end
				if ent:Health() == old_health then
					ent:KillSilent()
					hook.Run("PlayerDeath", ent, self, self)
				end
			end)
		end

		function npc:AttachCore(parent)
			local core = ents.Create("meta_core")
			core:SetPos(parent:GetPos())
			core:SetParent(parent)
			core:Spawn()
			core:SetColor(red_color)
			core:SetSize(3)

			parent.IsThrownCore = true

			core.Dissolver:SetKeyValue("dissolvetype", "2")
			core.Trigger.Touch = function(_, ent)
				if ent:GetClass() == "meta_core" or ent.IsThrownCore then return end
				if not IsValid(self) then return end
				if ent == self then return end

				local dist = ent:WorldSpaceCenter():Distance(core:GetPos()) / 2 / 4
				if dist <= core:GetSize() and (ent:IsPlayer() or ent:IsNPC()) then
					self:Obliterate(ent)
				end
			end

			core.Think = function(core_ent)
				core_ent:NextThink(CurTime())

				if IsValid(parent) and not util.IsInWorld(parent:GetPos()) then
					parent:Remove()
					return
				end

				local core_phys = parent:GetPhysicsObject()
				if not IsValid(core_phys) then return end
				local vel = core_phys:GetVelocity()
				core_phys:SetVelocity(vel:GetNormalized() * 9999)

				core_ent:NextThink(CurTime())
				return true
			end
		end

		function npc:ThrowCore()
			self:EmitSound("ut2k4/shockrifle/altfire.wav")

			local ent = ents.Create("prop_physics")
			if not IsValid(ent) then return end
			ent:SetModel("models/hunter/blocks/cube025x025x025.mdl")
			ent:SetPos(self:EyePos() + (self:GetAimVector() * 150))
			ent:Spawn()
			ent:SetNoDraw(true)

			self:AttachCore(ent)

			local core_phys = ent:GetPhysicsObject()
			if not IsValid(core_phys) then ent:Remove() return end

			core_phys:SetVelocity(self:GetAimVector() * 9999)
			core_phys:EnableGravity(false)
			core_phys:EnableCollisions(true)

			SafeRemoveEntityDelayed(ent, 3)
		end

		local next_core = 0
		hook.Add("Think", npc, function(self)
			local time = CurTime()

			if time > next_core then
				if IsValid(self:GetEnemy()) and self:Health() > 0 then
					self:ThrowCore()
				end

				next_core = time + 0.1
			end
		end)

		hook.Add("EntityTakeDamage", npc, function(self, ent, dmg_info)
			local attacker = dmg_info:GetAttacker()
			local inflictor = dmg_info:GetInflictor()
			if ent == self and IsValid(attacker) then
				if inflictor:GetClass():match("combine_ball") or inflictor == game.GetWorld() then return true end
				if attacker:IsPlayer() and not attacker:Alive() then return true end
				if attacker:WorldSpaceCenter():Distance(self:WorldSpaceCenter()) > DIST_THRESHOLD then return true end

				if attacker:GetClass() == "crossbow_bolt"
					and attacker.CPPIGetOwner
					and IsValid(attacker:CPPIGetOwner())
					and attacker:CPPIGetOwner():WorldSpaceCenter():Distance(self:WorldSpaceCenter()) > DIST_THRESHOLD
				then
					return true
				end

				self:AddEntityRelationship(attacker, D_HT, 99)
				self.Targets[attacker] = true

				if attacker:IsPlayer() then
					MTA.IncreasePlayerFactor(attacker, 1)
					MTA.DisallowPlayerEscape(attacker)
				end
			end
		end)

		hook.Add("PlayerShouldTakeDamage", npc, function(self, ply, attacker)
			if attacker == self then
				return self.Targets[ply] or false
			end
		end)

		hook.Add("PlayerDeath", npc, function(self, ply)
			self.Targets[ply] = nil
			self:AddEntityRelationship(ply, D_NU, 99)
			MTA.AllowPlayerEscape(ply)
		end)

		hook.Add("OnNPCKilled", npc, function(self, ent, attacker)
			if self ~= ent then return end
			if not attacker:IsPlayer() then return end

			MTA.ChatPrint(player.GetAll(), attacker, white_color, " has slain the ", red_color, "GOLIATH")

			net.Start(NET_GOLIATH)
			net.WriteBool(false)
			net.Broadcast()

			for ply, _ in pairs(self.Targets) do
				MTA.AllowPlayerEscape(ply)
				MTA.GivePoints(ply, 250)
				hook.Run("MTAGoliathKilled", ply, self)
			end

			timer.Simple(RESPAWN_TIME, spawn_goliath)
		end)

		MTA.ChatPrint(player.GetAll(), MTA.TextColor, "A ", MTA.OldValueColor, " GOLIATH ", MTA.TextColor, "has been ", MTA.OldValueColor, "deployed")
	end

	hook.Add("InitPostEntity", TAG, function()
		timer.Simple(RESPAWN_TIME, spawn_goliath)
	end)

	hook.Add("PostCleanupMap", TAG, function()
		timer.Simple(RESPAWN_TIME, spawn_goliath)
	end)
end

if CLIENT then
	local display = false
	local goliath
	net.Receive(NET_GOLIATH, function()
		display = net.ReadBool()
		if display then
			goliath = net.ReadEntity()
			surface.PlaySound("mvm/giant_heavy/giant_heavy_entrance.wav")
		end
	end)

	surface.CreateFont("MTAGoliathFont", {
		font = "Orbitron",
		size = 32,
		extended = true,
	})

	local old_health = GOLIATH_MAX_HEALTH
	local width, height = 400, 40
	local margin = 2
	local next_dist_check = 0
	hook.Add("HUDPaint", TAG, function()
		if IsValid(goliath) then
			if CurTime() > next_dist_check then
				display = goliath:GetPos():Distance(LocalPlayer():GetPos()) < DIST_THRESHOLD
				next_dist_check = CurTime() + 1
			end

			if not display then return end

			local screen_pos = goliath:WorldSpaceCenter():ToScreen()
			local x, y = screen_pos.x, screen_pos.y

			surface.SetDrawColor(MTA.PrimaryColor)
			surface.DrawOutlinedRect(x - width / 2, y - height / 2, width, height, 2)

			surface.SetDrawColor(MTA.BackgroundColor)
			surface.DrawRect(x - width / 2, y - height / 2, width, height)

			local health = goliath:Health()
			local health_width = width / GOLIATH_MAX_HEALTH * health
			surface.SetDrawColor(MTA.PrimaryColor)
			surface.DrawRect(x - width / 2 + margin, y - height / 2 + margin, health_width, height - margin * 2)

			if old_health ~= health then
				surface.SetDrawColor(MTA.DangerColor)
				surface.DrawRect(x - width / 2 + margin + health_width, y - height / 2 + margin, width / GOLIATH_MAX_HEALTH * (old_health - health), height - margin * 2)
				old_health = old_health - (old_health - health) / 50
			end

			surface.SetTextColor(white_color)
			surface.SetFont("MTAGoliathFont")

			local text = ("GOLIATH %d"):format(math.ceil((health / GOLIATH_MAX_HEALTH) * 100)) .. "%"
			local tw, _ = surface.GetTextSize(text)
			surface.SetTextPos(x - width / 2 + margin + (health_width < (tw + height) and margin or health_width - tw), y - height / 2 + margin + height + margin)
			surface.DrawText(text)
		end
	end)
end