-- Get the faction of the player 
local playerFaction = UnitFactionGroup("player")
if (playerFaction == "Alliance") then playerFaction = "A" else playerFaction = "H" end

-- Define some constants for the frames
local frameLength = 1250
local frameFirstCategoryPositionX = 30
local frameFirstCategoryPositionY = -30
local frameCategoryDistanceY = 140
local frameFirstSubCategoryPositionY = -40
local frameSubCategoryDistanceY = 70
local frameItemHeight = 40
local frameItemWidth = 40

-- Initialize some variables
local firstCategory = true
local firstSubCategory = true
local countItemInSubCategory = 0
local countCategory = 1
local countSubCategory = 0
local categoryPreviousLengthYCumulated = 0
local countItemCollected = 0
local countItemAll = 0

function CreateCollection(decoded_data, collectionType)

    for _, category in ipairs(decoded_data.all) do

        --------------------------------------------
        ----------------- CATEGORY -----------------
        --------------------------------------------

        if (collectionType == "Mounts" and category.name == "Mounts") then
            category.name = "General"
        end

        -- Create a frame for the category
        local categoryFrame = CreateFrame("Frame", nil, SCFrame.moduleoptions, "BackdropTemplate");
        categoryFrame:SetWidth(1);
        categoryFrame:SetHeight(1);

        -- If this is the first category, set its position to the first category position
        -- Otherwise, set its position relative to the previous category
        if (firstCategory) then
            categoryFrame:SetPoint("TOPLEFT", SCFrame.moduleoptions, "TOPLEFT", frameFirstCategoryPositionX, frameFirstCategoryPositionY);
            categoryPreviousLengthYCumulated = frameFirstCategoryPositionY
            firstCategory = false
        else
            categoryPreviousLengthYCumulated = categoryPreviousLengthYCumulated - frameCategoryDistanceY
            categoryFrame:SetPoint("TOPLEFT", SCFrame.moduleoptions, "TOPLEFT", frameFirstCategoryPositionX, categoryPreviousLengthYCumulated);
        end

        -- Create a title for the category
        categoryFrame.title = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        categoryFrame.title:SetPoint("TOPLEFT", 0, 0)
        categoryFrame.title:SetText(category.name)
        categoryFrame.title:SetScale(2)


        countCategory = countCategory + 1

        -- Initialize some variables for the subcategories
        local subCategoryPreviousLength = 0
        local subCategoryPreviousLengthCumulated = 0
        local subCategoryPreviousLengthCumulatedY = -40
        local countCollectedInSubcategory = 0
        local countItemInCategory = 0

        firstSubCategory = true


        for _, subcat in ipairs(category.subcats) do

            --------------------------------------------
            --------------- SUBCATEGORY ----------------
            --------------------------------------------

            -- Create a frame for the subcategory
            local subCategoryFrame = CreateFrame("Frame", nil, categoryFrame, "BackdropTemplate");
            subCategoryFrame.title = subCategoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            subCategoryFrame.title:SetPoint("TOPLEFT", 0, 0)
            subCategoryFrame.title:SetText(subcat.name)
            subCategoryFrame:SetWidth(subCategoryFrame.title:GetWidth());
            subCategoryFrame:SetHeight(frameItemHeight + 10);

            -- If this is the first subcategory, set its position to the first subcategory position
            -- Otherwise, set its position relative to the previous subcategory
            if (firstSubCategory) then
                subCategoryFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 0, frameFirstSubCategoryPositionY);
                firstSubCategory = false
            else
                subCategoryFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", subCategoryPreviousLengthCumulated, subCategoryPreviousLengthCumulatedY);
            end


            subCategoryPreviousLength = subCategoryFrame.title:GetWidth()


            countSubCategory = countSubCategory + 1
            countItemInSubCategory = 0

            -- Initialize some variables for the items
            local frameItemLengthCumulated = 0
            local frameItemLengthY = -5


            for _, item in ipairs(subcat.items) do

                --------------------------------------------
                ------------------ ITEMS -------------------
                --------------------------------------------

                -- Get the item's properties
                local spellID
                local icon
                local isCollected

                if (collectionType == "Mounts") then
                    _, spellID, icon, _, _, _, _, _, _, _, isCollected, _, _ = C_MountJournal.GetMountInfoByID(item.ID)
                end

                -- If the item is obtainable and either has no faction or matches the player's faction, get the item
                if (SCOptions.faction) then
                    if (SCOptions.obtainable) then
                        if ((not item.notObtainable or isCollected) and (item.side == nil or item.side == playerFaction)) then
                            countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated = GetItem(category.name, collectionType, item, icon, spellID, isCollected, subCategoryFrame, countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated)
                            countItemInSubCategory = countItemInSubCategory + 1
                            countItemInCategory = countItemInCategory + 1
                        end
                    else
                        if ((item.side == nil or item.side == playerFaction)) then
                            countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated = GetItem(category.name, collectionType, item, icon, spellID, isCollected, subCategoryFrame, countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated)
                            countItemInSubCategory = countItemInSubCategory + 1
                            countItemInCategory = countItemInCategory + 1
                        end
                    end
                else
                    if (SCOptions.obtainable) then
                        if (not item.notObtainable or isCollected) then
                            countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated = GetItem(category.name, collectionType, item, icon, spellID, isCollected, subCategoryFrame, countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated)
                            countItemInSubCategory = countItemInSubCategory + 1
                            countItemInCategory = countItemInCategory + 1
                        end
                    else
                        countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated= GetItem(category.name, collectionType, item, icon, spellID, isCollected, subCategoryFrame, countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated)
                        countItemInSubCategory = countItemInSubCategory + 1
                        countItemInCategory = countItemInCategory + 1
                    end
                end

                -- If the subcategory frame is too wide, move it to a new line
                if (subCategoryPreviousLengthCumulated > frameLength or (subCategoryPreviousLengthCumulated + countItemInSubCategory * frameItemWidth + 20) > frameLength) then
                    subCategoryPreviousLengthCumulated = 0
                    subCategoryPreviousLengthCumulatedY = subCategoryPreviousLengthCumulatedY - frameSubCategoryDistanceY
                    categoryPreviousLengthYCumulated = categoryPreviousLengthYCumulated - frameSubCategoryDistanceY
                    subCategoryFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", subCategoryPreviousLengthCumulated, subCategoryPreviousLengthCumulatedY);
                end
            end

            -- If there are no items in the subcategory, hide the subcategory frame
            if (countItemInSubCategory == 0) then
                subCategoryFrame:Hide()
            else
                -- If the width of the items is greater than the width of the subcategory frame, increase the width of the subcategory frame
                -- Otherwise, increase the width of the subcategory frame by the width of the subcategory title
                if (countItemInSubCategory > 1 and (countItemInSubCategory * frameItemWidth) > subCategoryPreviousLength) then
                    subCategoryPreviousLengthCumulated = subCategoryPreviousLengthCumulated + countItemInSubCategory * frameItemWidth + 20
                else
                    subCategoryPreviousLengthCumulated = subCategoryPreviousLengthCumulated + subCategoryPreviousLength + 20
                end
            end
        end

        -- Create a counter for the category title
        categoryFrame.titleCounter = categoryFrame:CreateFontString("SC_categoryFrameTitleCounter"..category.name, "OVERLAY", "GameFontHighlight")
        categoryFrame.titleCounter:SetPoint("LEFT", categoryFrame.title, "RIGHT", 5, 0)
        categoryFrame.titleCounter:SetText("("..countCollectedInSubcategory.."/"..countItemInCategory..")")
        categoryFrame.titleCounter:SetTextColor(0.5,0.5,0.5,1)

        -- Update the total item count and collected item count
        countItemAll = countItemAll + countItemInCategory
        countItemCollected = countItemCollected + countCollectedInSubcategory
        countSubCategory = 0
    end

    -- Create a status bar for the collection
    local statusBar = CreateFrame("StatusBar", "SC_statusBarItem", SCFrame.moduleoptions)
    statusBar:SetPoint("TOPRIGHT", -50, -30)
    statusBar:SetSize(200, 20)
    statusBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    statusBar:SetStatusBarColor(0.25, 0.25, 0.25)
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(100)

    -- Create a status bar for the collected items
    local statusBarItemCollected = CreateFrame("StatusBar", "SC_statusBarItemCollected", SCFrame.moduleoptions)
    statusBarItemCollected:SetPoint("TOPRIGHT", -50, -30)
    statusBarItemCollected:SetSize(200, 20)
    statusBarItemCollected:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    statusBarItemCollected:SetStatusBarColor(1, 1, 1, 0.25)
    statusBarItemCollected:SetMinMaxValues(0, 100)
    statusBarItemCollected:SetValue(countItemCollected / countItemAll * 100)

    -- Set the text for the status bar and its properties
    statusBar.text = statusBar:CreateFontString("SC_statusBarItemCollectedText", "OVERLAY", "GameFontHighlight")
    statusBar.text:SetPoint("CENTER", statusBar)
    statusBar.text:SetText(countItemCollected.." / "..countItemAll.." ("..string.format("%.0f %%", countItemCollected / countItemAll * 100)..")")
    statusBar.text:SetTextColor(1, 1, 1)


    -- Set Rarity data if the addon is loaded
    if SCOptions.rarity or SCOptions.rarityUnderIcon then
        local loadedOrLoading, loaded = C_AddOns.IsAddOnLoaded("Rarity")
        if loadedOrLoading then
            GetRarityData()
        elseif loaded then
            GetRarityData()
        end
    end
