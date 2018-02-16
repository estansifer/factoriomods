local o = 0
local function mk(item, dir, def)
    o = o + 1
    return {
        type = "bool-setting",
        name = "one-way-belts-" .. item .. "-" .. dir,
        setting_type = "runtime-global",
        default_value = def,
        order = tostring(o)
    }
end

data:extend {
    mk('belt', 'n', true),
    mk('belt', 'e', true),
    mk('belt', 's', false),
    mk('belt', 'w', false),
    mk('inserter', 'n', true),
    mk('inserter', 'e', true),
    mk('inserter', 's', true),
    mk('inserter', 'w', true)
}
