local function noop()
    return nil
end

function AllLand()
    local function get(x, y)
        return true
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function NoLand()
    local function get(x, y)
        return false
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Square(radius)
    local r = radius or 32
    local function get(x, y)
        return x >= -r and y >= -r and x < r and y < r
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- Includes (x1, y1) and excludes (x1, y2)
function Rectangle(x1, y1, x2, y2)
    local function get(x, y)
        return (x >= x1) and (x < x2) and (y >= y1) and (y < y2)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Circle(radius, centerx, centery)
    local r = radius or 32
    local r2 = r * r
    local cx = centerx or 0
    local cy = centery or 0
    local function get(x, y)
        return ((x - cx) * (x - cx)) + ((y - cy) * (y - cy)) < r2
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Halfplane()
    local function get(x, y)
        return (x >= 0)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Quarterplane()
    local function get(x, y)
        return (x >= 0) and (y >= 0)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Strip(width)
    local n = width or 1
    local function get(x, y)
        return (math.abs(y) * 2) < n
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Cross(width)
    local n = width or 1
    local function get(x, y)
        return (math.abs(x) * 2 < n) or (math.abs(y) * 2 < n)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Comb()
    local function get(x, y)
        if x < -1 then
            return false
        else
            return (x < 2) or ((y % 2) < 1)
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Grid()
    local function get(x, y)
        return ((x % 2) < 1) or ((y % 2) < 1)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function Checkerboard()
    local function get(x, y)
        return ((x % 2) < 1) == ((y % 2) < 1)
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- 'ratio' is the ratio of the distance of consecutive spirals from the center
-- 'land' is the proportion of terrain that is land
-- Use the reciprocal of some ratio to make the spiral go the other way
function Spiral(ratio, land)
    local r = ratio or 1.4
    local l = land or 0.5
    local lr = math.log(r)
    local function get(x, y)
        local n = (x * x) + (y * y)
        if n < 10 then
            return true
        else
            -- Very irritatingly Lua makes a backwards incompatible
            -- change in arctan between 5.2 and 5.3 that makes it impossible
            -- to write code that is correct in both versions. We are using
            -- 5.2 here.
            return (((math.atan2(y, x) / math.pi) + (math.log(n) / lr)) % 2) < (l * 2)
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- 'ratio' is the ratio of the distance of consecutive circles from the center
-- 'land' is the proportion of terrain that is land
function ConcentricCircles(ratio, land)
    local r = ratio or 1.4
    local l = land or 0.5
    local lr2 = 2 * math.log(r)
    local function get(x, y)
        local n = (x * x) + (y * y)
        if n < 10 then
            return true
        else
            return ((math.log(n) / lr2) % 1) < l
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- 'dist' is the distance between consecutive spirals
-- 'land' is the proportion of terrain that is land
function ArithmeticSpiral(dist, land)
    local d = dist or 40
    local l = land or 0.5
    local function get(x, y)
        local r = math.sqrt((x * x) + (y * y))
        if r < d then
            return true
        else
            return (((math.atan2(y, x) / (2 * math.pi)) + (r / d)) % 1) < l
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

-- 'dist' is the distance between consecutive circles
-- 'land' is the proportion of terrain that is land
function ArithmeticConcentricCircles(dist, land)
    local d = dist or 40
    local l = land or 0.5
    local function get(x, y)
        local r = math.sqrt((x * x) + (y * y))
        return ((r / d) % 1) < l
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end

function RectSpiral()
    local function get(x, y)
        if math.abs(x) > math.abs(y) or (x + y > 0 and y < x + 2) then
            return ((x + 0.5) % 2) < 1
        else
            return ((y + 0.5) % 2) < 1
        end
    end
    return {create = noop, reload = noop, get = get, output = "bool"}
end
