local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

-- Unit Frame System
NephUI.UnitFrames = NephUI.UnitFrames or {}
local UF = NephUI.UnitFrames

-- Unit to frame name mapping
local UnitToFrameName = {
    player = "NephUI_Player",
    target = "NephUI_Target",
    targettarget = "NephUI_TargetTarget",
    pet = "NephUI_Pet",
    focus = "NephUI_Focus",
    boss = "NephUI_Boss",
}

-- Track delayed initialization when called during combat lockdown
local pendingInitAfterCombat = false
local function EnsureDelayedInitListener()
    if UF._delayedInitFrame then
        return UF._delayedInitFrame
    end

    UF._delayedInitFrame = CreateFrame("Frame")
    UF._delayedInitFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_ENABLED" then
            self:UnregisterEvent(event)
            pendingInitAfterCombat = false

            -- Retry initialization now that combat lockdown is lifted
            if NephUI.UnitFrames and NephUI.UnitFrames.Initialize then
                NephUI.UnitFrames:Initialize()
            end
        end
    end)

    return UF._delayedInitFrame
end

-- Media and constants
UF.Media = {
    ForegroundTexture = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill",
    BackgroundTexture = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill",
    Font = "Fonts\\FRIZQT__.TTF",
    FontSize = 12,
    FontFlag = "OUTLINE"
}

-- Export helper tables and functions
UF.UnitToFrameName = UnitToFrameName

-- Power bar colors
local PowerBarColor = {
    [0] = { r = 0.00, g = 0.00, b = 1.00 }, -- Mana
    [1] = { r = 1.00, g = 0.00, b = 0.00 }, -- Rage
    [2] = { r = 1.00, g = 0.50, b = 0.25 }, -- Focus
    [3] = { r = 1.00, g = 1.00, b = 0.00 }, -- Energy
    [4] = { r = 0.00, g = 1.00, b = 1.00 }, -- Happiness
    [5] = { r = 0.50, g = 0.50, b = 0.50 }, -- Runes
    [6] = { r = 0.00, g = 0.82, b = 1.00 }, -- Runic Power
}

-- Preview portraits
local PreviewPortraits = {
    "INV_Misc_QuestionMark",
    "Achievement_Boss_Ragnaros",
    "Achievement_Boss_Illidan",
    "Achievement_Boss_YoggSaron_01",
    "Achievement_Boss_KelThuzad_01",
    "Achievement_Boss_Nefarian_01",
    "Achievement_Boss_LichKing_01",
    "Achievement_Boss_Deathbringer_Saurfang",
}

-- Resolve frame name from unit
function UF.ResolveFrameName(unit)
    if unit == "player" then
        return "NephUI_Player"
    elseif unit == "target" then
        return "NephUI_Target"
    elseif unit == "focus" then
        return "NephUI_Focus"
    elseif unit:match("^boss%d+$") then
        return "NephUI_" .. unit:gsub("^b", "B")
    elseif unit == "targettarget" then
        return "NephUI_TargetTarget"
    elseif unit == "focustarget" then
        return "NephUI_FocusTarget"
    elseif unit == "pet" then
        return "NephUI_Pet"
    end
    return "NephUI_" .. unit
end

-- Get power bar database
function UF.GetPowerBarDB(unit)
    local db = NephUI.db.profile.unitFrames
    if not db then return nil end

    local dbUnit = unit
    if unit:match("^boss(%d+)$") then dbUnit = "boss" end

    local unitDB = db[dbUnit]
    if not unitDB or not unitDB.PowerBar then return nil end

    return unitDB.PowerBar
end

