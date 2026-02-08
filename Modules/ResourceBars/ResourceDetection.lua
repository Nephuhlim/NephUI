local ADDON_NAME, ns = ...
local NephUI = ns.Addon

-- Tables
local buildVersion = select(4, GetBuildInfo())
local HAS_UNIT_POWER_PERCENT = type(UnitPowerPercent) == "function"

-- Safely fetch power percent across API variants (12.0 curve vs legacy boolean)
local function SafeUnitPowerPercent(unit, resource, usePredicted)
    if type(UnitPowerPercent) == "function" then
        local ok, pct

        if CurveConstants and CurveConstants.ScaleTo100 then
            ok, pct = pcall(UnitPowerPercent, unit, resource, usePredicted, CurveConstants.ScaleTo100)
        else
            ok, pct = pcall(UnitPowerPercent, unit, resource, usePredicted, true)
        end

        if (not ok or pct == nil) then
            ok, pct = pcall(UnitPowerPercent, unit, resource, usePredicted)
        end

        if ok and pct ~= nil then
            return pct
        end
    end

    if UnitPower and UnitPowerMax then
        local cur = UnitPower(unit, resource)
        local max = UnitPowerMax(unit, resource)
        if cur and max and max > 0 then
            return (cur / max) * 100
        end
    end

    return nil
end

local tickedPowerTypes = {
    [Enum.PowerType.ArcaneCharges] = true,
    [Enum.PowerType.Chi] = true,
    [Enum.PowerType.ComboPoints] = true,
    [Enum.PowerType.Essence] = true,
    [Enum.PowerType.HolyPower] = true,
    [Enum.PowerType.Runes] = true,
    [Enum.PowerType.SoulShards] = true,
    ["MAELSTROM_WEAPON"] = true,
    ["SOUL"] = true, -- Vengeance Demon Hunter only (checked dynamically)
}

local fragmentedPowerTypes = {
    [Enum.PowerType.Runes] = true,
    [Enum.PowerType.Essence] = true,
}

local classSpecResources = {
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

-- Export tables for use in other ResourceBars files
NephUI.ResourceBars = NephUI.ResourceBars or {}
NephUI.ResourceBars.tickedPowerTypes = tickedPowerTypes
NephUI.ResourceBars.fragmentedPowerTypes = fragmentedPowerTypes
NephUI.ResourceBars.HAS_UNIT_POWER_PERCENT = HAS_UNIT_POWER_PERCENT
NephUI.ResourceBars.buildVersion = buildVersion
NephUI.ResourceBars.classSpecResources = classSpecResources

-- RESOURCE DETECTION

local function GetPrimaryResource()
    local playerClass = select(2, UnitClass("player"))
    local primaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
        ["DEMONHUNTER"] = Enum.PowerType.Fury,
        ["DRUID"]       = {
            [0]   = Enum.PowerType.Mana, -- Human
            [1]   = Enum.PowerType.Energy, -- Cat
            [5]   = Enum.PowerType.Rage, -- Bear
            [27]  = Enum.PowerType.Mana, -- Travel
            [31]  = Enum.PowerType.LunarPower, -- Moonkin
        },
        ["EVOKER"]      = Enum.PowerType.Mana,
        ["HUNTER"]      = Enum.PowerType.Focus,
        ["MAGE"]        = Enum.PowerType.Mana,
        ["MONK"]        = {
            [268] = Enum.PowerType.Energy, -- Brewmaster
            [269] = Enum.PowerType.Energy, -- Windwalker
            [270] = Enum.PowerType.Mana, -- Mistweaver
        },
        ["PALADIN"]     = Enum.PowerType.Mana,
        ["PRIEST"]      = {
            [256] = Enum.PowerType.Mana, -- Disciple
            [257] = Enum.PowerType.Mana, -- Holy,
            [258] = Enum.PowerType.Insanity, -- Shadow,
        },
        ["ROGUE"]       = Enum.PowerType.Energy,
        ["SHAMAN"]      = {
            [262] = Enum.PowerType.Maelstrom, -- Elemental
            [263] = Enum.PowerType.Mana, -- Enhancement
            [264] = Enum.PowerType.Mana, -- Restoration
        },
        ["WARLOCK"]     = Enum.PowerType.Mana,
        ["WARRIOR"]     = Enum.PowerType.Rage,
    }

    local spec = GetSpecialization()
    local specID = GetSpecializationInfo(spec)

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        return primaryResources[playerClass][formID or 0]
    end

    if type(primaryResources[playerClass]) == "table" then
        return primaryResources[playerClass][specID]
    else 
        return primaryResources[playerClass]
    end
