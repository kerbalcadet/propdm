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
SWEP.NadeVel = 2000
SWEP.Fuse = 2

SWEP.Reloading = false
SWEP.CancelReload = false

SWEP.Primary.ClipSize = 6
SWEP.DrawAmmo = true
SWEP.Primary.Ammo = "pdm_propnade"
SWEP.Primary.DefaultClip = 12
SWEP.Automatic = false

SWEP.Secondary.ClipSize = 24
SWEP.Secondary.DefaultClip = 6
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType("shotgun")
    self.ShootSound = CreateSound(self, "NPC_Combine.GrenadeLaunch")
    self.RackSound = CreateSound(self, "weapons/shotgun/shotgun_cock.wav")
    self.EmptySound = CreateSound(self, "weapons/shotgun/shotgun_empty.wav")
    self.LoadSound = CreateSound(self, "weapons/shotgun/shotgun_reload3.wav")
end

if CLIENT then
    
local col = Color(255,240,50)
function SWEP:DrawWeaponSelection(x, y, width, height)
    draw.SimpleText("b", "hl2b", x + width/2, y + height/2, col, 1, 1)
    draw.SimpleText("b", "hl2f", x + width/2, y + height/2, col, 1, 1)
end

end


function SWEP:PrimaryAttack()
    if self.Reloading then
        self.CancelReload = true

        return
    end

    if self:Clip1() < 1 then
        self.EmptySound:Stop()
        self.EmptySound:Play()
        
        return
    end

    local own = self:GetOwner()
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

    self.ShootSound:Stop()
    self.ShootSound:Play()
    self.ShootSound:ChangePitch(80)

    self:TakePrimaryAmmo(1)

    --anims
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    own:SetAnimation(PLAYER_ATTACK1)
    
    timer.Simple(0.3, function()
        self:SendWeaponAnim(ACT_SHOTGUN_PUMP)
        self.RackSound:Stop()
        self.RackSound:Play()
    end)

    self:SetNextPrimaryFire(CurTime() + self.FireDelay)
end

function SWEP:SecondaryAttack()
end

--reloading logic
function SWEP:LoadRound()
    self:SendWeaponAnim(ACT_VM_RELOAD)
    self:GetOwner():SetAnimation(PLAYER_RELOAD)
    
    self.LoadSound:Stop()
    self.LoadSound:Play()

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

    local numrounds = math.min(self.Primary.ClipSize - self:Clip1(), self:Ammo1() - self:Clip1())
    if numrounds < 1 then return end

    self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)

    self:LoadRound()
    if numrounds < 2 then return end

    self.Reloading = true
    
    local title = self:GetName().."reload" 
    timer.Create(title, 0.7, numrounds - 1, function()
        if self.CancelReload then
            timer.Remove(title)

            self:FinishLoading()
            return
        end

        self:LoadRound()

        if timer.RepsLeft(title) < 1 then
            timer.Simple(0.4, function()
                self:FinishLoading()
                return
            end)
        end
    end)
end