-- Fetch unit color based on settings
function UF.FetchUnitColor(unit, unitDB)
    if not unitDB then return 0.5, 0.5, 0.5, 1.0 end

    local useClassColor = unitDB.ClassColor or unitDB.ClassColour
    local useReactionColor = unitDB.ReactionColor or unitDB.ReactionColour

    if useClassColor and useReactionColor then
        -- Priority: class color first, then reaction
        local _, class = UnitClass(unit)
        if class and RAID_CLASS_COLORS[class] then
            return RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1.0
        end
    elseif useClassColor then
        local _, class = UnitClass(unit)
        if class and RAID_CLASS_COLORS[class] then
            return RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1.0
        end
    elseif useReactionColor then
        local reaction = UnitReaction(unit, "player")
        if reaction and FACTION_BAR_COLORS[reaction] then
            return FACTION_BAR_COLORS[reaction].r, FACTION_BAR_COLORS[reaction].g, FACTION_BAR_COLORS[reaction].b, 1.0
        end
    end

    -- Fallback to custom colors
    return (unitDB.FGColor and unitDB.FGColor[1]) or 0.5,
           (unitDB.FGColor and unitDB.FGColor[2]) or 0.5,
           (unitDB.FGColor and unitDB.FGColor[3]) or 0.5,
           (unitDB.FGColor and unitDB.FGColor[4]) or 1.0
end

-- Fetch name text color
function UF.FetchNameTextColor(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class and RAID_CLASS_COLORS[class] then
            return RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1.0
        end
    else
        local reaction = UnitReaction(unit, "player")
        if reaction and FACTION_BAR_COLORS[reaction] then
            return FACTION_BAR_COLORS[reaction].r, FACTION_BAR_COLORS[reaction].g, FACTION_BAR_COLORS[reaction].b, 1.0
        end
    end
    return 1.0, 1.0, 1.0, 1.0
end

-- Update unit auras
function UF.UpdateUnitAuras(unitFrame)
    -- Aura updating logic would go here
    -- This is a placeholder for the aura system
end

-- Update unit frame power bar
function UF.UpdateUnitFramePowerBar(unitFrame)
    local unit = unitFrame.unit
    if not unit or not UnitExists(unit) then return end

    local powerBarDB = UF.GetPowerBarDB(unit)
    if not powerBarDB or not powerBarDB.Enabled then
        if unitFrame.PowerBar then unitFrame.PowerBar:Hide() end
        return
    end

    if not unitFrame.PowerBar then return end

    local powerType = UnitPowerType(unit)
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)

    -- Use pcall to safely check comparison since secret values pass type check but can't be compared
    local maxPowerValid = false
    if type(maxPower) == "number" then
        local success, result = pcall(function() return maxPower > 0 end)
        if success then
            maxPowerValid = result
        end
    end

    if maxPowerValid then
        unitFrame.PowerBar:SetMinMaxValues(0, maxPower)
        unitFrame.PowerBar:SetValue(power)

        local powerColor = PowerBarColor[powerType] or PowerBarColor[0]
        unitFrame.PowerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

        if unitFrame.PowerBG then
            unitFrame.PowerBG:SetMinMaxValues(0, maxPower)
            unitFrame.PowerBG:SetValue(maxPower)
            unitFrame.PowerBG:SetVertexColor(powerColor.r * 0.3, powerColor.g * 0.3, powerColor.b * 0.3, 1.0)
        end

        unitFrame.PowerBar:Show()
    else
        unitFrame.PowerBar:Hide()
    end
end

-- Media resolution
function UF:ResolveMedia()
    self.Media = self.Media or {}

    -- Always use global font
    self.Media.Font = NephUI:GetGlobalFont()

    -- Check for texture overrides in General settings, otherwise use global texture
    local db = NephUI.db and NephUI.db.profile and NephUI.db.profile.unitFrames
    local GeneralDB = db and db.General
    local foregroundOverride = GeneralDB and GeneralDB.ForegroundTexture
    local backgroundOverride = GeneralDB and GeneralDB.BackgroundTexture

    self.Media.ForegroundTexture = NephUI:GetTexture(foregroundOverride)
    self.Media.BackgroundTexture = NephUI:GetTexture(backgroundOverride)
end

