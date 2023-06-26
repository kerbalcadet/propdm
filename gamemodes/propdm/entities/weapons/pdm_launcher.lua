SWEP.PrintName = "Propket Launcher"
SWEP.Category = "Prop Deathmatch"
SWEP.Spawnable = true
SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.ViewModel = "models/weapons/c_rpg.mdl"
SWEP.UseHands = true

SWEP.Slot = 3
SWEP.Weight = 5
SWEP.SlotPos = 1

SWEP.Spool = 0
SWEP.SpoolTime = 1.2
SWEP.Spooling = false
SWEP.SpoolStart = 0

SWEP.FireDelay = 2
SWEP.LastFired = 0

SWEP.Ready = false
SWEP.Loaded = true
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

if CLIENT then

local col = Color(255,240,50)
function SWEP:DrawWeaponSelection(x, y, width, height)
    draw.SimpleText("i", "hl2b", x + width/2, y + height/2, col, 1, 1)
    draw.SimpleText("i", "hl2f", x + width/2, y + height/2, col, 1, 1)
end

local dropmdl = SWEP.WorldModel
local function DropRPG()
    local own = LocalPlayer()
    local prop = ents.CreateClientProp(dropmdl)
    local ea = own:EyeAngles()
    local ep = own:GetShootPos()
    local offset = Vector(7, -7, -6)
    local pos, ang = LocalToWorld(offset, Angle(0,180,0), ep, ea)
    prop:SetPos(pos)
    prop:SetAngles(ang)
    prop:Spawn()

    own:EmitSound("weapons/slam/throw.wav")

    timer.Simple(5, function()
        if IsValid(prop) then prop:Remove() end
    end)
end
net.Receive("PDM_DropRPG", DropRPG)

end



function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end


if SERVER then

function SWEP:OnRemove()
    self.SpoolSound:Stop()
end

util.AddNetworkString("PDM_DropRPG")
function SWEP:TestLoad()
    self.Loaded = false
    local own = self:GetOwner()

    if own:GetAmmoCount(self.Primary.Ammo) > 0 then
        --for some reason default reload() function pauses "think"
        self:SendWeaponAnim(ACT_VM_RELOAD)
        own:SetAnimation(PLAYER_RELOAD)
    
        timer.Simple(0.9, function()
            if not IsValid(self) then return end
            self:SetClip1(1)
            own:RemoveAmmo(1, self.Primary.Ammo)

            self.LoadSound:Stop()
            self.LoadSound:Play()
            self.LoadSound:ChangePitch(40)

            self.Loaded = true
        end)
    else
        self:Remove()
        own:SwitchLastWeapon()
        
        net.Start("PDM_DropRPG")
        net.Send(own)
    end
end

function SWEP:Launch()
    local own = self:GetOwner()

    local epos = own:EyePos()
    local eang = own:EyeAngles()
    local pos, ang = LocalToWorld(Vector(25, -6, -1), Angle(), epos, eang)

    local rkt = ents.Create("proj_pdm_propket")
    rkt:SetOwner(own)
    rkt:SetPos(pos)
    rkt:SetAngles(own:EyeAngles())
    rkt:Spawn()

    self.ShootSound:Stop()
    self.ShootSound:Play()

    self:TakePrimaryAmmo(1)

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    own:SetAnimation(PLAYER_ATTACK1)
end


function SWEP:Think()
    local own = self:GetOwner()
    local lclick = own:KeyDown(IN_ATTACK)
    local t = CurTime() - self.LastFired

    if lclick and not self.CoolDown and (t > self.FireDelay) and self.Loaded then
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
            self:Launch()

            timer.Simple(0.5, function()
                if not IsValid(self) then return end
                self:TestLoad()
            end)

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
        self.ReadySound:Stop()
        self.ReadySound:Play()
        self.ReadySound:ChangePitch(150)
        
        self.Ready = true
    end

    self.SpoolSound:ChangeVolume(spool)
    if not self.Spooling then self.SpoolSound:ChangePitch(255 - (1-spool)*200) end

    self:NextThink(CurTime())
    return true
end

end