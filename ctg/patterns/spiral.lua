require('simple')

-- 'ratio' is the ratio of the distance of consecutive spirals from the center
-- 'land' is the proportion of terrain that is land
-- Use the reciprocal of some ratio to make the spiral go the other way
function Spiral(ratio, land, minradius)
    ratio = ratio or 1.4
    land = land or 0.5
    minradius = minradius or 3
    local minn = minradius * minradius
    local lr = math.log(ratio)

    local function get(x, y)
        local n = (x * x) + (y * y)
        if n < minn then
            return true
        else
            -- Very irritatingly Lua makes a backwards incompatible
            -- change in arctan between 5.2 and 5.3 that makes it impossible
            -- to write code that is correct in both versions. We are using
            -- 5.2 here.
            return (((math.atan2(y, x) / math.pi) + (math.log(n) / lr)) % 2) < (land * 2)
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- 'ratio' is the ratio of the distance of consecutive circles from the center
-- 'land' is the proportion of terrain that is land
function ConcentricCircles(ratio, land)
    ratio = ratio or 1.4
    land = land or 0.5
    minradius = minradius or 3
    local minn = minradius * minradius
    local lr2 = 2 * math.log(ratio)
    local function get(x, y)
        local n = (x * x) + (y * y)
        if n < minn then
            return true
        else
            return ((math.log(n) / lr2) % 1) < land
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- 'dist' is the distance between consecutive spirals
-- 'land' is the proportion of terrain that is land
function ArithmeticSpiral(dist, land)
    dist = dist or 40
    land = land or 0.5
    local function get(x, y)
        local r = math.sqrt((x * x) + (y * y))
        if r < dist then
            return true
        else
            return (((math.atan2(y, x) / (2 * math.pi)) + (r / dist)) % 1) < land
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- 'dist' is the distance between consecutive circles
-- 'land' is the proportion of terrain that is land
function ArithmeticConcentricCircles(dist, land)
    dist = dist or 40
    land = land or 0.5
    local function get(x, y)
        local r = math.sqrt((x * x) + (y * y))
        return ((r / dist) % 1) < land
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function RectSpiral()
    local function get(x, y)
        if math.abs(x) > math.abs(y) or (x + y >= 0 and y < x + 2) then
            return ((x + 0.5) % 2) < 1
        else
            return ((y + 0.5) % 2) < 1
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end
