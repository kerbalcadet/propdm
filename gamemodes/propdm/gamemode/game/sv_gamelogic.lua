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
    if not att:IsPlayer() then return end

    att:AddPoints(10)
end)