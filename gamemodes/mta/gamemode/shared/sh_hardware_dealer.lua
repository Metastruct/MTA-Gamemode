local tag = "mta_hardware_dealer"
local blueprints = {
	drill = 5,
	portable_electroshield = 20,
}

if SERVER then
	util.AddNetworkString(tag)

	net.Receive(tag, function(_, ply)
		local item_class = net.ReadString()
		if blueprints[item_class] then
			MTA.PayPoints(ply, blueprints[item_class])
		end
	end)

	local MAX_NPC_DIST = 300 * 300
	hook.Add("KeyPress", tag, function(ply, key)
		if key ~= IN_USE then return end

		local npc = ply:GetEyeTrace().Entity
		if not npc:IsValid() then return end

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
		local frame = vgui.Create("DFrame")
		frame:SetSize(600, 500)
		frame:SetPos(ScrW() / 2 - 300, ScrH() / 2 - 250)
		frame:SetTitle("Blueprints")
		frame:MakePopup()

		do -- header
			local header = frame:Add("DPanel")
			header:Dock(TOP)
			header:SetTall(50)

			local dealer_av = header:Add("DModelPanel")
			dealer_av:Dock(LEFT)
			dealer_av:SetModel(npc:GetModel())

			local bone_number = dealer_av.Entity:LookupBone("ValveBiped.Bip01_Head1")
			if bone_number then
				local head_pos = dealer_av.Entity:GetBonePosition(bone_number)
				if head_pos then
					dealer_av:SetLookAt(head_pos)
					dealer_av:SetCamPos(head_pos - Vector(-13, 0, 0))
				end
			end

			function dealer_av:LayoutEntity(ent)
				ent:SetSequence(ent:LookupSequence("idle_subtle"))
				self:RunAnimation()
			end

			local intro = header:Add("DLabel")
			intro:Dock(FILL)
			intro:SetText([[Hey there! I'm selling some blueprints here, check if anything catches your attention]])
			intro:SetWrap(true)
		end

		local content = frame:Add("DScrollPanel")
		content:Dock(FILL)
		content:DockMargin(5, 10, 5, 5)

		local orange_color = Color(244, 135, 2)
		local function add_blueprint(item, price)
			local panel = content:Add("DPanel")
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
				if not disabled and MTA.Crafting.Blueprints[item_name] then
					disabled = true
				end

				self:SetDisabled(disabled)
			end

			return btn
		end

		for blueprint_name, price in pairs(blueprints) do
			local item = MTA.Inventory.Items[blueprint_name]
			if not item then return end
			if not item.Craft then return end

			add_blueprint(item, price)
		end
	end

	net.Receive(tag, function()
		local npc = net.ReadEntity()
		if not IsValid(npc) then return end

		open_gui(npc)
	end)
end