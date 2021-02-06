local tag = "MTA_Gunstore"

local deskHeight = 5550
local weaponData = {
	--model is the world prop model
	--pos is where the "buy weapon" highlight will be located
	--offset is the offset of the world prop relative to the pos
	--ang is the angle of the world prop

	--Weapon storage
	["weapon_ut2004_flak"] = {
		model = "models/ut2004/weapons/w_flak.mdl",
		pos = Vector(272, 7086.5, 5577),
		offset = Vector(-10.746215820313, -20, -15),
		ang = Angle(-9.5, 180, 0),
	},
	["weapon_ut2004_minigun"] = {
		model = "models/ut2004/weapons/w_minigun.mdl",
		pos = Vector(368, 7086.5, 5577),
		offset = Vector(-10.746215820313, -20, -15),
		ang = Angle(-3.05, 178, 45),
	},
	["weapon_crossbow"] = {
		model = "models/weapons/w_crossbow.mdl",
		pos = Vector(560, 7086.5, 5577),
		offset = Vector(-10.746215820313, -20, 23.31884765625),
		ang = Angle(1.5, -3.5, -92.5),
	},
	["weapon_rpg"] = {
		model = "models/weapons/w_rocket_launcher.mdl",
		pos = Vector(464, 7086.5, 5577),
		offset = Vector(16.992279052734, -20, 13.1015625),
		ang = Angle(0, -179.5, 1.5),
	},

	--Glass box
	["weapon_asmd"] = {
		model = "models/weapons/w_ut2k4_shock_rifle.mdl",
		pos = Vector(504.7548828125, 7263.86328125, deskHeight),
		offset = Vector(0, 0, -12),
		ang = Angle(0, -92, -77),
	},
	["weapon_ar2"] = {
		model = "models/weapons/w_irifle.mdl",
		pos = Vector(455.69458007813, 7422.173828125, deskHeight),
		offset = Vector(0, 0, -12),
		ang = Angle(0, 0, -90),
	},
	["weapon_escape_teleporter"] = {
		model = "models/maxofs2d/hover_rings.mdl",
		pos = Vector(505.33044433594, 7213.9462890625, deskHeight),
		offset = Vector(0.37005615234375, 0.08544921875, -9.3125),
		ang = Angle(-30, 76, 111.5),
	},
	["weapon_pistol"] = {
		model = "models/weapons/w_pistol.mdl",
		pos = Vector(358.38717651367, 7536.541015625, deskHeight),
		offset = Vector(0, 0, -12),
		ang = Angle(0, 90, 90),
	},
	["weapon_smg1"] = {
		model = "models/weapons/w_smg1.mdl",
		pos = Vector(353.90985107422, 7212.3784179688, deskHeight),
		offset = Vector(0, 0, -12),
		ang = Angle(1.5, 108.5, 90),
	},
	["weapon_shotgun"] = {
		model = "models/weapons/w_shotgun.mdl",
		pos = Vector(354.59365844727, 7261.9545898438, deskHeight),
		offset = Vector(0, 0, -12),
		ang = Angle(1.3, -72.2, -94),
	},
	["weapon_357"] = {
		model = "models/weapons/w_357.mdl",
		pos = Vector(358.54968261719, 7491.90234375, deskHeight),
		offset = Vector(0, 0, -12),
		ang = Angle(0, 90, 90),
	},

	--Desk
	["weapon_slam"] = {
		model = "models/weapons/w_slam.mdl",
		pos = Vector(355.3125, 7441.8125, deskHeight),
		offset = Vector(0, 0, 3),
		ang = Angle(0, -135, 0),
	},
	["weapon_plasmanade"] = {
		model = "models/weapons/w_suitcase_passenger.mdl",
		pos = Vector(378.0625, 7408.6875, deskHeight),
		offset = Vector(0, 0, 4),
		ang = Angle(0, 163, -90),
	},

	--Floor
	["weapon_riot_shield"] = {
		model = "models/cloud/ballisticshield_mod.mdl",
		pos = Vector(597.91192626953, 7147.1474609375, 5541.56640625),
		offset = Vector(-6.8494262695313, -2, -36.09765625),
		ang = Angle(12.5, 0.25, 0),
	},
}

