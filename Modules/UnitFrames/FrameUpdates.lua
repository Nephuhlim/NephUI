local ADDON_NAME, ns = ...
local NephUI = ns.Addon

-- Get UnitFrames module
local UF = NephUI.UnitFrames
if not UF then
    error("NephUI: UnitFrames module not initialized! Load UnitFrames.lua first.")
end

-- Get helper functions
local ResolveFrameName = UF.ResolveFrameName
local GetPowerBarDB = UF.GetPowerBarDB
local FetchUnitColor = UF.FetchUnitColor
local FetchNameTextColor = UF.FetchNameTextColor
local UpdateUnitAuras = UF.UpdateUnitAuras
local UpdateUnitFramePowerBar = UF.UpdateUnitFramePowerBar

-- Some Blizzard APIs can return "secret" values that error on comparison.
-- Use a guarded helper before doing string comparisons.
local function IsSafeNonEmptyString(value)
    if type(value) ~= "string" then
        return false
    end
    local ok, isNonEmpty = pcall(function()
        return value ~= ""
    end)
    return ok and isNonEmpty
end

-- Trim a UTF-8 string to a max character length (0 or nil keeps full name)
local function TruncateNameToLimit(name, maxLength)
    if not IsSafeNonEmptyString(name) then
        return name
    end

    local limit = tonumber(maxLength)
    if not limit or limit <= 0 then
        return name
    end

    limit = math.floor(limit)
    if limit <= 0 then
        return name
    end

    if utf8 and utf8.len and utf8.sub then
        local length = utf8.len(name)
        if length and length > limit then
            local truncated = utf8.sub(name, 1, limit)
            if truncated then
                return truncated
            end
        end
    end

    if #name > limit then
        return string.sub(name, 1, limit)
    end

    return name
end

-- Client build helpers so we can adapt between retail (TWW) and Midnight beta
local BUILD_NUMBER = tonumber((select(4, GetBuildInfo()))) or 0
local IS_MIDNIGHT_OR_LATER = BUILD_NUMBER >= 120000

-- Safely fetch health percent across API variants (retail vs Midnight)
local function SafeUnitHealthPercent(unit, includeAbsorbs, includePredicted)
    -- Midnight+: use the native helper that understands prediction curves
    if IS_MIDNIGHT_OR_LATER and type(UnitHealthPercent) == "function" then
        local ok, pct

        -- Modern signature expects a curve object; fallback to boolean then bare call
        if CurveConstants and CurveConstants.ScaleTo100 then
            ok, pct = pcall(UnitHealthPercent, unit, includePredicted, CurveConstants.ScaleTo100)
        else
            ok, pct = pcall(UnitHealthPercent, unit, includePredicted, true)
        end

        if (not ok or pct == nil) then
            ok, pct = pcall(UnitHealthPercent, unit, includePredicted)
        end

        if ok and pct ~= nil then
            return pct
        end
    end

    -- Midnight fallback: use UnitHealthMissing if available (includes absorbs)
    if IS_MIDNIGHT_OR_LATER and type(UnitHealthMissing) == "function" then
        local ok, missing = pcall(UnitHealthMissing, unit, includeAbsorbs)
        if ok and missing ~= nil and type(missing) == "number" then
            local max = UnitHealthMax(unit)
            if max and max > 0 then
                local cur = max - missing
                local pct = (cur / max) * 100
                return math.min(100, math.max(0, pct))
            end
        end
    end

    -- Retail fallback: compute from current/max (optionally including absorbs)
    if UnitHealth and UnitHealthMax then
        local cur = UnitHealth(unit)
        local max = UnitHealthMax(unit)
        if includeAbsorbs and UnitGetTotalAbsorbs then
            cur = (cur or 0) + (UnitGetTotalAbsorbs(unit) or 0)
        end
        if cur and max and max > 0 then
            local pct = (cur / max) * 100
            return math.min(100, math.max(0, pct))
        end
    end

    return nil
end

