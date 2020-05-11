local append = table.insert

logversion = '0.0.1'

function Logger(filename)
    local logger = {filename, {}, 0}
    if global.loggers == nil then
        global.loggers = {}
    end
    append(global.loggers, logger)
    return logger
end

-- Do not use newline characters in 'line'! This will mess up the journal.
function write_log(logger, line)
    local tick = game.tick
    append(logger[2], string.format('%d %s\n', tick - logger[3], line))
    logger[3] = tick
end

-- Do not use newline characters in 'line'! This will mess up the journal.
function write_logs(line)
    for _, logger in ipairs(global.loggers or {}) do
        write_log(logger, line)
    end
end

function flush_log(logger)
    -- for name, player in pairs(game.players) do
        -- if settings.get_player_settings(player)['timelapse-enable'].value then
            -- game.write_file(log[1], table.concat(log[2]), true, player.index)
        -- end
    -- end
    if #(logger[2]) > 0 then
        game.write_file(logger[1], table.concat(logger[2]), true)
        logger[2] = {}
    end
end

function flush_logs()
    -- Write to journal
    -- Note that the line count assumes no newline characters were printed
    local update_sizes = {}
    local total = 0
    for _, logger in ipairs(global.loggers or {}) do
        total = total + (#(logger[2]))
        append(update_sizes, tostring(#(logger[2])))
    end

    if total == 0 then
        return
    end

    flush_id = math.random(1024 * 1024 * 1024)

    local message = string.format('%d %d %d %d %s', game.tick, flush_id,
        global.last_flush_tick, global.last_flush_id, table.concat(update_sizes, ' '))
    write_log(global.journal, message)

    global.last_flush_tick = game.tick
    global.last_flush_id = flush_id

    -- Flush everything
    for _, logger in ipairs(global.loggers or {}) do
        flush_log(logger)
    end
end

function log_journal_header(seed)
    local names = {}
    for _, logger in ipairs(global.loggers or {}) do
        append(names, logger[1])
    end
    write_log(global.journal, 'logfiles ' .. table.concat(names, ' '))
    write_log(global.journal, string.format('logversion %d %d %s', seed, game.tick, logversion))
end
