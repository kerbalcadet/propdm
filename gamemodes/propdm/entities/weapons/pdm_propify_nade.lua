SWEP.PrintName = "Propmogrification Grenade"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_nade"
SWEP.Slot = 4
SWEP.SlotPos = 4

SWEP.Primary.Ammo = "propifynade"

function SWEP:ThrowNade()
    local nade = ents.Create("proj_pdm_propifynade")
    self:Throw(nade)
    if not self.Under then
        nade.Fuse = self.Fuse - (CurTime() - self.LastCook)
    end
end