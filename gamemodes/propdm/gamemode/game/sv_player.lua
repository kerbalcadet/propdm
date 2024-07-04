function GM:PlayerInitialSpawn(ply)
    ply:SetNW2Int("Points", 0)

    local ind = table.KeyFromValue(player.GetAll(), ply) % 4
    ply:SetTeam(ind)

    -- Manually set the Player Entity name, for use in setting the relationship with killstreak NPC(s)
    ply:SetName(ply:Nick())
end

function GM:PlayerSpawn(ply)

    ply:SetModel("models/player/hostage/hostage_04.mdl")
    --ply:SetModel("models/player/combine_super_soldier.mdl")
    ply:SetupHands()
    ply:SetWalkSpeed(200)
    ply:SetRunSpeed(400)

    --handle collision with players
    ply:SetCustomCollisionCheck(true)

    ply:PDM_GiveDefaultWeapons()
    ply:SetNW2Int("Streak", 0)

    local col = team.GetColor(ply:Team())
    ply:SetColor(col)

    --health regen
    if PDM_HEALTHREGEN:GetInt() then
        local title = tostring(ply).."_regen"
        timer.Create(title, PDM_HEALTHREGEN_INTERVAL:GetInt(), 0, function()
        if not IsValid(ply) then
            timer.Remove(title)
            return 
        end

        local health = ply:Health()
        if health < 100 then
            ply:SetHealth(health + 1)
        end
        end)
    end

    --grenade regen
    local title = tostring(ply).."_givenade"
    timer.Create(title, 60, 0, function()
        if not IsValid(ply) then
            timer.Remove(title)
            return 
        end

        local wep = ply:GetWeapon("pdm_nade")
        if not IsValid(wep) then 
            ply:Give("pdm_nade")
            ply:EmitSound("BaseCombatCharacter.AmmoPickup")
        elseif ply:GetAmmoCount("Grenade") < 2 then
            ply:GiveAmmo(1, "Grenade", false)
    end
    end)

    --kept weapons
    if PDM_KEEPWEPS:GetInt() == 1 and ply.KeepWeps then
        for _, tab in pairs(ply.KeepWeps) do
            local newWep = ply:Give(tab.weapon, true)
            if not IsValid(newWep) then continue end

            local clip1 = math.min(tab.ammo, newWep:GetMaxClip1())
            local reserve = clip1 < tab.ammo and tab.ammo - clip1 or 0

            newWep:SetClip1(clip1)
            ply:SetAmmo(reserve, newWep:GetPrimaryAmmoType())
        end
    end
end

--keep weapons on death
local defaultweps = {"pdm_kirby", "pdm_crowbar", "pdm_gluestick"}
function PDM_KeepWeapons(ply)
    ply.KeepWeps = {}

    for _, wep in ipairs(ply:GetWeapons()) do
        local default = false
        for _, defwep in pairs(defaultweps) do
            if defwep == wep:GetClass() then
                default = true
                break
            end
        end

        if not (wep:Ammo1() + wep:Clip1() > 0) or wep.Used then continue end
        table.insert(ply.KeepWeps, {weapon = wep:GetClass(), ammo = wep:Ammo1() + wep:Clip1()})
    end
end

hook.Remove("ShouldCollide", "PDM_PlayerCollide")
hook.Add("ShouldCollide", "PDM_PlayerCollide", function(e1, e2)
    if e1:IsPlayer() and e2:IsPlayer() then return false end
end)

function PLAYER:PDM_GiveDefaultWeapons()
    self:StripWeapons()
    self:StripAmmo()
    self:Give("pdm_crowbar")
    self:Give("pdm_kirby")
    self:Give("pdm_nade")
    self:Give("pdm_gluestick")
end

function PLAYER:SwitchLastWeapon()
    local lastwep = self:GetPreviousWeapon()
    local wep = IsValid(lastwep) and lastwep or self:GetWeapons()[1]

    if wep then self:SelectWeapon(self:GetClass()) end
end

hook.Remove("PlayerDeath", "remove_nadetimer")
hook.Add("PlayerDeath", "remove_nadetimer", function(ply)
    timer.Remove(tostring(ply).."_givenade")
end)

util.AddNetworkString("PDM_AddPoints")
function PLAYER:AddPoints(num)
    local pts = self:GetNW2Int("Points")
    pts = pts + num

    self:SetNW2Int("Points", pts)
    net.Start("PDM_AddPoints")
        net.WriteInt(num, 16)
    net.Send(self)

    PDM_ScoreUpdate()
end

--update scoreboard places for players
util.AddNetworkString("PDM_ScoreUpdate")
function PDM_ScoreUpdate()
    net.Start("PDM_ScoreUpdate")
        net.WriteTable(PDM_GetScoreBoard())
    net.Broadcast()
end

--called on player spawn
util.AddNetworkString("PDM_RequestScoreUpdate")
net.Receive("PDM_RequestScoreUpdate", PDM_ScoreUpdate)

function PDM_GetScoreBoard()
    local score = {}
    for _, p in pairs(player.GetAll()) do
        table.insert(score, {p:GetName(), p:GetNW2Int("Points")})
    end

    return score
end

util.AddNetworkString("PDM_RequestInitDetails")
net.Receive("PDM_RequestInitDetails", function(len, ply)
    net.Start("PDM_ScoreUpdate")
        net.WriteTable(PDM_GetScoreBoard())
    net.Send(ply)

    net.Start("PDM_RoundStart")
        net.WriteInt(PDM_KILLGOAL:GetInt(), 16)
        net.WriteInt(CurTime(), 16)
        net.WriteInt(PDM_ROUNDSTART or 0, 16)
    net.Send(ply)
end)

--disable fall damage
hook.Remove("GetFallDamage", "PDM_DisableFallDamage")
hook.Add( "GetFallDamage", "PDM_DisableFallDamage", function()
    return 0.1
end )