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
local GetPrimaryResourceValue = ResourceBars.GetPrimaryResourceValue
local GetSecondaryResourceValue = ResourceBars.GetSecondaryResourceValue
local GetChargedPowerPoints = ResourceBars.GetChargedPowerPoints
local IsSecondaryResourceForSpec = ResourceBars.IsSecondaryResourceForSpec
local tickedPowerTypes = ResourceBars.tickedPowerTypes
local fragmentedPowerTypes = ResourceBars.fragmentedPowerTypes
local buildVersion = ResourceBars.buildVersion

local function PixelSnap(value)
    return math.max(0, math.floor((value or 0) + 0.5))
end

-- PRIMARY POWER BAR

function ResourceBars:GetPowerBar()
    if NephUI.powerBar then return NephUI.powerBar end

    local cfg = NephUI.db.profile.powerBar
    local anchor = _G[cfg.attachTo] or UIParent
    local anchorPoint = cfg.anchorPoint or "CENTER"

    local bar = CreateFrame("Frame", "NephUI_PrimaryPower", anchor)
    bar:SetFrameStrata("MEDIUM")
    bar:SetHeight(NephUI:Scale(cfg.height or 6))
    bar:SetPoint("CENTER", anchor, anchorPoint, NephUI:Scale(cfg.offsetX or 0), NephUI:Scale(cfg.offsetY or 6))

    local width = cfg.width or 0
    if width <= 0 then
        width = PixelSnap(anchor.__cdmIconWidth or anchor:GetWidth())
        -- Width is already in pixels, no need to scale again
    else
        width = NephUI:Scale(width)
    end

    bar:SetWidth(width)

    -- BACKGROUND
    bar.Background = bar:CreateTexture(nil, "BACKGROUND")
    bar.Background:SetAllPoints()
    local bgColor = cfg.bgColor or { 0.15, 0.15, 0.15, 1 }
    bar.Background:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)

    -- STATUS BAR
    bar.StatusBar = CreateFrame("StatusBar", nil, bar)
    bar.StatusBar:SetAllPoints()
    -- Use GetTexture helper: if cfg.texture is set, use it; otherwise use global texture
    local tex = NephUI:GetTexture(cfg.texture)
    bar.StatusBar:SetStatusBarTexture(tex)
    bar.StatusBar:SetFrameLevel(bar:GetFrameLevel())

    -- Hide the StatusBar's internal background texture so it doesn't interfere with our custom solid color background
    for i = 1, select("#", bar.StatusBar:GetRegions()) do
        local region = select(i, bar.StatusBar:GetRegions())
        if region:GetObjectType() == "Texture" and region ~= bar.StatusBar:GetStatusBarTexture() then
            region:Hide()
        end
    end

    -- BORDER
    bar.Border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    local borderSize = NephUI:ScaleBorder(cfg.borderSize or 1)
    local borderOffset = borderSize
    bar.Border:SetPoint("TOPLEFT", bar, -borderOffset, borderOffset)
    bar.Border:SetPoint("BOTTOMRIGHT", bar, borderOffset, -borderOffset)
    bar.Border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = borderSize,
    })
    local borderColor = cfg.borderColor or { 0, 0, 0, 1 }
    bar.Border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)

    -- TEXT FRAME
    bar.TextFrame = CreateFrame("Frame", nil, bar)
    bar.TextFrame:SetAllPoints(bar)
    bar.TextFrame:SetFrameLevel(bar.StatusBar:GetFrameLevel() + 25)

    -- TICKS FRAME - above charged overlay
    bar.TicksFrame = CreateFrame("Frame", nil, bar)
    bar.TicksFrame:SetAllPoints(bar)
    bar.TicksFrame:SetFrameLevel(bar.StatusBar:GetFrameLevel() + 3)

    -- CHARGED POWER OVERLAY FRAME - sits above the status bar, below ticks/border
    bar.ChargedFrame = CreateFrame("Frame", nil, bar)
    bar.ChargedFrame:SetAllPoints(bar)
    bar.ChargedFrame:SetFrameLevel(bar.StatusBar:GetFrameLevel() + 2)

    -- TICKS FRAME - above charged overlay
    bar.TicksFrame = CreateFrame("Frame", nil, bar)
    bar.TicksFrame:SetAllPoints(bar)
    bar.TicksFrame:SetFrameLevel(bar.StatusBar:GetFrameLevel() + 5)

    -- CHARGED POWER OVERLAY FRAME - sits above the status bar, below ticks/border
    bar.ChargedFrame = CreateFrame("Frame", nil, bar)
    bar.ChargedFrame:SetAllPoints(bar)
    bar.ChargedFrame:SetFrameLevel(bar.StatusBar:GetFrameLevel() + 4)

    bar.TextValue = bar.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.TextValue:SetPoint("CENTER", bar.TextFrame, "CENTER", NephUI:Scale(cfg.textX or 0), NephUI:Scale(cfg.textY or 0))
    bar.TextValue:SetJustifyH("CENTER")
    bar.TextValue:SetFont(NephUI:GetGlobalFont(), cfg.textSize or 12, "OUTLINE")
    bar.TextValue:SetShadowOffset(0, 0)
    bar.TextValue:SetText("0")

    -- TICKS
    bar.ticks = {}

    -- CHARGED POWER SEGMENTS
    bar.ChargedSegments = {}

    -- FRAGMENTED POWER BARS (for Runes/Essence)
    bar.FragmentedPowerBars = {}
    bar.FragmentedPowerBarTexts = {}

    bar:Hide()

    NephUI.powerBar = bar
    return bar
