local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

-- Get ResourceBars module
local ResourceBars = NephUI.ResourceBars
if not ResourceBars then
    error("NephUI: ResourceBars module not initialized! Load ResourceDetection.lua first.")
end

-- Get functions from ResourceDetection
local GetAssignedResources = ResourceBars.GetAssignedResources
local GetResourceColor = ResourceBars.GetResourceColor
local GetSecondaryResourceValue = ResourceBars.GetSecondaryResourceValue
local GetChargedPowerPoints = ResourceBars.GetChargedPowerPoints
local tickedPowerTypes = ResourceBars.tickedPowerTypes
local fragmentedPowerTypes = ResourceBars.fragmentedPowerTypes
local buildVersion = ResourceBars.buildVersion

local function PixelSnap(value)
    return math.max(0, math.floor((value or 0) + 0.5))
end

-- SECONDARY POWER BAR

function ResourceBars:GetSecondaryPowerBar()
    if NephUI.secondaryPowerBar then return NephUI.secondaryPowerBar end

    local cfg = NephUI.db.profile.secondaryPowerBar
    local anchor = _G[cfg.attachTo] or UIParent
    local anchorPoint = cfg.anchorPoint or "CENTER"

    local bar = CreateFrame("Frame", "NephUI_SecondaryPower", anchor)
    bar:SetFrameStrata("MEDIUM")
    -- Keep the bar click-through so it never blocks PlayerFrame interactions
    bar:EnableMouse(false)
    bar:EnableMouseWheel(false)
    if bar.SetMouseMotionEnabled then
        bar:SetMouseMotionEnabled(false)
    end
    bar:SetHeight(NephUI:Scale(cfg.height or 4))
    bar:SetPoint("CENTER", anchor, anchorPoint, NephUI:Scale(cfg.offsetX or 0), NephUI:Scale(cfg.offsetY or 12))

    local width = cfg.width or 0
    if width <= 0 then
        width = PixelSnap(anchor.__cdmIconWidth or anchor:GetWidth())
        -- Width is already in pixels, no need to scale again
    else
        width = NephUI:Scale(width)
    end

    bar:SetWidth(width)

    -- BACKGROUND (lowest frame level)
    bar.Background = bar:CreateTexture(nil, "BACKGROUND")
    bar.Background:SetAllPoints()
    local bgColor = cfg.bgColor or { 0.15, 0.15, 0.15, 1 }
    bar.Background:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)

    -- STATUS BAR (for non-fragmented resources) - class/custom color fill
    bar.StatusBar = CreateFrame("StatusBar", nil, bar)
    bar.StatusBar:SetAllPoints()
    -- Use GetTexture helper: if cfg.texture is set, use it; otherwise use global texture
    local tex = NephUI:GetTexture(cfg.texture)
    bar.StatusBar:SetStatusBarTexture(tex)
    bar.StatusBar:SetFrameLevel(bar:GetFrameLevel() + 1)

    -- BORDER - above ticks
    bar.Border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.Border:SetFrameLevel(bar:GetFrameLevel() + 4)
    local borderSize = NephUI:ScaleBorder(cfg.borderSize or 1)
    bar._scaledBorder = borderSize
    bar.Border:SetPoint("TOPLEFT", bar, -borderSize, borderSize)
    bar.Border:SetPoint("BOTTOMRIGHT", bar, borderSize, -borderSize)
    bar.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = borderSize,
    })
    local borderColor = cfg.borderColor or { 0, 0, 0, 1 }
    bar.Border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)

    -- TICKS FRAME - above charged overlay
    bar.TicksFrame = CreateFrame("Frame", nil, bar)
    bar.TicksFrame:SetAllPoints(bar)
    bar.TicksFrame:SetFrameLevel(bar:GetFrameLevel() + 3)

    -- CHARGED POWER OVERLAY FRAME - sits above the status bar, below ticks/border
    bar.ChargedFrame = CreateFrame("Frame", nil, bar)
    bar.ChargedFrame:SetAllPoints(bar)
    bar.ChargedFrame:SetFrameLevel(bar:GetFrameLevel() + 2)

    -- RUNE TIMER TEXT FRAME - above border
    bar.RuneTimerTextFrame = CreateFrame("Frame", nil, bar)
    bar.RuneTimerTextFrame:SetAllPoints(bar)
    bar.RuneTimerTextFrame:SetFrameLevel(bar:GetFrameLevel() + 5)

    -- TEXT FRAME - highest
    bar.TextFrame = CreateFrame("Frame", nil, bar)
    bar.TextFrame:SetAllPoints(bar)
    bar.TextFrame:SetFrameLevel(bar:GetFrameLevel() + 6)

    bar.TextValue = bar.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.TextValue:SetPoint("CENTER", bar.TextFrame, "CENTER", NephUI:Scale(cfg.textX or 0), NephUI:Scale(cfg.textY or 0))
    bar.TextValue:SetJustifyH("CENTER")
    bar.TextValue:SetFont(NephUI:GetGlobalFont(), cfg.textSize or 12, "OUTLINE")
    bar.TextValue:SetShadowOffset(0, 0)
    bar.TextValue:SetText("0")


    -- FRAGMENTED POWER BARS (for Runes)
    bar.FragmentedPowerBars = {}
    bar.FragmentedPowerBarTexts = {}

    -- TICKS
    bar.ticks = {}

    -- CHARGED POWER SEGMENTS
    bar.ChargedSegments = {}

    bar:Hide()

    NephUI.secondaryPowerBar = bar
    return bar
