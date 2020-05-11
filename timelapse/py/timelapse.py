# Assumes log format version is 0.0.1
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
