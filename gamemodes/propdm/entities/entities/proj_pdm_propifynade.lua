AddCSLuaFile()
ENT.Base = "proj_pdm_nade"
ENT.Type = "anim"
ENT.PrintName = "Propify Grenade"

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/w_grenade.mdl")
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:DrawShadow(true)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)

        local phys = self:GetPhysicsObject()
        if phys:IsValid() then 
            phys:Wake()
            phys:SetMass(10)
        end
    end

    if CLIENT then
        self.SphereTime = 1
    end

    self.Fuse = self.Fuse or 3
    self.SpawnTime = CurTime()
    self.ExpRadius = 200
    self.ExpForce = 20*10^6
    self.Exploded = false
end

if CLIENT then
local mat = Material("models/props_combine/portalball001_sheet")
local refract = Material("propdm_refract")
local white = Vector(1,1,1)
local color = Vector(0.4,0.4,0.4)

local fadein = 0.1
local hold = 0.1
local fadeout = 0.8

function PropExpSphere(pos, radius, t)
    local col
    local rad
    local x
    if t < fadein then
        x = math.Clamp(t/fadein, 0, 1)
        col = color*x
        rad = radius*x
        
    elseif t < fadein + hold then
        x = 1
        col = color
        rad = radius
    else
        x = math.Clamp(1 - (t - fadein - hold)/fadeout, 0, 1)
        col = color*x
        rad = radius
    end


    mat:SetVector("$color2", col)       --fucking somehow this is the only way I seem to be able to be able to recolor/change alpha of this texture.
                                        --even when I deliberately make a new vtm with the same basetexture. I am at my wit's end.
    render.SetMaterial(mat)
    render.DrawSphere(pos, rad, 30, 30, color)

    mat:SetVector("$color2", white)
end
end

function ENT:Think()
    if self.SpawnTime + self.Fuse < CurTime() then
        local pos = self:GetPos()


        if CLIENT then
            if not self.Exploded then
                local diff = LocalPlayer():GetPos() - pos

                local ef = EffectData()
                ef:SetOrigin(pos)
                ef:SetNormal(diff:GetNormalized())
                ef:SetRadius(self.ExpRadius)
                util.Effect("AR2Explosion", ef)

                local exptime = CurTime()
                local rad = self.ExpRadius

                local title = tostring(self).."drawsphere"
                hook.Add("PreDrawEffects", title, function()
                    PropExpSphere(pos, rad, CurTime() - exptime)
                end)

                timer.Simple(self.SphereTime, function()
                    hook.Remove("PreDrawEffects", title)
                end)
            end
        
            
        end

        if SERVER and not self.Exploded then
            for _, v in pairs(ents.FindInSphere(pos, self.ExpRadius)) do
                local phys = v:GetPhysicsObject()
                local moveable = (v:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(phys) and phys:IsMoveable())
                if moveable then continue end

                local mdl = v:GetModel()
                if not mdl then continue end
                local vmdl = v.ViewModelIndex and v:ViewModelIndex()
                if vmdl then continue end

                
                v:EmitSound("physics/metal/metal_barrel_impact_soft"..math.random(1,4)..".wav")
                
                --actually replace the ent after our checks
                local newent = PDM_ReplaceProp(v, self:GetOwner())
                if not newent then continue end


                local diff = (newent:GetPos() - pos - Vector(0,0,100))
                local dir = Vector(0,0,1)

                local phys = newent:GetPhysicsObject()
                if not IsValid(phys) then continue end

                phys:SetVelocity(dir*self.ExpForce/diff:LengthSqr())
            end
        
            self:EmitSound("d3_citadel.zapper_warmup")
            self:SetNoDraw(true)
            self:Remove()
        end

        self.Exploded = true
    end
end