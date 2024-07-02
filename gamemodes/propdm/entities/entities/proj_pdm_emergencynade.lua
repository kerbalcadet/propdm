AddCSLuaFile()
ENT.Base = "proj_pdm_carepkgnade"
ENT.Type = "anim"
ENT.PrintName = "More is always better"

--sweet jank my beloved
function ENT:PreCallPlane()
    timer.Simple(self.CallTime, function()
        local data = {start=self:GetPos(), endpos=self:GetPos()+Vector(0,0,100000), filter=self, MASK_NPCWORLDSTATIC}
        self.Trace = util.TraceLine(data)  

        for i=1,4 do
            timer.Simple(math.Rand(0,1), function()
                --local pvec = VectorRand()
                --pvec.z = 0
                --pvec:Normalize()
                --self:SetPlaneVector(pvec)

                --self.PlaneHeight = 5000 + math.Rand(-500, 500)
                self:CallPlane()
            end)
        end
    end)
end