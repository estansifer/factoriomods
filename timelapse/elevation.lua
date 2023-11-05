require('logger')

function log_region(log, x0, y0, nx, ny, zoom)
    zoom = zoom or 1
    local surface = game.surfaces['nauvis']

    region = string.format('%d %d %d %d %d', x0, y0, nx, ny, zoom)
    write_log(log, region)

    for dy = 0, ny - 1 do
        local y = y0 + dy * zoom
        local pos = {}
        for dx = 0, nx - 1 do
            table.insert(pos, {x0 + dx * zoom, y})
        end
        zs = surface.calculate_tile_properties({'elevation'},pos).elevation
        for i = 1, nx do
            zs[i] = string.format('%.4f ', zs[i])
        end
        write_log(log, table.concat(zs))
    end
end

function log_elevation(x, y)
    log_region(global.logger_elevation, x, y, 32, 32)
end

function perform_elevation_scan()
    local x0 = 9000
    local y0 = 9000
    local nx = 1024
    local ny = 1024

    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 1)
    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 4)
    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 16)
    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 64)
    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 128)
    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 256)
    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 512)
    log_region(global.logger_elevation_scan, x0, y0, nx, ny, 1024)
end
