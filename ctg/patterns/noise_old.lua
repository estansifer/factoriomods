require("simple")

-- To compute the inverse CDF of the normal distribution, use
-- sqrt(2) * erfinv(2 * x - 1)
local function erfinv(x)
    local l = math.log((1 - x) * (1 + x))
    local t1 = 2 / (math.pi * 0.147) + l / 2
    local res = math.sqrt(-t1 + math.sqrt(t1 * t1 - l / 0.147))
    if x < 0 then
        return -res
    else
        return res
    end
end

local function default(t, k, v)
    if t[k] == nil then
        return v
    else
        return t[k]
    end
end

local function cache_grid(M, w1, w2, power, sigma)
    local grid = {}
    for i = 0, M-1 do
        grid[i] = {}
        for j = 0, M-1 do
            grid[i][j] = 0
        end
    end

    print("Caching...")
    local count = 0
    for wx = 0, M-1 do
        for wy = 0, M-1 do
            w = 2 * math.pi * math.sqrt(wx * wx + wy * wy) / M
            -- There are approximately (w * M) / 4 different choices of (wx, wy)
            -- that give "roughly" the same value of w, meaning within the interval
            -- [w, w + 2 pi / M)
            -- Amplitude is the square root of power
            if w > 0 and w >= w1 and w <= w2 then
                local amp = math.sqrt(power(w) - power(w + 8 * math.pi / (w * M * M)))
                local theta = 2 * math.pi * math.random()
                count = count + 1
                for x = 0, M-1 do
                    for y = 0, M-1 do
                        grid[x][y] = grid[x][y] + amp * math.cos(theta + 2 * math.pi * (wx * x + wy * y) / M)
                    end
                end
                if wx > 0 and wy > 0 then
                    theta = 2 * math.pi * math.random()
                    count = count + 1
                    for x = 0, M-1 do
                        for y = 0, M-1 do
                            grid[x][y] = grid[x][y] + amp * math.cos(theta + 2 * math.pi * (wx * x - wy * y) / M)
                        end
                    end
                end
            end
        end
    end
    print(count)

    -- Normalize the mean to zero (this step should be unnecessary...)
    local s = 0
    for i = 0, M-1 do
        for j = 0, M-1 do
            s = s + grid[i][j]
        end
    end
    s = s / (M * M)
    for i = 0, M-1 do
        for j = 0, M-1 do
            grid[i][j] = grid[i][j] - s
        end
    end

    -- Normalize the variance (i.e., total power) to sigma
    local ss = 0
    for i = 0, M-1 do
        for j = 0, M-1 do
            ss = ss + grid[i][j] * grid[i][j]
        end
    end
    ss = ss / (M * M)
    local f = math.sqrt(sigma / ss)
    for i = 0, M-1 do
        for j = 0, M-1 do
            grid[i][j] = grid[i][j] * f
        end
    end

    print("...done caching")

    return grid
end

-- Given a *decreasing* function func on the interval [x0, x1], find func(x) = value to the specified tolerance
local function binary_search(func, x0, x1, value, dx)
    if value >= func(x0 + dx) then
        return x0
    end
    if func(x1 - dx) >= value then
        return x1
    end

    while (x1 - x0) > dx do
        local xmid = (x0 + x1) / 2
        if func(xmid) > value then
            x0 = xmid
        else
            x1 = xmid
        end
    end
    return (x0 + x1) / 2
end

-- All defults:
--  Noise({
--          land_percent = 0.5,
--          start_on_land = true,
--          start_on_beach = true,
--          power = (must be specified),
--          wavelength_min = 2,
--          wavelength_max = 10000,
--          wave_samples = 20,
--          angular_samples = 7,
--          cache_length = 70
--      })

-- cache_length should not be a multiple of 11

