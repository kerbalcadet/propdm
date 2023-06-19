function GM:PlayerInitialSpawn(ply)
    ply:SetNW2Int("Points", 0)
end

function GM:PlayerSpawn(ply)
    ply:StripWeapons()
    ply:StripAmmo()
    ply:Give("pdm_crowbar")
    ply:Give("pdm_kirby")
    ply:Give("pdm_nade")
    ply:SetModel("models/player/hostage/hostage_04.mdl")
    ply:SetupHands()
    ply:SetWalkSpeed(200)
    ply:SetRunSpeed(400)

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
        elseif ply:GetAmmoCount("Grenade") < 3 then
            ply:GiveAmmo(1, "Grenade", false)
    end
    end)
end

hook.Remove("PlayerDeath", "remove_nadetimer")
hook.Add("PlayerDeath", "remove_nadetimer", function(ply)
    timer.Remove(tostring(ply).."_givenade")
end)

util.AddNetworkString("PDM_ScoreUpdate")
util.AddNetworkString("PDM_AddPoints")
function PLAYER:AddPoints(num)
    local pts = self:GetNW2Int("Points")
    pts = pts + num

    self:SetNW2Int("Points", pts)
    net.Start("PDM_AddPoints")
        net.WriteInt(num, 16)
    net.Send(self)

    net.Start("PDM_ScoreUpdate")
        net.WriteTable(PDM_GetScoreBoard())
    net.Broadcast()
end

function PDM_GetScoreBoard()
    local score = {}
    for _, p in pairs(player.GetAll()) do
        table.insert(score, {p, p:GetNW2Int("Points")})
    end

    return score
end