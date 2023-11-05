local noise = require("noise")
local util = require("util")
local tne = noise.to_noise_expression

local biome_scale = tne(10)
local elevation_scale = tne(5)

local average_sea_level_temperature = 15
local elevation_temperature_gradient = 0

local function clamp_moisture(raw_moisture)
  return noise.clamp(raw_moisture, 0, 1)
end

local function clamp_temperature(raw_temperature)
  return noise.clamp(raw_temperature, -20, 50)
end

local function clamp_aux(raw_aux)
  return noise.clamp(raw_aux, 0, 1)
end

local function make_basis_noise_function(seed0,seed1,outscale0,inscale0)
  outscale0 = outscale0 or 1
  inscale0 = inscale0 or 1/outscale0
  return function(x,y,inscale,outscale)
    return tne
    {
      type = "function-application",
      function_name = "factorio-basis-noise",
      arguments =
      {
        x = tne(x),
        y = tne(y),
        seed0 = tne(seed0),
        seed1 = tne(seed1),
        input_scale = tne((inscale or 1) * inscale0),
        output_scale = tne((outscale or 1) * outscale0)
      }
    }
  end
end

local function multioctave_noise(params)
  local x = params.x or noise.var("x")
  local y = params.y or noise.var("y")
  local seed0 = params.seed0 or 1
  local seed1 = params.seed1 or 1
  local octave_count = params.octave_count or 1
  local octave0_output_scale = params.octave0_output_scale or 1
  local octave0_input_scale = params.octave0_input_scale or 1
  if params.persistence and params.octave_output_scale_multiplier then
    error("Both persistence and octave_output_scale_multiplier were provided to multioctave_noise, which makes no sense!")
  end
  local octave_output_scale_multiplier = params.octave_output_scale_multiplier or 2
  local octave_input_scale_multiplier = params.octave_input_scale_multiplier or 1/2
  local basis_noise_function = params.basis_noise_function or make_basis_noise_function(seed0, seed1)

  if params.persistence then
    octave_output_scale_multiplier = params.persistence
    -- invert everything so that we can multiply by persistence every time
    -- first octave is the largest instead of the smallest
    octave0_input_scale = octave0_input_scale * math.pow(octave_input_scale_multiplier, octave_count - 1)
    -- 'persistence' implies that the octaves would otherwise have been powers of 2, I think
    octave0_output_scale = octave0_output_scale * math.pow(2, octave_count - 1)
    octave_input_scale_multiplier = 1 / octave_input_scale_multiplier
  end

  return tne{
    type = "function-application",
    function_name = "factorio-quick-multioctave-noise",
    arguments =
    {
      x = tne(x),
      y = tne(y),
      seed0 = tne(seed0),
      seed1 = tne(seed1),
      input_scale = tne(octave0_input_scale),
      output_scale = tne(octave0_output_scale),
      octaves = tne(octave_count),
      octave_output_scale_multiplier = tne(octave_output_scale_multiplier),
      octave_input_scale_multiplier = tne(octave_input_scale_multiplier)
    }
  }
end

-- Multioctave noise that's constructed in a simple way and knows about 'persistence'.
-- It doesn't *have* to be variable,
-- but this construction allows for it.
local function simple_variable_persistence_multioctave_noise(params)
  local x = params.x or noise.var("x")
  local y = params.y or noise.var("y")
  local seed0 = params.seed0 or 1
  local seed1 = params.seed1 or 1
  local octave_count = params.octave_count or 1
  local octave0_output_scale = params.octave0_output_scale or 1
  local octave0_input_scale = params.octave0_input_scale or 1
  local persistence = params.persistence or 1/2

  local terms = {}
  -- Start at the 'large' octave (assuming powers of 2 size increases)
  -- and work inwards, doubling the frequency and mulitplying amplitude by persistence.
  -- 'octave0' is the smallest octave.
  local largest_octave_scale = (2 ^ octave_count)
  local inscale = octave0_input_scale / largest_octave_scale
  local outscale = octave0_output_scale * largest_octave_scale
  for oct=1,octave_count do
    terms[oct] = tne{
      type = "function-application",
      function_name = "factorio-basis-noise",
      arguments = {
        x = tne(x),
        y = tne(y),
        seed0 = tne(seed0),
        seed1 = tne(seed1),
        input_scale = tne(inscale),
        output_scale = tne(1), -- Since outscale is variable, need to multiply separately
      }
    } * outscale
    inscale = inscale * 2 -- double frequency
    outscale = outscale * persistence -- lower amplitude (unless persistence is >1, which would be weird but okay)
  end
  return tne{
    type = "function-application",
    function_name = "add",
    arguments = terms
  }
