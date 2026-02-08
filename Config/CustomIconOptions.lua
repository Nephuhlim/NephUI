local ADDON_NAME, ns = ...
local NephUI = ns.Addon

local function CreateCustomIconOptions()
    return {
        type = "group",
        name = "Custom Spells",
        order = 8,
        args = {
            header = {
                type = "header",
                name = "Custom Spells",
                order = 1,
            },
            description = {
                type = "description",
                name = "Build custom spell, item, and equipment-slot trackers. Use the UI below to add icons, configure visuals, and organize groups.",
                order = 2,
            },
            customSpellsUI = {
                type = "dynamicIcons",
                name = "Custom Spells",
                order = 3,
            },
        },
    }
end

ns.CreateCustomIconOptions = CreateCustomIconOptions

