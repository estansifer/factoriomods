require('abridged_auto')

local start_message_tick = 8 * 60

function show_message(msg)
    if game.is_multiplayer() then
        game.print(msg)
    else
        game.show_message_dialog{text = msg}
    end
end

function is_modded(name)
    return name:find('ab-', 1, true) == 1
end

function at_start()
    local intro_msg = "Uggh... do these rocket building instructions have to be so complicated? Half these parts don't even seem to do anything. I think with a little corner cutting we can get this thing into the air on the cheap."
    show_message(intro_msg)
end

function rand_gaussian()
    local r1 = math.random()
    local r2 = math.random()
    return math.sqrt(-2 * math.log(r1)) * math.cos(2 * math.pi * r2)
end

function spawn_grenade(x, y, grenade_type)
    -- 'cluster-grenade'
    local grenade_type = grenade_type or 'grenade'
    local nauvis = game.surfaces['nauvis']
    if nauvis.is_chunk_generated({x / 32, y / 32}) then
        -- local delay = (1 + math.random() * 20) * 60
        local delay = 0
        while (delay < 1) or (delay > 20) do
            delay = 7 + 5 * rand_gaussian()
        end
        delay = delay * 60
        -- delay from 1 to 20 seconds, typically around 7

        local speed = 0
        -- accelerates at 0.005
        local dist = 0.5 * 0.005 * delay * delay + speed * delay
        nauvis.create_entity({
                name = grenade_type,
                position = {x, y - dist},
                target = {x, y},
                speed = speed,
                max_range = 10 + dist
            })
    end
end

function launch_storm(x, y)
    for i = 1, 5 do
        spawn_grenade(x, y, 'cluster-grenade')
    end
    for i = 1, 20 do
        spawn_grenade(x + 20 * rand_gaussian(), y + 20 * rand_gaussian(), 'cluster-grenade')
    end
    for i = 1, 100 do
        spawn_grenade(x + 100 * rand_gaussian(), y + 100 * rand_gaussian(), 'cluster-grenade')
    end
end

function init_techs()
    local force = game.forces['player']
    for name, recipe in pairs(force.recipes) do
        if not is_modded(name) then
            recipe.enabled = false
        end
    end
    for name, tech in pairs(force.technologies) do
        if not is_modded(name) then
            tech.enabled = false
        end
    end
end

function switch_techs()
    local force = game.forces['player']
    force.cancel_current_research()
    force.reset_technologies()
    force.reset_recipes()
    -- force.reset()
    force.disable_all_prototypes()
    for name, tech in pairs(force.technologies) do
        tech.enabled = false
        tech.researched = false
    end
    for name, tech in pairs(force.technologies) do
        if not is_modded(name) then
            tech.enabled = true
        end
    end
    force.reset_technology_effects()
    for name, recipe in pairs(force.recipes) do
        if is_modded(name) then
            recipe.enabled = false
        end
    end

    local nauvis = game.surfaces['nauvis']
    local assemblers = nauvis.find_entities_filtered{type = 'assembling-machine'}
    for _, a in ipairs(assemblers) do
        local r = a.get_recipe()
        if r ~= nil then
            if is_modded(r.name) then
                a.set_recipe(lookup_base_recipe[r.name])
            end
        end
    end
end

function at_launch()
    local finished_msg = "The rocket is losing control! Was that what those RCUs were for? ...Fine, next time I'll do it right."
    show_message(finished_msg)
    launch_storm(global.rocket_launch_pos.x, global.rocket_launch_pos.y)
    switch_techs()
end

function on_tick(event)
    if global.events[event.tick] ~= nil then
        local e = global.events[event.tick]
        if e == 'launch' then
            at_launch()
        elseif e == 'start_message' then
            at_start()
        end
        global.events[event.tick] = nil
    end
end

function on_rocket_launched(event)
    if event.rocket_silo.name == 'ab-rocket-silo' then
        if event.rocket_silo ~= nil then
            global.rocket_launch_pos = event.rocket_silo.position
        end
        local end_sequence_tick = event.tick + 2 * 60
        global.events[end_sequence_tick] = 'launch'
    end
end

function on_rocket_launch_ordered(event)
    if event.rocket_silo.name == 'ab-rocket-silo' then
        show_message('This looks safe.')
    end
end

function on_beacon_built(event)
    event.created_entity.operable = false
    local inv = event.created_entity.get_module_inventory()
    if inv ~= nil then
        inv.insert({name = 'speed-module', count = 2})
    end
end

function on_beacon_mined(event)
    local inv = event.entity.get_module_inventory()
    if inv ~= nil then
        inv.clear()
    end
end

function on_init()
    global.rocket_launch_pos = {x = 0, y = 0}
    global.end_sequence_tick = 0
    global.events = {}
    global.events[start_message_tick] = 'start_message'

    init_techs()

    on_load()
end

function on_load()
    script.on_event(defines.events.on_tick, on_tick)
    script.on_event(defines.events.on_rocket_launched, on_rocket_launched)
    script.on_event(defines.events.on_rocket_launch_ordered, on_rocket_launch_ordered)
    script.on_event(defines.events.on_built_entity, on_beacon_built, {{filter = 'name', name = 'ab-beacon'}})
    script.on_event(defines.events.on_robot_built_entity, on_beacon_built, {{filter = 'name', name = 'ab-beacon'}})
    script.on_event(defines.events.on_pre_player_mined_item, on_beacon_mined, {{filter = 'name', name = 'ab-beacon'}})
    script.on_event(defines.events.on_robot_pre_mined, on_beacon_mined, {{filter = 'name', name = 'ab-beacon'}})
end

script.on_init(on_init)
script.on_load(on_load)

commands.add_command('fa_launch', nil, at_launch)
