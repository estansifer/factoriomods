import math
import numpy as np
import numpy.random as npr
import scipy.special as ss

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

class Perlin:
    def __init__(self, N = 47):
        self.N = N

        angles = npr.random((N, N)) * 2 * math.pi
        self.cx = np.cos(angles)
        self.cy = np.sin(angles)

    def height(self, x, y):
        x_ = math.floor(x)
        y_ = math.floor(y)
        x = x - x_
        y = y - y_

        i0 = x_ % self.N
        i1 = (i0 + 1) % self.N
        j0 = y_ % self.N
        j1 = (j0 + 1) % self.N

        a = self.cx
        b = self.cy

        sx = x * x * x * (x * (x * 6 - 15) + 10)
        sy = y * y * y * (y * (y * 6 - 15) + 10)

        return (
                (a[i0, j0] * x + b[i0, j0] * y) * (1 - sx) * (1 - sy) +
                (a[i1, j0] * (x - 1) + b[i1, j0] * y) * sx * (1 - sy) +
                (a[i0, j1] * x + b[i0, j1] * (y - 1)) * (1 - sx) * sy +
                (a[i1, j1] * (x - 1) + b[i1, j1] * (y - 1)) * sx * sy
            )

    # Returns (dh/dx, dh/dy)
    def heights(self, x, y):
        x_ = math.floor(x)
        y_ = math.floor(y)
        x = x - x_
        y = y - y_

        i0 = x_ % self.N
        i1 = (i0 + 1) % self.N
        j0 = y_ % self.N
        j1 = (j0 + 1) % self.N

        a = self.cx
        b = self.cy

        sx = x * x * x * (x * (x * 6 - 15) + 10)
        sy = y * y * y * (y * (y * 6 - 15) + 10)
        dsx = x * x * (x * (x * 30 - 60) + 30)
        dsy = y * y * (y * (y * 30 - 60) + 30)

        return (
                (a[i0, j0] * x + b[i0, j0] * y) * (1 - sx) * (1 - sy) +
                (a[i1, j0] * (x - 1) + b[i1, j0] * y) * sx * (1 - sy) +
                (a[i0, j1] * x + b[i0, j1] * (y - 1)) * (1 - sx) * sy +
                (a[i1, j1] * (x - 1) + b[i1, j1] * (y - 1)) * sx * sy,

                (a[i0, j0] * (1 - sx) - (a[i0, j0] * x + b[i0, j0] * y) * dsx) * (1 - sy) +
                (a[i1, j0] * sx + (a[i1, j0] * (x - 1) + b[i1, j0] * y) * dsx) * (1 - sy) +
                (a[i0, j1] * (1 - sx) - (a[i0, j1] * x + b[i0, j1] * (y - 1)) * dsx) * sy +
                (a[i1, j1] * sx + (a[i1, j1] * (x - 1) + b[i1, j1] * (y - 1)) * dsx) * sy,

                (b[i0, j0] * (1 - sy) - (a[i0, j0] * x + b[i0, j0] * y) * dsy) * (1 - sx) +
                (b[i1, j0] * (1 - sy) - (a[i1, j0] * (x - 1) + b[i1, j0] * y) * dsy) * sx +
                (b[i0, j1] * sy + (a[i0, j1] * x + b[i0, j1] * (y - 1)) * dsy) * (1 - sx) +
                (b[i1, j1] * sy + (a[i1, j1] * (x - 1) + b[i1, j1] * (y - 1)) * dsy) * sx
            )

class Interpolate:
    def __init__(self, values):
        self.values = values
        self.A = values.shape[0]
        self.B = values.shape[1]

    def eval(self, x, y):
        i = math.floor(x)
        j = math.floor(y)
        x = x - i
        y = y - j
        i = i % self.A
        j = j % self.B

        v = self.values

        r = v[i, j]             * (1 - x) * (1 - y)
        r += v[i + 1, j]        * x * (1 - y)
        r += v[i, j + 1]        * (1 - x) * y
        r += v[i + 1, j + 1]    * x * y

        return r

