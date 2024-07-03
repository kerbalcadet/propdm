AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Proximity Klein"
ENT.Category = "Prop Deathmatch"
ENT.Spawnable = true

function ENT:Initialize()
    self.InitTime = CurTime()
    self.DeployTime = 0.5 --seconds
   
    self.Spawnlist = self.Spawnlist or PDM_PROPS
    self.PropExpMaxWPer = self.PropExpMaxWPer or 300   --explained in projpdm_propket
    self.PropExpMaxVol = self.PropExpMaxVol or 10000
    self.PropExpNum = self.PropExpNum or 12
    self.PropExpVel = self.PropExpVel or 3000
    self.PropExpAng = self.PropExpAng or 35
    self.PropDespTime = self.PropDespTime or 15
    self.PropExpAngle = 30  --angle of blast cone in degrees

    self.DmgRadius = self.DmgRadius or 300
    self.Dmg = self.Dmg or 200
    self:SetModel("models/kleiner.mdl")
   


    self:EmitSound("ambient/gas/cannister_loop.wav", 60, 120)
    timer.Simple(self.DeployTime, function()
        if not IsValid(self) then return end
        self:StopSound("ambient/gas/cannister_loop.wav")

        if SERVER then
            self.MinBound = self:LocalToWorld(Vector(7, 25, 0)) - self:GetPos()
            self.MaxBound = self:LocalToWorld(Vector(-7, -25, 72)) - self:GetPos()
            self:PhysicsInitBox(self.MinBound, self.MaxBound)
            self:SetTrigger(true)
        end
    end)
end

function ENT:Explode(normal)
    local own = self:GetOwner()
    self:SetOwner(own:IsValid() and own or game.GetWorld())
    local own = self:GetOwner()

    local pos = self:LocalToWorld(self:OBBCenter())
    local dmg = DamageInfo()
    dmg:SetDamage(self.Dmg)
    dmg:SetDamageType(DMG_BLAST)
    dmg:SetAttacker(own)
    util.BlastDamageInfo(dmg, self:GetPos(), self.DmgRadius)

    
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

    local proptabs = PDM_SelectRandomProps(self.PropExpNum, self.PropExpMaxWPer, self.PropExpMaxVol, self.Spawnlist)
    local props = {}
    for _, tab in pairs(proptabs) do
        local ar = AngleRand()
        local dir = normal and (normal:Angle() + ar*self.PropExpAngle/360):Forward() or VectorRand()

        local new = PDM_FireProp(tab, pos, ar, self.PropExpVel*dir, Vector(), own)
        new:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
        PDM_SetupDespawn(new, self.PropDespTime)
    end

    --fx
    self:StopSound("ambient/gas/cannister_loop.wav")
    self:EmitSound("BaseExplosionEffect.Sound", 200, 100, 1)

    local ef = EffectData()
    ef:SetOrigin(pos)
    ef:SetScale(0.75)
    ef:SetMagnitude(1)
    ef:SetFlags(0x4)    --no sound
    util.Effect("Explosion", ef)

    self:Remove()
end

function ENT:PhysicsCollide(coldata, collider)
    if coldata.HitEntity == game.GetWorld() then return end
    self:Explode(-coldata.TheirOldVelocity:GetNormalized())
end

function ENT:StartTouch(ent)
    if not ent:IsPlayer() or ent == self:GetOwner() then return end
    self:Explode((ent:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized())
end

function ENT:OnTakeDamage(info)
    if info:GetAttacker() == self:GetOwner() then return end
    local att = info:GetAttacker()
    local norm = (att and att:IsValid()) and (att:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() or nil
    
    self:Explode(norm)
end

function ENT:Draw()
    if CurTime() < self.InitTime + self.DeployTime then
        self:SetModelScale(0.3 + 0.7*(CurTime() - self.InitTime)/self.DeployTime)
    end

    self:DrawModel()
end