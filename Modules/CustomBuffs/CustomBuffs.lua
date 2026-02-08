local ADDON_NAME, ns = ...
local NephUI = ns.Addon

NephUI.CustomBuffs = NephUI.CustomBuffs or {}
local CustomBuffs = NephUI.CustomBuffs

local Widgets = NephUI.GUI and NephUI.GUI.Widgets
local THEME = NephUI.GUI and NephUI.GUI.THEME
local LSM = LibStub("LibSharedMedia-3.0", true)

-- ------------------------
-- Defaults and DB
-- ------------------------
local DEFAULT_BUFF_SETTINGS = {
    displayMode = "icon",  -- "icon" | "bar"
    iconSize = 44,
    aspectRatio = 1.0,
    borderSize = 1,
    borderColor = { 0, 0, 0, 1 },
    showCooldown = true,
    cooldownSwipeAlpha = 0.8,
    alwaysShow = false,
    desaturateWhenInactive = false,
    cooldownSettings = {
        size = 12,
        color = { 1, 1, 1, 1 },
    },
    -- Bar-only settings
    barSettings = {
        foregroundTexture = nil,  -- nil = use global
        foregroundColor = { 0.2, 0.6, 1, 1 },
        backgroundColor = { 0.15, 0.15, 0.15, 0.8 },
        showSpellIcon = true,
        width = 180,
        height = 18,
        borderSize = 1,
        borderColor = { 0, 0, 0, 1 },
        durationText = { show = true, anchor = "RIGHT", size = 12, color = { 1, 1, 1, 1 }, posX = -4, posY = 0 },
        nameText = { show = true, anchor = "LEFT", size = 12, color = { 1, 1, 1, 1 }, posX = 4, posY = 0 },
    },
}

local runtime = {
    iconFrames = {},
    barFrames = {},
    groupFrames = {},
    activeBuffs = {},
    buffTimers = {},  -- [buffKey] = C_Timer handle when Show Cooldown disabled
    barTicker = nil,  -- single frame OnUpdate for bar fill + duration text
    dragState = {},
}

local uiFrames = {
    listParent = nil,
    configParent = nil,
    searchBox = nil,
    resultText = nil,
    createFrame = nil,
    confirmFrame = nil,
    loadWindow = nil,
}

-- Spec list for Load Conditions (by spec) - same set as Custom Spells
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

local uiState = {
    searchText = "",
    selectedBuff = nil,
    selectedGroup = nil,
    collapsedGroups = {},
}

local function CopyColor(c)
    if type(c) ~= "table" then return nil end
    return { c[1], c[2], c[3], c[4] }
end

local function GetCustomBuffsDB()
    local profile = NephUI.db.profile
    profile.customBuffs = profile.customBuffs or {}
    local db = profile.customBuffs
    db.iconData = db.iconData or {}
    db.ungrouped = db.ungrouped or {}
    db.groups = db.groups or {}
    return db
end

local EnsureLoadConditions
local function EnsureBuffSettings(iconData)
    if not iconData then return end
    iconData.settings = iconData.settings or {}
    local s = iconData.settings
    if s.displayMode == nil then s.displayMode = DEFAULT_BUFF_SETTINGS.displayMode end
    if s.displayMode ~= "icon" and s.displayMode ~= "bar" then s.displayMode = "icon" end
    if s.iconSize == nil then s.iconSize = DEFAULT_BUFF_SETTINGS.iconSize end
    if s.aspectRatio == nil then s.aspectRatio = DEFAULT_BUFF_SETTINGS.aspectRatio end
    if s.borderSize == nil then s.borderSize = DEFAULT_BUFF_SETTINGS.borderSize end
    if s.borderColor == nil then s.borderColor = CopyColor(DEFAULT_BUFF_SETTINGS.borderColor) end
    if s.showCooldown == nil then s.showCooldown = DEFAULT_BUFF_SETTINGS.showCooldown end
    if s.cooldownSwipeAlpha == nil then s.cooldownSwipeAlpha = DEFAULT_BUFF_SETTINGS.cooldownSwipeAlpha end
    if s.alwaysShow == nil then s.alwaysShow = DEFAULT_BUFF_SETTINGS.alwaysShow end
    if s.desaturateWhenInactive == nil then s.desaturateWhenInactive = DEFAULT_BUFF_SETTINGS.desaturateWhenInactive end
    s.cooldownSettings = s.cooldownSettings or {}
    if s.cooldownSettings.size == nil then s.cooldownSettings.size = DEFAULT_BUFF_SETTINGS.cooldownSettings.size end
    if s.cooldownSettings.color == nil then s.cooldownSettings.color = CopyColor(DEFAULT_BUFF_SETTINGS.cooldownSettings.color) end
    s.barSettings = s.barSettings or {}
    local bs = s.barSettings
    local dbs = DEFAULT_BUFF_SETTINGS.barSettings
    if bs.foregroundTexture == nil then bs.foregroundTexture = dbs.foregroundTexture end
    if bs.foregroundColor == nil then bs.foregroundColor = CopyColor(dbs.foregroundColor) end
    if bs.backgroundColor == nil then bs.backgroundColor = CopyColor(dbs.backgroundColor) end
    if bs.showSpellIcon == nil then bs.showSpellIcon = dbs.showSpellIcon end
    if bs.width == nil then bs.width = dbs.width end
    if bs.height == nil then bs.height = dbs.height end
    if bs.borderSize == nil then bs.borderSize = dbs.borderSize end
    if bs.borderColor == nil then bs.borderColor = CopyColor(dbs.borderColor) end
    bs.durationText = bs.durationText or {}
    if bs.durationText.show == nil then bs.durationText.show = dbs.durationText.show end
    if bs.durationText.anchor == nil then bs.durationText.anchor = dbs.durationText.anchor end
    if bs.durationText.size == nil then bs.durationText.size = dbs.durationText.size end
    if bs.durationText.color == nil then bs.durationText.color = CopyColor(dbs.durationText.color) end
    if bs.durationText.posX == nil then bs.durationText.posX = dbs.durationText.posX end
    if bs.durationText.posY == nil then bs.durationText.posY = dbs.durationText.posY end
    bs.nameText = bs.nameText or {}
    if bs.nameText.show == nil then bs.nameText.show = dbs.nameText.show end
    if bs.nameText.anchor == nil then bs.nameText.anchor = dbs.nameText.anchor end
    if bs.nameText.size == nil then bs.nameText.size = dbs.nameText.size end
    if bs.nameText.color == nil then bs.nameText.color = CopyColor(dbs.nameText.color) end
    if bs.nameText.posX == nil then bs.nameText.posX = dbs.nameText.posX end
    if bs.nameText.posY == nil then bs.nameText.posY = dbs.nameText.posY end
    EnsureLoadConditions(iconData)
end

function EnsureLoadConditions(iconData)
    if not iconData then return end
    iconData.settings = iconData.settings or {}
    iconData.settings.loadConditions = iconData.settings.loadConditions or {
        enabled = false,
        specs = {},
    }
end

local function GetCurrentSpecID()
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        return GetSpecializationInfo(specIndex)
    end
    return nil
end

-- Returns true if the buff should be loaded (shown) under current load conditions.
local function IsBuffLoadable(data)
    if not data then return false end
    EnsureLoadConditions(data)
    local lc = data.settings.loadConditions or {}
    if not lc.enabled then
        return true
    end
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

-- ------------------------
-- Layout helpers (mirror Dynamic Icons)
-- ------------------------
local function GetAnchorFrame(anchorName)
    if not anchorName or anchorName == "" then return UIParent end
    return _G[anchorName] or UIParent
end

local function GetDefaultRowGrowth(growth)
    if growth == "LEFT" or growth == "RIGHT" then return "DOWN" end
    return "RIGHT"
end

local function NormalizeRowGrowth(growth, rowGrowth)
    if growth == "LEFT" or growth == "RIGHT" then
        return (rowGrowth == "UP" or rowGrowth == "DOWN") and rowGrowth or "DOWN"
    end
    return (rowGrowth == "LEFT" or rowGrowth == "RIGHT") and rowGrowth or "RIGHT"
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
    local start = GetStartAnchorForGrowthPair(g, rg)
    return {
        growthDirection = g,
        rowGrowthDirection = rg,
        anchorFrom = start,
        anchorTo = start,
        spacing = 5,
        maxIconsPerRow = 10,
        position = { x = 0, y = -200 },
    }
end

local function BuildDefaultUngroupedPositionSettings()
    local s = BuildDefaultSettings("RIGHT")
    s.anchorFrom = "CENTER"
    s.anchorTo = "CENTER"
    s.position = { x = 0, y = 0 }
    return s
end

local function NormalizeAnchor(settings)
    if not settings then return end
    if settings.anchorPoint and not settings.anchorFrom and not settings.anchorTo then
        settings.anchorFrom = settings.anchorPoint
        settings.anchorTo = settings.anchorPoint
        settings.anchorPoint = nil
    end
    settings.rowGrowthDirection = NormalizeRowGrowth(settings.growthDirection or "RIGHT", settings.rowGrowthDirection or GetDefaultRowGrowth(settings.growthDirection or "RIGHT"))
    if settings.maxIconsPerRow == nil and settings.maxColumns then
        settings.maxIconsPerRow = settings.maxColumns
        settings.maxColumns = nil
    end
    settings.anchorFrom = settings.anchorFrom or GetStartAnchorForGrowthPair(settings.growthDirection or "RIGHT", settings.rowGrowthDirection)
    settings.anchorTo = settings.anchorTo or settings.anchorFrom
end

local function GetGroupSettings(groupKey)
    local db = GetCustomBuffsDB()
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
        local g = db.groups[groupKey]
        g.settings = g.settings or BuildDefaultSettings(g.growthDirection or "RIGHT")
        NormalizeAnchor(g.settings)
        return g.settings
    end
    local def = BuildDefaultSettings("RIGHT")
    NormalizeAnchor(def)
    return def
end

local function GetBuffDisplayName(data)
    if not data or not data.spellID then return "Spell ?" end
    if data.customName and type(data.customName) == "string" and data.customName:gsub("^%s+", ""):gsub("%s+$", "") ~= "" then
        return data.customName:gsub("^%s+", ""):gsub("%s+$", "")
    end
    local info = C_Spell and C_Spell.GetSpellInfo(data.spellID)
    return (info and info.name) or ("Spell " .. tostring(data.spellID))
end

