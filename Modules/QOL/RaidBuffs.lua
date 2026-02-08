local ADDON_NAME, ns = ...
local NephUI = ns.Addon

---------------------------------------------------------------------------
-- Missing Raid Buffs Panel
---------------------------------------------------------------------------

local RaidBuffs = {}
NephUI.RaidBuffs = RaidBuffs

local ICON_SIZE = 32
local ICON_SPACING = 1
local UPDATE_THROTTLE = 0.5
local MAX_AURA_INDEX = 40

local RAID_BUFFS = {
    {
        spellId = 21562,
        name = "Power Word: Fortitude",
        stat = "Stamina",
        providerClass = "PRIEST",
        range = 40,
    },
    {
        spellId = 6673,
        name = "Battle Shout",
        stat = "Attack Power",
        providerClass = "WARRIOR",
        range = 100,
    },
    {
        spellId = 1459,
        name = "Arcane Intellect",
        stat = "Intellect",
        providerClass = "MAGE",
        range = 40,
    },
    {
        spellId = 1126,
        name = "Mark of the Wild",
        stat = "Versatility",
        providerClass = "DRUID",
        range = 40,
    },
    {
        spellId = 381748,
        name = "Blessing of the Bronze",
        stat = "Movement Speed",
        providerClass = "EVOKER",
        range = 40,
    },
    {
        spellId = 462854,
        name = "Skyfury",
        stat = "Mastery",
        providerClass = "SHAMAN",
        range = 100,
    },
}

local function GetBuffIcon(spellId)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellId)
    elseif GetSpellTexture then
        return GetSpellTexture(spellId)
    end
    return 134400
end

local mainFrame
local buffIcons = {}
local lastUpdate = 0
local groupClasses = {}
local previewMode = false
local previewBuffs = nil
local anchorActive = false
local anchorPreviousPreview = nil

local function GetSettings()
    if NephUI and NephUI.db and NephUI.db.profile and NephUI.db.profile.qol and NephUI.db.profile.qol.raidBuffs then
        return NephUI.db.profile.qol.raidBuffs
    end
    return {
        enabled = true,
        showOnlyInGroup = true,
        showOnlyInInstance = false,
        providerMode = false,
        iconSize = 32,
        borderColor = { 0, 0, 0, 1 },
        position = nil,
    }
end

local function SafeGetAuraField(auraData, fieldName)
    local success, value = pcall(function() return auraData[fieldName] end)
    if not success then return nil end
    local compareOk = pcall(function() return value == value end)
    if not compareOk then return nil end
    return value
end

local function IsUnitInRange(unit, rangeYards)
    rangeYards = rangeYards or 40
    local rangeSquared = rangeYards * rangeYards

    if UnitDistanceSquared then
        local ok, distSq = pcall(UnitDistanceSquared, unit)
        if ok and distSq and type(distSq) == "number" then
            return distSq <= rangeSquared
        end
    end

    if rangeYards <= 30 and CheckInteractDistance then
        local ok2, canInteract = pcall(CheckInteractDistance, unit, 1)
        if ok2 and canInteract ~= nil then
            return canInteract
        end
    end

    if UnitInRange then
        local ok, inRange, checkedRange = pcall(UnitInRange, unit)
        if ok and checkedRange then
            if rangeYards > 28 and inRange then
                return true
            end
            return inRange
        end
    end

    return true
end

local function SafeUnitClass(unit)
    local ok, localized, class = pcall(UnitClass, unit)
    if ok and class and type(class) == "string" then
        return class
    end
    return nil
end

local function IsUnitAvailable(unit, rangeYards)
    if not UnitExists(unit) then return false end
    if UnitIsDeadOrGhost(unit) then return false end
    if not UnitIsConnected(unit) then return false end
    return IsUnitInRange(unit, rangeYards)
end

local function ScanGroupClasses()
    wipe(groupClasses)

    local playerClass = SafeUnitClass("player")
    if playerClass then
        groupClasses[playerClass] = true
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitExists(unit) and UnitIsConnected(unit) then
                local class = SafeUnitClass(unit)
                if class then
                    groupClasses[class] = true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            if UnitExists(unit) and UnitIsConnected(unit) then
                local class = SafeUnitClass(unit)
                if class then
                    groupClasses[class] = true
                end
            end
        end
    end
end

