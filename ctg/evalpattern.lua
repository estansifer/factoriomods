require("patterns/patterns")

v4 = nil
v3 = nil
v2 = nil
v1 = nil

local function eval(str)
    if false then -- string.find(str, "return", 1, true) ~= nil then
        return assert(load(str))()
    else
        return assert(load("return (" .. str .. ")"))()
    end
end

local function evaluate_pattern(preset, custom, p_v1, p_v2, p_v3, p_v4)
    v4 = nil
    v3 = nil
    v2 = nil
    v1 = nil
    if preset ~= nil then
        return eval(preset)
    else
        v4 = eval(p_v4)
        v3 = eval(p_v3)
        v2 = eval(p_v2)
        v1 = eval(p_v1)
        return eval(custom)
    end
end

function evaluate_patterns(s)
    if not global.enabled then
        warn("Internal error; mod is disabled during evaluate_patterns")
        return
    end

    local land_pattern, void_pattern, water_tile, deepwater_tile, void_tile

    if s['water-color'] == "blue" then
        water_tile = 'water'
        deepwater_tile = 'deepwater'
    elseif s['water-color'] == "green" then
        water_tile = 'water-green'
        deepwater_tile = 'deepwater-green'
    end
    local void_tile = 'out-of-map'

    if s['water-enable'] then
        land_pattern = evaluate_pattern(
            water_preset_by_name(s['water-pattern-preset']),
            s['water-pattern-custom'],
            s['water-pattern-custom-v1'],
            s['water-pattern-custom-v2'],
            s['water-pattern-custom-v3'],
            s['water-pattern-custom-v4'])
    end

    if s['void-enable'] then
        void_pattern = evaluate_pattern(
            void_preset_by_name(s['void-pattern-preset']),
            s['void-pattern-custom'],
            s['void-pattern-custom-v1'],
            s['void-pattern-custom-v2'],
            s['void-pattern-custom-v3'],
            s['void-pattern-custom-v4'])
    end

    return TerrainPattern(land_pattern, void_pattern, water_tile, deepwater_tile, void_tile)
end
