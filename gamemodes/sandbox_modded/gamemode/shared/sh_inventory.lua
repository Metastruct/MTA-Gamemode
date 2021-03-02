local tag = "mta_inventory"
local inventory = MTA_TABLE("Inventory")
local MAX_WIDTH = 9
local MAX_HEIGHT = 4
local REQUEST_RATE_LIMIT = 2
local MAX_DROP_DISTANCE = 300
local DEFAULT_STACK_LIMIT = 1

local INCREMENTAL_NETWORK_ADD = 1
local INCREMENTAL_NETWORK_MODIFY = 2
local INCREMENTAL_NETWORK_REMOVE = 3
local INCREMENTAL_NETWORK_DROP = 4
local INCREMENTAL_NETWORK_USE = 5

local NET_INVENTORY_UPDATE = "MTA_INVENTORY_UPDATE"
local NET_INVENTORY_REQUESTS = "MTA_INVENTORY_REQUESTS"

inventory.Instances = {}
inventory.Items = {}

local function can_db()
    return _G.db and _G.co
end

function inventory.CallItem(item_class, method, ...)
    local item = inventory.Items[item_class]
    if not item then return end
    if not item[method] then return end

    local succ, ret = xpcall(item[method], ErrorNoHalt, item, ...)
    if succ then return ret end
end

function inventory.RegisterItem(item_class, item)
    item.ClassName = item_class
    inventory.Items[item_class] = item
end

function inventory.HasItem(ply, item_class, amount)
    if SERVER and not can_db() then return false end

    local inst = inventory.Instances[ply]
    if not inst then return false end

    amount = amount or 1

    local total = 0
    for y = 1, MAX_HEIGHT do
        for x = 1, MAX_WIDTH do
            local inv_space = inst[y][x]
            if inv_space and inv_space.Class == item_class then
                total = total + inv_space.Amount
                if total >= amount then return true end
            end
        end
    end

    return false
end

function inventory.GetInventory(ply)
    return inventory.Instances[ply]
end

function inventory.GetInventorySlot(ply, pos_x, pos_y)
    local inst = inventory.Instances[ply]
    if not inst then return end

    return inst[pos_y][pos_x]
end

function inventory.GetStackLimit(item_class)
    local item = inventory.Items[item_class]
    if not item then return DEFAULT_STACK_LIMIT end
    if not isnumber(item.StackLimit) then return DEFAULT_STACK_LIMIT end
    return item.StackLimit
end

