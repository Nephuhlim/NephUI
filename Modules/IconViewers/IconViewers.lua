local ADDON_NAME, ns = ...
local NephUI = ns.Addon

NephUI.IconViewers = NephUI.IconViewers or {}
local IconViewers = NephUI.IconViewers

local viewers = NephUI.viewers or {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
}

local function IsCooldownIconFrame(frame)
    return frame and (frame.icon or frame.Icon) and frame.Cooldown
end

-- Update our layout after CooldownViewerSettings is shown or closed (login, /cdm, or player_entering_world).
local function EnsureCooldownViewerSettingsLayoutHook()
    if IconViewers.__cdmSettingsLayoutHooked then return end
    local settingsFrame = _G["CooldownViewerSettings"]
    if not settingsFrame then return end
    IconViewers.__cdmSettingsLayoutHooked = true
    settingsFrame:HookScript("OnShow", function()
        C_Timer.After(0.05, function()
            IconViewers:RefreshAll()
            if not InCombatLockdown() and IconViewers.ProcessPendingIcons then
                IconViewers:ProcessPendingIcons()
            end
        end)
    end)
    settingsFrame:HookScript("OnHide", function()
        C_Timer.After(0.05, function()
            IconViewers:RefreshAll()
            if not InCombatLockdown() and IconViewers.ProcessPendingIcons then
                IconViewers:ProcessPendingIcons()
            end
        end)
    end)
end

-- Refresh layout upon PLAYER_ENTERING_WORLD (after loading screen).
local function EnsurePlayerEnteringWorldRefresh()
    if IconViewers.__cdmEnteringWorldRegistered then return end
    IconViewers.__cdmEnteringWorldRegistered = true
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(0.1, function()
                IconViewers:RefreshAll()
                if not InCombatLockdown() and IconViewers.ProcessPendingIcons then
                    IconViewers:ProcessPendingIcons()
                end
            end)
        end
    end)
end

function IconViewers:ApplyViewerSkin(viewer)
    if not viewer or not viewer.GetName then return end
    local name     = viewer:GetName()
    local settings = NephUI.db.profile.viewers[name]
    if not settings or not settings.enabled then return end

    if self.ApplyViewerLayout then
        self:ApplyViewerLayout(viewer)
    end
    if self.SkinAllIconsInViewer then
        self:SkinAllIconsInViewer(viewer)
    end
    if self.ApplyViewerLayout then
        self:ApplyViewerLayout(viewer)
    end
    if NephUI.ResourceBars and NephUI.ResourceBars.UpdatePowerBar then
        NephUI.ResourceBars:UpdatePowerBar()
    end
    if NephUI.ResourceBars and NephUI.ResourceBars.UpdateSecondaryPowerBar then
        NephUI.ResourceBars:UpdateSecondaryPowerBar()
    end
    if NephUI.CastBars and NephUI.CastBars.UpdateCastBarLayout then
        NephUI.CastBars:UpdateCastBarLayout()
    end
    
    if not InCombatLockdown() then
        self:ProcessPendingIcons()
    end
end

