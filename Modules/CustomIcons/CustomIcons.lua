local ADDON_NAME, ns = ...
local NephUI = ns.Addon

NephUI.CustomIcons = NephUI.CustomIcons or {}
local CustomIcons = NephUI.CustomIcons

local Widgets = NephUI.GUI and NephUI.GUI.Widgets
local THEME = NephUI.GUI and NephUI.GUI.THEME
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Forward declarations
local RefreshAllLayouts
local uiState

local SPEC_LIST = {
    {id=62, name="Arcane", classID=8, icon=135932},
    {id=63, name="Fire", classID=8, icon=135810},
    {id=64, name="Frost", classID=8, icon=135846},
    {id=65, name="Holy", classID=2, icon=135920},
    {id=66, name="Protection", classID=2, icon=236264},
    {id=70, name="Retribution", classID=2, icon=135873},
    {id=71, name="Arms", classID=1, icon=132355},
    {id=72, name="Fury", classID=1, icon=132347},
    {id=73, name="Protection", classID=1, icon=132341},
    {id=102, name="Balance", classID=11, icon=136096},
    {id=103, name="Feral", classID=11, icon=132115},
    {id=104, name="Guardian", classID=11, icon=132276},
    {id=105, name="Restoration", classID=11, icon=136041},
    {id=250, name="Blood", classID=6, icon=135770},
    {id=251, name="Frost", classID=6, icon=135773},
    {id=252, name="Unholy", classID=6, icon=135775},
    {id=253, name="Beast Mastery", classID=3, icon=461112},
    {id=254, name="Marksmanship", classID=3, icon=236179},
    {id=255, name="Survival", classID=3, icon=461113},
    {id=256, name="Discipline", classID=5, icon=135940},
    {id=257, name="Holy", classID=5, icon=237542},
    {id=258, name="Shadow", classID=5, icon=136207},
    {id=259, name="Assassination", classID=4, icon=236270},
    {id=260, name="Outlaw", classID=4, icon=236286},
    {id=261, name="Subtlety", classID=4, icon=132320},
    {id=262, name="Elemental", classID=7, icon=136048},
    {id=263, name="Enhancement", classID=7, icon=237581},
    {id=264, name="Restoration", classID=7, icon=136052},
    {id=265, name="Affliction", classID=9, icon=136145},
    {id=266, name="Demonology", classID=9, icon=136172},
    {id=267, name="Destruction", classID=9, icon=136186},
    {id=268, name="Brewmaster", classID=10, icon=608951},
    {id=269, name="Windwalker", classID=10, icon=608953},
    {id=270, name="Mistweaver", classID=10, icon=608952},
    {id=577, name="Havoc", classID=12, icon=1247264},
    {id=581, name="Vengeance", classID=12, icon=1247265},
    {id=1480, name="Devourer", classID=12, icon=7455385},
    {id=1467, name="Devastation", classID=13, icon=4511811},
    {id=1468, name="Preservation", classID=13, icon=4511812},
    {id=1473, name="Augmentation", classID=13, icon=5198700},
}

local function CreateBackdrop(frame, bgColor, borderColor)
    if not frame.SetBackdrop then
        if Mixin and BackdropTemplateMixin then
            Mixin(frame, BackdropTemplateMixin)
        else
            return
        end
    end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    if bgColor then
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    end
    if borderColor then
        frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    end
end

-- Runtime containers
local runtime = {
    iconFrames = {},  -- [iconKey] = frame
    groupFrames = {}, -- [groupKey] = frame
    dragState = {},
    pendingSpecReload = false,
}

-- UI state containers
local uiFrames = {
    listParent = nil,
    configParent = nil,
    searchBox = nil,
    resultText = nil,
    createFrame = nil,
    loadWindow = nil,
}

-- ------------------------
-- DB helpers
-- ------------------------
local DEFAULT_ICON_SETTINGS = {
    iconSize = 44,
    aspectRatio = 1.0,
    borderSize = 1,
    borderColor = { 0, 0, 0, 1 },
    showCharges = true,
    showCooldown = true,
    showGCDSwipe = false,
    desaturateWhenUnusable = true,
    desaturateOnCooldown = true,
    hideIfNotUsable = true,
    countSettings = {
        size = 16,
        anchor = "BOTTOMRIGHT",
        offsetX = -2,
        offsetY = 2,
        color = { 1, 1, 1, 1 },
    },
    cooldownSettings = {
        size = 12,
        color = { 1, 1, 1, 1 },
    },
}

local function CopyColor(color)
    if type(color) ~= "table" then return nil end
    return { color[1], color[2], color[3], color[4] }
end

local function EnsureIconSettings(iconData)
    if not iconData then return end
    iconData.settings = iconData.settings or {}
    local settings = iconData.settings

    if settings.iconSize == nil then settings.iconSize = DEFAULT_ICON_SETTINGS.iconSize end
    if settings.aspectRatio == nil then settings.aspectRatio = DEFAULT_ICON_SETTINGS.aspectRatio end
    if settings.borderSize == nil then settings.borderSize = DEFAULT_ICON_SETTINGS.borderSize end
    if settings.borderColor == nil then settings.borderColor = CopyColor(DEFAULT_ICON_SETTINGS.borderColor) end
    if settings.showCharges == nil then settings.showCharges = DEFAULT_ICON_SETTINGS.showCharges end
    if settings.showCooldown == nil then settings.showCooldown = DEFAULT_ICON_SETTINGS.showCooldown end
    if settings.showGCDSwipe == nil then settings.showGCDSwipe = DEFAULT_ICON_SETTINGS.showGCDSwipe end
    if settings.desaturateWhenUnusable == nil then settings.desaturateWhenUnusable = DEFAULT_ICON_SETTINGS.desaturateWhenUnusable end
    if settings.desaturateOnCooldown == nil then settings.desaturateOnCooldown = DEFAULT_ICON_SETTINGS.desaturateOnCooldown end
    if settings.hideIfNotUsable == nil then settings.hideIfNotUsable = DEFAULT_ICON_SETTINGS.hideIfNotUsable end

    settings.countSettings = settings.countSettings or {}
    if settings.countSettings.size == nil then settings.countSettings.size = DEFAULT_ICON_SETTINGS.countSettings.size end
    if settings.countSettings.anchor == nil then settings.countSettings.anchor = DEFAULT_ICON_SETTINGS.countSettings.anchor end
    if settings.countSettings.offsetX == nil then settings.countSettings.offsetX = DEFAULT_ICON_SETTINGS.countSettings.offsetX end
    if settings.countSettings.offsetY == nil then settings.countSettings.offsetY = DEFAULT_ICON_SETTINGS.countSettings.offsetY end
    if settings.countSettings.color == nil then settings.countSettings.color = CopyColor(DEFAULT_ICON_SETTINGS.countSettings.color) end

    settings.cooldownSettings = settings.cooldownSettings or {}
    if settings.cooldownSettings.size == nil then settings.cooldownSettings.size = DEFAULT_ICON_SETTINGS.cooldownSettings.size end
    if settings.cooldownSettings.color == nil then settings.cooldownSettings.color = CopyColor(DEFAULT_ICON_SETTINGS.cooldownSettings.color) end
end

local function GetDynamicDB()
    local profile = NephUI.db.profile
    profile.dynamicIcons = profile.dynamicIcons or {}
    local db = profile.dynamicIcons

    db.iconData = db.iconData or {}
    db.ungrouped = db.ungrouped or {}
    db.groups = db.groups or {}

    return db
end

local function EnsureLoadConditions(iconData)
    EnsureIconSettings(iconData)
    iconData.settings.loadConditions = iconData.settings.loadConditions or {
        enabled = false,
        specs = {},
        inCombat = false,
        outOfCombat = false,
    }
end

-- ------------------------
-- Icon updates
-- ------------------------
local IsCooldownFrameActive

local function UpdateItemIcon(iconFrame, iconData)
    local itemID = iconData.id
    if not itemID or not iconFrame then return end

    local start, duration = GetItemCooldown(itemID)
    local onCooldown = duration and duration > 1.5 and (start + duration - GetTime()) > 0
    if duration and duration > 1.5 then
        iconFrame.cooldown:SetCooldown(start, duration)
    else
        iconFrame.cooldown:Clear()
    end

    if iconData.settings and iconData.settings.showCooldown == false then
        iconFrame.cooldown:Hide()
    else
        if onCooldown then
            iconFrame.cooldown:Show()
        else
            iconFrame.cooldown:Hide()
        end
    end

    local includeCharges = iconData.settings and iconData.settings.showCharges
    local itemCount = C_Item.GetItemCount(itemID, false, includeCharges, false)
        if iconFrame.count then
        iconFrame.count:SetText(itemCount or 0)
        if iconData.settings and iconData.settings.showCharges == false then
            iconFrame.count:Hide()
        else
            iconFrame.count:Show()
        end
        end

    local allowCooldownDesat = not (iconData.settings and iconData.settings.desaturateOnCooldown == false)
    local allowUnusableDesat = not (iconData.settings and iconData.settings.desaturateWhenUnusable == false)

    local wantDesat = false
    local alpha = 1.0

    if itemCount == 0 or itemCount == nil then
        if allowUnusableDesat then
            wantDesat = true
            alpha = 1.0
        else
            wantDesat = allowCooldownDesat and onCooldown
            alpha = 1.0
        end
    elseif onCooldown then
        wantDesat = allowCooldownDesat
    end

    iconFrame.icon:SetDesaturated(wantDesat == true)
    iconFrame.icon:SetAlpha(alpha)
end

IsCooldownFrameActive = function(cooldownFrame)
    if not cooldownFrame then return false end
    -- Avoid arithmetic/comparisons on "secret" values; rely on the cooldown widget's own visibility.
    local ok, visible = pcall(cooldownFrame.IsVisible, cooldownFrame)
    return ok and visible == true
end

