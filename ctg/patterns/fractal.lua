require("lib/pqueue")
require("lib/rand")

function Fractal(dimension, width, aspect)
    local d = dimension or 1.4
    local w = width or 40
    local a = aspect or 0.4

    local turn = 4
    local drift = 4
    if turn * w * w * a * a / drift > 200 then
        drift = turn * w * w * a * a / 200
    end

    if d > 1.9 then
        d = 1.9
    end

    local data
    local ends

    local init
    local function create()
        ends = PQueue()
        data = {}
        data.rectangles = {}
        data.circles = {}
        data.ends_data = ends.data
        data.rng = new_rng()

        init()
        return data
    end

    local function reload(d)
        data = d
        ends = PQueue(data.ends_data)
    end

    local key_scale = 30

    local function key(x, y)
        return (math.floor(x / key_scale) .. '#' .. math.floor(y / key_scale))
    end

    -- Computes how many branches there should be at a distance of r
    -- from the origin.
    local function branches_needed(r)
        return 4 * ((r / 40) ^ (d - 1)) - 15 * (d - 1)
    end

    -- Choose a random length for a rectangle to be.
    -- We use the Dagum distribution with a = p = 2.
    local function length()
        return w * a * (((data.rng() ^ (-0.5)) - 1) ^ (-0.5))
    end

    -- (x0, y0) and (x1, y1) define a line going down the *center*
    -- of the rectangle, which has a width of w (i.e., w/2 on each side)
    local function add_rectangle(x0, y0, x1, y1)
        local dx = x1 - x0
        local dy = y1 - y0
        local l = math.sqrt((dx * dx) + (dy * dy))
        local c = dx / l
        local s = dy / l

        local rect = {x0 + w * s / 2, y0 - w * c / 2, c, s, l}

        -- Compute bounding box
        local x0_ = math.floor((math.min(x0, x1) - w * math.abs(s) / 2) / key_scale)
        local x1_ = math.floor((math.max(x0, x1) + w * math.abs(s) / 2) / key_scale)
        local y0_ = math.floor((math.min(y0, y1) - w * math.abs(c) / 2) / key_scale)
        local y1_ = math.floor((math.max(y0, y1) + w * math.abs(c) / 2) / key_scale)

        for i = x0_, x1_ do
            for j = y0_, y1_ do
                local k = i .. '#' .. j
                if data.rectangles[k] == nil then
                    data.rectangles[k] = {rect}
                else
                    table.insert(data.rectangles[k], rect)
                end
            end
        end
    end

    local function add_circle(x, y)
        local circ = {x, y}

        local x0_ = math.floor((x - w) / key_scale)
        local x1_ = math.floor((x + w) / key_scale)
        local y0_ = math.floor((y - w) / key_scale)
        local y1_ = math.floor((y + w) / key_scale)

        for i = x0_, x1_ do
            for j = y0_, y1_ do
                local k = i .. '#' .. j
                if data.circles[k] == nil then
                    data.circles[k] = {circ}
                else
                    table.insert(data.circles[k], circ)
                end
            end
        end
    end

    local function extend1(x0, y0, theta)
        local l = length()
        local x1 = x0 + l * math.cos(theta)
        local y1 = y0 + l * math.sin(theta)
        local r = math.sqrt(x1 * x1 + y1 * y1)
        x1 = x1 * (r + drift) / r
        y1 = y1 * (r + drift) / r
        add_rectangle(x0, y0, x1, y1)
        add_circle(x1, y1)
        theta = math.atan2(y1 - y0, x1 - x0)
        return {r + drift, x1, y1, theta}
    end

    local function extend()
        local e = ends.peek()
        if branches_needed(e[1]) > ends.size() then
            -- Two branches
            e1 = extend1(e[2], e[3], e[4] + math.pi * (data.rng() / turn + 1/3))
            e2 = extend1(e[2], e[3], e[4] - math.pi * (data.rng() / turn + 1/3))
            ends.pop_and_push(e1[1], e1)
            ends.push(e2[1], e2)
        else
            -- One branch
            e1 = extend1(e[2], e[3], e[4] + math.pi * (2 * data.rng() - 1) / turn)
            ends.pop_and_push(e1[1], e1)
        end
    end

    -- local function init()
    init = function()
        add_circle(0, 0)
        local theta = 2 * math.pi * data.rng()
        local e = extend1(0, 0, theta)
        ends.push(e[1], e)

        theta = theta + math.pi * (1 + (2 * data.rng() - 1) / (2 * turn))
        e = extend1(0, 0, theta)
        ends.push(e[1], e)
    end

    -- Diffusion vs advection
    -- Diffusion distance scales like w * a * sqrt(t)
    -- Advection distance scales like drift * t
    -- Comparable when t = (w * a / drift) ^ 2
    -- So maximum distance at which diffusion can overcome advection is around
    --      (w * a) ^ 2 / drift

    local function get(x, y)
        local r = math.sqrt(x * x + y * y)
        while r + 5 * turn * turn * w * w * a * a / drift > ends.peek()[1] do
            extend()
        end

        local k = key(x, y)
        if data.circles[k] ~= nil then
            for _, circ in ipairs(data.circles[k]) do
                if ((x - circ[1]) ^ 2 + (y - circ[2]) ^ 2) <= (w * w) / 4 then
                    return true
                end
            end
        end
        if data.rectangles[k] ~= nil then
            for _, rect in ipairs(data.rectangles[k]) do
                local x1 = x - rect[1]
                local y1 = y - rect[2]
                local x2 = rect[3] * x1 + rect[4] * y1
                local y2 = -rect[4] * x1 + rect[3] * y1
                if y2 >= 0 and y2 <= w and x2 >= 0 and x2 <= rect[5] then
                    return true
                end
            end
        end
        return false
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "bool"
    }
end