end

-- Make the Item frame grayscale if it is not collected
function SetDesaturation(texture, desaturation)
    local shaderSupported = texture:SetDesaturated(desaturation);
    if (not shaderSupported) then
        if (desaturation) then
            texture:SetVertexColor(0.5, 0.5, 0.5);
        else
            texture:SetVertexColor(1.0, 1.0, 1.0);
        end
    else
        texture:SetDesaturated(1)
    end
end


-- Function to get an item and its properties
function GetItem(categoryName, collectionType, item, icon, spellID, isCollected, subCategoryFrame, countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated)
    local frame = CreateFrame("Button", "SC_Item"..item.ID, subCategoryFrame, "BackdropTemplate");
    frame:SetWidth(frameItemWidth);
    frame:SetHeight(frameItemHeight);

    frame.tex = frame:CreateTexture()
    frame.tex:SetSize(frameItemWidth, frameItemHeight)
    frame.tex:SetPoint("LEFT")
    frame.tex:SetTexture(icon)

    -- Set greyscale if item is not collected
    if (isCollected) then
        SetDesaturation(frame.tex, nil)
        countCollectedInSubcategory = countCollectedInSubcategory + 1
    else
        SetDesaturation(frame.tex, 1)
    end

    -- If the item frame is too wide, move it to a new line and adjust the position of the subcategory & category frame
    if (frameItemLengthCumulated > frameLength - 100) then
        frameItemLengthCumulated = 0
        countItemInSubCategory = 0
        frameItemLengthY = frameItemLengthY * 2 - frameSubCategoryDistanceY - frameItemLengthY
        subCategoryPreviousLengthCumulatedY = subCategoryPreviousLengthCumulatedY - frameSubCategoryDistanceY
        categoryPreviousLengthYCumulated = categoryPreviousLengthYCumulated - frameSubCategoryDistanceY
    end

    frameItemLengthCumulated = 40 * countItemInSubCategory
    frame:SetPoint("BOTTOMLEFT", subCategoryFrame, "BOTTOMLEFT", frameItemLengthCumulated, frameItemLengthY);

    -- Set tooltip display when the frame is hovered over
    frame:HookScript("OnEnter", function()
        if (spellID) then
            GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")

            local source
            if (collectionType == "Mounts") then
                _, _, source, _, _, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(item.ID)
            end

            if item.itemId then
                GameTooltip:SetItemByID(item.itemId)
            else
                GameTooltip:SetSpellByID(spellID)
            end

            GameTooltip:AddLine(source)
            GameTooltip:Show()
            frame:SetHyperlinksEnabled(true)
        end
    end)

    frame:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame:HookScript("OnClick", function()
        if (IsShiftKeyDown()) then
            if (item.itemId) then
                local _, link = C_Item.GetItemInfo(item.itemId)
                if (link) then
                    ChatEdit_InsertLink(link)
                end
            elseif (spellID) then
                local link = GetSpellLink(spellID)
                if (link) then
                    ChatEdit_InsertLink(link)
                end
            end
        end
    end)

    return countCollectedInSubcategory, frameItemLengthCumulated, countItemInSubCategory, frameItemLengthY, subCategoryPreviousLengthCumulatedY, categoryPreviousLengthYCumulated
end
