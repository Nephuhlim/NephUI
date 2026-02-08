local ADDON_NAME, ns = ...
local NephUI = ns.Addon

local UF = NephUI.UnitFrames
if not UF then
    error("NephUI: UnitFrames module not initialized! Load UnitFrames.lua first.")
end

local ResolveFrameName = UF.ResolveFrameName
local GetAnchorFrame = UF.GetAnchorFrame
local MaskFrame = UF.MaskFrame
local SafeDisableMouse = UF.SafeDisableMouse
local MakePlayerFrameClickthrough = UF.MakePlayerFrameClickthrough

local function BeginRepositionGuard()
    if UF.__nephuiRepositioning then
        return false
    end

    UF.__nephuiRepositioning = true
    return true
end

local function EndRepositionGuard()
    UF.__nephuiRepositioning = nil
end

local function HideEditModeSelectionFrame(selectionFrame)
    if not selectionFrame or selectionFrame.__nephuiSelectionHidden then return end
    
    selectionFrame.__nephuiSelectionHidden = true
    selectionFrame:Hide()
    
    selectionFrame:HookScript("OnShow", function(self)
        local db = NephUI.db.profile.unitFrames
        if db and db.enabled then
            self:Hide()
        end
    end)
end

function UF:HideDefaultUnitFrames()
    -- Make PlayerFrame clickthrough for all classes; mask it (always hide Blizzard PlayerFrame when NephUI Player is enabled)
    MakePlayerFrameClickthrough()
    MaskFrame(PlayerFrame)
    
    MaskFrame(TargetFrame)
    MaskFrame(FocusFrame)
    MaskFrame(TargetFrameToT)
    MaskFrame(PetFrame)

    -- Hide default boss frames when custom boss frames are enabled
    for i = 1, 8 do
        local bossFrame = _G["Boss" .. i .. "TargetFrame"]
        if bossFrame then
            MaskFrame(bossFrame)
        end
    end
    
    if PlayerFrame and PlayerFrame.Selection then
        HideEditModeSelectionFrame(PlayerFrame.Selection)
    end
    if TargetFrame and TargetFrame.Selection then
        HideEditModeSelectionFrame(TargetFrame.Selection)
    end
    if FocusFrame and FocusFrame.Selection then
        HideEditModeSelectionFrame(FocusFrame.Selection)
    end
    if PetFrame and PetFrame.Selection then
        HideEditModeSelectionFrame(PetFrame.Selection)
    end
    
    if TargetFrame and not TargetFrame.__cdmAurasHooked and TargetFrame.UpdateAuras then
        TargetFrame.__cdmAurasHooked = true
        hooksecurefunc(TargetFrame, "UpdateAuras", function(frame)
            if frame ~= TargetFrame then return end
            if frame.auraPools and frame.auraPools.ReleaseAll then
                frame.auraPools:ReleaseAll()
            end
        end)
    end
    
    if FocusFrame and not FocusFrame.__cdmAurasHooked and FocusFrame.UpdateAuras then
        FocusFrame.__cdmAurasHooked = true
        hooksecurefunc(FocusFrame, "UpdateAuras", function(frame)
            if frame ~= FocusFrame then return end
            if frame.auraPools and frame.auraPools.ReleaseAll then
                frame.auraPools:ReleaseAll()
            end
        end)
    end
    
end

function UF:ApplyFramePosition(unitFrame, unit, DB)
    if not unitFrame or not DB or not DB.Frame then return end

    -- Boss frames are positioned as a group by LayoutBossFrames, not individually
    if unit:match("^boss%d+$") then
        return
    end

    -- Don't move frames in combat to avoid taint
    if InCombatLockdown() then
        return
    end

    unitFrame:ClearAllPoints()
    
    local anchorName = DB.Frame.AnchorFrame or "UIParent"
    local anchor = GetAnchorFrame(anchorName)
    local anchorFrom = DB.Frame.AnchorFrom or "CENTER"
    local anchorTo = DB.Frame.AnchorTo or "CENTER"
    local offsetX = DB.Frame.OffsetX or 0
    local offsetY = DB.Frame.OffsetY or 0
    
    local ecv = _G["EssentialCooldownViewer"]
    if DB.Frame.AnchorToCooldown and ecv and anchor == ecv then
        -- Anchor unit frames to the top of the viewer so added rows grow downward
        local gapX = offsetX or 0
        local gapY = offsetY
        if gapY == nil then
            gapY = -20
        end
        
        if unit == "player" then
            unitFrame:SetPoint("TOPRIGHT", ecv, "TOPLEFT", -20 + gapX, gapY)
            
            if unitFrame.editModeAnchor and not unitFrame.editModeAnchor.isMoving then
                unitFrame.editModeAnchor:ClearAllPoints()
                unitFrame.editModeAnchor:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
            end
            return
        elseif unit == "target" then
            unitFrame:SetPoint("TOPLEFT", ecv, "TOPRIGHT", 20 + gapX, gapY)
            
            if unitFrame.editModeAnchor and not unitFrame.editModeAnchor.isMoving then
                unitFrame.editModeAnchor:ClearAllPoints()
                unitFrame.editModeAnchor:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
            end
            return
        end
    end
    
    -- Round offsets for pixel-perfect alignment
    local roundedOffsetX = math.floor((offsetX or 0) + 0.5)
    local roundedOffsetY = math.floor((offsetY or 0) + 0.5)
    
    unitFrame:SetPoint(anchorFrom, anchor, anchorTo, roundedOffsetX, roundedOffsetY)
    
    if unitFrame.editModeAnchor and not unitFrame.editModeAnchor.isMoving then
        unitFrame.editModeAnchor:ClearAllPoints()
        unitFrame.editModeAnchor:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
    end
