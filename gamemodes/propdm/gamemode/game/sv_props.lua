

hook.Remove("EntityFireBullets", "Propageddon")
hook.Add("EntityFireBullets", "Propageddon", function(wep,bullet)
	if SERVER and wep:IsNPC() then
        if wep:GetClass() == "npc_helicopter" or wep:GetClass() == "npc_turret_floor" then
            wep:SetCustomCollisionCheck(true)

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

            if math.random(100) < BulletParams[wep:GetClass()]["prob"] then
                local tab = table.Random(PDM_PROPS)
                
                local ent = ents.Create("prop_physics")

                ent:SetModel(tab.model)

                ent:SetPos((BulletParams[wep:GetClass()]["pos"] or bullet.Src) + (bullet.Dir * 32))
                ent:Spawn()
                local phys = ent:GetPhysicsObject()

                if not IsValid(phys) or not ent:IsSolid() or ent:GetMoveType() ~= MOVETYPE_VPHYSICS then ent:Remove() return end

                -- The angles of the actual prop model, NOT the angle / direction it's being fired
                ent:SetAngles(AngleRand())
                ent:SetOwner(wep)
                ent.Attacker = wep

                ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
                timer.Simple(0.3, function()
                    if not IsValid(ent) then return end
                    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
                end)

                phys:SetVelocity(BulletParams[wep:GetClass()]["vel"] or Vector(3000, 3000, -3000))
               wep:EmitSound("garrysmod/balloon_pop_cute.wav", 400, 100, 0.4)

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