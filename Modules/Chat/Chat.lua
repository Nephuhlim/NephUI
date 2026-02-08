local ADDON_NAME, ns = ...
local NephUI = ns.Addon

NephUI.Chat = NephUI.Chat or {}
local Chat = NephUI.Chat

local function StyleFontString(fontString)
    if not fontString then return end
    
    local cfg = NephUI.db.profile.chat
    if not cfg or not cfg.enabled then return end
    
    local font, size, flags = fontString:GetFont()
    if font then
        if not flags or (flags ~= "OUTLINE" and flags ~= "THICKOUTLINE" and not flags:find("OUTLINE")) then
            fontString:SetFont(font, size, "OUTLINE")
        end
    end
    
    fontString:SetShadowOffset(0, 0)
    fontString:SetShadowColor(0, 0, 0, 1)
end

local function StyleEditBox(editBox)
    if not editBox then return end
    
    local cfg = NephUI.db.profile.chat
    if not cfg or not cfg.enabled then return end
    
    local font, size, flags = editBox:GetFont()
    if font then
        if not flags or (flags ~= "OUTLINE" and flags ~= "THICKOUTLINE" and not flags:find("OUTLINE")) then
            editBox:SetFont(font, size, "OUTLINE")
        end
    end
    
    editBox:SetShadowOffset(0, 0)
    editBox:SetShadowColor(0, 0, 0, 1)
end

local function CreateBorder(frame)
    if frame.__nephuiBorder then return frame.__nephuiBorder end
    
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    local borderOffset = NephUI:Scale(1)
    border:SetPoint("TOPLEFT", frame, -borderOffset, borderOffset)
    border:SetPoint("BOTTOMRIGHT", frame, borderOffset, -borderOffset)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 1)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    
    frame.__nephuiBorder = border
    return border
end

local function SetBackgroundColor(frame)
    if not frame then return end
    
    local cfg = NephUI.db.profile.chat
    if not cfg or not cfg.enabled then return end
    
    local bgColor = cfg.backgroundColor or {0, 0, 0, 1}
    
    if frame.GetObjectType and frame:GetObjectType() == "Texture" then
        if frame.SetColorTexture then
            frame:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
        end
        return
    end
    
    if frame.SetBackdrop then
        if not frame.__nephuiBackdropSet then
            frame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = nil,
                tile = false,
                tileSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            frame.__nephuiBackdropSet = true
        end
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    elseif frame.CreateTexture then
        if not frame.__nephuiBackground then
            local bg = frame:CreateTexture(nil, "BACKGROUND")
            if bg then
                bg:SetAllPoints()
                bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
                frame.__nephuiBackground = bg
            end
        else
            frame.__nephuiBackground:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
        end
    end
end

local function StyleAllFontStrings(frame)
    if not frame or frame:IsForbidden() then return end
    
    if frame.GetFontString then
        local fs = frame:GetFontString()
        if fs and not fs.__nephuiStyled then
            StyleFontString(fs)
            fs.__nephuiStyled = true
        end
    end
    
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for _, region in ipairs(regions) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                if not region.__nephuiStyled then
                    StyleFontString(region)
                    region.__nephuiStyled = true
                end
            end
        end
    end
    
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        StyleAllFontStrings(child)
    end
end

