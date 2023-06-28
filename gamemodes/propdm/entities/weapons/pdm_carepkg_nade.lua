SWEP.PrintName = "Care Package"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_nade"
SWEP.Slot = 4
SWEP.SlotPos = 1

SWEP.CanCook = false
SWEP.Primary = {
    ClipSize = 1,
    DefaultClip = 1,
    Automatic = false, 
    Ammo = "carepkgnade"
}


function SWEP:ThrowNade()
    local nade = ents.Create("proj_pdm_carepkgnade")
    self:Throw(nade)
end