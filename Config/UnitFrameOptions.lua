local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

-- Anchor points for positioning
local AnchorPoints = {
    ["TOPLEFT"] = "Top Left",
    ["TOP"] = "Top",
    ["TOPRIGHT"] = "Top Right",
    ["LEFT"] = "Left",
    ["CENTER"] = "Center",
    ["RIGHT"] = "Right",
    ["BOTTOMLEFT"] = "Bottom Left",
    ["BOTTOM"] = "Bottom",
    ["BOTTOMRIGHT"] = "Bottom Right",
}

-- Helper to get unit frame DB
local function GetUnitDB(unit)
    local dbUnit = unit
    if unit:match("^boss(%d+)$") then dbUnit = "boss" end
    
    if not NephUI.db.profile.unitFrames then
        NephUI.db.profile.unitFrames = {}
    end
    if not NephUI.db.profile.unitFrames[dbUnit] then
        NephUI.db.profile.unitFrames[dbUnit] = {}
    end
    return NephUI.db.profile.unitFrames[dbUnit]
end

-- Helper to update unit frame
local function UpdateUnitFrame(unit)
    if NephUI.UnitFrames then
        -- Resolve media first in case textures changed
        NephUI.UnitFrames:ResolveMedia()
        
        -- For boss frames, update all boss frames (boss1-boss8)
        if unit == "boss" then
            for i = 1, 8 do
                NephUI.UnitFrames:UpdateUnitFrame("boss" .. i)
            end
        else
            -- Update the specific unit frame
            NephUI.UnitFrames:UpdateUnitFrame(unit)
        end
    end
end

-- Helper to get current frame position in UIParent coordinates
local function GetFramePositionInUIParent(frame)
    if not frame then return nil end
    
    -- Get the current anchor point
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    if not point then return nil end
    
    -- If already anchored to UIParent, return the offset
    if relativeTo == UIParent then
        return point, relativePoint, xOfs, yOfs
    end
    
    -- Convert to UIParent coordinates
    local frameX, frameY = frame:GetCenter()
    if not frameX or not frameY then return nil end
    
    local uiX, uiY = UIParent:GetCenter()
    if not uiX or not uiY then return nil end
    
    -- Calculate offset from UIParent center
    local offsetX = frameX - uiX
    local offsetY = frameY - uiY
    
    return "CENTER", "CENTER", offsetX, offsetY
end

