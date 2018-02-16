local o = 0
local function mk(name, item)
    o = o + 1
    local allowed = nil
    if item then
        allowed = {"Visible", "Fish", "Invisible"}
    else
        allowed = {"Visible", "Invisible"}
    end

    return {
        type = "string-setting",
        name = "invisifactorio-" .. name,
        setting_type = "startup",
        default_value = "Visible",
        allowed_values = allowed,
        order = tostring(o)
    }
end

data:extend{
    mk("trains"),
    mk("biters"),
    mk("items", true)
}
