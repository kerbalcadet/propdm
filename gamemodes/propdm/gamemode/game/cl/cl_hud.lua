--DEFS
surface.CreateFont("Score32", { font = "CloseCaption_Bold", size = 32})
surface.CreateFont("Score24", { font = "Trebuchet24", size = 24})
surface.CreateFont("Points48", { font = "CloseCaption_Bold", size = 48})

local ScoreBoxCol = Color(255, 255, 255, 50)
local White = Color(255,255,255)
local Yellow = Color(253, 240, 92)

local w = ScrW()
local h = ScrH()

--txt boxes

local Box32 = {
    LRMargin = 40,
    TBMargin = 30,
    BtwMargin = 5,
    Height = 60,
    Corner = 10,
    TxtLRMargin = 15,
    TxtTBMargin = 10
}

local Box24 = {
    LRMargin = 40,
    TBMargin = 30,
    BtwMargin = 5,
    Height = 40,
    Corner = 10,
    TxtLRMargin = 15,
    TxtTBMargin = 5
}

--points ui
local fadestart = 1
local fadetime = 1
local stime = 0
local disp_points = 0

--scoreboard init
local top4 = {}
local voffset = 200  --slightly forgot that the ui still occupies the corners

net.Receive("PDM_AddPoints", function()
    disp_points = disp_points + net.ReadInt(16)
    stime = CurTime()
    surface.PlaySound("weapons/ar2/ar2_reload_push.wav")
end)

net.Receive("PDM_ScoreUpdate", function()
    local score = net.ReadTable()
    table.sort(score, function(a,b) return a[2] > b[2] end)

    local score4 = {}

    local ply_inc = false
    local max = #score > 4 and 4 or #score
    local name = LocalPlayer():GetName()
    for i=1, #score, 1 do
        if score[i][1] == name then ply_inc = true end
        score4[i] = score[i]
    end

    if ply_inc == false then
        score[1] = {name, LocalPlayer():GetNW2Int("Points")}
    end

    top4 = score4
end)

hook.Remove("InitPostEntity", "PDM_RequestScore")
hook.Add("InitPostEntity", "PDM_RequestScore", function()
    net.Start("PDM_RequestScoreUpdate")
    net.SendToServer()
    print("test")
end)

local function PDMHud()
    local ply = LocalPlayer()
    if not ply:Alive() then return end

    --POINTS INDICATOR
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
    else
        disp_points = 0
    end

    --SCOREBOARD

    if #top4 > 0 then
        --top box
        surface.SetFont("Score32")
        local txt = top4[1][1]..": "..top4[1][2] 
        local txtw, txth = surface.GetTextSize(txt)

        local name = LocalPlayer():GetName()
        local b = Box32

        local col = top4[1][1] == name and Yellow or White
        col.a = 255
        local txt_tab = {text = txt,
            font = "Score32",
            pos = {(b.LRMargin + b.TxtLRMargin + txtw/2), b.TBMargin + b.Height/2 + voffset},
            xalign = 1,
            yalign = 1,
            color = col
        }

        draw.RoundedBox(b.Corner, b.LRMargin, b.TBMargin + voffset, txtw + b.TxtLRMargin*2, b.Height, ScoreBoxCol)
        draw.Text(txt_tab)
        draw.TextShadow(txt_tab, 2, 200)

        --3 boxes under
        if #top4 > 1 then
            surface.SetFont("Score24")
            for i=2, #top4, 1 do
                local ply = top4[i][1]
                local pts = top4[i][2]
                local txt = ply..": "..pts
                local txtw, txth = surface.GetTextSize(txt)
                local col = ply == name and Yellow or White
                col.a = 255

                local b = Box24
                draw.RoundedBox(b.Corner, b.LRMargin, b.TBMargin + Box32.Height + b.Height*(i-2) + b.BtwMargin*(i-1) + voffset, txtw + b.TxtLRMargin*2, b.Height, ScoreBoxCol)

                local txt_tab = {text = txt,
                font = "Score24",
                pos = {(b.LRMargin + b.TxtLRMargin + txtw/2), b.TBMargin + b.Height/2 + Box32.Height + b.Height*(i-2) + b.BtwMargin*(i-1) + voffset},
                xalign = 1,
                yalign = 1,
                color = col
                }
            
                draw.Text(txt_tab)
                draw.TextShadow(txt_tab, 2, 200)
            end
        end
    end

end

hook.Remove("HUDPaint", "PDMHud")
hook.Add("HUDPaint", "PDMHud", PDMHud)
