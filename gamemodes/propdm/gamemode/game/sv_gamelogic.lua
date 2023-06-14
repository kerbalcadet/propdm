function RoundStart()

    for _, p in pairs(player.GetAll()) do
        p:Spawn()
        gamemode.Call("PlayerInitialSpawn", p)
        gamemode.Call("PlayerSpawn", p)
    end
end

hook.Remove("EntityFireBullets", "Propageddon")
hook.Add("EntityFireBullets", "Propageddon", function(v,bullet)
	if v:IsNPC() and v:GetClass() == "npc_helicopter" and SERVER then
			if math.random(100) < 35 then
                local tab = table.Random(PDM_PROPS)
                local ent = ents.Create("prop_physics")

                ent:SetModel(tab.model)
                ent:SetPos(bullet.Src + bullet.Dir * 32)
                ent:Spawn()
                local phys = ent:GetPhysicsObject()

                if not IsValid(phys) or ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return end
                ent:SetAngles(AngleRand())
                ent:SetOwner(v)

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