# Custom Terrain Generation

a [Factorio](http://factorio.com) mod by Eric Stansifer

Hosted at `https://github.com/estansifer/factoriomods/`

This mod is a customizable, algebraic terrain generator that alters the distribution of
land, water, and void cells at the start of a new game.

A wide variety of terrain generation algorithms are included, as well as the ability
to combine them in many ways or write your own algorithm.

 * Version 0.5.0
 * Initial release: 2016-03-15
 * Current release: 2023-11-04

## Important notes

 * This mod remembers all runtime settings on a per-save basis. Only the settings enabled
 when the game is first begun matter.
 * Don't enable this mod on a game partway through.
 * It is hard to thoroughly test the accuracy of the many possible settings, especially
 for saving / loading, so please let me know if you encounter any bugs so I can fix
 them as quickly as possible.
 * Version changes for this mod may introduce breaking changes.
 * If you plan on investing a lot of time on a randomly-generated map, you may interested
 in the testing features that let you preview a large area of the map so that you can
 re-roll the starting map if it is bad. See below for details.
 * Many of the default patterns use a lot of water or make navigating hard. You may want to
 greatly turn up resource generation to compensate.

## Screenshots

 Also, [old screenshots](https://imgur.com/a/C2pFsf8)

 Also, [very old screenshots](https://imgur.com/a/wptLh).

## How to use

By default, the mod creates a maze. The `Terrain preset` option gives a large list
of other patterns that have been given as examples. Screenshots of each of these can be
found above.

 * All of the presets are designed to place water near the starting location, but you may
 wish to use a custom pattern that does not. In this case, the `Force starting water` option
 puts a puddle next to your starting location to make the game playable.
 * You may wish to enable the "landfill chest" option which gives you a very large amount
 of landfill at the beginning. If you spawn near a good location but are blocked by water,
 you can use it to get there, and then throw away what you didn't need.

### Scanning options

 * `Big scan` scans everything within 1024 of your starting location; it takes several minutes
 to finish. For computationally expensive patterns, the game may be laggy while this is
 happening.
 * `Take screenshot` saves a textfile describing the terrain near the origin; this will
 cause a delay of several seconds before the game begins. (For the jagged islands pattern
 and a zoomed screenshot, this can be a significantly greater time.) A python script is included
 that turns this text output into an image of the surrounding terrain, in a 1440 x 900 region
 centered on the origin (each pixel is one tile). The zoomed screenshot zooms out by a factor of
 5. If you plan on investing a lot of time on a random map, you may wish to do this to make sure
 your map is reasonable before you begin the game.

### Going beyond just land and water

Most of the patterns just control where land and water is placed. For this reason, by default
the mod suppresses Factorio's built-in water generation.

However, you may want to do other things, like use this mod to scatter random void cells, or
put a concrete road running along the x-axis, but still use Factorio's built-in water
generation. If so, check the relevant start up option. When this mod "places land", what it
actually does is leave the tile however Factorio generated it. You can place specific land tiles with patterns like `Constant('grass-4')` or `Constant('nuclear-ground')` etc.

### Void cells

Void cells are black squares that are impassable and cannot be landfilled. To generate void cells,
use the `custom` option as described in the next section, and use the pattern

    TP(landpattern, voidpattern)

where landpattern is a pattern that specifies land placement, and voidpattern is a pattern that
specifies void placement. (`TP` stands for `terrain pattern`.) If water and void coincide, void will be placed.

If you would like this mod to generate void cells, but generate water through Factorio's built-in
water generation settings, then use the pattern

    TP(nil, voidpattern)

and uncheck the option "remove default water" in the startup settings.

## Custom patterns

If you don't want to use a preset, you can specify the `custom` option and write your
own pattern. If your terrain pattern uses more than one line of lua code, you use variables called
`v1` through `v8` for convenience (since the text box is tiny to type in).

### Examples

Here is a list of every preset and the code used to generate it.

Spirals:

    {"spiral", "Union(Spiral(1.3, 0.4), Rectangle(-105, -2, 115, 2))"},
    {"arithmetic spiral", "ArithmeticSpiral(50, 0.4)"},
    {"rectilinear spiral", "Zoom(RectSpiral(), 50)"},
    {"triple spiral", "AngularRepeat(Spiral(1.6, 0.5), 3)"},
    {"crossing spirals", "Union(Spiral(1.4, 0.4), Spiral(1 / 2.5, 0.15))"},

Next are various kind of natural looking land masses that resemble vanilla terrain generation.

Coast line as an infinite ocean to the west. The second variation will have some small lakes to the east and islands to the west, the first does not.

    {"coast line 1", "HF(Sum(NoiseExponent{exponent=2.2, start_beach = true}, LuaExpr('x / 150', 'height', false)))"},
    {"coast line 2", "HF(Sum(NoiseExponent{exponent=2.2, start_beach = true}, LuaExpr('1.2 * math.atan(x / 150)', 'height', false)))"},

A few patterns that use mud / shallow water.

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

Archipelago has larger land masses scattered with many tiny islands, and usually starts you on one of the smaller islands, forcing you to migrate early.

    {"archipelago",
        -- "NoiseCustom({exponent=1.5,noise={0.3,0.4,1,1,1.2,0.8,0.7,0.4,0.3,0.2},land_percent=0.13})",
        "HF(Max(" ..
        "NoiseCustom{exponent=1.4,noise={0.3,0.4,1,1,1.2,0.8,0.7,0.3,0.2,0.1},zero_percentile=0.93,start_beach=true}," ..
        "NoiseCustom{exponent=2.2,noise={1,1,1,1,1,1,0.7,0.4,0.3,0.2},zero_percentile=0.9,start_above_area=0.75,start_below_area=0.85}))"},

The following generate normal-ish terrain with variable amounts of water / land.

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

Moat generates normal-ish terrain but gives a moat of water around the starting area.

    {"moat",
        "HF{pattern=Sum(NoiseCustom{exponent=2,zero_percentile=0.35,start_above_area=0.4,start_below_area=0.6}, Moat(250, 350, 1.3))}"},

Last of the natural-looking generations. This one is just obnoxious.

    {"pink noise (good luck...)", "HF(NoiseExponent{exponent=1,zero_percentile=0.65,start_beach=true})"},

Various speciality maps.

    {"Sierpinski carpet", "Sierpinski(6)"},
    {"Hilbert curve", "Hilbert(28, 4)"},
    {"world map", "Zoom(Translate(WorldMap(), -1238, -315), 4)"},
    {"radioactive", "Union(AngularRepeat(Halfplane(), 3), Circle(38))"},
    {"comb", "Zoom(Comb(), 50)"},
    {"cross", "Cross(50)"},
    {"cross and circles", "Union(Cross(20), ConcentricBarcode(30, 60))"},
    {"crossing bars", "Union(Barcode(nil, 10, 20), Barcode(nil, 20, 50))"},
    {"grid", "Zoom(Grid(), 50)"},
    {"skew grid", "Zoom(Affine(Grid(), 1, 1, 1, 0), 50)"},
    {"distorted grid", "Distort(Zoom(Grid(), 30))"},

Various mazes, which are good for having lots of choke points, especially Maze4.

    {"maze 1 (fibonacci)", "Tighten(Zoom(Maze1(), 50))"},
    {"maze 2 (DLA)", "Tighten(Zoom(Maze2(), 50))"},
    {"maze 3 (percolation)", "Tighten(Zoom(Maze3(0.6), 50))"},
    {"maze 4 (bifurcation)", "Maze4(4, 50)"},
    {"polar maze 3", "Zoom(AngularRepeat(Maze3(), 3), 50)"},
    {"bridged maze 3", "IslandifySquares(Maze3(), 50, 10, 4)"},

More speciality presets. The pot holes presets do not generate water, but put small void regions randomly.

    {"thin branching fractal", "Fractal(1.5, 40, 0.4)"},
    {"mandelbrot", "Repeat(Mandelbrot(300), 150, 315, -600, -315)"},
    {"jigsaw islands", "Zoom(JigsawIslands(0.3), 40)"},
    {"pink noise maze",
        "Intersection(Zoom(Maze2(), 50), HF{pattern = NoiseExponent{exponent=1,zero_percentile=0.2,start_beach=true}, heights={False(), 0, True()}})"},
    {"tiny pot holes", "TP(nil, Zoom(Maze3(0.003, false), 2))"},
    {"small pot holes", "TP(nil, Zoom(Maze3(0.006, false), 3))"},

This one should generate exactly the same as vanilla Factorio water.

    {"factorio default", "HF{pattern = Elevation(), heights = {DeepWater(), -3, Water(), 0, Land()}}"}

### More examples

Shallow water instead of regular water:

    If(landpattern, Land(), ShallowWater())

### Types of patterns

Each pattern computes a value for every x, y position. Some patterns may yield booleans, others yield numbers (representing a height above sea level), and others may yield strings which are names of built in Factorio tiles (e.g. 'grass-4' or 'nuclear-ground'). A complete list of available Factorio tile names is at https://mods.factorio.com/mod/TilePrototypeViewer ; click on the preview image to enlarge.

If a pattern producing tile names returns 'nil' at some x, y position, then whatever tile Factorio generated there is left alone.

The pattern

    TP(landpattern) or TP(landpattern, voidpattern)

takes one (or two) bool patterns and creates a pattern that makes tiles, with true indicating land and false indicating water. It is roughly equivalent to:

    If(landpattern, Land(), Water())

or

    If(voidpattern, Void(), If(landpattern, Land(), Water()))

The pattern

    HF(pattern)

takes a pattern that yields heights and creates a pattern that makes tiles, where heights above 0 are land and heights below 0 are water. See below for more options.

You do not need to explicitly use TP or HF unless you want to customize some of their options; given a boolean pattern P, this mod implicity uses TP(P) (i.e., true becomes land and false becomes water), and given a height field P, this mod implicitly uses HF(P), thus converting the pattern into a tile pattern.

### Full listing of all provided patterns

Optional parameters have their default values indicated.

 * Constant patterns
    * True(), False()
    * Default(), Land()
    * Zero(), One()
    * ShallowishWater(), ShallowWater(), Water(), DeepWater(), WaterGreen(), DeepWaterGreen()
    * Void()
    * Constant(value)
 * Special patterns
    * LuaExpr(expr, output = 'height', multiline)
    * Elevation(surface_name = 'nauvis') -- height field
    * NoiseLayer(layer = 'elevation', surface_name = 'nauvis') -- height field
 * Simple patterns
    * Square(sidelength = 32)
    * Rectangle(x1, y1, x2, y2)
    * Circle(radius = 32, centerx = 0, centery = 0)
    * Halfplane(angle = '+x') (can be '+x', '-x', '+y', '-y', or an angle in degrees)
    * Quarterplane(angle = '+x')
    * Strip(width = 1)
    * Cross(width = 1)
    * Comb()
    * Grid()
    * Checkerboard()
 * Spirals
    * Spiral(ratio = 1.4, land = 0.5, minradius = 3)
    * ConcentricCircles(ratio = 1.4, land = 0.5)
    * ArithmeticSpiral(dist = 40, land = 0.5)
    * ArithmeticConcentricCircles(dist = 40, land = 0.5)
    * RectSpiral()
 * Transformations
    * Zoom(pattern, factor = 16)
    * Not(pattern)
    * Or, Union, Max -- takes any number of patterns
    * And, Intersection, Min
    * Translate(pattern, dx, dy)
    * Rotate(pattern, angle)
    * Affine(pattern, a, b, c, d, dx = 0, dy = 0)
    * Mirrorx(pattern)
    * Mirrory(pattern)
    * Repeat(pattern, xhigh, yhigh, xlow = 0, ylow = 0)
    * Repeatx(pattern, xhigh, xlow = 0)
    * Repeaty(pattern, yhigh, ylow = 0)
    * AngularRepeat(pattern, k)
    * Jitter(pattern, radius = 10)
    * Distort(pattern, distortion_map = DistortionMap(), wavelengths = distort_light)
    * Tighten(pattern)
    * FullTighten(pattern)
 * Islands with bridges patterns
    * KroneckerProduct(pattern1, pattern2, sizex, sizey = sizex)
    * Islandify(pattern1, pattern2, sizex, sizey = sizex, bridgelength = 48, bridgewidth = 2)
    * SquaresAndBridges(islandradius = 32, bridgelength = 48, bridgewidth = 2)
    * CirclesAndBridges(islandradius = 32, bridgelength = 48, bridgewidth = 2)
    * IslandifySquares(pattern, islandradius = 32, bridgelength = 48, bridgewidth = 2)
    * IslandifyCircles(pattern, islandradius = 32, bridgelength = 48, bridgewidth = 2)
 * Height fields
    * Noise(options) -- `power` is mandatory option
    * NoiseExponent(options)
    * NoiseCustom(options)
    * LNorm(power = 2, radius = 1, x0 = 0, y0 = 0, normalize = true, c = 1)
    * CircularCutoff(radius, slope)
    * Moat(r1, r2, depth)
    * Sum(patterns...), Product(patterns...)
    * Subtract(pattern1, pattern2)
    * Clip(pattern, low, high)
 * Complicated patterns
    * TP(waterpattern = nil, voidpattern = nil)
    * HF(pattern)
    * Barcode(angle = 0, landthickness = 20, waterthickness = 50)
    * ConcentricBarcode(landthickness = 20, waterthickness = 50)
    * Hilbert(landwidth = 1, waterwidth = 1)
    * Sierpinski(start = 1) -- integer from 1 to 14, exponential size of starting island
    * Mandelbrot(size = 100)
    * WorldMap()
    * Image(pixels, width, height)
    * Maze1()
    * Maze2()
    * Maze3(landratio = 0.6, verify = true)
    * Maze4(width = 2, wavelength = 50, max_dist = 100000)
    * Fractal(dimension = 1.4, width = 40, aspect_ratio = 0.4)
    * JigsawIslands(landratio = 0.5)

## How to use height fields

You can create and combine height fields like any other pattern, e.g.:

    Sum(Translate(Moat(300, 400, 2), 100, 100), NoiseExponent{exponent=1.8,land_percent = 0.8})

Moat and NoiseExponent are height fields; Translate is the same type as the pattern it is given; and Sum combines any number of height fields into a single height field.

The 'HF' pattern takes a height field and assigns a tile to each (x, y) location based on the height of the height field at that location. HF(pattern) is equivalent to

    HF{pattern, heights = {Water(), 0, Land()}}

which is water below 0 and land above 0. More generally,

    HF{pattern, heights = {P1, -1, P2, 0.5, P3, 2, P4}}

will follow pattern P1 for heights below -1, P2 from -1 to 0.5, P3 from 0.5 to 2, and P4 above 2. Any number of heights can be provided (they must be in increasing order). The patterns P1 ... P4 don't have to be constants, so long as they are the same type.

Instead of height thresholds one can specify area thresholds:

    HF{pattern, areas = {P1, 0.1, P2, 0.4, P3, 0.8, P4}}

which will automatically choose height thresholds so that 10% of the area is P1, 30% is P2, 40% is P3, and 20% is P4. This is done on the assumption that the heights are normally distributed with mean 0 and standard deviation 1, which is true by default for the Noise{...}, NoiseExponent{...}, and NoiseCustom{...} patterns. If pattern is normally distributed with different mean or stddev, you can specfiy:

    HF{pattern, areas = {P1, 0.1, P2, 0.4, P3, 0.8, P4}, mean = -4, stddev = 2}

### Noise, NoiseExponent, NoiseCustom

The main way to make height fields is with the Noise family of patterns. Noise, NoiseExponent, and NoiseCustom create natural looking landforms. This is done by summing millions of randomized sine waves; with some cleverness this can be done efficiently, though there will be a brief pause when starting or loading a game as it has to re-compute the sums. By adjusting the amplitudes of the sine waves, any desired power spectrum can be generated.

(This is somewhat analogous to Factorio's built-in Perlin noise generator.)

Because of their many options, to make things easier they take a table where you can specify only the options relevant to you. The simplest to use is NoiseExponent, or the somewhat more flexible NoiseCustom.

Options:
    * mean: mean height, default 0
    * stddev: standard deviation of height, default 1
    * zero_percentile: if specified, adjusts mean so that the specified fraction of terrain has height below 0. E.g., zero_percentile = 0.2 then 20% of terrain has negative height.
    * start_above: chooses a starting location whose height is at least this high
    * start_below: chooses a starting location whose height is at most this high
    * start_above_area, start_below_area: instead of a threshold specified as a height, specify as a percentile. E.g., start_above_area = 0.2 will start with a height higher than at least 20% of the terrain.
    * start_beach (bool): if zero_percentile is specified, then start at a height just above 0. Otherwise, start at a height that is just above median.
    * wavelength_min: the shortest size (in tiles) of features generated by the noise
    function. Default 2, which is the minimum.
    * wavelength_max: the longest size (in tiles) of features generated by the noise
    function. Default 10000. Increasing this will cause small features to be greatly smoothed
    in comparison.
    * power (Noise only): A function that takes a frequency and returns the power at that
    frequency. No default; this argument is required.
    * exponent (NoiseExponent and NoiseCustom): A number that controls the general type of
    noise generated. Sensible values are in the range 1.5 to 2.5 or so. "Pink noise" is a
    value of 1, which is quite unplayable. Smaller values create lots of small noise, while
    bigger values create smooth terrain that slowly changes over very long distances. Default 1.8. This is equivalent to choosing a power function that computes wavelength ^ (-exponent).
    * noise (NoiseCustom only): An array of numbers that allows you to fine tune the power
    function very carefully without having to actually define your own function. The elements
    of the array control features of size 3.2 tiles, 10 tiles, 32 tiles, 100 tiles, 320 tiles, etc.,
    with each successive element of the array controlling features sqrt(10) times bigger than
    the previous element. (NoiseCustom smoothly interpolates between the specified numbers.)
    If an array of all 1s is given, this is identical to NoiseExponent. Otherwise, the numbers in
    the array act as multipliers on how much importance features at that scale have. Scaling all
    values of the array up by the same constant has no effect. I suggest keeping values roughly
    within a factor of 3 or so of each other for reasonable results.
    Default: {1, 1, 1, 1, 1, 1, 0.7, 0.4, 0.3, 0.2}
    The default array causes very large size features to be de-emphasized slightly.

### Other height fields

Elevation(surface_name) returns the internal Factorio elevation on a specified surface, which is what is used by the internal terrain generator. These values were not meant to be directly exposed to the user so the range of values might be somewhat awkward.

NoiseLayer(layer, surface_name) does the same, but for any specified internal noise layer, not just the elevation layer. A partial list of noise layers in the base game is:

 *  elevation
 *  elevation-persistence
 *  temperature
 *  moisture
 *  aux (used for variations on terrain types)
 *  starting-area
 *  copper-ore
 *  iron-ore
 *  coal
 *  stone
 *  uranium-ore
 *  crude-oil
 *  enemy-base

There are also noise layers 'grass-1', 'red-desert-0', 'dirt-1', 'sand-1', 'dry-dirt' for the various possible tile types.

LNorm(power = 2, radius = 1, x0 = 0, y0 = 0, normalize = true, c = 1) returns the distance from any point to the point (x0, y0). The default power = 2 computes the Euclidean (Pythagorean) distance; power can be any number 0 or greater, or 'infinity', to use other L-norms. radius controls how far away is considered distance 1. The result is scaled by c. In general:

    c * ((|x - x0| / radius) ^ power + (|y - y0| / radius) ^ power) ^ (1 / power)

If normalize == false the (1 / power) exponent is skipped. If power == 0 it computes Manhattan distance c * (|x - x0| + |y - y0|) / radius. If power == 'infinity' it computes c * max(|x - x0|, |y - y0|) / radius.


CircularCutoff(radius, slope) produces a cone with maximum height (radius / slope) at the origin, sloping down with a slope of 'slope' until it reaches 0 at a radius of 'radius', and stays 0 for all greater radius.

Moat(r1, r2, depth) is 0 except when the distance to the origin is between r1 and r2. Within this annulus it slopes down to a maximum depth of 'depth' below 0 at a radius of (r1 + r2) / 2.

Sum(patterns...), Product(patterns...) takes any number of height fields and produces their sum or product. Subtract(pattern1, pattern2) computes pattern1 - pattern2.

Clip(pattern, low, high) clips the specified height field to a range of heights from low to high.

## Further notes on certain patterns

 * Default() and Land() simply return nil everywhere, which has the effect of leaving Factorio's default terrain generation in place.
 * Or, Union, Max are identical; likewise And, Intersection, Min
 * Sierpinski(start) starts you on an island of size 3^size on each side (or so)
 * Hilbert draws a Hilbert curve
 * Image expects a very specific format; there is a python file in the mod for converting a png or other image into the correct format.
 * The `ratio` option for Spiral and ConcentricCircles is the ratio of how many times further
 from the spiral gets when it goes once around (or, for the circles, how many times further
 each circle is).
 * The `land` option for the various spirals is the fraction of terrain covered by land.
 * The `dist` option for ArithmeticSpiral and ArithmeticConcentricCircles is how many squares
 further from the origin the spiral goes on each wrap around.
 * The ArithmeticSpiral and RectSpiral options were inspired by the Factorio subreddit.
 * Affine does any affine linear transformation. (a b, c d) is the affine matrix, reading across.
 * Repeat takes a rectangular region of a specified pattern and repeats it over the whole plane.
 * Repeatx and Repeaty take a vertical and horizontal strip and repeat it horizontally / vertically.
 * AngularRepeat squeezes a given pattern into a pie-shaped region with an angle of 2 pi / k,
 and repeats that pattern k times around the origin.
 * Tighten shrinks the land in a given pattern so that anything touching water on south or east
 or southeast is replaced by water. FullTighten does all eight directions.
 * KroneckerProduct zooms into pattern1 by a factor of sizex by sizey; every tile of water
 becomes fully water, and every tile of land becomes a copy of the region of pattern2 near the
 origin. This is a generalization of all of the islandy maps in that section.
 * Islandify creates gaps between the zoomed in regions, connecting them with narrow bridges when
 they both have land.
 * SquaresAndBridges fills the world with square islands that are connected by narrow bridges.
 Likewise for CirclesAndBridges.
 * IslandifySquares replaces each land tile of the given pattern with a square island, and each water
 tile with a water region, and connects adjacent square islands with bridges.
 * IslandifySquares suggested by Donovan Hawkins. IslandifyCircles suggested by EldVarg.
 * The angle for Barcode is in degrees. If nil, a random angle is chosen.
 * Fractal generates a branching network of thin strips of lands, such that the area within a
 radius R of the origin scales like R^dimension. Thus a fractal of any desired dimension from 1 to 2
 is created. Width is how wide the strips are, and aspect_ratio controls how long this strips are
 before they have an opportunity to turn or branch.
 * JigsawIslands creates an infinite sea with islands that interlock with each other like jigsaw
 pieces (there may be a few tiny gaps, and sometimes islands overlap, making the interlocking less
 obvious). The `landratio` is the fraction covered by land.
 * Maze1 creates a very tight maze based on Fibonacci numbers; the maze generation algorithm
 was created totally from scratch.
 * Maze2 creates a looser maze; it is a version of Wilson's algorithm adapted for infinite mazes.
 * Maze3 creates a highly random maze, which can have islands isolated from the origin by water.
 Each square is independently land with probability `landratio`. If `verify` is true, it is verified
 that the starting location is on an infinitely large region of the maze (with very high
 probability); this option forces `landratio` to be at least 0.6.
 * Maze4 creates a maze that is mostly land with walls of water, designed to have lots of chokepoints.
 * LuaExpr(expr, output, multiline) lets you write any lua code you like. 'expr' must be a string containing your code. 'output' should be either 'height', 'bool', or 'tile'. If 'multiline' is true then you must explicitly include a 'return' command, otherwise it will be added for you implicitly.

## Random Seed

 * If you would like to generate the exact same map when restarting the game or when playing on
 another computer with the same settings, use the "seed" option in the settings. For each value
 from 1 to 2^32, if you use the same seed, you will get the same map every time; if you change
 the seed, you get a different map entirely. If you choose the seed value of 0, then the seed
 will be randomly selected for you, and the map will be different each time you restart.

## Unimportant Notes

 * A lot of math, algorithms, and data structures went into this mod. This includes:
 numbers in base Fibonacci, the Burr distribution, the Dagum distribution, queues,
 priority queues, union-find algorithm, the Mandelbrot set, Perlin noise,
 a differential equation solver using fourth-order Runge-Kutta, percolation theory,
 diffusion limited aggregates (related to Wilson's maze algorithm), a pseudo-random number
 generator, the inverse error function, and the Fast Fourier Transform.
 * The `distort` transformation may get improved in the future, but I find that the Noise pattern
 does better at accomplishing roughly the same goal.

 * World map found at https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Perlshaper_Winkel-Tripel_example1.svg/2560px-Perlshaper_Winkel-Tripel_example1.svg.png

## Historical Note

## Known Issues

 * Some of the islands generated by JigsawIslands will have slightly different shape depending on
 which side of the island is explored first.

## License

MIT license
