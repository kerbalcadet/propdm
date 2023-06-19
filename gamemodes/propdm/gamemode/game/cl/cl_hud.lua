--DEFS
surface.CreateFont("Score32", { font = "CloseCaption_Bold", size = 32})
surface.CreateFont("Score24", { font = "Trebuchet24", size = 24})
surface.CreateFont("Points48", { font = "CloseCaption_Bold", size = 48})

local ScoreBoxCol = Color(200, 200, 200, 150)
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



net.Receive("PDM_AddPoints", function()
    disp_points = disp_points + net.ReadInt(16)
    stime = CurTime()
    surface.PlaySound("buttons/button9.wav")
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

    local top4 = {{"rocketpanda40", 20}, {"testp1", 10}, {"testp2", 10}, {"thirdguy", 0}}

    --overall box

    local b = BigBox
    --draw.RoundedBox(b.Corner, b.LRMargin, b.TBMargin, 300, Box32.TBMargin + Box32.BtwMargin*3 + Box32.Height + Box24.Height*3, BigScoreBox)

    --top box
    surface.SetFont("Score32")
    local txt = top4[1][1]..": "..top4[1][2] 
    local txtw, txth = surface.GetTextSize(txt)

    local b = Box32

    local txt_tab = {text = txt,
        font = "Score32",
        pos = {b.LRMargin + b.TxtLRMargin + txtw/2, b.TBMargin + b.Height/2},
        xalign = 1,
        yalign = 1,
        color = White
    }

    draw.RoundedBox(b.Corner, b.LRMargin, b.TBMargin, txtw + b.TxtLRMargin*2, b.Height, ScoreBoxCol)
    draw.Text(txt_tab)
    draw.TextShadow(txt_tab, 2, 200)

    --3 boxes under
    surface.SetFont("Score24")
    for i=2, #top4, 1 do
        local ply = top4[i][1]
        local pts = top4[i][2]
        local txt = ply..": "..pts
        local txtw, txth = surface.GetTextSize(txt)
        local col = ply == LocalPlayer():GetName() and Yellow or White
        
        local b = Box24
        draw.RoundedBox(b.Corner, b.LRMargin, b.TBMargin + Box32.Height + b.Height*(i-2) + b.BtwMargin*(i-1), txtw + b.TxtLRMargin*2, b.Height, ScoreBoxCol)

        local txt_tab = {text = txt,
        font = "Score24",
        pos = {b.LRMargin + b.TxtLRMargin + txtw/2, b.TBMargin + b.Height/2 + Box32.Height + b.Height*(i-2) + b.BtwMargin*(i-1)},
        xalign = 1,
        yalign = 1,
        color = col
        }
    
        draw.Text(txt_tab)
        draw.TextShadow(txt_tab, 2, 200)
    end

end

hook.Remove("HUDPaint", "PDMHud")
hook.Add("HUDPaint", "PDMHud", PDMHud)