class Integrator:
    def __init__(self, noise, k = 12, maxstepsize = 1 / 10, integration_time = 1.3):
        self.N = noise.N
        self.k = k
        self.noise = noise

        self.numsteps = int(integration_time / maxstepsize + 0.9999)
        self.step = (integration_time / self.numsteps) / 2

        Nk = self.N * k

        vec = np.zeros((Nk, Nk, 2))
        for i in range(Nk):
            for j in range(Nk):
                vec[i, j] = self.compute(i / k, j / k)

        self.interpolate = Interpolate(vec)

    def compute(self, x, y):
        h = self.noise.heights
        s = self.step

        x0 = x
        y0 = y

        # hs0 = h(x, y)[0]

        for i in range(self.numsteps):
            hs1 = h(x, y)
            hs2 = h(x - hs1[2] * s,         y + hs1[1] * s)
            hs3 = h(x - hs2[2] * s,         y + hs2[1] * s)
            hs4 = h(x - hs3[2] * s * 2,     y + hs3[1] * s * 2)

            x = x - (s / 3) * (hs1[2] + 2 * hs2[2] + 2 * hs3[2] + hs4[2])
            y = y + (s / 3) * (hs1[1] + 2 * hs2[1] + 2 * hs3[1] + hs4[1])

        return (x - x0, y - y0)

    def eval(self, x, y):
        return self.interpolate.eval(x * self.k, y * self.k)


def test1():
    p = Perlin()
    N = 500
    x = np.linspace(0, 3, N)
    y = np.linspace(0, 3, N)

    I = Integrator(p)
    print("Done sampling height field")

    h = np.zeros((N, N))
    dhdx = np.zeros((N, N))
    dhdy = np.zeros((N, N))
    v = np.zeros((N, N, 2))
    c = np.zeros((N, N))

    for i in range(N):
        for j in range(N):
            # h[i, j], dhdx[i, j], dhdy[i, j] = p.heights(x[i], y[j])
            h[i, j], dhdx[i, j], dhdy[i, j] = 0, 0, 0
            v[i, j] = I.eval(x[i], y[j])
            a = math.floor((x[i] + v[i, j, 0]) * 2)
            b = math.floor((y[j] + v[i, j, 1]) * 2)
            if (a + b) % 2 == 1:
                c[i, j] = 1

    print("Done sampling integrator")

    m0 = np.min(h)
    m1 = np.max(h)
    s = np.size(h)
    avg = np.sum(h) / s
    v = np.sum(h * h) / s - avg ** 2

    print(m0, m1, s, avg, v)

    plt.clf()
    plt.imshow(c, cmap = plt.cm.gray, aspect = 'equal')
    plt.savefig('distort.png')

    plt.clf()
    plt.imshow(h, cmap = plt.cm.gray, aspect = 'equal')
    plt.savefig('h.png')

    plt.clf()
    plt.imshow(dhdx, cmap = plt.cm.gray, aspect = 'equal')
    plt.savefig('h_dx.png')

    plt.clf()
    plt.imshow(dhdy, cmap = plt.cm.gray, aspect = 'equal')
    plt.savefig('h_dy.png')

def inverf(x):
    c = 0.147
    y = (1 - x) * (1 + x)
    logy = math.log(y)
    t1 = 2 / (math.pi * c) + logy / 2
    t2 = logy / c
    res = math.sqrt(-t1 + math.sqrt(t1 * t1 - t2))
    if x < 0:
        return -res
    else:
        return res

for x in [-0.9999, -0.5, 0, 0.5, 0.9, 0.99, 0.999, 0.9999, 0.99999]:
    i1 = inverf(x)
    i2 = ss.erfinv(x)
    print(x, i1, i2, i1 - i2, ss.erf(i1), ss.erf(i1) - x)

def go():
    pass

if __name__ == "__main__":
    go()