-- Helper function for text justification
function UF:SetJustification(anchorFrom)
    if anchorFrom == "TOPLEFT" or anchorFrom == "LEFT" or anchorFrom == "BOTTOMLEFT" then
        return "LEFT"
    elseif anchorFrom == "TOPRIGHT" or anchorFrom == "RIGHT" or anchorFrom == "BOTTOMRIGHT" then
        return "RIGHT"
    else
        return "CENTER"
    end
end

function UF:ApplyFrameLayer(unitFrame, GeneralDB)
    -- Apply frame layering settings
    if GeneralDB and GeneralDB.FrameStrata then
        unitFrame:SetFrameStrata(GeneralDB.FrameStrata)
    end
    if GeneralDB and GeneralDB.FrameLevel then
        unitFrame:SetFrameLevel(GeneralDB.FrameLevel)
    end
end

-- Boss preview functions
function UF:GetFakeBossData(bossIndex)
    if not bossIndex or bossIndex < 1 or bossIndex > 8 then return nil end

    local Classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER" }
    local PowerTypes = { 0, 1, 2, 3, 6, 0, 1, 2 } -- Mana, Rage, Focus, Energy, Runic Power

    -- Generate random health values
    local maxHealth = math.random(1000000, 10000000) -- Random max health between 1M and 10M
    local currentHealthPercent = math.random(10, 95) / 100 -- Random health percentage between 10% and 95%
    local health = math.floor(maxHealth * currentHealthPercent)
    local missingHealth = maxHealth - health
    local absorb = math.random(0, math.floor(maxHealth * 0.3)) -- Random absorb up to 30% of max health

    return {
        name = "Boss " .. bossIndex,
        class = Classes[bossIndex] or "WARRIOR",
        reaction = bossIndex % 2 == 0 and 2 or 5, -- Hostile or friendly
        health = health,
        maxHealth = maxHealth,
        missingHealth = missingHealth,
        absorb = absorb,
        power = math.random(20, 90),
        maxPower = 100,
        powerType = PowerTypes[bossIndex] or 0,
        portraitIndex = bossIndex,
        raidTargetIndex = (bossIndex <= 8) and bossIndex or nil -- Show raid markers 1-8 on bosses 1-8
    }
end

