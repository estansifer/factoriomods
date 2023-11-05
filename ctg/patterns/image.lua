-- require("worldmap")
require("simple")
require("transforms")
local world_map_pixels = require('worldmap')

function Image(pixels, width, height)
    local lookup = {}
    lookup[string.byte('a')] = {false, false, false, false}
    lookup[string.byte('b')] = {false, false, false, true}
    lookup[string.byte('c')] = {false, false, true, false}
    lookup[string.byte('d')] = {false, false, true, true}
    lookup[string.byte('e')] = {false, true, false, false}
    lookup[string.byte('f')] = {false, true, false, true}
    lookup[string.byte('g')] = {false, true, true, false}
    lookup[string.byte('h')] = {false, true, true, true}
    lookup[string.byte('i')] = {true, false, false, false}
    lookup[string.byte('j')] = {true, false, false, true}
    lookup[string.byte('k')] = {true, false, true, false}
    lookup[string.byte('l')] = {true, false, true, true}
    lookup[string.byte('m')] = {true, true, false, false}
    lookup[string.byte('n')] = {true, true, false, true}
    lookup[string.byte('o')] = {true, true, true, false}
    lookup[string.byte('p')] = {true, true, true, true}

    assert((4 * #pixels) >= (width * height))

    local function geti(x, y)
        if (x >= 0) and (x < width) and (y >= 0) and (y < height) then
            local i = x + y * width
            return lookup[string.byte(pixels, math.floor(i / 4) + 1)][(i % 4) + 1]
        end
        return false
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    return {create = noop, reload = noop, get = get, output = 'bool'}
end

function WorldMap()
    local width = 2328
    local height = 1420
    return Image(world_map_pixels, width, height)
end