local function GetGroupDisplayName(groupKey)
    if groupKey == "ungrouped" then return "Ungrouped" end
    local db = GetCustomBuffsDB()
    if db.iconData[groupKey] and db.ungrouped[groupKey] then
        local d = db.iconData[groupKey]
        if d then
            return GetBuffDisplayName(d)
        end
    end
    local g = db.groups[groupKey]
    if g and g.name and g.name ~= "" then return g.name end
    return groupKey
end

-- ------------------------
-- Visual helpers
-- ------------------------
local function SafeSetBackdrop(frame, backdropInfo, borderColor)
    if not frame or not frame.SetBackdrop then return end
    if InCombatLockdown() then return end
    pcall(frame.SetBackdrop, frame, backdropInfo)
    if borderColor then pcall(frame.SetBackdropBorderColor, frame, unpack(borderColor)) end
end

local function ApplyIconBorder(iconFrame, settings)
    if not iconFrame or not iconFrame.border then return end
    local edgeSize = settings.borderSize or 0
    if edgeSize <= 0 then
        iconFrame.border:Hide()
        SafeSetBackdrop(iconFrame.border, nil)
        return
    end
    SafeSetBackdrop(iconFrame.border, {
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = edgeSize,
    }, settings.borderColor or { 0, 0, 0, 1 })
    iconFrame.border:Show()
    local o = edgeSize
    iconFrame.border:ClearAllPoints()
    iconFrame.border:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -o, o)
    iconFrame.border:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", o, -o)
end

local function ApplyCooldownTextStyle(cooldown, iconData)
    if not cooldown or not cooldown.GetRegions then return end
    local fs
    for _, r in ipairs({ cooldown:GetRegions() }) do
        if r:GetObjectType() == "FontString" then fs = r break end
    end
    if not fs then return end
    local cds = (iconData.settings and iconData.settings.cooldownSettings) or {}
    local fontPath = NephUI:GetGlobalFont()
    local size = cds.size or 12
    local color = cds.color or { 1, 1, 1, 1 }
    local _, _, flags = fs:GetFont()
    fs:SetFont(fontPath, size, flags)
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    fs:SetShadowOffset(1, -1)
end

local function ApplyAspectRatioCrop(texture, aspect, baseZoom)
    if not texture or not texture.SetTexCoord then return end
    aspect = tonumber(aspect) or 1.0
    if aspect <= 0 then aspect = 1.0 end
    baseZoom = tonumber(baseZoom) or 0
    baseZoom = math.max(0, math.min(0.499, baseZoom))
    local left, right, top, bottom = baseZoom, 1 - baseZoom, baseZoom, 1 - baseZoom
    local rw, rh = right - left, bottom - top
    if rw <= 0 or rh <= 0 or aspect == 1.0 then return end
    local cr = rw / rh
    if aspect > cr then
        local h = rw / aspect
        local c = (rh - h) / 2
        top = top + c
        bottom = bottom - c
    elseif aspect < cr then
        local w = rh * aspect
        local c = (rw - w) / 2
        left = left + c
        right = right - c
    end
    texture:SetTexCoord(left, right, top, bottom)
end

local function ApplyIconSettings(iconFrame, iconData)
    EnsureBuffSettings(iconData)
    local s = iconData.settings or {}
    local size = s.iconSize or DEFAULT_BUFF_SETTINGS.iconSize
    local aspect = s.aspectRatio or 1.0
    local w, h = size, size
    if aspect > 1.0 then h = size / aspect elseif aspect < 1.0 then w = size * aspect end
    iconFrame:SetSize(w, h)
    if iconFrame.icon then
        iconFrame.icon:ClearAllPoints()
        iconFrame.icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
        iconFrame.icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
        ApplyAspectRatioCrop(iconFrame.icon, aspect, 0.08)
    end
    ApplyIconBorder(iconFrame, {
        borderSize = s.borderSize or DEFAULT_BUFF_SETTINGS.borderSize,
        borderColor = s.borderColor or DEFAULT_BUFF_SETTINGS.borderColor,
    })
    ApplyCooldownTextStyle(iconFrame.cooldown, iconData)
    local swipeAlpha = (s.cooldownSwipeAlpha ~= nil) and s.cooldownSwipeAlpha or 0.8
    pcall(iconFrame.cooldown.SetSwipeColor, iconFrame.cooldown, 0, 0, 0, swipeAlpha)
end

local function UpdateBuffIconDesaturation(buffKey)
    local db = GetCustomBuffsDB()
    local data = db and db.iconData[buffKey]
    local f = runtime.iconFrames[buffKey]
    if not f or not data or not f.icon then return end
    EnsureBuffSettings(data)
    local active = runtime.activeBuffs[buffKey]
    local desat = (data.settings.desaturateWhenInactive == true) and (not active)
    f.icon:SetDesaturated(desat == true)
end

-- ------------------------
-- Base icon
-- ------------------------
local RefreshAllLayouts
local ShouldShowAnchors

local function HandleCooldownDone(cdFrame)
    local parent = cdFrame and cdFrame:GetParent()
    local key = parent and parent._buffKey
    if not key then return end
    runtime.activeBuffs[key] = nil
    local frame = runtime.iconFrames[key]
    if frame then
        frame.cooldown:Clear()
        local db = GetCustomBuffsDB()
        local data = db and db.iconData[key]
        local alwaysShow = data and data.settings and data.settings.alwaysShow
        if alwaysShow then
            UpdateBuffIconDesaturation(key)
        else
            frame:Hide()
        end
    end
    if RefreshAllLayouts then RefreshAllLayouts() end
end

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
    cd:SetDrawEdge(false)
    cd:SetDrawSwipe(true)
    cd:SetSwipeColor(0, 0, 0, 0.8)
    cd:SetHideCountdownNumbers(false)
    cd:SetReverse(false)
    cd:SetScript("OnCooldownDone", HandleCooldownDone)
    frame.icon = icon
    frame.cooldown = cd
    frame.border = border
    frame:EnableMouse(true)
    return frame
end

local function CreateCustomBuffIcon(buffKey, iconData, parent)
    EnsureBuffSettings(iconData)
    local spellID = iconData.spellID
    local iconSpellID = iconData.iconSpellID or spellID
    if not spellID then return nil end
    local info = C_Spell and C_Spell.GetSpellInfo(iconSpellID)
    local tex = (info and info.iconID) or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(iconSpellID))
    local frame = CreateBaseIcon("NephUI_CustomBuff_" .. buffKey, parent)
    frame._buffKey = buffKey
    frame._spellID = spellID
    frame.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    frame:Hide()
    return frame
end

-- ------------------------
-- Bar display mode
-- ------------------------
local function ApplyBarBorder(barFrame, bs)
    if not barFrame or not barFrame.Border then return end
    local edgeSize = math.max(0, bs.borderSize or 1)
    if edgeSize <= 0 then
        barFrame.Border:Hide()
        SafeSetBackdrop(barFrame.Border, nil)
        return
    end
    SafeSetBackdrop(barFrame.Border, {
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = edgeSize,
    }, bs.borderColor or { 0, 0, 0, 1 })
    barFrame.Border:Show()
    barFrame.Border:ClearAllPoints()
    barFrame.Border:SetPoint("TOPLEFT", barFrame, "TOPLEFT", -edgeSize, edgeSize)
    barFrame.Border:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", edgeSize, -edgeSize)
end

local function ApplyBarSettings(barFrame, iconData)
    EnsureBuffSettings(iconData)
    local bs = (iconData.settings and iconData.settings.barSettings) or DEFAULT_BUFF_SETTINGS.barSettings
    local w = math.max(20, bs.width or 180)
    local h = math.max(8, bs.height or 18)
    local showIcon = bs.showSpellIcon
    local totalW = showIcon and (w + h) or w
    barFrame:SetSize(totalW, h)

    local fgTex = (NephUI and NephUI.GetTexture) and NephUI:GetTexture(bs.foregroundTexture) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
    barFrame.StatusBar:SetStatusBarTexture(fgTex)
    local fg = bs.foregroundColor or { 0.2, 0.6, 1, 1 }
    barFrame.StatusBar:SetStatusBarColor(fg[1], fg[2], fg[3], fg[4] or 1)
    local bg = bs.backgroundColor or { 0.15, 0.15, 0.15, 0.8 }
    barFrame.Background:SetColorTexture(bg[1], bg[2], bg[3], bg[4] or 1)

    ApplyBarBorder(barFrame, bs)

    if barFrame.Icon then
        if showIcon then
            barFrame.Icon:Show()
            barFrame.Icon:SetSize(h, h)
            barFrame.Icon:SetPoint("LEFT", barFrame, "LEFT", 0, 0)
            barFrame.StatusBar:ClearAllPoints()
            barFrame.StatusBar:SetPoint("TOPLEFT", barFrame, "TOPLEFT", h, 0)
            barFrame.StatusBar:SetPoint("BOTTOMRIGHT", barFrame, "BOTTOMRIGHT", 0, 0)
        else
            barFrame.Icon:Hide()
            barFrame.StatusBar:ClearAllPoints()
            barFrame.StatusBar:SetAllPoints()
        end
    else
        barFrame.StatusBar:ClearAllPoints()
        barFrame.StatusBar:SetAllPoints()
    end

    -- When spell icon is shown, left-side anchors must offset by icon width so text doesn't overlap
    local leftAnchors = { LEFT = true, TOPLEFT = true, BOTTOMLEFT = true }
    local iconOffsetX = (showIcon and h) or 0

    local dt = bs.durationText or {}
    local font = NephUI and NephUI.GetGlobalFont and NephUI:GetGlobalFont() or "GameFontHighlightSmall"
    local showDuration = dt.show ~= false
    barFrame.DurationText:SetFont(font, dt.size or 12, "OUTLINE")
    barFrame.DurationText:SetTextColor((dt.color or { 1,1,1,1 })[1], (dt.color or { 1,1,1,1 })[2], (dt.color or { 1,1,1,1 })[3], (dt.color or { 1,1,1,1 })[4] or 1)
    barFrame.DurationText:SetShadowOffset(0, 0)
    barFrame.DurationText:SetShadowColor(0, 0, 0, 0)
    barFrame.DurationText:ClearAllPoints()
    local dAnchor = dt.anchor or "RIGHT"
    local dX = (dt.posX or -4) + (leftAnchors[dAnchor] and iconOffsetX or 0)
    barFrame.DurationText:SetPoint(dAnchor, barFrame, dAnchor, dX, dt.posY or 0)
    if showDuration then barFrame.DurationText:Show() else barFrame.DurationText:Hide() end

    local nt = bs.nameText or {}
    local showName = nt.show ~= false
    barFrame.NameText:SetFont(font, nt.size or 12, "OUTLINE")
    barFrame.NameText:SetTextColor((nt.color or { 1,1,1,1 })[1], (nt.color or { 1,1,1,1 })[2], (nt.color or { 1,1,1,1 })[3], (nt.color or { 1,1,1,1 })[4] or 1)
    barFrame.NameText:SetShadowOffset(0, 0)
    barFrame.NameText:SetShadowColor(0, 0, 0, 0)
    barFrame.NameText:ClearAllPoints()
    local nAnchor = nt.anchor or "LEFT"
    local nX = (nt.posX or 4) + (leftAnchors[nAnchor] and iconOffsetX or 0)
    barFrame.NameText:SetPoint(nAnchor, barFrame, nAnchor, nX, nt.posY or 0)
    if showName then barFrame.NameText:Show() else barFrame.NameText:Hide() end
