local noise = require("noise") -- From the core mod

if settings.startup['ctg-enable'].value and not settings.startup['ctg-use-default-water'].value then
    -- Note sure what probability_expression does. Setting it to zero does not turn off water.
    local nowater = {
            probability_expression = noise.to_noise_expression(-math.huge)
        }

    local t = data.raw.tile
    t.water.autoplace = nowater
    t.deepwater.autoplace = nowater
    t['water-green'].autoplace = nowater
    t['deepwater-green'].autoplace = nowater
end

local function brighten1(x)
    if x >= 0 and x < 1 then
        return (x + 1) / 2
    end
    return math.floor((x + 128) / 2)
end
local function darken1(x)
    if x >= 0 and x < 1 then
        return x / 2
    end
    return math.floor(x / 2)
end

local function adjust(tile)
    c = tile['map_color']
    if string.find(tile.name, 'water') then
        c.r = darken1(darken1(c.r))
        c.g = darken1(darken1(c.g))
        -- c.b = brighten1(c.b)
    else
        c.r = brighten1(c.r)
        c.g = brighten1(c.g)
        c.b = brighten1(c.b)
    end
end

if false and settings.startup['ctg-brightmap'] then
    for name, tile in pairs(data.raw.tile) do
        adjust(tile)
    end

    local r = data.raw.resource
    local names = {"stone", "coal", "iron-ore", "copper-ore", "uranium-ore", "crude-oil"}
    for _, name in ipairs(names) do
        table.insert(r[name].flags, "not-on-map")
    end
end

--[[
--  t['out-of-map'].map_color   0   0   0
--  deepwater                   38  64  73
--  deepwater-green             0.0941  0.149   0.066
--  water                       51  83  95
--  water-green                 31  48  18
--  grass-1                     53  52  27
--  grass-2                     57  54  35
--  grass-3                     59  56  41
--  grass-4                     54  47  35
--  dry-dirt                    108 92  71
--  dirt-1                      119 104 85
--  dirt-2                      109 94  75
--  dirt-3                      99  85  65
--  dirt-4                      89  74  57
--  dirt-5
--]]
