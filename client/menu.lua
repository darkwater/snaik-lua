http = require "socket.http"

menu = {}

menu.titletext = "Loading"
menu.subtitletext = ""

menu.quit = {}
menu.quit.buttons = {
    {
        label = "cancel",
        quit = false,
        xbox_key = "B",
        xbox_color = {200, 50, 0}
    },
    {
        label = "quit",
        quit = true,
        xbox_key = "A",
        xbox_color = {50, 200, 0}
    }
}
menu.quit.visible = false
menu.quit.anim = 0
menu.quit.doquit = false

menu.servers = {}

menu.direct = {}
menu.direct.ipbox = {ip="127.1"}
menu.direct.connect = {}
menu.direct.doconnect = function ()
    local ip, port = menu.direct.ipbox.ip:match("([0-9.]+):([0-9]+)")
    if not ip then
        ip, port = menu.direct.ipbox.ip:match("([0-9.]+)"), 7182
    end
    net.newclient(ip, port)
end

menu.namebox = {}
menu.namebox.hovering = false
menu.namebox.hoveranim = 0
menu.namebox.active = false
menu.namebox.name = "anonymous"

menu.colorrow = {}
menu.colorrow.colors = {
    {color={255, 175,   0}, hovering = false, hoveranim = 0},
    {color={175, 255,   0}, hovering = false, hoveranim = 0},
    {color={255,   0, 175}, hovering = false, hoveranim = 0},
    {color={175,   0, 255}, hovering = false, hoveranim = 0},
    {color={  0, 255, 175}, hovering = false, hoveranim = 0},
    {color={  0, 175, 255}, hovering = false, hoveranim = 0},
}
menu.colorrow.active = 1

function menu.quit.update(dt)
    local y = 3
    for k,v in pairs(menu.quit.buttons) do
        if utils.update_button(v, 904, y, 120, 24, dt) then
            if v.quit then
                menu.quit.doquit = true
                love.event.quit()
            else
                menu.quit.visible = false
            end
        end

        y = y + 25
    end
end

