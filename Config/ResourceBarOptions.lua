local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local L = ns.L or LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME, true) or {}
local LSM = LibStub("LibSharedMedia-3.0")
local buildVersion = select(4, GetBuildInfo())

local BAR_ASSIGNMENT_VALUES = {
    primary = "Bar 1 (Primary)",
    secondary = "Bar 2 (Secondary)",
    hide = "Hide",
}

local CLASS_ORDER = {
    "DEATHKNIGHT",
    "DEMONHUNTER",
    "DRUID",
    "EVOKER",
    "HUNTER",
    "MAGE",
    "MONK",
    "PALADIN",
    "PRIEST",
    "ROGUE",
    "SHAMAN",
    "WARLOCK",
    "WARRIOR",
}

local POWER_TYPE_LABELS = {
    [Enum.PowerType.Mana] = "Mana",
    [Enum.PowerType.Rage] = "Rage",
    [Enum.PowerType.Focus] = "Focus",
    [Enum.PowerType.Energy] = "Energy",
    [Enum.PowerType.ComboPoints] = "Combo Points",
    [Enum.PowerType.Runes] = "Runes",
    [Enum.PowerType.RunicPower] = "Runic Power",
    [Enum.PowerType.SoulShards] = "Soul Shards",
    [Enum.PowerType.LunarPower] = "Astral Power",
    [Enum.PowerType.HolyPower] = "Holy Power",
    [Enum.PowerType.Maelstrom] = "Maelstrom",
    [Enum.PowerType.Chi] = "Chi",
    [Enum.PowerType.Insanity] = "Insanity",
    [Enum.PowerType.ArcaneCharges] = "Arcane Charges",
    [Enum.PowerType.Fury] = "Fury",
    [Enum.PowerType.Pain] = "Pain",
    [Enum.PowerType.Essence] = "Essence",
    ["SOUL"] = "Soul Fragments",
    ["STAGGER"] = "Stagger",
    ["MAELSTROM_WEAPON"] = "Maelstrom Weapon",
}

local CLASS_SPEC_RESOURCES = {
    DEATHKNIGHT = {
        [250] = { primary = { Enum.PowerType.RunicPower }, secondary = { Enum.PowerType.Runes } }, -- Blood
        [251] = { primary = { Enum.PowerType.RunicPower }, secondary = { Enum.PowerType.Runes } }, -- Frost
        [252] = { primary = { Enum.PowerType.RunicPower }, secondary = { Enum.PowerType.Runes } }, -- Unholy
    },
    DEMONHUNTER = {
        [577]  = { primary = { Enum.PowerType.Fury }, secondary = {} }, -- Havoc
        [581]  = { primary = { Enum.PowerType.Fury }, secondary = { "SOUL" } }, -- Vengeance
        [1480] = { primary = { Enum.PowerType.Fury }, secondary = { "SOUL" } }, -- Devourer (Aldrachi Reaver)
    },
    DRUID = {
        [102] = { primary = { Enum.PowerType.LunarPower }, secondary = { Enum.PowerType.Mana } }, -- Balance
        [103] = { primary = { Enum.PowerType.Energy }, secondary = { Enum.PowerType.ComboPoints } }, -- Feral
        [104] = { primary = { Enum.PowerType.Rage }, secondary = {} }, -- Guardian
        [105] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.ComboPoints } }, -- Restoration (Cat form)
    },
    EVOKER = {
        [1467] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.Essence } }, -- Devastation
        [1468] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.Essence } }, -- Preservation
        [1473] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.Essence } }, -- Augmentation
    },
    HUNTER = {
        [253] = { primary = { Enum.PowerType.Focus }, secondary = {} }, -- Beast Mastery
        [254] = { primary = { Enum.PowerType.Focus }, secondary = {} }, -- Marksmanship
        [255] = { primary = { Enum.PowerType.Focus }, secondary = {} }, -- Survival
    },
    MAGE = {
        [62] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.ArcaneCharges } }, -- Arcane
        [63] = { primary = { Enum.PowerType.Mana }, secondary = {} }, -- Fire
        [64] = { primary = { Enum.PowerType.Mana }, secondary = {} }, -- Frost
    },
    MONK = {
        [268] = { primary = { Enum.PowerType.Energy }, secondary = { "STAGGER" } }, -- Brewmaster
        [269] = { primary = { Enum.PowerType.Energy }, secondary = { Enum.PowerType.Chi } }, -- Windwalker
        [270] = { primary = { Enum.PowerType.Mana }, secondary = {} }, -- Mistweaver
    },
    PALADIN = {
        [65] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.HolyPower } }, -- Holy
        [66] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.HolyPower } }, -- Protection
        [70] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.HolyPower } }, -- Retribution
    },
    PRIEST = {
        [256] = { primary = { Enum.PowerType.Mana }, secondary = {} }, -- Discipline
        [257] = { primary = { Enum.PowerType.Mana }, secondary = {} }, -- Holy
        [258] = { primary = { Enum.PowerType.Insanity }, secondary = { Enum.PowerType.Mana } }, -- Shadow
    },
    ROGUE = {
        [259] = { primary = { Enum.PowerType.Energy }, secondary = { Enum.PowerType.ComboPoints } }, -- Assassination
        [260] = { primary = { Enum.PowerType.Energy }, secondary = { Enum.PowerType.ComboPoints } }, -- Outlaw
        [261] = { primary = { Enum.PowerType.Energy }, secondary = { Enum.PowerType.ComboPoints } }, -- Subtlety
    },
    SHAMAN = {
        [262] = { primary = { Enum.PowerType.Maelstrom }, secondary = { Enum.PowerType.Mana } }, -- Elemental
        [263] = { primary = { Enum.PowerType.Mana }, secondary = { "MAELSTROM_WEAPON" } }, -- Enhancement
        [264] = { primary = { Enum.PowerType.Mana }, secondary = {} }, -- Restoration
    },
    WARLOCK = {
        [265] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.SoulShards } }, -- Affliction
        [266] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.SoulShards } }, -- Demonology
        [267] = { primary = { Enum.PowerType.Mana }, secondary = { Enum.PowerType.SoulShards } }, -- Destruction
    },
    WARRIOR = {
        [71] = { primary = { Enum.PowerType.Rage }, secondary = {} }, -- Arms
        [72] = { primary = { Enum.PowerType.Rage }, secondary = {} }, -- Fury
        [73] = { primary = { Enum.PowerType.Rage }, secondary = {} }, -- Protection
    },
}

