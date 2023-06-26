SWEP.PrintName = "Cluster Grenade"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"
SWEP.Slot = 4
SWEP.Weight = 2
SWEP.SlotPos = 1

SWEP.UseHands = false 
SWEP.ViewModel = "models/weapons/v_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"

util.PrecacheModel(SWEP.ViewModel)
util.PrecacheModel(SWEP.WorldModel)

SWEP.SeparateFuse = 0.5
SWEP.ThrowDelay = 2 --delay between each throw
SWEP.Armed = false
SWEP.LastThrow = 0
SWEP.Under = false


SWEP.Primary = {
    ClipSize = 1,
    DefaultClip = 1,
    Automatic = false, 
    Ammo = "clustergrenade"
}

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = ""
}

if CLIENT then
    local col = Color(255,240,50)

    function SWEP:DrawWeaponSelection(x, y, width, height)
        draw.SimpleText("k", "hl2b", x + width/2, y + height/2, col, 1, 1)
        draw.SimpleText("k", "hl2f", x + width/2, y + height/2, col, 1, 1)
    end
end



function SWEP:Initialize()
    self:SetWeaponHoldType("grenade")
    self.SoundPin = CreateSound(self, "physics/metal/chain_impact_hard2.wav")
    self.SoundSpoon = CreateSound(self, "npc/combine_soldier/gear3.wav")
    self.SoundThrow = CreateSound(self, "weapons/slam/throw.wav")
end

function SWEP:Deploy()
    self.Armed = false
    self:SendWeaponAnim(ACT_VM_DRAW)

    timer.Simple(0.5, function()
        self.SoundPin:Play()
        self.SoundPin:ChangePitch(105)
        self.SoundPin:ChangeVolume(0.3)
    end)
end

function SWEP:Think()
    local lclick = self:GetOwner():KeyDown(IN_ATTACK)
    local rclick = self:GetOwner():KeyDown(IN_ATTACK2)

    --throw
    if self.Armed and self:CanPrimaryAttack() and not (lclick or rclick) then
        self.Armed = false
        self.LastThrow = CurTime()
        
        local wanim = self.Under and ACT_VM_HAULBACK or ACT_VM_THROW
        self:SendWeaponAnim(wanim)
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)

        self.SoundThrow:Stop()
        self.SoundThrow:Play()

        self.SoundSpoon:Stop()
        self.SoundSpoon:Play()
        self.SoundSpoon:ChangeVolume(0.3)

        if SERVER then
            timer.Simple(0.1, function()
                local vel = self.Under and 400 or 1300
                self:Throw(vel)
            end)
        end

        timer.Simple(0.5, function()
            if not IsValid(self) then return end
            self:SendWeaponAnim(ACT_VM_DRAW)
            
            timer.Simple(0.5, function()
                if not IsValid(self) then return end
                self.SoundPin:Stop()
                self.SoundPin:Play()
                self.SoundPin:ChangePitch(105)
                self.SoundPin:ChangeVolume(0.3)
            end)
        end)
    end
end

function SWEP:CanPrimaryAttack()
    return CurTime() > self.LastThrow + self.ThrowDelay and self:Clip1() > 0
end

function SWEP:PrimaryAttack()
    if self.Armed or not self:CanPrimaryAttack() then return end

    self.Armed = true
    self:SendWeaponAnim(ACT_VM_PULLBACK_HIGH)
    self.Under = false
end

function SWEP:SecondaryAttack()
    if self.Armed or not self:CanPrimaryAttack() then return end

    self.Armed = true
    self:SendWeaponAnim(ACT_VM_PULLBACK_LOW)
    self.Under = true
end

function SWEP:Throw(vel)
    local nade = ents.Create("proj_pdm_clusternade")
    local own = self:GetOwner()

    nade:SetOwner(own)

    --grenade spawn position
    local aim = own:GetAimVector()
    local gpos = own:GetPos()
    local right = aim:Cross(Vector(0,0,1))
    local pos = self.Under
    and gpos + right*6 + Vector(0,0,56) 
    or gpos + right*6 + Vector(0,0,66)
    
    nade:SetPos(pos)
    nade:SetAngles(own:EyeAngles())
    nade:Spawn()
    nade.SeparateFuse = self.SeparateFuse

    local phys = nade:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(own:GetVelocity() + own:GetAimVector()*vel)
    
        local angvel = self.Under and 200 or 300
        phys:SetAngleVelocity(VectorRand()*angvel)
    end

    local clip = self:Clip1() - 1
    local ammo = own:GetAmmoCount("grenade")
    if ammo + clip <= 0 then
        self:Remove()
        own:SwitchLastWeapon()
    else
        self:SetClip1(1)
        own:SetAmmo(ammo - 1, "grenade")
    end
end