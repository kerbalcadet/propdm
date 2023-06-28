SWEP.PrintName = "Emergency Airdrop"
SWEP.Purpose = "Be better than kerbalcadet"
SWEP.Spawnable = true
SWEP.Category = "Prop Deathmatch"
SWEP.Base = "pdm_carepkg_nade"

function SWEP:Throw(fuse, vel)
    local nade = ents.Create("proj_pdm_emergencynade")
    local own = self:GetOwner()

    nade:SetOwner(own)

    --grenade spawn position
    local aim = own:GetAimVector()
    local gpos = own:GetPos()
    local right = aim:Cross(Vector(0,0,1))
    local pos = self.Under
    and gpos + right*6 + Vector(0,0,56) 
    or gpos + right*6 + Vector(0,0,66)
    
    nade:SetPos(pos)
    nade:SetAngles(own:EyeAngles())
    nade:Spawn()
    nade.Fuse = fuse

    local phys = nade:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(own:GetVelocity() + own:GetAimVector()*vel)
    
        local angvel = self.Under and 200 or 300
        phys:SetAngleVelocity(VectorRand()*angvel)
    end

    self:Remove()
    own:SwitchLastWeapon()
end