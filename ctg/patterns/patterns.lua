require("simple")
require("transforms")
require('spiral')
require("maze1")
require("maze2")
require("maze3")
require("mandelbrot")
require("jigsawislands")
require("barcode")
require("distort")
require("islandify")
require("fractal")
require('hilbert')
require('sierpinski')
require('image')
require("noise")
require("lib/normal")

--
--  A pattern is a dictionary:
--      create() returns a serializable object that contains all data needed to
--          restore the pattern exactly as it is
--      reload(d) takes the serialized object and restores the pattern
--      get(x, y) takes floating point position (x, y) and returns the value of
--          the pattern at that location
--      output is "height", "bool", "tile"
--      [optional] input is "integer", "real"
--      [optional] geti(x, y) takes integer position (x, y) and returns the value of
--          the pattern at that location
--
--  If output is "tile", return a string that is the name of a tile, or nil to mean
--      no change from original tile type
--  If output is "bool", return true for land and false for not land
--  If output is "height", return higher values for more land-like

-- land_pattern returns "true" for land and "false" for water
-- void_pattern returns "true" for void and "false" for not void
-- void overrides land/water
function TP(land_pattern, void_pattern)
    -- Water tiles are: water, water-green, deepwater, deepwater-green
    local water_tile = 'water'
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

    if void_pattern == nil then
        if land_pattern == nil then
            get = function(x, y)
                return nil
            end
        else
            get = function(x, y)
                if lg(x, y) then
                    return nil
                else
                    return water_tile
                end
            end
        end
    else
        if land_pattern == nil then
            get = function(x, y)
                if vg(x, y) then
                    return void_tile
                else
                    return nil
                end
            end
        else
            get = function(x, y)
                if vg(x, y) then
                    return void_tile
                else
                    if lg(x, y) then
                        return nil
                    else
                        return water_tile
                    end
                end
            end
        end
    end

    local get_chunk

    if void_pattern == nil then
        if land_pattern == nil then
            get_chunk = function(x1, y1, x2, y2)
                return {}
            end
        else
            get_chunk = function(x1, y1, x2, y2)
                local tiles = {}
                for x = x1, x2 do
                    for y = y1, y2 do
                        if not lg(x, y) then
                            table.insert(tiles, {name = water_tile, position = {x, y}})
                        end
                    end
                end
                return tiles
            end
        end
    else
        if land_pattern == nil then
            get_chunk = function(x1, y1, x2, y2)
                local tiles = {}
                for x = x1, x2 do
                    for y = y1, y2 do
                        if vg(x, y) then
                            table.insert(tiles, {name = void_tile, position = {x, y}})
                        end
                    end
                end
                return tiles
            end
        else
            get_chunk = function(x1, y1, x2, y2)
                local tiles = {}
                for x = x1, x2 do
                    for y = y1, y2 do
                        if vg(x, y) then
                            table.insert(tiles, {name = void_tile, position = {x, y}})
                        elseif not lg(x, y) then
                            table.insert(tiles, {name = water_tile, position = {x, y}})
                        end
                    end
                end
                return tiles
            end
        end
    end

    return {
        create = create,
        reload = reload,
        get = get,
        get_chunk = get_chunk,
        output = "tile"
    }
end

-- Required opts.pattern
-- opts.heights or opts.areas
-- opts.mean, opts.stddev
function HF(opts)
    opts = opts or {}
    if opts.pattern == nil and opts.get ~= nil then
        local p = opts
        opts = {pattern = p}
    end
    assert(opts.pattern ~= nil, "Required argument 'pattern' for HF")
    assert(opts.pattern.output == "height", "pattern must be a height field")

    if opts.heights == nil then
        opts.areas = opts.areas or {Water(), 0.5, Land()}
        opts.mean = opts.mean or 0
        opts.stddev = opts.stddev or 1
        assert(opts.stddev > 0, "Standard deviation must be positive")

        opts.heights = {}
        local flag = false
        local last_area = -1
        for i, value in ipairs(opts.areas) do
            if flag then
                assert(0 < value, "Areas need to be positive")
                assert(value < 1, "Areas need to be less than 1")
                assert(last_area < value, "Areas need to be increasing")
                last_area = value
                table.insert(opts.heights, opts.mean + opts.stddev * normal_invcdf(value))
            else
                table.insert(opts.heights, value)
            end
            flag = not flag
        end
        assert(flag, "areas should have odd length")
    else
        assert(opts.areas == nil, "Don't supply both 'heights' and 'areas'")
    end

    if #opts.heights == 1 then
        return opts.heights[1]
    end
    assert(#opts.heights > 2, "heights should have an odd length")

    local choices = {}
    local levels = {}
    local flag = false
    local last_height = opts.heights[2] - 1
    for i, value in ipairs(opts.heights) do
        if flag then
            assert(value > last_height, "Heights need to be increasing")
            last_height = value
            table.insert(levels, value)
        else
            table.insert(choices, value)
        end
        flag = not flag
    end
    assert(flag, "heights should have odd length")

    local function create()
        local d = {}
        d[1] = opts.pattern.create()
        d[2] = {}
        for i, choice in ipairs(choices) do
            d[2][i] = choice.create()
        end
        return d
    end
    
    local function reload(d)
        opts.pattern.reload(d[1])
        for i, choice in ipairs(choices) do
            choice.reload(d[2][i])
        end
    end

    local pget = opts.pattern.get
    local function get(x, y)
        local height = pget(x, y)
        for i, value in ipairs(levels) do
            if height <= value then
                return choices[i].get(x, y)
            end
        end
        return choices[#choices].get(x, y)
    end

    return {create = create, reload = reload, get = get, output = same_output(choices)}
end