if SERVER then
    util.AddNetworkString(NET_INVENTORY_UPDATE)
    util.AddNetworkString(NET_INVENTORY_REQUESTS)

    local function compress_table(tbl)
        if not tbl then return "" end
        local json = util.TableToJSON(tbl)
        return util.Compress(util.Base64Encode(json))
    end

    local request_rate_limits = {}
    net.Receive(NET_INVENTORY_REQUESTS, function(_, ply)
        local id = net.ReadInt(32)
        local requested_ply = net.ReadEntity()

        if request_rate_limits[ply] or not can_db() then
            timer.Simple(0, function()
                net.Start(NET_INVENTORY_REQUESTS)
                net.WriteInt(id, 32)
                net.WriteBool(false)
                net.WriteEntity(requested_ply)
                net.Send(ply)
            end)

            return
        end

        request_rate_limits[ply] = true
        timer.Simple(REQUEST_RATE_LIMIT, function() request_rate_limits[ply] = nil end)

        local inst = inventory.Instances[requested_ply]
        local compressed_data = compress_table(inst)
        local len = #compressed_data

        timer.Simple(0, function()
            net.Start(NET_INVENTORY_REQUESTS)
            net.WriteInt(id, 32)
            net.WriteBool(true)
            net.WriteEntity(requested_ply)
            net.WriteInt(len, 32)
            net.WriteData(compressed_data, len)
            net.Send(ply)
        end)
    end)

    net.Receive(NET_INVENTORY_UPDATE, function(_, ply)
        local mode = net.ReadInt(32)
        if mode == INCREMENTAL_NETWORK_MODIFY then
            local item_class = net.ReadString()
            local old_pos_x = net.ReadInt(32)
            local old_pos_y = net.ReadInt(32)
            local new_pos_x = net.ReadInt(32)
            local new_pos_y = net.ReadInt(32)
            local amount = net.ReadInt(32)
            inventory.MoveItem(ply, item_class, old_pos_x, old_pos_y, new_pos_x, new_pos_y, amount)
        elseif mode == INCREMENTAL_NETWORK_REMOVE then
            local item_class = net.ReadString()
            local pos_x = net.ReadInt(32)
            local pos_y = net.ReadInt(32)
            local amount = net.ReadInt(32)
            inventory.RemoveItem(ply, item_class, pos_x, pos_y, amount)
        elseif mode == INCREMENTAL_NETWORK_DROP then
            local item_class = net.ReadString()
            local pos_x = net.ReadInt(32)
            local pos_y = net.ReadInt(32)
            local amount = net.ReadInt(32)
            local target_pos = net.ReadVector()
            inventory.DropItem(ply, item_class, pos_x, pos_y, amount, target_pos)
        elseif mode == INCREMENTAL_NETWORK_USE then
            local item_class = net.ReadString()
            local pos_x = net.ReadInt(32)
            local pos_y = net.ReadInt(32)
            local amount = net.ReadInt(32)
            inventory.UseItem(ply, item_class, pos_x, pos_y, amount)
        end
    end)

    function inventory.UseItem(ply, item_class, pos_x, pos_y, amount)
        local success = inventory.RemoveItem(ply, item_class, pos_x, pos_y, amount)
        if not success then return false end

        inventory.CallItem(item_class, "OnUse", ply, amount)
        return true
    end

    local function add_raw_item(ply, instance, item_class, pos_x, pos_y, amount)
        local inv_space = instance[pos_y][pos_x]
        if not inv_space then
            instance[pos_y][pos_x] = { Class = item_class, Amount = amount }
        else
            inv_space.Amount = inv_space.Amount + amount
        end

        co(function()
            db.Query(("INSERT INTO mta_inventory(id, item_class, slot_x, slot_y, amount) VALUES(%s, '%s', %d, %d, %d);")
                :format(ply:AccountID(), item_class, pos_x, pos_y, amount))
        end)

        net.Start(NET_INVENTORY_UPDATE)
        net.WriteBool(true)
        net.WriteEntity(ply)
        net.WriteInt(INCREMENTAL_NETWORK_ADD, 32)
        net.WriteString(item_class)
        net.WriteInt(pos_x, 32)
        net.WriteInt(pos_y, 32)
        net.WriteInt(amount, 32)
        net.Send(ply)

        inventory.CallItem(item_class, "OnAdd", ply, amount)
    end

    local function find_ok_inventory_pos(instance, item_class, stack_limit)
        for y = 1, MAX_HEIGHT do
            for x = 1, MAX_WIDTH do
                local inv_space = instance[y][x]
                if not inv_space then return true, y, x end
                if inv_space and inv_space.Class == item_class and inv_space.Amount < stack_limit then
                    return true, y, x
                end
            end
        end

        return false
    end

    function inventory.AddItem(ply, item_class, amount)
        if not can_db() then return false end

        local inst = inventory.Instances[ply]
        if not inst then return false end

        amount = amount or 1

        local stack_limit = inventory.GetStackLimit(item_class)
        local n_iter = math.ceil(amount / stack_limit)
        for _ = 1, n_iter do
            local succ, pos_y, pos_x = find_ok_inventory_pos(inst, item_class, stack_limit)
            if not succ then return false end

            local to_add = amount > stack_limit and stack_limit or amount
            amount = amount - to_add

            add_raw_item(ply, inst, item_class, pos_x, pos_y, to_add)
        end

        return true
    end

    -- is_row = true -> checks for row limits, is_row = false -> checks for column limits
    local function is_ok_inventory_pos(pos, is_row)
        if not isnumber(pos) then return false end
        if pos <= 0 then return false end

        local limit = is_row and MAX_WIDTH or MAX_HEIGHT
        return pos <= limit
    end

    local function try_move_item(instance, item_class, pos_x, pos_y)
        pos_y = math.Clamp(isnumber(pos_y) or 1, 1, MAX_HEIGHT)
        pos_x = math.Clamp(isnumber(pos_x) or 1, 1, MAX_WIDTH)

        local inv_space = instance[pos_y][pos_x]
        if not inv_space then return true, pos_y, pos_x end -- space not occupied, this is ok to use
        if inv_space.Class == item_class then return true, pos_y, pos_x end

        return false, -1, -1
    end

    function inventory.MoveItem(ply, item_class, old_pos_x, old_pos_y, new_pos_x, new_pos_y, amount)
        if not can_db() then return false end
        if not amount then return false end

        local inst = inventory.Instances[ply]
        if not inst then return  false end
        if not is_ok_inventory_pos(old_pos_x, true) or not is_ok_inventory_pos(old_pos_y, false) then return false end

        local old_inv_space = inst[old_pos_y][old_pos_x]
        if not old_inv_space then return false end
        if old_inv_space.Class ~= item_class then return false end

        local new_inv_space = inst[new_pos_y][new_pos_y]
        local stack_limit = inventory.GetStackLimit(item_class)
        if new_inv_space and (new_inv_space.Amount + amount) > stack_limit then return false end

        local succ, new_pos_y, new_pos_x = try_move_item(inst, item_class, new_pos_x, new_pos_y)
        if not succ then return false end

        local account_id = ply:AccountID()
        local remaining = old_inv_space.Amount - amount
        local sql_req
        if remaining <= 0 then
            inst[old_pos_y][old_pos_x] = nil
            sql_req = ("DELETE FROM mta_inventory WHERE id = %d AND item_class = '%s' AND slot_x = %d AND slot_y = %d;")
                :format(account_id, item_class, old_pos_x, old_pos_y)
        else
            old_inv_space.Amount = remaining
            sql_req = ("UPDATE mta_inventory SET amount = %d WHERE id = %d AND item_class = '%s' AND slot_x = %d AND slot_y = %d;")
                :format(remaining, account_id, item_class, old_pos_x, old_pos_y)
        end

        co(function() db.Query(sql_req) end)

        if not new_inv_space then
            inst[new_pos_y][new_pos_y] = { Class = item_class, Amount = amount }
            sql_req = ("INSERT INTO mta_inventory(id, item_class, slot_x, slot_y, amount) VALUES(%d, '%s', %d, %d, %d);")
                :format(account_id, item_class, new_pos_x, new_pos_y, amount)
        else
            new_inv_space.Amount = new_inv_space.Amount + amount
            sql_req = ("UPDATE mta_inventory SET amount = %d WHERE id = %d AND item_class = '%s' AND slot_x = %d AND slot_y = %d;")
                :format(new_inv_space.Amount, account_id, item_class, new_pos_x, new_pos_y)
        end

        co(function() db.Query(sql_req) end)

        net.Start(NET_INVENTORY_UPDATE)
        net.WriteBool(true)
        net.WriteEntity(ply)
        net.WriteInt(INCREMENTAL_NETWORK_MODIFY, 32)
        net.WriteString(item_class)
        net.WriteInt(old_pos_x, 32)
        net.WriteInt(old_pos_y, 32)
        net.WriteInt(new_pos_x, 32)
        net.WriteInt(new_pos_y, 32)
        net.WriteInt(amount, 32)
        net.Send(ply)

        inventory.CallItem(item_class, "OnMove", ply, amount)
        return true
    end

    function inventory.RemoveItem(ply, item_class, pos_x, pos_y, amount)
        if not can_db() then return false end
        if not amount then return false end

        local inst = inventory.Instances[ply]
        if not inst then return false end
        if not is_ok_inventory_pos(pos_x, true) or not is_ok_inventory_pos(pos_y, false) then return false end

        local old_inv_space = inst[pos_y][pos_x]
        if not old_inv_space then return false end
        if old_inv_space.Class ~= item_class then return false end

        local account_id = ply:AccountID()
        local remaining = old_inv_space.Amount - amount
        local sql_req
        if remaining <= 0 then
            inst[pos_y][pos_x] = nil
            sql_req = ("DELETE FROM mta_inventory WHERE id = %d AND item_class = '%s' AND slot_x = %d AND slot_y = %d;")
                :format(account_id, item_class, pos_x, pos_y)
        else
            old_inv_space.Amount = remaining
            sql_req = ("UPDATE mta_inventory SET amount = %d WHERE id = %d AND item_class = '%s' AND slot_x = %d AND slot_y = %d;")
                :format(remaining, account_id, item_class, pos_x, pos_y)
        end

        co(function() db.Query(sql_req) end)

        net.Start(NET_INVENTORY_UPDATE)
        net.WriteBool(true)
        net.WriteEntity(ply)
        net.WriteInt(INCREMENTAL_NETWORK_REMOVE, 32)
        net.WriteString(item_class)
        net.WriteInt(pos_x, 32)
        net.WriteInt(pos_y, 32)
        net.WriteInt(amount, 32)
        net.Send(ply)

        inventory.CallItem(item_class, "OnRemove", ply, amount)
        return true
    end

    function inventory.DropItem(ply, item_class, pos_x, pos_y, amount, target_pos)
        local should_drop = inventory.CallItem(item_class, "ShouldDrop", ply, amount, target_pos)
        if should_drop == false then return end

        local succ = inventory.RemoveItem(ply, item_class, pos_x, pos_y, amount)
        if not succ then return false end

        local eye_pos = ply:EyePos()
        if target_pos:Distance(eye_pos) >= MAX_DROP_DISTANCE then
            local dir = (eye_pos - target_pos):GetNormalized()
            target_pos = dir * MAX_DROP_DISTANCE
        end

        local is_handled = inventory.CallItem(item_class, "OnDrop", ply, amount, target_pos)
        if not is_handled then
            for _ = 1, amount do
                inventory.CreateItemEntity(item_class, target_pos)
            end
        end

        return true
    end

    function inventory.CreateItemEntity(item_class, world_pos)
        local item_base = ents.Create("mta_item_base")
        item_base:SetPos(world_pos)
        item_base:Spawn()
        item_base:SetItemClass(item_class)

        return item_base
    end

    function inventory.FillInventory(ply, data_rows)
        local inst = {}
        for _ = 1, MAX_HEIGHT do
            table.insert(inst, {})
        end

        for _, data_row in pairs(data_rows) do
            local pos_x, pos_y, amount =
                tonumber(data_row.slot_x),
                tonumber(data_row.slot_y),
                tonumber(data_row.amount)

            local row = inst[pos_y]
            row[pos_x] = { Class = data_row.item_class, Amount = amount }
            inventory.CallItem(data_row.item_class, "Initialize", ply, amount)
        end

        inventory.Instances[ply] = inst

        -- we do that here, so if it fails it doesnt error out within the net message
        local compressed_data = compress_table(inst)
        local len = #compressed_data

        net.Start(NET_INVENTORY_UPDATE)
        net.WriteBool(false)
        net.WriteEntity(ply)
        net.WriteInt(len, 32)
        net.WriteData(compressed_data, len)
        net.Send(ply)
    end

    function inventory.Init(ply)
		if not can_db() then return end
        co(function()
			local rows = db.Query(("SELECT * FROM mta_inventory WHERE id = %d;"):format(ply:AccountID()))
            inventory.FillInventory(ply, rows)
            hook.Run("MTAInventoryInitialized", ply)
		end)
    end

    hook.Add("PlayerFullyConnected", tag, inventory.Init)
    hook.Add("PlayerDisconnected", tag, function(ply) inventory.Instances[ply] = nil end)