-- Boss-specific tab functions
local function CreateBossFrameTab()
    local DB = GetUnitDB("boss")
    if not DB.Frame then DB.Frame = {} end

    return {
        type = "group",
        name = "Frame",
        order = 2,
        args = {
            -- Size Section
            sizeHeader = {
                type = "header",
                name = "Size",
                order = 10,
            },
            width = {
                type = "range",
                name = "Width",
                desc = "Frame width",
                order = 11,
                width = "full",
                min = 50, max = 1000, step = 1,
                get = function()
                    return DB.Frame.Width or 244
                end,
                set = function(_, val)
                    DB.Frame.Width = val
                    UpdateUnitFrame("boss")
                    -- Reposition all boss frames when size changes
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
            height = {
                type = "range",
                name = "Height",
                desc = "Frame height",
                order = 12,
                width = "full",
                min = 10, max = 500, step = 1,
                get = function()
                    return DB.Frame.Height or 42
                end,
                set = function(_, val)
                    DB.Frame.Height = val
                    UpdateUnitFrame("boss")
                    -- Reposition all boss frames when size changes
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },

            -- Positioning Section
            positioningHeader = {
                type = "header",
                name = "Positioning",
                order = 15,
            },
            xPosition = {
                type = "range",
                name = "X Position",
                desc = "Horizontal position of boss frames",
                order = 16,
                width = "full",
                min = -1000, max = 1000, step = 1,
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.OffsetX) or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.OffsetX = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
            yPosition = {
                type = "range",
                name = "Y Position",
                desc = "Vertical position of boss frames",
                order = 17,
                width = "full",
                min = -1000, max = 1000, step = 1,
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.OffsetY) or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.OffsetY = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
            growthDirection = {
                type = "select",
                name = "Growth Direction",
                desc = "Direction boss frames grow when multiple are shown",
                order = 18,
                width = "full",
                values = {
                    ["UP"] = "Up",
                    ["DOWN"] = "Down",
                },
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.GrowthDirection) or "UP"
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.GrowthDirection = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
            spacing = {
                type = "range",
                name = "Spacing",
                desc = "Vertical spacing between boss frames",
                order = 19,
                width = "full",
                min = 0, max = 100, step = 1,
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.Spacing) or 26
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.Spacing = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
        },
    }
end

local function CreateBossPositioningTab()
    return {
        type = "group",
        name = "Positioning",
        order = 5,
        args = {
            header = {
                type = "header",
                name = "Boss Frame Positioning",
                order = 1,
            },
            xPosition = {
                type = "range",
                name = "X Position",
                desc = "Horizontal position of boss frames",
                order = 2,
                width = "full",
                min = -1000, max = 1000, step = 1,
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.OffsetX) or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.OffsetX = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
            yPosition = {
                type = "range",
                name = "Y Position",
                desc = "Vertical position of boss frames",
                order = 3,
                width = "full",
                min = -1000, max = 1000, step = 1,
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.OffsetY) or 0
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.OffsetY = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
            growthDirection = {
                type = "select",
                name = "Growth Direction",
                desc = "Direction boss frames grow when multiple are shown",
                order = 4,
                width = "full",
                values = {
                    ["UP"] = "Up",
                    ["DOWN"] = "Down",
                },
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.GrowthDirection) or "DOWN"
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.GrowthDirection = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
            spacing = {
                type = "range",
                name = "Spacing",
                desc = "Vertical spacing between boss frames",
                order = 5,
                width = "full",
                min = 0, max = 100, step = 1,
                get = function()
                    local db = NephUI.db.profile.unitFrames
                    return (db.boss and db.boss.Spacing) or 26
                end,
                set = function(_, val)
                    local db = NephUI.db.profile.unitFrames
                    if not db.boss then db.boss = {} end
                    db.boss.Spacing = val
                    if NephUI.UnitFrames and NephUI.UnitFrames.LayoutBossFrames then
                        NephUI.UnitFrames:LayoutBossFrames()
                    end
                end,
            },
        },
    }
end

-- Helper to create unit frame options per frame
local function CreateUnitFrameOptions(unit, displayName, order)
    local unitKey = unit:gsub("^%l", string.upper) -- Capitalize first letter
    local hasPowerBar = (unit == "player" or unit == "target" or unit == "focus" or unit == "boss")
    
    -- Helper to create General tab (includes enable toggle and color options)
    local function CreateGeneralTab()
        local DB = GetUnitDB(unit)
        if not DB.Frame then DB.Frame = {} end
        
        return {
            type = "group",
            name = "General",
            order = 1,
            args = {
                header = {
                    type = "header",
                    name = displayName .. " Settings",
                    order = 1,
                },
                enabled = {
                    type = "toggle",
                    name = "Enable " .. displayName,
                    desc = "Show/hide this unit frame",
                    order = 2,
                    width = "full",
                    get = function()
                        return DB.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    order = 3,
                },

                -- Boss preview toggle (only for boss frames)
                previewMode = unit == "boss" and {
                    type = "toggle",
                    name = "Preview Mode",
                    desc = "Show boss frames with fake data for testing layout and appearance",
                    order = 4,
                    width = "full",
                    get = function()
                        return NephUI.UnitFrames and NephUI.UnitFrames.BossPreviewMode or false
                    end,
                    set = function(_, val)
                        if NephUI.UnitFrames then
                            if val then
                                NephUI.UnitFrames:ShowBossFramesPreview()
                            else
                                NephUI.UnitFrames:HideBossFramesPreview()
                            end
                        end
                    end,
                } or nil,

                -- Color Options
                colorsHeader = {
                    type = "header",
                    name = "Colors",
                    order = 10,
                },
                useClassColor = {
                    type = "toggle",
                    name = "Use Class Color",
                    desc = "Color health bar by class color",
                    order = 11,
                    width = "normal",
                    get = function()
                        return DB.Frame.ClassColor or false
                    end,
                    set = function(_, val)
                        DB.Frame.ClassColor = val
                        UpdateUnitFrame(unit)
                    end,
                },
                fgColor = {
                    type = "color",
                    name = "Foreground Color",
                    desc = "Health bar foreground color",
                    order = 12,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                        local c = DB.Frame.FGColor or {26/255, 26/255, 26/255, 1.0}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        DB.Frame.FGColor = {r, g, b, a or 1}
                        UpdateUnitFrame(unit)
                    end,
                },
                useReactionColor = {
                    type = "toggle",
                    name = "Use Reaction Color",
                    desc = "Color health bar by reaction (hostile/neutral/friendly)",
                    order = 13,
                    width = "normal",
                    get = function()
                        return DB.Frame.ReactionColor or false
                    end,
                    set = function(_, val)
                        DB.Frame.ReactionColor = val
                        UpdateUnitFrame(unit)
                    end,
                },
                bgColor = {
                    type = "color",
                    name = "Background Color",
                    desc = "Health bar background color",
                    order = 14,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                        local c = DB.Frame.BGColor or {128/255, 128/255, 128/255, 1.0}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        DB.Frame.BGColor = {r, g, b, a or 1}
                        UpdateUnitFrame(unit)
                    end,
                },
            },
        }
    end
    
    -- Helper to create Frame tab
    local function CreateFrameTab()
        local DB = GetUnitDB(unit)
        if not DB.Frame then DB.Frame = {} end
        
        return {
            type = "group",
            name = "Frame",
            order = 2,
            args = {
                -- Size Section
                sizeHeader = {
                    type = "header",
                    name = "Size",
                    order = 10,
                },
                width = {
                    type = "range",
                    name = "Width",
                    desc = "Frame width",
                    order = 11,
                    width = "full",
                    min = 50, max = 1000, step = 1,
                    get = function()
                        return DB.Frame.Width or 244
                    end,
                    set = function(_, val)
                        DB.Frame.Width = val
                        UpdateUnitFrame(unit)
                    end,
                },
                height = {
                    type = "range",
                    name = "Height",
                    desc = "Frame height",
                    order = 12,
                    width = "full",
                    min = 10, max = 500, step = 1,
                    get = function()
                        return DB.Frame.Height or 42
                    end,
                    set = function(_, val)
                        DB.Frame.Height = val
                        UpdateUnitFrame(unit)
                    end,
                },

                -- Anchoring Section
                anchorHeader = unit ~= "boss" and {
                    type = "header",
                    name = "Anchoring",
                    order = 20,
                } or nil,
                anchorToCooldown = unit ~= "boss" and {
                    type = "toggle",
                    name = "Anchor to Essential Cooldown Viewer",
                    desc = "Automatically anchor this frame to EssentialCooldownViewer. Only available for Player and Target frames.",
                    order = 21,
                    width = "full",
                    get = function()
                        return DB.Frame.AnchorToCooldown or false
                    end,
                    set = function(_, val)
                        -- Get the current frame
                        local frameName = (unit == "player") and "NephUI_Player" or "NephUI_Target"
                        local unitFrame = _G[frameName]
                        
                        if unitFrame then
                            -- Get current position in UIParent coordinates before toggling
                            local point, relativePoint, xOfs, yOfs = GetFramePositionInUIParent(unitFrame)
                            
                            if point and xOfs and yOfs then
                                if val then
                                    -- Toggling ON: Reset offsets to 0,0 for default positioning
                                    DB.Frame.OffsetX = 0
                                    DB.Frame.OffsetY = 0
                                else
                                    -- Toggling OFF: Save current position as the new anchor settings
                                    -- Use UIParent as the anchor frame and save current position
                                    -- If AnchorFrame was EssentialCooldownViewer, reset to UIParent
                                    if DB.Frame.AnchorFrame == "EssentialCooldownViewer" then
                                        DB.Frame.AnchorFrame = "UIParent"
                                    else
                                        DB.Frame.AnchorFrame = DB.Frame.AnchorFrame or "UIParent"
                                    end
                                    DB.Frame.AnchorFrom = point
                                    DB.Frame.AnchorTo = relativePoint or "CENTER"
                                    DB.Frame.OffsetX = xOfs
                                    DB.Frame.OffsetY = yOfs
                                end
                            end
                        end
                        
                        DB.Frame.AnchorToCooldown = val
                        
                        -- Update anchor frame based on toggle
                        if val then
                            DB.Frame.AnchorFrame = "EssentialCooldownViewer"
                        end
                        
                        UpdateUnitFrame(unit)
                        -- Re-hook anchor frames after change
                        if NephUI.UnitFrames then
                            C_Timer.After(0.1, function()
                                NephUI.UnitFrames:HookAnchorFrames()
                            end)
                        end
                    end,
                },
                anchorFrame = unit ~= "boss" and {
                    type = "input",
                    name = "Anchor Frame",
                    desc = "Frame name to anchor to (e.g., EssentialCooldownViewer, NephUI_Player, NephUI_Target, UIParent)",
                    order = 22,
                    width = "full",
                    get = function()
                        return DB.Frame.AnchorFrame or "UIParent"
                    end,
                    set = function(_, val)
                        DB.Frame.AnchorFrame = val
                        UpdateUnitFrame(unit)
                        -- Re-hook anchor frames after change
                        if NephUI.UnitFrames then
                            C_Timer.After(0.1, function()
                                NephUI.UnitFrames:HookAnchorFrames()
                            end)
                        end
                    end,
                } or nil,
                anchorFrom = unit ~= "boss" and {
                    type = "select",
                    name = "Anchor From",
                    desc = "Anchor point on the frame",
                    order = 23,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.Frame.AnchorFrom or "CENTER"
                    end,
                    set = function(_, val)
                        DB.Frame.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                } or nil,
                anchorTo = unit ~= "boss" and {
                    type = "select",
                    name = "Anchor To",
                    desc = "Anchor point on parent",
                    order = 24,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.Frame.AnchorTo or "CENTER"
                    end,
                    set = function(_, val)
                        DB.Frame.AnchorTo = val
                        UpdateUnitFrame(unit)
                    end,
                } or nil,
                offsetX = {
                    type = "range",
                    name = "X Offset",
                    desc = "Horizontal offset from anchor",
                    order = 25,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Frame.OffsetX or 0
                    end,
                    set = function(_, val)
                        DB.Frame.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                offsetY = {
                    type = "range",
                    name = "Y Offset",
                    desc = "Vertical offset from anchor",
                    order = 26,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Frame.OffsetY or 0
                    end,
                    set = function(_, val)
                        DB.Frame.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
            },
        }
    end
    
    -- Helper to create Power Bar tab
    local function CreatePowerBarTab()
        if not hasPowerBar then return nil end
        local DB = GetUnitDB(unit)
        if not DB.PowerBar then DB.PowerBar = {} end
        
        return {
            type = "group",
            name = "Power Bar",
            order = 3,
            args = {
                enabled = {
                    type = "toggle",
                    name = "Enable Power Bar",
                    desc = "Show the power bar (mana/energy/rage)",
                    order = 1,
                    width = "full",
                    get = function()
                        return DB.PowerBar.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.PowerBar.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                height = {
                    type = "range",
                    name = "Power Bar Height",
                    desc = "Height of the power bar",
                    order = 2,
                    width = "full",
                    min = 1, max = 100, step = 1,
                    get = function()
                        return DB.PowerBar.Height or 3
                    end,
                    set = function(_, val)
                        DB.PowerBar.Height = val
                        UpdateUnitFrame(unit)
                    end,
                },
                colorByType = {
                    type = "toggle",
                    name = "Color By Power Type",
                    desc = "Use default colors for power type (mana=blue, energy=yellow, etc.)",
                    order = 3,
                    width = "normal",
                    get = function()
                        return DB.PowerBar.ColorByType ~= false
                    end,
                    set = function(_, val)
                        DB.PowerBar.ColorByType = val
                        UpdateUnitFrame(unit)
                    end,
                },
                fgColor = {
                    type = "color",
                    name = "Foreground Color",
                    desc = "Power bar foreground color",
                    order = 4,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                        local c = DB.PowerBar.FGColor or {8/255, 8/255, 8/255, 0.8}
                        return c[1], c[2], c[3], c[4] or 0.8
                    end,
                    set = function(_, r, g, b, a)
                        DB.PowerBar.FGColor = {r, g, b, a or 0.8}
                        UpdateUnitFrame(unit)
                    end,
                },
                colorBackgroundByType = {
                    type = "toggle",
                    name = "Color Background By Power Type",
                    desc = "Use power type color for background",
                    order = 5,
                    width = "normal",
                    get = function()
                        return DB.PowerBar.ColorBackgroundByType or false
                    end,
                    set = function(_, val)
                        DB.PowerBar.ColorBackgroundByType = val
                        UpdateUnitFrame(unit)
                    end,
                },
                bgColor = {
                    type = "color",
                    name = "Background Color",
                    desc = "Power bar background color",
                    order = 6,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                        local c = DB.PowerBar.BGColor or {128/255, 128/255, 128/255, 1}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        DB.PowerBar.BGColor = {r, g, b, a or 1}
                        UpdateUnitFrame(unit)
                    end,
                },
            },
        }
    end
    
    -- Helper to create Texts tab
    local function CreateTextsTab()
        local DB = GetUnitDB(unit)
        if not DB.Tags then DB.Tags = {} end
        if not DB.Tags.Name then DB.Tags.Name = {} end
        if not DB.Tags.Health then DB.Tags.Health = {} end
        
        return {
            type = "group",
            name = "Texts",
            order = 4,
            args = {
                -- Name Tag
                nameHeader = {
                    type = "header",
                    name = "Name Tag",
                    order = 10,
                },
                nameEnabled = {
                    type = "toggle",
                    name = "Enable Name",
                    desc = "Show unit name",
                    order = 11,
                    width = "full",
                    get = function()
                        return DB.Tags.Name.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.Tags.Name.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                nameColorByStatus = {
                    type = "toggle",
                    name = "Color By Status",
                    desc = "Color name by class (player) or reaction (NPC)",
                    order = 12,
                    width = "normal",
                    get = function()
                        return DB.Tags.Name.ColorByStatus or false
                    end,
                    set = function(_, val)
                        DB.Tags.Name.ColorByStatus = val
                        UpdateUnitFrame(unit)
                    end,
                },
                nameColor = {
                    type = "color",
                    name = "Name Color",
                    desc = "Custom name text color",
                    order = 13,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                        local c = DB.Tags.Name.Color or {1, 1, 1, 1}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        DB.Tags.Name.Color = {r, g, b, a or 1}
                        UpdateUnitFrame(unit)
                    end,
                },
                nameAnchorFrom = {
                    type = "select",
                    name = "Name Anchor From",
                    order = 14,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.Tags.Name.AnchorFrom or "LEFT"
                    end,
                    set = function(_, val)
                        DB.Tags.Name.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                nameAnchorTo = {
                    type = "select",
                    name = "Name Anchor To",
                    order = 15,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.Tags.Name.AnchorTo or "LEFT"
                    end,
                    set = function(_, val)
                        DB.Tags.Name.AnchorTo = val
                        UpdateUnitFrame(unit)
                    end,
                },
                nameOffsetX = {
                    type = "range",
                    name = "Name Offset X",
                    order = 16,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Tags.Name.OffsetX or 3
                    end,
                    set = function(_, val)
                        DB.Tags.Name.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                nameOffsetY = {
                    type = "range",
                    name = "Name Offset Y",
                    order = 17,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Tags.Name.OffsetY or 0
                    end,
                    set = function(_, val)
                        DB.Tags.Name.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                nameMaxLength = {
                    type = "range",
                    name = "Max Name Length",
                    desc = "Clamp displayed name length (0 = no limit)",
                    order = 17.5,
                    width = "normal",
                    min = 0, max = 40, step = 1,
                    get = function()
                        return DB.Tags.Name.MaxLength or 0
                    end,
                    set = function(_, val)
                        DB.Tags.Name.MaxLength = val
                        UpdateUnitFrame(unit)
                    end,
                },
                nameFontSize = {
                    type = "range",
                    name = "Name Font Size",
                    order = 18,
                    width = "full",
                    min = 6, max = 72, step = 1,
                    get = function()
                        return DB.Tags.Name.FontSize or 12
                    end,
                    set = function(_, val)
                        DB.Tags.Name.FontSize = val
                        UpdateUnitFrame(unit)
                    end,
                },
                inlineTargetTarget = (unit == "target") and {
                    type = "toggle",
                    name = "Show Target of Target Inline",
                    desc = "Append target of target next to the target name without hiding the Target Target frame",
                    order = 19,
                    width = "full",
                    get = function()
                        return DB.Tags.Name.InlineTargetTarget or false
                    end,
                    set = function(_, val)
                        DB.Tags.Name.InlineTargetTarget = val
                        UpdateUnitFrame(unit)
                        UpdateUnitFrame("targettarget")
                    end,
                } or nil,
                inlineTargetTargetSeparator = (unit == "target") and {
                    type = "input",
                    name = "Inline Separator",
                    desc = "Separator shown between target and its target when inline is enabled",
                    order = 19.5,
                    width = "half",
                    get = function()
                        return DB.Tags.Name.TargetTargetSeparator or " » "
                    end,
                    set = function(_, val)
                        if val == nil or val == "" then
                            DB.Tags.Name.TargetTargetSeparator = " » "
                        else
                            DB.Tags.Name.TargetTargetSeparator = val
                        end
                        UpdateUnitFrame(unit)
                    end,
                } or nil,
                -- Health Tag
                healthHeader = {
                    type = "header",
                    name = "Health Tag",
                    order = 20,
                },
                healthEnabled = {
                    type = "toggle",
                    name = "Enable Health Tag",
                    desc = "Show health text",
                    order = 21,
                    width = "full",
                    get = function()
                        return DB.Tags.Health.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.Tags.Health.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                healthDisplayStyle = {
                    type = "select",
                    name = "Health Display Style",
                    desc = "Choose how health text is displayed",
                    order = 22,
                    width = "normal",
                    values = {
                        both = "Current amount - Percent amount",
                        both_reverse = "Percent amount - Current amount",
                        current = "Current amount ONLY",
                        percent = "Percent amount ONLY",
                    },
                    get = function()
                        local style = DB.Tags.Health.DisplayStyle
                        -- Migrate old DisplayPercent setting
                        if style == nil then
                            if DB.Tags.Health.DisplayPercent then
                                return "both"
                            else
                                return "current"
                            end
                        end
                        return style or "current"
                    end,
                    set = function(_, val)
                        DB.Tags.Health.DisplayStyle = val
                        -- Keep DisplayPercent for backwards compatibility, but it's now controlled by DisplayStyle
                        DB.Tags.Health.DisplayPercent = (val == "both" or val == "both_reverse" or val == "percent")
                        UpdateUnitFrame(unit)
                    end,
                },
                healthSeparator = {
                    type = "input",
                    name = "Health Separator",
                    desc = "Text to use as separator between health numbers (e.g., ' - ', ' / ', ' | '). Only used when Display Style shows both current and percent.",
                    order = 22.5,
                    width = "normal",
                    get = function()
                        return DB.Tags.Health.Separator or " - "
                    end,
                    set = function(_, val)
                        DB.Tags.Health.Separator = val
                        UpdateUnitFrame(unit)
                    end,
                },
                healthColor = {
                    type = "color",
                    name = "Health Color",
                    desc = "Health text color",
                    order = 23,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                        local c = DB.Tags.Health.Color or {1, 1, 1, 1}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        DB.Tags.Health.Color = {r, g, b, a or 1}
                        UpdateUnitFrame(unit)
                    end,
                },
                healthAnchorFrom = {
                    type = "select",
                    name = "Health Anchor From",
                    order = 24,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.Tags.Health.AnchorFrom or "RIGHT"
                    end,
                    set = function(_, val)
                        DB.Tags.Health.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                healthAnchorTo = {
                    type = "select",
                    name = "Health Anchor To",
                    order = 25,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.Tags.Health.AnchorTo or "RIGHT"
                    end,
                    set = function(_, val)
                        DB.Tags.Health.AnchorTo = val
                        UpdateUnitFrame(unit)
                    end,
                },
                healthOffsetX = {
                    type = "range",
                    name = "Health Offset X",
                    order = 26,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Tags.Health.OffsetX or -3
                    end,
                    set = function(_, val)
                        DB.Tags.Health.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                healthOffsetY = {
                    type = "range",
                    name = "Health Offset Y",
                    order = 27,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Tags.Health.OffsetY or 0
                    end,
                    set = function(_, val)
                        DB.Tags.Health.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                healthFontSize = {
                    type = "range",
                    name = "Health Font Size",
                    order = 28,
                    width = "full",
                    min = 6, max = 72, step = 1,
                    get = function()
                        return DB.Tags.Health.FontSize or 12
                    end,
                    set = function(_, val)
                        DB.Tags.Health.FontSize = val
                        UpdateUnitFrame(unit)
                    end,
                },
                -- Power Text (for player, target, focus, boss)
                powerHeader = {
                    type = "header",
                    name = "Power Text",
                    order = 30,
                },
                powerEnabled = {
                    type = "toggle",
                    name = "Enable Power Text",
                    desc = "Show power/resource text (mana, energy, etc.)",
                    order = 31,
                    width = "full",
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        return DB.Tags.Power.Enabled ~= false
                    end,
                    set = function(_, val)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                powerDisplayStyle = {
                    type = "select",
                    name = "Power Display Style",
                    desc = "Choose how power text is displayed",
                    order = 31.5,
                    width = "normal",
                    values = {
                        current = "Current Only",
                        both = "Current and Max",
                    },
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        return DB.Tags.Power.DisplayStyle or "both"
                    end,
                    set = function(_, val)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.DisplayStyle = val
                        UpdateUnitFrame(unit)
                    end,
                },
                powerColor = {
                    type = "color",
                    name = "Power Color",
                    desc = "Power text color",
                    order = 32,
                    width = "normal",
                    hasAlpha = true,
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        local c = DB.Tags.Power.Color or DB.Tags.Health.Color or {1, 1, 1, 1}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.Color = {r, g, b, a or 1}
                        UpdateUnitFrame(unit)
                    end,
                },
                powerAnchorFrom = {
                    type = "select",
                    name = "Power Anchor From",
                    order = 33,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        return DB.Tags.Power.AnchorFrom or "BOTTOMRIGHT"
                    end,
                    set = function(_, val)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                powerAnchorTo = {
                    type = "select",
                    name = "Power Anchor To",
                    order = 34,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        return DB.Tags.Power.AnchorTo or "BOTTOMRIGHT"
                    end,
                    set = function(_, val)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.AnchorTo = val
                        UpdateUnitFrame(unit)
                    end,
                },
                powerOffsetX = {
                    type = "range",
                    name = "Power Offset X",
                    order = 35,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        return DB.Tags.Power.OffsetX or -4
                    end,
                    set = function(_, val)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                powerOffsetY = {
                    type = "range",
                    name = "Power Offset Y",
                    order = 36,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        return DB.Tags.Power.OffsetY or 4
                    end,
                    set = function(_, val)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                powerFontSize = {
                    type = "range",
                    name = "Power Font Size",
                    order = 37,
                    width = "full",
                    min = 6, max = 72, step = 1,
                    get = function()
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        return DB.Tags.Power.FontSize or DB.Tags.Health.FontSize or 12
                    end,
                    set = function(_, val)
                        if not DB.Tags then DB.Tags = {} end
                        if not DB.Tags.Power then DB.Tags.Power = {} end
                        DB.Tags.Power.FontSize = val
                        UpdateUnitFrame(unit)
                    end,
                },
            },
        }
    end
    
    -- Helper to create Debuffs tab (only for target)
    local function CreateDebuffsTab()
        local DB = GetUnitDB(unit)
        if not DB.Auras then DB.Auras = {} end
        if not DB.Auras.Debuffs then DB.Auras.Debuffs = {} end

        return {
            type = "group",
            name = "Debuffs",
            order = 5,
            args = {
                header = {
                    type = "header",
                    name = displayName .. " Debuff Display Settings",
                    order = 1,
                },
                enabled = {
                    type = "toggle",
                    name = "Enable Debuffs",
                    desc = "Display harmful debuffs applied by you",
                    order = 2,
                    width = "full",
                    get = function()
                        return DB.Auras.Debuffs.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                preview = {
                    type = "toggle",
                    name = "Preview Debuffs",
                    desc = "Show fake debuff icons to preview layout",
                    order = 3,
                    width = "full",
                    get = function()
                        return DB.Auras.Debuffs.Preview or false
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.Preview = val
                        UpdateUnitFrame(unit)
                    end,
                },
                anchorPoint = {
                    type = "select",
                    name = "Anchor Point",
                    desc = "Point on the frame where debuffs should anchor",
                    order = 4,
                    width = "normal",
                    values = {
                        TOPLEFT = "Top Left",
                        TOPRIGHT = "Top Right",
                        BOTTOMLEFT = "Bottom Left",
                        BOTTOMRIGHT = "Bottom Right",
                        TOP = "Top",
                        BOTTOM = "Bottom",
                        LEFT = "Left",
                        RIGHT = "Right",
                        CENTER = "Center",
                    },
                    get = function()
                        return DB.Auras.Debuffs.AnchorPoint or "TOPLEFT"
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.AnchorPoint = val
                        UpdateUnitFrame(unit)
                    end,
                },
                growthDirection = {
                    type = "select",
                    name = "Growth Direction",
                    desc = "Direction debuff icons grow within each row",
                    order = 5,
                    width = "normal",
                    values = {
                        RIGHT = "Right",
                        LEFT = "Left",
                        DOWN = "Down",
                        UP = "Up",
                    },
                    get = function()
                        return DB.Auras.Debuffs.GrowthDirection or "RIGHT"
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.GrowthDirection = val
                        UpdateUnitFrame(unit)
                    end,
                },
                rowGrowthDirection = {
                    type = "select",
                    name = "Row Growth Direction",
                    desc = "Direction rows grow relative to each other",
                    order = 6,
                    width = "normal",
                    values = {
                        DOWN = "Down",
                        UP = "Up",
                        RIGHT = "Right",
                        LEFT = "Left",
                    },
                    get = function()
                        return DB.Auras.Debuffs.RowGrowthDirection or "DOWN"
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.RowGrowthDirection = val
                        UpdateUnitFrame(unit)
                    end,
                },
                iconSize = {
                    type = "range",
                    name = "Icon Size",
                    desc = "Size of individual debuff icons",
                    order = 7,
                    width = "normal",
                    min = 12, max = 64, step = 1,
                    get = function()
                        return DB.Auras.Debuffs.IconSize or 44
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.IconSize = val
                        UpdateUnitFrame(unit)
                    end,
                },
                iconsPerRow = {
                    type = "range",
                    name = "Icons Per Row",
                    desc = "Number of debuff icons to display per row",
                    order = 8,
                    width = "normal",
                    min = 1, max = 20, step = 1,
                    get = function()
                        return DB.Auras.Debuffs.IconsPerRow or 6
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.IconsPerRow = val
                        UpdateUnitFrame(unit)
                    end,
                },
                spacing = {
                    type = "range",
                    name = "Debuff Spacing",
                    desc = "Spacing between debuff icons",
                    order = 9,
                    width = "normal",
                    min = 0, max = 50, step = 1,
                    get = function()
                        return DB.Auras.Debuffs.Spacing or 2
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.Spacing = val
                        UpdateUnitFrame(unit)
                    end,
                },
                offsetX = {
                    type = "range",
                    name = "Debuff Offset X",
                    desc = "Horizontal offset from frame",
                    order = 10,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Auras.Debuffs.OffsetX or 0
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                offsetY = {
                    type = "range",
                    name = "Debuff Offset Y",
                    desc = "Vertical offset from frame top",
                    order = 11,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Auras.Debuffs.OffsetY or 2
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                alpha = {
                    type = "range",
                    name = "Debuff Alpha",
                    desc = "Transparency of debuff icons",
                    order = 12,
                    width = "full",
                    min = 0, max = 1, step = 0.1,
                    get = function()
                        return DB.Auras.Debuffs.Alpha or 1
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.Alpha = val
                        UpdateUnitFrame(unit)
                    end,
                },
                spacerCooldown = {
                    type = "description",
                    name = " ",
                    order = 13,
                },
                cooldownTextHeader = {
                    type = "header",
                    name = "Cooldown Text",
                    order = 14,
                },
                cooldownFontSize = {
                    type = "range",
                    name = "Cooldown Font Size",
                    desc = "Font size for cooldown countdown text on debuff icons",
                    order = 15,
                    width = "full",
                    min = 8, max = 48, step = 1,
                    get = function()
                        return DB.Auras.Debuffs.cooldownFontSize or
                               (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownFontSize) or 18
                    end,
                    set = function(_, val)
                        DB.Auras.Debuffs.cooldownFontSize = val
                        -- Refresh all cooldown fonts
                        if NephUI.ApplyGlobalFont then
                            NephUI:ApplyGlobalFont()
                        end
                        -- Force refresh unit frame auras and their cooldowns
                        local unitFrameName = (unit == "player") and "NephUI_Player" or (unit == "focus") and "NephUI_Focus" or "NephUI_Target"
                        local unitFrame = _G[unitFrameName]
                        if unitFrame then
                            UpdateUnitFrame(unit)
                            -- Refresh existing cooldown frames
                            if unitFrame.debuffIcons then
                                for _, icon in ipairs(unitFrame.debuffIcons) do
                                    if icon and icon.cooldown then
                                        -- Trigger cooldown font refresh
                                        if icon.cooldown._nephui_fontString then
                                            local debuffSettings = DB.Auras.Debuffs
                                            local fontSize = debuffSettings.cooldownFontSize or
                                                          (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownFontSize) or 18
                                            local textColor = debuffSettings.cooldownTextColor or
                                                           (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                                            local fontPath = NephUI:GetGlobalFont()
                                            if fontPath then
                                                icon.cooldown._nephui_fontString:SetFont(fontPath, fontSize, "OUTLINE")
                                                icon.cooldown._nephui_fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
                                                -- No shadow for target auras, they use outline instead
                                                icon.cooldown._nephui_fontString:SetShadowOffset(0, 0)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end,
                },
                cooldownTextColor = {
                    type = "color",
                    name = "Cooldown Text Color",
                    desc = "Color for cooldown countdown text on debuff icons",
                    order = 16,
                    width = "full",
                    hasAlpha = true,
                    get = function()
                        local c = DB.Auras.Debuffs.cooldownTextColor or
                                 (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        DB.Auras.Debuffs.cooldownTextColor = {r, g, b, a or 1}
                        -- Refresh all cooldown fonts
                        if NephUI.ApplyGlobalFont then
                            NephUI:ApplyGlobalFont()
                        end
                        -- Force refresh unit frame auras and their cooldowns
                        local unitFrameName = (unit == "player") and "NephUI_Player" or (unit == "focus") and "NephUI_Focus" or "NephUI_Target"
                        local unitFrame = _G[unitFrameName]
                        if unitFrame then
                            UpdateUnitFrame(unit)
                            -- Refresh existing cooldown frames
                            if unitFrame.debuffIcons then
                                for _, icon in ipairs(unitFrame.debuffIcons) do
                                    if icon and icon.cooldown then
                                        -- Trigger cooldown font refresh
                                        if icon.cooldown._nephui_fontString then
                                            local debuffSettings = DB.Auras.Debuffs
                                            local fontSize = debuffSettings.cooldownFontSize or
                                                          (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownFontSize) or 18
                                            local textColor = debuffSettings.cooldownTextColor or
                                                           (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                                            local fontPath = NephUI:GetGlobalFont()
                                            if fontPath then
                                                icon.cooldown._nephui_fontString:SetFont(fontPath, fontSize, "OUTLINE")
                                                icon.cooldown._nephui_fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
                                                -- No shadow for target auras, they use outline instead
                                                icon.cooldown._nephui_fontString:SetShadowOffset(0, 0)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end,
                },
            },
        }
    end

    -- Helper to create Buffs tab
    local function CreateBuffsTab()
        local DB = GetUnitDB(unit)
        if not DB.Auras then DB.Auras = {} end
        if not DB.Auras.Buffs then DB.Auras.Buffs = {} end

        return {
            type = "group",
            name = "Buffs",
            order = 4,
            args = {
                header = {
                    type = "header",
                    name = displayName .. " Buff Display Settings",
                    order = 1,
                },
                enabled = {
                    type = "toggle",
                    name = "Enable Buffs",
                    desc = "Display helpful buffs",
                    order = 2,
                    width = "full",
                    get = function()
                        return DB.Auras.Buffs.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                preview = {
                    type = "toggle",
                    name = "Preview Buffs",
                    desc = "Show fake buff icons to preview layout",
                    order = 3,
                    width = "full",
                    get = function()
                        return DB.Auras.Buffs.Preview or false
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.Preview = val
                        UpdateUnitFrame(unit)
                    end,
                },
                anchorPoint = {
                    type = "select",
                    name = "Anchor Point",
                    desc = "Point on the frame where buffs should anchor",
                    order = 4,
                    width = "normal",
                    values = {
                        TOPLEFT = "Top Left",
                        TOPRIGHT = "Top Right",
                        BOTTOMLEFT = "Bottom Left",
                        BOTTOMRIGHT = "Bottom Right",
                        TOP = "Top",
                        BOTTOM = "Bottom",
                        LEFT = "Left",
                        RIGHT = "Right",
                        CENTER = "Center",
                    },
                    get = function()
                        return DB.Auras.Buffs.AnchorPoint or "TOPLEFT"
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.AnchorPoint = val
                        UpdateUnitFrame(unit)
                    end,
                },
                growthDirection = {
                    type = "select",
                    name = "Growth Direction",
                    desc = "Direction buff icons grow within each row",
                    order = 5,
                    width = "normal",
                    values = {
                        RIGHT = "Right",
                        LEFT = "Left",
                        DOWN = "Down",
                        UP = "Up",
                    },
                    get = function()
                        return DB.Auras.Buffs.GrowthDirection or "RIGHT"
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.GrowthDirection = val
                        UpdateUnitFrame(unit)
                    end,
                },
                rowGrowthDirection = {
                    type = "select",
                    name = "Row Growth Direction",
                    desc = "Direction rows grow relative to each other",
                    order = 6,
                    width = "normal",
                    values = {
                        DOWN = "Down",
                        UP = "Up",
                        RIGHT = "Right",
                        LEFT = "Left",
                    },
                    get = function()
                        return DB.Auras.Buffs.RowGrowthDirection or "DOWN"
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.RowGrowthDirection = val
                        UpdateUnitFrame(unit)
                    end,
                },
                iconSize = {
                    type = "range",
                    name = "Icon Size",
                    desc = "Size of individual buff icons",
                    order = 7,
                    width = "normal",
                    min = 12, max = 64, step = 1,
                    get = function()
                        return DB.Auras.Buffs.IconSize or 44
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.IconSize = val
                        UpdateUnitFrame(unit)
                    end,
                },
                iconsPerRow = {
                    type = "range",
                    name = "Icons Per Row",
                    desc = "Number of buff icons to display per row",
                    order = 8,
                    width = "normal",
                    min = 1, max = 20, step = 1,
                    get = function()
                        return DB.Auras.Buffs.IconsPerRow or 6
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.IconsPerRow = val
                        UpdateUnitFrame(unit)
                    end,
                },
                spacing = {
                    type = "range",
                    name = "Buff Spacing",
                    desc = "Spacing between buff icons",
                    order = 9,
                    width = "normal",
                    min = 0, max = 50, step = 1,
                    get = function()
                        return DB.Auras.Buffs.Spacing or 2
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.Spacing = val
                        UpdateUnitFrame(unit)
                    end,
                },
                offsetX = {
                    type = "range",
                    name = "Buff Offset X",
                    desc = "Horizontal offset from frame",
                    order = 10,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Auras.Buffs.OffsetX or 0
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                offsetY = {
                    type = "range",
                    name = "Buff Offset Y",
                    desc = "Vertical offset from frame top",
                    order = 11,
                    width = "normal",
                    min = -1000, max = 1000, step = 1,
                    get = function()
                        return DB.Auras.Buffs.OffsetY or 2
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                alpha = {
                    type = "range",
                    name = "Buff Alpha",
                    desc = "Transparency of buff icons",
                    order = 12,
                    width = "full",
                    min = 0, max = 1, step = 0.1,
                    get = function()
                        return DB.Auras.Buffs.Alpha or 1
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.Alpha = val
                        UpdateUnitFrame(unit)
                    end,
                },
                spacerCooldown = {
                    type = "description",
                    name = " ",
                    order = 13,
                },
                cooldownTextHeader = {
                    type = "header",
                    name = "Cooldown Text",
                    order = 14,
                },
                cooldownFontSize = {
                    type = "range",
                    name = "Cooldown Font Size",
                    desc = "Font size for cooldown countdown text on buff icons",
                    order = 15,
                    width = "full",
                    min = 8, max = 48, step = 1,
                    get = function()
                        return DB.Auras.Buffs.cooldownFontSize or
                               (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownFontSize) or 18
                    end,
                    set = function(_, val)
                        DB.Auras.Buffs.cooldownFontSize = val
                        -- Refresh all cooldown fonts
                        if NephUI.ApplyGlobalFont then
                            NephUI:ApplyGlobalFont()
                        end
                        -- Force refresh unit frame auras and their cooldowns
                        local unitFrameName = (unit == "player") and "NephUI_Player" or (unit == "focus") and "NephUI_Focus" or "NephUI_Target"
                        local unitFrame = _G[unitFrameName]
                        if unitFrame then
                            UpdateUnitFrame(unit)
                            -- Refresh existing cooldown frames
                            if unitFrame.buffIcons then
                                for _, icon in ipairs(unitFrame.buffIcons) do
                                    if icon and icon.cooldown then
                                        -- Trigger cooldown font refresh
                                        if icon.cooldown._nephui_fontString then
                                            local buffSettings = DB.Auras.Buffs
                                            local fontSize = buffSettings.cooldownFontSize or
                                                          (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownFontSize) or 18
                                            local textColor = buffSettings.cooldownTextColor or
                                                           (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                                            local fontPath = NephUI:GetGlobalFont()
                                            if fontPath then
                                                icon.cooldown._nephui_fontString:SetFont(fontPath, fontSize, "OUTLINE")
                                                icon.cooldown._nephui_fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
                                                -- No shadow for target auras, they use outline instead
                                                icon.cooldown._nephui_fontString:SetShadowOffset(0, 0)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end,
                },
                cooldownTextColor = {
                    type = "color",
                    name = "Cooldown Text Color",
                    desc = "Color for cooldown countdown text on buff icons",
                    order = 16,
                    width = "full",
                    hasAlpha = true,
                    get = function()
                        local c = DB.Auras.Buffs.cooldownTextColor or
                                 (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                        return c[1], c[2], c[3], c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        DB.Auras.Buffs.cooldownTextColor = {r, g, b, a or 1}
                        -- Refresh all cooldown fonts
                        if NephUI.ApplyGlobalFont then
                            NephUI:ApplyGlobalFont()
                        end
                        -- Force refresh unit frame auras and their cooldowns
                        local unitFrameName = (unit == "player") and "NephUI_Player" or (unit == "focus") and "NephUI_Focus" or "NephUI_Target"
                        local unitFrame = _G[unitFrameName]
                        if unitFrame then
                            UpdateUnitFrame(unit)
                            -- Refresh existing cooldown frames
                            if unitFrame.buffIcons then
                                for _, icon in ipairs(unitFrame.buffIcons) do
                                    if icon and icon.cooldown then
                                        -- Trigger cooldown font refresh
                                        if icon.cooldown._nephui_fontString then
                                            local buffSettings = DB.Auras.Buffs
                                            local fontSize = buffSettings.cooldownFontSize or
                                                          (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownFontSize) or 18
                                            local textColor = buffSettings.cooldownTextColor or
                                                           (NephUI.db.profile.viewers.general and NephUI.db.profile.viewers.general.cooldownTextColor) or {1, 1, 1, 1}
                                            local fontPath = NephUI:GetGlobalFont()
                                            if fontPath then
                                                icon.cooldown._nephui_fontString:SetFont(fontPath, fontSize, "OUTLINE")
                                                icon.cooldown._nephui_fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
                                                -- No shadow for target auras, they use outline instead
                                                icon.cooldown._nephui_fontString:SetShadowOffset(0, 0)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end,
                },
            },
        }
    end

    -- Helper to create Absorb Bar tab (for player and target)
    local function CreateAbsorbBarTab()
        if unit ~= "player" and unit ~= "target" then return nil end
        local DB = GetUnitDB(unit)
        if not DB.AbsorbBar then DB.AbsorbBar = {} end
        
        return {
            type = "group",
            name = "Absorb Bar",
            order = 4,
            args = {
                texture = {
                    type = "select",
                    name = "Texture",
                    desc = "Texture for the absorb bar",
                    order = 1,
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
                        return DB.AbsorbBar.Texture or "Neph"
                    end,
                    set = function(_, val)
                        DB.AbsorbBar.Texture = val
                        -- Trigger absorb bar texture update
                        local frameName = (unit == "player") and "NephUI_Player" or "NephUI_Target"
                        local unitFrame = _G[frameName]
                        if unitFrame and unitFrame.__nephuiAbsorbBar then
                            local absorbBar = unitFrame.__nephuiAbsorbBar
                            if absorbBar.UpdateTexture then
                                absorbBar.UpdateTexture()
                            end
                        end
                    end,
                },
                color = {
                    type = "color",
                    name = "Color",
                    desc = "Color for the absorb bar",
                    order = 2,
                    width = "full",
                    hasAlpha = true,
                    get = function()
                        local c = DB.AbsorbBar.Color or {0.3, 0.6, 1.0, 0.8}
                        return c[1], c[2], c[3], c[4] or 0.8
                    end,
                    set = function(_, r, g, b, a)
                        DB.AbsorbBar.Color = {r, g, b, a or 0.8}
                        -- Trigger absorb bar color update
                        local frameName = (unit == "player") and "NephUI_Player" or "NephUI_Target"
                        local unitFrame = _G[frameName]
                        if unitFrame and unitFrame.__nephuiAbsorbBar then
                            local absorbBar = unitFrame.__nephuiAbsorbBar
                            if absorbBar.UpdateColor then
                                absorbBar.UpdateColor()
                            end
                        end
                    end,
                },
                anchorMode = {
                    type = "select",
                    name = "Anchor Mode",
                    desc = "Where the absorb bar is anchored",
                    order = 3,
                    width = "full",
                    values = {
                        health = "Attach to Health Texture (covers entire health bar)",
                        healthEnd = "Attach to End of Health Texture (starts where health ends)",
                        frame = "Attach to Unit Frame (visible even at 100% health)",
                    },
                    get = function()
                        return DB.AbsorbBar.AnchorMode or "health"
                    end,
                    set = function(_, val)
                        DB.AbsorbBar.AnchorMode = val
                        -- Trigger absorb bar position update
                        local frameName = (unit == "player") and "NephUI_Player" or "NephUI_Target"
                        local unitFrame = _G[frameName]
                        if unitFrame and unitFrame.__nephuiAbsorbBar then
                            local absorbBar = unitFrame.__nephuiAbsorbBar
                            if absorbBar.UpdatePosition then
                                absorbBar.UpdatePosition()
                            end
                        end
                    end,
                },
                fillDirection = {
                    type = "select",
                    name = "Fill Direction",
                    desc = "Direction the absorb bar fills from",
                    order = 4,
                    width = "full",
                    values = {
                        left = "Left to Right",
                        right = "Right to Left",
                    },
                    get = function()
                        return DB.AbsorbBar.FillDirection or "left"
                    end,
                    set = function(_, val)
                        DB.AbsorbBar.FillDirection = val
                        -- Trigger absorb bar fill direction update
                        local frameName = (unit == "player") and "NephUI_Player" or "NephUI_Target"
                        local unitFrame = _G[frameName]
                        if unitFrame and unitFrame.__nephuiAbsorbBar then
                            local absorbBar = unitFrame.__nephuiAbsorbBar
                            if absorbBar.UpdateFillDirection then
                                absorbBar.UpdateFillDirection()
                            end
                        end
                    end,
                },
            },
        }
    end
    
    -- Helper to create Indicator tab (boss, target, focus frames only)
    local function CreateIndicatorTab()
        if unit ~= "boss" and unit ~= "target" and unit ~= "focus" then return nil end
        local DB = GetUnitDB(unit)
        if not DB.RaidTargetIcon then DB.RaidTargetIcon = {} end
        
        return {
            type = "group",
            name = "Indicator",
            order = 5,
            args = {
                raidMarkerHeader = {
                    type = "header",
                    name = "Raid Marker",
                    order = 10,
                },
                raidMarkerEnabled = {
                    type = "toggle",
                    name = "Enable Raid Marker",
                    desc = "Show raid target marker icon",
                    order = 11,
                    width = "full",
                    get = function()
                        return DB.RaidTargetIcon.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerScale = {
                    type = "range",
                    name = "Raid Marker Scale",
                    desc = "Scale of the raid marker icon",
                    order = 12,
                    width = "full",
                    min = 0.5, max = 2.5, step = 0.1,
                    get = function()
                        return DB.RaidTargetIcon.Scale or 1.0
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.Scale = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerAnchor = {
                    type = "select",
                    name = "Raid Marker Position",
                    desc = "Anchor point for the raid marker",
                    order = 13,
                    width = "full",
                    values = AnchorPoints,
                    get = function()
                        return DB.RaidTargetIcon.AnchorTo or "TOP"
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.AnchorTo = val
                        DB.RaidTargetIcon.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerOffsetX = {
                    type = "range",
                    name = "Raid Marker X Offset",
                    desc = "Horizontal offset for raid marker",
                    order = 14,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.RaidTargetIcon.OffsetX or 0
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerOffsetY = {
                    type = "range",
                    name = "Raid Marker Y Offset",
                    desc = "Vertical offset for raid marker",
                    order = 15,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.RaidTargetIcon.OffsetY or 2
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
            },
        }
    end
    
    -- Helper to create Status Indicators tab (player frame only)
    local function CreateStatusIndicatorsTab()
        if unit ~= "player" then return nil end
        local DB = GetUnitDB(unit)
        if not DB.StatusIndicators then DB.StatusIndicators = {} end
        if not DB.StatusIndicators.Combat then DB.StatusIndicators.Combat = {} end
        if not DB.StatusIndicators.Resting then DB.StatusIndicators.Resting = {} end
        if not DB.LeaderIndicator then DB.LeaderIndicator = {} end
        if not DB.RaidTargetIcon then DB.RaidTargetIcon = {} end
        
        return {
            type = "group",
            name = "Status Indicators",
            order = 5,
            args = {
                combatHeader = {
                    type = "header",
                    name = "Combat Indicator",
                    order = 10,
                },
                combatEnabled = {
                    type = "toggle",
                    name = "Enable Combat Indicator",
                    desc = "Show combat indicator (sword icon) when in combat",
                    order = 11,
                    width = "full",
                    get = function()
                        return DB.StatusIndicators.Combat.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Combat.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                combatSize = {
                    type = "range",
                    name = "Combat Indicator Size",
                    desc = "Size of the combat indicator",
                    order = 12,
                    width = "full",
                    min = 12, max = 64, step = 1,
                    get = function()
                        return DB.StatusIndicators.Combat.Size or 24
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Combat.Size = val
                        UpdateUnitFrame(unit)
                    end,
                },
                combatAnchorFrom = {
                    type = "select",
                    name = "Combat Anchor From",
                    desc = "Anchor point on the indicator",
                    order = 13,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.StatusIndicators.Combat.AnchorFrom or "CENTER"
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Combat.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                combatAnchorTo = {
                    type = "select",
                    name = "Combat Anchor To",
                    desc = "Anchor point on the frame",
                    order = 14,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.StatusIndicators.Combat.AnchorTo or "TOPLEFT"
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Combat.AnchorTo = val
                        UpdateUnitFrame(unit)
                    end,
                },
                combatOffsetX = {
                    type = "range",
                    name = "Combat X Offset",
                    desc = "Horizontal offset for combat indicator",
                    order = 15,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.StatusIndicators.Combat.OffsetX or 3
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Combat.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                combatOffsetY = {
                    type = "range",
                    name = "Combat Y Offset",
                    desc = "Vertical offset for combat indicator",
                    order = 16,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.StatusIndicators.Combat.OffsetY or -3
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Combat.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                restingHeader = {
                    type = "header",
                    name = "Resting Indicator",
                    order = 30,
                },
                restingEnabled = {
                    type = "toggle",
                    name = "Enable Resting Indicator",
                    desc = "Show resting indicator (ZZZ icon) when resting",
                    order = 31,
                    width = "full",
                    get = function()
                        return DB.StatusIndicators.Resting.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Resting.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                restingSize = {
                    type = "range",
                    name = "Resting Indicator Size",
                    desc = "Size of the resting indicator",
                    order = 32,
                    width = "full",
                    min = 12, max = 64, step = 1,
                    get = function()
                        return DB.StatusIndicators.Resting.Size or 24
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Resting.Size = val
                        UpdateUnitFrame(unit)
                    end,
                },
                restingAnchorFrom = {
                    type = "select",
                    name = "Resting Anchor From",
                    desc = "Anchor point on the indicator",
                    order = 33,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.StatusIndicators.Resting.AnchorFrom or "CENTER"
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Resting.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                restingAnchorTo = {
                    type = "select",
                    name = "Resting Anchor To",
                    desc = "Anchor point on the frame",
                    order = 34,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.StatusIndicators.Resting.AnchorTo or "TOPLEFT"
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Resting.AnchorTo = val
                        UpdateUnitFrame(unit)
                    end,
                },
                restingOffsetX = {
                    type = "range",
                    name = "Resting X Offset",
                    desc = "Horizontal offset for resting indicator",
                    order = 35,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.StatusIndicators.Resting.OffsetX or 3
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Resting.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                restingOffsetY = {
                    type = "range",
                    name = "Resting Y Offset",
                    desc = "Vertical offset for resting indicator",
                    order = 36,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.StatusIndicators.Resting.OffsetY or -3
                    end,
                    set = function(_, val)
                        DB.StatusIndicators.Resting.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                leaderHeader = {
                    type = "header",
                    name = "Leader/Assistant Indicator",
                    order = 50,
                },
                leaderEnabled = {
                    type = "toggle",
                    name = "Enable Leader Indicator",
                    desc = "Show leader/assistant icon when unit is group leader or assistant",
                    order = 51,
                    width = "full",
                    get = function()
                        return DB.LeaderIndicator.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.LeaderIndicator.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                leaderSize = {
                    type = "range",
                    name = "Leader Indicator Size",
                    desc = "Size of the leader indicator",
                    order = 52,
                    width = "full",
                    min = 10, max = 40, step = 1,
                    get = function()
                        return DB.LeaderIndicator.Size or 15
                    end,
                    set = function(_, val)
                        DB.LeaderIndicator.Size = val
                        UpdateUnitFrame(unit)
                    end,
                },
                leaderAnchorFrom = {
                    type = "select",
                    name = "Leader Anchor From",
                    desc = "Anchor point on the indicator",
                    order = 53,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.LeaderIndicator.AnchorFrom or "RIGHT"
                    end,
                    set = function(_, val)
                        DB.LeaderIndicator.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                leaderAnchorTo = {
                    type = "select",
                    name = "Leader Anchor To",
                    desc = "Anchor point on the frame",
                    order = 54,
                    width = "normal",
                    values = AnchorPoints,
                    get = function()
                        return DB.LeaderIndicator.AnchorTo or "TOPRIGHT"
                    end,
                    set = function(_, val)
                        DB.LeaderIndicator.AnchorTo = val
                        UpdateUnitFrame(unit)
                    end,
                },
                leaderOffsetX = {
                    type = "range",
                    name = "Leader X Offset",
                    desc = "Horizontal offset for leader indicator",
                    order = 55,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.LeaderIndicator.OffsetX or -3
                    end,
                    set = function(_, val)
                        DB.LeaderIndicator.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                leaderOffsetY = {
                    type = "range",
                    name = "Leader Y Offset",
                    desc = "Vertical offset for leader indicator",
                    order = 56,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.LeaderIndicator.OffsetY or 0
                    end,
                    set = function(_, val)
                        DB.LeaderIndicator.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerHeader = {
                    type = "header",
                    name = "Raid Marker",
                    order = 60,
                },
                raidMarkerEnabled = {
                    type = "toggle",
                    name = "Enable Raid Marker",
                    desc = "Show raid target marker icon",
                    order = 61,
                    width = "full",
                    get = function()
                        return DB.RaidTargetIcon.Enabled ~= false
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.Enabled = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerScale = {
                    type = "range",
                    name = "Raid Marker Scale",
                    desc = "Scale of the raid marker icon",
                    order = 62,
                    width = "full",
                    min = 0.5, max = 2.5, step = 0.1,
                    get = function()
                        return DB.RaidTargetIcon.Scale or 1.0
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.Scale = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerAnchor = {
                    type = "select",
                    name = "Raid Marker Position",
                    desc = "Anchor point for the raid marker",
                    order = 63,
                    width = "full",
                    values = AnchorPoints,
                    get = function()
                        return DB.RaidTargetIcon.AnchorTo or "TOP"
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.AnchorTo = val
                        DB.RaidTargetIcon.AnchorFrom = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerOffsetX = {
                    type = "range",
                    name = "Raid Marker X Offset",
                    desc = "Horizontal offset for raid marker",
                    order = 64,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.RaidTargetIcon.OffsetX or 0
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.OffsetX = val
                        UpdateUnitFrame(unit)
                    end,
                },
                raidMarkerOffsetY = {
                    type = "range",
                    name = "Raid Marker Y Offset",
                    desc = "Vertical offset for raid marker",
                    order = 65,
                    width = "normal",
                    min = -200, max = 200, step = 1,
                    get = function()
                        return DB.RaidTargetIcon.OffsetY or 2
                    end,
                    set = function(_, val)
                        DB.RaidTargetIcon.OffsetY = val
                        UpdateUnitFrame(unit)
                    end,
                },
            },
        }
    end
    
    -- Main unit frame group with tabs
    local tabs = {
        General = CreateGeneralTab(),
        frame = (unit == "boss") and CreateBossFrameTab() or CreateFrameTab(),
        texts = CreateTextsTab(),
    }
    
    if hasPowerBar then
        tabs.powerBar = CreatePowerBarTab()
    end
    
    -- Add Absorb Bar tab for player and target frames
    if unit == "player" or unit == "target" then
        tabs.absorbBar = CreateAbsorbBarTab()
    end
    
    -- Add Buffs and Debuffs tabs for player, focus, target, and boss frames
    if unit == "player" or unit == "focus" or unit == "target" or unit == "boss" then
        tabs.buffs = CreateBuffsTab()
        tabs.debuffs = CreateDebuffsTab()
    end
    
    -- Add Status Indicators tab for player frame only
    if unit == "player" then
        tabs.statusIndicators = CreateStatusIndicatorsTab()
    end
    
    -- Add Indicator tab for boss, target, and focus frames
    if unit == "boss" or unit == "target" or unit == "focus" then
        tabs.indicator = CreateIndicatorTab()
    end

    -- Add boss-specific tabs
    if unit == "boss" then
        -- Positioning options are now in the Frame tab, no separate positioning tab needed
        -- tabs.positioning = CreateBossPositioningTab()
    end

    return {
        type = "group",
        name = displayName,
        order = order,
        childGroups = "tab",
        args = tabs,
    }
end

local function CreateUnitFrameOptionsGroup()
    return {
        type = "group",
        name = "Unit Frames",
        order = 9,
        childGroups = "tab",
        args = {
            -- General Settings Tab
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    header = {
                        type = "header",
                        name = "General Unit Frame Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Unit Frame Customization",
                        desc = "Enable custom unit frames (hides default Blizzard frames)",
                        width = "full",
                        order = 2,
                        get = function()
                            if not NephUI.db.profile.unitFrames then
                                NephUI.db.profile.unitFrames = {}
                            end
                            return NephUI.db.profile.unitFrames.enabled or false
                        end,
                        set = function(_, val)
                            if not NephUI.db.profile.unitFrames then
                                NephUI.db.profile.unitFrames = {}
                            end
                            NephUI.db.profile.unitFrames.enabled = val
                            if NephUI.UnitFrames then
                                if val then
                                    NephUI.UnitFrames:Initialize()
                                else
                                    -- Hide all frames when disabled
                                    for unit in pairs({player = true, target = true, targettarget = true, pet = true, focus = true}) do
                                        local frameName = "NephUI_" .. unit:gsub("^%l", string.upper):gsub("targettarget", "TargetTarget")
                                        local frame = _G[frameName]
                                        if frame then frame:Hide() end
                                    end
                                end
                            end
                        end,
                    },
                    spacer1 = {
                        type = "description",
                        name = " ",
                        order = 3,
                    },
                    showAnchorsLabel = {
                        type = "description",
                        name = "Unit Frame Anchors:",
                        order = 4,
                    },
                    enableAnchors = {
                        type = "execute",
                        name = "Enable Anchors",
                        desc = "Show draggable anchors for unit frames (works independently of Edit Mode)",
                        width = "normal",
                        order = 5,
                        func = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            db.General.ShowEditModeAnchors = true
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:UpdateEditModeAnchors()
                            end
                        end,
                    },
                    disableAnchors = {
                        type = "execute",
                        name = "Disable Anchors",
                        desc = "Hide draggable anchors for unit frames",
                        width = "normal",
                        order = 6,
                        func = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            db.General.ShowEditModeAnchors = false
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:UpdateEditModeAnchors()
                            end
                        end,
                    },
                    -- Textures Section
                    texturesHeader = {
                        type = "header",
                        name = "Textures",
                        order = 10,
                    },
                    foregroundTexture = {
                        type = "select",
                        name = "Foreground Texture",
                        desc = "Texture applied globally to all health bars",
                        order = 11,
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
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General then return "Blizzard Raid Bar" end
                            local override = db.General and db.General.ForegroundTexture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return NephUI.db.profile.general.globalTexture or "Neph"
                        end,
                        set = function(_, val)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            db.General.ForegroundTexture = val
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:ResolveMedia()
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    backgroundTexture = {
                        type = "select",
                        name = "Background Texture",
                        desc = "Texture applied globally to all health bar backgrounds",
                        order = 12,
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
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General then return "Solid" end
                            local override = db.General and db.General.BackgroundTexture
                            if override and override ~= "" then
                                return override
                            end
                            -- Return global texture name when override is nil
                            return NephUI.db.profile.general.globalTexture or "Neph"
                        end,
                        set = function(_, val)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            db.General.BackgroundTexture = val
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:ResolveMedia()
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    
                    -- Fonts Section
                    fontsHeader = {
                        type = "header",
                        name = "Fonts",
                        order = 20,
                    },
                    font = {
                        type = "select",
                        name = "Font",
                        desc = "Font used for all unit frame text (uses Global Font from General tab)",
                        order = 21,
                        width = "normal",
                        values = function()
                            local hashTable = LSM:HashTable("font")
                            local names = {}
                            for name, _ in pairs(hashTable) do
                                names[name] = name
                            end
                            return names
                        end,
                        get = function()
                            return NephUI.db.profile.general.globalFont or "Friz Quadrata TT"
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
                    fontFlag = {
                        type = "select",
                        name = "Font Flags",
                        desc = "Font outline style",
                        order = 22,
                        width = "normal",
                        values = {
                            ["OUTLINE"] = "Outline",
                            ["THICKOUTLINE"] = "Thick Outline",
                            ["MONOCHROME"] = "Monochrome",
                            ["NONE"] = "None",
                        },
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General then return "OUTLINE" end
                            return db.General.FontFlag or "OUTLINE"
                        end,
                        set = function(_, val)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            db.General.FontFlag = val
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    
                    -- Font Shadows Section
                    fontShadowsHeader = {
                        type = "header",
                        name = "Font Shadows",
                        order = 30,
                    },
                    shadowOffsetX = {
                        type = "range",
                        name = "Shadow X Offset",
                        order = 31,
                        width = "normal",
                        min = -10, max = 10, step = 1,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.FontShadows then return 0 end
                            return db.General.FontShadows.OffsetX or 0
                        end,
                        set = function(_, val)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.FontShadows then db.General.FontShadows = {} end
                            db.General.FontShadows.OffsetX = val
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    shadowOffsetY = {
                        type = "range",
                        name = "Shadow Y Offset",
                        order = 32,
                        width = "normal",
                        min = -10, max = 10, step = 1,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.FontShadows then return 0 end
                            return db.General.FontShadows.OffsetY or 0
                        end,
                        set = function(_, val)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.FontShadows then db.General.FontShadows = {} end
                            db.General.FontShadows.OffsetY = val
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    shadowColor = {
                        type = "color",
                        name = "Shadow Color",
                        order = 33,
                        width = "normal",
                        hasAlpha = true,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.FontShadows then return 0, 0, 0, 0 end
                            local c = db.General.FontShadows.Color or {0, 0, 0, 0}
                            return c[1], c[2], c[3], c[4] or 0
                        end,
                        set = function(_, r, g, b, a)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.FontShadows then db.General.FontShadows = {} end
                            db.General.FontShadows.Color = {r, g, b, a or 0}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    
                    mouseoverHeader = {
                        type = "header",
                        name = "Mouseover Highlight",
                        order = 34,
                    },
                    mouseoverToggle = {
                        type = "toggle",
                        name = "Enable Mouseover Highlight",
                        desc = "Show the custom mouseover glow on all NephUI unit frames",
                        order = 35,
                        width = "full",
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            local settings = db and db.General and db.General.MouseoverHighlight
                            if settings == nil then return true end
                            return settings.Enabled ~= false
                        end,
                        set = function(_, val)
                            local db = NephUI.db.profile.unitFrames
                            if not db then
                                NephUI.db.profile.unitFrames = {}
                                db = NephUI.db.profile.unitFrames
                            end
                            if not db.General then db.General = {} end
                            if not db.General.MouseoverHighlight then
                                db.General.MouseoverHighlight = {Enabled = true, Alpha = 0.5}
                            end
                            db.General.MouseoverHighlight.Enabled = val
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    mouseoverAlpha = {
                        type = "range",
                        name = "Mouseover Highlight Alpha",
                        desc = "Adjust the opacity of the mouseover glow for all unit frames",
                        order = 36,
                        width = "full",
                        min = 0,
                        max = 1,
                        step = 0.05,
                        disabled = function()
                            local db = NephUI.db.profile.unitFrames
                            local settings = db and db.General and db.General.MouseoverHighlight
                            return settings and settings.Enabled == false
                        end,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            local settings = db and db.General and db.General.MouseoverHighlight
                            return (settings and settings.Alpha) or 0.5
                        end,
                        set = function(_, val)
                            local db = NephUI.db.profile.unitFrames
                            if not db then
                                NephUI.db.profile.unitFrames = {}
                                db = NephUI.db.profile.unitFrames
                            end
                            if not db.General then db.General = {} end
                            if not db.General.MouseoverHighlight then
                                db.General.MouseoverHighlight = {Enabled = true, Alpha = 0.5}
                            end
                            db.General.MouseoverHighlight.Alpha = val
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    
                    -- Custom Colors Section
                    customColorsHeader = {
                        type = "header",
                        name = "Custom Colors",
                        order = 40,
                    },
                    powerColorsHeader = {
                        type = "header",
                        name = "Power Colors",
                        order = 41,
                    },
                    manaColor = {
                        type = "color",
                        name = "Mana",
                        order = 42,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 0, 0, 1
                            end
                            local c = db.General.CustomColors.Power[0] or {0, 0, 1}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[0] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    rageColor = {
                        type = "color",
                        name = "Rage",
                        order = 43,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 1, 0, 0
                            end
                            local c = db.General.CustomColors.Power[1] or {1, 0, 0}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[1] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    energyColor = {
                        type = "color",
                        name = "Energy",
                        order = 44,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 1, 1, 0
                            end
                            local c = db.General.CustomColors.Power[3] or {1, 1, 0}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[3] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    runicPowerColor = {
                        type = "color",
                        name = "Runic Power",
                        order = 45,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 0, 0.82, 1
                            end
                            local c = db.General.CustomColors.Power[6] or {0, 0.82, 1}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[6] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    focusColor = {
                        type = "color",
                        name = "Focus",
                        order = 46,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 1, 0.5, 0.25
                            end
                            local c = db.General.CustomColors.Power[2] or {1, 0.5, 0.25}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[2] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    astralPowerColor = {
                        type = "color",
                        name = "Astral Power",
                        order = 47,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 0.3, 0.52, 0.9
                            end
                            local c = db.General.CustomColors.Power[8] or {0.3, 0.52, 0.9}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[8] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    maelstromColor = {
                        type = "color",
                        name = "Maelstrom",
                        order = 48,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 0, 0.5, 1
                            end
                            local c = db.General.CustomColors.Power[11] or {0, 0.5, 1}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[11] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    insanityColor = {
                        type = "color",
                        name = "Insanity",
                        order = 49,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 0.4, 0, 0.8
                            end
                            local c = db.General.CustomColors.Power[13] or {0.4, 0, 0.8}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[13] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    furyColor = {
                        type = "color",
                        name = "Fury",
                        order = 50,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 0.79, 0.26, 0.99
                            end
                            local c = db.General.CustomColors.Power[17] or {0.79, 0.26, 0.99}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[17] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    painColor = {
                        type = "color",
                        name = "Pain",
                        order = 51,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Power then
                                return 1, 0.61, 0
                            end
                            local c = db.General.CustomColors.Power[18] or {1, 0.61, 0}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Power then db.General.CustomColors.Power = {} end
                            db.General.CustomColors.Power[18] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    reactionColorsHeader = {
                        type = "header",
                        name = "Reaction Colors",
                        order = 55,
                    },
                    hostileColor = {
                        type = "color",
                        name = "Hostile",
                        order = 56,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Reaction then
                                return 204/255, 64/255, 64/255
                            end
                            local c = db.General.CustomColors.Reaction[2] or {204/255, 64/255, 64/255}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Reaction then db.General.CustomColors.Reaction = {} end
                            db.General.CustomColors.Reaction[2] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    neutralColor = {
                        type = "color",
                        name = "Neutral",
                        order = 57,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Reaction then
                                return 204/255, 204/255, 64/255
                            end
                            local c = db.General.CustomColors.Reaction[4] or {204/255, 204/255, 64/255}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Reaction then db.General.CustomColors.Reaction = {} end
                            db.General.CustomColors.Reaction[4] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                    friendlyColor = {
                        type = "color",
                        name = "Friendly",
                        order = 58,
                        width = "normal",
                        hasAlpha = false,
                        get = function()
                            local db = NephUI.db.profile.unitFrames
                            if not db or not db.General or not db.General.CustomColors or not db.General.CustomColors.Reaction then
                                return 64/255, 204/255, 64/255
                            end
                            local c = db.General.CustomColors.Reaction[5] or {64/255, 204/255, 64/255}
                            return c[1], c[2], c[3]
                        end,
                        set = function(_, r, g, b)
                            local db = NephUI.db.profile.unitFrames
                            if not db.General then db.General = {} end
                            if not db.General.CustomColors then db.General.CustomColors = {} end
                            if not db.General.CustomColors.Reaction then db.General.CustomColors.Reaction = {} end
                            db.General.CustomColors.Reaction[5] = {r, g, b}
                            if NephUI.UnitFrames then
                                NephUI.UnitFrames:RefreshFrames()
                            end
                        end,
                    },
                },
            },
            
            -- Per-frame tabs
            playerFrame = CreateUnitFrameOptions("player", "Player", 10),
            targetFrame = CreateUnitFrameOptions("target", "Target", 20),
            targettargetFrame = CreateUnitFrameOptions("targettarget", "Target Target", 30),
            petFrame = CreateUnitFrameOptions("pet", "Pet", 40),
            focusFrame = CreateUnitFrameOptions("focus", "Focus", 50),
            bossFrame = CreateUnitFrameOptions("boss", "Boss", 60),
        },
    }
end

-- Export functions
ns.CreateUnitFrameOptions = CreateUnitFrameOptions
ns.CreateUnitFrameOptionsGroup = CreateUnitFrameOptionsGroup

