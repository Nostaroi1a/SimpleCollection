local addonName, ns = ...

-- Layout constants (sizes in UI units)
local CONTENT_WIDTH = 1250
local CONTENT_LEFT = 30
local CONTENT_TOP = -30
local ITEM_SIZE = 40
local SUBCAT_TITLE_HEIGHT = 20
local SUBCAT_SPACING_X = 20
local SUBCAT_SPACING_Y = 30
local CATEGORY_TITLE_HEIGHT = 40
local CATEGORY_SPACING = 60
local MAX_ITEMS_PER_ROW = math.floor(CONTENT_WIDTH / ITEM_SIZE)

-- Frame caches: all frames are recycled through simple pools across rebuilds.
-- Item buttons are pooled per occurrence (NOT keyed by mount ID) because the
-- SimpleArmory data lists some mounts in more than one category.
local buttonPool, activeButtons = {}, {}
local categoryPool, activeCategories = {}, {}
local subcatPool, activeSubcats = {}, {}

local rarityBySpellID

---------------------------------------------------------------------------
-- Rarity integration
---------------------------------------------------------------------------

-- Resolve the Rarity profile that is active for this character instead of
-- assuming the "Default" profile.
local function GetActiveRarityProfile()
    if type(RarityDB) ~= "table" or type(RarityDB.profiles) ~= "table" then
        return nil
    end
    local profileName = "Default"
    if type(RarityDB.profileKeys) == "table" then
        profileName = RarityDB.profileKeys[UnitName("player") .. " - " .. GetRealmName()] or profileName
    end
    return RarityDB.profiles[profileName]
end

-- Build a spellID -> { attempts, chance } map from the Rarity addon, if present.
local function BuildRarityData()
    if not (SCOptions.rarity or SCOptions.rarityUnderIcon) then return nil end
    if not C_AddOns.IsAddOnLoaded("Rarity") then return nil end
    if not (Rarity and Rarity.ItemDB and Rarity.ItemDB.mounts) then return nil end

    local profile = GetActiveRarityProfile()
    local groups = profile and profile.groups
    if type(groups) ~= "table" then return nil end

    local map = {}
    for _, mount in pairs(Rarity.ItemDB.mounts) do
        if type(mount) == "table" and mount.spellId and mount.name then
            -- Prefer user-tracked entries over the predefined mount group
            local tracked = (groups.user and groups.user[mount.name]) or (groups.mounts and groups.mounts[mount.name])
            if type(tracked) == "table" then
                map[mount.spellId] = {
                    attempts = tracked.attempts or tracked.lastAttempts or 0,
                    chance = mount.chance,
                }
            end
        end
    end
    return map
end

---------------------------------------------------------------------------
-- Item filtering
---------------------------------------------------------------------------

local function GetPlayerFactionTag()
    local faction = UnitFactionGroup("player")
    if faction == "Alliance" then return "A" end
    if faction == "Horde" then return "H" end
    return nil -- neutral characters see both factions
end

local function IsItemShown(item, isCollected, factionTag)
    if SCOptions.faction and factionTag and item.side and item.side ~= factionTag then
        return false
    end
    if SCOptions.obtainable and item.notObtainable and not isCollected then
        return false
    end
    return true
end

---------------------------------------------------------------------------
-- Item buttons
---------------------------------------------------------------------------

-- Gray out icons of mounts that are not collected yet
local function SetCollectedLook(texture, isCollected)
    texture:SetDesaturated(not isCollected)
    if isCollected then
        texture:SetVertexColor(1, 1, 1)
    else
        texture:SetVertexColor(0.6, 0.6, 0.6)
    end
end

local function ItemButton_OnEnter(self)
    if not self.spellID then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    if self.item.itemId then
        GameTooltip:SetItemByID(self.item.itemId)
    else
        GameTooltip:SetSpellByID(self.spellID)
    end
    local source = select(3, C_MountJournal.GetMountInfoExtraByID(self.item.ID))
    if source then
        GameTooltip:AddLine(source)
    end
    if SCOptions.rarity then
        local rarity = rarityBySpellID and rarityBySpellID[self.item.spellid]
        if rarity then
            local attempts = rarity.attempts or 0
            if rarity.chance and rarity.chance > 0 then
                GameTooltip:AddDoubleLine("Rarity:", attempts .. " / " .. rarity.chance .. " attempts", 1, 0, 0, 1, 0, 0)
            else
                GameTooltip:AddDoubleLine("Rarity:", attempts .. " attempts", 1, 0, 0, 1, 0, 0)
            end
        end
    end
    GameTooltip:Show()
