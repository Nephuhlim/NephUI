local ADDON_NAME, ns = ...
local NephUI = ns.Addon

local function CreateChatOptions()
    return {
        type = "group",
        name = "Chat",
        order = 3,
        args = {
            header = {
                type = "header",
                name = "Chat Settings",
                order = 1,
            },
            enabled = {
                type = "toggle",
                name = "Enable Chat Skinning",
                desc = "Apply custom styling to chat frames",
                width = "full",
                order = 2,
                get = function() return NephUI.db.profile.chat.enabled end,
                set = function(_, val)
                    NephUI.db.profile.chat.enabled = val
                    if NephUI.Chat and NephUI.Chat.RefreshAll then
                        NephUI.Chat:RefreshAll()
                    end
                end,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 3,
            },
            backgroundColor = {
                type = "color",
                name = "Background Color",
                desc = "Color of the chat frame background",
                order = 10,
                width = "full",
                hasAlpha = true,
                get = function()
                    local c = NephUI.db.profile.chat.backgroundColor
                    return c[1], c[2], c[3], c[4] or 1
                end,
                set = function(_, r, g, b, a)
                    NephUI.db.profile.chat.backgroundColor = { r, g, b, a or 1 }
                    if NephUI.Chat and NephUI.Chat.RefreshAll then
                        NephUI.Chat:RefreshAll()
                    end
                end,
            },
            spacer2 = {
                type = "description",
                name = " ",
                order = 11,
            },
            hideQuickJoinToastButton = {
                type = "toggle",
                name = "Hide Quick Join Toast Button",
                desc = "Hide the Quick Join toast button that appears in chat",
                width = "full",
                order = 12,
                get = function() return NephUI.db.profile.chat.hideQuickJoinToastButton end,
                set = function(_, val)
                    NephUI.db.profile.chat.hideQuickJoinToastButton = val
                    if NephUI.Chat and NephUI.Chat.UpdateQuickJoinToastButton then
                        NephUI.Chat:UpdateQuickJoinToastButton()
                    end
                end,
            },
            quickJoinToastButtonOffsetX = {
                type = "range",
                name = "Quick Join Toast Button X Offset",
                desc = "Horizontal offset for the Quick Join toast button",
                width = "full",
                min = -500,
                max = 500,
                step = 1,
                order = 13,
                get = function()
                    return NephUI.db.profile.chat.quickJoinToastButtonOffsetX or 31
                end,
                set = function(_, val)
                    NephUI.db.profile.chat.quickJoinToastButtonOffsetX = val
                    if NephUI.Chat and NephUI.Chat.UpdateQuickJoinToastButton then
                        NephUI.Chat:UpdateQuickJoinToastButton()
                    end
                end,
            },
            quickJoinToastButtonOffsetY = {
                type = "range",
                name = "Quick Join Toast Button Y Offset",
                desc = "Vertical offset for the Quick Join toast button",
                width = "full",
                min = -500,
                max = 500,
                step = 1,
                order = 14,
                get = function()
                    return NephUI.db.profile.chat.quickJoinToastButtonOffsetY or -23
                end,
                set = function(_, val)
                    NephUI.db.profile.chat.quickJoinToastButtonOffsetY = val
                    if NephUI.Chat and NephUI.Chat.UpdateQuickJoinToastButton then
                        NephUI.Chat:UpdateQuickJoinToastButton()
                    end
                end,
            },
        },
    }
end

ns.CreateChatOptions = CreateChatOptions