-- Update leader/assistant indicator
local function UpdateLeaderIndicator(unitFrame, unit, DB)
    if not unitFrame or not DB or not DB.LeaderIndicator then return end
    
    local LeaderDB = DB.LeaderIndicator
    if not unitFrame.leaderIndicator then return end
    
    if LeaderDB.Enabled then
        -- Check if unit is group leader or assistant
        local isLeader = UnitIsGroupLeader(unit)
        local isAssistant = UnitIsGroupAssistant(unit)
        
        if isLeader or isAssistant then
            unitFrame.leaderIndicator:Show()
        else
            unitFrame.leaderIndicator:Hide()
        end
    else
        unitFrame.leaderIndicator:Hide()
    end
end

-- Update status indicators (combat and resting)
local function UpdateStatusIndicators(unitFrame, DB)
    if not unitFrame or not DB or not DB.StatusIndicators then return end
    
    local StatusIndicatorsDB = DB.StatusIndicators
    
    -- Update combat indicator
    if unitFrame.combatIndicator and StatusIndicatorsDB.Combat then
        local CombatDB = StatusIndicatorsDB.Combat
        if CombatDB.Enabled then
            local inCombat = UnitAffectingCombat("player")
            if inCombat then
                unitFrame.combatIndicator:Show()
            else
                unitFrame.combatIndicator:Hide()
            end
        else
            unitFrame.combatIndicator:Hide()
        end
    end
    
    -- Update resting indicator
    if unitFrame.restingIndicator and StatusIndicatorsDB.Resting then
        local RestingDB = StatusIndicatorsDB.Resting
        if RestingDB.Enabled then
            local isResting = IsResting()
            local inCombat = UnitAffectingCombat("player")
            -- Show resting indicator only when resting and not in combat
            if isResting and not inCombat then
                unitFrame.restingIndicator:Show()
            else
                unitFrame.restingIndicator:Hide()
            end
        else
            unitFrame.restingIndicator:Hide()
        end
    end
end