end

local function GetSecondaryResource()
    local playerClass = select(2, UnitClass("player"))
    local secondaryResources = {
        ["DEATHKNIGHT"] = Enum.PowerType.Runes,
        ["DEMONHUNTER"] = {
            [581] = "SOUL", -- Vengeance
            [1480] = "SOUL", -- Devourer (Aldrachi Reaver)
        },
        ["DRUID"]       = {
            [1]    = Enum.PowerType.ComboPoints, -- Cat
            [31]   = Enum.PowerType.Mana, -- Moonkin
        },
        ["EVOKER"]      = Enum.PowerType.Essence,
        ["HUNTER"]      = nil,
        ["MAGE"]        = {
            [62]   = Enum.PowerType.ArcaneCharges, -- Arcane
        },
        ["MONK"]        = {
            [268]  = "STAGGER", -- Brewmaster
            [269]  = Enum.PowerType.Chi, -- Windwalker
        },
        ["PALADIN"]     = Enum.PowerType.HolyPower,
        ["PRIEST"]      = {
            [258]  = Enum.PowerType.Mana, -- Shadow
        },
        ["ROGUE"]       = Enum.PowerType.ComboPoints,
        ["SHAMAN"]      = {
            [262]  = Enum.PowerType.Mana, -- Elemental
            [263]  = "MAELSTROM_WEAPON", -- Enhancement
        },
        ["WARLOCK"]     = Enum.PowerType.SoulShards,
        ["WARRIOR"]     = nil,
    }

    local spec = GetSpecialization()
    local specID = GetSpecializationInfo(spec)

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        return secondaryResources[playerClass][formID or 0]
    end

    if type(secondaryResources[playerClass]) == "table" then
        return secondaryResources[playerClass][specID]
    else 
        return secondaryResources[playerClass]
    end
end

local function GetDefaultBarAssignment(class, specID, resource)
    local classData = classSpecResources[class]
    if classData then
        local specData = classData[specID]
        if specData then
            if specData.primary then
                for _, powerType in ipairs(specData.primary) do
                    if powerType == resource then
                        return "primary"
                    end
                end
            end
            if specData.secondary then
                for _, powerType in ipairs(specData.secondary) do
                    if powerType == resource then
                        return "secondary"
                    end
                end
            end
        end
    end
    return "primary"
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

local function GetResourceBarAssignment(class, specID, resource)
    local profile = NephUI.db and NephUI.db.profile
    local assignments = profile and profile.resourceBarAssignments
    local classAssignments = assignments and assignments[class]
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
    return GetDefaultBarAssignment(class, specID, resource)
end

local function IsSecondaryResourceForSpec(class, specID, resource)
    local classData = classSpecResources[class]
    if not classData then
        return false
    end
    local specData = classData[specID]
    if not specData or not specData.secondary then
        return false
    end
    for _, powerType in ipairs(specData.secondary) do
        if powerType == resource then
            return true
        end
    end
    return false
end

local function GetAssignedResources()
    local primaryResource = GetPrimaryResource()
    local secondaryResource = GetSecondaryResource()
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec)

    if not class or not specID then
        return primaryResource, secondaryResource
    end

    local primaryAssignment = primaryResource and GetResourceBarAssignment(class, specID, primaryResource)
    local secondaryAssignment = secondaryResource and GetResourceBarAssignment(class, specID, secondaryResource)

    local bar1Resource
    local bar2Resource

    if primaryResource and primaryAssignment == "primary" then
        bar1Resource = primaryResource
    end
    if secondaryResource and secondaryAssignment == "primary" and not bar1Resource then
        bar1Resource = secondaryResource
    end
    if primaryResource and primaryAssignment == "secondary" then
        bar2Resource = primaryResource
    end
    if secondaryResource and secondaryAssignment == "secondary" and not bar2Resource then
        bar2Resource = secondaryResource
    end

    return bar1Resource, bar2Resource
