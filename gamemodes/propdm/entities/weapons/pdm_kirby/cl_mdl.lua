--[[-------------------------------------
    create model feed in the bottom right
]]---------------------------------------

local margin = {x = 40, y = 35}
local size = {x = 250, y = 150}

local w = ScrW()
local h = ScrH()
local panel = vgui.Create( "DPanel" )

panel:SetPos(w - margin.x - size.x, margin.y)
panel:SetSize(size.x, size.y)
panel:SetVisible(false)

local icon = vgui.Create( "DModelPanel", panel )

function KirbyPanelVisible(bool)
    panel:SetVisible(bool)
end

function KirbyModelVisible(bool)
    icon:SetVisible(bool)
end

function KirbyPanelModel(mdl)
    icon:SetModel(mdl)

    local ent = icon:GetEntity()
    local pos = ent:WorldSpaceCenter()
    local rad = ent:GetModelRadius() or 500
    local campos = pos + Vector(1,0,0.5)*rad*3
    
    icon:SetSize(size.x, size.y)
    icon:SetCamPos(campos)
    icon:SetLookAt(pos)
end