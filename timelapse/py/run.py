# Assumes log version 0.0.1
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
