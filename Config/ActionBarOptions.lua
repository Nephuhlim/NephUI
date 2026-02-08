local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

local function CreateActionBarOptions()
    return {
        type = "group",
        name = "Action Bars",
        order = 10,
        childGroups = "tab",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
            header = {
                type = "header",
                name = "Action Bar Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Action Bar Styling",
                desc = "Apply custom NephUI styling to action bars",
                width = "full",
                order = 2,
                get = function() return NephUI.db.profile.actionBars.enabled end,
                set = function(_, val)
                    NephUI.db.profile.actionBars.enabled = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            borderSize = {
                type = "range",
                name = "Border Thickness",
                desc = "Thickness of the action button border (expands outward, WHITE8x8 texture)",
                min = 0,
                max = 6,
                step = 1,
                width = "full",
                order = 3,
                get = function()
                    return NephUI.db.profile.actionBars.borderSize or 1
                end,
                set = function(_, val)
                    NephUI.db.profile.actionBars.borderSize = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            borderColor = {
                type = "color",
                name = "Border Color",
                desc = "Color of the outer border (WHITE8x8 texture)",
                order = 4,
                width = "full",
                hasAlpha = true,
                get = function()
                    local c = NephUI.db.profile.actionBars.borderColor or {0, 0, 0, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    NephUI.db.profile.actionBars.borderColor = { r, g, b, a or 1 }
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 5,
            },
            backdropColor = {
                type = "color",
                name = "Backdrop Color",
                desc = "Color of the action button backdrop (using Blizzard's WHITE8x8 texture)",
                order = 10,
                width = "full",
                hasAlpha = true,
                get = function()
                    local c = NephUI.db.profile.actionBars.backdropColor
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    NephUI.db.profile.actionBars.backdropColor = { r, g, b, a or 1 }
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            
            -- Font Section
            fontHeader = {
                type = "header",
                name = "Font Settings",
                order = 20,
            },
            font = {
                type = "select",
                name = "Font",
                desc = "Font used for action bar text elements. Leave as 'Use Global Font' to use the font from General settings.",
                order = 21,
                width = "full",
                values = function()
                    local hashTable = LSM:HashTable("font")
                    local names = {}
                    names[""] = "Use Global Font"
                    for name, _ in pairs(hashTable) do
                        names[name] = name
                    end
                    return names
                end,
                get = function()
                    local font = NephUI.db.profile.actionBars.font
                    return font or ""
                end,
                set = function(_, val)
                    if val == "" then
                        NephUI.db.profile.actionBars.font = nil
                    else
                        NephUI.db.profile.actionBars.font = val
                    end
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            
            spacer2 = {
                type = "description",
                name = " ",
                order = 29,
            },
            
            -- Mouseover Section
            mouseoverHeader = {
                type = "header",
                name = "Mouseover Settings",
                order = 30,
            },
            mouseoverEnabled = {
                type = "toggle",
                name = "Enable Mouseover",
                desc = "Action bars will fade out when not moused over. Use individual bar toggles below to select which bars use mouseover.",
                width = "full",
                order = 31,
                get = function() 
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    return cfg and cfg.enabled or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.enabled = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverAlpha = {
                type = "range",
                name = "Hidden Alpha",
                desc = "Alpha value for action bars when mouseover is enabled and not moused over",
                min = 0,
                max = 1,
                step = 0.01,
                order = 32,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    return cfg and cfg.alpha or 0.3
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.alpha = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBarHeader = {
                type = "header",
                name = "Individual Bar Mouseover",
                order = 33,
            },
            mouseoverBar1 = {
                type = "toggle",
                name = "Bar 1 (Main Action Bar)",
                desc = "Enable mouseover for Bar 1",
                order = 34,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar1 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar1 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBar2 = {
                type = "toggle",
                name = "Bar 2",
                desc = "Enable mouseover for Bar 2",
                order = 35,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar2 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar2 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBar3 = {
                type = "toggle",
                name = "Bar 3",
                desc = "Enable mouseover for Bar 3",
                order = 36,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar3 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar3 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBar4 = {
                type = "toggle",
                name = "Bar 4 (Right)",
                desc = "Enable mouseover for Bar 4",
                order = 37,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar4 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar4 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBar5 = {
                type = "toggle",
                name = "Bar 5 (Left)",
                desc = "Enable mouseover for Bar 5",
                order = 38,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar5 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar5 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBar6 = {
                type = "toggle",
                name = "Bar 6",
                desc = "Enable mouseover for Bar 6",
                order = 39,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar6 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar6 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBar7 = {
                type = "toggle",
                name = "Bar 7",
                desc = "Enable mouseover for Bar 7",
                order = 40,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar7 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar7 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverBar8 = {
                type = "toggle",
                name = "Bar 8",
                desc = "Enable mouseover for Bar 8",
                order = 41,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.bar8 or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.bar8 = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverPetBar = {
                type = "toggle",
                name = "Pet Action Bar",
                desc = "Enable mouseover for Pet Action Bar",
                order = 42,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.petBar or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.petBar = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverStanceBar = {
                type = "toggle",
                name = "Stance Bar",
                desc = "Enable mouseover for Stance Bar",
                order = 43,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.stanceBar or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.stanceBar = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            mouseoverMicroMenu = {
                type = "toggle",
                name = "Micro Menu",
                desc = "Enable mouseover for the Micro Menu",
                order = 44,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.mouseover
                    local bars = cfg and cfg.bars
                    return bars and bars.microMenu or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.mouseover then
                        NephUI.db.profile.actionBars.mouseover = {}
                    end
                    if not NephUI.db.profile.actionBars.mouseover.bars then
                        NephUI.db.profile.actionBars.mouseover.bars = {}
                    end
                    NephUI.db.profile.actionBars.mouseover.bars.microMenu = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            
            spacer3 = {
                type = "description",
                name = " ",
                order = 49,
            },
            
            -- Keybind Text Section
            keybindHeader = {
                type = "header",
                name = "Keybind Text Settings",
                order = 50,
            },
            keybindHide = {
                type = "toggle",
                name = "Hide Keybind Text",
                desc = "Hide keybind text on action buttons",
                width = "full",
                order = 51,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.keybindText
                    return cfg and cfg.hide or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.keybindText then
                        NephUI.db.profile.actionBars.keybindText = {}
                    end
                    NephUI.db.profile.actionBars.keybindText.hide = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            keybindColor = {
                type = "color",
                name = "Keybind Text Color",
                desc = "Color of the keybind text",
                order = 52,
                width = "full",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.keybindText
                    local c = cfg and cfg.fontColor or {0.75, 0.75, 0.75, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    if not NephUI.db.profile.actionBars.keybindText then
                        NephUI.db.profile.actionBars.keybindText = {}
                    end
                    NephUI.db.profile.actionBars.keybindText.fontColor = { r, g, b, a or 1 }
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            keybindSize = {
                type = "range",
                name = "Keybind Text Size",
                desc = "Font size for keybind text",
                min = 6,
                max = 32,
                step = 1,
                order = 53,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.keybindText
                    return cfg and cfg.fontSize or 14
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.keybindText then
                        NephUI.db.profile.actionBars.keybindText = {}
                    end
                    NephUI.db.profile.actionBars.keybindText.fontSize = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            keybindOffsetX = {
                type = "range",
                name = "Keybind Text X Offset",
                desc = "Horizontal offset for keybind text",
                min = -50,
                max = 50,
                step = 1,
                order = 54,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.keybindText
                    return cfg and cfg.offsetX or -2
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.keybindText then
                        NephUI.db.profile.actionBars.keybindText = {}
                    end
                    NephUI.db.profile.actionBars.keybindText.offsetX = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            keybindOffsetY = {
                type = "range",
                name = "Keybind Text Y Offset",
                desc = "Vertical offset for keybind text",
                min = -50,
                max = 50,
                step = 1,
                order = 55,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.keybindText
                    return cfg and cfg.offsetY or -4
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.keybindText then
                        NephUI.db.profile.actionBars.keybindText = {}
                    end
                    NephUI.db.profile.actionBars.keybindText.offsetY = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            
            spacer4 = {
                type = "description",
                name = " ",
                order = 59,
            },
            
            -- Macro Text Section
            macroHeader = {
                type = "header",
                name = "Macro Text Settings",
                order = 60,
            },
            macroHide = {
                type = "toggle",
                name = "Hide Macro Text",
                desc = "Hide macro name text on action buttons",
                width = "full",
                order = 61,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.macroText
                    return cfg and cfg.hide or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.macroText then
                        NephUI.db.profile.actionBars.macroText = {}
                    end
                    NephUI.db.profile.actionBars.macroText.hide = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            macroColor = {
                type = "color",
                name = "Macro Text Color",
                desc = "Color of the macro name text",
                order = 62,
                width = "full",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.macroText
                    local c = cfg and cfg.fontColor or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    if not NephUI.db.profile.actionBars.macroText then
                        NephUI.db.profile.actionBars.macroText = {}
                    end
                    NephUI.db.profile.actionBars.macroText.fontColor = { r, g, b, a or 1 }
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            macroSize = {
                type = "range",
                name = "Macro Text Size",
                desc = "Font size for macro name text",
                min = 6,
                max = 32,
                step = 1,
                order = 63,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.macroText
                    return cfg and cfg.fontSize or 10
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.macroText then
                        NephUI.db.profile.actionBars.macroText = {}
                    end
                    NephUI.db.profile.actionBars.macroText.fontSize = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            macroOffsetX = {
                type = "range",
                name = "Macro Text X Offset",
                desc = "Horizontal offset for macro name text",
                min = -50,
                max = 50,
                step = 1,
                order = 64,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.macroText
                    return cfg and cfg.offsetX or 0
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.macroText then
                        NephUI.db.profile.actionBars.macroText = {}
                    end
                    NephUI.db.profile.actionBars.macroText.offsetX = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            macroOffsetY = {
                type = "range",
                name = "Macro Text Y Offset",
                desc = "Vertical offset for macro name text",
                min = -50,
                max = 50,
                step = 1,
                order = 65,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.macroText
                    return cfg and cfg.offsetY or 2
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.macroText then
                        NephUI.db.profile.actionBars.macroText = {}
                    end
                    NephUI.db.profile.actionBars.macroText.offsetY = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            
            spacer5 = {
                type = "description",
                name = " ",
                order = 69,
            },
            
            -- Count Text Section
            countHeader = {
                type = "header",
                name = "Count Text Settings",
                order = 70,
            },
            countHide = {
                type = "toggle",
                name = "Hide Count Text",
                desc = "Hide item/charge count text on action buttons",
                width = "full",
                order = 71,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.countText
                    return cfg and cfg.hide or false
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.countText then
                        NephUI.db.profile.actionBars.countText = {}
                    end
                    NephUI.db.profile.actionBars.countText.hide = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            countColor = {
                type = "color",
                name = "Count Text Color",
                desc = "Color of the count text",
                order = 72,
                width = "full",
                hasAlpha = true,
                get = function()
                    local cfg = NephUI.db.profile.actionBars.countText
                    local c = cfg and cfg.fontColor or {1, 1, 1, 1}
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    if not NephUI.db.profile.actionBars.countText then
                        NephUI.db.profile.actionBars.countText = {}
                    end
                    NephUI.db.profile.actionBars.countText.fontColor = { r, g, b, a or 1 }
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            countSize = {
                type = "range",
                name = "Count Text Size",
                desc = "Font size for count text",
                min = 6,
                max = 32,
                step = 1,
                order = 73,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.countText
                    return cfg and cfg.fontSize or 16
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.countText then
                        NephUI.db.profile.actionBars.countText = {}
                    end
                    NephUI.db.profile.actionBars.countText.fontSize = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            countOffsetX = {
                type = "range",
                name = "Count Text X Offset",
                desc = "Horizontal offset for count text",
                min = -50,
                max = 50,
                step = 1,
                order = 74,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.countText
                    return cfg and cfg.offsetX or -2
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.countText then
                        NephUI.db.profile.actionBars.countText = {}
                    end
                    NephUI.db.profile.actionBars.countText.offsetX = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
            countOffsetY = {
                type = "range",
                name = "Count Text Y Offset",
                desc = "Vertical offset for count text",
                min = -50,
                max = 50,
                step = 1,
                order = 75,
                width = "full",
                get = function()
                    local cfg = NephUI.db.profile.actionBars.countText
                    return cfg and cfg.offsetY or 4
                end,
                set = function(_, val)
                    if not NephUI.db.profile.actionBars.countText then
                        NephUI.db.profile.actionBars.countText = {}
                    end
                    NephUI.db.profile.actionBars.countText.offsetY = val
                    if NephUI.ActionBars and NephUI.ActionBars.RefreshAll then
                        NephUI.ActionBars:RefreshAll()
                    end
                end,
            },
                },
            },
            glows = {
                type = "group",
                name = "Glows",
                order = 2,
                args = {
                    -- Proc Glow Section
                    procGlowHeader = {
                        type = "header",
                        name = "Action Bar Proc Glow Customization",
                        order = 10,
                    },
                    procGlowEnabled = {
                        type = "toggle",
                        name = "Enable Proc Glow Customization",
                        desc = "Customize the spell activation overlay and proc glow effects on action bars using LibCustomGlow",
                        width = "full",
                        order = 11,
                        get = function()
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            return procGlow and procGlow.enabled or false
                        end,
                        set = function(_, val)
                            if not NephUI.db.profile.actionBars.procGlow then
                                NephUI.db.profile.actionBars.procGlow = {}
                            end
                            NephUI.db.profile.actionBars.procGlow.enabled = val
                                    if NephUI.ActionBarGlow and NephUI.ActionBarGlow.RefreshAll then
                                        NephUI.ActionBarGlow:RefreshAll()
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
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            return (procGlow and procGlow.glowType) or "Pixel Glow"
                        end,
                        set = function(_, val)
                            if not NephUI.db.profile.actionBars.procGlow then
                                NephUI.db.profile.actionBars.procGlow = {}
                            end
                            NephUI.db.profile.actionBars.procGlow.glowType = val
                                    if NephUI.ActionBarGlow and NephUI.ActionBarGlow.RefreshAll then
                                        NephUI.ActionBarGlow:RefreshAll()
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
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            local color = (procGlow and procGlow.loopColor) or {0.95, 0.95, 0.32, 1}
                            return color[1], color[2], color[3], color[4] or 1
                        end,
                        set = function(_, r, g, b, a)
                            if not NephUI.db.profile.actionBars.procGlow then
                                NephUI.db.profile.actionBars.procGlow = {}
                            end
                            NephUI.db.profile.actionBars.procGlow.loopColor = {r, g, b, a or 1}
                                    if NephUI.ActionBarGlow and NephUI.ActionBarGlow.RefreshAll then
                                        NephUI.ActionBarGlow:RefreshAll()
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
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            return not (procGlow and procGlow.glowType and procGlow.glowType ~= "Action Button Glow" and procGlow.glowType ~= "Proc Glow")
                        end,
                        get = function()
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            return procGlow and procGlow.lcgLines or 14
                        end,
                        set = function(_, val)
                            if not NephUI.db.profile.actionBars.procGlow then
                                NephUI.db.profile.actionBars.procGlow = {}
                            end
                            NephUI.db.profile.actionBars.procGlow.lcgLines = val
                                    if NephUI.ActionBarGlow and NephUI.ActionBarGlow.RefreshAll then
                                        NephUI.ActionBarGlow:RefreshAll()
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
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            return procGlow and procGlow.lcgFrequency or 0.25
                        end,
                        set = function(_, val)
                            if not NephUI.db.profile.actionBars.procGlow then
                                NephUI.db.profile.actionBars.procGlow = {}
                            end
                            NephUI.db.profile.actionBars.procGlow.lcgFrequency = val
                                    if NephUI.ActionBarGlow and NephUI.ActionBarGlow.RefreshAll then
                                        NephUI.ActionBarGlow:RefreshAll()
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
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            return not (procGlow and procGlow.glowType == "Pixel Glow")
                        end,
                        get = function()
                            local procGlow = NephUI.db.profile.actionBars.procGlow
                            return procGlow and procGlow.lcgThickness or 2
                        end,
                        set = function(_, val)
                            if not NephUI.db.profile.actionBars.procGlow then
                                NephUI.db.profile.actionBars.procGlow = {}
                            end
                            NephUI.db.profile.actionBars.procGlow.lcgThickness = val
                                    if NephUI.ActionBarGlow and NephUI.ActionBarGlow.RefreshAll then
                                        NephUI.ActionBarGlow:RefreshAll()
                                    end
                        end,
                    },
                },
            },
        },
    }
end

ns.CreateActionBarOptions = CreateActionBarOptions
