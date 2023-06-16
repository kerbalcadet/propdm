

hook.Remove("EntityFireBullets", "Propageddon")
hook.Add("EntityFireBullets", "Propageddon", function(v,bullet)
	if v:IsNPC() and v:GetClass() == "npc_helicopter" and SERVER then
        v:SetCustomCollisionCheck(true)
        if math.random(100) < 45 then
            local tab = table.Random(PDM_PROPS)
            local ent = ents.Create("prop_physics")

            ent:SetModel(tab.model)
            ent:SetPos(bullet.Src + bullet.Dir * 32)
            ent:Spawn()
            local phys = ent:GetPhysicsObject()

            if not IsValid(phys) or not ent:IsSolid() or ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return end

            
            ent:SetAngles(AngleRand())
            ent:SetOwner(v)
            ent.Attacker = v

            ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
            timer.Simple(0.3, function()
                if not IsValid(ent) then return end
                ent:SetCollisionGroup(COLLISION_GROUP_NONE)
            end)

            local vr = VectorRand()
            vr.z = 0;
            local vel = Vector(3000,3000,-3000)*vr
            vel.z = Vector(3000,3000,-3000).z
            phys:SetVelocity(vel)


            v:EmitSound("garrysmod/balloon_pop_cute.wav", 400, 100, 0.4)

            --despawning
            timer.Create(tostring(ent).."desp",PDM_DESPTIME,1, function()
                if not IsValid(ent) then return end
                ent:Dissolve(false, 1, ent:GetPos())
            end)
        end
		return false
	end
end)