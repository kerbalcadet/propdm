AddCSLuaFile()
ENT.Base = "proj_pdm_carepkgnade"
ENT.Type = "anim"
ENT.PrintName = "More is always better"

local carepkgnade = scripted_ents.GetStored(ENT.Base).t

function ENT:SpawnCrate(pos)
    self.SpawnPos = pos

    timer.Create(tostring(self).."SpawnCrate", 0.5, 4, function()
        carepkgnade.SpawnCrate(self, self.SpawnPos)

        self.SpawnPos = self.SpawnPos + VectorRand() * Vector(640, 640, 0)
    end)
end

function ENT:SpawnFakeCrate(pos, vpos, skyheight)
    self.SpawnPos = pos
    self.VSpawnPos = vpos
    
    timer.Create(tostring(self).."SpawnFakeCrate", 0.5, 4, function()
        carepkgnade.SpawnFakeCrate(self, self.SpawnPos, self.VSpawnPos, skyheight)

        vr = VectorRand() * Vector(640, 640, 0)
        self.SpawnPos = self.SpawnPos + vr
        self.VSpawnPos = self.VSpawnPos + vr
    end)
end