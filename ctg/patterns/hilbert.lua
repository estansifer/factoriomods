require('simple')

function Hilbert(landwidth, waterwidth)
    landwidth = landwidth or 1
    waterwidth = waterwidth or 1

    local rules = {}
    -- A1 = 1, A2 = 2
    -- B1 = 3, B2 = 4, B3 = 5
    -- C1 = 6, C2 = 7, C3 = 8
    -- D1 = 9, D2 = 10
    -- https://en.wikipedia.org/wiki/File:Hilbert_curve_production_rules!.svg

    rules[1] = {{9, 1}, {3, 2}}
    rules[2] = {{9, 1}, {5, 2}}
    rules[3] = {{3, 4}, {1, 6}}
    rules[4] = {{3, 4}, {2, 8}}
    rules[5] = {{3, 4}, {2, 6}}
    rules[6] = {{7,10}, {6, 5}}
    rules[7] = {{7, 9}, {6, 4}}
    rules[8] = {{7,10}, {6, 4}}
    rules[9] = {{1, 7}, {9,10}}
    rules[10]= {{1, 8}, {9,10}}

    local shape = {}
    shape[1] = {{{0, 1}, {1, 0}}, {{1, 1}, {0, 0}}}
    shape[2] = {{{0, 1}, {1, 0}}, {{0, 1}, {0, 0}}}
    shape[3] = {{{1, 1}, {1, 0}}, {{1, 0}, {0, 1}}}
    shape[4] = {{{1, 1}, {1, 0}}, {{0, 0}, {1, 0}}}
    shape[5] = {{{1, 1}, {1, 0}}, {{0, 0}, {0, 1}}}
    shape[6] = {{{1, 1}, {0, 0}}, {{0, 1}, {0, 1}}}
    shape[7] = {{{1, 1}, {0, 1}}, {{0, 1}, {1, 0}}}
    shape[8] = {{{1, 1}, {0, 0}}, {{0, 1}, {1, 0}}}
    shape[9] = {{{1, 0}, {1, 1}}, {{0, 1}, {0, 0}}}
    shape[10]= {{{1, 0}, {1, 0}}, {{0, 1}, {0, 0}}}

    local unit = (landwidth + waterwidth)

    local function get(x, y)
        if (x < 0) or (y < 0) then
            return false
        end

        local px = math.floor(x / unit)
        local py = math.floor(y / unit)
        local dx = x - px * unit
        local dy = y - py * unit

        if (dx < landwidth) and (dy < landwidth) then
            return true
        elseif (dx >= landwidth) and (dy >= landwidth) then
            return false
        end

        local xbits = {}
        local ybits = {}
        while (px > 0) or (py > 0) do
            table.insert(xbits, 1 + (px % 2))
            table.insert(ybits, 1 + (py % 2))
            px = math.floor(px / 2)
            py = math.floor(py / 2)
        end
        if #xbits == 0 then
            xbits[1] = 1
            ybits[1] = 1
        end

        local state
        if (#xbits) % 2 == 0 then
            state = 9
        else
            state = 1
        end

        for i = (#xbits), 2, -1 do
            state = rules[state][xbits[i]][ybits[i]]
        end

        local dir
        if dx > dy then
            dir = 1
        else
            dir = 2
        end
        -- assert((#xbits) > 0)
        -- assert((#ybits) > 0)
        -- assert(xbits[1] == 1 or xbits[1] == 2)
        -- assert(ybits[1] == 1 or ybits[1] == 2)
        -- assert(state >= 1 and state <= 10)
        -- local a = shape[state]
        -- local b = a[xbits[1]]
        -- local c = b[ybits[1]]
        -- local d = c[dir]
        -- return d == 1
        return (shape[state][xbits[1]][ybits[1]][dir]) == 1
    end

    return {create = noop, reload = noop, get = get, output = 'bool'}
end
