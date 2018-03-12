local function on_crafted(event)
    local player = game.players[event.player_index]
    local stats = player.force.item_production_statistics

    -- local count = event.item_stack.count

    for i, ingredient in ipairs(event.recipe.ingredients) do
        stats.on_flow(ingredient.name, -ingredient.amount)
    end
end

script.on_event(defines.events.on_player_crafted_item, on_crafted)