end

function UF:RepositionAllUnitFrames()
    if InCombatLockdown() then
        return
    end
    
    local db = NephUI.db.profile.unitFrames
    if not db then return end
    
    local units = {"player", "target", "targettarget", "pet", "focus"}
    for _, unit in ipairs(units) do
        local unitDB = db[unit]
        if unitDB and unitDB.Enabled then
            local frameName = ResolveFrameName(unit)
            local unitFrame = frameName and _G[frameName]
            if unitFrame then
                self:ApplyFramePosition(unitFrame, unit, unitDB)
            end
        end
    end
end

-- Hook EssentialCooldownViewer for player and target frames
function UF:HookCooldownViewer()
    local db = NephUI.db.profile.unitFrames
    if not db then return end
    
    -- Check if player or target has anchorToCooldown enabled
    local playerDB = db.player
    local targetDB = db.target
    local playerUsesCooldown = playerDB and playerDB.Frame and playerDB.Frame.AnchorToCooldown
    local targetUsesCooldown = targetDB and targetDB.Frame and targetDB.Frame.AnchorToCooldown
    
    -- If neither player nor target uses cooldown viewer, don't hook
    if not playerUsesCooldown and not targetUsesCooldown then
        return
    end
    
    -- Try to find EssentialCooldownViewer
    local ecv = _G["EssentialCooldownViewer"]
    
    -- If cooldown viewer doesn't exist, return (will retry on next call)
    if not ecv then
        return
    end
    
    -- If already hooked, return
    if ecv.__nephuiCooldownHooked then
        return
    end
    ecv.__nephuiCooldownHooked = true
    
    local function realign()
        if not BeginRepositionGuard() then
            return
        end

        repeat
            -- Don't move frames in combat to avoid taint
            if InCombatLockdown() then
                break
            end

            -- Don't interfere with Blizzard's edit mode positioning
            local inEditMode = EditModeManagerFrame and EditModeManagerFrame.editModeActive
            if inEditMode then
                break
            end

            -- Reposition player frame if it uses cooldown viewer
            if playerUsesCooldown then
                local frameName = ResolveFrameName("player")
                local unitFrame = frameName and _G[frameName]
                if unitFrame then
                    self:ApplyFramePosition(unitFrame, "player", db.player)
                end
            end

            -- Reposition target frame if it uses cooldown viewer
            if targetUsesCooldown then
                local frameName = ResolveFrameName("target")
                local unitFrame = frameName and _G[frameName]
                if unitFrame then
                    self:ApplyFramePosition(unitFrame, "target", db.target)
                end
            end

            -- Reposition all other unit frames (in case they're anchored to player/target)
            -- This ensures frames like targettarget, focus, or pet update when player/target moves
            local otherUnits = {"targettarget", "pet", "focus"}
            for _, unit in ipairs(otherUnits) do
                local unitDB = db[unit]
                if unitDB and unitDB.Enabled then
                    local frameName = ResolveFrameName(unit)
                    local unitFrame = frameName and _G[frameName]
                    if unitFrame then
                        self:ApplyFramePosition(unitFrame, unit, unitDB)
                    end
                end
            end
        until true

        EndRepositionGuard()
    end
    
    -- Hook the scripts
    ecv:HookScript("OnSizeChanged", realign)
    ecv:HookScript("OnShow", realign)
    ecv:HookScript("OnHide", realign)
    
    -- Initial realignment
    realign()
end

-- Hook anchor frames to reposition unit frames when they change
function UF:HookAnchorFrames()
    -- First, hook cooldown viewer if needed
    self:HookCooldownViewer()
    
    -- Also hook individual anchor frames (for non-cooldown viewer anchors)
    local function RepositionAllFrames()
        if not BeginRepositionGuard() then
            return
        end

        repeat
            if InCombatLockdown() then
                break
            end

            -- Don't interfere with Blizzard's edit mode positioning
            local inEditMode = EditModeManagerFrame and EditModeManagerFrame.editModeActive
            if inEditMode then
                break
            end

            local db = NephUI.db.profile.unitFrames
            if not db then
                break
            end

            for unit in pairs(UF.UnitToFrameName) do
                local dbUnit = unit
                if unit:match("^boss(%d+)$") then dbUnit = "boss" end
                
                local DB = db[dbUnit]
                if DB and DB.Enabled then
                    local frameName = ResolveFrameName(unit)
                    local unitFrame = frameName and _G[frameName]
                    if unitFrame then
                        self:ApplyFramePosition(unitFrame, unit, DB)
                    end
                end
            end
        until true

        EndRepositionGuard()
    end
    
    -- Hook common anchor frames
    local anchorFrames = {
        "NephUI_Player",
        "NephUI_Target",
        "EssentialCooldownViewer",
        "UtilityCooldownViewer",
        "BuffIconCooldownViewer",
    }
    
    for _, anchorName in ipairs(anchorFrames) do
        local anchor = _G[anchorName]
        if anchor and not anchor.__nephuiAnchorHooked then
            anchor.__nephuiAnchorHooked = true
            anchor:HookScript("OnSizeChanged", RepositionAllFrames)
            anchor:HookScript("OnShow", RepositionAllFrames)
            anchor:HookScript("OnHide", RepositionAllFrames)
        end
    end
end

