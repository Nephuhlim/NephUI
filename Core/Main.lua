local ADDON_NAME, ns = ...

local NephUI = LibStub("AceAddon-3.0"):NewAddon(
    ADDON_NAME,
    "AceConsole-3.0",
    "AceEvent-3.0"
)

ns.Addon = NephUI

-- Get localization table (should be loaded by Locales/Locale.lua)
local L = ns.L or LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME, true) or {}

local AceSerializer = LibStub("AceSerializer-3.0", true)
local LibDeflate    = LibStub("LibDeflate", true)
local AceDBOptions = LibStub("AceDBOptions-3.0", true)
local LibDualSpec   = LibStub("LibDualSpec-1.0", true)

local WHITE8 = "Interface\\Buttons\\WHITE8X8"

local SELECTION_ALPHA = 0.5
local SelectionRegionKeys = {
    "Center",
    "MouseOverHighlight",
    "TopEdge",
    "BottomEdge",
    "LeftEdge",
    "RightEdge",
    "TopLeft",
    "TopRight",
    "BottomLeft",
    "BottomRight",
    "Left",
    "Right",
    "Top",
    "Bottom",
}

local function ApplyAlphaToRegion(region)
    if not region or not region.SetAlpha then
        return
    end

    region:SetAlpha(SELECTION_ALPHA)
    if region.HookScript and not region.__nephuiSelectionAlphaHooked then
        region.__nephuiSelectionAlphaHooked = true
        region:HookScript("OnShow", function(self)
            self:SetAlpha(SELECTION_ALPHA)
        end)
    end
end

local function ForceSelectionAlpha(selection)
    if not selection or not selection.SetAlpha then
        return
    end

    selection.__nephuiSelectionAlphaLock = true
    selection:SetAlpha(SELECTION_ALPHA)
    selection.__nephuiSelectionAlphaLock = nil
end

function NephUI:ApplySelectionAlpha(selection)
    if not selection then
        return
    end

    ForceSelectionAlpha(selection)

    if selection.HookScript and not selection.__nephuiSelectionOnShowHooked then
        selection.__nephuiSelectionOnShowHooked = true
        selection:HookScript("OnShow", function(self)
            NephUI:ApplySelectionAlpha(self)
        end)
    end

    if selection.SetAlpha and not selection.__nephuiSelectionAlphaHooked then
        selection.__nephuiSelectionAlphaHooked = true
        hooksecurefunc(selection, "SetAlpha", function(frame)
            if frame.__nephuiSelectionAlphaLock then
                return
            end
            ForceSelectionAlpha(frame)
        end)
    end

    for _, key in ipairs(SelectionRegionKeys) do
        ApplyAlphaToRegion(selection[key])
    end
end

function NephUI:ApplySelectionAlphaToFrame(frame)
    if not frame then
        return
    end
    if frame.IsForbidden and frame:IsForbidden() then
        return
    end
    if frame.Selection then
        self:ApplySelectionAlpha(frame.Selection)
    end
end

function NephUI:ApplySelectionAlphaToAllFrames()
    local frame = EnumerateFrames()
    while frame do
        self:ApplySelectionAlphaToFrame(frame)
        frame = EnumerateFrames(frame)
    end
end

function NephUI:InitializeSelectionAlphaController()
    if self.__selectionAlphaInitialized then
        return
    end
    self.__selectionAlphaInitialized = true

    local function TryHookSelectionMixin()
        if self.__selectionMixinHooked then
            return true
        end
        if EditModeSelectionFrameBaseMixin then
            self.__selectionMixinHooked = true
            hooksecurefunc(EditModeSelectionFrameBaseMixin, "OnLoad", function(selectionFrame)
                NephUI:ApplySelectionAlpha(selectionFrame)
            end)
            hooksecurefunc(EditModeSelectionFrameBaseMixin, "OnShow", function(selectionFrame)
                NephUI:ApplySelectionAlpha(selectionFrame)
            end)
            return true
        end
        return false
    end

    if not TryHookSelectionMixin() then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("ADDON_LOADED")
        waiter:SetScript("OnEvent", function(self, _, addonName)
            if addonName == "Blizzard_EditMode" or addonName == ADDON_NAME then
                if TryHookSelectionMixin() then
                    self:UnregisterEvent("ADDON_LOADED")
                    self:SetScript("OnEvent", nil)
                end
            end
        end)
    end

    self:ApplySelectionAlphaToAllFrames()
    C_Timer.After(0.5, function()
        NephUI:ApplySelectionAlphaToAllFrames()
    end)

    self.SelectionAlphaTicker = C_Timer.NewTicker(1.0, function()
        if EditModeManagerFrame and EditModeManagerFrame.editModeActive then
            NephUI:ApplySelectionAlphaToAllFrames()
        end
    end)
end

local function DeepCopyTable(source, seen)
    if type(source) ~= "table" then
        return source
    end

    seen = seen or {}
    if seen[source] then
        return seen[source]
    end

    local copy = {}
    seen[source] = copy

    for key, value in pairs(source) do
        copy[DeepCopyTable(key, seen)] = DeepCopyTable(value, seen)
    end

    return copy
end

local function NormalizeResourceBarAssignments(assignments)
    if type(assignments) ~= "table" then
        return nil
    end

    local cleaned = {}
    for classKey, classAssignments in pairs(assignments) do
        if type(classKey) == "string" and type(classAssignments) == "table" then
            local classOut = {}
            for specKey, specAssignments in pairs(classAssignments) do
                local specId = specKey
                if type(specKey) == "string" then
                    specId = tonumber(specKey) or specKey
                end

                if (type(specId) == "number" or type(specId) == "string") and type(specAssignments) == "table" then
                    local specOut = {}
                    for resourceKey, value in pairs(specAssignments) do
                        local outKey = nil
                        if type(resourceKey) == "number" then
                            outKey = tostring(resourceKey)
                        elseif type(resourceKey) == "string" then
                            outKey = resourceKey
                        end

                        if outKey and (value == "primary" or value == "secondary" or value == "hide") then
                            specOut[outKey] = value
                        end
                    end

                    if next(specOut) then
                        classOut[specId] = specOut
                    end
                end
            end

            if next(classOut) then
                cleaned[classKey] = classOut
            end
        end
    end

    return cleaned
end

