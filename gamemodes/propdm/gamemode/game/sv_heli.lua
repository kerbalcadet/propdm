hook.Remove("EntityFireBullets", "PDM_HeliProps")
hook.Add("EntityFireBullets", "PDM_HeliProps", function(wep, bullet)
    --
    -- Sanity checks
    --
	if not SERVER then return end
    if not (wep:GetClass() == "npc_helicopter") then return end

    local prob = 45  --%
    if math.random(100) > prob then return false end
    
    --
    -- If we got to this point, we *should* be good to run the rest of the hook
    --
    
    local tab = table.Random(PDM_PROPS)
    local pos = bullet.Src + bullet.Dir * 32
    local vel = Vector(3000, 3000, 0) * bullet.Dir + Vector(0, 0, -3000)

    --table, pos, angle, vel, angvel
    local ent = PDM_FireProp(tab, pos, AngleRand(), vel, VectorRand()*100)

    --phys didn't work right
    if not ent then return false end

    ent.Attacker = wep
    wep:EmitSound("garrysmod/balloon_pop_cute.wav", 400, 100, 0.4)

    --collisions
    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
    timer.Simple(0.3, function()
        if not IsValid(ent) then return end
        ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    end)

    --despawning
    timer.Simple(PDM_DESPTIME, function()
        if IsValid(ent) then ent:Dissolve(false, 1, ent:GetPos()) end
    end)

    -- return false IOT NOT fire the original bullet(s)
    return false
end)