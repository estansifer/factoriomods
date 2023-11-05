import overhaul

# todo
#   beacons come with speed modules
#   fix recipes / techs on rocket launch
#   text messages on start and rocket launch

raw_default = overhaul.DataRaw.read_from_files('data_raw_1_1_82')

DRB = overhaul.DataRawBuilder(raw_default, prefix = 'ab')

i = overhaul.normalize_item_list

water = i('water')
stone = i('stone')
coal = i('coal')
fe = i('iron-plate')
cu = i('copper-plate')
gear = i('iron-gear-wheel')
gc = i('electronic-circuit')
rc = i('advanced-circuit')
bc = i('processing-unit')
plastic = i('plastic-bar')
steel = i('steel-plate')
lds = i('low-density-structure')
inserter = i('inserter')
belt = i('transport-belt')
ubelt = i('underground-belt')
splitter = i('splitter')
pipe = i('pipe')
engine = i('engine-unit')
turret = i('gun-turret')

oil = i('crude-oil')
h2so4 = i('sulfuric-acid')

red = i("automation-science-pack")
green = i("logistic-science-pack")
blue = i("chemical-science-pack")
# grey = i("military-science-pack")
# purple = i("production-science-pack")
yellow = i("utility-science-pack")
# white = i("space-science-pack")

def r(*args, **kwargs):
    return DRB.make_recipe(*args, **kwargs).enabled()

r(fe, 'iron-ore')
r(cu, 'copper-ore')
r(gear, 2 * fe)
r(2 * gc, 3 * cu).time(1)

r(inserter, gear + gc)
r(2 * belt, gear + fe)
r('burner-mining-drill', 5 * fe + i('stone-furnace')).time(2)
r('electric-mining-drill', 10 * gc + 10 * gear).time(2)
r('iron-chest', 8 * fe)
# r('firearm-magazine', 4 * fe)
r(2 * i('medium-electric-pole'), 2 * cu + fe)
r(pipe, fe)
r(2 * i('pipe-to-ground'), 6 * pipe)
r('stone-furnace', 5 * stone)
r('offshore-pump', pipe + 2 * gc)
r('boiler', 4 * pipe + i('stone-furnace'))
r('steam-engine', 20 * fe + 10 * pipe)
r('lab', 10 * gc + 10 * belt)
r(red, cu + fe)



tn = DRB.technology_with_name
tc = DRB.technology_with_cost
tr = DRB.technology_with_recipe

rg = red + green
rgb = rg + blue
rgby = rgb + yellow

# the only military research
tr(turret, 20 * gear + 10 * cu).r('firearm-magazine', 4 * fe)

Tgreen = tr(green, inserter + belt)
Tgreen.req(
        tr('assembling-machine-2', 10 * gear + 10 * gc)
        .r(2 * ubelt, 4 * belt)
        .r('splitter', 4 * belt + 5 * gc)
        .cost(red, 1)
        .req())
Tgreen.child(
        tr('fast-transport-belt', belt + 5 * gear)
        .r('fast-underground-belt', ubelt + 20 * gear)
        .r('fast-splitter', splitter + 10 * gc)
        .cost(rg, 100))

Tsteel = tr(steel, 5 * fe, time = 16)
Tsteel.bonus('character-mining-speed', modifier = 1)
Tengine = tr(engine, 2 * pipe + steel).req(Tsteel, Tgreen)
Tengine.r(i('car'), 8 * engine + 20 * steel)
Tengine.cost(rg, 50)
Tengine.child(
        tr('rail', stone + steel)
        .r('locomotive', 20 * engine + 30 * steel)
        .r('cargo-wagon', 20 * steel + 20 * fe)
        .r('train-stop', 5 * gc + 5 * steel))

Toil = tr('pumpjack', 10 * steel + 10 * gear).req(Tgreen, Tsteel)
Toil.r('chemical-plant', 10 * steel + 10 * gc)
Toil.r(50 * h2so4, 150 * oil + 5 * fe)
Toil.r(10 * i('lubricant'), 10 * oil)
Toil.cost(rg, 50)

Tbattery = tr('battery', cu + 20 * h2so4, time = 4).req(Toil).cost(rg, 100)

Trc = tr(rc, 4 * gc + 2 * plastic, time = 6).req(Toil)
Trc.r(2 * plastic, coal + 40 * oil)
Trc.cost(rg, 100)
Trc.child(
        tr('productivity-module', 5 * gc + 5 * rc)
        .base('modules'))

Tblue = tr(2 * blue, 2 * engine + 3 * rc).req(Trc, Tengine)

Tyellow = tr(3 * yellow, 2 * bc + 3 * lds)
Tyellow.req(
        tr(bc, 2 * rc + 5 * h2so4, time = 10).req(Tblue).cost(rgb, 200),
        tr(lds, 20 * cu + 5 * plastic, time = 20).req(Tblue).cost(rgb, 200))
Tyellow.child(
        tr('ab-beacon', 20 * steel + 10 * bc).base('effect-transmission').cost(rgby, 75))

(tr('logistic-chest-requester', i('iron-chest') + rc)
    .r('roboport', 45 * steel + 45 * rc)
    .r('logistic-robot', 2 * i('battery') + 15 * i('lubricant'),
        category = 'crafting-with-fluid', time = 20)
    .r('logistic-chest-passive-provider', i('iron-chest') + rc)
    .req(Tyellow, Tbattery)
    .cost(rgby, 100)) # instead of 500

Tsilo = tr('ab-rocket-silo', 1000 * engine, time = 30).req(Tyellow)
Tsilo.r('rocket-part', 10 * lds + 10 * i('rocket-fuel'))
Tsilo.req(
        tr(50 * h2so4, 100 * i('lubricant') + 50 * water)
        .r('rocket-fuel', 150 * oil + 50 * water, category = 'chemistry')
        .req(Tblue)
        .base('advanced-oil-processing'))
Tsilo.cost(rgby, 200) # instead of 1000
Tsilo.base('rocket-silo')

DRB.write_lua('abridged_auto.lua')
