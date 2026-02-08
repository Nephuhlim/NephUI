local ADDON_NAME, ns = ...
local NephUI = ns.Addon

local function CreateCustomBuffOptions()
    return {
        type = "group",
        name = "Custom Buffs",
        order = 9,
        args = {
            header = {
                type = "header",
                name = "Custom Buffs",
                order = 1,
            },
            description = {
                type = "description",
                name = "Track spell casts and show cooldown timers. Use the UI below to add spell IDs, set icons and duration, and organize buffs in groups.",
                order = 2,
            },
            customBuffsUI = {
                type = "customBuffs",
                name = "Custom Buffs",
                order = 3,
            },
        },
    }
end

ns.CreateCustomBuffOptions = CreateCustomBuffOptions