local function CleanEditBoxTextures(editBox)
    if not editBox then return end
    
    local regions = { editBox:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType then
            local objType = region:GetObjectType()
            if objType == "Texture" then
                if region ~= editBox.__nephuiBackground and region ~= editBox.__nephuiBorder then
                    region:Hide()
                end
            end
        end
    end
    
    local textureFrames = {
        "FocusLeft",
        "FocusMid", 
        "FocusRight",
        "Header",
        "HeaderSuffix",
        "LanguageHeader",
        "Prompt",
        "NewcomerHint"
    }
    
    for _, frameName in ipairs(textureFrames) do
        local frame = editBox[frameName]
        if frame then
            if frame.GetObjectType and frame:GetObjectType() == "Texture" then
                frame:Hide()
            elseif frame.Hide then
                frame:Hide()
            end
        end
    end
end

-- Function to skin a single chat frame
function Chat:SkinChatFrame(chatFrame)
    if not chatFrame or chatFrame:IsForbidden() or chatFrame.__nephuiSkinned then
        return
    end
    
    local cfg = NephUI.db.profile.chat
    if not cfg or not cfg.enabled then
        return
    end
    
    -- Mark as skinned
    chatFrame.__nephuiSkinned = true
    
    -- Disable clamping to allow movement to screen edges in edit mode
    if chatFrame.SetClampedToScreen then
        chatFrame:SetClampedToScreen(false)
    end
    
    -- Skin main frame: background and border
    SetBackgroundColor(chatFrame)
    CreateBorder(chatFrame)
    
    -- Skin Background child frame
    local background = chatFrame.Background
    if background then
        SetBackgroundColor(background)
        -- Set default background alpha to 0 (transparent)
        background:SetAlpha(0)
        -- Hook OnShow to maintain alpha at 0
        if not background.__nephuiAlphaHooked then
            background.__nephuiAlphaHooked = true
            if background.HookScript then
                background:HookScript("OnShow", function(self)
                    self:SetAlpha(0)
                end)
            end
            -- Override SetAlpha to always be 0
            local originalSetAlpha = background.SetAlpha
            background.SetAlpha = function(self, alpha)
                -- Always set to 0 regardless of what's requested
                originalSetAlpha(self, 0)
            end
        end
        -- Disable clamping on background frame too (it may be what's moved in edit mode)
        if background.SetClampedToScreen then
            background:SetClampedToScreen(false)
        end
    end
    
    -- Hide RightTexture (and other default textures if they exist)
    if chatFrame.GetName then
        local frameName = chatFrame:GetName()
        if frameName then
            local rightTexture = _G[frameName .. "RightTexture"]
            if rightTexture then
                rightTexture:Hide()
            end
            local leftTexture = _G[frameName .. "LeftTexture"]
            if leftTexture then
                leftTexture:Hide()
            end
            local midTexture = _G[frameName .. "MidTexture"]
            if midTexture then
                midTexture:Hide()
            end
            local topTexture = _G[frameName .. "TopTexture"]
            if topTexture then
                topTexture:Hide()
            end
            local bottomTexture = _G[frameName .. "BottomTexture"]
            if bottomTexture then
                bottomTexture:Hide()
            end
            local topRightTexture = _G[frameName .. "TopRightTexture"]
            if topRightTexture then
                topRightTexture:Hide()
            end
            local topLeftTexture = _G[frameName .. "TopLeftTexture"]
            if topLeftTexture then
                topLeftTexture:Hide()
            end
            local bottomRightTexture = _G[frameName .. "BottomRightTexture"]
            if bottomRightTexture then
                bottomRightTexture:Hide()
            end
            local bottomLeftTexture = _G[frameName .. "BottomLeftTexture"]
            if bottomLeftTexture then
                bottomLeftTexture:Hide()
            end
        end
    end
    
    -- Skin EditBox - try multiple ways to access it
    local editBox = chatFrame.editBox
    if not editBox and chatFrame.GetName then
        local frameName = chatFrame:GetName()
        if frameName then
            editBox = _G[frameName .. "EditBox"]
        end
    end
    
    if editBox then
        -- Remove default textures first
        CleanEditBoxTextures(editBox)
        
        -- Apply our styling (black background and border)
        SetBackgroundColor(editBox)
        CreateBorder(editBox)
        StyleEditBox(editBox)
        
        -- Set edit box alpha to 1.0 always
        editBox:SetAlpha(1.0)
        
        -- Function to match edit box width to chat frame (which has our custom background)
        local function MatchEditBoxWidthToChatFrame()
            if not chatFrame or not editBox then return end
            if InCombatLockdown() then return end
            
            local chatWidth = chatFrame:GetWidth()
            
            if chatWidth then
                -- Clear any anchors that might be controlling width
                -- Check for left/right anchors that would override SetWidth
                local numPoints = editBox:GetNumPoints()
                local hasLeftRightAnchors = false
                for i = 1, numPoints do
                    local point = editBox:GetPoint(i)
                    if point and (point:find("LEFT") or point:find("RIGHT")) then
                        hasLeftRightAnchors = true
                        break
                    end
                end
                
                -- If there are left/right anchors, we need to use anchors to control width
                -- Otherwise, SetWidth should work
                local targetWidth = chatWidth - 0
                local currentHeight = editBox:GetHeight()
                
                if hasLeftRightAnchors then
                    -- Use anchors to control width instead of SetWidth
                    -- Get current position
                    local point, relativeTo, relativePoint, xOfs, yOfs = editBox:GetPoint(1)
                    if point and relativeTo then
                        -- Clear and re-anchor with our width
                        editBox:ClearAllPoints()
                        -- Anchor left side (no padding)
                        editBox:SetPoint("LEFT", relativeTo, "LEFT", 0, 0)
                        -- Anchor right side (no padding)
                        editBox:SetPoint("RIGHT", relativeTo, "RIGHT", 0, 0)
                        -- Anchor bottom to bottom of chat frame
                        editBox:SetPoint("BOTTOM", chatFrame, "BOTTOM", 0, -33)
                    else
                        -- Fallback: anchor to chat frame
                        editBox:ClearAllPoints()
                        editBox:SetPoint("BOTTOMLEFT", chatFrame, "BOTTOMLEFT", 0, 0)
                        editBox:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 0, 0)
                    end
                else
                    -- No width-controlling anchors, SetWidth should work
                    if currentHeight then
                        editBox:SetWidth(targetWidth)
                        -- Also anchor to bottom
                        editBox:ClearAllPoints()
                        editBox:SetPoint("BOTTOMLEFT", chatFrame, "BOTTOMLEFT", 0, 0)
                        editBox:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 0, 0)
                    end
                end
            end
        end
        
        -- Override SetWidth to prevent Blizzard from changing it
        if not editBox.__nephuiSetWidthHooked then
            editBox.__nephuiSetWidthHooked = true
            local originalSetWidth = editBox.SetWidth
            editBox.SetWidth = function(self, width)
                -- Allow our function to set width, but prevent Blizzard from overriding
                if not self.__nephuiSettingWidth then
                    self.__nephuiSettingWidth = true
                    originalSetWidth(self, width)
                    self.__nephuiSettingWidth = nil
                end
            end
        end
        
        -- Initial width matching
        MatchEditBoxWidthToChatFrame()
        
        -- Hook size changes to maintain width matching
        if not chatFrame.__nephuiEditBoxWidthHooked then
            chatFrame.__nephuiEditBoxWidthHooked = true
            
            -- Hook chat frame size changes (our custom background matches this frame)
            if chatFrame.HookScript then
                chatFrame:HookScript("OnSizeChanged", function()
                    MatchEditBoxWidthToChatFrame()
                end)
            end
            
            -- Hook edit box show to re-match width
            if editBox.HookScript then
                editBox:HookScript("OnShow", function()
                    MatchEditBoxWidthToChatFrame()
                end)
            end
            
            -- Hook edit box size changes to re-apply our width
            if editBox.HookScript then
                editBox:HookScript("OnSizeChanged", function()
                    MatchEditBoxWidthToChatFrame()
                end)
            end
            
            -- Periodic check to ensure width stays matched (reduced frequency for performance)
            C_Timer.NewTicker(0.5, function()
                MatchEditBoxWidthToChatFrame()
            end)
        end
        
        -- Hook alpha changes to keep it at 1.0
        if not editBox.__nephuiAlphaHooked then
            editBox.__nephuiAlphaHooked = true
            
            -- Override SetAlpha to always be 1.0
            local originalSetAlpha = editBox.SetAlpha
            editBox.SetAlpha = function(self, alpha)
                -- Always set to 1.0 regardless of what's requested
                originalSetAlpha(self, 1.0)
            end
        end

        -- Keep only the primary chat edit box visible to avoid duplicates
        local primaryEditBox = _G.ChatFrameEditBox or _G.ChatFrame1EditBox
        if editBox == primaryEditBox and not editBox.__nephuiShowHooked then
            editBox.__nephuiShowHooked = true
            editBox:Show()

            if editBox.HookScript then
                editBox:HookScript("OnHide", function(self)
                    self:Show()
                end)
            end

            local originalHide = editBox.Hide
            editBox.Hide = function(self)
                originalHide(self)
                self:Show()
            end
        end

        if editBox == primaryEditBox and not editBox.__nephuiContentHooked then
            editBox.__nephuiContentHooked = true

            local function SetEditBoxContentVisible(self, visible)
                if not self.__nephuiTextColor then
                    local r, g, b, a = self:GetTextColor()
                    self.__nephuiTextColor = { r or 1, g or 1, b or 1, a or 1 }
                end

                local r, g, b, a = unpack(self.__nephuiTextColor)
                self:SetTextColor(r, g, b, visible and a or 0)

                local promptFrames = {
                    "Prompt", "Header", "HeaderSuffix", "LanguageHeader", "NewcomerHint",
                    "prompt", "header", "headerSuffix", "languageHeader", "newcomerHint",
                }
                for _, frameName in ipairs(promptFrames) do
                    local frame = self[frameName]
                    if frame and frame.SetAlpha then
                        frame:SetAlpha(visible and 1 or 0)
                    end
                end

                local focusFrames = {
                    "FocusLeft", "FocusMid", "FocusRight",
                    "focusLeft", "focusMid", "focusRight",
                }
                for _, frameName in ipairs(focusFrames) do
                    local frame = self[frameName]
                    if frame and frame.SetAlpha then
                        frame:SetAlpha(visible and 1 or 0)
                    end
                end
            end

            SetEditBoxContentVisible(editBox, editBox:HasFocus())

            if editBox.HookScript then
                editBox:HookScript("OnEditFocusGained", function(self)
                    SetEditBoxContentVisible(self, true)
                end)

                editBox:HookScript("OnEditFocusLost", function(self)
                    SetEditBoxContentVisible(self, false)
                end)

                editBox:HookScript("OnShow", function(self)
                    SetEditBoxContentVisible(self, self:HasFocus())
                end)
            end

        end
    end
    
    -- Style all font strings in the chat frame
    StyleAllFontStrings(chatFrame)
    
    -- Hook AddMessage to style new messages
    if chatFrame.AddMessage then
        hooksecurefunc(chatFrame, "AddMessage", function(self, text, ...)
            C_Timer.After(0, function()
                StyleAllFontStrings(self)
            end)
        end)
    end
    
    -- Note: We don't hook SetFont to avoid recursion issues
    -- Font styling is applied during skinning and refresh
    
    -- Skin FontStringContainer if it exists
    local fontStringContainer = chatFrame.FontStringContainer
    if fontStringContainer then
        StyleAllFontStrings(fontStringContainer)
    end
    
    -- Skin other child frames
    local childFrames = {
        "EditModeResizeButton",
        "ResizeButton",
        "ScrollBar",
        "ScrollToBottomButton",
        "Selection",
        "buttonFrame",
        "ClickAnywhereButton",
    }
    
    for _, frameName in ipairs(childFrames) do
        local child = chatFrame[frameName]
        if child then
            -- Hide buttonframe
            if frameName == "buttonFrame" then
                child:Hide()
            else
                -- Remove default borders/textures
                if child.SetBackdrop then
                    child:SetBackdrop(nil)
                end
                -- Style any font strings in child frames
                StyleAllFontStrings(child)
            end
        end
    end
    
    -- Set Selection.Center and Selection.MouseOverHighlight alpha to 0.3
    -- This function will be called during skinning and when edit mode activates
    local function SetSelectionAlpha(selection)
        if not selection then return end
        
        -- Set Center alpha
        if selection.Center then
            selection.Center:SetAlpha(0.3)
            -- Hook OnShow to maintain alpha
            if not selection.Center.__nephuiAlphaHooked then
                selection.Center.__nephuiAlphaHooked = true
                if selection.Center.HookScript then
                    selection.Center:HookScript("OnShow", function(self)
                        self:SetAlpha(0.3)
                    end)
                end
            end
        end
        
        -- Set MouseOverHighlight alpha
        if selection.MouseOverHighlight then
            selection.MouseOverHighlight:SetAlpha(0.3)
            -- Hook OnShow to maintain alpha
            if not selection.MouseOverHighlight.__nephuiAlphaHooked then
                selection.MouseOverHighlight.__nephuiAlphaHooked = true
                if selection.MouseOverHighlight.HookScript then
                    selection.MouseOverHighlight:HookScript("OnShow", function(self)
                        self:SetAlpha(0.3)
                    end)
                end
            end
        end
    end
    
    -- Try to set alpha immediately if Selection exists
    SetSelectionAlpha(chatFrame.Selection)
