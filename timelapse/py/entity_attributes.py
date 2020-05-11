import re
import numpy as np

class Size:
    def __init__(self, x, y, d = None):
        if not (d is None):
            self.d = d
        elif x == y:
            self.d = [[(dx, dy) for dx in range(-(x // 2), (x + 1) // 2) for dy in range(-(y // 2), (y + 1) // 2)]]
        else:
            self.d = [
                    [(dy, dx) for dx in range(-(x // 2), (x + 1) // 2) for dy in range(-(y // 2), (y + 1) // 2)],
                    [(dy, dx) for dx in range(-(x // 2), (x + 1) // 2) for dy in range(-(y // 2), (y + 1) // 2)],
                    [(dx, dy) for dx in range(-(x // 2), (x + 1) // 2) for dy in range(-(y // 2), (y + 1) // 2)],
                    [(dx, dy) for dx in range(-(x // 2), (x + 1) // 2) for dy in range(-(y // 2), (y + 1) // 2)]
                    ]
        self.num = len(self.d)

    def get(self, direction):
        return self.d[direction % self.num]

size_straightrail = Size(2, 2, [
        [(-1, -1), (-1, 0), (0, -1), (0, 0)],       # 0
        [(-1, -1), (0, -1), (0, 0)],                # 1
        [(-1, -1), (-1, 0), (0, -1), (0, 0)],       # 2
        [(-1, 0), (0, -1), (0, 0)],                 # 3
        [(-1, -1), (-1, 0), (0, -1), (0, 0)],       # 4
        [(-1, -1), (-1, 0), (0, 0)],                # 5
        [(-1, -1), (-1, 0), (0, -1), (0, 0)],       # 6
        [(-1, -1), (-1, 0), (0, -1)]                # 7
    ])

size_curvedrail = Size(4, 8, [
        [(0, 3), (1, 3), (0, 2), (1, 2), (0, 1), (1, 1), (-1, 0), (0, 0), (1, 0), (-1, -1), (0, -1), (-2, -2), (-1, -2), (0, -2), (-2, -3), (-1, -3), (-2, -4)], # 0
        [(-1, 3), (-2, 3), (-1, 2), (-2, 2), (-1, 1), (-2, 1), (0, 0), (-1, 0), (-2, 0), (0, -1), (-1, -1), (1, -2), (0, -2), (-1, -2), (1, -3), (0, -3), (1, -4)], # 1
        [(-4, 0), (-4, 1), (-3, 0), (-3, 1), (-2, 0), (-2, 1), (-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 0), (1, -2), (1, -1), (1, 0), (2, -2), (2, -1), (3, -2)], # 2
        [(-4, -1), (-4, -2), (-3, -1), (-3, -2), (-2, -1), (-2, -2), (-1, 0), (-1, -1), (-1, -2), (0, 0), (0, -1), (1, 1), (1, 0), (1, -1), (2, 1), (2, 0), (3, 1)], # 3
        [(-1, -4), (-2, -4), (-1, -3), (-2, -3), (-1, -2), (-2, -2), (0, -1), (-1, -1), (-2, -1), (0, 0), (-1, 0), (1, 1), (0, 1), (-1, 1), (1, 2), (0, 2), (1, 3)], # 4
        [(0, -4), (1, -4), (0, -3), (1, -3), (0, -2), (1, -2), (-1, -1), (0, -1), (1, -1), (-1, 0), (0, 0), (-2, 1), (-1, 1), (0, 1), (-2, 2), (-1, 2), (-2, 3)], # 5
        [(3, -1), (3, -2), (2, -1), (2, -2), (1, -1), (1, -2), (0, 0), (0, -1), (0, -2), (-1, 0), (-1, -1), (-2, 1), (-2, 0), (-2, -1), (-3, 1), (-3, 0), (-4, 1)], # 6
        [(3, 0), (3, 1), (2, 0), (2, 1), (1, 0), (1, 1), (0, -1), (0, 0), (0, 1), (-1, -1), (-1, 0), (-2, -2), (-2, -1), (-2, 0), (-3, -2), (-3, -1), (-4, -2)] # 7
    ])

_12 = ['.*splitter', 'pump']
_22 = ['train-stop', 'stone-furnace', 'steel-furnace', 'big-electric-pole',
        'burner-mining-drill', 'gun-turret', 'accumulator', 'laser-turret',
        'substation',
        'small-worm-turret']
_23 = ['boiler', 'offshore-pump']
_33 = ['assembling-machine.*', 'pumpjack', 'storage-tank', 'lab', 'radar',
        'electric-mining-drill', 'electric-furnace', 'chemical-plant',
        'solar-panel', 'beacon',
        'artillery-turret', 'medium-worm-turret', 'big-worm-turret', 'behemoth-worm-turret']
_44 = ['roboport']
_53 = ['steam-engine']
_55 = ['oil-refinery']
_57 = ['biter-spawner', 'spitter-spawner']
_99 = ['rocket-silo']
size_index = [(_12, 1, 2), (_22, 2, 2), (_23, 2, 3), (_33, 3, 3), (_44, 4, 4),
        (_53, 5, 3), (_55, 5, 5), (_57, 5, 7), (_99, 9, 9)]
size11 = Size(1, 1)
def name2size(name):
    if name is None:
        return size11
    if name == 'straight-rail':
        return size_straightrail
    if name == 'curved-rail':
        return size_curvedrail
    for s, x, y in size_index:
        for item in s:
            if re.fullmatch(item, name):
                return Size(x, y)
    return size11

size00 = Size(0, 0)
def name2mining_area(name):
    if name == 'burner-mining-drill':
        return Size(2, 2)
    elif name == 'electric-mining-drill':
        return Size(5, 5)
    else:
        return size00

def name2is_finite(name):
    return not (name in ['crude-oil'])


# From data.raw:


void = [0, 0, 0]
water = [0, 0, 90]
land = [50, 40, 15]
rail = [180, 180, 180]

belt = [220, 200, 50]
fast = [220, 10, 30]
express = [0, 0, 255]

white = [255, 255, 255]
furnace = [235, 60, 100]
drill = [80, 90, 10]
oil = [20, 20, 20]

solar_panel = [10, 10, 10]
accumulator = [130, 130, 130]
wall = [210, 230, 210]
turret = [230, 70, 40]

player = [60, 255, 60]

enemy = [255, 0, 0]

# The following are the resource's on-map rgb values, taken from data.raw
coal = [0, 0, 0]
copper = [230, 105, 45] # [205, 99, 55]
oil_map = [200, 51, 197]
iron = [86, 114, 180] # [106, 134, 148]
stone = [190, 165, 117] # [177, 156, 109]
uranium = [0, 179, 0]

# blends with the color of the land, a bit
def desaturate(a, l = 0.7):
    b = [0, 0, 0]
    for i in range(3):
        b[i] = int(a[i] * (1 - l) + land[i] * l)
        b[i] = max(0, b[i])
        b[i] = min(255, b[i])
    return b

enemy_names = [
        'biter-spawner',
        'spitter-spawner',
        'small-worm-turret',
        'medium-worm-turret',
        'behemoth-worm-turret']

# default = [40, 180, 255]
default_color = [0, 97, 145]
fixed_colors = {
        None : void,
        0 : water,
        1 : land,
        'void' : void,
        'water' : water,
        'land' : land,
        'debug' : [130, 20, 20],
        'grid lines' : [130, 20, 20],
        'water debug' : [70, 20, 130],
        'land debug' : [70, 130, 20],
        'grass-1' : land,
        'landfill' : land,
        'straight-rail' : rail,
        'curved-rail' : rail,
        'player' : player,

        'lab' : white,
        'rocket-silo' : white,

        'solar-panel' : solar_panel,
        'accumulator' : accumulator,
        'stone-wall' : wall,

        'gun-turret' : turret,
        'electric-turret' : turret,
        'fluid-turret' : turret,
        'artillery-turret' : turret,

        'stone-furnace' : furnace,
        'steel-furnace' : furnace,
        'electric-furnace' : furnace,

        'coal__active'              : coal,
        'copper-ore__active'        : copper,
        'iron-ore__active'          : iron,
        'stone__active'             : stone,
        'uranium-ore__active'       : uranium,

        'coal'                      : desaturate(coal),
        'copper-ore'                : desaturate(copper),
        'iron-ore'                  : desaturate(iron),
        'stone'                     : desaturate(stone),
        'uranium-ore'               : desaturate(uranium),

        'burner-mining-drill' : drill,
        'electric-mining-drill' : drill,

        'crude-oil': oil,
        'crude-oil__active': oil,
        'pumpjack' : oil,

        'oil-refinery' : oil,
        'storage-tank' : oil,

        'transport-belt' : belt,
        'splitter' : belt,
        'underground-belt' : belt,
        'fast-transport-belt' : fast,
        'fast-splitter' : fast,
        'fast-underground-belt' : fast,
        'express-transport-belt' : express,
        'express-splitter' : express,
        'express-underground-belt' : express
        }

def name2color(name):
    if name in fixed_colors:
        return fixed_colors[name]
    if name in enemy_names:
        return enemy

    return default_color

def name2is_miner(name):
    return name in ['burner-mining-drill', 'electric-mining-drill']


class EntityAttr:
    # First 10 ids are for reserved "entities"
    def __init__(self, id2name, name2id):
        self.name2id = dict(name2id)
        self.id2name = list(id2name)

        self.id2name[0] = 'void'
        self.id2name[1] = 'water'
        self.id2name[2] = 'land'
        self.id2name[3] = 'debug'
        self.id2name[4] = 'grid lines'
        self.id2name[5] = 'player'

        self.numid = len(id2name)

        self.id2size = [None] * self.numid
        self.id2color = np.zeros((self.numid, 3), dtype = np.uint8)
        self.id2is_miner = [False] * self.numid
        self.id2mining_area = [None] * self.numid
        self.id2is_finite = [False] * self.numid
        self.id2active_id = [0] * self.numid
        self.id2enemy = [False] * self.numid

        for id_ in range(self.numid):
            name = self.id2name[id_]
            self.id2size[id_] = name2size(name)
            self.id2color[id_] = name2color(name)
            self.id2is_miner[id_] = name2is_miner(name)
            self.id2mining_area[id_] = name2mining_area(name)
            self.id2is_finite[id_] = name2is_finite(name)
            self.id2enemy[id_] = (name in enemy_names)

            active_name = str(name) + '__active'
            if active_name in self.name2id:
                self.id2active_id[id_] = self.name2id[active_name]
            else:
                self.id2active_id[id_] = id_

    def name(self, id_):
        return self.id2name[id_]

    def size(self, id_):
        return self.id2size[id_]

    def color(self, id_):
        return self.id2color[id_]

    def is_miner(self, id_):
        return self.id2is_miner[id_]

    def mining_area(self, id_):
        return self.id2mining_area[id_]

    def is_finite(self, id_):
        return self.id2is_finite[id_]

    def active_id(self, id_):
        return self.id2active_id[id_]

    def is_enemy(self, id_):
        return self.id2enemy[id_]