local function UpdateSpellIconFrame(iconFrame, iconData)
    local spellID = iconData.id
    if not spellID or not iconFrame then return end

    local allowDesat = not (iconData.settings and iconData.settings.desaturateOnCooldown == false)
    local allowUnusableDesat = not (iconData.settings and iconData.settings.desaturateWhenUnusable == false)
    local showGCDSwipe = (iconData.settings and iconData.settings.showGCDSwipe == true)

    -- Get cooldown info with protected call to handle secret values
    local cooldownSet = false
    local isOnCooldown = false
    local ignoreGCD = false
    local isGCDOnly = false
    local ok, cooldownInfo = pcall(C_Spell.GetSpellCooldown, spellID)
    if ok and cooldownInfo then
        local setOk = pcall(function()
            -- Ignore GCD-only updates so we don't desaturate just for the global cooldown.
            if cooldownInfo.isOnGCD == true then
                if not showGCDSwipe then
                    iconFrame.cooldown:Clear()
                    if iconFrame.cooldownProbe then
                        iconFrame.cooldownProbe:Clear()
                    end
                    cooldownSet = false
                    ignoreGCD = true
                    return
                end
                isGCDOnly = true
            end

            if cooldownInfo.duration and cooldownInfo.startTime then
                iconFrame.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
                if iconFrame.cooldownProbe then
                    iconFrame.cooldownProbe:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
                end
                cooldownSet = true
            end
        end)
        -- Do not early-return; we still need to handle usability/desat logic
    end

    -- Fallback to old API if C_Spell failed
    local fallbackOk = pcall(function()
        if ignoreGCD then return end
        local start, duration = GetSpellCooldown(spellID)
        if start and duration then
            iconFrame.cooldown:SetCooldown(start, duration)
            if iconFrame.cooldownProbe then
                iconFrame.cooldownProbe:SetCooldown(start, duration)
            end
            cooldownSet = true
        end
    end)

    -- Clear cooldown if we couldn't set it
    if not cooldownSet then
        iconFrame.cooldown:Clear()
        if iconFrame.cooldownProbe then
            iconFrame.cooldownProbe:Clear()
        end
    end

    if iconData.settings and iconData.settings.showCooldown == false then
        iconFrame.cooldown:Hide()
    end

    -- Get charges using C_Spell API with protected call.
    -- Important: for charge spells, we only desaturate when OUT of charges (0),
    -- and we only show the swipe while a charge is recharging.
    local chargesInfo
    local chargesOk = pcall(function()
        chargesInfo = C_Spell.GetSpellCharges(spellID)
    end)
    local isChargeSpell = chargesOk and chargesInfo
    local charges = chargesOk and chargesInfo and chargesInfo.currentCharges

    -- Count display: do not compare charge values (can be secret). Just attempt to set text.
    local hasChargesText = false
    if isChargeSpell and iconData.settings and iconData.settings.showCharges == false then
        iconFrame.count:Hide()
    else
        hasChargesText = pcall(iconFrame.count.SetText, iconFrame.count, charges)
        if hasChargesText then
            iconFrame.count:Show()
        else
            iconFrame.count:SetText("")
            iconFrame.count:Hide()
        end
    end

    -- Cooldown state uses the probe so user "Hide Cooldown" doesn't affect logic.
    local cooldownActive = IsCooldownFrameActive(iconFrame.cooldownProbe or iconFrame.cooldown)
    isOnCooldown = cooldownActive and not isGCDOnly

    local rechargeActive = false
    if isChargeSpell then
        if chargesInfo.cooldownStartTime and chargesInfo.cooldownDuration then
            pcall(function()
                iconFrame.cooldown:SetCooldown(chargesInfo.cooldownStartTime, chargesInfo.cooldownDuration)
                if iconFrame.cooldownChargeProbe then
                    iconFrame.cooldownChargeProbe:SetCooldown(chargesInfo.cooldownStartTime, chargesInfo.cooldownDuration)
                end
            end)
            rechargeActive = IsCooldownFrameActive(iconFrame.cooldownChargeProbe or iconFrame.cooldown)
        else
            iconFrame.cooldown:Clear()
            if iconFrame.cooldownChargeProbe then
                iconFrame.cooldownChargeProbe:Clear()
            end
        end
    end

    -- Only show the cooldown swipe when enabled.
    if not (iconData.settings and iconData.settings.showCooldown == false) then
        if isChargeSpell then
            -- For charge recharges, avoid the dark swipe "background" fill; keep just the edge indicator.
            pcall(iconFrame.cooldown.SetSwipeColor, iconFrame.cooldown, 0, 0, 0, 0)
            pcall(iconFrame.cooldown.SetDrawEdge, iconFrame.cooldown, rechargeActive == true)
            if rechargeActive then
                iconFrame.cooldown:Show()
            else
                iconFrame.cooldown:Hide()
            end
        else
            -- Normal cooldowns use the standard dark swipe fill.
            pcall(iconFrame.cooldown.SetSwipeColor, iconFrame.cooldown, 0, 0, 0, 0.8)
            -- Do not draw an edge for normal spell cooldowns (edge reserved for charge recharge indicator).
            pcall(iconFrame.cooldown.SetDrawEdge, iconFrame.cooldown, false)
            -- If showing GCD swipes, allow display while on GCD but do not desaturate for it.
            local displayActive = cooldownActive
            if isGCDOnly and not showGCDSwipe then
                displayActive = false
            end
            if displayActive then
                iconFrame.cooldown:Show()
            else
                iconFrame.cooldown:Hide()
            end
        end
    else
        -- Cooldown hidden: ensure edge doesn't get stuck on from previous updates.
        pcall(iconFrame.cooldown.SetDrawEdge, iconFrame.cooldown, false)
    end

    -- Check usability (fallback for different WoW versions)
    local usable = false
    if C_Spell and C_Spell.IsSpellUsable then
        local okUsable, usableVal = pcall(C_Spell.IsSpellUsable, spellID)
        if okUsable then
            usable = usableVal == true
        end
    elseif IsUsableSpell then
        local okUsable, usableVal = pcall(IsUsableSpell, spellID)
        if okUsable then
            usable = usableVal == true
        end
    else
        -- Fallback: assume usable if spell exists
        usable = true
    end

    if usable then
        -- For charge spells: only desaturate when you're out of charges, which matches main cooldown active.
        local shouldDesaturate = isOnCooldown
        if allowDesat and shouldDesaturate then
            iconFrame.icon:SetDesaturated(true)
            iconFrame.icon:SetAlpha(1.0)
        else
            iconFrame.icon:SetDesaturated(false)
            iconFrame.icon:SetAlpha(1.0)
        end
    else
        if allowUnusableDesat then
            iconFrame.icon:SetDesaturated(true)
            iconFrame.icon:SetAlpha(1.0)
        else
            iconFrame.icon:SetDesaturated(false)
            iconFrame.icon:SetAlpha(1.0)
        end
    end
end

local function UpdateSlotIcon(iconFrame, iconData)
    local slotID = iconData.slotID
    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then
        iconFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        iconFrame.cooldown:Clear()
        iconFrame.count:Hide()
        return
    end

    local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if itemTexture then
        iconFrame.icon:SetTexture(itemTexture)
    end

    local start, duration = GetInventoryItemCooldown("player", slotID)
    local onCooldown = duration and duration > 1.5 and (start + duration - GetTime()) > 0
    if duration and duration > 1.5 then
        iconFrame.cooldown:SetCooldown(start, duration)
    else
        iconFrame.cooldown:Clear()
    end

    if iconData.settings and iconData.settings.showCooldown == false then
        iconFrame.cooldown:Hide()
    else
        if onCooldown then
            iconFrame.cooldown:Show()
        else
            iconFrame.cooldown:Hide()
        end
    end

    local allowDesat = not (iconData.settings and iconData.settings.desaturateOnCooldown == false)
    if allowDesat and onCooldown then
        iconFrame.icon:SetDesaturated(true)
    else
        iconFrame.icon:SetDesaturated(false)
    end
end

local function SafeSetBackdrop(frame, backdropInfo, borderColor)
    if not frame or not frame.SetBackdrop then return end
        if InCombatLockdown() then
            if not NephUI.__cdmPendingBackdrops then
                NephUI.__cdmPendingBackdrops = {}
            end
        NephUI.__cdmPendingBackdrops[frame] = {backdropInfo = backdropInfo, borderColor = borderColor}
            if not NephUI.__cdmBackdropEventFrame then
                local eventFrame = CreateFrame("Frame")
                eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            eventFrame:SetScript("OnEvent", function()
                for pending, settings in pairs(NephUI.__cdmPendingBackdrops) do
                    if pending and pending.SetBackdrop then
                        pcall(pending.SetBackdrop, pending, settings.backdropInfo)
                                        if settings.borderColor then
                            pcall(pending.SetBackdropBorderColor, pending, unpack(settings.borderColor))
                        end
                            end
                        end
                        NephUI.__cdmPendingBackdrops = {}
                end)
                NephUI.__cdmBackdropEventFrame = eventFrame
            end
        return
    end

    pcall(frame.SetBackdrop, frame, backdropInfo)
    if borderColor then
        pcall(frame.SetBackdropBorderColor, frame, unpack(borderColor))
    end
end

local function ApplyIconBorder(iconFrame, settings)
    if not iconFrame or not iconFrame.border then return end
    local edgeSize = settings.borderSize or 0
    if edgeSize <= 0 then
        iconFrame.border:Hide()
        SafeSetBackdrop(iconFrame.border, nil)
        return
        end

            local backdropInfo = {
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = edgeSize,
            }
    SafeSetBackdrop(iconFrame.border, backdropInfo, settings.borderColor or {0, 0, 0, 1})
    iconFrame.border:Show()
                local offset = edgeSize
    iconFrame.border:ClearAllPoints()
    iconFrame.border:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -offset, offset)
    iconFrame.border:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", offset, -offset)
end

local function BuildCountSettings(iconSettings)
    local cs = iconSettings.countSettings or {}
    return {
        size = cs.size or 16,
        anchor = cs.anchor or "BOTTOMRIGHT",
        offsetX = cs.offsetX or -2,
        offsetY = cs.offsetY or 2,
        color = cs.color or {1, 1, 1, 1},
        font = cs.font,  -- Font name from LSM, nil means use global font
    }
end

local function ApplyCooldownTextStyle(cooldown, iconData)
    if not cooldown or not cooldown.GetRegions then return end

    local fontString
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            fontString = region
            break
        end
    end
    if not fontString then return end

    local cds = (iconData.settings and iconData.settings.cooldownSettings) or {}
    local fontPath = NephUI:GetGlobalFont()
    local size = cds.size or 12
    local color = cds.color or { 1, 1, 1, 1 }

    -- Reuse general viewer shadow offsets for consistency
    local shadowOffsetX = 1
    local shadowOffsetY = -1
    if NephUI.db and NephUI.db.profile and NephUI.db.profile.viewers and NephUI.db.profile.viewers.general then
        shadowOffsetX = NephUI.db.profile.viewers.general.cooldownShadowOffsetX or shadowOffsetX
        shadowOffsetY = NephUI.db.profile.viewers.general.cooldownShadowOffsetY or shadowOffsetY
    end

    local _, _, flags = fontString:GetFont()
    fontString:SetFont(fontPath, size, flags)
    fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    fontString:SetShadowOffset(shadowOffsetX, shadowOffsetY)
end

local function ApplyAspectRatioCrop(texture, aspect, baseZoom)
    if not texture or not texture.SetTexCoord then return end

    aspect = tonumber(aspect) or 1.0
    if aspect <= 0 then aspect = 1.0 end

    baseZoom = tonumber(baseZoom) or 0
    if baseZoom < 0 then baseZoom = 0 end
    if baseZoom > 0.499 then baseZoom = 0.499 end

    local left, right, top, bottom = baseZoom, 1 - baseZoom, baseZoom, 1 - baseZoom
    local regionW = right - left
    local regionH = bottom - top

    if regionW > 0 and regionH > 0 and aspect ~= 1.0 then
        local currentRatio = regionW / regionH
        if aspect > currentRatio then
            local desiredH = regionW / aspect
            local cropH = (regionH - desiredH) / 2
            top = top + cropH
            bottom = bottom - cropH
        elseif aspect < currentRatio then
            local desiredW = regionH * aspect
            local cropW = (regionW - desiredW) / 2
            left = left + cropW
            right = right - cropW
        end
    end

    texture:SetTexCoord(left, right, top, bottom)
end

local function ApplyIconSettings(iconFrame, iconData)
    EnsureIconSettings(iconData)
    local settings = iconData.settings or {}
    local size = settings.iconSize or DEFAULT_ICON_SETTINGS.iconSize
    local aspect = settings.aspectRatio or 1.0
    local width = size
    local height = size
    if aspect > 1.0 then
        height = size / aspect
    elseif aspect < 1.0 then
        width = size * aspect
    end
    iconFrame:SetSize(width, height)

    if iconFrame.icon then
        iconFrame.icon:ClearAllPoints()
        iconFrame.icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
        iconFrame.icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
        -- Mirror CooldownViewer behavior: crop instead of stretching when aspect ratio changes.
        ApplyAspectRatioCrop(iconFrame.icon, aspect, 0.08)
    end

    ApplyIconBorder(iconFrame, {
        borderSize = settings.borderSize or DEFAULT_ICON_SETTINGS.borderSize,
        borderColor = settings.borderColor or DEFAULT_ICON_SETTINGS.borderColor,
    })

    local cs = BuildCountSettings(settings)
    local fontPath = NephUI:GetGlobalFont()
    if cs.font and LSM then
        local fetchedFont = LSM:Fetch("font", cs.font)
        if fetchedFont then
            fontPath = fetchedFont
        end
    end
    iconFrame.count:SetFont(fontPath, cs.size, "OUTLINE")
    if cs.color then
        iconFrame.count:SetTextColor(unpack(cs.color))
    end
    iconFrame.count:ClearAllPoints()
    iconFrame.count:SetPoint(cs.anchor, iconFrame, cs.anchor, cs.offsetX, cs.offsetY)

    -- Apply cooldown text settings
    local cooldownSettings = settings.cooldownSettings or {size = 12, color = {1, 1, 1, 1}}
    if iconFrame.cooldown.SetCountdownFont then
        local cdFontPath = NephUI:GetGlobalFont()
        iconFrame.cooldown:SetCountdownFont(cdFontPath, cooldownSettings.size, "OUTLINE")
    end
    ApplyCooldownTextStyle(iconFrame.cooldown, iconData)
    -- Note: Cooldown text color is not directly controllable with standard WoW cooldown frames.
    -- The color setting is saved but may not be applied depending on WoW API limitations.
end

-- ------------------------
-- Event-based update system
-- ------------------------
local function UpdateAllIcons()
    -- Update all active icon frames
    for iconKey, frame in pairs(runtime.iconFrames) do
        if frame and frame:IsVisible() then
            local db = GetDynamicDB()
            local iconData = db.iconData[iconKey]
            if iconData then
                ApplyIconSettings(frame, iconData)
                if iconData.type == "item" then
                    UpdateItemIcon(frame, iconData)
                elseif iconData.type == "spell" then
                    UpdateSpellIconFrame(frame, iconData)
                elseif iconData.type == "slot" then
                    UpdateSlotIcon(frame, iconData)
                end
            end
        end
    end
end

local function HandleCooldownDone(cooldownFrame)
    local parent = cooldownFrame and cooldownFrame:GetParent()
    local iconKey = parent and parent._iconKey
    if iconKey and runtime.UpdateDynamicIcon then
        runtime.UpdateDynamicIcon(iconKey)
        return
    end
    UpdateAllIcons()
end