end

-- Accounts for multiple octaves to return an expression whose amplitude maxes out at about +-1
-- (or +-octave0_input_scale, if that's passed in).
-- Parameters are the same as for simple_variable_persistence_multioctave_noise.
local function simple_amplitude_corrected_multioctave_noise(params)
  local amplitide = params.amplitude or 1
  local persistence = params.persistence or 0.5
  local octave_count = params.octave_count or 1
  -- 0.12's ImprovedNoise would do like:
  -- output = total / ((1 - amplitude) / (1 - persistence)) -- where amplitude is persistence ^ octaves
  -- output = total * (1 - persistence) / (1 - persistence ^ octaves)
  -- So use (1 - persistence) / (1 - persistence ^ octaves) as the output multiplier
  -- but it also uses 1 as the amplitude of the largest octave, whereas
  -- simple_variable_persistence_multioctave_noise uses 2^octave_count.
  -- So divide by that, too:
  local multiplier = (1 - persistence) / (2^octave_count) / (1 - persistence ^ octave_count)

  if params.octave0_output_scale then
    error("Don't pass octave0_output_scale to simple_amplitude_corrected_multioctave_noise; pass amplitude, instead")
  end
  return simple_variable_persistence_multioctave_noise(util.merge{params, {octave0_output_scale = multiplier * amplitide}})
end

local function make_multioctave_noise_function(seed0,seed1,octaves,octave_output_scale_multiplier,octave_input_scale_multiplier,output_scale0,input_scale0)
  octave_output_scale_multiplier = octave_output_scale_multiplier or 2
  octave_input_scale_multiplier = octave_input_scale_multiplier or 1 / octave_output_scale_multiplier
  return function(x,y,inscale,outscale)
    return tne{
      type = "function-application",
      function_name = "factorio-quick-multioctave-noise",
      arguments =
      {
        x = tne(x),
        y = tne(y),
        seed0 = tne(seed0),
        seed1 = tne(seed1),
        input_scale = tne((inscale or 1) * (input_scale0 or 1)),
        output_scale = tne((outscale or 1) * (output_scale0 or 1)),
        octaves = tne(octaves),
        octave_output_scale_multiplier = tne(octave_output_scale_multiplier),
        octave_input_scale_multiplier = tne(octave_input_scale_multiplier)
      }
    }
  end
end

-- unused for now
-- Returns a multioctave noise function where each octave's noise is multiplied by some other noise
-- by default 'some other noise' is the basis noise at 17x lower frequency,
-- normalized around 0.5 and clamped between 0 and 1
local function make_multioctave_modulated_noise_function(params)
  local seed0 = params.seed0 or 1
  local seed1 = params.seed1 or 1
  local octave_count = params.octave_count or 1
  local octave0_output_scale = params.octave0_output_scale or 1
  local octave0_input_scale = params.octave0_input_scale or 1
  local octave_output_scale_multiplier = params.octave_output_scale_multiplier or 2
  local octave_input_scale_multiplier = params.octave_input_scale_multiplier or 1/2
  local basis_noise_function = params.basis_noise_function or make_basis_noise_function(seed0, seed1)
  local modulation_noise_function = params.modulation_noise_function or function(x,y)
    return noise.clamp(basis_noise_function(x,y)+0.5, 0, 1)
  end
  -- input scale of modulation relative to each octave's base input scale
  local mris = params.modulation_relative_input_scale or 1/17

  return function(x,y)
    local outscale = octave0_output_scale
    local inscale = octave0_input_scale
    local result = 0

    for i=1,octave_count do
      local noise = basis_noise_function(x*inscale, y*inscale)
      local modulation = modulation_noise_function(x*(inscale*mris), y*(inscale*mris))
      result = result + (outscale * noise * modulation)

      outscale = outscale * octave_output_scale_multiplier
      inscale = inscale * octave_input_scale_multiplier
    end

    return result
  end
end

local standard_starting_lake_elevation_expression = noise.define_noise_function( function(x,y,tile,map)
    x = x * elevation_scale -- ems
    y = y * elevation_scale -- ems
  local starting_lake_distance = noise.distance_from(x, y, noise.var("starting_lake_positions"), 1024)
  local minimal_starting_lake_depth = 4
  local minimal_starting_lake_bottom =
    starting_lake_distance / 4 - minimal_starting_lake_depth +
    make_basis_noise_function(map.seed, 123, 1.5, 1/8)(x,y)

  -- Starting cone ensures a more random (but not ~too~ random, because people don't like 'swampy lakes')
  -- valley outside the starting lake:
  local starting_cone_slope = noise.fraction(1, 16)
  local starting_cone_offset = -1
  local starting_cone_noise_multiplier = noise.var("starting-lake-noise-amplitude")/16
  -- Second cone is intended to provide a more gradual slope and more noise
  -- outside of the first cone in order to prevent obvious circles of cliffs.
  -- Its bottom is clamped to a positive value so that it will only affect cliffs,
  -- not water.
  local second_cone_slope = noise.fraction(1, 16)
  local second_cone_offset = 2
  local second_cone_noise_multiplier = noise.var("starting-lake-noise-amplitude")/2

  local starting_lake_noise = multioctave_noise{
    x = x,
    y = y,
    seed0 = map.seed,
    seed1 = 14, -- CorePrototypes::elevationNoiseLayer->getID().getIndex()
    octave0_input_scale = 1/8, -- We don't want the starting lake to scale along with the rest of the map
    octave0_output_scale = 1,
    octave_count = 5,
    persistence = 0.75
  }
  return noise.ident(noise.min(
    minimal_starting_lake_bottom,
    starting_cone_offset + starting_cone_slope * starting_lake_distance + starting_cone_noise_multiplier * starting_lake_noise,
    noise.max(
      second_cone_offset,
      second_cone_offset + second_cone_slope * starting_lake_distance + second_cone_noise_multiplier * starting_lake_noise
    )
  ))
end)

local function water_level_correct(to_be_corrected, map)
  return noise.ident(noise.max(
    map.wlc_elevation_minimum,
    to_be_corrected + map.wlc_elevation_offset
  ))
end

local cliff_terracing_enabled = false

local function finish_elevation(elevation, map)
  local elevation = water_level_correct(elevation, map)
  elevation = elevation / map.segmentation_multiplier
  elevation = noise.min(elevation, standard_starting_lake_elevation_expression)
  if cliff_terracing_enabled then
    elevation = noise.terrace_for_cliffs(elevation, nil, map)
  end
  return elevation
end

local function make_0_12like_lakes(x, y, tile, map, options)
  options = options or {}
  local terrain_octaves = options.terrain_octaves or 8
  local amplitude_multiplier = 1/8
  local roughness_persistence = 0.7
  local bias = options.bias or 20 -- increase average elevation level by this much
  local starting_plateau_bias = 20
  local starting_plateau_octaves = 6

  local roughness = simple_amplitude_corrected_multioctave_noise{
    x = x,
    y = y,
    seed0 = map.seed,
    seed1 = 1,
    octave_count = terrain_octaves - 2,
    amplitude = 1/2,
    octave0_input_scale = 1/2,
    persistence = roughness_persistence
  }
  local persistence = noise.clamp(roughness + 0.3, 0.1, 0.9)
  local lakes = simple_variable_persistence_multioctave_noise{
    x = x,
    y = y,
    seed0 = map.seed,
    seed1 = 1,
    octave_count = terrain_octaves,
    octave0_input_scale = 1/2,
    octave0_output_scale = amplitude_multiplier,
    persistence = persistence
  }
  local starting_plateau_basis = simple_variable_persistence_multioctave_noise{
    x = x,
    y = y,
    seed0 = map.seed,
    seed1 = 2,
    octave_count = starting_plateau_octaves,
    octave0_input_scale = 1/2,
    octave0_output_scale = amplitude_multiplier,
    persistence = persistence
  }
  local starting_plateau = starting_plateau_basis + starting_plateau_bias + map.finite_water_level - tile.distance * elevation_scale * map.segmentation_multiplier / 10
  return noise.max(lakes + bias, starting_plateau)
end

data.raw["noise-expression"]["temperature"].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            x = x * biome_scale -- ems
            y = y * biome_scale -- ems
          x = x * noise.var("control-setting:temperature:frequency:multiplier") + 40000 -- Move the point where 'fractal similarity' is obvious off into the boonies
          y = y * noise.var("control-setting:temperature:frequency:multiplier")
          local base_temp =
            average_sea_level_temperature +
            -- make_multioctave_noise_function(map.seed, 5, 4, 3)(x,y,1/32,1/20) +
            make_multioctave_noise_function(map.seed, 5, 2, 3)(x,y,1/32,1/20) +
            noise.var("control-setting:temperature:bias")
          local elevation_adjusted_temperature = base_temp + noise.var("elevation") * elevation_temperature_gradient
          return noise.ident(clamp_temperature(elevation_adjusted_temperature))
        end)
    )

