local addonName, ns = ...

-- Create the main window (once). The collection content itself is built in
-- collection.lua the first time the window is opened.
function ns.CreateMainFrame()
    if ns.frame then return end

    local frame = CreateFrame("Frame", "SCFrame", UIParent, "SCFrameTemplate")
    frame.MainWindow:SetVertexColor(0, 0, 0, 0.95)
    frame.TitleBar:SetVertexColor(0.1, 0.1, 0.1, 0.95)
    frame:SetSize(1280, 600)
    frame:SetFrameStrata("HIGH")
    frame:SetHyperlinksEnabled(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetPoint("CENTER", UIParent, "CENTER")

    frame.close = CreateFrame("Button", "SCCloseButton", frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
    frame.close:SetScript("OnClick", function() frame:Hide() end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("CENTER", frame.TitleBar, "CENTER")
    frame.title:SetText(addonName)
    frame.title:SetTextColor(1, 1, 1)

    frame.scrollframe = CreateFrame("ScrollFrame", "SCScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.scrollchild = CreateFrame("Frame")

    local scrollbarName = frame.scrollframe:GetName()
    frame.scrollbar = _G[scrollbarName .. "ScrollBar"]
    frame.scrollupbutton = _G[scrollbarName .. "ScrollBarScrollUpButton"]
    frame.scrolldownbutton = _G[scrollbarName .. "ScrollBarScrollDownButton"]

    frame.scrollupbutton:ClearAllPoints()
    frame.scrollupbutton:SetPoint("TOPRIGHT", frame.scrollframe, "TOPRIGHT", -2, -2)
    frame.scrolldownbutton:ClearAllPoints()
    frame.scrolldownbutton:SetPoint("BOTTOMRIGHT", frame.scrollframe, "BOTTOMRIGHT", -2, -15)
    frame.scrollbar:ClearAllPoints()
    frame.scrollbar:SetPoint("TOP", frame.scrollupbutton, "BOTTOM")
    frame.scrollbar:SetPoint("BOTTOM", frame.scrolldownbutton, "TOP")

    frame.scrollframe:SetScrollChild(frame.scrollchild)
    frame.scrollframe:SetPoint("TOPLEFT", frame.MainWindow, "TOPLEFT", 0, -30)
    frame.scrollframe:SetPoint("BOTTOMRIGHT", frame.MainWindow, "BOTTOMRIGHT", 0, 20)
    -- Preliminary size; BuildCollection sets the real content height afterwards
    frame.scrollchild:SetSize(frame.scrollframe:GetWidth(), frame.scrollframe:GetHeight() * 2)

    frame.content = CreateFrame("Frame", nil, frame.scrollchild)
    frame.content:SetAllPoints(frame.scrollchild)

    -- Allow closing the window with the Escape key
    tinsert(UISpecialFrames, "SCFrame")

    ns.frame = frame
    ns.content = frame.content
end
