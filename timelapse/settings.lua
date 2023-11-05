local o = 0
local function make(name, default)
    o = o + 1
    return {
        type = "bool-setting",
        name = "timelapse-" .. name,
        setting_type = "runtime-global",
        default_value = default,
        order = tostring(o)
    }
end

data:extend{
    make('entities', true),
    make('tiles', true),
    make('resources', true),
    make('players', true),
    make('elevation', false),
    make('elevation-scan', false)
}
