IS_MTA_GMA = true

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("cl_init.lua")

AddCSLuaFile("client/cl_outlines.lua")
AddCSLuaFile("client/cl_targetid.lua")
AddCSLuaFile("client/cl_intro.lua")
AddCSLuaFile("client/cl_car_dealer.lua")

AddCSLuaFile("shared/sh_daily_challenges.lua")
AddCSLuaFile("shared/sh_gunstore.lua")
AddCSLuaFile("shared/sh_car_dealer.lua")
AddCSLuaFile("shared/sh_spawnmenu.lua")

include("sh_init.lua")

include("shared/sh_daily_challenges.lua")
include("shared/sh_gunstore.lua")
include("shared/sh_car_dealer.lua")
include("shared/sh_spawnmenu.lua")

include("server/sv_hud.lua")
include("server/sv_zones.lua")
include("server/sv_misc_map_ents.lua")

function GM:EntityRemoved(ent)
	-- Burning sounds are annoying.
	ent:StopSound("General.BurningFlesh")
	ent:StopSound("General.BurningObject")
	-- BaseClass has nothing
end

function GM:PostGamemodeLoaded()
	self.GrabEarAnimation = function()
	end
end
