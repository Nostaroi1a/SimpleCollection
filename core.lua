local title = "SimpleCollection"

SCOptions = {}
SimpleCollection = LibStub("AceAddon-3.0"):NewAddon(title, "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")
SCAddonOpened = false

-----------------------------------------------------------------------------------------------------
---------------------------------------------- OPTIONS ----------------------------------------------
-----------------------------------------------------------------------------------------------------


local myOptionsTable = {
    name = title,
    type = "group",
    args = {
        General = {
            order = 1,
            name = "Mount Options",
            type = "header",
            width = "full",
        },
        Faction = {
            order = 2,
            name = "Only show mounts that my faction can use",
            desc = "Mounts that your faction can't use will be hidden",
            type = "toggle",
            width = "full",
            set = function(info, val) SCOptions.faction = val; end,
            get = function(info) return SCOptions.faction; end,
        },
        Unobtainable = {
            order = 3,
            name = "Only show mounts that are obtainable",
            desc = "Mounts that are unobtainable will be hidden",
            type = "toggle",
            width = "full",
            set = function(info, val) SCOptions.obtainable = val; end,
            get = function(info) return SCOptions.obtainable; end,
        },
        Note = {
            order = 4,
            name = "Note: Changes will take effect after a reload",
            type = "description",
            width = "full",
        },
        RarityOptions = {
            order = 5,
            name = "Rarity Options",
            type = "header",
            width = "full",
        },
        Rarity = {
            order = 6,
            name = "Show Rarity data on tooltip",
            desc = "Shows the number of your attempts and the chance of getting the mount on tooltip",
            type = "toggle",
            width = "full",
            set = function(info, val) SCOptions.rarity = val; end,
            get = function(info) return SCOptions.rarity; end,
        },
        RarityUnderIcon = {
            order = 7,
            name = "Show Rarity data underneath the mount icon",
            desc = "Shows the number of your attempts and the chance of getting the mount underneath the mount icon",
            type = "toggle",
            width = "full",
            set = function(info, val) SCOptions.rarityUnderIcon = val; end,
            get = function(info) return SCOptions.rarityUnderIcon; end,
        },
        RarityNote = {
            order = 8,
            name = "Disclaimer: Only works if you have Rarity installed and a default profile",
            type = "description",
            width = "full",
        },
        RarityNote2 = {
            order = 9,
            name = "Note: Changes will take effect after a reload",
            type = "description",
            width = "full",
        },
    }
}

local myDefaultOptions = {
    ["faction"] = true,
    ["obtainable"] = true,
    ["rarity"] = true,
    ["rarityUnderIcon"] = true,
}

-----------------------------------------------------------------------------------------------------
---------------------------------------------- RARITY -----------------------------------------------
-----------------------------------------------------------------------------------------------------

