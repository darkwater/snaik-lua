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
    local y = 150

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setFont(game.fonts[16])
    love.graphics.print("Name", 30, 130)
    love.graphics.printf("Food", 600, 130, 100, "right")
    love.graphics.printf("Deaths", 700, 130, 100, "right")
    love.graphics.printf("Streak", 800, 130, 100, "right")
    love.graphics.printf("Ping", 900, 130, 100, "right")

    love.graphics.setFont(game.fonts[24])
    for k,v in pairs(scores.list) do
        love.graphics.setColor(0, 0, 0, 125)
        love.graphics.rectangle("fill", 0, y, 1024, 32)

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.print(v.name, 30, y + 2)
        love.graphics.printf(v.food, 600, y + 2, 100, "right")
        love.graphics.printf(v.deaths, 700, y + 2, 100, "right")
        love.graphics.printf(v.streak, 800, y + 2, 100, "right")
        love.graphics.printf(v.ping, 900, y + 2, 100, "right")

        y = y + 40
    end
end