local function GetPowerTypeLabel(resource)
    if POWER_TYPE_LABELS[resource] then
        return POWER_TYPE_LABELS[resource]
    end
    if type(resource) == "number" then
        for name, value in pairs(Enum.PowerType) do
            if value == resource then
                local label = name:gsub("(%u)", " %1"):gsub("^%s+", "")
                return label
            end
        end
    end
    return tostring(resource)
end

local function GetResourceKey(resource)
    if type(resource) == "string" then
        return resource
    end
    if type(resource) == "number" then
        return tostring(resource)
    end
    return tostring(resource)
end

local function GetSpecName(specID)
    local name = select(2, GetSpecializationInfoByID(specID))
    if name and name ~= "" then
        return name
    end
    return "Spec " .. tostring(specID)
end

local function GetClassName(classFile)
    return LOCALIZED_CLASS_NAMES_MALE[classFile]
        or LOCALIZED_CLASS_NAMES_FEMALE[classFile]
        or classFile
end

local function GetViewerOptions()
    return {
        ["EssentialCooldownViewer"] = "Essential Cooldowns",
        ["UtilityCooldownViewer"] = "Utility Cooldowns",
        ["BuffIconCooldownViewer"] = "Buff Icons",
        ["BuffBarCooldownViewer"] = "Buff Bar",
    }
end

