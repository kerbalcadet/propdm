AddCSLuaFile()
SWEP.PrintName = "Glue Stick"
SWEP.Category = "Prop Deathmatch"
SWEP.Slot = 2
SWEP.SlotPos = 0

SWEP.Spawnable = true

SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModel = "models/weapons/v_stunstick.mdl"
SWEP.UseHands = false
SWEP.Secondary.Automatic = true
SWEP.ViewModelFOV = 70



if CLIENT then
    local col = Color(255,240,50)

    function SWEP:DrawWeaponSelection(x, y, width, height)
        draw.SimpleText("/", "hl2b", x + width/2, y + height/2, col, 1, 1)
        draw.SimpleText("/", "hl2f", x + width/2, y + height/2, col, 1, 1)
    end    

    local poff = Vector(3, -3, 27)
    local aoff = Angle(50, 20, 0)
    function SWEP:CalcViewModelView(vm, op, oa, p, a)
        return LocalToWorld(poff, aoff, p, a)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Entity", 0, "GlueEnt")
    self:NetworkVar("Bool", 0, "Glued")
    self:NetworkVar("Bool", 1, "Gluing")
    self:NetworkVar("Vector", 0, "EntPos")
    self:NetworkVar("Angle", 0, "EntAng")
end

function SWEP:Initialize()
    self:SetHoldType("pistol")

    self.GlueRange = 75
    self.GlueTimeMul = 1/200  --multiplied by weight to get time it takes to stick a prop
    self.GlueMinTime = 0.5
    self.GlueMaxTime = 5

    --internal
    self.GlueEnt = nil
    self:SetGlued(false)
    self:SetGluing(false)
    self.GlueAmt = 0  

    self.EntDistSq = nil

    self.GluingSound = CreateSound(self, "ambient/machines/gas_loop_1.wav")
end

function SWEP:PrimaryAttack()
end

--drop/reset glued obj
--send 'true' as argument if it's being called on both sv and cl anyway
function SWEP:Drop(nomsg)
    local ent = self:GetGlueEnt()
    if not IsValid(ent) then
        if SERVER then
            self:SetGlued(false)
        end

        return
    end

    if SERVER then
        self:SetGlued(false)
        self.GlueAmt = 0

        if not nomsg then
            net.Start("PDM_GlueDrop")
                net.WriteEntity(self)
            net.Send(self:GetOwner())
        end

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableGravity(true)
        end

        ent:SetOwner(nil)
    end

    if CLIENT then 
        self:GetGlueEnt():PhysicsDestroy() 
    end

    self:EmitSound("weapons/bugbait/bugbait_squeeze"..math.random(1,3)..".wav")     
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
    
    --setowner disables collisions with wielder
    ent:SetOwner(own)
    --for unknown reasons, recheckcollisionfilter() doesn't seem to be fixing propflying for a second. but setpos sure does.
    ent:SetPos(ent:GetPos() + vector_up*0.1)

    if SERVER then 
        local EntPos, EntAng = WorldToLocal(ent:GetPos(), ent:GetAngles(), own:GetShootPos(), own:EyeAngles())
        self:SetEntPos(EntPos)
        self:SetEntAng(EntAng)
        self:SetGlued(true)
        
        self.EntDistSq = EntPos:LengthSqr()
        ent:SetPhysicsAttacker(own)
        ent.Attacker = own
    end

    self:SetGluing(false)
    self:EmitSound("weapons/bugbait/bugbait_squeeze"..math.random(1,3)..".wav")  
    self.GluingSound:Stop()   
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
    if self:GetGlued() then self:Drop(true) end
    return true
end

function SWEP:Reload()
    if self:GetGlued() then self:Drop(true) end
end

--hold rclick to glue objects
function SWEP:SecondaryAttack()
    if self:GetGlued() then return end

    self:SetNextSecondaryFire(CurTime())

    local own = self:GetOwner()
    local tr = util.QuickTrace(own:GetShootPos(), own:GetAimVector()*self.GlueRange, own)
    local tick = engine.TickInterval()
    
    --make sure ent is a valid target
    local ent = tr.Entity
    self.trent = ent
    local isprop = IsValid(ent) and string.StartsWith(ent:GetClass(), "prop_physics")

    if not isprop then
        self:SetGlueEnt(nil)
        self.GlueAmt = 0
        return
    end

    if not self:GetGluing() and not self:GetGlued() then
        self:SetGluing(true)
        self.GluingSound:Stop()
        self.GluingSound:Play()
        self.GluingSound:ChangePitch(80)
    end

    --gluing logic ahead, serverside only
    if CLIENT then return end

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
    local own = self:GetOwner()
    
    --stop gluing sound after we stop holding rclick
    if self:GetGluing() and (not own:KeyDown(IN_ATTACK2) or not IsValid(self.trent)) then
        self:SetGluing(false)
        self.GluingSound:Stop()        
    end
    

    --[[--------------------------------------
        glued obj. movement code
        uncomment below to disable client prediction
    ]]----------------------------------------
    --if CLIENT then return end 

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
        return
    end 


    --push ent to where it's supposed to be
    phys:Wake()

    local tick = FrameTime()
    local spos = own:GetShootPos()
    local ea = own:EyeAngles()

    local targpos, targang = LocalToWorld(self:GetEntPos(), self:GetEntAng(), spos, ea)

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