local ADDON_NAME, ns = ...
local NephUI = ns.Addon
local L = ns.L or LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME, true) or {}

local importBuffer = ""
local newProfileNameBuffer = ""

local function CreateProfileOptions()
    return {
        type = "group",
        name = L["Import / Export"] or "Import / Export",
        order = 13,
        args = {
            desc = {
                type  = "description",
                order = 1,
                name  = L["Export your current profile as text to share, or paste a string to import."] or "Export your current profile as text to share, or paste a string to import.",
            },

            spacer1 = {
                type  = "description",
                order = 2,
                name  = "",
            },

            export = {
                type      = "input",
                name      = L["Export Current Profile"] or "Export Current Profile",
                order     = 10,
                width     = "full",
                multiline = true,
                get       = function()
                    return NephUI:ExportProfileToString()
                end,
                set       = function() end,
            },

            spacer2 = {
                type  = "description",
                order = 19,
                name  = " ",
            },

            import = {
                type      = "input",
                name      = L["Import Profile String"] or "Import Profile String",
                order     = 20,
                width     = "full",
                multiline = true,
                get       = function()
                    return importBuffer
                end,
                set       = function(_, val)
                    importBuffer = val or ""
                end,
            },

            newProfileName = {
                type  = "input",
                name  = L["New Profile Name"] or "New Profile Name",
                order = 25,
                width = "full",
                get   = function()
                    return newProfileNameBuffer
                end,
                set   = function(_, val)
                    newProfileNameBuffer = val or ""
                end,
            },

            importButton = {
                type  = "execute",
                name  = L["Import"] or "Import",
                order = 30,
                func  = function()
                    local importString = importBuffer
                    
                    -- If buffer is empty, try to get text from the custom GUI
                    if not importString or importString == "" then
                        local configFrame = _G["NephUI_ConfigFrame"]
                        if configFrame and configFrame:IsShown() then
                            -- Try to find the import edit box in the custom GUI
                            local function FindImportEditBox(parent, depth)
                                depth = depth or 0
                                if depth > 15 then return nil end
                                
                                -- Check if this is an EditBox with multiline
                                if type(parent) == "table" and parent.GetObjectType then
                                    local objType = parent:GetObjectType()
                                    if objType == "EditBox" then
                                        -- Check if it's the import box by looking at parent structure
                                        local parentFrame = parent:GetParent()
                                        if parentFrame then
                                            local label = parentFrame.label
                                            if label and label.GetText then
                                                local labelText = label:GetText() or ""
                                                if string.find(labelText:lower(), "import") then
                                                    return parent:GetText() or ""
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                -- Check children
                                if type(parent) == "userdata" and parent.GetChildren then
                                    local children = {parent:GetChildren()}
                                    for _, child in ipairs(children) do
                                        local text = FindImportEditBox(child, depth + 1)
                                        if text then return text end
                                    end
                                end
                                
                                return nil
                            end
                            
                            importString = FindImportEditBox(configFrame, 0) or importBuffer
                        end
                    end
                    
                    -- Trim whitespace
                    if importString then
                        importString = importString:gsub("^%s+", ""):gsub("%s+$", "")
                    end
                    
                    if not importString or importString == "" then
                        print("|cffff0000" .. (L["NephUI: Import failed: No data found. Please paste your import string in the Import Profile String field."] or "NephUI: Import failed: No data found. Please paste your import string in the Import Profile String field.") .. "|r")
                        return
                    end
                    
                    -- Get the new profile name
                    local newProfileName = newProfileNameBuffer
                    if newProfileName then
                        newProfileName = newProfileName:gsub("^%s+", ""):gsub("%s+$", "")
                    end
                    
                    if not newProfileName or newProfileName == "" then
                        print("|cffff0000" .. (L["NephUI: Please enter a profile name for the imported profile."] or "NephUI: Please enter a profile name for the imported profile.") .. "|r")
                        return
                    end
                    
                    local ok, err = NephUI:ImportProfileFromString(importString, newProfileName)
                    if ok then
                        print("|cff00ff00" .. (L["NephUI: Profile imported as '%s'. Please reload your UI."] or "NephUI: Profile imported as '%s'. Please reload your UI."):format(newProfileName) .. "|r")
                        -- Clear the buffers after successful import
                        importBuffer = ""
                        newProfileNameBuffer = ""
                    else
                        local errMsg = L["NephUI: Import failed: %s"] or "NephUI: Import failed: %s"
                        print("|cffff0000" .. (errMsg:format(err or "Unknown error")) .. "|r")
                    end
                end,
            },
        },
    }
end

ns.CreateProfileOptions = CreateProfileOptions

