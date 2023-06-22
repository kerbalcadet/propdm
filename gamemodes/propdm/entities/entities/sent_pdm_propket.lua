AddCSLuaFile()
ENT.Type = "anim"

if SERVER then
    
function ENT:Initialize()
    self:SetModel("models/weapons/w_missile_closed.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:DrawShadow(true)

    self.Speed = 2000
    self.Mass = 10
    self.Gravity = 0.2
    self.Phys = self:GetPhysicsObject()
    self.Phys:SetVelocity(self:GetForward()*self.Speed)
    self.Phys:SetMass(self.Mass)
    
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
   
end