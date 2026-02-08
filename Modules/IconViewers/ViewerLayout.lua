local ADDON_NAME, ns = ...
local NephUI = ns.Addon

local IconViewers = NephUI.IconViewers
if not IconViewers then
    error("NephUI: IconViewers module not initialized! Load IconViewers.lua first.")
end

local ceil = math.ceil
local abs = math.abs

local DIRECTION_RULES = {
    CENTERED_HORIZONTAL = { type = "HORIZONTAL", defaultSecondary = "DOWN", allowed = { UP = true, DOWN = true } },
    LEFT                = { type = "HORIZONTAL", defaultSecondary = "DOWN", allowed = { UP = true, DOWN = true } },
    RIGHT               = { type = "HORIZONTAL", defaultSecondary = "DOWN", allowed = { UP = true, DOWN = true } },
    UP                  = { type = "VERTICAL",   defaultSecondary = "RIGHT", allowed = { LEFT = true, RIGHT = true } },
    DOWN                = { type = "VERTICAL",   defaultSecondary = "RIGHT", allowed = { LEFT = true, RIGHT = true } },
    STATIC              = { type = "STATIC" },
}

IconViewers.__cdmTrackedViewers = IconViewers.__cdmTrackedViewers or {}
local trackedViewers = IconViewers.__cdmTrackedViewers

local function PixelSnap(value)
    return math.max(0, math.floor((value or 0) + 0.5))
end

local function ResetTrackedViewerAnchors()
    if not trackedViewers then return end

    for viewer in pairs(trackedViewers) do
        if viewer and viewer.GetName then
            viewer.__cdmAnchorShiftX = 0
            viewer.__cdmAnchorShiftY = 0
            -- Prevent a post-EditMode snap by skipping the next anchor adjust
            viewer.__cdmSkipNextAnchorAdjust = true
            IconViewers:ApplyViewerLayout(viewer)
        else
            trackedViewers[viewer] = nil
        end
    end
end

local function EnsureEditModeHooks()
    if IconViewers.__cdmEditHooksInstalled then return end

    if not EditModeManagerFrame then
        if IsLoggedIn and IsLoggedIn() then
            if not IconViewers.__cdmEditHookTimer then
                IconViewers.__cdmEditHookTimer = true
                C_Timer.After(0.25, function()
                    IconViewers.__cdmEditHookTimer = nil
                    EnsureEditModeHooks()
                end)
            end
        elseif not IconViewers.__cdmEditHookListener then
            local listener = CreateFrame("Frame")
            listener:RegisterEvent("PLAYER_LOGIN")
            listener:SetScript("OnEvent", function(self)
                if EditModeManagerFrame then
                    EnsureEditModeHooks()
                    self:UnregisterAllEvents()
                    self:SetScript("OnEvent", nil)
                end
            end)
            IconViewers.__cdmEditHookListener = listener
        end
        return
    end

    IconViewers.__cdmEditHooksInstalled = true
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", ResetTrackedViewerAnchors)
end

local function TrackViewer(viewer)
    if not viewer then return end
    trackedViewers[viewer] = true
    EnsureEditModeHooks()
end

local function IsCooldownIconFrame(frame)
    return frame and (frame.icon or frame.Icon) and frame.Cooldown
end

