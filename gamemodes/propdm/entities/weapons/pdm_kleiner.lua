AddCSLuaFile()
SWEP.PrintName = "Proximity Klein"
SWEP.Category = "Prop Deathmatch"

SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.ViewModel = "models/weapons/v_slam.mdl"
SWEP.Slot = 5

SWEP.Spawnable = true
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.ViewModelFOV = 70
SWEP.AngleOffset = Angle(90,0,0)

SWEP.InRange = false
SWEP.Green = Color(50, 140, 50, 200)

SWEP.DrawAmmo = true
game.AddAmmoType({
    name = "Kleiners",
    dmgtype = DMG_BLAST
})

SWEP.Primary = {
    ClipSize = 100,
    DefaultClip = 1,
    Delay = 1.5,
    Ammo = "Kleiners",
    Range = 75
}

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = -1
}

function SWEP:Initialize()
    self:SetHoldType("slam")
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    --TODO: throwing?
    if not self.InRange then return end

    local own = self:GetOwner()
    local tr = own:GetEyeTrace()

    local klein = ents.Create("pdm_kleiner_mine")
    klein:SetPos(tr.HitPos)
    
    local ang = tr.HitNormal:Angle() + self.AngleOffset
    ang:RotateAroundAxis(ang:Up(), own:EyeAngles().y)
    klein:SetAngles(ang)

    klein:SetColor(own:GetColor())
    klein:SetOwner(own)
    klein:Spawn()

    local hitent = tr.Entity
    if hitent and IsValid(hitent) then
        constraint.Weld(klein, hitent, 0, 0, 0, true, false)
    end

    if self:Ammo1() < 1 then
        self:Remove()
        return
    end

    own:RemoveAmmo(1, "Kleiners")
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:SecondaryAttack()
end

function SWEP:Think()
    local own = self:GetOwner()
    self.tr = own:GetEyeTrace()

    if CLIENT and not self.EquipChecker then
        self:StartEquipChecker()
        self.EquipChecker = true
    end

    if (self.tr.HitPos - self.tr.StartPos):LengthSqr() > self.Primary.Range^2 then 
        self.InRange = false
        return 
    end
    self.InRange = true
end

--######## CLIENT #########

if CLIENT then

function SWEP:Initialize()
    self.csmodel = ClientsideModel("models/kleiner.mdl", RENDERGROUP_TRANSLUCENT)
    self.csmodel:SetModelScale(self.csmodel:GetModelScale()*0.18)
    self.csmodel:SetNoDraw(true)

    self.holo = ClientsideModel("models/kleiner.mdl", RENDERGROUP_TRANSLUCENT)
    self.holo:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self.holo:SetModelScale(self.holo:GetModelScale()*0.3)
    self.holo:SetColor(self.Green)
    self.holo:SetNoDraw(true)
end

--draw mini kleiner VM
local angoff = Angle(20,180,15)
local posoff = Vector(25,-1.5,-6.5)
function SWEP:PostDrawViewModel(vm, wep, ply)
    self.csmodel:SetPos(vm:LocalToWorld(posoff))

    local angadj = vm:LocalToWorldAngles(angoff)
    angadj:RotateAroundAxis(angadj:Up(), -vm:GetAngles().y)

    self.csmodel:SetAngles(angadj)
    
    --local colnorm = ply:GetColor():ToVector()*1.5
    --render.SetColorModulation(colnorm.r, colnorm.g, colnorm.b)    --regular set color won't work
    self.csmodel:DrawModel()
end

function SWEP:StartEquipChecker()
    --ughh 
    --really wish I could find a better solution
    hook.Remove("Tick", "pdm_checkkleiner")
    
    hook.Add("Tick", "pdm_checkkleiner", function()
        if not (LocalPlayer():GetActiveWeapon() == self) then 
            if IsValid(self) then
                self.holo:SetNoDraw(true)
                self.EquipChecker = false
            end
            hook.Remove("Tick", "pdm_checkkleiner")
        end
    end)
end

function SWEP:OnRemove()
    self.holo:Remove()
end

--hologram rendering
local holoangoff = SWEP.AngleOffset
function SWEP:PreDrawViewModel()
    local ply = LocalPlayer()
    if not self.InRange then 
        self.holo:SetNoDraw(true)
        return 
    end

    local tr = ply:GetEyeTrace()
    local ang = tr.HitNormal:Angle() + holoangoff
    ang:RotateAroundAxis(ang:Up(), ply:EyeAngles().y)

    self.holo:SetNoDraw(false)
    self.holo:SetPos(tr.HitPos)
    self.holo:SetAngles(ang)

    --I don't know why I can't get drawmodel() to render color properly
end

end