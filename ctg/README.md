# Custom Terrain Generation

a [Factorio](http://factorio.com) mod by Eric Stansifer

Hosted at `https://github.com/estansifer/factoriomods/`

This mod is a customizable, algebraic terrain generator that alters the distribution of
land, water, and void cells at the start of a new game.

A wide variety of terrain generation algorithms are included, as well as the ability
to combine them in many ways or write your own algorithm.

 * Version 0.2.0
 * Initial release: 2016-03-15
 * Current release: 2018-10-28

## Important notes

 * This mod remembers all settings on a per-save basis. Only the settings enabled
 when the game is first begun matter, and there is no need to synchronize settings for
 multiplayer.
 * If you enable this mod and then load a save that did not originally have this mod
 enabled, the mod will do nothing and no water will be generated any more. A warning will
 be printed.
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

 [screenshots](https://imgur.com/a/C2pFsf8)

 Just for fun, [very old screenshots](https://imgur.com/a/wptLh).

## How to use

By default, the mod creates a simple spiral map. The `Water pattern preset` option
gives a large list of other patterns that have been given as examples. Screenshots of
each of these can be found above.

 * You may wish to enable the "landfill chest" option which gives you a very large amount
 of landfill at the beginning. If you spawn near a good location but are blocked by water,
 you can use it to get there, and then throw away what you didn't need.
 * Any pattern that can be used for water and be used for void, but it generates voids
 instead of water (however, only a few void presets are given). If voids and water overlap,
 void takes priority.
 * All of the presets are designed to place water near the starting location, but you may
 wish to use a custom pattern that does not. In this case, the `Force starting water` option
 puts a puddle next to your starting location to make the game playable.

## Testing options

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

## Custom patterns

If you don't want to use a preset, you can specify the `custom` option and write your
own pattern. If your pattern uses more than one line of lua code, you use variables called
`v1`, `v2`, `v3`, and `v4` for convenience (since the text box is tiny to type in).

### Examples

Here is a list of every preset and the code used to generate it:

 * spiral: Spiral(1.3, 0.4)
 * arithmetic spiral: ArithmeticSpiral(50, 0.4)
 * rectilinear spiral: Zoom(RectSpiral(), 50)
 * triple spiral: AngularRepeat(Spiral(1.6, 0.5), 3)
 * crossing spirals: Union(Spiral(1.4, 0.4), Spiral(1 / 1.6, 0.2))
 * natural archipelago: NoiseCustom({exponent=1.5,noise={0.3,0.4,1,1,1.2,0.8,0.7,0.4,0.3,0.2},land_percent=0.13})
 * natural big islands: NoiseCustom({exponent=2.3,noise={1,1,1,1,1,1,0.7,0.4,0.3,0.2},land_percent=0.2})
 * natural continents: NoiseCustom({exponent=2.4,noise={1,1,1,1,1,1,1,0.6,0.3,0.2},land_percent=0.35})
 * natural half land: NoiseCustom({exponent=2,noise={1,1,1,1,1,1,0.7,0.4,0.3,0.2},land_percent=0.5})
 * natural big lakes: NoiseCustom({exponent=2.3,noise={1,1,1,1,1,1,0.7,0.4,0.3,0.2},land_percent=0.65})
 * natural medium lakes: NoiseCustom({exponent=2.1,noise={1,1,1,1,1,1,0.7,0.4,0.3,0.2},land_percent=0.86})
 * natural small lakes: NoiseCustom({exponent=1.8,noise={0.2,0.3,0.4,0.6,1,1,0.7,0.4,0.3,0.2},land_percent=0.96})
 * pink noise (good luck...): NoiseExponent({exponent=1,land_percent = 0.35})
 * radioactive: Union(AngularRepeat(Halfplane(), 3), Circle(38))
 * comb: Zoom(Comb(), 50)
 * cross: Cross(50)
 * cross and circles: Union(Cross(20), ConcentricBarcode(30, 60))
 * crossing bars: Union(Barcode(nil, 10, 20), Barcode(nil, 20, 50))
 * grid: Zoom(Grid(), 50)
 * skew grid: Zoom(Affine(Grid(), 1, 1, 1, 0), 50)
 * distorted grid: Distort(Zoom(Grid(), 30))
 * maze 1 (fibonacci): Tighten(Zoom(Maze1(), 50))
 * maze 2 (DLA): Tighten(Zoom(Maze2(), 50))
 * maze 3 (percolation): Tighten(Zoom(Maze3(0.6), 50))
 * polar maze 3: Zoom(AngularRepeat(Maze3(), 3), 50)
 * bridged maze 3: IslandifySquares(Maze3(), 50, 10, 4)
 * thin branching fractal: Fractal(1.5, 40, 0.4)
 * mandelbrot: Tile(Mandelbrot(300), 150, 315, -600, -315)
 * jigsaw islands: Zoom(JigsawIslands(0.3), 40)
 * pink noise maze: Intersection(Zoom(Maze2(), 50), NoiseExponent{exponent=1,land_percent=0.8})
 * tiny pot holes: Maze3(0.997)
 * small pot holes: Zoom(Maze3(0.994), 3)

### Full listing of all provided patterns

Optional parameters have their default values indicated.

 * Simple patterns
    * AllLand()
    * AllWater()
    * Square(radius = 32)
    * Rectangle(x1, y1, x2, y2)
    * Circle(radius = 32, centerx = 0, centery = 0)
    * Halfplane()
    * Quarterplane()
    * Strip(width = 1)
    * Cross(width = 1)
    * Comb()
    * Grid()
    * Checkerboard()
    * Spiral(ratio = 1.4, land = 0.5)
    * ConcentricCircles(ratio = 1.4, land = 0.5)
    * ArithmeticSpiral(dist = 40, land = 0.5)
    * ArithmeticConcentricCircles(dist = 40, land = 0.5)
    * RectSpiral()
 * Transformations
    * Zoom(pattern, factor = 16)
    * Not(pattern)
    * Union(patterns...) -- takes any number of comma-separated patterns
    * Intersection(patterns...) -- takes any number of comma-separated patterns
    * Translate(pattern, dx, dy)
    * Rotate(pattern, angle)
    * Affine(pattern, a, b, c, d, dx = 0, dy = 0)
    * Tile(pattern, xhigh, yhigh, xlow = 0, ylow = 0)
    * Tilex(pattern, xhigh, xlow = 0)
    * Tiley(pattern, yhigh, ylow = 0)
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
 * Complicated patterns
    * Barcode(angle = 0, landthickness = 20, waterthickness = 50)
    * ConcentricBarcode(landthickness = 20, waterthickness = 50)
    * Fractal(dimension = 1.4, width = 40, aspect_ratio = 0.4)
    * JigsawIslands(landratio = 0.5)
    * Mandelbrot(size = 100)
    * Maze1()
    * Maze2()
    * Maze3(landratio = 0.6, verify = true)
    * Noise(options) -- `power` is mandatory option
    * NoiseExponent(options)
    * NoiseCustom(options)

### Further notes on certain patterns

 * The `ratio` option for Spiral and ConcentricCircles is the ratio of how many times further
 from the spiral gets when it goes once around (or, for the circles, how many times further
 each circle is).
 * The `land` option for the various spirals is the fraction of terrain covered by land.
 * The `dist` option for ArithmeticSpiral and ArithmeticConcentricCircles is how many squares
 further from the origin the spiral goes on each wrap around.
 * The ArithmeticSpiral and RectSpiral options were inspired by the Factorio subreddit.
 * Affine does any affine linear transformation. (a b, c d) is the affine matrix, reading across.
 * Tile takes a rectangular region of a specified pattern and repeats it over the whole plane.
 * Tilex and Tiley take a vertical and horizontal strip and repeat it horizontally / vertically.
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
 * Noise, NoiseExponent, and NoiseCustom create natural looking landforms. Because of their many
 options, to make things easier they take a table where you can specify only the options relevant
 to you. The simplest to use is NoiseExponent. Only use Noise if you know what you are doing.
    * land_percent: fraction of terrain that is land. Note that enabling the start_on_land or
    start_on_beach options causes you to spawn in a location which might have more or less land
    than the average location. Default 0.5.
    * start_on_land: forces spawn to be on land. Default true.
    * start_on_beach: forces spawn to be on land and near water. Default true.
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
    bigger values create smooth terrain that slowly changes over very long distances. Default 1.8.
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

## Unimportant Notes

 * A lot of math, algorithms, and data structures went into this mod. This includes:
 numbers in base Fibonacci, the Burr distribution, the Dagum distribution, queues,
 priority queues, union-find algorithm, the Mandelbrot set, Perlin noise,
 a differential equation solver using fourth-order Runge-Kutta, percolation theory,
 diffusion limited aggregates (related to Wilson's maze algorithm), the inverse error
 function, and the Fast Fourier Transform.
 * The `distort` transformation may get improved in the future, but I find that the Noise pattern
 does better at accomplishing roughly the same goal.

## Versions

 * 0.2.1 Fixed bug in Maze3 / RandGrid; fixed misleading statement in README and warning message.
 * 0.2.0 Many changes:
    * Updated for Factorio 0.16 (skipping 0.15)
    * Rewrote all core code
    * Now uses Factorio's built-in mod settings support
    * Settings include a variety of suggested patterns, and ability to make custom patterns.
    * Got rid of deep magic for storing mod settings on per-save basis. As of Factorio 0.15,
    this was no longer necessary: now using ordinary magic.
    * Support for voids
    * Now warns if mod added after beginning of game
    * Added option to start the game with a chest of landfill
    * Created Noise, NoiseExponent, and NoiseCustom patterns, which create natural-looking landforms
    * Created Fractal pattern, which creates fractals of arbitrary dimensions from 1 to 2
    * Created ConcentricBarcode pattern, for random concentric circles of different thicknesses
    * Created RectSpiral pattern
    * Created Tilex and Tiley transforms
    * Small improvements to JaggedIslands pattern
    * Optimized Maze3 and Mandelbrot patterns
    * Fixed bug in Tile pattern when not tiling from origin
    * Fixed bug in saving of Union (and Intersection) if taking the union of a non-stateful pattern
    with a stateful pattern, in that order.
    * Many smaller changes
 * 0.1.1 Union and Intersection take any number of arguments instead of just two. Fixed bug
 in AllWater, thanks sintri on the forums for being the first person to find a bug. Added
 Rectangle pattern and changed Circle to take an optional center arugment.
 * 0.1.0 Added Distort, Jitter, Checkerboard, AllLand, AllWater, Rotate, Affine, Tile,
 AngularRepeat, Invert, Smooth, KroneckerProduct, IslandifyCircles, SquaresAndBridges,
 and CirclesAndBridges patterns. Multiple backwards incompatible changes. Made compatible
 with Factorissimo. Fixed bug in loading games saved with JaggedIslands with non-default
 land ratio.
 * 0.0.9 Updated for Factorio 0.14.
 * 0.0.8 Updated for Factorio 0.13.
 * 0.0.7 Added Mandelbrot, JaggedIslands, and Barcode patterns.
 * 0.0.6 Partial re-write. Moved configuration to `config.lua`. Added several new patterns,
 including Spiral and Islandify. Most patterns renamed more sensibly. Total overhaul of saving
 and loading to address earlier limitations that made it impossible to load a game saved with
 certain especially complicated patterns.
 * 0.0.5 Removed dependency and fixed the version in info.json
 * 0.0.4 Rewrote islands pattern again to align it with railroad tracks in case of path width of 2.
 * 0.0.3 Bug fix with `big_scans` option in multiplayer
 * 0.0.2 Improved islands pattern, added no water option, added half and quarter plane options,
 added translate filter
 * 0.0.1 Initial release

## Known Issues

## License

MIT license
