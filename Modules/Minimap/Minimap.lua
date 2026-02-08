local ADDON_NAME, ns = ...
local NephUI = ns.Addon

NephUI.Minimap = NephUI.Minimap or {}
local MinimapModule = NephUI.Minimap

local Minimap = _G.Minimap
local backdropFrame
local clockDisplay
local clockTimer
local fpsDisplay
local fpsTimer
local zoneTextFrame
local mailFrameRef
local trackingFrameHooked = false

-- Helper function to convert anchor position to SetPoint format
local function GetAnchorPoint(anchor)
    local anchorMap = {
        ["Top"] = "TOP",
        ["Top Right"] = "TOPRIGHT",
        ["Top Left"] = "TOPLEFT",
        ["Right"] = "RIGHT",
        ["Left"] = "LEFT",
        ["Center"] = "CENTER",
        ["Bottom Right"] = "BOTTOMRIGHT",
        ["Bottom"] = "BOTTOM",
        ["Bottom Left"] = "BOTTOMLEFT",
    }
    return anchorMap[anchor] or "BOTTOM"
end

local function GetClassColor()
    local _, class = UnitClass("player")
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b, 1
    end
    return 1, 1, 1, 1
end

-- Create backdrop frame for minimap border
local function CreateBackdrop()
    if backdropFrame then return end
    
    backdropFrame = CreateFrame("Frame", nil, UIParent)
    backdropFrame:SetFrameStrata("BACKGROUND")
    backdropFrame:SetFrameLevel(1)
    backdropFrame:SetFixedFrameStrata(true)
    backdropFrame:SetFixedFrameLevel(true)
    
    local backdrop = backdropFrame:CreateTexture(nil, "BACKGROUND")
    backdrop:SetPoint("CENTER", Minimap, "CENTER")
    backdropFrame.backdrop = backdrop
end

-- Update backdrop size and appearance
local function UpdateBackdrop()
    if not backdropFrame or not Minimap then return end
    
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then return end
    
    local fullSize = db.size + db.borderSize
    local backdrop = backdropFrame.backdrop
    
    if backdrop then
        backdrop:SetSize(fullSize, fullSize)
        backdrop:SetColorTexture(0, 0, 0, 1)
        
        -- Create mask for shape
        if not backdropFrame.mask then
            backdropFrame.mask = backdropFrame:CreateMaskTexture()
            backdropFrame.mask:SetAllPoints(backdrop)
            backdropFrame.mask:SetParent(backdropFrame)
            backdrop:AddMaskTexture(backdropFrame.mask)
        end
        
        local maskTexture = "Interface\\BUTTONS\\WHITE8X8"
        backdropFrame.mask:SetTexture(maskTexture)
    end
end

-- Preserve Layout methods to prevent errors when Blizzard code calls them
local function PreserveLayoutMethods()
    -- Preserve Layout method on Minimap frame itself
    if Minimap then
        if type(Minimap.Layout) ~= "function" then
            -- Create a stub Layout method to prevent errors
            Minimap.Layout = function() end
        end
    end
    
    if MinimapCluster then
        -- Preserve Layout method if it exists to prevent errors when Blizzard code calls it
        if type(MinimapCluster.Layout) ~= "function" then
            -- Create a stub Layout method to prevent errors
            MinimapCluster.Layout = function() end
        end
        
        -- Also ensure IndicatorFrame has a Layout method if it exists
        if MinimapCluster.IndicatorFrame then
            if type(MinimapCluster.IndicatorFrame.Layout) ~= "function" then
                MinimapCluster.IndicatorFrame.Layout = function() end
            end
        end
    end
end

