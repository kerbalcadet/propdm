function RoundStart()

    for _, p in pairs(player.GetAll()) do
        p:Spawn()
        gamemode.Call("PlayerInitialSpawn", p)
        gamemode.Call("PlayerSpawn", p)
    end

    PDM_ScoreUpdate()
end

hook.Remove("PlayerDeath", "PDM_PlayerDeath")
hook.Add("PlayerDeath", "PDM_PlayerDeath", function(vic, inf, att)
    if not att:IsPlayer() or vic == att then return end
    
    att:AddPoints(10)

    --handle killstreaks
    local ks = att:GetNW2Int("Streak") + 1
    att:SetNW2Int("Streak", ks)
    
    local kstab = PDM_KILLSTREAKS[ks]
    if istable(kstab) then
        local ksfunc = kstab[1]
        local name = kstab[2]

        ksfunc(att)

        net.Start("PDM_Killstreak")
            net.WriteString(name)
        net.Send(att)
    end
end)