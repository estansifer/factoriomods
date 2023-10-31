local outfile = 'ctg/rawtext'

local width = 1024 -- 1920 -- 1440
local height = 1024 -- 1080 -- 900

local function write(data, zoom)
    local seed = game.default_map_gen_settings.seed
    -- local o = outfile .. ' ' .. tostring(seed)
    game.write_file(outfile, tostring(width) .. ' ' .. tostring(height) .. ' '
        .. tostring(zoom) .. ' ' .. global.settings['pattern-preset'] .. ' ' ..
        tostring(seed) .. '\n', true)
    local stuff = {}
    for row = 1, height do
        for col = 1, width do
            table.insert(stuff, data[row][col])
        end
        table.insert(stuff, '\n')
    end
    game.write_file(outfile, table.concat(stuff), true)
end

function takescreenshot(get_tile, zoom)
    zoom = zoom or 1

    local code = {}
    local code_nil = '0'
    code['water-shallow'] = '1'
    code['water'] = '2'
    code['deepwater'] = '3'
    code['water-green'] = '2'
    code['deepwater-green'] = '3'
    code['out-of-map'] = '4'

    local data = {}
    for row = 1, height do
        data[row] = {}
    end

    local x0, y0, dx

    x0 = math.floor(-width * zoom / 2)
    y0 = math.floor(-height * zoom / 2)

    local tile

    for row = 1, height do
        for col = 1, width do
            tile = get_tile(x0 + zoom * col, y0 + zoom * row)
            if tile == nil then
                data[row][col] = code_nil
            else
                data[row][col] = code[tile]
            end
        end
    end

    write(data, zoom)
end