data.raw["noise-expression"]["moisture"].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            x = x * biome_scale -- ems
            y = y * biome_scale -- ems
          x = x * noise.var("control-setting:moisture:frequency:multiplier") + 30000 -- Move the point where 'fractal similarity' is obvious off into the boonies
          y = y * noise.var("control-setting:moisture:frequency:multiplier")
          local raw_moisture =
            3/8 +
            -- make_multioctave_noise_function(map.seed, 6, 4, 1.5, 1/3)(x,y,1/256,1/8) +
            make_multioctave_noise_function(map.seed, 6, 2, 1.5, 1/3)(x,y,1/256,1/8) +
            noise.var("control-setting:moisture:bias")
          return noise.ident(clamp_moisture(raw_moisture))
        end)
    )

data.raw["noise-expression"]["aux"].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            x = x * biome_scale -- ems
            y = y * biome_scale -- ems
          x = x * noise.var("control-setting:aux:frequency:multiplier") + 20000 -- Move the point where 'fractal similarity' is obvious off into the boonies
          y = y * noise.var("control-setting:aux:frequency:multiplier")
          local raw_aux =
            0.5 +
            -- make_multioctave_noise_function(map.seed, 7, 4, 1/2, 3)(x,y,1/2048,1/4) +
            make_multioctave_noise_function(map.seed, 7, 2, 1/2, 3)(x,y,1/2048,1/4) +
            noise.var("control-setting:aux:bias")
          return noise.ident(clamp_aux(raw_aux))
        end)
    )



