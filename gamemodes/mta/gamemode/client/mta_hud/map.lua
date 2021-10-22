local FindByClass = ents.FindByClass
local DealerIcon = Material("vgui/mta_hud/dealer_icon.png")
local VaultIcon = Material("vgui/mta_hud/vault_icon.png")
local CarDealerIcon = Material("vgui/mta_hud/garage_icon.png")
local VehicleIcon = Material("vgui/mta_hud/vehicle_icon.png")
local HardwareIcon = Material("vgui/mta_hud/hardware_icon.png")
local HotdogIcon = Material("vgui/mta_hud/hotdog_icon.png")
local UnknownRoleIcon = Material("vgui/mta_hud/business_icon.png")
--local DoshIcon = Material("vgui/mta_hud/points_icon.png") -- Unused right now
local PointsIcon = Material("vgui/mta_hud/cp_icon.png")

local IconSize = 30 * MTA.HUD.Config.ScrRatio
local IconOffset = IconSize * 0.5

-- Scale it up a bit since it looks smaller then the other icons
local VehicleIconSize = IconSize * 1.5
local VehicleIconOffset = IconOffset * 1.5

-- This is icons based of the npc role
local KnownNpcIcons = {
    ["dealer"] = DealerIcon,
    ["car_dealer"] = CarDealerIcon,
    ["hardware_dealer"] = HardwareIcon,
    ["hotdog_dealer"] = HotdogIcon,
}

-- If you want to blacklist your npc from the map, perhaps "secret" npc
local NpcBlacklist = {
    ["_bad"] = true, -- Default return for npc without role
}

local PlayerVerticalLimit = 72
local MapImage = Material("vgui/mta_hud/maps/rp_unioncity")

local MapPosXLeft = MTA.HUD.Config.ScrRatio * 30
local MapPosXRight = ScrW() - (MTA.HUD.Config.ScrRatio * 280)
local MapPosYLeft = MTA.HUD.Config.ScrRatio * 30
local MapPosYRight = MTA.HUD.Config.ScrRatio * 50

local MapW = 250 * MTA.HUD.Config.ScrRatio
local MapH = 250 * MTA.HUD.Config.ScrRatio
local MapZoom = MTA.HUD.Config.ScrRatio * 50

local PlayerTriangle = {
    { x = 0, y = 13 * MTA.HUD.Config.ScrRatio },
    { x = -7 * MTA.HUD.Config.ScrRatio, y = 18 * MTA.HUD.Config.ScrRatio },
    { x = 0, y = 0 },
    { x = 7 * MTA.HUD.Config.ScrRatio, y = 18 * MTA.HUD.Config.ScrRatio }
}

local ArrowUp = {
    { x = -5 * MTA.HUD.Config.ScrRatio, y = 0 },
    { x = 0, y = -7 * MTA.HUD.Config.ScrRatio },
    { x = 5 * MTA.HUD.Config.ScrRatio, y = 0 }
}

local ArrowDown = {
    { x = 5 * MTA.HUD.Config.ScrRatio, y = 0 },
    { x = 0, y = 7 * MTA.HUD.Config.ScrRatio },
    { x = -5 * MTA.HUD.Config.ScrRatio, y = 0 }
}

local function GetMapTexturePos(pos)
    local pxD = 1024 / 2
    local pyD = 1024 / 2

    local rx = -pos.y * (-pxD / -16384) + pxD
    local ry = pos.x * ((1024 - pyD) / -16384) + pyD

    return rx, ry
end

local function GetMapDrawPos(origin, pos)
    local scale = MapZoom / 512

    local diff = (origin - pos) / scale

    local pxD = MapW / 2
    local pyD = MapH / 2

    local rx = diff.y * (-pxD / -16384) + pxD
    local ry = -diff.x * ((MapH - pyD) / -16384) + pyD

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

