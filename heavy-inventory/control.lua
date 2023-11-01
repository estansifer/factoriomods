local function compute_fullness(player)
    local inv = player.get_inventory(defines.inventory.character_main)
    local max_stacks = #inv
    local num_stacks = 0

    local contents = inv.get_contents()
    for item, count in pairs(contents) do
        local stack_size = 1
        if game.item_prototypes[item].stackable then
            stack_size = game.item_prototypes[item].stack_size
        end

        num_stacks = num_stacks + count / stack_size
    end

    return num_stacks / max_stacks
end

local function check_burden(event)
    local player = game.players[event.player_index]
    if player.character ~= nil then
        local fullness = compute_fullness(player)

        -- This value is *added* to 1 to make the player's true speed. So
        -- if this value is set to 0, the player walks normally. At 1, the
        -- player moves at double speed. At -1, the player cannot move at all.
        --
        -- When inventory is full, move at 1.5 times normal speed. When inventory
        -- is empty, mvoe at 0.5 times normal speed.
        player.character_running_speed_modifier = 0.5 - fullness
    end
end


local function on_init(event)
    script.on_event(defines.events.on_player_main_inventory_changed, check_burden)
end

local function on_load(event)
    script.on_event(defines.events.on_player_main_inventory_changed, check_burden)
end

script.on_init(on_init)
script.on_load(on_load)