function IconViewers:ProcessPendingIcons()
    if not NephUI.__cdmPendingIcons then return end
    if InCombatLockdown() then return end
    
    local processed = {}
    for icon, data in pairs(NephUI.__cdmPendingIcons) do
        if icon and icon:IsShown() and not icon.__cdmSkinned then
            local success = pcall(self.SkinIcon, self, icon, data.settings)
            if success then
                icon.__cdmSkinPending = nil
                processed[icon] = true
            end
        elseif not icon or not icon:IsShown() then
            processed[icon] = true
        end
    end
    
    -- Also process icons that were partially skinned but need border created/updated
    for _, name in ipairs(viewers) do
        local viewer = _G[name]
        if viewer and viewer:IsShown() then
            local container = viewer.viewerFrame or viewer
            for _, child in ipairs({ container:GetChildren() }) do
                if IsCooldownIconFrame(child) and child.__cdmBorderPending and not InCombatLockdown() then
                    local settings = NephUI.db.profile.viewers[name]
                    if settings and settings.enabled then
                        -- Re-skin just the border part
                        local border = child.__CDM_Border
                        if not border then
                            local iconTexture = child.icon or child.Icon
                            if iconTexture then
                                border = CreateFrame("Frame", nil, child, "BackdropTemplate")
                                border:ClearAllPoints()
                                border:SetPoint("TOPLEFT", iconTexture, "TOPLEFT", 0, 0)
                                border:SetPoint("BOTTOMRIGHT", iconTexture, "BOTTOMRIGHT", 0, 0)
                                child.__CDM_Border = border
                            end
                        end
                        
                        if border then
                            local edgeSize = tonumber(settings.borderSize) or 1
                            if edgeSize <= 0 then
                                if border.SetBackdrop then
                                    local ok = pcall(border.SetBackdrop, border, nil)
                                    if ok then
                                        border:Hide()
                                    end
                                end
                            else
                                local backdropInfo = {
                                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                                    edgeSize = edgeSize,
                                }
                                -- Check dimensions are safe before setting backdrop
                                local widthOk, width = pcall(border.GetWidth, border)
                                local heightOk, height = pcall(border.GetHeight, border)
                                local dimensionsOk = false
                                if widthOk and heightOk and width and height then
                                    local testOk = pcall(function() return width + height end)
                                    dimensionsOk = testOk and width > 0 and height > 0
                                end
                                
                                if dimensionsOk then
                                    local ok = pcall(border.SetBackdrop, border, backdropInfo)
                                    if ok then
                                        border:Show()
                                        local r, g, b, a = unpack(settings.borderColor or { 0, 0, 0, 1 })
                                        border:SetBackdropBorderColor(r, g, b, a or 1)
                                    end
                                end
                            end
                            child.__cdmBorderPending = nil
                            child.__cdmSkinned = true
                        end
                    end
                end
            end
        end
    end
    
    for icon in pairs(processed) do
        NephUI.__cdmPendingIcons[icon] = nil
    end
    
    if not next(NephUI.__cdmPendingIcons) then
        NephUI.__cdmPendingIcons = nil
    end
end

function IconViewers:HookViewers()
    for _, name in ipairs(viewers) do
        local viewer = _G[name]
        if viewer and not viewer.__cdmHooked then
            viewer.__cdmHooked = true

            viewer:HookScript("OnShow", function(f)
                IconViewers:ApplyViewerSkin(f)
            end)

            -- Skinning will be handled by RefreshAll call in main initialization

            viewer:HookScript("OnSizeChanged", function(f)
                if f.__cdmLayoutSuppressed or f.__cdmLayoutRunning then
                    return
                end
                if IconViewers.ApplyViewerLayout then
                    IconViewers:ApplyViewerLayout(f)
                end
            end)

            -- Blizzard Cooldown Viewer API: RefreshLayout() is called when the viewer layout updates
            -- (e.g. after changing spells in Cooldown Manager). Re-apply our layout and skinning.
            hooksecurefunc(viewer, "RefreshLayout", function()
                if not viewer:IsShown() then return end
                C_Timer.After(0, function()
                    if viewer:IsShown() then
                        IconViewers:ApplyViewerSkin(viewer)
                    end
                end)
            end)

            -- Event-based updates instead of OnUpdate for better performance
            if name == "BuffIconCooldownViewer" then
                -- Buff viewer: refresh when Blizzard aura events fire on icon frames
                if not viewer.__cdmBuffIconOnShowHook then
                    viewer.__cdmBuffIconOnShowHook = true
                    viewer:HookScript("OnShow", function()
                        if IconViewers.RescanViewer then
                            IconViewers:RescanViewer(viewer)
                        end
                    end)
                end

                -- Minimal OnUpdate for pending icons only
                local lastProcessTime = 0
                viewer:HookScript("OnUpdate", function(f, elapsed)
                    lastProcessTime = lastProcessTime + elapsed
                    if lastProcessTime > 1.0 and not InCombatLockdown() then -- Process once per second
                        lastProcessTime = 0
                        IconViewers:ProcessPendingIcons()
                    end
                end)

                -- 0.5s ticker: BuffIconCooldownViewer only (no global RefreshAll / other viewers)
                if not viewer.__cdmLayoutTicker then
                    viewer.__cdmLayoutTicker = C_Timer.NewTicker(0.5, function()
                        local buffViewer = _G["BuffIconCooldownViewer"]
                        if buffViewer and buffViewer:IsShown() and IconViewers.RescanViewer then
                            IconViewers:RescanViewer(buffViewer)
                        end
                    end)
                end
            else
                -- Other viewers: use SPELL_UPDATE_COOLDOWN and other events
                if not viewer.__cdmCooldownHook then
                    viewer.__cdmCooldownHook = CreateFrame("Frame")
                    viewer.__cdmCooldownHook:RegisterEvent("SPELL_UPDATE_COOLDOWN")
                    viewer.__cdmCooldownHook:RegisterEvent("BAG_UPDATE_COOLDOWN")
                    viewer.__cdmCooldownHook:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
                    viewer.__cdmCooldownHook:SetScript("OnEvent", function(_, event)
                        if viewer:IsShown() then
                            -- Throttled rescan to avoid spam during heavy cooldown usage
                            if not viewer.__cdmRescanPending then
                                viewer.__cdmRescanPending = true
                                C_Timer.After(0.2, function()
                                    viewer.__cdmRescanPending = nil
                                    if viewer:IsShown() and IconViewers.RescanViewer then
                                        IconViewers:RescanViewer(viewer)
                                    end
                                end)
                            end
                        end
                    end)
                end

                -- Minimal OnUpdate for pending icons only
                local lastProcessTime = 0
                viewer:HookScript("OnUpdate", function(f, elapsed)
                    lastProcessTime = lastProcessTime + elapsed
                    if lastProcessTime > 2.0 and not InCombatLockdown() then -- Process every 2 seconds
                        lastProcessTime = 0
                        IconViewers:ProcessPendingIcons()
                    end
                end)
            end

            self:ApplyViewerSkin(viewer)
        end
    end

    -- When CooldownViewerSettings is shown or closed (login or /cdm), update our layout.
    EnsureCooldownViewerSettingsLayoutHook()
    if not IconViewers.__cdmSettingsLayoutHooked then
        C_Timer.After(0.5, EnsureCooldownViewerSettingsLayoutHook)
        C_Timer.After(1.5, EnsureCooldownViewerSettingsLayoutHook)
    end

    -- Refresh layout upon PLAYER_ENTERING_WORLD (after loading screen / close CooldownViewerSettings).
    EnsurePlayerEnteringWorldRefresh()
