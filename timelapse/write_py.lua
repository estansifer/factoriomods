
local content = {}
local filename = {}

-- py/timelapse.py
table.insert(content, [==[# Assumes log format version is 0.0.1
#
# python timelapse.py [length-in-seconds] [fps]

import os
import os.path
import sys
import numpy as np
import imageio

from boundingbox import BoundingBox
import read_log
import write_frames

def guess_name():
    name = None
    with open('recordings/catalog', 'r') as f:
        for line in f:
            line = line.strip()
            if len(line) > 0:
                name = line.split()[0]
    return name

class Action:
    def __init__(self, name = None):
        if name is None:
            name = guess_name()

        self.name = name
        self.data = read_log.Data(name)

        self.reset_defaults()

    def reset_defaults(self):
        self.movie = False
        self.image = False
        self.real_time = True
        self.bb = None
        self.flip = False
        self.show_grid = False
        self.start = 120
        self.end = self.data.maxtick + 2

    # seconds is the length of the animation, including the final pause
    # pause_at_end is how many seconds to pause at the end of the animation
    def set_movie(self, seconds, fps, pause_at_end = 5, movie_name = None):
        self.movie = True
        self.seconds = seconds
        self.fps = fps
        self.pause_at_end = pause_at_end
        self.movie_name = movie_name or (self.data.name + '.mp4')

        if self.pause_at_end * 1.1 > seconds or self.pause_at_end < 0.1:
            self.pause_at_end = 0

    def set_image(self, image_name = None):
        self.image = True
        self.image_name = image_name or (self.data.name + '.png')

    def set_real_time(self, rt):
        self.real_time = rt

    def set_bb(self, bb):
        self.bb = bb

    def set_tick_range(self, start, end):
        self.start = start
        self.end = end

    def set_flip(self, flip = True):
        self.flip = flip

    def set_show_grid(self, show_grid = True):
        self.show_grid = show_grid

    def go(self):
        if self.image:
            os.makedirs('images', exist_ok = True)
            image_file = os.path.join('images', self.image_name)

        if self.movie:
            os.makedirs('movies', exist_ok = True)
            movie_file = os.path.join('movies', self.movie_name)

            num_frames = self.fps * (self.seconds - self.pause_at_end)

            if self.real_time:
                ticks = list(np.linspace(self.start, self.end, num_frames))
            else:
                ticks = list(self.data.entity_ticks(self.start, self.end, num_frames))
            ticks = ticks + ([self.end] * int(self.fps * self.pause_at_end))

            writer = imageio.get_writer(movie_file, mode = 'I',
                    fps = self.fps,
                    codec = 'libx264',
                    ffmpeg_log_level = 'info',
                    quality = 10,
                    ffmpeg_params = ['-nostats', '-nostdin',
                        '-profile:v', 'high',
                        '-level', '4.2',
                        '-preset', 'slower',
                        '-crf', '15',
                        '-x264-params', 'ref=4',
                        '-movflags',
                        '+faststart'])

            with writer:
                end_frame = write_frames.write_frames(
                        writer,
                        self.data,
                        ticks,
                        bb = self.bb,
                        flip = self.flip,
                        show_grid = self.show_grid)
            print("Saved movie to", self.movie_name)

            if self.image:
                imageio.imwrite(image_file, end_frame)
                print("Saved last frame of movie to", self.image_name)

            print('Game ticks per frame', (self.end - self.start) / (num_frames - 1))
            print('Speed-up', (self.end - self.start) / (num_frames - 1) / 60 * self.fps)
            a, b = self.data.entities_created.interval(self.start, self.end)
            print('Entity updates per frame', (b - a) / (num_frames - 1))
        elif self.image:
            end_frame = write_frames.write_frames(
                    None,
                    self.data,
                    [self.end],
                    bb = self.bb,
                    flip = self.flip,
                    show_grid = self.show_grid)
            imageio.imwrite(image_file, end_frame)
            print("Saved screenshot to", self.image_name)

def make_default():
    length = 120
    if len(sys.argv) >= 2:
        length = float(sys.argv[1])

    fps = 30
    if len(sys.argv) >= 3:
        fps = float(sys.argv[2])

    action = Action()
    action.set_image()
    action.set_movie(length, fps)
    action.go()

if __name__ == "__main__":
    make_default()
]==])
table.insert(filename, "timelapse/timelapse.py")

