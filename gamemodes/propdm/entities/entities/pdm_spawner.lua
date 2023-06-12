ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true 
ENT.PrintName = "pdm spawner"
ENT.PropPos = Vector(0,0,-100)
ENT.PropVelRange = Vector(1000,1000,-1000)
ENT.SpawnDelay = 0.2
AddCSLuaFile()

function ENT:Initialize()
    self:SetModel("models/Combine_Helicopter.mdl")
    self:PhysicsInitStatic(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:EmitSound("npc/attack_helicopter/aheli_rotor_loop1.wav", 400, 100, 0.2)
    self:ResetSequence(0)
    self:SetPlaybackRate(1)

    self:Think()
end

if SERVER then
   
function ENT:Think()
    self:NextThink(CurTime())
end

function ENT:SpawnProp(num)
    timer.Create(tostring(self).."spawn", self.SpawnDelay, num, function()
        --create prop
        local tab = table.Random(PDM_PROPS)
        local ent = ents.Create("prop_physics")
        
        ent:SetModel(tab.model)
        ent:SetPos(self:GetPos() + self.PropPos)
        ent:Spawn()
        
        local phys = ent:GetPhysicsObject()
        phys:SetMass(tab.weight)
        ent:SetAngles(AngleRand())

        local vr = VectorRand()
        vr.z = 0;
        local vel = self.PropVelRange*vr
        vel.z = self.PropVelRange.z
        phys:SetVelocity(vel)

        self:EmitSound("garrysmod/balloon_pop_cute.wav", 400, 100, 0.4)

        --despawning
        timer.Create(tostring(ent).."desp",PDM_DESPTIME,1, function()
            ent:Dissolve(false, 1, self:GetPos())
        end)
    end)
end

function ENT:StartSpawn(num)
    num = num or 1
    timer.Create(tostring(self).."spawning", PDM_SPAWNDELAY, 0, function() self:SpawnProp(num) end)
end

function ENT:StopSpawn()
    timer.Destroy(tostring(self).."spawning")
end


end