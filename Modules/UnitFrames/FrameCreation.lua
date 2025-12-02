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
local FetchNameTextColor = UF.FetchNameTextColor
local UpdateTargetAuras = UF.UpdateTargetAuras

-- Get UpdateUnitFrame event handler (from FrameUpdates.lua)
-- This will be set when FrameUpdates.lua loads
local UpdateUnitFrameEventHandler = nil

-- Get UpdateUnitFramePowerBar (from PowerBars.lua)
-- This will be set when PowerBars.lua loads
local UpdateUnitFramePowerBar = nil

-- Create unit frame
function UF:CreateUnitFrame(unit)
    local db = NephUI.db.profile.unitFrames
    if not db then return end

    local dbUnit = unit
    if unit:match("^boss(%d+)$") then dbUnit = "boss" end
    local DB = db[dbUnit]
    local GeneralDB = db.General
    if not DB or not DB.Enabled then return end

    local TagsDB = DB.Tags
    local NameDB = TagsDB and TagsDB.Name
    local HealthDB = TagsDB and TagsDB.Health
    local frameName = ResolveFrameName(unit)
    local unitFrame = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate,BackdropTemplate")

    unitFrame:SetSize(DB.Frame.Width, DB.Frame.Height)
    self:ApplyFrameLayer(unitFrame, GeneralDB)
    if self.ApplyFramePosition then
        self:ApplyFramePosition(unitFrame, unit, DB)
    end

    -- Create edit mode anchor if needed (will be shown/hidden based on Edit Mode state)
    if not unitFrame.editModeAnchor and self.CreateEditModeAnchor then
        self:CreateEditModeAnchor(unit)
    end

    unitFrame:SetBackdrop({
        bgFile = self.Media.BackgroundTexture,
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    unitFrame:SetBackdropColor(unpack(DB.Frame.BGColor))
    unitFrame:SetBackdropBorderColor(0, 0, 0, 1)

    unitFrame.healthBar = CreateFrame("StatusBar", nil, unitFrame)
    unitFrame.healthBar:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
    unitFrame.healthBar:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
    unitFrame.healthBar:SetStatusBarTexture(self.Media.ForegroundTexture)

    if not unitFrame.healthBar.BG then
        unitFrame.healthBar.BG = unitFrame.healthBar:CreateTexture(nil, "BACKGROUND")
        unitFrame.healthBar.BG:SetAllPoints()
        unitFrame.healthBar.BG:SetTexture(self.Media.BackgroundTexture)
    end

    local bgR, bgG, bgB, bgA = unpack(DB.Frame.BGColor)
    unitFrame.healthBar.BG:SetVertexColor(bgR, bgG, bgB, bgA)

    -- Ensure media is resolved (in case it wasn't called yet)
    if not self.Media or not self.Media.Font then
        self:ResolveMedia()
    end

    -- Name text
    unitFrame.NameText = unitFrame.healthBar:CreateFontString(nil, "OVERLAY")
    unitFrame.NameText:SetFont(self.Media.Font, DB.Tags.Name.FontSize, GeneralDB.FontFlag)
    unitFrame.NameText:SetPoint(DB.Tags.Name.AnchorFrom, unitFrame, DB.Tags.Name.AnchorTo, DB.Tags.Name.OffsetX,
        DB.Tags.Name.OffsetY)
    unitFrame.NameText:SetJustifyH(self:SetJustification(DB.Tags.Name.AnchorFrom))
    local statusColorR, statusColorG, statusColorB = FetchNameTextColor(unit, DB, GeneralDB)
    unitFrame.NameText:SetTextColor(statusColorR, statusColorG, statusColorB)
    unitFrame.NameText:SetShadowColor(unpack(GeneralDB.FontShadows.Color))
    unitFrame.NameText:SetShadowOffset(GeneralDB.FontShadows.OffsetX, GeneralDB.FontShadows.OffsetY)
    if NameDB.Enabled then
        unitFrame.NameText:Show()
    else
        unitFrame.NameText:Hide()
    end

    -- Health text
    unitFrame.HealthText = unitFrame.healthBar:CreateFontString(nil, "OVERLAY")
    unitFrame.HealthText:SetFont(self.Media.Font, DB.Tags.Health.FontSize, GeneralDB.FontFlag)
    unitFrame.HealthText:SetPoint(DB.Tags.Health.AnchorFrom, unitFrame, DB.Tags.Health.AnchorTo, DB.Tags.Health.OffsetX,
        DB.Tags.Health.OffsetY)
    unitFrame.HealthText:SetJustifyH(self:SetJustification(DB.Tags.Health.AnchorFrom))
    unitFrame.HealthText:SetTextColor(unpack(DB.Tags.Health.Color))
    unitFrame.HealthText:SetShadowColor(unpack(GeneralDB.FontShadows.Color))
    unitFrame.HealthText:SetShadowOffset(GeneralDB.FontShadows.OffsetX, GeneralDB.FontShadows.OffsetY)
    if HealthDB.Enabled then
        unitFrame.HealthText:Show()
    else
        unitFrame.HealthText:Hide()
    end

    -- Power text (for player, target, focus, boss)
    local PowerTextDB = DB.Tags and DB.Tags.Power
    if PowerTextDB and (unit == "player" or unit == "target" or unit == "focus" or unit:match("^boss%d+$")) then
        unitFrame.PowerText = unitFrame.healthBar:CreateFontString(nil, "OVERLAY")
        unitFrame.PowerText:SetFont(self.Media.Font, PowerTextDB.FontSize or DB.Tags.Health.FontSize, GeneralDB.FontFlag)
        unitFrame.PowerText:SetPoint(PowerTextDB.AnchorFrom or "BOTTOMRIGHT", unitFrame,
            PowerTextDB.AnchorTo or "BOTTOMRIGHT", PowerTextDB.OffsetX or -4, PowerTextDB.OffsetY or 4)
        unitFrame.PowerText:SetJustifyH(self:SetJustification(PowerTextDB.AnchorFrom or "BOTTOMRIGHT"))
        unitFrame.PowerText:SetTextColor(unpack(PowerTextDB.Color or DB.Tags.Health.Color))
        unitFrame.PowerText:SetShadowColor(unpack(GeneralDB.FontShadows.Color))
        unitFrame.PowerText:SetShadowOffset(GeneralDB.FontShadows.OffsetX, GeneralDB.FontShadows.OffsetY)
        if PowerTextDB.Enabled ~= false then
            unitFrame.PowerText:Show()
        else
            unitFrame.PowerText:Hide()
        end
    end

    -- Power bar (for player, target, focus) - handled by PowerBars.lua
    if unit ~= "targettarget" and unit ~= "pet" then
        local PowerBarDB = GetPowerBarDB(DB)
        if PowerBarDB and self.CreatePowerBar then
            self:CreatePowerBar(unitFrame, unit, DB, PowerBarDB)
        end
    end

    -- Frame attributes
    unitFrame.unit = unit
    unitFrame:RegisterForClicks("AnyUp")
    unitFrame:SetAttribute("unit", unit)
    unitFrame:SetAttribute("*type1", "target")
    unitFrame:SetAttribute("*type2", "togglemenu")

    -- Events
    unitFrame:RegisterEvent("UNIT_HEALTH")
    unitFrame:RegisterEvent("UNIT_MAXHEALTH")
    unitFrame:RegisterEvent("UNIT_NAME_UPDATE")
    unitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    unitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

    -- Register power events for power text updates
    if unit == "player" or unit == "target" or unit == "focus" or unit:match("^boss%d+$") then
        unitFrame:RegisterEvent("UNIT_POWER_UPDATE")
        unitFrame:RegisterEvent("UNIT_MAXPOWER")
    end

    -- Register UNIT_AURA for target frame to update auras
    if unit == "target" then
        unitFrame:RegisterEvent("UNIT_AURA")
    end

    -- Special event for targettarget: listen to when target's target changes
    if unit == "targettarget" then
        unitFrame:RegisterEvent("UNIT_TARGET")
    end

    RegisterUnitWatch(unitFrame, false)
    unitFrame.__nephuiUnitWatchActive = true

    -- Tooltip support using Blizzard's default anchor
    --[[CAUSING ERRORS
    local function SetTooltipDefault(owner)
        -- Use Blizzard's default anchor, which respects user settings
        if GameTooltip_SetDefaultAnchor then
            GameTooltip_SetDefaultAnchor(GameTooltip, owner or UIParent)
        else
            -- Fallback: behave like a typical default bottom-right tooltip
            GameTooltip:SetOwner(owner or UIParent, "ANCHOR_NONE")
            GameTooltip:ClearAllPoints()
            GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -13, 130)
        end
    end

    unitFrame:SetScript("OnEnter", function(self)
        local unit = self.unit
        if unit and UnitExists(unit) then
            SetTooltipDefault(self)
            GameTooltip:SetUnit(unit)
        end
    end)
    unitFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    --]]
    -- Hide Blizzard's SecondaryResourceFrame to get rid of tooltip
    if unit == "player" then
        local secondaryResourceFrames = {
            MageArcaneChargesFrame or "nil",  -- Arcane Charges
            MonkHarmonyBarFrame or "nil",     -- Chi
            DruidComboPointBarFrame or "nil", -- Combo Points (Feral)
            RogueComboPointBarFrame or "nil", -- Combo Points (Rogue)
            EssencePlayerFrame or "nil",      -- Essences
            PaladinPowerBarFrame or "nil",    -- Holy Power
            RuneFrame or "nil",               -- Runes
            WarlockPowerFrame or "nil",       -- Soul Shards
        }

        for _, frame in ipairs(secondaryResourceFrames) do
            if frame ~= "nil" then
                frame:Hide()
            end
        end
    end
    if unit == "pet" then unitFrame:RegisterEvent("UNIT_PET") end
    if unit == "focus" then unitFrame:RegisterEvent("PLAYER_FOCUS_CHANGED") end

    -- Set event handler (will be set by FrameUpdates.lua)
    if UF.UpdateUnitFrameEventHandler then
        unitFrame:SetScript("OnEvent", UF.UpdateUnitFrameEventHandler)
    end

    -- Initial update
    if UF.UpdateUnitFrameEventHandler then
        UF.UpdateUnitFrameEventHandler(unitFrame)
    end

    -- Update target auras if this is the target frame
    if unit == "target" and UpdateTargetAuras then
        UpdateTargetAuras(unitFrame)
    end
end