end

local function CreateCustomBuffBar(buffKey, iconData, parent)
    EnsureBuffSettings(iconData)
    local spellID = iconData.spellID
    local iconSpellID = iconData.iconSpellID or spellID
    if not spellID then return nil end
    local bs = (iconData.settings and iconData.settings.barSettings) or DEFAULT_BUFF_SETTINGS.barSettings
    local w = math.max(20, bs.width or 180)
    local h = math.max(8, bs.height or 18)
    local totalW = (bs.showSpellIcon and (w + h)) or w

    local bar = CreateFrame("Frame", "NephUI_CustomBuffBar_" .. buffKey, parent)
    bar:SetSize(totalW, h)
    bar._buffKey = buffKey
    bar._spellID = spellID
    bar._duration = tonumber(iconData.duration) or 6
    bar._endTime = nil

    bar.Background = bar:CreateTexture(nil, "BACKGROUND")
    bar.Background:SetAllPoints()

    bar.StatusBar = CreateFrame("StatusBar", nil, bar)
    bar.StatusBar:SetMinMaxValues(0, 1)
    bar.StatusBar:SetValue(0)  -- Foreground only shows when buff is active
    bar.StatusBar:SetAllPoints()
    for i = 1, select("#", bar.StatusBar:GetRegions()) do
        local r = select(i, bar.StatusBar:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "Texture" and r ~= bar.StatusBar:GetStatusBarTexture() then
            r:Hide()
        end
    end

    bar.Icon = bar:CreateTexture(nil, "ARTWORK")
    bar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local info = C_Spell and C_Spell.GetSpellInfo(iconSpellID)
    local tex = (info and info.iconID) or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(iconSpellID))
    bar.Icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")

    bar.TextFrame = CreateFrame("Frame", nil, bar)
    bar.TextFrame:SetAllPoints(bar)
    bar.TextFrame:SetFrameLevel(bar.StatusBar:GetFrameLevel() + 5)
    bar.DurationText = bar.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.DurationText:SetText("")
    bar.NameText = bar.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.NameText:SetText(GetBuffDisplayName(iconData))

    bar.Border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.Border:SetFrameLevel(bar:GetFrameLevel() + 2)
    bar.Border:Hide()

    ApplyBarSettings(bar, iconData)
    bar:Hide()
    return bar
end

local barTickerOnUpdate
local function EnsureBarTicker()
    if runtime.barTicker then return end
    runtime.barTicker = CreateFrame("Frame")
    barTickerOnUpdate = function()
        local now = GetTime()
        local anyBarActive = false
        for buffKey, bar in pairs(runtime.barFrames) do
            if not bar._endTime then
                -- skip
            else
                local remain = bar._endTime - now
                if remain <= 0 then
                    bar._endTime = nil
                    runtime.activeBuffs[buffKey] = nil
                    local db = GetCustomBuffsDB()
                    local d = db and db.iconData[buffKey]
                    local alwaysShow = d and d.settings and d.settings.alwaysShow
                    if alwaysShow then
                        bar.StatusBar:SetMinMaxValues(0, 1)
                        bar.StatusBar:SetValue(0)  -- Inactive: no foreground fill
                        bar.DurationText:SetText("")
                        bar:Show()
                    else
                        bar:Hide()
                    end
                    if RefreshAllLayouts then RefreshAllLayouts() end
                else
                    anyBarActive = true
                    local dur = bar._duration or 1
                    bar.StatusBar:SetMinMaxValues(0, dur)
                    bar.StatusBar:SetValue(remain)
                    bar.DurationText:SetText(string.format("%.1f", remain))
                end
            end
        end
        if not anyBarActive then
            runtime.barTicker:SetScript("OnUpdate", nil)
        end
    end
    runtime.barTicker:SetScript("OnUpdate", barTickerOnUpdate)
end

local function StartBarTicker()
    EnsureBarTicker()
    if barTickerOnUpdate then
        runtime.barTicker:SetScript("OnUpdate", barTickerOnUpdate)
    end
end

local function GetBuffFrame(buffKey)
    local db = GetCustomBuffsDB()
    local d = db and db.iconData[buffKey]
    if not d then return nil end
    EnsureBuffSettings(d)
    if (d.settings and d.settings.displayMode) == "bar" then
        return runtime.barFrames[buffKey]
    end
    return runtime.iconFrames[buffKey]
end

local function GetBuffFrameSize(buffKey)
    local db = GetCustomBuffsDB()
    local d = db and db.iconData[buffKey]
    if not d then return 0, 0 end
    EnsureBuffSettings(d)
    if (d.settings and d.settings.displayMode) == "bar" then
        local bs = (d.settings and d.settings.barSettings) or DEFAULT_BUFF_SETTINGS.barSettings
        local w = math.max(20, bs.width or 180)
        local h = math.max(8, bs.height or 18)
        local totalW = (bs.showSpellIcon and (w + h)) or w
        local borderSize = math.max(0, bs.borderSize or 1)
        return totalW + borderSize * 2, h + borderSize * 2
    end
    local f = runtime.iconFrames[buffKey]
    if f then return f:GetWidth(), f:GetHeight() end
    return 0, 0
end

-- ------------------------
-- Event: UNIT_SPELLCAST_SUCCEEDED
-- ------------------------
local function EnsureEventFrame()
    if runtime.eventFrame then return end
    runtime.eventFrame = CreateFrame("Frame")
    runtime.eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    runtime.eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    runtime.eventFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            if RefreshAllLayouts then RefreshAllLayouts() end
            return
        end
        if event ~= "UNIT_SPELLCAST_SUCCEEDED" or unit ~= "player" or not spellID then return end
        local db = GetCustomBuffsDB()
        for buffKey, data in pairs(db.iconData) do
            if data.spellID == spellID then
                local dur = tonumber(data.duration) or 6
                if dur <= 0 then dur = 6 end
                runtime.activeBuffs[buffKey] = true
                EnsureBuffSettings(data)
                local isBar = (data.settings and data.settings.displayMode) == "bar"
                if isBar then
                    local bar = runtime.barFrames[buffKey]
                    if bar then
                        ApplyBarSettings(bar, data)
                        bar._duration = dur
                        bar._endTime = GetTime() + dur
                        bar.StatusBar:SetMinMaxValues(0, dur)
                        bar.StatusBar:SetValue(dur)
                        bar.DurationText:SetText(string.format("%.1f", dur))
                        bar:Show()
                        StartBarTicker()
                    end
                else
                    local f = runtime.iconFrames[buffKey]
                    if f then
                        ApplyIconSettings(f, data)
                        UpdateBuffIconDesaturation(buffKey)
                        if data.settings and data.settings.showCooldown ~= false then
                            f.cooldown:SetCooldown(GetTime(), dur)
                            f.cooldown:Show()
                        else
                            f.cooldown:Clear()
                            f.cooldown:Hide()
                            if C_Timer and C_Timer.After then
                                local t = runtime.buffTimers[buffKey]
                                if t and t.Cancel then t:Cancel() end
                                runtime.buffTimers[buffKey] = C_Timer.After(dur, function()
                                    runtime.buffTimers[buffKey] = nil
                                    runtime.activeBuffs[buffKey] = nil
                                    local frame = runtime.iconFrames[buffKey]
                                    if frame then
                                        local db = GetCustomBuffsDB()
                                        local d = db and db.iconData[buffKey]
                                        local alwaysShow = d and d.settings and d.settings.alwaysShow
                                        if alwaysShow then
                                            UpdateBuffIconDesaturation(buffKey)
                                        else
                                            frame:Hide()
                                        end
                                    end
                                    if RefreshAllLayouts then RefreshAllLayouts() end
                                end)
                            end
                        end
                        f:Show()
                    end
                end
                if RefreshAllLayouts then RefreshAllLayouts() end
            end
        end
    end)
end

-- ------------------------
-- Group frame and layout
-- ------------------------
local function EnsureGroupFrame(groupKey, settings)
    settings = settings or GetGroupSettings(groupKey)
    NormalizeAnchor(settings)
    if runtime.groupFrames[groupKey] then return runtime.groupFrames[groupKey] end
    local container = CreateFrame("Frame", "NephUI_CBGroup_" .. groupKey, UIParent)
    container:SetSize(100, 100)
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    local anchor = CreateFrame("Frame", container:GetName() .. "_Anchor", container, "BackdropTemplate")
    anchor:SetAllPoints(container)
    anchor:SetFrameStrata("HIGH")
    anchor:Hide()
    local anchorText = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorText:SetPoint("CENTER")
    anchorText:SetText(GetGroupDisplayName(groupKey))
    anchorText:SetTextColor(1, 1, 1, 1)
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", function() container:StartMoving() end)
    anchor:SetScript("OnDragStop", function()
        container:StopMovingOrSizing()
        local point, _, relPoint, x, y = container:GetPoint()
        settings.position = settings.position or {}
        settings.position.x = x
        settings.position.y = y
        settings.anchorFrom = point
        settings.anchorTo = relPoint or point
        local db = GetCustomBuffsDB()
        if db.groups[groupKey] then db.groups[groupKey].settings = settings
        elseif groupKey == "ungrouped" then db.ungroupedSettings = settings end
    end)
    container.anchor = anchor
    container.anchorText = anchorText
    container._settings = settings
    container._groupKey = groupKey
    if settings.position then
        local af = GetAnchorFrame(settings.anchorFrame)
        local cp = settings.anchorFrom or GetStartAnchorForGrowthPair(settings.growthDirection or "RIGHT", settings.rowGrowthDirection)
        local ap = settings.anchorTo or cp
        container:ClearAllPoints()
        container:SetPoint(cp, af, ap, settings.position.x or 0, settings.position.y or 0)
    else
        local cp = GetStartAnchorForGrowthPair(settings.growthDirection or "RIGHT", settings.rowGrowthDirection)
        container:SetPoint(cp, UIParent, cp, 0, -200)
    end
    runtime.groupFrames[groupKey] = container
    return container
