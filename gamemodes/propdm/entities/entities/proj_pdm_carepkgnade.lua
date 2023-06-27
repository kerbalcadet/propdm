AddCSLuaFile()
ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.PrintName = "Prop Grenade"

function ENT:PhysicsCollide(data,phys)
    if data.Speed > 50 then
        self:EmitSound("physics/metal/metal_grenade_impact_hard"..math.random(1,3)..".wav")
    end
end

if CLIENT then

function ENT:Draw()
    self:DrawModel()
end

end

function ENT:Initialize()
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
    end

    self.Fuse = self.Fuse or 3
    self.CallTime = 4   --after fuse
    self.PlaneHeight = 6000
    self.SpawnTime = self.CallTime + 3
    self.Failed = false

    self.DespTime = self.DespTime or 15
    self.SpawnTime = CurTime()
    self.Exploded = false

    self.Color = Color(240, 70, 70)
    self.ParticleDelay = 0.03 --affects density of smoke trail

    self.ExpSound = CreateSound(self, "Weapon_Extinguisher.NPC_Double")
    self.SmokeSound = CreateSound(self, "ambient/machines/gas_loop_1.wav")

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

function ENT:Think()
    if self.SpawnTime + self.Fuse < CurTime() and CurTime() < self.SpawnTime + self.Fuse + self.DespTime then
        if not self.Exploded then
            self.Exploded = true

            --sound

            if SERVER then
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
            timer.Simple(self.CallTime, function()
                local success = false
                local pos = self:GetPos()
                
                local data = {start=pos, endpos=pos+Vector(0,0,100000), filter=self, MASK_NPCWORLDSTATIC}
                local tr = util.TraceLine(data)            

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
            end)
        end

        --fx
        if CLIENT and not self.Failed then
            local pos = self:GetPos()
            local em = self.Emitter
            local part = em:Add("particles/pdm/smoke", pos)

            local c = self.Color
            part:SetColor(c.r, c.g, c.b)
            part:SetDieTime(4)
            part:SetEndAlpha(0)
            part:SetStartSize(5)
            part:SetEndSize(120)
            part:SetGravity(Vector(0,0,100))
            part:SetVelocity(Vector(80, 20, 50) + VectorRand()*20)
            part:SetAngleVelocity(AngleRand()/100)
        end
    end

    if CLIENT then
        self:SetNextClientThink(CurTime() + self.ParticleDelay)
        return true
    end
end

function ENT:CallPlane()
    if CLIENT then
        pos = self.Trace.HitPos
        pos.z = self.PlaneHeight
        
        local rvec = VectorRand()
        rvec.z = 0
        rvec:Normalize()

        local speed = 6000
        local dist = 30000

        local plane = ClientsideModel("models/xqm/jetbody3_s2.mdl")
        plane:SetAngles((-rvec):Angle() + Angle(0,90,0))
        local stpos = pos + rvec*dist
        local stime = CurTime()
        local etime = dist*2/speed
        local ppos = stpos



        local title = tostring(self).."drawplane"
        hook.Remove("PreDrawOpaqueRenderables", title)
        hook.Add("PreDrawOpaqueRenderables", title, function()
            ppos = pos + rvec*(dist - (CurTime() - stime)*speed)
            plane:SetPos(ppos)
            plane:DrawModel()
        end)

        --flyover sound is 10seconds, so play s before middle
        timer.Simple(math.max(etime/2 - 5, 0), function()
            sound.PlayFile("sound/ambient/overhead/plane3.wav", "3d", function(chan)
                chan:SetPos(stpos)
                chan:Set3DEnabled(true)
                chan:SetVolume(5)
                chan:Set3DFadeDistance(5000, 100000)

                local title = tostring(self).."sound"
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