local function ScheduleSpecReload()
    if runtime.pendingSpecReload then return end
    runtime.pendingSpecReload = true

    C_Timer.After(0.05, function()
        runtime.pendingSpecReload = false
        if CustomIcons and CustomIcons.LoadDynamicIcons then
            CustomIcons:LoadDynamicIcons()
        else
            if RefreshAllLayouts then RefreshAllLayouts() end
            UpdateAllIcons()
        end
        if CustomIcons and CustomIcons.RefreshAnchorVisibility then
            CustomIcons:RefreshAnchorVisibility()
        end
    end)
end

local function EnsureEventFrame()
    if runtime.eventFrame then return end
    runtime.eventFrame = CreateFrame("Frame")

    -- Register for events that should trigger icon updates
    runtime.eventFrame:RegisterEvent("BAG_UPDATE")                    -- Bag contents change
    runtime.eventFrame:RegisterEvent("ITEM_COUNT_CHANGED")             -- Item counts change
    runtime.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")          -- Spell cooldowns change
    runtime.eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")           -- Spell charges change
    runtime.eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")            -- Spells become usable/unusable (often at cooldown end)
    runtime.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")      -- Cooldown updates (reliable at cooldown end)
    runtime.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")         -- Equipment changes
    runtime.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")       -- Equipment changes (alternative event)
    runtime.eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")  -- Spec change
    runtime.eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")   -- Talent group/spec change (alternative event)
    runtime.eventFrame:RegisterEvent("SPELLS_CHANGED")                -- Spellbook changes (often after spec change)

    runtime.eventFrame:SetScript("OnEvent", function(self, event, ...)
        local arg1 = ...

        -- Only update for events that affect the player
        if event == "UNIT_INVENTORY_CHANGED" then
            if arg1 ~= "player" then return end
        end

        if event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 and arg1 ~= "player" then
            return
        end

        if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "SPELLS_CHANGED" then
            ScheduleSpecReload()
            return
        end

        -- When equipment changes, reload slot icons to check if they should be shown/hidden
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
            -- Reload all icons to check slot icon usability
            -- This will use IsIconLoadable which now checks if slot items are usable
            if CustomIcons and CustomIcons.LoadDynamicIcons then
                CustomIcons:LoadDynamicIcons()
            end
        end

        -- Update all icons when relevant events fire
        UpdateAllIcons()
    end)
end

-- ------------------------
-- Visual helpers
-- ------------------------
local function GetAnchorFrame(anchorName)
    if not anchorName or anchorName == "" then
        return UIParent
    end
    return _G[anchorName] or UIParent
end

local function IsSpellInPlayerBook(spellID)
    if not spellID then return false end

    -- Use the new Dragonflight API that checks if spell is actually known for current spec
    -- Includes handling of spell overrides/replacements
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.FindBaseSpellByID and C_SpellBook.FindSpellOverrideByID and Enum and Enum.SpellBookSpellBank then
        local bank = Enum.SpellBookSpellBank.Player

        -- Direct check first
        local ok, result = pcall(C_SpellBook.IsSpellKnown, spellID, bank)
        if ok and result then
            return true
        end

        -- Check base spell if this might be an override
        ok, result = pcall(C_SpellBook.FindBaseSpellByID, spellID)
        if ok and result and result ~= spellID then
            ok, result = pcall(C_SpellBook.IsSpellKnown, result, bank)
            if ok and result then
                return true
            end
        end

        -- Check override spell if this might be a base
        ok, result = pcall(C_SpellBook.FindSpellOverrideByID, spellID)
        if ok and result and result ~= spellID then
            ok, result = pcall(C_SpellBook.IsSpellKnown, result, bank)
            if ok and result then
                return true
            end
        end

        return false
    end

    -- Fallback to old API for backward compatibility
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
        local ok, result = pcall(C_SpellBook.IsSpellInSpellBook, spellID)
        if ok then
            return result == true
        end
    end

    -- Fallback: assume available if API missing/failed
    return true
end

local function IsSlotItemUsable(slotID)
    if not slotID then return false end
    
    local itemID = GetInventoryItemID("player", slotID)
    if not itemID then return false end
    
    -- Check if item has a use effect (spell) - this is the primary indicator of usability
    local itemSpell = GetItemSpell(itemID)
    if itemSpell then
        return true
    end
    
    -- Check if item is usable via C_Item API (most reliable check)
    if C_Item and C_Item.IsItemUsable then
        local isUsable = C_Item.IsItemUsable(itemID)
        if isUsable then
            return true
        end
    end
    
    -- If neither check indicates usability, the item is not usable
    return false
end

local function IsIconLoadable(iconData)
    if not iconData then return false end
    if iconData.type == "spell" then
        return IsSpellInPlayerBook(iconData.id)
    elseif iconData.type == "slot" then
        -- Check if hideIfNotUsable is enabled (defaults to true)
        local hideIfNotUsable = iconData.settings and iconData.settings.hideIfNotUsable
        if hideIfNotUsable == nil then hideIfNotUsable = true end -- Default to true
        
        -- If hideIfNotUsable is enabled, only load slot icons if the equipped item is usable
        if hideIfNotUsable then
            return IsSlotItemUsable(iconData.slotID)
        else
            -- If disabled, always load the icon (even if item is not usable)
            return true
        end
    end
    return true
end

-- (moved above UpdateSpellIconFrame via forward declaration)

local function GetCurrentSpecID()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        local id = GetSpecializationInfo(specIndex)
        return id
    end
    return nil
end

local function ShouldIconSpawn(iconData)
    if not iconData then return false end
    -- Spellbook gating
    if iconData.type == "spell" and not IsSpellInPlayerBook(iconData.id) then
        return false
    end
    
    -- Slot item usability gating - only spawn if item is usable (respects hideIfNotUsable setting)
    if iconData.type == "slot" and not IsIconLoadable(iconData) then
        return false
    end

    EnsureLoadConditions(iconData)
    local lc = iconData.settings.loadConditions or {}
    if not lc.enabled then
        return true
    end


    -- Spec conditions
    if lc.specs then
        local anySpecSet = false
        for _, v in pairs(lc.specs) do
            if v then anySpecSet = true break end
        end
        if anySpecSet then
            local currentSpec = GetCurrentSpecID()
            if not currentSpec or not lc.specs[currentSpec] then
                return false
            end
        end
    end

    return true
end

local function ResolveAnchorPoints(anchorPoint)
    if anchorPoint == "TOPLEFT" then
        return "BOTTOMLEFT", "TOPLEFT"
    elseif anchorPoint == "TOPRIGHT" then
        return "BOTTOMRIGHT", "TOPRIGHT"
    elseif anchorPoint == "BOTTOMLEFT" then
        return "TOPLEFT", "BOTTOMLEFT"
    elseif anchorPoint == "BOTTOMRIGHT" then
        return "TOPRIGHT", "BOTTOMRIGHT"
    elseif anchorPoint == "TOP" then
        return "BOTTOM", "TOP"
    elseif anchorPoint == "BOTTOM" then
        return "TOP", "BOTTOM"
    elseif anchorPoint == "LEFT" then
        return "RIGHT", "LEFT"
    elseif anchorPoint == "RIGHT" then
        return "LEFT", "RIGHT"
    end
    return "CENTER", "CENTER"
end

function CustomIcons:ShowLoadConditionsWindow(iconKey, iconData)
    EnsureLoadConditions(iconData)
    -- If a window already exists, discard it and rebuild to guarantee fresh bindings
    if uiFrames.loadWindow then
        uiFrames.loadWindow:Hide()
        uiFrames.loadWindow = nil
    end

    local lc = iconData.settings.loadConditions

    local f = CreateFrame("Frame", "NephUI_LoadConditions", UIParent, "BackdropTemplate")
    f:SetSize(360, 460)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0},
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetBackdropBorderColor(0.2, 0.6, 1, 1)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -10)
    f.title:SetText("Load Conditions")

    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    f.close:SetScript("OnClick", function() f:Hide() end)

    -- Enable toggle
    local enableBtn = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    enableBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -36)
    enableBtn.text:SetText("Enable Load Conditions")
    enableBtn:SetChecked(lc.enabled == true)
    enableBtn:SetScript("OnClick", function(self)
        lc.enabled = self:GetChecked() or false
        if RefreshAllLayouts then RefreshAllLayouts() end
    end)

    -- Specs header
    local specHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specHeader:SetPoint("TOPLEFT", enableBtn, "BOTTOMLEFT", 4, -12)
    specHeader:SetText("By Specialization")

    -- Spec scroll
    local specScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    specScroll:SetPoint("TOPLEFT", specHeader, "BOTTOMLEFT", -4, -8)
    specScroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 12)

    local specChild = CreateFrame("Frame", nil, specScroll)
    specChild:SetWidth(300)
    specChild:SetHeight(400)
    specScroll:SetScrollChild(specChild)

    local y = 0
    lc.specs = lc.specs or {}
    for _, spec in ipairs(SPEC_LIST) do
        local row = CreateFrame("Frame", nil, specChild)
        row:SetSize(280, 26)
        row:SetPoint("TOPLEFT", specChild, "TOPLEFT", 0, -y)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        icon:SetTexture(spec.icon)

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        name:SetText(spec.name)

        local toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        toggle:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        toggle:SetChecked(lc.specs[spec.id] == true)
        toggle:SetScript("OnClick", function(self)
            lc.specs[spec.id] = self:GetChecked() or false
            if RefreshAllLayouts then RefreshAllLayouts() end
        end)

        y = y + 28
    end
    specChild:SetHeight(y)

    uiFrames.loadWindow = f
end

-- ------------------------
-- Base icon creation
-- ------------------------
local function CreateBaseIcon(name, parent)
    local frame = CreateFrame("Button", name, parent, "BackdropTemplate")
    frame:SetSize(40, 40)
    
    local icon = frame:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    border:SetAllPoints(frame)
    border:Hide()
    
    local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cd:SetAllPoints(frame)
    -- Edge highlight is enabled dynamically (e.g. charge recharge), default off.
    cd:SetDrawEdge(false)
    cd:SetDrawSwipe(true)
    cd:SetSwipeColor(0, 0, 0, 0.8)
    cd:SetHideCountdownNumbers(false)
    cd:SetReverse(false)

    -- Probe cooldown: used for cooldown-state checks without being affected by user "Hide Cooldown" setting.
    local cdProbe = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cdProbe:SetAllPoints(frame)
    cdProbe:SetDrawEdge(false)
    cdProbe:SetDrawSwipe(true)
    cdProbe:SetSwipeColor(0, 0, 0, 0)
    cdProbe:SetHideCountdownNumbers(true)
    cdProbe:SetReverse(false)
    cdProbe:SetAlpha(0)

    -- Charge probe: used to detect whether a charge is recharging (show swipe) without affecting main cooldown state.
    local cdChargeProbe = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cdChargeProbe:SetAllPoints(frame)
    cdChargeProbe:SetDrawEdge(false)
    cdChargeProbe:SetDrawSwipe(true)
    cdChargeProbe:SetSwipeColor(0, 0, 0, 0)
    cdChargeProbe:SetHideCountdownNumbers(true)
    cdChargeProbe:SetReverse(false)
    cdChargeProbe:SetAlpha(0)

    cd:SetScript("OnCooldownDone", HandleCooldownDone)
    cdProbe:SetScript("OnCooldownDone", HandleCooldownDone)
    cdChargeProbe:SetScript("OnCooldownDone", HandleCooldownDone)
    
    local countLayer = CreateFrame("Frame", nil, frame)
    countLayer:SetFrameLevel(frame:GetFrameLevel() + 2)
    countLayer:SetAllPoints(frame)

    local count = countLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetJustifyH("RIGHT")
    count:SetTextColor(1, 1, 1, 1)
    count:SetShadowOffset(0, 0)
    count:SetShadowColor(0, 0, 0, 1)

    frame.icon = icon
    frame.cooldown = cd
    frame.cooldownProbe = cdProbe
    frame.cooldownChargeProbe = cdChargeProbe
    frame.count = count
    frame.border = border
    
    frame:EnableMouse(true)
    return frame
end

-- ------------------------
-- Icon creation per type
-- ------------------------
local function CreateItemIcon(iconKey, iconData, parent)
    local itemID = iconData.id
    if not itemID then return nil end

    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    if not itemName then
        C_Item.RequestLoadItemDataByID(itemID)
        return nil
    end

    local frame = CreateBaseIcon("NephUI_DynItem_" .. iconKey, parent)
    frame._type = "item"
    frame._itemID = itemID
    frame._iconKey = iconKey
    frame.icon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    return frame
end

local function CreateSpellIcon(iconKey, iconData, parent)
    local spellID = iconData.id
    if not spellID or not IsSpellInPlayerBook(spellID) then return nil end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then
        C_Spell.RequestLoadSpellData(spellID)
        return nil
    end

    local frame = CreateBaseIcon("NephUI_DynSpell_" .. iconKey, parent)
    frame._type = "spell"
    frame._spellID = spellID
    frame._iconKey = iconKey
    local tex = spellInfo.iconID or C_Spell.GetSpellTexture(spellID)
    frame.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    return frame
end

