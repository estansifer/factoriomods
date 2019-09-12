data:extend{
    {
        type = "bool-setting",
        name = "rainbow-player-color-enable",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "a"
    },
    {
        type = "double-setting",
        name = "rainbow-player-color-change-time",
        setting_type = "runtime-per-user",
        default_value = 300,
        minimum_value = 1,
        order = "b"
    },
    {
        type = "double-setting",
        name = "rainbow-player-color-alpha",
        setting_type = "runtime-per-user",
        default_value = 1,
        minimum_value = 0,
        maximum_value = 1,
        order = "c"
    }
}
