-- This is a minimum priority queue; the elements with the lowest priority
-- are popped first.
function PQueue(data)
    local elems = data or {}
    local cur_size = #elems
    local function push(p, x)
        cur_size = cur_size + 1

        local pos = cur_size
        local pos_ = math.floor(pos / 2)
        while pos > 1 do
            if p >= elems[pos_][1] then
                break
            end
            elems[pos] = elems[pos_]
            pos = pos_
            pos_ = math.floor(pos / 2)
        end
        elems[pos] = {p, x}
    end
    local function pop()
        local x = elems[1][2]
        local e = elems[cur_size]
        local p = e[1]
        cur_size = cur_size - 1
        elems[cur_size] = nil -- help the garbage collector

        local pos = 1
        local pos_ = 2 * pos
        while pos_ <= cur_size do
            if pos_ + 1 <= cur_size and elems[pos_ + 1][1] < elems[pos_][1] then
                pos_ = pos_ + 1
            end
            if elems[pos_][1] >= p then
                break
            end
            elems[pos] = elems[pos_]
            pos = pos_
            pos_ = 2 * pos
        end
        elems[pos] = e
        return x
    end
    -- Looks at the least value without popping it
    local function peek()
        return elems[1][2]
    end
    -- First pops a value, then pushes the given value
    local function pop_and_push(p, x)
        local x_ = elems[1][2]

        local pos = 1
        local pos_ = 2 * pos
        while pos_ <= cur_size do
            if pos_ + 1 <= cur_size and elems[pos_ + 1][1] < elems[pos_][1] then
                pos_ = pos_ + 1
            end
            if elems[pos_][1] >= p then
                break
            end
            elems[pos] = elems[pos_]
            pos = pos_
            pos_ = 2 * pos
        end
        elems[pos] = {p, x}
        return x_
    end
    local function size()
        return cur_size
    end
    return {
        push = push,
        pop = pop,
        peek = peek,
        pop_and_push = pop_and_push,
        size = size,
        data = elems -- live access to data for serializing purposes
    }
end