end

function ResourceBars:UpdateChargedPowerSegmentsPrimary(bar, resource, max)
    local cfg = NephUI.db.profile.powerBar

    for _, segment in pairs(bar.ChargedSegments) do
        segment:Hide()
    end

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
            segment:SetColorTexture(chargedColor[1], chargedColor[2], chargedColor[3], chargedColor[4] or 0.8)
            segment:SetBlendMode("BLEND")
            segment:Show()
        end
    end
end

function ResourceBars:ApplyFragmentTextStylePrimary(bar)
    local cfg = NephUI.db.profile.powerBar
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

function ResourceBars:CreateFragmentedPowerBarsPrimary(bar, resource)
    local cfg = NephUI.db.profile.powerBar
    local maxPower = UnitPowerMax("player", resource) or 0

    for i = 1, maxPower do
        if not bar.FragmentedPowerBars[i] then
            local fragmentBar = CreateFrame("StatusBar", nil, bar)
            local tex = NephUI:GetTexture(cfg.texture)
            fragmentBar:SetStatusBarTexture(tex)
            fragmentBar:SetOrientation("HORIZONTAL")
            fragmentBar:SetFrameLevel(bar.StatusBar:GetFrameLevel())
            bar.FragmentedPowerBars[i] = fragmentBar

            local text = fragmentBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("CENTER", fragmentBar, "CENTER", 0, 0)
            text:SetJustifyH("CENTER")
            text:SetText("")
            bar.FragmentedPowerBarTexts[i] = text
        end
    end

    self:ApplyFragmentTextStylePrimary(bar)
end

function ResourceBars:UpdateFragmentedPowerDisplayPrimary(bar, resource)
    local cfg = NephUI.db.profile.powerBar
    local maxPower = UnitPowerMax("player", resource)
    if maxPower <= 0 then return end

    local barWidth = bar:GetWidth()
    local barHeight = bar:GetHeight()
    local fragmentedBarWidth = barWidth / maxPower

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

        if current > bar._LastEssence then
            if current < maxEssence then
                bar._NextEssenceTick = now + tickDuration
            else
                bar._NextEssenceTick = nil
            end
        end

        if current < maxEssence and not bar._NextEssenceTick then
            bar._NextEssenceTick = now + tickDuration
        end

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

        table.sort(cdList, function(a, b)
            return a.remaining < b.remaining
        end)

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

    for i = maxPower + 1, #bar.FragmentedPowerBars do
        if bar.FragmentedPowerBars[i] then
            bar.FragmentedPowerBars[i]:Hide()
            if bar.FragmentedPowerBarTexts[i] then
                bar.FragmentedPowerBarTexts[i]:SetText("")
            end
        end
    end
