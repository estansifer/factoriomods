import os

header = """
local content = {}
local filename = {}

"""
footer = """

function write_py_files()
    for i = 1, #content do
        game.write_file(filename[i], content[i], false)
    end
end
"""

def quote_file(filename, out):
    with open('py/' + filename, 'r') as f:
        if not filename.endswith('.py'):
            print("Skipping file", filename)
            return

        print("Copying file", filename)

        content = f.read()

        out.write('-- py/{}\n'.format(filename))
        out.write('table.insert(content, [==[{}]==])\n'.format(content))
        out.write('table.insert(filename, "{}")\n\n'.format('timelapse/' + filename))

def go():
    with open('write_py.lua', 'w') as out:
        out.write(header)

        for filename in os.listdir('py'):
            quote_file(filename, out)

        out.write(footer)

if __name__ == "__main__":
    go()