local function SanitizeResourceBarAssignments(db)
    if not db or not db.sv or type(db.sv.profiles) ~= "table" then
        return
    end

    for _, profile in pairs(db.sv.profiles) do
        if type(profile) == "table" then
            local cleaned = NormalizeResourceBarAssignments(profile.resourceBarAssignments)
            if cleaned then
                profile.resourceBarAssignments = cleaned
            elseif profile.resourceBarAssignments ~= nil then
                profile.resourceBarAssignments = {}
            end
        end
    end
end

local function LooksLikeCooldownManagerProfile(profile)
    if type(profile) ~= "table" then
        return false
    end

    if profile.viewers or profile.cooldownManager_keybindFontName then
        return true
    end

    if profile.cooldownManager_showKeybinds_Essential
        or profile.cooldownManager_showKeybinds_Utility
        or profile.customIcons
        or profile.dynamicIcons then
        return true
    end

    return false
end

local function LooksLikeCooldownManagerDB(db)
    if type(db) ~= "table" then
        return false
    end

    if type(db.profiles) == "table" then
        for _, profile in pairs(db.profiles) do
            if LooksLikeCooldownManagerProfile(profile) then
                return true
            end
        end
    end

    if LooksLikeCooldownManagerProfile(db) then
        return true
    end

    return false
end

-- Merges legacy data into the existing SavedVariable table. Never replace _G["NephUIDB"]:
-- AceDB holds a reference to that table; replacing it would make runtime writes go to the
-- old table while WoW saves the new one, so nothing would persist.
function NephUI:ImportLegacyCooldownManagerDB()
    local sv = self.db and self.db.sv
    if not sv or sv ~= _G["NephUIDB"] then
        return false
    end
    if type(sv) ~= "table" or next(sv) ~= nil then
        return false
    end

    local legacyCandidates = {
        "NephUICooldownManagerDB",
        "NephUICooldownManager",
        "NephUICDMDB",
        "NephUICooldownDB",
        "NephUICooldownViewerDB",
        "CooldownManagerDB",
    }

    for _, name in ipairs(legacyCandidates) do
        local legacy = _G[name]
        if LooksLikeCooldownManagerDB(legacy) then
            local imported = DeepCopyTable(legacy)
            if not imported.profiles then
                imported = {
                    profileKeys = {},
                    profiles = {
                        Default = DeepCopyTable(legacy),
                    },
                }
            end

            -- Merge into existing sv so WoW keeps saving the same table AceDB uses
            if not sv.profileKeys then sv.profileKeys = {} end
            for k in pairs(sv.profileKeys) do sv.profileKeys[k] = nil end
            for k, v in pairs(imported.profileKeys or {}) do
                sv.profileKeys[k] = v
            end

            if not sv.profiles then sv.profiles = {} end
            for k in pairs(sv.profiles) do sv.profiles[k] = nil end
            for k, v in pairs(imported.profiles or {}) do
                sv.profiles[k] = DeepCopyTable(v)
            end

            if imported.global and type(imported.global) == "table" then
                if not sv.global then sv.global = {} end
                for k in pairs(sv.global) do sv.global[k] = nil end
                for k, v in pairs(imported.global) do
                    sv.global[k] = type(v) == "table" and DeepCopyTable(v) or v
                end
            end

            if imported.namespaces and type(imported.namespaces) == "table" then
                if not sv.namespaces then sv.namespaces = {} end
                for ns, data in pairs(imported.namespaces) do
                    sv.namespaces[ns] = type(data) == "table" and DeepCopyTable(data) or data
                end
            end

            sv.__nephuiLegacySource = name
            return true, name
        end
    end

    return false
end

function NephUI:ExportProfileToString()
    if not self.db or not self.db.profile then
        return L["No profile loaded."] or "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return L["Export requires AceSerializer-3.0 and LibDeflate."] or "Export requires AceSerializer-3.0 and LibDeflate."
    end

    local serialized = AceSerializer:Serialize(self.db.profile)
    if not serialized or type(serialized) ~= "string" then
        return L["Failed to serialize profile."] or "Failed to serialize profile."
    end

    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then
        return L["Failed to compress profile."] or "Failed to compress profile."
    end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return L["Failed to encode profile."] or "Failed to encode profile."
    end

    return "NUI1:" .. encoded
end

function NephUI:ImportProfileFromString(str, profileName)
    if not self.db then
        return false, L["No profile loaded."] or "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return false, L["Import requires AceSerializer-3.0 and LibDeflate."] or "Import requires AceSerializer-3.0 and LibDeflate."
    end
    if not str or str == "" then
        return false, L["No data provided."] or "No data provided."
    end

    str = str:gsub("%s+", "")
    str = str:gsub("^CDM1:", "")
    str = str:gsub("^NUI1:", "")

    local compressed = LibDeflate:DecodeForPrint(str)
    if not compressed then
        return false, L["Could not decode string (maybe corrupted)."] or "Could not decode string (maybe corrupted)."
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return false, L["Could not decompress data."] or "Could not decompress data."
    end

    local ok, t = AceSerializer:Deserialize(serialized)
    if not ok or type(t) ~= "table" then
        return false, L["Could not deserialize profile."] or "Could not deserialize profile."
    end

    -- If profileName is provided, create a new profile
    if profileName and profileName ~= "" then
        -- Ensure unique name by checking if profile already exists
        local baseName = profileName
        local counter = 1
        while self.db.profiles and self.db.profiles[profileName] do
            counter = counter + 1
            profileName = baseName .. " " .. counter
        end

        -- Create the new profile
        if not self.db.profiles then
            return false, L["Profile system not available."] or "Profile system not available."
        end

        self.db.profiles[profileName] = t
        self.db:SetProfile(profileName)
    else
        -- Old behavior: overwrite current profile (for backwards compatibility)
        if not self.db.profile then
            return false, L["No profile loaded."] or "No profile loaded."
        end
        local profile = self.db.profile
        for k in pairs(profile) do
            profile[k] = nil
        end
        for k, v in pairs(t) do
            profile[k] = v
        end
    end

    if self.RefreshAll then
        self:RefreshAll()
    end

    return true
end

-- Wago UI Pack Installer Integration Functions
function NephUI:ExportNephUI(profileKey)
    local profile = self.db.profiles[profileKey]
    if not profile then return nil end

    local profileData = { profile = profile, }

    local SerializedInfo = AceSerializer:Serialize(profileData)
    local CompressedInfo = LibDeflate:CompressDeflate(SerializedInfo)
    local EncodedInfo = LibDeflate:EncodeForPrint(CompressedInfo)
    EncodedInfo = "!NephUI_" .. EncodedInfo
    return EncodedInfo
