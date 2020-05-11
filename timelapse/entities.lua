require('logger')
require('names')

-- Does both entites and resources

local whitelist = {
        'accumulator',
        'ammo-turret',
        'arithmetic-combinator',
        'artillery-turret',
        'assembling-machine',
        'beacon',
        'boiler',
        'container',
        'curved-rail',
        'decider-combinator',
        'electric-pole',
        'electric-turret',
        'fluid-turret',
        'furnace',
        'gate',
        'generator',
        'heat-pipe',
        'infinity-container',
        'infinity-pipe',
        'inserter',
        'lab',
        'lamp',
        'loader',
        'logistic-container',
        'market',
        'mining-drill',
        'offshore-pump',
        'pipe',
        'pipe-to-ground',
        'power-switch',
        'programmable-speaker',
        'pump',
        'radar',
        'rail-chain-signal',
        'rail-signal',
        'reactor',
        'roboport',
        'rocket-silo',
        'solar-panel',
        'splitter',
        'storage-tank',
        'straight-rail',
        'train-stop',
        'transport-belt',
        'turret',
        'underground-belt',
        'unit-spawner',
        'wall'
    }

local resources = {
        'coal',
        'copper-ore',
        'crude-oil',
        'iron-ore',
        'stone',
        'uranium'
    }

-- Prototype types of entities whose bounding box varies with direction
local list_with_direction = {
        'boiler',
        'curved-rail',
        'gate',
        'offshore-pump',
        'splitter'
    }

local on_whitelist = {}
local has_direction = {}
for _, item in ipairs(whitelist) do
    on_whitelist[item] = true
end
for _, item in ipairs(list_with_direction) do
    has_direction[item] = true
end

local function is_major(entity)
    return entity.unit_number ~= nil and on_whitelist[entity.type]
end

-- Log all tiles in the range (x, y) to (x + 32, y + 32)
function log_entities_chunk(x, y)
    local s = game.surfaces['nauvis']
    for _, entity in ipairs(s.find_entities({{x, y}, {x + 32, y + 32}})) do
        log_entity_created(entity)
    end
end

function log_resources_chunk(x, y)
    local s = game.surfaces['nauvis']
    local es = s.find_entities_filtered({area = {{x, y}, {x + 32, y + 32}}, type = 'resource'})
    for _, entity in ipairs(es) do
        local pos = entity.position
        out = string.format('%d %d %d %d',
                name2id(entity.name),
                math.floor(pos.x),
                math.floor(pos.y),
                entity.amount)
        write_log(global.logger_resources, out)
    end
end

function log_entity_created(entity)
    if is_major(entity) then
        local pos = entity.position
        out = string.format('%d %d %d %d %d',
                entity.unit_number,
                name2id(entity.name),
                math.floor(pos.x),
                math.floor(pos.y),
                entity.direction)
        write_log(global.logger_entities, out)
    end
end

function log_entity_destroyed(entity)
    if is_major(entity) then
        out = string.format('%d', entity.unit_number)
        write_log(global.logger_entities_removed, out)
    end
end

function log_resource_depleted(entity)
    local pos = entity.position
    out = string.format('%d %d %d', name2id(entity.name), math.floor(pos.x), math.floor(pos.y))
    write_log(global.logger_resources_depleted, out)
end

function log_resource_names()
    for _, item in ipairs(resources) do
        name2id(item)
        name2id(item .. '__active')
    end
end