end

function ResourceBars:UpdateChargedPowerSegments(bar, resource, max)
    local cfg = NephUI.db.profile.secondaryPowerBar

    -- Hide all overlays first
    for _, segment in pairs(bar.ChargedSegments) do
        segment:Hide()
    end

    -- Bail out if the bar itself is hidden or not applicable
    if cfg.hideBarShowText or not resource or not max then
        return
    end

    if fragmentedPowerTypes[resource] or not tickedPowerTypes[resource] then
        return
    end

    local chargedPoints = GetChargedPowerPoints and GetChargedPowerPoints(resource)
    if not chargedPoints or #chargedPoints == 0 then
        return
    end

    local width = bar:GetWidth()
    local height = bar:GetHeight()
    if width <= 0 or height <= 0 then
        return
    end

    if not max or max <= 0 then
        return
    end

    local segmentWidth = width / max
    local chargedColor = cfg.chargedColor or { 0.22, 0.62, 1.0, 0.8 }

    for _, index in ipairs(chargedPoints) do
        if index >= 1 and index <= max then
            local segment = bar.ChargedSegments[index]
            if not segment then
                segment = bar.ChargedFrame:CreateTexture(nil, "ARTWORK")
                bar.ChargedSegments[index] = segment
            end

            segment:ClearAllPoints()
            segment:SetPoint("LEFT", bar, "LEFT", (index - 1) * segmentWidth, 0)
            segment:SetSize(segmentWidth, height)
            -- Use charged color exclusively; avoid additive blend so class/custom bar colors do not tint these overlays.
            segment:SetColorTexture(chargedColor[1], chargedColor[2], chargedColor[3], chargedColor[4] or 0.8)
            segment:SetBlendMode("BLEND")
            segment:Show()
        end
    end
end

function ResourceBars:CreateFragmentedPowerBars(bar, resource)
    local cfg = NephUI.db.profile.secondaryPowerBar
    local maxPower = (resource == "MAELSTROM_WEAPON" and 5) or UnitPowerMax("player", resource) or 0
    
    for i = 1, maxPower do
        if not bar.FragmentedPowerBars[i] then
            local fragmentBar = CreateFrame("StatusBar", nil, bar)
            -- Use GetTexture helper: if cfg.texture is set, use it; otherwise use global texture
            local tex = NephUI:GetTexture(cfg.texture)
            fragmentBar:SetStatusBarTexture(tex)
            fragmentBar:SetOrientation("HORIZONTAL")
            fragmentBar:SetFrameLevel(bar.StatusBar:GetFrameLevel())
            bar.FragmentedPowerBars[i] = fragmentBar
            
            -- Create text for reload time display (centered on fragment bar)
            local text = fragmentBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("CENTER", fragmentBar, "CENTER", 0, 0)
            text:SetJustifyH("CENTER")
            text:SetText("")
            bar.FragmentedPowerBarTexts[i] = text
        end
    end
end