end

function NephUI:ImportNephUI(importString, profileKey)
    local DecodedInfo = LibDeflate:DecodeForPrint(importString:sub(9))
    local DecompressedInfo = LibDeflate:DecompressDeflate(DecodedInfo)
    local success, profileData = AceSerializer:Deserialize(DecompressedInfo)

    if not success or type(profileData) ~= "table" then 
        print("|cFF8080FF" .. (L["NephUI: Invalid Import String."] or "NephUI: Invalid Import String.") .. "|r") 
        return 
    end

    if type(profileData.profile) == "table" then
        self.db.profiles[profileKey] = profileData.profile
        self.db:SetProfile(profileKey)
    end
end

function NephUI:OnInitialize()
    local defaults = NephUI.defaults
    if not defaults then
        error("NephUI: Defaults not loaded! Make sure Core/Defaults.lua is loaded before Core/Main.lua")
    end
    
    -- Use a unique database namespace to avoid conflicts with other addons
    -- The name must match the SavedVariables in NephUI.toc
    self.db = LibStub("AceDB-3.0"):New("NephUIDB", defaults, true)
    
    -- Verify the database was created with the correct namespace
    if not self.db or not self.db.sv then
        error("NephUI: Failed to initialize database! Check SavedVariables in NephUI.toc")
    end

    -- AceDB strips values that match defaults at PLAYER_LOGOUT, so SavedVariables only
    -- contains overrides and looks nearly empty. Prevent that so the full profile is saved.
    do
        local origRegisterDefaults = self.db.RegisterDefaults
        self.db.RegisterDefaults = function(db, defaults)
            if defaults == nil then
                db.defaults = nil
                return
            end
            return origRegisterDefaults(db, defaults)
        end
    end

    -- Touch every top-level profile key so the full default structure is in the profile
    -- table; then at logout (without strip above) the whole profile is saved.
    do
        local p = self.db.profile
        for key in pairs(defaults.profile) do
            p[key] = p[key]
        end
    end

    ns.db = self.db

    -- Ensure resource assignments are serialized safely across profiles
    SanitizeResourceBarAssignments(self.db)

    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied",  "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset",   "OnProfileChanged")
    
    -- Create ShadowUIParent for hiding UI elements
    self.ShadowUIParent = CreateFrame("Frame", nil, UIParent)
    self.ShadowUIParent:Hide()

    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(self.db, ADDON_NAME)
        -- Debug: verify LibDualSpec is working
        if self.db.IsDualSpecEnabled then
            -- LibDualSpec is properly initialized
        end
    else
        -- LibDualSpec not available (may be disabled in Classic Era for non-Season realms)
    end

    self:InitializePixelPerfect()

    self:SetupOptions()
    
    self:RegisterChatCommand("nephui", "OpenConfig")
    self:RegisterChatCommand("nephuirefresh", "ForceRefreshBuffIcons")
    self:RegisterChatCommand("nephuicheckdualspec", "CheckDualSpec")
    self:RegisterChatCommand("cdm", "OpenCooldownViewerSettings")
    self:RegisterChatCommand("wa", "OpenCooldownViewerSettings")
    
    self:CreateMinimapButton()
end

function NephUI:OnProfileChanged(event, db, profileKey)
    if self.RefreshAll then
        -- Defer RefreshAll if in combat to avoid taint/secret value errors
        if InCombatLockdown() then
            if not self.__pendingRefreshAll then
                self.__pendingRefreshAll = true
                local eventFrame = CreateFrame("Frame")
                eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                eventFrame:SetScript("OnEvent", function(self)
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    if NephUI.RefreshAll and not InCombatLockdown() then
                        NephUI:RefreshAll()
                    end
                    NephUI.__pendingRefreshAll = nil
                end)
            end
        else
            self:RefreshAll()
        end
    end
end

local function EnsureProfileTable(db, key)
    if not db or not db.profile then
        return nil
    end
    if type(db.profile[key]) ~= "table" then
        db.profile[key] = {}
    end
    return db.profile[key]
end

local function IsElvUILoaded()
    if not C_AddOns or not C_AddOns.IsAddOnLoaded then
        return false
    end
    return C_AddOns.IsAddOnLoaded("ElvUI")
end

function NephUI:ShowElvUIConflictPopup()
    if not self.db or not self.db.profile then
        return
    end

    local frame = self.ElvUIConflictPopup
    if not frame then
        frame = CreateFrame("Frame", "NephUIElvUIConflictPopup", UIParent, "BackdropTemplate")
        frame:SetSize(420, 280)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(100)
        frame:SetClampedToScreen(true)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
        end)

        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", 0, -16)
        title:SetText("ElvUI detected")
        frame.Title = title

        local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        desc:SetPoint("TOP", title, "BOTTOM", 0, -8)
        desc:SetText("To avoid conflicts, disable these NephUI features:")
        frame.Description = desc

        local function CreateConflictCheckbox(label, anchor)
            local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
            if check.Text then
                check.Text:SetText(label)
            end
            return check
        end

        local firstAnchor = desc

        frame.UnitFramesCheck = CreateConflictCheckbox("Disable Unit Frames", firstAnchor)
        frame.ActionBarsCheck = CreateConflictCheckbox("Disable Action Bars", frame.UnitFramesCheck)
        frame.MinimapCheck = CreateConflictCheckbox("Disable Minimap", frame.ActionBarsCheck)
        frame.MicroMenuCheck = CreateConflictCheckbox("Disable Micro Menu skinning", frame.MinimapCheck)

        local reloadButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        reloadButton:SetSize(140, 24)
        reloadButton:SetPoint("BOTTOM", 0, 16)
        reloadButton:SetText("Reload UI")
        frame.ReloadButton = reloadButton

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -4, -4)
        frame.CloseButton = closeButton

        local function SetElvUIPopupDismissed()
            local conflicts = EnsureProfileTable(self.db, "conflicts")
            if conflicts then
                conflicts.elvuiPopupDismissed = true
            end
        end

        local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        cancelButton:SetSize(90, 22)
        cancelButton:SetPoint("RIGHT", reloadButton, "LEFT", -10, 0)
        cancelButton:SetText("Cancel")
        cancelButton:SetScript("OnClick", function()
            SetElvUIPopupDismissed()
            frame:Hide()
        end)
        frame.CancelButton = cancelButton

        closeButton:SetScript("OnClick", function()
            SetElvUIPopupDismissed()
            frame:Hide()
        end)

        reloadButton:SetScript("OnClick", function()
            local unitFrames = EnsureProfileTable(self.db, "unitFrames")
            local actionBars = EnsureProfileTable(self.db, "actionBars")
            local minimap = EnsureProfileTable(self.db, "minimap")
            local qol = EnsureProfileTable(self.db, "qol")

            if frame.UnitFramesCheck:GetChecked() and unitFrames then
                unitFrames.enabled = false
            end
            if frame.ActionBarsCheck:GetChecked() and actionBars then
                actionBars.enabled = false
            end
            if frame.MinimapCheck:GetChecked() and minimap then
                minimap.enabled = false
            end
            if frame.MicroMenuCheck:GetChecked() and qol then
                qol.microMenuSkinning = false
            end

            SetElvUIPopupDismissed()
            ReloadUI()
        end)

        self.ElvUIConflictPopup = frame
    end

    local db = self.db.profile
    frame.UnitFramesCheck:SetChecked(db.unitFrames and db.unitFrames.enabled ~= false)
    frame.ActionBarsCheck:SetChecked(db.actionBars and db.actionBars.enabled ~= false)
    frame.MinimapCheck:SetChecked(db.minimap and db.minimap.enabled ~= false)
    frame.MicroMenuCheck:SetChecked(db.qol and db.qol.microMenuSkinning ~= false)

    frame:Show()
    frame:Raise()