end

local function LayoutGroup(groupKey, iconKeys)
    local db = GetCustomBuffsDB()
    local settings = GetGroupSettings(groupKey)
    local growth = settings.growthDirection or "RIGHT"
    settings.rowGrowthDirection = NormalizeRowGrowth(growth, settings.rowGrowthDirection or GetDefaultRowGrowth(growth))
    
    if not iconKeys or #iconKeys == 0 then
        local c = runtime.groupFrames[groupKey]
        if c then c:Hide() end
        return
    end
    
    -- First pass: determine which buffs (icons or bars) should be visible and filter
    local anchorsVisible = ShouldShowAnchors()
    local visibleKeys = {}
    for _, k in ipairs(iconKeys) do
        local f = GetBuffFrame(k)
        local d = db.iconData[k]
        local alwaysShow = d and d.settings and d.settings.alwaysShow
        local active = runtime.activeBuffs[k]
        local shouldShow = active or alwaysShow or anchorsVisible
        if shouldShow and f then
            table.insert(visibleKeys, k)
        elseif f then
            f:Hide()
        end
    end
    
    if #visibleKeys == 0 then
        local c = runtime.groupFrames[groupKey]
        if c then c:Hide() end
        return
    end
    
    local container = EnsureGroupFrame(groupKey, settings)
    container:Show()
    local spacing = settings.spacing or 5
    local maxPerRow = settings.maxIconsPerRow or 10
    local startAnchor = GetStartAnchorForGrowthPair(growth, settings.rowGrowthDirection)
    
    local iconSizes = {}
    for _, k in ipairs(visibleKeys) do
        local f = GetBuffFrame(k)
        if f then
            local d = db.iconData[k]
            local isBar = d and (d.settings and d.settings.displayMode) == "bar"
            if d then
                if isBar then ApplyBarSettings(f, d) else ApplyIconSettings(f, d) end
            end
            local w, h
            local bs = 0
            if isBar then
                w, h = GetBuffFrameSize(k)
                bs = math.max(0, (d.settings and d.settings.barSettings and d.settings.barSettings.borderSize) or 1)
            else
                w, h = f:GetWidth(), f:GetHeight()
                bs = math.max(0, (d and d.settings and d.settings.borderSize) or 0)
                w = w + bs * 2
                h = h + bs * 2
            end
            table.insert(iconSizes, { width = w, height = h, border = bs })
        end
    end
    
    local positions = {}
    local minL, maxR, minB, maxT = 0, 0, 0, 0
    local rowBaseX, rowBaseY = 0, 0
    local along, rowThick, countInRow = 0, 0, 0
    local horizontal = (growth == "LEFT" or growth == "RIGHT")
    local rg = settings.rowGrowthDirection

    local function advanceRow()
        local step = rowThick + spacing
        if rg == "RIGHT" then rowBaseX = rowBaseX + step
        elseif rg == "LEFT" then rowBaseX = rowBaseX - step
        elseif rg == "UP" then rowBaseY = rowBaseY + step
        else rowBaseY = rowBaseY - step end
        along = 0
        rowThick = 0
        countInRow = 0
    end

    local function acc(anchor, xOff, yOff, w, h)
        local L, R, T, B
        if anchor == "TOPLEFT" then
            L, R = xOff, xOff + w
            T, B = yOff, yOff - h
        elseif anchor == "TOPRIGHT" then
            R, L = xOff, xOff - w
            T, B = yOff, yOff - h
        elseif anchor == "BOTTOMLEFT" then
            L, R = xOff, xOff + w
            B, T = yOff, yOff + h
        else
            R, L = xOff, xOff - w
            B, T = yOff, yOff + h
        end
        minL = math.min(minL, L)
        maxR = math.max(maxR, R)
        minB = math.min(minB, B)
        maxT = math.max(maxT, T)
    end

    for i, sz in ipairs(iconSizes) do
        local w, h = sz.width, sz.height
        local xOff, yOff = rowBaseX, rowBaseY
        if growth == "RIGHT" then xOff = rowBaseX + along
        elseif growth == "LEFT" then xOff = rowBaseX - along
        elseif growth == "UP" then yOff = rowBaseY + along
        else yOff = rowBaseY - along end
        positions[i] = { x = xOff, y = yOff, width = w, height = h, border = sz.border or 0 }
        acc(startAnchor, xOff, yOff, w, h)
        countInRow = countInRow + 1
        if horizontal then
            along = along + w + spacing
            rowThick = math.max(rowThick, h)
        else
            along = along + h + spacing
            rowThick = math.max(rowThick, w)
        end
        if countInRow >= maxPerRow then advanceRow() end
    end

    local cw = maxR - minL
    local ch = maxT - minB
    
    for i, buffKey in ipairs(visibleKeys) do
        local f = GetBuffFrame(buffKey)
        local pos = positions[i]
        if f and pos then
            local dx = (startAnchor:find("LEFT") and (pos.border or 0)) or -(pos.border or 0)
            local dy = (startAnchor:find("TOP") and -(pos.border or 0)) or (pos.border or 0)
            f:ClearAllPoints()
            f:SetParent(container)
            f:SetPoint(startAnchor, container, startAnchor, (pos.x or 0) + dx, (pos.y or 0) + dy)
            f:Show()
            local d = db.iconData[buffKey]
            if d and (d.settings and d.settings.displayMode) == "bar" then
                if not runtime.activeBuffs[buffKey] then
                    f.DurationText:SetText("")
                    f.StatusBar:SetMinMaxValues(0, 1)
                    f.StatusBar:SetValue(0)  -- Inactive: no foreground fill
                end
            else
                UpdateBuffIconDesaturation(buffKey)
            end
        end
    end
    container:SetSize(cw, ch)
    if settings.position then
        local af = GetAnchorFrame(settings.anchorFrame)
        local cp = settings.anchorFrom or startAnchor
        local ap = settings.anchorTo or cp
        container:ClearAllPoints()
        container:SetPoint(cp, af, ap, settings.position.x or 0, settings.position.y or 0)
    end
    if container.anchor then
        container.anchor:SetAllPoints(container)
        if container.anchorText then container.anchorText:SetText(GetGroupDisplayName(groupKey)) end
    end
end

local function FindBuffGroup(buffKey, db)
    if db.ungrouped[buffKey] then return "ungrouped" end
    for gk, g in pairs(db.groups) do
        for _, k in ipairs(g.icons or {}) do
            if k == buffKey then return gk end
        end
    end
    return "ungrouped"
end

RefreshAllLayouts = function()
    local db = GetCustomBuffsDB()
    local ungroupedKeys = {}
    for k in pairs(db.ungrouped) do
        if db.iconData[k] and IsBuffLoadable(db.iconData[k]) then
            table.insert(ungroupedKeys, k)
        end
    end
    table.sort(ungroupedKeys)
    for _, k in ipairs(ungroupedKeys) do
        db.ungroupedPositions = db.ungroupedPositions or {}
        db.ungroupedPositions[k] = db.ungroupedPositions[k] or BuildDefaultUngroupedPositionSettings()
        LayoutGroup(k, { k })
    end
    for gk, g in pairs(db.groups) do
        local keys = {}
        local seen = {}
        for _, k in ipairs(g.icons or {}) do
            if db.iconData[k] and not seen[k] and IsBuffLoadable(db.iconData[k]) then
                table.insert(keys, k)
                seen[k] = true
            end
        end
        LayoutGroup(gk, keys)
    end
    -- Hide frames for buffs that are not loadable (e.g. wrong spec)
    for buffKey, data in pairs(db.iconData) do
        if not IsBuffLoadable(data) then
            local iconF = runtime.iconFrames[buffKey]
            local barF = runtime.barFrames[buffKey]
            if iconF then iconF:Hide() end
            if barF then barF:Hide() end
        end
    end
end

function CustomBuffs:ShowLoadConditionsWindow(buffKey, iconData)
    EnsureLoadConditions(iconData)
    if uiFrames.loadWindow then
        uiFrames.loadWindow:Hide()
        uiFrames.loadWindow = nil
    end

    local lc = iconData.settings.loadConditions

    local f = CreateFrame("Frame", "NephUI_CustomBuff_LoadConditions", UIParent, "BackdropTemplate")
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

    local enableBtn = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    enableBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -36)
    enableBtn.text:SetText("Enable Load Conditions")
    enableBtn:SetChecked(lc.enabled == true)
    enableBtn:SetScript("OnClick", function(self)
        lc.enabled = self:GetChecked() or false
        if RefreshAllLayouts then RefreshAllLayouts() end
        if CustomBuffs.RefreshBuffListUI then CustomBuffs:RefreshBuffListUI() end
    end)

    local specHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    specHeader:SetPoint("TOPLEFT", enableBtn, "BOTTOMLEFT", 4, -12)
    specHeader:SetText("By Specialization")

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
            if CustomBuffs.RefreshBuffListUI then CustomBuffs:RefreshBuffListUI() end
        end)

        y = y + 28
    end
    specChild:SetHeight(y)

    uiFrames.loadWindow = f
    f:Show()
end

-- ------------------------
-- Load / Add / Remove
-- ------------------------
function CustomBuffs:LoadCustomBuffs()
    EnsureEventFrame()
    local db = GetCustomBuffsDB()
    for buffKey, data in pairs(db.iconData) do
        EnsureBuffSettings(data)
        local isBar = (data.settings and data.settings.displayMode) == "bar"
        local groupKey = FindBuffGroup(buffKey, db)
        local settings
        if groupKey == "ungrouped" or db.ungrouped[buffKey] then
            db.ungroupedPositions = db.ungroupedPositions or {}
            db.ungroupedPositions[buffKey] = db.ungroupedPositions[buffKey] or BuildDefaultUngroupedPositionSettings()
            settings = db.ungroupedPositions[buffKey]
            groupKey = buffKey
        else
            settings = GetGroupSettings(groupKey)
        end
        local parent = EnsureGroupFrame(groupKey, settings)
        if isBar then
            local frame = runtime.barFrames[buffKey]
            if not frame then
                frame = CreateCustomBuffBar(buffKey, data, parent)
                if frame then runtime.barFrames[buffKey] = frame end
            end
        else
            local frame = runtime.iconFrames[buffKey]
            if not frame then
                frame = CreateCustomBuffIcon(buffKey, data, parent)
                if frame then runtime.iconFrames[buffKey] = frame end
            end
        end
    end
    RefreshAllLayouts()
end

