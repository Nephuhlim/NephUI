local ADDON_NAME, ns = ...
local NephUI = ns.Addon

NephUI.AuraOverride = NephUI.AuraOverride or {}
local AuraOverride = NephUI.AuraOverride

-- Track which viewers have ignoreAuraOverride enabled
local viewerSettings = {}

-- Get settings for a viewer
local function GetViewerSettings(viewerName)
    if not viewerName then return nil end
    local settings = NephUI.db.profile.viewers[viewerName]
    if not settings then return nil end
    return settings.ignoreAuraOverride or false
end

-- Check if an icon frame has an active aura
local function HasActiveAura(iconFrame)
    if not iconFrame then return false end
    local auraID = iconFrame.auraInstanceID
    return auraID and type(auraID) == "number" and auraID > 0
end

-- Get spell ID from icon frame
local function GetSpellID(iconFrame)
    if not iconFrame then return nil end
    if iconFrame.cooldownInfo then
        return iconFrame.cooldownInfo.overrideSpellID or iconFrame.cooldownInfo.spellID
    end
    return nil
end

-- Apply desaturation when aura is active but we're showing spell cooldown
-- Uses a force value flag that hooks will enforce to prevent flashing
local function ApplyDesaturationForAuraActive(iconFrame, desaturate)
    if not iconFrame then return end
    
    local iconTexture = iconFrame.icon or iconFrame.Icon
    if not iconTexture then return end
    
    -- Set the force value flag - hooks will enforce this
    if desaturate then
        iconFrame.__nephuiForceDesatValue = 1
    else
        iconFrame.__nephuiForceDesatValue = nil
    end
    
    -- Apply immediately
    if desaturate then
        if iconTexture.SetDesaturation then
            iconTexture:SetDesaturation(1)
        elseif iconTexture.SetDesaturated then
            iconTexture:SetDesaturated(true)
        end
    else
        if iconTexture.SetDesaturation then
            iconTexture:SetDesaturation(0)
        elseif iconTexture.SetDesaturated then
            iconTexture:SetDesaturated(false)
        end
    end
end

