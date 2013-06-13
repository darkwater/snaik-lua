local function index(str, key)
    if type(key) == "number" then
        return string.sub(str, key, key)
    else
        return string[key]
    end
end

getmetatable("s").__index = index


function print_r(tbl, pre)
    if not pre then pre = "" end
    for k,v in pairs(tbl) do
        if type(v) == "table" then
            print(k .. ":")
            print_r(v, pre .. "    ")
        else
            print(pre .. k, v)
        end
    end
end


utils = {}

utils.draw_button = function (v, x, y, w, h)
    if v.hovering then
        love.graphics.setColor(255, 255, 255, 255 - v.hoveranim * 200)
    else
        local i = (v.hoveranim or 0) * 255
        love.graphics.setColor(i, i, i, 100)
    end
    love.graphics.rectangle("fill", x, y, w, h)

    if v.hovering then
        return {0, 0, 0, 255}
    else
        return {255, 255, 255, 255}
    end
end

utils.update_button = function (v, x, y, w, h, dt)
    local hovering = love.mouse.getX() > x and love.mouse.getX() < x + w and
                        love.mouse.getY() > y and love.mouse.getY() < y + h
    local active = hovering and love.mouse.isDown("l")

    if hovering and not v.hovering then
        love.audio.stop(game.sounds["hover"])
        love.audio.play(game.sounds["hover"])
    end

    if hovering and game.mousepressed then
        love.audio.stop(game.sounds["click_next"])
        love.audio.play(game.sounds["click_next"])
    end

    v.hovering = hovering
    v.active = active

    if not v.hoveranim then
        v.hoveranim = 0
    end

    if v.hovering and v.hoveranim < 1 then
        v.hoveranim = v.hoveranim + dt * 5
    elseif not v.hovering and v.hoveranim > 0 then
        v.hoveranim = v.hoveranim - dt * 5
    end

    if v.hoveranim > 1 then
        v.hoveranim = 1
    elseif v.hoveranim < 0 then
        v.hoveranim = 0
    end

    return hovering and game.mousepressed
end


utils.draw_textbox = function (v, x, y, w, h)
    if v.active then
        love.graphics.setColor(255, 255, 255, 150)
    elseif v.hovering then
        love.graphics.setColor(255, 255, 255, 255 - v.hoveranim * 200)
    else
        local i = (v.hoveranim or 0) * 255
        love.graphics.setColor(i, i, i, 100)
    end
    love.graphics.rectangle("fill", x, y, w, h)

    if v.hovering or v.active then
        return {0, 0, 0, 255}
    else
        return {255, 255, 255, 255}
    end
end

utils.update_textbox = function (v, x, y, w, h, dt)
    local hovering = love.mouse.getX() > x and love.mouse.getX() < x + w and
                        love.mouse.getY() > y and love.mouse.getY() < y + h

    v.active = (v.active and not (not v.hovering and game.mousepressed)) or
               (v.hovering and game.mousepressed)

    if hovering and not v.hovering and not v.active then
        love.audio.stop(game.sounds["hover"])
        love.audio.play(game.sounds["hover"])
    end

    if hovering and game.mousepressed then
        love.audio.stop(game.sounds["click"])
        love.audio.play(game.sounds["click"])
    end

    v.hovering = hovering

    if not v.hoveranim then
        v.hoveranim = 0
    end

    if v.hovering and v.hoveranim < 1 then
        v.hoveranim = v.hoveranim + dt * 5
    elseif not v.hovering and v.hoveranim > 0 then
        v.hoveranim = v.hoveranim - dt * 5
    end

    if v.hoveranim > 1 then
        v.hoveranim = 1
    elseif v.hoveranim < 0 then
        v.hoveranim = 0
    end
end
