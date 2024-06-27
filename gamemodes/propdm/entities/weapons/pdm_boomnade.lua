SWEP.PrintName = "Boom Grenade"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_nade"
SWEP.Slot = 4
SWEP.SlotPos = 4

SWEP.Primary.Ammo = "boomnade"

function SWEP:ThrowNade()
    local nade = ents.Create("proj_pdm_nade")
    nade.Spawnlist = PDM_EXPPROPS
    nade.PropExpNum = 10
    nade.PropExpVel = 3000

    if not self.Under then
        nade.Fuse = self.Fuse - (CurTime() - self.LastCook)
    end

    self:Throw(nade)
end