-- Hook SetCooldown to enforce spell cooldown when ignoreAuraOverride is enabled
local function HookCooldownFrame(iconFrame, viewerName)
    if not iconFrame or not iconFrame.Cooldown then return end
    if iconFrame.__nephuiAuraOverrideHooked then return end
    
    iconFrame.__nephuiAuraOverrideHooked = true
    iconFrame.__nephuiViewerName = viewerName
    
    local cooldown = iconFrame.Cooldown
    local iconTexture = iconFrame.icon or iconFrame.Icon
    
    -- Hook SetDesaturated and SetDesaturation to enforce our force value
    -- This prevents CDM from constantly changing desaturation and causing flashing
    if iconTexture and not iconTexture.__nephuiDesatHooked then
        iconTexture.__nephuiDesatHooked = true
        iconTexture.__nephuiParentFrame = iconFrame
        
        -- Hook SetDesaturated (boolean version)
        if iconTexture.SetDesaturated then
            hooksecurefunc(iconTexture, "SetDesaturated", function(self, desaturated)
                local pf = self.__nephuiParentFrame
                if not pf then return end
                if pf.__nephuiBypassDesatHook then return end
                
                -- If we have a forced desaturation value (for ignoreAuraOverride), enforce it
                local forceValue = pf.__nephuiForceDesatValue
                if forceValue ~= nil and self.SetDesaturation then
                    pf.__nephuiBypassDesatHook = true
                    self:SetDesaturation(forceValue)
                    pf.__nephuiBypassDesatHook = false
                end
            end)
        end
        
        -- Hook SetDesaturation (numeric version)
        if iconTexture.SetDesaturation then
            hooksecurefunc(iconTexture, "SetDesaturation", function(self, value)
                local pf = self.__nephuiParentFrame
                if not pf then return end
                if pf.__nephuiBypassDesatHook then return end
                
                -- If we have a forced desaturation value (for ignoreAuraOverride), enforce it
                local forceValue = pf.__nephuiForceDesatValue
                if forceValue ~= nil then
                    pf.__nephuiBypassDesatHook = true
                    self:SetDesaturation(forceValue)
                    pf.__nephuiBypassDesatHook = false
                end
            end)
        end
    end
    
    -- Hook SetCooldown using hooksecurefunc
    hooksecurefunc(cooldown, "SetCooldown", function(self, startTime, duration)
        local parentFrame = self:GetParent()
        if not parentFrame or not parentFrame.__nephuiViewerName then return end
        if parentFrame.__nephuiBypassCooldownHook then return end
        
        local viewerName = parentFrame.__nephuiViewerName
        local ignoreAuraOverride = GetViewerSettings(viewerName)
        
        if ignoreAuraOverride and HasActiveAura(parentFrame) then
            -- Aura is active, but we want to show spell cooldown instead
            local spellID = GetSpellID(parentFrame)
            if spellID then
                -- Check if this is a charge spell
                local chargeInfo = nil
                local isChargeSpell = false
                pcall(function()
                    chargeInfo = C_Spell.GetSpellCharges(spellID)
                    isChargeSpell = chargeInfo ~= nil
                end)
                
                if isChargeSpell and C_Spell.GetSpellChargeDuration then
                    -- CHARGE SPELL: Use charge duration object (shows charge recharge swipe)
                    -- For charge spells, don't force desaturation - let CDM handle it based on charge availability
                    local ok, chargeDurObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
                    if ok and chargeDurObj then
                        parentFrame.__nephuiBypassCooldownHook = true
                        pcall(function()
                            if self.SetCooldownFromDurationObject then
                                self:SetCooldownFromDurationObject(chargeDurObj)
                            end
                        end)
                        parentFrame.__nephuiBypassCooldownHook = false
                        -- Set swipe color to black (like regular cooldown) instead of yellow (aura swipe)
                        if self.SetSwipeColor then
                            self:SetSwipeColor(0, 0, 0, 0.8)
                        end
                        -- Don't force desaturation for charge spells - let CDM handle it naturally
                    end
                else
                    -- NORMAL SPELL: Use regular spell cooldown
                    local ok, cooldownInfo = pcall(C_Spell.GetSpellCooldown, spellID)
                    if ok and cooldownInfo and cooldownInfo.duration and cooldownInfo.startTime 
                       and type(cooldownInfo.duration) == "number" and type(cooldownInfo.startTime) == "number" then
                        -- Use spell cooldown instead of aura duration
                        parentFrame.__nephuiBypassCooldownHook = true
                        self:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
                        -- Set swipe color to black (like regular cooldown) instead of yellow (aura swipe)
                        if self.SetSwipeColor then
                            self:SetSwipeColor(0, 0, 0, 0.8)
                        end
                        parentFrame.__nephuiBypassCooldownHook = false
                        -- Set force desaturation value - hooks will enforce it
                        parentFrame.__nephuiForceDesatValue = 1
                        -- Apply desaturation since aura is active
                        ApplyDesaturationForAuraActive(parentFrame, true)
                    end
                end
            end
        elseif ignoreAuraOverride then
            -- Clear force desaturation when aura is not active
            parentFrame.__nephuiForceDesatValue = nil
            -- Update desaturation when aura is not active
            ApplyDesaturationForAuraActive(parentFrame, false)
        end
    end)
    
    -- Hook SetCooldownFromDurationObject
    if cooldown.SetCooldownFromDurationObject then
        hooksecurefunc(cooldown, "SetCooldownFromDurationObject", function(self, durationObj, clearIfZero)
            local parentFrame = self:GetParent()
            if not parentFrame or not parentFrame.__nephuiViewerName then return end
            if parentFrame.__nephuiBypassCooldownHook then return end
            
            local viewerName = parentFrame.__nephuiViewerName
            local ignoreAuraOverride = GetViewerSettings(viewerName)
            
            if ignoreAuraOverride and HasActiveAura(parentFrame) then
                -- Aura is active, but we want to show spell cooldown instead
                local spellID = GetSpellID(parentFrame)
                if spellID then
                    -- Check if this is a charge spell
                    local chargeInfo = nil
                    local isChargeSpell = false
                    pcall(function()
                        chargeInfo = C_Spell.GetSpellCharges(spellID)
                        isChargeSpell = chargeInfo ~= nil
                    end)
                    
                    if isChargeSpell and C_Spell.GetSpellChargeDuration then
                        -- CHARGE SPELL: Use charge duration object (shows charge recharge swipe)
                        -- For charge spells, don't force desaturation - let CDM handle it based on charge availability
                        local ok, chargeDurObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
                        if ok and chargeDurObj then
                            parentFrame.__nephuiBypassCooldownHook = true
                            pcall(function()
                                self:SetCooldownFromDurationObject(chargeDurObj)
                            end)
                            parentFrame.__nephuiBypassCooldownHook = false
                            -- Set swipe color to black (like regular cooldown) instead of yellow (aura swipe)
                            if self.SetSwipeColor then
                                self:SetSwipeColor(0, 0, 0, 0.8)
                            end
                            -- Don't force desaturation for charge spells - let CDM handle it naturally
                        end
                    else
                        -- NORMAL SPELL: Use regular spell cooldown
                        local ok, cooldownInfo = pcall(C_Spell.GetSpellCooldown, spellID)
                        if ok and cooldownInfo and cooldownInfo.duration and cooldownInfo.startTime 
                           and type(cooldownInfo.duration) == "number" and type(cooldownInfo.startTime) == "number" then
                            -- Use spell cooldown instead of aura duration
                            parentFrame.__nephuiBypassCooldownHook = true
                            self:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
                            -- Set swipe color to black (like regular cooldown) instead of yellow (aura swipe)
                            if self.SetSwipeColor then
                                self:SetSwipeColor(0, 0, 0, 0.8)
                            end
                            parentFrame.__nephuiBypassCooldownHook = false
                            -- Set force desaturation value - hooks will enforce it
                            parentFrame.__nephuiForceDesatValue = 1
                            -- Apply desaturation since aura is active
                            ApplyDesaturationForAuraActive(parentFrame, true)
                        end
                    end
                end
            elseif ignoreAuraOverride then
                -- Clear force desaturation when aura is not active
                parentFrame.__nephuiForceDesatValue = nil
                -- Update desaturation when aura is not active
                ApplyDesaturationForAuraActive(parentFrame, false)
            end
        end)
    end
