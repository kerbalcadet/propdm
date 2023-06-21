AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Sentry Spawner"
    SWEP.Purpose = "Little Friend"
    SWEP.Category = "Prop Deathmatch"
    SWEP.ViewModelFOV = 80
    SWEP.Weight = 5
    SWEP.Slot = 5
    SWEP.SlotPos = 7
end

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Base = "weapon_base"
SWEP.WorldModel = "models/Combine_turrets/Floor_turret.mdl"
SWEP.WorldModelPos = Vector(0, -3, -30)    --relative to hand
SWEP.ViewModel = "models/Combine_turrets/Floor_turret.mdl"
SWEP.ViewModelPos = Vector(30, -25, -40)
SWEP.UseHands = false

SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

SWEP.DespTime = 60
SWEP.PlaceRange = 150
SWEP.CanPlace = false
SWEP.DeathBlastDmg = 50
SWEP.DeathBlastRad = 200


function SWEP:Initialize()
    self:SetHoldType("melee")   --for some reason this doesn't work in the field
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
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

    function SWEP:CalcViewModelView(vm, oep, oea, ep, ea)
        local pos, ang = LocalToWorld(self.ViewModelPos, Angle(0,0,0), ep, ea)
        
        return pos, ang
    end

    SWEP.Holo = ClientsideModel("models/Combine_turrets/Floor_turret.mdl", RENDERGROUP_TRANSLUCENT)
    SWEP.Holo:SetRenderMode(RENDERMODE_TRANSALPHA)
    SWEP.Holo:SetMaterial("models/debug/debugwhite")
    SWEP.Holo:SetColor(Color(50, 140, 50, 120))
    SWEP.Holo:SetNoDraw(true)

    SWEP.WM = ClientsideModel(SWEP.WorldModel, RENDERGROUP_OPAQUE)
    SWEP.WM:SetNoDraw(true)

    function SWEP:DrawWorldModel()
        local own = self:GetOwner()
        if not IsValid(own) then return end

        local bone = own:LookupBone("ValveBiped.Bip01_R_Hand")
        local bmat = own:GetBoneMatrix(bone)

        local ea = Angle(0, own:EyeAngles().y, 0)
        local pos, ang = LocalToWorld(self.WorldModelPos, Angle(0,0,0), bmat:GetTranslation(), ea)
    
        local wm = self.WM
        wm:SetPos(pos)
        wm:SetAngles(ang)
        wm:DrawModel()
    end

    function SWEP:Holster()
        self.Holo:SetNoDraw(true)
    end

    function SWEP:OnRemove()
        self.Holo:SetNoDraw(true)
    end
end




if SERVER then

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()    
    ply:SetAnimation(PLAYER_ATTACK1)


    -- Create a turret NPC, set its position and angle to just in front of the player in the aiming direction
    local turret = ents.Create("npc_turret_floor")
    turret:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    turret:SetPos(tr.HitPos)
    turret:Spawn()
    turret:SetMoveType(MOVETYPE_NONE)
    turret.NoPickup = true


    -- Don't attack the player placing this NPC
    turret:Fire("SetRelationship", ply:Nick() .. " D_LI 99")

    turret:EmitSound("physics/metal/metal_barrel_impact_soft1.wav")
    turret:EmitSound("k_lab.eyescanner_deploy")

    turret.BlastDmg = self.DeathBlastDmg
    turret.BlastRad = self.DeathBlastRad
    timer.Simple(self.DespTime, function()
        if not IsValid(turret) then return end

        turret:Fire("SelfDestruct")

        timer.Simple(4, function()
            local pos = turret:GetPos()

            turret:EmitSound("BaseExplosionEffect.Sound")

            local ef = EffectData()
            ef:SetOrigin(pos)
            ef:SetScale(0.75)
            ef:SetMagnitude(1)
            util.Effect("Explosion", ef)

            util.BlastDamage(turret, ply, pos, turret.BlastRad, turret.BlastDmg)
        end)
    end)

    self:Remove()
    local lastwep = ply:GetPreviousWeapon()
    local wep = IsValid(lastwep) and lastwep or ply:GetWeapons()[1]
    if wep then ply:SelectWeapon(wep:GetClass()) end
end

end