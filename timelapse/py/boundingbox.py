class BoundingBox:
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
