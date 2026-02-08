local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Helper function to get charge anchor options
local function GetChargeAnchorOptions()
    return {
        TOPLEFT     = "Top Left",
        TOP         = "Top",
        TOPRIGHT    = "Top Right",
        LEFT        = "Left",
        MIDDLE      = "Middle",
        RIGHT       = "Right",
        BOTTOMLEFT  = "Bottom Left",
        BOTTOM      = "Bottom",
        BOTTOMRIGHT = "Bottom Right",
    }
end

-- Helper function to get viewer options
local function GetViewerOptions()
    return {
        ["EssentialCooldownViewer"] = "Essential Cooldowns",
        ["UtilityCooldownViewer"] = "Utility Cooldowns",
        ["BuffIconCooldownViewer"] = "Buff Icons",
    }
end

-- Helper to create viewer option groups
local function CreateViewerOptions(viewerKey, displayName, order)
    local ret = {
        type = "group",
        name = displayName,
        order = order,
        args = {
            header = {
                type = "header",
                name = displayName .. " Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable",
                desc = "Show/hide this icon viewer",
                width = "full",
                order = 2,
                get = function() return NephUI.db.profile.viewers[viewerKey].enabled end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].enabled = val
                    local viewer = _G[viewerKey]
                    if viewer then
                        if val then
                            viewer:Show()
                        else
                            viewer:Hide()
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            -- Icon Layout Section
            iconLayoutHeader = {
                type = "header",
                name = "Icon Layout",
                order = 10,
            },
            rowLimit = {
                type = "range",
                name = "Icons Per Row",
                desc = "Maximum icons per row (0 = unlimited, single row). When exceeded, creates new rows that grow from the center.",
                order = 10.9,
                width = "normal",
                min = 0, max = 20, step = 1,
                get = function() return NephUI.db.profile.viewers[viewerKey].rowLimit or 0 end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].rowLimit = val
                    -- Force immediate layout update
                    local viewer = _G[viewerKey]
                    if viewer then
                        viewer.__cdmLastGrowthDirection = nil
                        if NephUI.IconViewers and NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            iconSize = {
                type = "range",
                name = "Icon Size",
                desc = "Base size of each icon in pixels (longest dimension)",
                order = 11,
                width = "full",
                min = 16, max = 96, step = 1,
                get = function() return NephUI.db.profile.viewers[viewerKey].iconSize end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].iconSize = val
                    -- Force re-skin of all icons in this viewer
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                        if NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            rowIconSize1 = {
                type = "range",
                name = "Row 1 Icon Size",
                desc = "Override the icon size for the first row. Set to 0 to use the base Icon Size value.",
                order = 11.1,
                width = "normal",
                min = 0, max = 128, step = 1,
                get = function()
                    local sizes = NephUI.db.profile.viewers[viewerKey].rowIconSizes
                    return (sizes and sizes[1]) or 0
                end,
                set = function(_, val)
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    profile.rowIconSizes = profile.rowIconSizes or {}
                    profile.rowIconSizes[1] = (val and val > 0) and val or nil

                    local viewer = _G[viewerKey]
                    if viewer then
                        viewer.__cdmLastGrowthDirection = nil
                        viewer.__cdmLastAppearanceKey = nil
                        if NephUI.IconViewers and NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            rowIconSize2 = {
                type = "range",
                name = "Row 2 Icon Size",
                desc = "Override the icon size for the second row. Set to 0 to use the base Icon Size value.",
                order = 11.2,
                width = "normal",
                min = 0, max = 128, step = 1,
                get = function()
                    local sizes = NephUI.db.profile.viewers[viewerKey].rowIconSizes
                    return (sizes and sizes[2]) or 0
                end,
                set = function(_, val)
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    profile.rowIconSizes = profile.rowIconSizes or {}
                    profile.rowIconSizes[2] = (val and val > 0) and val or nil

                    local viewer = _G[viewerKey]
                    if viewer then
                        viewer.__cdmLastGrowthDirection = nil
                        viewer.__cdmLastAppearanceKey = nil
                        if NephUI.IconViewers and NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            rowIconSize3 = {
                type = "range",
                name = "Row 3 Icon Size",
                desc = "Override the icon size for the third row. Set to 0 to use the base Icon Size value.",
                order = 11.3,
                width = "normal",
                min = 0, max = 128, step = 1,
                get = function()
                    local sizes = NephUI.db.profile.viewers[viewerKey].rowIconSizes
                    return (sizes and sizes[3]) or 0
                end,
                set = function(_, val)
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    profile.rowIconSizes = profile.rowIconSizes or {}
                    profile.rowIconSizes[3] = (val and val > 0) and val or nil

                    local viewer = _G[viewerKey]
                    if viewer then
                        viewer.__cdmLastGrowthDirection = nil
                        viewer.__cdmLastAppearanceKey = nil
                        if NephUI.IconViewers and NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            aspectRatio = {
                type = "range",
                name = "Aspect Ratio (Width:Height)",
                desc = "Control the icon aspect ratio. 1.0 = square, >1.0 = wider, <1.0 = taller. Examples: 1.0=1:1, 1.78=16:9, 0.56=9:16",
                order = 12,
                width = "full",
                min = 0.5, max = 2.5, step = 0.01,
                get = function() 
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    -- Convert aspect ratio string to number, or use stored crop value
                    if profile.aspectRatioCrop then
                        return profile.aspectRatioCrop
                    elseif profile.aspectRatio then
                        -- Convert "16:9" format to 1.78
                        local w, h = profile.aspectRatio:match("^(%d+):(%d+)$")
                        if w and h then
                            return tonumber(w) / tonumber(h)
                        end
                    end
                    return 1.0 -- Default to square
                end,
                set = function(_, val)
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    profile.aspectRatioCrop = val
                    -- Also store as string format for backwards compatibility
                    -- Round to nearest common ratio or use exact value
                    local rounded = math.floor(val * 100 + 0.5) / 100
                    profile.aspectRatio = string.format("%.2f:1", rounded)
                    -- Force re-skin of all icons in this viewer (aspect ratio affects texture coordinates)
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                        if NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            spacing = {
                type = "range",
                name = "Spacing",
                desc = "Space between icons (negative = overlap)",
                order = 13,
                width = "normal",
                min = -20, max = 20, step = 1,
                get = function() return NephUI.db.profile.viewers[viewerKey].spacing end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].spacing = val
                    -- Force immediate layout update
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers and NephUI.IconViewers.ApplyViewerLayout then
                        NephUI.IconViewers:ApplyViewerLayout(viewer)
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            zoom = {
                type = "range",
                name = "Icon Zoom",
                desc = "Crops the edges of icons (higher = more zoom)",
                order = 14,
                width = "normal",
                min = 0, max = 0.2, step = 0.01,
                get = function() return NephUI.db.profile.viewers[viewerKey].zoom end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].zoom = val
                    -- Force re-skin of all icons in this viewer (zoom affects texture coordinates)
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            primaryDirection = {
                type = "select",
                name = "Primary Growth Direction",
                desc = "Direction that icons grow in the first line. CENTERED_HORIZONTAL centers icons and expands left/right. Static keeps icons in original positions (BuffIconCooldownViewer only).",
                order = 17,
                width = "normal",
                values = function()
                    local values = {
                        ["CENTERED_HORIZONTAL"] = "Centered Horizontal",
                        ["RIGHT"] = "Right",
                        ["LEFT"] = "Left",
                        ["UP"] = "Up",
                        ["DOWN"] = "Down",
                    }
                    if viewerKey == "BuffIconCooldownViewer" then
                        values["STATIC"] = "Static"
                    end
                    return values
                end,
                get = function()
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    if profile.primaryDirection then
                        return profile.primaryDirection
                    end
                    -- Legacy: Parse from growthDirection
                    if profile.growthDirection then
                        if profile.growthDirection == "Static" then
                            return "STATIC"
                        elseif profile.growthDirection == "Centered Horizontal" then
                            return "CENTERED_HORIZONTAL"
                        elseif profile.growthDirection:match("^Centered Horizontal and") then
                            return "CENTERED_HORIZONTAL"
                        else
                            local primary = profile.growthDirection:match("^(%w+)")
                            if primary then
                                return primary:upper()
                            end
                        end
                    end
                    -- Legacy support for rowGrowDirection
                    if profile.rowGrowDirection then
                        return "CENTERED_HORIZONTAL"
                    end
                    return "CENTERED_HORIZONTAL"
                end,
                set = function(_, val)
                    if not NephUI.db.profile.viewers[viewerKey] then
                        NephUI.db.profile.viewers[viewerKey] = {}
                    end
                    
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    profile.primaryDirection = val
                    
                    local secondary = profile.secondaryDirection
                    
                    -- Validate and clear invalid secondary directions
                    if val == "STATIC" then
                        secondary = nil
                        profile.secondaryDirection = nil
                    elseif val == "CENTERED_HORIZONTAL" then
                        -- Only allow UP/DOWN for centered horizontal
                        if secondary and secondary ~= "UP" and secondary ~= "DOWN" then
                            secondary = nil
                            profile.secondaryDirection = nil
                        end
                    elseif val == "UP" or val == "DOWN" then
                        -- Vertical primary: only allow LEFT/RIGHT secondary
                        if secondary and secondary ~= "LEFT" and secondary ~= "RIGHT" then
                            secondary = nil
                            profile.secondaryDirection = nil
                        end
                    elseif val == "LEFT" or val == "RIGHT" then
                        -- Horizontal primary: only allow UP/DOWN secondary
                        if secondary and secondary ~= "UP" and secondary ~= "DOWN" then
                            secondary = nil
                            profile.secondaryDirection = nil
                        end
                    end
                    
                    -- Clear legacy settings
                    if profile.rowGrowDirection then
                        profile.rowGrowDirection = nil
                    end
                    if profile.growthDirection then
                        profile.growthDirection = nil
                    end
                    
                    -- Force immediate layout update
                    local viewer = _G[viewerKey]
                    if viewer then
                        viewer.__cdmLastGrowthDirection = nil
                        if NephUI.IconViewers and NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                    
                    -- Notify AceConfig to refresh the secondary dropdown values
                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                    if AceConfigRegistry then
                        AceConfigRegistry:NotifyChange(ADDON_NAME)
                    end
                end,
            },
            secondaryDirection = {
                type = "select",
                name = "Secondary Growth Direction",
                desc = "Direction that new rows/columns grow when icon limit per line is reached.",
                order = 18,
                width = "normal",
                values = function()
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    if not profile then
                        return {
                            ["UP"] = "Up",
                            ["DOWN"] = "Down",
                        }
                    end
                    
                    local primary = profile.primaryDirection
                    if not primary then
                        -- Try to parse from legacy growthDirection
                        if profile.growthDirection then
                            if profile.growthDirection == "Static" or profile.growthDirection == "STATIC" then
                                return {}
                            elseif profile.growthDirection == "Centered Horizontal" then
                                primary = "CENTERED_HORIZONTAL"
                            elseif profile.growthDirection:match("^Centered Horizontal and") then
                                primary = "CENTERED_HORIZONTAL"
                            else
                                local p = profile.growthDirection:match("^(%w+)")
                                if p then
                                    primary = p:upper()
                                end
                            end
                        end
                        if not primary then
                            primary = "CENTERED_HORIZONTAL"
                        end
                    end
                    
                    -- Return allowed secondary directions based on primary
                    if primary == "STATIC" then
                        return {}
                    elseif primary == "CENTERED_HORIZONTAL" then
                        -- Centered horizontal: only UP/DOWN allowed
                        return {
                            ["UP"] = "Up",
                            ["DOWN"] = "Down",
                        }
                    elseif primary == "UP" or primary == "DOWN" then
                        -- Vertical primary: only LEFT/RIGHT allowed
                        return {
                            ["LEFT"] = "Left",
                            ["RIGHT"] = "Right",
                        }
                    elseif primary == "LEFT" or primary == "RIGHT" then
                        -- Horizontal primary: only UP/DOWN allowed
                        return {
                            ["UP"] = "Up",
                            ["DOWN"] = "Down",
                        }
                    else
                        -- Default to UP/DOWN
                        return {
                            ["UP"] = "Up",
                            ["DOWN"] = "Down",
                        }
                    end
                end,
                get = function()
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    if profile.secondaryDirection then
                        return profile.secondaryDirection
                    end
                    -- Legacy: Parse from growthDirection
                    if profile.growthDirection then
                        local secondary = profile.growthDirection:match("and%s+(%w+)$")
                        if secondary then
                            return secondary:upper()
                        end
                    end
                    -- Legacy support
                    if profile.rowGrowDirection then
                        return profile.rowGrowDirection == "up" and "UP" or "DOWN"
                    end
                    return nil
                end,
                set = function(_, val)
                    if not NephUI.db.profile.viewers[viewerKey] then
                        NephUI.db.profile.viewers[viewerKey] = {}
                    end
                    
                    local profile = NephUI.db.profile.viewers[viewerKey]
                    profile.secondaryDirection = val
                    
                    -- Clear legacy settings
                    if profile.rowGrowDirection then
                        profile.rowGrowDirection = nil
                    end
                    if profile.growthDirection then
                        profile.growthDirection = nil
                    end
                    
                    -- Force immediate layout update
                    local viewer = _G[viewerKey]
                    if viewer then
                        viewer.__cdmLastGrowthDirection = nil
                        if NephUI.IconViewers and NephUI.IconViewers.ApplyViewerLayout then
                            NephUI.IconViewers:ApplyViewerLayout(viewer)
                        end
                    end
                    
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            
            -- Border Section
            borderHeader = {
                type = "header",
                name = "Borders",
                order = 20,
            },
            borderSize = {
                type = "range",
                name = "Border Size",
                desc = "Border thickness (0 = no border)",
                order = 21,
                width = "full",
                min = 0, max = 5, step = 1,
                get = function() return NephUI.db.profile.viewers[viewerKey].borderSize end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].borderSize = val
                    -- Force re-skin of all icons in this viewer (border size affects border display)
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            
            -- Charge / Stack Text Section
            chargeTextHeader = {
                type = "header",
                name = "Charge / Stack Text",
                order = 30,
            },
            countTextSize = {
                type = "range",
                name = "Text Size",
                desc = "Font size for charge/stack numbers",
                order = 31,
                width = "full",
                min = 6, max = 32, step = 1,
                get = function() return NephUI.db.profile.viewers[viewerKey].countTextSize or 16 end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].countTextSize = val
                    -- Force re-skin of all icons in this viewer (text size affects charge/stack text)
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            chargeTextAnchor = {
                type = "select",
                name = "Text Position",
                desc = "Where to anchor the charge/stack text",
                order = 32,
                width = "normal",
                values = GetChargeAnchorOptions(),
                get = function()
                    return NephUI.db.profile.viewers[viewerKey].chargeTextAnchor or "BOTTOMRIGHT"
                end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].chargeTextAnchor = val
                    -- Force re-skin of all icons in this viewer (text anchor affects charge/stack text position)
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            countTextOffsetX = {
                type = "range",
                name = "Horizontal Offset",
                desc = "Fine-tune text position horizontally",
                order = 33,
                width = "normal",
                min = -50, max = 50, step = 1,
                get = function()
                    return NephUI.db.profile.viewers[viewerKey].countTextOffsetX or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].countTextOffsetX = val
                    -- Force re-skin of all icons in this viewer (offset affects charge/stack text position)
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            countTextOffsetY = {
                type = "range",
                name = "Vertical Offset",
                desc = "Fine-tune text position vertically",
                order = 34,
                width = "normal",
                min = -50, max = 50, step = 1,
                get = function()
                    return NephUI.db.profile.viewers[viewerKey].countTextOffsetY or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].countTextOffsetY = val
                    -- Force re-skin of all icons in this viewer (offset affects charge/stack text position)
                    local viewer = _G[viewerKey]
                    if viewer and NephUI.IconViewers then
                        if NephUI.IconViewers.SkinAllIconsInViewer then
                            NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                        end
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            
            -- Cooldown Text Section
            cooldownTextHeader = {
                type = "header",
                name = "Cooldown Text",
                order = 40,
            },
            cooldownFontSize = {
                type = "range",
                name = "Font Size",
                desc = "Font size for cooldown countdown text",
                order = 41,
                width = "full",
                min = 8, max = 48, step = 1,
                get = function()
                    return NephUI.db.profile.viewers[viewerKey].cooldownFontSize or 
                           (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownFontSize) or 18
                end,
                set = function(_, val)
                    if not NephUI.db.profile.viewers[viewerKey] then
                        NephUI.db.profile.viewers[viewerKey] = {}
                    end
                    NephUI.db.profile.viewers[viewerKey].cooldownFontSize = val
                    -- Refresh all cooldown fonts
                    if NephUI.ApplyGlobalFont then
                        NephUI:ApplyGlobalFont()
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            cooldownTextColor = {
                type = "color",
                name = "Text Color",
                desc = "Color for cooldown countdown text",
                order = 42,
                width = "normal",
                hasAlpha = true,
                get = function()
                    local c = NephUI.db.profile.viewers[viewerKey].cooldownTextColor or 
                             (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    if not NephUI.db.profile.viewers[viewerKey] then
                        NephUI.db.profile.viewers[viewerKey] = {}
                    end
                    NephUI.db.profile.viewers[viewerKey].cooldownTextColor = {r, g, b, a or 1}
                    -- Refresh all cooldown fonts
                    if NephUI.ApplyGlobalFont then
                        NephUI:ApplyGlobalFont()
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            -- Shadow Subsection
            shadowHeader = {
                type = "header",
                name = "Shadow",
                order = 43,
            },
            cooldownShadowOffsetX = {
                type = "range",
                name = "Shadow Offset X",
                desc = "Horizontal shadow offset (positive = right, negative = left)",
                order = 44,
                width = "normal",
                min = -5, max = 5, step = 1,
                get = function()
                    return NephUI.db.profile.viewers[viewerKey].cooldownShadowOffsetX or 
                           (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownShadowOffsetX) or 1
                end,
                set = function(_, val)
                    if not NephUI.db.profile.viewers[viewerKey] then
                        NephUI.db.profile.viewers[viewerKey] = {}
                    end
                    NephUI.db.profile.viewers[viewerKey].cooldownShadowOffsetX = val
                    -- Refresh all cooldown fonts
                    if NephUI.ApplyGlobalFont then
                        NephUI:ApplyGlobalFont()
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            cooldownShadowOffsetY = {
                type = "range",
                name = "Shadow Offset Y",
                desc = "Vertical shadow offset (positive = up, negative = down)",
                order = 45,
                width = "normal",
                min = -5, max = 5, step = 1,
                get = function()
                    return NephUI.db.profile.viewers[viewerKey].cooldownShadowOffsetY or 
                           (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownShadowOffsetY) or -1
                end,
                set = function(_, val)
                    if not NephUI.db.profile.viewers[viewerKey] then
                        NephUI.db.profile.viewers[viewerKey] = {}
                    end
                    NephUI.db.profile.viewers[viewerKey].cooldownShadowOffsetY = val
                    -- Refresh all cooldown fonts
                    if NephUI.ApplyGlobalFont then
                        NephUI:ApplyGlobalFont()
                    end
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
        },
    }
    
    -- Add cooldown swipe alpha option for cooldown viewers
    if viewerKey == "EssentialCooldownViewer" or viewerKey == "UtilityCooldownViewer" or viewerKey == "BuffIconCooldownViewer" then
        ret.args.cooldownSwipeAlpha = {
            type = "range",
            name = "Cooldown Swipe Alpha",
            desc = "Alpha (transparency) of the cooldown swipe overlay. Does not affect duration text.",
            order = 46,
            width = "full",
            min = 0, max = 1, step = 0.05,
            get = function()
                return NephUI.db.profile.viewers[viewerKey].cooldownSwipeAlpha or 0.8
            end,
            set = function(_, val)
                if not NephUI.db.profile.viewers[viewerKey] then
                    NephUI.db.profile.viewers[viewerKey] = {}
                end
                NephUI.db.profile.viewers[viewerKey].cooldownSwipeAlpha = val
                -- Re-skin all icons in this viewer to apply the new swipe alpha
                local viewer = _G[viewerKey]
                if viewer and NephUI.IconViewers then
                    if NephUI.IconViewers.SkinAllIconsInViewer then
                        NephUI.IconViewers:SkinAllIconsInViewer(viewer)
                    end
                end
                if NephUI.RefreshViewers then
                    NephUI:RefreshViewers()
                end
            end,
        }
    end
    
    -- Add keybind and ignoreAuraOverride options at the top only for Essential and Utility viewers
    if viewerKey == "EssentialCooldownViewer" or viewerKey == "UtilityCooldownViewer" then
        local viewerSettingName = (viewerKey == "EssentialCooldownViewer") and "Essential" or "Utility"
        
        -- Keybind Text Toggle
        ret.args.showKeybinds = {
            type = "toggle",
            name = "Show Keybind Text",
            desc = "Display keybind text from action bars on cooldown icons",
            order = 2.1,
            width = "full",
            get = function()
                return NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] or false
            end,
            set = function(_, val)
                NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] = val
                if NephUI.Keybinds then
                    NephUI.Keybinds:OnSettingChanged(viewerSettingName)
                end
                -- Refresh GUI to show/hide keybind settings
                local configFrame = _G["NephUI_ConfigFrame"]
                if configFrame and configFrame:IsShown() and configFrame.FullRefresh then
                    configFrame:FullRefresh()
                end
            end,
        }
        
        -- Keybind Text Settings Header
        ret.args.keybindHeader = {
            type = "header",
            name = "Keybind Text Settings",
            order = 2.15,
        }
        
        -- Keybind Font
        ret.args.keybindFont = {
            type = "select",
            name = "Font",
            desc = "Font used for keybind text",
            order = 2.2,
            width = "full",
            values = function()
                local names = {}
                if LSM then
                    local hashTable = LSM:HashTable("font")
                    for name, _ in pairs(hashTable) do
                        names[name] = name
                    end
                end
                names["Friz Quadrata TT"] = "Friz Quadrata TT"
                return names
            end,
            get = function()
                local font = NephUI.db.profile["cooldownManager_keybindFontName_" .. viewerSettingName]
                if not font or font == "" then
                    font = NephUI.db.profile.cooldownManager_keybindFontName or "Friz Quadrata TT"
                end
                return font
            end,
            set = function(_, val)
                NephUI.db.profile["cooldownManager_keybindFontName_" .. viewerSettingName] = val
                if NephUI.Keybinds then
                    NephUI.Keybinds:ApplyKeybindSettings(viewerKey)
                end
            end,
            disabled = function()
                return not (NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] or false)
            end,
        }
        
        -- Keybind Font Size
        ret.args.keybindFontSize = {
            type = "range",
            name = "Font Size",
            desc = "Font size for keybind text",
            order = 2.3,
            width = "full",
            min = 8,
            max = 48,
            step = 1,
            get = function()
                return NephUI.db.profile["cooldownManager_keybindFontSize_" .. viewerSettingName] or 14
            end,
            set = function(_, val)
                NephUI.db.profile["cooldownManager_keybindFontSize_" .. viewerSettingName] = val
                if NephUI.Keybinds then
                    NephUI.Keybinds:ApplyKeybindSettings(viewerKey)
                end
            end,
            disabled = function()
                return not (NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] or false)
            end,
        }
        
        -- Keybind Text Color
        ret.args.keybindFontColor = {
            type = "color",
            name = "Text Color",
            desc = "Color for keybind text",
            order = 2.4,
            width = "normal",
            hasAlpha = true,
            get = function()
                local c = NephUI.db.profile["cooldownManager_keybindFontColor_" .. viewerSettingName]
                if not c then
                    c = NephUI.db.profile.cooldownManager_keybindFontColor or {1, 1, 1, 1}
                end
                return c[1], c[2], c[3], c[4] or 1
            end,
            set = function(_, r, g, b, a)
                NephUI.db.profile["cooldownManager_keybindFontColor_" .. viewerSettingName] = {r, g, b, a or 1}
                if NephUI.Keybinds then
                    NephUI.Keybinds:ApplyKeybindSettings(viewerKey)
                end
            end,
            disabled = function()
                return not (NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] or false)
            end,
        }
        
        -- Keybind Anchor Point
        ret.args.keybindAnchor = {
            type = "select",
            name = "Anchor Point",
            desc = "Position anchor for keybind text",
            order = 2.5,
            width = "normal",
            values = {
                TOP = "Top",
                TOPRIGHT = "Top Right",
                TOPLEFT = "Top Left",
                RIGHT = "Right",
                BOTTOMRIGHT = "Bottom Right",
                BOTTOM = "Bottom",
                BOTTOMLEFT = "Bottom Left",
                LEFT = "Left",
                CENTER = "Center",
            },
            get = function()
                return NephUI.db.profile["cooldownManager_keybindAnchor_" .. viewerSettingName] or "TOPRIGHT"
            end,
            set = function(_, val)
                NephUI.db.profile["cooldownManager_keybindAnchor_" .. viewerSettingName] = val
                if NephUI.Keybinds then
                    NephUI.Keybinds:ApplyKeybindSettings(viewerKey)
                end
            end,
            disabled = function()
                return not (NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] or false)
            end,
        }
        
        -- Keybind X Offset
        ret.args.keybindOffsetX = {
            type = "range",
            name = "X Offset",
            desc = "Horizontal offset for keybind text",
            order = 2.6,
            width = "normal",
            min = -40,
            max = 40,
            step = 1,
            get = function()
                return NephUI.db.profile["cooldownManager_keybindOffsetX_" .. viewerSettingName] or -3
            end,
            set = function(_, val)
                NephUI.db.profile["cooldownManager_keybindOffsetX_" .. viewerSettingName] = val
                if NephUI.Keybinds then
                    NephUI.Keybinds:ApplyKeybindSettings(viewerKey)
                end
            end,
            disabled = function()
                return not (NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] or false)
            end,
        }
        
        -- Keybind Y Offset
        ret.args.keybindOffsetY = {
            type = "range",
            name = "Y Offset",
            desc = "Vertical offset for keybind text",
            order = 2.7,
            width = "normal",
            min = -40,
            max = 40,
            step = 1,
            get = function()
                return NephUI.db.profile["cooldownManager_keybindOffsetY_" .. viewerSettingName] or -3
            end,
            set = function(_, val)
                NephUI.db.profile["cooldownManager_keybindOffsetY_" .. viewerSettingName] = val
                if NephUI.Keybinds then
                    NephUI.Keybinds:ApplyKeybindSettings(viewerKey)
                end
            end,
            disabled = function()
                return not (NephUI.db.profile["cooldownManager_showKeybinds_" .. viewerSettingName] or false)
            end,
        }
        
        -- Hide Aura Swipe Toggle
        ret.args.hideAuraSwipe = {
            type = "toggle",
            name = "Hide Aura Swipe",
            desc = "Show the actual spell cooldown instead of the aura/buff duration. When enabled, the icon will display your spell's cooldown even while the buff is active, with desaturation applied.",
            order = 2.8,
            width = "full",
            get = function()
                return NephUI.db.profile.viewers[viewerKey].ignoreAuraOverride or false
            end,
            set = function(_, val)
                if not NephUI.db.profile.viewers[viewerKey] then
                    NephUI.db.profile.viewers[viewerKey] = {}
                end
                NephUI.db.profile.viewers[viewerKey].ignoreAuraOverride = val
                -- Refresh all icons to apply the change
                if NephUI.AuraOverride and NephUI.AuraOverride.RefreshViewer then
                    local viewer = _G[viewerKey]
                    if viewer then
                        NephUI.AuraOverride:RefreshViewer(viewer)
                    end
                end
                if NephUI.RefreshViewers then
                    NephUI:RefreshViewers()
                end
            end,
        }
    end
    
    -- Add button to open config panel for BuffIconCooldownViewer (at the top)
    if viewerKey == "BuffIconCooldownViewer" then
        -- Insert at the top by using order 1.5 (between header and enabled)
        ret.args.previewBuffIcons = {
            type = "execute",
            name = "Preview Buff Icons",
            desc = "Open the full NephUI configuration panel",
            order = 1.5,
            width = "full",
            func = function()
                -- Try to find and open the CooldownViewerSettings frame
                local frame = _G["CooldownViewerSettings"]
                if frame then
                    frame:Show()
                    frame:Raise()
                else
                    -- Fallback: Open the custom GUI and navigate to the Cooldown Manager tab
                    if NephUI and NephUI.OpenConfigGUI then
                        NephUI:OpenConfigGUI(nil, "viewers")
                    end
                end
            end,
        }
    end
    
    return ret
end

-- Export functions
ns.CreateViewerOptions = CreateViewerOptions


