local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

-- Get ResourceBars module
local ResourceBars = NephUI.ResourceBars
if not ResourceBars then
    error("NephUI: ResourceBars module not initialized! Load ResourceDetection.lua first.")
end

-- Get functions from ResourceDetection
local GetPrimaryResource = ResourceBars.GetPrimaryResource
local GetResourceColor = ResourceBars.GetResourceColor
local GetPrimaryResourceValue = ResourceBars.GetPrimaryResourceValue
local tickedPowerTypes = ResourceBars.tickedPowerTypes

-- PRIMARY POWER BAR

function ResourceBars:GetPowerBar()
    if NephUI.powerBar then return NephUI.powerBar end

    local cfg = NephUI.db.profile.powerBar
    local anchor = _G[cfg.attachTo] or UIParent
    local anchorPoint = cfg.anchorPoint or "CENTER"

    local bar = CreateFrame("Frame", ADDON_NAME .. "PowerBar", anchor)
    bar:SetFrameStrata("MEDIUM")
    bar:SetHeight(NephUI:Scale(cfg.height or 6))
    bar:SetPoint("CENTER", anchor, anchorPoint, NephUI:Scale(cfg.offsetX or 0), NephUI:Scale(cfg.offsetY or 6))

    local width = cfg.width or 0
    if width <= 0 then
        width = (anchor.__cdmIconWidth or anchor:GetWidth())
        -- Round down to handle decimal values (e.g., 100.9 -> 100) to prevent overflow
        width = math.floor(width)

        -- Apply trim - scale padding first, then subtract from pixel width
        local pad = NephUI:Scale(cfg.autoWidthPadding or 5.8)
        width = width - (pad * 2)
        if width < 0 then width = 0 end
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

    -- BORDER
    bar.Border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    local borderSize = cfg.borderSize or 1
    local borderOffset = NephUI:Scale(borderSize)
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
    bar.TextFrame:SetFrameLevel(bar.StatusBar:GetFrameLevel() + 3)

    bar.TextValue = bar.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.TextValue:SetPoint("CENTER", bar.TextFrame, "CENTER", NephUI:Scale(cfg.textX or 0), NephUI:Scale(cfg.textY or 0))
    bar.TextValue:SetJustifyH("CENTER")
    bar.TextValue:SetFont(NephUI:GetGlobalFont(), cfg.textSize or 12, "OUTLINE")
    bar.TextValue:SetShadowOffset(0, 0)
    bar.TextValue:SetText("0")

    -- TICKS
    bar.ticks = {}

    bar:Hide()

    NephUI.powerBar = bar
    return bar
end

function ResourceBars:UpdatePowerBar()
    local cfg = NephUI.db.profile.powerBar
    if not cfg.enabled then
        if NephUI.powerBar then NephUI.powerBar:Hide() end
        return
    end

    local anchor = _G[cfg.attachTo]
    if not anchor or not anchor:IsShown() then
        if NephUI.powerBar then NephUI.powerBar:Hide() end
        return
    end

    local bar = self:GetPowerBar()
    local resource = GetPrimaryResource()

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
    bar:ClearAllPoints()
    bar:SetPoint("CENTER", anchor, anchorPoint, NephUI:Scale(cfg.offsetX or 0), NephUI:Scale(cfg.offsetY or 6))
    bar:SetHeight(NephUI:Scale(cfg.height or 6))

    local width = cfg.width or 0
    if width <= 0 then
        width = (anchor.__cdmIconWidth or anchor:GetWidth())
        -- Round down to handle decimal values (e.g., 100.9 -> 100) to prevent overflow
        width = math.floor(width)

        -- Apply trim - scale padding first, then subtract from pixel width
        local pad = NephUI:Scale(cfg.autoWidthPadding or 5.8)
        width = width - (pad * 2)
        if width < 0 then width = 0 end
        -- Width is already in pixels, no need to scale again
    else
        width = NephUI:Scale(width)
    end

    bar:SetWidth(width)

    -- Update background color
    local bgColor = cfg.bgColor or { 0.15, 0.15, 0.15, 1 }
    if bar.Background then
        bar.Background:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    end

    -- Update texture (use per-bar texture if set, otherwise use global)
    local tex = NephUI:GetTexture(cfg.texture)
    bar.StatusBar:SetStatusBarTexture(tex)

    -- Update border size and color
    local borderSize = cfg.borderSize or 1
    if bar.Border then
        local borderOffset = NephUI:Scale(borderSize)
        bar.Border:ClearAllPoints()
        bar.Border:SetPoint("TOPLEFT", bar, -borderOffset, borderOffset)
        bar.Border:SetPoint("BOTTOMRIGHT", bar, borderOffset, -borderOffset)
        bar.Border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = borderSize,
        })
        -- Update border color
        local borderColor = cfg.borderColor or { 0, 0, 0, 1 }
        bar.Border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        -- Show/hide border based on size
        if borderSize > 0 then
            bar.Border:Show()
        else
            bar.Border:Hide()
        end
    end

    -- Get resource values
    local max, current, displayValue, valueType = GetPrimaryResourceValue(resource, cfg)
    if not max then
        bar:Hide()
        return
    end

    -- Set bar values
    bar.StatusBar:SetMinMaxValues(0, max)
    bar.StatusBar:SetValue(current)

    -- Set bar color
    if cfg.useClassColor then
        -- Class color
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            bar.StatusBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
        else
            -- Fallback to resource color
            local color = GetResourceColor(resource)
            bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
        end
    elseif cfg.color then
        -- Custom color from GUI
        local r, g, b, a = cfg.color[1], cfg.color[2], cfg.color[3], cfg.color[4] or 1
        bar.StatusBar:SetStatusBarColor(r, g, b, a)
    else
        -- Default resource color
        local color = GetResourceColor(resource)
        bar.StatusBar:SetStatusBarColor(color.r, color.g, color.b)
    end

    -- Update text
    if valueType == "percent" then
        bar.TextValue:SetText(string.format("%.0f%%", displayValue))
    else
        bar.TextValue:SetText(tostring(displayValue))
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

    bar:Show()
end

function ResourceBars:UpdatePowerBarTicks(bar, resource, max)
    local cfg = NephUI.db.profile.powerBar

    -- Hide all ticks first
    for _, tick in ipairs(bar.ticks) do
        tick:Hide()
    end

    if not cfg.showTicks or not tickedPowerTypes[resource] then
        return
    end

    local width = bar:GetWidth()
    local height = bar:GetHeight()
    if width <= 0 or height <= 0 then return end

    local needed = max - 1
    for i = 1, needed do
        local tick = bar.ticks[i]
        if not tick then
            tick = bar:CreateTexture(nil, "OVERLAY")
            tick:SetColorTexture(0, 0, 0, 1)
            bar.ticks[i] = tick
        end

        local x = (i / max) * width
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
NephUI.UpdatePowerBarTicks = function(self, bar, resource, max) return ResourceBars:UpdatePowerBarTicks(bar, resource,
        max) end
