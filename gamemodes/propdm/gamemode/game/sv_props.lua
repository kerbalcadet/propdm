function PDM_EntFromTable(tab, pos)
    local ent = ents.Create(tab.class)
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
    local ent = PDM_EntFromTable(tab, pos)
    local phys = ent:GetPhysicsObject()

    if not IsValid(phys) or not ent:GetMoveType() == MOVETYPE_VPHYSICS then ent:Remove() return false end

    ent:SetAngles(ang or Angle(0, 0, 0))
    phys:SetVelocity(vel or Vector(0, 0, 0))
    phys:SetAngleVelocity(avel or Angle(0, 0, 0))

    ent.Attacker = att

    return ent
end

function PDM_PropExplode(tabs, pos, vel, normal, maxang, att)

    local props = {}
    for _, tab in pairs(tabs) do
        local ar = AngleRand()

        --create vector within max vertical angle
        local a = AngleRand()
        a.p = math.random(-maxang, maxang)
        local vr = a:Forward()

        --make sure it's firing in the same hemisphere as the normal
        --pass (0,0,0) to normal if you want to have a spherical-ish explosion
        local dot = vr:Dot(normal)
        if dot < 0 then vr = vr + 2*dot*normal end

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

--properly attribute prop damage
hook.Remove("EntityTakeDamage", "PDM_PropDamage")
hook.Add("EntityTakeDamage", "PDM_PropDamage", function(ent, dmg)
    local inf = dmg:GetInflictor()
    if not IsValid(ent) or not IsValid(inf) then return end
	if not ent:IsPlayer() or not string.StartsWith(inf:GetClass(), "prop_physics") then return end

	local inf = dmg:GetInflictor()
	if inf.Attacker then dmg:SetAttacker(inf.Attacker) end 
	if inf.Inflictor then dmg:SetInflictor(inf.Inflictor) end
end)