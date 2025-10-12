local modname = core.get_current_modname()

height_limit = {
    limit = core.settings:get(modname) or 310,
    mesecons_limit = core.settings:get(modname .. "_mesecons_close") or 20,
    deny_mesecons = core.settings:get_bool(modname .. "_mesecons", true)
}

local S = core.get_translator(modname)

core.register_on_placenode(function(pp, node, p, _, item)
    local name = p:get_player_name()
    local limit = height_limit.limit
    local lmt = limit + 1

    if string.find(node.name, "mesecon") and height_limit.deny_mesecons then
        if (pp.y > (limit - (height_limit.mesecons_limit - 1))) and (pp.y < lmt) then
            core.remove_node(pp)
            local color = math.random(1, 2) == 2 and "orange" or "yellow"
            local msg = math.random(1, 2) == 2 and "Nope!" or "Nuh Uh."
            core.chat_send_player(name, core.colorize(color, S(msg)))
            return item
        end
    end

    if pp.y < lmt then
        return
    end

    core.chat_send_player(name, core.colorize("red", S("Sorry, but you cannot place higher than @1 blocks!", limit)))
    return item
end)

local function remove(pos, size)
    local x1, x2 = pos.x - size, pos.x + size
    local y1, y2 = height_limit.limit + 1, height_limit.limit + 1 + size
    local z1, z2 = pos.z - size, pos.z + size

    for x = x1, x2 do
        for y = y1, y2 do
            for z = z1, z2 do
                local cpos = {x = x, y = y, z = z}
                core.remove_node(cpos)
            end
        end
    end
end

core.register_globalstep(function()
    for _, player in pairs(core.get_connected_players()) do
        local pos = player:get_pos()
        local limit = height_limit.limit
        local lmt = limit + 1

        if pos.y > (limit - (height_limit.mesecons_limit - 1)) then
            remove(pos, height_limit.mesecons_limit)
        end
    end
end)