function CustomBuffs:AddCustomBuff(iconData)
    local db = GetCustomBuffsDB()
    local key = iconData.key or ("buff_" .. tostring(math.floor(GetTime() * 1000)))
    iconData.key = key
    EnsureBuffSettings(iconData)
    db.iconData[key] = iconData
    db.ungrouped[key] = true
    db.ungroupedPositions = db.ungroupedPositions or {}
    db.ungroupedPositions[key] = db.ungroupedPositions[key] or BuildDefaultUngroupedPositionSettings()
    local parent = EnsureGroupFrame(key, db.ungroupedPositions[key])
    local isBar = (iconData.settings and iconData.settings.displayMode) == "bar"
    if isBar then
        local frame = CreateCustomBuffBar(key, iconData, parent)
        if frame then
            runtime.barFrames[key] = frame
            RefreshAllLayouts()
        end
    else
        local frame = CreateCustomBuffIcon(key, iconData, parent)
        if frame then
            runtime.iconFrames[key] = frame
            RefreshAllLayouts()
        end
    end
    if self.RefreshBuffListUI then self:RefreshBuffListUI() end
    return key
end

function CustomBuffs:RebuildBuffFrame(buffKey)
    local db = GetCustomBuffsDB()
    local data = db and db.iconData[buffKey]
    if not data then return end
    EnsureBuffSettings(data)
    local groupKey = FindBuffGroup(buffKey, db)
    local settings
    if groupKey == "ungrouped" or db.ungrouped[buffKey] then
        db.ungroupedPositions = db.ungroupedPositions or {}
        db.ungroupedPositions[buffKey] = db.ungroupedPositions[buffKey] or BuildDefaultUngroupedPositionSettings()
        settings = db.ungroupedPositions[buffKey]
        groupKey = buffKey
    else
        settings = GetGroupSettings(groupKey)
    end
    local parent = EnsureGroupFrame(groupKey, settings)
    local iconF = runtime.iconFrames[buffKey]
    local barF = runtime.barFrames[buffKey]
    if iconF then
        iconF:Hide()
        iconF:SetParent(nil)
        runtime.iconFrames[buffKey] = nil
    end
    if barF then
        barF._endTime = nil
        barF:Hide()
        barF:SetParent(nil)
        runtime.barFrames[buffKey] = nil
    end
    local isBar = (data.settings and data.settings.displayMode) == "bar"
    if isBar then
        local frame = CreateCustomBuffBar(buffKey, data, parent)
        if frame then runtime.barFrames[buffKey] = frame end
    else
        local frame = CreateCustomBuffIcon(buffKey, data, parent)
        if frame then runtime.iconFrames[buffKey] = frame end
    end
    RefreshAllLayouts()
end

function CustomBuffs:RemoveCustomBuff(buffKey)
    local db = GetCustomBuffsDB()
    db.iconData[buffKey] = nil
    db.ungrouped[buffKey] = nil
    if db.ungroupedPositions then db.ungroupedPositions[buffKey] = nil end
    for _, g in pairs(db.groups) do
        for i = #(g.icons or {}), 1, -1 do
            if g.icons[i] == buffKey then table.remove(g.icons, i) end
        end
    end
    runtime.activeBuffs[buffKey] = nil
    local t = runtime.buffTimers[buffKey]
    if t and t.Cancel then t:Cancel() end
    runtime.buffTimers[buffKey] = nil
    local f = runtime.iconFrames[buffKey]
    if f then
        f:Hide()
        f:SetParent(nil)
        runtime.iconFrames[buffKey] = nil
    end
    local bar = runtime.barFrames[buffKey]
    if bar then
        bar._endTime = nil
        bar:Hide()
        bar:SetParent(nil)
        runtime.barFrames[buffKey] = nil
    end
    RefreshAllLayouts()
    if self.RefreshBuffListUI then self:RefreshBuffListUI() end
end

function CustomBuffs:CreateGroup(name)
    local db = GetCustomBuffsDB()
    local key = "group_" .. tostring(math.floor(GetTime() * 1000))
    local start = GetStartAnchorForGrowthPair("RIGHT", "DOWN")
    db.groups[key] = {
        name = name or "New Group",
        icons = {},
        settings = {
            growthDirection = "RIGHT",
            rowGrowthDirection = "DOWN",
            anchorFrom = start,
            anchorTo = start,
            spacing = 5,
            maxIconsPerRow = 10,
        },
    }
    RefreshAllLayouts()
    if self.RefreshBuffListUI then self:RefreshBuffListUI() end
    return key
end

function CustomBuffs:RemoveGroup(groupKey)
    local db = GetCustomBuffsDB()
    local g = db.groups[groupKey]
    if not g then return end
    for _, k in ipairs(g.icons or {}) do db.ungrouped[k] = true end
    db.groups[groupKey] = nil
    if uiState.selectedGroup == groupKey then uiState.selectedGroup = nil end
    RefreshAllLayouts()
    if self.RefreshBuffListUI then self:RefreshBuffListUI() end
    if self.RefreshBuffConfigUI then self:RefreshBuffConfigUI() end
    if self.RefreshAnchorVisibility then self:RefreshAnchorVisibility() end
end

function CustomBuffs:MoveBuffToGroup(buffKey, targetGroup)
    local db = GetCustomBuffsDB()
    local function removeFrom(gk)
        local g = db.groups[gk]
        if not g or not g.icons then return end
        for i = #g.icons, 1, -1 do
            if g.icons[i] == buffKey then table.remove(g.icons, i) end
        end
    end
    if targetGroup == "ungrouped" then
        db.ungrouped[buffKey] = true
        db.ungroupedPositions = db.ungroupedPositions or {}
        db.ungroupedPositions[buffKey] = db.ungroupedPositions[buffKey] or BuildDefaultUngroupedPositionSettings()
    else
        db.ungrouped[buffKey] = nil
        if db.ungroupedPositions then db.ungroupedPositions[buffKey] = nil end
        if db.groups[targetGroup] then
            db.groups[targetGroup].icons = db.groups[targetGroup].icons or {}
            removeFrom(targetGroup)
            if #db.groups[targetGroup].icons == 0 then
                local f = runtime.iconFrames[buffKey]
                if f then
                    local uis = UIParent:GetEffectiveScale()
                    local cx, cy = f:GetCenter()
                    if cx and cy then
                        cx, cy = cx / uis, cy / uis
                        local s = db.groups[targetGroup].settings or {}
                        local af = GetAnchorFrame(s.anchorFrame)
                        local ax, ay = af:GetCenter()
                        ax, ay = (ax or 0) / uis, (ay or 0) / uis
                        s.position = { x = cx - ax, y = cy - ay }
                        db.groups[targetGroup].settings = s
                    end
                end
            end
            table.insert(db.groups[targetGroup].icons, buffKey)
        end
    end
    for gk, g in pairs(db.groups) do
        for i = #(g.icons or {}), 1, -1 do
            if g.icons[i] == buffKey and gk ~= targetGroup then table.remove(g.icons, i) end
        end
    end
    if targetGroup ~= "ungrouped" then
        local c = runtime.groupFrames[buffKey]
        if c then c:Hide() runtime.groupFrames[buffKey] = nil end
    end
    RefreshAllLayouts()
    if self.RefreshBuffListUI then self:RefreshBuffListUI() end
end

function CustomBuffs:ReorderBuffInGroup(groupKey, buffKey, beforeKey)
    local db = GetCustomBuffsDB()
    if groupKey == "ungrouped" then return end
    local g = db.groups[groupKey]
    if not g or not g.icons then return end
    for i = #g.icons, 1, -1 do
        if g.icons[i] == buffKey then table.remove(g.icons, i) end
    end
    local inserted = false
    if beforeKey then
        for i, k in ipairs(g.icons) do
            if k == beforeKey then table.insert(g.icons, i, buffKey) inserted = true break end
        end
    end
    if not inserted then table.insert(g.icons, buffKey) end
    RefreshAllLayouts()
end

-- ------------------------
-- UI: list, config, create
-- ------------------------
local function MatchesSearch(buffKey, data)
    if uiState.searchText == "" then return true end
    local q = string.lower(uiState.searchText)
    local name = string.lower(GetBuffDisplayName(data))
    return name:find(q) or tostring(data.spellID):find(q)
end

local function CreateBuffNode(parent, buffKey, data, groupKey)
    if not Widgets or not THEME then return end
    local node = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    node:SetSize(240, 42)
    node:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    node:SetBackdropColor(THEME.bgMedium[1], THEME.bgMedium[2], THEME.bgMedium[3], 0.75)
    node:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.9)
    node._buffKey = buffKey
    node._hover = false
    local function highlight()
        local sel = uiState.selectedBuff == buffKey
        local bg = THEME.bgMedium
        local border = THEME.border
        local a = 0.75
        if sel then bg = THEME.bgDark border = THEME.primary a = 0.95
        elseif node._hover then bg = THEME.bgDark border = THEME.primary a = 0.85 end
        node:SetBackdropColor(bg[1], bg[2], bg[3], a)
        node:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    end
    local tex = node:CreateTexture(nil, "ARTWORK")
    tex:SetSize(32, 32)
    tex:SetPoint("LEFT", node, "LEFT", 6, 0)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local iconID = data.iconSpellID or data.spellID
    local info = C_Spell and C_Spell.GetSpellInfo(iconID)
    tex:SetTexture((info and info.iconID) or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(iconID)) or "Interface\\Icons\\INV_Misc_QuestionMark")
    local label = node:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", tex, "RIGHT", 6, 6)
    label:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    label:SetText(GetBuffDisplayName(data))
    local badge = node:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge:SetPoint("LEFT", label, "LEFT", 0, -12)
    badge:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 0.9)
    badge:SetText(string.format("Spell %s · %ds", tostring(data.spellID), tonumber(data.duration) or 6))
    local del = CreateFrame("Button", nil, node, "UIPanelCloseButton")
    del:SetSize(16, 16)
    del:SetPoint("TOPRIGHT", node, "TOPRIGHT", -4, -4)
    del:SetScript("OnClick", function()
        CustomBuffs:ConfirmDeleteBuff(buffKey, label:GetText())
    end)
    node:SetScript("OnMouseUp", function()
        uiState.selectedBuff = buffKey
        uiState.selectedGroup = nil
        if CustomBuffs.RefreshBuffListUI then CustomBuffs:RefreshBuffListUI() end
        if CustomBuffs.RefreshBuffConfigUI then CustomBuffs:RefreshBuffConfigUI() end
    end)
    node:SetScript("OnEnter", function()
        node._hover = true
        highlight()
        if runtime.dragState.dragging then
            runtime.dragState.targetGroup = groupKey
            runtime.dragState.dropBefore = buffKey
        end
    end)
    node:SetScript("OnLeave", function()
        node._hover = false
        highlight()
        if runtime.dragState.dragging then runtime.dragState.dropBefore = nil end
    end)
    node:RegisterForDrag("LeftButton")
    node:SetScript("OnDragStart", function()
        runtime.dragState.buffKey = buffKey
        runtime.dragState.sourceGroup = groupKey
        runtime.dragState.dropBefore = nil
        runtime.dragState.dragging = true
        node:SetAlpha(0.35)
    end)
    node:SetScript("OnDragStop", function()
        if runtime.dragState.dragging then
            local tg = runtime.dragState.targetGroup or runtime.dragState.sourceGroup
            local before = runtime.dragState.dropBefore
            if tg then
                if tg ~= runtime.dragState.sourceGroup then CustomBuffs:MoveBuffToGroup(buffKey, tg) end
                CustomBuffs:ReorderBuffInGroup(tg, buffKey, before)
            end
        end
        runtime.dragState.buffKey = nil
        runtime.dragState.targetGroup = nil
        runtime.dragState.dropBefore = nil
        runtime.dragState.dragging = false
        node:SetAlpha(1)
        if CustomBuffs.RefreshBuffListUI then CustomBuffs:RefreshBuffListUI() end
    end)
    highlight()
    return node
