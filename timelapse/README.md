# Timelapse

This mod creates a timelapse of your Factorio game.

The mod saves a recording of all entities being placed or removed, chunks being
explored, tiles being placed or removed, resources being explored or mined, with
the exact tick that the event took place. Additionally, the player positions
are recorded every 2 seconds. 

A python script is included to use the recording to create an animation of your
game, or generate a snapshot at any particular moment of time. The animation has
a visual style similar to that of the in-game map view.

It is possible to make an animation of only part of your base or a limited
interval of time. Because events are recorded every tick (a resolution of
1/60 of a second of game time), the animations remain smooth even if the
animation is played at real in-game time.

## How to use

First, read the notes section. Then enable the mod in-game and play. The mod will
save a recording of the game in a text format.

Then, inside of your Factorio folder find the folder "script-output", and a
subfolder "timelapse". Within that is a collection of python files, and another
subfolder "recordings". The latter contains all of your recordings, and the
former the code to read these recordings and create screenshots and movies.

Run

    python run.py

to make a movie of your most recent game, with a screenshot of the end state.

The code requires the python imageio library with the ffmpeg plugin. Run

    pip install imageio
    pip install imageio-ffmpeg

to install the necessary libraries (or use your operating system's package
manager). Typically, imageio-ffmpeg comes with a copy of ffmpeg; if not, you
can install ffmpeg on your system using your operating system's package
manager. For example,

    apt install ffmpeg          # Ubuntu, Debian
    emerge ffmpeg               # Gentoo

I highly recommend testing the ability to make an animation after 15 or so
minutes of gameplay to verify that it works on your system (and to check if
I have any bugs).

## Notes

* By default the movie/screenshot will be sized to include only where you have
built buildings, and the movie will run from the beginning to the end of the
game. These and other parameters can be specified explicitly if you do not
like the defaults. Any python code you write should be put in *new* files
as changes to the existing files in script-output/timelapse/ will be overwritten
by the mod when a new game is started.

* Recordings are saved to disk once every minute, so let one minute pass after
the "end" of your game.

* It should be possible to enable this mod in the middle of an active game,
although this is not tested.

* New buildings / enemies introduced by mods might not appear in the animation,
or possibly not be recorded at all.

* Using Factorio's built-in "replay" feature on a game which had this mod enabled
may result in the recording being overwritten or corrupted in an unpredictable
way. Make a copy of your recording before trying this.

* When reloading a save file (including, for example, if you die in game and choose
not to respawn), the mod will continue to write the gameplay log to the same files,
which can cause multiple overlapping histories to be written together. The mod is
designed to properly handle this situation and should not be confused regardless
of how you jump forwards and backwards, saving and reloading files. However this
facility is difficult to test, so be aware of the possibility of bugs that may
arise in this circumstance.

Starting multiple different games with the same random seed could potentially make
the logs confused (as the different games will be recorded to the same log files),
although even in this circumstance it may work. Note that when starting a new game,
Factorio uses the same seed as the last game if you do not explicitly re-roll it:
check if the map in the preview looks familiar before starting!

Different Factorio games started with different random seeds will always be
recorded independently of each other.

* If you explore more than 500k chunks (16m tiles) from the origin, newly explored
terrain may not be recorded sometimes. Also, your screenshot will be absurdly massive.

* Optimizations have been made to reduce the size of the recordings where possible.
The main contributor to recording size seems to be the number of buildings placed,
followed by tiles being placed. A 70 hour game that launched some dozens of
rockets took about 6MB of space to store the recording. (The actual save file itself
is 18 MB, and a movie of first 24 hours of gameplay is 7 MB.) A megabase paved with
concrete will take significantly more space. You can estimate about 20 bytes per
building and 10 bytes per tile.

* Entities not present in vanilla Factorio will not be recorded.

## Adding music

If you have ffmpeg installed, you can add music to your movie by running:

    ffmpeg -i <input-movie-file> -i <audio-file> -codec copy -shortest <output-movie-file>

Note that if the music is shorter than your movie, your movie will be truncated
due to the "-shortest" option.

## Examples

A timelapse of a two hour game: youtube.com/watch?v=WagzSpVY4QA

From a much older version of the mod, here is a timelapse of a 50 hour game:
youtube.com/watch?v=Iz-BazXtDbs

## Version changes

The mod is unstable and may contain bugs. Upgrades to the mod may break
compatability of the recordings, and continuing a game after upgrading the mod
may make the recording unreadable to both the old and new version of the code.

The "logversion" number should indicate when a mod upgrade breaks compatibility
of recordings, although the reliability of this should not be assumed.

Changes to the python code will be propogated to the script-output/timelapse/
folder when a new game is started with the mod enabled. Note that this will
overwrite any changes you made to the python code.

## Versions
 * 0.0.1 Initial release. logversion = 0.0.1

## License

MIT license
