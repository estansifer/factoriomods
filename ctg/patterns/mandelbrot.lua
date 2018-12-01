-- Creates a Mandelbrot set
-- The set is bounded within about -size to size/2 along the x-axis,
-- and -1.2 * size to 1.2 * size along the y-axis.
function Mandelbrot(size)
    local s = size or 100
    local maxiter = 100

    local memo = {}

    local function compute(x0, y0)
        x0 = x0 / s
        y0 = y0 / s

        -- As shortcuts, we skip the computation if the point
        -- lies in the main bulbs of periods 1 and 2
        -- https://en.wikipedia.org/wiki/Mandelbrot_set#Main_cardioid_and_period_bulbs
        if (x0 + 1) * (x0 + 1) + y0 * y0 <= 1 / 16 then
            -- period 2 bulb
            return true
        end
        -- Cardiod equation:
        --      r < (1 - cos) / 2    where cos = x / r
        -- Therefore
        --      2r < 1 - x / r
        --      2r^2 < r - x
        --      2r^2 - r + x < 0
        --
        -- Note that x must be shifted by 1/4 because the cardiod is centered at -1/4
        -- Parameter a = 1/4 in the cardiod
        local r2 = (x0 - 1/4) * (x0 - 1/4) + y0 * y0
        if 2 * r2 - math.sqrt(r2) + (x0 - 1/4) < 0 then
            -- period 1 bulb (cardiod)
            -- https://en.wikipedia.org/wiki/Cardioid
            return true
        end

        -- Iterate
        local iter = 0
        local x, y, x_, y_
        x = x0
        y = y0
        while iter < maxiter do
            if x * x + y * y > 4 then
                return false
            end
            x_ = x * x - y * y + x0
            y_ = 2 * x * y + y0
            x = x_
            y = y_
            iter = iter + 1
        end
        return true
    end

    local function geti(x, y)
        if x * x + y * y > 4 * s * s then
            return false
        end
        local key = x .. '#' .. y
        if memo[key] == nil then
            memo[key] = compute(x, y)
        end
        return memo[key]
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    local function create()
        return nil
    end

    local function reload()
        return nil
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "bool"
    }
end
