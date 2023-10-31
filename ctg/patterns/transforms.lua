require("simple")
require("lib/rand")

local tinsert = table.insert
local M = math.pow(2, 26)
-- Lua can represent integers exactly up to a bit more than M^2

function Zoom(pattern, factor)
    factor = factor or 16
    local pget = pattern.get

    local function get(x, y)
        return pget(x / factor, y / factor)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

function Tighten(pattern)
    assert(pattern.output == "bool")
    local pget = pattern.get

    local function get(x, y)
        return pget(x, y) and pget(x + 1, y) and pget(x, y + 1) and pget(x + 1, y + 1)
    end
    return {create = pattern.create, reload = pattern.reload, get = get, output = "bool"}
end

function FullTighten(pattern)
    assert(pattern.output == "bool")
    local pget = pattern.get

    local function get(x, y)
        return pget(x, y) and pget(x + 1, y) and pget(x - 1, y) and pget(x, y + 1) and pget(x, y - 1)
    end
    return {create = pattern.create, reload = pattern.reload, get = get, output = "bool"}
end

function Not(pattern)
    local pget = pattern.get
    local get

    if pattern.output == "bool" then
        get = function(x, y) return not pget(x, y) end
    elseif pattern.output == "height" then
        get = function(x, y) return -pget(x, y) end
    else
        assert(false)
    end

    return {create = pattern.create, reload = pattern.reload, get = get, output = pattern.output}
end

function If(pattern, yes, no)
    assert(pattern.output == 'bool')
    assert(yes.output == no.output)
    local pget = pattern.get
    local yget = yes.get
    local nget = no.get

    local function create()
        local data = {}
        data.pattern = pattern.create()
        data.yes = yes.create()
        data.no = no.create()
        return data
    end

    local function reload(data)
        pattern.reload(data.pattern)
        yes.reload(data.yes)
        no.reload(data.no)
    end

    local function get(x, y)
        if pget(x, y) then
            return yget(x, y)
        else
            return nget(x, y)
        end
    end

    return {create = create, reload = reload, get = get, output = yes.output}
end

-- Takes any number of patterns. Either all patterns must output "bool", or "float". If no patterns
-- are given, "bool" is assumed. For float, takes maximum.
function Or(...)
    local n = select('#', ...)
    local patterns = {...}
    if n == 0 then
        return False
    elseif n == 1 then
        return patterns[1]
    end
    local o = same_output(patterns)

    local function create()
        local d = {}
        for i, p in ipairs(patterns) do
            d[i] = p.create()
        end
        return d
    end

    local function reload(d)
        for i, p in ipairs(patterns) do
            p.reload(d[i])
        end
    end

    local get

    if o == "bool" then
        get = function(x, y)
            for _, p in ipairs(patterns) do
                if p.get(x, y) then
                    return true
                end
            end
            return false
        end
    elseif o == "height" then
        get = function(x, y)
            local m = -999999
            for _, p in ipairs(patterns) do
                m = math.max(m, p.get(x, y))
            end
            return m
        end
    else
        assert(false)
    end

    return {create = create, reload = reload, get = get, output = o}
end

-- See Union. For "float", takes the minimum.
function And(...)
    local n = select('#', ...)
    local patterns = {...}
    if n == 0 then
        return True
    elseif n == 1 then
        return patterns[1]
    end
    local o = same_output(patterns)

    local function create()
        local d = {}
        for i, p in ipairs(patterns) do
            d[i] = p.create()
        end
        return d
    end

    local function reload(d)
        for i, p in ipairs(patterns) do
            p.reload(d[i])
        end
    end

    local get

    if o == "bool" then
        get = function(x, y)
            for _, p in ipairs(patterns) do
                if not p.get(x, y) then
                    return false
                end
            end
            return true
        end
    elseif o == "height" then
        get = function(x, y)
            local m = 999999
            for _, p in ipairs(patterns) do
                m = math.min(m, p.get(x, y))
            end
            return m
        end
    else
        assert(false)
    end

    return {create = create, reload = reload, get = get, output = o}
end

Union = Or
Max = Or
Intersection = And
Min = And

function Sum(...)
    local n = select('#', ...)
    local patterns = {...}
    if n == 0 then
        return Zero()
    elseif n == 1 then
        return patterns[1]
    end
    local o = same_output(patterns)
    assert(o == 'height')

    local function create()
        local d = {}
        for i, p in ipairs(patterns) do
            d[i] = p.create()
        end
        return d
    end

    local function reload(d)
        for i, p in ipairs(patterns) do
            p.reload(d[i])
        end
    end

    local function get(x, y)
        local s = 0
        for _, p in ipairs(patterns) do
            s = s + p.get(x, y)
        end
        return s
    end

    return {create = create, reload = reload, get = get, output = 'height'}
end

function Product(...)
    local n = select('#', ...)
    local patterns = {...}
    if n == 0 then
        return One()
    elseif n == 1 then
        return patterns[1]
    end
    local o = same_output(patterns)
    assert(o == 'height')

    local function create()
        local d = {}
        for i, p in ipairs(patterns) do
            d[i] = p.create()
        end
        return d
    end

    local function reload(d)
        for i, p in ipairs(patterns) do
            p.reload(d[i])
        end
    end

    local function get(x, y)
        local a = 1
        for _, p in ipairs(patterns) do
            a = a * p.get(x, y)
        end
        return a
    end

    return {create = create, reload = reload, get = get, output = 'height'}
end