function UF:ApplyBossPreviewData(unitFrame, bossIndex)
    if not unitFrame or not self.BossPreviewMode then return end

    local bossDB = NephUI.db.profile.unitFrames.boss
    if not bossDB then return end
    local frameDB = bossDB.Frame or {}
    local powerBarDB = bossDB.PowerBar or {}
    local generalDB = (NephUI.db.profile.unitFrames and NephUI.db.profile.unitFrames.General) or {}

    -- Get fake data for this boss
    local fakeData = self:GetFakeBossData(bossIndex)
    if not fakeData then return end

    -- Apply fake health data
    local healthBar = unitFrame.healthBar
    if healthBar then
        local fgColor = frameDB.FGColor or { 0.5, 0.5, 0.5, 1 }
        local healthR, healthG, healthB, healthA = fgColor[1] or 0.5, fgColor[2] or 0.5, fgColor[3] or 0.5, fgColor[4] or 1

        if frameDB.ClassColor then
            local classColor = RAID_CLASS_COLORS[fakeData.class]
            if classColor then
                healthR, healthG, healthB = classColor.r, classColor.g, classColor.b
            end
        elseif frameDB.ReactionColor then
            local reactionColors = generalDB.CustomColors and generalDB.CustomColors.Reaction
            local reactionColor = reactionColors and reactionColors[fakeData.reaction]
            if reactionColor then
                healthR, healthG, healthB = reactionColor[1], reactionColor[2], reactionColor[3]
            end
        end

        healthBar:SetStatusBarTexture(self.Media.ForegroundTexture)
        healthBar:SetMinMaxValues(0, fakeData.maxHealth)
        healthBar:SetValue(fakeData.health)
        healthBar:SetStatusBarColor(healthR, healthG, healthB, healthA)
        local baseLevel = unitFrame:GetFrameLevel() or 0
        healthBar:SetFrameLevel(baseLevel + 1)
        healthBar:SetAlpha(healthA or 1)
        healthBar:Show()

        local healthBarTexture = healthBar:GetStatusBarTexture()
        if healthBarTexture then
            healthBarTexture:SetAlpha(healthA or 1)
            healthBarTexture:SetDrawLayer("ARTWORK", 1)
        end

        if healthBar.BG then
            local bgColor = frameDB.BGColor or { 0.1, 0.1, 0.1, 0.8 }
            healthBar.BG:SetTexture(self.Media.BackgroundTexture)
            healthBar.BG:SetVertexColor(bgColor[1] or 0.1, bgColor[2] or 0.1, bgColor[3] or 0.1, bgColor[4] or 0.8)
        end
    end

    if unitFrame.healthBarBG then
        local bgColor = frameDB.BGColor or { 0.1, 0.1, 0.1, 0.8 }
        unitFrame.healthBarBG:SetMinMaxValues(0, fakeData.maxHealth)
        unitFrame.healthBarBG:SetValue(fakeData.missingHealth or (fakeData.maxHealth - fakeData.health))
        unitFrame.healthBarBG:SetStatusBarColor(bgColor[1] or 0.1, bgColor[2] or 0.1, bgColor[3] or 0.1, bgColor[4] or 0.8)
        unitFrame.healthBarBG:SetFrameLevel((healthBar and healthBar:GetFrameLevel() or unitFrame:GetFrameLevel() or 0) - 1)
        unitFrame.healthBarBG:Show()
    end

    -- Apply fake power data
    local powerBar = unitFrame.powerBar
    if powerBar then
        if powerBarDB.Enabled ~= false then
            powerBar:Show()

            local powerType = fakeData.powerType
            local powerColors = generalDB.CustomColors and generalDB.CustomColors.Power
            local powerColorTable = (powerBarDB.ColorByType and powerColors and powerColors[powerType]) or powerBarDB.FGColor
            local powerR, powerG, powerB, powerA
            if powerColorTable then
                powerR, powerG, powerB, powerA = powerColorTable[1], powerColorTable[2], powerColorTable[3], powerColorTable[4] or 1
            else
                local fallback = PowerBarColor[powerType] or PowerBarColor[0]
                powerR, powerG, powerB, powerA = fallback.r, fallback.g, fallback.b, 1
            end

            local powerValue = fakeData.power

            powerBar:SetStatusBarTexture(self.Media.ForegroundTexture)
            powerBar:SetStatusBarColor(powerR, powerG, powerB, powerA)
            powerBar:SetMinMaxValues(0, fakeData.maxPower)
            powerBar:SetValue(powerValue)

            if powerBar.bg then
                local bgColor = powerBarDB.BGColor or { 0.1, 0.1, 0.1, 0.7 }
                if powerBarDB.ColorBackgroundByType and powerColors and powerColors[powerType] then
                    bgColor = {
                        (powerColors[powerType][1] or 0) * 0.4,
                        (powerColors[powerType][2] or 0) * 0.4,
                        (powerColors[powerType][3] or 0) * 0.4,
                        powerColors[powerType][4] or 1,
                    }
                end
                powerBar.bg:SetTexture(self.Media.BackgroundTexture)
                powerBar.bg:SetVertexColor(bgColor[1] or 0.1, bgColor[2] or 0.1, bgColor[3] or 0.1, bgColor[4] or 0.7)
            end
        else
            powerBar:Hide()
        end
    end

    if self.UpdateHealthBarForPower then
        self.UpdateHealthBarForPower(unitFrame, unitFrame.unit or ("boss" .. bossIndex), bossDB)
    end

    -- Apply fake absorb data (hide during preview so health texture is visible)
    local absorbBar = unitFrame.__nephuiAbsorbBar
    if absorbBar then
        absorbBar:SetMinMaxValues(0, fakeData.maxHealth)
        absorbBar:SetValue(0)
        absorbBar:Hide()
    end

    -- Set fake portrait
    if unitFrame.Portrait and unitFrame.Portrait.Texture then
        local portraitIcon = PreviewPortraits[fakeData.portraitIndex]
        unitFrame.Portrait.Texture:SetTexture("Interface\\ICONS\\" .. portraitIcon)
        if bossDB.Portrait and bossDB.Portrait.Enabled then
            unitFrame.Portrait:Show()
        else
            unitFrame.Portrait:Hide()
        end
    elseif unitFrame.Portrait then
        unitFrame.Portrait:Hide()
    end

    -- Set fake name
    if unitFrame.NameText then
        unitFrame.NameText:SetText(fakeData.name)
    end

    -- Set fake health text
    local healthTags = bossDB.Tags and bossDB.Tags.Health
    if unitFrame.HealthText and healthTags and healthTags.Enabled then
        local healthPercent = math.floor((fakeData.health / fakeData.maxHealth) * 100)

        -- Match live frame display style (current/percent/both/both_reverse)
        local displayStyle = healthTags.DisplayStyle
        if displayStyle == nil then
            -- Migrate old DisplayPercent flag
            displayStyle = healthTags.DisplayPercent and "both" or "current"
        end
        displayStyle = displayStyle or "current"

        local separator = healthTags.Separator or " - "
        local healthText
        if displayStyle == "both" then
            healthText = AbbreviateLargeNumbers(fakeData.health) .. separator .. string.format("%.0f%%", healthPercent)
        elseif displayStyle == "both_reverse" then
            healthText = string.format("%.0f%%", healthPercent) .. separator .. AbbreviateLargeNumbers(fakeData.health)
        elseif displayStyle == "percent" then
            healthText = string.format("%.0f%%", healthPercent)
        else -- "current" or default
            healthText = AbbreviateLargeNumbers(fakeData.health)
        end

        unitFrame.HealthText:SetText(healthText)
        unitFrame.HealthText:Show()
    elseif unitFrame.HealthText then
        unitFrame.HealthText:Hide()
    end

    -- Set fake power text
    if unitFrame.PowerText and bossDB.Tags and bossDB.Tags.Power and bossDB.Tags.Power.Enabled then
        local powerValue = math.floor((fakeData.power / fakeData.maxPower) * 100)
        if bossDB.Tags.Power.DisplayStyle == "current" then
            unitFrame.PowerText:SetText(powerValue)
        elseif bossDB.Tags.Power.DisplayStyle == "both" then
            unitFrame.PowerText:SetText(powerValue .. " / " .. fakeData.maxPower)
        else -- percent
            unitFrame.PowerText:SetText(powerValue .. "%")
        end
        unitFrame.PowerText:Show()
    elseif unitFrame.PowerText then
        unitFrame.PowerText:Hide()
    end

    -- Handle target indicator (show on random bosses)
    if unitFrame.TargetIndicator and bossDB.Indicators and bossDB.Indicators.TargetIndicator and bossDB.Indicators.TargetIndicator.Enabled then
        if bossIndex == 2 or bossIndex == 4 then -- Show target indicator on bosses 2 and 4
            unitFrame.TargetIndicator:Show()
        else
            unitFrame.TargetIndicator:Hide()
        end
    elseif unitFrame.TargetIndicator then
        unitFrame.TargetIndicator:Hide()
    end
    
    -- Handle raid target icon (show fake markers in preview mode)
    if unitFrame.raidTargetIcon and bossDB.RaidTargetIcon then
        local RaidTargetDB = bossDB.RaidTargetIcon
        if RaidTargetDB.Enabled then
            if fakeData.raidTargetIndex then
                -- Show fake raid marker in preview mode
                unitFrame.raidTargetIcon.texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
                SetRaidTargetIconTexture(unitFrame.raidTargetIcon.texture, fakeData.raidTargetIndex)
                
                -- Apply positioning
                local scale = RaidTargetDB.Scale or 1.0
                local anchorFrom = RaidTargetDB.AnchorFrom or "TOP"
                local anchorTo = RaidTargetDB.AnchorTo or "TOP"
                local x = RaidTargetDB.OffsetX or 0
                local y = RaidTargetDB.OffsetY or 2
                
                local size = 16 * scale
                unitFrame.raidTargetIcon:SetSize(size, size)
                unitFrame.raidTargetIcon:ClearAllPoints()
                unitFrame.raidTargetIcon:SetPoint(anchorFrom, unitFrame, anchorTo, x, y)
                
                -- Apply frame level
                local frameLevel = RaidTargetDB.FrameLevel or 0
                if frameLevel > 0 then
                    unitFrame.raidTargetIcon:SetFrameLevel(unitFrame:GetFrameLevel() + frameLevel)
                end
                
                unitFrame.raidTargetIcon:Show()
            else
                unitFrame.raidTargetIcon:Hide()
            end
        else
            unitFrame.raidTargetIcon:Hide()
        end
    elseif unitFrame.raidTargetIcon then
        unitFrame.raidTargetIcon:Hide()
    end
