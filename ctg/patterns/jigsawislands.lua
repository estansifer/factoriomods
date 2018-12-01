function JigsawIslands(landratio)
    local lr = landratio or 0.5
    local l = math.sqrt(lr)
    local dirs = {
        {dx = 1, dy = 0},
        {dx = -1, dy = 0},
        {dx = 0, dy = 1},
        {dx = 0, dy = -1}
    }

    local data

    local function key(x, y)
        if x == 0 then
            x = 0
        end
        if y == 0 then
            y = 0
        end

        return x .. '#' .. y
    end

    local function create()
        data = {
            groups = {},
            xy2group = {}
        }

        return data
    end

    local function reload(d)
        data = d
    end

    local choices = {}

    local function which_group(x, y, keys, count)
        local k = key(x, y)

        if data.xy2group[k] == nil then
            if keys == nil then
                keys = {}
                count = 0
            end

            if keys[k] then
                group = {
                    id = (#(data.groups)) + 1,
                    sx = 0,
                    sy = 0,
                    count = 0,
                    done = false
                }
                data.groups[group.id] = group
                return group.id
            end

            keys[k] = true

            local dir = dirs[1 + math.floor(math.random() * 4)]
            if count < 3 and keys[key(x + dir.dx, y + dir.dy)] then
                dir = {dx = -dir.dx, dy = -dir.dy}
            end
            local gid = which_group(x + dir.dx, y + dir.dy, keys, count + 1)
            local group = data.groups[gid]
            group.sx = group.sx + x
            group.sy = group.sy + y
            group.count = group.count + 1
            data.xy2group[k] = gid
            return gid
        end

        return data.xy2group[k]
    end

    local function floodfill(x, y, gid, visited)
        local k = key(x, y)

        if visited[k] == nil then
            visited[k] = true
            gid2 = which_group(x, y)
            if gid == gid2 then
                for _, d in ipairs(dirs) do
                    floodfill(x + d.dx, y + d.dy, gid, visited)
                end
            end
        end
    end

    local function dofloodfill(x, y)
        local gid = which_group(x, y)
        local group = data.groups[gid]
        if not group.done then
            floodfill(x, y, gid, {})
            group.done = true
            -- print ("Group " .. gid .. " has " .. group.count .. " members.")
        end
        return group.count
    end

    local function ingroup(x, y, x_, y_)
        local gid = which_group(x_, y_)
        dofloodfill(x_, y_)

        local group = data.groups[gid]
        if group.count <= 4 then
            return false
        end
        local mx = group.sx / group.count
        local my = group.sy / group.count
        local x__ = math.floor(x + mx * (1 - 1 / l))
        local y__ = math.floor(y + my * (1 - 1 / l))
        return gid == which_group(x__, y__)
    end

    local function get(x, y)
        local x_ = math.floor(x * l)
        local y_ = math.floor(y * l)
        return (ingroup(x, y, x_, y_) or
            ingroup(x, y, x_ + 1, y_ + 1) or
            ingroup(x, y, x_ + 1, y_ - 1) or
            ingroup(x, y, x_ - 1, y_ + 1) or
            ingroup(x, y, x_ - 1, y_ - 1))
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "bool"
    }
end
