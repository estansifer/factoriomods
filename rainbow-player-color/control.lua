-- x is a number from 0 to 1
-- 0 = red -> yellow -> green -> cyan -> blue -> purple -> red = 1
local function get_color(x)
    local y = x * 6
    if y < 1 then
        return {r = 1, g = y}
    elseif y < 2 then
        return {r = 2 - y, g = 1}
    elseif y < 3 then
        return {g = 1, b = y - 2}
    elseif y < 4 then
        return {g = 4 - y, b = 1}
    elseif y < 5 then
        return {b = 1, r = y - 4}
    else
        return {b = 6 - y, r = 1}
    end
end

local function on_tick(event)
    if (event.tick % 10 == 0) then
        for pid, player in pairs(game.players) do

            local o = global.color_offsets[pid]
            if o == nil then
                o = math.random()
                global.color_offsets[pid] = o
            end

            local t = settings.get_player_settings(player)["rainbow-player-color-change-time"].value

            player.color = get_color((o + event.tick / (6 * 60 * t)) % 1)
        end
    end
end

local function on_init(event)
    global.color_offsets = {}
    script.on_event(defines.events.on_tick, on_tick)
end

local function on_load(event)
    script.on_event(defines.events.on_tick, on_tick)
end

script.on_init(on_init)
script.on_load(on_load)
