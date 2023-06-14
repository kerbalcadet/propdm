function GM:PlayerInitialSpawn(ply)
end

--[[]
function GM:PlayerSpawn(ply)
    --ply:StripWeapons()
    --ply:StripAmmo()
    ply:Give("pdm_crowbar")
    ply:Give("pdm_kirby")
    ply:SetModel("models/player/hostage/hostage_04.mdl")
    ply:SetupHands()
end
]]--