#!/bin/python

import numpy as np
import imageio

def make_map():
    source_file = 'worldmap.png'
    dest_file = 'worldmap.lua'

    data = imageio.imread(source_file)
    print(data.shape, data.dtype)

    land = (data[:, :, 0] < 255) & (data[:, :, 3] == 255)

    xs, ys = np.nonzero(land)

    x0 = np.min(xs)
    x1 = np.max(xs) + 1
    y0 = np.min(ys)
    y1 = np.max(ys) + 1

    while (y1 - y0) % 4 > 0:
        y1 += 1

    land = land[x0:x1, y0:y1]
    print(land.shape, land.dtype)

    land_hex = 8 * land[:, ::4] + 4 * land[:, 1::4] + 2 * land[:, 2::4] + 1 * land[:, 3::4]
    print(land_hex.shape, land_hex.dtype)

    chars = 'abcdefghijklmnop'

    with open(dest_file, 'w') as f:
        rows, cols = land_hex.shape
        f.write('local pixels = {}\n')
        text = 'pixels[{}]="{}"\n'
        for row in range(rows):
            f.write(text.format(row + 1, ''.join([chars[v] for v in land_hex[row]])))
        f.write('return table.concat(pixels)\n')

if __name__ == "__main__":
    make_map()