end

if CLIENT then
    local function decompress_table(compressed_tbl)
        if not compressed_tbl then return {} end
        local json = util.Base64Decode(util.Decompress(compressed_tbl))
        return util.JSONToTable(json)
    end

    net.Receive(NET_INVENTORY_UPDATE, function()
        local is_incremental = net.ReadBool()
        local ply = net.ReadEntity()
        if not is_incremental then
            local len = net.ReadInt(32)
            local data = net.ReadData(len)
            inventory.Instances[ply] = decompress_table(data)
        else
            local mode = net.ReadInt(32)
            if mode == INCREMENTAL_NETWORK_ADD then
                local item_class = net.ReadString()
                local pos_x = net.ReadInt(32)
                local pos_y = net.ReadInt(32)
                local amount = net.ReadInt(32)

                local inst = inventory.Instances[ply]
                if not inst then return end

                inst[pos_y][pos_x] = { Class = item_class, Amount = amount }
            elseif mode == INCREMENTAL_NETWORK_MODIFY then
                local item_class = net.ReadString()
                local old_pos_x = net.ReadInt(32)
                local old_pos_y = net.ReadInt(32)
                local new_pos_x = net.ReadInt(32)
                local new_pos_y = net.ReadInt(32)
                local amount = net.ReadInt(32)

                local inst = inventory.Instances[ply]
                if not inst then return end

                local old_inv_space = inst[old_pos_y][old_pos_x]
                local remaining = old_inv_space.Amount - amount
                if remaining <= 0 then
                    inst[old_pos_y][old_pos_x] = nil
                else
                    old_inv_space.Amount = remaining
                end

                local new_inv_space = inst[new_pos_y][new_pos_y]
                if not new_inv_space then
                    inst[new_pos_y][new_pos_y] = { Class = item_class, Amount = amount }
                else
                    new_inv_space.Amount = new_inv_space.Amount + amount
                end
            elseif mode == INCREMENTAL_NETWORK_REMOVE then
                local item_class = net.ReadString()
                local pos_x = net.ReadInt(32)
                local pos_y = net.ReadInt(32)
                local amount = net.ReadInt(32)

                local inst = inventory.Instances[ply]
                if not inst then return end

                local inv_space = inst[pos_y][pos_x]
                local remaining = inv_space.Amount - amount
                if remaining <= 0 then
                    inst[pos_y][pos_x] = nil
                else
                    inv_space.Amount = remaining
                end
            else
                ErrorNoHalt("Unknown inventory message mode?!!")
            end
        end

        hook.Run("MTAInventoryUpdate", ply)
    end)

    function inventory.MoveItem(item_class, old_pos_x, old_pos_y, new_pos_x, new_pos_y, amount)
        net.Start(NET_INVENTORY_UPDATE)
        net.WriteInt(INCREMENTAL_NETWORK_MODIFY, 32)
        net.WriteString(item_class)
        net.WriteInt(old_pos_x, 32)
        net.WriteInt(old_pos_y, 32)
        net.WriteInt(new_pos_x, 32)
        net.WriteInt(new_pos_y, 32)
        net.WriteInt(amount, 32)
        net.SendToServer()
    end

    function inventory.RemoveItem(item_class, pos_x, pos_y, amount)
        net.Start(NET_INVENTORY_UPDATE)
        net.WriteInt(INCREMENTAL_NETWORK_REMOVE, 32)
        net.WriteString(item_class)
        net.WriteInt(pos_x, 32)
        net.WriteInt(pos_y, 32)
        net.WriteInt(amount, 32)
        net.SendToServer()
    end

    function inventory.DropItem(item_class, pos_x, pos_y, amount, target_pos)
        net.Start(NET_INVENTORY_UPDATE)
        net.WriteInt(INCREMENTAL_NETWORK_DROP, 32)
        net.WriteString(item_class)
        net.WriteInt(pos_x, 32)
        net.WriteInt(pos_y, 32)
        net.WriteInt(amount, 32)
        net.WriteVector(target_pos)
        net.SendToServer()
    end

    function inventory.UseItem(item_class, pos_x, pos_y, amount)
        net.Start(NET_INVENTORY_UPDATE)
        net.WriteInt(INCREMENTAL_NETWORK_USE, 32)
        net.WriteString(item_class)
        net.WriteInt(pos_x, 32)
        net.WriteInt(pos_y, 32)
        net.WriteInt(amount, 32)
        net.SendToServer()
    end

    local request_callbacks = {}
    net.Receive(NET_INVENTORY_REQUESTS, function()
        local id = net.ReadInt(32)
        local success = net.ReadBool()
        local callbacks = request_callbacks[id]
        if callbacks then
            if success then
                local ply = net.ReadEntity()
                local len = net.ReadInt(32)
                local data = net.ReadData(len)
                local inst = decompress_table(data)
                inventory.Instances[ply] = inst
                callbacks.Success(inst)
            else
                local ply = net.ReadEntity()
                local inst = inventory.Instances[ply]
                if inst then
                    callbacks.Success(inst)
                else
                    callbacks.Error()
                end
            end
            request_callbacks[id] = nil
        end
    end)

    local cur_id = 0
    local next_req = 0
    function inventory.RequestPlayerInventory(ply, success_callback, error_callback)
        if CurTime() < next_req then
            if inventory.Instances[ply] then
                success_callback(inventory.Instances[ply])
            else
                error_callback()
            end

            return
        end

        request_callbacks[cur_id] = { Success = success_callback, Error = error_callback }

        net.Start(NET_INVENTORY_REQUESTS)
        net.WriteInt(cur_id, 32)
        net.WriteEntity(ply)
        net.SendToServer()

        cur_id = cur_id + 1
        next_req = CurTime() + REQUEST_RATE_LIMIT
    end
end

-- initialize items
local path = "sandbox_modded/gamemode/shared_items"
for _, f in pairs(file.Find(path .. "/*.lua", "LUA")) do
    local file_path = ("%s/%s"):format(path, f)
    if SERVER then
        AddCSLuaFile(file_path)
    end

    include(file_path)
end