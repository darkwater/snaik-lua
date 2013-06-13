require "socket"

net = {}

net.codes = {}

net.codes.start_of_key = string.char(30)
net.codes.start_of_value = string.char(31)
net.codes.block_end = string.char(04)

net.codes.query = string.char(05)

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

thread = love.thread.getThread()

local numservers = thread:demand("count")

for i=1, numservers do
    local ip = thread:demand("ip" .. i)
    local port = thread:demand("port" .. i)


    local sock = socket.udp()
    sock:setpeername(ip, port)
    sock:settimeout(1)


    local starttime = socket.gettime()
    sock:send(net.codes.query)
    local response = sock:receive()
    if not response then
        thread:set("ping" .. i, 0)
    else
        local ping = socket.gettime() - starttime + 0.000001
        thread:set("ping" .. i, math.ceil(ping * 1000))
        thread:set("data" .. i, response)
    end
end

thread:set("done", true)
