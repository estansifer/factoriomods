require('logger')

function init_names()
    global.name2id = {}
    global.next_id = 1
end

-- Given a string, returns a unique id number representing that string
-- Performs logging necessary to reconstruct the names from ids
function name2id(name)
    local id = global.name2id[name]
    if id == nil then
        id = global.next_id
        global.next_id = id + 1
        global.name2id[name] = id
        write_log(global.logger_names, string.format('%d %s', id, name))
    end
    return id
end
