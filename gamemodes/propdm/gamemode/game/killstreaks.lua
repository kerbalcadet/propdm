-- playerdeath hook called in sv_gamelogic.lua
AddCSLuaFile()
if SERVER then util.AddNetworkString("PDM_Killstreak") end

function KS_Clusternade(ply)
    ply:Give("pdm_clusternade")
end

function KS_EmergencyNade(ply)
    ply:Give("pdm_emregency_nade")
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

function KS_Chopper(ply)
    ply:Give("pdm_ks_chopper")
end

PDM_KILLSTREAKS = {
    {name = "Cluster Nade", kills = 3, func = KS_Clusternade},
    {name = "Care Package", kills = 3, func = KS_CarePkg},
    {name = "Propket Launcher", kills = 5, func = KS_Launcher},
    {name = "Emergency Airdrop", kills = 5, func = KS_EmergencyNade},
    {name = "Sentry Turret", kills = 7, func = KS_Sentry},
    {name = "Chopper Gunner", kills = 7, func = KS_Chopper},
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

if SERVER then
    
util.AddNetworkString("PDM_KS_Check")
util.AddNetworkString("PDM_KS_Request")

function PDM_IncreaseStreak(att)
    local ks = att:GetNW2Int("Streak") + 1
    att:SetNW2Int("Streak", ks)
    
    net.Start("PDM_KS_Check")
    net.WriteInt(ks, 8)
    net.Send(att)
end

function PDM_KS_Request(ply, name)
    for _, ks in pairs(PDM_KILLSTREAKS) do
        if not (name == ks.name) then continue end
        if not ply:GetNW2Int("Streak") == ks.kills then return end

        local ksfunc = ks.func
        ksfunc(ply)

        net.Start("PDM_Killstreak")
            net.WriteString(name)
        net.Send(ply)
    end
end

net.Receive("PDM_KS_Request", function(len, ply)
    print("svtest")

    local name = net.ReadString()
    if not name then return end

    PDM_KS_Request(ply, name)
end)

end