local function IsPlaceholderIcon(iconFrame)
    -- Blizzard creates placeholder icons without cooldownID
    -- Real icons have a cooldownID property set
    if not iconFrame then return true end
    -- Check if cooldownID exists (real icons have this, placeholders don't)
    return iconFrame.cooldownID == nil
end

-- BuffIconCooldownViewer may have icons as direct children or as grandchildren (e.g. inside a scroll frame).
local function CollectBuffIconCooldownViewerIconsInternal(container, shownOnly)
    local icons = {}
    if not container or not container.GetNumChildren then return icons end
    local n = container:GetNumChildren() or 0
    for i = 1, n do
        local child = select(i, container:GetChildren())
        if not child then break end
        if IsCooldownIconFrame(child) and not IsPlaceholderIcon(child) then
            if not shownOnly or child:IsShown() then
                table.insert(icons, child)
            end
        elseif child.GetNumChildren then
            local m = child:GetNumChildren() or 0
            for j = 1, m do
                local grandchild = select(j, child:GetChildren())
                if grandchild and IsCooldownIconFrame(grandchild) and not IsPlaceholderIcon(grandchild) then
                    if not shownOnly or grandchild:IsShown() then
                        table.insert(icons, grandchild)
                    end
                end
            end
        end
    end
    return icons
end

-- For layout: only shown, non-placeholder icons so CENTERED_HORIZONTAL and spacing are correct.
local function CollectBuffIconCooldownViewerIcons(container)
    return CollectBuffIconCooldownViewerIconsInternal(container, true)
end

local function HookBuffIconAuraEvents(viewer, iconFrame)
    if not viewer or not iconFrame or iconFrame.__cdmAuraHooked then return end
    iconFrame.__cdmAuraHooked = true

    local function RequestRescan()
        if not viewer:IsShown() or not IconViewers.RescanViewer then
            return
        end
        if viewer.__cdmRescanPending then
            return
        end
        viewer.__cdmRescanPending = true
        C_Timer.After(0, function()
            viewer.__cdmRescanPending = nil
            if viewer:IsShown() and IconViewers.RescanViewer then
                IconViewers:RescanViewer(viewer)
            end
        end)
    end

    if iconFrame.OnActiveStateChanged then
        hooksecurefunc(iconFrame, "OnActiveStateChanged", RequestRescan)
    end
    if iconFrame.OnUnitAuraAddedEvent then
        hooksecurefunc(iconFrame, "OnUnitAuraAddedEvent", RequestRescan)
    end
    if iconFrame.OnUnitAuraRemovedEvent then
        hooksecurefunc(iconFrame, "OnUnitAuraRemovedEvent", RequestRescan)
    end
end

local function NormalizeDirectionToken(token)
    if not token or token == "" then
        return nil
    end

    local aliases = {
        CENTEREDHORIZONTAL = "CENTERED_HORIZONTAL",
        CENTERHORIZONTAL   = "CENTERED_HORIZONTAL",
        CENTERED           = "CENTERED_HORIZONTAL",
        CENTER             = "CENTERED_HORIZONTAL",
        CENTRED            = "CENTERED_HORIZONTAL",
        CENTRE             = "CENTERED_HORIZONTAL",
    }

    local cleaned = token:gsub("[%s%-_]+", ""):upper()
    return aliases[cleaned] or cleaned
end

local function ClampRowLimit(value)
    if not value or value <= 0 then
        return 0
    end
    return math.floor(value + 0.0001)
end

local function ResolveDirections(viewerName, settings)
    local primary = NormalizeDirectionToken(settings.primaryDirection)
    local secondary = NormalizeDirectionToken(settings.secondaryDirection)

    local legacyDirection = settings.growthDirection
    if not primary and legacyDirection then
        if legacyDirection == "Static" or legacyDirection == "STATIC" then
            primary = "STATIC"
        elseif legacyDirection:match("^Centered Horizontal and") then
            primary = "CENTERED_HORIZONTAL"
            local token = legacyDirection:match("and%s+(.+)$")
            secondary = NormalizeDirectionToken(token)
        elseif legacyDirection == "Centered Horizontal" then
            primary = "CENTERED_HORIZONTAL"
        else
            local p = legacyDirection:match("^(%w+)")
            primary = NormalizeDirectionToken(p)
            local s = legacyDirection:match("and%s+(.+)$")
            secondary = NormalizeDirectionToken(s)
        end
    end

    if not primary and viewerName == "BuffIconCooldownViewer" and settings.rowGrowDirection then
        primary = "CENTERED_HORIZONTAL"
        if type(settings.rowGrowDirection) == "string" and settings.rowGrowDirection:lower() == "up" then
            secondary = "UP"
        else
            secondary = "DOWN"
        end
    end

    primary = primary or "CENTERED_HORIZONTAL"
    local rule = DIRECTION_RULES[primary]
    if not rule then
        primary = "CENTERED_HORIZONTAL"
        rule = DIRECTION_RULES[primary]
    end

    local rowLimit = ClampRowLimit(settings.rowLimit or 0)

    if rule.type ~= "STATIC" and rowLimit > 0 then
        if not secondary or not rule.allowed[secondary] then
            secondary = rule.defaultSecondary
        end
    else
        secondary = nil
    end

    return primary, secondary, rowLimit, rule.type
end

local function ComputeIconDimensions(settings, sizeOverride)
    local baseSize = sizeOverride or settings.iconSize or 32
    local iconSize = baseSize + 0.1
    local aspectRatioValue = 1.0

    if settings.aspectRatioCrop then
        aspectRatioValue = settings.aspectRatioCrop
    elseif settings.aspectRatio then
        local aspectW, aspectH = settings.aspectRatio:match("^(%d+%.?%d*):(%d+%.?%d*)$")
        if aspectW and aspectH then
            aspectRatioValue = tonumber(aspectW) / tonumber(aspectH)
        end
    end

    local iconWidth = iconSize
    local iconHeight = iconSize

    if aspectRatioValue and aspectRatioValue ~= 1.0 then
        if aspectRatioValue > 1.0 then
            iconHeight = iconSize / aspectRatioValue
        elseif aspectRatioValue < 1.0 then
            iconWidth = iconSize * aspectRatioValue
        end
    end

    -- Snap to whole pixels to keep downstream layout widths stable
    return PixelSnap(iconWidth), PixelSnap(iconHeight)
end

local function GetRowIconSize(settings, rowIndex)
    if not settings or not settings.rowIconSizes then
        return nil
    end

    local value = settings.rowIconSizes[rowIndex]
    if type(value) == "string" then
        value = tonumber(value)
    end

    if type(value) == "number" and value > 0 then
        return value
    end

    return nil
end

local function ComputeSpacing(settings, viewerName)
    local spacing = settings.spacing or 4
    -- BuffIconCooldownViewer: use exact spacing (1 = 1 pixel) for CENTERED_HORIZONTAL layout
    if viewerName == "BuffIconCooldownViewer" then
        return PixelSnap(spacing)
    end
    return PixelSnap(spacing + 2)
end

local function BuildDirectionKey(primary, secondary, rowLimit)
    return string.format("%s_%s_%d", primary or "CENTERED_HORIZONTAL", secondary or "NONE", rowLimit or 0)
end

local function BuildAppearanceKey(baseWidth, baseHeight, spacing, rowDimensions)
    local parts = { string.format("%.3f:%.3f:%.3f", baseWidth or 0, baseHeight or 0, spacing or 0) }

    if rowDimensions then
        for i = 1, 3 do
            local dims = rowDimensions[i]
            if dims and dims.width and dims.height then
                parts[#parts + 1] = string.format("r%d:%.3f:%.3f", i, dims.width, dims.height)
            end
        end
    end

    return table.concat(parts, "|")
end

local function PrepareIconOrder(viewerName, icons)
    if viewerName == "BuffIconCooldownViewer" then
        for index, icon in ipairs(icons) do
            if not icon.layoutIndex and not icon:GetID() then
                icon.__cdmCreationOrder = icon.__cdmCreationOrder or index
            end
        end
    end

    -- Only sort if we haven't cached the order or if icon count changed
    local needsSort = true
    if #icons > 0 then
        local cacheKey = tostring(#icons)
        for i, icon in ipairs(icons) do
            local iconKey = tostring(icon.layoutIndex or icon:GetID() or icon.__cdmCreationOrder or 0)
            cacheKey = cacheKey .. "_" .. iconKey
        end

        if icons.__cdmLastSortKey == cacheKey then
            needsSort = false
        else
            icons.__cdmLastSortKey = cacheKey
        end
    end

    if needsSort then
        table.sort(icons, function(a, b)
            local la = a.layoutIndex or a:GetID() or a.__cdmCreationOrder or 0
            local lb = b.layoutIndex or b:GetID() or b.__cdmCreationOrder or 0
            if la == lb then
                return (a.__cdmCreationOrder or 0) < (b.__cdmCreationOrder or 0)
            end
            return la < lb
        end)
    end
end

local function LayoutHorizontal(icons, container, primary, secondary, spacing, rowLimit, getDimensionsForRow)
    local count = #icons
    if count == 0 then return 0, 0, 0 end

    local iconsPerRow = rowLimit > 0 and math.max(1, rowLimit) or count
    local numRows = ceil(count / iconsPerRow)
    local rowDirection = (secondary == "UP") and 1 or -1

    local rowMeta = {}
    local maxRowWidth = 0
    local totalHeight = 0
    for row = 1, numRows do
        local iconWidth, iconHeight = getDimensionsForRow(row)
        local rowStart = (row - 1) * iconsPerRow + 1
        local rowEnd = math.min(row * iconsPerRow, count)
        local rowCount = rowEnd - rowStart + 1
        local rowWidth = rowCount * iconWidth + (rowCount - 1) * spacing
        if rowWidth < iconWidth then
            rowWidth = iconWidth
        end
        maxRowWidth = math.max(maxRowWidth, rowWidth)
        totalHeight = totalHeight + iconHeight

        rowMeta[row] = {
            startIndex = rowStart,
            count = rowCount,
            width = rowWidth,
            iconWidth = iconWidth,
            iconHeight = iconHeight,
        }
    end

    totalHeight = totalHeight + (numRows - 1) * spacing
    -- Start from the top (for DOWN) or bottom (for UP) so row 1 stays fixed without moving the container
    local anchorY
    if rowDirection == -1 then
        anchorY = (totalHeight / 2) - (rowMeta[1].iconHeight / 2)
    else
        anchorY = -(totalHeight / 2) + (rowMeta[1].iconHeight / 2)
    end

    local currentY = anchorY
    for row = 1, numRows do
        local meta = rowMeta[row]
        local rowLeftEdge = -(maxRowWidth / 2) + (meta.iconWidth / 2)
        local rowRightEdge = (maxRowWidth / 2) - (meta.iconWidth / 2)
        local baseX
        if primary == "CENTERED_HORIZONTAL" then
            baseX = -meta.width / 2 + meta.iconWidth / 2
        elseif primary == "RIGHT" then
            baseX = rowLeftEdge
        else -- LEFT
            baseX = rowRightEdge
        end

        for position = 0, meta.count - 1 do
            local icon = icons[meta.startIndex + position]
            local x
            if primary == "LEFT" then
                x = baseX - position * (meta.iconWidth + spacing)
            else
                x = baseX + position * (meta.iconWidth + spacing)
            end

            icon:SetSize(meta.iconWidth, meta.iconHeight)
            icon:SetPoint("CENTER", container, "CENTER", x, currentY)
        end

        local nextMeta = rowMeta[row + 1]
        if nextMeta then
            local step = (meta.iconHeight / 2) + (nextMeta.iconHeight / 2) + spacing
            currentY = currentY + step * rowDirection
        end
    end

    return maxRowWidth, totalHeight, 0
end

local function LayoutVertical(icons, container, primary, secondary, spacing, rowLimit, getDimensionsForRow)
    local count = #icons
    if count == 0 then return 0, 0, 0 end

    local iconsPerColumn = rowLimit > 0 and math.max(1, rowLimit) or count
    local numColumns = ceil(count / iconsPerColumn)
    local columnDirection = (secondary == "LEFT") and -1 or 1
    local verticalDirection = (primary == "UP") and 1 or -1

    local columnMeta = {}
    local maxColumnHeight = 0
    local totalWidth = 0
    for column = 1, numColumns do
        local iconWidth, iconHeight = getDimensionsForRow(column)
        local columnStart = (column - 1) * iconsPerColumn + 1
        local columnEnd = math.min(column * iconsPerColumn, count)
        local columnCount = columnEnd - columnStart + 1
        local columnHeight = columnCount * iconHeight + (columnCount - 1) * spacing

        maxColumnHeight = math.max(maxColumnHeight, columnHeight)
        totalWidth = totalWidth + iconWidth
        if column > 1 then
            totalWidth = totalWidth + spacing
        end

        columnMeta[column] = {
            startIndex = columnStart,
            count = columnCount,
            height = columnHeight,
            iconWidth = iconWidth,
            iconHeight = iconHeight,
        }
    end

    local totalHeight = maxColumnHeight

    -- Start from left (for RIGHT growth) or right (for LEFT growth) so column 1 stays fixed
    local anchorX
    if columnDirection == 1 then
        anchorX = -(totalWidth / 2) + (columnMeta[1].iconWidth / 2)
    else
        anchorX = (totalWidth / 2) - (columnMeta[1].iconWidth / 2)
    end

    local anchorY
    if verticalDirection == -1 then
        anchorY = (totalHeight / 2) - (columnMeta[1].iconHeight / 2)
    else
        anchorY = -(totalHeight / 2) + (columnMeta[1].iconHeight / 2)
    end

    local currentX = anchorX
    for column = 1, numColumns do
        local meta = columnMeta[column]

        local startY = anchorY
        for position = 0, meta.count - 1 do
            local icon = icons[meta.startIndex + position]
            local y = startY + position * (meta.iconHeight + spacing) * verticalDirection
            icon:SetSize(meta.iconWidth, meta.iconHeight)
            icon:SetPoint("CENTER", container, "CENTER", currentX, y)
        end

        local nextMeta = columnMeta[column + 1]
        if nextMeta then
            local step = (meta.iconWidth / 2) + (nextMeta.iconWidth / 2) + spacing
            currentX = currentX + step * columnDirection
        end
    end

    return totalWidth, totalHeight, 0
end

local function AdjustViewerAnchor(viewer, shiftX, shiftY)
    if viewer and viewer.__cdmSkipNextAnchorAdjust then
        viewer.__cdmSkipNextAnchorAdjust = nil
        return
    end

    shiftX = shiftX or 0
    shiftY = shiftY or 0

    local prevX = viewer.__cdmAnchorShiftX or 0
    local prevY = viewer.__cdmAnchorShiftY or 0
    local deltaX = shiftX - prevX
    local deltaY = shiftY - prevY

    if deltaX == 0 and deltaY == 0 then return end
    if InCombatLockdown() then return end

    local point, relativeTo, relativePoint, xOfs, yOfs = viewer:GetPoint(1)
    if not point then return end

    viewer:ClearAllPoints()
    viewer:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) - deltaX, (yOfs or 0) - deltaY)
    viewer.__cdmAnchorShiftX = shiftX
    viewer.__cdmAnchorShiftY = shiftY
end

function IconViewers:ApplyViewerLayout(viewer)
    if not viewer or not viewer.GetName then return end

    local name = viewer:GetName()
    local settings = NephUI.db.profile.viewers[name]
    if not settings or not settings.enabled then return end

    TrackViewer(viewer)

    local container = viewer.viewerFrame or viewer
    local icons
    if name == "BuffIconCooldownViewer" then
        icons = CollectBuffIconCooldownViewerIcons(container)
    else
        icons = {}
        for _, child in ipairs({ container:GetChildren() }) do
            if IsCooldownIconFrame(child) and child:IsShown() then
                table.insert(icons, child)
            end
        end
    end

    local count = #icons
    if count == 0 then return end

    if viewer.__cdmLayoutRunning then
        return
    end
    viewer.__cdmLayoutRunning = true
    local function finishLayout()
        viewer.__cdmLayoutRunning = nil
    end

    PrepareIconOrder(name, icons)

    local baseIconWidth, baseIconHeight = ComputeIconDimensions(settings)
    local spacing = ComputeSpacing(settings, name)
    local primary, secondary, rowLimit, layoutType = ResolveDirections(name, settings)
    local directionKey = BuildDirectionKey(primary, secondary, rowLimit)
    local rowDimensions = {}
    local function GetDimensionsForRow(rowIndex)
        if not rowDimensions[rowIndex] then
            local overrideSize = GetRowIconSize(settings, rowIndex)
            local w, h = ComputeIconDimensions(settings, overrideSize)
            rowDimensions[rowIndex] = { width = w, height = h }
        end
        return rowDimensions[rowIndex].width, rowDimensions[rowIndex].height
    end
    for preload = 1, 3 do
        GetDimensionsForRow(preload)
    end
    local appearanceKey = BuildAppearanceKey(baseIconWidth, baseIconHeight, spacing, rowDimensions)

    if name == "BuffIconCooldownViewer" and primary == "STATIC" then
        local rowWidth, rowHeight = GetDimensionsForRow(1)
        for _, icon in ipairs(icons) do
            icon:SetWidth(rowWidth)
            icon:SetHeight(rowHeight)
            icon:SetSize(rowWidth, rowHeight)
        end
        viewer.__cdmLastGrowthDirection = directionKey
        viewer.__cdmLastAppearanceKey = appearanceKey
        AdjustViewerAnchor(viewer, 0, 0)
        finishLayout()
        return
    end

    for _, icon in ipairs(icons) do
        icon:ClearAllPoints()
    end

    local totalWidth, totalHeight, anchorShift
    if layoutType == "VERTICAL" then
        totalWidth, totalHeight, anchorShift = LayoutVertical(icons, container, primary, secondary, spacing, rowLimit, GetDimensionsForRow)
    else
        totalWidth, totalHeight, anchorShift = LayoutHorizontal(icons, container, primary, secondary, spacing, rowLimit, GetDimensionsForRow)
    end

    local snappedWidth = PixelSnap(totalWidth)
    local snappedHeight = PixelSnap(totalHeight)
    viewer.__cdmIconWidth = snappedWidth
    viewer.__cdmIconHeight = snappedHeight
    viewer.__cdmLastGrowthDirection = directionKey
    viewer.__cdmLastAppearanceKey = appearanceKey

    if not InCombatLockdown() then
        viewer.__cdmLayoutSuppressed = (viewer.__cdmLayoutSuppressed or 0) + 1
        viewer:SetSize(snappedWidth, snappedHeight)
        viewer.__cdmLayoutSuppressed = viewer.__cdmLayoutSuppressed - 1
        if viewer.__cdmLayoutSuppressed <= 0 then
            viewer.__cdmLayoutSuppressed = nil
        end
    end

    finishLayout()
end

function IconViewers:RescanViewer(viewer)
    if not viewer or not viewer.GetName then return end

    local name = viewer:GetName()
    local settings = NephUI.db.profile.viewers[name]
    if not settings or not settings.enabled then return end

    TrackViewer(viewer)

    local container = viewer.viewerFrame or viewer
    local icons = {}
    local changed = false
    local inCombat = InCombatLockdown()

    if name == "BuffIconCooldownViewer" then
        icons = CollectBuffIconCooldownViewerIconsInternal(container, false)
    else
        for _, child in ipairs({ container:GetChildren() }) do
            if IsCooldownIconFrame(child) and child:IsShown() then
                table.insert(icons, child)
            end
        end
    end

    for _, child in ipairs(icons) do
        if name == "BuffIconCooldownViewer" then
            HookBuffIconAuraEvents(viewer, child)
        end

        if not child.__cdmSkinned and not child.__cdmSkinPending then
            child.__cdmSkinPending = true

            if inCombat then
                NephUI.__cdmPendingIcons = NephUI.__cdmPendingIcons or {}
                NephUI.__cdmPendingIcons[child] = { icon = child, settings = settings, viewer = viewer }

                if not NephUI.__cdmIconSkinEventFrame then
                    local eventFrame = CreateFrame("Frame")
                    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                    eventFrame:SetScript("OnEvent", function(self)
                        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                        if IconViewers.ProcessPendingIcons then
                            IconViewers:ProcessPendingIcons()
                        end
                    end)
                    NephUI.__cdmIconSkinEventFrame = eventFrame
                end
                NephUI.__cdmIconSkinEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            else
                local success = pcall(self.SkinIcon, self, child, settings)
                if success then
                    child.__cdmSkinPending = nil
                end
            end
            changed = true
        end
    end

    PrepareIconOrder(name, icons)
    local count = #icons

    local shownIcons = icons
    local shownCount = count
    if name == "BuffIconCooldownViewer" then
        shownIcons = {}
        for _, icon in ipairs(icons) do
            if icon and icon.IsShown and icon:IsShown() then
                shownIcons[#shownIcons + 1] = icon
            end
        end
        shownCount = #shownIcons
    end

    -- Cache expensive computations
    local cacheKey = string.format("%s_%s_%s", name, tostring(settings.iconSize or 32), tostring(settings.spacing or 4))
    local cached = viewer.__cdmLayoutCache
    if not cached or cached.cacheKey ~= cacheKey then
        local baseIconWidth, baseIconHeight = ComputeIconDimensions(settings)
        cached = {
            cacheKey = cacheKey,
            baseIconWidth = baseIconWidth,
            baseIconHeight = baseIconHeight,
            spacing = ComputeSpacing(settings, name),
            directions = {ResolveDirections(name, settings)},
            rowDimensions = {}
        }
        for preload = 1, 3 do
            local overrideSize = GetRowIconSize(settings, preload)
            local w, h = ComputeIconDimensions(settings, overrideSize)
            cached.rowDimensions[preload] = { width = w, height = h }
        end
        cached.appearanceKey = BuildAppearanceKey(cached.baseIconWidth, cached.baseIconHeight, cached.spacing, cached.rowDimensions)
        viewer.__cdmLayoutCache = cached
    end

    local baseIconWidth, baseIconHeight = cached.baseIconWidth, cached.baseIconHeight
    local spacing = cached.spacing
    local primary, secondary, rowLimit = unpack(cached.directions)
    local directionKey = BuildDirectionKey(primary, secondary, rowLimit)
    local rowDimensions = cached.rowDimensions
    local appearanceKey = cached.appearanceKey

    if viewer.__cdmLastGrowthDirection ~= directionKey then
        viewer.__cdmLastGrowthDirection = directionKey
        changed = true
    end

    if viewer.__cdmLastAppearanceKey ~= appearanceKey then
        viewer.__cdmLastAppearanceKey = appearanceKey
        changed = true
    end

    if viewer.__cdmIconCount ~= count then
        viewer.__cdmIconCount = count
        changed = true
    end

    if name == "BuffIconCooldownViewer" and viewer.__cdmShownIconCount ~= shownCount then
        viewer.__cdmShownIconCount = shownCount
        changed = true
    end

    -- Simplified spacing check - only check first few icons and cache result
    if name == "BuffIconCooldownViewer" and not changed and shownCount > 1 then
        local spacingCheckKey = string.format("%d_%d", shownCount, math.floor(time() / 5)) -- Check every 5 seconds
        if viewer.__cdmLastSpacingCheck ~= spacingCheckKey then
            viewer.__cdmLastSpacingCheck = spacingCheckKey
            -- Only check first 3 icon pairs for performance
            for i = 1, min(3, shownCount - 1) do
                local iconA = shownIcons[i]
                local iconB = shownIcons[i + 1]
                if iconA and iconB then
                    local x1 = iconA:GetCenter()
                    local x2 = iconB:GetCenter()
                    if x1 and x2 then
                        local widthA = (iconA.GetWidth and iconA:GetWidth()) or baseIconWidth
                        local expectedSpacing = widthA + spacing
                        local actualSpacing = abs(x2 - x1)
                        if abs(actualSpacing - expectedSpacing) > 2 then -- Increased tolerance
                            changed = true
                            break
                        end
                    end
                end
            end
        end
    end

    if changed then
        self:ApplyViewerLayout(viewer)

        if NephUI.ResourceBars and NephUI.ResourceBars.UpdatePowerBar then
            NephUI.ResourceBars:UpdatePowerBar()
        end
        if NephUI.ResourceBars and NephUI.ResourceBars.UpdateSecondaryPowerBar then
            NephUI.ResourceBars:UpdateSecondaryPowerBar()
        end
    end
end

NephUI.ApplyViewerLayout = function(self, viewer) return IconViewers:ApplyViewerLayout(viewer) end
NephUI.RescanViewer = function(self, viewer) return IconViewers:RescanViewer(viewer) end
