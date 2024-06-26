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

SWEP.FireDelay = 0.75
SWEP.NadeVel = 2000
SWEP.Fuse = 2

SWEP.Primary.ClipSize = 1
SWEP.DrawAmmo = true
SWEP.Primary.Ammo = "pdm_propnade"
SWEP.Primary.DefaultClip = 3
SWEP.Automatic = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
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

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    own:SetAnimation(PLAYER_ATTACK1)

    self:SetNextPrimaryFire(CurTime() + self.FireDelay)
end

function SWEP:SecondaryAttack()
end
