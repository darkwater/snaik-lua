scores = {}

scores.list = {
    {
        name = "Darkwater",
        food = 25,
        deaths = 2,
        streak = 21,
        ping = 4
    },
    {
        name = "Dubbhead",
        food = 12,
        deaths = 23,
        streak = 8,
        ping = 21
    }
}

function scores.draw()
    local y = 50

    love.graphics.setFont(game.fonts[24])
    for k,v in pairs(scores.list) do
        love.graphics.print(v.name, 30, y)

        y = y + 30
    end
end