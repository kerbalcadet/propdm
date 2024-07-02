AddCSLuaFile()
ENT.Base = "proj_pdm_nade"
ENT.Type = "anim"
ENT.PrintName = "Prop Grenade"

if CLIENT then

function ENT:Draw()
    self:DrawModel()
end

end

function ENT:Initialize()
    self.Fuse = self.Fuse or 3
    self.CallTime = self.CallTime or 5   --after fuse
    self.ChuteHeight = 3000
    self.PlaneHeight = 5000
    self.ChuteDrag = 1/200
    self.ChuteSlowDist = 1200   --how far away from the target point the parachute deploys to slow down

    self.SpawnTime = self.CallTime + 3
    self.DespTime = self.DespTime or 15

    self.Failed = false
    self.SpawnTime = CurTime()
    self.Exploded = false

    self.Color = Color(240, 70, 70)
    self.ParticleDelay = 0.03 --affects density of smoke trail

    self.ExpSound = CreateSound(self, "Weapon_Extinguisher.NPC_Double")
    self.SmokeSound = CreateSound(self, "ambient/machines/gas_loop_1.wav")

    if SERVER then
        self:SetModel("models/weapons/w_grenade.mdl")
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)

        local phys = self:GetPhysicsObject()
        if phys:IsValid() then 
            phys:Wake()
            phys:SetMass(1)
        end

        self.Owner = self.Owner or self:GetOwner()
        self.Weapon = self.Weapon or self:GetOwner():GetActiveWeapon()

        --generate shared plane direction for server & client
        local pvec = VectorRand()
        pvec.z = 0
        pvec:Normalize()
        self:SetPlaneVector(pvec)
    end

    if CLIENT then
        self.Emitter = ParticleEmitter(self:GetPos(), false)
        sound.Add({
            name = "PlaneSound",
            channel = CHAN_STATIC,
            volume = 3.0,
            level = 500,
            sound = "thrusters/jet03.wav"
        })
    end
end

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "PlaneVector")
end

function ENT:Think()
    if self.SpawnTime + self.Fuse < CurTime() and CurTime() < self.SpawnTime + self.Fuse + self.DespTime then
        if not self.Exploded then
            self.Exploded = true

            --sound

            if SERVER then
                self.ExpSound:SetSoundLevel(80)
                self.ExpSound:Play()
                self.ExpSound:ChangePitch(150)
                self.SmokeSound:Play()
            end

            --despawning
            timer.Simple(self.DespTime, function()
                if not IsValid(self) then return end

                if SERVER then
                    self.ExpSound:Stop()
                    self.SmokeSound:Stop() 
                    self:Remove() 
                end
                if CLIENT and not self.Failed then self.Emitter:Finish() end 
            end)

            --call plane
            self:PreCallPlane()
        end

        --fx
        if CLIENT and not self.Failed then
            self:EmitParticle()
        end
    end

    if CLIENT then
        self:SetNextClientThink(CurTime() + self.ParticleDelay)
        return true
    end
end

function ENT:PreCallPlane()
    timer.Simple(self.CallTime, function()

        local success = false
        local pos = self:GetPos()
        
        local data = {start=pos, endpos=pos+Vector(0,0,100000), filter=self, MASK_NPCWORLDSTATIC}
        local tr = util.TraceLine(data)         
        
        if not tr.HitSky then
            data.start = tr.HitPos + Vector(0,0,500)
            tr = util.TraceLine(data)
        end

        if not tr.HitSky then 
            self.Failed = true

            if CLIENT then
                self.Emitter:Finish() 
                self:GetOwner():PrintMessage(4, "Smoke could not be seen!") 
                return
            end
            if SERVER then 
                self.ExpSound:Stop()
                self.SmokeSound:Stop()
                self:GetOwner():Give("pdm_carepkg_nade")
                return
            end
        end

        --successful
        self.Trace = tr
        self:CallPlane()
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    end)
end

function ENT:EmitParticle()
    local pos = self:WorldSpaceCenter() + self:GetUp()*5
    local em = self.Emitter
    local part = em:Add("particles/pdm/smoke", pos)

    local c = self.Color
    part:SetColor(c.r, c.g, c.b)
    part:SetDieTime(3)
    part:SetEndAlpha(0)
    part:SetStartSize(5)
    part:SetEndSize(100)
    part:SetGravity(Vector(0,0,100))
    part:SetVelocity(Vector(80, 20, 50) + VectorRand()*20)
    part:SetAngleVelocity(AngleRand()/100)
end









--[[### CARE PACKAGE FUNCTIONS ###]]--


function ENT:SpawnCrate(pos, vpos, vvel, skyheight)
    local crate = ents.Create("pdm_carepkg")
    crate.CallHeight = self:GetPos().z
    crate:SetPos(pos)

    crate.Virtual = true
    crate.VPos = vpos
    crate.VVel = vvel
    
    local a = self:GetPlaneVector():Angle()
    a.r = 0
    crate.StartAng = a 
    
    crate.ChuteHeight = self.ChuteHeight
    crate.ChuteDrag = self.ChuteDrag
    crate.SkyHeight = skyheight

    crate:Spawn()
end


function ENT:CallPlane()
    local trpos = self.Trace.HitPos
    local pos = Vector(trpos.x, trpos.y, self:GetPos().z + self.PlaneHeight)
    local sky = trpos.z

    local speed = 5000
    local dist = 30000
    local pvec = self:GetPlaneVector()    --direction vector of rendered plane

    local etime = dist*2/speed

    --spawn crate
    if SERVER then
        -- use basic ballistics to predict where to drop
        -- s = (1/2)a*t^2 --> t = (2s/a)^1/2
        local dtime = (2*(self.PlaneHeight - self.ChuteHeight)/600)^(1/2)
        local t_remove = self.ChuteSlowDist/speed
        dtime = dtime + t_remove
        
        if dtime >= etime/2 then print("No window to drop! Try adjusting speed or height.") return end

        local spawnpos = pos - pvec*dtime*speed
        timer.Simple(etime/2 - dtime, function() self:SpawnCrate(trpos - Vector(0,0,100), spawnpos, speed*pvec, sky) end)
    end

    --render plane
    if CLIENT then

        local pvec = self:GetPlaneVector()
        local plane = ClientsideModel("models/xqm/jetbody3_s2.mdl")
        plane:SetAngles((pvec):Angle() + Angle(0,90,0))
        
        local stpos = pos - pvec*dist
        local stime = CurTime()
        local ppos = stpos

        local title = tostring(self).."drawplane"
        hook.Remove("PreDrawOpaqueRenderables", title)
        hook.Add("PreDrawOpaqueRenderables", title, function()
            ppos = pos - pvec*(dist - (CurTime() - stime)*speed)
            plane:SetPos(ppos)
            plane:DrawModel()
        end)

        --flyover sound is 10seconds, so play s before middle
        timer.Simple(math.max(etime/2 - 5, 0), function()
            sound.PlayFile("sound/ambient/overhead/plane3.wav", "3d", function(chan)
                chan:SetPos(stpos)
                chan:Set3DEnabled(true)
                chan:SetVolume(5)
                chan:Set3DFadeDistance(10000, 100000)

                hook.Add("Think", title, function()
                    chan:SetPos(ppos)
                end)

                timer.Simple(etime, function()
                    chan:Stop()
                    hook.Remove("Think", title)
                end)
            end)

            timer.Simple(etime, function()
                hook.Remove("PreDrawOpaqueRenderables", title)
                plane:Remove()
            end)
        end)
    end
end