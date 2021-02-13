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

local find_by_class = ents.FindByClass
local dealer_icon = Material("vgui/mta_hud/dealer_icon.png")
local vault_icon = Material("vgui/mta_hud/vault_icon.png")
local car_dealer_icon = Material("vgui/mta_hud/garage_icon.png")
local vehicle_icon = Material("vgui/mta_hud/vehicle_icon.png")
local unknown_role_icon = Material("vgui/mta_hud/business_icon.png")

local icon_size = 30 * MTAHud.Config.ScrRatio
local icon_offset = icon_size * 0.5

-- Scale it up a bit since it looks smaller then the other icons
local veh_icon_size = icon_size * 1.5
local veh_icon_offset = icon_offset * 1.5

-- This is icons based of the npc role
local known_npc_icons = {
    ["dealer"] = dealer_icon,
    ["car_dealer"] = car_dealer_icon,
}

-- If you want to blacklist your npc from the map, perhaps "secret" npc
local npc_black_list = {
    ["_bad"] = true, -- Default return for npc without role
}

local function DrawMapObjects(origin)
    surface.SetMaterial(vault_icon)
    for _, vault in ipairs(find_by_class("mta_vault")) do
        if IsValid(vault) then
            local px, py = GetMapDrawPos(origin, vault:GetPos())
            if px < MapW - icon_offset and py < MapH - icon_offset then
                surface.DrawTexturedRect(px - icon_offset, py - icon_offset, icon_size, icon_size)
            end
        end
    end

    for _, npc in ipairs(find_by_class("lua_npc")) do
        if IsValid(npc) then
            local role = npc:GetNWString("npc_role", "_bad")
            if not npc_black_list[role] then
                -- Grab the npc role icon or default to "unknown role" to always display an npc with a role
                local icon = known_npc_icons[role] or unknown_role_icon
                local px, py = GetMapDrawPos(origin, npc:GetPos())
                if px < MapW - icon_offset and py < MapH - icon_offset then
                    surface.SetMaterial(icon)
                    surface.DrawTexturedRect(px - icon_offset, py - icon_offset, icon_size, icon_size)
                end
            end
        end
    end

    -- Draw your vehicle on the map
    if MTACars then
        local curVehicle = MTACars.CurrentVehicle
        if IsValid(curVehicle) and curVehicle:GetDriver() ~= LocalPlayer() then
            local px, py = GetMapDrawPos(origin, curVehicle:GetPos())
            if px < MapW - veh_icon_offset and py < MapH - veh_icon_offset then
                surface.SetMaterial(vehicle_icon)
                surface.DrawTexturedRect(px - veh_icon_offset, py - veh_icon_offset, veh_icon_size, veh_icon_size)
            end
        end
    end
end

return {
    Draw = function()
        local lp_pos = LocalPlayer():GetPos()
        local yaw = -EyeAngles().y

        local mat = Matrix()

        mat:SetField(2, 1, MTAHud.Config.HudPos:GetBool() and -0.08 or 0.08)

        MatVec.x = (MTAHud.Config.HudPos:GetBool() and MapPosXRight or MapPosXLeft) + (MTAHud.Config.HudMovement:GetBool() and MTAHud.Vars.LastTranslateY * 2 or 0)
        MatVec.y = (MTAHud.Config.HudPos:GetBool() and MapPosYRight or MapPosYLeft) + (MTAHud.Config.HudMovement:GetBool() and MTAHud.Vars.LastTranslateP * 3 or 0)

        mat:SetTranslation(MatVec)

        cam.PushModelMatrix(mat)
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
        cam.PopModelMatrix()
    end
}