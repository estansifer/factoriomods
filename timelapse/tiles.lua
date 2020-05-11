require('logger')
require('names')

local append = table.insert

-- local pows = {[0] = 8, 4, 2, 1}
-- local tile_code = {
        -- [0] = 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p'
    -- }


local base32 = {
        [0] = 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
        'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F'
    }

local function encode_water_tiles(x0, y0, water_tiles)
    if #water_tiles == 0 then
        return '1'
    elseif #water_tiles == 1024 then
        return '0'
    else
        local water = {}
        for _, tile in ipairs(water_tiles) do
            local idx = (tile.position.y - y0) * 32 + tile.position.x - x0
            water[idx] = true
        end
        -- Compute RLE, starting with land
        local is_land = true
        local prev_idx = 0
        local rle = {}
        for idx = 0, 1023 do
            if is_land ~= (water[idx] == nil) then
                append(rle, idx - prev_idx)
                prev_idx = idx
                is_land = not is_land
            end
        end
        -- The length of the last segment is computed from how much is missing:
        -- append(rle, 1024 - prev_idx)

        -- Encode the RLE in base 32. Each number can be 1 or 2 digits.
        for i = 1, #rle do
            if rle[i] > 31 then
                rle[i] = '_' .. base32[math.floor(rle[i] / 32)] .. base32[rle[i] % 32]
            else
                rle[i] = base32[rle[i]]
            end
        end
        return table.concat(rle)
    end
end

-- Log all tiles in the range (x, y) to (x + 32, y + 32)
-- Format:
--  x y data

function log_tiles_chunk(x, y)
    -- The search is inclusive of (x, y) and exclusive of (x + 32, y + 32)
    local s = game.surfaces['nauvis']
    local condition = {
            area = {{x, y}, {x + 32, y + 32}},
            collision_mask = 'water-tile'
        }
    local encoding = encode_water_tiles(x, y, s.find_tiles_filtered(condition))

    local out = string.format('%d %d %s', math.floor(x / 32), math.floor(y / 32), encoding)
    write_log(global.logger_tiles_init, out)
end

-- tiles is an array of tables, each of which has an element 'position'
-- Format:
--  [id x y]...
-- where for each tile a triple is given (id, x, y) where x, y is the position
-- and id is a number indicating the name of the new tile
function log_tiles(tiles)
    local s = game.surfaces['nauvis'] 
    local pos, tile

    out = {}
    for _, item in ipairs(tiles) do
        pos = item.position
        tile = s.get_tile(pos)
        append(out, string.format('%d %d %d', name2id(tile.name), pos.x, pos.y))
    end
    if #out > 0 then
        write_log(global.logger_tiles, table.concat(out, ' '))
    end
end
