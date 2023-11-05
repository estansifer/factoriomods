meta = {
    -- water_colors    = {"blue", "green"},
    setting_type    = "runtime-global",
    -- List of pairs of name of preset and code to generate preset
    pattern_presets = {
            {"custom", nil},
            {"spiral", "Union(Spiral(1.3, 0.4), Rectangle(-105, -2, 115, 2))"},
            {"arithmetic spiral", "ArithmeticSpiral(50, 0.4)"},
            {"rectilinear spiral", "Zoom(RectSpiral(), 50)"},
            {"triple spiral", "AngularRepeat(Spiral(1.6, 0.5), 3)"},
            {"crossing spirals", "Union(Spiral(1.4, 0.4), Spiral(1 / 2.5, 0.15))"},
            -- {"crossing spirals", "Union(Spiral(1.4, 0.4), Spiral(1 / 1.6, 0.2))"},
            {"coast line 1", "HF(Sum(NoiseExponent{exponent=2.2, start_beach = true}, LuaExpr('x / 150', 'height', false)))"},
            {"coast line 2", "HF(Sum(NoiseExponent{exponent=2.2, start_beach = true}, LuaExpr('1.2 * math.atan(x / 150)', 'height', false)))"},
            -- {"natural", "HF(NoiseExponent{exponent=1.8, start_beach = true})"},
            {"shallow water",
            "HF{pattern=NoiseExponent{exponent=2.2, start_above_area = 0.30, start_below_area = 0.35}," ..
            "areas={DeepWater(),0.02, Water(), 0.05, ShallowishWater(), 0.12, ShallowWater(), 0.2, Land()}}"},
            {"swamp",
            "HF{pattern=NoiseExponent{exponent=1.6, start_above_area = 0.4, start_below_area = 0.45}," ..
            "areas={Water(), 0.005, ShallowishWater(), 0.15, ShallowWater(), 0.4, Land()}}"},
            {"mud flats",
            "HF{pattern=NoiseCustom{exponent=1,start_above_area=0.989,noise=" ..
            "{0,0.01,0.05,1,6,9,3,0,0}}," ..
            "areas={DeepWater(),0.2,Water(),0.6,ShallowishWater(),0.86,ShallowWater(),0.91,Land()}}"},
            {"archipelago",
                -- "NoiseCustom({exponent=1.5,noise={0.3,0.4,1,1,1.2,0.8,0.7,0.4,0.3,0.2},land_percent=0.13})",
                "HF(Max(" ..
                "NoiseCustom{exponent=1.4,noise={0.3,0.4,1,1,1.2,0.8,0.7,0.3,0.2,0.1},zero_percentile=0.93,start_beach=true}," ..
                "NoiseCustom{exponent=2.2,noise={1,1,1,1,1,1,0.7,0.4,0.3,0.2},zero_percentile=0.9,start_above_area=0.75,start_below_area=0.85}))"},
            {"big islands",
                "HF(NoiseCustom{exponent=2.3,noise={1,1,1,1,1,1,0.7,0.4,0.3,0.2},zero_percentile=0.8,start_beach=true})"},
            {"continents",
                "HF(NoiseCustom{exponent=2.4,noise={1,1,1,1,1,1,1,0.6,0.3,0.2},zero_percentile=0.65,start_beach=true})"},
            {"half land",
                "HF(NoiseCustom{exponent=2,noise={0.5,1,1,1,1,1,0.7,0.4,0.3,0.2},start_beach=true})"},
            {"big lakes",
                "HF(NoiseCustom{exponent=2.3,noise={0.5,0.8,1,1,1,1,0.7,0.4,0.3,0.2},zero_percentile=0.35,start_beach=true})"},
            {"medium lakes",
                "HF(NoiseCustom{exponent=2.1,noise={0.3,0.6,1,1,1,1,0.7,0.4,0.3,0.2},zero_percentile=0.14,start_beach=true})"},
            {"small lakes",
                -- "NoiseCustom({exponent=1.8,noise={0.2,0.3,0.4,0.6,1,1,0.7,0.4,0.3,0.2},land_percent=0.96})",
                "HF(NoiseCustom{exponent=1.5,noise={0.05,0.1,0.4,0.7,1,0.7,0.3,0.1},zero_percentile=0.08,start_beach=true})"},
            {"moat",
                "HF{pattern=Sum(NoiseCustom{exponent=2,zero_percentile=0.35,start_above_area=0.4,start_below_area=0.6}, Moat(250, 350, 1.3))}"},
            {"pink noise (good luck...)", "HF(NoiseExponent{exponent=1,zero_percentile=0.65,start_beach=true})"},
            {"Sierpinski carpet", "Sierpinski(6)"},
            {"Hilbert curve", "Hilbert(28, 4)"},
            -- {"Hilbert curve", "Mirrory(Mirrorx(Hilbert(30, 2)))"},
            {"world map", "Zoom(Translate(WorldMap(), -1238, -315), 4)"},
            {"radioactive", "Union(AngularRepeat(Halfplane(), 3), Circle(38))"},
            {"comb", "Zoom(Comb(), 50)"},
            {"cross", "Cross(50)"},
            {"cross and circles", "Union(Cross(20), ConcentricBarcode(30, 60))"},
            {"crossing bars", "Union(Barcode(nil, 10, 20), Barcode(nil, 20, 50))"},
            {"grid", "Zoom(Grid(), 50)"},
            {"skew grid", "Zoom(Affine(Grid(), 1, 1, 1, 0), 50)"},
            {"distorted grid", "Distort(Zoom(Grid(), 30))"},
            {"maze 1 (fibonacci)", "Tighten(Zoom(Maze1(), 50))"},
            {"maze 2 (DLA)", "Tighten(Zoom(Maze2(), 50))"},
            {"maze 3 (percolation)", "Tighten(Zoom(Maze3(0.6), 50))"},
            {"maze 4 (bifurcation)", "Maze4(4, 50)"},
            {"polar maze 3", "Zoom(AngularRepeat(Maze3(), 3), 50)"},
            {"bridged maze 3", "IslandifySquares(Maze3(), 50, 10, 4)"},
            {"thin branching fractal", "Fractal(1.5, 40, 0.4)"},
            {"mandelbrot", "Repeat(Mandelbrot(300), 150, 315, -600, -315)"},
            {"jigsaw islands", "Zoom(JigsawIslands(0.3), 40)"},
            {"pink noise maze",
                "Intersection(Zoom(Maze2(), 50), HF{pattern = NoiseExponent{exponent=1,zero_percentile=0.2,start_beach=true}, heights={False(), 0, True()}})"},
            {"tiny pot holes", "TP(nil, Zoom(Maze3(0.003, false), 2))"},
            {"small pot holes", "TP(nil, Zoom(Maze3(0.006, false), 3))"},
            {"factorio default", "HF{pattern = Elevation(), heights = {DeepWater(), -3, Water(), 0, Land()}}"}
    }
}

