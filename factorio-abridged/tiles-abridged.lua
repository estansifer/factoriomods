local noise = require("noise")
local autoplace_utils = require("autoplace_utils")

local biome_scale = 10

local tile_noise_enabled = true -- ems
local tile_noise_persistence = 0.7

-- local tile_noise_influence = 2/3
local tile_noise_influence = 0.1 -- ems
local size_control_influence = 1
local rectangle_influence = 1
local beach_influence = 5

local function noise_layer_expression(noise_name)
  if tile_noise_enabled == false then return noise.to_noise_expression(0) end
  return noise.function_application("factorio-multioctave-noise",
    {
      x = noise.var("x") * biome_scale, -- ems
      y = noise.var("y") * biome_scale, -- ems
      persistence = tile_noise_persistence,
      seed0 = noise.var("map_seed"),
      seed1 = noise.noise_layer_name_to_id(noise_name),
      input_scale = noise.fraction(1, 6),
      output_scale = tile_noise_influence,
      -- octaves = 4
      octaves = 2
    }
  )
end

local function peak_to_noise_expression(variable, optimal, range)
  local distance_from_optimal = noise.ridge(variable - optimal, 0, math.huge)
  -- Idea is to have a plateau in the center of the rectangle,
  -- edges that taper off at a consistent slope for all rectangles (so that interactions between rectangles are predictable),
  return range - distance_from_optimal
end
local function rectangle_peak_to_noise_expression(variable, optimal, range)
  -- Clamp rectangle-based peaks so that large rectangles don't become
  -- super powerful at their centers, because we want to be able to override
  -- them e.g. with beach peaks or whatever
  return noise.min(peak_to_noise_expression(variable, optimal, range) * 20, 1) * rectangle_influence
end

local function extend_left_rectangle_edge(left)
  if left == 0 then return -10 end
  return left
end
local function extend_right_rectangle_edge(right)
  if right == 1 then return 11 end
  return right
end

local function extend_edge_rectangle(rectangle)
  return
  {
    { extend_left_rectangle_edge(rectangle[1][1]),  extend_left_rectangle_edge(rectangle[1][2])},
    {extend_right_rectangle_edge(rectangle[2][1]), extend_right_rectangle_edge(rectangle[2][2])}
  }
end

local function auxwater_rect_to_noise_expression(rectangle)
  rectangle = extend_edge_rectangle(rectangle)

  local aux_center = (rectangle[2][1] + rectangle[1][1]) / 2
  local aux_range = math.abs(rectangle[2][1] - rectangle[1][1]) / 2
  local water_center = (rectangle[2][2] + rectangle[1][2]) / 2
  local water_range = math.abs(rectangle[2][2] - rectangle[1][2]) / 2

  local water_fitness = rectangle_peak_to_noise_expression(noise.var("moisture"), water_center, water_range)
  local aux_fitness   = rectangle_peak_to_noise_expression(noise.var("aux"), aux_center, aux_range)

  return noise.min(water_fitness, aux_fitness)
end

-- 'rectangles' indicate
-- {{minimum aux, minimum water}, {maximum aux, maximum water}}
local function autoplace_settings(noise_name, control_name, ...)
  local rectangles = {...}
  local probability_expression = noise.to_noise_expression(-math.huge)
  for i,rectangle in ipairs(rectangles) do
    if type(rectangle) == "table" then
      probability_expression = noise.max(probability_expression, auxwater_rect_to_noise_expression(rectangle))
    elseif type(rectangle) == "function" then
      probability_expression = rectangle(probability_expression)
    else
      error("Non-table, non-function passed as rectangle to autoplace_settings")
    end
  end

  -- local size_multiplier = noise.get_control_setting(control_name).size_multiplier
  -- local size_log = noise.log2(size_multiplier)
  -- local size_control_term = size_log * size_control_influence
  local size_control_term = 0
  probability_expression = probability_expression + noise_layer_expression(noise_name) + size_control_term

  return {
    probability_expression = probability_expression
  }
end

local function adjust_tile(name, control_name, ...)
    if mods['alien-biomes'] == nil then
        data.raw['tile'][name].autoplace = autoplace_settings(name, control_name, ...)
    end
end

-- name = "deepwater",
-- autoplace = make_water_autoplace_settings(-2, 200),

-- name = "water",
-- autoplace = make_water_autoplace_settings(0, 100),


adjust_tile("grass-1", "grass", {{0, 0.7}, {1, 1}})
adjust_tile("grass-2", "grass", {{0.45, 0.45}, {1, 0.8}})
adjust_tile("grass-3", "grass", {{0, 0.6}, {0.65, 0.9}})
adjust_tile("grass-4", "grass", {{0, 0.5}, {0.55, 0.7}})
adjust_tile("dry-dirt", "dirt", {{0.45, 0}, {0.55, 0.35}})
adjust_tile("dirt-1", "dirt", {{0, 0.25}, {0.45, 0.3}}, {{0.4, 0}, {0.45, 0.25}})
adjust_tile("dirt-2", "dirt", {{0, 0.3}, {0.45, 0.35}})
adjust_tile("dirt-3", "dirt", {{0, 0.35}, {0.55, 0.4}})
adjust_tile("dirt-4", "dirt", {{0.55, 0}, {0.6, 0.35}}, {{0.6, 0.3}, {1, 0.35}})
adjust_tile("dirt-5", "dirt", {{0, 0.4}, {0.55, 0.45}})
adjust_tile("dirt-6", "dirt", {{0, 0.45}, {0.55, 0.5}})
adjust_tile("dirt-7", "dirt", {{0, 0.5}, {0.55, 0.55}})
adjust_tile("sand-1", "sand", {{0, 0}, {0.25, 0.15}}, function(prob)
      local beach_peak = beach_influence * noise.min(
        peak_to_noise_expression(noise.var("elevation"), 0, 1.5),
        peak_to_noise_expression(noise.var("aux"), 0.75, 0.25)
      )
      return noise.max(prob, beach_peak)
    end)
adjust_tile("sand-2", "sand", {{0, 0.15}, {0.3, 0.2}}, {{0.25, 0}, {0.3, 0.15}})
adjust_tile("sand-3", "sand", {{0, 0.2}, {0.4, 0.25}}, {{0.3, 0}, {0.4, 0.2}})
adjust_tile("red-desert-0", "desert", {{0.55, 0.35}, {1, 0.5}})
adjust_tile("red-desert-1", "desert", {{0.6, 0}, {0.7, 0.3}}, {{0.7, 0.25}, {1, 0.3}})
adjust_tile("red-desert-2", "desert", {{0.7, 0}, {0.8, 0.25}}, {{0.8, 0.2}, {1, 0.25}})
adjust_tile("red-desert-3", "desert", {{0.8, 0}, {1, 0.2}})