end

function UF:ShowBossFramesPreview()
    if not NephUI.db.profile.unitFrames or not NephUI.db.profile.unitFrames.enabled then return end

    local bossDB = NephUI.db.profile.unitFrames.boss
    if not bossDB or not bossDB.Enabled then return end

    -- Mark as in preview mode
    self.BossPreviewMode = true

    for i = 1, 8 do
        local unitFrame = _G["NephUI_Boss" .. i]
        if unitFrame then
            -- Unregister unit events to prevent real unit data from overriding
            if not InCombatLockdown() then
                UnregisterUnitWatch(unitFrame)
            end

            -- Set fake unit data
            unitFrame.unit = "boss" .. i
            unitFrame.dbUnit = "boss"

            -- Update the frame first to set up proper layout
            self:UpdateUnitFrame("boss" .. i)

            -- Show the frame
            unitFrame:Show()

            -- Set up frame backdrop for preview
            if bossDB.Frame and bossDB.Frame.BGColor then
                unitFrame:SetBackdropColor(unpack(bossDB.Frame.BGColor))
            end

            -- Apply preview-specific data
            self:ApplyBossPreviewData(unitFrame, i)
        end
    end

    -- Layout boss frames
    self:LayoutBossFrames()

    -- Update boss anchor position
    self:UpdateBossAnchor()
