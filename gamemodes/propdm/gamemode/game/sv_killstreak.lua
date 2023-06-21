-- [num kills] = [function, name] (takes ply as input)
-- playerdeath hook called in sv_gamelogic.lua

util.AddNetworkString("PDM_Killstreak")

function KS_Clusternade(ply)
    ply:Give("pdm_clusternade")
end

function KS_Launcher(ply)
    print("launcher!") --tmp replace with launcher
end

PDM_KILLSTREAKS = {
    [3] = {KS_Clusternade, "Cluster Grenade"},
    [5] = {KS_Launcher, "Prop Launcher"}
}