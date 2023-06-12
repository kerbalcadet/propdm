include("shared.lua")
--include("cl_init.lua")
include("config/sv_globals.lua")
include("game/sv_entities.lua")
include("game/sv_gamelogic.lua")
include("util/sv_fileutil.lua")


function GM:InitPostEntity()
    PDM_PROPS = FILE:LoadList(PDM_PROPS_DIR, "GAME")

    game.CleanUpMap()
    RoundStart()
end