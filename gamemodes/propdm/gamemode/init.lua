include("config/sv_globals.lua")
include("game/sv_gamelogic.lua")

function GM:InitPostEntity()
    game.CleanUpMap()
end