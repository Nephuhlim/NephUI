local ADDON_NAME, ns = ...
local NephUI = ns.Addon

local LSM = LibStub("LibSharedMedia-3.0")

LSM:Register("statusbar","Neph", [[Interface\AddOns\NephUI\Media\Neph.tga]])
LSM:Register("font","Expressway", [[Interface\AddOns\NephUI\Fonts\Expressway.TTF]])

function NephUI:GetGlobalFont()
    local fontName = self.db.profile.general.globalFont or "Expressway"
    return LSM:Fetch("font", fontName) or [[Interface\AddOns\NephUI\Fonts\Expressway.TTF]]
end

function NephUI:GetGlobalTexture()
    local textureName = self.db.profile.general.globalTexture or "Neph"
    return LSM:Fetch("statusbar", textureName) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
end

-- Helper function to get texture with override support
-- If overrideTexture is provided and valid, use it; otherwise use global texture
function NephUI:GetTexture(overrideTexture)
    if overrideTexture and overrideTexture ~= "" then
        -- User has set a specific override texture
        local tex = LSM:Fetch("statusbar", overrideTexture)
        if tex then
            return tex
        end
    end
    -- Default to global texture
    return self:GetGlobalTexture()
end

function NephUI:ApplyGlobalFont()
    local fontPath = self:GetGlobalFont()
    if not fontPath then return end
    
    -- Check if user wants to apply global font to Blizzard UI
    local applyToBlizzard = self.db and self.db.profile and self.db.profile.general and self.db.profile.general.applyGlobalFontToBlizzard
    
    -- Apply fonts to Blizzard's global font objects (only if toggle is enabled)
    if applyToBlizzard then
        if GameFontNormal then
        local _, size, flags = GameFontNormal:GetFont()
        if size and flags then
            GameFontNormal:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontHighlight then
        local _, size, flags = GameFontHighlight:GetFont()
        if size and flags then
            GameFontHighlight:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontNormalSmall then
        local _, size, flags = GameFontNormalSmall:GetFont()
        if size and flags then
            GameFontNormalSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontHighlightSmall then
        local _, size, flags = GameFontHighlightSmall:GetFont()
        if size and flags then
            GameFontHighlightSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontNormalLarge then
        local _, size, flags = GameFontNormalLarge:GetFont()
        if size and flags then
            GameFontNormalLarge:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontHighlightLarge then
        local _, size, flags = GameFontHighlightLarge:GetFont()
        if size and flags then
            GameFontHighlightLarge:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontDisable then
        local _, size, flags = GameFontDisable:GetFont()
        if size and flags then
            GameFontDisable:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontDisableSmall then
        local _, size, flags = GameFontDisableSmall:GetFont()
        if size and flags then
            GameFontDisableSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if GameFontDisableLarge then
        local _, size, flags = GameFontDisableLarge:GetFont()
        if size and flags then
            GameFontDisableLarge:SetFont(fontPath, size, flags)
        end
    end
    
    if NumberFontNormal then
        local _, size, flags = NumberFontNormal:GetFont()
        if size and flags then
            NumberFontNormal:SetFont(fontPath, size, flags)
        end
    end
    
    if NumberFontNormalSmall then
        local _, size, flags = NumberFontNormalSmall:GetFont()
        if size and flags then
            NumberFontNormalSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if NumberFontNormalLarge then
        local _, size, flags = NumberFontNormalLarge:GetFont()
        if size and flags then
            NumberFontNormalLarge:SetFont(fontPath, size, flags)
        end
    end
    
    if NumberFontNormalHuge then
        local _, size, flags = NumberFontNormalHuge:GetFont()
        if size and flags then
            NumberFontNormalHuge:SetFont(fontPath, size, flags)
        end
    end
    
    if NumberFontNormalSmallGray then
        local _, size, flags = NumberFontNormalSmallGray:GetFont()
        if size and flags then
            NumberFontNormalSmallGray:SetFont(fontPath, size, flags)
        end
    end
    
    if ObjectiveTrackerFont then
        local _, size, flags = ObjectiveTrackerFont:GetFont()
        if size and flags then
            ObjectiveTrackerFont:SetFont(fontPath, size, flags)
        end
    end
    
    if QuestFont then
        local _, size, flags = QuestFont:GetFont()
        if size and flags then
            QuestFont:SetFont(fontPath, size, flags)
        end
    end
    
    if QuestFontHighlight then
        local _, size, flags = QuestFontHighlight:GetFont()
        if size and flags then
            QuestFontHighlight:SetFont(fontPath, size, flags)
        end
    end
    
    if QuestFontNormalSmall then
        local _, size, flags = QuestFontNormalSmall:GetFont()
        if size and flags then
            QuestFontNormalSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if QuestFontHighlightSmall then
        local _, size, flags = QuestFontHighlightSmall:GetFont()
        if size and flags then
            QuestFontHighlightSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if GameTooltipHeaderText then
        local _, size, flags = GameTooltipHeaderText:GetFont()
        if size and flags then
            GameTooltipHeaderText:SetFont(fontPath, size, flags)
        end
    end
    
    if GameTooltipText then
        local _, size, flags = GameTooltipText:GetFont()
        if size and flags then
            GameTooltipText:SetFont(fontPath, size, flags)
        end
    end
    
    if GameTooltipTextSmall then
        local _, size, flags = GameTooltipTextSmall:GetFont()
        if size and flags then
            GameTooltipTextSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if ChatFontNormal then
        local _, size, flags = ChatFontNormal:GetFont()
        if size and flags then
            ChatFontNormal:SetFont(fontPath, size, flags)
        end
    end
    
    if ChatFontSmall then
        local _, size, flags = ChatFontSmall:GetFont()
        if size and flags then
            ChatFontSmall:SetFont(fontPath, size, flags)
        end
    end
    
    if ChatFontLarge then
        local _, size, flags = ChatFontLarge:GetFont()
        if size and flags then
            ChatFontLarge:SetFont(fontPath, size, flags)
        end
    end
    end -- End of applyToBlizzard conditional
    
    -- Always apply fonts to NephUI's own elements (cooldown viewers, target auras, etc.)
    if not self._cooldownFontHooked then
        local function IdentifyCooldownSource(cooldownFrame)
            if not cooldownFrame then return nil end
            
            local parent = cooldownFrame:GetParent()
            if not parent then return nil end
            
            local iconFrame = parent
            local hasIcon = iconFrame.icon or iconFrame.Icon
            local hasCooldownRef = iconFrame.cooldown == cooldownFrame
            
            if hasIcon or hasCooldownRef then
                -- NephUI CustomIcons: per-icon cooldown text settings
                if iconFrame._iconKey then
                    return "customIcon:" .. tostring(iconFrame._iconKey)
                end
                
                -- Check if this is an action button (ActionButton, MultiBar, PetActionButton, StanceButton)
                local buttonName = iconFrame:GetName() or ""
                if buttonName:match("ActionButton") or buttonName:match("MultiBar") or 
                   buttonName:match("PetActionButton") or buttonName:match("StanceButton") then
                    -- Check if NephUI action bars are enabled
                    if self.db and self.db.profile and self.db.profile.actionBars and self.db.profile.actionBars.enabled then
                        return "actionButton"
                    end
                end

                local viewerFrame = iconFrame:GetParent()
                if viewerFrame then
                    local viewerName = viewerFrame:GetName()
                    if viewerName then
                        if viewerName == "EssentialCooldownViewer" then
                            return "EssentialCooldownViewer"
                        elseif viewerName == "UtilityCooldownViewer" then
                            return "UtilityCooldownViewer"
                        elseif viewerName == "BuffIconCooldownViewer" then
                            return "BuffIconCooldownViewer"
                            elseif viewerName == "NephUI_Target" then
                                if viewerFrame.buffIcons or viewerFrame.debuffIcons then
                                    local isInArray = false
                                    if viewerFrame.buffIcons then
                                        for _, buffIcon in ipairs(viewerFrame.buffIcons) do
                                            if buffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if not isInArray and viewerFrame.debuffIcons then
                                        for _, debuffIcon in ipairs(viewerFrame.debuffIcons) do
                                            if debuffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if isInArray or (viewerFrame.buffIcons and #viewerFrame.buffIcons > 0) or (viewerFrame.debuffIcons and #viewerFrame.debuffIcons > 0) then
                                        return "targetAuras"
                                    end
                                end
                            end
                        end
                        
                        -- Also check if viewerFrame's parent is NephUI_Target (in case of nested frames)
                        local targetFrame = viewerFrame:GetParent()
                        if targetFrame then
                            local targetFrameName = targetFrame:GetName()
                            if targetFrameName == "NephUI_Target" then
                                -- Check if this icon frame is in buffIcons or debuffIcons
                                if targetFrame.buffIcons or targetFrame.debuffIcons then
                                    -- Double-check by seeing if iconFrame is in the arrays
                                    local isInArray = false
                                    if targetFrame.buffIcons then
                                        for _, buffIcon in ipairs(targetFrame.buffIcons) do
                                            if buffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if not isInArray and targetFrame.debuffIcons then
                                        for _, debuffIcon in ipairs(targetFrame.debuffIcons) do
                                            if debuffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if isInArray or (targetFrame.buffIcons and #targetFrame.buffIcons > 0) or (targetFrame.debuffIcons and #targetFrame.debuffIcons > 0) then
                                        return "targetAuras"
                                    end
                                end
                            end
                        end
                end
            else
                -- Check if parent is an action button
                local parentName = parent:GetName() or ""
                if parentName:match("ActionButton") or parentName:match("MultiBar") or 
                   parentName:match("PetActionButton") or parentName:match("StanceButton") then
                    -- Check if NephUI action bars are enabled
                    if self.db and self.db.profile and self.db.profile.actionBars and self.db.profile.actionBars.enabled then
                        return "actionButton"
                    end
                end
                
                local viewerName = parent:GetName()
                if viewerName then
                    if viewerName == "EssentialCooldownViewer" then
                        return "EssentialCooldownViewer"
                    elseif viewerName == "UtilityCooldownViewer" then
                        return "UtilityCooldownViewer"
                    elseif viewerName == "BuffIconCooldownViewer" then
                        return "BuffIconCooldownViewer"
                    elseif viewerName == "NephUI_Target" then
                        if parent.buffIcons or parent.debuffIcons then
                            return "targetAuras"
                        end
                    end
                end
                
                local targetFrame = parent:GetParent()
                if targetFrame then
                    local targetFrameName = targetFrame:GetName()
                    if targetFrameName == "NephUI_Target" then
                        if targetFrame.buffIcons or targetFrame.debuffIcons then
                            return "targetAuras"
                        end
                    end
                end
            end
            
            return nil
        end
        
        local function GetCooldownSettings(source)
            local fontSize = 18
            local textColor = {1, 1, 1, 1}
            local shadowOffsetX = 1
            local shadowOffsetY = -1

            if source and type(source) == "string" then
                local iconKey = source:match("^customIcon:(.+)$")
                if iconKey then
                    -- Use per-icon settings where available; fallback to global viewer general settings.
                    local iconData
                    if self.db and self.db.profile and self.db.profile.dynamicIcons and self.db.profile.dynamicIcons.iconData then
                        iconData = self.db.profile.dynamicIcons.iconData[iconKey]
                    end

                    local cds = iconData and iconData.settings and iconData.settings.cooldownSettings
                    fontSize = (cds and cds.size) or 12
                    textColor = (cds and cds.color) or { 1, 1, 1, 1 }

                    if self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers.general then
                        shadowOffsetX = self.db.profile.viewers.general.cooldownShadowOffsetX or shadowOffsetX
                        shadowOffsetY = self.db.profile.viewers.general.cooldownShadowOffsetY or shadowOffsetY
                    end

                    return fontSize, textColor, shadowOffsetX, shadowOffsetY
                end
            end
            
            if source == "actionButton" then
                -- Get from action bar settings or fallback to general viewer settings
                if self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers.general then
                    fontSize = self.db.profile.viewers.general.cooldownFontSize or 18
                    textColor = self.db.profile.viewers.general.cooldownTextColor or {1, 1, 1, 1}
                    shadowOffsetX = self.db.profile.viewers.general.cooldownShadowOffsetX or 1
                    shadowOffsetY = self.db.profile.viewers.general.cooldownShadowOffsetY or -1
                end
            elseif source == "targetAuras" then
                -- Get from target auras settings
                if self.db and self.db.profile and self.db.profile.unitFrames and 
                   self.db.profile.unitFrames.target and self.db.profile.unitFrames.target.Auras then
                    local auraSettings = self.db.profile.unitFrames.target.Auras
                    fontSize = auraSettings.cooldownFontSize or 
                              (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownFontSize) or 18
                    textColor = auraSettings.cooldownTextColor or 
                               (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                    shadowOffsetX = auraSettings.cooldownShadowOffsetX or 
                                   (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetX) or 1
                    shadowOffsetY = auraSettings.cooldownShadowOffsetY or 
                                   (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetY) or -1
                end
            elseif source and (source == "EssentialCooldownViewer" or source == "UtilityCooldownViewer" or source == "BuffIconCooldownViewer") then
                -- Get from viewer-specific settings
                if self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers[source] then
                    local viewerSettings = self.db.profile.viewers[source]
                    fontSize = viewerSettings.cooldownFontSize or 
                              (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownFontSize) or 18
                    textColor = viewerSettings.cooldownTextColor or 
                               (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                    shadowOffsetX = viewerSettings.cooldownShadowOffsetX or 
                                   (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetX) or 1
                    shadowOffsetY = viewerSettings.cooldownShadowOffsetY or 
                                   (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetY) or -1
                end
            else
                -- Fallback to general settings
                if self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers.general then
                    fontSize = self.db.profile.viewers.general.cooldownFontSize or 18
                    textColor = self.db.profile.viewers.general.cooldownTextColor or {1, 1, 1, 1}
                    shadowOffsetX = self.db.profile.viewers.general.cooldownShadowOffsetX or 1
                    shadowOffsetY = self.db.profile.viewers.general.cooldownShadowOffsetY or -1
                end
            end
            
            return fontSize, textColor, shadowOffsetX, shadowOffsetY
        end
        
        local function GetCooldownFontString(cooldownFrame)
            if not cooldownFrame then return nil end
            
            if cooldownFrame._nephui_fontString then
                return cooldownFrame._nephui_fontString
            end
            
            for _, region in ipairs({cooldownFrame:GetRegions()}) do
                if region:GetObjectType() == "FontString" then
                    cooldownFrame._nephui_fontString = region
                    return region
                end
            end
            
            return nil
        end
        
        local function ApplyCooldownFont(cooldownFrame)
            if not cooldownFrame then return end

            local function IsGrid2Cooldown(frame)
                local name = frame:GetName()
                if name and name:match("^Grid2") then
                    return true
                end
                local parent = frame:GetParent()
                while parent do
                    local parentName = parent:GetName()
                    if parentName and parentName:match("^Grid2") then
                        return true
                    end
                    parent = parent:GetParent()
                end
                return false
            end

            local function IsElvUICooldown(frame)
                local name = frame:GetName()
                if name and name:match("^ElvUI") then
                    return true
                end
                local parent = frame:GetParent()
                while parent do
                    local parentName = parent:GetName()
                    if parentName and parentName:match("^ElvUI") then
                        return true
                    end
                    parent = parent:GetParent()
                end
                return false
            end

            -- Skip Grid2/ElvUI cooldowns to avoid overriding their font settings
            if IsGrid2Cooldown(cooldownFrame) or IsElvUICooldown(cooldownFrame) then
                return
            end
            
            -- Only apply fonts to NephUI cooldowns
            local source = IdentifyCooldownSource(cooldownFrame)
            if not source then
                -- This cooldown doesn't belong to NephUI, skip it
                return
            end
            
            local fontString = GetCooldownFontString(cooldownFrame)
            if not fontString then
                C_Timer.After(0, function()
                    local delayedFontString = GetCooldownFontString(cooldownFrame)
                    if delayedFontString then
                        local currentFontPath = self:GetGlobalFont()
                        if currentFontPath then
                            -- Re-check source in case frame structure changed
                            local delayedSource = IdentifyCooldownSource(cooldownFrame)
                            if not delayedSource then
                                return
                            end
                            local fontSize, textColor, shadowOffsetX, shadowOffsetY = GetCooldownSettings(delayedSource)
                            
                            local _, existingSize, flags = delayedFontString:GetFont()
                            if flags then
                                delayedFontString:SetFont(currentFontPath, fontSize, flags)
                            else
                                delayedFontString:SetFont(currentFontPath, fontSize)
                            end
                            
                            delayedFontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
                            delayedFontString:SetShadowOffset(shadowOffsetX, shadowOffsetY)
                        end
                    end
                end)
                return
            end
            
            local currentFontPath = self:GetGlobalFont()
            if currentFontPath then
                local fontSize, textColor, shadowOffsetX, shadowOffsetY = GetCooldownSettings(source)
                
                local _, existingSize, flags = fontString:GetFont()
                if flags then
                    fontString:SetFont(currentFontPath, fontSize, flags)
                else
                    fontString:SetFont(currentFontPath, fontSize)
                end
                
                fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
                fontString:SetShadowOffset(shadowOffsetX, shadowOffsetY)
            end
        end
        
        if CooldownFrame_Set then
            hooksecurefunc("CooldownFrame_Set", function(cooldownFrame, start, duration, enable, forceShowDrawEdge, modRate)
                if not cooldownFrame or cooldownFrame:IsForbidden() then
                    return
                end
                
                -- Use pcall to safely handle any errors during combat
                pcall(function()
                    cooldownFrame._nephui_fontString = nil
                    C_Timer.After(0, function()
                        if cooldownFrame and not cooldownFrame:IsForbidden() then
                            pcall(ApplyCooldownFont, cooldownFrame)
                        end
                    end)
                end)
            end)
        end
        
        if CooldownFrame_SetTimer then
            hooksecurefunc("CooldownFrame_SetTimer", function(cooldownFrame, start, duration, enable, forceShowDrawEdge, modRate)
                if not cooldownFrame or cooldownFrame:IsForbidden() then
                    return
                end
                
                -- Use pcall to safely handle any errors during combat
                pcall(function()
                    cooldownFrame._nephui_fontString = nil
                    C_Timer.After(0, function()
                        if cooldownFrame and not cooldownFrame:IsForbidden() then
                            pcall(ApplyCooldownFont, cooldownFrame)
                        end
                    end)
                end)
            end)
        end
        
        -- Don't wrap ActionButton_UpdateCooldown as it causes taint issues
        -- Action button cooldowns should be handled by the ActionBars module if needed
        
        hooksecurefunc("CreateFrame", function(frameType, name, parent, template)
            if frameType == "Cooldown" then
                C_Timer.After(0, function()
                    local cooldownFrame = name and _G[name] or nil
                    if not cooldownFrame and parent then
                        local children = {parent:GetChildren()}
                        for _, child in ipairs(children) do
                            if child:GetObjectType() == "Cooldown" then
                                cooldownFrame = child
                                break
                            end
                        end
                    end
                    if cooldownFrame then
                        ApplyCooldownFont(cooldownFrame)
                    end
                end)
            end
        end)
        
        local function ApplyFontToExistingCooldowns()
            local currentFontPath = self:GetGlobalFont()
            if currentFontPath and EnumerateFrames then
                local frame = EnumerateFrames()
                while frame do
                    if frame:GetObjectType() == "Cooldown" then
                        frame._nephui_fontString = nil
                        ApplyCooldownFont(frame)
                    end
                    frame = EnumerateFrames(frame)
                end
            end
        end
        
        C_Timer.After(1.0, ApplyFontToExistingCooldowns)
        
        if NephUI.UnitFrames and NephUI.UnitFrames.UpdateTargetAuras then
            local originalUpdateTargetAuras = NephUI.UnitFrames.UpdateTargetAuras
            NephUI.UnitFrames.UpdateTargetAuras = function(frame, ...)
                local result = originalUpdateTargetAuras(frame, ...)
                C_Timer.After(0.1, function()
                    if frame and (frame.buffIcons or frame.debuffIcons) then
                        local allIcons = {}
                        if frame.buffIcons then
                            for _, iconFrame in ipairs(frame.buffIcons) do
                                if iconFrame.cooldown then
                                    table.insert(allIcons, iconFrame.cooldown)
                                end
                            end
                        end
                        if frame.debuffIcons then
                            for _, iconFrame in ipairs(frame.debuffIcons) do
                                if iconFrame.cooldown then
                                    table.insert(allIcons, iconFrame.cooldown)
                                end
                            end
                        end
                        for _, cooldownFrame in ipairs(allIcons) do
                            cooldownFrame._nephui_fontString = nil
                            ApplyCooldownFont(cooldownFrame)
                        end
                    end
                end)
                return result
            end
        end
        
        self._cooldownFontHooked = true
    else
        local currentFontPath = self:GetGlobalFont()
        if currentFontPath then
            local function IdentifyCooldownSource(cooldownFrame)
                if not cooldownFrame then return nil end
                
                local parent = cooldownFrame:GetParent()
                if not parent then return nil end
                
                -- Check if parent is an icon frame (has icon texture or cooldown property)
                -- For target auras: iconFrame is parent of cooldown, and iconFrame's parent is NephUI_Target
                local iconFrame = parent
                local hasIcon = iconFrame.icon or iconFrame.Icon
                local hasCooldownRef = iconFrame.cooldown == cooldownFrame
                
                if hasIcon or hasCooldownRef then
                    -- Check if this is an action button (ActionButton, MultiBar, PetActionButton, StanceButton)
                    local buttonName = iconFrame:GetName() or ""
                    if buttonName:match("ActionButton") or buttonName:match("MultiBar") or 
                       buttonName:match("PetActionButton") or buttonName:match("StanceButton") then
                        -- Check if NephUI action bars are enabled
                        if self.db and self.db.profile and self.db.profile.actionBars and self.db.profile.actionBars.enabled then
                            return "actionButton"
                        end
                    end
                    
                    -- This is likely an icon frame, check its parent
                    local viewerFrame = iconFrame:GetParent()
                    if viewerFrame then
                        local viewerName = viewerFrame:GetName()
                        if viewerName then
                            -- Check if it's one of our viewers
                            if viewerName == "EssentialCooldownViewer" then
                                return "EssentialCooldownViewer"
                            elseif viewerName == "UtilityCooldownViewer" then
                                return "UtilityCooldownViewer"
                            elseif viewerName == "BuffIconCooldownViewer" then
                                return "BuffIconCooldownViewer"
                            elseif viewerName == "NephUI_Target" then
                                -- This is a target aura icon frame
                                -- Verify by checking if the frame has buffIcons or debuffIcons
                                -- Also check if this iconFrame is actually in those arrays
                                if viewerFrame.buffIcons or viewerFrame.debuffIcons then
                                    -- Double-check by seeing if iconFrame is in the arrays
                                    local isInArray = false
                                    if viewerFrame.buffIcons then
                                        for _, buffIcon in ipairs(viewerFrame.buffIcons) do
                                            if buffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if not isInArray and viewerFrame.debuffIcons then
                                        for _, debuffIcon in ipairs(viewerFrame.debuffIcons) do
                                            if debuffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if isInArray or (viewerFrame.buffIcons and #viewerFrame.buffIcons > 0) or (viewerFrame.debuffIcons and #viewerFrame.debuffIcons > 0) then
                                        return "targetAuras"
                                    end
                                end
                            end
                        end
                        
                        -- Also check if viewerFrame's parent is NephUI_Target (in case of nested frames)
                        local targetFrame = viewerFrame:GetParent()
                        if targetFrame then
                            local targetFrameName = targetFrame:GetName()
                            if targetFrameName == "NephUI_Target" then
                                -- Check if this icon frame is in buffIcons or debuffIcons
                                if targetFrame.buffIcons or targetFrame.debuffIcons then
                                    -- Double-check by seeing if iconFrame is in the arrays
                                    local isInArray = false
                                    if targetFrame.buffIcons then
                                        for _, buffIcon in ipairs(targetFrame.buffIcons) do
                                            if buffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if not isInArray and targetFrame.debuffIcons then
                                        for _, debuffIcon in ipairs(targetFrame.debuffIcons) do
                                            if debuffIcon == iconFrame then
                                                isInArray = true
                                                break
                                            end
                                        end
                                    end
                                    if isInArray or (targetFrame.buffIcons and #targetFrame.buffIcons > 0) or (targetFrame.debuffIcons and #targetFrame.debuffIcons > 0) then
                                        return "targetAuras"
                                    end
                                end
                            end
                        end
                    end
                else
                    -- Check if parent is an action button
                    local parentName = parent:GetName() or ""
                    if parentName:match("ActionButton") or parentName:match("MultiBar") or 
                       parentName:match("PetActionButton") or parentName:match("StanceButton") then
                        -- Check if NephUI action bars are enabled
                        if self.db and self.db.profile and self.db.profile.actionBars and self.db.profile.actionBars.enabled then
                            return "actionButton"
                        end
                    end
                    
                    -- Parent might be the viewer frame directly
                    local viewerName = parent:GetName()
                    if viewerName then
                        if viewerName == "EssentialCooldownViewer" then
                            return "EssentialCooldownViewer"
                        elseif viewerName == "UtilityCooldownViewer" then
                            return "UtilityCooldownViewer"
                        elseif viewerName == "BuffIconCooldownViewer" then
                            return "BuffIconCooldownViewer"
                        elseif viewerName == "NephUI_Target" then
                            -- Direct child of target frame - check if it has aura properties
                            if parent.buffIcons or parent.debuffIcons then
                                return "targetAuras"
                            end
                        end
                    end
                    
                    -- Check if parent is part of target auras
                    local targetFrame = parent:GetParent()
                    if targetFrame then
                        local targetFrameName = targetFrame:GetName()
                        if targetFrameName == "NephUI_Target" then
                            if targetFrame.buffIcons or targetFrame.debuffIcons then
                                return "targetAuras"
                            end
                        end
                    end
                end
                
                return nil
            end
            
            local function GetCooldownSettings(source)
                local fontSize = 18
                local textColor = {1, 1, 1, 1}
                local shadowOffsetX = 1
                local shadowOffsetY = -1
                
                if source == "actionButton" then
                    -- Get from action bar settings or fallback to general viewer settings
                    if self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers.general then
                        fontSize = self.db.profile.viewers.general.cooldownFontSize or 18
                        textColor = self.db.profile.viewers.general.cooldownTextColor or {1, 1, 1, 1}
                        shadowOffsetX = self.db.profile.viewers.general.cooldownShadowOffsetX or 1
                        shadowOffsetY = self.db.profile.viewers.general.cooldownShadowOffsetY or -1
                    end
                elseif source == "targetAuras" then
                    -- Get from target auras settings
                    if self.db and self.db.profile and self.db.profile.unitFrames and 
                       self.db.profile.unitFrames.target and self.db.profile.unitFrames.target.Auras then
                        local auraSettings = self.db.profile.unitFrames.target.Auras
                        fontSize = auraSettings.cooldownFontSize or 
                                  (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownFontSize) or 18
                        textColor = auraSettings.cooldownTextColor or 
                                   (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                        shadowOffsetX = auraSettings.cooldownShadowOffsetX or 
                                       (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetX) or 1
                        shadowOffsetY = auraSettings.cooldownShadowOffsetY or 
                                       (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetY) or -1
                    end
                elseif source and (source == "EssentialCooldownViewer" or source == "UtilityCooldownViewer" or source == "BuffIconCooldownViewer") then
                    -- Get from viewer-specific settings
                    if self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers[source] then
                        local viewerSettings = self.db.profile.viewers[source]
                        fontSize = viewerSettings.cooldownFontSize or 
                                  (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownFontSize) or 18
                        textColor = viewerSettings.cooldownTextColor or 
                                   (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                        shadowOffsetX = viewerSettings.cooldownShadowOffsetX or 
                                       (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetX) or 1
                        shadowOffsetY = viewerSettings.cooldownShadowOffsetY or 
                                       (self.db.profile.viewers.general and self.db.profile.viewers.general.cooldownShadowOffsetY) or -1
                    end
                else
                    if self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers.general then
                        fontSize = self.db.profile.viewers.general.cooldownFontSize or 18
                        textColor = self.db.profile.viewers.general.cooldownTextColor or {1, 1, 1, 1}
                        shadowOffsetX = self.db.profile.viewers.general.cooldownShadowOffsetX or 1
                        shadowOffsetY = self.db.profile.viewers.general.cooldownShadowOffsetY or -1
                    end
                end
                
                return fontSize, textColor, shadowOffsetX, shadowOffsetY
            end
            
            local function GetCooldownFontString(cooldownFrame)
                if not cooldownFrame then return nil end
                if cooldownFrame._nephui_fontString then
                    return cooldownFrame._nephui_fontString
                end
                for _, region in ipairs({cooldownFrame:GetRegions()}) do
                    if region:GetObjectType() == "FontString" then
                        cooldownFrame._nephui_fontString = region
                        return region
                    end
                end
                return nil
            end
            
            local function ApplyFontToExistingCooldowns()
                if EnumerateFrames then
                    local frame = EnumerateFrames()
                    while frame do
                        if frame:GetObjectType() == "Cooldown" then
                            frame._nephui_fontString = nil -- Clear cache
                            -- Only apply fonts to NephUI cooldowns
                            local source = IdentifyCooldownSource(frame)
                            if source then
                                local fontString = GetCooldownFontString(frame)
                                if fontString then
                                    local fontSize, textColor, shadowOffsetX, shadowOffsetY = GetCooldownSettings(source)
                                    
                                    local _, existingSize, flags = fontString:GetFont()
                                    if flags then
                                        fontString:SetFont(currentFontPath, fontSize, flags)
                                    else
                                        fontString:SetFont(currentFontPath, fontSize)
                                    end
                                    fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
                                    fontString:SetShadowOffset(shadowOffsetX, shadowOffsetY)
                                end
                            end
                        end
                        frame = EnumerateFrames(frame)
                    end
                end
            end
            ApplyFontToExistingCooldowns()
        end
    end
    
    -- Apply fonts to Blizzard's quest/tooltip/chat (only if toggle is enabled)
    if applyToBlizzard then
        if not self._questFontHooked then
        if ObjectiveTracker_Update then
            hooksecurefunc("ObjectiveTracker_Update", function()
                if not (self.db and self.db.profile and self.db.profile.general and self.db.profile.general.applyGlobalFontToBlizzard) then
                    return
                end
                local currentFontPath = self:GetGlobalFont()
                if currentFontPath and ObjectiveTrackerFrame then
                    local function ApplyFontToFrame(frame)
                        if not frame then return end
                        local children = {frame:GetChildren()}
                        for _, child in ipairs(children) do
                            if child:IsObjectType("FontString") then
                                local _, size, flags = child:GetFont()
                                if size and flags then
                                    child:SetFont(currentFontPath, size, flags)
                                end
                            end
                            ApplyFontToFrame(child)
                        end
                    end
                    ApplyFontToFrame(ObjectiveTrackerFrame)
                end
            end)
        end
        self._questFontHooked = true
        end
        
        if not self._tooltipFontHooked then
        if GameTooltip_SetDefaultAnchor then
            hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, owner)
                if not (self.db and self.db.profile and self.db.profile.general and self.db.profile.general.applyGlobalFontToBlizzard) then
                    return
                end
                local currentFontPath = self:GetGlobalFont()
                if currentFontPath and tooltip then
                    local function ApplyFontToTooltip(tip)
                        if not tip then return end
                        local children = {tip:GetChildren()}
                        for _, child in ipairs(children) do
                            if child:IsObjectType("FontString") then
                                local _, size, flags = child:GetFont()
                                if size and flags then
                                    child:SetFont(currentFontPath, size, flags)
                                end
                            end
                            ApplyFontToTooltip(child)
                        end
                    end
                    ApplyFontToTooltip(tooltip)
                end
            end)
        end
        
        if GameTooltip_OnLoad then
            hooksecurefunc("GameTooltip_OnLoad", function(tooltip)
                if not (self.db and self.db.profile and self.db.profile.general and self.db.profile.general.applyGlobalFontToBlizzard) then
                    return
                end
                local currentFontPath = self:GetGlobalFont()
                if currentFontPath and tooltip then
                    local function ApplyFontToTooltip(tip)
                        if not tip then return end
                        local children = {tip:GetChildren()}
                        for _, child in ipairs(children) do
                            if child:IsObjectType("FontString") then
                                local _, size, flags = child:GetFont()
                                if size and flags then
                                    child:SetFont(currentFontPath, size, flags)
                                end
                            end
                            ApplyFontToTooltip(child)
                        end
                    end
                    ApplyFontToTooltip(tooltip)
                end
            end)
        end
        self._tooltipFontHooked = true
        end
        
        if not self._chatFontHooked then
        if FCF_SetChatWindowFontSize then
            hooksecurefunc("FCF_SetChatWindowFontSize", function(frame, size)
                if not (self.db and self.db.profile and self.db.profile.general and self.db.profile.general.applyGlobalFontToBlizzard) then
                    return
                end
                local currentFontPath = self:GetGlobalFont()
                if currentFontPath and frame and frame:GetFont() then
                    local _, currentSize, flags = frame:GetFont()
                    if currentSize and flags then
                        frame:SetFont(currentFontPath, currentSize, flags)
                    end
                end
            end)
        end
        
        -- Apply fonts to existing chat frames (only if toggle is enabled)
        if applyToBlizzard then
            local numChatWindows = NUM_CHAT_WINDOWS
            if not numChatWindows then
                numChatWindows = 10
            end
            for i = 1, numChatWindows do
                local chatFrame = _G["ChatFrame" .. i]
                if chatFrame then
                    local _, size, flags = chatFrame:GetFont()
                    if size and flags then
                        chatFrame:SetFont(fontPath, size, flags)
                    end
                end
            end
            
            if DEFAULT_CHAT_FRAME then
                local _, size, flags = DEFAULT_CHAT_FRAME:GetFont()
                if size and flags then
                    DEFAULT_CHAT_FRAME:SetFont(fontPath, size, flags)
                end
            end
        end
        
        self._chatFontHooked = true
        end
    end -- End of applyToBlizzard conditional for quest/tooltip/chat hooks
end

