-- item can be 'belt' or 'inserter'
local function valid_rotations(item)
    local r = {
        settings.global['one-way-belts-' .. item .. '-n'].value,
        settings.global['one-way-belts-' .. item .. '-e'].value,
        settings.global['one-way-belts-' .. item .. '-s'].value,
        settings.global['one-way-belts-' .. item .. '-w'].value
    }
    if (not r[1]) and (not r[2]) and (not r[3]) and (not r[4]) then
        return {true, true, true, true}
    else
        return r
    end
end

local db = ({
        [defines.direction.north]   = 1,
        [defines.direction.east]    = 2,
        [defines.direction.south]   = 3,
        [defines.direction.west]    = 4
    })
local di = ({
        [defines.direction.north]   = 3,
        [defines.direction.east]    = 4,
        [defines.direction.south]   = 1,
        [defines.direction.west]    = 2
    })

-- item can be 'belt' or 'inserter'
local function fix(item, entity)
    local r = valid_rotations(item)
    if item == "inserter" then
        while not r[di[entity.direction]] do
            entity.rotate()
        end
    else
        while not r[db[entity.direction]] do
            entity.rotate()
        end
    end
end

local function check(entity)
    local proto = entity.prototype
    if proto.belt_speed ~= nil then
        fix('belt', entity)
    else
        if proto.type == "inserter" then
            fix('inserter', entity)
        end
    end
end

local function create_entity(event)
    check(event.created_entity)
end

local function rotate_entity(event)
    check(event.entity)
end

-- local function on_init(event)
    -- on_load(nil)
-- end

-- local function on_load(event)
-- end

-- script.on_init(on_init)
-- script.on_load(on_load)

script.on_event(defines.events.on_built_entity, create_entity)
script.on_event(defines.events.on_robot_built_entity, create_entity)
script.on_event(defines.events.on_player_rotated_entity, rotate_entity)
