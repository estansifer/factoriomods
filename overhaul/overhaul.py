import collections

def counter_mul(self, other):
    assert type(other) is int
    d = self.copy()
    for x in self:
        d[x] = other * self[x]
    return d

collections.Counter.__mul__ = counter_mul
collections.Counter.__rmul__ = counter_mul

def normalize_item_list(x):
    if type(x) is str:
        return collections.Counter({x : 1})
    else:
        assert type(x) is collections.Counter
        return x

def is_fluid(name):
    return name in ['water', 'crude-oil', 'steam', 'lubricant', 'sulfuric-acid']

def item_list_to_lua(c):
    items = []
    for key in c:
        if c[key] == 0:
            continue
        if is_fluid(key):
            items.append('{' + f'type = "fluid", name = "{key}", amount = {c[key]}' + '}')
        else:
            items.append('{' + f'"{key}", {c[key]}' + '}')
    return '{' + ', '.join(items) + '}'

def assert_is_valid(j):
    t = type(j)
    if t is list:
        for x in j:
            assert_is_valid(x)
    elif t is dict:
        for x in j:
            assert type(x) is str
            assert_is_valid(j[x])
    else:
        assert t in [str, int, float, bool]

def deepcopy(j):
    t = type(j)
    if t is list:
        return [deepcopy(x) for x in j]
    if t is dict:
        d = {}
        for x in j:
            d[deepcopy(x)] = deepcopy(j[x])
        return d
    assert t in [str, int, float, bool]
    return j

# This uses a format produced by a specific factorio mod
class DataRaw:
    def __init__(self, items, recipes, techs):
        assert_is_valid(items)
        assert_is_valid(recipes)
        assert_is_valid(techs)
        self.items = items
        self.recipes = recipes
        self.techs = techs

    def read_from_files(folder):
        import json
        with open(folder + '/item.json', 'r') as f:
            i = json.load(f)
        with open(folder + '/recipe.json', 'r') as f:
            r = json.load(f)
        with open(folder + '/technology.json', 'r') as f:
            t = json.load(f)
        return DataRaw(i, r, t)

    def get_item(self, name):
        return self.items[name]

    def get_recipe(self, name):
        return self.recipes[name]

    def get_recipe_by_result(self, result):
        for x in self.recipes.values():
            if x.get('main_product', {}).get('name') == result:
                return x['name']
        # for x in self.data['recipe'].values():
            # if x['result'] == result:
                # return x

    def get_technology(self, name):
        return self.techs.get(name, None)

    def get_technology_that_unlocks(self, name):
        for t in self.techs.values():
            for e in t['effects']:
                if e['type'] == 'unlock-recipe' and e['recipe'] == name:
                    return t['name']

class RecipeBuilder:
    def __init__(self, b, i, r):
        self.data_raw_builder = b
        self.auto_name = None
        self.ingredients = i
        self.result = r
        self._base = None
        self._enabled = None
        self._time = None
        self._category = None

    def base(self, d):
        self._base = d
        return self

    def enabled(self, e = True):
        self._enabled = e
        return self

    def time(self, t):
        self._time = t
        return self

    def category(self, c):
        self._category = c
        return self

class TechnologyBuilder:
    def __init__(self, b):
        self.data_raw_builder = b
        self.auto_name = None

        self.reqs = None
        self.recipes = []
        self.bonuses = []
        self._base = None
        self._ingredients = None
        self._count = None
        self._time = None

    def base(self, d):
        self._base = d
        return self

    def time(self, t):
        self._time = t
        return self

    def count(self, c):
        self._count = c
        return self

    def ingredients(self, i):
        self._ingredients = i
        return self

    def cost(self, ingredients, count = None, time = None):
        self._ingredients = ingredients
        if not (count is None):
            self._count = count
        if not (time is None):
            self._time = time
        return self

    def req(self, *techs):
        if self.reqs is None:
            self.reqs = []
        for tech in techs:
            self.reqs.append(tech)
        return self

    def unlock_recipe(self, recipe):
        recipe.enabled(False)
        self.recipes.append(recipe)
        return self

    # make a recipe
    def r(self, *args, **kwargs):
        recipe = self.data_raw_builder.make_recipe(*args, **kwargs)
        if self._base == None:
            name = list(recipe.result)[0]
            if name in self.data_raw_builder.base.techs:
                self.base(name)
        self.unlock_recipe(recipe)
        return self

    def bonus(self, bonus_type, **kwargs):
        kwargs['type'] = '"' + bonus_type + '"'
        b = [f'{key} = {kwargs[key]}' for key in kwargs]
        b = '{' + ', '.join(b) + '}'
        self.bonuses.append(b)
        return self

    # add child technologies
    # def __call__(self, *deps):
    def child(self, *deps):
        for d in deps:
            d.req(self)
        return self

lua_header = """
function with_prefix(group, prefix)
    prefix = prefix or ""
    results = {}
    for _, x in pairs(data.raw[group]) do
        if (x.name:find(prefix, 1, true) == 1) then
            table.insert(results, x)
        end
    end
    return results
end

function without_prefix(group, prefix)
    prefix = prefix or ""
    results = {}
    for _, x in pairs(data.raw[group]) do
        if not (x.name:find(prefix, 1, true) == 1) then
            table.insert(results, x)
        end
    end
    return results
end

function enable_all(xs, enable)
    if enable == nil then
        enable = true
    end
    for _, x in ipairs(xs) do
        x.enabled = enable
        if x.expensive then
            x.expensive.enabled = enable
        end
        if x.normal then
            x.normal.enabled = enable
        end
    end
end

function research_all(xs, researched)
    if researched == nil then
        researched = true
    end
    for _, x in ipairs(xs) do
        x.researched = researched
    end
end

function adjust_if_is_productive(recipe_name, new_name)
    local is_productive = false
    for _, x in ipairs(data.raw.module['productivity-module'].limitation) do
        if x == recipe_name then
            is_productive = true
        end
    end

    if is_productive then
        table.insert(data.raw.module['productivity-module'].limitation, new_name)
    end
end


"""

