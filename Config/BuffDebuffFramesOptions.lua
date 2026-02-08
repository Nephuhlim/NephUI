local ADDON_NAME, ns = ...
local NephUI = ns.Addon

-- Helper function to get anchor point options (all 8 points)
local function GetAnchorPointOptions()
    return {
        TOPLEFT = "Top Left",
        TOP = "Top",
        TOPRIGHT = "Top Right",
        LEFT = "Left",
        CENTER = "Center",
        RIGHT = "Right",
        BOTTOMLEFT = "Bottom Left",
        BOTTOM = "Bottom",
        BOTTOMRIGHT = "Bottom Right",
    }
end


-- Create options for a specific type (buffs or debuffs)
local function CreateTypeOptions(typeKey, displayName, order)
    local db = NephUI.db.profile.buffDebuffFrames
    if not db then return {} end
    
    return {
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
                name = "Enable " .. displayName .. " Frame Styling",
                desc = "Apply custom NephUI styling to " .. displayName:lower() .. " frames",
                width = "full",
                order = 2,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return false end
                    if not db.enabled then return false end
                    if not db[typeKey] then return true end
                    return db[typeKey].enabled ~= false
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then
                        NephUI.db.profile.buffDebuffFrames = {}
                        db = NephUI.db.profile.buffDebuffFrames
                    end
                    if not db.enabled then db.enabled = true end
                    if not db[typeKey] then db[typeKey] = {} end
                    db[typeKey].enabled = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            spacer0 = {
                type = "description",
                name = " ",
                order = 3,
            },
            iconSizeHeader = {
                type = "header",
                name = "Icon Size",
                order = 10,
            },
            iconSize = {
                type = "range",
                name = "Icon Size (use this to also adjust spacing)",
                desc = "Size of " .. displayName:lower() .. " icons in pixels",
                order = 11,
                width = "full",
                min = 16,
                max = 96,
                step = 1,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 36 end
                    return db[typeKey].iconSize or 36
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    db[typeKey].iconSize = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 12,
            },
            countHeader = {
                type = "header",
                name = "Stack Count Text",
                order = 19,
            },
            countEnabled = {
                type = "toggle",
                name = "Enable Stack Count Text",
                desc = "Show/hide stack count text",
                width = "full",
                order = 21,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return true end
                    local textConfig = db[typeKey].count or {}
                    return textConfig.enabled ~= false
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].count then db[typeKey].count = {} end
                    db[typeKey].count.enabled = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            countFontSize = {
                type = "range",
                name = "Stack Count Font Size",
                desc = "Font size for stack count text",
                order = 22,
                width = "full",
                min = 6,
                max = 32,
                step = 1,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 12 end
                    local textConfig = db[typeKey].count or {}
                    return textConfig.fontSize or 12
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].count then db[typeKey].count = {} end
                    db[typeKey].count.fontSize = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            countAnchorPoint = {
                type = "select",
                name = "Stack Count Anchor Point",
                desc = "Where to anchor stack count text relative to icon",
                order = 23,
                width = "full",
                values = GetAnchorPointOptions(),
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return "TOPRIGHT" end
                    local textConfig = db[typeKey].count or {}
                    return textConfig.anchorPoint or "TOPRIGHT"
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].count then db[typeKey].count = {} end
                    db[typeKey].count.anchorPoint = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            countOffsetX = {
                type = "range",
                name = "Stack Count X Offset",
                desc = "Horizontal offset for stack count text",
                order = 24,
                width = "full",
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 0 end
                    local textConfig = db[typeKey].count or {}
                    return textConfig.offsetX or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].count then db[typeKey].count = {} end
                    db[typeKey].count.offsetX = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            countOffsetY = {
                type = "range",
                name = "Stack Count Y Offset",
                desc = "Vertical offset for stack count text",
                order = 25,
                width = "full",
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 0 end
                    local textConfig = db[typeKey].count or {}
                    return textConfig.offsetY or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].count then db[typeKey].count = {} end
                    db[typeKey].count.offsetY = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            countTextColor = {
                type = "color",
                name = "Stack Count Text Color",
                desc = "Color for stack count text",
                order = 26,
                width = "full",
                hasAlpha = true,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 1, 1, 1, 1 end
                    local textConfig = db[typeKey].count or {}
                    local color = textConfig.textColor or {1, 1, 1, 1}
                    return color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
                end,
                set = function(_, r, g, b, a)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].count then db[typeKey].count = {} end
                    db[typeKey].count.textColor = {r, g, b, a or 1}
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            spacer3 = {
                type = "description",
                name = " ",
                order = 27,
            },
            durationHeader = {
                type = "header",
                name = "Duration Text",
                order = 30,
            },
            durationEnabled = {
                type = "toggle",
                name = "Enable Duration Text",
                desc = "Show/hide duration/cooldown text",
                width = "full",
                order = 31,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return true end
                    local textConfig = db[typeKey].duration or {}
                    return textConfig.enabled ~= false
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].duration then db[typeKey].duration = {} end
                    db[typeKey].duration.enabled = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            durationFontSize = {
                type = "range",
                name = "Duration Font Size",
                desc = "Font size for duration text",
                order = 32,
                width = "full",
                min = 6,
                max = 32,
                step = 1,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 12 end
                    local textConfig = db[typeKey].duration or {}
                    return textConfig.fontSize or 12
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].duration then db[typeKey].duration = {} end
                    db[typeKey].duration.fontSize = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            durationAnchorPoint = {
                type = "select",
                name = "Duration Anchor Point",
                desc = "Where to anchor duration text relative to icon",
                order = 33,
                width = "full",
                values = GetAnchorPointOptions(),
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return "CENTER" end
                    local textConfig = db[typeKey].duration or {}
                    return textConfig.anchorPoint or "CENTER"
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].duration then db[typeKey].duration = {} end
                    db[typeKey].duration.anchorPoint = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            durationOffsetX = {
                type = "range",
                name = "Duration X Offset",
                desc = "Horizontal offset for duration text",
                order = 34,
                width = "full",
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 0 end
                    local textConfig = db[typeKey].duration or {}
                    return textConfig.offsetX or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].duration then db[typeKey].duration = {} end
                    db[typeKey].duration.offsetX = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            durationOffsetY = {
                type = "range",
                name = "Duration Y Offset",
                desc = "Vertical offset for duration text",
                order = 35,
                width = "full",
                min = -50,
                max = 50,
                step = 1,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 0 end
                    local textConfig = db[typeKey].duration or {}
                    return textConfig.offsetY or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].duration then db[typeKey].duration = {} end
                    db[typeKey].duration.offsetY = val
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
            durationTextColor = {
                type = "color",
                name = "Duration Text Color",
                desc = "Color for duration text",
                order = 36,
                width = "full",
                hasAlpha = true,
                get = function()
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db or not db[typeKey] then return 1, 1, 1, 1 end
                    local textConfig = db[typeKey].duration or {}
                    local color = textConfig.textColor or {1, 1, 1, 1}
                    return color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
                end,
                set = function(_, r, g, b, a)
                    local db = NephUI.db.profile.buffDebuffFrames
                    if not db then return end
                    if not db[typeKey] then db[typeKey] = {} end
                    if not db[typeKey].duration then db[typeKey].duration = {} end
                    db[typeKey].duration.textColor = {r, g, b, a or 1}
                    if NephUI.BuffDebuffFrames and NephUI.BuffDebuffFrames.RefreshAll then
                        NephUI.BuffDebuffFrames:RefreshAll()
                    end
                end,
            },
        },
    }
end

local function CreateBuffDebuffFramesOptions()
    return {
        type = "group",
        name = "Buff/Debuffs",
        order = 11,
        childGroups = "tab",
        args = {
            buffs = CreateTypeOptions("buffs", "Buffs", 1),
            debuffs = CreateTypeOptions("debuffs", "Debuffs", 2),
        },
    }
end

ns.CreateBuffDebuffFramesOptions = CreateBuffDebuffFramesOptions

