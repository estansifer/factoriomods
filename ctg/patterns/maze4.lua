require('lib/rand')

-- Based on a novel idea
function Maze4(width, wavelength, max_dist)
    width = width or 4
    local width2 = width * 2
    wavelength = wavelength or 50
    max_dist = max_dist or 10000
    local num_points = math.floor(max_dist * max_dist / wavelength / wavelength)

    local data

    local function random_x()
        return (data.rng() * 2 - 1) * max_dist
    end

    local function add_point(tree, x, y, minx, miny, maxx, maxy)
        if tree[1] then
            if x < tree[2] - width2 then
                i = 4
                maxx = tree[2]
            elseif x > tree[2] + width2 then
                i = 5
                minx = tree[2]
            else
                return
            end
        else
            if y < tree[3] - width2 then
                i = 4
                maxy = tree[3]
            elseif y > tree[3] + width2 then
                i = 5
                miny = tree[3]
            else
                return
            end
        end
        if tree[i] == nil then
            local flag
            if minx == nil or miny == nil or maxx == nil or maxy == nil then
                flag = (data.rng() < 0.5)
            else
                flag = ((maxx - minx) > (maxy - miny))
            end
            tree[i] = {flag, x, y, nil, nil}

        else
            add_point(tree[i], x, y, minx, miny, maxx, maxy)
        end
    end

    local function get_tree(tree, x, y)
        if tree == nil then
            return true
        end
        if tree[1] then
            if x < tree[2] then
                i = 4
            elseif x >= tree[2] + width then
                i = 5
            else
                return (y >= tree[3]) and (y < tree[3] + width)
            end
        else
            if y < tree[3] then
                i = 4
            elseif y >= tree[3] + width then
                i = 5
            else
                return (x >= tree[2]) and (x < tree[2] + width)
            end
        end
        return get_tree(tree[i], x, y)
    end

    local function create()
        data = {
            tree        = {},
            rng         = new_rng()
        }

        data.tree = {data.rng() < 0.5, random_x(), random_x(), nil, nil}
        -- data.tree = {5, 5, nil, nil}

        for i = 1, num_points do
            add_point(data.tree, random_x(), random_x(), nil, nil, nil, nil)
        end

        return data
    end

    local function reload(d)
        data = d
    end

    local function get(x, y)
        return get_tree(data.tree, x, y)
    end

    return {
        create = create,
        reload = reload,
        get = get,
        output = "bool"
    }
end
