local ADDON_NAME, ns = ...
local NephUI = ns.Addon

-- Get CastBars module
local CastBars = NephUI.CastBars
if not CastBars then
    error("NephUI: CastBars module not initialized! Load CastBars.lua first.")
end

local CreateBorder = CastBars.CreateBorder
local ResolveCastIconTexture = CastBars.ResolveCastIconTexture
local function PixelSnap(value)
    return math.max(0, math.floor((value or 0) + 0.5))
end

-- BOSS CAST BAR SYSTEM
-- Boss frames have individual cast bars that attach to each boss frame

-- Table to store boss cast bars
NephUI.bossCastBars = NephUI.bossCastBars or {}

local function SetBossCastBarColor(bossIndex, state)
    local cfg = NephUI.db and NephUI.db.profile and NephUI.db.profile.bossCastBar
    if not cfg then return end

    local bar = NephUI.bossCastBars[bossIndex]
    if not bar or not bar.status then return end

    local color
    if state == "interrupted" then
        color = cfg.interruptedColor or cfg.color
    elseif state == "nonInterruptible" then
        color = cfg.nonInterruptibleColor or cfg.color
    else
        color = cfg.interruptibleColor or cfg.color
    end

    color = color or { 0.5, 0.5, 1.0, 1.0 }
    bar.status:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
end

function CastBars:GetBossCastBar(bossIndex)
    if NephUI.bossCastBars[bossIndex] then return NephUI.bossCastBars[bossIndex] end

    local cfg = NephUI.db.profile.bossCastBar
    local frameName = "NephUI_Boss" .. bossIndex
    local anchor = _G[frameName] or UIParent
    local anchorPoint = cfg.anchorPoint or "BOTTOM"

    local bar = CreateFrame("Frame", ADDON_NAME .. "Boss" .. bossIndex .. "CastBar", UIParent)
    bar:SetFrameStrata("MEDIUM")

    local height = cfg.height or 24
    bar:SetHeight(NephUI:Scale(height))
    bar:SetPoint(anchorPoint, anchor, anchorPoint, NephUI:Scale(cfg.offsetX or 0), NephUI:Scale(cfg.offsetY or 0))

    local width = cfg.width or 0
    if width <= 0 then
        width = PixelSnap((anchor.__cdmIconWidth or anchor:GetWidth() or 200) - 2)
    else
        width = NephUI:Scale(width)
    end
    bar:SetWidth(width)

    CreateBorder(bar)

    -- Status bar
    bar.status = CreateFrame("StatusBar", nil, bar)
    -- Use GetTexture helper: if cfg.texture is set, use it; otherwise use global texture
    local tex = NephUI:GetTexture(NephUI.db.profile.bossCastBar.texture)
    bar.status:SetStatusBarTexture(tex)

    local sbTex = bar.status:GetStatusBarTexture()
    if sbTex then
        sbTex:SetDrawLayer("BACKGROUND")
    end

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(bar.status)
    local bgColor = cfg.bgColor or { 0.1, 0.1, 0.1, 1 }
    bar.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)

    bar.icon = bar:CreateTexture(nil, "ARTWORK")
    bar.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

    -- Text (match target/focus cast bar styling)
    bar.spellName = bar.status:CreateFontString(nil, "OVERLAY")
    bar.spellName:SetJustifyH("LEFT")

    bar.timeText = bar.status:CreateFontString(nil, "OVERLAY")
    bar.timeText:SetJustifyH("RIGHT")

    bar:Hide()

    NephUI.bossCastBars[bossIndex] = bar
    return bar
end

