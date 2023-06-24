--DEFS
surface.CreateFont("Score32", { font = "CloseCaption_Bold", size = 32})
surface.CreateFont("Score24", { font = "Trebuchet24", size = 24})
surface.CreateFont("Points48", { font = "CloseCaption_Bold", size = 48})
surface.CreateFont("RoundStart", { font = "Roboto Mono", size = 80, weight = 1000})
surface.CreateFont("RoundStartSub", {font = "Roboto Mono", size = 36, weight = 1000})
surface.CreateFont("Timer", { font = "CloseCaption_Bold", size = 48})

local ScoreBoxCol = Color(255, 255, 255, 100)
local White = Color(255,255,255)

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
local YellowPts = Color(253, 240, 92)
local pts_fadestart = 1
local pts_fadetime = 1
local pts_stime = 0
local disp_points = 0

--scoreboard init
local top4 = {}
local voffset = 200  --slightly forgot that the ui still occupies the corners

--killstreak message
local YellowKS = Color(253, 240, 92)
local ks_fadein = 0.5
local ks_fadestart = 2
local ks_fadetime = 1
local ks_stime = 0
local ks_txt = ""

--round start / round end 
local GreenRS = Color(135, 240, 95)
local rs_fadein = 0.5
local rs_fadestart = 5
local rs_fadetime = 1
local rs_stime = -1000
local rs_txt = ""
local rs_sub = ""

--timer
local t_stime = -1000
local t_etime = -1000


--###### NET MESSAGES ########

net.Receive("PDM_AddPoints", function()
    disp_points = disp_points + net.ReadInt(16)
    pts_stime = CurTime()
    surface.PlaySound("buttons/button9.wav")
end)

net.Receive("PDM_ScoreUpdate", function()
    local score = net.ReadTable()
    table.sort(score, function(a,b) return a[2] > b[2] end)

    local score4 = {}

    local ply_inc = false
    local max = #score > 4 and 4 or #score
    local name = LocalPlayer():GetName()
    for i=1, math.min(#score, 4), 1 do
        if score[i][1] == name then ply_inc = true end
        score4[i] = score[i]
    end

    if ply_inc == false then
        score4[4] = {name, LocalPlayer():GetNW2Int("Points")}
    end

    top4 = score4
end)

net.Receive("PDM_RoundStart", function()
    rs_stime = CurTime()
    rs_txt = "Free For All"
    rs_sub = net.ReadInt(16).." kills to win"

    t_stime = net.ReadInt(16)
    t_etime = net.ReadInt(16)
end)

net.Receive("PDM_RoundEnd", function()
    rs_stime = CurTime()
    rs_txt = net.ReadString().." Wins!"
    rs_sub = ""
end)

--somehow the best way to do a real client init
hook.Remove("HUDPaint", "PDM_InitPlayer")
hook.Add("HUDPaint", "PDM_InitPlayer", function()
    net.Start("PDM_RequestInitDetails")
    net.SendToServer()

    hook.Remove("HUDPaint", "PDM_InitPlayer")
end)


net.Receive("PDM_Killstreak", function()
    ks_txt = net.ReadString()
    ks_stime = CurTime()
    surface.PlaySound("npc/dog/dog_playfull5.wav")
end)



--######## ACTUAL HUD RENDERING #######

local function PDMHud()
    local ply = LocalPlayer()
    if not ply:Alive() then return end

    --### POINTS INDICATOR ###
    local t = CurTime() - pts_stime

    if t < (pts_fadestart + pts_fadetime) then
        local y = YellowPts
        
        if t > pts_fadestart then
            local a = 255*(1 - (t - pts_fadestart)/pts_fadetime)
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



    --### SCOREBOARD ###

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


    --### KILLSTREAKS MESSAGES ###

    local t = CurTime() - ks_stime

    if t < (ks_fadein + ks_fadestart + ks_fadetime) then
        local y = YellowKS
        
        if t < ks_fadein then
            y.a = 255*t/ks_fadein
        elseif t > ks_fadestart then
            y.a = 255*(1 - (t - ks_fadestart)/ks_fadetime)
        else
            y.a = 255
        end

        local txt = {text = ks_txt,
        font = "Points48",
        pos = {w/2, h*1/4},
        xalign = 1,
        yalign = 1,
        color = y
        }

        draw.DrawText(txt)
        draw.TextShadow(txt, 2, y.a)

        local txt2 = {text = LocalPlayer():GetNW2Int("Streak").." Kills",
        font = "Points48",
        pos = {w/2, h*1/4 - 48 - 10},
        xalign = 1,
        yalign = 1,
        color = y
        }

        draw.DrawText(txt2)
        draw.TextShadow(txt2, 2, y.a)
    end

    --### Round Start/End ###--

    local t = CurTime() - rs_stime

    if t < (rs_fadein + rs_fadestart + rs_fadetime) then
        local c = GreenRS
        
        if t < rs_fadein then
            c.a = 220*t/rs_fadein
        elseif t > rs_fadestart then
            c.a = 220*(1 - (t - rs_fadestart)/rs_fadetime)
        else
            c.a = 220
        end

        local txt = {text = rs_txt,
        font = "RoundStart",
        pos = {w/2, h*1/4},
        xalign = 1,
        yalign = 1,
        color = c
        }

        draw.DrawText(txt)
        draw.TextShadow(txt, 5, c.a)

        txt.text = rs_sub
        txt.pos = {w/2, h/4 + 64 + 5}
        txt.font = "RoundStartSub"

        draw.DrawText(txt)
        draw.TextShadow(txt, 2, c.a)
        
    end

    --### Round Start Timer ###--

    local t = CurTime()
    if t > t_stime and t < t_etime then
        local txt = {text = math.ceil(t_etime - t),
        font = "Timer",
        pos = {w/2, h*3/8},
        xalign = 1,
        yalign = 1,
        color = White
        }

        draw.Text(txt)
    end

end

hook.Remove("HUDPaint", "PDMHud")
hook.Add("HUDPaint", "PDMHud", PDMHud)
