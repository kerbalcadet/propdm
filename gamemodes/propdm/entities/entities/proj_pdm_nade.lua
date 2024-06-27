AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Prop Grenade"

function ENT:PhysicsCollide(data, phys)
    if data.Speed > 50 then
        self:EmitSound("physics/metal/metal_grenade_impact_hard"..math.random(1,3)..".wav")
    end

    local ent = data.HitEntity
    if data.Speed > 500 and (ent:IsPlayer() or ent:IsNPC()) then
        local dmg = DamageInfo()
        dmg:SetDamage(data.Speed/8)
        dmg:SetInflictor(self)
        dmg:SetAttacker(self:GetOwner())
        dmg:SetDamageType(DMG_CRUSH)
        ent:TakeDamageInfo(dmg)
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
        phys:SetMass(10)
    end

    self.Fuse = self.Fuse or 3
    self.SpawnTime = CurTime()

    self.GravRadius = self.GravRadius or 400
    self.GravPwr = self.GravPwr or 40*10^6 --has to be super large because force is applied for one frame only
    self.MinRad = self.MinRad or 15 --range at which grav effects are unclamped (fall off) in ft
    self.PlyWeight = self.PlyWeight or 800

    self.Spawnlist = self.Spawnlist or PDM_PROPS
    self.PropExpMaxWPer = self.PropExpMaxWPer or 100   --explained in projpdm_propket
    self.PropExpMaxVol = self.PropExpMaxVol or 20000
    self.PropExpNum = self.PropExpNum or 20
    self.PropExpVel = self.PropExpVel or 3000
    self.PropExpAng = self.PropExpAng or 35
    self.PropDespTime = self.PropDespTime or 15

    self.DmgRadius = self.DmgRadius or 200
    self.Dmg = self.Dmg or 120
    
    self.Owner = self.Owner or self:GetOwner()
    self.Weapon = self.Weapon or self:GetOwner():GetActiveWeapon()
    self.ExpOffset = self.ExpOffset or Vector(0,0,-100)

    self.ExpSound = CreateSound(self, "BaseExplosionEffect.Sound")
end

function ENT:Think()
    if self.SpawnTime + self.Fuse < CurTime() then
        self:PropExplode()
    end
end

function ENT:PropExplode()
    local pos = self:GetPos()
    
    --regular explosions 
    PDM_GravExplode(pos, self.GravRadius, self.GravPwr, self.MinRad, self.PlyWeight, self.Owner)
    
    local wep = IsValid(self.Weapon) and self.Weapon or self
    local dmg = DamageInfo()
    dmg:SetDamage(self.Dmg)
    dmg:SetDamageType(DMG_BLAST)
    dmg:SetInflictor(wep)
    dmg:SetAttacker(self.Owner)
    util.BlastDamageInfo(dmg, pos, self.DmgRadius)

    --prop explosions
    local props = {}
    local n = 0
    while n < self.PropExpNum do
        
        local tab = {}
        for i = 1, 10 do
            tab = table.Random(self.Spawnlist)
            local mass, vol = PDM_PropInfo(tab.model)
            if not mass or not vol then continue end

            if vol <= self.PropExpMaxVol and mass < self.PropExpMaxWPer then 
                n = n + 1
                tab.class = "prop_physics_multiplayer"
                table.insert(props, tab)
                break 
            end
        end
    end

    local tr = util.QuickTrace(pos, Vector(0,0,-15), self)
    local normal = tr.HitWorld and Vector(0,0,1) or Vector(0,0,0)
    local props = PDM_PropExplode(props, pos, self.PropExpVel, normal, self.PropExpAng, self:GetOwner())
    
    timer.Simple(self.PropDespTime, function()
        for _, p in pairs(props) do
            if IsValid(p) then p:Dissolve(1, p:GetPos()) end
        end
    end)

    --fx
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