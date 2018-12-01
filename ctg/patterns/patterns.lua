require("maze1")
require("maze2")
require("maze3")
require("mandelbrot")
require("jigsawislands")
require("barcode")
require("distort")
require("simple")
require("transforms")
require("islandify")
require("fractal")
require("noise")

--
--  A pattern is a dictionary:
--      create() returns a serializable object that contains all data needed to
--          restore the pattern exactly as it is
--      reload(d) takes the serialized object and restores the pattern
--      get(x, y) takes floating point position (x, y) and returns the value of
--          the pattern at that location
--      [optional] geti(x, y) takes integer position (x, y) and returns the value of
--          the pattern at that location
--      [optional] output is "tilename", "tileid", "bool", or "float"
--
--  If output is "tilename", return a string that is the name of a tile, or nil to mean
--      no change from original tile type
--  If output is "tileid", return an integer:
--      1           land
--      0           water
--      -1          deepwater
--      -2          void
--  If output is bool, return true for land and false for not land
--  If output is float, return higher values for more land-like
--

-- pattern.output must be "tileid"
function TileID2Name(pattern, water_color)
    local color = water_color or global.settings['water-color']
    local water_tile, deep_water_tile
    if color == 'blue' then
        water_tile = 'water'
        deep_water_tile = 'deepwater'
    else
        water_tile = 'water-green'
        deep_water_tile = 'deepwater-green'
    end
    local void_tile = 'out-of-map'

    local pget = pattern.get
    local lookup = {}
    lookup[1] = nil
    lookup[0] = water_tile
    lookup[-1] = deep_water_tile
    lookup[-2] = void_tile

    local function get(x, y)
        return lookup[pget(x, y)]
    end

    return {
        create = pattern.create,
        reload = pattern.reload,
        get = get,
        output = "tilename"
    }
end

-- land_pattern returns "true" for land and "false" for water
-- void_pattern returns "true" for land and "false" for void
-- void overrides water
-- water_color should be "blue", "green", or nil. If nil, the value from mod setting
-- is used for the water color
function TP(land_pattern, void_pattern, water_color)
    local color = water_color or global.settings['water-color']
    local water_tile
    if color == 'blue' then
        water_tile = 'water'
    else
        water_tile = 'water-green'
    end
    local void_tile = 'out-of-map'

    local function create()
        local d = {}
        if land_pattern ~= nil then
            d[1] = land_pattern.create()
        end
        if void_pattern ~= nil then
            d[2] = void_pattern.create()
        end
        return d
    end

    local function reload(d)
        if land_pattern ~= nil then
            land_pattern.reload(d[1])
        end
        if void_pattern ~= nil then
            void_pattern.reload(d[2])
        end
    end

    local lg, vg, get

    if land_pattern ~= nil then
        lg = land_pattern.get
    end
    if void_pattern ~= nil then
        vg = void_pattern.get
    end

    if land_pattern == nil then
        if void_pattern == nil then
            get = function(x, y)
                return nil
            end
        else
            get = function(x, y)
                if vg(x, y) then
                    return nil
                else
                    return void_tile
                end
            end
        end
    else
        if void_pattern == nil then
            get = function(x, y)
                if lg(x, y) then
                    return nil
                else
                    return water_tile
                end
            end
        else
            get = function(x, y)
                if vg(x, y) then
                    if lg(x, y) then
                        return nil
                    else
                        return water_tile
                    end
                else
                    return void_tile
                end
            end
        end
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "tilename"
    }
end
