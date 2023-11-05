local noise = require('noise')
local tne = noise.to_noise_expression

require("abridged_auto")

add_recipes()
add_techs()

require('entity-changes')

require('noise-programs-abridged') -- Adjust biomes, terrain
require('resources-abridged') -- Adjust resources
require('tiles-abridged') -- Adjust tiles

-- Adjust enemies

local enemy_base_control_setting = noise.get_control_setting('enemy-base')

data.raw['noise-expression']['enemy-base-intensity'].expression = (
        noise.define_noise_function( function(x, y, tile, map)
            return noise.clamp(noise.var('distance') * 5, 0, 75 * 32) / 325 / 2
        end)
    )

local onehalf_exp = tne(1) / 2

data.raw['noise-expression']['enemy-base-radius'].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            return enemy_base_control_setting.size_multiplier ^ onehalf_exp * (tne(15) + 4 * noise.var("enemy-base-intensity") * (1 / 5))
        end)
    )

data.raw['noise-expression']['enemy-base-frequency'].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            local bases_per_km2 = 10 + 3 * noise.var("enemy-base-intensity")
            return 4 * enemy_base_control_setting.frequency_multiplier * bases_per_km2 / 1000000
        end)
    )

if mods['alien-biomes'] == nil then
    for k, v in pairs(data.raw['tree']) do
        local a = v.autoplace
        -- print(k, a.sharpness, a.richness_base, a.richness_multiplier)
        a.sharpness = 0.90
        if a.max_probability < 0.1 then
            a.max_probability = 0
        else
            a.max_probability = 0.9
            a.peaks[1].influence = a.peaks[1].influence - 1.1
            a.peaks[5].influence = 2
        end
    end
end