function menu.quit.draw()
    love.graphics.setFont(game.fonts[16])

    local y = (1-menu.quit.anim) * -((#menu.quit.buttons) * 20)
    for k,v in pairs(menu.quit.buttons) do
        local color = utils.draw_button(v, 904, y, 120, 25)
        love.graphics.setColor(color)
        -- love.graphics.print(v.label, 904 + (120 - game.fonts[16]:getWidth(v.label)) / 2, y + 3)
        love.graphics.printf(v.label, 904, y + 3, 120, "center")

        if love.joystick.isOpen(1) then
            love.graphics.setColor(v.xbox_color)
            love.graphics.print(v.xbox_key, 885, y + 3)
        end

        y = y + 25
    end
end



function menu.load()
--    local data = http.request("http://api.novaember.com/snaik/serverlist")
--    if data then
--         data = json.decode(data)
         menu.servers = { { name= "Novaember", ip= "novaember.com", port= 7182 } }
 
         menu.pingthread = love.thread.newThread("pingthread", "thread_ping.lua")
         menu.pingthread:start()
 
         menu.pingthread:set("count", #menu.servers)
 
         for k,v in pairs(menu.servers) do
             menu.pingthread:set("ip" .. k, v.ip)
             menu.pingthread:set("port" .. k, v.port)
 
             v.ping = 0
             v.maxplayers = "?"
             v.players = "?"
 
             v.hoveranim = 0
         end
--     else
--         menu.titletext = "Error"
--         menu.subtitletext = "Could not connect to master server"
--     end
end

function menu.update(dt)
    if menu.pingthread then
        for i=1, #menu.servers do
            local ping = menu.pingthread:get("ping" .. i)
            if ping and ping > 0 then
                menu.servers[i].ping = ping

                local data = net.unpack(menu.pingthread:demand("data" .. i))
                for k,v in pairs(data) do
                    menu.servers[i][k] = v
                end
            end
        end

        if menu.pingthread:get("done") then
            -- menu.pingthread = nil
            menu.titletext = "Choose a server"
        end
    end

    local y = 140
    for k,v in pairs(menu.servers) do
        if v.direct then
            y = y + 35
        end

        if utils.update_button(v, 0, y, 1024, 35, dt) then
            net.newclient(v.ip, v.port)
        end

        y = y + 40
    end

    -- Direct
    y = y + 35
    utils.update_textbox(menu.direct.ipbox, 25, y, 425, 35, dt)
    if utils.update_button(menu.direct.connect, 800, y, 180, 35, dt) then
        menu.direct.doconnect()
    end

    -- Namebox
    utils.update_textbox(menu.namebox, 20, 698, 450, 50, dt)

    -- Colors
    local x = 480
    for k,v in pairs(menu.colorrow.colors) do
        if utils.update_button(v, x, 698, 50, 50, dt) then
            menu.colorrow.active = k
        end

        x = x + 60
    end
end

function menu.draw()
    love.graphics.setColor(255, 255, 255, 255)

    love.graphics.setFont(game.fonts[48])
    love.graphics.print(menu.titletext, 20, 30) -- Title
    if game.time % 1.060 < 0.530 and menu.subtitletext == "" then
        love.graphics.print("_", game.fonts[48]:getWidth(menu.titletext) + 25, 30)
    end

    love.graphics.setFont(game.fonts[24])
    love.graphics.print(menu.subtitletext, 23, 80) -- Subtitle
    if game.time % 1.060 < 0.530 and menu.subtitletext ~= "" then
        love.graphics.print("_", game.fonts[24]:getWidth(menu.subtitletext) + 25, 80)
    end

    if #menu.servers > 1 then
        love.graphics.setFont(game.fonts[16])
        love.graphics.print("Server name", 40, 120)
        love.graphics.printf("Players", 750, 120, 0, "center") -- List legend
        love.graphics.printf("Ping", 992, 120, 0, "right")
    end

    -- Servers
    local y = 140
    for k,v in pairs(menu.servers) do
        love.graphics.setFont(game.fonts[24])

        local color = utils.draw_button(v, 0, y, 1024, 35)
        color[4] = v.ping > 0 and 255 or 100
        love.graphics.setColor(color)

        love.graphics.print(v.name .. ((v.ping > 0) and "" or "..."), 40, y + 2) -- Server name

        love.graphics.printf(v.players, 745, y + 2, 0, "right")
        love.graphics.printf("/", 750, y + 2, 0, "center") -- Server details
        love.graphics.printf(v.maxplayers, 758, y + 2, 0, "left")

        love.graphics.printf(((v.ping > 0) and v.ping or "-") .. "ms", 1000, y + 2, 0, "right")

        y = y + 40
    end

    -- Direct connect
    love.graphics.setFont(game.fonts[16])
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Direct connect:", 40, y + 12)

    y = y + 35

    love.graphics.setColor(0, 0, 0, 100)
    love.graphics.rectangle("fill", 0, y, 25, 35)

    local color = utils.draw_textbox(menu.direct.ipbox, 25, y, 425, 35)
    love.graphics.setColor(color)
    love.graphics.setFont(game.fonts[24])
    love.graphics.print(menu.direct.ipbox.ip .. ((menu.direct.ipbox.active and #menu.direct.ipbox.ip < 21 and game.time % 1.060 < 0.530) and "_" or ""), 40, y + 2)

    love.graphics.setColor(0, 0, 0, 100)
    love.graphics.rectangle("fill", 450, y, 350, 35)

    local color = utils.draw_button(menu.direct.connect, 800, y, 180, 35)
    love.graphics.setColor(color)
    love.graphics.print("Connect", 817, y + 2)

    love.graphics.setColor(0, 0, 0, 100)
    love.graphics.rectangle("fill", 980, y, 44, 35)
    
    -- Namebox
    local color = utils.draw_textbox(menu.namebox, 20, 698, 450, 50)
    love.graphics.setColor(color)
    love.graphics.setFont(game.fonts[32])
    love.graphics.print(menu.namebox.name .. ((menu.namebox.active and #menu.namebox.name < 15 and game.time % 1.060 < 0.530) and "_" or ""), 35, 703)

    -- Colors
    local x = 480
    for k,v in pairs(menu.colorrow.colors) do
        local r = v.color[1]
        local g = v.color[2]
        local b = v.color[3]

        if menu.colorrow.active == k then
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.rectangle("fill", x-2, 696, 54, 54)

            love.graphics.setColor(r, g, b, 255)
        elseif v.hovering then
            r = 255 - (255 - r) * v.hoveranim
            g = 255 - (255 - g) * v.hoveranim
            b = 255 - (255 - b) * v.hoveranim
            love.graphics.setColor(r, g, b, 255)
        else
            love.graphics.setColor(r, g, b, 100 + v.hoveranim * 155)
        end

        love.graphics.rectangle("fill", x, 698, 50, 50)

        x = x + 60
    end
end