end

local function ItemButton_OnClick(self)
    if not IsShiftKeyDown() then return end
    local link
    if self.item.itemId then
        link = select(2, C_Item.GetItemInfo(self.item.itemId))
    elseif self.spellID then
        link = C_Spell.GetSpellLink(self.spellID)
    end
    if link then
        ChatEdit_InsertLink(link)
    end
end

local function AcquireItemButton(parent, entry)
    local button = table.remove(buttonPool)
    if not button then
        button = CreateFrame("Button", nil, parent)
        button:SetSize(ITEM_SIZE, ITEM_SIZE)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        button.rarityText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        button.rarityText:SetPoint("BOTTOM", 0, -13)
        button.rarityText:SetScale(0.7)
        button.rarityText:SetTextColor(1, 0, 0)
        button:SetScript("OnEnter", ItemButton_OnEnter)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetScript("OnClick", ItemButton_OnClick)
    end
    activeButtons[#activeButtons + 1] = button

    button:SetParent(parent)
    button:ClearAllPoints()
    button:Show()
    button.item = entry.item
    button.spellID = entry.spellID
    button.icon:SetTexture(entry.icon)
    SetCollectedLook(button.icon, entry.isCollected)

    button.rarityText:SetText("")
    if SCOptions.rarityUnderIcon then
        local rarity = rarityBySpellID and rarityBySpellID[entry.item.spellid]
        if rarity and rarity.chance and rarity.chance > 0 and (rarity.attempts or 0) > 0 then
            button.rarityText:SetText(rarity.attempts .. "/" .. rarity.chance)
        end
    end

    return button
end

---------------------------------------------------------------------------
-- Category / subcategory frame pools
---------------------------------------------------------------------------

local function AcquirePooled(pool, active, create, parent)
    local frame = table.remove(pool) or create()
    frame:SetParent(parent)
    frame:ClearAllPoints()
    frame:Show()
    active[#active + 1] = frame
    return frame
end

local function CreateCategoryFrame()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOPLEFT", 0, 0)
    frame.title:SetScale(2)
    frame.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.counter:SetPoint("LEFT", frame.title, "RIGHT", 5, 0)
    frame.counter:SetTextColor(0.5, 0.5, 0.5, 1)
    return frame
end

local function CreateSubcatFrame()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOPLEFT", 0, 0)
    return frame
end

local function ReleaseAllFrames()
    for i = #activeSubcats, 1, -1 do
        local frame = activeSubcats[i]
        frame:Hide()
        frame:ClearAllPoints()
        subcatPool[#subcatPool + 1] = frame
        activeSubcats[i] = nil
    end
    for i = #activeCategories, 1, -1 do
        local frame = activeCategories[i]
        frame:Hide()
        frame:ClearAllPoints()
        categoryPool[#categoryPool + 1] = frame
        activeCategories[i] = nil
    end
    for i = #activeButtons, 1, -1 do
        local button = activeButtons[i]
        button:Hide()
        button:ClearAllPoints()
        buttonPool[#buttonPool + 1] = button
        activeButtons[i] = nil
    end
end

---------------------------------------------------------------------------
-- Collection rendering
---------------------------------------------------------------------------

local function UpdateProgressBar(content, collected, total)
    if not ns.progressBar then
        local bar = CreateFrame("StatusBar", "SC_ProgressBar", content)
        bar:SetPoint("TOPRIGHT", -50, -30)
        bar:SetSize(200, 20)
        bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
        bar:SetStatusBarColor(0.25, 0.25, 0.25)
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(100)

        local fill = CreateFrame("StatusBar", nil, content)
        fill:SetPoint("TOPRIGHT", -50, -30)
        fill:SetSize(200, 20)
        fill:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
        fill:SetStatusBarColor(1, 1, 1, 0.25)
        fill:SetMinMaxValues(0, 100)

        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        bar.text:SetPoint("CENTER", bar)
        bar.text:SetTextColor(1, 1, 1)

        bar.fill = fill
        ns.progressBar = bar
    end
    local percent = total > 0 and (collected / total * 100) or 0
    ns.progressBar.fill:SetValue(percent)
    ns.progressBar.text:SetText(string.format("%d / %d (%.0f %%)", collected, total, percent))
end

-- Build (or rebuild) the whole collection view. Safe to call repeatedly:
-- frames are pooled and item buttons are reused.
function ns.BuildCollection()
    local content = ns.content
    local factionTag = GetPlayerFactionTag()
    rarityBySpellID = BuildRarityData()

    ReleaseAllFrames()

    local totalShown, totalCollected = 0, 0
    local contentY = CONTENT_TOP

    for _, category in ipairs(SimpleCollectionData) do
        local categoryFrame = AcquirePooled(categoryPool, activeCategories, CreateCategoryFrame, content)
        categoryFrame:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_LEFT, contentY)
        categoryFrame.title:SetText(category.name == "Mounts" and "General" or category.name)

        local categoryShown, categoryCollected = 0, 0
        local x = 0
        local rowY = -CATEGORY_TITLE_HEIGHT
        local rowHeight = 0

        for _, subcat in ipairs(category.subcats or {}) do
            -- Resolve journal info and apply filters before creating any frames
            local shown = {}
            for _, item in ipairs(subcat.items or {}) do
                local _, spellID, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(item.ID)
                -- Skip mounts the client does not know yet (future patch content);
                -- they would render as invisible placeholder buttons otherwise
                if spellID and IsItemShown(item, isCollected, factionTag) then
                    shown[#shown + 1] = { item = item, spellID = spellID, icon = icon, isCollected = isCollected }
                end
            end

            if #shown > 0 then
                local subcatFrame = AcquirePooled(subcatPool, activeSubcats, CreateSubcatFrame, categoryFrame)
                subcatFrame.title:SetText(subcat.name)

                local itemsPerRow = math.min(#shown, MAX_ITEMS_PER_ROW)
                local rows = math.ceil(#shown / MAX_ITEMS_PER_ROW)
                local blockWidth = math.max(subcatFrame.title:GetStringWidth(), itemsPerRow * ITEM_SIZE)
                local blockHeight = SUBCAT_TITLE_HEIGHT + rows * ITEM_SIZE
                subcatFrame:SetSize(blockWidth, blockHeight)

                -- Wrap to the next row when the block does not fit anymore
                if x > 0 and x + blockWidth > CONTENT_WIDTH then
                    x = 0
                    rowY = rowY - rowHeight - SUBCAT_SPACING_Y
                    rowHeight = 0
                end
                subcatFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", x, rowY)
                x = x + blockWidth + SUBCAT_SPACING_X
                rowHeight = math.max(rowHeight, blockHeight)

                for index, entry in ipairs(shown) do
                    local column = (index - 1) % MAX_ITEMS_PER_ROW
                    local row = math.floor((index - 1) / MAX_ITEMS_PER_ROW)
                    local button = AcquireItemButton(subcatFrame, entry)
                    button:SetPoint("TOPLEFT", subcatFrame, "TOPLEFT", column * ITEM_SIZE, -(SUBCAT_TITLE_HEIGHT + row * ITEM_SIZE))
                    if entry.isCollected then
                        categoryCollected = categoryCollected + 1
                    end
                end
                categoryShown = categoryShown + #shown
            end
        end

        categoryFrame.counter:SetText("(" .. categoryCollected .. "/" .. categoryShown .. ")")
        local categoryHeight = -rowY + rowHeight
        categoryFrame:SetSize(CONTENT_WIDTH, categoryHeight)
        contentY = contentY - categoryHeight - CATEGORY_SPACING

        totalShown = totalShown + categoryShown
        totalCollected = totalCollected + categoryCollected
    end

    UpdateProgressBar(content, totalCollected, totalShown)

    -- Size the scroll child to the real content height so scrolling reaches the end
    ns.frame.scrollchild:SetHeight(-contentY + 50)

    ns.built = true
end
