MTACars = MTA_TABLE("Cars")
MTACars.Config = {
	CarList = {
		[1] = {
			veh = "sim_fphys_msa_vehicle_1",
			price = 40,
			model = "models/msavehs/msavehicle1.mdl",
			name = "Charger",
			desc = "A luxurious car which fits all your needs.\nWant to drive around the town in full glory?\nBuy the Charger."
		},
		[2] = {
			veh = "sim_fphys_msa_vehicle_2",
			price = 40,
			model = "models/msavehs/msavehicle02.mdl",
			name = "Golf",
			desc = "A comfortable everyday car.\nEconomic and perfect for those who don't need anything special."
		},
	},
	StylePrices = {
		paint = 4,
		mod = 3,
		skin = 5,
	},
}

local config = MTACars.Config
local stylePrices = config.StylePrices
local carList = config.CarList

function MTACars.GetSkinPrice(skin)
	return skin > 1 and stylePrices.skin or 0
end

function MTACars.GetModificationPrice(modParts)
	return table.IsEmpty(modParts) and 0 or stylePrices.mod * table.Count(modParts)
end

function MTACars.GetPaintPrice(color)
	return color.r == 255 and color.g == 255 and color.b == 255 and 0 or stylePrices.paint
end

function MTACars.GetCarPrice(carId)
	return carList[carId].price
end

function MTACars.GetTotalPrice(carId, color, skin, modParts)
	return MTACars.GetCarPrice(carId) + MTACars.GetPaintPrice(color) + MTACars.GetSkinPrice(skin) + MTACars.GetModificationPrice(modParts)
end

if CLIENT then
	function MTACars.GetCarDescription(carId)
		return carList[carId].desc
	end

	function MTACars.GetCarName(carId)
		return carList[carId].name
	end

	function MTACars.GetCarModel(carId)
		return carList[carId].model
	end

	function MTACars.CanBuy(cost)
		return MTA.GetPlayerStat("points") >= cost
	end

	return
end

--SERVER SIDE
function MTACars.GetSimCarType(carId)
	return carList[carId].veh
end

function MTACars.CanBuy(ply, cost)
	if not MTA then return false end

	return MTA.GetPlayerStat(ply, "points") >= cost
end

function MTACars.GetPlayerVehicle(ply)
	return MTACars.CurrentVehicles[ply]
end

local propCars = {
	--{
	--	model = "models/msavehs/msavehicle1.mdl",
	--	ang = Angle(0, 0, 0),
	--	parentName = "grgcl"
	--},
	{
		model = "models/msavehs/msavehicle02.mdl",
		pos = Vector(-1415, 5425, 5410),
		ang = Angle(0, -180, 0),
	}
}

local tag = "MTA_Car_Dealer"
util.AddNetworkString(tag)

MTACars.CurrentVehicles = MTACars.CurrentVehicles or {}

-- copy from mta dealer, thank earu
local MAX_NPC_DIST = 300 * 300
hook.Add("KeyPress", tag, function(ply, key)
	if key ~= IN_USE then return end

	local npc = ply:GetEyeTrace().Entity
	if not npc:IsValid() then return end

	if npc.role == "car_dealer" and npc:GetPos():DistToSqr(ply:GetPos()) <= MAX_NPC_DIST then
		net.Start(tag)
			net.WriteBool(true)
		net.Send(ply)

		if ply.LookAt then
			ply:LookAt(npc, 0.1, 0)
		end
		ply._inCarDeal = true --Prevent players from doing net message exploit
	end
end)

