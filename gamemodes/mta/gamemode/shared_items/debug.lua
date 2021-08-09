local ITEM = {}

ITEM.Name = "Debug"
ITEM.Model = "models/Gibs/HGIBS.mdl"
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
add_debug_function("OnItemEntitySet")
add_debug_function("OnItemEntityDraw")
add_debug_function("OnItemEntityPaint")

MTA.Inventory.RegisterItem("debug", ITEM)