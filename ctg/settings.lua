require("metaconfig")

local o = 0
for i, setting in ipairs(meta.settings) do
    o = o + 1
    local s = {
        type            = setting[2] .. '-setting',
        name            = "ctg-" .. setting[1],
        setting_type    = meta.setting_type,
        default_value   = setting[3],
        order           = string.format('ctg-%04d', i)
    }
    if setting[2] == 'string' and setting[4] ~= nil then
        s.allowed_values = setting[4]
    end
    if setting[2] == 'int' and setting[4] ~= nil then
        s.minimum_value = setting[4][1]
        s.maximum_value = setting[4][2]
    end
    data:extend{s}
end

data:extend{
    {
        type                = 'bool-setting',
        name                = 'ctg-enable',
        setting_type        = 'startup',
        default_value       = true,
        order               = 'ctg-s000'
    },
    {
        type                = 'bool-setting',
        name                = 'ctg-use-default-water',
        setting_type        = 'startup',
        default_value       = false,
        order               = 'ctg-s001'
    }
}

--[[
data:extend{
        {
            type            = 'bool-setting',
            name            = 'ctg-brightmap',
            setting_type    = 'startup',
            default_value   = false,
            order           = 'ctg-X'
        }
    }
--]]
