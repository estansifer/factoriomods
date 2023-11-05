local function near_origin(x, y)
    return math.abs(x) + math.abs(y) <= 70
end

function register_chunk_callback(pattern)
    assert(global.enabled)
    assert(pattern.output == 'tile')
    local get = pattern.get
    local get_chunk = pattern.get_chunk
    local vectorize = (get_chunk ~= nil)
    local callback
    local insert = table.insert
    local force_initial_water = global.settings['force-initial-water']

    -- Check for 'nauvis' per EldVarg, for Factorissimo compatibility

    if vectorize then
        callback = function(event)
            local surface = event.surface
            if surface.name ~= "nauvis" then
                return
            end
            local x1 = event.area.left_top.x
            local y1 = event.area.left_top.y
            local x2 = event.area.right_bottom.x
            local y2 = event.area.right_bottom.y

            local tiles

            if near_origin(x1, y1) then
                tiles = {}
                for x = x1, x2 do
                    for y = y1, y2 do
                        if force_initial_water and ((x - 7) * (x - 7) + y * y < 10) then
                            insert(tiles, {name = 'water', position = {x, y}})
                        elseif (x * x + y * y > 5) then
                            local new = get(x, y)
                            if new ~= nil then
                                insert(tiles, {name = new, position = {x, y}})
                            end
                        end
                    end
                end
            else
                tiles = get_chunk(x1, y1, x2, y2)
            end

            surface.set_tiles(tiles)
        end
    else
        callback = function(event)
            local surface = event.surface
            if surface.name ~= "nauvis" then
                return
            end
            local x1 = event.area.left_top.x
            local y1 = event.area.left_top.y
            local x2 = event.area.right_bottom.x
            local y2 = event.area.right_bottom.y

            local tiles = {}

            if near_origin(x1, y1) then
                for x = x1, x2 do
                    for y = y1, y2 do
                        if force_initial_water and ((x - 7) * (x - 7) + y * y < 10) then
                            insert(tiles, {name = 'water', position = {x, y}})
                        elseif (x * x + y * y > 5) then
                            local new = get(x, y)
                            if new ~= nil then
                                insert(tiles, {name = new, position = {x, y}})
                            end
                        end
                    end
                end
            else
                for x = x1, x2 do
                    for y = y1, y2 do
                        local new = get(x, y)
                        if new ~= nil then
                            insert(tiles, {name = new, position = {x, y}})
                        end
                    end
                end
            end

            surface.set_tiles(tiles)
        end
    end

    script.on_event(defines.events.on_chunk_generated, callback)
end