end

local function GetChargedPowerPoints(resource)
    -- Only attempt for ticked, non-fragmented secondary resources (combo points, holy power, etc.)
    if not resource or fragmentedPowerTypes[resource] or not tickedPowerTypes[resource] then
        return nil
    end

    if type(GetUnitChargedPowerPoints) ~= "function" then
        return nil
    end

    local ok, charged = pcall(GetUnitChargedPowerPoints, "player")
    if not ok or not charged then
        return nil
    end

    local normalized = {}
    for _, index in ipairs(charged) do
        if type(index) == "number" then
            table.insert(normalized, index)
        end
    end

    if #normalized == 0 then
        return nil
    end

    return normalized
end

local function GetResourceColor(resource)
    local color = nil
    
    -- Blizzard PowerType lookup name (fallback)
    local powerName = nil
    if type(resource) == "number" then
        for name, value in pairs(Enum.PowerType) do
            if value == resource then
                powerName = name:gsub("(%u)", "_%1"):gsub("^_", ""):upper()
                break
            end
        end
    end

    if resource == "STAGGER" then
        -- Monk stagger uses dynamic coloring based on configurable thresholds
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1
        local percent = 0
        if maxHealth > 0 then
            percent = (stagger / maxHealth) * 100
        end

        -- Use configurable colors if available, otherwise fall back to defaults
        if percent >= 60 then
            -- Heavy stagger - use configured heavy color or default red
            local heavyColor = NephUI.db and NephUI.db.profile and NephUI.db.profile.powerTypeColors and NephUI.db.profile.powerTypeColors.colors and NephUI.db.profile.powerTypeColors.colors["STAGGER_HEAVY"]
            color = heavyColor or { r = 1.00, g = 0.42, b = 0.42 }
        elseif percent >= 30 then
            -- Medium stagger - use configured medium color or default yellow
            local mediumColor = NephUI.db and NephUI.db.profile and NephUI.db.profile.powerTypeColors and NephUI.db.profile.powerTypeColors.colors and NephUI.db.profile.powerTypeColors.colors["STAGGER_MEDIUM"]
            color = mediumColor or { r = 1.00, g = 0.98, b = 0.72 }
        else
            -- Light stagger - use configured light color or default green
            local lightColor = NephUI.db and NephUI.db.profile and NephUI.db.profile.powerTypeColors and NephUI.db.profile.powerTypeColors.colors and NephUI.db.profile.powerTypeColors.colors["STAGGER_LIGHT"]
            color = lightColor or { r = 0.52, g = 1.00, b = 0.52 }
        end

    elseif resource == "SOUL" then
        -- Demon Hunter soul fragments
        color = { r = 0.64, g = 0.19, b = 0.79 }


    elseif resource == Enum.PowerType.Runes then
        -- Death Knight
        color = { r = 0.77, g = 0.12, b = 0.23 }

    elseif resource == Enum.PowerType.Essence then
        -- Evoker
        color = { r = 0.20, g = 0.58, b = 0.50 }

    elseif resource == Enum.PowerType.SoulShards then
        -- Warlock soul shards (WARLOCK class color)
        color = { r = 0.58, g = 0.51, b = 0.79 }

    elseif resource == Enum.PowerType.ComboPoints then
        -- Rogue
        color = { r = 1.00, g = 0.96, b = 0.41 }

    elseif resource == Enum.PowerType.Chi then
        -- Monk
        color = { r = 0.00, g = 1.00, b = 0.59 }
    end

    ---------------------------------------------------------

    -- Fallback to Blizzard's power bar colors
    return color
        or GetPowerBarColor(powerName)
        or GetPowerBarColor(resource)
        or GetPowerBarColor("MANA")
end

-- GET RESOURCE VALUES

local function GetPrimaryResourceValue(resource, cfg)
    if not resource then return nil, nil, nil, nil, nil end

    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil, nil, nil, nil, nil end

    if cfg.showManaAsPercent and resource == Enum.PowerType.Mana then
        local percent = SafeUnitPowerPercent("player", resource, false)
        if percent ~= nil then
            return max, max, current, percent, "percent"
        end
        return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
    else
        return max, max, current, current, "number"
    end