if SERVER then

	local doorLocations = {
		[1] = Vector(560, 7086.5, 5592),
		[2] = Vector(464, 7086.5, 5592),
		[3] = Vector(368, 7086.5, 5592),
		[4] = Vector(272, 7086.5, 5592),
	}

	local function SetupStore()
		for class, data in pairs(weaponData) do
			local ent = ents.Create("prop_dynamic")
			ent:SetModel(data.model)
			ent:SetPos(data.pos + data.offset)
			ent:SetAngles(data.ang)
			ent:Spawn()

			local hitBox = ents.Create("prop_dynamic")
			hitBox:SetModel("models/hunter/blocks/cube025x025x025.mdl")
			hitBox:SetPos(data.pos)
			hitBox:PhysicsInitStatic(SOLID_VPHYSICS)
			hitBox:Spawn()
			hitBox:SetRenderMode(RENDERMODE_TRANSCOLOR)
			hitBox:SetColor(Color(0, 0, 0, 0))

			local phys = hitBox:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
			end

			hitBox:SetUnFreezable(true)
			hitBox.PhysgunDisabled = true
			hitBox:SetNWBool(tag, true)
			hitBox:SetNWString(tag, class)

			function hitBox:CanProperty() return false end
			function hitBox:CanTool() return false end
		end

		for _,pos in ipairs(doorLocations) do
			for k, door in ipairs(ents.FindInSphere(pos, 5)) do

				if IsValid(door) and door:GetClass() == "func_door" then
					door:Fire("Open")
					door:Fire("Lock")
					door:SetNotSolid(true) -- its in the way
				end
			end
		end
	end

	hook.Add("InitPostEntity", tag, function()
		SetupStore()
	end)

	hook.Add("PostCleanupMap", tag, function()
		SetupStore()
	end)

	return
end

local gunStoreLocation = Vector(425, 7330, 5506)
local highlightColor = Color(255, 150, 150)

local hasSetup = false
local isKeyDown = false

local function CanBuy(weapon)
	return not MTA.Weapons[weapon] and MTA.GetPlayerStat("points") >= MTA_CONFIG.upgrades.WeaponCosts[weapon]
end

local function CallBuyServer(weapon)
	if not CanBuy(weapon) then surface.PlaySound("npc/scanner/combat_scan5.wav") return end

	net.Start("MTA_GIVE_WEAPON")
		net.WriteString(weapon)
	net.SendToServer()

	surface.PlaySound("npc/scanner/combat_scan2.wav")
end

local clWeaponData = {}
local function SetupClientData()
	for weapon, cost in pairs(MTA_CONFIG.upgrades.WeaponCosts) do

		local data = weaponData[weapon]
		local weaponInfo = list.Get("Weapon")[weapon]

		if data and weaponInfo then
			table.insert(clWeaponData, {
				class = weapon,
				cost = cost,
				pos = data.pos,
				name = weaponInfo.PrintName,
			})
		end
	end
end

--using post entity since then all "list.Get" should be setup, right?
hook.Add("InitPostEntity", tag, function()
	--setup a more optimized table for the hudpaint hook
	if hasSetup then return end --Client can call this several times
	if not MTA or not MTA_CONFIG then return end
	SetupClientData()
end)

hook.Add("HUDPaint", tag, function()
	if not MTA or not MTA_CONFIG then return end

	if LocalPlayer():GetPos():Distance(gunStoreLocation) > 256 then return end

	for _, data in ipairs(clWeaponData) do
		local pos = data.pos

		if LocalPlayer():GetPos():Distance(pos) < 100 then
			local name = data.name
			local cost = data.cost
			local text

			if MTA.Weapons[data.class] == true then
				text = "You own this weapon"
			elseif MTA.GetPlayerStat("points") < cost then
				text = "You can't afford this - " .. cost .. " points"
			else
				text = "Buy " .. name .. " - " .. cost .. " points"
			end

			MTA.HighlightPosition(pos, text, highlightColor)

			if LocalPlayer():KeyDown(IN_USE) then
				if not isKeyDown then
					local tr = LocalPlayer():GetEyeTrace()

					local ent = tr.Entity
					if tr.Hit and IsValid(ent) and ent:GetNWBool(tag) then
						CallBuyServer(ent:GetNWString(tag))
					end
					isKeyDown = true
				end
			else
				isKeyDown = false
			end
		end

	end
end)
