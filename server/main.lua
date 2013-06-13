math.randomseed(os.time())

if love then
    love.event.quit()
    return
end

game = {}

require "utils"
require "net"
require "snaik"

game.time = socket.gettime()
game.tick_timer = 0
game.tick_interval = 0.1

game.snaiks = {}
game.food = {}
game.food_nextid = 1
game.food_max = 2
game.initial_snaik_length = 10
game.respawn_time = 2
game.spawn_radius = 10
game.field_size = 30
game.max_players = 24

function game.new_food()
    local food = {
        id = game.food_nextid,
        x = math.random(-game.field_size, game.field_size),
        y = math.random(-game.field_size, game.field_size),
        nommed = false
    }
    table.insert(game.food, food)
    game.food_nextid = game.food_nextid + 1

    local data = {
        type = "food_spawned",
        id = food.id,
        x = food.x,
        y = food.y
    }
    net.broadcast(data)
end


net.new_server(7182)


table.insert(net.callbacks.client_connected, function(id, ip, port, data)
    game.snaiks[id] = game.new_snaik(id, ip, port, data)

    local data = {
        type = "client_connected",
        id = id,
        name = data.name,
        cr = data.color[1],
        cg = data.color[2],
        cb = data.color[3]
    }
    net.broadcast(data)

    local data = {
        type = "all_clients",
        amount = 0
    }
    for k,client in pairs(game.snaiks) do
        data.amount = data.amount + 1
        data[data.amount .. "id"] = client.id
        data[data.amount .. "name"] = client.name
        data[data.amount .. "cr"] = client.color[1]
        data[data.amount .. "cg"] = client.color[2]
        data[data.amount .. "cb"] = client.color[3]
    end
    net.send(data, ip, port)

    data = {
        type = "all_food",
        amount = 0
    }
    for k,food in pairs(game.food) do
        data.amount = data.amount + 1
        data[data.amount .. "id"] = food.id
        data[data.amount .. "x"] = food.x
        data[data.amount .. "y"] = food.y
    end
    net.send(data, ip, port)
end)

table.insert(net.callbacks.data_received, function(data, id, ip, port)
    if data.dir then
        local snaik = game.snaiks[id]
        
        local nextdir = snaik.direction_queue[#snaik.direction_queue] or snaik.direction
        local dirs = {
            up    = nextdir ~= "down",
            down  = nextdir ~= "up",
            left  = nextdir ~= "right",
            right = nextdir ~= "left",
        }
        if dirs[data.dir] then
            table.insert(snaik.direction_queue, data.dir)
        end
    end
end)


game.last_frame = game.time
while true do
    game.time = socket.gettime()
    local dt = game.time - game.last_frame
    game.last_frame = game.time

    net.update()

    game.tick_timer = game.tick_timer + dt
    if game.tick_timer > game.tick_interval then
        game.tick_timer = game.tick_timer - game.tick_interval

        local food_alive = 0
        for k,food in pairs(game.food) do
            if not food.nommed then
                food_alive = food_alive + 1
            end
        end

        while food_alive < game.food_max do
            game.new_food()
            food_alive = food_alive + 1
        end

        local clients_connected = 0
        for k,snaik in pairs(game.snaiks) do
            if snaik.connected then
                clients_connected = clients_connected + 1
            end
        end

        local target_size = clients_connected * 10 + 20
        if target_size < game.field_size then
            game.field_size = game.field_size - 1
        elseif target_size > game.field_size then
            game.field_size = game.field_size + 1
        end

        for id,snaik in pairs(game.snaiks) do
            if snaik.connected then
                if not snaik.gameover then
                    game.update_snaik(id, snaik)
                else
                    snaik.gameover_timer = snaik.gameover_timer - game.tick_interval
                    if snaik.gameover_timer < 0 then
                        snaik:spawn()
                    end
                end
            end
        end

        for k,food in pairs(game.food) do
            if food.nommed then
                local data = {
                    type = "food_nommed",
                    id = food.id
                }
                net.broadcast(data)
                table.remove(game.food, k)
            end
        end

        net.send_update()
    end
end
