local tag = "MTASourcePatches"
hook.Add("HandleCrazyPhysics", tag, function(_, ent)
	if IsValid(ent) then
		ent:Remove()
		return false
	end
end)

-- NPC npc_combine_s stuck in wall--level design error at (-1816.31 6072.35 5496.03)
local pattern = "^NPC ([a-zA-Z%_]+) stuck in wall%-%-level design error at %(([0-9%-%.%s]+)%)"
local function handle_stuck_npc(t, msg)
	if t == 0 and msg:match(pattern) then
		msg:gsub(pattern, function(npc_class, pos_str)
			local chunks = string.Explode(" ", pos_str)
			local x, y, z = tonumber(chunks[1]), tonumber(chunks[2]), tonumber(chunks[3])
			if not x or not y or not z then return end

			local pos = Vector(x, y, z)
			for _, ent in ipairs(ents.FindInSphere(pos, 20)) do
				if not IsValid(ent) or not ent:IsNPC() then continue end
				if ent:GetClass() == npc_class then
					ent:Remove()
				end
			end
		end)

		return true
	end

	return false
end


hook.Add("EngineSpew", tag, function(type, msg)
	if handle_stuck_npc(type, msg) then return "" end -- return an empty string to remove logs
	-- more shit?
end)