class DataRawBuilder:
    def __init__(self, base, prefix):
        self.base = base
        self.prefix = prefix
        self.recipes = []
        self.techs = []

    def make_recipe(self, result, ingredients, **kwargs):
        result = normalize_item_list(result)
        ingredients = normalize_item_list(ingredients)
        r = RecipeBuilder(self, ingredients, result)
        if 'category' in kwargs:
            r.category(kwargs['category'])
        if 'time' in kwargs:
            r.time(kwargs['time'])
        self.recipes.append(r)

        if len(result) == 1:
            d = self.base.get_recipe_by_result(list(result)[0])
            if d is not None:
                r.base(d)

        return r

    def technology_with_name(self, name = None):
        t = TechnologyBuilder(self)
        if not ((name is None) or (name == '')):
            assert name in self.base.techs
            t.base(name)
        self.techs.append(t)
        return t

    def technology_with_cost(self, ingredients = None, count = None, time = 30):
        t = TechnologyBuilder(self)
        t.cost(ingredients, count, time)
        self.techs.append(t)
        return t

    def technology_with_recipe(self, *args, **kwargs):
        r = self.make_recipe(*args, **kwargs)
        t = TechnologyBuilder(self)

        if not (r._base is None):
            d = self.base.get_technology_that_unlocks(r._base)
            if not (d is None):
                t.base(d)

        t.unlock_recipe(r)
        self.techs.append(t)

        return t

    def write_lua(self, outfile):
        auto_names = []
        for i, r in enumerate(self.recipes):
            r.auto_name = f'{self.prefix}-auto-recipe-{i}'
            if not (r._base is None):
                name = f'{self.prefix}-{r._base}'
                if not (name in auto_names):
                    r.auto_name = name
            auto_names.append(r.auto_name)

        auto_names = []
        for i, t in enumerate(self.techs):
            t.auto_name = f'{self.prefix}-auto-tech-{i}t'
            if not (t._base is None):
                name = f'{self.prefix}-{t._base}'
                if not (name in auto_names):
                    t.auto_name = name
            auto_names.append(t.auto_name)

        lua = []
        def w(line):
            lua.append(line)
        w(lua_header)

        def w_value(key, value, indent = 4):
            if value is None:
                return
            # start = (' ' * indent) + key + ' = '
            if type(value) is bool:
                if value:
                    r = 'true'
                else:
                    r = 'false'
            elif type(value) in [int, float]:
                r = str(value)
            elif type(value) is str:
                r = '"' + value + '"'
            elif type(value) is collections.Counter:
                r = item_list_to_lua(value)
            else:
                assert False
            w((' ' * indent) + key + ' = ' + r)

        # recipes
        w('function add_recipes()')
        w('    local recipe = nil')

        for r in self.recipes:
            if r._base:
                w(f'    adjust_if_is_productive("{r._base}", "{r.auto_name}")')
                w(f'    recipe = table.deepcopy(data.raw.recipe["{r._base}"])')
                w('    recipe.normal = nil')
                w('    recipe.expensive = nil')
            else:
                w('    recipe = {}')
            w_value('recipe.name', r.auto_name)
            w_value('recipe.type', 'recipe')
            w_value('recipe.enabled', r._enabled)
            w_value('recipe.energy_required', r._time)
            w_value('recipe.category', r._category)
            w_value('recipe.ingredients', r.ingredients)
            w_value('recipe.results', r.result)

            w('    data:extend{recipe}')
            w('')

        w('end -- add_recipes()\n\n')

        w('function add_techs()')
        w('    local tech = nil')

        for t in self.techs:
            if t._base:
                w(f'    tech = table.deepcopy(data.raw.technology["{t._base}"])')
                w('    if (tech.localised_name == nil) then')
                w('        tech.localised_name = {"technology-name.' + t._base + '"}')
                w('    end')
                w('    if (tech.localised_description == nil) then')
                w('        tech.localised_description = {"technology-description.' + t._base + '"}')
                w('    end')
            else:
                w('    tech = {unit = {}}')
            w_value('tech.name', t.auto_name)
            w_value('tech.type', 'technology')
            w_value('tech.unit.count', t._count)
            w_value('tech.unit.ingredients', t._ingredients)
            w_value('tech.unit.time', t._time)
            if not (t.reqs is None):
                reqs = ['"' + s.auto_name + '"' for s in t.reqs]
                w('    tech.prerequisites = {' + ', '.join(reqs) + '}')
            effects = []
            for r in t.recipes:
                effects.append('{type = "unlock-recipe", recipe = "' + r.auto_name + '"}')
            for b in t.bonuses:
                effects.append(b)
            w('    tech.effects = {' + ', '.join(effects) + '}')

            w('    data:extend{tech}')
            w('')
        w('end -- add_techs()\n\n')

        w('')
        w('lookup_base_recipe = {')
        for r in self.recipes:
            if r._base:
                w(f'        ["{r.auto_name}"] = "{r._base}",')
            else:
                w(f'        ["{r.auto_name}"] = nil,')
        w('    }')

        with open(outfile, 'w') as f:
            f.write('\n'.join(lua))
