-- I hope this is the last time I have to implement Perlin noise in Lua. I did at
-- least 3 totally different implementations here just trying to get it fast and
-- accurate enough.

-- This behaves like a pattern, in that it has internal data and must be saved/loaded
-- like normal patterns, but it returns a height field (and its derivative)

-- Returns a table of functions:
--      create, reload, h_and_dh, h, dh, N
--
-- The result is immutable. It can be reused in multiple patterns.
-- Creating an instance of PerlinNoise is computationally intensive, so if you need
-- more than one you would do well to reuse the same one in multiple places.
function PerlinNoise(N_)
    -- The distortion repeats with a period of N
    local N = N_ or 47
    local NN = N * N

    local data

    -- rand_vectors: N x N array of unit vectors
    -- noise: N x N x 8 array of numbers
    --      noise[i * N + j] holds four vectors
    -- ix * N + iy gives index corresponding to the integer x,y values (ix, iy)

    local function make_rand_vectors()
        for i = 0, NN-1 do
            local a = math.random() * 2 * math.pi
            data.rand_vectors[i] = {math.cos(a), math.sin(a)}
        end
    end

    local function calculate_noise_coefficients()
        local r = data.rand_vectors
        for i = 0, NN-1 do
            local n = {0, 0, 0, 0, 0, 0, 0, 0}
            n[1] = r[i][1]
            n[2] = r[i][2]
            n[3] = r[(i + N) % NN][1] - r[i][1]
            n[4] = r[(i + N) % NN][2] - r[i][2]
            n[5] = r[(i + 1) % NN][1] - r[i][1]
            n[6] = r[(i + 1) % NN][2] - r[i][2]
            n[7] = r[(i + N + 1) % NN][1] - r[(i + N) % NN][1] - r[(i + 1) % NN][1] + r[i][1]
            n[8] = r[(i + N + 1) % NN][2] - r[(i + N) % NN][2] - r[(i + 1) % NN][2] + r[i][2]
            data.noise[i] = n
        end
    end

    local function smooth(t)
        return t * t * t * (t * (t * 6 - 15) + 10)
    end

    local function dsmooth(t)
        return t * t * (t * (t * 30 - 60) + 30)
    end

    -- returns h(x, y), dh/dx(x, y), and dh/dy(x, y)
    local function h_and_dh(x, y)
        local ix = math.floor(x)
        local iy = math.floor(y)
        x = x - ix
        y = y - iy

        local sx = x*x*x*(x*(x*6-15)+10)
        local sy = y*y*y*(y*(y*6-15)+10)
        local dsx = x*x*(x*(x*30-60)+30)
        local dsy = y*y*(y*(y*30-60)+30)

        local n = data.noise[(ix % N) * N + (iy % N)]
        return {
                (n[1]*x+n[2]*y) +
                (n[3]*x+n[4]*y) * sx +
                (n[5]*x+n[6]*y) * sy +
                (n[7]*x+n[8]*y) * sx * sy,
                n[1] +
                n[3] * sx + (n[3]*x+n[4]*y) * dsx +
                n[5] * sy +
                (n[7] * sx + (n[7]*x+n[8]*y) * dsx) * sy,
                n[2] +
                n[4] * sx +
                n[6] * sy + (n[5]*x+n[6]*y) * dsy +
                (n[8] * sy + (n[7]*x+n[8]*y) * dsy) * sx
            }
    end
    
    -- returns h(x, y)
    local function h(x, y)
        local ix = math.floor(x)
        local iy = math.floor(y)
        x = x - ix
        y = y - iy

        local sx = x*x*x*(x*(x*6-15)+10)
        local sy = y*y*y*(y*(y*6-15)+10)

        local n = data.noise[(ix % N) * N + (iy % N)]
        return ((n[1]*x+n[2]*y) +
                (n[3]*x+n[4]*y) * sx +
                (n[5]*x+n[6]*y) * sy +
                (n[7]*x+n[8]*y) * sx * sy)
    end

    -- returns dh/dx(x, y), and dh/dy(x, y)
    local function dh(x, y)
        local ix = math.floor(x)
        local iy = math.floor(y)
        x = x - ix
        y = y - iy

        local sx = x*x*x*(x*(x*6-15)+10)
        local sy = y*y*y*(y*(y*6-15)+10)
        local dsx = x*x*(x*(x*30-60)+30)
        local dsy = y*y*(y*(y*30-60)+30)

        local n = data.noise[(ix % N) * N + (iy % N)]
        return {
                n[1] +
                n[3] * sx + (n[3]*x+n[4]*y) * dsx +
                n[5] * sy +
                (n[7] * sx + (n[7]*x+n[8]*y) * dsx) * sy,
                n[2] +
                n[4] * sx +
                n[6] * sy + (n[5]*x+n[6]*y) * dsy +
                (n[8] * sy + (n[7]*x+n[8]*y) * dsy) * sx
            }
    end

    local function create()
        data = {}
        data.rand_vectors = {}
        data.noise = {}

        make_rand_vectors()
        calculate_noise_coefficients()

        return data
    end
    
    local function reload(d)
        data = d
    end

    return {
        create = create,
        reload = reload,
        h_and_dh = dh,
        h = h,
        dh = dh,
        N = N
    }
end