local function CreateSlotIcon(iconKey, iconData, parent)
    local slotID = iconData.slotID
    if not slotID then return nil end

    local frame = CreateBaseIcon("NephUI_DynSlot_" .. iconKey, parent)
    frame._type = "slot"
    frame._slotID = slotID
    frame._iconKey = iconKey
    local itemID = GetInventoryItemID("player", slotID)
    if itemID then
        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
        if itemTexture then
            frame.icon:SetTexture(itemTexture)
        end
    end
    return frame
end

local function CreateDynamicIcon(iconKey, iconData, parent)
    if iconData.type == "item" then
        return CreateItemIcon(iconKey, iconData, parent)
    elseif iconData.type == "spell" then
        return CreateSpellIcon(iconKey, iconData, parent)
    elseif iconData.type == "slot" then
        return CreateSlotIcon(iconKey, iconData, parent)
    end
    return nil
end

local function UpdateDynamicIcon(iconKey)
    local db = GetDynamicDB()
    local iconData = db.iconData[iconKey]
    local frame = runtime.iconFrames[iconKey]
    if not iconData or not frame then return end

    ApplyIconSettings(frame, iconData)
    if iconData.type == "item" then
        UpdateItemIcon(frame, iconData)
    elseif iconData.type == "spell" then
        UpdateSpellIconFrame(frame, iconData)
    elseif iconData.type == "slot" then
        UpdateSlotIcon(frame, iconData)
    end
end

runtime.UpdateDynamicIcon = UpdateDynamicIcon

-- ------------------------
-- Group layout
-- ------------------------
local function GetStartAnchorForGrowth(growth)
    if growth == "LEFT" then
        return "TOPRIGHT"
    elseif growth == "UP" then
        return "BOTTOMLEFT"
    end
    return "TOPLEFT"
end

local function GetDefaultRowGrowth(growth)
    if growth == "LEFT" or growth == "RIGHT" then
        return "DOWN"
    end
    return "RIGHT"
end

local function NormalizeRowGrowth(growth, rowGrowth)
    if growth == "LEFT" or growth == "RIGHT" then
        if rowGrowth ~= "UP" and rowGrowth ~= "DOWN" then
            return "DOWN"
        end
        return rowGrowth
    end
    if rowGrowth ~= "LEFT" and rowGrowth ~= "RIGHT" then
        return "RIGHT"
    end
    return rowGrowth
end

local function GetStartAnchorForGrowthPair(growth, rowGrowth)
    local g = growth or "RIGHT"
    local rg = NormalizeRowGrowth(g, rowGrowth or GetDefaultRowGrowth(g))

    local top = (g == "LEFT" or g == "RIGHT" or rg == "DOWN")
    local left = (g == "RIGHT" or rg == "RIGHT")

    if top and left then return "TOPLEFT" end
    if top and not left then return "TOPRIGHT" end
    if not top and left then return "BOTTOMLEFT" end
    return "BOTTOMRIGHT"
end

local function BuildDefaultSettings(growth)
    local g = growth or "RIGHT"
    local rg = NormalizeRowGrowth(g, GetDefaultRowGrowth(g))
    local startAnchor = GetStartAnchorForGrowthPair(g, rg)
    return {
        growthDirection = g,
        rowGrowthDirection = rg,
        anchorFrom = startAnchor,
        anchorTo = startAnchor,
        spacing = 5,
        maxIconsPerRow = 10,
        position = {x = 0, y = -200},
    }
end

local function BuildDefaultUngroupedPositionSettings()
    local settings = BuildDefaultSettings("RIGHT")
    settings.anchorFrom = "CENTER"
    settings.anchorTo = "CENTER"
    settings.position = { x = 0, y = 0 }
    return settings
end

local function NormalizeAnchor(settings)
    if not settings then return end
    if settings.anchorPoint and not settings.anchorFrom and not settings.anchorTo then
        settings.anchorFrom = settings.anchorPoint
        settings.anchorTo = settings.anchorPoint
        settings.anchorPoint = nil
    end
    if settings.anchorPoint then
        settings.anchorPoint = nil
    end
    settings.rowGrowthDirection = settings.rowGrowthDirection or GetDefaultRowGrowth(settings.growthDirection or "RIGHT")
    settings.rowGrowthDirection = NormalizeRowGrowth(settings.growthDirection or "RIGHT", settings.rowGrowthDirection)
    if settings.maxIconsPerRow == nil and settings.maxColumns ~= nil then
        settings.maxIconsPerRow = settings.maxColumns
        settings.maxColumns = nil
    end
    settings.anchorFrom = settings.anchorFrom or GetStartAnchorForGrowthPair(settings.growthDirection or "RIGHT", settings.rowGrowthDirection)
    settings.anchorTo = settings.anchorTo or settings.anchorFrom
end

local function GetGroupSettings(groupKey)
    local db = GetDynamicDB()
    if groupKey == "ungrouped" then
        db.ungroupedSettings = db.ungroupedSettings or BuildDefaultSettings("RIGHT")
        NormalizeAnchor(db.ungroupedSettings)
        return db.ungroupedSettings
    end
    if db.iconData[groupKey] and db.ungrouped[groupKey] then
        db.ungroupedPositions = db.ungroupedPositions or {}
        db.ungroupedPositions[groupKey] = db.ungroupedPositions[groupKey] or BuildDefaultUngroupedPositionSettings()
        NormalizeAnchor(db.ungroupedPositions[groupKey])
        return db.ungroupedPositions[groupKey]
    end
    if db.groups[groupKey] then
        db.groups[groupKey].settings = db.groups[groupKey].settings or BuildDefaultSettings(db.groups[groupKey].growthDirection or "RIGHT")
        NormalizeAnchor(db.groups[groupKey].settings)
        return db.groups[groupKey].settings
    end
    local defaults = BuildDefaultSettings("RIGHT")
    NormalizeAnchor(defaults)
    return defaults
end

local function GetGroupDisplayName(groupKey)
    if groupKey == "ungrouped" then
        return "Ungrouped"
    end
    local db = GetDynamicDB()
    if db.iconData[groupKey] and db.ungrouped[groupKey] then
        local iconData = db.iconData[groupKey]
        if iconData then
            if iconData.type == "item" then
                return GetItemInfo(iconData.id) or ("Item " .. iconData.id)
            elseif iconData.type == "spell" then
                local info = C_Spell.GetSpellInfo(iconData.id)
                return (info and info.name) or ("Spell " .. iconData.id)
            elseif iconData.type == "slot" then
                return ("Slot " .. (iconData.slotID or ""))
            end
        end
    end
    local group = db.groups[groupKey]
    if group and group.name and group.name ~= "" then
        return group.name
    end
    return groupKey
end

local function EnsureGroupFrame(groupKey, settings)
    settings = settings or GetGroupSettings(groupKey)
    NormalizeAnchor(settings)
    if runtime.groupFrames[groupKey] then
        return runtime.groupFrames[groupKey]
    end

    -- Create the main container frame
    local container = CreateFrame("Frame", "NephUI_DynGroup_" .. groupKey, UIParent)
    container:SetSize(100, 100) -- Initial size, will be recalculated
    container:SetMovable(true) -- Container itself must be movable
    container:SetClampedToScreen(true)

    -- Create the drag anchor (similar to WeakAuras mover)
    local anchor = CreateFrame("Frame", container:GetName() .. "_Anchor", container, "BackdropTemplate")
    anchor:SetAllPoints(container)
    anchor:SetFrameStrata("HIGH")
    anchor:Hide() -- Hidden by default, shown when in config mode
    anchor:SetBackdrop(nil) -- No visual overlay; text-only anchor

    -- Add group name text to anchor
    local anchorText = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorText:SetPoint("CENTER")
    anchorText:SetText(GetGroupDisplayName(groupKey))
    anchorText:SetTextColor(1, 1, 1, 1)

    -- Make the anchor draggable
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", function(self)
        container:StartMoving()
    end)
    anchor:SetScript("OnDragStop", function(self)
        container:StopMovingOrSizing()
        -- Save new position
        local point, _, relativePoint, x, y = container:GetPoint()
        settings.position = settings.position or {}
        settings.position.x = x
        settings.position.y = y
        settings.anchorFrom = point
        settings.anchorTo = relativePoint or point
        -- Update settings in DB
        local db = GetDynamicDB()
        if db.groups[groupKey] then
            db.groups[groupKey].settings = settings
        elseif groupKey == "ungrouped" then
            db.ungroupedSettings = settings
        end
    end)

    container.anchor = anchor
    container.anchorText = anchorText
    container._settings = settings
    container._groupKey = groupKey

    -- Position the container
    if settings.position then
        local anchorFrame = GetAnchorFrame(settings.anchorFrame)
        local containerPoint = settings.anchorFrom or GetStartAnchorForGrowth(settings.growthDirection or "RIGHT")
        local anchorPoint = settings.anchorTo or containerPoint
        container:ClearAllPoints()
        container:SetPoint(containerPoint, anchorFrame, anchorPoint, settings.position.x or 0, settings.position.y or 0)
    else
        local containerPoint = GetStartAnchorForGrowth(settings.growthDirection or "RIGHT")
        container:SetPoint(containerPoint, UIParent, containerPoint, 0, -200)
    end

    runtime.groupFrames[groupKey] = container
    return container
end

local function LayoutGroup(groupKey, iconKeys)
    local db = GetDynamicDB()
    local groupSettings = GetGroupSettings(groupKey)
    local growth = groupSettings.growthDirection or "RIGHT"
    local settings = groupSettings
    growth = settings.growthDirection or growth
    settings.rowGrowthDirection = settings.rowGrowthDirection or GetDefaultRowGrowth(growth)
    settings.rowGrowthDirection = NormalizeRowGrowth(growth, settings.rowGrowthDirection)

    if not iconKeys or #iconKeys == 0 then
        local container = runtime.groupFrames[groupKey]
        if container then
            container:Hide()
        end
        return
    end

    local container = EnsureGroupFrame(groupKey, settings)
    container:Show()

    local spacing = settings.spacing or 5
    local maxPerRow = settings.maxIconsPerRow
    if maxPerRow == nil and settings.maxColumns ~= nil then
        maxPerRow = settings.maxColumns
        settings.maxIconsPerRow = maxPerRow
        settings.maxColumns = nil
    end
    maxPerRow = maxPerRow or 10

    local iconSizes = {}

    for _, iconKey in ipairs(iconKeys) do
        local iconFrame = runtime.iconFrames[iconKey]
        if iconFrame then
            local iconData = db.iconData[iconKey]
            local borderSize = 0
            if iconData then
                ApplyIconSettings(iconFrame, iconData)
                borderSize = math.max((iconData.settings and iconData.settings.borderSize) or 0, 0)
            end
            local w, h = iconFrame:GetWidth(), iconFrame:GetHeight()
            table.insert(iconSizes, {width = w + borderSize * 2, height = h + borderSize * 2, border = borderSize})
        end
    end

    local startAnchor = GetStartAnchorForGrowthPair(growth, settings.rowGrowthDirection)

    local function borderInsetForAnchor(anchor, border)
        if not border or border <= 0 then return 0, 0 end
        local dx = (anchor:find("LEFT") and border) or -border
        local dy = (anchor:find("TOP") and -border) or border
        return dx, dy
    end

    -- Layout in offsets relative to container startAnchor (x right+, y up+)
    local positions = {}
    local minLeft, maxRight = 0, 0
    local minBottom, maxTop = 0, 0

    local rowBaseX, rowBaseY = 0, 0
    local along = 0
    local rowThickness = 0
    local countInRow = 0
    local iconGrowthIsHorizontal = (growth == "LEFT" or growth == "RIGHT")

    local function advanceRow()
        local step = rowThickness + spacing
        local rg = settings.rowGrowthDirection
        if rg == "RIGHT" then
            rowBaseX = rowBaseX + step
        elseif rg == "LEFT" then
            rowBaseX = rowBaseX - step
        elseif rg == "UP" then
            rowBaseY = rowBaseY + step
        else -- DOWN
            rowBaseY = rowBaseY - step
        end
        along = 0
        rowThickness = 0
        countInRow = 0
    end

    local function accumulateBounds(anchor, xOff, yOff, w, h)
        local left, right, top, bottom
        if anchor == "TOPLEFT" then
            left, right = xOff, xOff + w
            top, bottom = yOff, yOff - h
        elseif anchor == "TOPRIGHT" then
            right, left = xOff, xOff - w
            top, bottom = yOff, yOff - h
        elseif anchor == "BOTTOMLEFT" then
            left, right = xOff, xOff + w
            bottom, top = yOff, yOff + h
        else -- BOTTOMRIGHT
            right, left = xOff, xOff - w
            bottom, top = yOff, yOff + h
        end
        minLeft = math.min(minLeft, left)
        maxRight = math.max(maxRight, right)
        minBottom = math.min(minBottom, bottom)
        maxTop = math.max(maxTop, top)
    end

    for i, iconSize in ipairs(iconSizes) do
        local w, h = iconSize.width, iconSize.height
        local xOff, yOff = rowBaseX, rowBaseY

        if growth == "RIGHT" then
            xOff = rowBaseX + along
        elseif growth == "LEFT" then
            xOff = rowBaseX - along
        elseif growth == "UP" then
            yOff = rowBaseY + along
        else -- DOWN
            yOff = rowBaseY - along
        end

        positions[i] = {x = xOff, y = yOff, width = w, height = h, border = iconSize.border or 0}
        accumulateBounds(startAnchor, xOff, yOff, w, h)

        countInRow = countInRow + 1
        if iconGrowthIsHorizontal then
            along = along + w + spacing
            rowThickness = math.max(rowThickness, h)
        else
            along = along + h + spacing
            rowThickness = math.max(rowThickness, w)
        end

        if countInRow >= maxPerRow then
            advanceRow()
        end
    end

    local contentWidth = maxRight - minLeft
    local contentHeight = maxTop - minBottom

    for i, iconKey in ipairs(iconKeys) do
        local iconFrame = runtime.iconFrames[iconKey]
        local pos = positions[i]
        if iconFrame and pos then
            local dx, dy = borderInsetForAnchor(startAnchor, pos.border or 0)
            iconFrame:ClearAllPoints()
            iconFrame:SetParent(container)
            iconFrame:SetPoint(startAnchor, container, startAnchor, (pos.x or 0) + dx, (pos.y or 0) + dy)
            iconFrame:Show()
        end
    end

    container:SetSize(contentWidth, contentHeight)

    -- Re-apply anchor using stored anchor points
    if settings.position then
        local containerPoint = settings.anchorFrom or startAnchor
        local anchorFrame = GetAnchorFrame(settings.anchorFrame)
        local anchorPoint = settings.anchorTo or containerPoint
        container:ClearAllPoints()
        container:SetPoint(containerPoint, anchorFrame, anchorPoint, settings.position.x or 0, settings.position.y or 0)
    end

    -- Update anchor if it exists
    if container.anchor then
        container.anchor:SetAllPoints(container)
        -- Update anchor text if name has changed
        if container.anchorText then
            container.anchorText:SetText(GetGroupDisplayName(groupKey))
        end
    end