end

function IconViewers:ForceRefreshBuffIcons()
    local viewer = _G["BuffIconCooldownViewer"]
    if viewer and viewer:IsShown() then
        viewer.__cdmIconCount = nil
        if self.RescanViewer then
            self:RescanViewer(viewer)
        end
        if not InCombatLockdown() then
            self:ProcessPendingIcons()
        end
        print("|cff00ff00[NephUI] Force refreshed BuffIconCooldownViewer|r")
    end
end

function IconViewers:AutoLoadBuffIcons(retryCount)
    retryCount = retryCount or 0
    local maxRetries = 5
    
    local viewer = _G["BuffIconCooldownViewer"]
    if not viewer then
        if retryCount < maxRetries then
            C_Timer.After(1.0, function() IconViewers:AutoLoadBuffIcons(retryCount + 1) end)
            C_Timer.After(2.0, function() IconViewers:AutoLoadBuffIcons(retryCount + 1) end)
            C_Timer.After(3.0, function() IconViewers:AutoLoadBuffIcons(retryCount + 1) end)
        end
        return
    end
    
    viewer.__nephuiInitialLoading = true
    
    -- Open CooldownViewerSettings frame instead of showing BuffIconCooldownViewer
    local settingsFrame = _G["CooldownViewerSettings"]
    if settingsFrame then
        settingsFrame:Show()
        settingsFrame:Raise()

        if not settingsFrame.__nephuiLayoutHook then
            settingsFrame.__nephuiLayoutHook = true
            settingsFrame:HookScript("OnHide", function()
                local buffViewer = _G["CooldownViewerSettings"]
                if buffViewer and buffViewer:IsShown() and IconViewers.ApplyViewerLayout then
                    -- Delay slightly so the hide completes before relayout
                    C_Timer.After(0.05, function()
                        if buffViewer and buffViewer:IsShown() and IconViewers.ApplyViewerLayout and not InCombatLockdown() then
                            IconViewers:ApplyViewerLayout(buffViewer)
                        end
                    end)
                end
            end)
        end
    end
    
    local settings = NephUI.db.profile.viewers["BuffIconCooldownViewer"]
    if not settings or not settings.enabled then
        viewer.__nephuiInitialLoading = nil
        return
    end
    
    local function collectAllIcons(container)
        local icons = {}
        if not container or not container.GetNumChildren then return icons end
        
        local n = container:GetNumChildren() or 0
        for i = 1, n do
            local child = select(i, container:GetChildren())
            if child and IsCooldownIconFrame(child) then
                table.insert(icons, child)
            elseif child and child.GetNumChildren then
                local m = child:GetNumChildren() or 0
                for j = 1, m do
                    local grandchild = select(j, child:GetChildren())
                    if grandchild and IsCooldownIconFrame(grandchild) then
                        table.insert(icons, grandchild)
                    end
                end
            end
        end
        return icons
    end
    
    local container = viewer.viewerFrame or viewer
    local icons = collectAllIcons(container)
    
    local skinnedCount = 0
    local pendingCount = 0
    for _, icon in ipairs(icons) do
        if not icon:IsShown() then
            icon:Show()
        end
        
        if not icon.__cdmSkinned and not InCombatLockdown() then
            local success = pcall(self.SkinIcon, self, icon, settings)
            if success then
                skinnedCount = skinnedCount + 1
            end
        elseif not icon.__cdmSkinned then
            if not icon.__cdmSkinPending then
                icon.__cdmSkinPending = true
                if not NephUI.__cdmPendingIcons then
                    NephUI.__cdmPendingIcons = {}
                end
                NephUI.__cdmPendingIcons[icon] = { icon = icon, settings = settings, viewer = viewer }
                pendingCount = pendingCount + 1
            end
        end
    end
    
    if #icons > 0 and self.ApplyViewerLayout then
        self:ApplyViewerLayout(viewer)
    end
    
    local shouldRetry = false
    if #icons == 0 and retryCount < maxRetries then
        shouldRetry = true
        C_Timer.After(0.5, function() IconViewers:AutoLoadBuffIcons(retryCount + 1) end)
        C_Timer.After(1.5, function() IconViewers:AutoLoadBuffIcons(retryCount + 1) end)
        C_Timer.After(3.0, function() IconViewers:AutoLoadBuffIcons(retryCount + 1) end)
    elseif skinnedCount > 0 and retryCount < maxRetries then
        shouldRetry = true
        C_Timer.After(1.0, function() IconViewers:AutoLoadBuffIcons(retryCount + 1) end)
    end
    
    if not shouldRetry then
        viewer.__nephuiInitialLoading = nil
        
        -- Hide CooldownViewerSettings frame after a couple seconds
        C_Timer.After(2.0, function()
            local settingsFrame = _G["CooldownViewerSettings"]
            if settingsFrame and settingsFrame:IsShown() then
                settingsFrame:Hide()
            elseif not settingsFrame then
                -- If the frame vanished, still attempt a delayed relayout
                local buffViewer = _G["CooldownViewerSettings"]
                if buffViewer and buffViewer:IsShown() and IconViewers.ApplyViewerLayout and not InCombatLockdown() then
                    C_Timer.After(0.05, function()
                        if buffViewer and buffViewer:IsShown() and IconViewers.ApplyViewerLayout and not InCombatLockdown() then
                            IconViewers:ApplyViewerLayout(buffViewer)
                        end
                    end)
                end
            end
        end)
    end
end

function IconViewers:RefreshAll()
    for _, name in ipairs(viewers) do
        local viewer = _G[name]
        if viewer then
            self:ApplyViewerSkin(viewer)
        end
    end

    if self.BuffBarCooldownViewer and self.BuffBarCooldownViewer.Refresh then
        self.BuffBarCooldownViewer:Refresh()
    end
end

NephUI.ApplyViewerSkin = function(self, viewer) return IconViewers:ApplyViewerSkin(viewer) end
NephUI.HookViewers = function(self) return IconViewers:HookViewers() end
NephUI.AutoLoadBuffIcons = function(self, retryCount) return IconViewers:AutoLoadBuffIcons(retryCount) end
NephUI.ForceRefreshBuffIcons = function(self) return IconViewers:ForceRefreshBuffIcons() end
NephUI.ProcessPendingIcons = function(self) return IconViewers:ProcessPendingIcons() end

