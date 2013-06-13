function love.load()
    game = {}

    game.time = 0

    require "json"
    require "utils"
    require "net"
    require "shaders"
    require "menu"


    game.fonts = {}
    game.fonts[16] = love.graphics.newFont("res/SF Intermosaic B.ttf", 16)
    game.fonts[24] = love.graphics.newFont("res/SF Intermosaic.ttf", 24)
    game.fonts[32] = love.graphics.newFont("res/SF Intermosaic.ttf", 32)
    game.fonts[48] = love.graphics.newFont("res/SF Intermosaic.ttf", 48)
    game.fonts[64] = love.graphics.newFont("res/SF Intermosaic.ttf", 64)

    game.sounds = {}
    game.sounds["hover"] = love.audio.newSource("res/hover.ogg", "static")
    game.sounds["click"] = love.audio.newSource("res/click.ogg", "static")
    game.sounds["click_next"] = love.audio.newSource("res/click_next.ogg", "static")

    -- love.audio.setVolume(0.2)


    game.snaiks = {}
    game.food = {}
    game.food_particles = {}

    function game.new_food_particle(x, y, ci)
        local speed = math.random(4, 8) / 10
        table.insert(game.food_particles, {
            x     = x * game.block_size,
            y     = y * game.block_size,
            ci    = ci,
            r     = math.cos(ci) * 40 + 200,
            g     = math.sin(ci) * 40 + 200,
            b     = math.tan(ci) * 40 + 200,
            dir   = math.random(0, 628) / 100,
            ang   = math.random(0, 628) / 100,
            speed = speed
        })
    end

    game.mapx = -5000
    game.mapy = 2000
    game.block_size = 25
    game.field_size = 1
    game.scroll_speed = 0.5

    game.our_id = 0
    game.last_dir_sent = ""
    game.focused = true


    love.joystick.open(1)


    menu.load()
end


function love.update(dt)
    game.time = game.time + dt

    if not net.connected then

        menu.update(dt)

    else

        if love.joystick.isOpen(1) and game.focused then
            local x,y = love.joystick.getAxes(1)
            if y < -0.5 and math.abs(y) > math.abs(x) and game.last_dir_sent ~= "up" then
                net.send({dir = "up"})
                game.last_dir_sent = "up"
            end
            if x < -0.5 and math.abs(x) > math.abs(y) and game.last_dir_sent ~= "left" then
                net.send({dir = "left"})
                game.last_dir_sent = "left"
            end
            if y > 0.5 and math.abs(y) > math.abs(x) and game.last_dir_sent ~= "down" then
                net.send({dir = "down"})
                game.last_dir_sent = "down"
            end
            if x > 0.5 and math.abs(x) > math.abs(y) and game.last_dir_sent ~= "right" then
                net.send({dir = "right"})
                game.last_dir_sent = "right"
            end
        end

        net.update()

        if game.snaiks[game.our_id] and game.snaiks[game.our_id].connected then
            game.mapx = game.mapx + (game.snaiks[game.our_id].blocks[1].x * game.block_size - 512 - game.mapx) / game.scroll_speed * dt
            game.mapy = game.mapy + (game.snaiks[game.our_id].blocks[1].y * game.block_size - 384 - game.mapy) / game.scroll_speed * dt
        end

        for id,snaik in pairs(game.snaiks) do
            if snaik.connected then
                local namex = snaik.blocks[1].x * game.block_size - game.mapx
                local namey = snaik.blocks[1].y * game.block_size - game.mapy

                if math.sqrt(namex*namex + namey*namey) > 350 then
                    local ang = math.atan2(namey, namex)
                    namex = math.cos(ang) * 350
                    namey = math.sin(ang) * 350
                end

                namex = namex + 512 - snaik.namew / 2
                namey = namey + 384 - 10

                snaik.namex = snaik.namex + (namex - snaik.namex) / game.scroll_speed * dt
                snaik.namey = snaik.namey + (namey - snaik.namey) / game.scroll_speed * dt


                if snaik.gameover then
                    snaik.gameover_anim = snaik.gameover_anim + dt * 2.5
                    if snaik.gameover_anim > 1 then
                        snaik.gameover_anim = 1
                    end

                    snaik.final_color = {
                        snaik.color[1] + (255 - snaik.color[1]) * snaik.gameover_anim,
                        snaik.color[2] + (255 - snaik.color[2]) * snaik.gameover_anim,
                        snaik.color[3] + (255 - snaik.color[3]) * snaik.gameover_anim,
                        (1 - snaik.gameover_anim) * 255
                    }
                else
                    snaik.gameover_anim = 0
                    snaik.final_color = snaik.color
                end
            end
        end

        for k,v in pairs(game.food) do
            if math.random(1, 10) == 1 then
                game.new_food_particle(v.x, v.y, v.ci)
            end
        end

        for k,v in pairs(game.food_particles) do
            if v.speed <= 0 then
                game.food_particles[k] = nil
            else
                v.x = v.x + math.cos(v.dir) * v.speed
                v.y = v.y + math.sin(v.dir) * v.speed
                v.speed = math.max(v.speed - 0.002, 0)
                v.ang = v.ang + v.speed * 2
            end
        end
    end

    if menu.quit.anim > 0 then
        menu.quit.update(dt)
    end

    shaders.update()