end

local function RefreshAllLayouts()
    local db = GetDynamicDB()

    -- Build ungrouped list (one anchor per ungrouped icon)
    local ungroupedKeys = {}
    for iconKey, _ in pairs(db.ungrouped) do
        table.insert(ungroupedKeys, iconKey)
    end
    table.sort(ungroupedKeys)
    for _, iconKey in ipairs(ungroupedKeys) do
        db.ungroupedPositions = db.ungroupedPositions or {}
        db.ungroupedPositions[iconKey] = db.ungroupedPositions[iconKey] or BuildDefaultUngroupedPositionSettings()
        if ShouldIconSpawn(db.iconData[iconKey]) then
            LayoutGroup(iconKey, {iconKey})
        else
            local cont = runtime.groupFrames[iconKey]
            if cont then cont:Hide() end
            local frame = runtime.iconFrames[iconKey]
            if frame then frame:Hide() end
        end
    end

    -- Groups
    for groupKey, group in pairs(db.groups) do
        local keys = {}
        local seen = {}
        for _, k in ipairs(group.icons or {}) do
            if db.iconData[k] and not seen[k] and ShouldIconSpawn(db.iconData[k]) then
                table.insert(keys, k)
                seen[k] = true
            else
                local frame = runtime.iconFrames[k]
                if frame then frame:Hide() end
            end
        end
        LayoutGroup(groupKey, keys)
        end
    end

local function FindIconGroup(iconKey, db)
    if db.ungrouped[iconKey] then return "ungrouped" end
    for gk, group in pairs(db.groups) do
        for _, k in ipairs(group.icons or {}) do
            if k == iconKey then
                return gk
            end
        end
    end
    return "ungrouped"
end

function CustomIcons:LoadDynamicIcons()
    EnsureEventFrame()
    local db = GetDynamicDB()
    for iconKey, iconData in pairs(db.iconData) do
        EnsureLoadConditions(iconData)
        if IsIconLoadable(iconData) then
            local groupKey = FindIconGroup(iconKey, db)
            local settings
            if groupKey == "ungrouped" or db.ungrouped[iconKey] then
                db.ungroupedPositions = db.ungroupedPositions or {}
                db.ungroupedPositions[iconKey] = db.ungroupedPositions[iconKey] or BuildDefaultUngroupedPositionSettings()
                settings = db.ungroupedPositions[iconKey]
                groupKey = iconKey
            else
                settings = GetGroupSettings(groupKey)
            end
            local parent = EnsureGroupFrame(groupKey, settings)
            local frame = runtime.iconFrames[iconKey]
            if not frame then
                frame = CreateDynamicIcon(iconKey, iconData, parent)
                if frame then
                    runtime.iconFrames[iconKey] = frame
                end
            end
        else
            -- Hide/clear frames for spells not in the spellbook
            local frame = runtime.iconFrames[iconKey]
            if frame then
                frame:Hide()
                frame:SetParent(nil)
                runtime.iconFrames[iconKey] = nil
            end
        end
    end
    RefreshAllLayouts()
    -- Initial update to ensure icons show correct state
    UpdateAllIcons()
end

function CustomIcons:CreateCustomIconsTrackerFrame()
    if not NephUI.db.profile.customIcons.enabled then return nil end

    -- Create the main container frame (for backwards compatibility)
    if not NephUI.customIconsTrackerFrame then
        NephUI.customIconsTrackerFrame = CreateFrame("Frame", "NephUI_CustomIconsTrackerFrame", UIParent)
        NephUI.customIconsTrackerFrame:SetSize(200, 40)
        NephUI.customIconsTrackerFrame:SetFrameStrata("MEDIUM")
        NephUI.customIconsTrackerFrame:SetClampedToScreen(true)
        NephUI.customIconsTrackerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        NephUI.customIconsTrackerFrame._NephUI_CustomIconsTracker = true
    end

    -- Load all dynamic icons
    self:LoadDynamicIcons()

    return NephUI.customIconsTrackerFrame
end

-- ------------------------
-- Public API
-- ------------------------
function CustomIcons:AddDynamicIcon(iconData)
    local db = GetDynamicDB()
    local iconKey = iconData.key or ("icon_" .. tostring(math.floor(GetTime() * 1000)))
    iconData.key = iconKey
    EnsureIconSettings(iconData)
    EnsureLoadConditions(iconData)

    db.iconData[iconKey] = iconData
    EnsureLoadConditions(db.iconData[iconKey])
    db.ungrouped[iconKey] = true
    db.ungroupedPositions = db.ungroupedPositions or {}
    db.ungroupedPositions[iconKey] = db.ungroupedPositions[iconKey] or BuildDefaultUngroupedPositionSettings()

    -- Build frame
    local frame = CreateDynamicIcon(iconKey, iconData, EnsureGroupFrame(iconKey, db.ungroupedPositions[iconKey]))
    if frame then
        runtime.iconFrames[iconKey] = frame
        UpdateDynamicIcon(iconKey)
        RefreshAllLayouts()
    else
        C_Timer.After(0.5, function()
            CustomIcons:LoadDynamicIcons()
        end)
    end

    CustomIcons:RefreshDynamicListUI()
    return iconKey
end

function CustomIcons:RemoveDynamicIcon(iconKey)
    local db = GetDynamicDB()
    db.iconData[iconKey] = nil
    db.ungrouped[iconKey] = nil
    if db.ungroupedPositions then
        db.ungroupedPositions[iconKey] = nil
    end
    for _, group in pairs(db.groups) do
        for i = #group.icons, 1, -1 do
            if group.icons[i] == iconKey then
                table.remove(group.icons, i)
            end
        end
    end

    local frame = runtime.iconFrames[iconKey]
    if frame then
        frame:Hide()
        frame:SetParent(nil)
        runtime.iconFrames[iconKey] = nil
    end

    RefreshAllLayouts()
    CustomIcons:RefreshDynamicListUI()
end

function CustomIcons:CreateDynamicGroup(name)
    local db = GetDynamicDB()
    local key = "group_" .. tostring(math.floor(GetTime() * 1000))
    local startAnchor = GetStartAnchorForGrowthPair("RIGHT", "DOWN")
    db.groups[key] = {
        name = name or "New Group",
        icons = {},
        settings = {
            growthDirection = "RIGHT",
            rowGrowthDirection = "DOWN",
            anchorFrom = startAnchor,
            anchorTo = startAnchor,
            spacing = 5,
            maxIconsPerRow = 10,
            -- No default position - will be set when first icon is added
        },
    }
    RefreshAllLayouts()
    CustomIcons:RefreshDynamicListUI()
    return key
end

function CustomIcons:RemoveGroup(groupKey)
    local db = GetDynamicDB()
    local group = db.groups[groupKey]
    if not group then return end
    for _, iconKey in ipairs(group.icons or {}) do
        db.ungrouped[iconKey] = true
    end
    db.groups[groupKey] = nil
    if uiState and uiState.selectedGroup == groupKey then
        uiState.selectedGroup = nil
    end
    RefreshAllLayouts()
    CustomIcons:RefreshDynamicListUI()
    CustomIcons:RefreshDynamicConfigUI()

    -- Sync anchor visibility with global state when opening the UI
    CustomIcons:RefreshAnchorVisibility()
end

function CustomIcons:MoveIconToGroup(iconKey, targetGroup)
    local db = GetDynamicDB()
    local function removeFromGroup(gkey)
        local group = db.groups[gkey]
        if not group or not group.icons then return end
        for i = #group.icons, 1, -1 do
            if group.icons[i] == iconKey then
                table.remove(group.icons, i)
            end
        end
    end

    if targetGroup == "ungrouped" then
        db.ungrouped[iconKey] = true
        db.ungroupedPositions = db.ungroupedPositions or {}
        db.ungroupedPositions[iconKey] = db.ungroupedPositions[iconKey] or BuildDefaultUngroupedPositionSettings()
    else
        db.ungrouped[iconKey] = nil
        if db.ungroupedPositions then
            db.ungroupedPositions[iconKey] = nil
        end
        if db.groups[targetGroup] then
            db.groups[targetGroup].icons = db.groups[targetGroup].icons or {}
            -- Ensure the icon is not already present to avoid duplicates
            removeFromGroup(targetGroup)

            -- If this is the first icon in the group, position the group at the icon's current location
            if #db.groups[targetGroup].icons == 0 then
                local iconFrame = runtime.iconFrames[iconKey]
                if iconFrame then
                    local iconX, iconY = iconFrame:GetCenter()
                    if iconX and iconY then
                        -- Convert from world coordinates to relative coordinates
                        local uiScale = UIParent:GetEffectiveScale()
                        iconX = iconX / uiScale
                        iconY = iconY / uiScale

                        -- Get the current anchor frame
                        local settings = db.groups[targetGroup].settings or {}
                        local anchorFrame = GetAnchorFrame(settings.anchorFrame)

                        -- Calculate position relative to anchor frame
                        local anchorX, anchorY = anchorFrame:GetCenter()
                        anchorX = anchorX / uiScale
                        anchorY = anchorY / uiScale

                        settings.position = {
                            x = iconX - anchorX,
                            y = iconY - anchorY
                        }
                        db.groups[targetGroup].settings = settings
                    end
                end
            end

            table.insert(db.groups[targetGroup].icons, iconKey)
        end
    end

    -- Remove from other groups
    for gk, group in pairs(db.groups) do
        for i = #group.icons, 1, -1 do
            if group.icons[i] == iconKey and gk ~= targetGroup then
                table.remove(group.icons, i)
            end
        end
    end

    -- Destroy standalone container when moving into a group
    if targetGroup ~= "ungrouped" then
        local cont = runtime.groupFrames[iconKey]
        if cont then
            cont:Hide()
            runtime.groupFrames[iconKey] = nil
        end
    end

    RefreshAllLayouts()
    CustomIcons:RefreshDynamicListUI()
end

function CustomIcons:ReorderIconInGroup(groupKey, iconKey, beforeKey)
    local db = GetDynamicDB()
    if groupKey == "ungrouped" then
        -- preserve set semantics for ungrouped; sorting not needed
        return
    end
    local group = db.groups[groupKey]
    if not group or not group.icons then return end

    -- remove existing
    for i = #group.icons, 1, -1 do
        if group.icons[i] == iconKey then
            table.remove(group.icons, i)
        end
    end

    -- insert before target or at end
    local inserted = false
    if beforeKey then
        for i, k in ipairs(group.icons) do
            if k == beforeKey then
                table.insert(group.icons, i, iconKey)
                inserted = true
                break
            end
        end
    end
    if not inserted then
        table.insert(group.icons, iconKey)
    end

    RefreshAllLayouts()
