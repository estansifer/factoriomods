-- I read like 100 pages about computational fluid dynamics while writing this code
-- and ended up using none of it, I just wanted you to know that.

-- The first version of this code took about 5 minutes to run when you started a new
-- game. Be glad it's been sped up a lot.

-- This behaves like a pattern, in that it has internal data and must be saved/loaded
-- like normal patterns, but 'get' returns a vector

-- Returns a table of functions:
--      create, reload, get
--
-- The result is immutable. It can be reused in multiple patterns.
-- Creating an instance of DistortionMap is computationally intensive, so if you need
-- more than one you would do well to reuse the same one in multiple places.
require("perlin")

function DistortionMap(interpolate_, perlin_, maxstepsize_, integration_time_, k_)
    if interpolate_ == nil then
        local do_interpolate = true
    else
        local do_interpolate = interpolate_
    end
    local perlin = perlin_ or PerlinNoise()

    -- The distortion repeats with a period of N (times wavelength)
    -- Each unit square of Perlin noise is sampled in k x k places,
    -- and then interpolated within those samples.
    local N = perlin.N
    local NN = N * N
    local k = k_ or 6
    local kN = k * N
    local kkNN = k * k * N * N

    -- 1 / 100 for midpoint method seems good
    -- 1 / 8 for RK4
    local maxstepsize = maxstepsize_ or 1 / 8
    local integration_time = integration_time_ or 0.1
    local numsteps = math.ceil(integration_time / maxstepsize)

    -- half of the true stepsize 
    local stepsize_ = (integration_time / numsteps) / 2

    local dh = perlin.dh

    local data

    -- map: (N * k) x (N * k) x 2 array of images of the distortion map
    -- land: infinite 2D array of whether each square is land or water
    --
    -- ix * N + iy gives index corresponding to the integer x,y values (ix, iy)

    local function compute_map(x, y)
        local x0 = x
        local y0 = y

        -- local h = perlin.h(x, y)[1]

        for i = 1, numsteps do
            -- midpoint method, a second-order Runge-Kutta method
            -- local dh1 = dh(x, y)
            -- local dh2 = dh(x - dh1[2] * stepsize_, y + dh1[1] * stepsize_)
            -- x = x - dh2[2] * stepsize_ * 2
            -- y = y + dh2[1] * stepsize_ * 2

            -- RK4
            local dh1 = dh(x, y)
            local dh2 = dh(x - dh1[2] * stepsize_,     y + dh1[1] * stepsize_)
            local dh3 = dh(x - dh2[2] * stepsize_,     y + dh2[1] * stepsize_)
            local dh4 = dh(x - dh3[2] * stepsize_ * 2, y + dh3[1] * stepsize_ * 2)
            x = x - (stepsize_ / 3) * (dh1[2] + 2*dh2[2] + 2*dh3[2] + dh4[2])
            y = y + (stepsize_ / 3) * (dh1[1] + 2*dh2[1] + 2*dh3[1] + dh4[1])

            -- Correct back to the desired contour
            -- For some reason, the following seems to behave really poorly
            -- local hs = perlin.h_and_dh(x, y)
            -- local alpha = (h - hs[1]) / (hs[2] * hs[2] + hs[3] * hs[3])
            -- if alpha == alpha and math.abs(alpha) < 0.1 then
                -- x = x + hs[2] * alpha / 4
                -- y = y + hs[3] * alpha / 4
            -- end
        end
        return {x - x0, y - y0}
    end

    local function sample_distortion_map()
        for i = 0, kN - 1 do
            for j = 0, kN - 1 do
                local a = compute_map(i / k, j / k)
                data.map[i * kN + j] = a[1]
                data.map[kkNN + i * kN + j] = a[2]
            end
        end
    end

    local function interpolate(x, y)
        x = x * k
        y = y * k
        local ix = math.floor(x)
        local iy = math.floor(y)
        x = x - ix
        y = y - iy
        local i = (ix % kN) * kN + (iy % kN)

        local rx = 0
        local ry = 0

        local m = data.map
        rx = rx + m[i]                              * (1 - x) * (1 - y)
        ry = ry + m[i + kkNN]                       * (1 - x) * (1 - y)

        rx = rx + m[(i + kN) % kkNN]                * x * (1 - y)
        ry = ry + m[((i + kN) % kkNN) + kkNN]       * x * (1 - y)

        rx = rx + m[(i + 1) % kkNN]                 * (1 - x) * y
        ry = ry + m[((i + 1) % kkNN) + kkNN]        * (1 - x) * y

        rx = rx + m[(i + kN + 1) % kkNN]            * x * y
        ry = ry + m[((i + kN + 1) % kkNN) + kkNN]   * x * y

        return {rx, ry}
    end

    local function create()
        data = {}
        data.perlin = perlin.create()
        data.map = {}

        sample_distortion_map()

        return data
    end
    
    local function reload(d)
        data = d
        perlin.reload(data.perlin)
    end

    if do_interpolate then
        get = interpolate
    else
        get = compute_map
    end

    return {
        create = create,
        reload = reload,
        get = get
    }
end
