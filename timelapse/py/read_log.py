import os.path

from boundingbox import BoundingBox
import entity_attributes

logversion = '0.0.1'

def readfile(path):
    result = []
    with open(path) as f:
        for rawline in f:
            result.append(rawline.strip().split(maxsplit = 1))
            # line = rawline.strip()
            # if len(line) > 0 and ('#' not in line):
                # result.append(line.split(maxsplit = 1))
    return result

lognames = [
            'journal',
            'names',
            'entities',
            'entities_removed',
            'tiles_init',
            'tiles',
            'resources',
            'resources_depleted',
            'player_position'
        ]

def warn(true, message, error = False):
    if not true:
        if error:
            print('Error: ' + message)
            assert true
        else:
            print('Warning: ' + message)

class Log:
    def __init__(self, recording_name):
        self.directory = os.path.join('recordings', recording_name)

        self.N = len(lognames)

        self.read_journal()

    def read_journal(self):
        journallines = readfile(os.path.join(self.directory, 'journal'))

        headers = 0
        for i, line in enumerate(journallines):
            if line[1].startswith('logfiles'):
                warn(i + 1 < len(journallines), 'truncated journal header', True)

                l2 = journallines[i + 1][1].split()
                warn(len(l2) > 0 and l2[0] == 'logversion', 'missing log version', True)
                warn(len(l2) == 4, 'can\'t read log version', True)
                warn(l2[3] == logversion,
                    'expected logversion ' + logversion + ' but found logversion ' + l2[3], True)

                headers += 1
                names = line[1].split()[1:]
                warn(len(names) == self.N,
                    'expected {} logs, found {} logs'.format(len(lognames), self.N), True)
                for j in range(self.N):
                    warn(names[j].split('/')[-1] == lognames[j],
                            'found unexpected log name', True)


        warn(headers > 0, 'did not find a header in the journal!')
        msg = ('Found more than one header in journal!' +
            ' Maybe multiple saves are using the same log?')
        warn(headers < 2, msg)

        counts = [0] * self.N
        self.journal_last = None
        self.journal = {}

        for line in journallines:
            if line[1].startswith('log') or line[1].startswith('#'):
                continue

            xs = [int(x) for x in line[1].split()]
            assert len(xs) == 4 + self.N
            tick = xs[0]
            id_ = xs[1]
            last_tick = xs[2]
            last_id = xs[3]

            counts_new = [None] * self.N
            for i in range(self.N):
                counts_new[i] = counts[i] + xs[4 + i]

            self.journal_last = (tick, id_)
            self.journal[self.journal_last] = ((last_tick, last_id), counts, counts_new)

            counts = counts_new

    def get_history(self, journal_entry = None):
        if journal_entry is None:
            journal_entry = self.journal_last

        history = []

        # debug_out = []

        while journal_entry in self.journal:
            history.append(self.journal[journal_entry][1:3])
            # debug_out.append((journal_entry, history[-1]))
            journal_entry = self.journal[journal_entry][0]

        # print("==Journal==")
        # for entry in reversed(debug_out):
            # print(entry)
        # print("==End journal==")

        return list(reversed(history))

    def reduced_log_files(self, journal_entry = None):
        history = self.get_history(journal_entry)

        logs = {}

        for i in range(self.N):
            lines = []
            tick = 0

            rawlines = readfile(os.path.join(self.directory, lognames[i]))
            for c1, c2 in history:
                for rawline in rawlines[c1[i] : c2[i]]:
                    tick += int(rawline[0])
                    if not rawline[1].startswith('#'):
                        lines.append((tick, rawline[1]))

            logs[lognames[i]] = lines

            msg = 'Read {}: '.format(lognames[i])
            while len(msg) < 25:
                msg = msg + ' '

            print(msg, len(lines), '/', len(rawlines))

        return logs

class EventIterator:
    def __init__(self, xs):
        self.xs = xs
        self.num = len(xs)
        self.next = 0

    def until(self, tick):
        while self.next < self.num and self.xs[self.next][0] <= tick:
            yield self.xs[self.next]
            self.next += 1

