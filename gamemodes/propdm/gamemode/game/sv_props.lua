function PDM_PropFromTable(tab, pos)
    local ent = ents.Create("prop_physics")
    ent:SetModel(tab.model)
    ent:SetPos(pos)
    ent:Spawn()

    return ent
end

function PDM_PropInfo(mdl)
    local info = util.GetModelInfo(mdl)
    if not info.KeyValues then return false end

    local tab = util.KeyValuesToTable(info.KeyValues)
    local mass = tab.editparams.totalmass or nil
    local vol = tab.solid.volume or nil

    return mass, vol, tab
end

function PDM_FireProp(tab, pos, ang, vel, avel, att)
    local ent = PDM_PropFromTable(tab, pos)
    local phys = ent:GetPhysicsObject()

    if not IsValid(phys) or not ent:GetMoveType() == MOVETYPE_VPHYSICS then ent:Remove() return false end

    ent:SetAngles(ang or Angle(0, 0, 0))
    phys:SetVelocity(vel or Vector(0, 0, 0))
    phys:SetAngleVelocity(avel or Angle(0, 0, 0))

    ent.Attacker = att

    return ent
end

function PDM_PropExplode(tabs, pos, vel, normal, att)
    local props = {}
    for _, tab in pairs(tabs) do
        local ar = AngleRand()
        local vr = VectorRand()

        --keep vector in same hemisphere as normal
        local dot = vr:Dot(normal)
        if dot < 0 then vr = vr - dot*2*normal end

        local new = PDM_FireProp(tab, pos + normal*100, ar, vel*vr, vr*100, att)
        new:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
        table.insert(props, new)
    end

    timer.Simple(0.1, function()
        for _, p in pairs(props) do
            if IsValid(p) then p:SetCollisionGroup(COLLISION_GROUP_NONE) end
        end
    end)

    return props
end

hook.Remove("ShouldCollide", "PDM_PropExplode")
hook.Add("ShouldCollide", "PDM_PropExplode", function()
    
end)

--properly attribute prop damage
hook.Remove("EntityTakeDamage", "PDM_PropDamage")
hook.Add("EntityTakeDamage", "PDM_PropDamage", function(ent, dmg)
	if not ent:IsPlayer() or not (dmg:GetInflictor():GetClass() == "prop_physics") then return end
	
	local inf = dmg:GetInflictor()
	if inf.Attacker then dmg:SetAttacker(inf.Attacker) end 
	if inf.Inflictor then dmg:SetInflictor(inf.Inflictor) end
end)