end

function NephUI:MaybeShowElvUIConflictPopup()
    if self.__elvuiConflictPopupShown then
        return
    end
    if not IsElvUILoaded() then
        return
    end
    if not self.db or not self.db.profile then
        return
    end

    local db = self.db.profile
    if db.conflicts and db.conflicts.elvuiPopupDismissed then
        return
    end
    local unitFramesEnabled = db.unitFrames and db.unitFrames.enabled ~= false
    local actionBarsEnabled = db.actionBars and db.actionBars.enabled ~= false
    local minimapEnabled = db.minimap and db.minimap.enabled ~= false
    local microMenuEnabled = db.qol and db.qol.microMenuSkinning ~= false

    if not (unitFramesEnabled or actionBarsEnabled or minimapEnabled or microMenuEnabled) then
        return
    end

    if InCombatLockdown() then
        if not self.__pendingElvUIConflictPopup then
            self.__pendingElvUIConflictPopup = true
            local eventFrame = CreateFrame("Frame")
            eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            eventFrame:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                NephUI.__pendingElvUIConflictPopup = nil
                NephUI:MaybeShowElvUIConflictPopup()
            end)
        end
        return
    end

    self.__elvuiConflictPopupShown = true
    self:ShowElvUIConflictPopup()
end

function NephUI:InitializePixelPerfect()
    self.physicalWidth, self.physicalHeight = GetPhysicalScreenSize()
    self.resolution = string.format('%dx%d', self.physicalWidth, self.physicalHeight)
    self.perfect = 768 / self.physicalHeight
    if UIParent and UIParent.GetScale then
        self.uiscale = UIParent:GetScale()
    end
    self:UIMult()
    self:RegisterEvent('UI_SCALE_CHANGED')
end

function NephUI:UI_SCALE_CHANGED()
    self:PixelScaleChanged('UI_SCALE_CHANGED')
    -- Re-apply our global scale so we keep control after resolution/scale changes
    if self.AutoUIScale and self.AutoUIScale.ApplySavedScale then
        self.AutoUIScale:ApplySavedScale()
    end
end

local function StyleMicroButtonRegion(button, region)
    if not (button and region) then
        return
    end
    if region.__nephuiStyled then
        return
    end

    region.__nephuiStyled = true
    region:SetTexture(WHITE8)
    region:SetVertexColor(0, 0, 0, 1)
    region:SetAlpha(0.8)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", button, 2.5, -2.5)
    region:SetPoint("BOTTOMRIGHT", button, -2.5, 2.5)
end

local function StyleMicroButton(button)
    if not button then
        return
    end
    StyleMicroButtonRegion(button, button.Background)
    StyleMicroButtonRegion(button, button.PushedBackground)
end

function NephUI:StyleMicroButtons()
    local db = self.db and self.db.profile and self.db.profile.qol
    if db and db.microMenuSkinning == false then
        return
    end
    if type(MICRO_BUTTONS) == "table" then
        for _, name in ipairs(MICRO_BUTTONS) do
            StyleMicroButton(_G[name])
        end
    end
    -- Fallback if MICRO_BUTTONS is missing
    StyleMicroButton(_G.CharacterMicroButton)
end

function NephUI:PLAYER_LOGIN()
    if self.ApplyGlobalFont then
        self:ApplyGlobalFont()
    end
    
    -- Initialize unit frame anchoring if enabled (after all addons are loaded)
    local cfg = self.db.profile.viewers.general
    if cfg and cfg.anchorToUnitFrame then
        if self.UpdateViewerUnitFrameAnchor then
            -- Apply multiple times with increasing delays to ensure it works after all addons load
            local delays = {0.5, 1.0, 2.0, 3.0, 5.0}
            for _, delay in ipairs(delays) do
                C_Timer.After(delay, function()
                    self:UpdateViewerUnitFrameAnchor()
                end)
            end
        end
    end
    
    self:UnregisterEvent("PLAYER_LOGIN")
end

function NephUI:PLAYER_ENTERING_WORLD()
    -- Setup hooks and apply anchors if the toggle is enabled
    -- Use the exact same logic as when the toggle is enabled in config
    local cfg = self.db.profile.viewers.general
    if cfg and cfg.anchorToUnitFrame then
        if self.UpdateViewerUnitFrameAnchor then
            -- Apply multiple times with increasing delays to override other addons.
            -- ~2s delay is important for reload: UUF/ElvUI frames are created in OnEnable
            -- after ADDON_LOADED; this ensures we run after they exist.
            local delays = {0.5, 1.5, 2.0, 3.0, 5.0}
            for _, delay in ipairs(delays) do
                C_Timer.After(delay, function()
                    self:UpdateViewerUnitFrameAnchor()
                end)
            end
        end
    end
end

-- Unit frame addons we want to re-apply anchors after
local unitFrameAddons = {
    ["UnhaltedUnitFrames"] = true,
    ["ElvUI"] = true,
    ["ElvUI_Libraries"] = true,
    ["ElvUI_Options"] = true,
    ["ShadowedUnitFrames"] = true,
    ["Pitbull4"] = true,
    ["Grid2"] = true,
}