function ResourceBars:ApplyFragmentTextStyleSecondary(bar)
    local cfg = NephUI.db.profile.secondaryPowerBar
    local font = NephUI:GetGlobalFont()
    local size = cfg.runeTimerTextSize or 10
    local offsetX = cfg.runeTimerTextX or 0
    local offsetY = cfg.runeTimerTextY or 0

    for _, text in ipairs(bar.FragmentedPowerBarTexts) do
        if text then
            text:SetFont(font, size, "OUTLINE")
            text:SetShadowOffset(0, 0)
            text:ClearAllPoints()
            text:SetPoint("CENTER", text:GetParent(), "CENTER", NephUI:Scale(offsetX), NephUI:Scale(offsetY))
        end
    end
end

function ResourceBars:UpdateFragmentedPowerDisplay(bar, resource)
    local cfg = NephUI.db.profile.secondaryPowerBar
    local maxPower = (resource == "MAELSTROM_WEAPON" and 5) or UnitPowerMax("player", resource)
    if maxPower <= 0 then return end

    local barWidth = bar:GetWidth()
    local barHeight = bar:GetHeight()
    local fragmentedBarWidth = barWidth / maxPower
    local fragmentedBarHeight = barHeight / maxPower

    local r, g, b, a = bar.StatusBar:GetStatusBarColor()
    local color = { r = r, g = g, b = b, a = a or 1 }

    if resource == Enum.PowerType.Essence then
        local current = UnitPower("player", resource)
        local maxEssence = UnitPowerMax("player", resource)
        local regenRate = (type(GetPowerRegenForPowerType) == "function" and GetPowerRegenForPowerType(resource)) or 0.2
        local tickDuration = 5 / (5 / (1 / regenRate))
        local now = GetTime()

        bar._NextEssenceTick = bar._NextEssenceTick or nil
        bar._LastEssence = bar._LastEssence or current

        -- If we gained an essence, reset timer
        if current > bar._LastEssence then
            if current < maxEssence then
                bar._NextEssenceTick = now + tickDuration
            else
                bar._NextEssenceTick = nil
            end
        end

        -- If missing essence and no timer, start it
        if current < maxEssence and not bar._NextEssenceTick then
            bar._NextEssenceTick = now + tickDuration
        end

        -- If full essence, hide timer
        if current >= maxEssence then
            bar._NextEssenceTick = nil
        end

        bar._LastEssence = current

        local displayOrder = {}
        local stateList = {}
        for i = 1, maxEssence do
            if i <= current then
                stateList[i] = "full"
            elseif i == current + 1 then
                stateList[i] = bar._NextEssenceTick and "partial" or "empty"
            else
                stateList[i] = "empty"
            end
            table.insert(displayOrder, i)
        end

        bar.StatusBar:SetValue(current)

        local precision = (cfg.fragmentedPowerBarTextPrecision and math.max(0, string.len(cfg.fragmentedPowerBarTextPrecision) - 3)) or 0
        local interpolation = cfg.smoothProgress and buildVersion >= 120000 and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
        for pos = 1, #displayOrder do
            local idx = displayOrder[pos]
            local essFrame = bar.FragmentedPowerBars[idx]
            local essText = bar.FragmentedPowerBarTexts[idx]
            local state = stateList[idx]

            if essFrame then
                essFrame:ClearAllPoints()
                essFrame:SetSize(fragmentedBarWidth, barHeight)
                essFrame:SetPoint("LEFT", bar, "LEFT", (pos - 1) * fragmentedBarWidth, 0)

                essFrame:SetMinMaxValues(0, 1)

                if state == "full" then
                    essFrame:Hide()
                    essFrame:SetValue(1, interpolation)
                    essFrame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                    essText:SetText("")
                elseif state == "partial" then
                    essFrame:Show()
                    local remaining = math.max(0, bar._NextEssenceTick - now)
                    local value = 1 - (remaining / tickDuration)
                    essFrame:SetValue(value, interpolation)
                    essFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                    if cfg.showFragmentedPowerBarText then
                        essText:SetText(string.format("%." .. (precision or 1) .. "f", remaining))
                    else
                        essText:SetText("")
                    end
                else
                    essFrame:Show()
                    essFrame:SetValue(0, interpolation)
                    essFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                    essText:SetText("")
                end
            end
        end
    elseif resource == Enum.PowerType.Runes then
        -- Collect rune states: ready and recharging
        local readyList = {}
        local cdList = {}
        local now = GetTime()
        for i = 1, maxPower do
            local start, duration, runeReady = GetRuneCooldown(i)
            if runeReady then
                table.insert(readyList, { index = i })
            else
                if start and duration and duration > 0 then
                    local elapsed = now - start
                    local remaining = math.max(0, duration - elapsed)
                    local frac = math.max(0, math.min(1, elapsed / duration))
                    table.insert(cdList, { index = i, remaining = remaining, frac = frac })
                else
                    table.insert(cdList, { index = i, remaining = math.huge, frac = 0 })
                end
            end
        end

        -- Sort cdList by ascending remaining time (least remaining on the left of the CD group)
        table.sort(cdList, function(a, b)
            return a.remaining < b.remaining
        end)

        -- Build final display order: ready runes first (left), then CD runes sorted by remaining
        local displayOrder = {}
        local readyLookup = {}
        local cdLookup = {}
        for _, v in ipairs(readyList) do
            table.insert(displayOrder, v.index)
            readyLookup[v.index] = true
        end
        for _, v in ipairs(cdList) do
            table.insert(displayOrder, v.index)
            cdLookup[v.index] = v
        end

        bar.StatusBar:SetValue(#readyList)

        local precision = (cfg.fragmentedPowerBarTextPrecision and math.max(0, string.len(cfg.fragmentedPowerBarTextPrecision) - 3)) or 0
        local interpolation = cfg.smoothProgress and buildVersion >= 120000 and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
        for pos = 1, #displayOrder do
            local runeIndex = displayOrder[pos]
            local runeFrame = bar.FragmentedPowerBars[runeIndex]
            local runeText = bar.FragmentedPowerBarTexts[runeIndex]

            if runeFrame then
                runeFrame:ClearAllPoints()
                runeFrame:SetSize(fragmentedBarWidth, barHeight)
                runeFrame:SetPoint("LEFT", bar, "LEFT", (pos - 1) * fragmentedBarWidth, 0)

                runeFrame:SetMinMaxValues(0, 1)
                if readyLookup[runeIndex] then
                    runeFrame:Hide()
                    runeFrame:SetValue(1, interpolation)
                    runeText:SetText("")
                    runeFrame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
                else
                    runeFrame:Show()
                    local cdInfo = cdLookup[runeIndex]
                    runeFrame:SetStatusBarColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a or 1)
                    if cdInfo then
                        runeFrame:SetValue(cdInfo.frac, interpolation)
                        if cfg.showFragmentedPowerBarText then
                            runeText:SetText(string.format("%." .. (precision or 1) .. "f", math.max(0, cdInfo.remaining)))
                        else
                            runeText:SetText("")
                        end
                    else
                        runeFrame:SetValue(0, interpolation)
                        runeText:SetText("")
                    end
                end
            end
        end
    end

    -- Hide extra fragmented power bars beyond current maxPower
    for i = maxPower + 1, #bar.FragmentedPowerBars do
        if bar.FragmentedPowerBars[i] then
            bar.FragmentedPowerBars[i]:Hide()
            if bar.FragmentedPowerBarTexts[i] then
                bar.FragmentedPowerBarTexts[i]:SetText("")
            end
        end
    end
