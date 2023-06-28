SWEP.PrintName = "Emergency Airdrop"
SWEP.Purpose = "Be better than kerbalcadet"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_carepkg_nade"

function SWEP:ThrowNade()
    local nade = ents.Create("proj_pdm_emergencynade")
    self:Throw(nade)
end