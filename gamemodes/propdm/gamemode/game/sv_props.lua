

hook.Remove("EntityFireBullets", "Propageddon")
hook.Add("EntityFireBullets", "Propageddon", function(v,bullet)
	if SERVER and v:IsNPC() then
        if v:GetClass() == "npc_helicopter" or v:GetClass() == "npc_turret_floor" then
            v:SetCustomCollisionCheck(true)

            -- Dictionary for firing parameters of different NPCs / Killstreaks
            local BulletParams = {
                ["npc_helicopter"] = {
                    ["vel"] = Vector(3000, 3000, 0) * bullet.Dir + Vector(0, 0, -3000),
                    ["prob"] = 45
                },
                ["npc_turret_floor"] = {
                    ["pos"] = bullet.Src,
                    ["vel"] = Vector(2000, 2000, 0) * bullet.Dir,
                    ["prob"] = 30
                }
            }

            if math.random(100) < BulletParams[v:GetClass()]["prob"] then
                local tab = table.Random(PDM_PROPS)
                
                local ent = ents.Create("prop_physics")

                ent:SetModel(tab.model)

                ent:SetPos((BulletParams[v:GetClass()]["pos"] or bullet.Src) + (bullet.Dir * 32))
                ent:Spawn()
                local phys = ent:GetPhysicsObject()

                if not IsValid(phys) or not ent:IsSolid() or ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return end

                -- The angles of the actual prop model, NOT the angle / direction it's being fired
                ent:SetAngles(AngleRand())
                ent:SetOwner(v)
                ent.Attacker = v

                ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
                timer.Simple(0.3, function()
                    if not IsValid(ent) then return end
                    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
                end)

                phys:SetVelocity(BulletParams[v:GetClass()]["vel"] or Vector(3000, 3000, -3000))
                v:EmitSound("garrysmod/balloon_pop_cute.wav", 400, 100, 0.4)

                --despawning
                timer.Create(tostring(ent).."desp",PDM_DESPTIME,1, function()
                    if not IsValid(ent) then return end
                    ent:Dissolve(false, 1, ent:GetPos())
                end)
            end
            return false
        end
	end
end)