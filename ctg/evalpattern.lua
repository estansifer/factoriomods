require("patterns/patterns")

local function eval(str, env)
    -- string.find(str, "return", 1, true) ~= nil then
    if env == nil then
        return assert(load("return (" .. str .. ")", str, 't'))()
    else
        return assert(load("return (" .. str .. ")", str, 't', env))()
    end
end

-- 'pattern' is a string containing Lua code.
-- 'vars' is a list of pairs (name, code) where name and code are strings,
-- and name contains a Lua variable, and code contains Lua code.
-- Each variable in vars can refer to the later variables, and pattern can refer to any of them.
-- 'vars' can be nil.
local function evaluate_pattern_with_context(pattern, vars)
    if vars == nil then
        return eval(pattern)
    end

    local env = {}
    setmetatable(env, {__index = _G})
    for i = 1, #vars do
        local item = vars[#vars - i + 1]
        local var_name = item[1]
        local var_value = eval(item[2], env)
        env[var_name] = var_value
    end

    return eval(pattern, env)
end

function evaluate_pattern(s)
    if not global.enabled then
        warn("Internal error; mod is disabled during evaluate_pattern")
        return
    end

    local land_pattern, void_pattern, water_tile, deepwater_tile, void_tile

    local vars = {
            {"v1", s['pattern-v1']},
            {"v2", s['pattern-v2']},
            {"v3", s['pattern-v3']},
            {"v4", s['pattern-v4']},
            {"v5", s['pattern-v5']},
            {"v6", s['pattern-v6']},
            {"v7", s['pattern-v7']},
            {"v8", s['pattern-v8']}
        }

    local preset = preset_by_name(s['pattern-preset'])
    local pattern
    if preset == nil then
        pattern = evaluate_pattern_with_context(s['pattern-custom'], vars)
    else
        pattern = evaluate_pattern_with_context(preset)
    end

    if pattern.output == "tilename" then
        return pattern
    elseif pattern.output == "bool" then
        return TP(pattern, nil, nil)
    elseif pattern.output == "tileid" then
        return TileID2Name(pattern, nil)
    else
        return nil
    end
end
