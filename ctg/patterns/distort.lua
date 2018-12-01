-- I read like 100 pages about computational fluid dynamics while writing this code
-- and ended up using none of it, I just wanted you to know that.

-- The first version of this code took about 5 minutes to run when you started a new
-- game. Be glad it's been sped up a lot.

require("lib/perlin")
require("lib/distortion_map")

-- I hope this is the last time I have to implement Perlin noise in Lua. I did at
-- least 3 totally different implementations here just trying to get it fast and
-- accurate enough.

-- Using relatively prime (or nearly relatively prime) wavelengths will greatly
-- improve the randomness, which is why all of these are 1 more than a multiple
-- of 10.
distort_light = {
        [21] = 1,
        [51] = 1
    }
distort_heavy = {
        [51] = 1,
        [101] = 0.3,
        [201] = 1,
        [401] = 0.8,
        [1601] = 0.5,
        [5001] = 0.5
    }

distort_default = distort_light

function Distort(pattern, distortion_map, wavelengths)
    local pget = pattern.get
    local dmap = distortion_map or DistortionMap()
    local w = wavelengths or distort_light

    local data

    local function create()
        data = {}
        data.distortion = dmap.create()
        data.pattern = pattern.create()
        return data
    end
    
    local function reload(d)
        data = d
        pattern.reload(data.pattern)
        dmap.reload(data.distortion)
    end

    local function compute(x, y)
        local dx = 0
        local dy = 0
        for wavelength, amp in pairs(w) do
            if amp > 0 then
                local a = dmap.get((x + 10000) / wavelength, (y + 10000) / wavelength)
                dx = dx + a[1] * wavelength * amp
                dy = dy + a[2] * wavelength * amp
            end
        end
        return pget(x + dx, y + dy)
    end

    local function key(x, y)
        return x .. '#' .. y
    end

    local function geti_(x, y)
        local k = key(x, y)
        if data.land[k] == nil then
            data.land[k] = compute(x, y)
        end
        return data.land[k]
    end

    local function geti(x, y)
        return compute(x, y)
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = pattern.output
    }
end
