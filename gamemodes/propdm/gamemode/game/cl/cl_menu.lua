local KSMenu = KSMenu or vgui.Create("DFrame")
local w = ScrW()/1920
local h = ScrH()/1080

KSMenu:SetVisible(false)
KSMenu:SetTitle("Killstreak Selection")
KSMenu:SetDraggable(false)
KSMenu:ShowCloseButton(false)
KSMenu:SetSize(w*500, h*1000)
KSMenu:SetPos(w*50, h*50)

local TextColor = Color(50,50,50)
local CheckBoxes = {}
local PDM_KSSelection = {}

--have to include this up here so it can be referenced lol
function PDM_GetKSSelection()
    PDM_KSSelection = {}
    
    for kills, tab in pairs(CheckBoxes) do
        for _, tab2 in pairs(tab) do
            if tab2.box:GetChecked() then
                PDM_KSSelection[kills] = tab2.name
                break
            end
        end
    end
end

--actual ui
for i, ks in pairs(PDM_KILLSTREAKS) do
    local posx = 40*w
    local posy = 60*h*i

    --overall button
    local btn = KSMenu:Add("DPanel")
    btn:SetSize(400*w, 40*h)
    btn:SetPos(posx, posy - 5*h)
    btn:SetText("")
    btn:SetMouseInputEnabled(true)
    

    --check box
    local cb = KSMenu:Add("DCheckBox")
    cb:SetPos(posx, posy)
    cb:SetSize(30, 30)
    
    local group = CheckBoxes[ks.kills]
    if not group then
        CheckBoxes[ks.kills] = {}
        cb:SetChecked(true)
    end    
    
    table.insert(CheckBoxes[ks.kills], {name = ks.name, box = cb})

    function btn:OnMousePressed()
        local checked = cb:GetChecked()
        cb:SetChecked(not checked)
        cb:OnChange(not checked)
    end

    function cb:OnChange(bval)
        if not bval then 
            cb:SetChecked(true)
            return 
        end

        for _, tab in pairs(CheckBoxes[ks.kills]) do
            if tab.box == cb then continue end
            
            tab.box:SetChecked(false)
        end
    
        PDM_GetKSSelection()    --update KS table
    end

    PDM_GetKSSelection()    --update table with default inputs

    --numkills
    local lbl = KSMenu:Add("DLabel")
    lbl:SetSize(500*w, 30*h)
    lbl:SetPos(80*w, posy)
    lbl:SetFont("Trebuchet24")
    lbl:SetText(ks.kills.." kills")
    lbl:SetColor(TextColor)

    --title
    local lbl2 = KSMenu:Add("DLabel")
    lbl2:SetSize(500*w, 30*h)
    lbl2:SetFont("Trebuchet24")
    lbl2:SetText(ks.name)
    lbl2:SetColor(TextColor)

    local width, _ = lbl2:GetTextSize()
    lbl2:SetPos(430*w - width, posy)

end

net.Receive("PDM_KS_Check", function()
    local streak = net.ReadInt(8)
    if not streak then return end

    if PDM_KSSelection[streak] then
        net.Start("PDM_KS_Request")
            net.WriteString(PDM_KSSelection[streak])
        net.SendToServer()
    end
end)

hook.Remove("ScoreboardShow", "KillstreakMenu")
hook.Add("ScoreboardShow", "KillstreakMenu", function()
    if not IsValid(KSMenu) then return end
    KSMenu:SetVisible(true)
end)

hook.Remove("ScoreboardHide", "KillstreakMenu")
hook.Add("ScoreboardHide", "KillstreakMenu", function()
    if not IsValid(KSMenu) then return end
    KSMenu:SetVisible(false)
end)