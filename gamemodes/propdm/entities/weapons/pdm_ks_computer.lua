AddCSLuaFile()
SWEP.PrintName = "KS_Computer"
SWEP.Category = "Prop Deathmatch"
SWEP.Slot = 5
SWEP.SlotPos = 0

SWEP.Spawnable = false

SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/props/cs_office/computer.mdl"
SWEP.ViewModel = "models/props/cs_office/computer.mdl"
SWEP.UseHands = false
SWEP.Secondary.Automatic = true
SWEP.ViewModelFOV = 70

SWEP.Used = false

if CLIENT then

local col = Color(255,240,50)

function SWEP:DrawWeaponSelection(x, y, width, height)
    draw.SimpleText("x", "hl2b", x + width/2, y + height/2, col, 1, 1)
    draw.SimpleText("x", "hl2f", x + width/2, y + height/2, col, 1, 1)
end    

local poff = Vector(30, -1, -12)
local aoff = Angle(0, 180, 0)
function SWEP:CalcViewModelView(vm, op, oa, p, a)
    return LocalToWorld(poff, aoff, p, a)
end

local worldModel = ClientsideModel(SWEP.ViewModel)
worldModel:SetNoDraw(true)

local poff_world = Vector(7, -21, -4)
local aoff_world = Angle(180,-15,-12)
function SWEP:DrawWorldModel()
    --lifted straight from the wiki
    local owner = self:GetOwner()
    if not owner:IsValid() then 
        self:DrawModel()
        return 
    end

    local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    local mat = owner:GetBoneMatrix(bone)

    local pos, ang = LocalToWorld(poff_world, aoff_world, mat:GetTranslation(), mat:GetAngles())

    worldModel:SetPos(pos)
    worldModel:SetAngles(ang)
    worldModel:DrawModel()
end

end

function SWEP:Initialize()
    self:SetHoldType("duel")
end

function SWEP:PrimaryAttack()
    if self.Used then return end

    self:EmitSound("k_lab.typing_fast_1")
    self:KS_Effect()
    self.Used = true
end

function SWEP:KS_Effect()
    return
end