end

-- Hook an icon frame
function AuraOverride:HookIconFrame(iconFrame, viewerName)
    if not iconFrame or not viewerName then return end
    if not GetViewerSettings(viewerName) then return end
    
    HookCooldownFrame(iconFrame, viewerName)
end

-- Refresh all icons in a viewer
function AuraOverride:RefreshViewer(viewer)
    if not viewer or not viewer.GetName then return end
    
    local viewerName = viewer:GetName()
    local ignoreAuraOverride = GetViewerSettings(viewerName)
    
    if not ignoreAuraOverride then return end
    
    local container = viewer.viewerFrame or viewer
    local children = { container:GetChildren() }
    
    for _, icon in ipairs(children) do
        if icon and (icon.icon or icon.Icon) and icon.Cooldown then
            self:HookIconFrame(icon, viewerName)
            
            -- Force update if aura is active
            if HasActiveAura(icon) then
                local spellID = GetSpellID(icon)
                if spellID and icon.Cooldown then
                    -- Check if this is a charge spell
                    local chargeInfo = nil
                    local isChargeSpell = false
                    pcall(function()
                        chargeInfo = C_Spell.GetSpellCharges(spellID)
                        isChargeSpell = chargeInfo ~= nil
                    end)
                    
                    if isChargeSpell and C_Spell.GetSpellChargeDuration then
                        -- CHARGE SPELL: Use charge duration object (shows charge recharge swipe)
                        -- For charge spells, don't force desaturation - let CDM handle it based on charge availability
                        local ok, chargeDurObj = pcall(C_Spell.GetSpellChargeDuration, spellID)
                        if ok and chargeDurObj and icon.Cooldown.SetCooldownFromDurationObject then
                            pcall(function()
                                icon.Cooldown:SetCooldownFromDurationObject(chargeDurObj)
                            end)
                            -- Set swipe color to black (like regular cooldown) instead of yellow (aura swipe)
                            if icon.Cooldown.SetSwipeColor then
                                icon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
                            end
                            -- Don't force desaturation for charge spells - let CDM handle it naturally
                        end
                    else
                        -- NORMAL SPELL: Use regular spell cooldown
                        local ok, cooldownInfo = pcall(C_Spell.GetSpellCooldown, spellID)
                        if ok and cooldownInfo and cooldownInfo.duration and cooldownInfo.startTime 
                           and type(cooldownInfo.duration) == "number" and type(cooldownInfo.startTime) == "number" then
                            icon.Cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
                            -- Set swipe color to black (like regular cooldown) instead of yellow (aura swipe)
                            if icon.Cooldown.SetSwipeColor then
                                icon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
                            end
                            -- Set force desaturation value - hooks will enforce it
                            icon.__nephuiForceDesatValue = 1
                            ApplyDesaturationForAuraActive(icon, true)
                        end
                    end
                end
            end
        end
    end
