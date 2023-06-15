SWEP.PrintName = "Gravity Grenade"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"

SWEP.UseHands = false 
SWEP.ViewModel = "models/weapons/v_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"

SWEP.Armed = false
SWEP.ThrowDelay = 1.3 --delay between each throw
SWEP.LastThrow = 0
SWEP.Under = false

SWEP.Primary = {
    ClipSize = 100,
    DefaultClip = 100,
    Automatic = false, 
    Ammo = "pdmnade"
}

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = ""
}

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
                self:Throw()
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
    return CurTime() > self.LastThrow + self.ThrowDelay
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

function SWEP:Throw()
    local nade = ents.Create("sent_pdm_nade")
    local own = self:GetOwner()

    nade:SetOwner(own)

    --grenade spawn position
    local aim = own:GetAimVector()
    local gpos = own:GetPos()
    local right = aim:Cross(Vector(0,0,1))
    local pos = self.Under
    and gpos + aim*15 + right*6 + Vector(0,0,56) 
    or gpos + right*6 + Vector(0,0,66)
    
    nade:SetPos(pos)
    nade:SetAngles(own:EyeAngles())
    nade:Spawn()

    local phys = nade:GetPhysicsObject()
    if IsValid(phys) then
        local vel = self.Under and 400 or 1300
        phys:SetVelocity(own:GetVelocity() + own:GetAimVector()*vel)
    
        local angvel = self.Under and 200 or 300
        phys:SetAngleVelocity(VectorRand()*angvel)
    end

    self:SetClip1(self:Clip1()-1)
end