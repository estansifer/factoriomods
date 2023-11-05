local outfile = 'ctg/rawtext'

local zoom = 1
local nx = 96
local ny = 96

local width = nx * 32 -- 1920 -- 1440
local height = ny * 32 -- 1080 -- 900

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

function takescreenshot_slow()
    local data = {}
    for row = 1, height do
        data[row] = {}
        for col = 1, width do
            data[row][col] = '0'
        end
    end

    local x0, y0

    x0 = 500
    y0 = 500

    -- x0 = math.floor(-width / 2)
    -- y0 = math.floor(-height / 2)

    local s = game.surfaces['nauvis']

    -- Queue up relevant chunks for charting
    -- No good way to queue up all chunks in an area, instead have
    -- to give position and radius, documentation very unclear

    if zoom < 63 then
        for i = 1, zoom * nx do
            for j = 1, zoom * ny do
                s.request_to_generate_chunks({x0 + 1 + 32 * i, y0 + 1 + 32 * j}, 1)
            end
        end
    else
        for i = 1, width do
            for j = 1, height do
                s.request_to_generate_chunks({x0 + 1 + zoom * i, y0 + 1 + zoom * 32 * j}, 1)
            end
        end
    end

    s.force_generate_chunk_requests()

    if zoom == 1 then
        local condition = {
                area = {{x0 + 1, y0 + 1}, {x0 + width + 1, y0 + height + 1}},
                collision_mask = 'water-tile'
            }
        local tiles = s.find_tiles_filtered(condition)

        for _, tile in ipairs(tiles) do
            data[tile.position.y - y0][tile.position.x - x0] = '1'
        end
    else
        for i = 1, width do
            for j = 1, height do
                local tile = s.get_tile(x0 + 1 + zoom * i, y0 + 1 + zoom * j)
                if tile.collides_with('water-tile') then
                    data[i][j] = '1'
                end
            end
        end
    end

    write(data, zoom)
end
