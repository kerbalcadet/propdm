AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Prop Grenade"

function ENT:PhysicsCollide(data,phys)
    if data.Speed > 50 then
        self:EmitSound("physics/metal/metal_grenade_impact_hard"..math.random(1,3)..".wav")
    end
end

if CLIENT then

function ENT:Draw()
    self:DrawModel()
end

end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/w_grenade.mdl")
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)

        local phys = self:GetPhysicsObject()
        if phys:IsValid() then 
            phys:Wake()
            phys:SetMass(1)
        end

        self.Owner = self.Owner or self:GetOwner()
        self.Weapon = self.Weapon or self:GetOwner():GetActiveWeapon()
    end

    self.Fuse = self.Fuse or 3
    self.CallTime = 4   --after fuse
    self.SpawnTime = self.CallTime + 3
    self.Failed = false

    self.DespTime = self.DespTime or 15
    self.SpawnTime = CurTime()
    self.Exploded = false

    self.Color = Color(240, 70, 70)
    self.ParticleDelay = 0.03 --affects density of smoke trail

    self.ExpSound = CreateSound(self, "Weapon_Extinguisher.NPC_Double")
    self.SmokeSound = CreateSound(self, "ambient/machines/gas_loop_1.wav")

    if CLIENT then
        self.Emitter = ParticleEmitter(self:GetPos(), false)
    end
end

function ENT:Think()
    if self.SpawnTime + self.Fuse < CurTime() and CurTime() < self.SpawnTime + self.Fuse + self.DespTime then
        if not self.Exploded then
            self.Exploded = true

            --sound

            if SERVER then
                self.ExpSound:Play()
                self.ExpSound:ChangePitch(150)
                self.SmokeSound:Play()
            end

            --despawning
            timer.Simple(self.DespTime, function()
                if not IsValid(self) then return end

                if SERVER then
                    self.ExpSound:Stop()
                    self.SmokeSound:Stop() 
                    self:Remove() 
                end
                if CLIENT and not self.Failed then self.Emitter:Finish() end 
            end)

            --call plane
            timer.Simple(self.CallTime, function()
                local success = false
                local pos = self:GetPos()
                
                local data = {start=pos, endpos=pos+Vector(0,0,100000), filter=self, MASK_NPCWORLDSTATIC}
                local tr = util.TraceLine(data)            

                if not tr.HitSky then 
                    self.Failed = true

                    if CLIENT then
                        self.Emitter:Finish() 
                        self:GetOwner():PrintMessage(4, "Smoke could not be seen!") 
                        return
                    end
                    if SERVER then 
                        self.ExpSound:Stop()
                        self.SmokeSound:Stop()
                        self:GetOwner():Give("pdm_carepkg_nade")
                        return
                    end
                end
            end)
        end

        --fx
        if CLIENT and not self.Failed then
            local pos = self:GetPos()
            local em = self.Emitter
            local part = em:Add("particles/pdm/smoke", pos)

            local c = self.Color
            part:SetColor(c.r, c.g, c.b)
            part:SetDieTime(4)
            part:SetEndAlpha(0)
            part:SetStartSize(5)
            part:SetEndSize(120)
            part:SetGravity(Vector(0,0,100))
            part:SetVelocity(Vector(80, 20, 50) + VectorRand()*20)
            part:SetAngleVelocity(AngleRand()/100)
        end
    end

    if CLIENT then
        self:SetNextClientThink(CurTime() + self.ParticleDelay)
        return true
    end
end