end

-- Create draggable anchor for boss frame group
function UF:CreateBossAnchor()
    -- Don't create if already exists
    if self.bossAnchor then return self.bossAnchor end

    local anchor = CreateFrame("Frame", "NephUI_BossAnchor", UIParent)
    anchor:SetFrameStrata("TOOLTIP")
    anchor:SetSize(200, 40) -- Default size, will be updated when shown

    -- Create text label
    local label = anchor:CreateFontString(nil, "OVERLAY")
    local fontPath = NephUI:GetGlobalFont()
    if fontPath then
        label:SetFont(fontPath, 12, "OUTLINE")
    else
        label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    label:SetTextColor(0.2, 0.5, 1, 1) -- Blue color matching border
    label:SetText("Boss Frames")
    label:SetPoint("TOP", anchor, "TOP", 0, -2)
    label:SetJustifyH("CENTER")
    anchor.label = label

    -- Make it draggable
    anchor:SetMovable(true)
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetClampedToScreen(true)

    -- Function to update boss frame position based on anchor position
    local function UpdateBossFramesFromAnchor(anchor)
        if InCombatLockdown() then return end

        local db = NephUI.db.profile.unitFrames
        if not db or not db.boss or not db.boss.Frame then return end

        local bossDB = db.boss
        local anchorX, anchorY = UIParent:GetCenter()
        local selfX, selfY = anchor:GetCenter()

        if anchorX and anchorY and selfX and selfY then
            -- Calculate offset and round for pixel-perfect alignment
            local offsetX = selfX - anchorX
            local offsetY = selfY - anchorY
            offsetX = math.floor(offsetX + 0.5)
            offsetY = math.floor(offsetY + 0.5)

            -- Update database
            bossDB.OffsetX = offsetX
            bossDB.OffsetY = offsetY

            -- Layout boss frames
            UF:LayoutBossFrames()
        end
    end

    -- Drag handlers
    anchor:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self:StartMoving()
        self.isMoving = true

        -- Set up OnUpdate to move boss frames in real-time while dragging
        self:SetScript("OnUpdate", function(self, elapsed)
            if not self.isMoving then
                self:SetScript("OnUpdate", nil)
                return
            end
            UpdateBossFramesFromAnchor(self)
        end)
    end)

    anchor:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        self.isMoving = false

        -- Remove OnUpdate script
        self:SetScript("OnUpdate", nil)

        -- Final update to ensure database is saved
        UpdateBossFramesFromAnchor(self)
    end)

    -- Hide by default
    anchor:Hide()

    self.bossAnchor = anchor
    return anchor