end

function ResourceBars:UpdateSecondaryPowerBarTicks(bar, resource, max)
    local cfg = NephUI.db.profile.secondaryPowerBar

    -- Hide all ticks first
    for _, tick in ipairs(bar.ticks) do
        tick:Hide()
    end

    -- Special check for SOUL: only show ticks for Vengeance spec
    local isTickedResource = tickedPowerTypes[resource]
    if resource == "SOUL" then
        local spec = GetSpecialization()
        local specID = GetSpecializationInfo(spec)
        -- Only ticked for Vengeance (specID 581)
        isTickedResource = (specID == 581)
    end

    -- Don't show ticks if disabled or not a ticked power type
    if not cfg.showTicks or not isTickedResource then
        return
    end

    local width  = bar:GetWidth()
    local height = bar:GetHeight()
    if width <= 0 or height <= 0 then return end

    -- For Soul Shards, use the display max (not the internal fractional max)
    local displayMax = max
    if resource == Enum.PowerType.SoulShards then
        displayMax = UnitPowerMax("player", resource) -- non-fractional max (usually 5)
    end
    if not displayMax or displayMax <= 0 then
        return
    end

    local needed = displayMax - 1
    for i = 1, needed do
        local tick = bar.ticks[i]
        if not tick then
            tick = bar.TicksFrame:CreateTexture(nil, "OVERLAY")
            tick:SetColorTexture(0, 0, 0, 1)
            bar.ticks[i] = tick
        end

        local x = (i / displayMax) * width
        tick:ClearAllPoints()
        -- x is already in pixels (calculated from bar width), no need to scale
        tick:SetPoint("LEFT", bar.StatusBar, "LEFT", x, 0)
        -- Ensure tick width is at least 1 pixel to prevent disappearing
        local tickWidth = math.max(1, NephUI:Scale(1))
        -- height is already in pixels (from bar:GetHeight()), no need to scale
        tick:SetSize(tickWidth, height)
        tick:Show()
    end