local function CreateResourceAssignmentOptions()
    local classSpecResources = (NephUI.ResourceBars and NephUI.ResourceBars.classSpecResources) or CLASS_SPEC_RESOURCES
    if not classSpecResources then
        return {
            type = "group",
            name = "Assignments",
            order = 4,
            args = {
                missing = {
                    type = "description",
                    name = "Resource assignment data is not available yet. Please reload the UI.",
                    order = 1,
                },
            },
        }
    end

    local function GetAssignment(classFile, specID, resource)
        local assignments = NephUI.db.profile.resourceBarAssignments
        local classAssignments = assignments and assignments[classFile]
        local specAssignments = classAssignments and classAssignments[specID]
        local resourceKey = GetResourceKey(resource)
        local assigned = specAssignments and (specAssignments[resourceKey] or specAssignments[resource])
        if assigned and specAssignments and specAssignments[resource] and not specAssignments[resourceKey] then
            specAssignments[resourceKey] = specAssignments[resource]
            specAssignments[resource] = nil
        end
        if assigned == "primary" or assigned == "secondary" or assigned == "hide" then
            return assigned
        end
        if NephUI.ResourceBars and NephUI.ResourceBars.GetDefaultBarAssignment then
            return NephUI.ResourceBars.GetDefaultBarAssignment(classFile, specID, resource)
        end
        return "primary"
    end

    local function SetAssignment(classFile, specID, resource, value)
        local assignments = NephUI.db.profile.resourceBarAssignments
        if not assignments then
            NephUI.db.profile.resourceBarAssignments = {}
            assignments = NephUI.db.profile.resourceBarAssignments
        end
        assignments[classFile] = assignments[classFile] or {}
        assignments[classFile][specID] = assignments[classFile][specID] or {}
        assignments[classFile][specID][GetResourceKey(resource)] = value
        NephUI:UpdatePowerBar()
        NephUI:UpdateSecondaryPowerBar()
    end

    local args = {
        info = {
            type = "description",
            name = "Assign each power type to Bar 1, Bar 2, or Hide for every class and spec.",
            order = 1,
        },
    }

    for classIndex, classFile in ipairs(CLASS_ORDER) do
        local classData = classSpecResources[classFile]
        if classData then
            local classArgs = {}
            for specID, specData in pairs(classData) do
                local specArgs = {}
                local order = 1
                if specData.primary and #specData.primary > 0 then
                    specArgs.primaryHeader = {
                        type = "header",
                        name = "Primary Power Types",
                        order = order,
                    }
                    order = order + 1
                    for _, resource in ipairs(specData.primary) do
                        local resourceKey = "primary_" .. tostring(resource)
                        specArgs[resourceKey] = {
                            type = "select",
                            name = GetPowerTypeLabel(resource),
                            order = order,
                            width = "normal",
                            values = BAR_ASSIGNMENT_VALUES,
                            get = function() return GetAssignment(classFile, specID, resource) end,
                            set = function(_, val) SetAssignment(classFile, specID, resource, val) end,
                        }
                        order = order + 1
                    end
                end

                if specData.secondary and #specData.secondary > 0 then
                    specArgs.secondaryHeader = {
                        type = "header",
                        name = "Secondary Power Types",
                        order = order,
                    }
                    order = order + 1
                    for _, resource in ipairs(specData.secondary) do
                        local resourceKey = "secondary_" .. tostring(resource)
                        specArgs[resourceKey] = {
                            type = "select",
                            name = GetPowerTypeLabel(resource),
                            order = order,
                            width = "normal",
                            values = BAR_ASSIGNMENT_VALUES,
                            get = function() return GetAssignment(classFile, specID, resource) end,
                            set = function(_, val) SetAssignment(classFile, specID, resource, val) end,
                        }
                        order = order + 1
                    end
                end

                classArgs["spec_" .. tostring(specID)] = {
                    type = "group",
                    name = GetSpecName(specID),
                    order = specID,
                    args = specArgs,
                }
            end

            args["class_" .. classFile] = {
                type = "group",
                name = GetClassName(classFile),
                order = classIndex + 1,
                childGroups = "tab",
                args = classArgs,
            }
        end
    end

    return {
        type = "group",
        name = "Assignments",
        order = 4,
        childGroups = "tab",
        args = args,
    }
end