function NephUI:ADDON_LOADED(_, addonName)
    -- Re-apply anchors when a unit frame addon finishes loading
    if unitFrameAddons[addonName] then
        local cfg = self.db and self.db.profile and self.db.profile.viewers and self.db.profile.viewers.general
        if cfg and cfg.anchorToUnitFrame and self.UpdateViewerUnitFrameAnchor then
            -- Delay to let the addon initialize its frames (OnEnable runs after ADDON_LOADED).
            -- UUF creates frames in OnEnable; 2s and 2.5s help with reload timing.
            C_Timer.After(1.0, function()
                self:UpdateViewerUnitFrameAnchor()
            end)
            C_Timer.After(2.0, function()
                self:UpdateViewerUnitFrameAnchor()
            end)
            C_Timer.After(2.5, function()
                self:UpdateViewerUnitFrameAnchor()
            end)
        end
    end
end

function NephUI:OnEnable()
    SetCVar("cooldownViewerEnabled", 1)
    
    if self.UIMult then
        self:UIMult()
    end
    
    if self.AutoUIScale and self.AutoUIScale.Initialize then
        self.AutoUIScale:Initialize()
    end
    
    if self.ApplyGlobalFont then
        C_Timer.After(0.5, function()
            self:ApplyGlobalFont()
        end)
    end
    
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ADDON_LOADED")
    
    -- Initialize anchoring immediately on enable (for reload scenarios)
    -- PLAYER_ENTERING_WORLD might have already fired before OnEnable
    local cfg = self.db.profile.viewers.general
    if cfg and cfg.anchorToUnitFrame then
        if self.UpdateViewerUnitFrameAnchor then
            -- Apply multiple times with increasing delays to ensure it works
            local delays = {0.1, 0.5, 1.0, 2.0, 3.0, 5.0}
            for _, delay in ipairs(delays) do
                C_Timer.After(delay, function()
                    self:UpdateViewerUnitFrameAnchor()
                end)
            end
        end
    end
    
    C_Timer.After(0.1, function()
        NephUI:StyleMicroButtons()
    end)
    
    if self.IconViewers and self.IconViewers.HookViewers then
        self.IconViewers:HookViewers()
    end

    if self.IconViewers and self.IconViewers.BuffBarCooldownViewer and self.IconViewers.BuffBarCooldownViewer.Initialize then
        self.IconViewers.BuffBarCooldownViewer:Initialize()
    end

    if self.ProcGlow and self.ProcGlow.Initialize then
        C_Timer.After(1.0, function()
            self.ProcGlow:Initialize()
        end)
    end

    if self.Keybinds and self.Keybinds.Initialize then
        C_Timer.After(1.0, function()
            self.Keybinds:Initialize()
        end)
    end

    if self.CastBars and self.CastBars.Initialize then
        self.CastBars:Initialize()
    end
    
    if self.ResourceBars and self.ResourceBars.Initialize then
        self.ResourceBars:Initialize()
    end

    if self.UnitFrames and self.UnitFrames.Initialize then
        self.UnitFrames:Initialize()
    end

    if self.AbsorbBars and self.AbsorbBars.Initialize then
        local ufDb = self.db and self.db.profile and self.db.profile.unitFrames
        if not ufDb or ufDb.enabled ~= false then
            C_Timer.After(0.5, function()
                self.AbsorbBars:Initialize()
            end)
        end
    end

    if self.QOL and self.QOL.Initialize then
        self.QOL:Initialize()
    end
    
    if self.Chat and self.Chat.Initialize then
        self.Chat:Initialize()
    end
    
    C_Timer.After(0.1, function()
        if self.CastBars and self.CastBars.HookTargetAndFocusCastBars then
            self.CastBars:HookTargetAndFocusCastBars()
        end
        if self.CastBars and self.CastBars.HookFocusCastBar then
            self.CastBars:HookFocusCastBar()
        end
        if self.CastBars and self.CastBars.HookBossCastBars then
            self.CastBars:HookBossCastBars()
        end
    end)
    
    
    if self.IconViewers and self.IconViewers.AutoLoadBuffIcons then
        C_Timer.After(0.5, function()
            self.IconViewers:AutoLoadBuffIcons()
        end)
    end

    -- Ensure all viewers are skinned on load
    if self.IconViewers and self.IconViewers.RefreshAll then
        C_Timer.After(1.0, function()
            self.IconViewers:RefreshAll()
        end)
    end
    
    if self.CustomIcons then
        C_Timer.After(1.5, function()
            if self.CustomIcons.CreateCustomIconsTrackerFrame then
                self.CustomIcons:CreateCustomIconsTrackerFrame()
            end
            if self.CustomIcons.CreateTrinketsTrackerFrame then
                self.CustomIcons:CreateTrinketsTrackerFrame()
            end
            if self.CustomIcons.CreateDefensivesTrackerFrame then
                self.CustomIcons:CreateDefensivesTrackerFrame()
            end
        end)

        C_Timer.After(2.5, function()
            if self.CustomIcons.ApplyCustomIconsLayout then
                self.CustomIcons:ApplyCustomIconsLayout()
            end
            if self.CustomIcons.ApplyTrinketsLayout then
                self.CustomIcons:ApplyTrinketsLayout()
            end
            if self.CustomIcons.ApplyDefensivesLayout then
                self.CustomIcons:ApplyDefensivesLayout()
            end
        end)
    end

    self:InitializeSelectionAlphaController()

    C_Timer.After(1.0, function()
        NephUI:MaybeShowElvUIConflictPopup()
    end)
end

function NephUI:OpenConfig()
    if self.OpenConfigGUI then
        self:OpenConfigGUI()
    else
        print("|cffff0000[NephUI] Warning: Custom GUI not loaded, using AceConfigDialog|r")
        LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
    end
end

function NephUI:OpenCooldownViewerSettings()
    local frame = _G["CooldownViewerSettings"]
    if frame then
        frame:Show()
        frame:Raise()
        return
    end
    if self.OpenConfigGUI then
        self:OpenConfigGUI(nil, "viewers")
    end
end