end

local function GetSecondaryResourceValue(resource, cfg)
    if not resource then return nil, nil, nil, nil, nil end

    -- Allow callers to pass config for formatting; fall back to current DB if omitted
    cfg = cfg or (NephUI.db and NephUI.db.profile and NephUI.db.profile.secondaryPowerBar) or {}

    if resource == "STAGGER" then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1
        return maxHealth, maxHealth, stagger, stagger, "number"
    end

    if resource == "SOUL" then
        -- DH souls – get from API instead of hooking Blizzard bar
        local spec = GetSpecialization()
        local specID = GetSpecializationInfo(spec)
        
        if specID == 581 then
            -- Vengeance: use Soul Cleave spell cast count
            local current = C_Spell.GetSpellCastCount(228477) or 0 -- Soul Cleave
            local max = 6
            return max, max, current, current, "number"
        elseif specID == 1480 then
            -- Devourer: use aura applications (Soul Fragments / Collapsing Star)
            local auraData = C_UnitAuras.GetPlayerAuraBySpellID(1225789) or C_UnitAuras.GetPlayerAuraBySpellID(1227702)
            local current = auraData and auraData.applications or 0
            local max = C_SpellBook.IsSpellKnown(1247534) and 35 or 50 -- Soul Glutton talent
            return max, max, current, current, "number"
        else
            -- Fallback (shouldn't happen, but just in case)
            return nil, nil, nil, nil, nil
        end
    end

    if resource == "MAELSTROM_WEAPON" then
        -- Enhancement Shaman Maelstrom Weapon buff tracking
        local auraData = C_UnitAuras.GetPlayerAuraBySpellID(344179) -- Maelstrom Weapon
        local current = auraData and auraData.applications or 0
        local max = 10

        return max, max, current, current, "number"
    end

    if resource == Enum.PowerType.Runes then
        local current = 0
        local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil, nil end

        for i = 1, max do
            local runeReady = select(3, GetRuneCooldown(i))
            if runeReady then
                current = current + 1
            end
        end

        if cfg.textFormat == "Percent" or cfg.textFormat == "Percent%" then
            return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
        else
            return max, max, current, current, "number"
        end
    end

    if resource == Enum.PowerType.SoulShards then
        local current = UnitPower("player", resource, true)
        local max = UnitPowerMax("player", resource, true)
        if max <= 0 then return nil, nil, nil, nil, nil end

        if cfg.textFormat == "Percent" or cfg.textFormat == "Percent%" then
            return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
        else
            return max, max / 10, current, current / 10, "number"
        end
    end

    -- Default case for all other power types (ComboPoints, Chi, HolyPower, Mana, etc.)
    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
        if max <= 0 then return nil, nil, nil, nil, nil end

    if cfg.showManaAsPercent and resource == Enum.PowerType.Mana then
        local percent = SafeUnitPowerPercent("player", resource, false)
        if percent ~= nil then
            return max, max, current, percent, "percent"
        end
        return max, max, current, math.floor((current / max) * 100 + 0.5), "percent"
    end

    return max, max, current, current, "number"
end

-- Export functions
NephUI.ResourceBars.GetPrimaryResource = GetPrimaryResource
NephUI.ResourceBars.GetSecondaryResource = GetSecondaryResource
NephUI.ResourceBars.GetResourceBarAssignment = GetResourceBarAssignment
NephUI.ResourceBars.GetAssignedResources = GetAssignedResources
NephUI.ResourceBars.IsSecondaryResourceForSpec = IsSecondaryResourceForSpec
NephUI.ResourceBars.GetDefaultBarAssignment = GetDefaultBarAssignment
NephUI.ResourceBars.GetResourceColor = GetResourceColor
NephUI.ResourceBars.GetPrimaryResourceValue = GetPrimaryResourceValue
NephUI.ResourceBars.GetSecondaryResourceValue = GetSecondaryResourceValue
NephUI.ResourceBars.GetChargedPowerPoints = GetChargedPowerPoints