-- Hide Blizzard minimap elements
local function HideBlizzardElements()
    if MinimapBackdrop then
        MinimapBackdrop:SetParent(UIParent)
        MinimapBackdrop:Hide()
        hooksecurefunc(MinimapBackdrop, "SetParent", function(self)
            if self:GetParent() ~= UIParent then
                self:SetParent(UIParent)
                self:Hide()
            end
        end)
    end
    
    if MinimapBorder then
        MinimapBorder:SetParent(UIParent)
        MinimapBorder:Hide()
        hooksecurefunc(MinimapBorder, "SetParent", function(self)
            if self:GetParent() ~= UIParent then
                self:SetParent(UIParent)
                self:Hide()
            end
        end)
    end
    
    if MinimapCluster then
        -- Extract mail frame reference before hiding MinimapCluster
        if MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame then
            mailFrameRef = MinimapCluster.IndicatorFrame.MailFrame
        elseif MiniMapMailFrame then
            mailFrameRef = MiniMapMailFrame
        elseif MinimapCluster.MailFrame then
            mailFrameRef = MinimapCluster.MailFrame
        end
        
        -- Preserve Layout methods before hiding to prevent errors
        PreserveLayoutMethods()
        
        MinimapCluster:SetParent(UIParent)
        MinimapCluster:Hide()
        hooksecurefunc(MinimapCluster, "SetParent", function(self)
            if self:GetParent() ~= UIParent then
                self:SetParent(UIParent)
                self:Hide()
            end
            -- Re-preserve Layout methods after reparenting
            PreserveLayoutMethods()
        end)
        hooksecurefunc(MinimapCluster, "Show", function(self)
            self:Hide()
        end)
    end
    
    if MinimapNorthTag then
        MinimapNorthTag:SetParent(UIParent)
        MinimapNorthTag:Hide()
    end
    
    if MinimapBorderTop then
        MinimapBorderTop:SetParent(UIParent)
        MinimapBorderTop:Hide()
    end
end

-- Setup minimap shape
local function ApplyMinimapShape()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then return end
    
    local maskTexture = "Interface\\BUTTONS\\WHITE8X8"
    
    Minimap:SetMaskTexture(maskTexture)
    
    if HybridMinimap then
        HybridMinimap.MapCanvas:SetUseMaskTexture(false)
        if HybridMinimap.CircleMask then
            HybridMinimap.CircleMask:SetTexture(maskTexture)
        end
        HybridMinimap.MapCanvas:SetUseMaskTexture(true)
    end
end

-- Hide blob rings (archaeology/quest rings)
local function HideBlobRings()
    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetArchBlobRingAlpha(0)
    Minimap:SetQuestBlobRingScalar(0)
    Minimap:SetQuestBlobRingAlpha(0)
end

-- Create clock display
local function CreateClock()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled or not db.clock or not db.clock.enabled then
        if clockDisplay then
            clockDisplay:SetParent(UIParent)
            clockDisplay:Hide()
        end
        return
    end
    
    if not clockDisplay then
        clockDisplay = Minimap:CreateFontString(nil, "OVERLAY")
        clockDisplay:SetJustifyH("CENTER")
    end
    
    -- Update font size
    clockDisplay:SetFont(NephUI:GetGlobalFont(), db.clock.fontSize or 12, "OUTLINE")
    
    -- Set color
    if db.clock.useClassColor then
        clockDisplay:SetTextColor(GetClassColor())
    else
        local color = db.clock.color or {1, 1, 1, 1}
        clockDisplay:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    
    clockDisplay:SetParent(Minimap)
    clockDisplay:ClearAllPoints()
    local anchor = GetAnchorPoint(db.clock.anchor or "Bottom")
    local relativePoint = GetAnchorPoint(db.clock.anchor or "Bottom")
    clockDisplay:SetPoint(anchor, backdropFrame and backdropFrame.backdrop or Minimap, relativePoint, db.clock.offsetX or 0, db.clock.offsetY or -4)
    clockDisplay:Show()
    
    -- Cancel existing timer if any
    if clockTimer then
        clockTimer:Cancel()
        clockTimer = nil
    end
    
    -- Update clock
    local function UpdateClock()
        if not clockDisplay or not clockDisplay:IsShown() then return end
        
        local hour, minute
        local useLocalTime = db.clock.timeSource == "local"
        if db.clock.timeSource == nil then
            useLocalTime = GetCVarBool("timeMgrUseLocalTime")
        end
        
        if useLocalTime then
            hour, minute = tonumber(date("%H")), tonumber(date("%M"))
        else
            hour, minute = GetGameTime()
        end
        
        local useMilitaryTime = db.clock.useMilitaryTime
        if useMilitaryTime == nil then
            useMilitaryTime = GetCVarBool("timeMgrUseMilitaryTime")
        end
        
        if useMilitaryTime then
            clockDisplay:SetFormattedText(TIMEMANAGER_TICKER_24HOUR, hour, minute)
        else
            local suffix = hour >= 12 and TIMEMANAGER_PM or TIMEMANAGER_AM
            if hour == 0 then
                hour = 12
            elseif hour > 12 then
                hour = hour - 12
            end
            clockDisplay:SetText(string.format("%d:%02d %s", hour, minute, suffix))
        end
        
        -- Update every minute (60 seconds)
        clockTimer = C_Timer.NewTimer(60, UpdateClock)
    end
    
    UpdateClock()
