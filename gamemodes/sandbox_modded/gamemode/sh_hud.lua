if SERVER then
	resource.AddFile("materials/vgui/mta_hud/maps/rp_unioncity.vmt")
	resource.AddFile("materials/vgui/mta_hud/maps/rp_unioncity.vtf")

	resource.AddFile("materials/vgui/mta_hud/hpicon.vmt")
	resource.AddFile("materials/vgui/mta_hud/hpicon.vtf")
	resource.AddFile("materials/vgui/mta_hud/apicon.vmt")
	resource.AddFile("materials/vgui/mta_hud/apicon.vtf")
	resource.AddFile("materials/vgui/mta_hud/secammo.vmt")
	resource.AddFile("materials/vgui/mta_hud/secammo.vtf")
	resource.AddFile("materials/vgui/mta_hud/ammobg.vmt")
	resource.AddFile("materials/vgui/mta_hud/ammobg.vtf")
	resource.AddFile("resource/fonts/altehaasgroteskbold.ttf")
	resource.AddFile("resource/fonts/orbitron black.ttf")
	return
end

MTAHud = {}

MTAHud.Config = {
	ScrRatio = ScrH() / 1080,
	HudPos = CreateClientConVar("mta_hud_pos", "0", true, false)
}

MTAHud.Vars = {
	LastAngs = EyeAngles(),
	AngDeltaP = 0,
	AngDeltaY = 0,
	LastTranslateP = 0,
	LastTranslateY = 0
}

MTAHud.UpdateVars = function(self)
	local vel = LocalPlayer():GetAbsVelocity()

	local curAngs = EyeAngles()

	self.Vars.AngDeltaP = math.AngleDifference(self.Vars.LastAngs.p, curAngs.p)
	self.Vars.AngDeltaY = math.AngleDifference(self.Vars.LastAngs.y, curAngs.y)

	self.Vars.LastAngs = curAngs

	self.Vars.LastTranslateP = Lerp(FrameTime() * 5, self.Vars.LastTranslateP, self.Vars.AngDeltaP)
	self.Vars.LastTranslateY = Lerp(FrameTime() * 5, self.Vars.LastTranslateY, self.Vars.AngDeltaY)

	if vel.z ~= 0 then
		self.Vars.LastTranslateP = self.Vars.LastTranslateP + (math.Clamp(vel.z, -100, 100) * FrameTime() * 0.2)
	end
end

MTAHud.Components = {}
MTAHud.DrawComponents = function(self)
	for k, v in pairs(self.Components) do
		v:Draw()
	end
end
MTAHud.AddComponent = function(self, name, func)
	self.Components[name] = func()
end
MTAHud.RemoveComponent = function(self, name)
	self.Components[name] = nil
end

hook.Add("HUDPaint", "mta_hud", function()
	MTAHud:UpdateVars()
	MTAHud:DrawComponents()
end)

local elements_to_hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true
}

-- Hide default hud
hook.Add("HUDShouldDraw", "mta_hud", function(element)
	if elements_to_hide[element] then
		return false
	end
end)

