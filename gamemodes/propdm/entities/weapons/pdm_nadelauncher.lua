SWEP.PrintName = "Nade Launcher"
SWEP.Category = "Prop Deathmatch"
SWEP.Spawnable = true
SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.ViewModel = "models/weapons/v_shotgun.mdl"
SWEP.UseHands = false

SWEP.Slot = 3
SWEP.Weight = 5
SWEP.SlotPos = 1

SWEP.FireDelay = 0.6
SWEP.NadeVel = 1500
SWEP.Fuse = 2

SWEP.Reloading = false
SWEP.CancelReload = false
SWEP.LastLoad = 0

SWEP.Primary.ClipSize = 3
SWEP.DrawAmmo = true
SWEP.Primary.Ammo = "pdm_propnade"
SWEP.Primary.DefaultClip = 6
SWEP.Automatic = false

SWEP.Secondary.ClipSize = 24
SWEP.Secondary.DefaultClip = 6
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType("shotgun")
    self.ShootSound = CreateSound(self, "NPC_Combine.GrenadeLaunch")
end

if CLIENT then
    
local col = Color(255,240,50)
function SWEP:DrawWeaponSelection(x, y, width, height)
    draw.SimpleText("b", "hl2b", x + width/2, y + height/2, col, 1, 1)
    draw.SimpleText("b", "hl2f", x + width/2, y + height/2, col, 1, 1)
end

end


function SWEP:PrimaryAttack()
    if self:GetOwner():KeyDown(IN_RELOAD) then return end

    if self.Reloading then
        self.CancelReload = true

        return
    end

    if self:Clip1() < 1 then
        self:EmitSound("weapons/shotgun/shotgun_empty.wav", 100)
        return
    end

    local own = self:GetOwner()
    if SERVER then 
        local aim = own:EyeAngles()
        local epos = own:EyePos()

        local pos, ang = LocalToWorld(Vector(25, -6, -1), Angle(), epos, aim)

        local nade = ents.Create("proj_pdm_nade")
        nade:SetOwner(own)
        nade:SetPos(pos)
        nade:SetAngles(aim + Angle(90,0,0))
        nade:Spawn()
        nade:GetPhysicsObject():SetVelocity(aim:Forward()*self.NadeVel)
        nade.Fuse = 1

        self:TakePrimaryAmmo(1)
    end

    self.ShootSound:Stop()
    self.ShootSound:Play()
    self.ShootSound:ChangePitch(80)


    --anims
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    own:SetAnimation(PLAYER_ATTACK1)
    
    timer.Simple(0.3, function()
        if not self:IsValid() then return end

        self:SendWeaponAnim(ACT_SHOTGUN_PUMP)
        self:EmitSound("weapons/shotgun/shotgun_cock.wav", 70)
    end)

    self:SetNextPrimaryFire(CurTime() + self.FireDelay)
end

function SWEP:SecondaryAttack()
end

function SWEP:Think()
    if not self.Reloading or CurTime() < self.LastLoad + 1 then return end

    if self.CancelReload then
        self:FinishLoading()
        return
    end

    numleft = math.min(self.Primary.ClipSize - self:Clip1(), self:Ammo1())
    if numleft < 1 then 
        self:FinishLoading()
        return 
    end

    self:LoadRound()
    self.LastLoad = CurTime()

    --remove delay for returning to deployed
    if numleft < 2 then
        self.LastLoad = CurTime() - 0.5
        return
    end
end

--reloading logic
function SWEP:LoadRound()
    self:SendWeaponAnim(ACT_VM_RELOAD)
    
    self:EmitSound("weapons/shotgun/shotgun_reload3.wav", 100)

    if SERVER then
        self:GetOwner():RemoveAmmo(1, "pdm_propnade")
        self:SetClip1(self:Clip1() + 1)
    end
end

function SWEP:FinishLoading()
    self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)

    self.Reloading = false
    self.CancelReload = false
end

function SWEP:Reload()
    if self.Reloading then return end
    self.Reloading = true
end