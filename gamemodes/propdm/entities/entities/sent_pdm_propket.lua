AddCSLuaFile()
ENT.Type = "anim"

game.AddParticles("particles/rocket_fx.pcf")
PrecacheParticleSystem("Rocket_Smoke")
PrecacheParticleSystem("Rocket_Smoke_Trail")

if SERVER then
    
function ENT:Initialize()
    self:SetModel("models/weapons/w_missile_closed.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:DrawShadow(true)

    self.RocketVel = self.RocketVel or 2000
    self.Mass = 10
    self.Gravity = 0.2
    self.Phys = self:GetPhysicsObject()
    self.Phys:SetVelocity(self:GetForward()*self.RocketVel)
    self.Phys:SetMass(self.Mass)
    
    self.ExpDmg = self.ExpDmg or 120
    self.ExpRad = self.ExpRad or 400
    self.GravRadius = self.GravRadius or 400
    self.GravPower = self.GravPower or 20*10^6
    self.PlyWeight = self.PlyWeight or 1200
    
    self.Owner = self:GetOwner()
    self.Filter = {self.Owner, self}

    self.ExpSound = CreateSound(self, "BaseExplosionEffect.Sound")
    self.RocketSound = CreateSound(self, "weapons/rpg/rocket1.wav")
    self.RocketSound:Play()
end

function ENT:Think()
    --reduce gravity
    self.Phys:ApplyForceCenter(Vector(0,0,1)*self.Mass*600*(1-self.Gravity)*engine.TickInterval())
    
    --fix angle sorta
    local tq = self:GetAngles():Forward():Cross(self:GetVelocity())
    self.Phys:ApplyTorqueCenter(tq/100)

    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsCollide()
    local ef = EffectData()
    ef:SetOrigin(self:GetPos())
    ef:SetScale(1)
    ef:SetMagnitude(1)
    util.Effect("Explosion", ef)

    self.ExpSound:Play()
    self.RocketSound:Stop()
    self:Remove()
end

end


if CLIENT then

    function ENT:Initialize()
        local smoke = CreateParticleSystem(self, "Rocket_Smoke", 1, 0, -self:GetForward()*25)
        local smoketrail = CreateParticleSystem(self, "Rocket_Smoke_Trail", 1, 0, -self:GetForward()*25)
        smoke:StartEmission()
        smoketrail:StartEmission()
    end

end