function UnionFind(data)
    local parents = data or {}
    local function get(key)
        p = parents[key]
        if p == nil or p == key then
            return key
        else
            root = get(p)
            parents[key] = root
            return root
        end
    end
    local function set(key, newroot)
        p = parents[key]
        parents[key] = newroot
        if not (p == nil or p == key) then
            set(p, newroot)
        end
    end
    local function union(k1, k2)
        set(k2, get(k1))
    end
    local function same(k1, k2)
        return get(k1) == get(k2)
    end
    return {
        get = get,
        union = union,
        same = same,
        data = parents -- live access to data for serializing purposes
    }
end
