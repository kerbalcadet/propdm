include("shared.lua")
include("config/sv_globals.lua")
include("config/sv_config.lua")
include("game/sv_entities.lua")
include("game/sv_gamelogic.lua")
include("game/sv_player.lua")
include("game/sv_props.lua")
include("game/sv_teams.lua")
include("game/sv_killstreak.lua")
include("game/sv_heli.lua")
include("util/sv_fileutil.lua")

AddCSLuaFile("game/cl/cl_fonts.lua")
AddCSLuaFile("game/cl/cl_hud.lua")

function GM:InitPostEntity()
    local t1 = FILE:LoadList("gamemodes/propdm/gamemode/config/spawnlists/construction.txt", "GAME")
    local t2 = FILE:LoadList("gamemodes/propdm/gamemode/config/spawnlists/comic.txt", "GAME")

    PDM_PROPS = t1.contents
    table.Add(PDM_PROPS, t2.contents)

    for _, ent in pairs(PDM_PROPS) do
        util.PrecacheModel(ent.model)
    end

    RoundTimer()
end