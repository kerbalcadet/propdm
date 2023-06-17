function RoundStart()

    for _, p in pairs(player.GetAll()) do
        p:Spawn()
        gamemode.Call("PlayerInitialSpawn", p)
        gamemode.Call("PlayerSpawn", p)
    end
end

util.AddNetworkString("PDM_Points")