end

-- ------------------------
-- GUI (lightweight WeakAuras-like list)
-- ------------------------
uiState = {
    searchText = "",
    selectedIcon = nil,
    selectedGroup = nil,
    collapsedGroups = {},
}

local function MatchesSearch(iconKey, iconData)
    if uiState.searchText == "" then return true end
    local query = string.lower(uiState.searchText)
    local name = ""
    if iconData.type == "item" then
        name = GetItemInfo(iconData.id) or ("Item " .. iconData.id)
    elseif iconData.type == "spell" then
        local info = C_Spell.GetSpellInfo(iconData.id)
        name = (info and info.name) or ("Spell " .. iconData.id)
    elseif iconData.type == "slot" then
        name = ("Slot " .. (iconData.slotID or ""))
    end
    name = string.lower(tostring(name))
    local idStr = tostring(iconData.id or iconData.slotID or "")
    return name:find(query) or idStr:find(query)
end

local function CreateIconNode(parent, iconKey, iconData, groupKey)
    local node = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    node:SetSize(240, 42)
    node:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0},
    })
    node:SetBackdropColor(THEME.bgMedium[1], THEME.bgMedium[2], THEME.bgMedium[3], 0.75)
    node:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.9)
    node._iconKey = iconKey
    node._hover = false

    local function applyNodeHighlight()
        local isSelected = uiState.selectedIcon == iconKey
        local bg = THEME.bgMedium
        local border = THEME.border
        local alpha = 0.75
        if isSelected then
            bg = THEME.bgDark
            border = THEME.primary
            alpha = 0.95
        elseif node._hover then
            bg = THEME.bgDark
            border = THEME.primary
            alpha = 0.85
        end
        node:SetBackdropColor(bg[1], bg[2], bg[3], alpha)
        node:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    end

    node.iconTex = node:CreateTexture(nil, "ARTWORK")
    node.iconTex:SetSize(32, 32)
    node.iconTex:SetPoint("LEFT", node, "LEFT", 6, 0)
    node.iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if iconData.type == "item" then
        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(iconData.id)
        node.iconTex:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    elseif iconData.type == "spell" then
        local info = C_Spell.GetSpellInfo(iconData.id)
        node.iconTex:SetTexture((info and info.iconID) or C_Spell.GetSpellTexture(iconData.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
    elseif iconData.type == "slot" then
        local iid = GetInventoryItemID("player", iconData.slotID)
        local _, _, _, _, _, _, _, _, _, tex = iid and GetItemInfo(iid)
        node.iconTex:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    end

    local label = node:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", node.iconTex, "RIGHT", 6, 6)
    label:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)

    local displayName = ""
    if iconData.type == "item" then
        displayName = GetItemInfo(iconData.id) or ("Item ID: " .. iconData.id)
    elseif iconData.type == "spell" then
        local info = C_Spell.GetSpellInfo(iconData.id)
        displayName = (info and info.name) or ("Spell ID: " .. iconData.id)
    elseif iconData.type == "slot" then
        displayName = "Slot " .. tostring(iconData.slotID or "")
    end
    label:SetText(displayName)

    local badge = node:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint("LEFT", label, "LEFT", 0, -12)
    badge:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 0.9)
    badge:SetText(string.upper(iconData.type))

    local deleteBtn = CreateFrame("Button", nil, node, "UIPanelCloseButton")
    deleteBtn:SetSize(16, 16)
    deleteBtn:SetPoint("TOPRIGHT", node, "TOPRIGHT", -4, -4)
    deleteBtn:SetScript("OnClick", function()
        CustomIcons:ConfirmDeleteIcon(iconKey, displayName)
    end)

    node:SetScript("OnMouseUp", function()
        uiState.selectedIcon = iconKey
        uiState.selectedGroup = nil
        CustomIcons:RefreshDynamicListUI()
        CustomIcons:RefreshDynamicConfigUI()
    end)
    node:SetScript("OnEnter", function()
        node._hover = true
        applyNodeHighlight()
        if runtime.dragState.dragging then
            runtime.dragState.targetGroup = groupKey
            runtime.dragState.dropBefore = iconKey
        end
    end)
    node:SetScript("OnLeave", function()
        node._hover = false
        applyNodeHighlight()
        if runtime.dragState.dragging then
            runtime.dragState.dropBefore = nil
        end
    end)

    node:RegisterForDrag("LeftButton")
    node:SetScript("OnDragStart", function()
        runtime.dragState.iconKey = iconKey
        runtime.dragState.sourceGroup = groupKey
        runtime.dragState.dropBefore = nil
        runtime.dragState.dragging = true
        node:SetAlpha(0.35)
    end)
    node:SetScript("OnDragStop", function()
        if runtime.dragState.dragging then
            local targetGroup = runtime.dragState.targetGroup or runtime.dragState.sourceGroup
            local beforeKey = runtime.dragState.dropBefore
            if targetGroup then
                if targetGroup ~= runtime.dragState.sourceGroup then
                    CustomIcons:MoveIconToGroup(iconKey, targetGroup)
                end
                CustomIcons:ReorderIconInGroup(targetGroup, iconKey, beforeKey)
            end
        end
        runtime.dragState.iconKey = nil
        runtime.dragState.targetGroup = nil
        runtime.dragState.dropBefore = nil
        runtime.dragState.dragging = false
        node:SetAlpha(1)
        CustomIcons:RefreshDynamicListUI()
    end)

    applyNodeHighlight()
    return node
end

-- UI containers
local uiFrames = {
    listParent = nil,
    configParent = nil,
    searchBox = nil,
    resultText = nil,
    createFrame = nil,
    loadWindow = nil,
}

function CustomIcons:RefreshDynamicListUI()
    if not uiFrames.listParent then return end
    local db = GetDynamicDB()

    -- Clear children
    for _, child in ipairs({uiFrames.listParent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local y = -5
    local shown = 0
    local total = 0

    local function renderSection(title, iconKeys, groupKey)
        local isCollapsed = uiState.collapsedGroups[groupKey] == true
        local isSelectedGroup = uiState.selectedGroup == groupKey
        local headerHover = false

        local box = CreateFrame("Frame", nil, uiFrames.listParent, "BackdropTemplate")
        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1},
        })
        box:SetBackdropColor(THEME.bgDark[1], THEME.bgDark[2], THEME.bgDark[3], 0.4)
        box:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.8)
        box:SetPoint("TOPLEFT", uiFrames.listParent, "TOPLEFT", -2, y)
        box:SetPoint("TOPRIGHT", uiFrames.listParent, "TOPRIGHT", 2, y)

        local header = CreateFrame("Button", nil, box)
        header:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4)
        header:SetPoint("TOPRIGHT", box, "TOPRIGHT", -4, -4)
        header:SetHeight(22)

        local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerText:SetPoint("LEFT", header, "LEFT", 4, 0)
        headerText:SetTextColor(THEME.primary[1], THEME.primary[2], THEME.primary[3], 1)
        headerText:SetText(title)

        local arrowBtn = CreateFrame("Button", nil, header)
        arrowBtn:SetSize(24, 24)
        arrowBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
        local function updateArrow()
            if uiState.collapsedGroups[groupKey] == true then
                arrowBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
            else
                arrowBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
            end
        end
        updateArrow()
        arrowBtn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")

        local function applyBoxHighlight()
            local bg = isSelectedGroup and THEME.bgDark or THEME.bgMedium
            local alpha = isSelectedGroup and 0.9 or 0.6
            local border = (isSelectedGroup or headerHover) and THEME.primary or THEME.border
            box:SetBackdropColor(bg[1], bg[2], bg[3], alpha)
            box:SetBackdropBorderColor(border[1], border[2], border[3], 1)
        end
        applyBoxHighlight()

        header:SetScript("OnEnter", function()
            headerHover = true
            if runtime.dragState.iconKey then
                runtime.dragState.targetGroup = groupKey
            end
            applyBoxHighlight()
        end)
        header:SetScript("OnLeave", function()
            headerHover = false
            if runtime.dragState.targetGroup == groupKey then
                runtime.dragState.targetGroup = nil
            end
            applyBoxHighlight()
        end)
        header:SetScript("OnMouseUp", function()
            uiState.selectedGroup = groupKey
            uiState.selectedIcon = nil
            isSelectedGroup = true
            applyBoxHighlight()
            CustomIcons:RefreshDynamicListUI()
            CustomIcons:RefreshDynamicConfigUI()
        end)
        header:SetScript("OnClick", nil)

        arrowBtn:SetScript("OnClick", function()
            uiState.collapsedGroups[groupKey] = not (uiState.collapsedGroups[groupKey] == true)
            CustomIcons:RefreshDynamicListUI()
        end)

        local innerY = -28
        if not isCollapsed then
            for _, iconKey in ipairs(iconKeys) do
                local iconData = db.iconData[iconKey]
                if iconData then
                    total = total + 1
                    if MatchesSearch(iconKey, iconData) then
                        local node = CreateIconNode(box, iconKey, iconData, groupKey)
                        node:SetPoint("TOPLEFT", box, "TOPLEFT", 8, innerY)
                        innerY = innerY - 46
                        shown = shown + 1
                    end
                end
            end
        else
            -- Count totals even when collapsed for result text
            for _, iconKey in ipairs(iconKeys) do
                if db.iconData[iconKey] then
                    total = total + 1
                end
            end
        end

        local boxHeight = math.abs(innerY) + 8
        box:SetHeight(boxHeight)
        y = y - boxHeight - 8
    end

    -- Sort icons by type (Spell, Item, Slot) then by key for consistent organization
    local function iconTypeOrder(iconKey)
        local d = db.iconData[iconKey]
        if not d or not d.type then return 4 end
        if d.type == "spell" then return 1 end
        if d.type == "item" then return 2 end
        if d.type == "slot" then return 3 end
        return 4
    end
    local function sortIconsByTypeThenKey(a, b)
        local oa, ob = iconTypeOrder(a), iconTypeOrder(b)
        if oa ~= ob then return oa < ob end
        return tostring(a) < tostring(b)
    end

    -- Ungrouped
    local ungroupedKeys = {}
    for k in pairs(db.ungrouped) do
        table.insert(ungroupedKeys, k)
    end
    table.sort(ungroupedKeys, sortIconsByTypeThenKey)
    renderSection("Ungrouped Icons", ungroupedKeys, "ungrouped")

    for groupKey, group in pairs(db.groups) do
        local keys = {}
        local seen = {}
        for _, k in ipairs(group.icons or {}) do
            if db.iconData[k] and not seen[k] then
                table.insert(keys, k)
                seen[k] = true
            end
        end
        table.sort(keys, sortIconsByTypeThenKey)
        renderSection(GetGroupDisplayName(groupKey), keys, groupKey)
    end

    if uiFrames.resultText then
        uiFrames.resultText:SetText(string.format("Showing %d of %d icons", shown, total))
    end

    uiFrames.listParent:SetHeight(math.abs(y) + 20)
end