function GetRarityData()
    local rarityMounts = {}

    for name, mount in pairs(Rarity.ItemDB.mounts) do
        if mount then

            local m = RarityDB["profiles"]["Default"]["groups"]["mounts"][mount.name]
            local u = RarityDB["profiles"]["Default"]["groups"]["user"][mount.name]

            if u and m then
                m = u
            end

            if m then

                if mount.spellId then

                    rarityMounts[mount.spellId] = {}

                    if name then
                        rarityMounts[mount.spellId].name = name
                    end

                    if mount.itemId then
                        rarityMounts[mount.spellId].itemId = mount.itemId
                    end

                    if m.lastAttempts then
                        rarityMounts[mount.spellId].lastAttempts = m.lastAttempts
                    end

                    if m.attempts then
                        rarityMounts[mount.spellId].attempts = m.attempts
                    end

                    if mount.chance then
                        rarityMounts[mount.spellId].chance = mount.chance
                    end
                    
                end
            end
        end
    end

    for _, category in ipairs(Decoded_data.all) do
        for _, subcat in ipairs(category.subcats) do
            for _, item in ipairs(subcat.items) do
                if item then
                    local mount = rarityMounts[item.spellid]

                    if mount then

                        local chance = 0
                        if mount.chance then
                            chance = mount.chance
                        end

                        local attempts = 0
                        local dataAttempts = mount.attempts
                        local dataLastAttempts = mount.lastAttempts

                        if dataAttempts then
                            attempts = dataAttempts
                        else
                            if dataLastAttempts then
                                attempts = dataLastAttempts
                            end
                        end

                        if SCOptions.rarity or SCOptions.rarityUnderIcon then

                            local frameItem = _G["SC_Item"..item.ID]
                            if frameItem then


                                if SCOptions.rarityUnderIcon then
                                    frameItem.title = frameItem:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                                    frameItem.title:SetPoint("BOTTOM", 0, -13)
                                    if (chance > 0 and attempts > 0) then
                                        frameItem.title:SetText(attempts.."/"..chance)
                                        frameItem.title:SetTextColor(1, 0, 0)
                                    end
                                    frameItem.title:SetScale(0.7)
                                end

                                if SCOptions.rarity then
                                    frameItem:HookScript("OnEnter", function()

                                        if (chance > 0 ) then
                                            GameTooltip:AddDoubleLine("Rarity:", attempts.." / "..chance.." attempts", 1, 0, 0, 1, 0, 0)
                                        else
                                            GameTooltip:AddDoubleLine("Rarity:", attempts.." attempts", 1, 0, 0, 1, 0, 0)
                                        end

                                        GameTooltip:Show()
                                        frameItem:SetHyperlinksEnabled(true)

                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
--DevTools_Dump(value)



-----------------------------------------------------------------------------------------------------
---------------------------------------------- EVENTS -----------------------------------------------
-----------------------------------------------------------------------------------------------------

local regEvents = {
	"ADDON_LOADED",
}

function SimpleCollection:OnInitialize()
    self:RegisterChatCommand(title, "MySlashProcessorFunc")
    self:RegisterChatCommand("sc", "MySlashProcessorFunc")

    for _, event in pairs (regEvents) do
		self:RegisterEvent(event)
	end

    LibStub("AceConfig-3.0"):RegisterOptionsTable(title, myOptionsTable)
  	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(title, title)
end

local addon_initialized = false

function SimpleCollection:ADDON_LOADED(event, ...)
    if not addon_initialized then
		addon_initialized = true

        local LibJSON = LibStub("LibJSON-1.0")

        if SCOptions.faction == nil then SCOptions.faction = myDefaultOptions.faction end
        if SCOptions.obtainable == nil then SCOptions.obtainable = myDefaultOptions.obtainable end
        if SCOptions.rarity == nil then SCOptions.rarity = myDefaultOptions.rarity end
        if SCOptions.rarityUnderIcon == nil then SCOptions.rarityUnderIcon = myDefaultOptions.rarityUnderIcon end

        CreateFrameSimpleCollection()
        SCFrame:Hide()

        Decoded_data = LibJSON.Decode(SimpleCollectionData)

        --C_Timer.After(2, function() CreateCollection(Decoded_data, "Mounts") end)
    end
end

function SimpleCollection:OnFirstLoad()
    SCAddonOpened = true
    CreateCollection(Decoded_data, "Mounts")
    SCFrame:Show();
end

function SC_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
    if SCAddonOpened then
        SimpleCollection:Toggle()
    else
        SimpleCollection:OnFirstLoad()
    end
end

function SimpleCollection:Toggle()
	if not SCFrame:IsVisible() then
		SCFrame:Show();
	else
		SCFrame:Hide();
	end
end

function SimpleCollection:MySlashProcessorFunc(input)
    if strlower(input)=="" then
        if SCAddonOpened then
            SimpleCollection:Toggle()
        else
            SimpleCollection:OnFirstLoad()
        end
    end
    if strlower(input)=="help" then
        print("|cff00CCFFSimpleCollection")
        print("|cff00CCFFCommands:")
        print("|cffFF0000/" .. title .. "|cffFFFFFF: Shows your SimpleCollection")
        print("|cffFF0000/sc|cffFFFFFF: Shows your SimpleCollection")
    end
end