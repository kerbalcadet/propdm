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

SWEP.Spool = 0
SWEP.SpoolTime = 1.2
SWEP.Spooling = false
SWEP.SpoolStart = 0

SWEP.FireDelay = 2
SWEP.LastFired = 0

SWEP.Ready = false
SWEP.Loaded = false
SWEP.CoolDown = false

SWEP.Primary.ClipSize = 1
SWEP.Primary.Ammo = "rpg_round"
SWEP.Primary.DefaultClip = 3
SWEP.Automatic = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"


function SWEP:Initialize()
    self:SetHoldType("rpg")
    self.SpoolSound = CreateSound(self, "vehicles/apc/apc_firstgear_loop1.wav")
    self.LoadSound = CreateSound(self, "garrysmod/balloon_pop_cute.wav")
    self.ShootSound = CreateSound(self, "weapons/rpg/rocketfire1.wav")
    self.ReadySound = CreateSound(self, "buttons/button10.wav")
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:OnRemove()
    self.SpoolSound:Stop()
end

function SWEP:Load()
    self.Loaded = false
    self:Reload()
    
    timer.Simple(0.9, function()
        if not IsValid(self) then return end

        self.LoadSound:Stop()
        self.LoadSound:Play()
        self.LoadSound:ChangePitch(40)

        self.Loaded = true
    end)
end

function SWEP:Deploy()
    if not self.Loaded then self:Load() end
end

function SWEP:Launch()
    local own = self:GetOwner()

    local epos = own:EyePos()
    local eang = own:EyeAngles()
    local pos, ang = LocalToWorld(Vector(25, -6, -1), Angle(), epos, eang)

    local rkt = ents.Create("sent_pdm_propket")
    rkt:SetOwner(own)
    rkt:SetPos(pos)
    rkt:SetAngles(own:EyeAngles())
    rkt:Spawn()

    self.ShootSound:Stop()
    self.ShootSound:Play()

    self:TakePrimaryAmmo(1)

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    own:SetAnimation(PLAYER_ATTACK1)

    timer.Simple(0.5, function()
        if not IsValid(self) then return end
        self:Load()
    end)
end

function SWEP:Think()
    local own = self:GetOwner()
    local lclick = own:KeyDown(IN_ATTACK)
    local t = CurTime() - self.LastFired

    if lclick and not self.CoolDown and (t > self.FireDelay) then
        if not self.Spooling then
            self.Spooling = true
            self.SpoolStart = CurTime()
    
            self:EmitSound("buttons/button4.wav")
            self.SpoolSound:Stop()
            self.SpoolSound:Play()
            self.SpoolSound:ChangePitch(255)
        end

        local t = CurTime() - self.SpoolStart
        self.Spool = math.Clamp(t/self.SpoolTime, 0, 1)

    else
        if self.Ready then
            if SERVER then self:Launch() end

            self.Ready = false
            self.LastFired = CurTime()
        end
        
        if self.Spooling then
            self.CoolDown = true
            self.Spooling = false
            self.SpoolStart = CurTime()
        end

        local t = CurTime() - self.SpoolStart
        self.Spool = math.Clamp(1 - t*3/4, 0, 1)
    end

    local spool = self.Spool
    
    if spool == 0 then self.CoolDown = false
    elseif spool == 1 and not self.Ready and not self.CoolDown then
        if SERVER then
            self.ReadySound:Stop()
            self.ReadySound:Play()
            self.ReadySound:ChangePitch(150)
        end
        self.Ready = true
    end

    self.SpoolSound:ChangeVolume(spool)
    if not self.Spooling then self.SpoolSound:ChangePitch(255 - (1-spool)*200) end

end