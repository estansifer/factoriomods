require("simple")

local function noop()
    return nil
end

local tinsert = table.insert
local M = math.pow(2, 26)
-- Lua can represent integers exactly up to a bit more than M^2

function Zoom(pattern, f)
    local factor = f or 16
    local pget = pattern.get

    local function get(x, y)
        return pget(x / factor, y / factor)
    end

    return {create = pattern.create, reload = pattern.reload,
        continuous = pattern.continuous, get = get}
end

function Tighten(pattern)
    local pget = pattern.get

    local function get(x, y)
        return pget(x, y) and pget(x + 1, y) and pget(x, y + 1) and pget(x + 1, y + 1)
    end
    return {create = pattern.create, reload = pattern.reload, get = get}
end

function FullTighten(pattern)
    local pget = pattern.get

    local function get(x, y)
        return pget(x, y) and pget(x + 1, y) and pget(x - 1, y) and pget(x, y + 1) and pget(x, y - 1)
    end
    return {create = pattern.create, reload = pattern.reload, get = get}
end

-- Accepts continuous or discrete pattern
function Not(pattern)
    local pget = pattern.get

    if pattern.continuous then
        local function get(x, y)
            return not pget(x, y)
        end
        return {create = pattern.create, reload = pattern.reload, get = get}
    else
        local function get(x, y)
            return -pget(x, y)
        end
        return {create = pattern.create, reload = pattern.reload, get = get, continuous = true}
    end
end

-- Takes any number of patterns. They must be discrete.
function Union(...)
    local n = select('#', ...)
    local patterns = {...}
    if n == 0 then
        return NoLand()
    elseif n == 1 then
        return patterns[1]
    end

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
        for _, p in ipairs(patterns) do
            if p.get(x, y) then
                return true
            end
        end
        return false
    end

    return {create = create, reload = reload, get = get}
end

-- Takes any number of patterns. They must be discrete.
function Intersection(...)
    local n = select('#', ...)
    local patterns = {...}
    if n == 0 then
        return AllLand()
    elseif n == 1 then
        return patterns[1]
    end

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
        for _, p in ipairs(patterns) do
            if not p.get(x, y) then
                return false
            end
        end
        return true
    end

    return {create = create, reload = reload, get = get}
end

-- Takes any number of patterns. They must be continuous.
function Max(...)
    local n = select('#', ...)
    local patterns = {...}
    if n == 0 then
        local function get(x, y)
            return -1
        end
        return {create = noop, reload = noop, get = get, continuous = true}
    elseif n == 1 then
        return patterns[1]
    end

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
        local m = -999999
        for _, p in ipairs(patterns) do
            m = math.max(m, p.get(x, y))
        end
        return m
    end

    return {create = create, reload = reload, get = get, continuous = true}
end


-- Shifts the given pattern by dx to the right and dy up
function Translate(pattern, dx, dy)
    local pget = pattern.get

    local function get(x, y)
        return pget(x - dx, y - dy)
    end

    return {create = pattern.create, reload = pattern.reload,
        continuous = pattern.continuous, get = get}
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
        get = get, continuous = pattern.continuous}
end

function Affine(pattern, a, b, c, d, dx, dy)
    local pget = pattern.get
    local dx_ = dx or 0
    local dy_ = dy or 0

    local function get(x, y)
        return pget(a * x + b * y + dx_, c * x + d * y + dy_)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, continuous = pattern.continuous}
end

-- Tiles the plane with the contents of the given pattern from [xlow, xhigh) x [ylow, yhigh)
function Tile(pattern, xhigh, yhigh, xlow, ylow)
    local pget = pattern.get
    local xl = xlow or 0
    local yl = ylow or 0
    local dx = xhigh - xl
    local dy = yhigh - yl

    local function get(x, y)
        return pget(((x - xl) % dx) + xl, ((y - yl) % dy) + yl)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, continuous = pattern.continuous}
end

function Tilex(pattern, xhigh, xlow)
    local pget = pattern.get
    local xl = xlow or 0
    local dx = xhigh - xl

    local function get(x, y)
        return pget(((x - xl) % dx) + xl, y)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, continuous = pattern.continuous}
end

function Tiley(pattern, yhigh, ylow)
    local pget = pattern.get
    local yl = ylow or 0
    local dy = yhigh - yl

    local function get(x, y)
        return pget(x, ((y - yl) % dy) + yl)
    end

    return {create = pattern.create, reload = pattern.reload,
        get = get, continuous = pattern.continuous}
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
        get = get, continuous = pattern.continuous}
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
        return data
    end

    local function reload(d)
        data = d
        pattern.reload(data.pattern)
    end

    local function compute(x, y)
        local dx = (math.random() + math.random() - 1) * (r / 2)
        local dy = (math.random() + math.random() - 1) * (r / 2)
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

    return {create = create, reload = reload, get = get, continuous = pattern.continuous}
end

-- Poor performance, don't use
-- pattern should not be continuous
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

    return {create = create, reload = reload, get = get}
end
