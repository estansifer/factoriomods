require "patterns/patterns"

-- This file is no longer needed

--[[
        Configuration (information below)
]]

local watercolor = "blue"

local pattern = Zoom(Maze2(), 32)
-- local pattern = Distort(Distort(Distort(Zoom(Checkerboard(), 16), 64, 1), 32, 0.05), 256, 1)
-- local pattern = Distort(Distort(Distort(Zoom(Checkerboard(), 32), 256, 3.0), 128, 0.4), 64, 0.3)
-- You might want to change the 16 above to a larger number to make it more playable

-- Some fun patterns!:
-- local pattern = SquaresAndBridges(64, 32, 4) -- the most popular pattern, probably
-- local pattern = IslandifySquares(Maze3(), 16, 8, 4)
-- local pattern = Union(Zoom(Cross(), 16), ConcentricCircles(1.3))
-- local pattern = Intersection(Zoom(Maze3(), 32), Zoom(Grid(), 2))
-- local pattern = Distort(Zoom(Comb(), 32))
-- local pattern = Union(Spiral(1.6, 0.6), Intersection(Zoom(Maze3(0.5, false), 8), Zoom(Grid(), 2)))
-- local pattern = Union(Union(Zoom(Maze3(0.25, false), 31), Zoom(Maze3(0.1, false), 97)), Zoom(Maze3(0.6), 11))
-- local pattern = Union(Barcode(10, 5, 20), Barcode(60, 5, 30))
-- local pattern = Union(Zoom(JaggedIslands(0.3), 32), Union(Barcode(0, 6, 50), Barcode(90, 6, 50)))

config = {
    check_for_instant_death = true,
    terrain_pattern     = TerrainPattern(pattern, watercolor)
}

--[[
        In most configurations, you will want to turn resource generation WAY up, probably to
        maximum on all settings, to compensate for the decreased land area and inaccessibility.
        You may want to turn down enemy spawns to compensate for inaccessibility.

        watercolor:
            "blue" or "green"
        
        Patterns (optional arguments show default value)

        barcode
            Barcode(angle = 0, landthickness = 20, waterthickness = 50)
        distort
            Distort(pattern, wavelengths = distort_light)
        islandify
            KroneckerProduct(pattern1, pattern2, sizex, sizey = sizex)
            Islandify(pattern1, pattern1, sizex, sizey = sizex, bridgelenth = 48, bridgewidth = 2)
            SquaresAndBridges(islandradius = 32, bridgelength = 48, bridgewidth = 2)
            CirclesAndBridges(islandradius = 32, bridgelength = 48, bridgewidth = 2)
            IslandifySquares(pattern, islandradius = 32, bridgelength = 48, bridgewidth = 2)
            IslandifyCircles(pattern, islandradius = 32, bridgelength = 48, bridgewidth = 2)
        jaggedislands
            JaggedIslands(landratio = 0.5)
        mandelbrot
            Mandelbrot(sixe = 100)
        maze1
            Maze1()
        maze2
            Maze2()
        maze3
            Maze3(threshold = 0.6, verify = true)
        simple
            AllLand()
            AllWater()
            Square(radius = 32)
            Circle(radius = 32)
            Halfplane()
            Quarterplane()
            Strip(width = 1)
            Cross(width = 1)
            Comb()
            Gridf()
            Checkerboard()
            Spiral(ratio = 1.4, land = 0.5)
            ConcentricCircles(ratio = 1.4, land = 0.5)
        transform
            Zoom(pattern. factor = 16)
            Invert(pattern)
            Union(pattern1, pattern2)
            Intersection(pattern1, pattern2)
            Translate(pattern, dx, dy)
            Rotate(pattern, angle)
            Affine(pattern, a, b, c, d, dx, dy)
            Tile(pattern, xszize, ysize)
            AngularRepeat(pattern, k)
            Jitter(pattern, radius = 10)
            Smooth(pattern, radius = 3) -- too slow, don't use
]]
