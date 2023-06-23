function PDM_SpawnHeli()
    local HSpawn = ents.FindByClass("pdm_helispawn")[1]
    local heli = ents.Create("npc_helicopter")

    heli:SetPos(HSpawn:GetPos())
    heli:SetHealth(100)
    heli:SetKeyValue("InitialSpeed", "500")
    heli:SetKeyValue("PatrolSpeed", "1000")
    heli:SetKeyValue("ignoreunseenenemies", "yes")
    --heli:AddFlags(1377028)
    heli:SetKeyValue("spawnflags", "1377028")

    heli:Spawn()
    heli:Activate()
    heli:Fire("SetTrack", "heli_patrol_1")
    heli:Fire("physdamagescale", "1")
    heli:Fire("StartPatrol")

    heli.MaxProps = 100
    heli.Props = {}
end

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
    ent:SetOwner(wep)
    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
    timer.Simple(0.3, function()
        if not IsValid(ent) then return end
        ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    end)


    --despawning
    timer.Simple(2, function()
        --only track number if they aren't immediately deleted 
        if not wep.Props or not wep.MaxProps then return end
        
        if #wep.Props > wep.MaxProps then
            local e = wep.Props[1]
            if IsValid(e) then e:Dissolve(false, 1, ent:GetPos()) end
        end
    
        table.remove(wep.Props, 1)
        table.insert(wep.Props, ent)

        --regular ol despawn timer
        timer.Simple(PDM_DESPTIME, function()
        if IsValid(ent) then ent:Dissolve(false, 1, ent:GetPos()) end
    end)
    end)



    -- return false IOT NOT fire the original bullet(s)
    return false
end)