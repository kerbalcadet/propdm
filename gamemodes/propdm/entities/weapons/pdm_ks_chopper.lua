AddCSLuaFile()
SWEP.PrintName = "Chopper Gunner"
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_ks_computer"
SWEP.Spawnable = true

SWEP.HeliTime = 45
local HeliPrimaryDelay = 0.1
local HeliSecondaryDelay = 5
local gunsight_offset = Vector(125,0,-100)
local MaxProps = 20

function SWEP:Initialize()
    self:SetHoldType("duel")
end

function SWEP:KS_Effect()
    local own = self:GetOwner()
    local hooktitle = tostring(own).."heli"

    if SERVER then
        local HSpawn = ents.FindByClass("pdm_helispawn")[1]
        if not HSpawn then
            own:ChatPrint("ERR: Could not find heli spawn!")
            return 
        end

        self.heli = ents.Create("npc_helicopter")
        local heli = self.heli
        heli:SetPos(HSpawn:GetPos())
        heli:AddRelationship("player D_NU 99")
        heli:SetKeyValue("Initial Speed", "100")

        heli:Spawn()
        heli:Activate()
        heli:Fire("SetTrack", "heli_patrol_1")
        heli:Fire("StartPatrol")
        heli:Fire("GunOff")
        heli:SetCollisionGroup(COLLISION_GROUP_WORLD)
        heli.Props = {}

        --communicate w client
        own:SetNW2Entity("Heli", heli)

        --heli logic
        hook.Add("Think", hooktitle, function() 
            HeliThink(heli, own)
        end)
    end

    if CLIENT then
        hook.Add("CreateMove", hooktitle, function(ucmd)
            ControlThink(ucmd)
        end)

        hook.Add("CalcView", hooktitle, CalcView)
    end

    timer.Simple(self.HeliTime, function()
        if CLIENT then
            hook.Remove("CreateMove", hooktitle)
            hook.Remove("CalcView", hooktitle)
            return 
        end

        --server only
        hook.Remove("Think", hooktitle)

        if self.heli and self.heli:IsValid() then
            self.heli:Remove()
        end

        if self:IsValid() then
            self:Remove()
        end
    end)
end



--########### SERVER ###########
if SERVER then

util.AddNetworkString("HeliFirePrimary")
util.AddNetworkString("HeliFireSecondary")

--main helilogic
function HeliThink(heli, own)
end

--chaingun
function HeliPrimary(len, ply)
    local heli = ply:GetNW2Entity("Heli")
    if not heli:IsValid() then return end

    if not heli.LastPrimaryFire then heli.LastPrimaryFire = 0 end
    if heli.LastPrimaryFire + HeliPrimaryDelay > CurTime() then return end
    heli.LastPrimaryFire = CurTime()

    --actual firing
    local maxv = 10000
    local maxw = 100
    local forward = ply:EyeAngles():Forward()
    local pos = heli:LocalToWorld(gunsight_offset) + forward*100
    local vel = forward*8000

    local ent = PDM_FireRandomProp(pos, AngleRand(), vel, AngleRand()*20, ply, maxw, maxv)

    local phys = ent:GetPhysicsObject() 
    if phys:IsValid() then
        phys:EnableDrag(false)
    end
    
    heli:EmitSound("garrysmod/balloon_pop_cute.wav", 400, 100, 0.4)

    --despawning
    table.insert(heli.Props, ent)
    if #heli.Props > MaxProps then
        local e = heli.Props[1]
        if IsValid(e) then e:Dissolve(1, ent:GetPos()) end

        table.remove(heli.Props, 1)
    end

    timer.Simple(PDM_DESPTIME:GetInt(), function()
        if IsValid(ent) then ent:Dissolve(1, ent:GetPos()) end
    end)
end
net.Receive("HeliFirePrimary", HeliPrimary)

--missiles
function HeliSecondary(len, ply)
    local heli = ply:GetNW2Entity("Heli")
    if not heli:IsValid() then return end

    if not heli.LastSecondaryFire then heli.LastSecondaryFire = 0 end
    if heli.LastSecondaryFire + HeliSecondaryDelay > CurTime() then return end
    heli.LastSecondaryFire = CurTime()

    local ang = ply:EyeAngles()
    local pos = heli:LocalToWorld(gunsight_offset) + ang:Forward()*100

    local rkt = ents.Create("proj_pdm_propket")
    rkt:SetOwner(ply)
    rkt:SetPos(pos)
    rkt:SetAngles(ang)

    rkt.RocketVel = 2000
    rkt.ExpRad = 300

    rkt:Spawn()

    heli:EmitSound("weapons/rpg/rocketfire1.wav", 300, 80)
end
net.Receive("HeliFireSecondary", HeliSecondary)

end



--######### CLIENT ##########
if CLIENT then

function CalcView(ply, origin, angles, fov, znear, zfar)
    local heli = LocalPlayer():GetNW2Entity("Heli")
    if not heli:IsValid() then return end
    local view = {
        origin = heli:LocalToWorld(gunsight_offset),
        fov = 70,
        drawviewer = true
    }

    return view
end

function ControlThink(ucmd)
    if ucmd:KeyDown(IN_ATTACK) then
        net.Start("HeliFirePrimary")
        net.SendToServer()
    end

    if ucmd:KeyDown(IN_ATTACK2) then
        net.Start("HeliFireSecondary")
        net.SendToServer()
    end

    ucmd:ClearButtons()
    ucmd:ClearMovement()
    ucmd:SetMouseWheel(0)
end

end

