function RoundStart()
    game.CleanUpMap()

    for _, e in pairs(ents.GetAll()) do
        e.Map = true
    end

    for _, p in pairs(player.GetAll()) do
        p:Spawn()
        gamemode.Call("PlayerInitialSpawn", p)
        gamemode.Call("PlayerSpawn", p)
    end

    PDM_ScoreUpdate()
    PDM_SpawnHeli()

    --to write round start message on clients 
    net.Start("PDM_RoundStart")
        net.WriteInt(PDM_KILLGOAL:GetInt(), 16)
    net.Broadcast()
end
concommand.Add("pdm_roundstart", RoundStart)
concommand.Add("pdm_reset", GAMEMODE.InitPostEntity)

hook.Remove("PlayerDeath", "PDM_PlayerDeath")
hook.Add("PlayerDeath", "PDM_PlayerDeath", function(vic, inf, att)
    if not att:IsPlayer() or vic == att then return end
    
    att:AddPoints(10)

    --handle game ending
    local pts = att:GetNW2Int("Points")
    print(pts)


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