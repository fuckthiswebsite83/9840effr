loadstring([[
    local stuff = getconnections(game:GetService("ScriptContext").Error)
    for i, v in pairs(stuff) do
        v:Disconnect()
    end

    loadstring(game:HttpGet("https://raw.githubusercontent.com/fuckthiswebsite83/9840effr/refs/heads/main/thegame.lua"))()
]])()