function NephUI:CheckDualSpec()
    local LibDualSpec = LibStub("LibDualSpec-1.0", true)
    if not LibDualSpec then
        print("|cffff0000[NephUI] LibDualSpec-1.0 is NOT loaded.|r")
        print("|cffffff00This is normal on Classic Era realms (except Season of Discovery/Anniversary).|r")
        return
    end
    
    print("|cff00ff00[NephUI] LibDualSpec-1.0 is loaded.|r")
    
    if not self.db then
        print("|cffff0000[NephUI] Database not initialized yet.|r")
        return
    end
    
    if self.db.IsDualSpecEnabled then
        local isEnabled = self.db:IsDualSpecEnabled()
        print(string.format("|cff00ff00[NephUI] Dual Spec support: %s|r", isEnabled and "ENABLED" or "DISABLED"))
        
        if isEnabled then
            local currentSpec = GetSpecialization() or GetActiveTalentGroup() or 0
            print(string.format("|cff00ff00[NephUI] Current spec: %d|r", currentSpec))
            
            local currentProfile = self.db:GetCurrentProfile()
            print(string.format("|cff00ff00[NephUI] Current profile: %s|r", currentProfile))
            
            -- Check spec profiles
            for i = 1, 2 do
                local specProfile = self.db:GetDualSpecProfile(i)
                print(string.format("|cff00ff00[NephUI] Spec %d profile: %s|r", i, specProfile))
            end
        end
    else
        print("|cffff0000[NephUI] LibDualSpec methods not found on database (database not enhanced).|r")
    end
end

function NephUI:CreateMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)
    
    if not LDB or not LibDBIcon then
        return
    end
    
    if not self.db.profile.minimap then
        self.db.profile.minimap = {
            hide = false,
        }
    end
    
    local dataObj = LDB:NewDataObject(ADDON_NAME, {
        type = "launcher",
        icon = "Interface\\AddOns\\NephUI\\Media\\nephui.tga",
        label = ADDON_NAME,
        OnClick = function(clickedframe, button)
            if button == "LeftButton" then
                self:OpenConfig()
            elseif button == "RightButton" then
                self:OpenConfig()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText(ADDON_NAME)
            tooltip:AddLine(L["Left-click to open configuration"] or "Left-click to open configuration", 1, 1, 1)
            tooltip:AddLine(L["Right-click to open configuration"] or "Right-click to open configuration", 1, 1, 1)
        end,
    })
    
    LibDBIcon:Register(ADDON_NAME, dataObj, self.db.profile.minimap)
end

function NephUI:RefreshViewers()
    if self.IconViewers and self.IconViewers.RefreshAll then
        self.IconViewers:RefreshAll()
    end

    if self.ProcGlow and self.ProcGlow.RefreshAll then
        self.ProcGlow:RefreshAll()
    end
    
    -- Update unit frame anchors to viewer if enabled
    if self.UpdateViewerUnitFrameAnchor then
        self:UpdateViewerUnitFrameAnchor()
    end
end

-- Unit frame names to check
local unitFrameNames = {
    -- Default frames
    "PlayerFrame",
    "TargetFrame",
    "FocusFrame",
    "PetFrame",
    -- Unhalted Unit Frames
    "UUF_Player",
    "UUF_Target",
    "UUF_Pet",
    -- ElvUI frames
    "ElvUF_Player",
    "ElvUF_Target",
    "ElvUF_Pet",
}

-- Debug command to check frame status: /nephuidebuganchor
SLASH_NEPHUIDEBUGANCHOR1 = "/nephuidebuganchor"
SlashCmdList["NEPHUIDEBUGANCHOR"] = function()
    print("|cFF00FF00[NephUI Anchor Debug]|r")
    local viewer = _G["EssentialCooldownViewer"]
    print("  Viewer exists: " .. tostring(viewer ~= nil))
    if viewer then
        print("  Viewer shown: " .. tostring(viewer:IsShown()))
    end
    print("  anchorToUnitFrame enabled: " .. tostring(NephUI.db and NephUI.db.profile and NephUI.db.profile.viewers and NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.anchorToUnitFrame or false))
    print("  Unit frames:")
    for _, frameName in ipairs(unitFrameNames) do
        local frame = _G[frameName]
        if frame then
            local hooked = frame.__nephuiAnchorHooked and "YES" or "NO"
            local _, relativeTo = frame:GetPoint(1)
            local anchoredTo = relativeTo and (relativeTo.GetName and relativeTo:GetName() or tostring(relativeTo)) or "nil"
            print(string.format("    %s: EXISTS, hooked=%s, anchored to=%s", frameName, hooked, anchoredTo))
        else
            print(string.format("    %s: NOT FOUND", frameName))
        end
    end
end

-- Reload UI shortcut: /rl
SLASH_NEPHUIRELOAD1 = "/rl"
SlashCmdList["NEPHUIRELOAD"] = function()
    ReloadUI()
end

-- Helper function to hook a single unit frame
local function HookUnitFrame(frame)
    if not frame or frame.__nephuiAnchorHooked then
        return false
    end

    frame.__nephuiAnchorHooked = true
    frame.__nephuiOriginalSetPoint = frame.SetPoint
    frame.__nephuiOriginalClearAllPoints = frame.ClearAllPoints

    -- Override SetPoint to intercept other addons trying to reposition the frame
    frame.SetPoint = function(unitFrame, ...)
        local viewer = _G["EssentialCooldownViewer"]
        local anchorCfg = NephUI.db and NephUI.db.profile and NephUI.db.profile.viewers and NephUI.db.profile.viewers.general

        -- If anchoring is enabled and viewer exists, ignore external SetPoint calls
        -- and re-apply our anchor instead
        if anchorCfg and anchorCfg.anchorToUnitFrame and viewer and not unitFrame.__nephuiApplyingAnchor then
            -- Schedule re-application of our anchor (debounced)
            if not unitFrame.__nephuiReanchorPending then
                unitFrame.__nephuiReanchorPending = true
                C_Timer.After(0.1, function()
                    unitFrame.__nephuiReanchorPending = nil
                    if NephUI.ApplyUnitFrameAnchors then
                        NephUI:ApplyUnitFrameAnchors()
                    end
                end)
            end
            return
        end

        -- If not anchoring or viewer doesn't exist, use original SetPoint
        if unitFrame.__nephuiOriginalSetPoint then
            unitFrame.__nephuiOriginalSetPoint(unitFrame, ...)
        end
    end

    -- Override ClearAllPoints similarly
    frame.ClearAllPoints = function(unitFrame)
        local anchorCfg = NephUI.db and NephUI.db.profile and NephUI.db.profile.viewers and NephUI.db.profile.viewers.general

        -- If we're applying our own anchor, allow it
        if unitFrame.__nephuiApplyingAnchor then
            if unitFrame.__nephuiOriginalClearAllPoints then
                unitFrame.__nephuiOriginalClearAllPoints(unitFrame)
            end
            return
        end

        -- If anchoring is enabled, ignore external ClearAllPoints calls
        if anchorCfg and anchorCfg.anchorToUnitFrame then
            return
        end

        -- Otherwise use original
        if unitFrame.__nephuiOriginalClearAllPoints then
            unitFrame.__nephuiOriginalClearAllPoints(unitFrame)
        end
    end

    return true