end

-- Create FPS display
local function CreateFPS()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled or not db.fps or not db.fps.enabled then
        if fpsDisplay then
            fpsDisplay:SetParent(UIParent)
            fpsDisplay:Hide()
        end
        return
    end
    
    if not fpsDisplay then
        fpsDisplay = Minimap:CreateFontString(nil, "OVERLAY")
        fpsDisplay:SetJustifyH("CENTER")
    end
    
    -- Update font size
    fpsDisplay:SetFont(NephUI:GetGlobalFont(), db.fps.fontSize or 12, "OUTLINE")
    
    -- Set color
    if db.fps.useClassColor then
        fpsDisplay:SetTextColor(GetClassColor())
    else
        local color = db.fps.color or {1, 1, 1, 1}
        fpsDisplay:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    
    fpsDisplay:SetParent(Minimap)
    fpsDisplay:ClearAllPoints()
    local anchor = GetAnchorPoint(db.fps.anchor or "Bottom")
    local relativePoint = GetAnchorPoint(db.fps.anchor or "Bottom")
    fpsDisplay:SetPoint(anchor, backdropFrame and backdropFrame.backdrop or Minimap, relativePoint, db.fps.offsetX or 0, db.fps.offsetY or -20)
    fpsDisplay:Show()
    
    -- Cancel existing timer if any
    if fpsTimer then
        fpsTimer:Cancel()
        fpsTimer = nil
    end
    
    -- Update FPS
    local function UpdateFPS()
        if not fpsDisplay or not fpsDisplay:IsShown() then return end
        
        -- Get current profile's database to avoid stale closure references
        local currentDb = NephUI.db.profile.minimap
        if not currentDb or not currentDb.fps or not currentDb.fps.enabled then
            if fpsDisplay then
                fpsDisplay:SetParent(UIParent)
                fpsDisplay:Hide()
            end
            if fpsTimer then
                fpsTimer:Cancel()
                fpsTimer = nil
            end
            return
        end
        
        local fps = math.floor(GetFramerate())
        if currentDb.fps.showPing then
            local _, _, _, latencyHome, latencyWorld = GetNetStats()
            local ping = currentDb.fps.pingSource == "world" and latencyWorld or latencyHome
            fpsDisplay:SetText(string.format("%d FPS %d MS", fps, ping or 0))
        else
            fpsDisplay:SetText(string.format("%d FPS", fps))
        end
        
        -- Update at configured frequency
        local updateFrequency = currentDb.fps.updateFrequency or 2.0
        fpsTimer = C_Timer.NewTimer(updateFrequency, UpdateFPS)
    end
    
    UpdateFPS()
end

