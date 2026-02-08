local ADDON_NAME, ns = ...
local NephUI = ns.Addon

-- Create namespace
NephUI.CastBars = NephUI.CastBars or {}
local CastBars = NephUI.CastBars

-- Build helpers so we can branch between Midnight (>=120000) and retail (TWW)
local BUILD_NUMBER = tonumber((select(4, GetBuildInfo()))) or 0
local IS_MIDNIGHT_OR_LATER = BUILD_NUMBER >= 120000

-- Utility functions (from Main.lua)
local function GetClassColor()
    local classColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
    if not classColor then
        return 1, 1, 1
    end
    return classColor.r, classColor.g, classColor.b
end

local function CreateBorder(frame)
    if frame.border then return frame.border end

    local bord = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	local borderSize = (NephUI.ScaleBorder and NephUI:ScaleBorder(1)) or math.floor((NephUI:Scale(1) or 1) + 0.5)
	local borderOffset = borderSize
	bord:SetPoint("TOPLEFT", frame, -borderOffset, borderOffset)
	bord:SetPoint("BOTTOMRIGHT", frame, borderOffset, -borderOffset)
    bord:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = borderSize,
    })
    bord:SetBackdropBorderColor(0, 0, 0, 1)
    bord:SetFrameLevel(frame:GetFrameLevel() + 1)

    frame.border = bord
    return bord
end

-- Export utilities
CastBars.GetClassColor = GetClassColor
CastBars.CreateBorder = CreateBorder
CastBars.BUILD_NUMBER = BUILD_NUMBER
CastBars.IS_MIDNIGHT_OR_LATER = IS_MIDNIGHT_OR_LATER

-- Resolve a cast icon texture across client variants
local function ResolveCastIconTexture(spellbar, unit, spellID)
    -- Midnight+ uses the new spell texture pipeline
    if IS_MIDNIGHT_OR_LATER then
        if spellID and C_Spell and C_Spell.GetSpellTexture then
            local tex = C_Spell.GetSpellTexture(spellID)
            if tex then
                return tex
            end
        end
        return 136243 -- fallback book icon
    end

    -- Retail (TWW) fallback path
    local texture

    -- First try the Blizzard spellbar's existing icon texture
    if spellbar then
        local icon = spellbar.Icon or spellbar.icon
        if icon and icon.GetTexture then
            texture = icon:GetTexture()
        end
    end

    -- Then try spell-based lookups
    if not texture and spellID then
        if GetSpellTexture then
            texture = GetSpellTexture(spellID)
        end
        if not texture and C_Spell and C_Spell.GetSpellTexture then
            texture = C_Spell.GetSpellTexture(spellID)
        end
    end

    -- Finally ask the unit APIs
    if not texture and unit then
        if UnitCastingInfo then
            local _, _, tex = UnitCastingInfo(unit)
            texture = texture or tex
        end
        if not texture and UnitChannelInfo then
            local _, _, tex = UnitChannelInfo(unit)
            texture = texture or tex
        end
    end

    return texture or 136243
end

CastBars.ResolveCastIconTexture = ResolveCastIconTexture

