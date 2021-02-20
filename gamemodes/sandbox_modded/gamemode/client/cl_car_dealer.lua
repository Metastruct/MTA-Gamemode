if not MTA then return end
if not MTA.Cars then return end

local tag = "MTA_Car_Dealer"

local carAmount     = #MTA.Cars.Config.CarList
local curCarCost    = MTA.Cars.GetCarPrice(1)
local selectedCar   = 1
local selectedColor = Color(255, 255, 255)
local selectedBodygroups = {}
local selectedSkin  = 0

local function CallBuyServer()
	net.Start(tag)
		net.WriteInt(selectedCar, 32)
		net.WriteColor(selectedColor)
		net.WriteInt(selectedSkin, 32)
		net.WriteTable(selectedBodygroups)
	net.SendToServer()
end

local MTA_COLOR = Color(244, 136, 0)
local WHITE = Color(255, 255, 255)
local function CreateCarDealerUI()
	if not MTACars then return end

	local WIDTH, HEIGHT = ScrW() / 2, ScrH() / 2

	local FRAME
	local RIGHT_DOCK
	local MIDDLE_DOCK
	local BOTTOM_DOCK

	local CAR_VIEW
	local COLOR_MIXER
	local DESCRIPTION
	local STYLE_SKIN
	local STYLE_BODY

	local BUY_BUTTON
	local PRICE_LIST
	local NEXT_CAR_BUTTON_R
	local NEXT_CAR_BUTTON_L

	local carAmount     = #MTACars.Config.CarList
	local curCarCost    = MTACars.GetCarPrice(1)

	FRAME = vgui.Create("DFrame")
	FRAME:SetSize(WIDTH, HEIGHT)
	FRAME:Center()
	FRAME:MakePopup()
	FRAME:SetTitle("Car Dealer")
	FRAME.btnMaxim:Hide()
	FRAME.btnMinim:Hide()

	RIGHT_DOCK = FRAME:Add("DPanel")
	RIGHT_DOCK:SetWidth(WIDTH / 3)
	RIGHT_DOCK:Dock(RIGHT)
	function RIGHT_DOCK:Paint(w, h)
	end

	MIDDLE_DOCK = FRAME:Add("DPanel")
	MIDDLE_DOCK:SetHeight(HEIGHT - HEIGHT / 4)
	MIDDLE_DOCK:Dock(TOP)
	function MIDDLE_DOCK:Paint(w, h)
	end

	BOTTOM_DOCK = FRAME:Add("DPanel")
	BOTTOM_DOCK:Dock(FILL)
	function BOTTOM_DOCK:Paint(w, h)
	end

	COLOR_MIXER = RIGHT_DOCK:Add("DColorMixer")
	COLOR_MIXER:Dock(TOP)
	COLOR_MIXER:SetHeight(HEIGHT / 2.5)
	COLOR_MIXER:SetPalette(true)
	COLOR_MIXER:SetAlphaBar(false)
	COLOR_MIXER:SetWangs(true)
	COLOR_MIXER:SetColor(WHITE)
	function COLOR_MIXER:ValueChanged(col)
		-- col returns as normal table so we modify our color object
		selectedColor.r = col.r
		selectedColor.g = col.g
		selectedColor.b = col.b

		if IsValid(CAR_VIEW) then
			CAR_VIEW:SetColor(selectedColor)
		end

		BUY_BUTTON:UpdatePrice()
	end

	BUY_BUTTON = RIGHT_DOCK:Add("DButton")
	BUY_BUTTON:SetHeight(32)
	BUY_BUTTON:Dock(BOTTOM)
	BUY_BUTTON.Price = 0
	function BUY_BUTTON:UpdatePrice()
		local cost = MTA.Cars.GetTotalPrice(selectedCar, selectedColor, selectedSkin, selectedBodygroups)

		if not MTA.Cars.CanBuy(cost) then
			self:SetDisabled(true)
			self:SetText("Can't afford - " .. cost .. " points")
		elseif IsValid(MTA.Cars.CurrentCar) then
			self:SetDisabled(true)
			self:SetText("You already own a vehicle.")
		else
			self:SetText("Rent car - " .. cost .. " points")
			self:SetEnabled(true)
		end

		self.Price = cost
		PRICE_LIST:Update()
	end

	function BUY_BUTTON:DoClick(w, h)
		if not MTA.Cars.CanBuy(self.Price) then return end
		CallBuyServer()
		FRAME:Close()
	end

	PRICE_LIST = RIGHT_DOCK:Add("RichText")
	PRICE_LIST:Dock(BOTTOM)
	PRICE_LIST:SetHeight(96)
	function PRICE_LIST:PerformLayout()
		self:SetFontInternal("DermaDefaultBold")
		self:SetFGColor(255, 255, 255)
	end

	function PRICE_LIST:Update()
		self:SetText("")
		local paintPrice = MTA.Cars.GetPaintPrice(selectedColor)
		local skinPrice  = MTA.Cars.GetSkinPrice(selectedSkin)
		local partCost   = MTA.Cars.GetModificationPrice(selectedBodygroups)

		self:InsertColorChange(255, 255, 255, 255)
		self:AppendText("Rental - " .. curCarCost .. " points\n")

		if paintPrice > 0 then
			self:AppendText("Paintjob - " .. paintPrice .. " points\n")
		end
		if skinPrice > 0 then
			self:AppendText("Livery - " .. skinPrice .. " points\n")
		end
		if partCost > 0 then
			self:AppendText("Modifications" .. " - " .. partCost .. " points\n")
		end

		self:InsertColorChange(255, 225, 100, 255)
		local points = MTA.GetPlayerStat("points")
		local sum = paintPrice + skinPrice + partCost + curCarCost
		local finalPoints = points - sum

		local text = points .. " - " .. sum .. " = " .. finalPoints .. " points left after purchase."
		self:AppendText("\n" .. text)
	end

	DESCRIPTION = RIGHT_DOCK:Add("RichText")
	DESCRIPTION:Dock(FILL)
	function DESCRIPTION:PerformLayout()
		self:SetFontInternal("CreditsText")
		self:SetFGColor(255, 255, 255)
	end

	function DESCRIPTION:UpdateText()
		DESCRIPTION:SetText("")
		DESCRIPTION:InsertColorChange(MTA_COLOR:Unpack())

		local name = MTA.Cars.GetCarName(selectedCar)
		DESCRIPTION:AppendText(name .. "\n")
		MTA.Cars.LastCarName = name

		DESCRIPTION:InsertColorChange(255, 255, 224, 255)
		DESCRIPTION:AppendText(MTA.Cars.GetCarDescription(selectedCar))
		DESCRIPTION:InsertColorChange(200, 100, 100, 255)
		DESCRIPTION:AppendText("\nNOTE: Currently cars do not save.")
	end

	CAR_VIEW = MIDDLE_DOCK:Add("DModelPanel")
	CAR_VIEW:Dock(FILL)
	CAR_VIEW:SetModel(MTA.Cars.GetCarModel(1))
	CAR_VIEW.Angle = Angle()

	function CAR_VIEW:LayoutEntity(ent)
		local pos = ent:GetPos()
		self.Angle.y = FrameTime() * 10

		ent:SetAngles(ent:GetAngles() + self.Angle)

		self:SetLookAt(pos)
		self:SetCamPos(pos + Vector(256, 0, 64))
	end

	CAR_VIEW.FloorEntity = ClientsideModel("")
	CAR_VIEW.FloorEntity:SetMaterial("phoenix_storms/concrete3")

	CAR_VIEW.WallEntity = ClientsideModel("")
	CAR_VIEW.WallEntity:SetMaterial("phoenix_storms/roadside")

	CAR_VIEW.Plateau = ClientsideModel("")
	CAR_VIEW.Plateau:SetModelScale(2.5)
	CAR_VIEW.Plateau:SetMaterial("phoenix_storms/pack2/chrome")

	CAR_VIEW.Mechanic = ClientsideModel("models/odessa.mdl")
	CAR_VIEW.Mechanic:SetSequence("idle_reference")

	local wallModel = {
		model = "models/hunter/plates/plate32x32.mdl",
		pos   = Vector(-350, 0, 350),
		angle = Angle(90, 0, 0)
	}

	local floorModel = {
		model = "models/hunter/plates/plate32x32.mdl",
		pos   = Vector(0, 0, -5),
		angle = Angle()
	}

	local plateauModel = {
		model = "models/hunter/tubes/circle2x2.mdl",
		pos   = Vector(0, 0, -5),
		angle = Angle(0, 90, 0),
	}

	local decor = {
		{
			model = "models/props_wasteland/controlroom_desk001b.mdl",
			pos   = Vector(-150, 200, 15),
			angle = Angle(0, 135, 0),
			ent = ClientsideModel("")
		},
		{
			model = "models/props_c17/trappropeller_engine.mdl",
			pos   = Vector(-170, 190, 45),
			angle = Angle(-90, 0, 0),
			ent = ClientsideModel("")
		},
		{
			model = "models/props_c17/light_floodlight02_off.mdl",
			pos   = Vector(-150, -200, 15),
			angle = Angle(0, 45, 0),
			ent = ClientsideModel("")
		}
	}

	local mechanic = {
		model = "models/odessa.mdl",
		pos   = Vector(-170, 235, 5),
		angle = Angle(0, -45, 0),
	}

	function CAR_VIEW:ResetCar()
		self:SetModel(MTA.Cars.GetCarModel(selectedCar))
		DESCRIPTION:UpdateText()

		STYLE_SKIN:ResetSkins()
		STYLE_BODY:ResetBodygroups()

		BUY_BUTTON:UpdatePrice()
	end

	function CAR_VIEW:PreDrawModel(ent)
		local r, g, b = render.GetColorModulation()

		render.SetColorModulation(1, 1, 1)
		render.Model(plateauModel, self.Plateau)

		for _, model in ipairs(decor) do
			render.Model(model, model.ent)
		end

		render.Model(mechanic, self.Mechanic)

		render.SetColorModulation(0.2, 0.2, 0.2)
		render.Model(wallModel, self.WallEntity)

		render.SetColorModulation(0.25, 0.25, 0.25)
		render.Model(floorModel, self.FloorEntity)

		render.SetColorModulation(r, g, b)
	end

	local arrow = Material("gui/html/back")
	local function CarButtonDraw(self, w, h)

		if self.Text then
			local arrowSize = h / 2

			if self:IsHovered() then
				surface.SetTextColor(MTA_COLOR)
				surface.SetDrawColor(MTA_COLOR)
			else
				surface.SetTextColor(255, 255, 255)
				surface.SetDrawColor(255, 255, 255)
			end

			surface.SetFont("Trebuchet18")

			local tW, tH = surface.GetTextSize(self.Text)
			surface.SetTextPos(arrowSize / 2 + tW / 2, h / 2 - tH / 2)
			surface.DrawText(self.Text)

			surface.SetMaterial(arrow)

			if self.IsRight then
				surface.DrawTexturedRectRotated(w - arrowSize, h / 2, arrowSize, arrowSize, 180)
			else
				surface.DrawTexturedRect(arrowSize / 2, h / 2-h / 4, arrowSize, arrowSize)
			end
		end
	end

	NEXT_CAR_BUTTON_R = CAR_VIEW:Add("DButton")
	NEXT_CAR_BUTTON_R:Dock(RIGHT)
	NEXT_CAR_BUTTON_R:SetWidth(128)
	NEXT_CAR_BUTTON_R:DockMargin(0, 0, 0, HEIGHT / 1.5)
	NEXT_CAR_BUTTON_R:SetText("")
	NEXT_CAR_BUTTON_R.Text = "Next Car"
	NEXT_CAR_BUTTON_R.IsRight = true
	NEXT_CAR_BUTTON_R.Paint = CarButtonDraw

	function NEXT_CAR_BUTTON_R:DoClick()
		selectedCar = selectedCar + 1 > carAmount and 1 or selectedCar + 1
		CAR_VIEW:ResetCar()
	end

	NEXT_CAR_BUTTON_L = CAR_VIEW:Add("DButton")
	NEXT_CAR_BUTTON_L:Dock(LEFT)
	NEXT_CAR_BUTTON_L:SetWidth(128)
	NEXT_CAR_BUTTON_L:DockMargin(0, 0, 0, HEIGHT / 1.5)
	NEXT_CAR_BUTTON_L:SetText("")
	NEXT_CAR_BUTTON_L.Text = "Previous Car"
	NEXT_CAR_BUTTON_L.Paint = CarButtonDraw

	function NEXT_CAR_BUTTON_L:DoClick()
		selectedCar = selectedCar - 1 < 1 and carAmount or selectedCar - 1
		CAR_VIEW:ResetCar()
	end

	local docker = BOTTOM_DOCK:Add("DPanel")
	docker:Dock(LEFT)
	docker:SetWidth(WIDTH / 6)

	STYLE_SKIN = docker:Add("DNumSlider")
	STYLE_SKIN:Dock(FILL)
	STYLE_SKIN:DockMargin(-docker:GetWide() / 2, 0, 0, 0) --wang and scratch fucks up the docking
	STYLE_SKIN.Wang:Hide()
	STYLE_SKIN.Scratch:Hide()
	STYLE_SKIN.TextArea:SetTextColor(WHITE)

	function STYLE_SKIN:ResetSkins()
		self:SetMinMax(1, CAR_VIEW.Entity:SkinCount() - 1)
		self:ResetToDefaultValue()
		selectedSkin = 0
	end

	STYLE_SKIN:SetMinMax(1, 1)
	STYLE_SKIN:SetDefaultValue(1)
	STYLE_SKIN:SetDecimals(0)
	STYLE_SKIN.LastValue = 1
	function STYLE_SKIN:OnValueChanged(value)
		value = math.Round(value)

		if value ~= self.LastValue then
			CAR_VIEW.Entity:SetSkin(value)
			self.LastValue = value
			selectedSkin = value

			BUY_BUTTON:UpdatePrice()
		end
	end

	function STYLE_SKIN.Slider:Paint(w, h)
		local notches = self:GetNotches()

		surface.SetDrawColor(255, 255, 255)
		for i = 1, notches do
			surface.DrawRect(i * w / notches, h / 2 + h / 10, 1, h / 10)
		end
	end

	local STYLE_LABEL = docker:Add("DLabel")
	STYLE_LABEL:Dock(TOP)
	STYLE_LABEL:DockMargin(10, 10, 0, 0)
	STYLE_LABEL:SetText("SKIN")
	STYLE_LABEL:SetColor(MTA_COLOR)
	STYLE_LABEL:SetFont("DermaLarge")

	STYLE_BODY = BOTTOM_DOCK:Add("DPanel")
	STYLE_BODY:Dock(FILL)

	function STYLE_BODY:ResetBodygroups()
		STYLE_BODY:Clear()
		selectedBodygroups = {}

		for k, bodyGroup in ipairs(CAR_VIEW.Entity:GetBodyGroups()) do
			if bodyGroup.num > 1 then

				local DList = self:Add("DListView")
				DList:Dock(RIGHT)
				DList:SetSortable(false)

				function DList:OnRowSelected(rowIndex, line)
					local group = tonumber(line:GetValue(2))
					if not group then return end
					CAR_VIEW.Entity:SetBodygroup(bodyGroup.id, group)

					if group == 0 then
						selectedBodygroups[bodyGroup.id] = nil
					else
						selectedBodygroups[bodyGroup.id] = group
					end
					BUY_BUTTON:UpdatePrice()
				end

				DList:AddColumn(bodyGroup.name)

				for id, model in pairs(bodyGroup.submodels) do
					local line = DList:AddLine(model)
					if model == "" then model = "?" end
					if id == 0 then DList:SelectItem(line) model = "default" end
					model = string.gsub(model, ".smd", "")
					line:SetValue(1, model)
					line:SetValue(2, id)
				end
			end
		end
	end

	CAR_VIEW:ResetCar()
