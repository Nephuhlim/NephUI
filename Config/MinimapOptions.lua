local ADDON_NAME, ns = ...
local NephUI = ns.Addon

local function CreateMinimapOptions()
    return {
        type = "group",
        name = "Minimap",
        order = 2,
        args = {
            header = {
                type = "header",
                name = "Minimap Settings",
                order = 1,
            },
            
            mouseButtonNote = {
                type = "description",
                name = "|cffffd100Mouse Button Controls:|r\nMiddle Mouse Button = Calendar\nRight Mouse Button = Tracking Menu",
                width = "full",
                order = 1.5,
            },
            
            enabled = {
                type = "toggle",
                name = "Enable Minimap Module",
                desc = "Enable or disable the minimap customization",
                width = "full",
                order = 2,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return true
                    end
                    return NephUI.db.profile.minimap.enabled
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.enabled = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            spacer1 = {
                type = "description",
                name = " ",
                order = 3,
            },
            
            size = {
                type = "range",
                name = "Minimap Size",
                desc = "Size of the minimap in pixels",
                order = 10,
                width = "full",
                min = 100,
                max = 400,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return 200
                    end
                    return NephUI.db.profile.minimap.size or 200
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.size = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            borderSize = {
                type = "range",
                name = "Border Size",
                desc = "Size of the black border around the minimap in pixels",
                order = 11,
                width = "full",
                min = 0,
                max = 10,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return 1
                    end
                    return NephUI.db.profile.minimap.borderSize or 1
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.borderSize = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            lock = {
                type = "toggle",
                name = "Lock Minimap",
                desc = "Lock the minimap position to prevent dragging",
                width = "full",
                order = 13,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.lock or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.lock = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            scale = {
                type = "range",
                name = "Minimap Scale",
                desc = "Scale of the minimap",
                order = 14,
                width = "full",
                min = 0.5,
                max = 2.0,
                step = 0.1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return 1
                    end
                    return NephUI.db.profile.minimap.scale or 1
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.scale = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            autoZoom = {
                type = "toggle",
                name = "Auto Zoom Out",
                desc = "Automatically zoom out after 10 seconds",
                width = "full",
                order = 15,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return true
                    end
                    return NephUI.db.profile.minimap.autoZoom ~= false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.autoZoom = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            mouseWheelZoom = {
                type = "toggle",
                name = "Mouse Wheel Zoom",
                desc = "Enable zooming with mouse wheel",
                width = "full",
                order = 16,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return true
                    end
                    return NephUI.db.profile.minimap.mouseWheelZoom ~= false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.mouseWheelZoom = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            hideZoomButtons = {
                type = "toggle",
                name = "Hide Zoom Buttons",
                desc = "Hide the zoom in/out buttons",
                width = "full",
                order = 17,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.hideZoomButtons or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.hideZoomButtons = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            spacer2 = {
                type = "description",
                name = " ",
                order = 19,
            },
            
            zoneTextHeader = {
                type = "header",
                name = "Zone Text",
                order = 20,
            },
            
            zoneTextEnabled = {
                type = "toggle",
                name = "Enable Zone Text",
                desc = "Show or hide the zone text above the minimap",
                width = "full",
                order = 21,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.zoneText then
                        return true
                    end
                    return NephUI.db.profile.minimap.zoneText.enabled
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.zoneText then
                        NephUI.db.profile.minimap.zoneText = {}
                    end
                    NephUI.db.profile.minimap.zoneText.enabled = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            zoneTextFontSize = {
                type = "range",
                name = "Zone Text Font Size",
                desc = "Font size for the zone text",
                order = 22,
                width = "full",
                min = 8,
                max = 24,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.zoneText then
                        return 14
                    end
                    return NephUI.db.profile.minimap.zoneText.fontSize or 14
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.zoneText then
                        NephUI.db.profile.minimap.zoneText = {}
                    end
                    NephUI.db.profile.minimap.zoneText.fontSize = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            zoneTextAnchor = {
                type = "select",
                name = "Zone Text Anchor",
                desc = "Anchor position for the zone text",
                order = 23,
                width = "full",
                values = {
                    ["Top"] = "Top",
                    ["Top Right"] = "Top Right",
                    ["Top Left"] = "Top Left",
                    ["Right"] = "Right",
                    ["Left"] = "Left",
                    ["Center"] = "Center",
                    ["Bottom Right"] = "Bottom Right",
                    ["Bottom"] = "Bottom",
                    ["Bottom Left"] = "Bottom Left",
                },
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.zoneText then
                        return "Top"
                    end
                    return NephUI.db.profile.minimap.zoneText.anchor or "Top"
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.zoneText then
                        NephUI.db.profile.minimap.zoneText = {}
                    end
                    NephUI.db.profile.minimap.zoneText.anchor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            zoneTextOffsetX = {
                type = "range",
                name = "Zone Text X Offset",
                desc = "Horizontal offset for the zone text",
                order = 24,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.zoneText then
                        return 0
                    end
                    return NephUI.db.profile.minimap.zoneText.offsetX or 0
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.zoneText then
                        NephUI.db.profile.minimap.zoneText = {}
                    end
                    NephUI.db.profile.minimap.zoneText.offsetX = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            zoneTextOffsetY = {
                type = "range",
                name = "Zone Text Y Offset",
                desc = "Vertical offset for the zone text",
                order = 25,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.zoneText then
                        return -5
                    end
                    return NephUI.db.profile.minimap.zoneText.offsetY or -5
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.zoneText then
                        NephUI.db.profile.minimap.zoneText = {}
                    end
                    NephUI.db.profile.minimap.zoneText.offsetY = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            zoneTextUseCustomColor = {
                type = "toggle",
                name = "Use Custom Color",
                desc = "Override PVP zone colors with custom color",
                width = "full",
                order = 26,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.zoneText then
                        return false
                    end
                    return NephUI.db.profile.minimap.zoneText.useCustomColor or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.zoneText then
                        NephUI.db.profile.minimap.zoneText = {}
                    end
                    NephUI.db.profile.minimap.zoneText.useCustomColor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            zoneTextColor = {
                type = "color",
                name = "Zone Text Color",
                desc = "Custom color for zone text (when custom color is enabled)",
                order = 27,
                width = "full",
                hasAlpha = true,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.zoneText then
                        return 1, 0.82, 0, 1
                    end
                    local c = NephUI.db.profile.minimap.zoneText.color or {1, 0.82, 0, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.zoneText then
                        NephUI.db.profile.minimap.zoneText = {}
                    end
                    NephUI.db.profile.minimap.zoneText.color = {r, g, b, a or 1}
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            spacer3 = {
                type = "description",
                name = " ",
                order = 29,
            },
            
            spacer4 = {
                type = "description",
                name = " ",
                order = 49,
            },
            
            clockHeader = {
                type = "header",
                name = "Clock",
                order = 50,
            },
            
            clockEnabled = {
                type = "toggle",
                name = "Enable Clock",
                desc = "Show clock on the minimap",
                width = "full",
                order = 51,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return false
                    end
                    return NephUI.db.profile.minimap.clock.enabled or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.enabled = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            clockTimeSource = {
                type = "select",
                name = "Clock Time Source",
                desc = "Choose between local time and server time",
                order = 51.2,
                width = "full",
                values = {
                    server = "Server Time",
                    ["local"] = "Local Time",
                },
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return "server"
                    end
                    return NephUI.db.profile.minimap.clock.timeSource or "server"
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.timeSource = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            clockTimeFormat = {
                type = "toggle",
                name = "Use 24-Hour Clock",
                desc = "Toggle between 12-hour and 24-hour time",
                width = "full",
                order = 51.3,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return false
                    end
                    return NephUI.db.profile.minimap.clock.useMilitaryTime or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.useMilitaryTime = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            clockFontSize = {
                type = "range",
                name = "Clock Font Size",
                desc = "Font size for clock",
                order = 52,
                width = "full",
                min = 8,
                max = 24,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return 12
                    end
                    return NephUI.db.profile.minimap.clock.fontSize or 12
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.fontSize = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            clockAnchor = {
                type = "select",
                name = "Clock Anchor",
                desc = "Anchor position for the clock",
                order = 52.5,
                width = "full",
                values = {
                    ["Top"] = "Top",
                    ["Top Right"] = "Top Right",
                    ["Top Left"] = "Top Left",
                    ["Right"] = "Right",
                    ["Left"] = "Left",
                    ["Center"] = "Center",
                    ["Bottom Right"] = "Bottom Right",
                    ["Bottom"] = "Bottom",
                    ["Bottom Left"] = "Bottom Left",
                },
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return "Bottom"
                    end
                    return NephUI.db.profile.minimap.clock.anchor or "Bottom"
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.anchor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            clockUseClassColor = {
                type = "toggle",
                name = "Use Class Color",
                desc = "Use your class color for the clock text",
                width = "full",
                order = 52.55,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return false
                    end
                    return NephUI.db.profile.minimap.clock.useClassColor or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.useClassColor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            clockColor = {
                type = "color",
                name = "Clock Color",
                desc = "Color for the clock text",
                order = 52.6,
                width = "full",
                hasAlpha = true,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return 1, 1, 1, 1
                    end
                    local c = NephUI.db.profile.minimap.clock.color or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.color = {r, g, b, a or 1}
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            clockOffsetX = {
                type = "range",
                name = "Clock X Offset",
                desc = "Horizontal offset for the clock",
                order = 53,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return 0
                    end
                    return NephUI.db.profile.minimap.clock.offsetX or 0
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.offsetX = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            clockOffsetY = {
                type = "range",
                name = "Clock Y Offset",
                desc = "Vertical offset for the clock",
                order = 54,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.clock then
                        return -4
                    end
                    return NephUI.db.profile.minimap.clock.offsetY or -4
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.clock then
                        NephUI.db.profile.minimap.clock = {}
                    end
                    NephUI.db.profile.minimap.clock.offsetY = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            spacer6a = {
                type = "description",
                name = " ",
                order = 55,
            },
            
            fpsHeader = {
                type = "header",
                name = "System Data",
                order = 56,
            },
            
            fpsEnabled = {
                type = "toggle",
                name = "Enable System Data",
                desc = "Show system data on the minimap",
                width = "full",
                order = 57,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return false
                    end
                    return NephUI.db.profile.minimap.fps.enabled or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.enabled = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            fpsFontSize = {
                type = "range",
                name = "System Data Font Size",
                desc = "Font size for the system data display",
                order = 58,
                width = "full",
                min = 8,
                max = 24,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return 12
                    end
                    return NephUI.db.profile.minimap.fps.fontSize or 12
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.fontSize = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            fpsUpdateFrequency = {
                type = "range",
                name = "System Data Update Frequency",
                desc = "How often to update the system data display (in seconds)",
                order = 58.1,
                width = "full",
                min = 0.1,
                max = 5.0,
                step = 0.1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return 0.5
                    end
                    return NephUI.db.profile.minimap.fps.updateFrequency or 0.5
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.updateFrequency = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            fpsAnchor = {
                type = "select",
                name = "System Data Anchor",
                desc = "Anchor position for the system data display",
                order = 58.5,
                width = "full",
                values = {
                    ["Top"] = "Top",
                    ["Top Right"] = "Top Right",
                    ["Top Left"] = "Top Left",
                    ["Right"] = "Right",
                    ["Left"] = "Left",
                    ["Center"] = "Center",
                    ["Bottom Right"] = "Bottom Right",
                    ["Bottom"] = "Bottom",
                    ["Bottom Left"] = "Bottom Left",
                },
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return "Bottom"
                    end
                    return NephUI.db.profile.minimap.fps.anchor or "Bottom"
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.anchor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            fpsUseClassColor = {
                type = "toggle",
                name = "Use Class Color",
                desc = "Use your class color for the system data text",
                width = "full",
                order = 58.55,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return false
                    end
                    return NephUI.db.profile.minimap.fps.useClassColor or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.useClassColor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            fpsShowPing = {
                type = "toggle",
                name = "Show Ping",
                desc = "Show your ping alongside FPS",
                width = "full",
                order = 58.56,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return false
                    end
                    return NephUI.db.profile.minimap.fps.showPing or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.showPing = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            fpsPingSource = {
                type = "select",
                name = "Ping Source",
                desc = "Choose which ping value to display",
                order = 58.57,
                width = "full",
                values = {
                    home = "Home Ping",
                    world = "World Ping",
                },
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return "home"
                    end
                    return NephUI.db.profile.minimap.fps.pingSource or "home"
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.pingSource = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            fpsColor = {
                type = "color",
                name = "System Data Color",
                desc = "Color for the system data text",
                order = 58.6,
                width = "full",
                hasAlpha = true,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return 1, 1, 1, 1
                    end
                    local c = NephUI.db.profile.minimap.fps.color or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.color = {r, g, b, a or 1}
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            fpsOffsetX = {
                type = "range",
                name = "System Data X Offset",
                desc = "Horizontal offset for the system data display",
                order = 58.7,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return 0
                    end
                    return NephUI.db.profile.minimap.fps.offsetX or 0
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.offsetX = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            fpsOffsetY = {
                type = "range",
                name = "System Data Y Offset",
                desc = "Vertical offset for the system data display",
                order = 58.8,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.fps then
                        return -20
                    end
                    return NephUI.db.profile.minimap.fps.offsetY or -20
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.fps then
                        NephUI.db.profile.minimap.fps = {}
                    end
                    NephUI.db.profile.minimap.fps.offsetY = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            spacer6 = {
                type = "description",
                name = " ",
                order = 59,
            },
            
            buttonsHeader = {
                type = "header",
                name = "Button Visibility",
                order = 60,
            },
            
            hideTrackingButton = {
                type = "toggle",
                name = "Hide Tracking Button",
                desc = "Hide the tracking button",
                width = "full",
                order = 61,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.hideTrackingButton or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.hideTrackingButton = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            hideMailButton = {
                type = "toggle",
                name = "Hide Mail Button",
                desc = "Hide the mail indicator button",
                width = "full",
                order = 62,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.hideMailButton or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.hideMailButton = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            mailIconAnchor = {
                type = "select",
                name = "Mail Icon Anchor",
                desc = "Anchor position for the mail icon",
                order = 62.1,
                width = "full",
                values = {
                    ["Top"] = "Top",
                    ["Top Right"] = "Top Right",
                    ["Top Left"] = "Top Left",
                    ["Right"] = "Right",
                    ["Left"] = "Left",
                    ["Center"] = "Center",
                    ["Bottom Right"] = "Bottom Right",
                    ["Bottom"] = "Bottom",
                    ["Bottom Left"] = "Bottom Left",
                },
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.mailIcon then
                        return "Top Left"
                    end
                    return NephUI.db.profile.minimap.mailIcon.anchor or "Top Left"
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.mailIcon then
                        NephUI.db.profile.minimap.mailIcon = {}
                    end
                    NephUI.db.profile.minimap.mailIcon.anchor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            mailIconOffsetX = {
                type = "range",
                name = "Mail Icon X Offset",
                desc = "Horizontal offset for the mail icon",
                order = 62.2,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.mailIcon then
                        return 3
                    end
                    return NephUI.db.profile.minimap.mailIcon.offsetX or 3
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.mailIcon then
                        NephUI.db.profile.minimap.mailIcon = {}
                    end
                    NephUI.db.profile.minimap.mailIcon.offsetX = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            mailIconOffsetY = {
                type = "range",
                name = "Mail Icon Y Offset",
                desc = "Vertical offset for the mail icon",
                order = 62.3,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.mailIcon then
                        return -3
                    end
                    return NephUI.db.profile.minimap.mailIcon.offsetY or -3
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.mailIcon then
                        NephUI.db.profile.minimap.mailIcon = {}
                    end
                    NephUI.db.profile.minimap.mailIcon.offsetY = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            hideCalendarButton = {
                type = "toggle",
                name = "Hide Calendar Button",
                desc = "Hide the calendar button",
                width = "full",
                order = 63,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.hideCalendarButton or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.hideCalendarButton = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            hideDifficultyIcon = {
                type = "toggle",
                name = "Hide Difficulty Icon",
                desc = "Hide the instance difficulty icon",
                width = "full",
                order = 64,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.hideDifficultyIcon or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.hideDifficultyIcon = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            difficultyIconAnchor = {
                type = "select",
                name = "Difficulty Icon Anchor",
                desc = "Anchor position for the difficulty icon",
                order = 64.1,
                width = "full",
                values = {
                    ["Top"] = "Top",
                    ["Top Right"] = "Top Right",
                    ["Top Left"] = "Top Left",
                    ["Right"] = "Right",
                    ["Left"] = "Left",
                    ["Center"] = "Center",
                    ["Bottom Right"] = "Bottom Right",
                    ["Bottom"] = "Bottom",
                    ["Bottom Left"] = "Bottom Left",
                },
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.difficultyIcon then
                        return "Top Right"
                    end
                    return NephUI.db.profile.minimap.difficultyIcon.anchor or "Top Right"
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.difficultyIcon then
                        NephUI.db.profile.minimap.difficultyIcon = {}
                    end
                    NephUI.db.profile.minimap.difficultyIcon.anchor = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            difficultyIconOffsetX = {
                type = "range",
                name = "Difficulty Icon X Offset",
                desc = "Horizontal offset for the difficulty icon",
                order = 64.2,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.difficultyIcon then
                        return -5
                    end
                    return NephUI.db.profile.minimap.difficultyIcon.offsetX or -5
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.difficultyIcon then
                        NephUI.db.profile.minimap.difficultyIcon = {}
                    end
                    NephUI.db.profile.minimap.difficultyIcon.offsetX = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            difficultyIconOffsetY = {
                type = "range",
                name = "Difficulty Icon Y Offset",
                desc = "Vertical offset for the difficulty icon",
                order = 64.3,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap or not NephUI.db.profile.minimap.difficultyIcon then
                        return -5
                    end
                    return NephUI.db.profile.minimap.difficultyIcon.offsetY or -5
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.difficultyIcon then
                        NephUI.db.profile.minimap.difficultyIcon = {}
                    end
                    NephUI.db.profile.minimap.difficultyIcon.offsetY = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            hideMissionsButton = {
                type = "toggle",
                name = "Hide Missions Button",
                desc = "Hide the missions/garrison button",
                width = "full",
                order = 65,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.hideMissionsButton or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.hideMissionsButton = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            missionsButtonOffsetX = {
                type = "range",
                name = "Missions Button X Offset",
                desc = "Horizontal offset for the missions button",
                order = 65.1,
                width = "full",
                min = -200,
                max = 200,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return 0
                    end
                    if not NephUI.db.profile.minimap.missionsButton then
                        NephUI.db.profile.minimap.missionsButton = {}
                    end
                    return NephUI.db.profile.minimap.missionsButton.offsetX or 0
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.missionsButton then
                        NephUI.db.profile.minimap.missionsButton = {}
                    end
                    NephUI.db.profile.minimap.missionsButton.offsetX = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },

            missionsButtonOffsetY = {
                type = "range",
                name = "Missions Button Y Offset",
                desc = "Vertical offset for the missions button",
                order = 65.2,
                width = "full",
                min = -500,
                max = 500,
                step = 1,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return 0
                    end
                    if not NephUI.db.profile.minimap.missionsButton then
                        NephUI.db.profile.minimap.missionsButton = {}
                    end
                    return NephUI.db.profile.minimap.missionsButton.offsetY or 0
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    if not NephUI.db.profile.minimap.missionsButton then
                        NephUI.db.profile.minimap.missionsButton = {}
                    end
                    NephUI.db.profile.minimap.missionsButton.offsetY = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
            
            hideAddonCompartment = {
                type = "toggle",
                name = "Hide Addon Compartment",
                desc = "Hide the addon compartment button",
                width = "full",
                order = 66,
                get = function()
                    if not NephUI.db or not NephUI.db.profile or not NephUI.db.profile.minimap then
                        return false
                    end
                    return NephUI.db.profile.minimap.hideAddonCompartment or false
                end,
                set = function(_, val)
                    if not NephUI.db or not NephUI.db.profile then return end
                    if not NephUI.db.profile.minimap then
                        NephUI.db.profile.minimap = {}
                    end
                    NephUI.db.profile.minimap.hideAddonCompartment = val
                    if NephUI.Minimap and NephUI.Minimap.Refresh then
                        NephUI.Minimap:Refresh()
                    end
                end,
            },
        },
    }
end

ns.CreateMinimapOptions = CreateMinimapOptions
