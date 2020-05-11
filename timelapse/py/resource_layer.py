import numpy as np

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
