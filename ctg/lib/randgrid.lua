-- Returns a random number from 0 to 1 for each (x, y) spot

local M = math.pow(2, 12)

function RandGrid()
    local data

    local function create()
        data = {}
        data.xr = {}
        data.yr = {}
        data.yk = {}

        return data
    end

    local function reload(d)
        data = d
    end

    local function geti(x, y)
        if data.xr[x] == nil then
            data.xr[x] = math.random()
        end
        if data.yr[y] == nil then
            data.yr[y] = math.random()
            data.yk[y] = math.random(M)
        end
        return (data.xr[x] * data.yk[y] + data.yr[y]) % 1
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    return {
        create = create,
        reload = reload,
        get = get,
        geti = geti
    }
end
