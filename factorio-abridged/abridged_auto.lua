
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



function add_recipes()
    local recipe = nil
    adjust_if_is_productive("iron-plate", "ab-iron-plate")
    recipe = table.deepcopy(data.raw.recipe["iron-plate"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-iron-plate"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"iron-ore", 1}}
    recipe.results = {{"iron-plate", 1}}
    data:extend{recipe}

    adjust_if_is_productive("copper-plate", "ab-copper-plate")
    recipe = table.deepcopy(data.raw.recipe["copper-plate"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-copper-plate"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"copper-ore", 1}}
    recipe.results = {{"copper-plate", 1}}
    data:extend{recipe}

    adjust_if_is_productive("iron-gear-wheel", "ab-iron-gear-wheel")
    recipe = table.deepcopy(data.raw.recipe["iron-gear-wheel"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-iron-gear-wheel"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"iron-plate", 2}}
    recipe.results = {{"iron-gear-wheel", 1}}
    data:extend{recipe}

    adjust_if_is_productive("electronic-circuit", "ab-electronic-circuit")
    recipe = table.deepcopy(data.raw.recipe["electronic-circuit"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-electronic-circuit"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.energy_required = 1
    recipe.ingredients = {{"copper-plate", 3}}
    recipe.results = {{"electronic-circuit", 2}}
    data:extend{recipe}

    adjust_if_is_productive("inserter", "ab-inserter")
    recipe = table.deepcopy(data.raw.recipe["inserter"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-inserter"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"iron-gear-wheel", 1}, {"electronic-circuit", 1}}
    recipe.results = {{"inserter", 1}}
    data:extend{recipe}

    adjust_if_is_productive("transport-belt", "ab-transport-belt")
    recipe = table.deepcopy(data.raw.recipe["transport-belt"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-transport-belt"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"iron-gear-wheel", 1}, {"iron-plate", 1}}
    recipe.results = {{"transport-belt", 2}}
    data:extend{recipe}

    adjust_if_is_productive("burner-mining-drill", "ab-burner-mining-drill")
    recipe = table.deepcopy(data.raw.recipe["burner-mining-drill"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-burner-mining-drill"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.energy_required = 2
    recipe.ingredients = {{"iron-plate", 5}, {"stone-furnace", 1}}
    recipe.results = {{"burner-mining-drill", 1}}
    data:extend{recipe}

    adjust_if_is_productive("electric-mining-drill", "ab-electric-mining-drill")
    recipe = table.deepcopy(data.raw.recipe["electric-mining-drill"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-electric-mining-drill"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.energy_required = 2
    recipe.ingredients = {{"electronic-circuit", 10}, {"iron-gear-wheel", 10}}
    recipe.results = {{"electric-mining-drill", 1}}
    data:extend{recipe}

    adjust_if_is_productive("iron-chest", "ab-iron-chest")
    recipe = table.deepcopy(data.raw.recipe["iron-chest"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-iron-chest"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"iron-plate", 8}}
    recipe.results = {{"iron-chest", 1}}
    data:extend{recipe}

    adjust_if_is_productive("medium-electric-pole", "ab-medium-electric-pole")
    recipe = table.deepcopy(data.raw.recipe["medium-electric-pole"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-medium-electric-pole"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"copper-plate", 2}, {"iron-plate", 1}}
    recipe.results = {{"medium-electric-pole", 2}}
    data:extend{recipe}

    adjust_if_is_productive("pipe", "ab-pipe")
    recipe = table.deepcopy(data.raw.recipe["pipe"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-pipe"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"iron-plate", 1}}
    recipe.results = {{"pipe", 1}}
    data:extend{recipe}

    adjust_if_is_productive("pipe-to-ground", "ab-pipe-to-ground")
    recipe = table.deepcopy(data.raw.recipe["pipe-to-ground"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-pipe-to-ground"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"pipe", 6}}
    recipe.results = {{"pipe-to-ground", 2}}
    data:extend{recipe}

    adjust_if_is_productive("stone-furnace", "ab-stone-furnace")
    recipe = table.deepcopy(data.raw.recipe["stone-furnace"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-stone-furnace"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"stone", 5}}
    recipe.results = {{"stone-furnace", 1}}
    data:extend{recipe}

    adjust_if_is_productive("offshore-pump", "ab-offshore-pump")
    recipe = table.deepcopy(data.raw.recipe["offshore-pump"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-offshore-pump"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"pipe", 1}, {"electronic-circuit", 2}}
    recipe.results = {{"offshore-pump", 1}}
    data:extend{recipe}

    adjust_if_is_productive("boiler", "ab-boiler")
    recipe = table.deepcopy(data.raw.recipe["boiler"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-boiler"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"pipe", 4}, {"stone-furnace", 1}}
    recipe.results = {{"boiler", 1}}
    data:extend{recipe}

    adjust_if_is_productive("steam-engine", "ab-steam-engine")
    recipe = table.deepcopy(data.raw.recipe["steam-engine"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-steam-engine"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"iron-plate", 20}, {"pipe", 10}}
    recipe.results = {{"steam-engine", 1}}
    data:extend{recipe}

    adjust_if_is_productive("lab", "ab-lab")
    recipe = table.deepcopy(data.raw.recipe["lab"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-lab"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"electronic-circuit", 10}, {"transport-belt", 10}}
    recipe.results = {{"lab", 1}}
    data:extend{recipe}

    adjust_if_is_productive("automation-science-pack", "ab-automation-science-pack")
    recipe = table.deepcopy(data.raw.recipe["automation-science-pack"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-automation-science-pack"
    recipe.type = "recipe"
    recipe.enabled = true
    recipe.ingredients = {{"copper-plate", 1}, {"iron-plate", 1}}
    recipe.results = {{"automation-science-pack", 1}}
    data:extend{recipe}

    adjust_if_is_productive("gun-turret", "ab-gun-turret")
    recipe = table.deepcopy(data.raw.recipe["gun-turret"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-gun-turret"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"iron-gear-wheel", 20}, {"copper-plate", 10}}
    recipe.results = {{"gun-turret", 1}}
    data:extend{recipe}

    adjust_if_is_productive("firearm-magazine", "ab-firearm-magazine")
    recipe = table.deepcopy(data.raw.recipe["firearm-magazine"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-firearm-magazine"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"iron-plate", 4}}
    recipe.results = {{"firearm-magazine", 1}}
    data:extend{recipe}

    adjust_if_is_productive("logistic-science-pack", "ab-logistic-science-pack")
    recipe = table.deepcopy(data.raw.recipe["logistic-science-pack"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-logistic-science-pack"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"inserter", 1}, {"transport-belt", 1}}
    recipe.results = {{"logistic-science-pack", 1}}
    data:extend{recipe}

    adjust_if_is_productive("assembling-machine-2", "ab-assembling-machine-2")
    recipe = table.deepcopy(data.raw.recipe["assembling-machine-2"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-assembling-machine-2"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"iron-gear-wheel", 10}, {"electronic-circuit", 10}}
    recipe.results = {{"assembling-machine-2", 1}}
    data:extend{recipe}

    adjust_if_is_productive("underground-belt", "ab-underground-belt")
    recipe = table.deepcopy(data.raw.recipe["underground-belt"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-underground-belt"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"transport-belt", 4}}
    recipe.results = {{"underground-belt", 2}}
    data:extend{recipe}

    adjust_if_is_productive("splitter", "ab-splitter")
    recipe = table.deepcopy(data.raw.recipe["splitter"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-splitter"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"transport-belt", 4}, {"electronic-circuit", 5}}
    recipe.results = {{"splitter", 1}}
    data:extend{recipe}

    adjust_if_is_productive("fast-transport-belt", "ab-fast-transport-belt")
    recipe = table.deepcopy(data.raw.recipe["fast-transport-belt"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-fast-transport-belt"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"transport-belt", 1}, {"iron-gear-wheel", 5}}
    recipe.results = {{"fast-transport-belt", 1}}
    data:extend{recipe}

    adjust_if_is_productive("fast-underground-belt", "ab-fast-underground-belt")
    recipe = table.deepcopy(data.raw.recipe["fast-underground-belt"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-fast-underground-belt"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"underground-belt", 1}, {"iron-gear-wheel", 20}}
    recipe.results = {{"fast-underground-belt", 1}}
    data:extend{recipe}

    adjust_if_is_productive("fast-splitter", "ab-fast-splitter")
    recipe = table.deepcopy(data.raw.recipe["fast-splitter"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-fast-splitter"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"splitter", 1}, {"electronic-circuit", 10}}
    recipe.results = {{"fast-splitter", 1}}
    data:extend{recipe}

    adjust_if_is_productive("steel-plate", "ab-steel-plate")
    recipe = table.deepcopy(data.raw.recipe["steel-plate"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-steel-plate"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.energy_required = 16
    recipe.ingredients = {{"iron-plate", 5}}
    recipe.results = {{"steel-plate", 1}}
    data:extend{recipe}

    adjust_if_is_productive("engine-unit", "ab-engine-unit")
    recipe = table.deepcopy(data.raw.recipe["engine-unit"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-engine-unit"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"pipe", 2}, {"steel-plate", 1}}
    recipe.results = {{"engine-unit", 1}}
    data:extend{recipe}

    adjust_if_is_productive("car", "ab-car")
    recipe = table.deepcopy(data.raw.recipe["car"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-car"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"engine-unit", 8}, {"steel-plate", 20}}
    recipe.results = {{"car", 1}}
    data:extend{recipe}

    adjust_if_is_productive("rail", "ab-rail")
    recipe = table.deepcopy(data.raw.recipe["rail"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-rail"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"stone", 1}, {"steel-plate", 1}}
    recipe.results = {{"rail", 1}}
    data:extend{recipe}

    adjust_if_is_productive("locomotive", "ab-locomotive")
    recipe = table.deepcopy(data.raw.recipe["locomotive"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-locomotive"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"engine-unit", 20}, {"steel-plate", 30}}
    recipe.results = {{"locomotive", 1}}
    data:extend{recipe}

    adjust_if_is_productive("cargo-wagon", "ab-cargo-wagon")
    recipe = table.deepcopy(data.raw.recipe["cargo-wagon"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-cargo-wagon"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"steel-plate", 20}, {"iron-plate", 20}}
    recipe.results = {{"cargo-wagon", 1}}
    data:extend{recipe}

    adjust_if_is_productive("train-stop", "ab-train-stop")
    recipe = table.deepcopy(data.raw.recipe["train-stop"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-train-stop"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"electronic-circuit", 5}, {"steel-plate", 5}}
    recipe.results = {{"train-stop", 1}}
    data:extend{recipe}

    adjust_if_is_productive("pumpjack", "ab-pumpjack")
    recipe = table.deepcopy(data.raw.recipe["pumpjack"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-pumpjack"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"steel-plate", 10}, {"iron-gear-wheel", 10}}
    recipe.results = {{"pumpjack", 1}}
    data:extend{recipe}

    adjust_if_is_productive("chemical-plant", "ab-chemical-plant")
    recipe = table.deepcopy(data.raw.recipe["chemical-plant"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-chemical-plant"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"steel-plate", 10}, {"electronic-circuit", 10}}
    recipe.results = {{"chemical-plant", 1}}
    data:extend{recipe}

    adjust_if_is_productive("sulfuric-acid", "ab-sulfuric-acid")
    recipe = table.deepcopy(data.raw.recipe["sulfuric-acid"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-sulfuric-acid"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{type = "fluid", name = "crude-oil", amount = 150}, {"iron-plate", 5}}
    recipe.results = {{type = "fluid", name = "sulfuric-acid", amount = 50}}
    data:extend{recipe}

    adjust_if_is_productive("lubricant", "ab-lubricant")
    recipe = table.deepcopy(data.raw.recipe["lubricant"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-lubricant"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{type = "fluid", name = "crude-oil", amount = 10}}
    recipe.results = {{type = "fluid", name = "lubricant", amount = 10}}
    data:extend{recipe}

    adjust_if_is_productive("battery", "ab-battery")
    recipe = table.deepcopy(data.raw.recipe["battery"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-battery"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.energy_required = 4
    recipe.ingredients = {{"copper-plate", 1}, {type = "fluid", name = "sulfuric-acid", amount = 20}}
    recipe.results = {{"battery", 1}}
    data:extend{recipe}

    adjust_if_is_productive("advanced-circuit", "ab-advanced-circuit")
    recipe = table.deepcopy(data.raw.recipe["advanced-circuit"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-advanced-circuit"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.energy_required = 6
    recipe.ingredients = {{"electronic-circuit", 4}, {"plastic-bar", 2}}
    recipe.results = {{"advanced-circuit", 1}}
    data:extend{recipe}

    adjust_if_is_productive("plastic-bar", "ab-plastic-bar")
    recipe = table.deepcopy(data.raw.recipe["plastic-bar"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-plastic-bar"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"coal", 1}, {type = "fluid", name = "crude-oil", amount = 40}}
    recipe.results = {{"plastic-bar", 2}}
    data:extend{recipe}

    adjust_if_is_productive("productivity-module", "ab-productivity-module")
    recipe = table.deepcopy(data.raw.recipe["productivity-module"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-productivity-module"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"electronic-circuit", 5}, {"advanced-circuit", 5}}
    recipe.results = {{"productivity-module", 1}}
    data:extend{recipe}

    adjust_if_is_productive("chemical-science-pack", "ab-chemical-science-pack")
    recipe = table.deepcopy(data.raw.recipe["chemical-science-pack"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-chemical-science-pack"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"engine-unit", 2}, {"advanced-circuit", 3}}
    recipe.results = {{"chemical-science-pack", 2}}
    data:extend{recipe}

    adjust_if_is_productive("utility-science-pack", "ab-utility-science-pack")
    recipe = table.deepcopy(data.raw.recipe["utility-science-pack"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-utility-science-pack"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"processing-unit", 2}, {"low-density-structure", 3}}
    recipe.results = {{"utility-science-pack", 3}}
    data:extend{recipe}

    adjust_if_is_productive("processing-unit", "ab-processing-unit")
    recipe = table.deepcopy(data.raw.recipe["processing-unit"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-processing-unit"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.energy_required = 10
    recipe.ingredients = {{"advanced-circuit", 2}, {type = "fluid", name = "sulfuric-acid", amount = 5}}
    recipe.results = {{"processing-unit", 1}}
    data:extend{recipe}

    adjust_if_is_productive("low-density-structure", "ab-low-density-structure")
    recipe = table.deepcopy(data.raw.recipe["low-density-structure"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-low-density-structure"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.energy_required = 20
    recipe.ingredients = {{"copper-plate", 20}, {"plastic-bar", 5}}
    recipe.results = {{"low-density-structure", 1}}
    data:extend{recipe}

    recipe = {}
    recipe.name = "ab-auto-recipe-46"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"steel-plate", 20}, {"processing-unit", 10}}
    recipe.results = {{"ab-beacon", 1}}
    data:extend{recipe}

    adjust_if_is_productive("logistic-chest-requester", "ab-logistic-chest-requester")
    recipe = table.deepcopy(data.raw.recipe["logistic-chest-requester"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-logistic-chest-requester"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"iron-chest", 1}, {"advanced-circuit", 1}}
    recipe.results = {{"logistic-chest-requester", 1}}
    data:extend{recipe}

    adjust_if_is_productive("roboport", "ab-roboport")
    recipe = table.deepcopy(data.raw.recipe["roboport"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-roboport"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"steel-plate", 45}, {"advanced-circuit", 45}}
    recipe.results = {{"roboport", 1}}
    data:extend{recipe}

    adjust_if_is_productive("logistic-robot", "ab-logistic-robot")
    recipe = table.deepcopy(data.raw.recipe["logistic-robot"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-logistic-robot"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.energy_required = 20
    recipe.category = "crafting-with-fluid"
    recipe.ingredients = {{"battery", 2}, {type = "fluid", name = "lubricant", amount = 15}}
    recipe.results = {{"logistic-robot", 1}}
    data:extend{recipe}

    adjust_if_is_productive("logistic-chest-passive-provider", "ab-logistic-chest-passive-provider")
    recipe = table.deepcopy(data.raw.recipe["logistic-chest-passive-provider"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-logistic-chest-passive-provider"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"iron-chest", 1}, {"advanced-circuit", 1}}
    recipe.results = {{"logistic-chest-passive-provider", 1}}
    data:extend{recipe}

    recipe = {}
    recipe.name = "ab-auto-recipe-51"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.energy_required = 30
    recipe.ingredients = {{"engine-unit", 1000}}
    recipe.results = {{"ab-rocket-silo", 1}}
    data:extend{recipe}

    adjust_if_is_productive("rocket-part", "ab-rocket-part")
    recipe = table.deepcopy(data.raw.recipe["rocket-part"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-rocket-part"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{"low-density-structure", 10}, {"rocket-fuel", 10}}
    recipe.results = {{"rocket-part", 1}}
    data:extend{recipe}

    adjust_if_is_productive("sulfuric-acid", "ab-auto-recipe-53")
    recipe = table.deepcopy(data.raw.recipe["sulfuric-acid"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-auto-recipe-53"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.ingredients = {{type = "fluid", name = "lubricant", amount = 100}, {type = "fluid", name = "water", amount = 50}}
    recipe.results = {{type = "fluid", name = "sulfuric-acid", amount = 50}}
    data:extend{recipe}

    adjust_if_is_productive("rocket-fuel", "ab-rocket-fuel")
    recipe = table.deepcopy(data.raw.recipe["rocket-fuel"])
    recipe.normal = nil
    recipe.expensive = nil
    recipe.name = "ab-rocket-fuel"
    recipe.type = "recipe"
    recipe.enabled = false
    recipe.category = "chemistry"
    recipe.ingredients = {{type = "fluid", name = "crude-oil", amount = 150}, {type = "fluid", name = "water", amount = 50}}
    recipe.results = {{"rocket-fuel", 1}}
    data:extend{recipe}

end -- add_recipes()


function add_techs()
    local tech = nil
    tech = table.deepcopy(data.raw.technology["gun-turret"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.gun-turret"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.gun-turret"}
    end
    tech.name = "ab-gun-turret"
    tech.type = "technology"
    tech.effects = {{type = "unlock-recipe", recipe = "ab-gun-turret"}, {type = "unlock-recipe", recipe = "ab-firearm-magazine"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["logistic-science-pack"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.logistic-science-pack"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.logistic-science-pack"}
    end
    tech.name = "ab-logistic-science-pack"
    tech.type = "technology"
    tech.prerequisites = {"ab-automation-2"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-logistic-science-pack"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["automation-2"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.automation-2"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.automation-2"}
    end
    tech.name = "ab-automation-2"
    tech.type = "technology"
    tech.unit.count = 1
    tech.unit.ingredients = {{"automation-science-pack", 1}}
    tech.prerequisites = {}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-assembling-machine-2"}, {type = "unlock-recipe", recipe = "ab-underground-belt"}, {type = "unlock-recipe", recipe = "ab-splitter"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["logistics-2"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.logistics-2"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.logistics-2"}
    end
    tech.name = "ab-logistics-2"
    tech.type = "technology"
    tech.unit.count = 100
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}}
    tech.prerequisites = {"ab-logistic-science-pack"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-fast-transport-belt"}, {type = "unlock-recipe", recipe = "ab-fast-underground-belt"}, {type = "unlock-recipe", recipe = "ab-fast-splitter"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["steel-processing"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.steel-processing"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.steel-processing"}
    end
    tech.name = "ab-steel-processing"
    tech.type = "technology"
    tech.effects = {{type = "unlock-recipe", recipe = "ab-steel-plate"}, {modifier = 1, type = "character-mining-speed"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["engine"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.engine"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.engine"}
    end
    tech.name = "ab-engine"
    tech.type = "technology"
    tech.unit.count = 50
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}}
    tech.prerequisites = {"ab-steel-processing", "ab-logistic-science-pack"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-engine-unit"}, {type = "unlock-recipe", recipe = "ab-car"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["railway"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.railway"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.railway"}
    end
    tech.name = "ab-railway"
    tech.type = "technology"
    tech.prerequisites = {"ab-engine"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-rail"}, {type = "unlock-recipe", recipe = "ab-locomotive"}, {type = "unlock-recipe", recipe = "ab-cargo-wagon"}, {type = "unlock-recipe", recipe = "ab-train-stop"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["oil-processing"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.oil-processing"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.oil-processing"}
    end
    tech.name = "ab-oil-processing"
    tech.type = "technology"
    tech.unit.count = 50
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}}
    tech.prerequisites = {"ab-logistic-science-pack", "ab-steel-processing"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-pumpjack"}, {type = "unlock-recipe", recipe = "ab-chemical-plant"}, {type = "unlock-recipe", recipe = "ab-sulfuric-acid"}, {type = "unlock-recipe", recipe = "ab-lubricant"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["battery"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.battery"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.battery"}
    end
    tech.name = "ab-battery"
    tech.type = "technology"
    tech.unit.count = 100
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}}
    tech.prerequisites = {"ab-oil-processing"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-battery"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["advanced-electronics"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.advanced-electronics"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.advanced-electronics"}
    end
    tech.name = "ab-advanced-electronics"
    tech.type = "technology"
    tech.unit.count = 100
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}}
    tech.prerequisites = {"ab-oil-processing"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-advanced-circuit"}, {type = "unlock-recipe", recipe = "ab-plastic-bar"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["modules"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.modules"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.modules"}
    end
    tech.name = "ab-modules"
    tech.type = "technology"
    tech.prerequisites = {"ab-advanced-electronics"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-productivity-module"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["chemical-science-pack"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.chemical-science-pack"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.chemical-science-pack"}
    end
    tech.name = "ab-chemical-science-pack"
    tech.type = "technology"
    tech.prerequisites = {"ab-advanced-electronics", "ab-engine"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-chemical-science-pack"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["utility-science-pack"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.utility-science-pack"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.utility-science-pack"}
    end
    tech.name = "ab-utility-science-pack"
    tech.type = "technology"
    tech.prerequisites = {"ab-advanced-electronics-2", "ab-low-density-structure"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-utility-science-pack"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["advanced-electronics-2"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.advanced-electronics-2"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.advanced-electronics-2"}
    end
    tech.name = "ab-advanced-electronics-2"
    tech.type = "technology"
    tech.unit.count = 200
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}}
    tech.prerequisites = {"ab-chemical-science-pack"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-processing-unit"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["low-density-structure"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.low-density-structure"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.low-density-structure"}
    end
    tech.name = "ab-low-density-structure"
    tech.type = "technology"
    tech.unit.count = 200
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}}
    tech.prerequisites = {"ab-chemical-science-pack"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-low-density-structure"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["effect-transmission"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.effect-transmission"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.effect-transmission"}
    end
    tech.name = "ab-effect-transmission"
    tech.type = "technology"
    tech.unit.count = 75
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}, {"utility-science-pack", 1}}
    tech.prerequisites = {"ab-utility-science-pack"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-auto-recipe-46"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["logistic-system"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.logistic-system"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.logistic-system"}
    end
    tech.name = "ab-logistic-system"
    tech.type = "technology"
    tech.unit.count = 100
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}, {"utility-science-pack", 1}}
    tech.prerequisites = {"ab-utility-science-pack", "ab-battery"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-logistic-chest-requester"}, {type = "unlock-recipe", recipe = "ab-roboport"}, {type = "unlock-recipe", recipe = "ab-logistic-robot"}, {type = "unlock-recipe", recipe = "ab-logistic-chest-passive-provider"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["rocket-silo"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.rocket-silo"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.rocket-silo"}
    end
    tech.name = "ab-rocket-silo"
    tech.type = "technology"
    tech.unit.count = 200
    tech.unit.ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}, {"utility-science-pack", 1}}
    tech.prerequisites = {"ab-utility-science-pack", "ab-advanced-oil-processing"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-auto-recipe-51"}, {type = "unlock-recipe", recipe = "ab-rocket-part"}}
    data:extend{tech}

    tech = table.deepcopy(data.raw.technology["advanced-oil-processing"])
    if (tech.localised_name == nil) then
        tech.localised_name = {"technology-name.advanced-oil-processing"}
    end
    if (tech.localised_description == nil) then
        tech.localised_description = {"technology-description.advanced-oil-processing"}
    end
    tech.name = "ab-advanced-oil-processing"
    tech.type = "technology"
    tech.prerequisites = {"ab-chemical-science-pack"}
    tech.effects = {{type = "unlock-recipe", recipe = "ab-auto-recipe-53"}, {type = "unlock-recipe", recipe = "ab-rocket-fuel"}}
    data:extend{tech}

end -- add_techs()



lookup_base_recipe = {
        ["ab-iron-plate"] = "iron-plate",
        ["ab-copper-plate"] = "copper-plate",
        ["ab-iron-gear-wheel"] = "iron-gear-wheel",
        ["ab-electronic-circuit"] = "electronic-circuit",
        ["ab-inserter"] = "inserter",
        ["ab-transport-belt"] = "transport-belt",
        ["ab-burner-mining-drill"] = "burner-mining-drill",
        ["ab-electric-mining-drill"] = "electric-mining-drill",
        ["ab-iron-chest"] = "iron-chest",
        ["ab-medium-electric-pole"] = "medium-electric-pole",
        ["ab-pipe"] = "pipe",
        ["ab-pipe-to-ground"] = "pipe-to-ground",
        ["ab-stone-furnace"] = "stone-furnace",
        ["ab-offshore-pump"] = "offshore-pump",
        ["ab-boiler"] = "boiler",
        ["ab-steam-engine"] = "steam-engine",
        ["ab-lab"] = "lab",
        ["ab-automation-science-pack"] = "automation-science-pack",
        ["ab-gun-turret"] = "gun-turret",
        ["ab-firearm-magazine"] = "firearm-magazine",
        ["ab-logistic-science-pack"] = "logistic-science-pack",
        ["ab-assembling-machine-2"] = "assembling-machine-2",
        ["ab-underground-belt"] = "underground-belt",
        ["ab-splitter"] = "splitter",
        ["ab-fast-transport-belt"] = "fast-transport-belt",
        ["ab-fast-underground-belt"] = "fast-underground-belt",
        ["ab-fast-splitter"] = "fast-splitter",
        ["ab-steel-plate"] = "steel-plate",
        ["ab-engine-unit"] = "engine-unit",
        ["ab-car"] = "car",
        ["ab-rail"] = "rail",
        ["ab-locomotive"] = "locomotive",
        ["ab-cargo-wagon"] = "cargo-wagon",
        ["ab-train-stop"] = "train-stop",
        ["ab-pumpjack"] = "pumpjack",
        ["ab-chemical-plant"] = "chemical-plant",
        ["ab-sulfuric-acid"] = "sulfuric-acid",
        ["ab-lubricant"] = "lubricant",
        ["ab-battery"] = "battery",
        ["ab-advanced-circuit"] = "advanced-circuit",
        ["ab-plastic-bar"] = "plastic-bar",
        ["ab-productivity-module"] = "productivity-module",
        ["ab-chemical-science-pack"] = "chemical-science-pack",
        ["ab-utility-science-pack"] = "utility-science-pack",
        ["ab-processing-unit"] = "processing-unit",
        ["ab-low-density-structure"] = "low-density-structure",
        ["ab-auto-recipe-46"] = nil,
        ["ab-logistic-chest-requester"] = "logistic-chest-requester",
        ["ab-roboport"] = "roboport",
        ["ab-logistic-robot"] = "logistic-robot",
        ["ab-logistic-chest-passive-provider"] = "logistic-chest-passive-provider",
        ["ab-auto-recipe-51"] = nil,
        ["ab-rocket-part"] = "rocket-part",
        ["ab-auto-recipe-53"] = "sulfuric-acid",
        ["ab-rocket-fuel"] = "rocket-fuel",
    }