require "socket"

net = {}
net.connected = false
net.sent = 0
net.received = 0
net.sent_last = 0
net.received_last = 0
net.up = 0
net.down = 0
net.last_snapshot = os.time()

net.codes = {}

net.codes.start_of_key = string.char(30)
net.codes.start_of_value = string.char(31)
net.codes.block_end = string.char(04)

net.codes.query = string.char(05)
net.codes.connect = string.char(15)
net.codes.data = string.char(01)
net.codes.disconnect = string.char(14)

net.codes.connection_accepted = string.char(06)
net.codes.connection_rejected = string.char(21)

net.codes.bool_true  = string.char(17)
net.codes.bool_false = string.char(18)


function net.newclient(ip, port)
    net.client = socket.udp()
    net.client:setpeername(ip, port)
    net.client:settimeout(1)

    -- print("Querying server...")

    -- net.client:send(net.codes.query)
    -- local versions = net.client:receive()
    -- if not versions then
    --     print("Connection failed.")
    --     return false
    -- end

    -- print("Server is at versions " .. versions)

    local str = net.codes.connect
    str = str .. net.codes.start_of_key .. "name" .. net.codes.start_of_value .. menu.namebox.name
              .. net.codes.start_of_key .. "color" .. net.codes.start_of_value
              .. menu.colorrow.colors[menu.colorrow.active].color[1] .. '.'
              .. menu.colorrow.colors[menu.colorrow.active].color[2] .. '.'
              .. menu.colorrow.colors[menu.colorrow.active].color[3]
              .. net.codes.block_end

    net.client:send(str)
    local response = net.client:receive()
    if not response then
        print("Connection failed.")
        return false
    elseif response[1] == net.codes.connection_rejected then
        print("The server rejected us! - " .. string.sub(response, 2))
        return false
    end

    if response[1] ~= net.codes.connection_accepted then
        print("Something went wrong...")
        return false
    end

    local clientid = response:sub(2)
    game.our_id = tonumber(clientid)


    net.client:settimeout(0)

    net.connected = true
    return true
end

function net.receive()
    local data = net.client:receive()
    if data then
        net.received = net.received + #data

        data = net.unpack(data)
        return data
    end
end

