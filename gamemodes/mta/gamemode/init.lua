DeriveGamemode("sandbox")
DEFINE_BASECLASS("gamemode_sandbox")
GM.Sandbox = BaseClass

IS_MTA_GMA = true

function MTA_TABLE(name)
	_G.MTA = _G.MTA or {}
	_G.MTA[name] = _G.MTA[name] or {}
	return _G.MTA[name]
end

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("cl_init.lua")

AddCSLuaFile("client/cl_outlines.lua")
AddCSLuaFile("client/cl_targetid.lua")
AddCSLuaFile("client/cl_intro.lua")
AddCSLuaFile("client/cl_car_dealer.lua")
AddCSLuaFile("client/dinventory.lua")
AddCSLuaFile("client/cl_inventory.lua")
AddCSLuaFile("client/cl_crafting.lua")

AddCSLuaFile("shared/sh_daily_challenges.lua")
AddCSLuaFile("shared/sh_death_recap.lua")
AddCSLuaFile("shared/sh_gunstore.lua")
AddCSLuaFile("shared/sh_car_dealer.lua")
AddCSLuaFile("shared/sh_hardware_dealer.lua")
AddCSLuaFile("shared/sh_inventory.lua")
AddCSLuaFile("shared/sh_crafting.lua")
AddCSLuaFile("shared/sh_spawnmenu.lua")

include("sh_init.lua")

include("shared/sh_daily_challenges.lua")
include("shared/sh_death_recap.lua")
include("shared/sh_gunstore.lua")
include("shared/sh_car_dealer.lua")
include("shared/sh_hardware_dealer.lua")
include("shared/sh_inventory.lua")
include("shared/sh_crafting.lua")
include("shared/sh_spawnmenu.lua")

include("server/sv_statuses.lua")
include("server/sv_hud.lua")
include("server/sv_zones.lua")
include("server/sv_misc_map_ents.lua")
include("server/sv_hunter_model.lua")
include("server/sv_bank.lua")
include("server/sv_combine_vault_skybox.lua")

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
