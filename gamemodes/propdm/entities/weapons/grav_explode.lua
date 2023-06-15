--helper function since multiple weapons use gravity explosions
function PDM_GravExplode(pos, rad, pwr, minrad, plyw, att)
    for _,ent in pairs(ents.FindInSphere(pos, rad)) do
        local phys = ent:GetPhysicsObject()
        if not ent:IsSolid() or not phys:IsValid() then continue end

        local diff = ent:GetPos() + phys:GetMassCenter() - pos
        local dir = diff:GetNormalized()
        local dist = math.Clamp(diff:Length()/12, minrad, rad/12)	--feet bc why not
        local force = (dir/(dist^(3/2)))*pwr
        local plyweight = plyw or 2400

        ent:SetPos(ent:GetPos()+Vector(0,0,1))  --remove ground friction

        if(ent:IsPlayer()) then     --applyforce doesn't work for players
            ent:SetVelocity(ent:GetVelocity() + force/plyw)
        else
            phys:ApplyForceCenter(force)
        end

        ent.Attacker = att

        -- if not friend or ent != own then
        --     local dmginfo = DamageInfo()
        --     dmginfo:SetDamage(dmg)
        --     dmginfo:SetInflictor(inf)
        --     dmginfo:SetAttacker(own)
        --     ent:TakeDamageInfo(dmginfo)
        -- end
    end
end