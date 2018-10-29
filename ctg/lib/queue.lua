function Queue()
    local elems = {}
    local head = 1
    local tail = 1
    local function push(x)
        elems[tail] = x
        tail = tail + 1
    end
    local function pop()
        local value = elems[head]
        elems[head] = nil   -- help the garbage collector
        head = head + 1
        return value
    end
    local function size()
        return tail - head
    end
    return {
        push = push,
        pop = pop,
        size = size
    }
end
