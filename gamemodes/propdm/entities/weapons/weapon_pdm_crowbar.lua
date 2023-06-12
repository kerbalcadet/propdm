AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Normal Crowbar"
    SWEP.Purpose = "Quite repulsive"
    SWEP.Category = "Prop Deathmatch"
    SWEP.ViewModelFOV = 55
    SWEP.Weight = 5
    SWEP.Slot = 0
    SWEP.SlotPos = 1
end

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.UseHands = true

SWEP.Primary.Damage = 0
SWEP.Primary.Range = 100
SWEP.Primary.ExpRadius = 500

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true 
SWEP.Primary.Delay = 0.4
SWEP.Primary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType("melee")   --for some reason this doesn't work in the field
end

if CLIENT then

    surface.CreateFont( "hl2f", {
        font = "halflife2",
        size = 128
    } )

    surface.CreateFont( "hl2b", {
        font = "halflife2",
        size = 128,
        blursize = 12,
        scanlines = 4
    } )


    local col = Color(255,240,50)

    function SWEP:DrawWeaponSelection(x, y, width, height)
        draw.SimpleText("c", "hl2b", x + width/2, y + height/2, col, 1, 1)
        draw.SimpleText("c", "hl2f", x + width/2, y + height/2, col, 1, 1)
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not IsValid(self:GetOwner()) then return end


    

    local own = self:GetOwner()
    own:LagCompensation(true)
    local eye = own:GetShootPos()
    local pos = eye + own:GetAimVector()*self.Primary.Range 
    local hsize = 10*Vector(1,1,1)

    --stealing from ttt
    local tr = util.TraceHull({start = eye, endpos = pos, mask = MASK_SHOT_HULL, filter = own, mins = -hsize, maxs = hsize})
    if not tr.Entity:IsValid() then
        tr = util.TraceLine({start = eye, endpos = pos, filter = own, mask = MASK_SHOT})
    end
    local ent = tr.Entity

    if tr.Hit then
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        self:EmitSound("Weapon_Crowbar.Melee_Hit")

        if SERVER then
            local ef = EffectData()
            ef:SetOrigin(tr.HitPos)
            ef:SetNormal(tr.Normal)
            util.Effect("Impact", ef)
        end
    else
        self:EmitSound("Weapon_Crowbar.Single")
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end


    if SERVER then
        own:SetAnimation(PLAYER_ATTACK1)

        --no hit
        if tr.HitWorld or not tr.Entity:IsValid() then return end

        --explosion
        local targs = {}
        for _,ent in pairs(ents.FindInSphere(tr.HitPos, SWEP.Primary.ExpRadius))


    end

end