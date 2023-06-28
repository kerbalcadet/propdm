AddCSLuaFile()
ENT.Base = "proj_pdm_carepkgnade"
ENT.Type = "anim"
ENT.PrintName = "More is always better"

--[[### CARE PACKAGE FUNCTIONS ###]]--

function ENT:SpawnCrate(pos)
    self.SpawnPos = pos

    timer.Create(tostring(self).."SpawnCrate", 0.5, 4, function()
        local crate = ents.Create("pdm_carepkg")
        crate.ChuteHeight = self.ChuteHeight
        crate.ChuteDrag = self.ChuteDrag
        crate:SetPos(self.SpawnPos)
        crate:Spawn()

        self.SpawnPos = self.SpawnPos + VectorRand() * Vector(640, 640, 0)
    end)
end

function ENT:SpawnFakeCrate(pos, vpos, skyheight)
    self.SpawnPos = pos
    self.VSpawnPos = vpos
    
    timer.Create(tostring(self).."SpawnFakeCrate", 0.5, 4, function()
        local crate = ents.Create("pdm_carepkg")
        crate.ChuteHeight = self.ChuteHeight
        crate.ChuteDrag = self.ChuteDrag
        crate:SetPos(self.SpawnPos)

        crate.Virtual = true
        crate.VPos = self.VSpawnPos
        crate.SkyHeight = skyheight

        crate:Spawn()

        vr = VectorRand() * Vector(640, 640, 0)
        self.SpawnPos = self.SpawnPos + vr
        self.VSpawnPos = self.VSpawnPos + vr
    end)
end