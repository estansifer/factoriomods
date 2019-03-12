local outfile = 'ctg/rawtext'

local width = 1440
local height = 900

local function write(data, zoom)
    game.write_file(outfile, tostring(width) .. ' ' .. tostring(height) .. ' '
        .. tostring(zoom) .. ' ' .. global.settings['pattern-preset'] .. '\n', true)
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
    code['water'] = '1'
    code['deepwater'] = '2'
    code['water-green'] = '1'
    code['deepwater-green'] = '2'
    code['out-of-map'] = '3'

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
            tile = get_tile(math.floor(x0 + zoom * col), math.floor(y0 + zoom * row))
            if tile == nil then
                data[row][col] = code_nil
            else
                data[row][col] = code[tile]
            end
        end
    end

    write(data, zoom)
end
