function GM:PlayerInitialSpawn(ply)
    ply:SetNW2Int("Points", 0)

    local ind = table.KeyFromValue(player.GetAll(), ply) % 4
    ply:SetTeam(ind)

    -- Manually set the Player Entity name, for use in setting the relationship with killstreak NPC(s)
    ply:SetName(ply:Nick())
end

function GM:PlayerSpawn(ply)
    ply:StripWeapons()
    ply:StripAmmo()
    ply:Give("pdm_crowbar")
    ply:Give("pdm_kirby")
    ply:Give("pdm_nade")
    ply:SetModel("models/player/hostage/hostage_04.mdl")
    --ply:SetModel("models/player/combine_super_soldier.mdl")
    ply:SetupHands()
    ply:SetWalkSpeed(200)
    ply:SetRunSpeed(400)
    
    ply:SetNW2Int("Streak", 0)

    local col = team.GetColor(ply:Team())
    --local cvec = Vector(col.r/255, col.g/255, col.b/255)
    ply:SetColor(col)

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
        net.WriteInt(PDM_ROUNDSTART, 16)
    net.Send(ply)
end)