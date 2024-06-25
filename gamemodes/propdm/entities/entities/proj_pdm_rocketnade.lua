AddCSLuaFile()
ENT.Base = "proj_pdm_nade"
ENT.Type = "anim"
ENT.PrintName = "Rocket Nade"

function ENT:Initialize()
    self:SetModel("models/weapons/w_grenade.mdl")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:DrawShadow(true)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then 
        phys:Wake()
        phys:SetMass(1)
    end

    self.RocketDelay = self.RocketDelay or 0.2    --seconds
    self.RocketBurn = self.RocketBurn or 5
    self.RocketPower = 100
    self.PlayerPush = 50
    self.PropPush = 500

    self.Owner = self.Owner or self:GetOwner()
    self.Weapon = self.Weapon or self:GetOwner():GetActiveWeapon()
    self.ExpOffset = self.ExpOffset or Vector(0,0,-100)

    self.ExpSound = CreateSound(self, "BaseExplosionEffect.Sound")
    self.SpawnTime = CurTime()

    if SERVER then
        self.DmgRadius = self.DmgRadius or 600
        self.Dmg = self.Dmg or 120
        self.GravRadius = self.GravRadius or 600
        self.GravPwr = self.GravPwr or 60*10^6 --has to be super large because force is applied for one frame only
        self.MinRad = self.MinRad or 15 --range at which grav effects are unclamped (fall off) in ft
        self.PlyWeight = self.PlyWeight or 800

        self.PropExpMaxWPer = self.PropExpMaxWPer or 100   --explained in projpdm_propket
        self.PropExpMaxVol = self.PropExpMaxVol or 20000
        self.PropExpNum = self.PropExpNum or 30
        self.PropExpVel = self.PropExpVel or 5000
        self.PropExpAng = self.PropExpAng or 35
        self.PropDespTime = self.PropDespTime or 15
        
        self:SetPhysicsAttacker(self.Owner)
    end


end

function ENT:PhysicsCollide(data, phys)
    local ent = data.HitEntity
    if ent:IsPlayer() or ent:IsNPC() or string.StartsWith(ent:GetClass(), "prop") then
        self.StuckEntity = ent
        self:SetParent(ent)
        ent:SetPhysicsAttacker(self.Owner)
    end
end

function ENT:OnRemove()
    self:StopSound("weapons/rpg/rocket1.wav")
end

function ENT:Think()
    if CurTime() > self.SpawnTime + self.RocketDelay + self.RocketBurn then
        self:StopSound("weapons/rpg/rocket1.wav")

        if SERVER then self:PropExplode() end
        return
    end

    if CurTime() > self.SpawnTime + self.RocketDelay then
        if not self.RocketEngaged then
            self.RocketEngaged = true

            if CLIENT then 
                self.RocketFX = CreateParticleSystem(self, "Rocket_Smoke", 1, 0, Vector())
            end
            
            self:EmitSound("weapons/rpg/rocket1.wav", 100, 100, 0.3)
        end

        if CLIENT then return end

        --rocket push
        local nade_up = self:GetAngles():Up()
        local world_up = Vector(0,0,1)
        local tickrate = engine.TickInterval()
        local g = -physenv.GetGravity().z
        if not self.StuckEntity then
            local phys = self:GetPhysicsObject()
            if not phys then return end
            
            phys:ApplyForceCenter(nade_up*self.RocketPower + world_up*g*tickrate)
        
        elseif not self.StuckEntity:IsValid() then 
            return
        elseif self.StuckEntity:IsNPC() or self.StuckEntity:IsPlayer() then
            self.StuckEntity:SetGroundEntity(nil)
            self.StuckEntity:SetVelocity(nade_up*self.PlayerPush)
        else
            local phys = self.StuckEntity:GetPhysicsObject()
            if not IsValid(phys) then return end

            phys:ApplyForceOffset(self.PropPush*phys:GetMass()*nade_up, self:GetPos())
        end
    end

    self:NextThink(CurTime())
    return true 
end