end

function ResourceBars:UpdateSecondaryPowerBar()
    local cfg = NephUI.db.profile.secondaryPowerBar
    if not cfg.enabled then
        if NephUI.secondaryPowerBar then
            NephUI.secondaryPowerBar:Hide()
            NephUI.secondaryPowerBar:SetScript("OnUpdate", nil)
        end
        return
    end

    -- Setup/teardown OnUpdate ticker for faster updates
    local bar = self:GetSecondaryPowerBar()
    if cfg.fasterUpdates then
        local updateFrequency = cfg.updateFrequency or 0.1
        bar:SetScript("OnUpdate", function(frame, elapsed)
            frame._updateElapsed = (frame._updateElapsed or 0) + elapsed
            if frame._updateElapsed >= updateFrequency then
                frame._updateElapsed = 0
                ResourceBars:UpdateSecondaryPowerBar()
            end
        end)
    else
        bar:SetScript("OnUpdate", nil)
    end

    -- Track stagger percentage for dynamic color changes
    local resource = select(2, GetAssignedResources())
    if resource == "STAGGER" then
        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1
        local staggerPercent = (stagger / maxHealth) * 100

        -- Initialize tracking variable if it doesn't exist
        bar._lastStaggerPercent = bar._lastStaggerPercent or staggerPercent

        -- Check if we crossed a threshold and need to update colors
        if (staggerPercent >= 30 and bar._lastStaggerPercent < 30)
            or (staggerPercent < 30 and bar._lastStaggerPercent >= 30)
            or (staggerPercent >= 60 and bar._lastStaggerPercent < 60)
            or (staggerPercent < 60 and bar._lastStaggerPercent >= 60) then
            -- Force color update by clearing cached color
            bar._lastColorResource = nil
        end

        bar._lastStaggerPercent = staggerPercent
    end

    local anchor = _G[cfg.attachTo]
    if not anchor or not anchor:IsShown() then
        if NephUI.secondaryPowerBar then NephUI.secondaryPowerBar:Hide() end
        return
    end

    local bar = self:GetSecondaryPowerBar()
    local resource = select(2, GetAssignedResources())
    
    if not resource then
        bar:Hide()
        return
    end

    -- Optionally hide when the secondary resource is mana (e.g., boomkin/ele)
    if cfg.hideWhenMana and resource == Enum.PowerType.Mana then
        if not InCombatLockdown() then
            bar:Hide()
        end
        return
    end

    -- Update layout
    local anchorPoint = cfg.anchorPoint or "CENTER"
    local desiredHeight = NephUI:Scale(cfg.height or 4)
    local desiredX = NephUI:Scale(cfg.offsetX or 0)
    local desiredY = NephUI:Scale(cfg.offsetY or 12)

    local width = cfg.width or 0
    if width <= 0 then
        width = PixelSnap(
            anchor.__cdmIconWidth
            or (NephUI.powerBar and NephUI.powerBar:IsShown() and NephUI.powerBar:GetWidth())
            or anchor:GetWidth()
        )
        -- Width is already in pixels, no need to scale again
    else
        width = NephUI:Scale(width)
    end

    -- Only reposition / resize when something actually changed to avoid texture flicker
    if bar._lastAnchor ~= anchor or bar._lastAnchorPoint ~= anchorPoint or bar._lastOffsetX ~= desiredX or bar._lastOffsetY ~= desiredY then
        bar:ClearAllPoints()
        bar:SetPoint("CENTER", anchor, anchorPoint, desiredX, desiredY)
        bar._lastAnchor = anchor
        bar._lastAnchorPoint = anchorPoint
        bar._lastOffsetX = desiredX
        bar._lastOffsetY = desiredY
    end

    if bar._lastHeight ~= desiredHeight then
        bar:SetHeight(desiredHeight)
        bar._lastHeight = desiredHeight
    end

    if bar._lastWidth ~= width then
        bar:SetWidth(width)
        bar._lastWidth = width
    end

    -- Update background color
    local bgColor = cfg.bgColor or { 0.15, 0.15, 0.15, 1 }
    if bar.Background then
        bar.Background:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    end

    -- Update texture (use per-bar texture if set, otherwise use global)
    local tex = NephUI:GetTexture(cfg.texture)
    if bar._lastTexture ~= tex then
        bar.StatusBar:SetStatusBarTexture(tex)
        bar._lastTexture = tex
    end

    -- Update border size and color
    local borderSize = cfg.borderSize or 1
    if bar.Border then
        local scaledBorder = NephUI:ScaleBorder(borderSize)
        bar._scaledBorder = scaledBorder
        bar.Border:ClearAllPoints()
        bar.Border:SetPoint("TOPLEFT", bar, -scaledBorder, scaledBorder)
        bar.Border:SetPoint("BOTTOMRIGHT", bar, scaledBorder, -scaledBorder)
        bar.Border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = scaledBorder,
        })
        -- Update border color
        local borderColor = cfg.borderColor or { 0, 0, 0, 1 }
        bar.Border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        -- Show/hide border based on size
        if scaledBorder > 0 then
            bar.Border:Show()
        else
            bar.Border:Hide()
        end
    end

    -- Get resource values
    local max, maxDisplayValue, current, displayValue, valueType = GetSecondaryResourceValue(resource, cfg)
    if not max then
        bar:Hide()
        return
    end

    -- Handle fragmented power types (Runes, Essence)
    if fragmentedPowerTypes[resource] then
        -- Set StatusBar color first so UpdateFragmentedPowerDisplay can read it
        local powerTypeColors = NephUI.db.profile.powerTypeColors
        if powerTypeColors.useClassColor then
            -- Class color for all resources
            local _, class = UnitClass("player")
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                bar.StatusBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
            else
                local color = GetResourceColor(resource)
                bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
            end
        elseif powerTypeColors.colors[resource] then
            -- Power type specific color
            local color = powerTypeColors.colors[resource]
            bar.StatusBar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
        else
            -- Default resource color
            local color = GetResourceColor(resource)
            bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
        end
        
        -- Set StatusBar min/max and value first
        local interpolation = cfg.smoothProgress and buildVersion >= 120000 and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
        bar.StatusBar:SetMinMaxValues(0, max, interpolation)
        bar.StatusBar:SetValue(current, interpolation)
        
        self:CreateFragmentedPowerBars(bar, resource)
        self:ApplyFragmentTextStyleSecondary(bar)
        self:UpdateFragmentedPowerDisplay(bar, resource)
        
        -- Update ticks for fragmented resources
        self:UpdateSecondaryPowerBarTicks(bar, resource, max)

        bar.TextValue:SetText(tostring(current))
    else
        -- Normal bar display
        bar.StatusBar:SetAlpha(1)
        local interpolation = cfg.smoothProgress and buildVersion >= 120000 and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
        bar.StatusBar:SetMinMaxValues(0, max, interpolation)
        bar.StatusBar:SetValue(current, interpolation)

        -- Set bar color
        local powerTypeColors = NephUI.db.profile.powerTypeColors
        if powerTypeColors.useClassColor then
            -- Class color for all resources
            local _, class = UnitClass("player")
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                bar.StatusBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
            else
                local color = GetResourceColor(resource)
                bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
            end
        elseif powerTypeColors.colors[resource] and resource ~= "STAGGER" then
            -- Power type specific color (skip for stagger as it uses dynamic colors)
            local color = powerTypeColors.colors[resource]
            bar.StatusBar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
        else
            -- Default resource color (includes dynamic stagger colors)
            local color = GetResourceColor(resource)
            bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
        end

        if cfg.textFormat == "Percent" or cfg.textFormat == "Percent%" then
            local precision = cfg.textPrecision and math.max(0, string.len(cfg.textPrecision) - 3) or 0
            if valueType == "custom" then
                bar.TextValue:SetText(displayValue)
            else
                bar.TextValue:SetText(string.format("%." .. (precision or 0) .. "f" .. (cfg.textFormat == "Percent%" and "%%" or ""), displayValue))
            end
        elseif cfg.textFormat == "Current / Maximum" then
            if valueType == "custom" then
                bar.TextValue:SetText(displayValue .. ' / ' .. (maxDisplayValue or max))
            else
                bar.TextValue:SetText(AbbreviateNumbers(displayValue) .. ' / ' .. AbbreviateNumbers(maxDisplayValue or max))
            end
        else -- Default "Current" format
            if valueType == "custom" then
                bar.TextValue:SetText(displayValue)
            elseif valueType == "percent" then
                local formatStr = cfg.showManaPercentDecimal and "%.1f%%" or "%.0f%%"
                bar.TextValue:SetText(string.format(formatStr, displayValue))
            else
                bar.TextValue:SetText(AbbreviateNumbers(displayValue))
            end
        end
        
        -- Hide fragmented bars
        for _, fragmentBar in ipairs(bar.FragmentedPowerBars) do
            fragmentBar:Hide()
        end
    end

    bar.TextValue:SetFont(NephUI:GetGlobalFont(), cfg.textSize or 12, "OUTLINE")
    bar.TextValue:SetShadowOffset(0, 0)
    bar.TextValue:ClearAllPoints()
    bar.TextValue:SetPoint("CENTER", bar.TextFrame, "CENTER", NephUI:Scale(cfg.textX or 0), NephUI:Scale(cfg.textY or 0))


    -- Show text
    bar.TextFrame:SetShown(cfg.showText ~= false)

    -- Handle hide bar but show text option
    if cfg.hideBarShowText then
        -- Hide the bar visuals but keep text visible
        if bar.StatusBar then
            bar.StatusBar:Hide()
        end
        if bar.Background then
            bar.Background:Hide()
        end
        -- Hide border when bar is hidden
        if bar.Border then
            bar.Border:Hide()
        end
        -- Hide ticks when bar is hidden
        for _, tick in ipairs(bar.ticks) do
            tick:Hide()
        end
        -- Hide fragmented power bars (runes) when bar is hidden
        for _, fragmentBar in ipairs(bar.FragmentedPowerBars) do
            fragmentBar:Hide()
        end
        -- Hide rune timer texts when bar is hidden
        for _, runeText in ipairs(bar.FragmentedPowerBarTexts) do
            if runeText then
                runeText:Hide()
            end
        end
    else
        -- Show the bar visuals
        if bar.StatusBar then
            bar.StatusBar:Show()
        end
        if bar.Background then
            bar.Background:Show()
        end
        -- Show border if size > 0
        if bar.Border and (bar._scaledBorder or NephUI:ScaleBorder(cfg.borderSize or 1)) > 0 then
            bar.Border:Show()
        end
        -- Update ticks if this is a ticked power type and not fragmented
        if not fragmentedPowerTypes[resource] then
            self:UpdateSecondaryPowerBarTicks(bar, resource, max)
        end
    end

    -- Update charged power overlays (e.g., Charged Combo Points)
    self:UpdateChargedPowerSegments(bar, resource, max)


    bar:Show()
end

-- Expose to main addon for backwards compatibility
NephUI.GetSecondaryPowerBar = function(self) return ResourceBars:GetSecondaryPowerBar() end
NephUI.UpdateSecondaryPowerBar = function(self) return ResourceBars:UpdateSecondaryPowerBar() end
NephUI.UpdateSecondaryPowerBarTicks = function(self, bar, resource, max) return ResourceBars:UpdateSecondaryPowerBarTicks(bar, resource, max) end
NephUI.CreateFragmentedPowerBars = function(self, bar, resource) return ResourceBars:CreateFragmentedPowerBars(bar, resource) end
NephUI.UpdateFragmentedPowerDisplay = function(self, bar, resource) return ResourceBars:UpdateFragmentedPowerDisplay(bar, resource) end
NephUI.UpdateChargedPowerSegments = function(self, bar, resource, max) return ResourceBars:UpdateChargedPowerSegments(bar, resource, max) end