function Noise(options)
    if options == nil then
        options = {}
    end

    local land_percent = default(options, "land_percent", 0.5)
    if land_percent > 0.999 then
        return AllLand()
    end
    if land_percent < 0.001 then
        return NoLand()
    end
    -- For a Gaussian distribution with mean 0 and variance 1, the fraction of
    -- the time it is above thresh equals land_pct.
    local thresh = math.sqrt(2) * erfinv(1 - 2 * land_percent)

    local start_on_land = default(options, "start_on_land", true)
    local start_on_beach = default(options, "start_on_beach", true)
    local power = options["power"]
    local wavelength_min = default(options, "wavelength_min", 2)
    local wavelength_max = default(options, "wavelength_max", 10000)
    local wave_samples = default(options, "wave_samples", 20)
    local angular_samples = default(options, "angular_samples", 7)
    local cache_length = default(options, "cache_length", 70)

    if wavelength_min < 2 then
        wavelength_min = 2
    end
    if wavelength_max > 1000000 then
        wavelength_max = 1000000
    end
    if wavelength_max <= wavelength_min then
        wavelength_max = wavelength_min
        wave_samples = 1
    end
    if wave_samples <= 1 then
        wave_samples = 1
    end
    local w1 = 2 * math.pi / wavelength_max
    local w2 = 2 * math.pi / wavelength_min
    local wmid = 11 * math.pi / cache_length

    local power_total = power(w1) - power(w2)
    local power_high = power(wmid) - power(w2)
    local power_low = power_total - power_high
    print("Power")
    print(power_low)
    print(power_high)

    local data = {}

    local function init_high_freqs()
        data.M1 = cache_length
        data.grid1 = cache_grid(data.M1, wmid, w2, power, power_high / (2 * power_total))
        data.M2 = cache_length + 11
        data.grid2 = cache_grid(data.M2, wmid, w2, power, power_high / (2 * power_total))
    end

    local function init_wavenumber(terms, w)
        local phi0 = math.random() * 2 * math.pi
        for i = 1, angular_samples do
            local wx = 2 * math.pi * w * math.cos(phi0 + math.pi * i / angular_samples)
            local wy = 2 * math.pi * w * math.sin(phi0 + math.pi * i / angular_samples)
            table.insert(terms, {wx, wy, math.random() * 2 * math.pi})
        end
    end

    local function init_low_freqs()
        data.terms = {}

        if wave_samples <= 1 then
            wave_samples = 1
            init_wavenumber(data.terms, w1)
        end

        for i = 1, wave_samples do
            local w = binary_search(power, w1, wmid, power(wmid) + power_low * i / wave_samples, w1 / 100)
            init_wavenumber(data.terms, w)
        end

        data.low_coefficient = math.sqrt(2 * power_low / (power_total * (#(data.terms))))
    end

    -- x, y must be integers
    local function height(x, y)
        local h = 0

        for _, w in ipairs(data.terms) do
            h = h + math.cos(w[1] * x + w[2] * y + w[3])
        end

        return (h * data.low_coefficient +
            data.grid1[x % data.M1][y % data.M1] +
            data.grid2[x % data.M2][y % data.M2])
    end

    local function geti(x, y)
        return height(x, y) > thresh
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    local function verify_ok()
        dh = height(0, 0) - thresh
        if start_on_beach then
            return dh > 0 and dh < 0.1
        end
        if start_on_land then
            return dh > 0
        end
        return true
    end

    local function height_distribution()
        print("Sampling heights")
        local M = 100000
        local s = 0
        local ss = 0
        local h
        local hs = {}
        for i = 1, M do
            h = height(math.random(1000000), math.random(1000000))
            s = s + h
            ss = ss + h * h
            table.insert(hs, h)
        end
        table.sort(hs)
        print("Height distribution:")
        hs[0] = hs[1]
        for i = 0, M, 2000 do
            print(i)
            print(hs[i])
        end
        print(s / M)
        print(ss / M - (s / M) * (s / M))
        print(thresh)
    end

    local function create()
        local num_attempts = 0
        local max_attempts = 1000
        repeat
            if num_attempts % 100 == 0 then
                init_high_freqs()
            end
            init_low_freqs()

            num_attempts = num_attempts + 1
        until verify_ok() or num_attempts >= max_attempts
        print(num_attempts)

        -- height_distribution()

        return data
    end

    local function reload(d)
        data = d
    end

    return {
        create = create,
        reload = reload,
        get = get
    }
end

function NoisePink(options)
    local function power(w)
        return -math.log(w)
    end
    options["power"] = power
    return Noise(options)
end

function NoiseExponent(options)
    local exponent = default(options, "exponent", -0.8)
    if exponent >= 0 then
        return NoisePink(options)
    end

    local function power(w)
        return math.pow(w, exponent)
    end
    options["power"] = power
    return Noise(options)
end

local function sigmoidal(x)
    return 1 + math.atan(x) / math.pi
end

local function mixed_power_sigmoidal(exponent, wmix, sig_amp)
    local function power(w)
        return math.pow(w / wmix, exponent) + sig_amp * sigmoidal(math.log(wmix / w))
    end
    return power
end

function Continents(options)
    local exponent = default(options, "exponent", -0.8)
    local continent_amp = default(options, "continent_amp", 0.5)
    options["power"] = mixed_power_sigmoidal(exponent, 5000, continent_amp)
    return Noise(options)
end
