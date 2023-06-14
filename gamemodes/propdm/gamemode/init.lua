include("shared.lua")
include("config/sv_globals.lua")
include("game/sv_entities.lua")
include("game/sv_gamelogic.lua")
include("game/sv_player.lua")
include("util/sv_fileutil.lua")


function GM:InitPostEntity()
    local t1 = FILE:LoadList("gamemodes/propdm/content/construction.txt", "GAME")
    local t2 = FILE:LoadList("gamemodes/propdm/content/comic.txt", "GAME")

    PDM_PROPS = t1.contents
    table.Add(PDM_PROPS, t2.contents)

    for _, ent in pairs(PDM_PROPS) do
        util.PrecacheModel(ent.model)
    end

    game.CleanUpMap()
    RoundStart()
end