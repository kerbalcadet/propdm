ENT.Type = "anim"
ENT.Base = "base_gmodentity"
AddCSLuaFile()

function ENT:Initialize()
    self:SetModel("models/Combine_Helicopter.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end