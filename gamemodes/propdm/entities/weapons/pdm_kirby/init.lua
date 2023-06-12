AddCSLuaFile()
AddCSLuaFile("cl_viewscreen.lua")

if CLIENT then
    SWEP.PrintName = "Kirby"
    SWEP.Purpose = "(つ -‘ _ ‘- )つ"
    SWEP.Category = "Prop Deathmatch"
    SWEP.ViewModelFOV = 55
    SWEP.Weight = 5
    SWEP.Slot = 1
    SWEP.SlotPos = 1
end

SWEP.Spawnable = true

SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.ViewModel = "models/weapons/v_toolgun.mdl"
SWEP.UseHands = true

function SWEP:Initialize()
    self:SetHoldType("pistol")
end