SWEP.PrintName = "Glue Stick"
SWEP.Category = "Prop Deathmatch"
SWEP.Slot = 0
SWEP.SlotPos = 2

SWEP.Spawnable = true

SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModel = "models/weapons/v_stunstick.mdl"
SWEP.UseHands = true
SWEP.Secondary.Automatic = true



if CLIENT then
    local col = Color(255,240,50)

    function SWEP:DrawWeaponSelection(x, y, width, height)
        draw.SimpleText("/", "hl2b", x + width/2, y + height/2, col, 1, 1)
        draw.SimpleText("/", "hl2f", x + width/2, y + height/2, col, 1, 1)
    end    
end


function SWEP:Initialize()
    self:SetHoldType("pistol")

    self.GlueRange = 100
    self.GlueTimeMul = 1/200  --multiplied by weight to get time it takes to stick a prop
    self.GlueMinTime = 0.5
    self.GlueMaxTime = 5

    --internal
    self.GlueEnt = nil
    self.GlueAmt = 0  
    self.Gluing = false  
    self.Glued = false

    self.EntPos = nil
    self.EntAng = nil
end

function SWEP:PrimaryAttack()
end

--drop/reset glued obj
function SWEP:Reload()
    if self.Glued then
        self.Glued = false
        self.GlueAmt = 0

        if IsValid(self.GlueEnt) then
            local phys = self.GlueEnt:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
            end
        end
        self.GlueEnt = nil
    end
end

--hold rclick to glue objects
function SWEP:SecondaryAttack()
    if self.Glued then return end

    self:SetNextSecondaryFire(CurTime())

    local own = self:GetOwner()
    local tr = util.QuickTrace(own:GetShootPos(), own:GetAimVector()*self.GlueRange, own)
    local tick = engine.TickInterval()
    
    --make sure ent is a valid target
    local ent = tr.Entity
    local isprop = IsValid(ent) and string.StartsWith(ent:GetClass(), "prop_physics")

    if not isprop then
        self.GlueEnt = nil
        self.GlueAmt = 0
        return
    end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return end

    --add to progress for current target
    if ent == self.GlueEnt then
        self.GlueAmt = self.GlueAmt + tick

        local gtime = ent.GlueTime
        if not gtime then
            gtime = math.Clamp(phys:GetMass()*self.GlueTimeMul, self.GlueMinTime, self.GlueMaxTime)
            ent.GlueTime = gtime
        end

        if self.GlueAmt >= gtime then
            self.Glued = true
            self.Gluing = false

            self.EntPos, self.EntAng = WorldToLocal(ent:GetPos(), ent:GetAngles(), own:GetShootPos(), own:EyeAngles())
        end
        
    --switch target
    else   
        self.GlueEnt = ent
        self.GlueAmt = tick
    end


end

function SWEP:Think()
    local own = self:GetOwner()
    if not self.Glued or not own:Alive() then return end

    local ent = self.GlueEnt
    if not IsValid(ent) then
        self:Reload()   --drop/reset
        return 
    end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then
        self:Reload()
        return
    end


    --push ent to where it's supposed to be
    local spos = own:GetShootPos()
    local ea = own:EyeAngles()

    local targpos, targang = LocalToWorld(self.EntPos, self.EntAng, spos, ea)

    local m = phys:GetMass()
    local k = 100*m
    local d = 0*m

    local force = k*(targpos - ent:GetPos()) + d*(ent:GetVelocity())
    --phys:ApplyForceCenter(force)

    local inertia = phys:GetInertia()
    local adiff = ent:WorldToLocalAngles(targang)
    local avel = phys:GetAngleVelocity()
    local k = 0
    local d = 1
    local torque = inertia*(k*Vector(-adiff.r, -adiff.p, adiff.y) - d*avel)
    phys:ApplyTorqueCenter(torque)

    self:NextThink(CurTime())
end