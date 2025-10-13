local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local cfg = dofile(modpath .. "/config.lua")
local storage = minetest.get_mod_storage()
local S = core.get_translator(modname)

-- Load saved height limit or default
local function load_limit()
    local val = tonumber(storage:get_string("build_limit"))
    if val then
        core.log("action", "[height_limit] Loaded saved build limit: " .. val)
        return val
    end
    return cfg.build_limit
end

-- Save new limit
local function save_limit(limit)
    storage:set_string("build_limit", tostring(limit))
    core.log("action", "[height_limit] New build limit saved: " .. limit)
end

cfg.build_limit = load_limit()

local function is_mesecon(name)
    return name and string.find(name, "mesecon")
end

local function exceeds_limit(pos)
    if not pos or not pos.y then
        return false
    end
    return (pos.y + 1.0) > cfg.build_limit
end

local function send_mesecon_denied_message(player_name)
    local colors = {"yellow", "orange"}
    local msgs = {S("Nope!"), S("Nuh uh."), S("Not here!")}
    local color = colors[math.random(#colors)]
    local msg = msgs[math.random(#msgs)]
    core.chat_send_player(player_name, core.colorize(color, msg))
end

local function send_height_limit_message(player_name, limit)
    local msg = S("Sorry, but you cannot place higher than @1 blocks!", limit)
    core.chat_send_player(player_name, core.colorize("red", msg))
end

local function remove_above_limit(pos)
    if not pos or not pos.y then return end
    local start_y = cfg.build_limit + 1
    local end_y = math.floor(pos.y + cfg.mesecons_limit)
    for y = start_y, end_y do
        local cpos = {x = pos.x, y = y, z = pos.z}
        local node = core.get_node_or_nil(cpos)
        if node and node.name and node.name ~= "air" then
            core.remove_node(cpos)
        end
    end
end

-- Node placement event
core.register_on_placenode(function(pos, node, placer, pointed_thing, itemstack)
    if not placer or not pos then return end
    local name = placer:get_player_name()

    if cfg.deny_mesecons and is_mesecon(node.name) then
        if pos.y > (cfg.build_limit - (cfg.mesecons_limit - 1)) and pos.y < cfg.build_limit + 1 then
            core.remove_node(pos)
            send_mesecon_denied_message(name)
            return itemstack
        end
    end

    if exceeds_limit(pos) or (pointed_thing and pointed_thing.above and exceeds_limit(pointed_thing.above)) then
        send_height_limit_message(name, cfg.build_limit)
        core.remove_node(pos)
        return itemstack
    end
end)

-- Periodic cleanup
local timer = 0
core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < cfg.check_interval then return end
    timer = 0

    for _, player in ipairs(core.get_connected_players()) do
        local pos = vector.round(player:get_pos())
        if pos.y > (cfg.build_limit - cfg.mesecons_limit) then
            remove_above_limit(pos)
        end
    end
end)

-- Admin command
core.register_chatcommand("set_height_limit", {
    params = "<number>",
    description = S("Set a new height limit for building."),
    privs = {server = true},
    func = function(name, param)
        local limit = tonumber(param)
        if not limit then
            return false, S("Invalid value. Usage: /set_height_limit <number>")
        end
        cfg.build_limit = limit
        save_limit(limit)
        core.chat_send_all(S("Build limit updated to @1 by @2", limit, name))
        return true, S("New limit set to @1 blocks (saved permanently)", limit)
    end
})
