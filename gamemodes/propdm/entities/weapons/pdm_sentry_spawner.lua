AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Sentry Spawner"
    SWEP.Purpose = "Little Friend"
    SWEP.Category = "Prop Deathmatch"
    SWEP.ViewModelFOV = 100
    SWEP.Weight = 5
    SWEP.Slot = 5
    SWEP.SlotPos = 7
end

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/Combine_turrets/Floor_turret.mdl"
SWEP.ViewModel = "models/Combine_turrets/Floor_turret.mdl"
SWEP.UseHands = false

SWEP.PlaceRange = 150
SWEP.CanPlace = false

function SWEP:Initialize()
    self:SetHoldType("melee")   --for some reason this doesn't work in the field
end

local tr = {}
function SWEP:Think()
    local own = self:GetOwner()

    --get trace location for placing
    tr = util.QuickTrace(own:GetShootPos(), own:GetAimVector()*self.PlaceRange, own)
    if not tr.Hit then
        tr = util.QuickTrace(tr.HitPos, Vector(0,0,-self.PlaceRange))
    end

    self.CanPlace = tr.Hit

    --render sentry hologram
    if CLIENT then
        if not IsValid(self.Holo) then
            self.Holo = ClientsideModel("models/Combine_turrets/Floor_turret.mdl", RENDERGROUP_TRANSLUCENT)
            self.Holo:SetRenderMode(RENDERMODE_TRANSALPHA)
            self.Holo:SetMaterial("models/debug/debugwhite")
            self.Holo:SetColor(Color(50, 140, 50, 120))
        end

        local holo = self.Holo
        if tr.Hit then
            holo:SetNoDraw(false)
            holo:SetPos(tr.HitPos)
            holo:SetAngles(Angle(0, self:GetOwner():EyeAngles().y, 0))
        else
            holo:SetNoDraw(true)
        end

        self:SetNextClientThink(CurTime())
        return true
    end
end



if CLIENT then
    local col = Color(255,240,50)

    function SWEP:DrawWeaponSelection(x, y, width, height)
        draw.SimpleText("?", "hl2b", x + width/2, y + height/2, col, 1, 1)
        draw.SimpleText("?", "hl2f", x + width/2, y + height/2, col, 1, 1)
    end

    function SWEP:Holster()
        self.Holo:SetNoDraw(true)
    end

    function SWEP:OnRemove()
        self.Holo:Remove()
    end
end




if SERVER then

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
    
    self:SendWeaponAnim(ACT_VM_MISSCENTER)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    -- Create a turret NPC, set its position and angle to just in front of the player in the aiming direction
    local turret = ents.Create("npc_turret_floor")
    turret:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    turret:SetPos(tr.HitPos + Vector(0,0,1))
    turret:SetOwner(ply)
    turret:Spawn()

    -- Don't attack the player placing this NPC
    turret:Fire("SetRelationship", ply:Nick() .. " D_LI 99")

    timer.Create(tostring(turret).."desp", PDM_DESPTIME, 1, function()
        if not IsValid(turret) then return end
        turret:Ignite()
    end)
end

end