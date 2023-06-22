-- [num kills] = [function, name] (takes ply as input)
-- playerdeath hook called in sv_gamelogic.lua

util.AddNetworkString("PDM_Killstreak")

function KS_Clusternade(ply)
    ply:Give("pdm_clusternade")
end

function KS_Launcher(ply)
    ply:Give("pdm_launcher")
end

function KS_Sentry(ply)
    ply:Give("pdm_sentry_spawner")
end

PDM_KILLSTREAKS = {
    [3] = {KS_Clusternade, "Cluster Grenade"},
    [5] = {KS_Launcher, "Propket Launcher"},
    [7] = {KS_Sentry, "Sentry Gun"}
}