function CustomIcons:RefreshDynamicConfigUI()
    if not uiFrames.configParent then return end
    for _, child in ipairs({uiFrames.configParent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local db = GetDynamicDB()
    local iconKey = uiState.selectedIcon
    local groupKey = uiState.selectedGroup
    local iconData = iconKey and db.iconData[iconKey]
    local selectedGroup = groupKey and db.groups[groupKey]

    local y = 0
    local function addSectionHeader(title)
        Widgets.CreateHeader(uiFrames.configParent, { name = title }, y)
        y = y + 32
    end
    local function addSlider(text, min, max, step, getter, setter)
        local slider = Widgets.CreateRange(uiFrames.configParent, {
            name = text,
            min = min,
            max = max,
            step = step,
            get = function() return getter() end,
            set = function(_, val)
                setter(val)
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicListUI()
            end,
            width = "full",
        }, y, {})  -- Pass empty optionsTable
        slider.slider:SetObeyStepOnDrag(true)
        slider.slider:SetValue(getter())
        y = y + 36
    end

    local function showIconConfig()
        -- Identity (spell/item/slot-specific)
        if iconData.type == "spell" then
            addSectionHeader("Identity")
            Widgets.CreateInput(uiFrames.configParent, {
                name = "Spell ID",
                get = function() return tostring(iconData.id or "") end,
                set = function(_, val)
                    local n = tonumber(val)
                    if n and n > 0 then
                        iconData.id = n
                        if iconKey and runtime.UpdateDynamicIcon then
                            runtime.UpdateDynamicIcon(iconKey)
                        end
                        RefreshAllLayouts()
                        CustomIcons:RefreshDynamicListUI()
                    end
                end,
                width = "full",
            }, y)
            y = y + 40
        end

        addSectionHeader("Appearance")
        addSlider("Icon Size", 16, 128, 1, function() return iconData.settings.iconSize or 40 end, function(val) iconData.settings.iconSize = val end)
        addSlider("Aspect Ratio", 0.5, 2.0, 0.01, function() return iconData.settings.aspectRatio or 1.0 end, function(val) iconData.settings.aspectRatio = val end)
        addSlider("Border Size", 0, 10, 1, function() return iconData.settings.borderSize or DEFAULT_ICON_SETTINGS.borderSize end, function(val) iconData.settings.borderSize = val end)

        -- Border Color
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Border Color",
            get = function() return unpack(iconData.settings.borderColor or {1, 1, 1, 1}) end,
            set = function(_, r, g, b, a)
                iconData.settings.borderColor = {r, g, b, a}
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicListUI()
            end,
            width = "full",
        }, y)
        y = y + 40

        addSectionHeader("Count & Charges")
        addSlider("Count Size", 4, 64, 1, function() return (iconData.settings.countSettings and iconData.settings.countSettings.size) or 16 end, function(val)
            iconData.settings.countSettings = iconData.settings.countSettings or {}
            iconData.settings.countSettings.size = val
        end)

        -- Count Font Type
        do
            local fontValues = {}
            if LSM then
                local hashTable = LSM:HashTable("font")
                for name, _ in pairs(hashTable) do
                    fontValues[name] = name
                end
            end
            Widgets.CreateSelect(uiFrames.configParent, {
                name = "Count Font Type",
                values = fontValues,
                get = function()
                    local cs = iconData.settings.countSettings or {}
                    return cs.font or (NephUI.db and NephUI.db.profile and NephUI.db.profile.general and NephUI.db.profile.general.globalFont) or "Expressway"
                end,
                set = function(_, val)
                    iconData.settings.countSettings = iconData.settings.countSettings or {}
                    iconData.settings.countSettings.font = val
                    if iconKey and runtime.UpdateDynamicIcon then
                        runtime.UpdateDynamicIcon(iconKey)
                    end
                    RefreshAllLayouts()
                    CustomIcons:RefreshDynamicListUI()
                end,
                width = "full",
            }, y, nil, nil, nil)
            y = y + 40
        end

        -- Count Color
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Count Color",
            get = function()
                local cs = iconData.settings.countSettings or {}
                return unpack(cs.color or {1, 1, 1, 1})
            end,
            set = function(_, r, g, b, a)
                iconData.settings.countSettings = iconData.settings.countSettings or {}
                iconData.settings.countSettings.color = {r, g, b, a}
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicListUI()
            end,
            width = "full",
        }, y)
        y = y + 40

        -- Count X Offset
        addSlider("Count X Offset", -50, 50, 1, function()
            local cs = iconData.settings.countSettings or {}
            return cs.offsetX or -2
        end, function(val)
            iconData.settings.countSettings = iconData.settings.countSettings or {}
            iconData.settings.countSettings.offsetX = val
            if iconKey and runtime.UpdateDynamicIcon then
                runtime.UpdateDynamicIcon(iconKey)
            end
            RefreshAllLayouts()
            CustomIcons:RefreshDynamicListUI()
        end)

        -- Count Y Offset
        addSlider("Count Y Offset", -50, 50, 1, function()
            local cs = iconData.settings.countSettings or {}
            return cs.offsetY or 2
        end, function(val)
            iconData.settings.countSettings = iconData.settings.countSettings or {}
            iconData.settings.countSettings.offsetY = val
            if iconKey and runtime.UpdateDynamicIcon then
                runtime.UpdateDynamicIcon(iconKey)
            end
            RefreshAllLayouts()
            CustomIcons:RefreshDynamicListUI()
        end)

        -- Count Anchor Point
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Count Anchor Point",
            values = {
                TOPLEFT = "Top Left",
                TOP = "Top",
                TOPRIGHT = "Top Right",
                LEFT = "Left",
                RIGHT = "Right",
                BOTTOMLEFT = "Bottom Left",
                BOTTOM = "Bottom",
                BOTTOMRIGHT = "Bottom Right",
            },
            get = function()
                local cs = iconData.settings.countSettings or {}
                return cs.anchor or "BOTTOMRIGHT"
            end,
            set = function(_, val)
                iconData.settings.countSettings = iconData.settings.countSettings or {}
                iconData.settings.countSettings.anchor = val
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicListUI()
            end,
            width = "full",
        }, y, nil, nil, nil)
        y = y + 40

        addSectionHeader("Cooldown")
        -- Cooldown Text Size
        addSlider("Cooldown Text Size", 4, 64, 1, function()
            local cds = iconData.settings.cooldownSettings or {}
            return cds.size or 12
        end, function(val)
            iconData.settings.cooldownSettings = iconData.settings.cooldownSettings or {}
            iconData.settings.cooldownSettings.size = val
        end)

        -- Cooldown Text Color
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Cooldown Text Color",
            get = function()
                local cds = iconData.settings.cooldownSettings or {}
                return unpack(cds.color or {1, 1, 1, 1})
            end,
            set = function(_, r, g, b, a)
                iconData.settings.cooldownSettings = iconData.settings.cooldownSettings or {}
                iconData.settings.cooldownSettings.color = {r, g, b, a}
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicListUI()
            end,
            width = "full",
        }, y)
        y = y + 40

        addSectionHeader("Behavior")
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Show Cooldown",
            get = function() return iconData.settings.showCooldown ~= false end,
            set = function(_, val)
                iconData.settings.showCooldown = val
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 32

        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Show GCD Swipe",
            get = function() return iconData.settings.showGCDSwipe == true end,
            set = function(_, val)
                iconData.settings.showGCDSwipe = val == true
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 32

        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Show Charges/Count",
            get = function() return iconData.settings.showCharges ~= false end,
            set = function(_, val)
                iconData.settings.showCharges = val
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 32

        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Desaturate on Cooldown",
            get = function() return iconData.settings.desaturateOnCooldown ~= false end,
            set = function(_, val)
                iconData.settings.desaturateOnCooldown = val
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 32

        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Desaturate When Unusable",
            get = function() return iconData.settings.desaturateWhenUnusable ~= false end,
            set = function(_, val)
                iconData.settings.desaturateWhenUnusable = val
                if iconKey and runtime.UpdateDynamicIcon then
                    runtime.UpdateDynamicIcon(iconKey)
                end
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 32

        -- Only show "Hide if Not Usable" toggle for slot-type icons
        if iconData.type == "slot" then
            Widgets.CreateToggle(uiFrames.configParent, {
                name = "Hide if Not Usable",
                get = function() return iconData.settings.hideIfNotUsable ~= false end,
                set = function(_, val)
                    iconData.settings.hideIfNotUsable = val
                    -- Reload icons to apply the change immediately
                    if CustomIcons and CustomIcons.LoadDynamicIcons then
                        CustomIcons:LoadDynamicIcons()
                    end
                    RefreshAllLayouts()
                    CustomIcons:RefreshDynamicConfigUI()
                end,
                width = "full",
            }, y)
            y = y + 32
        end

        Widgets.CreateExecute(uiFrames.configParent, {
            name = "Load Conditions...",
            func = function() CustomIcons:ShowLoadConditionsWindow(iconKey, iconData) end,
            width = "full",
        }, y)
    end

    local function ensureGroupDefaults(group)
        group.settings = group.settings or {}
        local s = group.settings
        s.growthDirection = s.growthDirection or "RIGHT"
        s.rowGrowthDirection = s.rowGrowthDirection or GetDefaultRowGrowth(s.growthDirection)
        s.rowGrowthDirection = NormalizeRowGrowth(s.growthDirection, s.rowGrowthDirection)
        if s.maxIconsPerRow == nil and s.maxColumns ~= nil then
            s.maxIconsPerRow = s.maxColumns
            s.maxColumns = nil
        end
        if s.anchorPoint and not s.anchorFrom and not s.anchorTo then
            s.anchorFrom = s.anchorPoint
            s.anchorTo = s.anchorPoint
            s.anchorPoint = nil
        end
        s.anchorFrom = s.anchorFrom or GetStartAnchorForGrowthPair(s.growthDirection, s.rowGrowthDirection)
        s.anchorTo = s.anchorTo or s.anchorFrom
        s.spacing = s.spacing or 5
        s.position = s.position or {x = 100, y = -100}
        s.anchorFrame = s.anchorFrame or ""
    end

    local function showGroupConfig()
        if not selectedGroup then
            local label = uiFrames.configParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            label:SetPoint("TOPLEFT", uiFrames.configParent, "TOPLEFT", 0, 20)
            label:SetText("Select an icon or group")
            label:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
            return
        end
        ensureGroupDefaults(selectedGroup)
        local s = selectedGroup.settings

        Widgets.CreateInput(uiFrames.configParent, {
            name = "Group Name",
            get = function() return selectedGroup.name or "" end,
            set = function(_, val)
                selectedGroup.name = val or "Group"
                CustomIcons:RefreshDynamicListUI()
            end,
            width = "full",
        }, y)
        y = y + 40

        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Growth Direction",
            values = {RIGHT = "Right", LEFT = "Left", UP = "Up", DOWN = "Down"},
            get = function() return s.growthDirection end,
            set = function(_, val)
                s.growthDirection = val
                s.rowGrowthDirection = NormalizeRowGrowth(val, s.rowGrowthDirection or GetDefaultRowGrowth(val))
                s.anchorFrom = GetStartAnchorForGrowthPair(val, s.rowGrowthDirection)
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "normal",
        }, y, nil, nil, nil)
        y = y + 40

        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Row Growth",
            values = {RIGHT = "Right", LEFT = "Left", UP = "Up", DOWN = "Down"},
            get = function() return s.rowGrowthDirection end,
            set = function(_, val)
                s.rowGrowthDirection = NormalizeRowGrowth(s.growthDirection or "RIGHT", val)
                s.anchorFrom = GetStartAnchorForGrowthPair(s.growthDirection or "RIGHT", s.rowGrowthDirection)
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "normal",
        }, y, nil, nil, nil)
        y = y + 40

        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Anchor Frame Point",
            values = {
                TOPLEFT="TOPLEFT", TOP="TOP", TOPRIGHT="TOPRIGHT",
                LEFT="LEFT", CENTER="CENTER", RIGHT="RIGHT",
                BOTTOMLEFT="BOTTOMLEFT", BOTTOM="BOTTOM", BOTTOMRIGHT="BOTTOMRIGHT",
            },
            get = function() return s.anchorTo end,
            set = function(_, val)
                s.anchorTo = val
                RefreshAllLayouts()
                CustomIcons:RefreshDynamicConfigUI()
            end,
            width = "full",
        }, y, nil, nil, nil)
        y = y + 40

        addSlider("Spacing", -10, 10, 1, function() return s.spacing or 5 end, function(val) s.spacing = val end)
        addSlider("Max Icons Per Row", 1, 40, 1, function() return s.maxIconsPerRow or 10 end, function(val) s.maxIconsPerRow = val end)
        addSlider("Position X", -1000, 1000, 1, function() return (s.position and s.position.x) or 0 end, function(val)
            s.position = s.position or {}
            s.position.x = val
        end)
        addSlider("Position Y", -1000, 1000, 1, function() return (s.position and s.position.y) or 0 end, function(val)
            s.position = s.position or {}
            s.position.y = val
        end)

        Widgets.CreateInput(uiFrames.configParent, {
            name = "Anchor Frame",
            get = function() return s.anchorFrame or "" end,
            set = function(_, val)
                s.anchorFrame = val or ""
                if not s.anchorFrame or s.anchorFrame == "" then
                    s.anchorFrame = ""
                end
                -- Avoid rebuilding the config UI while typing; just update layout shortly after change
                if C_Timer and C_Timer.After then
                    C_Timer.After(0.05, RefreshAllLayouts)
                else
                    RefreshAllLayouts()
                end
            end,
            width = "full",
        }, y)
        y = y + 40

        Widgets.CreateExecute(uiFrames.configParent, {
            name = "Delete Group",
            func = function()
                CustomIcons:RemoveGroup(groupKey)
            end,
            width = "full",
        }, y)
    end

    local function updateScrollHeight()
        if uiFrames.configChild then
            uiFrames.configChild:SetHeight(math.max(y + 20, 1))
        end
    end

    if iconData then
        showIconConfig()
        updateScrollHeight()
        return
    end
    if selectedGroup then
        showGroupConfig()
        updateScrollHeight()
        return
    end

    local label = uiFrames.configParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", uiFrames.configParent, "TOPLEFT", 0, 20)
    label:SetText("Select an icon or group")
    label:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
    updateScrollHeight()
end

