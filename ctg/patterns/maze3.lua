require("lib/rand")

function Maze3(t, v)
    if v == nil then
        v = true
    end

    local max_attempts = 1000
    local initial_range = 100

    -- do not change this number unless you know what you are doing
    -- values greater than 0.59274621 are fine
    -- lower than that is bad
    -- https://en.wikipedia.org/wiki/Percolation_threshold
    local criticalvalue = 0.59274621
    local threshhold = t or 0.6
    local verify = v

    -- Safeguard to make sure we don't try to do the impossible
    if (threshhold < criticalvalue + 0.001) and verify then
        threshhold = 0.6
    end

    local seed = nil

    local function geti(x, y)
        return rand_iii2f(seed, x, y) < threshhold
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    local function floodfill(visited, x, y)
        local n = initial_range
        if x < -n or x > n or y < -n or y > n or visited[x][y] then
            return
        end
        if geti(x, y) then
            visited[x][y] = true
            floodfill(visited, x - 1, y)
            floodfill(visited, x + 1, y)
            floodfill(visited, x, y - 1)
            floodfill(visited, x, y + 1)
        end
    end

    local function verify_ok()
        if not verify then
            return true
        end

        local n = initial_range
        local visited = {}
        for x = -n, n do
            visited[x] = {}
        end
        floodfill(visited, 0, 0)

        local left = false
        local right = false
        local top = false
        local bottom = false

        for i = -n, n do
            left = left or visited[-n][i] 
            right = right or visited[n][i]
            top = top or visited[i][-n]
            bottom = bottom or visited[i][n]
        end

        return left and right and top and bottom
    end

    local function create()
        local num_attempts = 0
        repeat
            seed = rand_i()
            num_attempts = num_attempts + 1
        until verify_ok() or num_attempts >= max_attempts

        return seed
    end

    local function reload(d)
        seed = d
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "bool"
    }
end
