IS_MTA_GMA = true

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("sh_hud.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("sh_gunstore.lua")

include("sh_init.lua")
include("sh_hud.lua")
include("sh_gunstore.lua")

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
