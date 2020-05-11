import numpy as np

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
