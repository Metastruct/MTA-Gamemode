local ITEM = {}

ITEM.StackLimit = 12

local function add_debug_function(name)
	ITEM[name] = function(self, ...)
		print("[ITEM DEBUG]", name, ...)
	end
end

add_debug_function("Initialize")
add_debug_function("OnDrop")
add_debug_function("ShouldDrop")
add_debug_function("OnAdd")
add_debug_function("OnMove")
add_debug_function("OnUse")
add_debug_function("OnRemove")

MTA.Inventory.RegisterItem("debug", ITEM)