function CastBars:UpdateBossCastBarLayout(bossIndex)
    local cfg = NephUI.db.profile.bossCastBar
    if not cfg then return end

    local bar = NephUI.bossCastBars[bossIndex]
    if not bar then return end

    if not cfg.enabled then
        bar:Hide()
        return
    end

    local frameName = "NephUI_Boss" .. bossIndex
    local anchor = _G[frameName] or UIParent
    local anchorPoint = cfg.anchorPoint or "BOTTOM"

    bar:ClearAllPoints()
    bar:SetPoint(anchorPoint, anchor, anchorPoint, NephUI:Scale(cfg.offsetX or 0), NephUI:Scale(cfg.offsetY or 0))

    local height = cfg.height or 24
    bar:SetHeight(NephUI:Scale(height))

    local width = cfg.width or 0
    if width <= 0 then
        width = PixelSnap((anchor.__cdmIconWidth or anchor:GetWidth() or 200) - 2)
    else
        width = NephUI:Scale(width)
    end
    bar:SetWidth(width)

    -- Update status bar texture
    local tex = NephUI:GetTexture(NephUI.db.profile.bossCastBar.texture)
    bar.status:SetStatusBarTexture(tex)

    -- Update background color
    local bgColor = cfg.bgColor or { 0.1, 0.1, 0.1, 1 }
    bar.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)

    -- Update text font and styling (match target/focus cast bars)
    local font = NephUI:GetGlobalFont()
    bar.spellName:SetFont(font, cfg.textSize or 16, "OUTLINE")
    bar.spellName:SetShadowOffset(0, 0)

    bar.timeText:SetFont(font, cfg.textSize or 16, "OUTLINE")
    bar.timeText:SetShadowOffset(0, 0)

    -- Position elements (match target/focus cast bars - icon on LEFT)
    bar.icon:ClearAllPoints()
    bar.status:ClearAllPoints()
    bar.bg:ClearAllPoints()

    if cfg.showIcon then
        bar.icon:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        bar.icon:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        bar.icon:SetWidth(bar:GetHeight())
        bar.icon:Show()

        bar.status:SetPoint("TOPLEFT", bar.icon, "TOPRIGHT", 0, 0)
    else
        bar.icon:SetWidth(0)
        bar.icon:Hide()

        bar.status:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    end

    bar.status:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    bar.bg:SetAllPoints(bar.status)

    local nameOffsetX = cfg.nameOffsetX or 0
    local nameOffsetY = cfg.nameOffsetY or 0
    local timeOffsetX = cfg.timeOffsetX or 0
    local timeOffsetY = cfg.timeOffsetY or 0

    -- Position text (match target/focus cast bars)
    bar.spellName:ClearAllPoints()
    bar.spellName:SetPoint("LEFT", bar.status, "LEFT", NephUI:Scale(4 + nameOffsetX), NephUI:Scale(nameOffsetY))

    bar.timeText:ClearAllPoints()
    bar.timeText:SetPoint("RIGHT", bar.status, "RIGHT", NephUI:Scale(-4 + timeOffsetX), NephUI:Scale(timeOffsetY))

    -- Show/hide time text based on setting
    if cfg.showTimeText ~= false then
        bar.timeText:Show()
    else
        bar.timeText:Hide()
    end

    if cfg.showTimeText then
        bar.timeText:Show()
    else
        bar.timeText:Hide()
    end
end

function CastBars:UpdateAllBossCastBarLayouts()
    for i = 1, 8 do
        self:UpdateBossCastBarLayout(i)
    end
end