local function UnitHasBuff(unit, spellId, spellName)
    if not unit or not UnitExists(unit) then return false end

    if AuraUtil and AuraUtil.ForEachAura then
        local found = false
        AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(auraData)
            if auraData then
                local auraSpellId = SafeGetAuraField(auraData, "spellId")
                local auraName = SafeGetAuraField(auraData, "name")
                if auraSpellId and auraSpellId == spellId then
                    found = true
                elseif spellName and auraName and auraName == spellName then
                    found = true
                end
            end
            if found then return true end
        end, true)
        if found then return true end
    end

    if spellName and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local success, auraData = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, spellName, "HELPFUL")
        if success and auraData then return true end
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, MAX_AURA_INDEX do
            local success, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if not success or not auraData then break end
            local auraSpellId = SafeGetAuraField(auraData, "spellId")
            local auraName = SafeGetAuraField(auraData, "name")
            if auraSpellId and auraSpellId == spellId then
                return true
            elseif spellName and auraName and auraName == spellName then
                return true
            end
        end
    end

    return false
end

local function PlayerHasBuff(spellId, spellName)
    return UnitHasBuff("player", spellId, spellName)
end

local function AnyGroupMemberMissingBuff(spellId, spellName, rangeYards)
    if not PlayerHasBuff(spellId, spellName) then
        return true
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if IsUnitAvailable(unit, rangeYards) and not UnitIsUnit(unit, "player") then
                if not UnitHasBuff(unit, spellId, spellName) then
                    return true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            if IsUnitAvailable(unit, rangeYards) then
                if not UnitHasBuff(unit, spellId, spellName) then
                    return true
                end
            end
        end
    end

    return false
end

local function IsProviderClassInRange(providerClass, rangeYards)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if not UnitIsUnit(unit, "player") then
                local class = SafeUnitClass(unit)
                if class == providerClass and IsUnitAvailable(unit, rangeYards) then
                    return true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local class = SafeUnitClass(unit)
            if class == providerClass and IsUnitAvailable(unit, rangeYards) then
                return true
            end
        end
    end
    return false
end

local function GetMissingBuffs()
    local missing = {}
    local settings = GetSettings()

    if previewMode and previewBuffs then
        return previewBuffs
    end

    if settings.showOnlyInGroup and not IsInGroup() then
        return missing
    end

    if settings.showOnlyInInstance then
        local inInstance = IsInInstance()
        if not inInstance then
            return missing
        end
    end

    if InCombatLockdown() then
        return missing
    end

    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
        return missing
    end

    ScanGroupClasses()

    local playerClass = SafeUnitClass("player")

    for _, buff in ipairs(RAID_BUFFS) do
        local dominated = false
        local buffRange = buff.range or 40

        if groupClasses[buff.providerClass] and not PlayerHasBuff(buff.spellId, buff.name) then
            if IsProviderClassInRange(buff.providerClass, buffRange) then
                table.insert(missing, buff)
                dominated = true
            end
        end

        if settings.providerMode and not dominated then
            if buff.providerClass == playerClass and AnyGroupMemberMissingBuff(buff.spellId, buff.name, buffRange) then
                table.insert(missing, buff)
            end
        end
    end

    return missing
end

local function CreateBuffIcon(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button:EnableMouse(false)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    button:SetBackdropColor(0, 0, 0, 0.8)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    return button
end

local function CreateMainFrame()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "NephUI_MissingRaidBuffs", UIParent)
    mainFrame:SetSize(200, 70)
    mainFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local settings = GetSettings()
        if settings then
            local point, _, relPoint, x, y = self:GetPoint()
            settings.position = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)

    mainFrame.iconContainer = CreateFrame("Frame", nil, mainFrame)
    mainFrame.iconContainer:SetPoint("TOP", mainFrame, "TOP", 0, 0)
    mainFrame.iconContainer:SetSize(200, ICON_SIZE)
    mainFrame.iconContainer:EnableMouse(false)

    mainFrame.anchorLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainFrame.anchorLabel:SetPoint("CENTER", mainFrame, "CENTER", 0, 0)
    mainFrame.anchorLabel:SetText("Missing Riad Buffs")
    mainFrame.anchorLabel:Hide()

    for i = 1, #RAID_BUFFS do
        buffIcons[i] = CreateBuffIcon(mainFrame.iconContainer)
        buffIcons[i]:Hide()
    end

    mainFrame:Hide()
    return mainFrame
end

local function ApplySkin()
    if not mainFrame then return end

    local settings = GetSettings()
    local borderColor = settings.borderColor or { 0, 0, 0, 1 }

    for _, icon in ipairs(buffIcons) do
        icon:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        icon:SetBackdropColor(0, 0, 0, 0.8)
    end
end

function RaidBuffs:RefreshColors()
    ApplySkin()
