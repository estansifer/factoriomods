require "lib/union-find"

local append = table.insert

function Maze1()
    -- Small adjustment to connectedness of land. Values from 0 to 1 ok.
    local connectedness = 0.4

    local dirs = {
        {dx = 1, dy = 0},
        {dx = -1, dy = 0},
        {dx = 0, dy = 1},
        {dx = 0, dy = -1}
    }
    local fibs = {1, 2, 3, 5, 8, 13, 21, 34, 55}

    local data
    local values
    local group
    local x1, y1, x2, y2

    local function key(x, y)
        return x .. '#' .. y
    end

    local function assign(x, y, value)
        local k = key(x, y)
        values[k] = value

        for _, d in ipairs(dirs) do
            local k2 = key(x + d.dx, y + d.dy)
            if value == values[k2] then
                group.union(k, k2)
            end
        end
    end

    -- Needs to be called any time these values have been changed
    local function resync()
        data.x1 = x1
        data.y1 = y1
        data.x2 = x2
        data.y2 = y2
    end

    local function create()
        values = {}
        group = UnionFind()
        data = {
            values          = values,
            group_data      = group.data
        }
        x1 = -1
        y1 = -1
        x2 = 0
        y2 = 0
        resync()
        assign(0, 0, true)
        assign(-1, 0, true)
        assign(0, -1, true)
        assign(-1, -1, true)

        return data
    end

    local function reload(d)
        data = d
        values = data.values
        group = UnionFind(data.group_data)
        x1 = data.x1
        y1 = data.y1
        x2 = data.x2
        y2 = data.y2
    end

    local function fibdigits(n, k)
        local ans = {}
        for i = 1, n do
            local f = fibs[n + 1 - i]
            ans[i] = (k >= f)
            if ans[i] then
                k = k - f
            end
        end
        return ans
    end

    local function random(n)
        while n >= #fibs do
            append(fibs, fibs[#fibs] + fibs[#fibs - 1])
        end
        return math.floor(math.random() * fibs[n + 1])
    end

    local function expand()
        local a = {}

        for x = x1, x2 do
            local k = key(x, y1)
            local p = {x = x, y = y1 - 1}
            local b = a[group.get(k)]
            if values[k] == values[key(x - 1, y1)] then
                append(b[#b], p)
            else
                if b == nil then
                    b = {}
                    a[group.get(k)] = b
                end
                append(b, {p})
            end
        end

        for x = x1, x2 do
            local k = key(x, y2)
            local p = {x = x, y = y2 + 1}
            local b = a[group.get(k)]
            if values[k] == values[key(x - 1, y2)] then
                append(b[#b], p)
            else
                if b == nil then
                    b = {}
                    a[group.get(k)] = b
                end
                append(b, {p})
            end
        end

        for y = y1, y2 do
            local k = key(x1, y)
            local p = {x = x1 - 1, y = y}
            local b = a[group.get(k)]
            if values[k] == values[key(x1, y - 1)] then
                append(b[#b], p)
            else
                if b == nil then
                    b = {}
                    a[group.get(k)] = b
                end
                append(b, {p})
            end
        end

        for y = y1, y2 do
            local k = key(x2, y)
            local p = {x = x2 + 1, y = y}
            local b = a[group.get(k)]
            if values[k] == values[key(x2, y - 1)] then
                append(b[#b], p)
            else
                if b == nil then
                    b = {}
                    a[group.get(k)] = b
                end
                append(b, {p})
            end
        end
        
        for k, b in pairs(a) do
            -- db("Group " .. k .. " has " .. #b .. " segments")
            local r
            local positive
            repeat
                positive = not values[k]
                r = {}
                for _, c in ipairs(b) do
                    append(r, random(#c))
                    if r[#r] > 0 then
                        positive = true
                        if not values[k] and math.random() < connectedness then
                            r[#r] = 0
                        end
                    end
                end
            until positive
            for i = 1, #r do
                local c = b[i]
                -- db("  Segment " .. i .. " has " .. #c .. " parts")
                local rr = fibdigits(#c, r[i])
                for j = 1, #c do
                    -- db("    " .. i .. " " .. j .. " " .. c[j].x .. " " .. c[j].y .. " " .. tostring(rr[j]) .. " " .. tostring(rr[j] == values[k]))
                    assign(c[j].x, c[j].y, rr[j] == values[k])
                end
            end
        end

        local v = values
        if (v[key(x1, y1)] == v[key(x1, y1 - 1)]) and (v[key(x1, y1)] == v[key(x1 - 1, y1)]) then
            assign(x1 - 1, y1 - 1, not v[key(x1, y1)])
        else
            assign(x1 - 1, y1 - 1, math.random() < 0.5)
        end
        if (v[key(x1, y2)] == v[key(x1, y2 + 1)]) and (v[key(x1, y2)] == v[key(x1 - 1, y2)]) then
            assign(x1 - 1, y2 + 1, not v[key(x1, y2)])
        else
            assign(x1 - 1, y2 + 1, math.random() < 0.5)
        end
        if (v[key(x2, y1)] == v[key(x2, y1 - 1)]) and (v[key(x2, y1)] == v[key(x2 + 1, y1)]) then
            assign(x2 + 1, y1 - 1, not v[key(x2, y1)])
        else
            assign(x2 + 1, y1 - 1, math.random() < 0.5)
        end
        if (v[key(x2, y2)] == v[key(x2, y2 + 1)]) and (v[key(x2, y2)] == v[key(x2 + 1, y2)]) then
            assign(x2 + 1, y2 + 1, not v[key(x2, y2)])
        else
            assign(x2 + 1, y2 + 1, math.random() < 0.5)
        end

        x1 = x1 - 1
        x2 = x2 + 1
        y1 = y1 - 1
        y2 = y2 + 1
        resync()
    end

    local function geti(x, y)
        k = key(x, y)
        while true do
            v = values[k]
            if v == nil then
                expand()
            else
                return v
            end
        end
    end

    local function get(x, y)
        return geti(math.floor(x + 0.5), math.floor(y + 0.5))
    end

    return {
            create = create,
            reload = reload,
            get = get,
            output = "bool"
        }
end
