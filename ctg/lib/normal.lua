-- To compute the inverse CDF of the normal distribution, use
-- sqrt(2) * erfinv(2 * x - 1)
function erfinv(x)
    local l = math.log((1 - x) * (1 + x))
    local t1 = 2 / (math.pi * 0.147) + l / 2
    local res = math.sqrt(-t1 + math.sqrt(t1 * t1 - l / 0.147))
    if x < 0 then
        return -res
    else
        return res
    end
end

function normal_invcdf(p)
    return math.sqrt(2) * erfinv(2 * p - 1)
end