class EventList:
    def __init__(self, xs):
        self.xs = xs

    def iterator(self):
        return EventIterator(self.xs)

    def interval(self, t1, t2):
        a = 0
        while a < len(self.xs) and self.xs[a][0] < t1:
            a += 1
        b = a
        while b < len(self.xs) and self.xs[b][0] < t2:
            b += 1

        return (a, b)

    def uniform_sampling(self, t1, t2, n):
        if len(self.xs) == 0 or n <= 0:
            return []
        if n == 1:
            return [t1]
        if n == 2:
            return [t1, t2]

        a, b = self.interval(t1, t2)
        ticks = []
        for i in np.linspace(a, b, n):
            j = int(i + 0.5)
            if j < len(self.xs):
                ticks.append(self.xs[j][0])
            else:
                ticks.append(self.xs[-1][0] + 1)
        ticks[0] = t1
        ticks[-1] = t2
        return ticks

idshift = 10

class Data:
    def __init__(self, recording_name):
        logs = Log(recording_name).reduced_log_files()

        self.name = recording_name

        self.maxtick = 0

        self.read_names(logs['names'])
        self.read_entities(logs['entities'], logs['entities_removed'])
        self.read_tiles(logs['tiles'])
        self.read_charts(logs['tiles_init'])
        self.read_resources(logs['resources'], logs['resources_depleted'])
        self.read_player_position(logs['player_position'])

    def read_names(self, names):
        name2id = {}
        content = []
        maxid = idshift
        for tick, line in names:
            a, b = line.split()
            id_ = int(a) + idshift
            content.append((id_, b))
            name2id[b] = id_
            maxid = max(maxid, id_)

        id2name = [None] * (maxid + 1)
        for a, b in content:
            id2name[a] = b

        self.attr = entity_attributes.EntityAttr(id2name, name2id)

    def read_entities(self, entities, entities_removed):
        self.entity_range = BoundingBox()
        l = []

        for tick, line in entities:
            xs = line.split()
            unit = int(xs[0])
            id_ = int(xs[1]) + idshift
            x = int(xs[2])
            y = int(xs[3])
            direction = int(xs[4])

            if not self.attr.is_enemy(id_):
                self.entity_range.update(x, y)
            l.append((tick, unit, id_, x, y, direction))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.entities_created = EventList(l)

        l = []
        for tick, unit in entities_removed:
            l.append((tick, int(unit)))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.entities_removed = EventList(l)

    def read_tiles(self, tiles):
        l = []
        for tick, line in tiles:
            xs = line.split()
            for i in range(len(xs) // 3):
                id_ = int(xs[3 * i]) + idshift
                x = int(xs[3 * i + 1])
                y = int(xs[3 * i + 2])
                l.append((tick, id_, x, y))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.tile_history = EventList(l)

    def read_charts(self, tiles_init):
        self.charted_range = BoundingBox()

        l = []
        for tick, line in tiles_init:
            xs = line.split()
            x = int(xs[0])
            y = int(xs[1])
            l.append((tick, x, y, xs[2]))
            self.charted_range.update(32 * x, 32 * y)
            self.charted_range.update(32 * x + 31, 32 * y + 31)

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.charts = EventList(l)

    def read_resources(self, resources, resources_depleted):
        l = []
        for tick, line in resources:
            xs = line.split()
            id_ = int(xs[0]) + idshift
            x = int(xs[1])
            y = int(xs[2])
            amount = int(xs[3])
            l.append((tick, id_, x, y))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.resources = EventList(l)

        l = []
        for tick, line in resources_depleted:
            xs = line.split()
            id_ = int(xs[0]) + idshift
            x = int(xs[1])
            y = int(xs[2])
            l.append((tick, id_, x, y))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.resources_depleted = EventList(l)

    def read_player_position(self, player_position):
        l = []
        for tick, line in player_position:
            xs = line.split()
            pos = []
            for i in range(len(xs) // 3):
                x = int(float(xs[3 * i + 1]))
                y = int(float(xs[3 * i + 2]))
                pos.append((x, y))

            l.append((tick, pos))

        if len(l) > 0:
            self.maxtick = max(self.maxtick, l[-1][0])

        self.player_position = EventList(l)
