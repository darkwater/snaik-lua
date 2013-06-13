game.snaiks_metatable = {}
game.snaiks_metatable.__index = {}
game.snaiks_metatable.__index.spawn = function (snaik)
    local x = math.random(-game.spawn_radius, game.spawn_radius)
    local y = math.random(-game.spawn_radius, game.spawn_radius)

    snaik.blocks = {}
    for i=1, game.initial_snaik_length do
        snaik.blocks[i] = {x = x - i, y = y}
    end

    snaik.direction = "right"
    snaik.direction_queue = {}

    snaik.gameover = false
end

game.new_snaik = function(id, ip, port, data)

    local snaik = {
        connected       = true,
        name            = "Foo",
        id              = id,
        ip              = ip,
        port            = port,
        blocks          = {},
        direction       = "right",
        direction_queue = {},
        gameover        = false,
        color           = data.color,
        name            = data.name,
    }

    setmetatable(snaik, game.snaiks_metatable)

    snaik:spawn()

    return snaik
end

game.update_snaik = function (id, snaik)
    snaik.direction = table.remove(snaik.direction_queue, 1) or snaik.direction

    local new_block = {x= snaik.blocks[1].x, y= snaik.blocks[1].y}

    if snaik.direction == "left" then
        new_block.x = new_block.x - 1
    elseif snaik.direction == "right" then
        new_block.x = new_block.x + 1
    elseif snaik.direction == "up" then
        new_block.y = new_block.y - 1
    elseif snaik.direction == "down" then
        new_block.y = new_block.y + 1
    end

    local collided = false

    if math.abs(new_block.x) > game.field_size or math.abs(new_block.y) > game.field_size then
        collided = true
    else
        for tid,target in pairs(game.snaiks) do
            if not target.gameover and target.connected then
                for _,block in pairs(target.blocks) do
                    if block.x == new_block.x and block.y == new_block.y then
                        collided = true
                        break
                    end
                end
            end
        end
    end

    local nommed = false
    for k,food in pairs(game.food) do
        if new_block.x == food.x and new_block.y == food.y then
            game.food[k].nommed = true
            nommed = true
            break
        end
    end

    if collided then
        snaik.gameover = true
        snaik.gameover_timer = game.respawn_time
    else
        table.insert(snaik.blocks, 1, new_block)
        if not nommed then
            table.remove(snaik.blocks, #snaik.blocks)
        end
    end
end
