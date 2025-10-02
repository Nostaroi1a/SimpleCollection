function CreateFrameSimpleCollection()
    -- MainFrame
    SCFrame = CreateFrame("Frame", "SCFrame", UIParent, "SCFrameTemplate");
    SCFrame.MainWindow:SetVertexColor(0,0,0,0.95)
    SCFrame.TitleBar:SetVertexColor(0.1,0.1,0.1,0.95)
    SCFrame:SetSize(1280, 600)
    SCFrame:SetFrameStrata("HIGH")
    SCFrame:SetHyperlinksEnabled(true)
    SCFrame:EnableMouse(true)
    SCFrame:SetMovable(true)
    SCFrame:RegisterForDrag("LeftButton")
	SCFrame:SetScript("OnDragStart", SCFrame.StartMoving)
	SCFrame:SetScript("OnDragStop", SCFrame.StopMovingOrSizing)

    SCFrame:SetPoint("CENTER", UIParent, "CENTER")
    --SCFrame:Show()

    -- Close Button for MainFrame
    SCFrame.close = CreateFrame("Button", "SCCloseButton", SCFrame, "UIPanelCloseButton")
    SCFrame.close:SetPoint("TOPRIGHT", SCFrame, "TOPRIGHT")
    SCFrame.close:SetScript("OnClick", function()
        SCFrame:Hide()
    end)

    -- Title for MainFrame
	SCFrame.title = SCFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	SCFrame.title:SetPoint("CENTER", SCFrame.TitleBar, "CENTER");
	SCFrame.title:SetText("SimpleCollection");
	SCFrame.title:SetTextColor(1, 1, 1)

    -- ScrollFrame for MainFrame
    SCFrame.scrollframe = CreateFrame("ScrollFrame", "ANewScrollFrame", SCFrame, "UIPanelScrollFrameTemplate");
    SCFrame.scrollchild = CreateFrame("Frame");

    local scrollbarName = SCFrame.scrollframe:GetName()
    SCFrame.scrollbar = _G[scrollbarName.."ScrollBar"];
    SCFrame.scrollupbutton = _G[scrollbarName.."ScrollBarScrollUpButton"];
    SCFrame.scrolldownbutton = _G[scrollbarName.."ScrollBarScrollDownButton"];

    SCFrame.scrollupbutton:ClearAllPoints();
    SCFrame.scrollupbutton:SetPoint("TOPRIGHT", SCFrame.scrollframe, "TOPRIGHT", -2, -2);

    SCFrame.scrolldownbutton:ClearAllPoints();
    SCFrame.scrolldownbutton:SetPoint("BOTTOMRIGHT", SCFrame.scrollframe, "BOTTOMRIGHT", -2, -15);

    SCFrame.scrollbar:ClearAllPoints();
    SCFrame.scrollbar:SetPoint("TOP", SCFrame.scrollupbutton, "BOTTOM");
    SCFrame.scrollbar:SetPoint("BOTTOM", SCFrame.scrolldownbutton, "TOP");

    SCFrame.scrollframe:SetScrollChild(SCFrame.scrollchild);

    --SCFrame.scrollframe:SetAllPoints(SCFrame.MainWindow);
    SCFrame.scrollframe:SetPoint("TOPLEFT", SCFrame.MainWindow, "TOPLEFT", 0, -30);
    SCFrame.scrollframe:SetPoint("BOTTOMRIGHT", SCFrame.MainWindow, "BOTTOMRIGHT", 0, 20);

    SCFrame.scrollchild:SetSize(SCFrame.scrollframe:GetWidth(), (SCFrame.scrollframe:GetHeight() * 2));

    SCFrame.moduleoptions = CreateFrame("Frame", nil, SCFrame.scrollchild);
    SCFrame.moduleoptions:SetAllPoints(SCFrame.scrollchild);

    tinsert(UISpecialFrames, "SCFrame")
end