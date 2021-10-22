DeriveGamemode("sandbox")
DEFINE_BASECLASS("gamemode_sandbox")
GM.Sandbox = BaseClass

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("cl_init.lua")

AddCSLuaFile("client/cl_outlines.lua")
AddCSLuaFile("client/cl_targetid.lua")
AddCSLuaFile("client/cl_intro.lua")
AddCSLuaFile("client/cl_car_dealer.lua")
AddCSLuaFile("client/dinventory.lua")
AddCSLuaFile("client/cl_inventory.lua")
AddCSLuaFile("client/cl_quick_items.lua")
AddCSLuaFile("client/cl_crafting.lua")
AddCSLuaFile("client/cl_apartments.lua")

AddCSLuaFile("shared/sh_daily_challenges.lua")
AddCSLuaFile("shared/sh_death_recap.lua")
AddCSLuaFile("shared/sh_gunstore.lua")
AddCSLuaFile("shared/sh_car_dealer.lua")
AddCSLuaFile("shared/sh_hardware_dealer.lua")
AddCSLuaFile("shared/sh_inventory.lua")
AddCSLuaFile("shared/sh_crafting.lua")
AddCSLuaFile("shared/sh_spawnmenu.lua")
AddCSLuaFile("shared/sh_apartments.lua")
AddCSLuaFile("shared/sh_goliath.lua")
AddCSLuaFile("shared/sh_hotdog_dealer.lua")

include("sh_init.lua")

include("shared/sh_daily_challenges.lua")
include("shared/sh_death_recap.lua")
include("shared/sh_gunstore.lua")
include("shared/sh_car_dealer.lua")
include("shared/sh_hardware_dealer.lua")
include("shared/sh_inventory.lua")
include("shared/sh_crafting.lua")
include("shared/sh_spawnmenu.lua")
include("shared/sh_apartments.lua")
include("shared/sh_goliath.lua")
include("shared/sh_hotdog_dealer.lua")

include("server/sv_source_patches.lua")
include("server/sv_statuses.lua")
include("server/sv_hud.lua")
include("server/sv_zones.lua")
include("server/sv_misc_map_ents.lua")
include("server/sv_hunter_model.lua")
include("server/sv_bank.lua")
include("server/sv_combine_vault_skybox.lua")
include("server/sv_apartments.lua")
include("server/sv_wanders.lua")

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