-- Create custom zone text with PVP colors
local function CreateZoneText()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled or not db.zoneText or not db.zoneText.enabled then
        if MinimapZoneTextButton then
            MinimapZoneTextButton:Hide()
        end
        if zoneTextFrame then
            zoneTextFrame:Hide()
        end
        return
    end
    
    -- Hide default zone text button
    if MinimapZoneTextButton then
        MinimapZoneTextButton:Hide()
    end
    
    -- Update zone text function (defined outside if block so it's always accessible)
    local function UpdateZoneText()
        if not zoneTextFrame or not zoneTextFrame.font then return end
        
        local text = GetMinimapZoneText()
        zoneTextFrame.font:SetText(text)
        
        local color
        if db.zoneText.useCustomColor and db.zoneText.color then
            color = db.zoneText.color
        else
            local pvpType = C_PvP and C_PvP.GetZonePVPInfo() or GetZonePVPInfo()
            if pvpType == "sanctuary" then
                color = db.zoneText.colorSanctuary or {0.41, 0.8, 0.94, 1}
            elseif pvpType == "arena" then
                color = db.zoneText.colorArena or {1, 0.1, 0.1, 1}
            elseif pvpType == "friendly" then
                color = db.zoneText.colorFriendly or {0.1, 1, 0.1, 1}
            elseif pvpType == "hostile" then
                color = db.zoneText.colorHostile or {1, 0.1, 0.1, 1}
            elseif pvpType == "contested" then
                color = db.zoneText.colorContested or {1, 0.7, 0, 1}
            else
                color = db.zoneText.colorNormal or {1, 0.82, 0, 1}
            end
        end
        
        zoneTextFrame.font:SetTextColor(unpack(color))
    end
    
    -- Create our own zone text frame
    if not zoneTextFrame then
        zoneTextFrame = CreateFrame("Button", nil, Minimap)
        local zoneTextFont = zoneTextFrame:CreateFontString(nil, "OVERLAY")
        zoneTextFont:SetAllPoints(zoneTextFrame)
        zoneTextFont:SetJustifyH("CENTER")
        zoneTextFrame.font = zoneTextFont
        
        zoneTextFrame:EnableMouse(true)
        zoneTextFrame:RegisterForClicks("AnyUp")
        
        -- Tooltip on enter
        zoneTextFrame:SetScript("OnEnter", function(self)
            local tooltip = GameTooltip
            tooltip:SetOwner(self, "ANCHOR_LEFT")
            
            local pvpType, _, factionName = C_PvP and C_PvP.GetZonePVPInfo() or GetZonePVPInfo()
            local zoneName = GetZoneText()
            local subzoneName = GetSubZoneText()
            
            if subzoneName == zoneName then
                subzoneName = ""
            end
            
            tooltip:AddLine(zoneName, 1, 1, 1)
            
            if pvpType == "sanctuary" then
                local c = db.zoneText.colorSanctuary or {0.41, 0.8, 0.94, 1}
                if subzoneName ~= "" then tooltip:AddLine(subzoneName, unpack(c)) end
                tooltip:AddLine(SANCTUARY_TERRITORY, unpack(c))
            elseif pvpType == "arena" then
                local c = db.zoneText.colorArena or {1, 0.1, 0.1, 1}
                if subzoneName ~= "" then tooltip:AddLine(subzoneName, unpack(c)) end
                tooltip:AddLine(FREE_FOR_ALL_TERRITORY, unpack(c))
            elseif pvpType == "friendly" then
                local c = db.zoneText.colorFriendly or {0.1, 1, 0.1, 1}
                if subzoneName ~= "" then tooltip:AddLine(subzoneName, unpack(c)) end
                if factionName and factionName ~= "" then
                    tooltip:AddLine((FACTION_CONTROLLED_TERRITORY):format(factionName), unpack(c))
                end
            elseif pvpType == "hostile" then
                local c = db.zoneText.colorHostile or {1, 0.1, 0.1, 1}
                if subzoneName ~= "" then tooltip:AddLine(subzoneName, unpack(c)) end
                if factionName and factionName ~= "" then
                    tooltip:AddLine((FACTION_CONTROLLED_TERRITORY):format(factionName), unpack(c))
                end
            elseif pvpType == "contested" then
                local c = db.zoneText.colorContested or {1, 0.7, 0, 1}
                if subzoneName ~= "" then tooltip:AddLine(subzoneName, unpack(c)) end
                tooltip:AddLine(CONTESTED_TERRITORY, unpack(c))
            else
                local c = db.zoneText.colorNormal or {1, 0.82, 0, 1}
                if subzoneName ~= "" then tooltip:AddLine(subzoneName, unpack(c)) end
            end
            
            tooltip:Show()
        end)
        
        zoneTextFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        zoneTextFrame:RegisterEvent("ZONE_CHANGED")
        zoneTextFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
        zoneTextFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        zoneTextFrame:SetScript("OnEvent", UpdateZoneText)
    end
    
    -- Update font size and frame height
    local fontSize = db.zoneText.fontSize or 14
    zoneTextFrame:SetHeight(fontSize + 1)
    if zoneTextFrame.font then
        zoneTextFrame.font:SetFont(NephUI:GetGlobalFont(), fontSize, "OUTLINE")
    end
    
    zoneTextFrame:Show()
    zoneTextFrame:ClearAllPoints()
    local minimapWidth = Minimap:GetWidth()
    zoneTextFrame:SetWidth(minimapWidth and minimapWidth > 0 and (minimapWidth - 10) or 200)
    -- Position using anchor
    local anchor = GetAnchorPoint(db.zoneText.anchor or "Top")
    local relativePoint = GetAnchorPoint(db.zoneText.anchor or "Top")
    zoneTextFrame:SetPoint(anchor, Minimap, relativePoint, db.zoneText.offsetX or 0, db.zoneText.offsetY or -5)
    
    -- Update zone text color immediately
    UpdateZoneText()
end

-- Manage Blizzard buttons
local function ManageBlizzardButtons()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then return end
    
    -- Zoom buttons
    if Minimap.ZoomIn and Minimap.ZoomOut then
        if db.hideZoomButtons then
            Minimap.ZoomIn:Hide()
            Minimap.ZoomOut:Hide()
        else
            Minimap.ZoomIn:Show()
            Minimap.ZoomOut:Show()
            -- Prevent auto-hide
            local fakeMouseOver = function() return true end
            Minimap.ZoomIn.IsMouseOver = fakeMouseOver
            Minimap.ZoomOut.IsMouseOver = fakeMouseOver
        end
    end
    
    -- Tracking button
    local trackingFrame = MinimapCluster and MinimapCluster.Tracking
    if trackingFrame then
        trackingFrame:SetParent(Minimap)
        
        -- Hook Show only once to maintain alpha control
        if not trackingFrameHooked then
            hooksecurefunc(trackingFrame, "Show", function(self)
                local db = NephUI.db.profile.minimap
                if db and db.hideTrackingButton then
                    self:SetAlpha(0)
                else
                    self:SetAlpha(1)
                end
            end)
            trackingFrameHooked = true
        end
        
        -- Always keep frame shown, control visibility with alpha
        -- Only call Show() if it's not already shown to avoid triggering hooks unnecessarily
        if not trackingFrame:IsShown() then
            trackingFrame:Show()
        end
        
        -- Set alpha based on setting
        if db.hideTrackingButton then
            trackingFrame:SetAlpha(0)
        else
            trackingFrame:SetAlpha(1)
        end
    end
    
    local mailFrame = mailFrameRef
    if not mailFrame then
        if MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame then
            mailFrame = MinimapCluster.IndicatorFrame.MailFrame
        elseif _G.MiniMapMailFrame then
            mailFrame = _G.MiniMapMailFrame
        end
    end
    
    -- Update stored reference if we found it
    if mailFrame and not mailFrameRef then
        mailFrameRef = mailFrame
    end
    
    if mailFrame then
        if db.hideMailButton then
            mailFrame:SetParent(UIParent)
            mailFrame:Hide()
            hooksecurefunc(mailFrame, "Show", function(self)
                self:Hide()
            end)
        else
            mailFrame:SetParent(Minimap)
            
            -- Ensure it's above the minimap
            mailFrame:SetFrameStrata("MEDIUM")
            mailFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
            
            -- Ensure alpha is visible
            mailFrame:SetAlpha(1)
            
            -- Ensure child elements are visible (like MailIcon)
            if mailFrame.MailIcon then
                mailFrame.MailIcon:SetAlpha(1)
                mailFrame.MailIcon:Show()
            end
            
            -- Position the mail icon using configured settings
            mailFrame:ClearAllPoints()
            local mailAnchor = GetAnchorPoint((db.mailIcon and db.mailIcon.anchor) or "Top Left")
            local offsetX = (db.mailIcon and db.mailIcon.offsetX) or 3
            local offsetY = (db.mailIcon and db.mailIcon.offsetY) or -3
            mailFrame:SetPoint(mailAnchor, Minimap, mailAnchor, offsetX, offsetY)
            
            -- Let the mail frame manage its own visibility based on mail status
            mailFrame:Show()
        end
    end
    
    -- Calendar button
    if GameTimeFrame then
        GameTimeFrame:SetParent(Minimap)
        if db.hideCalendarButton then
            GameTimeFrame:Hide()
            hooksecurefunc(GameTimeFrame, "Show", function(self)
                self:Hide()
            end)
        else
            GameTimeFrame:Show()
        end
    end
    
    -- Difficulty icon - reparent to Minimap since MinimapCluster is hidden
    local difficultyFrame = MinimapCluster and MinimapCluster.InstanceDifficulty
    if difficultyFrame then
        difficultyFrame:SetParent(Minimap)
        if db.hideDifficultyIcon then
            difficultyFrame:Hide()
        else
            difficultyFrame:Show()
            -- Position the difficulty icon
            difficultyFrame:ClearAllPoints()
            local iconAnchor = GetAnchorPoint((db.difficultyIcon and db.difficultyIcon.anchor) or "Top Right")
            local offsetX = (db.difficultyIcon and db.difficultyIcon.offsetX) or -5
            local offsetY = (db.difficultyIcon and db.difficultyIcon.offsetY) or -5
            difficultyFrame:SetPoint(iconAnchor, Minimap, iconAnchor, offsetX, offsetY)
        end
    end
    
    -- Missions/garrison buttons - handle both expansion and garrison buttons
    if ExpansionLandingPageMinimapButton then
        -- Keep it visible by default; only hide when the user explicitly requests it
        ExpansionLandingPageMinimapButton:SetParent(Minimap)
        ExpansionLandingPageMinimapButton:SetFrameStrata("MEDIUM")
        ExpansionLandingPageMinimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 10)

        if db.hideMissionsButton then
            ExpansionLandingPageMinimapButton:Hide()
        else
            ExpansionLandingPageMinimapButton:Show()
            local offsetX = (db.missionsButton and db.missionsButton.offsetX) or 0
            local offsetY = (db.missionsButton and db.missionsButton.offsetY) or 0
            ExpansionLandingPageMinimapButton:ClearAllPoints()
            ExpansionLandingPageMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", offsetX, offsetY)
        end
    end

    -- Handle GarrisonLandingPageMinimapButton if it exists
    if GarrisonLandingPageMinimapButton then
        if db.hideMissionsButton then
            GarrisonLandingPageMinimapButton:Hide()
        else
            GarrisonLandingPageMinimapButton:Show()
        end
    end
    
    -- Addon compartment
    if AddonCompartmentFrame then
        AddonCompartmentFrame:SetParent(Minimap)
        if db.hideAddonCompartment then
            AddonCompartmentFrame:Hide()
            hooksecurefunc(AddonCompartmentFrame, "Show", function(self)
                self:Hide()
            end)
        else
            AddonCompartmentFrame:Show()
        end
    end
