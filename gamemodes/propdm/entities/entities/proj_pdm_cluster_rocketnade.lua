AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Cluster Rocketnade"

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

    self.RocketBurn = 4   --for nadelets
    self.SeparateFuse = self.SeparateFuse or 0.2
    self.SpawnTime = CurTime()

    --these stats apply to cluster grenades
    self.Nades = 5  --number of grenades
    self.Vel = 400
    self.SideVel = 100

    self.GravRadius = 200
    self.GravPwr = 20*10^6 --has to be super large because force is applied for one frame only
    self.MinRad = 15 --range at which grav effects are unclamped (fall off) in ft
    self.PlyWeight = 800
    
    self.DmgRadius = 600    --gmod units not ft (probably should fix)
    self.Dmg = 90

    self.PropExpNum = 8
    --rest of prop exp stats are fine as default

    self.Owner = self:GetOwner()
    self.Weapon = self:GetOwner():GetActiveWeapon()

    self.Forward = self.Forward or nil
end

function ENT:Think()
    if not self.Forward then self.Forward = self:GetVelocity():GetNormalized() end

    if self.SpawnTime + self.SeparateFuse < CurTime() then
        
        local pos = self:GetPos()
        local own = self.Owner
        local ang = self:GetAngles()

        for i=1, self.Nades do            
            local vel = self:GetVelocity()
            local sideaim = VectorRand():Cross(vel):GetNormalized()
            
            local n = ents.Create("proj_pdm_rocketnade")
            n:SetPos(pos + sideaim*0)
            n:SetAngles(ang)
            n:SetOwner(self.Owner)

            n.RocketBurn = self.RocketBurn + math.Rand(0, 0.2)
            n.GravRadius = self.GravRadius
            n.GravPwr = self.GravPwr
            n.MinRad = self.MinRad
            n.DmgRadius = self.DmgRadius
            n.Dmg = self.Dmg
            n.PlyWeight = self.PlyWeight
            n.PropExpNum = self.PropExpNum

            n.Owner = own
            n.Weapon = self.Weapon

            n:Spawn()
            n:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)

            local phys = n:GetPhysicsObject()

            phys:SetVelocity(self.Forward*self.Vel + sideaim*self.SideVel)
            phys:SetAngleVelocity(VectorRand()*20)
        end

        self:EmitSound("NPC_Combine.GrenadeLaunch", 300)

        self:Remove()
    end
end

end