--grgdr1
--grgdr2
local function SetupGarage()
	local door1 = ents.FindByName("grgdr1")[1]
	if IsValid(door1) then
		door1:Fire("Open")
		door1:Fire("Lock")
	end

	local door2 = ents.FindByName("grgdr2")[1]
	if IsValid(door2) then
		door2:Fire("Open")
		door2:Fire("Lock")
	end

	local lift = ents.FindByName("grgcl")[1]
	if IsValid(lift) then
		lift:Fire("Lock")
	end

	for _, data in ipairs(propCars) do
		local ent = ents.Create("prop_dynamic")
		ent:SetModel(data.model)
		ent:SetAngles(data.ang)
		ent:PhysicsInitStatic(SOLID_VPHYSICS)
		ent:Spawn()

		ent:SetColor(ColorRand())

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end

		--protecc
		ent.PhysgunDisabled = true
		ent:SetUnFreezable(true)
		function ent:CanTool() return false end
		function ent:CanProperty() return false end

		if data.parentName then
			local parent = ents.FindByName(data.parentName)[1]
			if not IsValid(parent) then return end

			ent:SetPos(parent:GetPos())
			ent:SetParent(parent)
		else
			ent:SetPos(data.pos)
		end
	end

	local repair = ents.Create("car_repair_field")
	repair:SetPos(Vector(-1740, 5305, 5417))
	repair:Spawn()
end

hook.Add("InitPostEntity", tag, function()
	SetupGarage()
end)

hook.Add("PostCleanupMap", tag, function()
	SetupGarage()
end)

local parking_spots = {
	{
		ang = Angle(0, -90, 0),
		pos = Vector(5103, 4709, 5447),
	},
	{
		ang = Angle(0, -90, 0),
		pos = Vector(5119, 5001, 5447),
	},
	{
		ang = Angle(0, -90, 0),
		pos = Vector(5122, 5250, 5447),
	},
	{
		ang = Angle(0, 0, 0),
		pos = Vector(4999, 5920, 5447),
	},
	{
		ang = Angle(0, 0, 0),
		pos = Vector(5289, 5922, 5447),
	},
	{
		ang = Angle(0, 0, 0),
		pos = Vector(5543, 5931, 5447),
	},
	{
		ang = Angle(0, 90, 0),
		pos = Vector(5572, 5259, 5447),
	},
	{
		ang = Angle(0, 90, 0),
		pos = Vector(5534, 4981, 5447),
	},
	{
		ang = Angle(0, 90, 0),
		pos = Vector(5557, 4712, 5447),
	},
	{
		ang = Angle(0, -90, 0),
		pos = Vector(6225, 5125, 5447),
	},
	{
		ang = Angle(0, -90, 0),
		pos = Vector(6240, 4867, 5447),
	},
	{
		ang = Angle(0, -90, 0),
		pos = Vector(6240, 4591, 5447),
	},
	{
		ang = Angle(0, -90, 0),
		pos = Vector(6228, 4335, 5447),
	},
}

