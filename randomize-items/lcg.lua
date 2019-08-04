
local a = 1664525
local c = 1013904223
local M = 0x10000
local state = 0

function setseed(seed)
    state = seed
end

-- Returns an integer from 0 to N - 1
function rand(N)
    state = (a * state + c) % M
    return (state % N)
end