end

-- Event handler for aura changes
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_AURA" and unit == "player" then
        -- Refresh viewers when player auras change
        C_Timer.After(0.1, function()
            for _, viewerName in ipairs({"EssentialCooldownViewer", "UtilityCooldownViewer"}) do
                local viewer = _G[viewerName]
                if viewer and viewer:IsShown() and GetViewerSettings(viewerName) then
                    AuraOverride:RefreshViewer(viewer)
                end
            end
        end)
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        -- Refresh viewers when spell cooldowns update
        C_Timer.After(0.1, function()
            for _, viewerName in ipairs({"EssentialCooldownViewer", "UtilityCooldownViewer"}) do
                local viewer = _G[viewerName]
                if viewer and viewer:IsShown() and GetViewerSettings(viewerName) then
                    AuraOverride:RefreshViewer(viewer)
                end
            end
        end)
    end
end)

-- Initialize hooks for existing viewers
function AuraOverride:Initialize()
    local viewers = {
        "EssentialCooldownViewer",
        "UtilityCooldownViewer",
    }
    
    for _, viewerName in ipairs(viewers) do
        local viewer = _G[viewerName]
        if viewer then
            -- Hook the viewer's OnShow to refresh icons
            if not viewer.__nephuiAuraOverrideHooked then
                viewer.__nephuiAuraOverrideHooked = true
                viewer:HookScript("OnShow", function()
                    C_Timer.After(0.1, function()
                        AuraOverride:RefreshViewer(viewer)
                    end)
                end)
            end
            
            -- Initial refresh
            C_Timer.After(1.0, function()
                self:RefreshViewer(viewer)
            end)
        end
    end
    
    -- Hook into IconViewers to hook new icons as they're skinned
    if NephUI.IconViewers and NephUI.IconViewers.SkinIcon then
        local originalSkinIcon = NephUI.IconViewers.SkinIcon
        function NephUI.IconViewers:SkinIcon(icon, settings)
            local result = originalSkinIcon(self, icon, settings)
            
            -- Determine viewer name from settings
            local viewerName = nil
            for name, viewerSettings in pairs(NephUI.db.profile.viewers) do
                if viewerSettings == settings then
                    viewerName = name
                    break
                end
            end
            
            if viewerName and (viewerName == "EssentialCooldownViewer" or viewerName == "UtilityCooldownViewer") then
                AuraOverride:HookIconFrame(icon, viewerName)
            end
            
            return result
        end
    end
end

-- Initialize on load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2.0, function()
            AuraOverride:Initialize()
        end)
    end
end)

