--helper function since multiple weapons use gravity explosions
function PDM_GravExplode(pos, rad, pwr, dmg, dmgrad, own, inf)
    for _,ent in pairs(ents.FindInSphere(pos, rad)) do
        local phys = ent:GetPhysicsObject()
        if not ent:IsSolid() or not phys:IsValid() then continue end

        local diff = ent:GetPos() + phys:GetMassCenter() - pos
        local dir = diff:GetNormalized()
        local distsq = math.Clamp(diff:LengthSqr()/144, 0.5, 100)	--feet bc why not
        local force = (dir/distsq)*pwr
        local plyweight = PDM_GRAVPLYWEIGHT or 2400

        if(ent:IsPlayer()) then     --applyforce doesn't work for players
            ent:SetVelocity(ent:GetVelocity() + force/plyweight)
        else
            phys:ApplyForceCenter(force)
        end

        if ent != own then
            local dmginfo = DamageInfo()
            dmg:SetDamage(dmg)
            dmg:SetInflictor(inf)
            dmg:SetAttacker(own)
            ent:TakeDamageInfo(dmg)
        end
    end
end