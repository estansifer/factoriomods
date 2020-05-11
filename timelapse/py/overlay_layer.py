import numpy as np

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