function CastBars:HookBossCastBars()
    -- Hook each boss frame's spellbar
    for i = 1, 8 do
        local bossFrame = _G["Boss" .. i .. "TargetFrame"] or _G["Boss" .. i .. "Frame"]
        if bossFrame and bossFrame.spellbar and not bossFrame.spellbar.__nephuiHooked then
            bossFrame.spellbar.__nephuiHooked = true

            -- Per-boss throttling variables
            local lastUpdate = 0
            local updateThrottle = 1/60 -- 60fps maximum

            bossFrame.spellbar:HookScript("OnShow", function(self)
                local cfg = NephUI.db.profile.bossCastBar
                if not cfg or not cfg.enabled then
                    if NephUI.bossCastBars[i] then NephUI.bossCastBars[i]:Hide() end
                    return
                end

                local bar = CastBars:GetBossCastBar(i)
                if not bar then return end

                CastBars:UpdateBossCastBarLayout(i)

                -- Get spell info from the default cast bar
                local spellID = self.spellID
                local iconTexture
                if ResolveCastIconTexture then
                    iconTexture = ResolveCastIconTexture(self, "boss" .. i, spellID)
                elseif spellID and C_Spell and C_Spell.GetSpellTexture then
                    iconTexture = C_Spell.GetSpellTexture(spellID)
                end
                bar.icon:SetTexture(iconTexture or 136243)

                -- Get spell name from the text field
                if self.Text then
                    bar.spellName:SetText(self.Text:GetText() or "Casting...")
                end

                -- Get min/max values and set up the cast bar
                local min, max = self:GetMinMaxValues()
                if min and max then
                    bar.status:SetMinMaxValues(min, max)
                    bar.status:SetValue(self:GetValue() or 0)
                end

                -- Apply proper color based on interrupt state
                if self.notInterruptible then
                    SetBossCastBarColor(i, "nonInterruptible")
                else
                    SetBossCastBarColor(i, "interruptible")
                end

                bar:Show()
            end)

            bossFrame.spellbar:HookScript("OnHide", function()
                if NephUI.bossCastBars[i] then
                    NephUI.bossCastBars[i]:Hide()
                end
            end)

            -- React to interruptibility changes and interrupts
            bossFrame.spellbar:HookScript("OnEvent", function(self, event, unit)
                if unit ~= ("boss" .. i) then return end

                local cfg = NephUI.db.profile.bossCastBar
                if not cfg or not cfg.enabled then return end

                if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
                    SetBossCastBarColor(i, "interrupted")
                elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
                    SetBossCastBarColor(i, "nonInterruptible")
                elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
                    SetBossCastBarColor(i, "interruptible")
                end
            end)

            -- Hook OnUpdate to sync progress and time text (throttled to 60fps for performance)
            bossFrame.spellbar:HookScript("OnUpdate", function(self, elapsed)
                local cfg = NephUI.db.profile.bossCastBar
                if not cfg or not cfg.enabled then return end

                local bar = NephUI.bossCastBars[i]
                if not bar or not bar:IsShown() then return end

                lastUpdate = lastUpdate + elapsed
                if lastUpdate < updateThrottle then return end
                lastUpdate = 0

                local progress = self:GetValue()
                if progress then
                    bar.status:SetValue(progress)
                end

                -- Update time text using Blizzard's values directly (avoids math on secret values)
                if bar.timeText and cfg.showTimeText ~= false then
                    local min, max = self:GetMinMaxValues()
                    if min and max then
                        bar.timeText:SetFormattedText("%.1f/%.1f", progress or 0, max)
                    end
                end
            end)
        end
    end
end

function CastBars:ShowTestBossCastBars()
    -- Show test cast bars on boss frames that are in preview mode
    if not NephUI.UnitFrames or not NephUI.UnitFrames.BossPreviewMode then
        print("Boss frames must be in preview mode to test cast bars")
        return
    end

    for i = 1, 8 do
        local unitFrame = _G["NephUI_Boss" .. i]
        if unitFrame and unitFrame:IsShown() then
            local bar = CastBars:GetBossCastBar(i)
            if bar then
                -- Ensure the cast bar layout is updated before setting text
                CastBars:UpdateBossCastBarLayout(i)

                -- Set up the test cast (same as other cast bars)
                local now = GetTime()
                bar.startTime = now
                bar.endTime = now + 15
                bar.isChannel = false
                bar.castGUID = "test_boss_" .. i .. "_" .. now
                bar.isEmpowered = false
                bar.numStages = nil

                -- Set icon and spell name
                bar.icon:SetTexture(136243)  -- Default spell icon
                bar.spellName:SetText("Test Cast")

                -- Set up fonts (match other cast bars)
                local cfg = NephUI.db.profile.bossCastBar
                local font = NephUI:GetGlobalFont()
                bar.spellName:SetFont(font, cfg.textSize or 16, "OUTLINE")
                bar.spellName:SetShadowOffset(0, 0)

                if bar.timeText then
                    bar.timeText:SetFont(font, cfg.textSize or 16, "OUTLINE")
                    bar.timeText:SetShadowOffset(0, 0)
                end

                -- Set interruptible color (test casts are interruptible)
                SetBossCastBarColor(i, "interruptible")

                -- Use the standard cast bar OnUpdate function
                bar:SetScript("OnUpdate", CastBars.CastBar_OnUpdate)
                bar:Show()
            end
        end
    end
end

-- Expose to main addon for backwards compatibility
NephUI.GetBossCastBar = function(self, bossIndex) return CastBars:GetBossCastBar(bossIndex) end
NephUI.UpdateBossCastBarLayout = function(self, bossIndex) return CastBars:UpdateBossCastBarLayout(bossIndex) end
NephUI.UpdateAllBossCastBarLayouts = function(self) return CastBars:UpdateAllBossCastBarLayouts() end
NephUI.HookBossCastBars = function(self) return CastBars:HookBossCastBars() end
NephUI.ShowTestBossCastBars = function(self) return CastBars:ShowTestBossCastBars() end
