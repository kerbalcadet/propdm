util.AddNetworkString("PDM_RoundStart")
function RoundStart()
    PDM_ResetHeliPath(true)
    PDM_SpawnHeli()

    for _, p in pairs(player.GetAll()) do
        p:SetMoveType(MOVETYPE_WALK)
        p:PDM_GiveDefaultWeapons()
    end
end
concommand.Add("pdm_roundstart", RoundStart)

PDM_ROUNDSTART = 0
function RoundTimer()
    local delay = PDM_TIMEBEFOREROUND:GetInt()
    local t = CurTime() + delay
    PDM_ROUNDSTART = t

    --write round start message on clients 
    net.Start("PDM_RoundStart")
        net.WriteInt(PDM_KILLGOAL:GetInt(), 16)
        net.WriteInt(CurTime(), 16)
        net.WriteInt(t, 16)
    net.Broadcast()

    --actual round cleanup/player init
    game.CleanUpMap()
    game.SetTimeScale(1)
    for _, e in pairs(ents.GetAll()) do
        e.map = true
    end

    for _, p in pairs(player.GetAll()) do
        p:Spawn()
        gamemode.Call("PlayerInitialSpawn", p)
        gamemode.Call("PlayerSpawn", p)

        --freeze plys
        p:SetMoveType(MOVETYPE_NONE)
        p:StripWeapons()
    end

    PDM_ScoreUpdate()

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
    PDM_IncreaseStreak(att)
    
    --create global ragdoll
    vic:SetShouldServerRagdoll(true)
end)

hook.Remove("OnNPCKilled", "PDM_NPCRagdoll")
hook.Add("OnNPCKilled", "PDM_NPCRagdoll", function(npc)
    npc:SetShouldServerRagdoll(true)
end)

hook.Remove("CreateEntityRagdoll", "PDM_RagdollDespawn")
hook.Add("CreateEntityRagdoll", "PDM_RagdollDespawn", function(own, rag)
    --only one ragdoll at a time
    if IsValid(own.Ragdoll) then
        own.Ragdoll:Dissolve(1, rag:GetPos())
    end
    own.Ragdoll = rag
    
    timer.Simple(PDM_DESPTIME:GetInt(), function()
        if IsValid(rag) then rag:Dissolve(1, rag:GetPos()) end
    end)
end)