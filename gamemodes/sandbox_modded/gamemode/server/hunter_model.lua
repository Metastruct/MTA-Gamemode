local hunter_files = {
	"materials/effects/huntermuzzle.vmt",
	"materials/effects/hunterphysblast.vmt",
	"materials/effects/hunterphysblast_normal.vtf",
	"materials/effects/huntertracer.vmt",

	"materials/models/weapons/hunter_flechette.vmt",
	"materials/models/weapons/hunter_flechette_normal.vtf",

	"materials/models/ministrider/mini_armor_basecolor.vmt",
	"materials/models/ministrider/mini_armor_exponent.vtf",
	"materials/models/ministrider/mini_armor_normal.vtf",
	"materials/models/ministrider/mini_iridescence.vtf",
	"materials/models/ministrider/mini_skin_basecolor.vmt",
	"materials/models/ministrider/mini_skin_exponent.vtf",
	"materials/models/ministrider/mini_skin_normal.vtf",

	"models/hunter.mdl",
	"models/hunter_animations.mdl",
	"models/weapons/hunter_flechette.mdl",

	"particles/hunter_flechette.pcf",
	"particles/hunter_projectile.pcf",
	"particles/hunter_shield_impact.pcf",
}

-- Add all the sounds
local SOUND_PATH = "sound/npc/ministrider/"

local sounds = file.Find(SOUND_PATH .. "*.wav", "GAME")
for _, sound in ipairs(sounds) do
	resource.AddFile(SOUND_PATH .. "/" .. sound)
end

for _, res in ipairs(hunter_files) do
	resource.AddFile(res)
end
