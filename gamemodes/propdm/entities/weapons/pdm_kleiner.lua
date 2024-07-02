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

SWEP.InRange = false
SWEP.Green = Color(50, 140, 50, 200)

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
    --TODO: throwing?
    if not self.InRange then return end

    

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

SWEP.csmodel = ClientsideModel("models/kleiner.mdl", RENDERGROUP_TRANSLUCENT)
SWEP.csmodel:SetModelScale(SWEP.csmodel:GetModelScale()*0.18)
SWEP.csmodel:SetNoDraw(true)

SWEP.holo = ClientsideModel("models/kleiner.mdl", RENDERGROUP_TRANSLUCENT)
SWEP.holo:SetRenderMode(RENDERMODE_TRANSCOLOR)
SWEP.holo:SetModelScale(SWEP.holo:GetModelScale()*0.3)
SWEP.holo:SetColor(SWEP.Green)
SWEP.holo:SetNoDraw(true)

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
            self.holo:SetNoDraw(true)
            self.EquipChecker = false
            hook.Remove("Tick", "pdm_checkkleiner")
        end
    end)
end

--hologram rendering
local holoangoff = Angle(90, 0, 0)
function SWEP:PreDrawViewModel()
    local ply = LocalPlayer()
    if not self.InRange then 
        self.holo:SetNoDraw(true)
        return 
    end

    local tr = ply:GetEyeTrace()
    local ang = tr.HitNormal:Angle() + holoangoff
    ang:RotateAroundAxis(ang:Up(), ply:GetAngles().y)

    self.holo:SetNoDraw(false)
    self.holo:SetPos(tr.HitPos)
    self.holo:SetAngles(ang)

    --I don't know why I can't get drawmodel() to render color properly
end

end