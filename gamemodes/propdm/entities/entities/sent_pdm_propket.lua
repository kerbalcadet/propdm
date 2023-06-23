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

    self.RocketVel = self.RocketVel or 1400
    self.Mass = 10
    self.Gravity = 0.2
    self.Phys = self:GetPhysicsObject()
    self.Phys:SetVelocity(self:GetForward()*self.RocketVel)
    self.Phys:SetMass(self.Mass)
    
    self.PropExpMaxW = 2000  --total weight of exp
    self.PropExpMaxWPer = 200   --weight per prop
    self.PropExpMaxN = 20   --max number in exp
    self.PropExpMinVol = 5000
    self.PropExpMaxVol = 35000 --volume per prop
    self.PropExpVel = 4000

    self.ExpDmg = self.ExpDmg or 200
    self.ExpRad = self.ExpRad or 100
    self.GravRadius = self.GravRadius or 400
    self.GravPower = self.GravPower or 30*10^6
    self.PlyWeight = self.PlyWeight or 2000

    self.PropDespTime = 15
    
    self.Owner = self:GetOwner()
    self.Filter = {self.Owner, self}

    self.ExpSound = CreateSound(self, "BaseExplosionEffect.Sound")
    self.RocketSound = CreateSound(self, "weapons/rpg/rocket1.wav")
    self.RocketSound:Play()
end

local tr = {}
function ENT:Think()
    --reduce gravity
    self.Phys:ApplyForceCenter(Vector(0,0,1)*self.Mass*600*(1-self.Gravity)*engine.TickInterval())
    
    --fix angle sorta
    local tq = self:GetAngles():Forward():Cross(self:GetVelocity())
    self.Phys:ApplyTorqueCenter(tq/100)

    tr = util.QuickTrace(self:GetPos(), self:GetForward()*100, self.Filter)
    if tr.Hit then
        self:Explode()
    else
        self:NextThink(CurTime())
        return true
    end
end

function ENT:Explode()
    if self.Exploded then return end
    
    local ef = EffectData()
    ef:SetOrigin(self:GetPos())
    ef:SetScale(1)
    ef:SetMagnitude(1)
    util.Effect("Explosion", ef)

    --normal explosions
    local own = self:GetOwner()
    local pos = self:GetPos()
    util.BlastDamage(self, own, pos, self.ExpRad, self.ExpDmg)
    PDM_GravExplode(pos, self.GravRadius, self.GravPower, 5, self.PlyWeight, own)


    --prop explosion
    local props = {}
    local w = 0
    local n = 0
    while w < self.PropExpMaxW and n < self.PropExpMaxN do
        
        local tab = {}
        for i = 1, 10 do
            tab = table.Random(PDM_PROPS)
            local mass, vol = PDM_PropInfo(tab.model)
            if not mass or not vol then continue end

            if vol <= self.PropExpMaxVol and vol >= self.PropExpMinVol and mass < self.PropExpMaxWPer then 
                w = w + mass
                n = n + 1
                table.insert(props, tab)
                break 
            end
        end
    end

    local props = PDM_PropExplode(props, self:GetPos(), self.PropExpVel, -self:GetForward(), self:GetOwner())
    
    timer.Simple(self.PropDespTime, function()
        for _, p in pairs(props) do
            if IsValid(p) then p:Dissolve(false, 1, p:GetPos()) end
        end
    end)


    self.ExpSound:Play()
    self.RocketSound:Stop()
    self.Exploded = true
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