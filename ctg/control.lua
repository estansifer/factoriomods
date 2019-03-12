require("metaconfig")
require("evalpattern")
require("screenshot")
require("lib/rand")

local get_tile = nil
local force_initial_water = false

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

local function make_chunk(event)
    local gt = get_tile
    local tinsert = table.insert
    if gt == nil then
        warn("Internal error; get_tile undefined.")
        return
    end
    if not global.enabled then
        warn("Internal error; mod is disabled during make_chunk.")
        return
    end

    local surface = event.surface
    if surface.name ~= "nauvis" then
        -- "nauvis" change from EldVarg, to make it compatible with Factorissimo
        return
    end

    local x1 = event.area.left_top.x
    local y1 = event.area.left_top.y
    local x2 = event.area.right_bottom.x
    local y2 = event.area.right_bottom.y

    tiles = {}

    if math.abs(x1) + math.abs(y1) > 70 then
        for x = x1, x2 do
            for y = y1, y2 do
                local new = gt(x, y)
                if new ~= nil then
                    tinsert(tiles, {name = new, position = {x, y}})
                end
            end
        end

    else
        -- Only happens for a few chunks near the origin
        for x = x1, x2 do
            for y = y1, y2 do
                if force_initial_water and ((x - 7) * (x - 7) + y * y < 10) then
                    if global.settings['water-color'] == 'blue' then
                        tinsert(tiles, {name = 'water', position = {x, y}})
                    else
                        tinsert(tiles, {name = 'water-green', position = {x, y}})
                    end
                else
                    if (x * x + y * y > 5) then
                        local new = gt(x, y)
                        if new ~= nil then
                            tinsert(tiles, {name = new, position = {x, y}})
                        end
                    end
                end
            end
        end
    end

    surface.set_tiles(tiles)
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
        force_initial_water = global.settings['force-initial-water']
        local tp = evaluate_pattern(global.settings)
        tp.reload(global.tp_data)
        get_tile = tp.get
        script.on_event(defines.events.on_chunk_generated, make_chunk)
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

        force_initial_water = global.settings['force-initial-water']
        local tp = evaluate_pattern(global.settings)
        global.tp_data = tp.create()
        get_tile = tp.get
        script.on_event(defines.events.on_chunk_generated, make_chunk)
    end

    if global.settings['initial-landfill'] then
        create_landfill(nil)
    end

    if global.settings['big-scan'] then
        local R = 1024
        game.forces.player.chart(game.surfaces[1], {{x = -R, y = -R}, {x = R, y = R}})
    end

    if global.settings['screenshot'] then
        takescreenshot(get_tile)
    end

    if global.settings['screenshot-zoom'] then
        takescreenshot(get_tile, 5)
    end
end

script.on_init(on_init)
script.on_load(on_load)
