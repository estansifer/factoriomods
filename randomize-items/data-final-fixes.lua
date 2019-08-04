require("lcg")

local function is_visible(item)
    if item.flags ~= nil then
        for _, flag in ipairs(item.flags) do
            if flag == "hidden" then
                return false
            end
        end
    end
    return true
end

local function get_localized_name(item_id, item)
    if item.localised_name == nil then
        if item.place_result ~= nil then
            return {"entity-name." .. item.place_result}
        elseif item.placed_as_equipment_result ~= nil then
            return {"equipment-name." .. item.placed_as_equipment_result}
        elseif item.type == "fluid" then
            return {"fluid-name." .. item_id}
        else
            return {"item-name." .. item_id}
        end
    else
        return item.localised_name
    end
end

local function get_localized_description(item_id, item)
    if item.localised_description == nil then
        return ''
            -- -- return {"entity-description." .. item.place_result}
    else
        return item.localised_description
    end
end

local function shuffle(xs, N)
    for i = 1, N - 1 do
        local j = i + rand(N + 1 - i)

        if j > i then
            local x = xs[i]
            xs[i] = xs[j]
            xs[j] = x
        end
    end
end

local function process(seed)
    local items = {}
    local item_names = {}
    local item_icons = {}

    local group_names = {'item', 'fluid', 'tool', 'rail-planner', 'capsule',
        'module', 'ammo', 'armor', 'gun', 'repair-tool'}

    local icon_keys = {'icon', 'icons', 'icon_size', 'icon_mipmaps', 'pictures'}

    for _, group_name in ipairs(group_names) do
        for item_id, item in pairs(data.raw[group_name]) do
            if is_visible(item) then
                table.insert(items, {group_name, item_id, item})
                table.insert(item_names,
                    {get_localized_name(item_id, item), get_localized_description(item_id, item)})
                local icon_data = {}
                for i = 1, #icon_keys do
                    icon_data[i] = item[icon_keys[i]]
                end
                table.insert(item_icons, icon_data)
            end
        end
    end

    local N = #items

    setseed(seed)
    for i = 1, N do
        rand(N)
    end

    shuffle(item_names, N)
    shuffle(item_icons, N)

    for i = 1, N do
        local item = data.raw[items[i][1]][items[i][2]]
        item.localised_name = item_names[i][1]
        item.localised_description = item_names[i][2]
        for j = 1, #icon_keys do
            item[icon_keys[j]] = item_icons[i][j]
        end
    end
end

process(settings.startup['randomize-items-seed'].value)