end

function ResourceBars:UpdatePowerBar()
    local cfg = NephUI.db.profile.powerBar
    if not cfg.enabled then
        if NephUI.powerBar then
            NephUI.powerBar:Hide()
            NephUI.powerBar:SetScript("OnUpdate", nil)
        end
        return
    end

    local anchor = _G[cfg.attachTo]
    if not anchor or not anchor:IsShown() then
        local bar = NephUI.powerBar
        if bar then
            bar:Hide()
            bar:SetScript("OnUpdate", nil)
        end
        return
    end

    local bar = self:GetPowerBar()
    
    -- Setup/teardown OnUpdate ticker for faster updates
    if cfg.fasterUpdates then
        local updateFrequency = cfg.updateFrequency or 0.1
        bar:SetScript("OnUpdate", function(frame, elapsed)
            frame._updateElapsed = (frame._updateElapsed or 0) + elapsed
            if frame._updateElapsed >= updateFrequency then
                frame._updateElapsed = 0
                ResourceBars:UpdatePowerBar()
            end
        end)
    else
        bar:SetScript("OnUpdate", nil)
    end

    local resource = select(1, GetAssignedResources())
    
    if not resource then
        bar:Hide()
        return
    end

    -- Check if we should hide the bar when power is mana
    if cfg.hideWhenMana and resource == Enum.PowerType.Mana then
        -- Only hide/show if not in combat lockdown to prevent errors during druid shapeshifting
        if not InCombatLockdown() then
            bar:Hide()
        end
        return
    end

    -- Update layout
    local anchorPoint = cfg.anchorPoint or "CENTER"
    local desiredHeight = NephUI:Scale(cfg.height or 6)
    local desiredX = NephUI:Scale(cfg.offsetX or 0)
    local desiredY = NephUI:Scale(cfg.offsetY or 6)

    local width = cfg.width or 0
    if width <= 0 then
        width = PixelSnap(anchor.__cdmIconWidth or anchor:GetWidth())
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

        -- Re-hide the StatusBar's internal background texture after texture change
        for i = 1, select("#", bar.StatusBar:GetRegions()) do
            local region = select(i, bar.StatusBar:GetRegions())
            if region:GetObjectType() == "Texture" and region ~= bar.StatusBar:GetStatusBarTexture() then
                region:Hide()
            end
        end
    end

    -- Update border size and color
    local borderSize = cfg.borderSize or 1
    if bar.Border then
        local scaledBorder = NephUI:ScaleBorder(borderSize)
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
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    local specID = spec and GetSpecializationInfo(spec)
    local useSecondaryValues = class and specID and IsSecondaryResourceForSpec(class, specID, resource)
    local max, _, current, displayValue, valueType
    if useSecondaryValues then
        max, _, current, displayValue, valueType = GetSecondaryResourceValue(resource, cfg)
    else
        max, _, current, displayValue, valueType = GetPrimaryResourceValue(resource, cfg)
    end
    if not max then
        bar:Hide()
        return
    end

    -- Set bar color
    local powerTypeColors = NephUI.db.profile.powerTypeColors
    if powerTypeColors.useClassColor then
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            bar.StatusBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
        else
            local color = GetResourceColor(resource)
            bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
        end
    elseif powerTypeColors.colors[resource] and resource ~= "STAGGER" then
        local color = powerTypeColors.colors[resource]
        bar.StatusBar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
    else
        local color = GetResourceColor(resource)
        bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
    end

    if fragmentedPowerTypes[resource] then
        local interpolation = cfg.smoothProgress and buildVersion >= 120000 and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
        bar.StatusBar:SetMinMaxValues(0, max, interpolation)
        bar.StatusBar:SetValue(current, interpolation)

        self:CreateFragmentedPowerBarsPrimary(bar, resource)
        self:ApplyFragmentTextStylePrimary(bar)
        self:UpdateFragmentedPowerDisplayPrimary(bar, resource)
        self:UpdatePowerBarTicks(bar, resource, max)

        bar.TextValue:SetText(tostring(current))
    else
        local interpolation = cfg.smoothProgress and buildVersion >= 120000 and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
        bar.StatusBar:SetMinMaxValues(0, max, interpolation)
        bar.StatusBar:SetValue(current, interpolation)

        if cfg.textFormat == "Percent" or cfg.textFormat == "Percent%" then
            local precision = cfg.textPrecision and math.max(0, string.len(cfg.textPrecision) - 3) or 0
            local percentValue = (valueType == "percent") and displayValue or ((max > 0 and (current / max) * 100) or 0)
            bar.TextValue:SetText(string.format("%." .. (precision or 0) .. "f" .. (cfg.textFormat == "Percent%" and "%%" or ""), percentValue))
        elseif cfg.textFormat == "Current / Maximum" then
            if AbbreviateNumbers then
                bar.TextValue:SetText(AbbreviateNumbers(displayValue) .. " / " .. AbbreviateNumbers(max))
            else
                bar.TextValue:SetText(tostring(displayValue) .. " / " .. tostring(max))
            end
        else
            if valueType == "percent" then
                local formatStr = cfg.showManaPercentDecimal and "%.1f%%" or "%.0f%%"
                bar.TextValue:SetText(string.format(formatStr, displayValue))
            else
                bar.TextValue:SetText(tostring(displayValue))
            end
        end

        for _, fragmentBar in ipairs(bar.FragmentedPowerBars) do
            fragmentBar:Hide()
        end
        for _, fragmentText in ipairs(bar.FragmentedPowerBarTexts) do
            if fragmentText then
                fragmentText:SetText("")
            end
        end
    end

    bar.TextValue:SetFont(NephUI:GetGlobalFont(), cfg.textSize or 12, "OUTLINE")
    bar.TextValue:SetShadowOffset(0, 0)
    bar.TextValue:ClearAllPoints()
    bar.TextValue:SetPoint("CENTER", bar.TextFrame, "CENTER", NephUI:Scale(cfg.textX or 0), NephUI:Scale(cfg.textY or 0))

    -- Show text based on config
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
        for _, fragmentBar in ipairs(bar.FragmentedPowerBars) do
            fragmentBar:Hide()
        end
        for _, fragmentText in ipairs(bar.FragmentedPowerBarTexts) do
            if fragmentText then
                fragmentText:Hide()
            end
        end
        for _, segment in pairs(bar.ChargedSegments) do
            segment:Hide()
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
        if bar.Border and (cfg.borderSize or 1) > 0 then
            bar.Border:Show()
        end
        -- Update ticks if this is a ticked power type
        self:UpdatePowerBarTicks(bar, resource, max)
    end

    self:UpdateChargedPowerSegmentsPrimary(bar, resource, max)

    bar:Show()
end

function ResourceBars:UpdatePowerBarTicks(bar, resource, max)
    local cfg = NephUI.db.profile.powerBar
    
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

    if not cfg.showTicks or not isTickedResource then
        return
    end

    local width = bar:GetWidth()
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
            local parent = bar.TicksFrame or bar
            tick = parent:CreateTexture(nil, "OVERLAY")
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

-- Expose to main addon for backwards compatibility
NephUI.GetPowerBar = function(self) return ResourceBars:GetPowerBar() end
NephUI.UpdatePowerBar = function(self) return ResourceBars:UpdatePowerBar() end
NephUI.UpdatePowerBarTicks = function(self, bar, resource, max) return ResourceBars:UpdatePowerBarTicks(bar, resource, max) end

