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
--      [optional] continuous is true/false, default is false
--
--  If continuous is true, then get returns a float where higher numbers means
--      more land-like. Typically the value is 0-centered with a range of [-1, 1] or
--      with a variance of about 1 or some such.
--  If continuous is false, then get returns a boolean, with 'true' meaning land
--      and 'false' meaning not land.
--  Except TerrainPattern returns either a tile name (as a string) or nil.
--

-- land_pattern returns "true" for land and "false" for water
-- void_pattern returns "true" for not-void and "false" for void
-- void overrides water
-- water_tile / void_tile are the internal names of the appropriate tiles
function TerrainPattern(land_pattern, void_pattern, water_tile, deepwater_tile, void_tile)
    -- This should never happen:
    if land_pattern == nil and void_pattern == nil then
        return nil
    end

    local pattern, lg, vg
    if land_pattern == nil then
        pattern = void_pattern
        vg = void_pattern.get
    elseif void_pattern == nil then
        pattern = land_pattern
        lg = land_pattern.get
    else
        lg = land_pattern.get
        vg = void_pattern.get
    end

    local function create()
        if pattern == nil then
            return {land_pattern.create(), void_pattern.create()}
        else
            return pattern.create()
        end
    end

    local function reload(d)
        if pattern == nil then
            land_pattern.reload(d[1])
            void_pattern.reload(d[2])
        else
            pattern.reload(d)
        end
    end

    local get

    if land_pattern == nil then
        get = function(x, y)
            if vg(x, y) then
                return nil
            else
                return void_tile
            end
        end
    elseif void_pattern == nil then
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

    return {
        create = create,
        reload = reload,
        get = get
    }
end
