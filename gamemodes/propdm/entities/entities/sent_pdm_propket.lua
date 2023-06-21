AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Propket"

if CLIENT then
    
function ENT:Draw()
    self:DrawModel()
end

end


if SERVER then
    
function ENT:Initialize()
    self:SetModel("models/weapons/w_grenade.mdl")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:DrawShadow(true)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)

    local phys = self:GetPhysicsObject()
    phys:Wake()
    phys:SetMass(10)

    self.GravRadius = self.GravRadius or 400
    self.GravPower = self.GravPower or 20*10^6
    self.PlyWeight = self.PlyWeight or 1200
    
    self.RocketSound = CreateSound(self, "weapons/rpg/rocket1.wav")
    self.RocketSound:Play()
end

function ENT:PhysicsCollide(data, phys)
    self:Remove()
end




end