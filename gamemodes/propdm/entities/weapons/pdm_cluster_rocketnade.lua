SWEP.PrintName = "Cluster Rocketnade"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_nade"
SWEP.Slot = 4
SWEP.Weight = 2
SWEP.SlotPos = 1

SWEP.CanCook = false
SWEP.SeparateFuse = 0.5
SWEP.ThrowDelay = 2 --delay between each throw

SWEP.Primary = {
    ClipSize = 1,
    DefaultClip = 1,
    Automatic = false, 
    Ammo = "clusterrocketnade"
}

local angoffset = Angle(90, 0, 0)
function SWEP:ThrowNade()
    local nade = ents.Create("proj_pdm_cluster_rocketnade")
    nade.Forward = self:GetOwner():GetAimVector()
    self:Throw(nade, angoffset, nil, 0)
end