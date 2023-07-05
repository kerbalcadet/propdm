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

    self.GlueRange = 50
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
    self.EntDistSq = nil
end

function SWEP:PrimaryAttack()
end

--drop/reset glued obj
function SWEP:Drop()
    if self.Glued then
        self.Glued = false
        self.GlueAmt = 0

        local ent = self.GlueEnt
        self.GlueEnt = nil

        if IsValid(ent) then
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
            end

            ent:SetOwner(nil)
            if CLIENT then ent:PhysicsDestroy() end
        end

    end
end

function SWEP:Reload()
    self:Drop()
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

    --clients don't automatically make phys
    if CLIENT then ent:PhysicsInit(SOLID_VPHYSICS) end

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

            ent:SetOwner(own)
            self.EntPos, self.EntAng = WorldToLocal(ent:GetPos(), ent:GetAngles(), own:GetShootPos(), own:EyeAngles())
            self.EntDistSq = self.EntPos:LengthSqr()
        end
        
    --switch target
    else   
        self.GlueEnt = ent
        self.GlueAmt = tick
    end


end

--move glued entity to where it should be 
function SWEP:Think()
    --[[--------------------------------------
        uncomment to disable client prediction
    ]]----------------------------------------
    --if CLIENT then return end  
    

    local own = SERVER and self:GetOwner() or LocalPlayer()
    if not self.Glued or not own:Alive() then return end

    local ent = self.GlueEnt
    if not IsValid(ent) then
        self:Drop()   --drop/reset
        return 
    end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then
        self:Drop()
        return
    end

    if SERVER and (ent:GetPos() - own:GetShootPos()):LengthSqr() > (self.EntDistSq + 100^2) then
        self:Drop()
        self:CallOnClient("Drop")
        return
    end 


    --push ent to where it's supposed to be
    phys:Wake()

    local tick = FrameTime()
    local spos = own:GetShootPos()
    local ea = own:EyeAngles()

    local targpos, targang = LocalToWorld(self.EntPos, self.EntAng, spos, ea)

    local m = phys:GetMass()
    local k = m*(SERVER and 5000 or 3000)
    local d = m*(SERVER and 50 or 100)

    local force = tick*(k*(targpos - ent:GetPos()) - d*(ent:GetVelocity()))
    phys:ApplyForceCenter(force)

    local inertia = phys:GetInertia()
    local adiff = ent:WorldToLocalAngles(targang)
    local avel = phys:GetAngleVelocity()
    local k = SERVER and 1000 or 1000
    local d = SERVER and 50 or 50
    local torque = tick*inertia*(k*Vector(adiff.r, adiff.p, adiff.y) - d*avel)
    phys:ApplyTorqueCenter(ent:LocalToWorld(torque) - ent:GetPos())
end