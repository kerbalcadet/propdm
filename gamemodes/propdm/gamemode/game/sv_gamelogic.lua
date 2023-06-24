util.AddNetworkString("PDM_RoundStart")
function RoundStart()
    PDM_ScoreUpdate()
    PDM_SpawnHeli()

    for _, p in pairs(player.GetAll()) do
        p:SetMoveType(MOVETYPE_WALK)
        p:PDM_GiveDefaultWeapons()
    end
end
concommand.Add("pdm_roundstart", RoundStart)
concommand.Add("pdm_reset", GAMEMODE.InitPostEntity)

PDM_ROUNDSTART = 0
function RoundTimer()
    local delay = PDM_TIMEBEFOREROUND:GetInt()
    local t = CurTime() + delay
    PDM_ROUNDSTART = t

    --write round start message on clients 
    net.Start("PDM_RoundStart")
        net.WriteInt(PDM_KILLGOAL:GetInt(), 16)
        net.WriteInt(t, 16)
    net.Broadcast()

    --actual round cleanup/player init
    game.CleanUpMap()
    game.SetTimeScale(1)
    for _, e in pairs(ents.GetAll()) do
        e.Map = true
    end

    for _, p in pairs(player.GetAll()) do
        p:Spawn()
        gamemode.Call("PlayerInitialSpawn", p)
        gamemode.Call("PlayerSpawn", p)

        --freeze plys
        p:SetMoveType(MOVETYPE_NONE)
        p:StripWeapons()
    end

    timer.Simple(delay, function()
        RoundStart()
    end)
end

util.AddNetworkString("PDM_RoundEnd")
function RoundEnd(winner)
    net.Start("PDM_RoundEnd")
        net.WriteString(winner:Nick())
    net.Broadcast()

    timer.Simple(0.1, function()
        local slomo = PDM_SLOMO:GetInt()/100
        game.SetTimeScale(slomo)
        timer.Simple(PDM_TIMEAFTERROUND:GetInt()*slomo, RoundTimer)
    end)
end

hook.Remove("PlayerDeath", "PDM_PlayerDeath")
hook.Add("PlayerDeath", "PDM_PlayerDeath", function(vic, inf, att)
    if not att:IsPlayer() or vic == att then return end
    
    att:AddPoints(10)

    --handle game ending
    local pts = att:GetNW2Int("Points")
    if pts >= PDM_KILLGOAL:GetInt()*10 then
        RoundEnd(att)
        return
    end

    --handle killstreaks
    local ks = att:GetNW2Int("Streak") + 1
    att:SetNW2Int("Streak", ks)
    
    local kstab = PDM_KILLSTREAKS[ks]
    if kstab and not table.IsEmpty(kstab) then
        local ksfunc = kstab[1]
        local name = kstab[2]

        ksfunc(att)

        net.Start("PDM_Killstreak")
            net.WriteString(name)
        net.Send(att)
    end
end)