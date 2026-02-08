local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

local ViewerOptions = ns.CreateViewerOptions
local ResourceBarOptions = ns.CreateResourceBarOptions
local CastBarOptions = ns.CreateCastBarOptions
local ChatOptions = ns.CreateChatOptions
local ActionBarOptions = ns.CreateActionBarOptions
local BuffDebuffFramesOptions = ns.CreateBuffDebuffFramesOptions
local MinimapOptions = ns.CreateMinimapOptions
local CustomIconOptions = ns.CreateCustomIconOptions
local CustomBuffOptions = ns.CreateCustomBuffOptions
local IconCustomizationOptions = ns.CreateIconCustomizationOptions
local UnitFrameOptionsGroup = ns.CreateUnitFrameOptionsGroup
local ProfileOptions = ns.CreateProfileOptions
local QOLOptions = ns.CreateQOLOptions

local function GetViewerOptions()
    return {
        ["EssentialCooldownViewer"] = "Essential Cooldowns",
        ["UtilityCooldownViewer"] = "Utility Cooldowns",
        ["BuffIconCooldownViewer"] = "Buff Icons",
        ["BuffBarCooldownViewer"] = "Buff Bar",
    }
end

local AceDBOptions = LibStub("AceDBOptions-3.0", true)

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

-- Scan for available unit frames that can be anchored
local function GetAvailableAnchorFrames()
    local availableFrames = {}
    
    -- Frame name to display name mapping
    local frameDisplayNames = {
        -- Default frames
        PlayerFrame = "Player Frame (Default)",
        TargetFrame = "Target Frame (Default)",
        FocusFrame = "Focus Frame (Default)",
        PetFrame = "Pet Frame (Default)",
        -- Unhalted Unit Frames
        UUF_Player = "Player Frame (UUF)",
        UUF_Target = "Target Frame (UUF)",
        UUF_Focus = "Focus Frame (UUF)",
        UUF_Pet = "Pet Frame (UUF)",
        UUF_TargetTarget = "Target of Target (UUF)",
        -- ElvUI frames
        ElvUF_Player = "Player Frame (ElvUI)",
        ElvUF_Target = "Target Frame (ElvUI)",
        ElvUF_Focus = "Focus Frame (ElvUI)",
        ElvUF_TargetTarget = "Target of Target (ElvUI)",
        ElvUF_Pet = "Pet Frame (ElvUI)",
    }
    
    -- Check each frame to see if it exists
    for frameName, displayName in pairs(frameDisplayNames) do
        local frame = _G[frameName]
        if frame and type(frame) == "table" then
            -- Frame exists and is a valid frame object
            availableFrames[frameName] = displayName
        end
    end
    
    return availableFrames
end