end


function love.draw()
    if net.connected then
        love.graphics.setColor(255, 255, 255, 255)

        love.graphics.setPixelEffect(shaders.effects.background)
            love.graphics.rectangle("fill", 0, 0, 1024, 768)
        love.graphics.setPixelEffect()

        love.graphics.push()
        love.graphics.translate(-game.mapx, -game.mapy)

        for k,v in pairs(game.food_particles) do
            love.graphics.setColor(v.r, v.g, v.b)

            local x1 = v.x - math.cos(v.ang) * 2
            local y1 = v.y - math.sin(v.ang) * 2
            local x2 = v.x + math.cos(v.ang) * 2
            local y2 = v.y + math.sin(v.ang) * 2
            love.graphics.line(x1,y1 , x2,y2)
        end

        for k,food in pairs(game.food) do
            local n = math.sin((game.time + food.ci) * 2) * 0.3 + 0.6
            local r = math.cos(food.ci) * 40 + 200
            local g = math.sin(food.ci) * 40 + 200
            local b = math.tan(food.ci) * 40 + 200
            love.graphics.setColor(r, g, b, n*255)

            local fx = food.x*game.block_size
            local fy = food.y*game.block_size

            if game.snaiks[game.our_id].connected then
                local sx = game.snaiks[game.our_id].blocks[1].x * game.block_size
                local sy = game.snaiks[game.our_id].blocks[1].y * game.block_size

                love.graphics.line(fx, fy, sx, sy)
            end

            love.graphics.rectangle("fill", fx - game.block_size/2,
                                            fy - game.block_size/2,
                                            game.block_size, game.block_size)
        end
        
        love.graphics.setFont(game.fonts[16])
        for id,snaik in pairs(game.snaiks) do
            if snaik.connected then
                love.graphics.setColor(snaik.final_color)

                for i,block in pairs(snaik.blocks) do
                    love.graphics.rectangle("fill", block.x*game.block_size - game.block_size/2,
                                                    block.y*game.block_size - game.block_size/2,
                                                    game.block_size, game.block_size)
                end
            end
        end

        love.graphics.pop()


        -- for id,snaik in pairs(game.snaiks) do
        --     if snaik.connected then
        --         love.graphics.setColor(snaik.final_color)

        --         local dx = snaik.blocks[1].x * game.block_size - game.mapx
        --         local dy = snaik.blocks[1].y * game.block_size - game.mapy

        --         if math.sqrt(dx*dx + dy*dy) > 350 then
        --             local ang = math.atan2(dy, dx)
        --             love.graphics.circle("fill", 512 + math.cos(ang) * 350, 384 + math.sin(ang) * 350, 10, 10)
        --         end
        --     end
        -- end

        for id,snaik in pairs(game.snaiks) do
            if snaik.connected then
                -- if id ~= game.our_id then
                    love.graphics.setColor(0, 0, 0, 100)
                    love.graphics.rectangle("fill", snaik.namex - 10, snaik.namey - 2, snaik.namew + 20, 25)

                    love.graphics.setColor(0, 0, 0, 255)
                    love.graphics.print(snaik.name, snaik.namex + 2, snaik.namey + 2)
                    
                    love.graphics.setColor(snaik.color)
                    love.graphics.print(snaik.name, snaik.namex, snaik.namey)
                -- end
            end
        end


        net.debug()
    end

    if shaders.menu_background.alpha > 0.01 then
        love.graphics.setPixelEffect(shaders.effects.menu_background)
            love.graphics.rectangle("fill", 0, 0, 1024, 768)
        love.graphics.setPixelEffect()
    end

    if not net.connected then
        menu.draw()
    end


    if menu.quit.visible and menu.quit.anim < 1 then
        menu.quit.anim = menu.quit.anim + 0.1
    end
    if not menu.quit.visible and menu.quit.anim > 0 then
        menu.quit.anim = menu.quit.anim - 0.1
    end

    if menu.quit.anim > 1 then menu.quit.anim = 1 end
    if menu.quit.anim < 0 then menu.quit.anim = 0 end

    if menu.quit.anim > 0 then
        menu.quit.draw()
    end


    if love.joystick.isOpen(1) then
        local x,y = love.joystick.getAxes(1)
        love.graphics.setColor(255, 255, 255)
        love.graphics.setPointSize(5)
        love.graphics.point(x*100+100, y*100+100)

        love.graphics.setColor(200, 200, 200, 100)
        if y < -0.5 and math.abs(y) > math.abs(x) then
            love.graphics.setColor(255, 175, 0, 200)
        end
        love.graphics.polygon("fill", 0,0 , 50,50 , 150,50 , 200,0)

        love.graphics.setColor(200, 200, 200, 100)
        if x < -0.5 and math.abs(x) > math.abs(y) then
            love.graphics.setColor(255, 175, 0, 200)
        end
        love.graphics.polygon("fill", 0,0 , 50,50 , 50,150 , 0,200)

        love.graphics.setColor(200, 200, 200, 100)
        if y > 0.5 and math.abs(y) > math.abs(x) then
            love.graphics.setColor(255, 175, 0, 200)
        end
        love.graphics.polygon("fill", 0,200 , 50,150 , 150,150 , 200,200)

        love.graphics.setColor(200, 200, 200, 100)
        if x > 0.5 and math.abs(x) > math.abs(y) then
            love.graphics.setColor(255, 175, 0, 200)
        end
        love.graphics.polygon("fill", 200,0 , 150,50 , 150,150 , 200,200)
    end


    game.mousepressed = false
