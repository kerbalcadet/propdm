AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Normal Crowbar"
    SWEP.Purpose = "Quite repulsive"
    SWEP.Category = "Prop Deathmatch"
    SWEP.ViewModelFOV = 40
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

SWEP.Primary.Damage = 25
SWEP.Primary.Range = 100
SWEP.Primary.ExpRadius = 200
SWEP.Primary.ExpPower = 12*10^6
SWEP.PlyWeight = 2000
SWEP.Primary.ExpDmg = 40
SWEP.Primary.DmgRadius = 200

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true 
SWEP.Primary.Delay = 1.5
SWEP.Primary.AttackDelay = 0.15
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType("melee")   --for some reason this doesn't work in the field
end

if SERVER then
    --disable self damage with crowbar
    hook.Remove("EntityTakeDamage", "pdm_crowbar_friendly")
    hook.Add("EntityTakeDamage", "pdm_crowbar_friendly", function(ent, dmg)
        if not dmg:GetInflictor() then return end
        
        local class = dmg:GetInflictor():GetClass()
        if ent:IsPlayer() and class and class == "pdm_crowbar" and ent == dmg:GetAttacker() then return true end
    end)
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
    self:SendWeaponAnim(ACT_VM_MISSCENTER)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    timer.Create(tostring(self), self.Primary.AttackDelay, 1, function() 
        if not self or not IsValid(self) or not self:GetOwner():Alive() then return end
        self:DelayedAttack() 
    end)
end

function SWEP:DelayedAttack()   --explosion doesn't hit the second you click
    --trace
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
    
    --sound
    local num = math.random(4)
    self:EmitSound("weapons/physcannon/superphys_launch"..num..".wav")

    --effect
    local ef = EffectData()
    ef:SetOrigin(tr.HitPos)
    ef:SetNormal(tr.Normal)
    
    if tr.Hit then  --sparks
        ef:SetMagnitude(1)
        ef:SetScale(2)
        ef:SetRadius(100)
        util.Effect("cball_explode", ef)
    end

    ef:SetScale(100)
    util.Effect("ThumperDust", ef)

    ef:SetEntity(own:GetViewModel())
    ef:SetAngles(own:EyeAngles())
    ef:SetAttachment(1)
    util.Effect("AirboatMuzzleFlash", ef)

    if SERVER then
        --explosion
        util.ScreenShake(tr.HitPos, 3, 1, 0.75, 500)
        PDM_GravExplode(tr.HitPos, self.Primary.ExpRadius, self.Primary.ExpPower, 5, 2400, own)        
        
        local dmg = DamageInfo()
        dmg:SetDamage(self.Primary.ExpDmg)
        dmg:SetDamageType(DMG_CRUSH)
        dmg:SetInflictor(self)
        dmg:SetAttacker(own)
        util.BlastDamageInfo(dmg, tr.HitPos, self.Primary.DmgRadius)
    end

end

function SWEP:SecondaryAttack()
end