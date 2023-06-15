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
end

function ENT:Think()
    if self.ExpTime < CurTime() then
        local range = 500
        local dmg = 25
        local pos = self:GetPos()

        local exp = ents.Create("env_explosion")
        exp:SetKeyValue("magnitude", 100)
        exp:SetPos(pos)
        exp:Spawn()
        exp:Fire("explode","",0)

        self:Remove()
    end
end

end