local function DrawHud()
	local Transitions = {}
	Transitions.LostTotHealth = {}
	Transitions.LostHealth = {}
	Transitions.LostArmor = {}
	Transitions.GainHealth = {}
	Transitions.GainArmor = {}

	local StoredMaxAmmo = {}

	local MaxHp = 0
	local MaxAp = 0
	local SetMaxHp = 100

	local ReachMaxHp = 100
	local ReachMaxAp = 100

	local HpGainAlpha = 0
	local ApGainAlpha = 0
	local ArmorClamp = 0
	local ApBg = 0

	local CNextTimer = 0
	local AmNextTimer = 0
	local NNextTimer = 0

	-- local HpFlashAlpha = 0
	local AmmoLocation = 0

	local WeaponNameAlpha = 0
	local AmmoAlpha = 0

	local ClipShakeH = 0
	local ClipShakeW = 0
	local BgClipShakeH = 0
	local BgClipShakeW = 0

	local ClipShakeTime = 0
	local BgClipShakeTime = 0

	local ClipAlpha = 255
	local ClipAlphaDir = 0
	local ClipAlphaVel = 0

	-- local AmmoShakeH = 0
	-- local AmmoShakeW = 0
	-- local AmmoShakeTime = 0

	local AmmoAnimTime = 0
	-- local AmmoAnimTime2 = 0
	local AmmoAnimStep = 0

	local AmmoFlash = 0

	-- Setting up textures
	local HpIcon = surface.GetTextureID("vgui/mta_hud/hpicon")
	local ApIcon = surface.GetTextureID("vgui/mta_hud/apicon")
	local SecAmmoIcon = surface.GetTextureID("vgui/mta_hud/secammo")
	local AmmoCountBG = surface.GetTextureID("vgui/mta_hud/ammobg")

	local function LoadFonts()
		surface.CreateFont("Font Ammo", {
			font = "Alte Haas Grotesk",
			size = 34 * MTAHud.Config.ScrRatio,
			weight = 500,
			blursize = 0,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false
		})

		surface.CreateFont("Font Bars", {
			font = "Alte Haas Grotesk",
			size = 22 * MTAHud.Config.ScrRatio,
			weight = 500,
			blursize = 0,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false
		})

		surface.CreateFont("Font Name", {
			font = "Alte Haas Grotesk",
			size = 26 * MTAHud.Config.ScrRatio,
			weight = 500,
			blursize = 0,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false
		})

		surface.CreateFont("Font Clip", {
			font = "Orbitron",
			size = 45 * MTAHud.Config.ScrRatio,
			weight = 500,
			blursize = 0,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false
		})
	end

	LoadFonts()

	local function CalculateLossTransition(value, name)
		if not Transitions[name].Lost then
			Transitions[name].Lost = 0
			Transitions[name].VelocityMult = 0
			Transitions[name].LossVelocity = 0
			Transitions[name].DamageDelay = 0
			Transitions[name].DamageValue = 0
			Transitions[name].LossFreeze = 0

			Transitions[name].LastDamage = 0
			Transitions[name].LastDamageFade = 0
			Transitions[name].LastDamageAnim = 0
			Transitions[name].LastDamageAnimSpeed = 0
		end

		local Trans = Transitions[name]

		if name == "LostArmor" then
			Trans.VelocityMult = 5
		else
			Trans.VelocityMult = 1.5
		end

		Trans.LossVelocity = math.Clamp((Trans.Lost - value) * Trans.VelocityMult, 1, 30000)

		if value and Trans.Lost then
			if Trans.Lost > value then
				Trans.Lost = Trans.Lost - RealFrameTime() * Trans.LossVelocity
				if Trans.Lost < value then
					Trans.Lost = value
				end
			elseif Trans.Lost < value then
				Trans.Lost = value
			end
		end

		-- Last inflicted damage overlap
		if Trans.LossFreeze == 0 then
			Trans.LastDamageFade = math.Clamp(Trans.LastDamageFade - RealFrameTime() * 500, 0, 255)
		end

		if Trans.DamageDelay < CurTime() then
			Trans.LossFreeze = 0
		end

		if Trans.DamageValue > value then
			Trans.LossFreeze = 1
			Trans.LastDamage = Trans.DamageValue
			Trans.DamageValue = value
			Trans.DamageDelay = CurTime() + 0.4
			Trans.LastDamageFade = 255
			Trans.LastDamageAnim = 0
		end

		if Trans.DamageValue <= value then
			Trans.DamageValue = value
		end

		Trans.LastDamageAnimSpeed = math.max((2.5 - Trans.LastDamageAnim) * 4, 1)

		if Trans.LastDamageFade > 0 then
			Trans.LastDamageAnim = Trans.LastDamageAnim + RealFrameTime() * Trans.LastDamageAnimSpeed
		end

		return Trans.Lost, Trans.LastDamage, Trans.LastDamageFade, Trans.LastDamageAnim
	end

	local function CalculateGainTransition(value, name, default)
		if not Transitions[name].Gain then
			Transitions[name].Gain = 0
			Transitions[name].GainDifference = 0
			Transitions[name].GainDelay = 0
			Transitions[name].GainFreeze = 0
			Transitions[name].GainValue = 0
			Transitions[name].GainAlpha = 0
		end

		local Transition = Transitions[name]

		if not LocalPlayer():Alive() then
			Transition.Gain = default
		end

		if Transition.Gain and value then
			if Transition.Gain > value then
				Transition.Gain = value
			elseif Transition.Gain < value and Transition.GainAlpha == 0 then
				Transition.Gain = value
			end
		end

		Transition.HpGainDifference = value - Transition.Gain

		if Transition.GainDelay < CurTime() then
			Transition.GainFreeze = 0
			Transition.GainAlpha = math.Clamp(Transition.GainAlpha - RealFrameTime() * 500, 0, 250)
		end

		if Transition.Gain == value or (Transition.HealthGainValue < value and (Transition.GainAlpha > 0 or Transition.GainFreeze == 1)) then
			Transition.GainFreeze = 1
			Transition.GainDelay = CurTime() + 0.6
			Transition.HealthGainValue = value
			Transition.GainAlpha = 250
		end

		return Transition.HpGainDifference, Transition.GainAlpha
	end

	local HudPosXLeft = MTAHud.Config.ScrRatio * 10
	local HudPosXRight = ScrW() - (MTAHud.Config.ScrRatio * 450)
	local HudPosYLeft = ScrH() - (MTAHud.Config.ScrRatio * 190)
	local HudPosYRight = ScrH() - (MTAHud.Config.ScrRatio * 220)

	local Separated = 1

	local FixedAp = 0
	local BarsDigits = 1

	local HpBarLength = 180 * MTAHud.Config.ScrRatio
	local HpBarHeight = 18 * MTAHud.Config.ScrRatio

	local HealthBarPercentageStartW = 50
	local HealthBarPercentageStartH = 125 * MTAHud.Config.ScrRatio

	local MatVec = Vector()

	return {
		Draw = function()
			-- TODO: Clean this up

			local player = LocalPlayer()
			local Weapon = player:GetActiveWeapon()

			if not player:Alive() then
				StoredMaxAmmo = {}
			end

			-- Maximum value
			local KeepExceed = 0

			local ConMaxHp = 0
			local ConMaxAp = 100

			if ConMaxHp > 0 then
				SetMaxHp = ConMaxHp
			elseif ConMaxHp <= 0 then
				SetMaxHp = player:GetMaxHealth()
			end

			SetMaxAp = ConMaxAp

			if not PlayerMaxAp then
				PlayerMaxAp = 100
			end

			if KeepExceed == true then
				if player:Health() > ReachMaxHp then
					ReachMaxHp = player:Health()
				end

				if player:Armor() > ReachMaxAp then
					ReachMaxAp = player:Armor()
				end

				if ReachMaxHp > MaxHp then
					MaxHp = ReachMaxHp
				end

				if ReachMaxAp > MaxAp then
					MaxAp = ReachMaxAp
				end
			else
				if player:Health() > SetMaxHp then
					MaxHp = player:Health()
				else
					MaxHp = SetMaxHp
				end

				if player:Armor() > SetMaxAp then
					MaxAp = player:Armor()
				else
					MaxAp = SetMaxAp
				end
			end

			if not player:Alive() then
				ReachMaxHp = 0
				ReachMaxAp = 0
				MaxHp = SetMaxHp
				MaxAp = SetMaxAp
			end

			local MaxTot = MaxHp + MaxAp

			local HpRatio = MaxHp / MaxTot
			local ApRatio = MaxAp / MaxTot

			if not player.DispHealth then
				player.DispHealth = 0
			end

			player.DispHealth = player:Health()

			local mat = Matrix()

			mat:SetField(2, 1, MTAHud.Config.HudPos:GetBool() and 0.1 or -0.1)

			MatVec.x = (MTAHud.Config.HudPos:GetBool() and HudPosXRight or HudPosXLeft) + (MTAHud.Vars.LastTranslateY * 2)
			MatVec.y = (MTAHud.Config.HudPos:GetBool() and HudPosYRight or HudPosYLeft) + (MTAHud.Vars.LastTranslateP * 3)

			mat:SetTranslation(MatVec)

			cam.PushModelMatrix(mat)

			-- Background elements
			if player:Alive() then
				-- Ammo background
				local x, y, w, h = HealthBarPercentageStartW,
					HealthBarPercentageStartH - (45 * MTAHud.Config.ScrRatio),
					HpBarLength * 2 + (Separated * 4),
					39 * MTAHud.Config.ScrRatio

				surface.SetDrawColor(0, 0, 0, 150)
				surface.DrawRect(x, y, w, h)

				surface.SetDrawColor(244, 135, 2)
				surface.DrawOutlinedRect(x, y, w, h, 2)
			end
			-- END of background elements

			-- Ammo counters

			if Weapon:IsValid() then
				-- Setting up variables

				local Clip = Weapon:Clip1()
				local MaxClip = Weapon:GetMaxClip1()
				local Ammo = player:GetAmmoCount(Weapon:GetPrimaryAmmoType())
				local SecAmmo = player:GetAmmoCount(Weapon:GetSecondaryAmmoType())
				local AmmoType = LocalPlayer():GetActiveWeapon():GetPrimaryAmmoType()
				-- local SecAmmoType = LocalPlayer():GetActiveWeapon():GetSecondaryAmmoType()
				-- local GrenadeCount = LocalPlayer():GetAmmoCount("grenade")
				local WeaponName = Weapon:GetPrintName()

				-- Weapons that doesn't have magazine

				if Weapon:GetMaxClip1() == -1 then
					StoredMaxAmmo[WeaponName] = StoredMaxAmmo[WeaponName] or Ammo
					if Ammo > StoredMaxAmmo[WeaponName] then
						StoredMaxAmmo[WeaponName] = Ammo
					end

					Clip = Ammo
					MaxClip = StoredMaxAmmo[WeaponName]
				end

				-- Location calculation

				-- local AmmoCountLocationW = HealthBarPercentageStartW + (HpBarLength * 2) - (232 * MTAHud.Config.ScrRatio) + (Separated * 4)
				-- local AmmoCountLocationH = HealthBarPercentageStartH - (59 * MTAHud.Config.ScrRatio)

				-- local AmmoIconW = 256 * MTAHud.Config.ScrRatio
				-- local AmmoIconH = 64 * MTAHud.Config.ScrRatio

				-- Texture scissor coordinates

				-- AmmoRectStartX = AmmoCountLocationW - (5 * MTAHud.Config.ScrRatio)
				-- AmmoRectStartY = AmmoCountLocationH + (14 * MTAHud.Config.ScrRatio)
				-- AmmoRectStopX = AmmoCountLocationW + (232 * MTAHud.Config.ScrRatio)
				-- AmmoRectStopY = AmmoCountLocationH + (53 * MTAHud.Config.ScrRatio)

				-- If custom ammo type, display SMG icon

				if AmmoType > 10 or AmmoType == 9 then
					AmmoType = 4
				end

				-- Alternative AR2 ammo type

				local AltAr2 = 0

				if AmmoType == 1 and AltAr2 == true then
					AmmoType = 20
				end

				AmmoFlash = AmmoType

				-- Setting up Ammo animation variables

				CurrentTimer = CurTime()
				ClipNum = Clip
				AmmoNum = Ammo
				AmmoTarget = 100

				if not NextFire then
					NextFire = 0
				end

				AmmoVel = 44 / NextFire * MTAHud.Config.ScrRatio
				if AmmoVel <= 0 then
					AmmoVel = 300
				end

				AmmoLocation = math.Clamp(AmmoLocation - RealFrameTime() * AmmoVel, 0, 100)

				if not ClipNumNew then
					ClipNumNew = 0
				end

				if CurrentTimer < CNextTimer then
					ClipNumNew = Clip
				end

				-- Setting up reload animation reading (Thanks to Darky's Arx HUD, that helped me to figure out how to detect animation sequence https://steamcommunity.com/sharedfiles/filedetails/?id=2360363900)

				local ViewModel, Reloading

				if Weapon.Wep then --  FA:S 2.0
					ViewModel = Weapon.Wep
				elseif Weapon.CW_VM then --  CW 2.0
					ViewModel = Weapon.CW_VM
				else --  ArcCW, TFA or any other weapon pack
					ViewModel = LocalPlayer():GetViewModel()
				end

				local SequenceName = ViewModel:GetSequenceName(ViewModel:GetSequence())
				local SequenceCycle = -(ViewModel:GetCycle()) + 1

				if string.find(string.lower(SequenceName), "reload") and not Reloading or string.find(string.lower(SequenceName), "wet") and not Reloading then
					Reloading = true
				end

				if Reloading and ViewModel:GetCycle() >= 0.97 then
					Reloading = false
				end

				-- Shake clip counter
				if (ClipNum ~= ClipNumNew) or (ClipNum < 0 and AmmoNum ~= AmmoNumNew) then
					CNextTimer = CurTime() + 0.05
					ClipShakeTime = CurTime() + 0.1
				end

				if WeaponName ~= WeaponNameNew then
					CNextTimer = CurTime() + 0.05
					BgClipShakeTime = CurTime() + 0.1
					ClipShakeTime = CurTime()
				end

				if not AmmoNumNew then
					AmmoNumNew = 0
				end

				if CurrentTimer < AmNextTimer then
					AmmoNumNew = Ammo
				end

				if AmmoNum ~= AmmoNumNew then
					AmNextTimer = CurTime() + 0.05
				end

				ClipShakeH = math.Rand(-200 * MTAHud.Config.ScrRatio, 200 * MTAHud.Config.ScrRatio) * math.min(CurTime() - ClipShakeTime, 0)
				ClipShakeW = math.Rand(-200 * MTAHud.Config.ScrRatio, 200 * MTAHud.Config.ScrRatio) * math.min(CurTime() - ClipShakeTime, 0)
				BgClipShakeH = math.Rand(-100 * MTAHud.Config.ScrRatio, 100 * MTAHud.Config.ScrRatio) * math.min(CurTime() - BgClipShakeTime, 0)
				BgClipShakeW = math.Rand(-100 * MTAHud.Config.ScrRatio, 100 * MTAHud.Config.ScrRatio) * math.min(CurTime() - BgClipShakeTime, 0)

				-- Ammo Consuption Animation
				if ((ClipNum < ClipNumNew) and (WeaponName == WeaponNameNew)) or ((AmmoNum < AmmoNumNew) and (WeaponName == WeaponNameNew) and ClipNum < 0) then
					AmmoAnimStep = 1
					AmmoAnimTime = CurTime() + 0.02
					NextFire = Weapon:GetNextPrimaryFire() - CurTime()
				end

				-- Step 1: Bullet slash and shading
				if AmmoAnimStep == 1 then
					AmmoFlash = AmmoFlash + 100
					AmmoShakeTime = CurTime() + 0.05
					AmmoLocation = 0
				end

				-- Step 2: Stop shading and place bullet at bottom
				if (CurrentTimer > AmmoAnimTime) and AmmoAnimStep == 1 then
					AmmoAnimStep = 2
					AmmoLocation = (44 * MTAHud.Config.ScrRatio)
				end

				-- Reset to step 0
				if (CurrentTimer > AmmoAnimTime) and AmmoAnimStep == 2 then
					AmmoAnimStep = 0
				end

				-- Ammo Reload Flash
				if ((ClipNum > ClipNumNew) or (WeaponName ~= WeaponNameNew) and AmmoType >= 0) then
					AmmoAnimStep = 11
					AmmoAnimTime = CurTime() + 0.1
					AmmoLocation = 0
				end

				if AmmoAnimStep == 11 then
					AmmoFlash = AmmoFlash + 100
					AmmoShakeTime = CurTime() + 0.05
				end

				if (CurrentTimer > AmmoAnimTime) and AmmoAnimStep == 11 then
					AmmoAnimStep = 0
				end

				-- Empty ammo flickering
				if (Clip == 0 and AmmoAnimStep == 0) or (Clip == -1 and Ammo == 0) then
					AmmoFade = math.Rand(25, 75)
					AmmoLocation = 0
				else
					AmmoFade = 255
				end

				-- Ammo reload animation (thanks to )

				if Reloading == true and AmmoAnimStep == 0 then
					AmmoLocation = (44 * MTAHud.Config.ScrRatio) * SequenceCycle
					AmmoFade = math.Rand(25, 75)
				end

				-- Ammo shaking coordinates

				-- AmmoShakeW = math.Rand(-150 * MTAHud.Config.ScrRatio, 150 * MTAHud.Config.ScrRatio) * math.min(CurTime() - AmmoShakeTime, 0)
				-- AmmoShakeH = math.Rand(-150 * MTAHud.Config.ScrRatio, 150 * MTAHud.Config.ScrRatio) * math.min(CurTime() - AmmoShakeTime, 0)

				-- Ammo Counter + weapon name
				WeaponNameAlpha = math.Clamp(WeaponNameAlpha - RealFrameTime() * 250, 0, 250)
				WeaponNameAlphaFlick = math.random(WeaponNameAlpha - 50, WeaponNameAlpha)
				AmmoAlpha = math.Clamp(AmmoAlpha + RealFrameTime() * 250, 0, 250)

				if not WeaponNameNew then
					WeaponNameNew = ""
				end

				if CurrentTimer < NNextTimer then
					WeaponNameNew = WeaponName
				end

				if (WeaponName ~= WeaponNameNew) then
					NNextTimer = CurTime() + 0.05
					AmmoAlphaDelay = CurTime() + 1
					AmmoLocation = 60
				end

				if (CurTime() < AmmoAlphaDelay) or (AmmoType <= 0) or (Weapon:GetMaxClip1() == -1) then
					WeaponNameAlpha = 250
					AmmoAlpha = 0
				end

				if Ammo > 0 then
					draw.SimpleText(Ammo, "Font Ammo",
						HealthBarPercentageStartW + (10 * MTAHud.Config.ScrRatio) + (ClipShakeW / 2),
						HealthBarPercentageStartH - (43 * MTAHud.Config.ScrRatio) + (ClipShakeH / 2),
						Color(255, 255, 255, AmmoAlpha),
						0,
						0
					)
				else
					draw.SimpleText("EMPTY", "Font Ammo",
						HealthBarPercentageStartW + (10 * MTAHud.Config.ScrRatio) + (ClipShakeW / 2),
						HealthBarPercentageStartH - (43 * MTAHud.Config.ScrRatio) + (ClipShakeH / 2),
						Color(255, 255, 255, AmmoAlpha),
						0,
						0
					)
				end

				draw.SimpleText(WeaponName:upper(), "Font Name",
					HealthBarPercentageStartW + (8 * MTAHud.Config.ScrRatio),
					HealthBarPercentageStartH - (39 * MTAHud.Config.ScrRatio),
					Color(255, 255, 255, WeaponNameAlphaFlick),
					0,
					0
				)

				-- Clip Counter
				ClipLocationLimit = (HpBarLength + (Separated * 2)) * 2
				ClipLocation = math.Clamp(Clip / MaxClip * ClipLocationLimit, 0, ClipLocationLimit + 20)
				ClipPercent = Clip / MaxClip * 100
				ClipLocationV = HealthBarPercentageStartH - (110 * MTAHud.Config.ScrRatio)

				if (not ClipContent) then
					ClipContent = Clip
				end

				if (not ClipHundred) then
					ClipHundred = 0
				end

				if AmmoType > -1 then
					-- Clip BG color

					if ClipPercent > 25 then
						ACR = 255
						ACG = 255
						ACB = 255
					else
						ACR = 255
						ACG = 175
						ACB = 30
					end

					-- Empty clip alpha

					if Clip == 0 then
						if ClipAlpha <= 00 then
							ClipAlphaDir = 1
						elseif ClipAlpha >= 255 then
							ClipAlphaDir = 2
						end

						if ClipAlphaDir == 1 then
							ClipAlphaVel = RealFrameTime() * 300
						elseif ClipAlphaDir == 2 then
							ClipAlphaVel = -RealFrameTime() * 300
						end

						ClipAlpha = math.Clamp(ClipAlpha + ClipAlphaVel, 0, 255)
					else
						ClipAlpha = 255
						ClipAlphaDir = 0
						ClipAlphaVel = 0
					end

					-- Ghost clip trail

					if (not LostClip) then
						LostClip = 0
					end

					LostClipVelocity = math.Clamp((LostClip - ClipLocation) * 4, 1, 30000)

					if ClipLocation and LostClip then
						if LostClip > ClipLocation then
							LostClip = LostClip - RealFrameTime() * LostClipVelocity
							if LostClip < ClipLocation then
								LostClip = ClipLocation
							end
						elseif (LostClip < ClipLocation) then
							LostClip = ClipLocation
						end
					end

					if WeaponName ~= WeaponNameNew then
						LostClip = ClipLocation
					end

					-- Drawing BG
					surface.SetTexture(AmmoCountBG)
					surface.SetDrawColor(ACR, ACG, ACB, 255)
					surface.DrawTexturedRect(
						HealthBarPercentageStartW - (36 * MTAHud.Config.ScrRatio) + ClipLocation + BgClipShakeW,
						ClipLocationV + BgClipShakeH,
						70 * MTAHud.Config.ScrRatio,
						54 * MTAHud.Config.ScrRatio
					)

					-- Drawing text
					if Clip >= 100 then
						-- ClipContent = Clip
						local mult = 10 ^ -2
						ClipHundred = math.floor(Clip * mult) / mult
						local roundClip = math.floor(Clip - ClipHundred)
						if roundClip >= 10 then
							ClipContent = roundClip
						else
							ClipContent = "0" .. roundClip
						end
					elseif Clip >= 10 then
						ClipContent = Clip
					elseif Clip > 0 then
						ClipContent = "0" .. Clip
					elseif Clip <= 0 and Ammo > 0 then
						ClipContent = "'R'"
					elseif (Clip <= 0) and (Ammo <= 0) then
						ClipContent = "NO"
					end

					draw.SimpleText(
						ClipContent,
						"Font Clip",
						HealthBarPercentageStartW - 2 + ClipLocation + ClipShakeW + BgClipShakeW,
						ClipLocationV + (4 * MTAHud.Config.ScrRatio) + ClipShakeH + BgClipShakeH,
						Color(0, 0, 0, ClipAlpha),
						1,
						0
					)
					if Clip >= 100 then
						draw.SimpleText(
							"+" .. ClipHundred,
							"Font Bars",
							HealthBarPercentageStartW - 2 + ClipLocation + BgClipShakeW,
							ClipLocationV + (-17 * MTAHud.Config.ScrRatio) + BgClipShakeH,
							Color(255, 255, 255, ClipAlpha),
							1,
							0
						)
					end
					-- Secondary
					for i = 0, math.Clamp(SecAmmo - 1, -1, 2) do
						surface.SetTexture(SecAmmoIcon)
						surface.SetDrawColor(255, 255, 255, 255)
						surface.DrawTexturedRect(
							HealthBarPercentageStartW + (HpBarLength * 2) + (8 * MTAHud.Config.ScrRatio),
							HealthBarPercentageStartH - (45 * MTAHud.Config.ScrRatio) + (i * (16 * MTAHud.Config.ScrRatio)),
							21 * MTAHud.Config.ScrRatio,
							7 * MTAHud.Config.ScrRatio
						)
					end
				end
			end
			-- END of ammo counter drawing
			-- Health and armor drawing
			local BarsBg = 1
			local ApBgStyle = 1

			-- Lost total transition
			player.TotHealth = player:Health() + player:Armor()
			player.LostTotHealth, player.LastTotDamage, player.TotDamageFade, player.TotDamageAnim =
				CalculateLossTransition(player.TotHealth, "LostTotHealth")

			-- Lost Health transition
			player.LostHealth, player.LastHpDamage, player.HpDamageFade, player.HpDamageAnim =
				CalculateLossTransition(player:Health(), "LostHealth")

			-- Lost Armor transition
			player.LostArmor, player.LastApDamage, player.ApDamageFade, player.ApDamageAnim =
				CalculateLossTransition(player:Armor(), "LostArmor")

			-- Gained health transition
			player.HpGainDifference, HpGainAlpha = CalculateGainTransition(player:Health(), "GainHealth", 100)

			-- Gained Armor transition
			player.ApGainDifference, ApGainAlpha = CalculateGainTransition(player:Armor(), "GainArmor", 0)

			-- Flashing armor background
			local ApBgClr = 250

			if ApBgStyle == 0 then
				ApBg = math.random(10, 40)
			elseif ApBgStyle == 1 then
				ApBg = 20
			elseif ApBgStyle == 2 then
				ApBg = 225
				ApBgClr = 30
			else
				ApBg = 0
			end

			local HpLength = player:Health() / MaxHp * HpBarLength * HpRatio * 2
			local BgLength = HpBarLength * 2 + Separated * 4

			if Separated == 1 and FixedAp == true and BarsBg == true then
				BgLength = HpBarLength * HpRatio * 2
			end

			local LostBarStart = HealthBarPercentageStartW + player.TotHealth / MaxTot * HpBarLength * 2
			local LostBarLength = (player.LostTotHealth - player.TotHealth) / MaxTot * HpBarLength * 2
			local LastTotDamageLength = (player.LastTotDamage - player.TotHealth) / MaxTot * HpBarLength * 2
			local LastTotDamageAnim = math.sin(player.TotDamageAnim) * 10

			local HpGainStart =
				(HealthBarPercentageStartW + HpLength - (player.HpGainDifference / MaxHp) * HpRatio * 2) -
				(player.HpGainDifference / MaxHp * HpBarLength * HpRatio * 2)
			local HpGainLength = (player.HpGainDifference / MaxHp * HpBarLength * HpRatio * 2)

			local LostHpStart = HealthBarPercentageStartW + player:Health() / MaxHp * HpBarLength * HpRatio * 2
			local LostHpLength = (player.LostHealth - player:Health()) / MaxHp * HpBarLength * HpRatio * 2
			local LastHpDamageLength = (player.LastHpDamage - player:Health()) / MaxHp * HpBarLength * HpRatio * 2
			local LastHpDamageAnim = math.sin(player.HpDamageAnim) * 10

			local ApStart = 0
			local ApGainStart = 0
			local ApLength = player:Armor() / MaxAp * HpBarLength * ApRatio * 2
			local ApGainLength = player.ApGainDifference / MaxAp * HpBarLength * ApRatio * 2
			local LostApLength = (player.LostArmor - player:Armor()) / MaxAp * HpBarLength * ApRatio * 2
			local LostApStart = 0
			local LastApDamageLength = (player.LastApDamage - player:Armor()) / MaxAp * HpBarLength * ApRatio * 2
			local LastApDamageAnim = math.sin(player.ApDamageAnim) * 10

			if Separated == 0 then
				ApStart = HealthBarPercentageStartW + HpLength
				ApGainStart =
					(HealthBarPercentageStartW + player.TotHealth / MaxTot * HpBarLength * 2 -
					(player.ApGainDifference / MaxAp * ApRatio * 2)) -
					(player.ApGainDifference / MaxAp * HpBarLength * ApRatio * 2)
			else
				if FixedAp == false then
					ApStart = (HealthBarPercentageStartW + player.LostHealth / MaxHp * HpBarLength * HpRatio * 2) + (4 * MTAHud.Config.ScrRatio)
					ApGainStart =
						(HealthBarPercentageStartW + (player.LostHealth + player:Armor() + 2) / MaxHp * HpBarLength * HpRatio * 2 -
						(player.ApGainDifference / MaxAp * ApRatio * 2)) -
						(player.ApGainDifference / MaxAp * HpBarLength * ApRatio * 2)
					LostApStart = ApStart + player:Armor() / MaxAp * HpBarLength * ApRatio * 2
				else
					ApStart = (HealthBarPercentageStartW + HpBarLength * HpRatio * 2) + (4 * MTAHud.Config.ScrRatio)
					ApGainStart = ApStart + (player:Armor() / MaxAp * HpBarLength * ApRatio * 2) - 2 - ApGainLength
					LostApStart = ApStart + player:Armor() / MaxAp * HpBarLength * ApRatio * 2
				end
			end

			-- Bars drawing
			if player:Alive() then
				-- Background
				if BarsBg == true then
					surface.SetDrawColor(30, 30, 30, 225)
					surface.DrawRect(HealthBarPercentageStartW, HealthBarPercentageStartH, BgLength, HpBarHeight)
				end

				-- Armor bar background
				surface.SetDrawColor(ApBgClr, ApBgClr, ApBgClr, ApBg)
				surface.DrawRect(ApStart, HealthBarPercentageStartH, HpBarLength * ApRatio * 2, HpBarHeight)

				-- HpBar
				surface.SetDrawColor(244, 135, 2)
				surface.DrawRect(HealthBarPercentageStartW, HealthBarPercentageStartH, HpLength, HpBarHeight)

				-- ArmorBar
				surface.SetDrawColor(244, 135, 2)
				surface.DrawRect(ApStart, HealthBarPercentageStartH, ApLength, HpBarHeight)

				if Separated == 0 then
					-- LostBar
					surface.SetDrawColor(222, 166, 50, 255)
					surface.DrawRect(LostBarStart, HealthBarPercentageStartH, LostBarLength, HpBarHeight)

					-- Last damage
					surface.SetDrawColor(222, 166, 50, player.HpDamageFade)
					surface.DrawRect(LostBarStart, HealthBarPercentageStartH, LastTotDamageLength, HpBarHeight)

					-- Last damage animation
					surface.SetDrawColor(222, 166, 50, player.HpDamageFade / 4)
					surface.DrawRect(
						LostBarStart,
						HealthBarPercentageStartH - (LastTotDamageAnim * 2),
						LastTotDamageLength + (LastTotDamageAnim * 2),
						HpBarHeight + (LastTotDamageAnim * 4)
					)
				else
					-- LostArmor
					surface.SetDrawColor(222, 255, 255, 255)
					surface.DrawRect(LostApStart, HealthBarPercentageStartH, LostApLength, HpBarHeight)

					-- Last damage
					surface.SetDrawColor(222, 255, 255, player.ApDamageFade)
					surface.DrawRect(LostApStart - 1, HealthBarPercentageStartH, LastApDamageLength, HpBarHeight)

					-- Last damage animation
					surface.SetDrawColor(222, 255, 255, player.ApDamageFade / 4)
					surface.DrawRect(
						LostApStart - 1,
						HealthBarPercentageStartH - (LastApDamageAnim * 2),
						LastApDamageLength + (LastApDamageAnim * 2),
						HpBarHeight + (LastApDamageAnim * 4)
					)

					-- LostHealth
					surface.SetDrawColor(222, 166, 50, 255)
					surface.DrawRect(LostHpStart - 1, HealthBarPercentageStartH, LostHpLength, HpBarHeight)

					-- Last damage
					surface.SetDrawColor(222, 166, 50, player.HpDamageFade)
					surface.DrawRect(LostHpStart - 1, HealthBarPercentageStartH, LastHpDamageLength, HpBarHeight)

					-- Last damage animation
					surface.SetDrawColor(222, 166, 50, player.HpDamageFade / 4)
					surface.DrawRect(
						LostHpStart - 1,
						HealthBarPercentageStartH - (LastHpDamageAnim * 2),
						LastHpDamageLength + (LastHpDamageAnim * 2),
						HpBarHeight + (LastHpDamageAnim * 4)
					)
				end

				-- Hp Gain Bar
				surface.SetDrawColor(250, 250, 250, HpGainAlpha)
				surface.DrawRect(HpGainStart, HealthBarPercentageStartH, HpGainLength, HpBarHeight)

				-- Ap Gain Bar
				surface.SetDrawColor(250, 250, 250, ApGainAlpha)
				surface.DrawRect(ApGainStart + 2, HealthBarPercentageStartH, ApGainLength, HpBarHeight)

				-- Texts
				surface.SetTexture(HpIcon)
				surface.SetDrawColor(244, 135, 2)
				surface.DrawTexturedRect(
					HealthBarPercentageStartW,
					HealthBarPercentageStartH + (23 * MTAHud.Config.ScrRatio),
					18 * MTAHud.Config.ScrRatio,
					18 * MTAHud.Config.ScrRatio
				)

				draw.SimpleText(
					player:Health(),
					"Font Bars",
					HealthBarPercentageStartW + 30,
					HealthBarPercentageStartH + (20 * MTAHud.Config.ScrRatio)
				)

				if player.HpGainDifference > 0 then
					draw.SimpleText(
						"+" .. player.HpGainDifference,
						"Font Bars",
						HealthBarPercentageStartW + (4 * MTAHud.Config.ScrRatio),
						HealthBarPercentageStartH + (-3 * MTAHud.Config.ScrRatio),
						Color(255, 255, 255, HpGainAlpha),
						0,
						0
					)
				end

				if BarsDigits == true then
					draw.SimpleText(
						player:Health(),
						"Font Bars",
						HealthBarPercentageStartW + (22 * MTAHud.Config.ScrRatio),
						HealthBarPercentageStartH + (20 * MTAHud.Config.ScrRatio),
						Color(229, 45, 47, 255),
						0,
						0
					)
				end

				if BarsDigits == true then
					ArmorClamp = 55
				else
					ArmorClamp = 20
				end

				if MaxAp > 0 then
					surface.SetTexture(ApIcon)
					surface.SetDrawColor(244, 135, 2)
					surface.DrawTexturedRect(
						math.Clamp(ApStart, HealthBarPercentageStartW + (ArmorClamp * MTAHud.Config.ScrRatio), 100000),
						HealthBarPercentageStartH + (23 * MTAHud.Config.ScrRatio),
						18 * MTAHud.Config.ScrRatio,
						18 * MTAHud.Config.ScrRatio
					)

					draw.SimpleText(
						player:Armor(),
						"Font Bars",
						math.Clamp(ApStart, HealthBarPercentageStartW + (ArmorClamp * MTAHud.Config.ScrRatio), 100000) + 30,
						HealthBarPercentageStartH + (20 * MTAHud.Config.ScrRatio)
					)

					if player.ApGainDifference > 0 then
						draw.SimpleText(
							"+" .. player.ApGainDifference,
							"Font Bars",
							ApStart + (4 * MTAHud.Config.ScrRatio),
							HealthBarPercentageStartH + (-3 * MTAHud.Config.ScrRatio),
							Color(255, 255, 255, ApGainAlpha),
							0,
							0
						)
					end

					if BarsDigits == true then
						draw.SimpleText(
							player:Armor(),
							"Font Bars",
							math.Clamp(ApStart, HealthBarPercentageStartW + (ArmorClamp * MTAHud.Config.ScrRatio), 100000) + (22 * MTAHud.Config.ScrRatio),
							HealthBarPercentageStartH + (20 * MTAHud.Config.ScrRatio),
							Color(49, 194, 213, 255),
							0,
							0
						)
					end
				end
			end
			-- END of Health/Armor drawing
			cam.PopModelMatrix()
		end
	}
end

local function DrawMap()
	local function GetMapDrawPos(pos)
		local pxD = 1024 / 2
		local pyD = 1024 / 2

		local rx = -pos.y * (-pxD / -16384) + pxD
		local ry = pos.x * ((1024 - pyD) / -16384) + pyD

		return rx, ry
	end

	local function TranslatePoly(poly, ox, oy)
		local translated = {}

		for k, v in pairs(poly) do
			translated[k] = { x = ox + v.x, y = oy + v.y }
		end

		return translated
	end

	local function Rotate(ox, oy, px, py, angle)
		local qx = ox + math.cos(angle) * (px - ox) - math.sin(angle) * (py - oy)
		local qy = oy + math.sin(angle) * (px - ox) + math.cos(angle) * (py - oy)
		return qx, qy
	end

	local function RotatePoly(poly, angle, ox, oy)
		local rotated = {}

		for k, v in pairs(poly) do
			local rx, ry = Rotate(ox, oy, v.x, v.y, math.rad(angle))

			rotated[k] = { x = rx, y = ry }
		end

		return rotated
	end

	local MapImage = Material("vgui/mta_hud/maps/rp_unioncity")

	local MapPosXLeft = MTAHud.Config.ScrRatio * 30
	local MapPosXRight = ScrW() - (MTAHud.Config.ScrRatio * 280)
	local MapPosYLeft = MTAHud.Config.ScrRatio * 30
	local MapPosYRight = MTAHud.Config.ScrRatio * 50

	local MapW = 250 * MTAHud.Config.ScrRatio
	local MapH = 250 * MTAHud.Config.ScrRatio
	local MapZoom = MTAHud.Config.ScrRatio * 50

	local PlayerTriangle = {
		{ x = 0, y = 13 * MTAHud.Config.ScrRatio },
		{ x = -7 * MTAHud.Config.ScrRatio, y = 18 * MTAHud.Config.ScrRatio },
		{ x = 0, y = 0 },
		{ x = 7 * MTAHud.Config.ScrRatio, y = 18 * MTAHud.Config.ScrRatio }
	}

	local MatVec = Vector()

	return {
		Draw = function()
			local yaw = -EyeAngles().y

			local mat = Matrix()

			mat:SetField(2, 1, MTAHud.Config.HudPos:GetBool() and -0.08 or 0.08)

			MatVec.x = (MTAHud.Config.HudPos:GetBool() and MapPosXRight or MapPosXLeft) + (MTAHud.Vars.LastTranslateY * 2)
			MatVec.y = (MTAHud.Config.HudPos:GetBool() and MapPosYRight or MapPosYLeft) + (MTAHud.Vars.LastTranslateP * 3)

			mat:SetTranslation(MatVec)

			cam.PushModelMatrix(mat)
				local rx, ry = GetMapDrawPos(LocalPlayer():GetPos())

				local startU = (rx - MapZoom) / 1024
				local startV = (ry - MapZoom) / 1024
				local endU = (rx + MapZoom) / 1024
				local endV = (ry + MapZoom) / 1024

				surface.SetMaterial(MapImage)
				surface.SetDrawColor(255, 255, 255, 180)
				surface.DrawTexturedRectUV(0, 0, MapW, MapH, startU, startV, endU, endV)

				local tri = TranslatePoly(PlayerTriangle, MapW / 2, MapH / 2 - (10 * MTAHud.Config.ScrRatio))
				tri = RotatePoly(tri, yaw, MapW / 2, MapH / 2)
				draw.NoTexture()
				surface.SetDrawColor(255, 255, 255, 180)
				surface.DrawPoly(tri)

				surface.SetDrawColor(244, 135, 2)
				surface.DrawOutlinedRect(0, 0, MapW, MapH, 2)
			cam.PopModelMatrix()
		end
	}
end

MTAHud:AddComponent("hud", DrawHud)
MTAHud:AddComponent("map", DrawMap)