end

local function UpdateDisplay()
    local settings = GetSettings()
    if not settings.enabled and not anchorActive then
        if mainFrame then mainFrame:Hide() end
        return
    end

    if not mainFrame then
        CreateMainFrame()
        ApplySkin()
    end

    local missing = GetMissingBuffs()
    if anchorActive then
        if not previewBuffs then
            previewBuffs = {}
            for i, buff in ipairs(RAID_BUFFS) do
                previewBuffs[i] = buff
            end
        end
        missing = previewBuffs
    end
    if #missing == 0 and not anchorActive then
        mainFrame:Hide()
        return
    end

    local iconSize = settings.iconSize or ICON_SIZE
    local totalWidth = (#missing * iconSize) + ((#missing - 1) * ICON_SPACING)
    local startX = -totalWidth / 2 + iconSize / 2

    for i, icon in ipairs(buffIcons) do
        if i <= #missing then
            local buff = missing[i]
            icon:SetSize(iconSize, iconSize)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", mainFrame.iconContainer, "CENTER", startX + (i - 1) * (iconSize + ICON_SPACING), 0)
            icon.icon:SetTexture(GetBuffIcon(buff.spellId))
            icon.buffData = buff
            icon:Show()
        else
            icon:Hide()
        end
    end

    local minIconsWidth = (3 * iconSize) + (2 * ICON_SPACING)
    local frameWidth = math.max(totalWidth, minIconsWidth)

    mainFrame.iconContainer:SetSize(frameWidth, iconSize)
    mainFrame:SetSize(frameWidth, iconSize)

    if settings.position then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(settings.position.point, UIParent, settings.position.relPoint, settings.position.x, settings.position.y)
    end

    if mainFrame.anchorLabel then
        mainFrame.anchorLabel:SetShown(anchorActive)
    end

    mainFrame:Show()
end

local function ThrottledUpdate()
    local now = GetTime()
    if now - lastUpdate < UPDATE_THROTTLE then return end
    lastUpdate = now
    UpdateDisplay()
end

local eventFrame = CreateFrame("Frame")

local function OnEvent(_, event, ...)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    if event == "PLAYER_LOGIN" then
        CreateMainFrame()
        ApplySkin()
        C_Timer.After(2, UpdateDisplay)
    elseif event == "GROUP_ROSTER_UPDATE" then
        ThrottledUpdate()
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            ThrottledUpdate()
        elseif unit and settings.providerMode and (unit:match("^party") or unit:match("^raid")) then
            ThrottledUpdate()
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        ThrottledUpdate()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(1, UpdateDisplay)
    elseif event == "UNIT_FLAGS" then
        local unit = ...
        if unit and (unit:match("^party") or unit:match("^raid")) then
            ThrottledUpdate()
        end
    elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" then
        ThrottledUpdate()
    end
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("UNIT_FLAGS")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_UNGHOST")
eventFrame:SetScript("OnEvent", OnEvent)

function RaidBuffs:Toggle()
    local settings = GetSettings()
    settings.enabled = not settings.enabled
    UpdateDisplay()
end

function RaidBuffs:ForceUpdate()
    UpdateDisplay()
    ApplySkin()
end

function RaidBuffs:GetFrame()
    return mainFrame
end

function RaidBuffs:TogglePreview()
    previewMode = not previewMode
    if previewMode then
        previewBuffs = {}
        for i, buff in ipairs(RAID_BUFFS) do
            previewBuffs[i] = buff
        end
    else
        previewBuffs = nil
    end
    UpdateDisplay()
    return previewMode
end

function RaidBuffs:IsPreviewMode()
    return previewMode
end

function RaidBuffs:EnableAnchor()
    if not anchorActive then
        anchorPreviousPreview = previewMode
    end
    anchorActive = true
    if not mainFrame then
        CreateMainFrame()
        ApplySkin()
    end
    if not previewMode then
        previewMode = true
        previewBuffs = {}
        for i, buff in ipairs(RAID_BUFFS) do
            previewBuffs[i] = buff
        end
    end
    UpdateDisplay()
end

function RaidBuffs:DisableAnchor()
    anchorActive = false
    previewMode = anchorPreviousPreview and true or false
    anchorPreviousPreview = nil
    if previewMode then
        previewBuffs = {}
        for i, buff in ipairs(RAID_BUFFS) do
            previewBuffs[i] = buff
        end
    else
        previewBuffs = nil
    end
    if mainFrame and mainFrame.anchorLabel then
        mainFrame.anchorLabel:Hide()
    end
    UpdateDisplay()
end