local function respawnCar(ply)
	if not _G.co or not _G.db then return end
	co(function()
		local ret = db.Query("SELECT * FROM mta_user_cars WHERE id = ?", ply:AccountID())
		if ret and ret[1] then
			local data = ret[1]

			local parking_slot = parking_spots[math.random(#parking_spots)]
			local vehicleList = list.Get("simfphys_vehicles")
			local vehicle = vehicleList[data.name]

			local car = simfphys.SpawnVehicle(ply, parking_slot.pos, parking_slot.ang, data.model, data.class, data.name, vehicle, true)
			if not IsValid(car) then return end

			function car:CanProperty() return false end
			function car:CanTool() return false end
			function car:UpdateTransmitState() return TRANSMIT_ALWAYS end

			local old_OnDestroyed = car.OnDestroyed
			function car:OnDestroyed()
				timer.Simple(10, function()
					if not IsValid(ply) then return end
					respawnCar(ply)
				end)
				old_OnDestroyed(self)
			end

			car.PhysgunDisabled = true
			do
				local chunks = data.color:Split(" ")
				car:SetColor(Color(
					tonumber(chunks[1]) or 255,
					tonumber(chunks[2]) or 255,
					tonumber(chunks[3]) or 255,
					tonumber(chunks[4]) or 255
				))
			end

			car:SetSkin(tonumber(data.skin) or 0)

			local modParts = util.JSONToTable(data.bodygroups)
			for _, group in pairs(modParts) do
				car:SetBodygroup(group.id, group.num)
			end

			for _, wheel in ipairs(car.Wheels) do
				if IsValid(wheel) then
					wheel.doorexploding = true
				end
			end

			car.doorexploding = true
			car.IsMTACar = true
			car.Renter = ply

			--Add delay to make sure it's spawned
			timer.Simple(0.5, function()
				net.Start(tag)
					net.WriteBool(false)
					net.WriteEntity(car)
				net.Send(ply)
			end)

			MTACars.CurrentVehicles[ply] = car
		end
	end)
end

hook.Add("PlayerInitialSpawn", tag, respawnCar)

local vSpawnPos, vSpawnAng = Vector(-1735, 4888, 5417), Angle(0, -90, 0)

local function BuyVehicle(ply, cost, sim, color, skin, modParts)
	local vehicleList = list.Get("simfphys_vehicles")
	local vehicle = vehicleList[sim]

	if not vehicle then return end

	local car = simfphys.SpawnVehicle(ply, vSpawnPos, vSpawnAng, vehicle.Model, vehicle.Class, sim, vehicle, true)
	if not IsValid(car) then return end

	--checks say it's good! let's take those points
	MTA.IncreasePlayerStat(ply, "points", -cost, true)

	local old_OnDestroyed = car.OnDestroyed
	function car:OnDestroyed()
		timer.Simple(10, function()
			if not IsValid(ply) then return end
			respawnCar(ply)
		end)
		old_OnDestroyed(self)
	end

	function car:CanProperty()
		return false
	end

	function car:CanTool()
		return false
	end

	car.PhysgunDisabled = true

	function car:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

	if color then
		car:SetColor(color)
	end

	if skin then
		car:SetSkin(skin)
	end

	for id, group in pairs(modParts) do
		car:SetBodygroup(id, group)
	end

	for _, wheel in ipairs(car.Wheels) do
		if IsValid(wheel) then
			wheel.doorexploding = true
		end
	end

	car.doorexploding = true
	car.IsMTACar = true
	car.Renter = ply

	if _G.co and _G.db then
		co(function()
			local bodygroups = {}
			for _, group in pairs(car:GetBodyGroups()) do
				table.insert(bodygroups, { id = group.id, num = group.num })
			end
			bodygroups = util.TableToJSON(bodygroups)

			local rows_updated = db.Query("UPDATE mta_user_cars SET model = ?, class = ?, name = ?, color = ?, bodygroups = ?, skin = ? WHERE id = ?",
				vehicle.Model, vehicle.Class, sim, tostring(color), bodygroups, skin, ply:AccountID())
			if rows_updated == 0 then
				db.Query("INSERT INTO mta_user_cars(id, model, class, name, color, bodygroups, skin) VALUES(?, ?, ?, ?, ?, ?, ?)",
					ply:AccountID(), vehicle.Model, vehicle.Class, sim, tostring(color), bodygroups, skin, ply:AccountID())
			end
		end)
	end

	--Add delay to make sure it's spawned
	timer.Simple(0.5, function()
		net.Start(tag)
			net.WriteBool(false)
			net.WriteEntity(car)
		net.Send(ply)
	end)

	MTACars.CurrentVehicles[ply] = car
end

net.Receive(tag, function(len, ply)
	if not IsValid(ply) then return end
	if not ply._inCarDeal then
		print(ply, "Requested car dealer without using the NPC first?")
		return
	end
	ply._inCarDeal = nil

	if IsValid(MTACars.GetPlayerVehicle(ply)) then
		return
	end

	local carId     = net.ReadInt(32)
	local color     = net.ReadColor()
	local skin      = net.ReadInt(32)
	local modParts  = net.ReadTable()

	local car = MTACars.GetSimCarType(carId)
	if not car then return end

	local cost = MTACars.GetTotalPrice(carId, color, skin, modParts)

	if not MTACars.CanBuy(ply, cost) then return end

	BuyVehicle(ply, cost, car, color, skin, modParts)
end)

hook.Add("PlayerDisconnected", tag, function(ply)
	local entry = MTACars.GetPlayerVehicle(ply)
	if not entry then return end

	--eat that car
	SafeRemoveEntity(entry)
end)

hook.Add("CanPlayerEnterVehicle", tag, function(ply, car)
	if not car.fphysSeat then return end

	local veh = car.base
	if not veh or not veh.IsMTACar then return end

	--If the renter has not entered this vehicle yet, no one else can
	if not veh.FreeForAll and ply ~= veh.Renter then
		return false
	else --Renter has used it, anyone can use it now
		veh.FreeForAll = true
	end
end)