end

local function DoNotice()

	local text = "Your car is waiting outside the garage."
	hook.Add("HUDPaint", tag, function()

		surface.SetFont("DermaLarge")
		local tW, tH = surface.GetTextSize(text)

		--Let text adjust the rect size
		local RECTW, RECTH = tW + 20, tH + 20
		local x, y = ScrW() / 2 - RECTW / 2, RECTH / 2

		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(x, y, RECTW, RECTH)

		surface.SetDrawColor(MTA_COLOR)
		surface.DrawOutlinedRect(x, y, RECTW, RECTH, 2)

		surface.SetTextColor(MTA_COLOR)

		surface.SetTextPos(x + RECTW / 2 - tW / 2, y + RECTH / 2 - tH / 2)
		surface.DrawText(text)

		-- If the car somehow vanishes
		if not IsValid(MTA.Cars.CurrentVehicle) then
			hook.Remove("HUDPaint", tag)
			return
		end

		-- keep annoying until they enter the car
		local veh = LocalPlayer():GetVehicle()
		if not IsValid(veh) then return end

		if MTA.Cars.CurrentVehicle == veh.vehiclebase then
			hook.Remove("HUDPaint", tag)
		end
	end)
end

hook.Add("PreDrawOutlines", tag, function()
	if MTA and MTA.Cars and IsValid(MTA.Cars.CurrentVehicle) then
		if MTA.Cars.CurrentVehicle:GetDriver() == LocalPlayer() then return end
		outline.Add(MTA.Cars.CurrentVehicle, MTA_COLOR, OUTLINE_MODE_BOTH, 4)
	end
end)

net.Receive(tag, function()
	local isUi = net.ReadBool()
	if isUi then
		CreateCarDealerUI()
	else
		local veh = net.ReadEntity()
		MTA.Cars.CurrentVehicle = veh
		DoNotice()
	end
end)