end

-- Function to skin all existing chat frames
function Chat:SkinAllChatFrames()
    local numChatWindows = NUM_CHAT_WINDOWS or 10
    
    for i = 1, numChatWindows do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            self:SkinChatFrame(chatFrame)
        end
    end
    
    -- Also skin DEFAULT_CHAT_FRAME if it exists
    if DEFAULT_CHAT_FRAME then
        self:SkinChatFrame(DEFAULT_CHAT_FRAME)
    end
end

-- Hook chat frame creation and updates
function Chat:HookChatFrameCreation()
    -- Hook FCF_OpenNewWindow to skin new frames
    if FCF_OpenNewWindow then
        hooksecurefunc("FCF_OpenNewWindow", function(name)
            C_Timer.After(0.1, function()
                Chat:SkinAllChatFrames()
            end)
        end)
    end
    
    -- Hook FCF_OpenTemporaryWindow for temporary chat windows
    if FCF_OpenTemporaryWindow then
        hooksecurefunc("FCF_OpenTemporaryWindow", function(messageType, ...)
            C_Timer.After(0.1, function()
                Chat:SkinAllChatFrames()
            end)
        end)
    end
    
    -- Hook FCF_SelectDockFrame to skin when switching tabs
    if FCF_SelectDockFrame then
        hooksecurefunc("FCF_SelectDockFrame", function(chatFrame)
            C_Timer.After(0.1, function()
                if chatFrame then
                    Chat:SkinChatFrame(chatFrame)
                end
                Chat:SkinAllChatFrames()
            end)
        end)
    end
    
    -- Hook FCF_DockFrame to skin when docking frames
    if FCF_DockFrame then
        hooksecurefunc("FCF_DockFrame", function(chatFrame, ...)
            C_Timer.After(0.1, function()
                if chatFrame then
                    Chat:SkinChatFrame(chatFrame)
                end
            end)
        end)
    end
    
    -- Periodic check to catch any frames we might have missed
    C_Timer.NewTicker(2.0, function()
        Chat:SkinAllChatFrames()
    end)
