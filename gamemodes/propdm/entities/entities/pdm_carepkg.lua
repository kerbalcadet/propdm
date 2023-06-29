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
    self:NetworkVar("Vector", 1, "VVel")
    self:NetworkVar("Angle", 0, "VAng")
    self:NetworkVar("Float", 0, "OpenFraction")
end

if CLIENT then


function ENT:Initialize()
    self.CS = ClientsideModel("models/Items/ammoCrate_Rockets.mdl")

    self.CSInit = false
    self.RealInit = false

    self.Bottom = ClientsideModel("models/Items/ammoCrate_Rockets.mdl")
    self.Bottom:SetModelScale(0.99)

    self.ChuteHeight = 75
    self.Chute = ClientsideModel("models/props_phx/construct/metal_dome360.mdl")
    self.Chute:SetMaterial("models/props_debris/building_template010a")
    self.Chute:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self.CColor = Color(255,255,255,255)
    self.Chute:SetColor(self.CColor)

    
    self.ChuteAttach = true
    self.ChuteFall = false
end

function ENT:OnRemove()
    if self.CS then self.CS:Remove() end
    if self.Chute then self.Chute:Remove() end
    if self.Bottom then self.Bottom:Remove() end
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
end

function ENT:Draw()
    if self:GetVirtual() then
        local vpos = self:GetVPos()
        local ang = self:GetVAng()

        self.CS:SetPos(vpos)
        self.CS:SetAngles(ang)
        self.CS:DrawModel()

        if not self.CSInit then
            self.Bottom:SetPos(vpos)
            self.Bottom:SetAngles(ang + Angle(0,0,180))
            self.Bottom:SetParent(self.CS)
            
            self.Chute:SetPos(vpos + self.CS:GetUp()*self.ChuteHeight)
            self.Chute:SetAngles(ang)
            self.Chute:SetParent(self.CS)
        end

        self.Bottom:DrawModel()
        if self:GetDeployed() then self.Chute:DrawModel() end
    else
        if not self.RealInit and not self:GetLanded() then
            self.CS:Remove()

            self.Bottom:SetPos(self:GetPos())
            self.Bottom:SetAngles(self:GetAngles() + Angle(0,0,180))
            self.Bottom:SetParent(self)
            
            self.Chute:SetPos(self:GetPos() + self:GetUp()*self.ChuteHeight)
            self.Chute:SetAngles(self:GetAngles())
            self.Chute:SetParent(self)
        end 
        
        self:DrawModel()

        --self.Bottom:SetAngles(self:GetAngles() + Angle(0,0,180))
        self.Bottom:DrawModel()
        
        if self:GetDeployed() and not self:GetLanded() then self.Chute:DrawModel() end
    end
end

end



if SERVER then

util.PrecacheModel("models/Items/ammoCrate_Rockets.mdl")
    
