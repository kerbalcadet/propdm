-- playerdeath hook called in sv_gamelogic.lua
AddCSLuaFile()
if SERVER then util.AddNetworkString("PDM_Killstreak") end

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
    {name = "Cluster Nade", kills = 3, func = KS_Clusternade},
    {name = "Care Package", kills = 3, func = KS_CarePkg},
    {name = "Propket Launcher", kills = 5, func = KS_Launcher},
    {name = "Sentry Turret", kills = 7, func = KS_Sentry},
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