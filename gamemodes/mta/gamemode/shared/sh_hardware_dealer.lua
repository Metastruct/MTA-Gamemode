local tag = "mta_hardware_dealer"
local blueprints = {
	drill = 5,
	portable_electroshield = 20,
}

if SERVER then
	util.AddNetworkString(tag)

	net.Receive(tag, function(_, ply)
		if MTA.IsWanted(ply) then return end -- the npc is in a drill zone, dont allow buying if wanted

		local item_class = net.ReadString()
		local owned_blueprints = MTA.Crafting.Blueprints.Get(ply)
		if blueprints[item_class] and not owned_blueprints[item_class] then
			MTA.PayPoints(ply, blueprints[item_class])
		end
	end)

	local MAX_NPC_DIST = 300 * 300
	hook.Add("KeyPress", tag, function(ply, key)
		if key ~= IN_USE then return end

		local npc = ply:GetEyeTrace().Entity
		if not npc:IsValid() then return end
		if MTA.IsWanted(ply) then return end

		if npc.role == "hardware_dealer" and npc:GetPos():DistToSqr(ply:GetPos()) <= MAX_NPC_DIST then
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
	local function open_gui(npc)
		local frame = vgui.Create("mta_shop")
		frame:SetHeader(npc, [[Hey there! I'm selling some blueprints here, check if anything catches your attention]])
		frame:SetSize(600, 500)
		frame:Center()
		frame:MakePopup()

		local orange_color = Color(244, 135, 2)
		function frame:AddBlueprint(item, price)
			local panel = self.Content:Add("DPanel")
			panel:Dock(TOP)
			panel:DockMargin(0, 10, 0, 0)
			panel:SetTall(50)

			local label = panel:Add("DLabel")
			label:SetPos(10, 5)
			label:SetText("● " .. item.Name)
			label:SetWide(400)

			local label_desc = panel:Add("DLabel")
			label_desc:SetPos(10, 20)
			label_desc:SetText(item.Description)
			label_desc:SetWide(400)
			label_desc:SetTextColor(orange_color)

			local btn = panel:Add("DButton")
			btn:Dock(RIGHT)
			btn:DockMargin(5, 5, 5, 5)
			btn:SetText(("Buy (%d pts)"):format(price))
			btn:SetTextColor(color_white)
			btn:SetWide(125)
			btn.DoClick = function()
				net.Start(tag)
				net.WriteString(item.ClassName)
				net.SendToServer()
			end
			btn.Description = label

			function btn:Think()
				self:SetText(("Buy (%d pts)"):format(price))
				local disabled = MTA.GetPlayerStat("points") < price
				if MTA.Crafting.Blueprints[item.ClassName] then
					disabled = true
				end

				self:SetDisabled(disabled)
			end
		end

		for blueprint_name, price in pairs(blueprints) do
			local item = MTA.Inventory.Items[blueprint_name]
			if not item then return end
			if not item.Craft then return end

			frame:AddBlueprint(item, price)
		end
	end

	net.Receive(tag, function()
		local npc = net.ReadEntity()
		if not IsValid(npc) then return end

		open_gui(npc)
	end)
end