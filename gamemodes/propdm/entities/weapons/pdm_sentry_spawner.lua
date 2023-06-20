AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Sentry Spawner"
    SWEP.Purpose = "Little Friend"
    SWEP.Category = "Prop Deathmatch"
    SWEP.ViewModelFOV = 40
    SWEP.Weight = 5
    SWEP.Slot = 0
    SWEP.SlotPos = 7
end

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/Combine_turrets/Floor_turret.mdl"
SWEP.ViewModel = "models/Combine_turrets/Floor_turret.mdl"
SWEP.UseHands = false

function SWEP:Initialize()
    self:SetHoldType("melee")   --for some reason this doesn't work in the field
end

if CLIENT then
    local col = Color(255,240,50)

    function SWEP:DrawWeaponSelection(x, y, width, height)
        draw.SimpleText("c", "hl2b", x + width/2, y + height/2, col, 1, 1)
        draw.SimpleText("c", "hl2f", x + width/2, y + height/2, col, 1, 1)
    end
end

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    
    self:SendWeaponAnim(ACT_VM_MISSCENTER)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    -- Create a turret NPC, set its position and angle to just in front of the player in the aiming direction
    local turret = ents.Create("npc_turret_floor")
    turret:SetAngles(Angle(0, ply:GetAngles().y, 0))
    turret:SetPos(ply:GetPos() + ply:GetAimVector()*Vector(48, 48, 0))
    turret:SetOwner(ply)
    turret:Spawn()
    turret:DropToFloor()
    -- Don't attack the player placing this NPC
    turret:Fire("SetRelationship", ply:Nick() .. " D_LI 99")

    timer.Create(tostring(turret).."desp", PDM_DESPTIME, 1, function()
        if not IsValid(turret) then return end
        turret:Ignite()
    end)
end