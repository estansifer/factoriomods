require("metaconfig")
require("lib/rand")

function migrate_1(c)
    local P = 'Union(ConcentricBarcode(45, 80),Fractal(1.5, 40, 0.7), Circle(100))'

    if global.settings ~= nil and
        preset_by_name(global.settings['pattern-preset']) == nil and
        global.settings['pattern-custom'] == P then
        local x = c.mod_changes['ctg']
        if x ~= nil and x.old_version == '0.4.1' and x.new_version == '0.4.2' then
            init_global_rng(0)
            global.tp_data[1][1].rng = new_rng()
            global.tp_data[1][2].rng = new_rng()
        end
    end
end