local function DrawMapObjects(origin)
    surface.SetMaterial(VaultIcon)
    for _, vault in ipairs(FindByClass("mta_vault")) do
        if IsValid(vault) then
            local px, py = GetMapDrawPos(origin, vault:GetPos())
            surface.DrawTexturedRect(px - IconOffset, py - IconOffset, IconSize, IconSize)
        end
    end

    for _, npc in ipairs(FindByClass("lua_npc")) do
        if IsValid(npc) then
            local role = npc:GetNWString("npc_role", "_bad")
            if not NpcBlacklist[role] then
                -- Grab the npc role icon or default to "unknown role" to always display an npc with a role
                local icon = KnownNpcIcons[role] or UnknownRoleIcon
                local px, py = GetMapDrawPos(origin, npc:GetPos())
                surface.SetMaterial(icon)
                surface.DrawTexturedRect(px - IconOffset, py - IconOffset, IconSize, IconSize)
            end
        end
    end

    -- Draw your vehicle on the map
    if MTA.Cars then
        local curVehicle = MTA.Cars.CurrentVehicle
        if IsValid(curVehicle) and curVehicle:GetDriver() ~= LocalPlayer() then
            local px, py = GetMapDrawPos(origin, curVehicle:GetPos())
            surface.SetMaterial(VehicleIcon)
            surface.DrawTexturedRect(px - VehicleIconOffset, py - VehicleIconOffset, VehicleIconSize, VehicleIconSize)
        end
    end

    --surface.SetDrawColor(MTA.PrimaryColor)
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= LocalPlayer() and ply:Alive() then
            local yaw = ply:EyeAngles().yaw
            local px, py = GetMapDrawPos(origin, ply:GetPos())
            local tri = TranslatePoly(PlayerTriangle, px, py - 10)
            tri = RotatePoly(tri, -yaw, px, py)
            draw.NoTexture()
            surface.SetDrawColor(MTA.PrimaryColor)
            surface.DrawPoly(tri)

            if ply:GetPos().z > LocalPlayer():GetPos().z + PlayerVerticalLimit then
                local up = TranslatePoly(ArrowUp, px, py - 20)
                surface.SetDrawColor(MTA.NewValueColor)
                surface.DrawPoly(up)
            end

            if ply:GetPos().z < LocalPlayer():GetPos().z - PlayerVerticalLimit then
                local down = TranslatePoly(ArrowDown, px, py + 20)
                surface.SetDrawColor(MTA.OldValueColor)
                surface.DrawPoly(down)
            end
        end
    end
    surface.SetDrawColor(MTA.TextColor)
end

if IsValid(MTA.HUD.Vars.MapPanel) then MTA.HUD.Vars.MapPanel:Remove() end

MTA.HUD.Vars.MapPanel = vgui.Create("Panel")
MTA.HUD.Vars.MapPanel.NoCleanup = true
MTA.HUD.Vars.MapPanel:SetSize(MapW, MapH)
MTA.HUD.Vars.MapPanel:SetPaintedManually(true)
MTA.HUD.Vars.MapPanel:SetKeyboardInputEnabled(false)
MTA.HUD.Vars.MapPanel:SetMouseInputEnabled(false)
MTA.HUD.Vars.MapPanel.Paint = function(self, w, h)
    local lp_pos = LocalPlayer():GetPos()
    local yaw = -EyeAngles().y

    local rx, ry = GetMapTexturePos(lp_pos)

    local startU = (rx - MapZoom) / 1024
    local startV = (ry - MapZoom) / 1024
    local endU = (rx + MapZoom) / 1024
    local endV = (ry + MapZoom) / 1024

    surface.SetMaterial(MapImage)
    surface.SetDrawColor(255, 255, 255, 180)
    surface.DrawTexturedRectUV(0, 0, w, h, startU, startV, endU, endV)

    DrawMapObjects(lp_pos)

    local tri = TranslatePoly(PlayerTriangle, w / 2, h / 2 - (10 * MTA.HUD.Config.ScrRatio))
    tri = RotatePoly(tri, yaw, w / 2, h / 2)
    draw.NoTexture()
    surface.DrawPoly(tri)

    surface.SetDrawColor(MTA.PrimaryColor)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
end

local Mat = Matrix()
local MatVec = Vector()

return function()
    Mat:SetField(2, 1, MTA.HUD.Config.MapPos:GetBool() and -0.08 or 0.08)

    MatVec.x = (MTA.HUD.Config.MapPos:GetBool() and MapPosXRight or MapPosXLeft) + (MTA.HUD.Config.HudMovement:GetBool() and MTA.HUD.Vars.LastTranslateY * 2 or 0)
    MatVec.y = (MTA.HUD.Config.MapPos:GetBool() and MapPosYRight or MapPosYLeft) + (MTA.HUD.Config.HudMovement:GetBool() and MTA.HUD.Vars.LastTranslateP * 3 or 0)

    Mat:SetTranslation(MatVec)

    cam.PushModelMatrix(Mat)
        MTA.HUD.Vars.MapPanel:PaintManual()

        surface.SetMaterial(PointsIcon)
        surface.SetDrawColor(255, 255, 255, 180)
        surface.DrawTexturedRect(0, MapH + (10 * MTA.HUD.Config.ScrRatio), IconSize, IconSize)

        surface.SetFont("MTAMissionsFontDesc")
        surface.SetTextColor(MTA.TextColor)
        surface.SetTextPos(IconSize + (10 * MTA.HUD.Config.ScrRatio), MapH + (12 * MTA.HUD.Config.ScrRatio))
        surface.DrawText(MTA.GetPlayerStat("points"))
    cam.PopModelMatrix()
end