-- data.raw['noise-expression']['control-setting:temperature:frequency:multiplier'].expression = biome_scale
-- data.raw['noise-expression']['control-setting:moisture:frequency:multiplier'].expression = biome_scale
-- data.raw['noise-expression']['control-setting:aux:frequency:multiplier'].expression = biome_scale

-- data.raw['noise-expression']['distance'].expression = (
        -- noise.distance_from(noise.var("x"), noise.var("y"), noise.var("starting_positions")) * scale
    -- )
-- 
-- data:extend{
        -- {
            -- type = 'noise-expression',
            -- name = 'true-distance',
            -- expression = noise.distance_from(noise.var('x'), noise.var('y'), noise.var('starting_positions'))
        -- }
    -- }

data.raw['noise-expression']['0_17-lakes-elevation'].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            x = x * elevation_scale -- ems
            y = y * elevation_scale -- ems
            x = x * map.segmentation_multiplier + 10000 -- Move the point where 'fractal similarity' is obvious off into the boonies
            y = y * map.segmentation_multiplier
            return finish_elevation(make_0_12like_lakes(x, y, tile, map), map)
        end)
    )
data.raw['noise-expression']['0_17-island'].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            map = util.merge
                {
                    map,
                    { segmentation_multiplier = map.segmentation_multiplier / 4 }
                }
            x = x * elevation_scale -- ems
            y = y * elevation_scale -- ems
            x = x * map.segmentation_multiplier + 10000 -- Move the point where 'fractal similarity' is obvious off into the boonies
            y = y * map.segmentation_multiplier
            options = {bias = -1000}
            return finish_elevation(make_0_12like_lakes(x, y, tile, map, options), map)
        end)
    )

data.raw['noise-expression']['cliffiness'].expression = (
        noise.define_noise_function( function(x,y,tile,map)
            x = x * elevation_scale -- ems
            y = y * elevation_scale -- ems
            -- return 0.5 + noise.clamp(
            return 0.2 + noise.clamp( -- ems
                make_multioctave_noise_function(map.seed, 123, 2, 1, 1/3)(x,y,1/32,1) +
                noise.log2(noise.var("control-setting:cliffs:richness:multiplier")) / 2,
                0, 1)
        end)
    )
