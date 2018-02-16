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

local d = {
        defines.direction.north     = 1,
        defines.direction.east      = 2,
        defines.direction.south     = 3,
        defines.direction.west      = 3,
    }

-- item can be 'belt' or 'inserter'
local function fix(item, entity)
    local r = valid_rotations(item)
    while not r[d[entity.direction]] do
        print('Rotating... ')
        print(entity.rotate())
    end
end

local function check(entity)
    local proto = entity.prototype
    if proto.belt_speed > 0 then
        fix('belt', entity)
    else
        print("proto.type")
        print(proto.type)
        print("proto.name")
        print(proto.name)
        local group = proto.group
        print("group.type")
        print(group.type)
        print("group.name")
        print(group.name)
        group = proto.subgroup
        print("subgroup.type")
        print(subgroup.type)
        print("subgroup.name")
        print(subgroup.name)
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
script.on_event(defines.events.on_player_rotate_entity, rotate_entity)