function ENT:Initialize()
    self:SetModel("models/Items/ammoCrate_Rockets.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetElasticity(0)
    self:DrawShadow(true)

    self.OpenTime = 2
    self.Open = false
    self.LastUse = 0
    self:SetOpenFraction(0)
    
    --[[### all of this really should be adjusted in the proj_pdm_carepkgnade file, these are just defaults in case ###]]--

    self.ChuteHeight = self.ChuteHeight or 3000
    self.ChuteDrag = self.ChuteDrag or 1/200
    self.DragFactor = Vector(0.5,0.5,1)
    
    self.WindPwr = 100
    self.WindFreq = 1
    self.WindRotFreq = 0.5
    self.WindTOffset = math.Rand(-10,10)

    self.StartAng = self.StartAng or Angle()

    self.CallHeight = self.CallHeight or self:GetPos().z
    self.SkyHeight = self.SkyHeight or nil

    self.Grav = Vector(0,0,-600)    --these are only here for safekeeping. don't fuck with
    self.Drag = 0  

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

        self.VVel = self.VVel or Vector(0,0,0)   
        self:SetVVel(self.VVel)
    end

    self:SetLanded(false)
    self:SetDeployed(false)

    self.WindSound = CreateSound(self, "ambient/levels/forest/treewind1.wav")
    self.DeploySound = CreateSound(self, "ambient/wind/wind_hit1.wav")

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(500)
        phys:SetAngleDragCoefficient(1000)
        phys:Wake()
    end
end

--keeps clientside models from being unparented 
function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:PhysicsCollide(data,phys)
    if data.Speed > 100 and data.DeltaTime > 0.1 then
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
    if self:GetLanded() then return end 
    
    local t = CurTime() + self.WindTOffset
    local wrf = self.WindRotFreq
    local wf = self.WindFreq
    local wind = Vector(math.sin(t*wrf), math.cos(t*wrf), 0)*math.sin(CurTime()*wf)*self.WindPwr

    --calculate phys
    local vpos
    local vvel
    local aim
    if self:GetVirtual() or (not self:GetVirtual() and not self:GetDeployed()) then
        vpos = self:GetVPos()
        vvel = self:GetVVel()
        aim = vvel:GetNormalized()
        local dt = engine.TickInterval()

        local windf = self:GetDeployed() and wind or Vector(0,0,0)

        --iterate pos and velocity to simulate movement
        local drag = self.Drag*self.DragFactor*aim*vvel:LengthSqr()
        vvel = vvel + (self.Grav - drag + windf)*dt
        vpos = vpos + vvel*dt

        self:SetVPos(vpos)
        self:SetVVel(vvel)
        
        --angles
        local ang = vvel:Angle() + Angle(-90,0,0)
        ang.y = self.StartAng.y
        self:SetVAng(ang)
    end

    --phys should be simulated before chute opens
    --otherwise even with drag disabled, it will deploy earlier than it should
    if not self:GetVirtual() and not self:GetDeployed() then
        self:SetPos(vpos)
        self:SetAngles(vvel:Angle() + Angle(-90,0,0))
    end

    --virtual state checks
    if self:GetVirtual() then
        local inworld = util.IsInWorld(vpos - aim*100)

        --pop into real level
        if inworld then
            self:SetVirtual(false)

            self:SetMoveType(MOVETYPE_VPHYSICS)
            self:SetCollisionGroup(COLLISION_GROUP_NONE)
            self:SetPos(vpos)
            self:SetAngles(self:GetVAng())

            if self:GetDeployed() then
                local phys = self:GetPhysicsObject()
                phys:SetVelocity(self:GetVVel())
                phys:SetAngleVelocity(Vector())
            end

        --simulate parachute while out of level
        elseif not self:GetDeployed() and vpos.z < self.CallHeight + self.ChuteHeight then
            self.Drag = self.ChuteDrag
            self:SetDeployed(true)
        end
    end

    --in-world physics 
    if not self:GetVirtual() then

        --simulate parachute if deployed
        if self:GetDeployed() then
            local phys = self:GetPhysicsObject()
            local vel = phys:GetVelocity()
            
            local cforce = -self.ChuteDrag*self.DragFactor*phys:GetMass()*vel:GetNormalized()*vel:LengthSqr()
            phys:ApplyForceOffset(cforce*engine.TickInterval(), self:GetPos() + self:GetUp()*75)

            local wforce = wind*phys:GetMass()
            phys:ApplyForceCenter(wforce*engine.TickInterval())

        --check if parachute can be deployed
        elseif self:GetPos().z < self.CallHeight + self.ChuteHeight then
            self:SetDeployed(true)
            
            local phys = self:GetPhysicsObject()
            phys:Wake()
            phys:SetVelocity(vvel)
            phys:SetAngleVelocity(Vector(0,0,0))
            
            self.DeploySound:Play()
            self.DeploySound:SetSoundLevel(500)
            
            self.WindSound:Play()
            self.WindSound:ChangePitch(80)
            self.WindSound:SetSoundLevel(500)
        end
    end


    --remove opening status of crate
    local t = CurTime() - self.LastUse
    local of = self:GetOpenFraction()
    if of > 0 and t > 0.1 then 
        self:SetOpenFraction(math.clamp(of - engine.TickInterval()/self.OpenTime, 0, 1))
    end

    self:NextThink(CurTime() + engine.TickInterval())
    return true
end

function ENT:Use(ply)
    if self.Open then return end
    self.LastUse = CurTime()

    local of = self:GetOpenFraction()
    if of == 0 then self.FirstPly = ply end

    local tick = engine.TickInterval()
    of = of + tick/self.OpenTime    

    if of >= 1 then
        p = self.FirstPly or ply
        p:Give(table.Random(PDM_CAREPKG_WEPS))
        
        self:EmitSound("BaseCombatCharacter.AmmoPickup")
        
        self.Open = true
        timer.Simple(1, function()
            self:Remove()
        end)
    else
        self:SetOpenFraction(of)
    end
end

end