end

function CustomBuffs:RefreshBuffListUI()
    if not uiFrames.listParent or not Widgets or not THEME then return end
    for _, c in ipairs({ uiFrames.listParent:GetChildren() }) do
        c:Hide()
        c:SetParent(nil)
    end
    local db = GetCustomBuffsDB()
    local y = -5
    local shown, total = 0, 0

    local function renderSection(title, keys, groupKey)
        local collapsed = uiState.collapsedGroups[groupKey] == true
        local selGroup = uiState.selectedGroup == groupKey
        local headerHover = false
        local box = CreateFrame("Frame", nil, uiFrames.listParent, "BackdropTemplate")
        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
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
        if uiState.collapsedGroups[groupKey] then
            arrowBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
        else
            arrowBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
        end
        arrowBtn:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
        local function boxHighlight()
            local bg = selGroup and THEME.bgDark or THEME.bgMedium
            local a = selGroup and 0.9 or 0.6
            local border = (selGroup or headerHover) and THEME.primary or THEME.border
            box:SetBackdropColor(bg[1], bg[2], bg[3], a)
            box:SetBackdropBorderColor(border[1], border[2], border[3], 1)
        end
        header:SetScript("OnEnter", function()
            headerHover = true
            if runtime.dragState.buffKey then runtime.dragState.targetGroup = groupKey end
            boxHighlight()
        end)
        header:SetScript("OnLeave", function()
            headerHover = false
            if runtime.dragState.targetGroup == groupKey then runtime.dragState.targetGroup = nil end
            boxHighlight()
        end)
        header:SetScript("OnMouseUp", function()
            uiState.selectedGroup = groupKey
            uiState.selectedBuff = nil
            selGroup = true
            boxHighlight()
            CustomBuffs:RefreshBuffListUI()
            CustomBuffs:RefreshBuffConfigUI()
        end)
        arrowBtn:SetScript("OnClick", function()
            uiState.collapsedGroups[groupKey] = not uiState.collapsedGroups[groupKey]
            CustomBuffs:RefreshBuffListUI()
        end)
        local innerY = -28
        if not collapsed then
            for _, k in ipairs(keys) do
                local d = db.iconData[k]
                if d then
                    total = total + 1
                    if MatchesSearch(k, d) then
                        local n = CreateBuffNode(box, k, d, groupKey)
                        n:SetPoint("TOPLEFT", box, "TOPLEFT", 8, innerY)
                        innerY = innerY - 46
                        shown = shown + 1
                    end
                end
            end
        else
            for _, k in ipairs(keys) do
                if db.iconData[k] then total = total + 1 end
            end
        end
        box:SetHeight(math.abs(innerY) + 8)
        y = y - box:GetHeight() - 8
    end

    -- Sort buffs by display name for consistent organization
    local function sortBuffsByName(a, b)
        local na = GetBuffDisplayName(db.iconData[a] or {})
        local nb = GetBuffDisplayName(db.iconData[b] or {})
        if na ~= nb then return na < nb end
        return tostring(a) < tostring(b)
    end

    local ungroupedKeys = {}
    for k in pairs(db.ungrouped) do table.insert(ungroupedKeys, k) end
    table.sort(ungroupedKeys, sortBuffsByName)
    renderSection("Ungrouped Buffs", ungroupedKeys, "ungrouped")
    for gk, g in pairs(db.groups) do
        local keys = {}
        local seen = {}
        for _, k in ipairs(g.icons or {}) do
            if db.iconData[k] and not seen[k] then
                table.insert(keys, k)
                seen[k] = true
            end
        end
        table.sort(keys, sortBuffsByName)
        renderSection(GetGroupDisplayName(gk), keys, gk)
    end
    if uiFrames.resultText then
        uiFrames.resultText:SetText(string.format("Showing %d of %d", shown, total))
    end
    uiFrames.listParent:SetHeight(math.abs(y) + 20)
end

