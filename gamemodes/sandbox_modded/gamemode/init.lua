IS_MTA_GMA = true

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_outlines.lua")
AddCSLuaFile("cl_intro.lua")
AddCSLuaFile("sh_daily_challenges.lua")
AddCSLuaFile("sh_gunstore.lua")
AddCSLuaFile("sh_car_dealer.lua")
AddCSLuaFile("cl_car_dealer.lua")
AddCSLuaFile("sh_spawnmenu.lua")

include("sh_init.lua")
include("sh_daily_challenges.lua")
include("sh_gunstore.lua")
include("sh_car_dealer.lua")
include("sh_spawnmenu.lua")

include("sv_hud.lua")

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
