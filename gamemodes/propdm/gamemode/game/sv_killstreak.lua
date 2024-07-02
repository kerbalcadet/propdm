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

function KS_CarePkg(ply)
    ply:Give("pdm_carepkg_nade")
end

PDM_KILLSTREAKS = {
    [2] = {KS_Clusternade, "Cluster Grenade"},
    [3] = {KS_CarePkg, "Care Package"},
    [5] = {KS_Launcher, "Propket Launcher"},
    [7] = {KS_Sentry, "Sentry Gun"},
}

PDM_CAREPKG_WEPS = {
    "pdm_launcher",
    "pdm_sentry_spawner",
    "pdm_carepkg_nade",
    "pdm_propify_nade",
    "pdm_emergency_nade",
    "pdm_ks_chopper",
    "pdm_nadelauncher",
    "pdm_cluster_rocketnade"
}