end

-- Update boss anchor visibility and position
function UF:UpdateBossAnchor()
    if not self.bossAnchor then return end

    local db = NephUI.db.profile.unitFrames
    if not db or not db.General then return end

    local bossDB = db.boss
    if not bossDB or not bossDB.Enabled then
        self.bossAnchor:Hide()
        return
    end

    local toggleEnabled = db.General.ShowEditModeAnchors ~= false
    local inEditMode = EditModeManagerFrame and EditModeManagerFrame.editModeActive

    -- Show anchor if Edit Mode is active OR if the toggle is enabled
    local showAnchor = inEditMode or toggleEnabled

    if showAnchor then
        -- Position anchor on boss1 frame (the anchor point of the boss group)
        local boss1Frame = _G["NephUI_Boss1"]
        if boss1Frame and boss1Frame:IsShown() then
            -- Update anchor size to match boss1 frame plus padding
            local frameWidth = boss1Frame:GetWidth() or 200
            local frameHeight = boss1Frame:GetHeight() or 40
            self.bossAnchor:SetSize(math.max(1, frameWidth + 8), math.max(1, frameHeight + 8))

            -- Position over boss1 frame
            if not self.bossAnchor.isMoving then
                self.bossAnchor:ClearAllPoints()
                self.bossAnchor:SetPoint("CENTER", boss1Frame, "CENTER", 0, 0)
            end

            self.bossAnchor:Show()
            if self.bossAnchor.label then
                self.bossAnchor.label:Show()
            end
        else
            self.bossAnchor:Hide()
        end
    else
        self.bossAnchor:Hide()
        if self.bossAnchor.label then
            self.bossAnchor.label:Hide()
        end
    end
end

function UF:HideBossFramesPreview()
    self.BossPreviewMode = false

    for i = 1, 8 do
        local unitFrame = _G["NephUI_Boss" .. i]
        if unitFrame then
            -- Re-register unit watch so frames hide when no real bosses
            if not InCombatLockdown() then
                RegisterUnitWatch(unitFrame, false)
                unitFrame.__nephuiUnitWatchActive = true
            end
            unitFrame:Hide()
        end

        -- Hide boss cast bar previews
        if NephUI.bossCastBars and NephUI.bossCastBars[i] then
            NephUI.bossCastBars[i]:Hide()
        end
    end

    -- Hide associated boss cast bars
    if NephUI.CastBars and NephUI.CastBars.HideTestBossCastBars then
        NephUI.CastBars:HideTestBossCastBars()
    end
end