end

-- Setup minimap dragging
local function SetupDragging()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then return end
    
    Minimap:ClearAllPoints()
    Minimap:SetPoint(db.position[1] or "CENTER", UIParent, db.position[2] or "CENTER", db.position[3] or 0, db.position[4] or 0)
    
    if not db.lock then
        Minimap:RegisterForDrag("LeftButton")
        Minimap:SetMovable(true)
        Minimap:SetClampedToScreen(true)
        
        Minimap:SetScript("OnDragStart", function()
            if Minimap:IsMovable() then
                Minimap:StartMoving()
            end
        end)
        
        Minimap:SetScript("OnDragStop", function()
            Minimap:StopMovingOrSizing()
            local point, relativeTo, relativePoint, x, y = Minimap:GetPoint()
            db.position[1] = point or "CENTER"
            db.position[2] = relativePoint or "CENTER"
            db.position[3] = x or 0
            db.position[4] = y or 0
        end)
    else
        Minimap:SetMovable(false)
        Minimap:RegisterForDrag()
    end
end

-- Setup mouse wheel zoom
local function SetupMouseWheelZoom()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled or not db.mouseWheelZoom then return end
    
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            if Minimap.ZoomIn then
                Minimap.ZoomIn:Click()
            end
        elseif delta < 0 then
            if Minimap.ZoomOut then
                Minimap.ZoomOut:Click()
            end
        end
    end)
