--[[================================
    utility functions for the filesystem
]]--================================


FILE = {}

--[[================
    Lists & JSON
]]--================

function FILE:LoadList(path, sec)
    local tab = {}
    local sec = sec or "DATA"

    if file.Exists(path, sec) then
        tab = util.KeyValuesToTable(file.Read(path, sec))
    end
    
    return tab
end

