-- [num kills] = [function, name] (takes ply as input)
-- playerdeath hook called in sv_gamelogic.lua

util.AddNetworkString("PDM_Killstreak")

PDM_KILLSTREAKS = {
    [2] = {KS_Clusternade, "Cluster Grenade"}   
}

function KS_Clusternade(ply)
    ply:Give("pdm_clusternade")
end