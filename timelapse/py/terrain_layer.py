import numpy as np

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
