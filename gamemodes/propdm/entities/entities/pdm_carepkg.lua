AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Care Package"
ENT.Category = "Prop Deathmatch"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Deployed")
    self:NetworkVar("Bool", 1, "Landed")
    self:NetworkVar("Bool", 2, "Virtual")
    self:NetworkVar("Vector", 0, "VPos")
end

if CLIENT then


function ENT:Initialize()
    self.CS = ClientsideModel("models/Items/ammoCrate_Rockets.mdl")
    
    self.ChuteHeight = 75
    self.Chute = ClientsideModel("models/props_phx/construct/metal_dome360.mdl")
    self.Chute:SetPos(self:GetPos() + Vector(0,0,self.ChuteHeight))
    self.Chute:SetParent(self)
    self.Chute:SetMaterial("models/props_debris/building_template010a")
    self.Chute:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self.CColor = Color(255,255,255,255)


    
    self.ChuteAttach = true
    self.ChuteFall = false
end

function ENT:Think()
    if self.Chute then
        self.Chute:SetNoDraw(not self:GetDeployed())

        if self.ChuteAttach and self:GetLanded() then
            self.ChuteAttach = false
            self.ChuteFall = true
            self.Chute:SetParent(nil)
        
            timer.Simple(2, function()
                self.ChuteFall = false
                self.Chute:Remove()
            end)
        end
    
        if self.ChuteFall then
            local vel = Vector(0,0,-20)
            self.Chute:SetPos(self.Chute:GetPos() + vel*engine.TickInterval())
            
            self.CColor.a = math.Clamp(self.CColor.a - 0.5, 0, 255)
            self.Chute:SetColor(self.CColor)
        
            self:SetNextClientThink(CurTime())
            return true
        end
    end

    if not self:GetVirtual() then
        self.CS:Remove()
    end 
end

function ENT:Draw()
    if IsValid(self.CS) then
        local vpos = self:GetVPos()
        self.CS:SetPos(vpos)
        self.CS:DrawModel()

        if self:GetDeployed() then
            self.Chute:SetPos(vpos + Vector(0,0,self.ChuteHeight))
            self.Chute:DrawModel()
        end
    else
        self:DrawModel()
    end
end

end



if SERVER then
    
function ENT:Initialize()
    self:SetModel("models/Items/ammoCrate_Rockets.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetElasticity(0)
    self:DrawShadow(true)
    
    self.ChuteHeight = self.ChuteHeight or 2000
    self.ChuteDrag = self.ChuteDrag or 1/400
    self.WindPwr = 50
    self.WindFreq = 0.8

    self.SkyHeight = self.SkyHeight or nil
    self.VVel = Vector(0,0,0)   --these are only here for safekeeping. don't fuck with
    self.Grav = Vector(0,0,-600)
    self.Drag = Vector(0,0,0)   

    self.Virtual = self.Virtual or false

    if not self.Virtual then
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
    else
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)

        --variables for virtual crate in skybox
        self:SetVirtual(self.Virtual)
    
        self.VPos = self.VPos or nil
        self:SetVPos(self.VPos)
    end

    
    self:SetLanded(false)
    self:SetDeployed(false)

    self.WindSound = CreateSound(self, "ambient/levels/forest/treewind1.wav")
    self.DeploySound = CreateSound(self, "ambient/wind/wind_hit1.wav")

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(500)
    end
end

function ENT:PhysicsCollide(data,phys)
    if data.Speed > 100 then
        self:EmitSound("physics/metal/metal_barrel_impact_hard"..math.random(1,3)..".wav")
    end

    --less bouncing
    local phys = self:GetPhysicsObject()
    local force = -data.OurNewVelocity*phys:GetMass()*0.4
    phys:ApplyForceCenter(force)
    
    if not self:GetLanded() then 
        self:SetLanded(true)
        self.WindSound:Stop()
    end
end



function ENT:Think()
    --virtual physics
    if self:GetVirtual() then
        local vpos = self:GetVPos()
        local vvel = self.VVel
        local dt = engine.TickInterval()

        local wind = self:GetDeployed() and Vector(1,1,0)*math.sin(CurTime()*self.WindFreq)*self.WindPwr or Vector(0,0,0)

        vvel = vvel + (self.Grav + self.Drag*vvel.z^2 + wind)*dt
        vpos = vpos + vvel*dt

        self:SetVPos(vpos)
        self.VVel = vvel

        --pop into real level
        if vpos.z < self.SkyHeight - 200 then
            self:SetVirtual(false)
            self:SetMoveType(MOVETYPE_VPHYSICS)
            self:SetCollisionGroup(COLLISION_GROUP_NONE)
            self:SetPos(vpos)
            self:SetAngles(Angle())

            local phys = self:GetPhysicsObject()
            phys:Wake()
            phys:SetVelocity(vvel)
            phys:SetAngleVelocity(Vector(0,0,0))

        --simulate parachute while out of level
        elseif not self:GetDeployed() and vpos.z < self.ChuteHeight then
            self.Drag = Vector(0,0,1)*self.ChuteDrag
            self:SetDeployed(true)
        end
    end


    --in-world physics 
    if not self:GetVirtual() and not self:GetLanded() then
        --simulate parachute if deployed
        if self:GetDeployed() then
            local phys = self:GetPhysicsObject()
            local vel = phys:GetVelocity()
            
            local cforce = self.ChuteDrag*self:GetUp()*phys:GetMass()*(vel.z^2)
            local wforce = Vector(1,1,0)*math.sin(CurTime()*self.WindFreq)*phys:GetMass()*self.WindPwr
            phys:ApplyForceCenter((cforce + wforce)*engine.TickInterval())

            --small angle approximation for difference in angles
            local diff = vel:GetNormalized():Cross(self:GetUp())*phys:GetMass()*(1)
            local der = phys:GetAngleVelocity()*5
            phys:ApplyTorqueCenter(diff - der)

        --check if parachute can be deployed
        else
            local tr = util.QuickTrace(self:GetPos(), Vector(0,0,-10000), self)
            --deploy
            if (self:GetPos().z - tr.HitPos.z) < self.ChuteHeight then
                self:SetDeployed(true)
                
                self.DeploySound:Play()
                self.DeploySound:SetSoundLevel(500)
                
                self.WindSound:Play()
                self.WindSound:ChangePitch(80)
                self.WindSound:SetSoundLevel(500)
            end
        end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:Use(ply)
    print("test!")
end

end