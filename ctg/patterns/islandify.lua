require("simple")
require("transforms")

-- Given a pattern p1, each square in p1 is replaced by a region of size sizex x sizey
--      If the square is water in p1, the whole new region is water
--      If the square is land in p1, the whole new region is taken from pattern p2

function KroneckerProduct(p1, p2, sizex, sizey)
    local p1get = p1.get
    local p2get = p2.get
    sizey = sizey or sizex

    local function create()
        return {p1.create(), p2.create()}
    end

    local function reload(d)
        p1.reload(d[1])
        p2.reload(d[2])
    end

    local function get(x, y)
        local x1 = math.floor(x / sizex)
        local y1 = math.floor(y / sizey)
        local x2 = x - x1 * sizex
        local y2 = y - y1 * sizey
        if p1get(x1, y1) then
            return p2get(x2, y2)
        else
            return false
        end
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "bool"
    }
end

-- Same, but now we add a gap of size bridgelength between each region. This gap is
-- filled with a bridge of the indicated width when two adjacent cells both have land.
function Islandify(p1, p2, sizex, sizey, bridgelength, bridgewidth)
    assert(p1.output == 'bool')
    assert(p2.output == 'bool')
    local p1get = p1.get
    local p2get = p2.get
    sizey = sizey or sizex
    local l = bridgelength or 48
    local w = bridgewidth or 2

    local function create()
        return {p1.create(), p2.create()}
    end

    local function reload(d)
        p1.reload(d[1])
        p2.reload(d[2])
    end

    local function get(x, y)
        local x1 = math.floor(x / (sizex + l))
        local y1 = math.floor(y / (sizey + l))
        local x2 = x - x1 * (sizex + l)
        local y2 = y - y1 * (sizey + l)
        if p1get(x1, y1) then
            if (x2 < sizex) and (y2 < sizey) and p2get(x2, y2) then
                return true
            else
                -- What a mess!
                if math.abs(y2 - (sizey / 2) + 0.25) * 2 < w then
                    if x2 > (sizex / 2) then
                        return p1get(x1 + 1, y1)
                    else
                        assert(false)
                        return p1get(x1 - 1, y1)
                    end
                end

                if math.abs(x2 - (sizex / 2) + 0.25) * 2 < w then
                    if y2 > (sizey / 2) then
                        return p1get(x1, y1 + 1)
                    else
                        assert(false)
                        return p1get(x1, y1 - 1)
                    end
                end
            end
        end
        return false
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "bool"
    }
end

-- Makes a pattern with a bunch of square islands connected by bridges.
function SquaresAndBridges(islandradius, bridgelength, bridgewidth)
    local r = islandradius or 32
    local l = bridgelength or 48
    local w = bridgewidth or 2
    return Islandify(True(), True(), 2 * r, 2 * r, l, w)
end

-- Makes a pattern with a bunch of circular islands connected by bridges.
function CirclesAndBridges(islandradius, bridgelength, bridgewidth)
    local r = islandradius or 32
    local l = bridgelength or 48
    local w = bridgewidth or 2
    return Islandify(True(), Translate(Circle(r), r, r), 2 * r, 2 * r, l, w)
end

-- This pattern is based on an idea and code by Donovan Hawkins:
-- https://forums.factorio.com/viewtopic.php?f=94&t=21568&start=10#p138292
function IslandifySquares(pattern, islandradius, bridgelength, bridgewidth)
    local r = islandradius or 32
    local l = bridgelength or 48
    local w = bridgewidth or 2
    return Islandify(pattern, True(), 2 * r, 2 * r, l, w)
end

-- Suggested by EldVarg
function IslandifyCircles(pattern, islandradius, bridgelength, bridgewidth)
    local r = islandradius or 32
    local l = bridgelength or 48
    local w = bridgewidth or 2
    return Islandify(pattern, Translate(Circle(r), r, r), 2 * r, 2 * r, l, w)
end

-- This pattern is based on an idea and code by Donovan Hawkins:
-- https://forums.factorio.com/viewtopic.php?f=94&t=21568&start=10#p138292
-- function Islandify(pattern, islandradius, bridgelength, bridgewidth)
    -- local pget = pattern.get
    -- local r = islandradius or 32
    -- local k = bridgelength or 48
    -- local w = bridgewidth or 2
    -- local n = 2 * r + w + k
-- 
    -- local function create()
        -- return pattern.create()
    -- end
-- 
    -- local function reload(d)
        -- pattern.reload(d)
    -- end
-- 
    -- local function get(x, y)
        -- local px = math.floor((x + r) / n)
        -- local py = math.floor((y + r) / n)
        -- if not pget(px, py) then
            -- return false
        -- end
        -- x = x % n
        -- y = y % n
        -- if (x < w and pget(px, py + 1)) or (y < w and pget(px + 1, py)) then
            -- return true
        -- else
            -- x = (x + r) % n
            -- y = (y + r) % n
            -- return (x < 2 * r + w) and (y < 2 * r + w)
        -- end
    -- end
-- 
    -- return {
        -- create = create,
        -- reload = reload,
        -- get = get,
        -- lua = 'Islandify(' .. pattern.lua .. ', ' .. r .. ', ' .. k .. ', ' .. w .. ')'
    -- }
-- end