end

-- Initialize function
function Chat:Initialize()
    if self.initialized then
        return
    end
    self.initialized = true
    
    -- Wait a bit for chat frames to be fully loaded
    C_Timer.After(0.5, function()
        self:SkinAllChatFrames()
        self:HookChatFrameCreation()
        self:UpdateQuickJoinToastButton()
        self:DisableChatFrameClamping()
    end)
    
    -- Also skin after PLAYER_LOGIN
    NephUI:RegisterEvent("PLAYER_LOGIN", function()
        C_Timer.After(0.5, function()
            self:SkinAllChatFrames()
            self:UpdateQuickJoinToastButton()
            self:DisableChatFrameClamping()
        end)
    end)
    
    -- Periodic check for QuickJoinToastButton (it may be created later)
    C_Timer.NewTicker(1.0, function()
        self:UpdateQuickJoinToastButton()
    end)
    
    -- Hook edit mode to disable clamping when frames are selected and set Selection alpha
    if EditModeManagerFrame then
        if EditModeManagerFrame.RegisterCallback then
            EditModeManagerFrame:RegisterCallback("EditModeEnter", function()
                C_Timer.After(0.1, function()
                    self:DisableChatFrameClamping()
                    -- Set Selection alpha for all chat frames when edit mode enters
                    self:SetChatSelectionAlpha()
                end)
            end)
        end
        
        -- Also hook when edit mode is shown
        if EditModeManagerFrame.HookScript then
            EditModeManagerFrame:HookScript("OnShow", function()
                C_Timer.After(0.1, function()
                    self:DisableChatFrameClamping()
                    -- Set Selection alpha for all chat frames when edit mode is shown
                    self:SetChatSelectionAlpha()
                end)
            end)
        end
        
        -- Hook EnterEditMode function if it exists
        if EditModeManagerFrame.EnterEditMode then
            hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
                C_Timer.After(0.1, function()
                    Chat:SetChatSelectionAlpha()
                end)
            end)
        end
    end
    
    -- Periodic check to ensure clamping stays disabled and Selection alpha is set
    C_Timer.NewTicker(2.0, function()
        self:DisableChatFrameClamping()
        self:SetChatSelectionAlpha()
    end)
