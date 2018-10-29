local permute_bit_reversal = {}
-- N must be a power of 2.
local function precompute_bit_reversal(N)
    if permute_bit_reversal[N] ~= nil then
        return
    end
    local result = {}
    if N == 0 then
        result[0] = 0
    elseif N == 1 then
        result[0] = 0
        result[1] = 1
    else
        precompute_bit_reversal(N / 2)
        local p = permute_bit_reversal[N / 2]
        for i = 0, N - 1 do
            result[i] = p[i % (N / 2)] * 2 + math.floor(i / (N / 2))
        end
    end
    permute_bit_reversal[N] = result
end

-- Permute the elements x[a], x[a + da], ..., x[a + da * (N - 1)].
-- according to the bit reversal of the coefficient multiplying da. N must be a power of 2.
local function bit_reverse(x, a, da, N, scrap)
    if permute_bit_reversal[N] == nil then
        precompute_bit_reversal(N)
    end
    local p = permute_bit_reversal[N]

    for i = 0, N - 1 do
        scrap[p[i]] = x[a + i * da]
    end
    for i = 0, N - 1 do
        x[a + i * da] = scrap[i]
    end
end


-- Computes the FFT of the given data in place.
-- x_1 is the real part of the data, and x_2 is the imaginary part of the data.
-- a is the starting index of the relevant section, and da is the increment
-- from one relevant index to the next. N is the number of relevant indices
-- and must be a power of two.
-- scrap is an array of length at least N for holding temporary data
-- Uses Cooley-Tukey algorithm.
function fft(x1, x2, a, da, N, scrap)

    -- temporary variables
    local t, ta1, ta2, tb1, tb2, idx

    -- Perform bit reversal permutation of input elements.
    bit_reverse(x1, a, da, N, scrap)
    bit_reverse(x2, a, da, N, scrap)

    -- Iterative FFT
    local M = 2
    while M <= N do
        -- wM1 + i wM2 is a primitive Mth-root of unity
        local wM1 = math.cos(-2 * math.pi / M)
        local wM2 = math.sin(-2 * math.pi / M)
        for k = 0, N - 1, M do
            -- w1 + i w2 will run through all the Mth-roots of unity in order
            local w1 = 1
            local w2 = 0
            for j = 0, (M / 2) - 1 do
                idx = a + da * (k + j + (M / 2))

                -- ta = x[k + j]
                ta1 = x1[a + da * (k + j)]
                ta2 = x2[a + da * (k + j)]

                -- tb = w * x[k + j + (M / 2)]
                t = w1 * x1[idx] - w2 * x2[idx]
                tb2 = w1 * x2[idx] + w2 * x1[idx]
                tb1 = t

                -- x[k + j] = ta + tb
                x1[a + da * (k + j)] = ta1 + tb1
                x2[a + da * (k + j)] = ta2 + tb2

                -- x[k + j + (M / 2)] = ta - tb
                x1[idx] = ta1 - tb1
                x2[idx] = ta2 - tb2

                -- w = w * wM
                t = w1 * wM1 - w2 * wM2
                w2 = w1 * wM2 + w2 * wM1
                w1 = t
            end
        end

        M = 2 * M
    end
end

-- If x1 and x2 are N x N arrays, with N a power of two, compute the 2d FFT in place.
-- scrap is an array of length at least N for holding temporary data.
function fft2d(x1, x2, N, scrap)
    for i = 0, N - 1 do
        fft(x1, x2, i, N, N, scrap)
    end
    for i = 0, N - 1 do
        fft(x1, x2, i * N, 1, N, scrap)
    end
end

--[[
local function zeros(N)
    local x = {}
    for i = 0, N - 1 do
        x[i] = 0
    end
    return x
end

print("Testing fft")
local scrap = zeros(16)
local x1 = zeros(16)
local x2 = zeros(16)

x1[0] = 1
fft(x1, x2, 0, 1, 16, scrap)
print('a')
print(serpent.line(x1))
print(serpent.line(x2))

x1 = zeros(16)
x2 = zeros(16)
x1[1] = 1
fft(x1, x2, 0, 1, 16, scrap)
print('b')
print(serpent.line(x1))
print(serpent.line(x2))

x1 = zeros(16)
x2 = zeros(16)
x1[2] = 1
fft(x1, x2, 0, 1, 16, scrap)
print('c')
print(serpent.line(x1))
print(serpent.line(x2))

x1 = zeros(16)
x2 = zeros(16)
x1[13] = 1
fft(x1, x2, 0, 1, 16, scrap)
print('d')
print(serpent.line(x1))
print(serpent.line(x2))
--]]
