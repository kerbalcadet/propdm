AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Gravity Grenade"

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

if SERVER then
    
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

    self.ExpTime = CurTime() + 3
    self.GravRadius = 300
    self.GravPwr = 40*10^6 --has to be super large because force is applied for one frame only
    self.MinRad = 15 --range at which grav effects are unclamped (fall off) in ft
    self.DmgRadius = 50
    self.Dmg = 50
    self.Owner = self:GetOwner()
    self.Weapon = self:GetOwner():GetActiveWeapon()
    self.ExpOffset = Vector(0,0,-100)
    self.PlyWeight = 800
end

function ENT:Think()
    if self.ExpTime < CurTime() then
        local pos = self:GetPos()
        PDM_GravExplode(pos, self.GravRadius, self.GravPwr, self.MinRad, self.PlyWeight, self.Owner)
        
        local exp = ents.Create("env_explosion")
        exp:SetKeyValue("magnitude", 100)
        exp:SetPos(pos)
        exp:Spawn()
        exp:Fire("explode","",0)

        self:Remove()
    end
end

end