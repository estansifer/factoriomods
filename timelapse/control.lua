require('logger')
require('names')
require('tiles')
require('entities')
require('elevation')
require('write_py')

-- Takes a position {x = ..., y = ...} where (x, y) are chunk coordinates.
-- The area of the chunk goes from (32 * x, 32 * y) to (32 * (x + 1), 32 * (y + 1)).
local function log_chunk(chunk)
    local id = chunk.x * 1000000 + chunk.y
    if global.chunks[id] == nil then
        global.chunks[id] = true
        if global.settings.tiles then
            log_tiles_chunk(32 * chunk.x, 32 * chunk.y)
        end
        if global.settings.resources then
            log_resources_chunk(32 * chunk.x, 32 * chunk.y)
        end
        if global.settings.entities then
            log_entities_chunk(32 * chunk.x, 32 * chunk.y)
        end
        if global.settings.elevation then
            log_elevation(32 * chunk.x, 32 * chunk.y)
        end
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

local function log_existing_chunks()
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
    local s = global.settings
    if s.players then
        script.on_event(defines.events.on_tick, on_tick)
    end
    if s.on_chunk then
        script.on_event(defines.events.on_chunk_charted, on_chunk_charted)
    end
    if s.resources then
        script.on_event(defines.events.on_resource_depleted, on_depleted)
    end

    if s.entities then
        script.on_event(defines.events.on_built_entity, on_created)
        script.on_event(defines.events.on_robot_built_entity, on_created)
        script.on_event(defines.events.on_biter_base_built, on_biter_base_built)
        script.on_event(defines.events.on_entity_died, on_destroyed)
        script.on_event(defines.events.on_player_mined_entity, on_destroyed)
        script.on_event(defines.events.on_robot_mined_entity, on_destroyed)
    end

    if s.tiles then
        script.on_event(defines.events.on_player_built_tile, on_tiles_changed)
        script.on_event(defines.events.on_robot_built_tile, on_tiles_changed)
        script.on_event(defines.events.on_player_mined_tile, on_tiles_changed)
        script.on_event(defines.events.on_robot_mined_tile, on_tiles_changed)
    end
end

local function on_init()
    local surface = game.surfaces['nauvis']
    local seed = surface.map_gen_settings.seed
    global.logversion = logversion
    global.settings = {
        entities = settings.global['timelapse-entities'].value,
        tiles = settings.global['timelapse-tiles'].value,
        resources = settings.global['timelapse-resources'].value,
        players = settings.global['timelapse-players'].value,
        elevation = settings.global['timelapse-elevation'].value,
        elevation_scan = settings.global['timelapse-elevation-scan'].value,
    }
    local s = global.settings
    s.names = (s.entities or s.tiles or s.resources)
    s.on_chunk = (s.entities or s.tiles or s.resources or s.elevation)

    if s.elevation_scan then
        global.settings = {}
        global.logger_elevation_scan = Logger('elevations/' .. tostring(seed))
        perform_elevation_scan()
        flush_log(global.logger_elevation_scan)
        return nil
    end

    write_py_files()
    if s.names then
        init_names()
    end
    -- For keeping track of which chunks have been processed already
    global.chunks = {}

    -- For tracking the last time the logs were flushed
    global.last_flush_tick = game.tick
    global.last_flush_id = -1

    global.game_id = math.random(1024 * 1024 * 1024)
    local folder = 'timelapse/recordings/' .. tostring(global.game_id) .. '/'
    global.journal = Logger(folder .. 'journal')

    if s.names then
        global.logger_names = Logger(folder .. 'names')
    end
    if s.entities then
        global.logger_entities = Logger(folder .. 'entities')
        global.logger_entities_removed = Logger(folder .. 'entities_removed')
    end
    if s.tiles then
        global.logger_tiles_init = Logger(folder .. 'tiles_init')
        global.logger_tiles = Logger(folder .. 'tiles')
    end
    if s.resources then
        global.logger_resources = Logger(folder .. 'resources')
        global.logger_resources_depleted = Logger(folder .. 'resources_depleted')
    end
    if s.players then
        global.logger_player = Logger(folder .. 'player_position')
    end
    if s.elevation then
        global.logger_elevation = Logger(folder .. 'elevation')
    end
    if s.elevation_scan then
        global.logger_elevation_scan = Logger(folder .. 'elevation_scan')
    end

    local message = '# on_init seed = ' .. tostring(seed) .. ' tick = ' .. tostring(game.tick) .. ' logversion = ' .. logversion

    write_logs(message)
    log_journal_header(seed)

    -- Log things that exist already on the map at this point
    if s.names then
        log_resource_names()
    end
    if s.on_chunk then
        log_existing_chunks()
    end
    if s.elevation_scan then
        perform_elevation_scan()
    end

    flush_logs()

    local msg = tostring(global.game_id) .. ' ' .. tostring(seed)
    msg = msg .. ' ' .. tostring(game.tick) .. ' ' .. surface.get_map_exchange_string() .. '\n'
    game.write_file('timelapse/recordings/catalog', msg, true)

    on_load()
end

script.on_init(on_init)
script.on_load(on_load)