-- CastBar OnUpdate function
local function CastBar_OnUpdate(frame, elapsed)
    if not frame.startTime or not frame.endTime then return end

    local now = GetTime()
    if now >= frame.endTime then
        frame.castGUID  = nil
        frame.castBarID = nil
        frame.isChannel = nil
        frame.isEmpowered = nil
        frame.numStages = nil
        frame.lastNumStages = nil
        frame.currentEmpoweredStage = nil
        if frame.empoweredStages then
            for _, stage in ipairs(frame.empoweredStages) do
                if stage then
                    stage:Hide()
                    if stage.border then
                        stage.border:Hide()
                    end
                end
            end
        end
        if frame.empoweredGlow then
            frame.empoweredGlow:Hide()
        end
        if frame.empoweredSegments then
            for _, segment in ipairs(frame.empoweredSegments) do
                if segment then
                    segment:Hide()
                end
            end
        end
        frame:Hide()
        frame:SetScript("OnUpdate", nil)
        return
    end

    local status = frame.status
    if not status then return end

    local duration  = frame.endTime - frame.startTime
    if duration <= 0 then duration = 0.001 end

    local remaining = frame.endTime - now
    local progress

    if frame.isChannel then
        -- For regular channels, use remaining time (fills right to left)
        progress = remaining
    else
        -- For regular casts and empowered casts (which are NOT channels), use elapsed time
        progress = now - frame.startTime
    end

    -- Handle empowered cast stage-based coloring
    if frame.isEmpowered and frame.numStages and frame.numStages > 0 then
        -- CRITICAL: Verify we have valid timing data - if not, skip empowered logic
        if not frame.startTime or not frame.endTime or frame.startTime <= 0 or frame.endTime <= 0 then
            -- Invalid timing data, hide empowered segments and return
            if frame.empoweredSegments then
                if frame.empoweredSegments[0] then frame.empoweredSegments[0]:Hide() end
                if frame.empoweredSegments[-1] then frame.empoweredSegments[-1]:Hide() end
                for _, seg in ipairs(frame.empoweredSegments) do
                    if seg then seg:Hide() end
                end
            end
            if frame.empoweredSegmentFills then
                if frame.empoweredSegmentFills[0] then frame.empoweredSegmentFills[0]:Hide() end
                if frame.empoweredSegmentFills[-1] then frame.empoweredSegmentFills[-1]:Hide() end
                for _, fill in ipairs(frame.empoweredSegmentFills) do
                    if fill then fill:Hide() end
                end
            end
            return
        end
        
        -- Get stage durations/percentages to determine current stage and segment boundaries
        local stagePercentages = {}
        local totalDuration = duration  -- Default to calculated duration
        
        -- Try to use UnitEmpoweredStageDurations first (new API)
        if UnitEmpoweredStageDurations then
            local stageDurations = UnitEmpoweredStageDurations("player")
            if stageDurations and #stageDurations > 0 then
                -- Calculate total duration (sum of all stages including hold-at-max)
                local calcTotal = 0
                for i = 1, #stageDurations do
                    if stageDurations[i] and stageDurations[i].durationMS then
                        calcTotal = calcTotal + (stageDurations[i].durationMS / 1000)
                    end
                end
                if calcTotal > 0 then
                    totalDuration = calcTotal
                    -- Convert durations to percentages
                    for i = 1, #stageDurations do
                        if stageDurations[i] and stageDurations[i].durationMS then
                            stagePercentages[i] = (stageDurations[i].durationMS / 1000) / totalDuration
                        end
                    end
                end
            end
        end
        
        -- Fallback to UnitEmpoweredStagePercentages if UnitEmpoweredStageDurations not available
        if #stagePercentages == 0 and UnitEmpoweredStagePercentages then
            local percentages = UnitEmpoweredStagePercentages("player", true)
            if percentages and #percentages > 0 then
                stagePercentages = percentages
            end
        end
        
        -- Calculate current progress percentage (0 to 1)
        -- Use totalDuration which includes hold-at-max period
        local progressPercent = progress / totalDuration
        -- For regular channels, reverse it (right to left fill)
        -- But for empowered casts, we want left to right fill, so don't reverse
        if frame.isChannel and not frame.isEmpowered then
            -- For regular channels, progress is remaining time, so we need to reverse it
            progressPercent = 1.0 - progressPercent
        end
        
        -- Determine current stage and calculate segment boundaries
        -- Account for initial blank period (stage 0)
        local stage1StartPercent = 0
        if #stagePercentages > 0 then
            -- First percentage is the initial blank period
            stage1StartPercent = stagePercentages[1] or 0
        end
        
        local currentStage = 0  -- 0 = blank period, 1+ = actual stages
        local stageStartPercent = 0
        local stageEndPercent = stage1StartPercent
        
        if progressPercent < stage1StartPercent then
            -- Still in the initial blank period (stage 0)
            currentStage = 0
            stageStartPercent = 0
            stageEndPercent = stage1StartPercent
        elseif #stagePercentages > 0 then
            -- Calculate which stage we're in, accounting for the blank period
            local cumulative = stage1StartPercent
            for i = 1, math.min(#stagePercentages - 2, frame.numStages) do  -- Exclude blank period and hold-at-max
                local stagePercent = stagePercentages[i + 1] or 0  -- i+1 because we skip the first (blank period)
                local nextCumulative = cumulative + stagePercent
                
                if progressPercent <= nextCumulative + 0.01 then
                    currentStage = i
                    stageStartPercent = cumulative
                    stageEndPercent = nextCumulative
                    break
                end
                
                cumulative = nextCumulative
                if i == math.min(#stagePercentages - 2, frame.numStages) then
                    currentStage = i
                    stageStartPercent = cumulative
                    stageEndPercent = 1.0
                end
            end
        else
            -- Fallback: divide evenly, accounting for blank period
            local stageSize = (1.0 - stage1StartPercent) / frame.numStages
            if progressPercent < stage1StartPercent then
                currentStage = 0
                stageStartPercent = 0
                stageEndPercent = stage1StartPercent
            else
                local adjustedProgress = progressPercent - stage1StartPercent
                currentStage = math.min(math.max(1, math.ceil(adjustedProgress / stageSize)), frame.numStages)
                stageStartPercent = stage1StartPercent + (currentStage - 1) * stageSize
                stageEndPercent = stage1StartPercent + currentStage * stageSize
            end
        end
        
        -- Get stage colors from config
        local cfg = NephUI.db.profile.castBar
        local stageColors = cfg and cfg.empoweredStageColors or {}
        local defaultColors = {
            [1] = {0.3, 0.75, 1, 1},      -- Teal
            [2] = {1, 0.75, 0.3, 1},      -- Amber/Gold
            [3] = {0.7, 0.1, 0.1, 1},     -- Dark red
            [4] = {1, 0.5, 0, 1},          -- Orange
            [5] = {1, 0.2, 0.2, 1},        -- Red
        }
        
        local neutralColor = {0.1, 0.1, 0.1, 1}  -- Very dark gray
        -- If currentStage is 0 (blank period), use neutral color, otherwise use stage color
        local stageColor
        if currentStage == 0 then
            stageColor = neutralColor
        else
            stageColor = stageColors[currentStage] or defaultColors[currentStage] or defaultColors[1]
        end
        
        -- Keep main background neutral
        if frame.bg then
            local bgColor = cfg and cfg.bgColor or { 0.1, 0.1, 0.1, 1 }
            frame.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
        end
        
        -- Check if stage colors should be shown
        local showStageColors = true  -- Default to true
        if cfg and cfg.showEmpoweredStageColors == false then
            showStageColors = false
        end
        
        -- Hide main status bar if stage colors are enabled - we'll use segment fills instead for per-segment coloring
        -- If stage colors are disabled, show the normal status bar
        local statusTex = status:GetStatusBarTexture()
        if statusTex then
            if showStageColors then
                statusTex:SetAlpha(0)  -- Hide the main status bar when using stage colors
            else
                statusTex:SetAlpha(1)  -- Show the main status bar when stage colors are disabled
            end
        end
        status:SetMinMaxValues(0, duration)
        status:SetValue(progress)
        
        -- Get status bar width for calculations
        local statusWidth = status:GetWidth()
        if statusWidth <= 0 then
            -- Fallback if width not available
            statusWidth = 200
        end
        
        -- Update segment backgrounds and fills
        if frame.empoweredSegments and frame.empoweredSegmentFills then
            -- Update initial blank period segment (if it exists)
            if stage1StartPercent > 0 then
                local blankSegmentBg = frame.empoweredSegments[0]
                local blankSegmentFill = frame.empoweredSegmentFills[0]
                
                if blankSegmentBg and blankSegmentFill then
                    local blankSegmentWidth = stage1StartPercent * statusWidth
                    
                    -- Background is already set in InitializeEmpoweredStages, just ensure it's shown
                    blankSegmentBg:Show()
                    
                    -- Update foreground fill based on progress
                    if progressPercent < stage1StartPercent then
                        -- Still in blank period - show progress
                        local blankProgress = progressPercent / stage1StartPercent
                        local fillWidth = math.max(0, blankSegmentWidth * blankProgress)
                        blankSegmentFill:SetWidth(fillWidth)
                        
                        -- Use regular cast bar color for foreground
                        local barColor = cfg and cfg.color or { 1.0, 0.7, 0.0, 1.0 }
                        local useClassColor = cfg and cfg.useClassColor or false
                        if useClassColor then
                            local r, g, b = GetClassColor()
                            blankSegmentFill:SetColorTexture(r, g, b, 1)
                        else
                            blankSegmentFill:SetColorTexture(barColor[1], barColor[2], barColor[3], barColor[4] or 1)
                        end
                        blankSegmentFill:Show()
                    else
                        -- Past blank period - show full fill
                        blankSegmentFill:SetWidth(blankSegmentWidth)
                        local barColor = cfg and cfg.color or { 1.0, 0.7, 0.0, 1.0 }
                        local useClassColor = cfg and cfg.useClassColor or false
                        if useClassColor then
                            local r, g, b = GetClassColor()
                            blankSegmentFill:SetColorTexture(r, g, b, 1)
                        else
                            blankSegmentFill:SetColorTexture(barColor[1], barColor[2], barColor[3], barColor[4] or 1)
                        end
                        blankSegmentFill:Show()
                    end
                end
            end
            
            if showStageColors then
                -- Get tick positions for segment boundaries
                -- stage1StartPercent is already calculated above in the stage detection logic
                local tickPositions = {}
                -- Calculate cumulative positions starting from stage 1
                if #stagePercentages > 0 then
                    local cumulative = stage1StartPercent
                    for i = 1, math.min(#stagePercentages - 2, frame.numStages) do  -- Exclude blank period and hold-at-max
                        cumulative = cumulative + (stagePercentages[i + 1] or 0)  -- i+1 because we skip the first (blank period)
                        tickPositions[i] = cumulative
                    end
                else
                    -- Fallback: assume 20% blank period, then distribute stages evenly
                    local fallbackStage1Start = 0.2
                    local stageSize = (1.0 - fallbackStage1Start) / frame.numStages
                    for i = 1, frame.numStages do
                        tickPositions[i] = fallbackStage1Start + (i * stageSize)
                    end
                end
                
                -- Calculate where the hold-to-max period starts (end of last actual stage)
                local lastStageEndPercent = stage1StartPercent
                if #tickPositions > 0 and frame.numStages > 0 then
                    -- If we have tick positions, the last stage starts at the last tick position
                    if frame.numStages > 1 then
                        local lastTickPos = tickPositions[frame.numStages - 1] or stage1StartPercent
                        -- Estimate last stage size (average of other stages)
                        local avgStageSize = (lastTickPos - stage1StartPercent) / (frame.numStages - 1)
                        lastStageEndPercent = lastTickPos + avgStageSize
                    else
                        -- Only one stage
                        lastStageEndPercent = 0.9
                    end
                else
                    -- Fallback: calculate based on number of stages
                    local stageArea = 0.9 - stage1StartPercent
                    local stageSize = stageArea / frame.numStages
                    lastStageEndPercent = stage1StartPercent + (frame.numStages * stageSize)
                end
                -- Ensure hold-to-max starts before 1.0
                local holdAtMaxStartPercent = math.min(math.max(lastStageEndPercent, stage1StartPercent), 0.95)
                local holdAtMaxEndPercent = 1.0
                
                -- Start segments from stage 1 start position
                local prevPosition = stage1StartPercent
                for i = 1, frame.numStages do
                    -- For the final stage, end at holdAtMaxStartPercent (before hold-to-max period)
                    local segmentEnd
                    if i == frame.numStages then
                        segmentEnd = holdAtMaxStartPercent
                    else
                        segmentEnd = tickPositions[i] or (prevPosition + (1.0 - stage1StartPercent) / frame.numStages)
                    end
                    local segmentStart = prevPosition
                    local segmentWidth = (segmentEnd - segmentStart) * statusWidth
                    
                    -- Debug: ensure final stage segment has valid width
                    if i == frame.numStages and segmentWidth <= 0 then
                        -- Fallback: use remaining space
                        segmentWidth = (holdAtMaxStartPercent - segmentStart) * statusWidth
                    end
                    
                    -- Get this stage's color (stage 1 is index 1, not 0)
                    local thisStageColor = stageColors[i] or defaultColors[i] or defaultColors[1]
                    
                    -- Get the alpha/opacity from the stage color (use same alpha for both background and foreground)
                    local stageAlpha = thisStageColor[4] or 1
                    
                    -- Update segment background - ALL segments always show their stage colors (50% darker)
                    local segmentBg = frame.empoweredSegments[i]
                    if segmentBg then
                        -- Always use 50% darker version of the stage color for background
                        -- Use the same alpha as the foreground color
                        -- This creates the highlight effect when foreground (full color) is shown on top
                        segmentBg:SetColorTexture(thisStageColor[1] * 0.5, thisStageColor[2] * 0.5, thisStageColor[3] * 0.5, stageAlpha)
                        segmentBg:Show()
                    end
                    
                    -- Update segment fill (foreground) - colored with this stage's color
                    local segmentFill = frame.empoweredSegmentFills[i]
                    if segmentFill then
                        -- Special handling for final stage: always check if progress is in final stage range
                        if i == frame.numStages then
                            -- For final stage, check if progress is in the final stage segment range
                            if progressPercent >= segmentStart and progressPercent < holdAtMaxStartPercent then
                                -- In final stage segment - show progress
                                local segmentDuration = segmentEnd - segmentStart
                                if segmentDuration > 0 then
                                    local stageProgress = math.min(1.0, math.max(0, (progressPercent - segmentStart) / segmentDuration))
                                    local fillWidth = math.max(0, segmentWidth * stageProgress)
                                    segmentFill:SetWidth(fillWidth)
                                    segmentFill:SetColorTexture(thisStageColor[1], thisStageColor[2], thisStageColor[3], stageAlpha)
                                    segmentFill:Show()
                                else
                                    segmentFill:SetWidth(0)
                                    segmentFill:Hide()
                                end
                            elseif progressPercent >= holdAtMaxStartPercent then
                                -- Past final stage segment, show full (we're in hold-to-max now)
                                segmentFill:SetWidth(segmentWidth)
                                segmentFill:SetColorTexture(thisStageColor[1], thisStageColor[2], thisStageColor[3], stageAlpha)
                                segmentFill:Show()
                            else
                                -- Before final stage segment
                                segmentFill:SetWidth(0)
                                segmentFill:Hide()
                            end
                        elseif i < currentStage then
                            -- Past stages: show full fill
                            segmentFill:SetWidth(segmentWidth)
                            segmentFill:SetColorTexture(thisStageColor[1], thisStageColor[2], thisStageColor[3], stageAlpha)
                            segmentFill:Show()
                        elseif i == currentStage and currentStage > 0 then
                            -- Current stage: show progress within this segment
                            local stageProgress = 0
                            if progressPercent >= segmentStart and progressPercent <= segmentEnd then
                                local segmentDuration = segmentEnd - segmentStart
                                if segmentDuration > 0 then
                                    stageProgress = math.min(1.0, math.max(0, (progressPercent - segmentStart) / segmentDuration))
                                end
                            elseif progressPercent > segmentEnd then
                                -- Past this segment, show full
                                stageProgress = 1.0
                            end
                            
                            local fillWidth = math.max(0, segmentWidth * stageProgress)
                            segmentFill:SetWidth(fillWidth)
                            segmentFill:SetColorTexture(thisStageColor[1], thisStageColor[2], thisStageColor[3], stageAlpha)
                            segmentFill:Show()
                        else
                            -- Future stages: no fill yet
                            segmentFill:SetWidth(0)
                            segmentFill:Hide()
                        end
                    end
                    
                    prevPosition = segmentEnd
                end
                
                -- Update hold-to-max segment (the final 1 second period)
                if holdAtMaxStartPercent < 1.0 then
                    local holdAtMaxSegmentBg = frame.empoweredSegments[-1]
                    local holdAtMaxSegmentFill = frame.empoweredSegmentFills[-1]
                    
                    if holdAtMaxSegmentBg and holdAtMaxSegmentFill then
                        local holdAtMaxSegmentWidth = (holdAtMaxEndPercent - holdAtMaxStartPercent) * statusWidth
                        
                        -- Background is always shown with final stage color (50% darker)
                        local finalStageColor = stageColors[frame.numStages] or defaultColors[frame.numStages] or defaultColors[1]
                        local finalStageAlpha = finalStageColor[4] or 1
                        holdAtMaxSegmentBg:SetColorTexture(finalStageColor[1] * 0.5, finalStageColor[2] * 0.5, finalStageColor[3] * 0.5, finalStageAlpha)
                        holdAtMaxSegmentBg:Show()
                        
                        -- Update foreground fill based on progress
                        if progressPercent >= holdAtMaxStartPercent then
                            -- In or past hold-to-max period
                            local holdAtMaxProgress = 0
                            if progressPercent >= holdAtMaxStartPercent and progressPercent <= holdAtMaxEndPercent then
                                local holdAtMaxDuration = holdAtMaxEndPercent - holdAtMaxStartPercent
                                if holdAtMaxDuration > 0 then
                                    holdAtMaxProgress = math.min(1.0, math.max(0, (progressPercent - holdAtMaxStartPercent) / holdAtMaxDuration))
                                end
                            elseif progressPercent > holdAtMaxEndPercent then
                                -- Past hold-to-max, show full
                                holdAtMaxProgress = 1.0
                            end
                            
                            local fillWidth = math.max(0, holdAtMaxSegmentWidth * holdAtMaxProgress)
                            holdAtMaxSegmentFill:SetWidth(fillWidth)
                            holdAtMaxSegmentFill:SetColorTexture(finalStageColor[1], finalStageColor[2], finalStageColor[3], finalStageAlpha)
                            holdAtMaxSegmentFill:Show()
                        else
                            -- Before hold-to-max period
                            holdAtMaxSegmentFill:SetWidth(0)
                            holdAtMaxSegmentFill:Hide()
                        end
                    end
                end
            else
                -- Stage colors disabled - hide all segments and fills (including blank period), show normal status bar
                -- Hide blank period segment
                local blankSegmentBg = frame.empoweredSegments[0]
                if blankSegmentBg then
                    blankSegmentBg:Hide()
                end
                local blankSegmentFill = frame.empoweredSegmentFills[0]
                if blankSegmentFill then
                    blankSegmentFill:Hide()
                end
                
                -- Hide stage segments
                for i = 1, frame.numStages do
                    local segmentBg = frame.empoweredSegments[i]
                    if segmentBg then
                        segmentBg:Hide()
                    end
                    local segmentFill = frame.empoweredSegmentFills[i]
                    if segmentFill then
                        segmentFill:Hide()
                    end
                end
                -- Hide hold-to-max segment
                local holdAtMaxSegmentBg = frame.empoweredSegments[-1]
                if holdAtMaxSegmentBg then
                    holdAtMaxSegmentBg:Hide()
                end
                local holdAtMaxSegmentFill = frame.empoweredSegmentFills[-1]
                if holdAtMaxSegmentFill then
                    holdAtMaxSegmentFill:Hide()
                end
                -- Show the main status bar instead
                local statusTex = status:GetStatusBarTexture()
                if statusTex then
                    statusTex:SetAlpha(1)  -- Show the main status bar
                end
            end
        end
        
        -- Hide glow effect
        if frame.empoweredGlow then
            frame.empoweredGlow:Hide()
        end
        
        -- Store current stage for reference
        frame.currentEmpoweredStage = currentStage
    else
        -- Regular cast - use normal status bar
        -- Restore status bar visibility
        local statusTex = status:GetStatusBarTexture()
        if statusTex then
            statusTex:SetAlpha(1)  -- Show the main status bar for regular casts
        end
        status:SetMinMaxValues(0, duration)
        status:SetValue(progress)
        
        -- Hide empowered segments and fills (including blank period segment at index 0 and hold-to-max at index -1)
        if frame.empoweredSegments then
            -- Hide blank period segment
            if frame.empoweredSegments[0] then
                frame.empoweredSegments[0]:Hide()
            end
            -- Hide hold-to-max segment
            if frame.empoweredSegments[-1] then
                frame.empoweredSegments[-1]:Hide()
            end
            -- Hide stage segments
            for _, segment in ipairs(frame.empoweredSegments) do
                if segment then
                    segment:Hide()
                end
            end
        end
        if frame.empoweredSegmentFills then
            -- Hide blank period fill
            if frame.empoweredSegmentFills[0] then
                frame.empoweredSegmentFills[0]:Hide()
            end
            -- Hide hold-to-max fill
            if frame.empoweredSegmentFills[-1] then
                frame.empoweredSegmentFills[-1]:Hide()
            end
            -- Hide stage fills
            for _, fill in ipairs(frame.empoweredSegmentFills) do
                if fill then
                    fill:Hide()
                end
            end
        end
        
        -- Restore status bar (already visible, just ensure it's normal)
        -- Status bar texture is already at alpha 1 for regular casts
        
        -- Restore normal background color
        if frame == NephUI.castBar then
            local cfg = NephUI.db.profile.castBar
            local bgColor = cfg and cfg.bgColor or { 0.1, 0.1, 0.1, 1 }
            if frame.bg then
                frame.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
            end
        end
    end

    if frame.timeText then
        -- Get the config for this cast bar
        local cfg
        if frame == NephUI.castBar then
            cfg = NephUI.db.profile.castBar
        elseif frame == NephUI.targetCastBar then
            cfg = NephUI.db.profile.targetCastBar
        elseif frame == NephUI.focusCastBar then
            cfg = NephUI.db.profile.focusCastBar
        elseif NephUI.bossCastBars then
            -- Check if this is a boss cast bar
            for _, bossBar in pairs(NephUI.bossCastBars) do
                if frame == bossBar then
                    cfg = NephUI.db.profile.bossCastBar
                    break
                end
            end
        end
        
        -- Show/hide time text based on setting
        if cfg and cfg.showTimeText ~= false then
            frame.timeText:Show()
            -- Boss cast bars show current/max format, others show remaining time
            if cfg == NephUI.db.profile.bossCastBar then
                frame.timeText:SetFormattedText("%.1f/%.1f", progress, duration)
            else
                frame.timeText:SetFormattedText("%.1f", remaining)
            end
        else
            frame.timeText:Hide()
        end
    end
end

-- Export CastBar_OnUpdate
CastBars.CastBar_OnUpdate = CastBar_OnUpdate

-- Initialize function
function CastBars:Initialize()
    -- Register player cast bar events
    NephUI:RegisterEvent("UNIT_SPELLCAST_START", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastStart then
            self:OnPlayerSpellcastStart(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_STOP", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastStop then
            self:OnPlayerSpellcastStop(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_FAILED", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastStop then
            self:OnPlayerSpellcastStop(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastStop then
            self:OnPlayerSpellcastStop(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastChannelStart then
            self:OnPlayerSpellcastChannelStart(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastStop then
            self:OnPlayerSpellcastStop(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastChannelUpdate then
            self:OnPlayerSpellcastChannelUpdate(unit, castGUID, spellID)
        end
    end)
    
    -- Register empowered cast events
    NephUI:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastEmpowerStart then
            self:OnPlayerSpellcastEmpowerStart(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastEmpowerUpdate then
            self:OnPlayerSpellcastEmpowerUpdate(unit, castGUID, spellID)
        end
    end)
    
    NephUI:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP", function(_, unit, castGUID, spellID)
        if unit == "player" and self.OnPlayerSpellcastEmpowerStop then
            self:OnPlayerSpellcastEmpowerStop(unit, castGUID, spellID)
        end
    end)
    
    -- Hook target and focus cast bars (will be called from OnEnable with delay)
    if self.HookTargetAndFocusCastBars then
        self:HookTargetAndFocusCastBars()
    end
    if self.HookFocusCastBar then
        self:HookFocusCastBar()
    end
end

-- Refresh function
function CastBars:RefreshAll()
    if self.UpdateCastBarLayout then
        self:UpdateCastBarLayout()
    end
    if self.UpdateTargetCastBarLayout then
        self:UpdateTargetCastBarLayout()
    end
    if self.UpdateFocusCastBarLayout then
        self:UpdateFocusCastBarLayout()
    end
end

-- Test functions for showing fake casts
function CastBars:ShowTestCastBar()
    if not self.GetCastBar then return end
    
    local bar = self:GetCastBar()
    if not bar then return end
    
    if self.UpdateCastBarLayout then
        self:UpdateCastBarLayout()
    end
    
    local now = GetTime()
    bar.startTime = now
    bar.endTime = now + 15
    bar.isChannel = false
    bar.castGUID = "test_" .. now
    bar.isEmpowered = false
    bar.numStages = nil
    
    bar.icon:SetTexture(136243)  -- Default spell icon
    bar.spellName:SetText("Test Cast")
    
    local cfg = NephUI.db.profile.castBar
    local font = NephUI:GetGlobalFont()
    bar.spellName:SetFont(font, cfg.textSize or 10, "OUTLINE")
    bar.spellName:SetShadowOffset(0, 0)
    
    if bar.timeText then
        bar.timeText:SetFont(font, cfg.textSize or 10, "OUTLINE")
        bar.timeText:SetShadowOffset(0, 0)
    end
    
    bar:SetScript("OnUpdate", CastBars.CastBar_OnUpdate)
    bar:Show()
end

function CastBars:ShowTestTargetCastBar()
    if not self.GetTargetCastBar then return end
    
    local bar = self:GetTargetCastBar()
    if not bar then return end
    
    if self.UpdateTargetCastBarLayout then
        self:UpdateTargetCastBarLayout()
    end
    
    local now = GetTime()
    bar.startTime = now
    bar.endTime = now + 15
    bar.isChannel = false
    bar.castGUID = "test_target_" .. now
    bar.isEmpowered = false
    bar.numStages = nil
    
    bar.icon:SetTexture(136243)  -- Default spell icon
    bar.spellName:SetText("Test Target Cast")
    
    local cfg = NephUI.db.profile.targetCastBar
    local font = NephUI:GetGlobalFont()
    bar.spellName:SetFont(font, cfg.textSize or 10, "OUTLINE")
    bar.spellName:SetShadowOffset(0, 0)
    
    if bar.timeText then
        bar.timeText:SetFont(font, cfg.textSize or 10, "OUTLINE")
        bar.timeText:SetShadowOffset(0, 0)
    end
    
    bar:SetScript("OnUpdate", CastBars.CastBar_OnUpdate)
    bar:Show()
end

function CastBars:ShowTestFocusCastBar()
    if not self.GetFocusCastBar then return end
    
    local bar = self:GetFocusCastBar()
    if not bar then return end
    
    if self.UpdateFocusCastBarLayout then
        self:UpdateFocusCastBarLayout()
    end
    
    local now = GetTime()
    bar.startTime = now
    bar.endTime = now + 15
    bar.isChannel = false
    bar.castGUID = "test_focus_" .. now
    bar.isEmpowered = false
    bar.numStages = nil
    
    bar.icon:SetTexture(136243)  -- Default spell icon
    bar.spellName:SetText("Test Focus Cast")
    
    local cfg = NephUI.db.profile.focusCastBar
    local font = NephUI:GetGlobalFont()
    bar.spellName:SetFont(font, cfg.textSize or 10, "OUTLINE")
    bar.spellName:SetShadowOffset(0, 0)
    
    if bar.timeText then
        bar.timeText:SetFont(font, cfg.textSize or 10, "OUTLINE")
        bar.timeText:SetShadowOffset(0, 0)
    end
    
    bar:SetScript("OnUpdate", CastBar_OnUpdate)
    bar:Show()
end

-- Expose test functions to main addon
NephUI.ShowTestCastBar = function(self) return CastBars:ShowTestCastBar() end
NephUI.ShowTestTargetCastBar = function(self) return CastBars:ShowTestTargetCastBar() end
NephUI.ShowTestFocusCastBar = function(self) return CastBars:ShowTestFocusCastBar() end


