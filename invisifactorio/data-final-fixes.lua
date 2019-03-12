local function not_vis(name)
    return (settings.startup['invisifactorio-' .. name].value ~= "Visible")
end

local function f(x, y)
    return ("__invisifactorio__/graphics/empty" .. tostring(x) .. "x" .. tostring(y) .. ".png")
end

local function rep(x, n)
    local t = {}
    for i = 1,n do
        table.insert(t, x)
    end
    return t
end

local function pkeys(t)
    local k = {}
    for a, b in pairs(t) do
        table.insert(k, a)
    end
    print(serpent.block(k))
end

--[[
local function sub(x)
    print(x)
    pkeys(data.raw[x])
end

local function subs(x,y)
    print(x .. '.' .. y)
    print(serpent.block(data.raw[x][y]))
end
]]

if not_vis('trains') then
    data.raw['locomotive']['locomotive'].color.a = 0
    data.raw['cargo-wagon']['cargo-wagon'].color.a = 0
    data.raw['fluid-wagon']['fluid-wagon'].color.a = 0

    local trains = {'locomotive', 'cargo-wagon', 'fluid-wagon'}
    for _, train in pairs(trains) do
        local w = data.raw[train][train].wheels
        w.filenames = rep(f(920, 1840), 2)
        w.hr_version.filenames = rep(f(916, 1816), 8)
    end

    local a = data.raw['locomotive']['locomotive'].pictures.layers

    a[1].filenames = rep(f(952, 1840), 8)
    a[2].filenames = rep(f(944, 1824), 8)
    a[3].filenames = rep(f(1012, 1696), 8)
    a[1].hr_version.filenames = rep(f(1896, 1832), 16)
    a[2].hr_version.filenames = rep(f(1888, 1824), 16)

    a = data.raw['cargo-wagon']['cargo-wagon']

    local b = a.pictures.layers
    b[1].filenames = rep(f(888, 1640), 4)
    b[2].filenames = rep(f(784, 1914), 3)
    b[2].filenames[3] = f(784, 1740)
    b[3].filenames = rep(f(984, 1608), 4)
    b[1].hr_version.filenames = rep(f(1768, 3256), 4)
    b[2].hr_version.filenames = rep(f(1624, 4081), 3)
    b[2].hr_version.filenames[3] = f(1624, 3710)
    b[3].hr_version.filenames = rep(f(1960, 3208), 4)

    b = a.horizontal_doors.layers
    b[1].filename = f(220, 264)
    b[2].filename = f(186, 304)
    b[3].filename = f(182, 280)
    b[4].filename = f(185, 224)
    b[5].filename = f(185, 184)
    b[1].hr_version.filename = f(438, 504)
    b[2].hr_version.filename = f(368, 608)
    b[3].hr_version.filename = f(320, 552)
    b[4].hr_version.filename = f(369, 432)
    b[5].hr_version.filename = f(369, 360)

    b = a.vertical_doors.layers
    b[1].filename = f(240, 202)
    b[2].filename = f(536, 169)
    b[3].filename = f(448, 163)
    b[4].filename = f(256, 168)
    b[5].filename = f(256, 166)
    b[1].hr_version.filename = f(464, 401)
    b[2].hr_version.filename = f(1016, 337)
    b[3].hr_version.filename = f(896, 326)
    b[4].hr_version.filename = f(512, 337)
    b[5].hr_version.filename = f(512, 332)

    a = data.raw['fluid-wagon']['fluid-wagon'].pictures.layers
    a[1].filenames = rep(f(832, 1680), 4)
    a[1].hr_version.filenames = rep(f(1664, 1676), 8)
    a[2].filenames = rep(f(1004, 1504), 4)
    a[2].hr_version.filenames = rep(f(2004, 1875), 7)
    a[2].hr_version.filenames[7] = f(2004, 750)
end

if false and not_vis('biters') then
    local biters = {'small-biter', 'medium-biter', 'big-biter', 'behemoth-biter'}
    local spitters = {'small-spitter', 'medium-spitter', 'big-spitter', 'behemoth-spitter'}

    for _, biter in pairs(biters) do
        local b = data.raw['unit'][biter]
        local a = b.attack_parameters.animation.layers
        a[1].stripes[1].filename = f(1674, 1472)
        a[1].stripes[2].filename = f(1395, 1472)
        a[1].stripes[3].filename = f(1674, 1472)
        a[1].stripes[4].filename = f(1395, 1472)
        a[2].filename = f(1375, 1728)
        a[3].filename = f(1254, 1600)
        a = b.run_animation.layers
        a[1].stripes[1].filename = f(1352, 1824)
        a[1].stripes[2].filename = f(1352, 1824)
        a[2].filename = f(1680, 1296)
        a[3].filename = f(1520, 1296)
    end

    for _, spitter in pairs(spitters) do
        local s = data.raw['unit'][spitter]
        local a = s.attack_parameters.animation.layers
        a[1].stripes[1].filename = f(1592, 1312)
        a[1].stripes[2].filename = f(1592, 1312)
        a[1].stripes[3].filename = f(1194, 1312)
        a[1].stripes[4].filename = f(1592, 1312)
        a[1].stripes[5].filename = f(1592, 1312)
        a[1].stripes[6].filename = f(1194, 1312)
        a[2].stripes[1].filename = f(1188, 1440)
        a[2].stripes[2].filename = f(1188, 1440)
        a = s.run_animation.layers
        a[1].stripes[1].filename = f(1544, 1312)
        a[1].stripes[2].filename = f(1544, 1312)
        a[1].stripes[3].filename = f(1544, 1312)
        a[1].stripes[4].filename = f(1544, 1312)
        a[1].stripes[5].filename = f(1544, 1312)
        a[1].stripes[6].filename = f(1544, 1312)
        
    end
end

if not_vis('items') then
    local file = nil
    if settings.startup['invisifactorio-items'].value == "Fish" then
        file = "__base__/graphics/icons/fish.png"
    else
        file = f(32, 32)
        data.raw['utility-sprites'].default['entity_info_dark_background'].filename = f(53, 53)
    end
    local cats = {'item', 'item-with-entity-data', 'fluid',
        'blueprint', 'blueprint-book', 'deconstruction-item',
        'ammo', 'gun', 'tool', 'armor', 'capsule', 'mining-tool',
        'repair-tool', 'module', 'rail-planner', 'recipe'}
    for _, cat in pairs(cats) do
        for _, item in pairs(data.raw[cat]) do
            if item.icon ~= nil then
                item.icon = file
            end
            if item.icons ~= nil then
                item.icons = nil
                item.icon = file
            end
        end
    end
    data.raw.item.coal.dark_background_icon = nil
end

--[[
-- This doesn't work, it makes the game complain about missing images
if is_invis('belts') then
    local cats = {'transport-belt', 'underground-belt', 'splitter'}
    local keys = {'animations', 'belt_horizontal', 'belt_vertical',
        'circuit_connector_sprites', 'connector_frame_sprites',
        'ending_bottom', 'ending_patch', 'ending_side', 'ending_top',
        'starting_bottom', 'starting_side', 'starting_top'}
    for _, cat in pairs(cats) do
        for _, belt in pairs(data.raw[cat]) do
            for _, key in pairs(keys) do
                belt[key] = nil
            end
        end
    end
end
]]