function UF:LayoutBossFrames()
    local db = NephUI.db.profile.unitFrames
    if not db or not db.boss or not db.boss.Enabled then return end
    if InCombatLockdown() then return end

    local bossDB = db.boss
    local bossFrames = {}

    -- Collect available boss frames (even if hidden) so we can position them before combat
    for i = 1, 8 do
        local unitFrame = _G["NephUI_Boss" .. i]
        if unitFrame then
            bossFrames[#bossFrames + 1] = unitFrame
        end
    end

    if #bossFrames == 0 then return end

    local anchorFrom = (bossDB.Frame and bossDB.Frame.AnchorFrom) or "CENTER"
    local anchorTo = (bossDB.Frame and bossDB.Frame.AnchorTo) or "CENTER"
    local anchorFrame = self.GetAnchorFrame and self:GetAnchorFrame((bossDB.Frame and bossDB.Frame.AnchorFrame) or bossDB.AnchorFrame)
    anchorFrame = anchorFrame or UIParent

    local firstFrame = bossFrames[1]
    local spacing = bossDB.Spacing or 28
    local growthDirection = bossDB.GrowthDirection or "UP"
    local offsetX = bossDB.OffsetX or (bossDB.Frame and bossDB.Frame.OffsetX) or 0
    local offsetY = bossDB.OffsetY or (bossDB.Frame and bossDB.Frame.OffsetY) or 0

    firstFrame:ClearAllPoints()
    firstFrame:SetPoint(anchorFrom, anchorFrame, anchorTo, offsetX, offsetY)

    for i = 2, #bossFrames do
        local frame = bossFrames[i]
        local prevFrame = bossFrames[i-1]

        frame:ClearAllPoints()
        if growthDirection == "DOWN" then
            frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
        else
            frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
        end
    end
end

function UF:Initialize()
    local db = NephUI.db.profile.unitFrames
    if not db or not db.enabled then return end

    -- Creating secure unit frames or registering state drivers is blocked in combat.
    -- When /reload happens mid-combat we queue initialization until combat ends.
    if InCombatLockdown() then
        if not pendingInitAfterCombat then
            pendingInitAfterCombat = true
            local frame = EnsureDelayedInitListener()
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        return
    end

    -- Resolve media
    self:ResolveMedia()

    -- Hide default unit frames
    if self.HideDefaultUnitFrames then
        self:HideDefaultUnitFrames()
    end

    -- Hook cooldown viewer and anchor frames
    if self.HookCooldownViewer then
        self:HookCooldownViewer()
    end
    if self.HookAnchorFrames then
        self:HookAnchorFrames()
    end

    -- Hook edit mode
    if self.HookEditMode then
        self:HookEditMode()
    end

    -- Create unit frames
    local units = {"player", "target", "targettarget", "pet", "focus"}
    for _, unit in ipairs(units) do
        if self.CreateUnitFrame then
            self:CreateUnitFrame(unit)
        end
    end

    -- Create boss frames (up to 8)
    for i = 1, 8 do
        local unit = "boss" .. i
        if self.CreateUnitFrame then
            self:CreateUnitFrame(unit)
        end
    end

    -- Create boss anchor frame
    self:CreateBossAnchor()

    -- Ensure boss frames have an initial layout before combat
    self:LayoutBossFrames()
    self:UpdateBossAnchor()

    -- Hook target and focus power bars
    if self.HookTargetAndFocusPowerBars then
        C_Timer.After(0.1, function()
            self:HookTargetAndFocusPowerBars()
        end)
    end
end

function UF:RefreshFrames()
    -- Refresh all unit frames
    for _, unit in ipairs({"player", "target", "focus"}) do
        if NephUI.db.profile.unitFrames[unit] and NephUI.db.profile.unitFrames[unit].Enabled then
            self:UpdateUnitFrame(unit)
        end
    end

    -- Refresh boss frames
    if NephUI.db.profile.unitFrames.boss and NephUI.db.profile.unitFrames.boss.Enabled then
        for i = 1, 8 do
            self:UpdateUnitFrame("boss" .. i)
        end
        self:LayoutBossFrames()
    end
end
