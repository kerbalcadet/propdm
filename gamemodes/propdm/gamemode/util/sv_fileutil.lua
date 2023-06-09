--[[================================
    utility functions for the filesystem
]]--================================


FILE = {}

local function EntsToTable()
    local tab = {}
    for k, v in pairs(ents.GetAll()) do
        local vclass = v:GetClass()
        if(string.match(vclass, "^scrap_")) then
            local ent = {class = vclass, pos = v:GetPos(), size = v.Size}
            PrintTable(ent)
            print("###")
            table.insert(tab, ent)
        end
    end

    return tab
end


--[[================
    Lists & JSON
]]--================

function FILE:WriteList(table, path)
    local str = util.TableToJSON(table, true)
  
    file.CreateDir("scrapheap/")
    file.Write(path, str)

    print("[SCRAP] Saved list to "..path)
end

concommand.Add("scrap_savemap", function() FILE:WriteList(EntsToTable(), "scrapheap/maps/"..game.GetMap()..".txt") end)


function FILE:LoadList(path, sec)
    local tab = {}
    local sec = sec or "DATA"

    if file.Exists(path, sec) then
        tab = util.JSONToTable(file.Read(path, sec))
    end

    if #tab != 0 then return tab
    else
        return {}
    end
end



local function PropToJSON(prop, argprice)
    if !prop:IsValid() or !prop:GetPhysicsObject():IsValid() then return end

    print(util.TableToJSON({value = argprice or nil, model = prop:GetModel(), weight = prop:GetPhysicsObject():GetMass()}))
end

concommand.Add("scrap_propjson", 
    function(ply, cmd, args) PropToJSON(ply:GetEyeTrace().Entity, args[1]) end,
    nil, "Converts the entity you're looking at to a json table for the tables in /content, adding rarity and price as arguments"
)