end

-- Function to set Selection alpha for all chat frames
function Chat:SetChatSelectionAlpha()
    local numChatWindows = NUM_CHAT_WINDOWS or 10
    
    for i = 1, numChatWindows do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame.Selection then
            local selection = chatFrame.Selection
            if selection then
                if selection.Center then
                    selection.Center:SetAlpha(0.3)
                    if not selection.Center.__nephuiAlphaHooked then
                        selection.Center.__nephuiAlphaHooked = true
                        if selection.Center.HookScript then
                            selection.Center:HookScript("OnShow", function(self)
                                self:SetAlpha(0.3)
                            end)
                        end
                    end
                end
                if selection.MouseOverHighlight then
                    selection.MouseOverHighlight:SetAlpha(0.3)
                    if not selection.MouseOverHighlight.__nephuiAlphaHooked then
                        selection.MouseOverHighlight.__nephuiAlphaHooked = true
                        if selection.MouseOverHighlight.HookScript then
                            selection.MouseOverHighlight:HookScript("OnShow", function(self)
                                self:SetAlpha(0.3)
                            end)
                        end
                    end
                end
            end
        end
    end
    
    -- Also handle DEFAULT_CHAT_FRAME
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.Selection then
        local selection = DEFAULT_CHAT_FRAME.Selection
        if selection then
            if selection.Center then
                selection.Center:SetAlpha(0.3)
                if not selection.Center.__nephuiAlphaHooked then
                    selection.Center.__nephuiAlphaHooked = true
                    if selection.Center.HookScript then
                        selection.Center:HookScript("OnShow", function(self)
                            self:SetAlpha(0.3)
                        end)
                    end
                end
            end
            if selection.MouseOverHighlight then
                selection.MouseOverHighlight:SetAlpha(0.3)
                if not selection.MouseOverHighlight.__nephuiAlphaHooked then
                    selection.MouseOverHighlight.__nephuiAlphaHooked = true
                    if selection.MouseOverHighlight.HookScript then
                        selection.MouseOverHighlight:HookScript("OnShow", function(self)
                            self:SetAlpha(0.3)
                        end)
                    end
                end
            end
        end
    end
