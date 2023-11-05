local resource_autoplace = require("resource-autoplace-abridged")

local resource_scale = 4
local oil_scale = 3

local function adjust_autoplace (
        name,
        base_density,
        regular_rq_factor_multiplier,
        starting_rq_factor_multiplier,
        candidate_spot_count,
        regular_offset,
        starting_offset)
    local old = data.raw['resource'][name].autoplace
    local new = resource_autoplace.resource_autoplace_settings {
            name = name,
            order = 'b',
            base_density = base_density,
            starting_density = 15,
            has_starting_area_placement = true,
            regular_rq_factor_multiplier = regular_rq_factor_multiplier,
            starting_rq_factor_multiplier = starting_rq_factor_multiplier,
            candidate_spot_count = candidate_spot_count,
            regular_patch_offset = regular_offset,
            starting_patch_offset = starting_offset,
            scale = resource_scale
        }
    old.probability_expression = new.probability_expression
    old.richness_expression = new.richness_expression
end

local function adjust_autoplace_oil()
    local name = 'crude-oil'
    local old = data.raw['resource'][name].autoplace
    local new = resource_autoplace.resource_autoplace_settings {
            name = name,
            order = 'c',
            base_density = 8.2,
            has_starting_area_placement = false,
            regular_rq_factor_multiplier = 0.3,
            starting_rq_factor_multiplier = 1,
            regular_patch_offset = 6,
            scale = oil_scale,
            base_spots_per_km2 = 1.8,
            random_probability = 1.8,
            random_spot_size_minimum = 1,
            random_spot_size_maximum = 1,
            additional_richness = 220000
        }
    old.probability_expression = new.probability_expression
    old.richness_expression = new.richness_expression
end

-- adjust_autoplace('iron-ore', 10, 1.10, 1.5, 22, 1, 1)
-- adjust_autoplace('copper-ore', 8, 1.10, 1.2, 22, 2, 2)
-- adjust_autoplace('coal', 8, 1.0, 1.1, nil, 3, 3)
-- adjust_autoplace('stone', 4, 1.0, 1.1, nil, 4, 4)

local bd = 0.15 -- multiplier to density
local rq1 = 2 -- other. Larger is more spread out
local rq2 = 1.5 -- starting. Larger is more spread out
adjust_autoplace('iron-ore', bd * 10, rq1 * 1.10, rq2 * 1.5, 22, 1, 1)
adjust_autoplace('copper-ore', bd * 8, rq1 * 1.10, rq2 * 1.2, 22, 2, 2)
adjust_autoplace('coal', bd * 8, rq1 * 1.0, rq2 * 1.1, nil, 3, 3)
adjust_autoplace('stone', bd * 4, rq1 * 1.0, rq2 * 1.1, nil, 4, 4)

adjust_autoplace_oil()

-- adjust_autoplace('uranium-ore', 0.9, 1, 1, nil, 5, nil)
-- base_spots_per_km2 = 1.25
-- has_starting_area_placement = false
-- random_spot_size_minimum = 2,
-- random_spot_size_maximum = 4,


-- adjust_autoplace('crude-oil', 8.2, 1, 1, nil, 6, nil)
-- base_spots_per_km2 = 1.8,
-- random_probability = 1/48,
-- random_spot_size_minimum = 1,
-- random_spot_size_maximum = 1, -- don't randomize spot size
-- additional_richness = 220000, -- this increases the total everywhere, so base_density needs to be decreased to compensate
-- has_starting_area_placement = false,
