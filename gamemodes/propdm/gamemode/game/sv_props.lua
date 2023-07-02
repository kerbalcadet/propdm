PDM_PROPREPLACE = {
    "prop_",
    "func_"
}

function PDM_EntFromTable(tab, pos, ang)
    local class = tab.class

    local replace = nil
    for _, v in pairs(PDM_PROPREPLACE) do
        if string.StartsWith(class, v) then 
            replace = true
            break 
        end
    end

    class = replace and "prop_physics_multiplayer" or class

    local ent = ents.Create(class)
    ent:SetModel(tab.model)
    ent:SetSkin(tab.skn or 0)
    ent:SetPos(pos)
    ent:Spawn()

    local phys = ent:GetPhysicsObject()
    local mass = tab.mass or nil
    if mass then phys:SetMass(mass) end

    --npc weapons
    if tab.weps and not table.IsEmpty(tab.weps) then
        for _, v in pairs(tab.weps) do
            ent:Give(v)
        end
    end

    if ent:IsNPC() then ang = ang/3 end  --easy way to keep npc angles above ground
    ent:SetAngles(ang)

    return ent
end

function PDM_PropInfo(mdl)
    local info = util.GetModelInfo(mdl)
    if not info or not info.KeyValues then return false end

    local tab = util.KeyValuesToTable(info.KeyValues)
    local mass = tab.editparams.totalmass or nil
    local vol = tab.solid.volume or nil

    return mass, vol, tab
end

function PDM_CalcMass(phys)
    --https://wiki.facepunch.com/gmod/Structures/SurfacePropertyData
    --calculation of default gmod mass data for metal
    return phys:GetSurfaceArea()*0.1*0.0254^3*2700
end

function PDM_FireProp(tab, pos, ang, vel, avel, att)
    local ent = PDM_EntFromTable(tab, pos, ang)
    local phys = ent:GetPhysicsObject()

    if not IsValid(phys) or not ent:GetMoveType() == MOVETYPE_VPHYSICS then ent:Remove() return false end

    local minv = ent:WorldSpaceAABB()
    local ground = util.QuickTrace(pos, Vector(0,0,-5000), ent).HitPos
    local zdiff = minv.z - ground.z

    if zdiff < 0 then
        ent:SetPos(pos + Vector(0,0, -zdiff + 5))
    end

    if ent:IsNPC() then
        ent:SetNavType(NAV_NONE)
        ent:SetVelocity(vel)
        ent:SetNavType(NAV_GROUND)
        ent:AddRelationship("player D_HT 99")
        ent:AddEntityRelationship(att, D_LI, 99)
    else
        phys:SetVelocity(vel or Vector(0, 0, 0))
        phys:SetAngleVelocity(avel or Angle(0, 0, 0))
    end

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
	if not string.StartsWith(inf:GetClass(), "prop_physics") then return end

	local inf = dmg:GetInflictor()
	if inf.Attacker then dmg:SetAttacker(inf.Attacker) end 
	if inf.Inflictor then dmg:SetInflictor(inf.Inflictor) end
end)