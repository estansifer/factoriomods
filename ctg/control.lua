require("metaconfig")
require("evalpattern")
require("screenshot")
require("screenshot_slow")
require("lib/rand")
require("migrations")
require("make_chunk")

local function read_settings()
    local s = {}
    for i, setting in ipairs(meta.settings) do
        local name = setting[1]
        local value = settings.global['ctg-' .. name].value
        s[name] = value
    end
    return s
end

function warn(msg)
    local msg_full = 'CTG mod warning: ' .. msg
    print(msg_full)
    game.print(msg_full)
    -- print(serpent.line(thing))
    -- print(serpent.block(thing))
end

local function create_landfill(event)
    if global.settings['initial-landfill'] then
        local n = (game.item_prototypes['landfill'].stack_size *
            game.entity_prototypes['steel-chest'].get_inventory_size(defines.inventory.chest))
        local chest = game.surfaces[1].create_entity{
            name = 'steel-chest', position = {2, 0}, force = game.forces.player}
        chest.insert{name='landfill', count=n}
    end
end

local function on_load(event)
    if global.enabled and settings.startup['ctg-enable'].value then
        local tp = evaluate_pattern(global.settings)
        tp.reload(global.tp_data)
        register_chunk_callback(tp)
    end
end

local function on_init(event)
    global.enabled = settings.startup['ctg-enable'].value
    if not global.enabled then
        return
    end

    if (game.tick > 1 or global.settings ~= nil) then
        if settings.startup['ctg-remove-default-water'].value then
            warn("This mod should not be enabled when loading a save that did not initially use " ..
                "use it. No more water will be generated on this map!")
        else
            warn("This mod should not be enabled when loading a save that did not initially use it.")
        end
        global.enabled = false
    end
    global.settings = read_settings()

    if global.enabled then
        init_global_rng(global.settings['seed'])

        local tp = evaluate_pattern(global.settings)
        global.tp_data = tp.create()
        register_chunk_callback(tp)
    end

    if global.settings['initial-landfill'] then
        create_landfill(nil)
    end

    if global.settings['big-scan'] then
        local R = 1024
        game.forces.player.chart(game.surfaces[1], {{x = -R, y = -R}, {x = R, y = R}})
    end

    if global.settings['screenshot'] then
        -- takescreenshot(tp.get)
        takescreenshot_slow()
    end

    if global.settings['screenshot-zoom'] then
        takescreenshot(tp.get, 5)
    end
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(migrate_1)
