surface.CreateFont("Points48", { font = "CloseCaption_Bold", size = 48})

local fadestart = 1
local fadetime = 1
local stime = 0
local disp_points = 0

local Yellow = Color(253, 240, 92)


net.Receive("PDM_AddPoints", function()
    disp_points = net.ReadInt(16)
    stime = CurTime()
    surface.PlaySound("buttons/button9.wav")
end)


local function PDMHud()
    local ply = LocalPlayer()
    if not ply:Alive() then return end

    local w = ScrW()
    local h = ScrH()



    local t = CurTime() - stime

    if t < (fadestart + fadetime) then
        local y = Yellow
        
        if t > fadestart then
            local a = 255*(1 - (t - fadestart)/fadetime)
            y.a = a
        else
            y.a = 255
        end

        local points = {text = "+"..disp_points,
        font = "Points48",
        pos = {w/2, h*3/8},
        xalign = 1,
        yalign = 1,
        color = y
        }

        draw.Text(points)
        draw.TextShadow(points, 2, y.a)
    end
end

hook.Remove("HUDPaint", "PDMHud")
hook.Add("HUDPaint", "PDMHud", PDMHud)