end

-- Function to disable clamping for chat frames in edit mode
function Chat:DisableChatFrameClamping()
    local numChatWindows = NUM_CHAT_WINDOWS or 10
    
    for i = 1, numChatWindows do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            -- Disable clamping on main chat frame
            if chatFrame.SetClampedToScreen and not chatFrame.__nephuiClampingDisabled then
                chatFrame.__nephuiClampingDisabled = true
                chatFrame:SetClampedToScreen(false)
                
                -- Hook OnShow to maintain unclamped state
                if chatFrame.HookScript then
                    chatFrame:HookScript("OnShow", function(self)
                        if self.SetClampedToScreen then
                            self:SetClampedToScreen(false)
                        end
                    end)
                end
            end
            
            -- Also disable clamping on Background frame (often what's moved in edit mode)
            local background = chatFrame.Background
            if background and background.SetClampedToScreen and not background.__nephuiClampingDisabled then
                background.__nephuiClampingDisabled = true
                background:SetClampedToScreen(false)
                
                if background.HookScript then
                    background:HookScript("OnShow", function(self)
                        if self.SetClampedToScreen then
                            self:SetClampedToScreen(false)
                        end
                    end)
                end
            end
        end
    end
    
    -- Also handle DEFAULT_CHAT_FRAME
    if DEFAULT_CHAT_FRAME then
        if DEFAULT_CHAT_FRAME.SetClampedToScreen and not DEFAULT_CHAT_FRAME.__nephuiClampingDisabled then
            DEFAULT_CHAT_FRAME.__nephuiClampingDisabled = true
            DEFAULT_CHAT_FRAME:SetClampedToScreen(false)
            if DEFAULT_CHAT_FRAME.HookScript then
                DEFAULT_CHAT_FRAME:HookScript("OnShow", function(self)
                    if self.SetClampedToScreen then
                        self:SetClampedToScreen(false)
                    end
                end)
            end
        end
        
        local defaultBackground = DEFAULT_CHAT_FRAME.Background
        if defaultBackground and defaultBackground.SetClampedToScreen and not defaultBackground.__nephuiClampingDisabled then
            defaultBackground.__nephuiClampingDisabled = true
            defaultBackground:SetClampedToScreen(false)
            if defaultBackground.HookScript then
                defaultBackground:HookScript("OnShow", function(self)
                    if self.SetClampedToScreen then
                        self:SetClampedToScreen(false)
                    end
                end)
            end
        end
    end
end

-- Function to apply position offset to QuickJoinToastButton
local function ApplyQuickJoinToastButtonOffset(button, offsetX, offsetY)
    if not button then return end
    
    -- Get current position
    local point, relativeTo, relativePoint, xOfs, yOfs = button:GetPoint(1)
    if not point or not relativeTo then return end
    
    -- Store base position if not already stored or if anchor changed
    if not button.__nephuiBaseAnchor or 
       button.__nephuiBaseAnchor.relativeTo ~= relativeTo or
       button.__nephuiBaseAnchor.point ~= point then
        
        -- Calculate base position by subtracting previously applied offset
        local currentOffsetX = button.__nephuiLastOffsetX or 0
        local currentOffsetY = button.__nephuiLastOffsetY or 0
        local baseX = (xOfs or 0) - currentOffsetX
        local baseY = (yOfs or 0) - currentOffsetY
        
        button.__nephuiBaseAnchor = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint or point,
            xOfs = baseX,
            yOfs = baseY,
        }
    end
    
    local baseAnchor = button.__nephuiBaseAnchor
    
    -- Update stored offset values
    local lastOffsetX = button.__nephuiLastOffsetX or 0
    local lastOffsetY = button.__nephuiLastOffsetY or 0
    button.__nephuiLastOffsetX = offsetX
    button.__nephuiLastOffsetY = offsetY
    
    -- Calculate final position
    local finalX = baseAnchor.xOfs + offsetX
    local finalY = baseAnchor.yOfs + offsetY
    
    -- Only reposition if offset changed or position doesn't match expected
    if offsetX ~= lastOffsetX or offsetY ~= lastOffsetY or 
       math.abs((xOfs or 0) - finalX) > 0.1 or math.abs((yOfs or 0) - finalY) > 0.1 then
        -- Clear and reapply with offset
        button:ClearAllPoints()
        button:SetPoint(
            baseAnchor.point,
            baseAnchor.relativeTo,
            baseAnchor.relativePoint,
            finalX,
            finalY
        )
    end
