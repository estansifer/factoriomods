require('simple')

function Sierpinski(start)
    start = start or 1
    assert(start < 15)
    local dx = math.floor((3 ^ start) / 2)

    local function geti(x, y)
        x = x - dx
        y = y - dx
        if x < 0 then
            x = -x - 1
        end
        if y < 0 then
            y = -y - 1
        end

        while (x > 0) and (y > 0) do
            if (x % 3) == 1 and (y % 3) == 1 then
                return true
            end
            x = math.floor(x / 3)
            y = math.floor(y / 3)
        end
        return false
    end

    local function get(x, y)
        return geti(math.floor(x), math.floor(y))
    end

    return {create = noop, reload = noop, get = get, output = 'bool'}
end