-- Update unit frame event handler
local function UpdateUnitFrame(self, event, eventUnit, ...)
    local unit = self.unit
    if not unit or not UnitExists(unit) then return end
    
    -- Handle UNIT_AURA events for player, focus, target, and boss frames
    if event == "UNIT_AURA" then
        if (unit == "player" or unit == "focus" or unit == "target" or unit:match("^boss%d+$")) and eventUnit == unit then
            if UpdateUnitAuras then
                UpdateUnitAuras(self)
            end
        end
        return
    end
    
    if unit == "targettarget" and event == "UNIT_TARGET" then
        if eventUnit == "target" then
        else
            return
        end
    end
        
    -- If event has a unit parameter, only update if it matches our unit
    -- Inline targettarget on the target frame needs to react to targettarget events
    local isInlineTargetTargetEvent = (unit == "target" and eventUnit == "targettarget")
    if eventUnit and eventUnit ~= unit and not isInlineTargetTargetEvent then
        if event and event:match("^UNIT_") and eventUnit ~= unit then
            if not (unit == "targettarget" and (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH")) then
                return
            end
        end
    end
        
    local db = NephUI.db.profile.unitFrames
    if not db then return end
    
    local dbUnit = unit
    if unit:match("^boss(%d+)$") then dbUnit = "boss" end
    local DB = db[dbUnit]
    local GeneralDB = db.General
    if not DB then return end
    
    local unitHealth = UnitHealth(unit)
    local unitMaxHealth = UnitHealthMax(unit)
    local unitColorR, unitColorG, unitColorB, unitColorA = FetchUnitColor(unit, DB, GeneralDB)

    -- Use UnitHealthMissing API if available (Midnight+)
    local unitHealthMissing = 0
    if IS_MIDNIGHT_OR_LATER and type(UnitHealthMissing) == "function" then
        unitHealthMissing = UnitHealthMissing(unit, true) or 0 -- Include absorbs
    else
        -- Fallback: calculate missing health manually (including absorbs)
        local absorbs = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0
        unitHealthMissing = unitMaxHealth - unitHealth - absorbs
        unitHealthMissing = math.max(0, unitHealthMissing) -- Ensure not negative
    end

    if self.healthBar then
        self.healthBar:SetMinMaxValues(0, unitMaxHealth)
        self.healthBar:SetValue(unitHealth)
        self.healthBar:SetStatusBarColor(unitColorR, unitColorG, unitColorB, unitColorA)
    end

    -- Update background health bar to show missing health
    if self.healthBarBG then
        self.healthBarBG:SetMinMaxValues(0, unitMaxHealth)
        self.healthBarBG:SetValue(unitHealthMissing)

        -- Set background color (missing health color)
        -- Use same alpha as foreground for consistent transparency
        local fgAlpha = (DB.Frame.FGColor and DB.Frame.FGColor[4]) or 1.0
        local bgR, bgG, bgB, bgA
        if DB.Frame.ClassColorBackground then
            -- Use darkened class/reaction color for background - fetch class color independently
            local darkenFactor = DB.Frame.ClassColorBackgroundBrightness or 0.35
            local classR, classG, classB = 0.5, 0.5, 0.5
            
            -- Try to get class color first
            local _, class = UnitClass(unit)
            if class and RAID_CLASS_COLORS[class] then
                classR, classG, classB = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
            else
                -- Fallback to reaction color for non-player units
                local reaction = UnitReaction(unit, "player")
                if reaction and FACTION_BAR_COLORS[reaction] then
                    classR, classG, classB = FACTION_BAR_COLORS[reaction].r, FACTION_BAR_COLORS[reaction].g, FACTION_BAR_COLORS[reaction].b
                end
            end
            
            bgR, bgG, bgB = classR * darkenFactor, classG * darkenFactor, classB * darkenFactor
            bgA = fgAlpha
        else
            local bgColor = DB.Frame.BGColor or {0.5, 0.5, 0.5, 1.0}
            bgR, bgG, bgB = bgColor[1], bgColor[2], bgColor[3]
            bgA = fgAlpha
        end
        self.healthBarBG:SetStatusBarColor(bgR, bgG, bgB, bgA)
    end
    
    if self.HealthText then
        local isUnitDead = UnitIsDeadOrGhost(unit)
        if isUnitDead then
            self.HealthText:SetText("Dead")
        else
            local unitHealthPercent = SafeUnitHealthPercent(unit, false, true) or 0
            local displayStyle = DB.Tags and DB.Tags.Health and DB.Tags.Health.DisplayStyle
            -- Migrate old DisplayPercent setting
            if displayStyle == nil then
                local displayPercentHealth = DB.Tags and DB.Tags.Health and DB.Tags.Health.DisplayPercent
                displayStyle = displayPercentHealth and "both" or "current"
            end
            displayStyle = displayStyle or "current"
            
            local separator = (DB.Tags and DB.Tags.Health and DB.Tags.Health.Separator) or " - "
            local healthText
            if displayStyle == "both" then
                healthText = AbbreviateLargeNumbers(unitHealth) .. separator .. string.format("%.0f%%", unitHealthPercent)
            elseif displayStyle == "both_reverse" then
                healthText = string.format("%.0f%%", unitHealthPercent) .. separator .. AbbreviateLargeNumbers(unitHealth)
            elseif displayStyle == "percent" then
                healthText = string.format("%.0f%%", unitHealthPercent)
            else -- "current" or default
                healthText = AbbreviateLargeNumbers(unitHealth)
            end
            self.HealthText:SetText(healthText)
        end
    end
    
    if self.NameText then
        local NameDB = (DB.Tags and DB.Tags.Name) or {}
        local statusColorR, statusColorG, statusColorB = FetchNameTextColor(unit, DB, GeneralDB)
        self.NameText:SetTextColor(statusColorR, statusColorG, statusColorB)
        -- Safely get unit name (may be secret value in combat)
        local unitName = UnitName(unit)
        if type(unitName) == "string" then
            local finalName = TruncateNameToLimit(unitName, NameDB.MaxLength)
            if unit == "target" and NameDB.InlineTargetTarget then
                -- Force inline targettarget separator to white so it ignores custom/status text colors
                local separator = NameDB.TargetTargetSeparator or " » "
                local coloredSeparator = "|cFFFFFFFF" .. separator .. "|r"
                local hasTargetTarget = UnitExists("targettarget")
                local targetTargetName = hasTargetTarget and UnitName("targettarget")
                -- Allow showing whatever name we get back (even if it's empty/unknown) for testing
                if type(targetTargetName) == "string" then
                    finalName = finalName .. coloredSeparator .. TruncateNameToLimit(targetTargetName, NameDB.MaxLength)
                end
            end
            self.NameText:SetText(finalName)
        else
            -- If secret value, keep existing text or use empty string
            self.NameText:SetText("")
        end
    end
    
    -- Power text (for player, target, focus, boss)
    if self.PowerText then
        local PowerTextDB = DB.Tags and DB.Tags.Power
        if PowerTextDB and PowerTextDB.Enabled ~= false then
            local displayStyle = PowerTextDB.DisplayStyle or "both"
            
            -- For target and focus: if power bar is hooked, get values from Blizzard's bar
            if (unit == "target" or unit == "focus") and self.powerBar and self.powerBar.__hookedToBlizzard then
                local blizzardFrame = (unit == "target") and _G["TargetFrame"] or _G["FocusFrame"]
                local blizzardPowerBar = blizzardFrame and (blizzardFrame.manabar or blizzardFrame.powerBar)
                if blizzardPowerBar and blizzardPowerBar:IsShown() then
                    local value = blizzardPowerBar:GetValue()
                    local min, max = blizzardPowerBar:GetMinMaxValues()
                    if min and max and type(value) == "number" and type(max) == "number" then
                        if displayStyle == "current" then
                            self.PowerText:SetFormattedText("%d", value)
                        else
                            self.PowerText:SetFormattedText("%d / %d", value, max)
                        end
                        self.PowerText:Show()
                    else
                        self.PowerText:Hide()
                    end
                else
                    self.PowerText:Hide()
                end
            -- For other units: use normal UnitPower approach
            elseif unit == "player" or unit == "target" or unit == "focus" or unit:match("^boss%d+$") or UnitIsPlayer(unit) then
                -- Safely get power values (may be secret values in combat)
                local unitPower = UnitPower(unit)
                local unitMaxPower = UnitPowerMax(unit)
                
                if type(unitPower) == "number" and type(unitMaxPower) == "number" then
                    if displayStyle == "current" then
                        self.PowerText:SetFormattedText("%d", unitPower)
                    else
                        self.PowerText:SetFormattedText("%d / %d", unitPower, unitMaxPower)
                    end
                    self.PowerText:Show()
                else
                    -- Secret values - hide or keep last known state
                    self.PowerText:Hide()
                end
            else
                self.PowerText:SetText("")
                self.PowerText:Hide()
            end
        else
            self.PowerText:Hide()
        end
    end
    
    -- Update leader indicator (player frame only)
    if unit == "player" and DB.LeaderIndicator then
        UpdateLeaderIndicator(self, unit, DB)
    end
    
    -- Update status indicators (player frame only)
    if unit == "player" then
        UpdateStatusIndicators(self, DB)
    end
    
    -- Update unit auras if this is a player, focus, target, or boss frame (always update, not just on specific events)
    if (unit == "player" or unit == "focus" or unit == "target" or unit:match("^boss%d+$")) and UpdateUnitAuras then
        UpdateUnitAuras(self)
    end
end

-- Export event handler
UF.UpdateUnitFrameEventHandler = UpdateUnitFrame

-- Update unit frame (UF function)
function UF:UpdateUnitFrame(unit)
    if not unit then return end
    
    local db = NephUI.db.profile.unitFrames
    if not db then return end
    
    local dbUnit = unit
    if unit:match("^boss(%d+)$") then dbUnit = "boss" end
    local DB = db[dbUnit]
    local GeneralDB = db.General
    if not DB then return end

    if not unit then return end
    local frameName = ResolveFrameName(unit)
    local unitFrame = _G[frameName]
    if not unitFrame then return end
    
    local shouldHideUnitFrame = (not DB.Enabled)

    if shouldHideUnitFrame then
        unitFrame:Hide()
        unitFrame:UnregisterAllEvents()
        if unitFrame.__nephuiUnitWatchActive then
            UnregisterUnitWatch(unitFrame)
            unitFrame.__nephuiUnitWatchActive = nil
        end
        unitFrame:SetScript("OnEvent", nil)
        unitFrame:SetScript("OnEnter", nil)
        unitFrame:SetScript("OnLeave", nil)
        return
    else
        if unit:match("^boss%d+$") and NephUI.UnitFrames.BossPreviewMode then
            -- In boss preview mode, unregister unit watch and force show
            UnregisterUnitWatch(unitFrame)
            unitFrame.__nephuiUnitWatchActive = false
            unitFrame:Show()
        else
            -- Normal mode: ensure unit watch is active
            UnregisterUnitWatch(unitFrame)
            RegisterUnitWatch(unitFrame, false)
            unitFrame.__nephuiUnitWatchActive = true
            -- Don't force show - let UnitWatch handle visibility
        end
    end
    
    unitFrame:SetSize(DB.Frame.Width, DB.Frame.Height)
    self:ApplyFrameLayer(unitFrame, GeneralDB)
    if self.ApplyFramePosition then
        self:ApplyFramePosition(unitFrame, unit, DB)
    end
    
    -- Update edit mode anchor if it exists
    if unitFrame.editModeAnchor then
        unitFrame.editModeAnchor:SetSize(DB.Frame.Width, DB.Frame.Height)
        if not unitFrame.editModeAnchor.isMoving then
            unitFrame.editModeAnchor:ClearAllPoints()
            unitFrame.editModeAnchor:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
        end
    end
    
    unitFrame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    unitFrame:SetBackdropColor(0, 0, 0, 0) -- Transparent background
    unitFrame:SetBackdropBorderColor(0, 0, 0, 1)
    
    if self.UpdateMouseoverHighlight then
        self.UpdateMouseoverHighlight(unitFrame)
    end
    
    -- Update foreground health bar (current health)
    local unitHealthBar = unitFrame.healthBar
    unitHealthBar:ClearAllPoints()
    unitHealthBar:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
    unitHealthBar:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
    unitFrame.healthBar:SetStatusBarTexture(self.Media.ForegroundTexture)

    -- Update background health bar (missing health)
    -- Note: For ClassColorBackground, the actual color is applied in the event handler
    -- since we need the unit's class/reaction color, which requires UnitExists check
    if unitFrame.healthBarBG then
        unitFrame.healthBarBG:ClearAllPoints()
        unitFrame.healthBarBG:SetAllPoints(unitFrame.healthBar)
        unitFrame.healthBarBG:SetStatusBarTexture(self.Media.BackgroundTexture)

        -- Use default BGColor here; ClassColorBackground is applied in event handler
        local bgColor = DB.Frame.BGColor or {0.1, 0.1, 0.1, 0.8}
        unitFrame.healthBarBG:SetStatusBarColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.8)
    end
    
    -- Ensure media is resolved with latest global font
    self:ResolveMedia()
    
    -- Update name text
    if unitFrame.NameText then
        local unitNameText = unitFrame.NameText
        local NameDB = DB.Tags.Name
        unitNameText:SetFont(self.Media.Font, NameDB.FontSize, GeneralDB.FontFlag)
        unitNameText:ClearAllPoints()
        unitNameText:SetPoint(NameDB.AnchorFrom, unitFrame, NameDB.AnchorTo, NameDB.OffsetX, NameDB.OffsetY)
        unitNameText:SetJustifyH(self:SetJustification(NameDB.AnchorFrom))
        unitNameText:SetShadowColor(unpack(GeneralDB.FontShadows.Color))
        unitNameText:SetShadowOffset(GeneralDB.FontShadows.OffsetX, GeneralDB.FontShadows.OffsetY)
        
        if NameDB.Enabled then
            unitNameText:Show()
        else
            unitNameText:Hide()
        end
    end
    
    -- Update health text
    if unitFrame.HealthText then
        local unitHealthText = unitFrame.HealthText
        local HDB = DB.Tags.Health
        
        unitHealthText:SetFont(self.Media.Font, HDB.FontSize, GeneralDB.FontFlag)
        unitHealthText:ClearAllPoints()
        unitHealthText:SetPoint(HDB.AnchorFrom, unitFrame, HDB.AnchorTo, HDB.OffsetX, HDB.OffsetY)
        unitHealthText:SetJustifyH(self:SetJustification(HDB.AnchorFrom))
        unitHealthText:SetTextColor(unpack(HDB.Color))
        unitHealthText:SetShadowColor(unpack(GeneralDB.FontShadows.Color))
        unitHealthText:SetShadowOffset(GeneralDB.FontShadows.OffsetX, GeneralDB.FontShadows.OffsetY)
        
        if HDB.Enabled then
            unitHealthText:Show()
        else
            unitHealthText:Hide()
        end
    end
    
    -- Update power text
    local PowerTextDB = DB.Tags and DB.Tags.Power
    if PowerTextDB and (unit == "player" or unit == "target" or unit == "focus" or unit:match("^boss%d+$")) then
        if not unitFrame.PowerText then
            unitFrame.PowerText = unitFrame.healthBar:CreateFontString(nil, "OVERLAY")
        end
        local unitPowerText = unitFrame.PowerText
        unitPowerText:SetFont(self.Media.Font, PowerTextDB.FontSize or DB.Tags.Health.FontSize, GeneralDB.FontFlag)
        unitPowerText:ClearAllPoints()
        unitPowerText:SetPoint(PowerTextDB.AnchorFrom or "BOTTOMRIGHT", unitFrame, PowerTextDB.AnchorTo or "BOTTOMRIGHT", PowerTextDB.OffsetX or -4, PowerTextDB.OffsetY or 4)
        unitPowerText:SetJustifyH(self:SetJustification(PowerTextDB.AnchorFrom or "BOTTOMRIGHT"))
        unitPowerText:SetTextColor(unpack(PowerTextDB.Color or DB.Tags.Health.Color))
        unitPowerText:SetShadowColor(unpack(GeneralDB.FontShadows.Color))
        unitPowerText:SetShadowOffset(GeneralDB.FontShadows.OffsetX, GeneralDB.FontShadows.OffsetY)
        
        if PowerTextDB.Enabled ~= false then
            unitPowerText:Show()
        else
            unitPowerText:Hide()
        end
    elseif unitFrame.PowerText then
        unitFrame.PowerText:Hide()
    end
    
    -- Update leader indicator (player frame only)
    if unit == "player" and DB.LeaderIndicator then
        local LeaderDB = DB.LeaderIndicator
            if not unitFrame.leaderIndicator then
                -- Create frame and texture
                local leaderFrame = CreateFrame("Frame", nil, unitFrame)
                leaderFrame:SetFrameLevel(unitFrame:GetFrameLevel() + 5)
                leaderFrame:SetFrameStrata("HIGH")
                local leaderTexture = leaderFrame:CreateTexture(nil, "OVERLAY")
                leaderTexture:SetAllPoints()
                leaderTexture:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
            unitFrame.leaderIndicator = leaderFrame
            unitFrame.leaderIndicator.texture = leaderTexture
        end
        
        unitFrame.leaderIndicator:ClearAllPoints()
        unitFrame.leaderIndicator:SetSize(LeaderDB.Size or 15, LeaderDB.Size or 15)
        unitFrame.leaderIndicator:SetPoint(LeaderDB.AnchorFrom or "RIGHT", unitFrame, LeaderDB.AnchorTo or "TOPRIGHT", LeaderDB.OffsetX or -3, LeaderDB.OffsetY or 0)
    end
    
    -- Update status indicators (player frame only)
    if unit == "player" and DB.StatusIndicators then
        local StatusIndicatorsDB = DB.StatusIndicators
        
        -- Update combat indicator
        if StatusIndicatorsDB.Combat then
            local CombatDB = StatusIndicatorsDB.Combat
            if not unitFrame.combatIndicator then
                -- Create frame and texture
                local combatFrame = CreateFrame("Frame", nil, unitFrame)
                combatFrame:SetFrameLevel(unitFrame:GetFrameLevel() + 5)
                local combatTexture = combatFrame:CreateTexture(nil, "OVERLAY")
                combatTexture:SetAllPoints()
                unitFrame.combatIndicator = combatFrame
                unitFrame.combatIndicator.texture = combatTexture
            end
            
            unitFrame.combatIndicator:ClearAllPoints()
            unitFrame.combatIndicator:SetSize(CombatDB.Size or 24, CombatDB.Size or 24)
            unitFrame.combatIndicator:SetPoint(CombatDB.AnchorFrom or "CENTER", unitFrame, CombatDB.AnchorTo or "TOPLEFT", CombatDB.OffsetX or 3, CombatDB.OffsetY or -3)
            
            local textureType = CombatDB.Texture or "DEFAULT"
            if textureType == "DEFAULT" then
                unitFrame.combatIndicator.texture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
                unitFrame.combatIndicator.texture:SetTexCoord(0.5, 1, 0, 0.49)
            else
                unitFrame.combatIndicator.texture:SetTexture(textureType)
                unitFrame.combatIndicator.texture:SetTexCoord(0, 1, 0, 1)
            end
        end
        
        -- Update resting indicator
        if StatusIndicatorsDB.Resting then
            local RestingDB = StatusIndicatorsDB.Resting
            if not unitFrame.restingIndicator then
                -- Create frame and texture
                local restingFrame = CreateFrame("Frame", nil, unitFrame)
                restingFrame:SetFrameLevel(unitFrame:GetFrameLevel() + 5)
                local restingTexture = restingFrame:CreateTexture(nil, "OVERLAY")
                restingTexture:SetAllPoints()
                unitFrame.restingIndicator = restingFrame
                unitFrame.restingIndicator.texture = restingTexture
            end
            
            unitFrame.restingIndicator:ClearAllPoints()
            unitFrame.restingIndicator:SetSize(RestingDB.Size or 24, RestingDB.Size or 24)
            unitFrame.restingIndicator:SetPoint(RestingDB.AnchorFrom or "CENTER", unitFrame, RestingDB.AnchorTo or "TOPLEFT", RestingDB.OffsetX or 3, RestingDB.OffsetY or -3)
            
            local textureType = RestingDB.Texture or "DEFAULT"
            if textureType == "DEFAULT" then
                unitFrame.restingIndicator.texture:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
                unitFrame.restingIndicator.texture:SetTexCoord(0, 0.5, 0, 0.421875)
            else
                unitFrame.restingIndicator.texture:SetTexture(textureType)
                unitFrame.restingIndicator.texture:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
    
    -- Update alternate power bar first (for player only) - handled by AlternatePowerBar.lua
    -- Alternate power bar takes precedence over regular power bar for health bar positioning
    if unit == "player" then
        local AltPowerBarDB = DB.AlternatePowerBar
        if AltPowerBarDB and self.UpdateAlternatePowerBar then
            self:UpdateAlternatePowerBar(unitFrame, unit, DB, AltPowerBarDB)
        end
    end
    
    -- Update power bar (handled by PowerBars.lua)
    -- Only update if alternate power bar is not shown (alternate takes precedence)
    local unitPowerBar = unitFrame.powerBar
    local PowerBarDB = GetPowerBarDB(DB)
    local shouldUpdatePowerBar = true
    if unit == "player" then
        local altPowerBar = unitFrame.alternatePowerBar
        if altPowerBar and altPowerBar:IsShown() and DB.AlternatePowerBar and DB.AlternatePowerBar.Enabled then
            shouldUpdatePowerBar = false
        end
    end
    
    if shouldUpdatePowerBar and unitPowerBar and PowerBarDB and self.UpdatePowerBar then
        self:UpdatePowerBar(unitFrame, unit, DB, PowerBarDB)
    end
    
    -- Re-register events
    unitFrame:UnregisterAllEvents()
    if DB.Enabled then
        unitFrame:RegisterEvent("UNIT_HEALTH")
        unitFrame:RegisterEvent("UNIT_MAXHEALTH")
        unitFrame:RegisterEvent("UNIT_NAME_UPDATE")
        unitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        unitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        -- Keep target name updated when its target changes (for inline targettarget)
        if unit == "target" then
            unitFrame:RegisterEvent("UNIT_TARGET")
        end
        -- Register power events for power text updates
        if unit == "player" or unit == "target" or unit == "focus" or unit:match("^boss%d+$") then
            unitFrame:RegisterEvent("UNIT_POWER_UPDATE")
            unitFrame:RegisterEvent("UNIT_MAXPOWER")
        end
        -- Register UNIT_AURA for target and boss frames to update auras
        if unit == "target" or unit:match("^boss%d+$") then
            unitFrame:RegisterEvent("UNIT_AURA")
        end
        -- Special event for targettarget: listen to when target's target changes
        -- targettarget frames need health updates for their dynamic unit
        if unit == "targettarget" then
            unitFrame:RegisterEvent("UNIT_TARGET")
            unitFrame:RegisterEvent("UNIT_HEALTH")
            unitFrame:RegisterEvent("UNIT_MAXHEALTH")
        end
        if unit == "pet" then unitFrame:RegisterEvent("UNIT_PET") end
        if unit == "focus" then unitFrame:RegisterEvent("PLAYER_FOCUS_CHANGED") end
        -- Status indicator events (player frame only)
        if unit == "player" then
            unitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            unitFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
            unitFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        end
        -- Leader indicator events (player frame only)
        if unit == "player" then
            unitFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
            unitFrame:RegisterEvent("PARTY_LEADER_CHANGED")
        end
        unitFrame:SetScript("OnEvent", UpdateUnitFrame)
    else
        unitFrame:SetScript("OnEvent", nil)
        unitFrame:SetScript("OnEnter", nil)
        unitFrame:SetScript("OnLeave", nil)
    end
    
    if unitPowerBar then
        local PowerBarDB = GetPowerBarDB(DB)
        unitPowerBar:UnregisterAllEvents()
        if PowerBarDB and PowerBarDB.Enabled then
            unitPowerBar:RegisterEvent("UNIT_POWER_UPDATE")
            unitPowerBar:RegisterEvent("UNIT_POWER_FREQUENT") -- More frequent updates in combat
            unitPowerBar:RegisterEvent("UNIT_MAXPOWER")
            unitPowerBar:RegisterEvent("UNIT_DISPLAYPOWER") -- For power type changes
            -- Register target change event for target/focus frames
            if unit == "target" then
                unitPowerBar:RegisterEvent("PLAYER_TARGET_CHANGED")
            elseif unit == "focus" then
                unitPowerBar:RegisterEvent("PLAYER_FOCUS_CHANGED")
            end
            if UpdateUnitFramePowerBar then
                unitPowerBar:SetScript("OnEvent", UpdateUnitFramePowerBar)
                -- Force update immediately
                UpdateUnitFramePowerBar(unitPowerBar)
            end
        else
            unitPowerBar:SetScript("OnEvent", nil)
        end
    end
    
    -- Update leader indicator (player frame only)
    if unit == "player" and DB.LeaderIndicator then
        UpdateLeaderIndicator(unitFrame, unit, DB)
    end
    
    -- Update status indicators (player frame only)
    if unit == "player" and DB.StatusIndicators then
        UpdateStatusIndicators(unitFrame, DB)
    end
    
    -- Initial update
    UpdateUnitFrame(unitFrame)
    if unitPowerBar and UpdateUnitFramePowerBar then
        UpdateUnitFramePowerBar(unitPowerBar)
    end
    
    -- Update unit auras if this is a player, focus, target, or boss frame
    if (unit == "player" or unit == "focus" or unit == "target" or unit:match("^boss%d+$")) and UpdateUnitAuras then
        UpdateUnitAuras(unitFrame)
    end

    -- Re-apply preview data if in boss preview mode
    if unit:match("^boss%d+$") and NephUI.UnitFrames.BossPreviewMode then
        local bossIndex = tonumber(unit:match("^boss(%d+)$"))
        if bossIndex then
            NephUI.UnitFrames:ApplyBossPreviewData(unitFrame, bossIndex)
        end
    end
end