local function CreateBuffBarViewerOptions(order)
    return {
        type = "group",
        name = "Buff Bar",
        order = order,
        args = {
            header = {
                type = "header",
                name = "Buff Bar Cooldowns",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable",
                width = "full",
                order = 2,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.enabled ~= false
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.enabled = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            width = {
                type = "range",
                name = "Bar Width (0 = Auto Size to Essential Viewer)",
                desc = "0 = auto width based on the attached viewer.",
                order = 8,
                width = "normal",
                min = 0, max = 1000, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.width or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.width = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            height = {
                type = "range",
                name = "Bar Height",
                order = 9,
                width = "normal",
                min = 4, max = 100, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.height or 16
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.height = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            texture = {
                type = "select",
                name = "Bar Texture",
                desc = "Texture for buff bars. Blank uses the global texture.",
                order = 9.2,
                width = "full",
                values = function()
                    local hashTable = LSM:HashTable("statusbar")
                    local names = {}
                    for name, _ in pairs(hashTable) do
                        names[name] = name
                    end
                    names[""] = "Use Global"
                    return names
                end,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.texture or ""
                end,
                set = function(_, val)
                    if val == "" then val = nil end
                    NephUI.db.profile.buffBarViewer.texture = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            bgColor = {
                type = "color",
                name = "Bar Background Color",
                order = 9.3,
                width = "full",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local c = cfg.bgColor or { 0.1, 0.1, 0.1, 0.7 }
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    cfg.bgColor = { r, g, b, a or 1 }
                    NephUI.db.profile.buffBarViewer = cfg
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            hideIconMask = {
                type = "toggle",
                name = "Hide Icon Mask",
                desc = "Remove the Blizzard mask from the buff icon attached to the bar.",
                order = 10,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.hideIconMask ~= false
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.hideIconMask = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            hideIcon = {
                type = "toggle",
                name = "Hide Icon",
                desc = "Hide the buff bar icon entirely.",
                order = 10.5,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.hideIcon or false
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.hideIcon = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            iconZoom = {
                type = "range",
                name = "Icon Zoom",
                desc = "Crops the buff bar icon edges (higher = more zoom).",
                order = 11,
                width = "normal",
                min = 0, max = 0.2, step = 0.01,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.iconZoom or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.iconZoom = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            iconBorderSize = {
                type = "range",
                name = "Icon Border",
                desc = "Border thickness around the buff bar icon (0 = none).",
                order = 12,
                width = "normal",
                min = 0, max = 5, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.iconBorderSize or 1
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.iconBorderSize = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            iconBorderColor = {
                type = "color",
                name = "Icon Border Color",
                order = 12.1,
                width = "normal",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local c = cfg.iconBorderColor or {0, 0, 0, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    cfg.iconBorderColor = { r, g, b, a or 1 }
                    NephUI.db.profile.buffBarViewer = cfg
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            nameHeader = {
                type = "header",
                name = "Name Text",
                order = 20,
            },
            showName = {
                type = "toggle",
                name = "Show Name",
                order = 21,
                width = "normal",
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.showName ~= false
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.showName = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            nameSize = {
                type = "range",
                name = "Name Size",
                order = 22,
                width = "normal",
                min = 6, max = 32, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.nameSize or 14
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.nameSize = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            nameColor = {
                type = "color",
                name = "Name Color",
                order = 23,
                width = "normal",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local c = cfg.nameColor or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    cfg.nameColor = { r, g, b, a or 1 }
                    NephUI.db.profile.buffBarViewer = cfg
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            nameAnchor = {
                type = "select",
                name = "Name Anchor",
                order = 23.1,
                width = "normal",
                values = GetChargeAnchorOptions(),
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local anchor = cfg.nameAnchor or "LEFT"
                    return anchor == "MIDDLE" and "CENTER" or anchor
                end,
                set = function(_, val)
                    if val == "MIDDLE" then val = "CENTER" end
                    NephUI.db.profile.buffBarViewer.nameAnchor = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            nameOffsetX = {
                type = "range",
                name = "Name Offset X",
                order = 23.2,
                width = "normal",
                min = -100, max = 100, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.nameOffsetX or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.nameOffsetX = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            nameOffsetY = {
                type = "range",
                name = "Name Offset Y",
                order = 23.3,
                width = "normal",
                min = -100, max = 100, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.nameOffsetY or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.nameOffsetY = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            durationHeader = {
                type = "header",
                name = "Duration Text",
                order = 30,
            },
            showDuration = {
                type = "toggle",
                name = "Show Duration",
                order = 31,
                width = "normal",
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.showDuration ~= false
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.showDuration = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            durationSize = {
                type = "range",
                name = "Duration Size",
                order = 32,
                width = "normal",
                min = 6, max = 32, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.durationSize or 12
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.durationSize = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            durationColor = {
                type = "color",
                name = "Duration Color",
                order = 33,
                width = "normal",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local c = cfg.durationColor or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    cfg.durationColor = { r, g, b, a or 1 }
                    NephUI.db.profile.buffBarViewer = cfg
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            durationAnchor = {
                type = "select",
                name = "Duration Anchor",
                order = 33.1,
                width = "normal",
                values = GetChargeAnchorOptions(),
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local anchor = cfg.durationAnchor or "RIGHT"
                    return anchor == "MIDDLE" and "CENTER" or anchor
                end,
                set = function(_, val)
                    if val == "MIDDLE" then val = "CENTER" end
                    NephUI.db.profile.buffBarViewer.durationAnchor = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            durationOffsetX = {
                type = "range",
                name = "Duration Offset X",
                order = 33.2,
                width = "normal",
                min = -100, max = 100, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.durationOffsetX or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.durationOffsetX = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            durationOffsetY = {
                type = "range",
                name = "Duration Offset Y",
                order = 33.3,
                width = "normal",
                min = -100, max = 100, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.durationOffsetY or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.durationOffsetY = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            applicationsHeader = {
                type = "header",
                name = "Applications Text",
                order = 40,
            },
            showApplications = {
                type = "toggle",
                name = "Show Applications",
                order = 40.5,
                width = "normal",
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.showApplications ~= false
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.showApplications = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            applicationsSize = {
                type = "range",
                name = "Applications Size",
                order = 41,
                width = "normal",
                min = 6, max = 32, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.applicationsSize or 12
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.applicationsSize = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            applicationsColor = {
                type = "color",
                name = "Applications Color",
                order = 42,
                width = "normal",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local c = cfg.applicationsColor or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    cfg.applicationsColor = { r, g, b, a or 1 }
                    NephUI.db.profile.buffBarViewer = cfg
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            applicationsAnchor = {
                type = "select",
                name = "Applications Anchor",
                order = 43,
                width = "normal",
                values = GetChargeAnchorOptions(),
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    local anchor = cfg.applicationsAnchor or "BOTTOMRIGHT"
                    return anchor == "MIDDLE" and "CENTER" or anchor
                end,
                set = function(_, val)
                    if val == "MIDDLE" then val = "CENTER" end
                    NephUI.db.profile.buffBarViewer.applicationsAnchor = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            applicationsOffsetX = {
                type = "range",
                name = "Applications Offset X",
                order = 44,
                width = "normal",
                min = -50, max = 50, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.applicationsOffsetX or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.applicationsOffsetX = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            applicationsOffsetY = {
                type = "range",
                name = "Applications Offset Y",
                order = 45,
                width = "normal",
                min = -50, max = 50, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.applicationsOffsetY or 0
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.applicationsOffsetY = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
            layoutHeader = {
                type = "header",
                name = "Layout",
                order = 50,
            },
            barSpacing = {
                type = "range",
                name = "Bar Spacing",
                desc = "Space between bars when stacked.",
                order = 52,
                width = "normal",
                min = 0, max = 20, step = 1,
                get = function()
                    local cfg = NephUI.db.profile.buffBarViewer or {}
                    return cfg.barSpacing or 2
                end,
                set = function(_, val)
                    NephUI.db.profile.buffBarViewer.barSpacing = val
                    if NephUI.RefreshViewers then
                        NephUI:RefreshViewers()
                    end
                end,
            },
        },
    }
end

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
                desc = "Show/hide this Cooldown Manager",
                width = "full",
                order = 2,
                get = function() return NephUI.db.profile.viewers[viewerKey].enabled end,
                set = function(_, val)
                    NephUI.db.profile.viewers[viewerKey].enabled = val
                    NephUI:RefreshAll()
                end,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 3,
            },
            
            -- ICON LAYOUT GROUP
            layoutGroup = {
                type = "group",
                name = "Icon Layout",
                inline = true,
                order = 10,
                args = {
                    iconSize = {
                        type = "range",
                        name = "Icon Size",
                        desc = "Base size of each icon in pixels (longest dimension)",
                        order = 1,
                        width = "full",
                        min = 16, max = 96, step = 1,
                        get = function() return NephUI.db.profile.viewers[viewerKey].iconSize end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].iconSize = val
                            NephUI:RefreshAll()
                        end,
                    },
                    aspectRatio = {
                        type = "range",
                        name = "Aspect Ratio (Width:Height)",
                        desc = "Control the icon aspect ratio. 1.0 = square, >1.0 = wider, <1.0 = taller. Examples: 1.0=1:1, 1.78=16:9, 0.56=9:16",
                        order = 2,
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
                            local rounded = math.floor(val * 100 + 0.5) / 100
                            profile.aspectRatio = string.format("%.2f:1", rounded)
                            NephUI:RefreshAll()
                        end,
                    },
                    spacing = {
                        type = "range",
                        name = "Spacing",
                        desc = "Space between icons (negative = overlap)",
                        order = 4,
                        width = "full",
                        min = -20, max = 20, step = 1,
                        get = function() return NephUI.db.profile.viewers[viewerKey].spacing end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].spacing = val
                            NephUI:RefreshAll()
                        end,
                    },
                    zoom = {
                        type = "range",
                        name = "Icon Zoom",
                        desc = "Crops the edges of icons (higher = more zoom)",
                        order = 5,
                        width = "full",
                        min = 0, max = 0.2, step = 0.01,
                        get = function() return NephUI.db.profile.viewers[viewerKey].zoom end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].zoom = val
                            NephUI:RefreshAll()
                        end,
                    },
                    rowLimit = {
                        type = "range",
                        name = "Icons Per Row",
                        desc = "Maximum icons per row (0 = unlimited, single row). When exceeded, creates new rows that grow from the center.",
                        order = 6,
                        width = "full",
                        min = 0, max = 20, step = 1,
                        get = function() return NephUI.db.profile.viewers[viewerKey].rowLimit or 0 end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].rowLimit = val
                            NephUI:RefreshAll()
                        end,
                    },
                    rowGrowDirection = {
                        type = "select",
                        name = "Row Growth Direction",
                        desc = "Direction that rows grow when Icons Per Row is exceeded (only applies to BuffIconCooldownViewer)",
                        order = 7,
                        width = "full",
                        values = {
                            ["up"] = "Up",
                            ["down"] = "Down",
                        },
                        get = function()
                            return NephUI.db.profile.viewers[viewerKey].rowGrowDirection or "down"
                        end,
                        set = function(_, val)
                            if viewerKey == "BuffIconCooldownViewer" then
                                NephUI.db.profile.viewers[viewerKey].rowGrowDirection = val
                                NephUI:RefreshAll()
                            end
                        end,
                    },
                },
            },
            
            -- BORDER GROUP
            borderGroup = {
                type = "group",
                name = "Borders",
                inline = true,
                order = 20,
                args = {
                    borderSize = {
                        type = "range",
                        name = "Border Size",
                        desc = "Border thickness (0 = no border)",
                        order = 1,
                        width = "full",
                        min = 0, max = 5, step = 1,
                        get = function() return NephUI.db.profile.viewers[viewerKey].borderSize end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].borderSize = val
                            NephUI:RefreshAll()
                        end,
                    },
                },
            },
            
            -- TEXT GROUP
            textGroup = {
                type = "group",
                name = "Charge / Stack Text",
                inline = true,
                order = 30,
                args = {
                    countTextSize = {
                        type = "range",
                        name = "Text Size",
                        desc = "Font size for charge/stack numbers",
                        order = 1,
                        width = "full",
                        min = 6, max = 32, step = 1,
                        get = function() return NephUI.db.profile.viewers[viewerKey].countTextSize or 16 end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].countTextSize = val
                            NephUI:RefreshAll()
                        end,
                    },
                    chargeTextAnchor = {
                        type = "select",
                        name = "Text Position",
                        desc = "Where to anchor the charge/stack text",
                        order = 2,
                        width = "full",
                        values = GetChargeAnchorOptions(),
                        get = function()
                            return NephUI.db.profile.viewers[viewerKey].chargeTextAnchor or "BOTTOMRIGHT"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].chargeTextAnchor = val
                            NephUI:RefreshAll()
                        end,
                    },
                    countTextOffsetX = {
                        type = "range",
                        name = "Horizontal Offset",
                        desc = "Fine-tune text position horizontally",
                        order = 3,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function()
                            return NephUI.db.profile.viewers[viewerKey].countTextOffsetX or 0
                        end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].countTextOffsetX = val
                            NephUI:RefreshAll()
                        end,
                    },
                    countTextOffsetY = {
                        type = "range",
                        name = "Vertical Offset",
                        desc = "Fine-tune text position vertically",
                        order = 4,
                        width = "normal",
                        min = -50, max = 50, step = 1,
                        get = function()
                            return NephUI.db.profile.viewers[viewerKey].countTextOffsetY or 0
                        end,
                        set = function(_, val)
                            NephUI.db.profile.viewers[viewerKey].countTextOffsetY = val
                            NephUI:RefreshAll()
                        end,
                    },
                },
            },
        },
    }
    
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
                -- Open the custom GUI instead
                if NephUI and NephUI.OpenConfigGUI then
                    NephUI:OpenConfigGUI()
                end
            end,
        }
    end
    
    return ViewerOptions(viewerKey, displayName, order)
end

function NephUI:SetupOptions()
    local AceConfig = LibStub("AceConfig-3.0")
    local LibDualSpec = LibStub("LibDualSpec-1.0", true)

    local profileOptions
    if AceDBOptions and self.db then
        -- Verify the database is properly initialized and isolated
        if not self.db.sv or not self.db.keys then
            error("NephUI: Database not properly initialized! Cannot create profile options.")
        end
        
        -- Get the profile options table for our specific database
        -- CRITICAL: profileOptions.args is a SHARED table (optionsTable) used by ALL addons
        -- We must NEVER modify profileOptions.args directly - only work with a deep copy
        profileOptions = AceDBOptions:GetOptionsTable(self.db)
        
        -- Verify the handler is bound to our database
        if profileOptions and profileOptions.handler then
            if profileOptions.handler.db ~= self.db then
                error("NephUI: Profile options handler is not bound to the correct database!")
            end
        end
        
        -- CRITICAL: Do NOT call LibDualSpec:EnhanceOptions on profileOptions here
        -- because it might modify the shared profileOptions.args table.
        -- We'll handle LibDualSpec after we've created our isolated copy.
    end

    local options = {
        type = "group",
        name = "NephUI",
        args = {
            -- GENERAL TAB
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    -- General Settings Header
                    generalHeader = {
                        type = "header",
                        name = "General Settings",
                        order = 1,
                    },
                    
                    -- Global Texture
                    globalTexture = {
                        type = "select",
                        name = "Global Texture",
                        desc = "Texture used globally across all UI elements",
                        order = 10,
                        width = "full",
                        values = function()
                            local hashTable = LSM:HashTable("statusbar")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function()
                            return NephUI.db.profile.general.globalTexture or "Neph"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.general.globalTexture = val
                            if NephUI.RefreshAll then
                                NephUI:RefreshAll()
                            end
                        end,
                    },
                    
                    spacer1 = {
                        type = "description",
                        name = " ",
                        order = 19,
                    },
                    
                    -- Apply Global Font to Blizzard UI
                    applyGlobalFontToBlizzard = {
                        type = "toggle",
                        name = "Apply Global Font to Blizzard UI",
                        desc = "When enabled, the global font will also change Blizzard's default UI fonts (tooltips, quest tracker, chat, etc.). When disabled, only NephUI elements will use the global font.",
                        order = 19.5,
                        width = "full",
                        get = function()
                            return NephUI.db.profile.general.applyGlobalFontToBlizzard or false
                        end,
                        set = function(_, val)
                            NephUI.db.profile.general.applyGlobalFontToBlizzard = val
                            -- Reset hook flags so hooks can be recreated if needed
                            if NephUI._questFontHooked then
                                NephUI._questFontHooked = nil
                            end
                            if NephUI._tooltipFontHooked then
                                NephUI._tooltipFontHooked = nil
                            end
                            if NephUI._chatFontHooked then
                                NephUI._chatFontHooked = nil
                            end
                            if NephUI.ApplyGlobalFont then
                                NephUI:ApplyGlobalFont()
                            end
                        end,
                    },
                    
                    -- Global Font
                    globalFont = {
                        type = "select",
                        name = "Global Font",
                        desc = "Font used globally across all NephUI elements (viewers, auras, cast bars, etc.). Use the toggle above to also apply to Blizzard's UI.",
                        order = 20,
                        width = "full",
                        values = function()
                            local hashTable = LSM:HashTable("font")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function()
                            return NephUI.db.profile.general.globalFont or "Expressway"
                        end,
                        set = function(_, val)
                            NephUI.db.profile.general.globalFont = val
                            if NephUI.ApplyGlobalFont then
                                NephUI:ApplyGlobalFont()
                            end
                            if NephUI.RefreshAll then
                                NephUI:RefreshAll()
                            end
                        end,
                    },
                    
                    spacer2 = {
                        type = "description",
                        name = " ",
                        order = 29,
                    },
                    
                    -- UI Scale Header
                    uiScaleHeader = {
                        type = "header",
                        name = "UI Scale Settings",
                        order = 30,
                    },
                    
                    spacer3 = {
                        type = "description",
                        name = " ",
                        order = 41,
                    },
                    
                    -- UI Scale Input
                    uiScale = {
                        type = "input",
                        name = "UI Scale",
                        desc = "Enter a UI scale value (0.33 to 1.0)",
                        order = 50,
                        width = "full",
                        get = function()
                            -- If we have a saved value, show that (user has manually set it)
                            local savedScale = NephUI.db.profile.general.uiScale
                            if savedScale and type(savedScale) == "number" then
                                return string.format("%.8f", savedScale)
                            end
                            
                            -- Otherwise, read current scale from CVar (don't save it)
                            local cvarValue = GetCVar("uiscale")
                            if cvarValue then
                                local scale = tonumber(cvarValue)
                                if scale then
                                    return string.format("%.8f", scale)
                                end
                            end
                            
                            -- Fallback: get from UIParent if CVar not available
                            local currentScale = UIParent:GetScale()
                            if currentScale then
                                return string.format("%.8f", currentScale)
                            end
                            
                            -- Last resort: default to 1.0 (but don't save it)
                            return "1.00000000"
                        end,
                        set = function(_, val)
                            -- Store the value temporarily (don't apply yet)
                            -- This allows the confirm button to read what the user typed
                            local numValue = tonumber(val)
                            if numValue then
                                -- Clamp to valid range (0.33 to 1.0)
                                numValue = math.max(0.33, math.min(1.0, numValue))
                                NephUI.db.profile.general.uiScale = numValue
                                -- Note: We don't apply it here - only when Confirm is clicked
                            end
                        end,
                    },
                    
                    -- Confirm UI Scale Button
                    confirmUIScale = {
                        type = "execute",
                        name = "Confirm UI Scale",
                        desc = "Apply the UI scale value from the input box above",
                        order = 51,
                        width = "full",
                        func = function()
                            -- Get the value from the database (which is updated as user types)
                            local savedScale = NephUI.db.profile.general.uiScale
                            
                            -- If no saved value, read current CVar value
                            if not savedScale or type(savedScale) ~= "number" then
                                local cvarValue = GetCVar("uiscale")
                                if cvarValue then
                                    savedScale = tonumber(cvarValue)
                                end
                            end
                            
                            if savedScale and type(savedScale) == "number" then
                                -- Clamp to valid range
                                savedScale = math.max(0.33, math.min(1.0, savedScale))
                                -- Save the value (this is the user's choice, so we save it)
                                NephUI.db.profile.general.uiScale = savedScale
                                -- Apply the scale
                                if NephUI.AutoUIScale and NephUI.AutoUIScale.SetUIScale then
                                    NephUI.AutoUIScale:SetUIScale(savedScale)
                                    print("|cff00ff00[NephUI] UI Scale set to " .. string.format("%.8f", savedScale) .. "|r")
                                end
                                -- Refresh config to update the input field
                                local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                if AceConfigRegistry then
                                    AceConfigRegistry:NotifyChange(ADDON_NAME)
                                end
                                -- Refresh custom GUI if open
                                local configFrame = _G["NephUI_ConfigFrame"]
                                if configFrame and configFrame:IsShown() and configFrame.FullRefresh then
                                    configFrame:FullRefresh()
                                end
                            else
                                print("|cffff0000[NephUI] Invalid UI scale value. Please enter a number between 0.33 and 1.0|r")
                            end
                        end,
                    },
                    
                    spacer4 = {
                        type = "description",
                        name = " ",
                        order = 52,
                    },
                    
                    -- Preset Buttons
                    preset1080p = {
                        type = "execute",
                        name = "Set for 1080p (0.711111)",
                        desc = "Automatically set UI scale to 0.711111 for 1080p displays",
                        order = 60,
                        width = "full",
                        func = function()
                            local scale1080p = 0.711111
                            NephUI.db.profile.general.uiScale = scale1080p
                            -- Apply the scale
                            if NephUI.AutoUIScale and NephUI.AutoUIScale.SetUIScale then
                                NephUI.AutoUIScale:SetUIScale(scale1080p)
                                print("|cff00ff00[NephUI] UI Scale set to 0.711111 for 1080p|r")
                            end
                            -- Refresh config to update the input field
                            local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                            if AceConfigRegistry then
                                AceConfigRegistry:NotifyChange(ADDON_NAME)
                            end
                            -- Refresh custom GUI if open
                            local configFrame = _G["NephUI_ConfigFrame"]
                            if configFrame and configFrame:IsShown() and configFrame.FullRefresh then
                                configFrame:FullRefresh()
                            end
                        end,
                    },
                    
                    preset1440p = {
                        type = "execute",
                        name = "Set for 1440p (0.53333333)",
                        desc = "Automatically set UI scale to 0.53333333 for 1440p displays",
                        order = 61,
                        width = "full",
                        func = function()
                            local scale1440p = 0.53333333
                            NephUI.db.profile.general.uiScale = scale1440p
                            -- Apply the scale
                            if NephUI.AutoUIScale and NephUI.AutoUIScale.SetUIScale then
                                NephUI.AutoUIScale:SetUIScale(scale1440p)
                                print("|cff00ff00[NephUI] UI Scale set to 0.53333333 for 1440p|r")
                            end
                            -- Refresh config to update the input field
                            local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                            if AceConfigRegistry then
                                AceConfigRegistry:NotifyChange(ADDON_NAME)
                            end
                            -- Refresh custom GUI if open
                            local configFrame = _G["NephUI_ConfigFrame"]
                            if configFrame and configFrame:IsShown() and configFrame.FullRefresh then
                                configFrame:FullRefresh()
                            end
                        end,
                    },
                },
            },
            
            -- Cooldown Manager TAB
            viewers = {
                type = "group",
                name = "Cooldown Manager",
                order = 5,
                childGroups = "tab",
                args = {
                    general = {
                        type = "group",
                        name = "General",
                        order = 0,
                        args = {
                            header = {
                                type = "header",
                                name = "Cooldown Manager Settings",
                                order = 1,
                            },
                            -- Anchor to Unit Frame Section
                            anchorHeader = {
                                type = "header",
                                name = "Unit Frame Anchoring",
                                order = 5,
                            },
                            anchorToUnitFrame = {
                                type = "toggle",
                                name = "Anchor Unit Frames to Viewer (Used for non NephUI Unit Frames)",
                                desc = "Automatically anchor Player/Target/Focus/Pet frames to Essential Cooldown Viewer. Supports default frames, Unhalted Unit Frames (UUF), and ElvUI frames.",
                                width = "full",
                                order = 6,
                                get = function()
                                    return NephUI.db.profile.viewers.general.anchorToUnitFrame or false
                                end,
                                set = function(_, val)
                                    NephUI.db.profile.viewers.general.anchorToUnitFrame = val
                                    -- Clear watcher flag so it can be set up again if needed
                                    if NephUI.__nephuiViewerWatcher then
                                        NephUI.__nephuiViewerWatcher = nil
                                    end
                                    if NephUI.UpdateViewerUnitFrameAnchor then
                                        -- Delay to allow frames to spawn
                                        C_Timer.After(0.5, function()
                                            NephUI:UpdateViewerUnitFrameAnchor()
                                        end)
                                    end
                                    -- Refresh GUI to show/hide anchor position options
                                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                                    if AceConfigRegistry then
                                        AceConfigRegistry:NotifyChange(ADDON_NAME)
                                    end
                                    -- Refresh custom GUI if open
                                    local configFrame = _G["NephUI_ConfigFrame"]
                                    if configFrame and configFrame:IsShown() and configFrame.FullRefresh then
                                        configFrame:FullRefresh()
                                    end
                                end,
                            },
                            anchorSpacer = {
                                type = "description",
                                name = " ",
                                order = 7,
                            },
                            -- Frame Selection Dropdown
                            selectedAnchorFrame = {
                                type = "select",
                                name = "Select Frame to Adjust",
                                desc = "Choose which unit frame to adjust the position for",
                                order = 8,
                                width = "full",
                                disabled = function()
                                    return not (NephUI.db.profile.viewers.general.anchorToUnitFrame or false)
                                end,
                                values = function()
                                    -- Scan for available unit frames that are currently loaded
                                    return GetAvailableAnchorFrames()
                                end,
                                get = function()
                                    local cfg = NephUI.db.profile.viewers.general
                                    if not cfg.anchorPositions then
                                        cfg.anchorPositions = {}
                                    end
                                    local selectedFrame = cfg.anchorPositions.selectedFrame or "PlayerFrame"
                                    -- Verify the selected frame still exists, fallback to first available if not
                                    local availableFrames = GetAvailableAnchorFrames()
                                    if not availableFrames[selectedFrame] then
                                        -- Find first available frame (prefer PlayerFrame if available)
                                        if availableFrames.PlayerFrame then
                                            selectedFrame = "PlayerFrame"
                                        else
                                            -- Get first available frame
                                            for frameName, _ in pairs(availableFrames) do
                                                selectedFrame = frameName
                                                break
                                            end
                                        end
                                        cfg.anchorPositions.selectedFrame = selectedFrame
                                    end
                                    return selectedFrame
                                end,
                                set = function(_, val)
                                    local cfg = NephUI.db.profile.viewers.general
                                    if not cfg.anchorPositions then
                                        cfg.anchorPositions = {}
                                    end
                                    cfg.anchorPositions.selectedFrame = val
                                end,
                            },
                            anchorOffsetX = {
                                type = "range",
                                name = "Horizontal Offset (X)",
                                desc = "Adjust the horizontal position offset for the selected frame",
                                order = 9,
                                width = "full",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                disabled = function()
                                    return not (NephUI.db.profile.viewers.general.anchorToUnitFrame or false)
                                end,
                                get = function()
                                    local cfg = NephUI.db.profile.viewers.general
                                    if not cfg.anchorPositions then
                                        cfg.anchorPositions = {}
                                    end
                                    local selectedFrame = cfg.anchorPositions.selectedFrame or "PlayerFrame"
                                    if not cfg.anchorPositions[selectedFrame] then
                                        cfg.anchorPositions[selectedFrame] = {}
                                    end
                                    -- Get default offset from hard-coded config if not set
                                    local defaultOffsets = {
                                        PlayerFrame = -20,
                                        TargetFrame = 20,
                                        FocusFrame = 0,
                                        PetFrame = 0,
                                        UUF_Player = -20,
                                        UUF_Target = 20,
                                        UUF_Focus = 0,
                                        UUF_Pet = 0,
                                        UUF_TargetTarget = 0,
                                        ElvUF_Player = -20,
                                        ElvUF_Target = 20,
                                        ElvUF_Focus = 0,
                                        ElvUF_TargetTarget = 0,
                                        ElvUF_Pet = 0,
                                    }
                                    return cfg.anchorPositions[selectedFrame].offsetX or defaultOffsets[selectedFrame] or 0
                                end,
                                set = function(_, val)
                                    local cfg = NephUI.db.profile.viewers.general
                                    if not cfg.anchorPositions then
                                        cfg.anchorPositions = {}
                                    end
                                    local selectedFrame = cfg.anchorPositions.selectedFrame or "PlayerFrame"
                                    if not cfg.anchorPositions[selectedFrame] then
                                        cfg.anchorPositions[selectedFrame] = {}
                                    end
                                    cfg.anchorPositions[selectedFrame].offsetX = val
                                    -- Apply the change immediately
                                    if NephUI.UpdateViewerUnitFrameAnchor then
                                        C_Timer.After(0.1, function()
                                            NephUI:UpdateViewerUnitFrameAnchor()
                                        end)
                                    end
                                end,
                            },
                            anchorOffsetY = {
                                type = "range",
                                name = "Vertical Offset (Y)",
                                desc = "Adjust the vertical position offset for the selected frame",
                                order = 10,
                                width = "full",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                disabled = function()
                                    return not (NephUI.db.profile.viewers.general.anchorToUnitFrame or false)
                                end,
                                get = function()
                                    local cfg = NephUI.db.profile.viewers.general
                                    if not cfg.anchorPositions then
                                        cfg.anchorPositions = {}
                                    end
                                    local selectedFrame = cfg.anchorPositions.selectedFrame or "PlayerFrame"
                                    if not cfg.anchorPositions[selectedFrame] then
                                        cfg.anchorPositions[selectedFrame] = {}
                                    end
                                    -- Default Y offset is 0 for all frames
                                    return cfg.anchorPositions[selectedFrame].offsetY or 0
                                end,
                                set = function(_, val)
                                    local cfg = NephUI.db.profile.viewers.general
                                    if not cfg.anchorPositions then
                                        cfg.anchorPositions = {}
                                    end
                                    local selectedFrame = cfg.anchorPositions.selectedFrame or "PlayerFrame"
                                    if not cfg.anchorPositions[selectedFrame] then
                                        cfg.anchorPositions[selectedFrame] = {}
                                    end
                                    cfg.anchorPositions[selectedFrame].offsetY = val
                                    -- Apply the change immediately
                                    if NephUI.UpdateViewerUnitFrameAnchor then
                                        C_Timer.After(0.1, function()
                                            NephUI:UpdateViewerUnitFrameAnchor()
                                        end)
                                    end
                                end,
                            },
                            anchorPositionSpacer = {
                                type = "description",
                                name = " ",
                                order = 10.5,
                            },
                            -- Proc Glow Section
                            procGlowHeader = {
                                type = "header",
                                name = "Proc Glow Customization",
                                order = 10,
                            },
                            procGlowEnabled = {
                                type = "toggle",
                                name = "Enable Proc Glow Customization",
                                desc = "Customize the spell activation overlay and proc glow effects using LibCustomGlow",
                                width = "full",
                                order = 11,
                                get = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    return procGlow and procGlow.enabled or false
                                end,
                                set = function(_, val)
                                    if not NephUI.db.profile.viewers.general.procGlow then
                                        NephUI.db.profile.viewers.general.procGlow = {}
                                    end
                                    NephUI.db.profile.viewers.general.procGlow.enabled = val
                                    if NephUI.ProcGlow and NephUI.ProcGlow.RefreshAll then
                                        NephUI.ProcGlow:RefreshAll()
                                    end
                                end,
                            },
                            procGlowSpacer1 = {
                                type = "description",
                                name = " ",
                                order = 12,
                            },
                            -- Glow Type
                            glowType = {
                                type = "select",
                                name = "Glow Type",
                                desc = "Choose the type of glow effect",
                                order = 20,
                                width = "full",
                                values = function()
                                    local result = {}
                                    if NephUI.ProcGlow and NephUI.ProcGlow.LibCustomGlowTypes then
                                        for _, glowType in ipairs(NephUI.ProcGlow.LibCustomGlowTypes) do
                                            result[glowType] = glowType
                                        end
                                    end
                                    return result
                                end,
                                get = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    return (procGlow and procGlow.glowType) or "Pixel Glow"
                                end,
                                set = function(_, val)
                                    if not NephUI.db.profile.viewers.general.procGlow then
                                        NephUI.db.profile.viewers.general.procGlow = {}
                                    end
                                    NephUI.db.profile.viewers.general.procGlow.glowType = val
                                    if NephUI.ProcGlow and NephUI.ProcGlow.RefreshAll then
                                        NephUI.ProcGlow:RefreshAll()
                                    end
                                end,
                            },
                            loopColor = {
                                type = "color",
                                name = "Glow Color",
                                desc = "Color for the glow effect",
                                order = 21,
                                width = "normal",
                                hasAlpha = true,
                                get = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    local color = (procGlow and procGlow.loopColor) or {0.95, 0.95, 0.32, 1}
                                    return color[1], color[2], color[3], color[4] or 1
                                end,
                                set = function(_, r, g, b, a)
                                    if not NephUI.db.profile.viewers.general.procGlow then
                                        NephUI.db.profile.viewers.general.procGlow = {}
                                    end
                                    NephUI.db.profile.viewers.general.procGlow.loopColor = {r, g, b, a or 1}
                                    if NephUI.ProcGlow and NephUI.ProcGlow.RefreshAll then
                                        NephUI.ProcGlow:RefreshAll()
                                    end
                                end,
                            },
                            procGlowSpacer2 = {
                                type = "description",
                                name = " ",
                                order = 22,
                            },
                            -- Custom Glow Options
                            lcgHeader = {
                                type = "header",
                                name = "Custom Glow Options",
                                order = 30,
                            },
                            lcgLines = {
                                type = "range",
                                name = "Lines",
                                desc = "Number of lines for Pixel Glow and Autocast Shine",
                                order = 31,
                                width = "normal",
                                min = 1,
                                max = 30,
                                step = 1,
                                disabled = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    return not (procGlow and procGlow.glowType and procGlow.glowType ~= "Action Button Glow" and procGlow.glowType ~= "Proc Glow")
                                end,
                                get = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    return procGlow and procGlow.lcgLines or 14
                                end,
                                set = function(_, val)
                                    if not NephUI.db.profile.viewers.general.procGlow then
                                        NephUI.db.profile.viewers.general.procGlow = {}
                                    end
                                    NephUI.db.profile.viewers.general.procGlow.lcgLines = val
                                    if NephUI.ProcGlow and NephUI.ProcGlow.RefreshAll then
                                        NephUI.ProcGlow:RefreshAll()
                                    end
                                end,
                            },
                            lcgFrequency = {
                                type = "range",
                                name = "Frequency",
                                desc = "Animation frequency/speed",
                                order = 32,
                                width = "normal",
                                min = 0.1,
                                max = 2.0,
                                step = 0.05,
                                get = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    return procGlow and procGlow.lcgFrequency or 0.25
                                end,
                                set = function(_, val)
                                    if not NephUI.db.profile.viewers.general.procGlow then
                                        NephUI.db.profile.viewers.general.procGlow = {}
                                    end
                                    NephUI.db.profile.viewers.general.procGlow.lcgFrequency = val
                                    if NephUI.ProcGlow and NephUI.ProcGlow.RefreshAll then
                                        NephUI.ProcGlow:RefreshAll()
                                    end
                                end,
                            },
                            lcgThickness = {
                                type = "range",
                                name = "Thickness",
                                desc = "Line thickness for Pixel Glow",
                                order = 33,
                                width = "normal",
                                min = 1,
                                max = 10,
                                step = 1,
                                disabled = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    return not (procGlow and procGlow.glowType == "Pixel Glow")
                                end,
                                get = function()
                                    local procGlow = NephUI.db.profile.viewers.general.procGlow
                                    return procGlow and procGlow.lcgThickness or 2
                                end,
                                set = function(_, val)
                                    if not NephUI.db.profile.viewers.general.procGlow then
                                        NephUI.db.profile.viewers.general.procGlow = {}
                                    end
                                    NephUI.db.profile.viewers.general.procGlow.lcgThickness = val
                                    if NephUI.ProcGlow and NephUI.ProcGlow.RefreshAll then
                                        NephUI.ProcGlow:RefreshAll()
                                    end
                                end,
                            },
                        },
                    },
                    essential = CreateViewerOptions("EssentialCooldownViewer", "Essential", 1),
                    utility = CreateViewerOptions("UtilityCooldownViewer", "Utility", 2),
                    buff = CreateViewerOptions("BuffIconCooldownViewer", "Buffs", 3),
                    buffBar = CreateBuffBarViewerOptions(4),
                    iconCustomization = IconCustomizationOptions(),
                },
            },

            -- CHAT TAB
            chat = ChatOptions(),

            -- MINIMAP TAB
            minimap = MinimapOptions(),
            
            -- ACTION BARS TAB
            actionBars = ActionBarOptions(),
            
            -- BUFF/DEBUFF FRAMES TAB
            buffDebuffFrames = BuffDebuffFramesOptions(),
            
            -- RESOURCE BARS TAB
            resourceBars = ResourceBarOptions(),
            
            -- CAST BARS TAB
            castBars = CastBarOptions(),

            -- UNIT FRAMES TAB
            unitFrames = UnitFrameOptionsGroup(),
            
            -- CUSTOM ICONS TAB
            customIcons = CustomIconOptions(),

            -- CUSTOM BUFFS TAB
            customBuffs = CustomBuffOptions(),
            
            -- QOL TAB
            qol = QOLOptions(),

            -- IMPORT / EXPORT TAB
            importExport = ProfileOptions(),
        },
    }
    
    if profileOptions then
        -- AceDBOptions reuses a shared args table across addons; clone what we mutate.
        -- We need to do a deep copy to ensure complete isolation from other addons.
        -- Functions are preserved (not copied) to maintain handler references.
        local function DeepCopyTable(source, seen)
            seen = seen or {}
            if type(source) ~= "table" then
                return source
            end
            if seen[source] then
                return seen[source] -- Avoid circular references
            end
            local copy = {}
            seen[source] = copy
            for k, v in pairs(source) do
                local vtype = type(v)
                if vtype == "table" then
                    copy[k] = DeepCopyTable(v, seen)
                elseif vtype == "function" then
                    -- Preserve functions (they contain handler references)
                    copy[k] = v
                else
                    copy[k] = v
                end
            end
            return copy
        end

        -- Copy all properties from profileOptions first
        options.args.profiles = {}
        for k, v in pairs(profileOptions) do
            if k ~= "args" then -- We'll handle args separately with deep copy
                options.args.profiles[k] = v
            end
        end

        -- CRITICAL: Deep copy the args table FIRST, before ANY modifications
        -- This ensures we never touch the shared optionsTable that other addons use
        -- Functions are preserved to maintain proper handler binding
        local profileArgs = DeepCopyTable(profileOptions.args or {})
        options.args.profiles.args = profileArgs
        
        -- CRITICAL: Ensure the handler is correctly set to our database
        -- The handler contains the database reference and must be unique per addon
        options.args.profiles.handler = profileOptions.handler
        
        -- Verify the handler is bound to our database
        if options.args.profiles.handler and options.args.profiles.handler.db ~= self.db then
            error("NephUI: Profile options handler is not bound to the correct database! This will cause profile conflicts with other addons.")
        end
        
        -- Store a reference to our database for use in closures
        -- This ensures all profile operations use NephUI's database and never affect other addons
        local nephDB = self.db
        
        -- Override name and order
        options.args.profiles.name = "Profiles"
        options.args.profiles.order = 12
        
        -- NOW we can safely enhance with LibDualSpec on the original profileOptions
        -- Since we've already copied profileOptions.args, any modifications to the original
        -- won't affect our isolated copy. LibDualSpec only modifies profileOptions.plugins anyway.
        if LibDualSpec then
            -- Enhance the original profileOptions (this modifies profileOptions.plugins, not args)
            LibDualSpec:EnhanceOptions(profileOptions, self.db)
            
            -- Copy LibDualSpec plugin options from the original to our isolated copy
            if profileOptions.plugins and profileOptions.plugins["LibDualSpec-1.0"] then
                local dualSpecOptions = profileOptions.plugins["LibDualSpec-1.0"]
                -- Deep copy the dual spec options to ensure complete isolation
                local dualSpecOptionsCopy = DeepCopyTable(dualSpecOptions)
                -- Merge all dual spec options into our isolated args
                for key, option in pairs(dualSpecOptionsCopy) do
                    options.args.profiles.args[key] = option
                end
            end
            
            -- Override the enabled toggle's set function to refresh the GUI immediately
            if options.args.profiles.args and options.args.profiles.args.enabled then
                local originalEnabledSet = options.args.profiles.args.enabled.set
                options.args.profiles.args.enabled.set = function(info, value)
                    if originalEnabledSet then
                        originalEnabledSet(info, value)
                    end
                    -- Refresh custom GUI if open
                    local configFrame = _G["NephUI_ConfigFrame"]
                    if configFrame and configFrame:IsShown() and configFrame.FullRefresh then
                        configFrame:FullRefresh()
                    end
                end
            end
        end
        
        -- Fix the "new" profile input field to not create profiles on every keystroke
        -- Store the profile name in a buffer and only create when button is clicked
        local profileBuffers = {
            new = "",
            copyFrom = "",
            delete = "",
        }
        local handler = options.args.profiles.handler
        
        if options.args.profiles.args and options.args.profiles.args.new then
            local originalSet = options.args.profiles.args.new.set
            
            -- Override the set function to just store the value instead of creating profile
            options.args.profiles.args.new.set = function(info, value)
                profileBuffers.new = value or ""
            end
            -- Change get to return empty string (don't show buffer)
            options.args.profiles.args.new.get = function()
                return ""
            end
            
            -- Add a "Create Profile" button after the new input field
            options.args.profiles.args.createProfile = {
                type = "execute",
                name = "Create Profile",
                desc = "Create a new profile with the name entered above",
                order = 31,
                func = function(info)
                    if not profileBuffers.new or profileBuffers.new == "" then
                        print("|cffff0000NephUI: Please enter a profile name.|r")
                        return
                    end
                    -- Trim whitespace
                    profileBuffers.new = profileBuffers.new:gsub("^%s+", ""):gsub("%s+$", "")
                    if profileBuffers.new == "" then
                        print("|cffff0000NephUI: Please enter a valid profile name.|r")
                        return
                    end
                    
                    -- Directly call SetProfile on OUR database - this will create the profile if it doesn't exist
                    -- Use the stored reference to ensure we're always using NephUI's database
                    if nephDB then
                        local profileName = profileBuffers.new
                        local success, err = pcall(function()
                            -- SetProfile will create the profile if it doesn't exist (lazy creation)
                            nephDB:SetProfile(profileName)
                            -- Access the profile to trigger its creation if it's new
                            local _ = nephDB.profile
                        end)
                        if success then
                            -- Verify the profile was created by checking if it's in the profiles list
                            local profiles = nephDB:GetProfiles()
                            local profileExists = false
                            for _, p in ipairs(profiles) do
                                if p == profileName then
                                    profileExists = true
                                    break
                                end
                            end
                            if profileExists then
                                print("|cff00ff00NephUI: Profile '" .. profileName .. "' created successfully. Please reload your UI.|r")
                            else
                                print("|cffff0000NephUI: Profile creation may have failed. Please reload your UI and check if the profile exists.|r")
                            end
                        else
                            print("|cffff0000NephUI: Failed to create profile: " .. (err or "Unknown error") .. "|r")
                        end
                    else
                        -- Fallback to handler method if database not directly available
                        -- CRITICAL: Always use our handler with our database
                        if originalSet then
                            if type(originalSet) == "string" then
                                -- It's a method name, call it on OUR handler
                                local handlerToUse = options.args.profiles.handler
                                if handlerToUse and handlerToUse.db == nephDB and handlerToUse[originalSet] then
                                    handlerToUse[originalSet](handlerToUse, info, profileBuffers.new)
                                    print("|cff00ff00NephUI: Profile '" .. profileBuffers.new .. "' created successfully. Please reload your UI.|r")
                                else
                                    print("|cffff0000NephUI: Failed to create profile: Handler not available or wrong database.|r")
                                end
                            elseif type(originalSet) == "function" then
                                -- Create a wrapper that ensures we use our handler
                                local wrappedSet = function(info, value)
                                    -- Ensure info.handler is our handler
                                    local originalInfo = info
                                    info = {}
                                    for k, v in pairs(originalInfo) do
                                        info[k] = v
                                    end
                                    info.handler = options.args.profiles.handler
                                    originalSet(info, value)
                                end
                                wrappedSet(info, profileBuffers.new)
                                print("|cff00ff00NephUI: Profile '" .. profileBuffers.new .. "' created successfully. Please reload your UI.|r")
                            end
                        else
                            print("|cffff0000NephUI: Failed to create profile: No profile creation method available.|r")
                        end
                    end
                    
                    -- Clear the buffer
                    profileBuffers.new = ""
                    -- Clear the input field by refreshing
                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                    if AceConfigRegistry then
                        AceConfigRegistry:NotifyChange(ADDON_NAME)
                    end
                end,
            }
        end
        
        -- Fix the "copyfrom" dropdown to require confirmation button
        if options.args.profiles.args and options.args.profiles.args.copyfrom then
            local originalCopySet = options.args.profiles.args.copyfrom.set
            local originalCopyGet = options.args.profiles.args.copyfrom.get
            
            -- Override the set function to just store the selection
            options.args.profiles.args.copyfrom.set = function(info, value)
                profileBuffers.copyFrom = value or ""
                -- Refresh the config UI immediately so the button shows up
                local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                if AceConfigRegistry then
                    AceConfigRegistry:NotifyChange(ADDON_NAME)
                end
            end
            -- Override get to show the selected value from buffer
            options.args.profiles.args.copyfrom.get = function(info)
                if profileBuffers.copyFrom and profileBuffers.copyFrom ~= "" then
                    return profileBuffers.copyFrom
                end
                -- If no buffer, try original get or return nil
                if originalCopyGet then
                    if type(originalCopyGet) == "function" then
                        return originalCopyGet(info)
                    elseif type(originalCopyGet) == "string" then
                        local handlerToUse = handler or info.handler
                        if handlerToUse and handlerToUse[originalCopyGet] then
                            return handlerToUse[originalCopyGet](handlerToUse, info)
                        end
                    end
                end
                return nil
            end
            
            -- Add a "Copy Profile" button after the copyfrom dropdown
            options.args.profiles.args.copyProfile = {
                type = "execute",
                name = "Copy Profile",
                desc = "Copy settings from the selected profile to the current profile",
                order = 61,
                func = function(info)
                    if not profileBuffers.copyFrom or profileBuffers.copyFrom == "" then
                        print("|cffff0000NephUI: Please select a profile to copy from.|r")
                        return
                    end
                    -- Call the original CopyProfile function
                    -- CRITICAL: Always use our handler with our database
                    if originalCopySet then
                        if type(originalCopySet) == "string" then
                            local handlerToUse = options.args.profiles.handler
                            if handlerToUse and handlerToUse.db == nephDB and handlerToUse[originalCopySet] then
                                handlerToUse[originalCopySet](handlerToUse, info, profileBuffers.copyFrom)
                            end
                        elseif type(originalCopySet) == "function" then
                            -- Create a wrapper that ensures we use our handler
                            local wrappedSet = function(info, value)
                                local originalInfo = info
                                info = {}
                                for k, v in pairs(originalInfo) do
                                    info[k] = v
                                end
                                info.handler = options.args.profiles.handler
                                originalCopySet(info, value)
                            end
                            wrappedSet(info, profileBuffers.copyFrom)
                        end
                    end
                    -- Clear the buffer
                    profileBuffers.copyFrom = ""
                    -- Refresh the config
                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                    if AceConfigRegistry then
                        AceConfigRegistry:NotifyChange(ADDON_NAME)
                    end
                    print("|cff00ff00NephUI: Profile copied successfully.|r")
                end,
            }
        end
        
        -- Fix the "delete" dropdown to require confirmation button
        if options.args.profiles.args and options.args.profiles.args.delete then
            local originalDeleteSet = options.args.profiles.args.delete.set
            local originalDeleteGet = options.args.profiles.args.delete.get
            
            -- Override the set function to just store the selection
            options.args.profiles.args.delete.set = function(info, value)
                profileBuffers.delete = value or ""
                -- Refresh the config UI immediately so the button shows up
                local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                if AceConfigRegistry then
                    AceConfigRegistry:NotifyChange(ADDON_NAME)
                end
            end
            -- Override get to show the selected value from buffer
            options.args.profiles.args.delete.get = function(info)
                if profileBuffers.delete and profileBuffers.delete ~= "" then
                    return profileBuffers.delete
                end
                -- If no buffer, try original get or return nil
                if originalDeleteGet then
                    if type(originalDeleteGet) == "function" then
                        return originalDeleteGet(info)
                    elseif type(originalDeleteGet) == "string" then
                        local handlerToUse = handler or info.handler
                        if handlerToUse and handlerToUse[originalDeleteGet] then
                            return handlerToUse[originalDeleteGet](handlerToUse, info)
                        end
                    end
                end
                return nil
            end
            
            -- Remove the confirm property since we're using a button instead
            options.args.profiles.args.delete.confirm = false
            
            -- Add a "Delete Profile" button after the delete dropdown
            options.args.profiles.args.deleteProfile = {
                type = "execute",
                name = "Delete Profile",
                desc = "Permanently delete the selected profile. This cannot be undone!",
                order = 81,
                func = function(info)
                    if not profileBuffers.delete or profileBuffers.delete == "" then
                        print("|cffff0000NephUI: Please select a profile to delete.|r")
                        return
                    end
                    -- Show confirmation dialog
                    -- CRITICAL: Always use our handler with our database
                    local dialogData = {
                        profileName = profileBuffers.delete,
                        handler = options.args.profiles.handler,
                        originalDeleteSet = originalDeleteSet,
                        info = info,
                        profileBuffers = profileBuffers,
                        nephDB = nephDB, -- Store reference to our database
                    }
                    StaticPopup_Show("NEPHUI_DELETE_PROFILE", profileBuffers.delete, nil, dialogData)
                end,
            }
        end
        
        -- Register the delete confirmation popup
        if not StaticPopupDialogs["NEPHUI_DELETE_PROFILE"] then
            StaticPopupDialogs["NEPHUI_DELETE_PROFILE"] = {
                text = "Are you sure you want to delete the profile '%s'? This cannot be undone!",
                button1 = "Delete",
                button2 = "Cancel",
                OnAccept = function(self, data)
                    if data and data.originalDeleteSet then
                        -- CRITICAL: Always use our handler with our database
                        if type(data.originalDeleteSet) == "string" then
                            local handlerToUse = data.handler
                            if handlerToUse and handlerToUse.db == data.nephDB and handlerToUse[data.originalDeleteSet] then
                                handlerToUse[data.originalDeleteSet](handlerToUse, data.info, data.profileName)
                            end
                        elseif type(data.originalDeleteSet) == "function" then
                            -- Create a wrapper that ensures we use our handler
                            local wrappedSet = function(info, value)
                                local originalInfo = info
                                info = {}
                                for k, v in pairs(originalInfo) do
                                    info[k] = v
                                end
                                info.handler = data.handler
                                data.originalDeleteSet(info, value)
                            end
                            wrappedSet(data.info, data.profileName)
                        end
                    end
                    -- Clear the buffer
                    if data and data.profileBuffers then
                        data.profileBuffers.delete = ""
                    end
                    -- Refresh the config
                    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
                    if AceConfigRegistry then
                        AceConfigRegistry:NotifyChange(ADDON_NAME)
                    end
                    print("|cff00ff00NephUI: Profile deleted successfully.|r")
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
        end
        
        if options.args.profiles.args and options.args.profiles.args.reset then
            local originalResetFunc = options.args.profiles.args.reset.func
            options.args.profiles.args.reset.func = function(info)
                -- CRITICAL: Always use our handler with our database
                local handlerToUse = options.args.profiles.handler
                if handlerToUse and handlerToUse.db == nephDB and handlerToUse.Reset then
                    handlerToUse:Reset()
                    print("|cff00ff00NephUI: Profile reset to defaults. Please reload your UI.|r")
                elseif originalResetFunc then
                    -- Fallback to original func if handler method doesn't exist
                    if type(originalResetFunc) == "string" then
                        if handlerToUse and handlerToUse.db == nephDB and handlerToUse[originalResetFunc] then
                            handlerToUse[originalResetFunc](handlerToUse)
                            print("|cff00ff00NephUI: Profile reset to defaults. Please reload your UI.|r")
                        end
                    elseif type(originalResetFunc) == "function" then
                        -- Create a wrapper that ensures we use our handler
                        local wrappedFunc = function(info)
                            local originalInfo = info
                            info = {}
                            for k, v in pairs(originalInfo) do
                                info[k] = v
                            end
                            info.handler = handlerToUse
                            originalResetFunc(info)
                        end
                        wrappedFunc(info)
                        print("|cff00ff00NephUI: Profile reset to defaults. Please reload your UI.|r")
                    end
                else
                    -- Last resort: call ResetProfile directly on our database
                    if nephDB then
                        nephDB:ResetProfile()
                        print("|cff00ff00NephUI: Profile reset to defaults. Please reload your UI.|r")
                    end
                end
            end
        end
    end

    -- QUICK ACCESS BUTTONS
    options.args.openEditMode = {
        type = "execute",
        name = "Open Edit Mode",
        desc = "Open WoW's Edit Mode to reposition UI elements",
        order = 100,
        func = function()
            DEFAULT_CHAT_FRAME.editBox:SetText("/editmode")
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
        end,
    }

    options.args.openConfig = {
        type = "execute",
        name = "Open Advanced Cooldown Manager Panel",
        desc = "Open Advanced Cooldown Manager Panel",
        order = 101,
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

    -- Version display and Discord link button
    options.args.versionSpacer = {
        type = "description",
        name = " ",
        order = 200,
    }

    options.args.version = {
        type = "description",
        name = function()
            return "|cff00ff00NephUI v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unknown") .. "|r"
        end,
        order = 201,
    }

    options.args.discord = {
        type = "input",
        name = "Discord",
        desc = "Join our Discord server for support and updates",
        order = 202,
        width = "full",
        get = function()
            return "https://discord.gg/Mc2StWHKya"
        end,
        set = function() end,
    }

    -- Register options with AceConfig (for compatibility - still needed for option table structure)
    AceConfig:RegisterOptionsTable(ADDON_NAME, options)
    
    -- Store options for custom GUI
    self.configOptions = options
end

