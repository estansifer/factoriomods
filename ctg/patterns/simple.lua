function noop()
    return nil
end

function same_output(patterns)
    o = patterns[1].output
    for i, pattern in ipairs(patterns) do
        assert(pattern.output == o, "Each pattern must have the same output type.")
    end
    return o
end

local function constant_(v, o)
    local function get(x, y)
        return v
    end
    return (function() return {create = noop, reload = noop, get = get, output = o} end)
end

True = constant_(true, "bool")
False = constant_(false, "bool")
Default = constant_(nil, 'tile')
Land = constant_(nil, "tile")
ShallowishWater = constant_('water-mud', 'tile') -- walking speed 70%
ShallowWater = constant_('water-shallow', 'tile') -- walking speed 80%
Water = constant_('water', "tile")
DeepWater = constant_('deepwater', "tile")
WaterGreen = constant_('water-green', "tile")
DeepWaterGreen = constant_('deepwater-green', "tile")
Void = constant_('out-of-map', "tile")
-- See https://wiki.factorio.com/Data.raw#tile for full list
One = constant_(1, "height")
Zero = constant_(0, "height")

function Constant(v, o)
    if o == nil then
        if type(v) == 'boolean' then
            o = 'bool'
        elseif type(v) == 'number' then
            o = 'height'
        elseif type(v) == 'string' then
            o = 'tile'
        elseif v == nil then
            o = 'tile'
        else
            assert(false)
        end
    end

    local function get(x, y)
        return v
    end
    return {create = noop, reload = noop, get = get, output = o}
end


function LuaExpr(expr, o, multiline)
    o = o or "height"
    if multiline then
        get_code = "return (function (x, y) " .. expr .. " end)"
    else
        get_code = "return (function (x, y) return (" .. expr .. ") end)"
    end
    local get = assert(load(get_code))()
    get(0, 0) -- Test that the user code works

    return {create = noop, reload = noop, get = get, output = o}
end

function NoiseLayer(layer, surface_name)
    layer = layer or 'elevation'
    surface_name = surface_name or 'nauvis'
    local layers = {layer}
    local surface = game.surfaces[surface_name]
    local function get(x, y)
        return surface.calculate_tile_properties(layers,{x, y})[layer][1]
    end
    return {create = noop, reload = noop, get = get, output = 'height'}
end

function Elevation(surface_name)
    return NoiseLayer('elevation', surface_name)
end

function Square(radius)
    local function get(x, y)
        return x >= 0 and y >= 0 and x < radius and y < radius
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- Includes (x1, y1) and excludes (x2, y2)
function Rectangle(x1, y1, x2, y2)
    local function get(x, y)
        return (x >= x1) and (x < x2) and (y >= y1) and (y < y2)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Circle(radius, centerx, centery)
    local r2 = radius * radius
    local cx = centerx or 0
    local cy = centery or 0
    local function get(x, y)
        return ((x - cx) * (x - cx)) + ((y - cy) * (y - cy)) < r2
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Halfplane(angle)
    angle = angle or "+x"
    local get
    if angle == "+x" or angle == "0" or angle == 0 then
        get = function(x, y) return (x >= 0) end
    elseif angle == "+y" or angle == "90" or angle == 90 then
        get = function(x, y) return (y >= 0) end
    elseif angle == "-x" or angle == "180" or angle == 180 then
        get = function(x, y) return (x <= 0) end
    elseif angle == "-y" or angle == "270" or angle == 270 then
        get = function(x, y) return (y <= 0) end
    else
        local x0 = math.cos(math.pi * angle / 180)
        local y0 = math.sin(math.pi * angle / 180)
        get = function(x, y)
            return ((x * x0) + (y * y0) >= 0)
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Quarterplane(angle)
    angle = angle or "+x"
    local get
    if angle == "+x" or angle == "0" or angle == 0 then
        get = function(x, y) return (x >= 0) and (y >= 0) end
    elseif angle == "+y" or angle == "90" or angle == 90 then
        get = function(x, y) return (x <= 0) and (y >= 0) end
    elseif angle == "-x" or angle == "180" or angle == 180 then
        get = function(x, y) return (x <= 0) and (y <= 0) end
    elseif angle == "-y" or angle == "270" or angle == 270 then
        get = function(x, y) return (x >= 0) and (y <= 0) end
    else
        local x0 = math.cos(math.pi * angle / 180)
        local y0 = math.sin(math.pi * angle / 180)
        get = function(x, y)
            return ((x * x0) + (y * y0) >= 0) and ((y * x0) - (x * y0) >= 0)
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Strip(width, y0)
    width = width or 1
    local h = width / 2
    if y0 == nil then
        y0 = -0.25
    end
    local function get(x, y)
        return math.abs(y - y0) < h
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Cross(width, x0, y0)
    width = width or 1
    local h = width / 2
    if x0 == nil then
        x0 = -0.25
    end
    if y0 == nil then
        y0 = -0.25
    end
    local function get(x, y)
        return (math.abs(x - x0) < h) or (math.abs(y - y0) < h)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Comb()
    local function get(x, y)
        return (x >= -1) and ((x < 1) or (((y + 0.5) % 2) < 1))
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Grid()
    local function get(x, y)
        return (((x + 0.5) % 2) < 1) or (((y + 0.5) % 2) < 1)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Checkerboard()
    local function get(x, y)
        return (((x + 0.5) % 2) < 1) == (((y + 0.5) % 2) < 1)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- power can be 'infinity' or any nonnegative number
