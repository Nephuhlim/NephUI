local ADDON_NAME, ns = ...
local NephUI = ns.Addon

-- Create namespace
NephUI.AutoUIScale = NephUI.AutoUIScale or {}
local AutoUIScale = NephUI.AutoUIScale

function AutoUIScale:SetUIScale(scale)
    if not NephUI or not NephUI.ApplyGlobalUIScale then return end
    -- Apply scale to UIParent so the whole UI (and other addons) use it. Handles combat defer internally.
    NephUI:ApplyGlobalUIScale(scale)
    if NephUI.PixelScaleChanged then
        NephUI:PixelScaleChanged()
    end
end

function AutoUIScale:ApplySavedScale()
    -- Apply global UIParent scale so the entire UI (including other addons) is pixel-perfect.
    -- If the user has a saved scale, use it; otherwise apply the recommended scale for this resolution.
    if not NephUI then return end
    local savedScale
    if NephUI.db and NephUI.db.profile and NephUI.db.profile.general then
        savedScale = NephUI.db.profile.general.uiScale
    end
    if savedScale and type(savedScale) == "number" then
        AutoUIScale:SetUIScale(savedScale)
    else
        -- First load or no saved value: apply recommended pixel-perfect scale globally
        NephUI:ApplyGlobalUIScale(nil)
        if NephUI.PixelScaleChanged then
            NephUI:PixelScaleChanged()
        end
    end
end

function AutoUIScale:Initialize()
    -- Apply saved scale immediately
    self:ApplySavedScale()
    
    -- Also register for PLAYER_LOGIN to apply it as early as possible
    -- This ensures the scale is set before edit mode initializes
    if not self.loginHandlerRegistered then
        self.loginHandlerRegistered = true
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_LOGIN")
        frame:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_LOGIN" then
                AutoUIScale:ApplySavedScale()
                self:UnregisterEvent("PLAYER_LOGIN")
            end
        end)
    end
end

