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

SWEP.TurretHealth = 200
SWEP.DespTime = 60
SWEP.PlaceRange = 150
SWEP.MaxProps = 20
SWEP.CanPlace = false
SWEP.DeathBlastDmg = 50
SWEP.DeathBlastRad = 200

SWEP.Green = Color(50, 140, 50, 120)
SWEP.Red = Color(200, 50, 50, 120)


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

    local plyinbox = false 
    if tr.Hit then
        --check if it will collide with player
        local pos = tr.HitPos
        local rad = 40
        
        for _, p in pairs(player.GetAll()) do
            local diff = p:GetPos() - pos
            if (diff.x^2 + diff.y^2 < rad^2) and diff.z < 64 then 
                plyinbox = true
                break 
            end 
        end
    end
    

    self.CanPlace = tr.Hit and not plyinbox 

    --render sentry hologram
    if CLIENT then
        if not IsValid(self.Holo) then
        end


        local holo = self.Holo
        local col = self.CanPlace and self.Green or self.Red

        if tr.Hit and not self.Holstered then
            holo:SetNoDraw(false)
            holo:SetPos(tr.HitPos)
            holo:SetAngles(Angle(0, self:GetOwner():EyeAngles().y, 0))
            holo:SetColor(col)
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
    SWEP.Holo:SetColor(SWEP.Green)
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

    function SWEP:Deploy()
        self.Holstered = false
    end

    function SWEP:Holster()
        self.Holstered = true
    end

    function SWEP:OnRemove()
        self.Holstered = false
        self.Holo:SetNoDraw(true)
    end
end




if SERVER then

--[[### WEAPON LOGIC ###]]--

function ENTITY:PDM_TurretDeath()
    if not IsValid(self) then return end

    self.Dying = true
    self:Fire("SelfDestruct")

    local rad = self.BlastRad
    local dmg = self.BlastDmg
    local own = self.Owner

    timer.Simple(4, function()
        if not IsValid(self) then return end

        local pos = self:GetPos()

        self:EmitSound("BaseExplosionEffect.Sound")

        local ef = EffectData()
        ef:SetOrigin(pos)
        ef:SetScale(0.75)
        ef:SetMagnitude(1)
        util.Effect("Explosion", ef)
        
        util.BlastDamage(game.GetWorld(), own, pos, rad, dmg)
    end)
end

function SWEP:PrimaryAttack()
    if not self.CanPlace then return end

    local ply = self:GetOwner()    
    ply:SetAnimation(PLAYER_ATTACK1)


    -- Create a turret NPC, set its position and angle to just in front of the player in the aiming direction
    local turret = ents.Create("npc_turret_floor")
    turret:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    turret:SetPos(tr.HitPos)
    turret:Spawn()
    turret:SetMoveType(MOVETYPE_NONE)

    turret:SetHealth(self.TurretHealth)
    turret.PDM = true
    turret.NoPickup = true
    turret.MaxProps = self.MaxProps
    turret.Props = {}   --list of all props fired
    turret.Owner = ply

    -- Setup relationships
    turret:Fire("SetRelationship", ply:Nick() .. " D_LI 99")
    turret:Fire("SetRelationship", "npc_helicopter D_HT 99")

    --sound
    turret:EmitSound("physics/metal/metal_barrel_impact_soft1.wav")
    turret:EmitSound("k_lab.eyescanner_deploy")

    --despawning
    turret.BlastDmg = self.DeathBlastDmg
    turret.BlastRad = self.DeathBlastRad
    timer.Simple(self.DespTime, function()
        turret:PDM_TurretDeath()
    end)

    self:Remove()
    local lastwep = ply:GetPreviousWeapon()
    local wep = IsValid(lastwep) and lastwep or ply:GetWeapons()[1]
    if wep then ply:SelectWeapon(wep:GetClass()) end
end




--[[### HOOKS ###]]--

--turrets normally do not process health
--genuinely I do not think there is a better way to add this
hook.Remove("EntityTakeDamage", "PDM_SentryHealth")
hook.Add("EntityTakeDamage", "PDM_SentryHealth", function(ent, dmg)
    if not (ent:GetClass() == "npc_turret_floor" and ent.PDM == true) then return end

    local health = ent:Health() - dmg:GetDamage()
    ent:SetHealth(health)

    if health <= 0 and not ent.Dying then ent:PDM_TurretDeath() end
end)

--shoot props
hook.Remove("EntityFireBullets", "PDM_SentryProps")
hook.Add("EntityFireBullets", "PDM_SentryProps", function(wep, bullet)
    if not (wep:GetClass() == "npc_turret_floor") then return end

    local prob = 45  --%
    if math.random(100) > prob then return false end
    
    --
    -- If we got to this point, we *should* be good to run the rest of the hook
    --
    
    --find prop under volume and weight limit
    local maxv = 30000
    local maxw = 100
    local pos = bullet.Src + bullet.Dir * 32
    local vel = 4000 * bullet.Dir

    --table, pos, angle, vel, angvel
    local ent = PDM_FireRandomProp(pos, AngleRand(), vel, AngleRand()*100, wep.Owner, maxw, maxv)
    wep:EmitSound("garrysmod/balloon_pop_cute.wav", 400, 100, 0.4)

    --collisions
    ent:SetOwner(wep)

    --despawning
    table.insert(wep.Props, ent)
    if #wep.Props > wep.MaxProps then
        local e = wep.Props[1]
        if IsValid(e) then e:Dissolve(1, ent:GetPos()) end

        table.remove(wep.Props, 1)
    end

    PDM_SetupDespawn(ent)

    -- return false IOT NOT fire the original bullet(s)
    return false
end)

end