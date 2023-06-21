--disable self damage
hook.Add("PlayerShouldTakeDamage", "disableselfdamage", function(ply,att)
    if ply == att && ply:GetActiveWeapon():GetClass() == "weapon_pdm_crowbar" then return false end
end)

--dissolve ents in lightning
local diss
function ENTITY:Dissolve(safe, type, pos)                               
    if not IsValid(self) then return end

    local targ

    if self:IsPlayer() then
        self:Kill()
        self:CreateRagdoll()
        targ = self:GetRagdollEntity()
    else targ = self end

    if not IsValid(diss) then
        diss = ents.Create("env_entity_dissolver")
    end

    if pos then diss:SetPos(pos) end

    local t = type or 0
    diss:SetKeyValue("target", "dissolveme")
    diss:SetKeyValue("dissolvetype", t)
    targ:SetName("dissolveme")
    diss:Fire("Dissolve")


    if safe then
        timer.Create(tostring(targ).."diss", PDM_DESPTIME, 1, function()       --remove cars and such without explosion
            if IsValid(targ) then targ:Remove() end
        end)
    end
end

function PDM_SpawnHeli()
    local HSpawn = ents.FindByClass("pdm_helispawn")[1]
    local heli = ents.Create("npc_helicopter")

    heli:SetPos(HSpawn:GetPos())
    heli:SetHealth(100)
    heli:SetKeyValue("InitialSpeed", "500")
    heli:SetKeyValue("PatrolSpeed", "1000")
    heli:SetKeyValue("ignoreunseenenemies", "yes")
    --heli:AddFlags(1377028)
    heli:SetKeyValue("spawnflags", "1377028")

    heli:Spawn()
    heli:Activate()
    heli:Fire("SetTrack", "heli_patrol_1")
    heli:Fire("physdamagescale", "1")
    heli:Fire("StartPatrol")
end