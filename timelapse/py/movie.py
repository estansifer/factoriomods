import os
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