function CustomBuffs:RefreshBuffConfigUI()
    if not uiFrames.configParent or not Widgets or not THEME then return end
    for _, c in ipairs({ uiFrames.configParent:GetChildren() }) do
        c:Hide()
        c:SetParent(nil)
    end
    local db = GetCustomBuffsDB()
    local buffKey = uiState.selectedBuff
    local groupKey = uiState.selectedGroup
    local data = buffKey and db.iconData[buffKey]
    local selGroup = groupKey and db.groups[groupKey]
    local y = 0

    local function addSectionHeader(title)
        if Widgets and Widgets.CreateHeader then
            Widgets.CreateHeader(uiFrames.configParent, { name = title }, y)
        end
        y = y + 32
    end

    local function applyCurrentBuffVisuals()
        if not buffKey or not data then return end
        local f = GetBuffFrame(buffKey)
        if f then
            if (data.settings and data.settings.displayMode) == "bar" then
                ApplyBarSettings(f, data)
            else
                ApplyIconSettings(f, data)
                UpdateBuffIconDesaturation(buffKey)
            end
        end
        RefreshAllLayouts()
        CustomBuffs:RefreshBuffListUI()
    end

    local function addSlider(name, min, max, step, get, set)
        local opt = {
            name = name,
            min = min, max = max, step = step,
            get = get,
            set = function(_, v)
                set(v)
                applyCurrentBuffVisuals()
            end,
            width = "full",
        }
        local w = Widgets.CreateRange(uiFrames.configParent, opt, y, {})
        if w.slider and w.slider.SetObeyStepOnDrag then w.slider:SetObeyStepOnDrag(true) end
        if w.slider and get then w.slider:SetValue(get()) end
        y = y + 36
    end

    local function showBuffConfig()
        if not data then return end
        EnsureBuffSettings(data)

        addSectionHeader("Display")
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Display",
            values = { icon = "Icon", bar = "Bar" },
            get = function() return data.settings.displayMode or "icon" end,
            set = function(_, v)
                data.settings.displayMode = v
                CustomBuffs:RebuildBuffFrame(buffKey)
                CustomBuffs:RefreshBuffConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 40

        Widgets.CreateExecute(uiFrames.configParent, {
            name = "Load Conditions",
            func = function()
                CustomBuffs:ShowLoadConditionsWindow(buffKey, data)
            end,
            width = "full",
        }, y)
        y = y + 32

        local isBar = (data.settings.displayMode or "icon") == "bar"
        if not isBar then
        addSectionHeader("Appearance")
        addSlider("Icon Size", 16, 128, 1, function() return data.settings.iconSize or 44 end, function(v) data.settings.iconSize = v end)
        addSlider("Aspect Ratio", 0.5, 2.0, 0.01, function() return data.settings.aspectRatio or 1.0 end, function(v) data.settings.aspectRatio = v end)
        addSlider("Border Size", 0, 10, 1, function() return data.settings.borderSize or 1 end, function(v) data.settings.borderSize = v end)
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Border Color",
            get = function() return unpack(data.settings.borderColor or { 0, 0, 0, 1 }) end,
            set = function(_, r, g, b, a)
                data.settings.borderColor = { r, g, b, a }
                applyCurrentBuffVisuals()
            end,
            width = "full",
        }, y)
        y = y + 40
        addSectionHeader("Cooldown")
        addSlider("Cooldown Text Size", 4, 64, 1, function()
            local c = data.settings.cooldownSettings or {}
            return c.size or 12
        end, function(v)
            data.settings.cooldownSettings = data.settings.cooldownSettings or {}
            data.settings.cooldownSettings.size = v
        end)
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Cooldown Text Color",
            get = function()
                local c = data.settings.cooldownSettings or {}
                return unpack(c.color or { 1, 1, 1, 1 })
            end,
            set = function(_, r, g, b, a)
                data.settings.cooldownSettings = data.settings.cooldownSettings or {}
                data.settings.cooldownSettings.color = { r, g, b, a }
                applyCurrentBuffVisuals()
            end,
            width = "full",
        }, y)
        y = y + 40
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Show Cooldown",
            get = function() return data.settings.showCooldown ~= false end,
            set = function(_, v)
                data.settings.showCooldown = v
                applyCurrentBuffVisuals()
                CustomBuffs:RefreshBuffConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 32
        addSlider("Cooldown Swipe Alpha", 0, 1, 0.05, function()
            local v = data.settings.cooldownSwipeAlpha
            return (v ~= nil) and v or 0.8
        end, function(v) data.settings.cooldownSwipeAlpha = v end)
        addSectionHeader("Behavior")
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Always show icon",
            get = function() return data.settings.alwaysShow == true end,
            set = function(_, v)
                data.settings.alwaysShow = v == true
                applyCurrentBuffVisuals()
                CustomBuffs:RefreshBuffConfigUI()
            end,
            width = "full",
        }, y)
        y = y + 32
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Desaturate when inactive",
            get = function() return data.settings.desaturateWhenInactive == true end,
            set = function(_, v)
                data.settings.desaturateWhenInactive = v == true
                applyCurrentBuffVisuals()
            end,
            width = "full",
        }, y)
        y = y + 32
        else
        addSectionHeader("Appearance")
        -- Bar options
        local bs = data.settings.barSettings or {}
        local function barApply()
            bs = data.settings.barSettings or {}
            applyCurrentBuffVisuals()
        end
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Foreground Texture",
            values = function()
                if not LSM then return { [""] = "Default" } end
                local ht = LSM:HashTable("statusbar") or {}
                local t = { [""] = "Global" }
                for name, _ in pairs(ht) do t[name] = name end
                return t
            end,
            get = function() return bs.foregroundTexture or "" end,
            set = function(_, v) bs.foregroundTexture = (v and v ~= "") and v or nil barApply() end,
            width = "full",
        }, y)
        y = y + 40
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Foreground Color",
            hasAlpha = true,
            get = function() return unpack(bs.foregroundColor or { 0.2, 0.6, 1, 1 }) end,
            set = function(_, r, g, b, a) bs.foregroundColor = { r, g, b, a } barApply() end,
            width = "full",
        }, y)
        y = y + 40
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Background Color",
            hasAlpha = true,
            get = function() return unpack(bs.backgroundColor or { 0.15, 0.15, 0.15, 0.8 }) end,
            set = function(_, r, g, b, a) bs.backgroundColor = { r, g, b, a } barApply() end,
            width = "full",
        }, y)
        y = y + 40
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Show Spell ID Icon",
            get = function() return bs.showSpellIcon ~= false end,
            set = function(_, v) bs.showSpellIcon = v barApply() CustomBuffs:RefreshBuffConfigUI() end,
            width = "full",
        }, y)
        y = y + 32
        addSlider("Border Size", 0, 10, 1, function() return bs.borderSize or 1 end, function(v) bs.borderSize = v end)
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Border Color",
            hasAlpha = true,
            get = function() return unpack(bs.borderColor or { 0, 0, 0, 1 }) end,
            set = function(_, r, g, b, a) bs.borderColor = { r, g, b, a } barApply() end,
            width = "full",
        }, y)
        y = y + 40
        addSlider("Width", 40, 500, 1, function() return bs.width or 180 end, function(v) bs.width = v end)
        addSlider("Height", 8, 80, 1, function() return bs.height or 18 end, function(v) bs.height = v end)
        local anchorPoints = {
            LEFT = "Left", RIGHT = "Right", CENTER = "Center",
            TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right",
            BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right",
        }
        addSectionHeader("Bar Text")
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Show Duration Text",
            get = function() return (bs.durationText or {}).show ~= false end,
            set = function(_, v) bs.durationText = bs.durationText or {} bs.durationText.show = v barApply() end,
            width = "full",
        }, y)
        y = y + 32
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Duration Text Anchor",
            values = anchorPoints,
            get = function() return (bs.durationText or {}).anchor or "RIGHT" end,
            set = function(_, v) bs.durationText = bs.durationText or {} bs.durationText.anchor = v barApply() end,
            width = "full",
        }, y)
        y = y + 40
        addSlider("Duration Text Size", 6, 32, 1, function() return (bs.durationText or {}).size or 12 end, function(v) bs.durationText = bs.durationText or {} bs.durationText.size = v end)
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Duration Text Color",
            hasAlpha = true,
            get = function() return unpack((bs.durationText or {}).color or { 1, 1, 1, 1 }) end,
            set = function(_, r, g, b, a) bs.durationText = bs.durationText or {} bs.durationText.color = { r, g, b, a } barApply() end,
            width = "full",
        }, y)
        y = y + 40
        addSlider("Duration Text X", -200, 200, 1, function() return (bs.durationText or {}).posX or -4 end, function(v) bs.durationText = bs.durationText or {} bs.durationText.posX = v end)
        addSlider("Duration Text Y", -100, 100, 1, function() return (bs.durationText or {}).posY or 0 end, function(v) bs.durationText = bs.durationText or {} bs.durationText.posY = v end)
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Show Name Text",
            get = function() return (bs.nameText or {}).show ~= false end,
            set = function(_, v) bs.nameText = bs.nameText or {} bs.nameText.show = v barApply() end,
            width = "full",
        }, y)
        y = y + 32
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Name Text Anchor",
            values = anchorPoints,
            get = function() return (bs.nameText or {}).anchor or "LEFT" end,
            set = function(_, v) bs.nameText = bs.nameText or {} bs.nameText.anchor = v barApply() end,
            width = "full",
        }, y)
        y = y + 40
        addSlider("Name Text Size", 6, 32, 1, function() return (bs.nameText or {}).size or 12 end, function(v) bs.nameText = bs.nameText or {} bs.nameText.size = v end)
        Widgets.CreateColor(uiFrames.configParent, {
            name = "Name Text Color",
            hasAlpha = true,
            get = function() return unpack((bs.nameText or {}).color or { 1, 1, 1, 1 }) end,
            set = function(_, r, g, b, a) bs.nameText = bs.nameText or {} bs.nameText.color = { r, g, b, a } barApply() end,
            width = "full",
        }, y)
        y = y + 40
        addSlider("Name Text X", -200, 200, 1, function() return (bs.nameText or {}).posX or 4 end, function(v) bs.nameText = bs.nameText or {} bs.nameText.posX = v end)
        addSlider("Name Text Y", -100, 100, 1, function() return (bs.nameText or {}).posY or 0 end, function(v) bs.nameText = bs.nameText or {} bs.nameText.posY = v end)
        addSectionHeader("Behavior")
        Widgets.CreateToggle(uiFrames.configParent, {
            name = "Always Show",
            get = function() return data.settings.alwaysShow == true end,
            set = function(_, v) data.settings.alwaysShow = v == true barApply() CustomBuffs:RefreshBuffConfigUI() end,
            width = "full",
        }, y)
        y = y + 32
        end
        addSectionHeader("Identity")
        -- Spell ID (read-only display), Duration, Icon Spell ID (shared)
        Widgets.CreateInput(uiFrames.configParent, {
            name = "Spell ID (watch)",
            get = function() return tostring(data.spellID or "") end,
            set = function() end,
            width = "full",
        }, y)
        y = y + 40
        addSlider("Duration (seconds)", 1, 120, 1, function() return tonumber(data.duration) or 6 end, function(v) data.duration = v end)
        Widgets.CreateInput(uiFrames.configParent, {
            name = "Icon Spell ID (blank = watch ID)",
            get = function() return data.iconSpellID and tostring(data.iconSpellID) or "" end,
            set = function(_, val)
                local n = tonumber(val)
                data.iconSpellID = (n and n > 0) and n or nil
                local f = GetBuffFrame(buffKey)
                if f and data then
                    local sid = data.iconSpellID or data.spellID
                    local info = C_Spell and C_Spell.GetSpellInfo(sid)
                    local tex = (info and info.iconID) or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(sid)) or "Interface\\Icons\\INV_Misc_QuestionMark"
                    if f.icon then f.icon:SetTexture(tex) elseif f.Icon then f.Icon:SetTexture(tex) end
                end
                if (data.settings and data.settings.displayMode) == "bar" then
                    local bar = runtime.barFrames[buffKey]
                    if bar and bar.NameText then
                        bar.NameText:SetText(GetBuffDisplayName(data))
                    end
                end
                applyCurrentBuffVisuals()
            end,
            width = "full",
        }, y)
        y = y + 40
        Widgets.CreateInput(uiFrames.configParent, {
            name = "Display Name (blank = spell name)",
            get = function() return data.customName or "" end,
            set = function(_, val)
                data.customName = (val and val ~= "" and val:gsub("^%s+", ""):gsub("%s+$", "") ~= "") and val:gsub("^%s+", ""):gsub("%s+$", "") or nil
                CustomBuffs:RefreshBuffListUI()
                if (data.settings and data.settings.displayMode) == "bar" then
                    local bar = runtime.barFrames[buffKey]
                    if bar and bar.NameText then
                        bar.NameText:SetText(GetBuffDisplayName(data))
                    end
                end
                applyCurrentBuffVisuals()
            end,
            width = "full",
        }, y)
    end

    local function ensureGroupDefaults(g)
        g.settings = g.settings or {}
        local s = g.settings
        s.growthDirection = s.growthDirection or "RIGHT"
        s.rowGrowthDirection = NormalizeRowGrowth(s.growthDirection, s.rowGrowthDirection or GetDefaultRowGrowth(s.growthDirection))
        if s.maxIconsPerRow == nil and s.maxColumns then s.maxIconsPerRow = s.maxColumns s.maxColumns = nil end
        if s.anchorPoint and not s.anchorFrom and not s.anchorTo then s.anchorFrom = s.anchorPoint s.anchorTo = s.anchorPoint s.anchorPoint = nil end
        s.anchorFrom = s.anchorFrom or GetStartAnchorForGrowthPair(s.growthDirection, s.rowGrowthDirection)
        s.anchorTo = s.anchorTo or s.anchorFrom
        s.spacing = s.spacing or 5
        s.position = s.position or { x = 100, y = -100 }
        s.anchorFrame = s.anchorFrame or ""
    end

    local function showGroupConfig()
        if not selGroup then
            local lab = uiFrames.configParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            lab:SetPoint("TOPLEFT", uiFrames.configParent, "TOPLEFT", 0, 20)
            lab:SetText("Select a buff or group")
            lab:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
            return
        end
        ensureGroupDefaults(selGroup)
        local s = selGroup.settings
        Widgets.CreateInput(uiFrames.configParent, {
            name = "Group Name",
            get = function() return selGroup.name or "" end,
            set = function(_, v) selGroup.name = v or "Group" CustomBuffs:RefreshBuffListUI() end,
            width = "full",
        }, y)
        y = y + 40
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Growth Direction",
            values = { RIGHT = "Right", LEFT = "Left", UP = "Up", DOWN = "Down" },
            get = function() return s.growthDirection end,
            set = function(_, v)
                s.growthDirection = v
                s.rowGrowthDirection = NormalizeRowGrowth(v, s.rowGrowthDirection or GetDefaultRowGrowth(v))
                s.anchorFrom = GetStartAnchorForGrowthPair(v, s.rowGrowthDirection)
                RefreshAllLayouts()
                CustomBuffs:RefreshBuffConfigUI()
            end,
            width = "normal",
        }, y, nil, nil, nil)
        y = y + 40
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Row Growth",
            values = { RIGHT = "Right", LEFT = "Left", UP = "Up", DOWN = "Down" },
            get = function() return s.rowGrowthDirection end,
            set = function(_, v)
                s.rowGrowthDirection = NormalizeRowGrowth(s.growthDirection or "RIGHT", v)
                s.anchorFrom = GetStartAnchorForGrowthPair(s.growthDirection or "RIGHT", s.rowGrowthDirection)
                RefreshAllLayouts()
                CustomBuffs:RefreshBuffConfigUI()
            end,
            width = "normal",
        }, y, nil, nil, nil)
        y = y + 40
        Widgets.CreateSelect(uiFrames.configParent, {
            name = "Anchor Frame Point",
            values = {
                TOPLEFT = "TOPLEFT", TOP = "TOP", TOPRIGHT = "TOPRIGHT",
                LEFT = "LEFT", CENTER = "CENTER", RIGHT = "RIGHT",
                BOTTOMLEFT = "BOTTOMLEFT", BOTTOM = "BOTTOM", BOTTOMRIGHT = "BOTTOMRIGHT",
            },
            get = function() return s.anchorTo end,
            set = function(_, v) s.anchorTo = v RefreshAllLayouts() CustomBuffs:RefreshBuffConfigUI() end,
            width = "full",
        }, y, nil, nil, nil)
        y = y + 40
        addSlider("Spacing", -10, 10, 1, function() return s.spacing or 5 end, function(v) s.spacing = v end)
        addSlider("Max Buffs Per Row", 1, 40, 1, function() return s.maxIconsPerRow or 10 end, function(v) s.maxIconsPerRow = v end)
        addSlider("Position X", -1000, 1000, 1, function() return (s.position and s.position.x) or 0 end, function(v) s.position = s.position or {} s.position.x = v end)
        addSlider("Position Y", -1000, 1000, 1, function() return (s.position and s.position.y) or 0 end, function(v) s.position = s.position or {} s.position.y = v end)
        Widgets.CreateInput(uiFrames.configParent, {
            name = "Anchor Frame",
            get = function() return s.anchorFrame or "" end,
            set = function(_, v)
                s.anchorFrame = (v and v ~= "") and v or ""
                if C_Timer and C_Timer.After then C_Timer.After(0.05, RefreshAllLayouts) else RefreshAllLayouts() end
            end,
            width = "full",
        }, y)
        y = y + 40
        Widgets.CreateExecute(uiFrames.configParent, {
            name = "Delete Group",
            func = function() CustomBuffs:RemoveGroup(groupKey) end,
            width = "full",
        }, y)
    end

    local function updateScrollHeight()
        if uiFrames.configChild then
            uiFrames.configChild:SetHeight(math.max(y + 20, 1))
        end
    end

    if data then
        showBuffConfig()
        updateScrollHeight()
        return
    end
    if selGroup then
        showGroupConfig()
        updateScrollHeight()
        return
    end
    local lab = uiFrames.configParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    lab:SetPoint("TOPLEFT", uiFrames.configParent, "TOPLEFT", 0, 20)
    lab:SetText("Select a buff or group")
    lab:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
    updateScrollHeight()
