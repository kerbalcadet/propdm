function PDM_PropFromTable(tab, pos)
    local ent = ents.Create("prop_physics")
    ent:SetModel(tab.model)
    ent:SetPos(pos)
    ent:Spawn()

    return ent
end

function PDM_FireProp(tab, pos, ang, vel, avel)
    local ent = PDM_PropFromTable(tab, pos)
    local phys = ent:GetPhysicsObject()

    if not IsValid(phys) or not ent:GetMoveType() == MOVETYPE_VPHYSICS then return false end

    ent:SetAngles(ang or Angle(0, 0, 0))
    phys:SetVelocity(vel or Vector(0, 0, 0))
    phys:SetAngleVelocity(avel or Angle(0, 0, 0))

    return ent
end

--properly attribute prop damage
hook.Remove("EntityTakeDamage", "PDM_PropDamage")
hook.Add("EntityTakeDamage", "PDM_PropDamage", function(ent, dmg)
	if not ent:IsPlayer() or not (dmg:GetInflictor():GetClass() == "prop_physics") then return end
	
	local inf = dmg:GetInflictor()
	if inf.Attacker then dmg:SetAttacker(inf.Attacker) end 
	if inf.Inflictor then dmg:SetInflictor(inf.Inflictor) end
end)