end

-- Function to update QuickJoinToastButton visibility and position
function Chat:UpdateQuickJoinToastButton()
    local cfg = NephUI.db.profile.chat
    if not cfg then return end
    
    local quickJoinButton = _G.QuickJoinToastButton
    if not quickJoinButton then return end
    
    -- Handle visibility
    if cfg.hideQuickJoinToastButton then
        quickJoinButton:Hide()
        -- Hook OnShow to keep it hidden
        if not quickJoinButton.__nephuiHideHooked then
            quickJoinButton.__nephuiHideHooked = true
            quickJoinButton:HookScript("OnShow", function(self)
                local cfg2 = NephUI.db.profile.chat
                if cfg2 and cfg2.hideQuickJoinToastButton then
                    self:Hide()
                end
            end)
        end
    else
        -- Unhook and show if setting is disabled
        if quickJoinButton.__nephuiHideHooked then
            quickJoinButton:SetScript("OnShow", nil)
            quickJoinButton.__nephuiHideHooked = nil
        end
        -- Don't force show, let it show naturally if it wants to
    end
    
    -- Handle position offsets
    local offsetX = cfg.quickJoinToastButtonOffsetX or 31
    local offsetY = cfg.quickJoinToastButtonOffsetY or -23
    
    -- Hook SetPoint to intercept positioning and apply our offset
    if not quickJoinButton.__nephuiSetPointHooked then
        quickJoinButton.__nephuiSetPointHooked = true
        hooksecurefunc(quickJoinButton, "SetPoint", function(self, ...)
            -- Clear base anchor so it gets recalculated from new position
            self.__nephuiBaseAnchor = nil
            -- Apply offset after Blizzard sets the position
            C_Timer.After(0, function()
                local cfg3 = NephUI.db.profile.chat
                if cfg3 and not cfg3.hideQuickJoinToastButton then
                    ApplyQuickJoinToastButtonOffset(self, cfg3.quickJoinToastButtonOffsetX or 31, cfg3.quickJoinToastButtonOffsetY or -23)
                end
            end)
        end)
        
        -- Also hook OnShow to apply offset when button appears
        if not quickJoinButton.__nephuiShowHooked then
            quickJoinButton.__nephuiShowHooked = true
            quickJoinButton:HookScript("OnShow", function(self)
                C_Timer.After(0.1, function()
                    local cfg4 = NephUI.db.profile.chat
                    if cfg4 and not cfg4.hideQuickJoinToastButton then
                        ApplyQuickJoinToastButtonOffset(self, cfg4.quickJoinToastButtonOffsetX or 31, cfg4.quickJoinToastButtonOffsetY or -23)
                    end
                end)
            end)
        end
    end
    
    -- Apply offsets immediately if button is already visible and positioned
    if not cfg.hideQuickJoinToastButton then
        local point = quickJoinButton:GetPoint(1)
        if point then
            ApplyQuickJoinToastButtonOffset(quickJoinButton, offsetX, offsetY)
        end
    end
end

-- Refresh function
function Chat:RefreshAll()
    -- Clear skinned flags and re-skin
    local numChatWindows = NUM_CHAT_WINDOWS or 10
    for i = 1, numChatWindows do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame.__nephuiSkinned = nil
            -- Also clear clamping disabled flag so it gets reapplied
            chatFrame.__nephuiClampingDisabled = nil
            if chatFrame.Background then
                chatFrame.Background.__nephuiClampingDisabled = nil
            end
        end
    end
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME.__nephuiSkinned = nil
        DEFAULT_CHAT_FRAME.__nephuiClampingDisabled = nil
        if DEFAULT_CHAT_FRAME.Background then
            DEFAULT_CHAT_FRAME.Background.__nephuiClampingDisabled = nil
        end
    end
    
    self:SkinAllChatFrames()
    self:UpdateQuickJoinToastButton()
    self:DisableChatFrameClamping()
end