end

-- Setup minimap click handlers for tracker and calendar
local function SetupMinimapClicks()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then return end
    
    -- Get the original OnMouseUp script if it exists
    local originalOnMouseUp = Minimap:GetScript("OnMouseUp")
    
    Minimap:SetScript("OnMouseUp", function(self, button)
        -- Right-click opens tracker menu
        if button == "RightButton" then
            local trackingButton = MinimapCluster and MinimapCluster.Tracking and MinimapCluster.Tracking.Button
            if trackingButton and trackingButton.OpenMenu then
                trackingButton:OpenMenu()
            end
            return
        end
        
        -- Middle-click opens calendar
        if button == "MiddleButton" then
            if GameTimeFrame then
                GameTimeFrame:Click()
            end
            return
        end
        
        -- Call original handler for other buttons (like LeftButton)
        if originalOnMouseUp then
            originalOnMouseUp(self, button)
        end
    end)
end

-- Setup auto zoom
local function SetupAutoZoom()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled or not db.autoZoom then return end
    
    local zoomTimer
    local function AutoZoomOut()
        if zoomTimer then
            zoomTimer:Cancel()
        end
        
        zoomTimer = C_Timer.NewTimer(10, function()
            Minimap:SetZoom(0)
            if Minimap.ZoomIn then Minimap.ZoomIn:Enable() end
            if Minimap.ZoomOut then Minimap.ZoomOut:Disable() end
        end)
    end
    
    if Minimap.ZoomIn then
        Minimap.ZoomIn:HookScript("OnClick", AutoZoomOut)
    end
    if Minimap.ZoomOut then
        Minimap.ZoomOut:HookScript("OnClick", AutoZoomOut)
    end
