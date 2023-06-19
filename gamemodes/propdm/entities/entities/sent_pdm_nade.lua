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

    self.Fuse = self.Fuse or 3
    self.SpawnTime = CurTime()
    self.GravRadius = 400
    self.GravPwr = 60*10^6 --has to be super large because force is applied for one frame only
    self.MinRad = 15 --range at which grav effects are unclamped (fall off) in ft
    self.DmgRadius = 400
    self.Dmg = 120
    self.Owner = self:GetOwner()
    self.Weapon = self:GetOwner():GetActiveWeapon()
    self.ExpOffset = Vector(0,0,-100)
    self.PlyWeight = 800

    self.ExpSound = CreateSound(self, "BaseExplosionEffect.Sound")
end

function ENT:Think()
    if self.SpawnTime + self.Fuse < CurTime() then
        
        local pos = self:GetPos()
        PDM_GravExplode(pos, self.GravRadius, self.GravPwr, self.MinRad, self.PlyWeight, self.Owner)
        
        local wep = IsValid(self.Weapon) and self.Weapon or self
        local dmg = DamageInfo()
        dmg:SetDamage(self.Dmg)
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetInflictor(wep)
        dmg:SetAttacker(self.Owner)
        util.BlastDamageInfo(dmg, pos, self.DmgRadius)
        
        local num = math.random(4)
        self:EmitSound("weapons/physcannon/superphys_launch"..num..".wav", 350)
        self.ExpSound:Play()
        self.ExpSound:ChangeVolume(0.7)

        local ef = EffectData()
        ef:SetOrigin(pos)

        ef:SetScale(150)
        util.Effect("ThumperDust", ef)

        ef:SetScale(0.75)
        ef:SetMagnitude(1)
        ef:SetFlags(0x4)    --no sound
        util.Effect("Explosion", ef)

        self:Remove()
    end
end

end