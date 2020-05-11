require('logger')
require('names')
require('tiles')
require('entities')
require('write_py')

-- Takes a position {x = ..., y = ...} where (x, y) are chunk coordinates.
-- The area of the chunk goes from (32 * x, 32 * y) to (32 * (x + 1), 32 * (y + 1)).
local function log_chunk(chunk)
    local id = chunk.x * 1000000 + chunk.y
    if global.chunks[id] == nil then
        global.chunks[id] = true
        log_tiles_chunk(32 * chunk.x, 32 * chunk.y)
        log_resources_chunk(32 * chunk.x, 32 * chunk.y)
        log_entities_chunk(32 * chunk.x, 32 * chunk.y)
    end
end

local function log_player_position()
    positions = {}
    for name, player in pairs(game.players) do
        local p = player.position
        table.insert(positions, string.format("%d %.1f %.1f", player.index, p.x, p.y))
    end
    write_log(global.logger_player, table.concat(positions, ' '))
end

local function on_tick(event)
    if (game.tick % (2 * 60)) == 0 then
        log_player_position()
    end
    if (game.tick % (60 * 60)) == 0 then
        flush_logs()
    end
end

local function on_chunk_charted(event)
    log_chunk(event.position)
end

local function on_depleted(event)
    log_resource_depleted(event.entity)
end

local function on_created(event)
    log_entity_created(event.created_entity)
end

local function on_biter_base_built(event)
    log_entity_created(event.entity)
end

local function on_destroyed(event)
    log_entity_destroyed(event.entity)
end

local function on_tiles_changed(event)
    -- event.tiles is an array of tables, each of which has an element 'position'
    -- with the position of the affected tile
    log_tiles(event.tiles)
end

local function log_init()
    local s = game.surfaces['nauvis']
    for _, force in pairs(game.forces) do
        for _, player in ipairs(force.players) do
            for chunk in s.get_chunks() do
                if force.is_chunk_charted(s, chunk) then
                    log_chunk(chunk)
                end
            end
            break
        end
    end
end

local function on_load()
    script.on_event(defines.events.on_tick, on_tick)
    script.on_event(defines.events.on_chunk_charted, on_chunk_charted)
    script.on_event(defines.events.on_resource_depleted, on_depleted)

    script.on_event(defines.events.on_built_entity, on_created)
    script.on_event(defines.events.on_robot_built_entity, on_created)
    script.on_event(defines.events.on_biter_base_built, on_biter_base_built)
    script.on_event(defines.events.on_entity_died, on_destroyed)
    script.on_event(defines.events.on_player_mined_entity, on_destroyed)
    script.on_event(defines.events.on_robot_mined_entity, on_destroyed)

    script.on_event(defines.events.on_player_built_tile, on_tiles_changed)
    script.on_event(defines.events.on_robot_built_tile, on_tiles_changed)
    script.on_event(defines.events.on_player_mined_tile, on_tiles_changed)
    script.on_event(defines.events.on_robot_mined_tile, on_tiles_changed)
end

local function on_init()
    local s = game.surfaces['nauvis']

    write_py_files()
    init_names()
    -- For keeping track of which chunks have been processed already
    global.chunks = {}

    -- For tracking the last time the logs were flushed
    global.last_flush_tick = game.tick
    global.last_flush_id = -1

    global.game_id = math.random(1024 * 1024 * 1024)
    local folder = 'timelapse/recordings/' .. tostring(global.game_id) .. '/'
    global.journal = Logger(folder .. 'journal')
    global.logger_names = Logger(folder .. 'names')
    global.logger_entities = Logger(folder .. 'entities')
    global.logger_entities_removed = Logger(folder .. 'entities_removed')
    global.logger_tiles_init = Logger(folder .. 'tiles_init')
    global.logger_tiles = Logger(folder .. 'tiles')
    global.logger_resources = Logger(folder .. 'resources')
    global.logger_resources_depleted = Logger(folder .. 'resources_depleted')
    global.logger_player = Logger(folder .. 'player_position')

    local seed = s.map_gen_settings.seed
    local message = '# on_init seed = ' .. tostring(seed) .. ' tick = ' .. tostring(game.tick) .. ' logversion = ' .. logversion

    write_logs(message)
    log_journal_header(seed)

    -- Log things that exist already on the map at this point
    log_resource_names()
    log_init()

    flush_logs()

    local msg = tostring(global.game_id) .. ' ' .. tostring(seed)
    msg = msg .. ' ' .. tostring(game.tick) .. ' ' .. s.get_map_exchange_string() .. '\n'
    game.write_file('timelapse/recordings/catalog', msg, true)

    on_load()
end

script.on_init(on_init)
script.on_load(on_load)
