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
        phys:SetMass(2)
    end

    self.RocketDelay = self.RocketDelay or 0.25    --seconds
    self.RocketBurn = self.RocketBurn or 5
    self.RocketPower = 2000
    
    
    self.DmgRadius = self.DmgRadius or 200
    self.Dmg = self.Dmg or 120
    self.GravRadius = self.GravRadius or 400
    self.GravPwr = self.GravPwr or 40*10^6 --has to be super large because force is applied for one frame only
    self.MinRad = self.MinRad or 15 --range at which grav effects are unclamped (fall off) in ft
    self.PlyWeight = self.PlyWeight or 800

    self.PropExpMaxWPer = self.PropExpMaxWPer or 100   --explained in projpdm_propket
    self.PropExpMaxVol = self.PropExpMaxVol or 20000
    self.PropExpNum = self.PropExpNum or 20
    self.PropExpVel = self.PropExpVel or 3000
    self.PropExpAng = self.PropExpAng or 35
    self.PropDespTime = self.PropDespTime or 15
    
    self.Owner = self.Owner or self:GetOwner()
    self.Weapon = self.Weapon or self:GetOwner():GetActiveWeapon()
    self.ExpOffset = self.ExpOffset or Vector(0,0,-100)

    self.ExpSound = CreateSound(self, "BaseExplosionEffect.Sound")
    
    self.SpawnTime = CurTime()
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
        if not self.StuckEntity then
            local phys = self:GetPhysicsObject()
            if not phys then print("nophys") return end

            phys:ApplyForceCenter(self:GetAngles():Up()*self.RocketPower)
        end
    end
end
