require("simple")
require("lib/fft")
require("lib/rand")
require("lib/normal")

local tau = 2 * math.pi

local function default(t, k, v)
    if t == nil or t[k] == nil then
        return v
    else
        return t[k]
    end
end

local function randomize_phases(schema, wmin, wmax, rng)
    local thetass = {}
    for idx = 1, #(schema[1]) do
        local inner = schema[1][idx]
        local outer = schema[2][idx]
        local M = schema[3][idx]
        local zoom = schema[4][idx]
        local extended = schema[5][idx]

        local thetas = {}

        for wx = 0, outer - 1 do
            for wy = 0, outer - 1 do
                local w = tau * math.sqrt(wx * wx + wy * wy) / (M * zoom)
                if (w > 0 and w >= wmin and w <= wmax and
                    (extended or (wx >= inner) or (wy >= inner))) then
                    table.insert(thetas, tau * rng())
                    if wx > 0 and wy > 0 and 2 * wy < M then
                        table.insert(thetas, tau * rng())
                    end
                end
            end
        end
        thetass[idx] = thetas
    end
    return thetass
end

local function compute_grid(schema, idx, phasess, wmin, wmax, power)
    local inner = schema[1][idx]
    local outer = schema[2][idx]
    local M = schema[3][idx]
    local zoom = schema[4][idx]
    local extended = schema[5][idx]
    local phases = phasess[idx]
    local MM = M * M
    local grid = {}
    local grid_imag = {}
    local grid_dx = {}
    local grid_dy = {}
    local grid_dxy = {}
    local scrap = {}
    for i = 0, MM - 1 do
        grid[i] = 0
        grid_imag[i] = 0
        grid_dx[i] = 0
        grid_dy[i] = 0
        grid_dxy[i] = 0
    end

    local w, dw, amp, theta
    local i = 1
    for wx = 0, outer - 1 do
        for wy = 0, outer - 1 do
            w = tau * math.sqrt(wx * wx + wy * wy) / (M * zoom)
            if (w > 0 and w >= wmin and w <= wmax and
                (extended or (wx >= inner) or (wy >= inner))) then
                -- The (wx, wy) lattice point represents a square in the frequency
                -- plane with a side length of 2 pi / (M zoom), so has area that squared.
                -- Then divide by the Jacobian 2 pi w to convert to polar coordinates,
                -- since power(w) gives the total power of frequency above w.
                -- Take the square root to go from power to amplitude.
                -- dw = tau / (w * MM * zoom * zoom)
                -- amp = math.sqrt(power(w - (dw / 2)) - power(w + (dw / 2)))
                amp = math.sqrt(power(w) * tau / w) / (M * zoom)
                theta = phases[i]
                i = i + 1
                grid[wx * M + wy] = amp * math.cos(theta)
                grid_imag[wx * M + wy] = amp * math.sin(theta)

                if wx > 0 and wy > 0 and 2 * wy < M then
                    theta = phases[i]
                    i = i + 1
                    grid[wx * M + (M - wy)] = amp * math.cos(theta)
                    grid_imag[wx * M + (M - wy)] = amp * math.sin(theta)
                end
            end
        end
    end

    fft2d(grid, grid_imag, M, scrap)

    -- Normalize the mean
    local s = 0
    for i = 0, MM - 1 do
        s = s + grid[i]
    end
    s = s / MM
    for i = 0, MM - 1 do
        grid[i] = grid[i] - s
    end

    -- Calculate differences for linear interpolation
    for x = 0, M - 1 do
        for y = 0, M - 1 do
            local a, b, c, d
            a = grid[x * M              + y]
            b = grid[((x + 1) % M) * M  + y]
            c = grid[x * M              + (y + 1) % M]
            d = grid[((x + 1) % M) * M  + (y + 1) % M]
            grid_dx[x * M + y] = b - a
            grid_dy[x * M + y] = c - a
            grid_dxy[x * M + y] = a + d - b - c
        end
    end

    return {grid, grid_dx, grid_dy, grid_dxy}
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