-- py/read_log.py
table.insert(content, [==[import os.path

from boundingbox import BoundingBox
import entity_attributes

logversion = '0.0.1'

def readfile(path):
    result = []
    with open(path) as f:
        for rawline in f:
            result.append(rawline.strip().split(maxsplit = 1))
            # line = rawline.strip()
            # if len(line) > 0 and ('#' not in line):
                # result.append(line.split(maxsplit = 1))
    return result

lognames = [
            'journal',
            'names',
            'entities',
            'entities_removed',
            'tiles_init',
            'tiles',
            'resources',
            'resources_depleted',
            'player_position'
        ]

def warn(true, message, error = False):
    if not true:
        if error:
            print('Error: ' + message)
            assert true
        else:
            print('Warning: ' + message)

class Log:
    def __init__(self, recording_name):
        self.directory = os.path.join('recordings', recording_name)

        self.N = len(lognames)

        self.read_journal()

    def read_journal(self):
        journallines = readfile(os.path.join(self.directory, 'journal'))

        headers = 0
        for i, line in enumerate(journallines):
            if line[1].startswith('logfiles'):
                warn(i + 1 < len(journallines), 'truncated journal header', True)

                l2 = journallines[i + 1][1].split()
                warn(len(l2) > 0 and l2[0] == 'logversion', 'missing log version', True)
                warn(len(l2) == 4, 'can\'t read log version', True)
                warn(l2[3] == logversion,
                    'expected logversion ' + logversion + ' but found logversion ' + l2[3], True)

                headers += 1
                names = line[1].split()[1:]
                warn(len(names) == self.N,
                    'expected {} logs, found {} logs'.format(len(lognames), self.N), True)
                for j in range(self.N):
                    warn(names[j].split('/')[-1] == lognames[j],
                            'found unexpected log name', True)


        warn(headers > 0, 'did not find a header in the journal!')
        msg = ('Found more than one header in journal!' +
            ' Maybe multiple saves are using the same log?')
        warn(headers < 2, msg)

        counts = [0] * self.N
        self.journal_last = None
        self.journal = {}

        for line in journallines:
            if line[1].startswith('log') or line[1].startswith('#'):
                continue

            xs = [int(x) for x in line[1].split()]
            assert len(xs) == 4 + self.N
            tick = xs[0]
            id_ = xs[1]
            last_tick = xs[2]
            last_id = xs[3]

            counts_new = [None] * self.N
            for i in range(self.N):
                counts_new[i] = counts[i] + xs[4 + i]

            self.journal_last = (tick, id_)
            self.journal[self.journal_last] = ((last_tick, last_id), counts, counts_new)

            counts = counts_new

    def get_history(self, journal_entry = None):
        if journal_entry is None:
            journal_entry = self.journal_last

        history = []

        # debug_out = []

        while journal_entry in self.journal:
            history.append(self.journal[journal_entry][1:3])
            # debug_out.append((journal_entry, history[-1]))
            journal_entry = self.journal[journal_entry][0]

        # print("==Journal==")
        # for entry in reversed(debug_out):
            # print(entry)
        # print("==End journal==")

        return list(reversed(history))

    def reduced_log_files(self, journal_entry = None):
        history = self.get_history(journal_entry)

        logs = {}

        for i in range(self.N):
            lines = []
            tick = 0

            rawlines = readfile(os.path.join(self.directory, lognames[i]))
            for c1, c2 in history:
                for rawline in rawlines[c1[i] : c2[i]]:
                    tick += int(rawline[0])
                    if not rawline[1].startswith('#'):
                        lines.append((tick, rawline[1]))

            logs[lognames[i]] = lines

            msg = 'Read {}: '.format(lognames[i])
            while len(msg) < 25:
                msg = msg + ' '

            print(msg, len(lines), '/', len(rawlines))

        return logs

class EventIterator:
    def __init__(self, xs):
        self.xs = xs
        self.num = len(xs)
        self.next = 0

    def until(self, tick):
        while self.next < self.num and self.xs[self.next][0] <= tick:
            yield self.xs[self.next]
            self.next += 1

class EventList:
    def __init__(self, xs):
        self.xs = xs

    def iterator(self):
        return EventIterator(self.xs)

    def interval(self, t1, t2):
        a = 0
        while a < len(self.xs) and self.xs[a][0] < t1:
            a += 1
        b = a
        while b < len(self.xs) and self.xs[b][0] < t2:
            b += 1

        return (a, b)

    def uniform_sampling(self, t1, t2, n):
        if len(self.xs) == 0 or n <= 0:
            return []
        if n == 1:
            return [t1]
        if n == 2:
            return [t1, t2]

        a, b = self.interval(t1, t2)
        ticks = []
        for i in np.linspace(a, b, n):
            j = int(i + 0.5)
            if j < len(self.xs):
                ticks.append(self.xs[j][0])
            else:
                ticks.append(self.xs[-1][0] + 1)
        ticks[0] = t1
        ticks[-1] = t2
        return ticks

idshift = 10

class Data:
    def __init__(self, recording_name):
        logs = Log(recording_name).reduced_log_files()

        self.name = recording_name

        self.maxtick = 0

        self.read_names(logs['names'])
        self.read_entities(logs['entities'], logs['entities_removed'])
        self.read_tiles(logs['tiles'])
        self.read_charts(logs['tiles_init'])
        self.read_resources(logs['resources'], logs['resources_depleted'])
        self.read_player_position(logs['player_position'])

    def read_names(self, names):
        name2id = {}
        content = []
        maxid = idshift
        for tick, line in names:
            a, b = line.split()
            id_ = int(a) + idshift
            content.append((id_, b))
            name2id[b] = id_
            maxid = max(maxid, id_)

        id2name = [None] * (maxid + 1)
        for a, b in content:
            id2name[a] = b

        self.attr = entity_attributes.EntityAttr(id2name, name2id)

    def read_entities(self, entities, entities_removed):
        self.entity_range = BoundingBox()
        l = []

        for tick, line in entities:
            xs = line.split()
            unit = int(xs[0])
            id_ = int(xs[1]) + idshift
            x = int(xs[2])
            y = int(xs[3])
            direction = int(xs[4])

            if not self.attr.is_enemy(id_):
                self.entity_range.update(x, y)
            l.append((tick, unit, id_, x, y, direction))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.entities_created = EventList(l)

        l = []
        for tick, unit in entities_removed:
            l.append((tick, int(unit)))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.entities_removed = EventList(l)

    def read_tiles(self, tiles):
        l = []
        for tick, line in tiles:
            xs = line.split()
            for i in range(len(xs) // 3):
                id_ = int(xs[3 * i]) + idshift
                x = int(xs[3 * i + 1])
                y = int(xs[3 * i + 2])
                l.append((tick, id_, x, y))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.tile_history = EventList(l)

    def read_charts(self, tiles_init):
        self.charted_range = BoundingBox()

        l = []
        for tick, line in tiles_init:
            xs = line.split()
            x = int(xs[0])
            y = int(xs[1])
            l.append((tick, x, y, xs[2]))
            self.charted_range.update(32 * x, 32 * y)
            self.charted_range.update(32 * x + 31, 32 * y + 31)

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.charts = EventList(l)

    def read_resources(self, resources, resources_depleted):
        l = []
        for tick, line in resources:
            xs = line.split()
            id_ = int(xs[0]) + idshift
            x = int(xs[1])
            y = int(xs[2])
            amount = int(xs[3])
            l.append((tick, id_, x, y))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.resources = EventList(l)

        l = []
        for tick, line in resources_depleted:
            xs = line.split()
            id_ = int(xs[0]) + idshift
            x = int(xs[1])
            y = int(xs[2])
            l.append((tick, id_, x, y))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.resources_depleted = EventList(l)

    def read_player_position(self, player_position):
        l = []
        for tick, line in player_position:
            xs = line.split()
            pos = []
            for i in range(len(xs) // 3):
                x = int(float(xs[3 * i + 1]))
                y = int(float(xs[3 * i + 2]))
                pos.append((x, y))

            l.append((tick, pos))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.player_position = EventList(l)
]==])
table.insert(filename, "timelapse/read_log.py")

-- py/entity_layer.py
table.insert(content, [==[import numpy as np

class EntityLayer:
    def __init__(self, bb, data):
        self.bb = bb
        dx = bb.dx()
        dy = bb.dy()
        self.x0 = bb.xmin
        self.y0 = bb.ymin

        self.id_ = np.zeros((dx, dy), dtype = int)
        self.num = np.zeros((dx, dy), dtype = int)
        self.is_miner = np.zeros((dx, dy), dtype = bool)
        self.num_mining = np.zeros((dx, dy), dtype = int)

        # map from unit to (id, x, y, direction)
        self.entities = {}
        # set of units
        self.entities_off_map = set()
        # map from (x, y) to list of ids that didn't fit in self.id_ due to overlaps
        self.overlaps = {}

        self.events_create = data.entities_created.iterator()
        self.events_remove = data.entities_removed.iterator()
        self.attr = data.attr

        self.missing_entities = []

    def create_entity(self, unit, id_, x, y, direction, dirty):
        if unit in self.entities or unit in self.entities_off_map:
            # Duplicate entities can be found if they straddle multiple chunks
            return

        onmap = False

        im = self.attr.is_miner(id_)

        for dx, dy in self.attr.size(id_).get(direction):
            if self.bb.inrange(x + dx, y + dy):
                onmap = True
                x1 = x + dx - self.x0
                y1 = y + dy - self.y0
                if self.num[x1, y1] == 0:
                    self.id_[x1, y1] = id_
                    self.is_miner[x1, y1] = im
                    dirty.add((x1, y1))
                else:
                    if (x1, y1) in self.overlaps:
                        self.overlaps[(x1, y1)].append(id_)
                    else:
                        self.overlaps[(x1, y1)] = [id_]
                self.num[x1, y1] += 1

        if im and onmap:
            for dx, dy in self.attr.mining_area(id_).get(direction):
                if self.bb.inrange(x + dx, y + dy):
                    x1 = x + dx - self.x0
                    y1 = y + dy - self.y0
                    self.num_mining[x1, y1] += 1
                    dirty.add((x1, y1))

        if onmap:
            self.entities[unit] = (id_, x, y, direction)
        else:
            self.entities_off_map.add(unit)

    def remove_entity(self, unit, dirty):
        if unit in self.entities_off_map:
            self.entities_off_map.remove(unit)
            return

        if unit not in self.entities:
            # print("Missing entity", unit)
            self.missing_entities.append(unit)
            return

        id_, x, y, direction = self.entities.pop(unit)

        for dx, dy in self.attr.size(id_).get(direction):
            if self.bb.inrange(x + dx, y + dy):
                x1 = x + dx - self.x0
                y1 = y + dy - self.y0
                if self.id_[x1, y1] == id_:
                    if self.num[x1, y1] == 1:
                        self.id_[x1, y1] = 0
                        self.is_miner[x1, y1] = False
                    else:
                        o = self.overlaps
                        self.id_[x1, y1] = o[(x1, y1)].pop()
                        if len(o[(x1, y1)]) == 0:
                            del o[(x1, y1)]
                        self.is_miner[x1, y1] = self.attr.is_miner(self.id_[x1, y1])
                    dirty.add((x1, y1))
                else:
                    o = self.overlaps
                    o[(x1, y1)].remove(id_)
                    if len(o[(x1, y1)]) == 0:
                        del o[(x1, y1)]
                self.num[x1, y1] -= 1

        if self.attr.is_miner(id_):
            for dx, dy in self.attr.mining_area(id_).get(direction):
                if self.bb.inrange(x + dx, y + dy):
                    x1 = x + dx - self.x0
                    y1 = y + dy - self.y0
                    self.num_mining[x1, y1] -= 1
                    dirty.add((x1, y1))


    def update_entities(self, tick, dirty):
        for event in self.events_create.until(tick):
            self.create_entity(event[1], event[2], event[3], event[4], event[5], dirty)
        for event in self.events_remove.until(tick):
            self.remove_entity(event[1], dirty)
]==])
table.insert(filename, "timelapse/entity_layer.py")

-- py/resource_layer.py
table.insert(content, [==[import numpy as np

class ResourceLayer:
    def __init__(self, bb, data):
        self.bb = bb
        dx = bb.dx()
        dy = bb.dy()
        self.x0 = bb.xmin
        self.y0 = bb.ymin

        self.id_ = np.zeros((dx, dy), dtype = int)

        self.resources_create = data.resources.iterator()
        self.resources_deplete = data.resources_depleted.iterator()

        self.attr = data.attr

    def update_resources(self, tick, dirty):
        for tick, id_, x, y in self.resources_create.until(tick):
            if self.bb.inrange(x, y):
                x1 = x - self.x0
                y1 = y - self.y0
                self.id_[x1, y1] = id_
                dirty.add((x1, y1))

        for tick, id_, x, y in self.resources_deplete.until(tick):
            if self.attr.is_finite(id_) and self.bb.inrange(x, y):
                x1 = x - self.x0
                y1 = y - self.y0
                self.id_[x1, y1] = 0
                dirty.add((x1, y1))
]==])
table.insert(filename, "timelapse/resource_layer.py")

-- py/overlay_layer.py
table.insert(content, [==[import numpy as np

cursor = []
for i in range(-5, 6):
    cursor.append((i, 0))
for j in range(-5, 6):
    if j != 0:
        cursor.append((0, j))

class OverlayLayer:
    def __init__(self, bb, data, show_grid):
        self.bb = bb
        dx = bb.dx()
        dy = bb.dy()
        self.x0 = bb.xmin
        self.y0 = bb.ymin

        self.id_ = np.zeros((dx, dy), dtype = int)

        self.needs_to_draw_grid = show_grid
        self.player_color = data.attr.color(5) # player

        self.player_pos = data.player_position.iterator()

        self.last_seen = []

    def update_grid(self, dirty):
        if self.needs_to_draw_grid:
            bb = self.bb

            for x in range(bb.xmin, bb.xmax):
                if x % 128 == 0:
                    for y in range(bb.ymin, bb.ymax):
                        self.id_[x - self.x0, y - self.y0] = 4 # grid lines
                        dirty.add((x - self.x0, y - self.y0))

            for y in range(bb.ymin, bb.ymax):
                if y % 128 == 0:
                    for x in range(bb.xmin, bb.xmax):
                        self.id_[x - self.x0, y - self.y0] = 4 # grid lines
                        dirty.add((x - self.x0, y - self.y0))

            self.needs_to_draw_grid = False

    # Returns a list of (x, y, color)
    def draw_player(self, tick):
        for event in self.player_pos.until(tick):
            self.last_seen = event[1]

        c = self.player_color

        pixels = []
        for x, y in self.last_seen:
            for dx, dy in cursor:
                if self.bb.inrange(x + dx, y + dy):
                    pixels.append((x + dx - self.x0, y + dy - self.y0, c))
        return pixels

    def update_overlay(self, tick, dirty, transient_pixels):
        self.update_grid(dirty)

        transient_pixels.extend(self.draw_player(tick))
]==])
table.insert(filename, "timelapse/overlay_layer.py")

-- py/run.py
table.insert(content, [==[# Assumes log version 0.0.1
#
# To run:
#       python run.py [length-in-seconds] [fps]

#########################
# Customizing the movie #
#########################
#
#   First, create a movie object:
#       m = movie.Movie(name)
#   'name' is the name of recording. If omitted, it takes the
#   recording of the game most recently started.
#
#   Start the movie, create some scenes, and then end the movie:
#       m.start_movie(movie_name, fps)
#       [make some scenes]
#       m.end_movie()
#
#   movie_name is the filename within the movie directory you wish to save to,
#   including extension. (Can be omitted for default.)
#   fps is frame per second; defaults to 30
#
#
#   If all of your scenes are screenshots (you have no movies), you should omit
#   start_movie() and end_movie():
#
#       m = movie.Movie(name)
#       [make some scenes, each of which is a screenshot]
#
#   Make sure not to call any of the functions (described below) which are only for movies.
#
#
#
#
#   Make one or more scene, and customize each scene. For saving a screenshot:
#
#       scene = m.new_scene()
#       [customize scene options]
#       scene.render_image(image_name, tick)
#
#   image_name is the filename within the images directory you wish to save to,
#   including extension. (Can be omitted for default.)
#   tick is on which game tick you want the screenshot. If omitted, the default
#   is immediately after the last event in the log.
#
#   For saving part of a movie:
#
#       scene = m.new_scene()
#       [customize scene options]
#       scene.set_time_frames(...) or scene.set_time_seconds(...)
#       scene.set_movie_real_time(...) or scene.set_movie_entity_time(...) or scene.set_ticks(...)
#       scene.render_scene(save_end, save_start)
#
#   set_time_*(...) controls how long the movie is, how long to pause on the last frame,
#   and how long to fade in and out at the beginning and end.
#   set_time_frames() takes time in number of frames
#   set_time_seconds() takes time in seconds
#
#   set_time_* must be called before set_movie_* !
#
#   set_movie_real_time(start, end) sets the movie to run linearly from the specified
#   starting game tick to the specified ending game tick. If omitted, defaults to run from
#   beginning of game to immediately after the event in the log.
#   set_movie_entity_time(start, end) does the same, but speeds up / down so that entities
#   are built at a steady rate (in particular, any long gaps with no activity will be skipped)
#
#   set_ticks(ticks) takes a list of ticks, in ascending order, and renders frames on those
#   ticks. The movie still will fade in and out (if those have not been changed to 0), but
#   will not pause on the last frame unless you explicitly repeat that tick in the given list.
#
#   render_scene() saves the scene. save_end (default True) will save a screenshot of the
#   last frame. save_start (default False) will save a screenshot of the first frame.
#
#
#   After m.end_movie() you can call m.add_music() if you have ffmpeg installed on your system.
#
#
#
#
#   Scene customizations (all optional):
#       
#           scene.set_bb(bb)
#
#       Sets the bounding box of which coordinates are rendered. By default, a rectangle
#       around all built entities is chosen (with a small margin). See bounding_box if you want
#       to make your own.
#
#           scene.set_flip(flip)
#
#       Default False. If True, flips x and y coordinates in the movie. Good for if your base
#       is taller than it is wide.
#
#           scene.set_show_grid(show_grid)
#
#       Default False. If True, adds a regular grid to the output. Useful for helping you choose
#       your bounding box. The grid is drawn on x / y coordinates which are a multiple of 128.
#
#           scene.set_target_resolution(dx, dy)
#
#       Specifies the resolution of the movie file. (Note that, if flip is True, then dx will
#       be the height and dy will be the width.) By default, the movie will be rendered with
#       each Factorio tile being 1 pixel. If a resolution is specified smaller than that, then the
#       bounding box will be clipped to fit in the specified resolution. If bigger, then
#       the movie will be enlarged to some integer number of pixels for each Factorio tile.
#       The movie will be letterboxed if the resolution is not an integer multiple.
#
#       If you have multiple animated scenes in the same movie their target resolutions must agree!
#       Target resolutions of screenshots are unrestricted, only animated scenes need to agree.
#
#       If target resolution is not a multiple of 16 x 16 ffmpeg may complain.

import sys

import movie

def example():
    import os
    import boundingbox

    # Use my system's version of fmpeg instead of the one bundled with imageio-ffmpeg,
    # because my system's is more up to date
    os.environ['IMAGEIO_FFMPEG_EXE'] = 'ffmpeg'


    # The name of the recording to read
    name = '382321879'

    # Customize some bounding boxes
    x0 = 740
    y0 = 60
    bb1 = boundingbox.BoundingBox(-356, -270 + y0, 604, 270 + y0)
    bb2 = boundingbox.BoundingBox(-1248 + x0, -540 + y0, 672 + x0, 540 + y0)

    # Specify explicit time intervals
    t0 = 60
    t1 = 456800
    t2 = 478801

    # Start the movie! By default use 'mandelbrot' for output files.
    m = movie.Movie(recording_name = name, filename = 'mandelbrot')

    m.start_movie(fps = 60)

    scene = m.new_scene()
    scene.set_bb(bb1)
    scene.set_target_resolution(1920, 1080)
    # 120 seconds, 2 second pause at end, 1 second fade in, 0.5 second fade out
    scene.set_time_seconds(120, 2, 1, 0.5)
    scene.set_movie_real_time(t0, t1)
    scene.render_scene(False) # False means not to save a screenshot of the ending

    scene = m.new_scene()
    scene.set_bb(bb2)
    scene.set_target_resolution(1920, 1080)
    # 55 seconds, 5 second pause at end, 0.5 second fade in, 2 second fade out
    scene.set_time_seconds(55, 5, 0.5, 2)
    scene.set_movie_real_time(t1, t2)
    scene.render_scene()

    m.end_movie()

    # Add music. Requires ffmpeg to be installed on your system.
    m.add_music(movie.factorio_music_path + 'expansion.ogg')



def run():
    length = 120
    if len(sys.argv) >= 2:
        length = float(sys.argv[1])

    fps = 30
    if len(sys.argv) >= 3:
        fps = float(sys.argv[2])

    m = movie.Movie()
    m.start_movie(fps = fps)

    scene = m.new_scene()
    scene.set_time_seconds(length)
    scene.set_movie_real_time()
    scene.render_scene()

    m.end_movie()

if __name__ == "__main__":
    run()
]==])
table.insert(filename, "timelapse/run.py")

-- py/terrain_layer.py
table.insert(content, [==[import numpy as np

def base32(c):
    ord_c = ord(c)
    if ord_c >= ord('a'):
        return ord_c - ord('a')
    else:
        return ord_c - ord('A') + 26

# Returns a list of 1024 bools
allland = [True] * 1024
allwater = [False] * 1024
def decode(code):
    if code == '0':
        return allwater
    if code == '1':
        return allland
    out = []
    curland = True
    idx = 0
    while idx < len(code):
        if code[idx] == '_':
            num = base32(code[idx + 1]) * 32 + base32(code[idx + 2])
            idx += 3
        else:
            num = base32(code[idx])
            idx += 1
        out.extend([curland] * num)
        curland = not curland
    out.extend([curland] * (1024 - len(out)))
    return out

class TerrainLayer:
    def __init__(self, bb, data):
        self.bb = bb
        dx = bb.dx()
        dy = bb.dy()
        self.x0 = bb.xmin
        self.y0 = bb.ymin

        self.charted = np.zeros((dx, dy), dtype = bool)
        self.id_ = np.zeros((dx, dy), dtype = int)

        self.chart_events = data.charts.iterator()
        self.tile_events = data.tile_history.iterator()

    # update_charts must be before update_tiles
    def update_charts(self, tick, dirty):
        bb = self.bb
        for _, x, y, code in self.chart_events.until(tick):
            x *= 32
            y *= 32

            if x <= bb.xmax and y <= bb.ymax and x + 32 >= bb.xmin and y + 32 >= bb.ymin:
                tiles = decode(code)
                for dx in range(32):
                    for dy in range(32):
                        if self.bb.inrange(x + dx, y + dy):
                            x1 = x + dx - self.x0
                            y1 = y + dy - self.y0
                            self.charted[x1, y1] = True
                            if tiles[32 * dy + dx]:
                                self.id_[x1, y1] = 2 # land
                            else:
                                self.id_[x1, y1] = 1 # water
                            dirty.add((x1, y1))

    def update_tiles(self, tick, dirty):
        for _, id_, x, y in self.tile_events.until(tick):
            if self.bb.inrange(x, y):
                self.id_[x - self.x0, y - self.y0] = id_
                dirty.add((x - self.x0, y - self.y0))
]==])
table.insert(filename, "timelapse/terrain_layer.py")

-- py/movie.py
table.insert(content, [==[import os
import os.path
import time
import subprocess

import numpy as np
import imageio

import read_log

from entity_layer import EntityLayer
from terrain_layer import TerrainLayer
from overlay_layer import OverlayLayer
from resource_layer import ResourceLayer

class Timer:
    def __init__(self):
        self.total = 0
        self.start = None

    def __enter__(self):
        self.start = time.process_time()

    def __exit__(self, a, b, c):
        self.total += time.process_time() - self.start

    def __str__(self):
        return str(self.total)

def flip_xy(frame):
    return np.transpose(frame, (1, 0))


msg_frame = "Made frame {} of {} at tick {}: {} dirty pixels since last message"
msg_summary = """
{} frames; each is {} x {} and has {} MB of data
Average {} dirty pixels per frame
{} ticks from {} to {}
Timing (seconds):
    overlay             {}
    entity              {}
    resources           {}
    chart               {}
    tile                {}
    dirty pixel update  {}
    write               {}
    total               {}
Number of missing entities {}
Bounding box {}
"""

def guess_name():
    name = None
    with open('recordings/catalog', 'r') as f:
        for line in f:
            line = line.strip()
            if len(line) > 0:
                name = line.split()[0]
    return name

ffmpeg_params = [
        '-nostats',
        '-nostdin',
        '-profile:v', 'high',
        '-level', '4.2',
        '-preset', 'slower',
        '-crf', '15',
        '-x264-params', 'ref=4',
        '-movflags',
        '+faststart']

home_dir = '/home/user/home/'
factorio_music_path = home_dir + '.local/share/Steam/steamapps/common/Factorio/data/base/sound/ambient/'

class Movie:
    def __init__(self, recording_name = None, filename = None):
        if recording_name is None:
            recording_name = guess_name()
            assert not (recording_name is None)
        if filename is None:
            filename = recording_name

        self.recording_name = recording_name
        self.filename = filename

        self.data = read_log.Data(recording_name)
        self.writer = None
        self.fps = None

    def start_movie(self, movie_name = None, fps = 30):
        if not (self.writer is None):
            print("Movie already started!")
            assert False

        if movie_name is None:
            movie_name = self.filename + '.mp4'

        self.fps = fps

        os.makedirs('movies', exist_ok = True)
        self.movie_file = os.path.join('movies', movie_name)

        self.writer = imageio.get_writer(self.movie_file, mode = 'I',
                fps = fps,
                codec = 'libx264',
                ffmpeg_log_level = 'info',
                quality = 10,
                macro_block_size = 1,
                ffmpeg_params = ffmpeg_params)

    def new_scene(self):
        return SceneInfo(self)

    def end_movie(self):
        if self.writer is None:
            print("Movie already ended!")
            assert False
        self.writer.close()
        self.writer = None
        self.fps = None

        print("Saved movie to", self.movie_file)

    def add_music(self, music_file):
        if not (self.writer is None):
            print("Should finish writing movie before adding music")
            assert False

        subprocess.run([
            'ffmpeg',
            '-i', self.movie_file,
            '-i', music_file,
            '-codec', 'copy',
            '-shortest',
            os.path.join('movies', self.filename + '_music.mp4')])

class SceneInfo:
    def __init__(self, movie):
        self.movie = movie
        self.data = movie.data
        self.set_time_frames()
        self.set_movie_real_time()
        self.set_bb()
        self.target_resolution = None
        self.flip = False
        self.show_grid = False

    def render_image(self, image_name = None, tick = None):
        if image_name is None:
            image_name = self.movie.filename + '.png'

        if tick is None:
            tick = self.data.maxtick + 1
        self.set_time_frames(1, 0, 0, 0)
        self.ticks = [tick]

        first_frame, final_frame = write_frames(self, NullWriter())
        self.save_image(final_frame, image_name)

    def render_scene(self, save_end = True, save_start = False):
        if self.movie.writer is None:
            print("Need to start movie before rendering any scenes!")
            assert False

        first_frame, final_frame = write_frames(self, self.movie.writer)

        gametime = self.ticks[-1] - self.ticks[0]
        frames = self.frames_moving - 1
        if frames <= 0:
            frames = 1
        print('Game ticks per frame', gametime / frames)
        print('Speed-up', self.movie.fps * gametime / frames / 60)
        a, b = self.data.entities_created.interval(self.ticks[0], self.ticks[-1] + 1)
        print('Entity updates per frame', (b - a) / frames)

        if save_start:
            self.save_image(first_frame, self.movie.filename + '_start.png')
        if save_end:
            self.save_image(final_frame, self.movie.filename + '_end.png')

    def save_image(self, frame, name):
        os.makedirs('images', exist_ok = True)
        image_file = os.path.join('images', name)
        imageio.imwrite(image_file, frame)
        print("Saved screenshot to", image_file)

    def set_movie_ticks(self, ticks):
        self.ticks = ticks

    # Call *after* setting number of frames
    def set_movie_real_time(self, start = None, end = None):
        if start is None:
            start = 60
        if end is None:
            end = self.data.maxtick + 1

        self.ticks = list(np.linspace(start, end, self.frames_moving))
        self.ticks.extend([end] * self.frames_pause)

    # Call *after* setting number of frames
    def set_movie_entity_time(self, start = None, end = None):
        if start is None:
            start = 60
        if end is None:
            end = self.data.maxtick + 1

        self.ticks = list(self.data.entities_created.
                uniform_sampling(start, end, self.frames_moving))
        self.ticks.extend([end] * self.frames_pause)

    def set_time_frames(self, num_frames = 3600, pause_at_end = 150, fade_in = 15, fade_out = 15):
        self.num_frames = num_frames
        self.frames_pause = pause_at_end
        self.frames_fade_in = fade_in
        self.frames_fade_out = fade_out
        self.frames_moving = num_frames - pause_at_end - fade_in - fade_out

        assert fade_in >= 0 and fade_out >= 0 and pause_at_end >= 0 and self.frames_moving >= 1

    def set_time_seconds(self, seconds = 120, pause_at_end = 5,
                    fade_in = 0.5, fade_out = 0.5, fps = None):

        if fps is None:
            fps = self.movie.fps
        self.set_time_frames(
                int(fps * seconds + 0.5),
                int(fps * pause_at_end + 0.5),
                int(fps * fade_in + 0.5),
                int(fps * fade_out + 0.5))

    def set_bb(self, bb = None):
        if bb is None:
            self.bb = self.data.entity_range.copy().add_margin(32).align(32)
        else:
            self.bb = bb.copy()
        if self.bb.dx() <= 0 or self.bb.dy() <= 0:
            raise ValueError("Bounding box cannot be smaller than 1x1!")

    def set_flip(self, flip):
        self.flip = flip

    def set_show_grid(self, show_grid):
        self.show_grid = show_grid

    def set_target_resolution(self, dx, dy):
        if dx <= 0 or dy <= 0:
            raise ValueError("Target resolution cannot be smaller than 1x1! {} x {}".format(dx, dy))
        self.target_resolution = (dx, dy)

    # Call *after* setting bb and target resolution
    def calculate_zoom(self):
        if self.target_resolution is None:
            if ((self.bb.dx() % 2) != 0) or ((self.bb.dy() % 2) != 0):
                print("Warning: using an odd resolution makes many media players unhappy!")
            if ((self.bb.dx() % 16) != 0) or ((self.bb.dy() % 16) != 0):
                print("Warning: some codecs require resolutions to be a multiple of 16 x 16")

            self.zoom = None
        else:
            tdx, tdy = self.target_resolution

            assert tdx > 0 and tdy > 0

            if ((tdx % 2) != 0) or ((tdy % 2) != 0):
                print("Warning: using an odd resolution makes many media players unhappy!")
            if ((tdx % 16) != 0) or ((tdy % 16) != 0):
                print("Warning: some codecs require resolutions to be a multiple of 16 x 16")

            if tdx < self.bb.dx():
                print("Warning: target resolution is too small! Movie is clipped in x direction")
                self.bb.xmin = ((self.bb.xmin + self.bb.xmax - tdx) // 2)
                self.bb.xmax = self.bb.xmin + tdx

            if tdy < self.bb.dy():
                print("Warning: target resolution is too small! Movie is clipped in y direction")
                self.bb.ymin = ((self.bb.ymin + self.bb.ymax - tdy) // 2)
                self.bb.ymax = self.bb.ymin + tdy

            self.zoom = min(tdx // self.bb.dx(), tdy // self.bb.dy())
            assert self.zoom >= 1
            self.x0 = (tdx - self.bb.dx() * self.zoom) // 2
            self.y0 = (tdy - self.bb.dy() * self.zoom) // 2
            assert self.x0 >= 0 and self.y0 >= 0

            print("Zoom level:", self.zoom)
            print("Letterboxing:", tdx - self.bb.dx() * self.zoom, tdy - self.bb.dy() * self.zoom)

class NullWriter:
    def append_data(self, frame):
        pass

# Returns the first and last frames of the movie
# Pass a writer from imageio to write a movie, or NullWriter() to write no movie
# progress is how many frames between printing progress status to stdout
# (Use progress = 0 to suppress printing progress)
def write_frames(scene_info, writer, progress = 30):
    scene_info.calculate_zoom()
    data = scene_info.data
    bb = scene_info.bb
    flip = scene_info.flip

    z = scene_info.zoom
    zoomed = not (z is None)
    if zoomed:
        x0 = scene_info.x0
        y0 = scene_info.y0

    if zoomed:
        if scene_info.flip:
            dy, dx = scene_info.target_resolution
        else:
            dx, dy = scene_info.target_resolution
    else:
        if scene_info.flip:
            dx = bb.dy()
            dy = bb.dx()
        else:
            dx = bb.dx()
            dy = bb.dy()


    id2color = data.attr.id2color
    id2active_id = data.attr.id2active_id
    void_id = 0
    void_color = id2color[void_id]

    overlay_layer = OverlayLayer(bb, data, scene_info.show_grid)
    entity_layer = EntityLayer(bb, data)
    resource_layer = ResourceLayer(bb, data)
    terrain_layer = TerrainLayer(bb, data)

    charted = terrain_layer.charted
    terrain_id = terrain_layer.id_
    entity_id = entity_layer.id_
    entity_is_miner = entity_layer.is_miner
    num_mining = entity_layer.num_mining
    resource_id = resource_layer.id_
    overlay_id = overlay_layer.id_

    def get_pixel_id(x, y):
        if overlay_id[x, y] > 0:
            return overlay_id[x, y]
        elif charted[x, y]:
            if resource_id[x, y] > 0:
                if entity_id[x, y] > 0 and (not entity_is_miner[x, y]):
                    return entity_id[x, y]

                if num_mining[x, y] > 0:
                    return id2active_id[resource_id[x, y]]
                else:
                    return resource_id[x, y]


            if entity_id[x, y] > 0:
                return entity_id[x, y]
            else:
                return terrain_id[x, y]
        else:
            return void_id


    frame = np.zeros((dy, dx, 3), dtype = np.uint8)
    frame[:, :, :] = void_color[None, None, :]

    first_frame = None

    timers = [Timer() for i in range(7)]

    start = time.perf_counter()

    num_dirty = 0
    total_dirty = 0
    dirty = set()

    for i, tick in enumerate(scene_info.ticks):
        transient_pixels = []

        with timers[0]:
            overlay_layer.update_overlay(tick, dirty, transient_pixels)
        with timers[1]:
            entity_layer.update_entities(tick, dirty)
        with timers[2]:
            resource_layer.update_resources(tick, dirty)
        with timers[3]:
            terrain_layer.update_charts(tick, dirty)
        with timers[4]:
            terrain_layer.update_tiles(tick, dirty)
        # Charts must be updated before tiles

        with timers[5]:
            if zoomed:
                if flip:
                    for x, y in dirty:
                        c = id2color[get_pixel_id(x, y)]
                        for xa in range(x0 + x * z, x0 + (x + 1) * z):
                            for ya in range(y0 + y * z, y0 + (y + 1) * z):
                                frame[xa, ya, :] = c
                else:
                    for x, y in dirty:
                        c = id2color[get_pixel_id(x, y)]
                        for xa in range(x0 + x * z, x0 + (x + 1) * z):
                            for ya in range(y0 + y * z, y0 + (y + 1) * z):
                                frame[ya, xa, :] = c
            else:
                if flip:
                    for x, y in dirty:
                        frame[x, y, :] = id2color[get_pixel_id(x, y)]
                else:
                    for x, y in dirty:
                        frame[y, x, :] = id2color[get_pixel_id(x, y)]

            cur_dirty = len(dirty) + len(transient_pixels)
            num_dirty += cur_dirty
            total_dirty += cur_dirty
            dirty.clear()

            if zoomed:
                if flip:
                    for x, y, c in transient_pixels:
                        dirty.add((x, y))
                        for xa in range(x0 + x * z, x0 + (x + 1) * z):
                            for ya in range(y0 + y * z, y0 + (y + 1) * z):
                                frame[xa, ya, :] = c
                else:
                    for x, y, c in transient_pixels:
                        dirty.add((x, y))
                        for xa in range(x0 + x * z, x0 + (x + 1) * z):
                            for ya in range(y0 + y * z, y0 + (y + 1) * z):
                                frame[ya, xa, :] = c

            else:
                if flip:
                    for x, y, c in transient_pixels:
                        dirty.add((x, y))
                        frame[x, y, :] = c
                else:
                    for x, y, c in transient_pixels:
                        dirty.add((x, y))
                        frame[y, x, :] = c

        if first_frame is None:
            first_frame = np.copy(frame)
            with timers[6]:
                for j in range(scene_info.frames_fade_in):
                    l = j / scene_info.frames_fade_in
                    fade_frame = (first_frame * l).astype(np.uint8)
                    writer.append_data(fade_frame)

        with timers[6]:
            writer.append_data(frame)

        if (progress > 0) and ((i + 1) % progress == 0):
            m = msg_frame.format(i + 1, len(scene_info.ticks), tick, num_dirty)
            num_dirty = 0
            print(m)

    with timers[6]:
        for j in range(scene_info.frames_fade_out):
            l = 1 - ((j + 1) / scene_info.frames_fade_out)
            fade_frame = (frame * l).astype(np.uint8)
            writer.append_data(fade_frame)

    total_time = time.perf_counter() - start

    miss = entity_layer.missing_entities

    m = msg_summary.format(
                len(scene_info.ticks), dx, dy, dx * dy * 3 / (2 ** 20),
                total_dirty / len(scene_info.ticks),
                len(scene_info.ticks), scene_info.ticks[0], scene_info.ticks[-1],
                timers[0], timers[1], timers[2], timers[3], timers[4], timers[5], timers[6],
                total_time,
                len(miss),
                bb
            )
    print(m)

    if len(miss) > 0:
        print("Missing entities:")
        if len(miss) > 40:
            print(miss[:20])
            print('...')
            print(miss[-20:])
        else:
            print(miss)

    return (first_frame, frame)
]==])
table.insert(filename, "timelapse/movie.py")

-- py/boundingbox.py
table.insert(content, [==[class BoundingBox:
    def __init__(self, x0 = None, y0 = None, x1 = None, y1 = None):
        self.xmin = x0
        self.ymin = y0
        self.xmax = x1
        self.ymax = y1

    def update(self, x, y):
        if self.xmax is None:
            self.xmax = x + 1
            self.xmin = x
            self.ymax = y + 1
            self.ymin = y
        else:
            self.xmax = max(x + 1, self.xmax)
            self.xmin = min(x, self.xmin)
            self.ymax = max(y + 1, self.ymax)
            self.ymin = min(y, self.ymin)

    def copy(self):
        return BoundingBox(self.xmin, self.ymin, self.xmax, self.ymax)

    def add_margin(self, margin):
        self.xmax += margin
        self.xmin -= margin
        self.ymax += margin
        self.ymin -= margin
        return self

    def align(self, k):
        x = k - 1 - (self.dx() - 1) % k
        y = k - 1 - (self.dy() - 1) % k
        self.xmin -= (x // 2)
        self.xmax += ((x + 1) // 2)
        self.ymin -= (y // 2)
        self.ymax += ((y + 1) // 2)
        return self

    def inrange(self, x, y):
        return x >= self.xmin and x < self.xmax and y >= self.ymin and y < self.ymax

    def dx(self):
        return self.xmax - self.xmin

    def dy(self):
        return self.ymax - self.ymin

    def __str__(self):
        return '({}, {}) to ({}, {})'.format(self.xmin, self.ymin, self.xmax, self.ymax)
]==])
table.insert(filename, "timelapse/boundingbox.py")

-- py/entity_attributes.py
table.insert(content, [==[import re
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
]==])
table.insert(filename, "timelapse/entity_attributes.py")



function write_py_files()
    for i = 1, #content do
        game.write_file(filename[i], content[i], false)
    end
end