end


function love.keypressed(key, unicode)
    if key == "escape" then
        love.event.quit()
        return
    end

    local char = string.char(unicode)

    if menu.namebox.active then
        if char:match("^[%w ]$") and #menu.namebox.name < 15 then
            menu.namebox.name = menu.namebox.name .. char
        end
        if key == "backspace" then
            menu.namebox.name = menu.namebox.name:sub(1, #menu.namebox.name-1)
        end
    end

    if menu.direct.ipbox.active then
        if char:match("^[0-9.:]$") and #menu.direct.ipbox.ip < 21 then
            menu.direct.ipbox.ip = menu.direct.ipbox.ip .. char
        end
        if key == "backspace" then
            menu.direct.ipbox.ip = menu.direct.ipbox.ip:sub(1, #menu.direct.ipbox.ip-1)
        end
        if key == "return" then
            menu.direct.doconnect()
            menu.direct.ipbox.active = false
        end
    end

    if key == "f1" then
        debug.visible = not debug.visible
    end

    if net.connected then
        local keys = {
            up    = "up",     w = "up",
            down  = "down",   s = "down",
            left  = "left",   a = "left",
            right = "right",  d = "right"
        }
        if keys[key] and game.last_dir_sent ~= keys[key] then
            net.send({dir = keys[key]})
            game.last_dir_sent = keys[key]
        end
    end
end


function love.mousepressed(x, y, but)
    if but == "l" then
        game.mousepressed = true
    -- elseif but == "wu" then                          -- FRIES YOUR GRAPHICS CARD UNLESS
    --     game.block_size = game.block_size + 1        -- CAREFULLY USED!!
    -- elseif but == "wd" then
    --     game.block_size = game.block_size - 1        -- okay it doesnt but it made my screen flicker
    end
end


function love.focus(f)
    game.focused = f
end


function love.joystickpressed(joy, but)
    if menu.quit.visible then
        if but == 1 then
            menu.quit.doquit = true
            love.event.quit()
        elseif but == 2 then
            menu.quit.visible = false
        end
    elseif but >= 7 and but <= 9 then
        menu.quit.visible = true
    end
end


function love.quit()
    if not menu.quit.doquit then
        menu.quit.visible = not menu.quit.visible
    end

    if menu.quit.doquit then
        if net.connected then
            net.close()
        end
        return false
    end

    return true
end
