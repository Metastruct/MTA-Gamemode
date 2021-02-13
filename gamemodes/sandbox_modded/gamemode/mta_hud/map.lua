local FindByClass = ents.FindByClass
local DealerIcon = Material("vgui/mta_hud/dealer_icon.png")
local VaultIcon = Material("vgui/mta_hud/vault_icon.png")
local CarDealerIcon = Material("vgui/mta_hud/garage_icon.png")
local VehicleIcon = Material("vgui/mta_hud/vehicle_icon.png")
local UnknownRoleIcon = Material("vgui/mta_hud/business_icon.png")
local DoshIcon = Material("vgui/mta_hud/points_icon.png")

local IconSize = 30 * MTAHud.Config.ScrRatio
local IconOffset = IconSize * 0.5

-- Scale it up a bit since it looks smaller then the other icons
local VehicleIconSize = IconSize * 1.5
local VehicleIconOffset = IconOffset * 1.5

-- This is icons based of the npc role
local KnownNpcIcons = {
    ["dealer"] = DealerIcon,
    ["car_dealer"] = CarDealerIcon,
}

-- If you want to blacklist your npc from the map, perhaps "secret" npc
local NpcBlacklist = {
    ["_bad"] = true, -- Default return for npc without role
}

local WhiteColor = Color(255, 255, 255)

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

local Mat = Matrix()
local MatVec = Vector()

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
            if px < MapW - IconOffset and py < MapH - IconOffset then
                surface.DrawTexturedRect(px - IconOffset, py - IconOffset, IconSize, IconSize)
            end
        end
    end

    for _, npc in ipairs(FindByClass("lua_npc")) do
        if IsValid(npc) then
            local role = npc:GetNWString("npc_role", "_bad")
            if not NpcBlacklist[role] then
                -- Grab the npc role icon or default to "unknown role" to always display an npc with a role
                local icon = KnownNpcIcons[role] or UnknownRoleIcon
                local px, py = GetMapDrawPos(origin, npc:GetPos())
                if px < MapW - IconOffset and py < MapH - IconOffset then
                    surface.SetMaterial(icon)
                    surface.DrawTexturedRect(px - IconOffset, py - IconOffset, IconSize, IconSize)
                end
            end
        end
    end

    -- Draw your vehicle on the map
    if MTACars then
        local curVehicle = MTACars.CurrentVehicle
        if IsValid(curVehicle) and curVehicle:GetDriver() ~= LocalPlayer() then
            local px, py = GetMapDrawPos(origin, curVehicle:GetPos())
            if px < MapW - VehicleIconOffset and py < MapH - VehicleIconOffset then
                surface.SetMaterial(VehicleIcon)
                surface.DrawTexturedRect(px - VehicleIconOffset, py - VehicleIconOffset, VehicleIconSize, VehicleIconSize)
            end
        end
    end
end

return function()
    local lp_pos = LocalPlayer():GetPos()
    local yaw = -EyeAngles().y

    Mat:SetField(2, 1, MTAHud.Config.MapPos:GetBool() and -0.08 or 0.08)

    MatVec.x = (MTAHud.Config.MapPos:GetBool() and MapPosXRight or MapPosXLeft) + (MTAHud.Config.HudMovement:GetBool() and MTAHud.Vars.LastTranslateY * 2 or 0)
    MatVec.y = (MTAHud.Config.MapPos:GetBool() and MapPosYRight or MapPosYLeft) + (MTAHud.Config.HudMovement:GetBool() and MTAHud.Vars.LastTranslateP * 3 or 0)

    Mat:SetTranslation(MatVec)

    cam.PushModelMatrix(Mat)
        local rx, ry = GetMapTexturePos(lp_pos)

        local startU = (rx - MapZoom) / 1024
        local startV = (ry - MapZoom) / 1024
        local endU = (rx + MapZoom) / 1024
        local endV = (ry + MapZoom) / 1024

        surface.SetMaterial(MapImage)
        surface.SetDrawColor(255, 255, 255, 180)
        surface.DrawTexturedRectUV(0, 0, MapW, MapH, startU, startV, endU, endV)

        DrawMapObjects(lp_pos)

        local tri = TranslatePoly(PlayerTriangle, MapW / 2, MapH / 2 - (10 * MTAHud.Config.ScrRatio))
        tri = RotatePoly(tri, yaw, MapW / 2, MapH / 2)
        draw.NoTexture()
        surface.DrawPoly(tri)

        surface.SetDrawColor(244, 135, 2)
        surface.DrawOutlinedRect(0, 0, MapW, MapH, 2)

        surface.SetMaterial(DoshIcon)
        surface.SetDrawColor(255, 255, 255, 180)
        surface.DrawTexturedRect(0, MapH + (10 * MTAHud.Config.ScrRatio), IconSize, IconSize)

        surface.SetFont("MTAMissionsFontDesc")
        surface.SetTextColor(WhiteColor)
        surface.SetTextPos(IconSize + (10 * MTAHud.Config.ScrRatio), MapH + (12 * MTAHud.Config.ScrRatio))
        surface.DrawText(MTA.GetPlayerStat("points"))
    cam.PopModelMatrix()
end