function preset_by_name(name)
    for _, item in ipairs(meta.pattern_presets) do
        if item[1] == name then
            return item[2]
        end
    end
    return nil
end

local function map_first(xs)
    local result = {}
    for i, x in pairs(xs) do
        table.insert(result, x[1])
    end
    return result
end

local function mk_bool(name, def)
    return {name, "bool", def}
end
local function mk_str(name, def)
    return {name, "string", def}
end
local function mk_dropdown(name, opts, default)
    if default == nil then
        return {name, "string", opts[1], opts}
    else
        return {name, "string", default, opts}
    end
end
local function mk_int(name, def, range)
    if range == nil then
        return {name, "int", def}
    else
        return {name, "int", def, range}
    end
end

meta.settings = {
    mk_dropdown("pattern-preset", map_first(meta.pattern_presets), "maze 2 (DLA)"),
    mk_str("pattern-custom", "(lua code goes here)"),

    mk_str("pattern-v1", "nil"),
    mk_str("pattern-v2", "nil"),
    mk_str("pattern-v3", "nil"),
    mk_str("pattern-v4", "nil"),
    mk_str("pattern-v5", "nil"),
    mk_str("pattern-v6", "nil"),
    mk_str("pattern-v7", "nil"),
    mk_str("pattern-v8", "nil"),

    -- mk_dropdown("water-color", meta.water_colors),
    mk_int("seed", 0, {0, 2 ^ 32}),

    mk_bool("initial-landfill", false),
    mk_bool("force-initial-water", false),
    mk_bool("big-scan", false),
    mk_bool("screenshot", false),
    mk_bool("screenshot-zoom", false)
}