end

-- Set minimap shape function for other addons
local function SetMinimapShapeFunction()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then return end
    
    if GetMinimapShape then
        GetMinimapShape = function()
            return "SQUARE"
        end
    end
end

function MinimapModule:Initialize()
    if not Minimap then return end
    
    -- Preserve Layout methods early to prevent errors
    PreserveLayoutMethods()
    
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then return end
    
    -- Setup minimap frame
    Minimap:SetFixedFrameStrata(true)
    Minimap:SetFixedFrameLevel(true)
    Minimap:SetParent(UIParent)
    
    if Minimap:GetFrameStrata() ~= "LOW" then
        Minimap:SetFrameStrata("LOW")
    end
    if Minimap:GetFrameLevel() ~= 2 then
        Minimap:SetFrameLevel(2)
    end
    
    Minimap:SetSize(db.size or 200, db.size or 200)
    
    if db.scale and db.scale ~= 1 then
        Minimap:SetScale(db.scale)
    end
    
    -- Create backdrop
    CreateBackdrop()
    
    -- Hide blizzard elements
    HideBlizzardElements()
    
    -- Apply shape
    ApplyMinimapShape()
    
    -- Hide blob rings
    HideBlobRings()
    
    -- Setup dragging
    SetupDragging()
    
    -- Setup mouse wheel zoom
    SetupMouseWheelZoom()
    
    -- Setup auto zoom
    SetupAutoZoom()
    
    -- Setup minimap clicks for tracker and calendar
    SetupMinimapClicks()
    
    -- Set minimap shape function
    SetMinimapShapeFunction()
    
    -- Update backdrop
    C_Timer.After(0.1, function()
        UpdateBackdrop()
        CreateZoneText()
        CreateClock()
        CreateFPS()
        ManageBlizzardButtons()
    end)
    
    -- Hook size changes
    hooksecurefunc(Minimap, "SetSize", function()
        UpdateBackdrop()
        if zoneTextFrame then
            local minimapWidth = Minimap:GetWidth()
            zoneTextFrame:SetWidth(minimapWidth and minimapWidth > 0 and (minimapWidth - 10) or 200)
        end
    end)
end

function MinimapModule:Refresh()
    local db = NephUI.db.profile.minimap
    if not db or not db.enabled then
        if Minimap then
            Minimap:SetSize(140, 140)
            Minimap:SetScale(1)
        end
        if backdropFrame then
            backdropFrame:Hide()
        end
        if clockDisplay then
            clockDisplay:Hide()
        end
        if clockTimer then
            clockTimer:Cancel()
            clockTimer = nil
        end
        if fpsDisplay then
            fpsDisplay:Hide()
        end
        if fpsTimer then
            fpsTimer:Cancel()
            fpsTimer = nil
        end
        if zoneTextFrame then
            zoneTextFrame:Hide()
        end
        return
    end
    
    if Minimap then
        Minimap:SetSize(db.size or 200, db.size or 200)
        
        if db.scale and db.scale ~= 1 then
            Minimap:SetScale(db.scale)
        else
            Minimap:SetScale(1)
        end
    end
    
    UpdateBackdrop()
    ApplyMinimapShape()
    CreateZoneText()
    CreateClock()
    CreateFPS()
    ManageBlizzardButtons()
    SetupDragging()
    SetupMouseWheelZoom()
    SetupAutoZoom()
    SetupMinimapClicks()
end

-- Handle HybridMinimap when it loads
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UPDATE_PENDING_MAIL")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "Blizzard_HybridMinimap" then
        ApplyMinimapShape()
        if MinimapModule.Initialize then
            MinimapModule:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        if MinimapModule.Initialize then
            MinimapModule:Initialize()
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "UPDATE_PENDING_MAIL" then
        -- Ensure Layout methods are preserved when mail updates occur
        -- This prevents errors when Blizzard code tries to call Layout
        PreserveLayoutMethods()
    end
end)
