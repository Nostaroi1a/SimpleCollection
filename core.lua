local addonName, ns = ...

local SimpleCollection = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local defaultOptions = {
    faction = true,
    obtainable = true,
    rarity = true,
    rarityUnderIcon = true,
}

-- Update an option and rebuild the collection so the change applies immediately
local function SetOption(key, value)
    SCOptions[key] = value
    if ns.built then
        ns.BuildCollection()
    end
end

local optionsTable = {
    name = addonName,
    type = "group",
    args = {
        MountOptions = {
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
            set = function(_, value) SetOption("faction", value) end,
            get = function() return SCOptions.faction end,
        },
        Unobtainable = {
            order = 3,
            name = "Only show mounts that are obtainable",
            desc = "Mounts that are unobtainable will be hidden",
            type = "toggle",
            width = "full",
            set = function(_, value) SetOption("obtainable", value) end,
            get = function() return SCOptions.obtainable end,
        },
        RarityOptions = {
            order = 4,
            name = "Rarity Options",
            type = "header",
            width = "full",
        },
        Rarity = {
            order = 5,
            name = "Show Rarity data on tooltip",
            desc = "Shows the number of your attempts and the chance of getting the mount on tooltip",
            type = "toggle",
            width = "full",
            set = function(_, value) SetOption("rarity", value) end,
            get = function() return SCOptions.rarity end,
        },
        RarityUnderIcon = {
            order = 6,
            name = "Show Rarity data underneath the mount icon",
            desc = "Shows the number of your attempts and the chance of getting the mount underneath the mount icon",
            type = "toggle",
            width = "full",
            set = function(_, value) SetOption("rarityUnderIcon", value) end,
            get = function() return SCOptions.rarityUnderIcon end,
        },
        RarityNote = {
            order = 7,
            name = "Note: Requires the Rarity addon",
            type = "description",
            width = "full",
        },
    },
}

function SimpleCollection:OnInitialize()
    -- SavedVariables are loaded at this point; fill in defaults for missing keys
    SCOptions = SCOptions or {}
    for key, value in pairs(defaultOptions) do
        if SCOptions[key] == nil then
            SCOptions[key] = value
        end
    end

    self:RegisterChatCommand("simplecollection", "OnSlashCommand")
    self:RegisterChatCommand("sc", "OnSlashCommand")

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, optionsTable)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

    ns.CreateMainFrame()
    ns.frame:Hide()

    -- Refresh the view when a new mount is learned
    self:RegisterEvent("NEW_MOUNT_ADDED", "OnNewMountAdded")
end

function SimpleCollection:OnNewMountAdded()
    if ns.built then
        ns.BuildCollection()
    end
end

function SimpleCollection:Toggle()
    if ns.frame:IsShown() then
        ns.frame:Hide()
    else
        -- Build lazily on first open, reuse the frames afterwards
        if not ns.built then
            ns.BuildCollection()
        end
        ns.frame:Show()
    end
end

function SimpleCollection:OnSlashCommand(input)
    input = strlower(input or "")
    if input == "" then
        self:Toggle()
    elseif input == "help" then
        print("|cff00CCFF" .. addonName)
        print("|cff00CCFFCommands:")
        print("|cffFF0000/simplecollection|cffFFFFFF: Shows your SimpleCollection")
        print("|cffFF0000/sc|cffFFFFFF: Shows your SimpleCollection")
    end
end

-- Global entry point referenced by "## AddonCompartmentFunc" in the TOC
function SC_OnAddonCompartmentClick()
    SimpleCollection:Toggle()
end
