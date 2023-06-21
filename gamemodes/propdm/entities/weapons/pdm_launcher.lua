SWEP.PrintName = "Propket Launcher"
SWEP.Category = "Prop Deathmatch"
SWEP.Spawnable = true
SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.ViewModel = "models/weapons/c_rpg.mdl"
SWEP.UseHands = true

SWEP.Slot = 5
SWEP.Weight = 5
SWEP.SlotPos = 1

SWEP.RocketVel = 1500
SWEP.GravRadius = 400
SWEP.GravPower = 20*10^6
SWEP.PlyWeight = 1200

SWEP.Spool = 0
SWEP.SpoolTime = 1.5
SWEP.Spooling = false
SWEP.SpoolStart = 0

SWEP.FireDelay = 2
SWEP.LastFired = 0

SWEP.Loaded = false
SWEP.CoolDown = false

SWEP.Primary.ClipSize = 1
SWEP.Primary.Ammo = "rpg_round"
SWEP.DefaultClip = 1
SWEP.Automatic = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"


function SWEP:Initialize()
    self:SetHoldType("rpg")
    self.SpoolSound = CreateSound(self, "vehicles/apc/apc_firstgear_loop1.wav")
    self.LoadSound = CreateSound(self, "garrysmod/balloon_pop_cute.wav")
    self.ShootSound = CreateSound(self, "NPC_Combine.GrenadeLaunch")

end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:OnRemove()
    self.SpoolSound:Stop()
end

function SWEP:Launch()
    local own = self:GetOwner()

    local aim = own:GetAimVector()
    local gpos = own:GetPos()
    local right = aim:Cross(Vector(0,0,1))
    local pos = gpos

    local rkt = ents.Create("sent_pdm_propket")
    rkt:SetOwner(own)
    rkt:SetPos(pos)
    rkt:SetAngles(own:EyeAngles())
    rkt:Spawn()

    local phys = rkt:GetPhysicsObject()
    phys:SetVelocity(own:GetVelocity() + aim*self.RocketVel)
    phys:SetAngleVelocity(Angle(0, 0, 100))
end

function SWEP:Think()
    local own = self:GetOwner()
    local lclick = own:KeyDown(IN_ATTACK)
    local t = CurTime() - self.LastFired

    if lclick and not self.CoolDown and t > self.FireDelay then
        if not self.Spooling then
            self.Spooling = true
            self.SpoolStart = CurTime()
    
            self.SpoolSound:Stop()
            self.SpoolSound:Play()
            self.SpoolSound:ChangePitch(255)
        end

        local t = CurTime() - self.SpoolStart
        self.Spool = math.Clamp(t/self.SpoolTime, 0, 1)

    else
        if SERVER and self.Loaded then
            self:Launch()

            self.ShootSound:Stop()
            self.ShootSound:Play()

            self.Loaded = false
            self.LastFired = CurTime()
        end
        
        if self.Spooling then
            self.CoolDown = true
            self.Spooling = false
            self.SpoolStart = CurTime()
        end

        local t = CurTime() - self.SpoolStart
        self.Spool = math.Clamp(1 - t, 0, 1)
    end

    local spool = self.Spool
    
    if spool == 0 then self.CoolDown = false
    elseif spool == 1 and not self.Loaded and not self.CoolDown then
        self.Loaded = true
        self.LoadSound:Stop()
        self.LoadSound:Play()
        self.LoadSound:ChangePitch(40)
    end

    self.SpoolSound:ChangeVolume(spool)
    if not self.Spooling then self.SpoolSound:ChangePitch(255 - (1-spool)*100) end

end