AddCSLuaFile()
SWEP.PrintName = "Chopper Gunner"
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_ks_computer"
SWEP.Spawnable = true

SWEP.HeliTime = 60
local HeliPrimaryDelay = 0.1
local HeliSecondaryDelay = 5
local gunsight_offset = Vector(125,0,-100)
local MaxProps = 20
local HeliInitTime = 0
local introTime = 3

function SWEP:Initialize()
    self:SetHoldType("duel")
end

function SWEP:KS_Effect()
    if CLIENT then return true end

    local own = self:GetOwner()
    local hooktitle = tostring(own).."heli"
    HeliInitTime = CurTime()

    if SERVER then
        local heli = PDM_HELI
        if not heli:IsValid() then 
            own:ChatPrint("Could not find helicopter!")
            
            return false
        end

        heli:AddRelationship("player D_NU 99")
        heli:Fire("GunOff")

        --communicate w client
        own:SetNW2Entity("Heli", heli)
    end

    --initialize on client if successful
    net.Start("HeliClientStart")
        net.WriteEntity(self)
    net.Send(own)

    timer.Simple(self.HeliTime, function()
        local heli = PDM_HELI
        if heli and heli:IsValid() then
            heli:AddRelationship("player D_HT 99")
            heli:Fire("GunOn")
        end

        if self:IsValid() then
            self:Remove()
        end
    end)

    return true
end



--########### SERVER ###########
if SERVER then

util.AddNetworkString("HeliFirePrimary")
util.AddNetworkString("HeliFireSecondary")
util.AddNetworkString("HeliClientStart")

--chaingun
function HeliPrimary(len, ply)
    local heli = ply:GetNW2Entity("Heli")
    if not heli:IsValid() then return end

    if not heli.LastPrimaryFire then heli.LastPrimaryFire = 0 end
    if heli.LastPrimaryFire + HeliPrimaryDelay > CurTime() or CurTime() < HeliInitTime + 5 then return end
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
    heli:EmitSound("weapons/airboat/airboat_gun_energy1.wav", 400, 100, 0.4)

    --despawning
    table.insert(heli.Props, ent)
    if #heli.Props > MaxProps then
        local e = heli.Props[1]
        if IsValid(e) then e:Dissolve(1, ent:GetPos()) end

        table.remove(heli.Props, 1)
    end

    PDM_SetupDespawn(ent)
end
net.Receive("HeliFirePrimary", HeliPrimary)

--missiles
function HeliSecondary(len, ply)
    local heli = ply:GetNW2Entity("Heli")
    if not heli:IsValid() then return end

    if not heli.LastSecondaryFire then heli.LastSecondaryFire = 0 end
    if heli.LastSecondaryFire + HeliSecondaryDelay > CurTime() or CurTime() < HeliInitTime + 5 then return end
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

    heli:EmitSound("weapons/rpg/rocketfire1.wav", 400, 80, 1)
end
net.Receive("HeliFireSecondary", HeliSecondary)

end



--######### CLIENT ##########
if CLIENT then

function SWEP:ClientStart()
    local hooktitle = tostring(self:GetOwner()).."heli"
    HeliInitTime = CurTime()

    hook.Add("CalcView", hooktitle, CalcView)
    hook.Add("CreateMove", hooktitle, ControlThink)
    
    timer.Simple(introTime, function() 
        render.SetLightingMode(2)
        hook.Add("RenderScreenspaceEffects", hooktitle, RenderFX)
        hook.Add("PostDrawOpaqueRenderables", hooktitle, RenderPlayers)
        hook.Add("HUDShouldDraw", hooktitle, function(name) 
            if not (name == "CHudGMod") then return false end
        end)
    end)

    timer.Simple(self.HeliTime, function()
        render.SetLightingMode(0)
        RemoveHooks(hooktitle)
    end)
end

net.Receive("HeliClientStart", function(len, ply)
    net.ReadEntity():ClientStart()
end)

function RemoveHooks(hooktitle)
    hook.Remove("CreateMove", hooktitle)
    hook.Remove("CalcView", hooktitle)
    hook.Remove("RenderScreenspaceEffects", hooktitle)
    hook.Remove("PostDrawOpaqueRenderables", hooktitle)
    hook.Remove("HUDShouldDraw", hooktitle)
end

function CalcView(ply, origin, angles, fov, znear, zfar)
    if CurTime() < HeliInitTime + introTime then 
        local view = {fov = fov - 30*(CurTime() - HeliInitTime)/introTime}
        return view
    end

    local heli = LocalPlayer():GetNW2Entity("Heli")
    if not heli:IsValid() then 
        RemoveHooks(tostring(LocalPlayer()).."heli")
        render.SetLightingMode(0)
        return 
    end
    local view = {
        origin = heli:LocalToWorld(gunsight_offset),
        fov = 60,
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


--########HUD########

--FLIR
local fx = {
    ["$pp_colour_colour"] = 0,
	["$pp_colour_contrast"] = 0.9,
	["$pp_colour_brightness"] = 0.02
}
local FlirMat = Material("phoenix_storms/concrete0")

--HUD
local BoxColor = Color(218,74,74)
local GunsightColor = Color(255,255,255,255)
local heli_gunsight_mat = Material("brick/brick_model")

local ScrW = ScrW()
local ScrH = ScrH()

function RenderFX()
    DrawMaterialOverlay("models/shadertest/shader3", 0.003)
    DrawColorModify(fx)

    DrawBloom(0.5,1.0,2,2,2,1, 1, 1, 1) 
    DrawBokehDOF(1, 0.1, 0.000001)
    DrawSharpen(0.2, 1)

    --HUD
    render.SetLightingMode(0)
    for _, p in ipairs(player.GetAll()) do
        if not p:Alive() or p == LocalPlayer() then continue end
        
        local ts = p:GetPos():ToScreen()
        local posx = ts.x
        local posy = ts.y
        local w = ScrH/14
        local thickness = ScrH/400

        surface.SetDrawColor(BoxColor)
        surface.DrawOutlinedRect(posx - w/2, posy - w/2, w, w, thickness)
    end

    DrawMaterialOverlay("heli_gunsight/heli_gunsight", 0)
    DrawBokehDOF(1, 0.1, 0.000001)


    render.SetLightingMode(2)
end

function RenderPlayers()
    render.MaterialOverride(FlirMat)
    render.SuppressEngineLighting(true)
    render.SetColorModulation(5,5,5)

    for _, p in ipairs(player.GetAll()) do
        if not p:Alive() then continue end

        p:DrawModel()
    end

    render.SuppressEngineLighting(false)
    render.SetColorModulation(1,1,1)
    render.MaterialOverride(nil)
end

function SWEP:DoDrawCrosshair()
    return self.Used
end

end