function CustomIcons:ConfirmDeleteIcon(iconKey, label)
    if not uiFrames.confirmFrame then
        local f = CreateFrame("Frame", "NephUI_DynIconConfirm", UIParent, "BackdropTemplate")
        f:SetSize(320, 140)
        f:SetPoint("CENTER")
        f:SetFrameStrata("TOOLTIP")
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0},
        })
        f:SetBackdropColor(THEME.bgDark[1], THEME.bgDark[2], THEME.bgDark[3], 0.95)
        f:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 1)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", f, "TOP", 0, -12)
        f.title:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)

        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.text:SetPoint("TOP", f, "TOP", 0, -38)
        f.text:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)

        f.confirm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.confirm:SetSize(100, 24)
        f.confirm:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
        f.confirm:SetText("Confirm")

        f.cancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.cancel:SetSize(100, 24)
        f.cancel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
        f.cancel:SetText("Cancel")

        f:Hide()
        uiFrames.confirmFrame = f
    end

    local f = uiFrames.confirmFrame
    f.title:SetText("Confirm Deletion")
    f.text:SetText(("Delete \"%s\"?\nThis cannot be undone."):format(label or "icon"))
    f.confirm:SetScript("OnClick", function()
        f:Hide()
        CustomIcons:RemoveDynamicIcon(iconKey)
    end)
    f.cancel:SetScript("OnClick", function() f:Hide() end)
    f:Show()
end

function CustomIcons:BuildDynamicIconsUI(parent)
    EnsureEventFrame()

    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)

    -- Search bar
    local search = Widgets.CreateInput(container, {
        name = "Search by name or ID...",
        width = "full",
        get = function() return uiState.searchText end,
        set = function(_, val)
            uiState.searchText = val or ""
            CustomIcons:RefreshDynamicListUI()
        end,
    }, 0)
    if search.editBox then
        search.editBox:SetHeight(28)
    end

    local resultText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if search.editBox then
        resultText:SetPoint("TOPLEFT", search.editBox, "BOTTOMLEFT", 4, -6)
    else
        resultText:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -34)
    end
    resultText:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
    uiFrames.resultText = resultText

    -- Buttons
    local createIconBtn = Widgets.CreateExecute(container, {
        name = "+ Create Icon",
        func = function() CustomIcons:ShowCreateIconDialog() end,
        width = "normal",
    }, 40)
    if search.editBox then
        createIconBtn:SetPoint("TOPLEFT", search.editBox, "BOTTOMLEFT", 0, -18)
    else
        createIconBtn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -52)
    end

    local createGroupBtn = Widgets.CreateExecute(container, {
        name = "+ Create Group",
        func = function()
            CustomIcons:CreateDynamicGroup("New Group")
        end,
        width = "normal",
    }, 40)
    createGroupBtn:SetPoint("LEFT", createIconBtn, "RIGHT", 8, 0)

    -- Left list scroll (skinned to match GUI)
    local listScroll = CreateFrame("ScrollFrame", nil, container)
    listScroll:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -80)
    listScroll:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    listScroll:SetWidth(270)

    local listScrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
    listScrollBar:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", 2, 0)
    listScrollBar:SetPoint("BOTTOMLEFT", listScroll, "BOTTOMRIGHT", 2, 0)
    listScroll.ScrollBar = listScrollBar

    local listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetWidth(250)
    listChild:SetHeight(400)
    listScroll:SetScrollChild(listChild)
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
        ScrollUtil.InitScrollFrameWithScrollBar(listScroll, listScrollBar)
    end

    uiFrames.listParent = listChild

    -- Right config area
    local config = CreateFrame("Frame", nil, container, "BackdropTemplate")
    config:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", 12, 0)
    config:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    CreateBackdrop(config, THEME.bgMedium, THEME.border)

    -- Create scroll frame inside config panel
    local configScroll = CreateFrame("ScrollFrame", nil, config)
    configScroll:SetPoint("TOPLEFT", config, "TOPLEFT", 4, -4)
    configScroll:SetPoint("BOTTOMRIGHT", config, "BOTTOMRIGHT", -20, 4)
    local configScrollBar = CreateFrame("EventFrame", nil, config, "MinimalScrollBar")
    configScrollBar:SetPoint("TOPLEFT", configScroll, "TOPRIGHT", 2, 0)
    configScrollBar:SetPoint("BOTTOMLEFT", configScroll, "BOTTOMRIGHT", 2, 0)
    configScroll.ScrollBar = configScrollBar
    local configChild = CreateFrame("Frame", nil, configScroll)
    configChild:SetWidth(configScroll:GetWidth() or 200)
    configChild:SetHeight(1)
    configScroll:SetScrollChild(configChild)
    configScroll:SetScript("OnSizeChanged", function(_, w)
        if configChild and w and w > 0 then
            configChild:SetWidth(w)
        end
    end)
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
        ScrollUtil.InitScrollFrameWithScrollBar(configScroll, configScrollBar)
    end
    uiFrames.configScroll = configScroll
    uiFrames.configChild = configChild
    uiFrames.configParent = configChild

    CustomIcons:RefreshDynamicListUI()
    CustomIcons:RefreshDynamicConfigUI()
end

-- Creation dialog
local slotOptions = {
    {text = "Trinket 0 (Slot 13)", slotID = 13},
    {text = "Trinket 1 (Slot 14)", slotID = 14},
    {text = "Main Hand (16)", slotID = 16},
    {text = "Off Hand (17)", slotID = 17},
    {text = "Head (1)", slotID = 1},
    {text = "Neck (2)", slotID = 2},
    {text = "Shoulder (3)", slotID = 3},
    {text = "Back (15)", slotID = 15},
    {text = "Chest (5)", slotID = 5},
    {text = "Wrist (9)", slotID = 9},
    {text = "Hands (10)", slotID = 10},
    {text = "Waist (6)", slotID = 6},
    {text = "Legs (7)", slotID = 7},
    {text = "Feet (8)", slotID = 8},
    {text = "Finger 0 (11)", slotID = 11},
    {text = "Finger 1 (12)", slotID = 12},
}

-- Keep dropdown menus above the create dialog so they don't get obscured
local function RaiseDropDownMenus()
    for i = 1, 2 do
        local list = _G["DropDownList"..i]
        if list then
            list:SetFrameStrata("TOOLTIP")
            if uiFrames.createFrame then
                list:SetFrameLevel(uiFrames.createFrame:GetFrameLevel() + 10)
            end
            if not list.__nuiStrataHooked then
                list:HookScript("OnShow", RaiseDropDownMenus)
                list.__nuiStrataHooked = true
            end
        end
    end
end

function CustomIcons:ShowCreateIconDialog()
    if not uiFrames.createFrame then
        local f = CreateFrame("Frame", "NephUI_DynIconCreate", UIParent, "BackdropTemplate")
        f:SetSize(360, 220)
        f:SetPoint("CENTER")
        f:SetFrameStrata("TOOLTIP")
        CreateBackdrop(f, THEME.bgDark, THEME.border)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", f, "TOP", 0, -12)
        f.title:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
        f.title:SetText("Create Icon")

        f.typeButtons = {}
        local types = { {key = "spell", label = "Spell"}, {key = "item", label = "Item"}, {key = "slot", label = "Slot"} }
        local spacing = 100
        local startX = -((#types - 1) * spacing) / 2
        for idx, info in ipairs(types) do
            local btn = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
            btn:SetPoint("TOP", f, "TOP", startX + (idx - 1) * spacing, -42)
            btn.text:SetText(info.label)
            btn:SetScript("OnClick", function()
                for _, b in pairs(f.typeButtons) do b:SetChecked(false) end
                btn:SetChecked(true)
                f.selectedType = info.key
                if info.key == "slot" then
                    f.idInput:Hide()
                    f.slotDropdown:Show()
                else
                    f.idInput:Show()
                    f.slotDropdown:Hide()
                end
            end)
            f.typeButtons[info.key] = btn
        end
        f.typeButtons.spell:SetChecked(true)
        f.selectedType = "spell"

        -- ID input
        local idBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        idBox:SetAutoFocus(false)
        idBox:SetSize(140, 24)
        idBox:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -78)
        idBox:SetNumeric(true)
        idBox:SetMaxLetters(8)
        idBox:SetText("")
        f.idInput = idBox

        local idLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        idLabel:SetPoint("BOTTOMLEFT", idBox, "TOPLEFT", 2, 2)
        idLabel:SetText("Spell or Item ID")

        -- Slot dropdown
        local dropdown = CreateFrame("Frame", "NephUI_DynIconCreateSlotDrop", f, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", idBox, "TOPLEFT", -16, -2)
        UIDropDownMenu_SetWidth(dropdown, 180)
        UIDropDownMenu_SetText(dropdown, "Select Slot")
        dropdown:Hide()
        f.slotDropdown = dropdown
        f.selectedSlot = slotOptions[1].slotID

        UIDropDownMenu_Initialize(dropdown, function(self, level)
            for _, opt in ipairs(slotOptions) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt.text
                info.func = function()
                    UIDropDownMenu_SetSelectedValue(dropdown, opt.slotID)
                    UIDropDownMenu_SetText(dropdown, opt.text)
                    f.selectedSlot = opt.slotID
                end
                info.value = opt.slotID
                UIDropDownMenu_AddButton(info)
            end
        end)

        f.confirm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.confirm:SetSize(100, 24)
        f.confirm:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
        f.confirm:SetText("Create")

        f.cancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.cancel:SetSize(100, 24)
        f.cancel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
        f.cancel:SetText("Cancel")
        f.cancel:SetScript("OnClick", function() f:Hide() end)

        f.confirm:SetScript("OnClick", function()
            local t = f.selectedType
            if t == "slot" then
                CustomIcons:AddDynamicIcon({type = "slot", slotID = f.selectedSlot})
            else
                local idVal = tonumber(f.idInput:GetText() or "")
                if not idVal or idVal <= 0 then
                    UIErrorsFrame:AddMessage("Enter a valid ID", 1, 0, 0)
                    return
                end
                CustomIcons:AddDynamicIcon({type = t, id = idVal})
            end
            f:Hide()
        end)

        uiFrames.createFrame = f
    end

    RaiseDropDownMenus()
    uiFrames.createFrame:Show()
end

-- Config mode for showing/hiding group anchors
function CustomIcons:SetConfigMode(enabled)
    for groupKey, container in pairs(runtime.groupFrames) do
        if container and container.anchor then
            if enabled then
                container.anchor:Show()
            else
                container.anchor:Hide()
            end
        end
    end
end

-- Disable config mode (called when GUI closes)
function CustomIcons:DisableConfigMode()
    self:SetConfigMode(false)
end

local function ShouldShowAnchors()
    local showFromButton = false
    local uf = NephUI.db and NephUI.db.profile and NephUI.db.profile.unitFrames
    if uf and uf.General and uf.General.ShowEditModeAnchors then
        showFromButton = true
    end
    local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
    return showFromButton or inEditMode
end

function CustomIcons:RefreshAnchorVisibility()
    self:SetConfigMode(ShouldShowAnchors())
end

local anchorHooked = false
local function EnsureAnchorHooks()
    if anchorHooked then return end
    if NephUI.UnitFrames and NephUI.UnitFrames.UpdateEditModeAnchors then
        hooksecurefunc(NephUI.UnitFrames, "UpdateEditModeAnchors", function()
            CustomIcons:RefreshAnchorVisibility()
        end)
        anchorHooked = true
    end
end

-- Hook into GUI renderer
CustomIcons.BuildDynamicIconsUI = CustomIcons.BuildDynamicIconsUI
CustomIcons.RefreshDynamicListUI = CustomIcons.RefreshDynamicListUI
CustomIcons.RefreshDynamicConfigUI = CustomIcons.RefreshDynamicConfigUI
CustomIcons.ApplyIconBorder = ApplyIconBorder
CustomIcons.ResolveAnchorPoints = ResolveAnchorPoints
CustomIcons.GetAnchorFrame = GetAnchorFrame
CustomIcons.SetConfigMode = CustomIcons.SetConfigMode
CustomIcons.DisableConfigMode = CustomIcons.DisableConfigMode
CustomIcons.RefreshAnchorVisibility = CustomIcons.RefreshAnchorVisibility
CustomIcons.ShowLoadConditionsWindow = CustomIcons.ShowLoadConditionsWindow

-- Auto-load saved icons when DB is available
if NephUI.db and NephUI.db.profile then
    CustomIcons:LoadDynamicIcons()
    CustomIcons:RefreshAnchorVisibility()
    EnsureAnchorHooks()

    -- Hook edit mode enter/exit to hide anchors when leaving
    if EditModeManagerFrame and EditModeManagerFrame.ExitEditMode then
        hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
            CustomIcons:RefreshAnchorVisibility()
        end)
    end
    if EditModeManagerFrame and EditModeManagerFrame.EnterEditMode then
        hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
            CustomIcons:RefreshAnchorVisibility()
        end)
    end

    -- Hook unit frame anchor toggles (Enable/Disable Anchors buttons call this)
    EnsureAnchorHooks()
end

-- Watch for edit mode and unit frame anchor toggles coming online after load
if not CustomIcons.__anchorWatcher then
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    watcher:SetScript("OnEvent", function()
        EnsureAnchorHooks()
        CustomIcons:RefreshAnchorVisibility()
    end)
    CustomIcons.__anchorWatcher = watcher
end