function net.update()
    local data = net.receive()
    if data and data.type then
        if data.type == "update" then
            if data["field_size"] then
                game.field_size = data["field_size"]
            end

            for id,snaik in pairs(game.snaiks) do
                snaik.connected = false
            end

            for i=1, data.snaiks do
                if data[i .. "id"] and game.snaiks[data[i .. "id"]] then
                    local sid = tonumber(data[i .. "id"])

                    if data[i .. "name"] then
                        game.snaiks[sid].name = data[i .. "name"]
                        game.snaiks[sid].namew = game.fonts[16]:getWidth(data[i .. "name"])
                    end

                    if data[i .. "cr"] and data[i .. "cg"] and data[i .. "cb"] then
                        game.snaiks[sid].color = {
                            data[i .. "cr"],
                            data[i .. "cg"],
                            data[i .. "cb"]
                        }
                    end

                    if data[i .. "gameover"] ~= nil then
                        game.snaiks[sid].gameover = data[i .. "gameover"]
                    end

                    game.snaiks[sid].connected = true

                    if data[i .. "x"] and data[i .. "x"] then
                        game.snaiks[sid].blocks = {{
                            x = data[i .. "x"],
                            y = data[i .. "y"]
                        }}
                    end

                    j = 1
                    for c in data[i .. "dirs"]:gmatch"." do
                        local block = {
                            x = game.snaiks[sid].blocks[j].x,
                            y = game.snaiks[sid].blocks[j].y
                        }
                        if     c == "l" then block.x = block.x - 1
                        elseif c == "u" then block.y = block.y - 1
                        elseif c == "r" then block.x = block.x + 1
                        elseif c == "d" then block.y = block.y + 1 end
                        table.insert(game.snaiks[sid].blocks, block)
                        j = j + 1
                    end
                end
            end
        end

        if data.type == "client_connected" then
            local sid = data["id"]
            
            game.snaiks[sid] = {
                blocks = {},
                namex = 0,
                namey = 0,
                gameover_anim = 0,
                connected = false
            }

            if data["name"] then
                game.snaiks[sid].name = data["name"]
                game.snaiks[sid].namew = game.fonts[16]:getWidth(data["name"])
            end

            if data["cr"] and data["cg"] and data["cb"] then
                game.snaiks[sid].color = {
                    data["cr"],
                    data["cg"],
                    data["cb"]
                }
            end
        end

        if data.type == "all_clients" then
            for i=1, data.amount do
                local sid = data[i .. "id"]

                if not game.snaiks[sid] then
                    game.snaiks[sid] = {
                        blocks = {},
                        namex = 0,
                        namey = 0,
                        gameover_anim = 0,
                        connected = false
                    }
                end

                if data[sid .. "name"] then
                    game.snaiks[sid].name = data[sid .. "name"]
                    game.snaiks[sid].namew = game.fonts[16]:getWidth(data[sid .. "name"])
                end

                if data[sid .. "cr"] and data[sid .. "cg"] and data[sid .. "cb"] then
                    game.snaiks[sid].color = {
                        data[sid .. "cr"],
                        data[sid .. "cg"],
                        data[sid .. "cb"]
                    }
                end
            end
        end

        if data.type == "food_spawned" then
            local fid = data["id"]

            game.food[fid] = {
                x = data["x"],
                y = data["y"],
                ci = math.random(1, 100)
            }
        end

        if data.type == "all_food" then
            for k,v in pairs(game.food) do
                v.expire = true
            end

            for i=1, data.amount do
                local fid = data[i .. "id"]

                if game.food[fid] then
                    game.food[fid].x = data[i .. "x"]
                    game.food[fid].y = data[i .. "y"]
                else
                    game.food[fid] = {
                        x = data[i .. "x"],
                        y = data[i .. "y"],
                        ci = math.random(1, 100)
                    }
                end
            end

            for k,v in pairs(game.food) do
                if v.expire then
                    game.food[k] = nil
                end
            end
        end

        if data.type == "food_nommed" then
            game.food[data["id"]] = nil
        end
    end
end

function net.unpack(data)
    local i = 1
    local tbl = {}
    local key = ""
    local value = ""
    local current = ""
    while i <= #data do
        local char = data:sub(i, i)

        if (char == net.codes.start_of_key or char == net.codes.block_end) and current ~= "" then
            if tonumber(value) ~= nil then
                value = tonumber(value)
            end
            if value == net.codes.bool_true then value = true end
            if value == net.codes.bool_false then value = false end
            tbl[key] = value
            key = ""
            value = ""
        end

        if char == net.codes.start_of_key then
            current = "key"
        elseif char == net.codes.start_of_value then
            current = "value"
        else
            if current == "key" then
                key = key .. char
            elseif current == "value" then
                value = value .. char
            end
        end

        i = i + 1
    end

    return tbl
end

function net.send(data)
    local str = net.codes.data
    for k,v in pairs(data) do
        str = str .. net.codes.start_of_key .. k .. net.codes.start_of_value .. v
    end
    str = str .. net.codes.block_end
    net.client:send(str)

    net.sent = net.sent + #str
end

function net.close()
    net.client:send(net.codes.disconnect)
end

function net.debug()
    if net.last_snapshot < os.time() then
        net.up = net.sent - net.sent_last
        net.down = net.received - net.received_last

        net.sent_last = net.sent
        net.received_last = net.received
        net.last_snapshot = os.time()
    end

    love.graphics.setFont(game.fonts[16])
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Sent: " .. kbps(net.sent), 10, 10)
    love.graphics.print("Received: " .. kbps(net.received), 10, 30)

    love.graphics.print("Up: " .. kbps(net.up) .. "/s", 10, 60)
    love.graphics.print("Down: " .. kbps(net.down) .. "/s", 10, 80)
end
function kbps(n) return math.floor((n/1024) * 100) / 100 .. " kb" end
