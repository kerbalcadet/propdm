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

function SWEP:SetupDataTables()
    self:NetworkVar("Entity", 0, "GlueEnt")
    self:NetworkVar("Bool", 0, "Glued")
end

function SWEP:Initialize()
    self:SetHoldType("pistol")

    self.GlueRange = 50
    self.GlueTimeMul = 1/200  --multiplied by weight to get time it takes to stick a prop
    self.GlueMinTime = 0.5
    self.GlueMaxTime = 5

    --internal
    self:SetGlueEnt(nil)
    self:SetGlued(false)
    self.GlueAmt = 0  
    self.Gluing = false  

    self.EntPos = nil
    self.EntAng = nil
    self.EntDistSq = nil
end

function SWEP:PrimaryAttack()
end

--drop/reset glued obj
function SWEP:Drop()
    if self:GetGlued() then
        self:SetGlued(false)
        self.GlueAmt = 0

        local ent = self:GetGlueEnt()
        self:SetGlueEnt(nil)

        if IsValid(ent) then
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                phys:EnableGravity(true)
            end

            ent:SetOwner(nil)
            if CLIENT then ent:PhysicsDestroy() end
        end

    end
end

if SERVER then util.AddNetworkString("PDM_GlueDrop") end
net.Receive("PDM_GlueDrop", function()
    local wep = net.ReadEntity()
    wep:Drop()
end)

function SWEP:Pickup(ent)
    local own = self:GetOwner()

    --clients don't automatically make phys
    if CLIENT then ent:PhysicsInit(SOLID_VPHYSICS) end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then
        if CLIENT then ent:PhysicsDestroy() end
        return
    end

    phys:EnableGravity(false)
    
    ent:SetOwner(own)
    self.EntPos, self.EntAng = WorldToLocal(ent:GetPos(), ent:GetAngles(), own:GetShootPos(), own:EyeAngles())
    self.EntDistSq = self.EntPos:LengthSqr()

    self:SetGlued(true)
    self.Gluing = false
end

--server tells client when to pick up, so we don't have issues with initializing physics
--for every single prop we look at or desync between the two 
if SERVER then util.AddNetworkString("PDM_GluePickup") end
net.Receive("PDM_GluePickup", function()
    local wep = net.ReadEntity()
    local ent = net.ReadEntity()
    wep:Pickup(ent)
end)

function SWEP:Holster()
    self:Drop()
    return true
end

function SWEP:Reload()
    self:Drop()
end

--hold rclick to glue objects
function SWEP:SecondaryAttack()
    if self:GetGlued() then return end

    self:SetNextSecondaryFire(CurTime())

    --gluing logic ahead, serverside only
    if CLIENT then return end

    local own = self:GetOwner()
    local tr = util.QuickTrace(own:GetShootPos(), own:GetAimVector()*self.GlueRange, own)
    local tick = engine.TickInterval()
    
    --make sure ent is a valid target
    local ent = tr.Entity
    local isprop = IsValid(ent) and string.StartsWith(ent:GetClass(), "prop_physics")


    if not isprop then
        self:SetGlueEnt(nil)
        self.GlueAmt = 0
        return
    end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return end

    --add to progress for current target
    if ent == self:GetGlueEnt() then
        self.GlueAmt = self.GlueAmt + tick

        local gtime = ent.GlueTime
        if not gtime then
            gtime = math.Clamp(phys:GetMass()*self.GlueTimeMul, self.GlueMinTime, self.GlueMaxTime)
            ent.GlueTime = gtime
        end

        if self.GlueAmt >= gtime then
            self:Pickup(ent)
            
            --tell client to pick up
            net.Start("PDM_GluePickup")
                net.WriteEntity(self)
                net.WriteEntity(ent)
            net.Send(own)
        end
        
    --switch target
    else   
        self:SetGlueEnt(ent)
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
    if not self:GetGlued() or not own:Alive() then return end

    local ent = self:GetGlueEnt()
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
        
        net.Start("PDM_GlueDrop")
            net.WriteEntity(self)
        net.Send(own)
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