-- normalize == true if you want output to be same units as x, y
function LNorm(power, radius, x0, y0, normalize, c)
    if power == nil then
        power = 2
    end
    radius = radius or 1
    local invr = 1 / radius
    x0 = x0 or 0
    y0 = y0 or 0
    if normalize == nil then
        normalize = true
    end
    c = c or 1

    local get

    if power == 0 then
        get = function(x, y)
            return c * (math.abs((x - x0) * invr) + math.abs((y - y0) * invr))
        end
    elseif power == 'infinity' then
        get = function(x, y)
            return c * math.max(math.abs((x - x0) * invr), math.abs((y - y0) * invr))
        end
    elseif (power % 2) == 0 then
        if normalize then
            local inv_power = 1 / power
            get = function (x, y)
                local dx = (x - x0) * invr
                local dy = (y - y0) * invr
                return c * (((dx ^ power) + (dy ^ power)) ^ inv_power)
            end
        else
            get = function (x, y)
                local dx = (x - x0) * invr
                local dy = (y - y0) * invr
                return c * ((dx ^ power) + (dy ^ power))
            end
        end
    else
        if normalize then
            local inv_power = 1 / power
            get = function (x, y)
                local dx = math.abs((x - x0) * invr)
                local dy = math.abs((y - y0) * invr)
                return c * (((dx ^ power) + (dy ^ power)) ^ inv_power)
            end
        else
            get = function (x, y)
                local dx = math.abs((x - x0) * invr)
                local dy = math.abs((y - y0) * invr)
                return c * ((dx ^ power) + (dy ^ power))
            end
        end
    end

    return {create = noop, reload = noop, get = get, output = 'height'}
end

-- slope should be equal to the std dev of desired cut off radius
-- divided by std dev of the height field being cut off
function CircularCutoff(radius, slope)
    local function get(x, y)
        local r = math.sqrt(x * x + y * y)
        return math.min(0, (radius - r) / slope)
    end
    return {create = noop, reload = noop, get = get, output = 'height'}
end

function Moat(r1, r2, depth)
    assert(5 < r1)
    assert(r1 < r2)
    depth = depth or 0.5
    local rmid = (r1 + r2) / 2
    local slope = 2 * depth / (r2 - r1)
    local function get(x, y)
        local r = math.sqrt(x * x + y * y)
        if (r1 < r) and (r < r2) then
            return math.abs(r - rmid) * slope - depth
        end
    end
    return {create = noop, reload = noop, get = get, output = 'height'}
end