local function CreateResourceBarOptions()
    return {
        type = "group",
        name = L["Resource Bars"] or "Resource Bars",
        order = 6,
        childGroups = "tab",
        args = {
            primary = {
                type = "group",
                name = L["Primary"] or "Primary",
                order = 1,
                args = {
                    header = {
                        type = "header",
                        name = L["Primary Power Bar Settings"] or "Primary Power Bar Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = L["Enable Primary Power Bar"] or "Enable Primary Power Bar",
                        desc = L["Show your main resource (mana, energy, rage, etc.)"] or "Show your main resource (mana, energy, rage, etc.)",
                        width = "full",
                        order = 2,
                        get = function() return NephUI.db.profile.powerBar.enabled end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.enabled = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    smoothProgress = {
                        type = "toggle",
                        name = "Smooth Progress",
                        desc = "Enable smooth animation for bar updates (requires WoW 12.0+)",
                        width = "full",
                        order = 3,
                        hidden = function() return buildVersion < 120000 end,
                        get = function() return NephUI.db.profile.powerBar.smoothProgress end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.smoothProgress = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    updateFrequency = {
                        type = "range",
                        name = "Update Frequency",
                        desc = "|cffff0000WARNING: Lower values = more frequent updates = higher CPU usage!|r How often to update the bar (in seconds).",
                        order = 4,
                        width = "full",
                        min = 0.01,
                        max = 0.5,
                        step = 0.01,
                        get = function() return NephUI.db.profile.powerBar.updateFrequency end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.updateFrequency = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    positionHeader = {
                        type = "header",
                        name = "Position & Size",
                        order = 10,
                    },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Which frame to attach this bar to",
                        order = 11,
                        width = "full",
                        values = function()
                            local opts = {}
                            opts["UIParent"] = "Screen (UIParent)"
                            if NephUI.db.profile.unitFrames and NephUI.db.profile.unitFrames.enabled then
                                opts["NephUI_Player"] = "Player Frame (Custom)"
                            end
                            opts["PlayerFrame"] = "Default Player Frame"
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            return opts
                        end,
                        get = function() return NephUI.db.profile.powerBar.attachTo end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.attachTo = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    anchorPoint = {
                        type = "select",
                        name = "Anchor Point",
                        desc = "Which point on the anchor frame to attach to",
                        order = 11.1,
                        width = "normal",
                        values = {
                            TOP = "Top",
                            CENTER = "Center",
                            BOTTOM = "Bottom",
                        },
                        get = function() return NephUI.db.profile.powerBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.anchorPoint = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 2, max = 100, step = 1,
                        get = function() return NephUI.db.profile.powerBar.height end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.height = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on icons",
                        order = 13,
                        width = "normal",
                        min = 0, max = 1000, step = 1,
                        get = function() return NephUI.db.profile.powerBar.width end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.width = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the icon viewer",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return NephUI.db.profile.powerBar.offsetY end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.offsetY = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return NephUI.db.profile.powerBar.offsetX or 0 end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.offsetX = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    
                    appearanceHeader = {
                        type = "header",
                        name = "Appearance",
                        order = 20,
                    },
                    texture = {
                        type = "select",
                        name = "Bar Texture",
                        order = 21,
                        width = "full",
                        values = function()
                            local hashTable = LSM:HashTable("statusbar")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function() 
                            local override = NephUI.db.profile.powerBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return NephUI.db.profile.general.globalTexture or "Neph"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.texture = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    borderSize = {
                        type = "range",
                        name = "Border Size",
                        desc = "Size of the border around the resource bar",
                        order = 22,
                        width = "normal",
                        min = 0, max = 5, step = 1,
                        get = function() return NephUI.db.profile.powerBar.borderSize end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.borderSize = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    borderColor = {
                        type = "color",
                        name = "Border Color",
                        desc = "Color of the border around the resource bar",
                        order = 23,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerBar.borderColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0, 0, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerBar.borderColor = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    
                    displayHeader = {
                        type = "header",
                        name = "Display Options",
                        order = 30,
                    },
                    showText = {
                        type = "toggle",
                        name = L["Show Resource Number"] or "Show Resource Number",
                        desc = L["Display current resource amount as text"] or "Display current resource amount as text",
                        order = 31,
                        width = "normal",
                        get = function() return NephUI.db.profile.powerBar.showText end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.showText = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    showManaAsPercent = {
                        type = "toggle",
                        name = L["Show Mana as Percent"] or "Show Mana as Percent",
                        desc = L["Display mana as percentage instead of raw value"] or "Display mana as percentage instead of raw value",
                        order = 32,
                        width = "normal",
                        get = function() return NephUI.db.profile.powerBar.showManaAsPercent end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.showManaAsPercent = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    showManaPercentDecimal = {
                        type = "toggle",
                        name = "Show Mana Percent Decimal",
                        desc = "Show one decimal place in mana percentage (94.3% vs 94%)",
                        order = 32.5,
                        width = "normal",
                        get = function() return NephUI.db.profile.powerBar.showManaPercentDecimal end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.showManaPercentDecimal = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    textFormat = {
                        type = "select",
                        name = "Text Format",
                        desc = "Formatting for resource text",
                        order = 32.6,
                        width = "normal",
                        values = {
                            ["Current"] = "Current",
                            ["Current / Maximum"] = "Current / Maximum",
                            ["Percent"] = "Percent",
                            ["Percent%"] = "Percent%",
                        },
                        get = function()
                            return NephUI.db.profile.powerBar.textFormat or "Current"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.textFormat = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    textPrecision = {
                        type = "select",
                        name = "Percent Precision",
                        desc = "Decimal precision for percent text",
                        order = 32.7,
                        width = "normal",
                        values = {
                            ["0"] = "0",
                            ["0.0"] = "0.0",
                            ["0.00"] = "0.00",
                        },
                        get = function()
                            return NephUI.db.profile.powerBar.textPrecision or "0"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.textPrecision = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    fragmentedPowerBarTextPrecision = {
                        type = "select",
                        name = "Fragment Timer Precision",
                        desc = "Decimal precision for rune/essence timers",
                        order = 32.8,
                        width = "normal",
                        values = {
                            ["0"] = "0",
                            ["0.0"] = "0.0",
                            ["0.00"] = "0.00",
                        },
                        get = function()
                            return NephUI.db.profile.powerBar.fragmentedPowerBarTextPrecision or "0.0"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.fragmentedPowerBarTextPrecision = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    chargedColor = {
                        type = "color",
                        name = "Charged Segment Color",
                        desc = "Overlay color for charged power points",
                        order = 32.9,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerBar.chargedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.22, 0.62, 1.0, 0.8
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerBar.chargedColor = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    showTicks = {
                        type = "toggle",
                        name = L["Show Ticks"] or "Show Ticks",
                        desc = L["Show segment markers for combo points, chi, etc."] or "Show segment markers for combo points, chi, etc.",
                        order = 33,
                        width = "normal",
                        get = function() return NephUI.db.profile.powerBar.showTicks end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.showTicks = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    fragmentTimerHeader = {
                        type = "header",
                        name = "Fragment Timer Options",
                        order = 39,
                    },
                    showFragmentedPowerBarText = {
                        type = "toggle",
                        name = "Show Fragment Timers",
                        desc = "Show cooldown timers on fragmented resources like runes or essence",
                        order = 40,
                        width = "normal",
                        get = function() return NephUI.db.profile.powerBar.showFragmentedPowerBarText end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.showFragmentedPowerBarText = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    runeTimerTextSize = {
                        type = "range",
                        name = "Fragment Timer Text Size",
                        desc = "Font size for fragment timer text",
                        order = 41,
                        width = "normal",
                        min = 6, max = 24, step = 1,
                        get = function() return NephUI.db.profile.powerBar.runeTimerTextSize end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.runeTimerTextSize = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    runeTimerTextX = {
                        type = "range",
                        name = "Fragment Timer Text X Position",
                        desc = "Horizontal offset for fragment timer text",
                        order = 42,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.powerBar.runeTimerTextX end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.runeTimerTextX = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    runeTimerTextY = {
                        type = "range",
                        name = "Fragment Timer Text Y Position",
                        desc = "Vertical offset for fragment timer text",
                        order = 43,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.powerBar.runeTimerTextY end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.runeTimerTextY = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    hideWhenMana = {
                        type = "toggle",
                        name = "Hide Bar When Mana",
                        desc = "Hide the resource bar completely when current power is mana (prevents errors during druid shapeshifting)",
                        order = 33.5,
                        width = "normal",
                        get = function() return NephUI.db.profile.powerBar.hideWhenMana end,
                        set = function(_, val)
                            if InCombatLockdown() then
                                return
                            end
                            NephUI.db.profile.powerBar.hideWhenMana = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    hideBarShowText = {
                        type = "toggle",
                        name = "Hide Bar, Show Text Only",
                        desc = "Hide the resource bar visual but keep the text visible",
                        order = 33.6,
                        width = "normal",
                        get = function() return NephUI.db.profile.powerBar.hideBarShowText end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.hideBarShowText = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = L["Text Size"] or "Text Size",
                        order = 34,
                        width = "normal",
                        min = 6, max = 24, step = 1,
                        get = function() return NephUI.db.profile.powerBar.textSize end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.textSize = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    textX = {
                        type = "range",
                        name = L["Text Horizontal Offset"] or "Text Horizontal Offset",
                        order = 35,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.powerBar.textX end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.textX = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    textY = {
                        type = "range",
                        name = L["Text Vertical Offset"] or "Text Vertical Offset",
                        order = 36,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.powerBar.textY end,
                        set = function(_, val)
                            NephUI.db.profile.powerBar.textY = val
                            NephUI:UpdatePowerBar()
                        end,
                    },
                },
            },
            secondary = {
                type = "group",
                name = L["Secondary"] or "Secondary",
                name = "Secondary",
                order = 2,
                args = {
                    header = {
                        type = "header",
                        name = "Secondary Power Bar Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Secondary Power Bar",
                        desc = "Show your secondary resource (combo points, chi, runes, etc.)",
                        width = "full",
                        order = 2,
                        get = function() return NephUI.db.profile.secondaryPowerBar.enabled end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.enabled = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    smoothProgress = {
                        type = "toggle",
                        name = "Smooth Progress",
                        desc = "Enable smooth animation for bar updates (requires WoW 12.0+)",
                        width = "full",
                        order = 3,
                        hidden = function() return buildVersion < 120000 end,
                        get = function() return NephUI.db.profile.secondaryPowerBar.smoothProgress end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.smoothProgress = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    updateFrequency = {
                        type = "range",
                        name = "Update Frequency",
                        desc = "|cffff0000WARNING: Lower values = more frequent updates = higher CPU usage!|r How often to update the bar (in seconds).",
                        order = 4,
                        width = "full",
                        min = 0.01,
                        max = 0.5,
                        step = 0.01,
                        get = function() return NephUI.db.profile.secondaryPowerBar.updateFrequency end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.updateFrequency = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    positionHeader = {
                        type = "header",
                        name = "Position & Size",
                        order = 10,
                    },
                    attachTo = {
                        type = "select",
                        name = "Attach To",
                        desc = "Which frame to attach this bar to",
                        order = 11,
                        width = "full",
                        values = function()
                            local opts = {}
                            opts["UIParent"] = "Screen (UIParent)"
                            if NephUI.db.profile.unitFrames and NephUI.db.profile.unitFrames.enabled then
                                opts["NephUI_Player"] = "Player Frame (Custom)"
                            end
                            opts["PlayerFrame"] = "Default Player Frame"
                            local viewerOpts = GetViewerOptions()
                            for k, v in pairs(viewerOpts) do
                                opts[k] = v
                            end
                            return opts
                        end,
                        get = function() return NephUI.db.profile.secondaryPowerBar.attachTo end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.attachTo = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    anchorPoint = {
                        type = "select",
                        name = "Anchor Point",
                        desc = "Which point on the anchor frame to attach to",
                        order = 11.1,
                        width = "normal",
                        values = {
                            TOP = "Top",
                            CENTER = "Center",
                            BOTTOM = "Bottom",
                        },
                        get = function() return NephUI.db.profile.secondaryPowerBar.anchorPoint or "CENTER" end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.anchorPoint = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 12,
                        width = "normal",
                        min = 2, max = 30, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.height end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.height = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        desc = "0 = automatic width based on icons",
                        order = 13,
                        width = "normal",
                        min = 0, max = 500, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.width end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.width = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    offsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Distance from the icon viewer",
                        order = 14,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.offsetY end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.offsetY = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    offsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Horizontal distance from the anchor point",
                        order = 15,
                        width = "full",
                        min = -500, max = 500, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.offsetX or 0 end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.offsetX = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    
                    appearanceHeader = {
                        type = "header",
                        name = "Appearance",
                        order = 20,
                    },
                    texture = {
                        type = "select",
                        name = "Bar Texture",
                        order = 21,
                        width = "full",
                        values = function()
                            local hashTable = LSM:HashTable("statusbar")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function() 
                            local override = NephUI.db.profile.secondaryPowerBar.texture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return NephUI.db.profile.general.globalTexture or "Neph"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.texture = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    borderSize = {
                        type = "range",
                        name = "Border Size",
                        desc = "Size of the border around the resource bar",
                        order = 22,
                        width = "normal",
                        min = 0, max = 5, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.borderSize end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.borderSize = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    borderColor = {
                        type = "color",
                        name = "Border Color",
                        desc = "Color of the border around the resource bar",
                        order = 23,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.secondaryPowerBar.borderColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0, 0, 0, 1
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.secondaryPowerBar.borderColor = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    
                    displayHeader = {
                        type = "header",
                        name = "Display Options",
                        order = 30,
                    },
                    showText = {
                        type = "toggle",
                        name = "Show Resource Number",
                        desc = "Display current resource amount as text",
                        order = 31,
                        width = "normal",
                        get = function() return NephUI.db.profile.secondaryPowerBar.showText end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.showText = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    showManaAsPercent = {
                        type = "toggle",
                        name = "Show Mana as Percent",
                        desc = "Display mana as percentage instead of raw value for mana-based secondary resources",
                        order = 31.5,
                        width = "normal",
                        get = function() return NephUI.db.profile.secondaryPowerBar.showManaAsPercent end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.showManaAsPercent = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    showManaPercentDecimal = {
                        type = "toggle",
                        name = "Show Mana Percent Decimal",
                        desc = "Show one decimal place in mana percentage (94.3% vs 94%)",
                        order = 31.6,
                        width = "normal",
                        get = function() return NephUI.db.profile.secondaryPowerBar.showManaPercentDecimal end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.showManaPercentDecimal = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    textFormat = {
                        type = "select",
                        name = "Text Format",
                        desc = "Formatting for resource text",
                        order = 31.7,
                        width = "normal",
                        values = {
                            ["Current"] = "Current",
                            ["Current / Maximum"] = "Current / Maximum",
                            ["Percent"] = "Percent",
                            ["Percent%"] = "Percent%",
                        },
                        get = function()
                            return NephUI.db.profile.secondaryPowerBar.textFormat or "Current"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.textFormat = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    textPrecision = {
                        type = "select",
                        name = "Percent Precision",
                        desc = "Decimal precision for percent text",
                        order = 31.8,
                        width = "normal",
                        values = {
                            ["0"] = "0",
                            ["0.0"] = "0.0",
                            ["0.00"] = "0.00",
                        },
                        get = function()
                            return NephUI.db.profile.secondaryPowerBar.textPrecision or "0"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.textPrecision = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    fragmentedPowerBarTextPrecision = {
                        type = "select",
                        name = "Fragment Timer Precision",
                        desc = "Decimal precision for rune/essence timers",
                        order = 31.9,
                        width = "normal",
                        values = {
                            ["0"] = "0",
                            ["0.0"] = "0.0",
                            ["0.00"] = "0.00",
                        },
                        get = function()
                            return NephUI.db.profile.secondaryPowerBar.fragmentedPowerBarTextPrecision or "0.0"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.fragmentedPowerBarTextPrecision = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    chargedColor = {
                        type = "color",
                        name = "Charged Segment Color",
                        desc = "Overlay color for charged power points",
                        order = 31.95,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.secondaryPowerBar.chargedColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.22, 0.62, 1.0, 0.8
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.secondaryPowerBar.chargedColor = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    showTicks = {
                        type = "toggle",
                        name = "Show Ticks",
                        desc = "Show segment markers between resources",
                        order = 32,
                        width = "normal",
                        get = function() return NephUI.db.profile.secondaryPowerBar.showTicks end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.showTicks = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    hideWhenMana = {
                        type = "toggle",
                        name = "Hide Bar When Mana",
                        desc = "Hide the secondary bar entirely when the current power is mana",
                        order = 32.3,
                        width = "normal",
                        get = function() return NephUI.db.profile.secondaryPowerBar.hideWhenMana end,
                        set = function(_, val)
                            if InCombatLockdown() then
                                return
                            end
                            NephUI.db.profile.secondaryPowerBar.hideWhenMana = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    hideBarShowText = {
                        type = "toggle",
                        name = "Hide Bar, Show Text Only",
                        desc = "Hide the resource bar visual but keep the text visible",
                        order = 32.5,
                        width = "normal",
                        get = function() return NephUI.db.profile.secondaryPowerBar.hideBarShowText end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.hideBarShowText = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    textSize = {
                        type = "range",
                        name = "Text Size",
                        order = 33,
                        width = "normal",
                        min = 6, max = 24, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.textSize end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.textSize = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    textX = {
                        type = "range",
                        name = "Text Horizontal Offset",
                        order = 34,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.textX end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.textX = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    textY = {
                        type = "range",
                        name = "Text Vertical Offset",
                        order = 35,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.textY end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.textY = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    
                    runeTimerHeader = {
                        type = "header",
                        name = "Fragment Timer Options",
                        order = 39,
                    },
                    showFragmentedPowerBarText = {
                        type = "toggle",
                        name = "Show Fragment Timers",
                        desc = "Show cooldown timers on fragmented resources like runes or essence",
                        order = 40,
                        width = "normal",
                        get = function() return NephUI.db.profile.secondaryPowerBar.showFragmentedPowerBarText end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.showFragmentedPowerBarText = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    runeTimerTextSize = {
                        type = "range",
                        name = "Fragment Timer Text Size",
                        desc = "Font size for fragment timer text",
                        order = 41,
                        width = "normal",
                        min = 6, max = 24, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.runeTimerTextSize end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.runeTimerTextSize = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    runeTimerTextX = {
                        type = "range",
                        name = "Fragment Timer Text X Position",
                        desc = "Horizontal offset for fragment timer text",
                        order = 42,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.runeTimerTextX end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.runeTimerTextX = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    runeTimerTextY = {
                        type = "range",
                        name = "Fragment Timer Text Y Position",
                        desc = "Vertical offset for fragment timer text",
                        order = 43,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function() return NephUI.db.profile.secondaryPowerBar.runeTimerTextY end,
                        set = function(_, val)
                            NephUI.db.profile.secondaryPowerBar.runeTimerTextY = val
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                },
            },
            colors = {
                type = "group",
                name = "Colors",
                order = 3,
                args = {
                    useClassColor = {
                        type = "toggle",
                        name = "Use Class Color",
                        desc = "Use your class color for resource bars instead of power type colors",
                        width = "full",
                        order = 1,
                        get = function() return NephUI.db.profile.powerTypeColors.useClassColor end,
                        set = function(_, val)
                            NephUI.db.profile.powerTypeColors.useClassColor = val
                            NephUI:UpdatePowerBar()
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    backgroundHeader = {
                        type = "header",
                        name = "Global Background Colors",
                        order = 2,
                    },
                    primaryBgColor = {
                        type = "color",
                        name = "Primary Bar Background",
                        desc = "Background color for primary power bars",
                        order = 3,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.15, 0.15, 0.15, 1
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerBar.bgColor = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    secondaryBgColor = {
                        type = "color",
                        name = "Secondary Bar Background",
                        desc = "Background color for secondary power bars",
                        order = 4,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.secondaryPowerBar.bgColor
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.15, 0.15, 0.15, 1
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.secondaryPowerBar.bgColor = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    primaryHeader = {
                        type = "header",
                        name = "Primary Power Types",
                        order = 10,
                    },
                    manaColor = {
                        type = "color",
                        name = "Mana",
                        desc = "Color for mana bars",
                        order = 11,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Mana]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.00, 0.00, 1.00, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Mana] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    rageColor = {
                        type = "color",
                        name = "Rage",
                        desc = "Color for rage bars",
                        order = 12,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Rage]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1.00, 0.00, 0.00, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Rage] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    focusColor = {
                        type = "color",
                        name = "Focus",
                        desc = "Color for focus bars",
                        order = 13,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Focus]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1.00, 0.50, 0.25, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Focus] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    energyColor = {
                        type = "color",
                        name = "Energy",
                        desc = "Color for energy bars",
                        order = 14,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Energy]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1.00, 1.00, 0.00, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Energy] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    runicPowerColor = {
                        type = "color",
                        name = "Runic Power",
                        desc = "Color for runic power bars",
                        order = 15,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.RunicPower]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.00, 0.82, 1.00, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.RunicPower] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    lunarPowerColor = {
                        type = "color",
                        name = "Astral Power",
                        desc = "Color for astral power bars",
                        order = 16,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.LunarPower]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.30, 0.52, 0.90, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.LunarPower] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    furyColor = {
                        type = "color",
                        name = "Fury",
                        desc = "Color for fury bars",
                        order = 17,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Fury]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.79, 0.26, 0.99, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Fury] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    maelstromColor = {
                        type = "color",
                        name = "Maelstrom",
                        desc = "Color for maelstrom bars",
                        order = 18,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Maelstrom]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.00, 0.50, 1.00, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Maelstrom] = { r, g, b, a }
                            NephUI:UpdatePowerBar()
                        end,
                    },
                    secondaryHeader = {
                        type = "header",
                        name = "Secondary Power Types",
                        order = 20,
                    },
                    runesColor = {
                        type = "color",
                        name = "Runes",
                        desc = "Color for rune bars",
                        order = 21,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Runes]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.77, 0.12, 0.23, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Runes] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    soulFragmentsColor = {
                        type = "color",
                        name = "Soul Fragments",
                        desc = "Color for soul fragment bars",
                        order = 22,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors["SOUL"]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.64, 0.19, 0.79, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors["SOUL"] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    comboPointsColor = {
                        type = "color",
                        name = "Combo Points",
                        desc = "Color for combo point bars",
                        order = 23,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.ComboPoints]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1.00, 0.96, 0.41, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.ComboPoints] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    essenceColor = {
                        type = "color",
                        name = "Essence",
                        desc = "Color for essence bars",
                        order = 24,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Essence]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.20, 0.58, 0.50, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Essence] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    arcaneChargesColor = {
                        type = "color",
                        name = "Arcane Charges",
                        desc = "Color for arcane charge bars",
                        order = 25,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.ArcaneCharges]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.20, 0.60, 1.00, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.ArcaneCharges] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    staggerLightColor = {
                        type = "color",
                        name = "Light Stagger",
                        desc = "Color for stagger bars when stagger is less than 30% of max health",
                        order = 26,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors["STAGGER_LIGHT"]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.52, 1.00, 0.52, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors["STAGGER_LIGHT"] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    staggerMediumColor = {
                        type = "color",
                        name = "Medium Stagger",
                        desc = "Color for stagger bars when stagger is 30-59% of max health",
                        order = 26.1,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors["STAGGER_MEDIUM"]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1.00, 0.98, 0.72, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors["STAGGER_MEDIUM"] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    staggerHeavyColor = {
                        type = "color",
                        name = "Heavy Stagger",
                        desc = "Color for stagger bars when stagger is 60% or more of max health",
                        order = 26.2,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors["STAGGER_HEAVY"]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 1.00, 0.42, 0.42, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors["STAGGER_HEAVY"] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    chiColor = {
                        type = "color",
                        name = "Chi",
                        desc = "Color for chi bars",
                        order = 27,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Chi]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.00, 1.00, 0.59, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.Chi] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    holyPowerColor = {
                        type = "color",
                        name = "Holy Power",
                        desc = "Color for holy power bars",
                        order = 28,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.HolyPower]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.95, 0.90, 0.60, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.HolyPower] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    soulShardsColor = {
                        type = "color",
                        name = "Soul Shards",
                        desc = "Color for soul shard bars",
                        order = 29,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.SoulShards]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.58, 0.51, 0.79, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors[Enum.PowerType.SoulShards] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                    maelstromWeaponColor = {
                        type = "color",
                        name = "Maelstrom Weapon",
                        desc = "Color for maelstrom weapon bars",
                        order = 30,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local c = NephUI.db.profile.powerTypeColors.colors["MAELSTROM_WEAPON"]
                            if c then
                                return c[1], c[2], c[3], c[4] or 1
                            end
                            return 0.00, 0.50, 1.00, 1.0
                        end,
                        set = function(_, r, g, b, a)
                            NephUI.db.profile.powerTypeColors.colors["MAELSTROM_WEAPON"] = { r, g, b, a }
                            NephUI:UpdateSecondaryPowerBar()
                        end,
                    },
                },
            },
            assignments = CreateResourceAssignmentOptions(),
        },
    }
end

ns.CreateResourceBarOptions = CreateResourceBarOptions

