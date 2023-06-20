AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Cluster Grenade"

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

    self.SeparateFuse = self.SeparateFuse or 0.5
    self.SpawnTime = CurTime()

    --spread by 60degrees
    self.AimVecs = {
    Vector(1, 0, 0),
    Vector(-0.86, 0.5, 0),
    Vector(-0.86, -0.5, 0)
    }

    --these stats apply to 3 cluster grenades
    self.Vel = 400
    self.UpVel = 100
    self.Fuse = self.Fuse or 1
    self.GravRadius = 300
    self.GravPwr = 30*10^6 --has to be super large because force is applied for one frame only
    self.MinRad = 15 --range at which grav effects are unclamped (fall off) in ft
    self.DmgRadius = 500
    self.Dmg = 120
    self.PlyWeight = 800


    self.Owner = self:GetOwner()
    self.Weapon = self:GetOwner():GetActiveWeapon()
end

function ENT:Think()
    if self.SpawnTime + self.SeparateFuse < CurTime() then
        
        local pos = self:GetPos()
        local own = self.Owner

        for i=1, 3 do
            local n = ents.Create("sent_pdm_nade")
            n:SetPos(pos)
            n:SetOwner(self.Owner)

            n.Fuse = self.Fuse
            n.GravRadius = self.GravRadius
            n.GravPwr = self.GravPwr
            n.MinRad = self.MinRad
            n.DmgRadius = self.DmgRadius
            n.Dmg = self.Dmg
            n.PlyWeight = self.PlyWeight

            n.Owner = own
            n.Weapon = self.Weapon

            n:Spawn()
            local phys = n:GetPhysicsObject()
            local aim = self:LocalToWorld(self.AimVecs[i]) - pos
            phys:SetVelocity(self:GetVelocity() + aim*self.Vel + Vector(0,0,1)*self.UpVel)
            phys:SetAngleVelocity(VectorRand()*300)
        end

        self:EmitSound("NPC_Combine.GrenadeLaunch", 300)

        self:Remove()
    end
end

end