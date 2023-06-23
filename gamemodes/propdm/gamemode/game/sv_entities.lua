--disable self damage
hook.Add("PlayerShouldTakeDamage", "disableselfdamage", function(ply,att)
    if not IsValid(ply) or not IsValid(att) then return end
    
    if ply == att && ply:GetActiveWeapon():GetClass() == "weapon_pdm_crowbar" then return false end
end)

--dissolve ents in lightning
local diss
function ENTITY:Dissolve(type, pos)                               
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
end