local function make_grid_schema(wmin)
    local function inner(i)
        return 8
    end
    local function outer(i)
        return default({128, 32}, i, 32)
    end
    local function M(i)
        return 256
    end
    local inners = {inner(1)}
    local outers = {outer(1)}
    local Ms = {M(1)}
    local zooms = {1}
    local extended = {false}

    -- A grid covers a (rectangular) annular region of the frequency space
    -- with an inner radius of
    --      tau * (inner - 0.5) / (M * zoom)
    -- and outer radius of
    --      tau * (outer + 0.5) / (M * zoom)
    -- We want the outer radius of the next grid to equal the inner radius
    -- of the previous grid.
    local function grid_wmin(i)
        return tau * (inners[i] - 0.5) / (Ms[i] * zooms[i])
    end
    local function grid_wmax(i)
        return tau * (outers[i] - 0.5) / (Ms[i] * zooms[i])
    end

    while grid_wmin(#Ms) > 1.05 * wmin do
        local n = #Ms
        table.insert(inners, inner(n + 1))
        table.insert(outers, outer(n + 1))
        table.insert(Ms, M(n + 1))
        table.insert(zooms, tau * (outer(n + 1) - 0.5) / (M(n + 1) * grid_wmin(n)))
        table.insert(extended, false)
    end

    extended[#extended] = true

    return {inners, outers, Ms, zooms, extended}
end

-- All defults:
--  Noise({
--          power = (must be specified),
--          wavelength_min = 2,
--          wavelength_max = 10000
--      })
--
-- "power" is a function that takes a frequency and returns the power at that
-- frequency. If F(w) is the total power at all frequencies less than or equal to
-- w, then "power" is the derivative of F *with respect to w*.
--
-- Multiplying "power" by a constant has no effect.

function Noise(options)
    if options == nil then
        options = {}
    end

    local mean = default(options, 'mean', 0)
    local stddev = default(options, 'stddev', 1)
    assert(stddev > 0)
    if options.zero_percentile ~= nil then
        local zp = options.zero_percentile
        assert(zp > 0.01)
        assert(zp < 0.99)
        mean = -normal_invcdf(zp) * stddev
    end

    if options.start_beach == true then
        if options.zero_percentile == nil then
            options.start_above_area = 0.5
            options.start_below_area = 0.55
        else
            options.start_above_area = math.min(options.zero_percentile, 0.97)
            options.start_below_area = math.min(options.zero_percentile + 0.05, 0.99)
            -- print('A', options.start_below_area, options.start_above_area)
        end
    end

    if options.start_above_area ~= nil then
        assert(options.start_above_area > 0)
        assert(options.start_above_area < 0.99)
        options.start_above = mean + stddev * normal_invcdf(options.start_above_area)
    end
    if options.start_below_area ~= nil then
        assert(options.start_below_area > 0.01)
        assert(options.start_below_area < 1)
        options.start_below = mean + stddev * normal_invcdf(options.start_below_area)
        if options.start_above_area ~= nil then
            -- print('B', options.start_below_area, options.start_above_area, stddev)
            assert(options.start_above_area + stddev * 0.009 < options.start_below_area)
        end
    end

    local start_above = default(options, "start_above", mean - 99)
    local start_below = default(options, "start_below", mean + 99)
    assert(start_above < mean + stddev * 3.5)
    assert(start_below > mean - stddev * 3.5)
    assert(start_above + stddev * 0.009 < start_below)

    local wavelength_min = default(options, "wavelength_min", 2)
    local wavelength_max = default(options, "wavelength_max", 10000)
    local power = options["power"]

    if wavelength_min < 2 then
        wavelength_min = 2
    end
    if wavelength_max > 1000000 then
        wavelength_max = 1000000
    end
    if wavelength_max <= 10 * wavelength_min then
        wavelength_max = 10 * wavelength_min
    end

    local wmin = tau / wavelength_max
    local wmax = tau / wavelength_min

    local grid_schema = make_grid_schema(wmin)
    local Ms = grid_schema[3]
    local zooms = grid_schema[4]
    local ngrids = #Ms
    -- print(serpent.block(grid_schema))

    local griddata = {}
    griddata.grids = {}
    griddata.grids_dx = {}
    griddata.grids_dy = {}
    griddata.grids_dxy = {}
    griddata.variances = {}

    local data = {}

    local function make_grid(i)
        print("Making grid")
        local res = compute_grid(grid_schema, i, data.phasess, wmin, wmax, power)
        local v = 0
        for j = 0, (Ms[i] * Ms[i]) - 1 do
            v = v + res[1][j] * res[1][j]
        end
        griddata.variances[i] = v / (Ms[i] * Ms[i])
        griddata.grids[i] = res[1]
        griddata.grids_dx[i] = res[2]
        griddata.grids_dy[i] = res[3]
        griddata.grids_dxy[i] = res[4]
    end

    local function compute_stddev()
        local v = 0
        for i = 1, ngrids do
            v = v + griddata.variances[i]
        end

        griddata.stddev = math.sqrt(v)
        print("Variances and stddev")
        print(serpent.line(griddata.variances))
        print(griddata.stddev)
    end

    local function build_data()
        for i = 1, ngrids do
            make_grid(i)
        end
        compute_stddev()
    end

    local function randomize_starting_square(rng)
        data.dx = math.floor(rng() * 1000000)
        data.dy = math.floor(rng() * 1000000)
    end

    local function init(rng)
        data.phasess = randomize_phases(grid_schema, wmin, wmax, rng)
        randomize_starting_square(rng)
        build_data()
    end

    -- local function remake_some_grids(count)
        -- for i = 1, ngrids do
            -- if (count % (1 + 3 * (ngrids - i))) == 0 then
                -- make_grid(i)
            -- end
        -- end
        -- compute_stddev()
    -- end

    -- x, y must be integers
    local function geti(x, y)
        x = x + data.dx
        y = y + data.dy
        local h = 0
        local z, j, dx, dy, M

        -- for i = n1, n2 do
        for i = 1, ngrids do
            z = zooms[i]
            M = Ms[i]
            if z == 1 then
                h = h + griddata.grids[i][(x % M) * M + (y % M)]
            else
                j = (math.floor(x / z) % M) * M + math.floor(y / z) % M
                dx = (x / z) % 1
                dy = (y / z) % 1
                h = (h
                    + griddata.grids[i][j]
                    + griddata.grids_dx[i][j] * dx
                    + griddata.grids_dy[i][j] * dy
                    + griddata.grids_dxy[i][j] * dx * dy)
            end
        end

        return mean + h * stddev / griddata.stddev
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    local function verify_ok()
        local h = geti(0, 0)
        return (h > start_above) and (h < start_below)
    end

    local function height_distribution()
        print("Sampling heights")
        local rng = new_rng()
        local M = 100000
        local s = 0
        local ss = 0
        local h
        local hs = {}
        for i = 1, M do
            h = height(rng(1000000), rng(1000000))
            s = s + h
            ss = ss + h * h
            table.insert(hs, h)
        end
        table.sort(hs)
        print("Height distribution:")
        hs[0] = hs[1]
        for i = 0, M, 4000 do
            print(i)
            print(hs[i])
        end
        print(s / M)
        print(ss / M - (s / M) * (s / M))
    end

    local function create()
        local rng = new_rng()
        init(rng)
        local num_attempts = 1
        local max_attempts = 10000
        repeat
            if num_attempts > 500 then
                start_below = start_below + 0.01
                start_above = start_above - 0.01
            end
            if num_attempts % 1000 == 0 then
                init(rng)
            else
                randomize_starting_square(rng)
            end
            num_attempts = num_attempts + 1
        until verify_ok() or num_attempts >= max_attempts
        print("Number of re-rolls:")
        print(num_attempts)

        -- height_distribution()

        return data
    end

    local function reload(d)
        data = d
        build_data()
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "height"
    }
end

function NoiseExponent(options)
    if options == nil then
        options = {}
    end

    local exponent = default(options, "exponent", 1.8)
    if exponent <= 1 then
        exponent = 1
    end
    local function power(w)
        return math.pow(w, -exponent)
    end
    options["power"] = power
    return Noise(options)
end

-- The "noise" array gives a relative amplitude for noise of various frequencies,
-- with the first element corresponding to a wavelength of sqrt(10), and each
-- successive element corresponding to a wavelength sqrt(10) times larger.
function NoiseCustom(options)
    if options == nil then
        options = {}
    end
    local exponent = default(options, "exponent", 1.8)
    local noise = default(options, "noise", {1, 1, 1, 1, 1, 1, 0.7, 0.4, 0.3, 0.2})
    if #noise < 1 then
        noise = {1}
    end
    table.insert(noise, 0)

    local logws = {math.log(tau) - 0.5 * math.log(10)}
    while #logws < #noise do
        table.insert(logws, logws[#logws] - 0.5 * math.log(10))
    end
    local n = #logws

    local function power(w)
        local logw = math.log(w)
        if logw >= logws[1] then
            return math.pow(w, -exponent) * noise[1]
        elseif logw <= logws[n] then
            return math.pow(w, -exponent) * noise[n]
        else
            for i = 1, n - 1 do
                if logw <= logws[i] and logw >= logws[i + 1] then
                    return math.pow(w, -exponent) * (noise[i+1] +
                        (noise[i] - noise[i+1]) * (logw - logws[i+1]) / (logws[i] - logws[i+1]))
                end
            end
        end
    end
    options["power"] = power
    return Noise(options)
end