function Subtract(p1, p2)
    assert(p1.output == 'height')
    assert(p2.output == 'height')

    local function create()
        local d = {}
        d[1] = p1.create()
        d[2] = p2.create()
        return d
    end

    local function reload(d)
        p1.reload(d[1])
        p2.reload(d[2])
    end

    local p1get = p1.get
    local p2get = p2.get

    local function get(x, y)
        return p1get(x, y) - p2get(x, y)
    end

    return {create = create, reload = reload, get = get, output = 'height'}
end

function Clip(pattern, low, high)
    assert(pattern.output == 'height')
    local pget = pattern.get
    local get
    if low == nil then
        if high == nil then
            return pattern
        else
            get = function (x, y)
                return math.min(pget(x, y), high)
            end
        end
    else
        if high == nil then
            get = function (x, y)
                return math.max(pget(x, y), low)
            end
        else
            assert(low < high)
            get = function (x, y)
                return math.max(math.min(pget(x, y), high), low)
            end
        end
    end
    return {create = pattern.create, reload = pattern.reload, get = get, output = 'height'}
end

-- Shifts the given pattern by dx to the right and dy up
function Translate(pattern, dx, dy)
    local pget = pattern.get

    local function get(x, y)
        return pget(x - dx, y - dy)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

-- Given an angle in degrees, rotates anticlockwise by that much
function Rotate(pattern, angle)
    local pget = pattern.get
    local c = math.cos(angle * math.pi / 180)
    local s = math.sin(angle * math.pi / 180)

    local function get(x, y)
        return pget(c * x + s * y, -s * x + c * y)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

function Affine(pattern, a, b, c, d, dx, dy)
    local pget = pattern.get
    dx = dx or 0
    dy = dy or 0

    local function get(x, y)
        return pget(a * x + b * y + dx, c * x + d * y + dy)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

-- Tiles the plane with the contents of the given pattern from [xlow, xhigh) x [ylow, yhigh)
function Tile(pattern, xhigh, yhigh, xlow, ylow)
    local pget = pattern.get
    yhigh = yhigh or xhigh
    xlow = xlow or 0
    ylow = ylow or 0
    local dx = xhigh - xlow
    local dy = yhigh - ylow

    local function get(x, y)
        return pget(((x - xlow) % dx) + xlow, ((y - ylow) % dy) + ylow)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

function Tilex(pattern, xhigh, xlow)
    local pget = pattern.get
    xlow = xlow or 0
    local dx = xhigh - xlow

    local function get(x, y)
        return pget(((x - xlow) % dx) + xlow, y)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

function Tiley(pattern, yhigh, ylow)
    local pget = pattern.get
    ylow = ylow or 0
    local dy = yhigh - ylow

    local function get(x, y)
        return pget(x, ((y - ylow) % dy) + ylow)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

-- Similar to the z -> z^k function, repeats the given pattern k times by squeezing
-- k copies angularly around the origin.
-- If you can come up with a better name for this, let me know.
function AngularRepeat(pattern, k)
    local pget = pattern.get

    local function get(x, y)
        if x == 0 and y == 0 then
            return pget(0, 0)
        else
            -- This could be done without trig functions but this just seems easier
            local alpha = k * math.atan2(y, x)
            local r = math.sqrt(x * x + y * y)
            local x_ = r * math.cos(alpha)
            local y_ = r * math.sin(alpha)
            return pget(x_, y_)
        end
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, output = pattern.output}
end

-- Adds jitter to the boundaries of the given pattern; radius controls the size of the
-- jitter.
function Jitter(pattern, radius)
    local pget = pattern.get
    local r = radius or 10
    local data

    local function create()
        data = {}
        data.values = {}
        data.pattern = pattern.create()
        data.seed = rand_i()
        return data
    end

    local function reload(d)
        data = d
        pattern.reload(data.pattern)
    end

    local function compute(x, y)
        local dx = (rand_iiii2f(data.seed, x, y, 0) + rand_iiii2f(data.seed, x, y, 1) - 1) * (r / 2)
        local dy = (rand_iiii2f(data.seed, x, y, 2) + rand_iiii2f(data.seed, x, y, 3) - 1) * (r / 2)
        return pget(x + dx, y + dy)
    end

    local function geti(x, y)
        local key = (x * M) + y
        if data.values[key] == nil then
            data.values[key] = compute(x, y)
        end
        return data.values[key]
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    return {create = create, reload = reload, get = get, output = pattern.output}
end

-- Poor performance, don't use
function SmoothDiscrete(pattern, radius)
    local pget = pattern.get
    local r = radius or 3

    local dx = {}
    local dy = {}
    local total = 0
    for i = -r,r+1 do
        for j = -r,r+1 do
            if i * i + j * j <= r * r then
                table.insert(dx, i)
                table.insert(dy, j)
                total = total + 1
            end
        end
    end

    local data

    local function create()
        data = {}
        data.values = {}
        data.pattern = pattern.create()
        return data
    end

    local function reload(d)
        data = d
        pattern.reload(data.pattern)
    end

    local function compute(x, y)
        local count = 0
        for i = 1,total do
            if pget(x + dx[i], y + dy[i]) then
                count = count + 1
            end
        end
        return count * 2 > total
    end

    local function geti(x, y)
        local key = (x * M) + y
        if data.values[key] == nil then
            data.values[key] = compute(x, y)
        end
        return data.values[key]
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    return {create = create, reload = reload, get = get, output = "bool"}
end
