require "socket"

net = {}

net.protocol_version = "1.0a" -- major dot minor (private alpha / public beta)
net.server_version   = "1.0a"


--  00  NUL  Null                       16  DLE  Data Link Escape      --
--  01  SOH  Start of Heading           17  DC1  Device Control 1      --
--  02  STX  Start of Text              18  DC2  Device Control 2      --
--  03  ETX  End of Text                19  DC3  Device Control 3      --
--  04  EOT  End of Transmission        20  DC4  Device Control 4      --
--  05  ENQ  Enquiry                    21  NAK  Negative Acknowledge  --
--  06  ACK  Acknowledge                22  SYN  Synchronous Idle      --
--  07  BEL  Bell                       23  ETB  End of Transmission   --
--  08  BS   Backspace                  24  CAN  Cancel                --
--  09  HT   Horizontal Tabulation      25  EM   End of Medium         --
--  10  LF   Line Feed                  26  SUB  Substitute            --
--  11  VT   Vertical Tabulation        27  ESC  Escape                --
--  12  FF   Form Feed                  28  FS   File Separator        --
--  13  CR   Carriage Return            29  GS   Group Separator       --
--  14  SO   Shift Out                  30  RS   Record Separator      --
--  15  SI   Shift In                   31  US   Unit Separator        --

net.codes = {}

net.codes.start_of_key   = string.char(30)
net.codes.start_of_value = string.char(31)
net.codes.block_end      = string.char(04)

net.codes.query      = string.char(05)
net.codes.connect    = string.char(15)
net.codes.data       = string.char(01)
net.codes.disconnect = string.char(14)

net.codes.connection_accepted = string.char(06)
net.codes.connection_rejected = string.char(21)

net.codes.bool_true  = string.char(17)
net.codes.bool_false = string.char(18)


net.callbacks = {}
net.callbacks.client_connected = {}
net.callbacks.data_received = {}

for _,callback in pairs(net.callbacks) do -- Allow for net.callbacks.callback_type(args)
    setmetatable(callback, {__call = function (tbl, ...)
        for _,func in pairs(tbl) do
            func(...)
        end
    end })
end


net.clients = {}
net.clients_nextid = 1

function net.new_server(port)
    net.server = socket.udp()
    net.server:setsockname("*", port)
    net.server:settimeout(0.01)
end

function net.update()
    local data, ip, port = net.server:receivefrom()
    if data then
        -- print(getccode(data), ip, port)
        local address = ip .. ":" .. port
        local header = data:sub(1,1)
        local data = data:sub(2)

        if header == net.codes.query then
            -- Send data like version numbers and players
            local players = 0
            for k,v in pairs(game.snaiks) do
                if v.connected then
                    players = players + 1
                end
            end
            net.server:sendto(net.pack({
                version = net.server_version,
                protocol = net.protocol_version,
                players = players,
                maxplayers = game.max_players
            }), ip, port)

            return
        end

        if header == net.codes.connect then
            if net.clients[address] then
                -- Client already connected
                net.server:sendto(net.codes.connection_rejected .. "Already connected", ip, port)
            else
                local players = 0
                for k,v in pairs(game.snaiks) do
                    if v.connected then
                        players = players + 1
                    end
                end
                if players >= game.max_players then
                    net.server:sendto(net.codes.connection_rejected .. "Server is full!", ip, port)

                    return
                end

                local connections = 0
                for k,v in pairs(net.clients) do
                    if v.ip == ip and game.snaiks[v.id].connected then
                        connections = connections + 1
                    end
                end
                if connections >= 300 then
                    net.server:sendto(net.codes.connection_rejected .. "Too many connections!", ip, port)

                    return
                end

                data = net.unpack(data)

                if #data.name > 15 then
                    net.server:sendto(net.codes.connection_rejected .. "Invalid name", ip, port)

                    return
                end

                -- Let the client connect
                net.clients[address] = {
                    id = net.clients_nextid,
                    ip = ip,
                    port = port
                }
                net.server:sendto(net.codes.connection_accepted .. net.clients_nextid, ip, port)

                print(data.name .. " (#" .. net.clients_nextid .. ") connected - " .. address)
                net.callbacks.client_connected(net.clients_nextid, ip, port, data)

                net.clients_nextid = net.clients_nextid + 1
            end

            return
        end

        if header == net.codes.data then
            local client = net.clients[address]
            if client then
                net.callbacks.data_received(net.unpack(data), client.id, client.ip, client.port)
            end

            return
        end

        if header == net.codes.disconnect then
            local client = net.clients[address]
            if client then
                print("Client #" .. client.id .. " disconnected")
                game.snaiks[client.id].connected = false
            end

            return
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
            if tonumber(value) == value then
                value = tonumber(value)
            end

            local cr, cg, cb = value:match("([0-9]+)%.([0-9]+)%.([0-9]+)")
            if cr and cg and cb then
                value = {cr, cg, cb}
            end

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

function net.pack(data)
    local str = ""
    for k,v in pairs(data) do
        if type(v) == "boolean" then
            v = v and net.codes.bool_true or net.codes.bool_false
        end
        str = str .. net.codes.start_of_key .. k .. net.codes.start_of_value .. v
    end
    return str .. net.codes.block_end
end

function net.broadcast(data)
    str = net.pack(data)
    for k,v in pairs(net.clients) do
        net.server:sendto(str, v.ip, v.port)
    end
end

function net.send(data, ip, port)
    str = net.pack(data)
    net.server:sendto(str, ip, port)
end

function net.send_update()
    local data = {
        type       = "update",
        snaiks     = 0,
        field_size = game.field_size
    }
    for id,snaik in pairs(game.snaiks) do
        if snaik.connected then
            data.snaiks = data.snaiks + 1
            data[data.snaiks .. "x"] = snaik.blocks[1].x
            data[data.snaiks .. "y"] = snaik.blocks[1].y
            data[data.snaiks .. "id"] = snaik.id
            data[data.snaiks .. "gameover"] = snaik.gameover

            local dirs = ""
            for k,block in pairs(snaik.blocks) do
                if k > 1 then
                    if block.x < snaik.blocks[k-1].x then
                        dirs = dirs .. "l"
                    elseif block.y < snaik.blocks[k-1].y then
                        dirs = dirs .. "u"
                    elseif block.x > snaik.blocks[k-1].x then
                        dirs = dirs .. "r"
                    elseif block.y > snaik.blocks[k-1].y then
                        dirs = dirs .. "d"
                    end
                end
            end
            data[data.snaiks .. "dirs"] = dirs
        end
    end
    net.broadcast(data)
end