end

-- Setup hooks on unit frames (doesn't require viewer to exist)
function NephUI:SetupUnitFrameHooks()
    local cfg = self.db.profile.viewers.general
    if not cfg then
        return
    end

    if cfg.anchorToUnitFrame then
        -- Hook SetPoint on unit frames to intercept repositioning and maintain our anchor
        local unhookedFrames = {}
        for _, frameName in ipairs(unitFrameNames) do
            local frame = _G[frameName]
            if frame then
                HookUnitFrame(frame)
            else
                -- Frame doesn't exist yet, track it for polling
                table.insert(unhookedFrames, frameName)
            end
        end

        -- If some frames don't exist yet, poll for them
        if #unhookedFrames > 0 and not self.__nephuiPollingForFrames then
            self.__nephuiPollingForFrames = true
            local attempts = 0
            local maxAttempts = 20 -- Poll for up to 10 seconds (20 * 0.5s)

            local function PollForFrames()
                attempts = attempts + 1
                local stillMissing = {}

                for _, frameName in ipairs(unhookedFrames) do
                    local frame = _G[frameName]
                    if frame then
                        if HookUnitFrame(frame) then
                            -- Successfully hooked, apply anchor
                            C_Timer.After(0.1, function()
                                if NephUI.ApplyUnitFrameAnchors then
                                    NephUI:ApplyUnitFrameAnchors()
                                end
                            end)
                        end
                    else
                        table.insert(stillMissing, frameName)
                    end
                end

                unhookedFrames = stillMissing

                -- Continue polling if frames still missing and under max attempts
                if #unhookedFrames > 0 and attempts < maxAttempts then
                    C_Timer.After(0.5, PollForFrames)
                else
                    self.__nephuiPollingForFrames = nil
                end
            end

            C_Timer.After(0.5, PollForFrames)
        end
    else
        -- Unhook and restore original behavior
        for _, frameName in ipairs(unitFrameNames) do
            local frame = _G[frameName]
            if frame and frame.__nephuiAnchorHooked then
                frame.__nephuiAnchorHooked = nil
                if frame.__nephuiOriginalSetPoint then
                    frame.SetPoint = frame.__nephuiOriginalSetPoint
                    frame.__nephuiOriginalSetPoint = nil
                end
                if frame.__nephuiOriginalClearAllPoints then
                    frame.ClearAllPoints = frame.__nephuiOriginalClearAllPoints
                    frame.__nephuiOriginalClearAllPoints = nil
                end
            end
        end
    end
end

-- Function to anchor unit frames to EssentialCooldownViewer
function NephUI:UpdateViewerUnitFrameAnchor()
    local cfg = self.db.profile.viewers.general
    if not cfg then
        return
    end

    -- Setup hooks first (doesn't require viewer)
    self:SetupUnitFrameHooks()

    -- Hook the viewer's OnShow to re-apply anchors whenever it becomes visible
    local viewer = _G["EssentialCooldownViewer"]
    if viewer and not viewer.__nephuiAnchorOnShowHooked then
        viewer.__nephuiAnchorOnShowHooked = true
        viewer:HookScript("OnShow", function()
            local anchorCfg = NephUI.db and NephUI.db.profile and NephUI.db.profile.viewers and NephUI.db.profile.viewers.general
            if anchorCfg and anchorCfg.anchorToUnitFrame then
                -- Apply anchors with delays to override other addons
                C_Timer.After(0.1, function()
                    NephUI:ApplyUnitFrameAnchors()
                end)
                C_Timer.After(1.0, function()
                    NephUI:ApplyUnitFrameAnchors()
                end)
            end
        end)
    elseif not viewer and cfg.anchorToUnitFrame then
        -- Viewer doesn't exist yet, set up a watcher to hook it when it appears
        if not self.__nephuiViewerWatcher then
            self.__nephuiViewerWatcher = true
            local attempts = 0
            local maxAttempts = 30 -- Poll for up to 15 seconds (30 * 0.5s)
            
            local function WatchForViewer()
                attempts = attempts + 1
                local viewer = _G["EssentialCooldownViewer"]
                
                if viewer and not viewer.__nephuiAnchorOnShowHooked then
                    -- Viewer appeared, hook it now
                    viewer.__nephuiAnchorOnShowHooked = true
                    viewer:HookScript("OnShow", function()
                        local anchorCfg = NephUI.db and NephUI.db.profile and NephUI.db.profile.viewers and NephUI.db.profile.viewers.general
                        if anchorCfg and anchorCfg.anchorToUnitFrame then
                            -- Apply anchors with delays to override other addons
                            C_Timer.After(0.1, function()
                                NephUI:ApplyUnitFrameAnchors()
                            end)
                            C_Timer.After(1.0, function()
                                NephUI:ApplyUnitFrameAnchors()
                            end)
                        end
                    end)
                    -- Apply anchors immediately since viewer now exists
                    if cfg.anchorToUnitFrame then
                        C_Timer.After(0.1, function()
                            NephUI:ApplyUnitFrameAnchors()
                        end)
                    end
                    self.__nephuiViewerWatcher = nil
                elseif attempts < maxAttempts then
                    -- Keep watching
                    C_Timer.After(0.5, WatchForViewer)
                else
                    -- Give up after max attempts
                    self.__nephuiViewerWatcher = nil
                end
            end
            
            C_Timer.After(0.5, WatchForViewer)
        end
    end

    -- Apply anchoring (has retry logic if viewer doesn't exist yet)
    if cfg.anchorToUnitFrame then
        self:ApplyUnitFrameAnchors()
    end
end

-- Apply anchors from unit frames to EssentialCooldownViewer
function NephUI:ApplyUnitFrameAnchors()
    local cfg = self.db.profile.viewers.general
    if not cfg or not cfg.anchorToUnitFrame then
        return
    end
    
    -- First check: viewer must exist
    local viewer = _G["EssentialCooldownViewer"]
    if not viewer or type(viewer) ~= "table" then
        -- Viewer doesn't exist yet, retry later
        C_Timer.After(0.5, function()
            if self.ApplyUnitFrameAnchors then
                self:ApplyUnitFrameAnchors()
            end
        end)
        return
    end
    
    if InCombatLockdown() then
        C_Timer.After(0.5, function()
            if self.ApplyUnitFrameAnchors then
                self:ApplyUnitFrameAnchors()
            end
        end)
        return
    end
    
    -- Unit frame mapping (frame name -> anchor config)
    -- Anchor points and viewer points remain constant, but offsets come from database
    local unitFrameConfig = {
        -- Default frames
        PlayerFrame = { anchorPoint = "RIGHT", viewerPoint = "TOPLEFT" },
        TargetFrame = { anchorPoint = "LEFT", viewerPoint = "TOPRIGHT" },
        FocusFrame = { anchorPoint = "CENTER", viewerPoint = "TOP" },
        PetFrame = { anchorPoint = "CENTER", viewerPoint = "TOP" },
        -- Unhalted Unit Frames
        UUF_Player = { anchorPoint = "TOPRIGHT", viewerPoint = "TOPLEFT" },
        UUF_Target = { anchorPoint = "TOPLEFT", viewerPoint = "TOPRIGHT" },
        UUF_Focus = { anchorPoint = "TOP", viewerPoint = "TOP" },
        UUF_Pet = { anchorPoint = "TOP", viewerPoint = "TOP" },
        UUF_TargetTarget = { anchorPoint = "TOP", viewerPoint = "TOP" },
        -- ElvUI frames
        ElvUF_Player = { anchorPoint = "TOPRIGHT", viewerPoint = "TOPLEFT" },
        ElvUF_Target = { anchorPoint = "TOPLEFT", viewerPoint = "TOPRIGHT" },
        ElvUF_Focus = { anchorPoint = "TOP", viewerPoint = "TOP" },
        ElvUF_TargetTarget = { anchorPoint = "TOP", viewerPoint = "TOP" },
        ElvUF_Pet = { anchorPoint = "TOP", viewerPoint = "TOP" },
    }
    
    -- Get stored positions from database, with defaults
    local anchorPositions = cfg.anchorPositions or {}
    local defaultOffsets = {
        PlayerFrame = { offsetX = -20, offsetY = 0 },
        TargetFrame = { offsetX = 20, offsetY = 0 },
        FocusFrame = { offsetX = 0, offsetY = 0 },
        PetFrame = { offsetX = 0, offsetY = 0 },
        UUF_Player = { offsetX = -20, offsetY = 0 },
        UUF_Target = { offsetX = 20, offsetY = 0 },
        UUF_Focus = { offsetX = 0, offsetY = 0 },
        UUF_Pet = { offsetX = 0, offsetY = 0 },
        UUF_TargetTarget = { offsetX = 0, offsetY = 0 },
        ElvUF_Player = { offsetX = -20, offsetY = 0 },
        ElvUF_Target = { offsetX = 20, offsetY = 0 },
        ElvUF_Focus = { offsetX = 0, offsetY = 0 },
        ElvUF_TargetTarget = { offsetX = 0, offsetY = 0 },
        ElvUF_Pet = { offsetX = 0, offsetY = 0 },
    }
    
    -- Second check: find at least one unit frame type that exists
    local foundAnyFrame = false
    for frameName, _ in pairs(unitFrameConfig) do
        local frame = _G[frameName]
        if frame and type(frame) == "table" then
            foundAnyFrame = true
            break
        end
    end
    
    -- If no unit frames found, retry after a delay (frames might not be spawned yet)
    if not foundAnyFrame then
        C_Timer.After(1.0, function()
            if self.ApplyUnitFrameAnchors then
                self:ApplyUnitFrameAnchors()
            end
        end)
        return
    end
    
    -- Both viewer and unit frames exist, apply anchors
    local anchoredAny = false
    for frameName, config in pairs(unitFrameConfig) do
        local frame = _G[frameName]
        if frame and type(frame) == "table" then
            -- Set flag so our hooks allow our own calls through
            frame.__nephuiApplyingAnchor = true

            -- Get stored offsets or use defaults
            local storedPos = anchorPositions[frameName]
            local defaultOffset = defaultOffsets[frameName] or { offsetX = 0, offsetY = 0 }
            local offsetX = (storedPos and storedPos.offsetX ~= nil) and storedPos.offsetX or defaultOffset.offsetX
            local offsetY = (storedPos and storedPos.offsetY ~= nil) and storedPos.offsetY or defaultOffset.offsetY

            -- Frame exists, anchor it
            if frame.__nephuiOriginalClearAllPoints then
                frame.__nephuiOriginalClearAllPoints(frame)
            else
                frame:ClearAllPoints()
            end

            if frame.__nephuiOriginalSetPoint then
                frame.__nephuiOriginalSetPoint(frame, config.anchorPoint, viewer, config.viewerPoint, offsetX, offsetY)
            else
                frame:SetPoint(config.anchorPoint, viewer, config.viewerPoint, offsetX, offsetY)
            end

            frame.__nephuiApplyingAnchor = nil
            anchoredAny = true
        end
    end
end

function NephUI:RefreshCustomIcons()
    if not (self.CustomIcons and self.db and self.db.profile and self.db.profile.customIcons) then
        return
    end
    if self.db.profile.customIcons.enabled == false then
        return
    end

    local module = self.CustomIcons
    if module.CreateCustomIconsTrackerFrame then
        module:CreateCustomIconsTrackerFrame()
    end
end

function NephUI:RefreshAll()
    self:RefreshViewers()
    
    if self.ResourceBars and self.ResourceBars.RefreshAll then
        self.ResourceBars:RefreshAll()
    end
    
    if self.CastBars and self.CastBars.RefreshAll then
        self.CastBars:RefreshAll()
    end

    if self.QOL and self.QOL.Refresh then
        self.QOL:Refresh()
    end
    
    if self.Chat and self.Chat.RefreshAll then
        self.Chat:RefreshAll()
    end
    
    if self.CustomIcons and self.db.profile.customIcons and self.db.profile.customIcons.enabled ~= false then
        self:RefreshCustomIcons()
    end
end