end

function CustomBuffs:ConfirmDeleteBuff(buffKey, label)
    if not uiFrames.confirmFrame then
        local f = CreateFrame("Frame", "NephUI_CBConfirm", UIParent, "BackdropTemplate")
        f:SetSize(320, 140)
        f:SetPoint("CENTER")
        f:SetFrameStrata("TOOLTIP")
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
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
    f.text:SetText(("Delete \"%s\"?\nThis cannot be undone."):format(label or "buff"))
    f.confirm:SetScript("OnClick", function()
        f:Hide()
        CustomBuffs:RemoveCustomBuff(buffKey)
    end)
    f.cancel:SetScript("OnClick", function() f:Hide() end)
    f:Show()
end

function CustomBuffs:ShowCreateBuffDialog()
    if not Widgets or not THEME then return end
    if not uiFrames.createFrame then
        local f = CreateFrame("Frame", "NephUI_CBCreate", UIParent, "BackdropTemplate")
        f:SetSize(360, 260)
        f:SetPoint("CENTER")
        f:SetFrameStrata("TOOLTIP")
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        f:SetBackdropColor(THEME.bgDark[1], THEME.bgDark[2], THEME.bgDark[3], 0.95)
        f:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 1)
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", f, "TOP", 0, -12)
        f.title:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
        f.title:SetText("Create Custom Buff")
        local l1 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        l1:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -42)
        l1:SetText("Spell ID to watch (UNIT_SPELLCAST_SUCCEEDED)")
        local idBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        idBox:SetAutoFocus(false)
        idBox:SetSize(140, 24)
        idBox:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -58)
        idBox:SetNumeric(true)
        idBox:SetMaxLetters(8)
        idBox:SetText("")
        f.idInput = idBox
        local l2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        l2:SetPoint("TOPLEFT", idBox, "BOTTOMLEFT", 0, -8)
        l2:SetText("Icon Spell ID (optional; blank = watch ID)")
        local iconBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        iconBox:SetAutoFocus(false)
        iconBox:SetSize(140, 24)
        iconBox:SetPoint("TOPLEFT", l2, "BOTTOMLEFT", 0, -4)
        iconBox:SetNumeric(true)
        iconBox:SetMaxLetters(8)
        iconBox:SetText("")
        f.iconInput = iconBox
        local l3 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        l3:SetPoint("TOPLEFT", iconBox, "BOTTOMLEFT", 0, -8)
        l3:SetText("Duration (seconds)")
        local durBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        durBox:SetAutoFocus(false)
        durBox:SetSize(80, 24)
        durBox:SetPoint("TOPLEFT", l3, "BOTTOMLEFT", 0, -4)
        durBox:SetNumeric(true)
        durBox:SetMaxLetters(4)
        durBox:SetText("6")
        f.durInput = durBox
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
            local idVal = tonumber(f.idInput:GetText() or "")
            if not idVal or idVal <= 0 then
                if UIErrorsFrame then UIErrorsFrame:AddMessage("Enter a valid Spell ID", 1, 0, 0) end
                return
            end
            local iconVal = tonumber(f.iconInput:GetText() or "")
            if iconVal and iconVal <= 0 then iconVal = nil end
            local dur = tonumber(f.durInput:GetText() or "6") or 6
            if dur <= 0 then dur = 6 end
            CustomBuffs:AddCustomBuff({
                spellID = idVal,
                iconSpellID = iconVal or nil,
                duration = dur,
            })
            f:Hide()
            f.idInput:SetText("")
            f.iconInput:SetText("")
            f.durInput:SetText("6")
        end)
        uiFrames.createFrame = f
    end
    uiFrames.createFrame:Show()
end

-- ------------------------
-- Build UI
-- ------------------------
function CustomBuffs:BuildCustomBuffsUI(parent)
    EnsureEventFrame()
    if not Widgets or not THEME then return end
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)

    local search = Widgets.CreateInput(container, {
        name = "Search by name or spell ID...",
        width = "full",
        get = function() return uiState.searchText end,
        set = function(_, v)
            uiState.searchText = v or ""
            CustomBuffs:RefreshBuffListUI()
        end,
    }, 0)
    if search.editBox then search.editBox:SetHeight(28) end

    local resultText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if search.editBox then
        resultText:SetPoint("TOPLEFT", search.editBox, "BOTTOMLEFT", 4, -6)
    else
        resultText:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -34)
    end
    resultText:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3], 1)
    uiFrames.resultText = resultText

    local createBtn = Widgets.CreateExecute(container, {
        name = "+ Create Buff",
        func = function() CustomBuffs:ShowCreateBuffDialog() end,
        width = "normal",
    }, 40)
    if search.editBox then
        createBtn:SetPoint("TOPLEFT", search.editBox, "BOTTOMLEFT", 0, -18)
    else
        createBtn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -52)
    end

    local createGroupBtn = Widgets.CreateExecute(container, {
        name = "+ Create Group",
        func = function() CustomBuffs:CreateGroup("New Group") end,
        width = "normal",
    }, 40)
    createGroupBtn:SetPoint("LEFT", createBtn, "RIGHT", 8, 0)

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

    local config = CreateFrame("Frame", nil, container, "BackdropTemplate")
    config:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", 12, 0)
    config:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    config:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    config:SetBackdropColor(THEME.bgMedium[1], THEME.bgMedium[2], THEME.bgMedium[3], 0.5)
    config:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 1)

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

    CustomBuffs:RefreshBuffListUI()
    CustomBuffs:RefreshBuffConfigUI()
end

-- ------------------------
-- Anchors
-- ------------------------
function CustomBuffs:SetConfigMode(enabled)
    for gk, c in pairs(runtime.groupFrames) do
        if c and c.anchor then
            if enabled then c.anchor:Show() else c.anchor:Hide() end
        end
    end
end

function CustomBuffs:DisableConfigMode()
    self:SetConfigMode(false)
end

ShouldShowAnchors = function()
    local uf = NephUI.db and NephUI.db.profile and NephUI.db.profile.unitFrames
    if uf and uf.General and uf.General.ShowEditModeAnchors then return true end
    return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

function CustomBuffs:RefreshAnchorVisibility()
    self:SetConfigMode(ShouldShowAnchors())
    RefreshAllLayouts()
end

local anchorHooked = false
local function EnsureAnchorHooks()
    if anchorHooked then return end
    if NephUI.UnitFrames and NephUI.UnitFrames.UpdateEditModeAnchors then
        hooksecurefunc(NephUI.UnitFrames, "UpdateEditModeAnchors", function()
            CustomBuffs:RefreshAnchorVisibility()
        end)
        anchorHooked = true
    end
end

-- ------------------------
-- Init
-- ------------------------
if NephUI.db and NephUI.db.profile then
    local profile = NephUI.db.profile
    profile.customBuffs = profile.customBuffs or {}
    if profile.customBuffs.enabled ~= false then
        CustomBuffs:LoadCustomBuffs()
        CustomBuffs:RefreshAnchorVisibility()
        EnsureAnchorHooks()
    end
    if EditModeManagerFrame then
        if EditModeManagerFrame.ExitEditMode then
            hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() CustomBuffs:RefreshAnchorVisibility() end)
        end
        if EditModeManagerFrame.EnterEditMode then
            hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() CustomBuffs:RefreshAnchorVisibility() end)
        end
    end
    EnsureAnchorHooks()
end

if not CustomBuffs.__anchorWatcher then
    local w = CreateFrame("Frame")
    w:RegisterEvent("PLAYER_ENTERING_WORLD")
    w:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    w:SetScript("OnEvent", function(_, event)
        -- Ensure custom buffs are loaded when the world is ready
        -- This handles cases where NephUI.db wasn't ready at file load time
        if event == "PLAYER_ENTERING_WORLD" then
            if NephUI.db and NephUI.db.profile then
                local profile = NephUI.db.profile
                profile.customBuffs = profile.customBuffs or {}
                if profile.customBuffs.enabled ~= false then
                    CustomBuffs:LoadCustomBuffs()
                end
            end
        end
        EnsureAnchorHooks()
        CustomBuffs:RefreshAnchorVisibility()
    end)
    CustomBuffs.__anchorWatcher = w
end
