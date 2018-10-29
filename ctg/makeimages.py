import numpy as np
import imageio

infile = 'rawtext'
outfile = 'map_{:03d}{}_{}.png'

#
# 0     land
# 1     water
# 2     deepwater
# 3     void
#
colors = [
            np.array([206, 169, 52], dtype = np.uint8),
            np.array([0, 40, 220], dtype = np.uint8),
            np.array([0, 20, 140], dtype = np.uint8),
            np.array([0, 0, 0], dtype = np.uint8)
        ]

drawzoombox = True
box_color = np.array([255, 0, 0], dtype = np.uint8)

def make_image(data, width, height, zoom, idx, name):
    name_ = ''
    for c in name:
        if c in ' ;:()[].':
            name_ = name_ + '_'
        else:
            name_ = name_ + c
    if zoom > 1.001:
        filename = outfile.format(idx, '_zoom', name_)
    else:
        filename = outfile.format(idx, '', name_)

    image = np.zeros((height, width, 3), dtype = np.uint8)
    for row in range(height):
        for col in range(width):
            image[row, col, :] = colors[int(data[row][col])]

    if zoom > 1.3 and drawzoombox:
        x0 = int(width * (1 - 1 / zoom) / 2)
        x1 = int(width * (1 + 1 / zoom) / 2)
        y0 = int(height * (1 - 1 / zoom) / 2)
        y1 = int(height * (1 + 1 / zoom) / 2)

        for x in range(x0, x1 + 1):
            image[y0, x, :] = box_color
            image[y1, x, :] = box_color
        for y in range(y0, y1 + 1):
            image[y, x0, :] = box_color
            image[y, x1, :] = box_color

    imageio.imwrite(filename, image)

def process_data():
    idx = 0
    with open(infile) as f:
        while True:
            header = f.readline().strip()
            if len(header) > 0:
                pieces = header.split(maxsplit=3)
                width = int(pieces[0])
                height = int(pieces[1])
                zoom = float(pieces[2])
                name = pieces[3]

                data = []
                for row in range(height):
                    data.append(f.readline().strip())

                make_image(data, width, height, zoom, idx, name)
                idx += 1
            else:
                break

if __name__ == "__main__":
    process_data()
