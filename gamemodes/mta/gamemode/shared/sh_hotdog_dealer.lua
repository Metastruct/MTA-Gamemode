local tag = "mta_hotdog_dealer"
local goods = {
	hotdog = 1,
	hotdog_armored = 5
}

if SERVER then
	util.AddNetworkString(tag)

	net.Receive(tag, function(l, ply)
		if MTA.IsWanted(ply) then return end

		local item_class = net.ReadString()
		local is_blueprint = net.ReadBool()

		local owned_blueprints = MTA.Crafting.Blueprints.Get(ply)
		local price = goods[item_class]

		if price and not owned_blueprints[item_class] and MTA.PayPoints(ply, price) then
			if is_blueprint then
				MTA.Crafting.GiveBlueprint(ply, item_class)

				return
			end

			MTA.Inventory.AddItem(ply, item_class)
		end
	end)

	local MAX_NPC_DIST = 300 * 300
	hook.Add("KeyPress", tag, function(ply, key)
		if key ~= IN_USE then return end

		local npc = ply:GetEyeTrace().Entity
		if not npc:IsValid() then return end
		if MTA.IsWanted(ply) then return end

		if npc.role == "hotdog_dealer" and npc:GetPos():DistToSqr(ply:GetPos()) <= MAX_NPC_DIST then
			net.Start(tag)
				net.WriteEntity(npc)
			net.Send(ply)

			if ply.LookAt then
				ply:LookAt(npc, 0.1, 0)
			end
		end
	end)
end

if CLIENT then
	local function dealer_gui(npc)
		local FRAME

		FRAME = vgui.Create("mta_shop")
		FRAME:SetTitle("Hotdog Stand")
		FRAME:SetSize(600, 500)
		FRAME:SetHeader(npc, "Hey! Care to buy some hotdogs?")
		FRAME:Center()

		FRAME:MakePopup()

		local orange_color = Color(244, 135, 2)
		function FRAME:AddItem(item, price, is_blueprint)
			local panel = self.Content:Add("DPanel")
			panel:Dock(TOP)
			panel:DockMargin(0, 10, 0, 0)
			panel:SetTall(50)

			local label_item = panel:Add("DLabel")
			label_item:SetPos(10, 5)
			label_item:SetWide(400)
			label_item:SetText("● " .. item.Name .. (is_blueprint and " (Blueprint)" or ""))

			local label_item_desc = panel:Add("DLabel")
			label_item_desc:SetPos(10, 20)
			label_item_desc:SetWide(400)
			label_item_desc:SetText(item.Description)
			label_item_desc:SetTextColor(orange_color)

			local buy_btn = panel:Add("DButton")
			buy_btn:Dock(RIGHT)
			buy_btn:DockMargin(5, 5, 5, 5)
			buy_btn:SetWide(125)
			buy_btn:SetText(("Buy (%d pts)"):format(price))
			buy_btn:SetTextColor(color_white)
			function buy_btn:DoClick()
				net.Start(tag)
					net.WriteString(item.ClassName)
					net.WriteBool(is_blueprint)
				net.SendToServer()

				surface.PlaySound("ui/buttonclick.wav")
			end
			buy_btn.Description = label_item

			function buy_btn:Think()
				self:SetText(("Buy (%d pts)"):format(price))
				local disabled = MTA.GetPlayerStat("points") < price

				if MTA.Crafting.Blueprints[item.ClassName] then
					disabled = true
				end

				self:SetDisabled(disabled)
			end
		end

		for class, price in pairs(goods) do
			local item = MTA.Inventory.Items[class]
			if not item then return end

			local bp = item.Craft and true or false

			FRAME:AddItem(item, price, bp)
		end
	end

	net.Receive(tag, function()
		local npc = net.ReadEntity()
		if not IsValid(npc) then return end

		dealer_gui(npc)
	end)

	return
end