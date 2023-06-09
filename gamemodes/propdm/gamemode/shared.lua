GM.Name = "Prop Deathmatch"
GM.Author = "rocketpanda40"
GM.Email = "N/A"
GM.Website = "N/A"

AddCSLuaFile()

local p = 250
local s = 75

team.SetUp(0, "Unassigned", Color(255, 255, 255), false)
team.SetUp(1, "Red", Color(p, s, s), true)
team.SetUp(2, "Blue", Color(s, s, p), true)
team.SetUp(3, "Green", Color(s, p, s), true)
team.SetUp(4, "Yellow", Color(p, p, s), true)