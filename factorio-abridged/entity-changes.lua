data.raw.inserter.inserter.energy_source = {type = 'void'}
data.raw.furnace['stone-furnace'].energy_source = {type = 'void'}
data.raw['underground-belt']['underground-belt'].max_distance = 3
data.raw['pipe-to-ground']['pipe-to-ground'].fluid_box.pipe_connections[2].max_underground_distance = 6

data.raw['mining-drill']['electric-mining-drill'].mining_speed = 0.75

silo = table.deepcopy(data.raw['rocket-silo']['rocket-silo'])
silo.name = 'ab-rocket-silo'
silo.fixed_recipe = 'ab-rocket-part'
silo.rocket_parts_required = 10
silo.max_health = 400
silo.minable.mining_time = 3
silo.minable.result = 'ab-rocket-silo'
silo.resistances = {}
silo.localised_name = {'entity-name.rocket-silo'}
silo.localised_description = {'entity-description.rocket-silo'}
data:extend{silo}

silo_item = table.deepcopy(data.raw.item['rocket-silo'])
silo_item.name = 'ab-rocket-silo'
silo_item.place_result = 'ab-rocket-silo'
-- silo_item.localised_name = {'item-name.rocket-silo'}
silo_item.localised_description = {'item-description.rocket-silo'}
data:extend{silo_item}

beacon = table.deepcopy(data.raw.beacon.beacon)
beacon.name = 'ab-beacon'
beacon.minable.result = 'ab-beacon'
beacon.localised_name = {'entity-name.beacon'}
beacon.localised_description = {'entity-description.beacon'}
data:extend{beacon}

beacon_item = table.deepcopy(data.raw.item['beacon'])
beacon_item.name = 'ab-beacon'
beacon_item.place_result = 'ab-beacon'
beacon_item.localised_name = {'item-name.beacon'}
beacon_item.localised_description = {'item-description.beacon'}
data:extend{beacon_item}
