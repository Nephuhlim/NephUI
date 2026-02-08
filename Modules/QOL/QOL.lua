local ADDON_NAME, ns = ...
local NephUI = ns.Addon

NephUI.QOL = NephUI.QOL or {}
local QOL = NephUI.QOL

local function GetDB()
    if not (NephUI.db and NephUI.db.profile) then
        return nil
    end
    if not NephUI.db.profile.qol then
        NephUI.db.profile.qol = {}
    end
    return NephUI.db.profile.qol
end

local function GetBagsBar()
    return _G.BagsBar
        or _G.BagBar
        or (_G.MainMenuBarBackpackButton and _G.MainMenuBarBackpackButton:GetParent())
        or nil
end

local function GetExpandToggle()
    return _G.BagsBarExpandToggle or _G.BagBarExpandToggle
end

local function TooltipIDsAllowed()
    local db = GetDB()
    return db and db.tooltipIDs
end

-- Like idTip: Blizzard marks tooltip data as "secret" in combat/restricted contexts.
-- Checking this (instead of InCombatLockdown) avoids showing IDs when data is restricted.
local function isSecret(value)
    if not issecretvalue or not issecrettable then return false end
    return issecretvalue(value) or issecrettable(value)
end

function QOL:IsHideBagsBarEnabled()
    local db = GetDB()
    return db and db.hideBagsBar
end

function QOL:StoreOriginalParents()
    local bagsBar = GetBagsBar()
    if bagsBar and not self.originalBagsBarParent then
        self.originalBagsBarParent = bagsBar:GetParent()
    end

    local toggle = GetExpandToggle()
    if toggle and not self.originalToggleParent then
        self.originalToggleParent = toggle:GetParent()
    end
end

function QOL:ApplyHiddenState()
    if InCombatLockdown() then
        self.pendingUpdate = true
        self:RegisterCombatWatcher()
        return
    end

    local bagsBar = GetBagsBar()
    if not bagsBar then
        self:ScheduleRetry()
        return
    end

    if self.isApplying then
        return
    end
    self.isApplying = true

    self:StoreOriginalParents()

    local hiddenParent = NephUI.ShadowUIParent or UIParent
    if bagsBar.SetParent then
        bagsBar:SetParent(hiddenParent)
    end
    if bagsBar.Hide then
        bagsBar:Hide()
    end
    if bagsBar.SetAlpha then
        bagsBar:SetAlpha(0)
    end

    local toggle = GetExpandToggle()
    if toggle then
        if toggle.SetParent then
            toggle:SetParent(hiddenParent)
        end
        if toggle.Hide then
            toggle:Hide()
        end
        if toggle.SetAlpha then
            toggle:SetAlpha(0)
        end
    end

    self.isApplying = nil
end

function QOL:RestoreBagsBar()
    if InCombatLockdown() then
        self.pendingUpdate = true
        self:RegisterCombatWatcher()
        return
    end

    local bagsBar = GetBagsBar()
    if not bagsBar then
        self:ScheduleRetry()
        return
    end

    if self.isApplying then
        return
    end
    self.isApplying = true

    local parent = self.originalBagsBarParent or UIParent
    if self.originalBagsBarParent and bagsBar.SetParent then
        bagsBar:SetParent(parent)
    end
    if bagsBar.SetAlpha then
        bagsBar:SetAlpha(1)
    end
    if bagsBar.Show then
        bagsBar:Show()
    end

    local toggle = GetExpandToggle()
    if toggle then
        if self.originalToggleParent and toggle.SetParent then
            toggle:SetParent(self.originalToggleParent or parent)
        end
        if toggle.SetAlpha then
            toggle:SetAlpha(1)
        end
        if toggle.Show then
            toggle:Show()
        end
    end

    self.isApplying = nil
end

function QOL:RegisterCombatWatcher()
    if self.combatWatcher then
        return
    end
    self.combatWatcher = CreateFrame("Frame")
    self.combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.combatWatcher:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" and QOL.pendingUpdate then
            QOL.pendingUpdate = nil
            QOL:UpdateBagsBarVisibility()
        end
    end)
end

function QOL:ScheduleRetry()
    if self.retryTimer then
        return
    end
    self.retryTimer = C_Timer.NewTimer(1, function()
        QOL.retryTimer = nil
        QOL:UpdateBagsBarVisibility()
    end)
end

function QOL:EnsureHooks()
    if self.hooksSet then
        return
    end

    local bagsBar = GetBagsBar()
    if not bagsBar then
        self:ScheduleRetry()
        return
    end

    self.hooksSet = true

    hooksecurefunc(bagsBar, "Show", function()
        if QOL:IsHideBagsBarEnabled() then
            QOL:ApplyHiddenState()
        end
    end)

    hooksecurefunc(bagsBar, "SetParent", function()
        if QOL:IsHideBagsBarEnabled() then
            QOL:ApplyHiddenState()
        end
    end)

    local toggle = GetExpandToggle()
    if toggle then
        hooksecurefunc(toggle, "Show", function()
            if QOL:IsHideBagsBarEnabled() then
                if toggle.Hide then
                    toggle:Hide()
                end
            end
        end)
        hooksecurefunc(toggle, "SetParent", function()
            if QOL:IsHideBagsBarEnabled() then
                QOL:ApplyHiddenState()
            end
        end)
    end
end

function QOL:UpdateBagsBarVisibility()
    if InCombatLockdown() then
        self.pendingUpdate = true
        self:RegisterCombatWatcher()
        return
    end

    if not self.hooksSet then
        self:EnsureHooks()
    end

    if self:IsHideBagsBarEnabled() then
        self:ApplyHiddenState()
    else
        self:RestoreBagsBar()
    end
end

function QOL:Initialize()
    self:EnsureHooks()
    self:UpdateBagsBarVisibility()
    self:RefreshTooltipIDs()
end

function QOL:Refresh()
    self:UpdateBagsBarVisibility()
    self:RefreshTooltipIDs()
end

-- Tooltip IDs functionality
local tooltipKinds = {
    spell = "SpellID",
    item = "ItemID",
    quest = "QuestID",
    talent = "TalentID",
    achievement = "AchievementID",
    criteria = "CriteriaID",
    ability = "AbilityID",
    currency = "CurrencyID",
    artifactpower = "ArtifactPowerID",
    enchant = "EnchantID",
    bonus = "BonusID",
    gem = "GemID",
    mount = "MountID",
    companion = "CompanionID",
    macro = "MacroID",
    set = "SetID",
    visual = "VisualID",
    source = "SourceID",
    species = "SpeciesID",
    icon = "IconID",
    areapoi = "AreaPoiID",
    vignette = "VignetteID",
    expansion = "ExpansionID",
    object = "ObjectID",
    traitnode = "TraitNodeID",
    traitentry = "TraitEntryID",
    traitdef = "TraitDefinitionID",
}

local tooltipKindsByID = {
    [0]  = "item", -- Item
    [1]  = "spell", -- Spell
    [2]  = "unit", -- Unit
    [3]  = "unit", -- Corpse
    [4]  = "object", -- Object
    [5]  = "currency", -- Currency
    [6]  = "unit", -- BattlePet
    [7]  = "spell", -- UnitAura
    [8]  = "spell", -- AzeriteEssence
    [9]  = "unit", -- CompanionPet
    [10] = "mount", -- Mount
    [11] = "spell", -- PetAction
    [12] = "achievement", -- Achievement
    [13] = "spell", -- EnhancedConduit
    [14] = "set", -- EquipmentSet
    [15] = "", -- InstanceLock
    [16] = "", -- PvPBrawl
    [17] = "spell", -- RecipeRankInfo
    [18] = "spell", -- Totem
    [19] = "item", -- Toy
    [20] = "", -- CorruptionCleanser
    [21] = "", -- MinimapMouseover
    [22] = "", -- Flyout
    [23] = "quest", -- Quest
    [24] = "quest", -- QuestPartyProgress
    [25] = "macro", -- Macro
    [26] = "", -- Debug
}

local function tooltipAddLine(tooltip, id, kind)
    if isSecret(id) then return end
    if not id or id == "" or not tooltip or not tooltip.GetName then return end

    if not TooltipIDsAllowed() then return end

    -- Check if we already added to this tooltip
    local frame, text
    for i = tooltip:NumLines(), 1, -1 do
        frame = _G[tooltip:GetName() .. "TextLeft" .. i]
        if frame then text = frame:GetText() end
        if isSecret(text) then return end
        if text and string.find(text, tooltipKinds[kind]) then return end
    end

    local multiple = type(id) == "table"
    if multiple and #id == 1 then
        id = id[1]
        multiple = false
    end

    local left = tooltipKinds[kind] .. (multiple and "s" or "")
    local right = multiple and table.concat(id, ", ") or id
    tooltip:AddDoubleLine(left, right, nil, nil, nil, 1, 1, 1)
    tooltip:Show()
end

local function tooltipAdd(tooltip, id, kind)
    if not TooltipIDsAllowed() then return end
    tooltipAddLine(tooltip, id, kind)

    -- item spell
    if kind == "item" and GetItemSpell then
        local numId = type(id) == "number" and id or tonumber(id)
        if numId then
            local spellId = select(2, GetItemSpell(numId))
            if spellId then tooltipAdd(tooltip, spellId, "spell") end
        end
    end
end

local function tooltipAddByKind(tooltip, id, kind)
    if not TooltipIDsAllowed() then return end
    if not kind or not id then return end
    if kind == "spell" or kind == "enchant" or kind == "trade" then
        tooltipAdd(tooltip, id, "spell")
    elseif (tooltipKinds[kind]) then
        tooltipAdd(tooltip, id, kind)
    end
end

local function tooltipAddItemInfo(tooltip, link)
    if not TooltipIDsAllowed() then return end
    if not link then return end
    local itemString = string.match(link, "item:([%-?%d:]+)")
    if not itemString then return end

    local bonuses = {}
    local itemSplit = {}

    for v in string.gmatch(itemString, "(%d*:?)") do
        if v == ":" then
            itemSplit[#itemSplit + 1] = 0
        else
            itemSplit[#itemSplit + 1] = string.gsub(v, ":", "")
        end
    end

    for index = 1, tonumber(itemSplit[13]) do
        bonuses[#bonuses + 1] = itemSplit[13 + index]
    end

    local gems = {}
    if GetItemGem then
        for i = 1, 4 do
            local gemLink = select(2, GetItemGem(link, i))
            if gemLink then
                local gemDetail = string.match(gemLink, "item[%-?%d:]+")
                gems[#gems + 1] = string.match(gemDetail, "item:(%d+):")
            end
        end
    end

    local itemId = string.match(link, "item:(%d*)")
    if itemId and itemId ~= "" and itemId ~= "0" then
        tooltipAdd(tooltip, itemId, "item")

        if itemSplit[2] ~= 0 then tooltipAdd(tooltip, itemSplit[2], "enchant") end
        if #bonuses ~= 0 then tooltipAdd(tooltip, bonuses, "bonus") end
        if #gems ~= 0 then tooltipAdd(tooltip, gems, "gem") end

        local expansionId = select(15, GetItemInfo(itemId))
        if expansionId and expansionId ~= 254 then
            tooltipAdd(tooltip, expansionId, "expansion")
        end

        local setId = select(16, GetItemInfo(itemId))
        if setId then
            tooltipAdd(tooltip, setId, "set")
        end
    end
end

function QOL:IsTooltipIDsEnabled()
    local db = GetDB()
    return db and db.tooltipIDs
end

function QOL:InitializeTooltipIDs()
    if not self:IsTooltipIDsEnabled() then return end

    if self.tooltipIDsInitialized then return end
    self.tooltipIDsInitialized = true

    -- Hook TooltipDataProcessor for modern tooltip system
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
            if not TooltipIDsAllowed() then return end
            if not data or not data.type then return end
            if isSecret(data.type) or isSecret(data.guid) then return end
            local kind = tooltipKindsByID[tonumber(data.type)]

            if kind == "unit" then return end -- NPC IDs not shown
            if kind == "item" and data then
                -- Safely check if we can access guid for items
                local guid = data.guid
                if guid and type(guid) == "string" and GetItemLinkByGUID then
                    local link = GetItemLinkByGUID(guid)
                    if link then
                        tooltipAddItemInfo(tooltip, link)
                    else
                        tooltipAdd(tooltip, data.id, kind)
                    end
                else
                    tooltipAdd(tooltip, data.id, kind)
                end
            elseif kind then
                tooltipAdd(tooltip, data.id, kind)
            end
        end)
    end

    -- Hook various tooltip functions
    if GetActionInfo then
        hooksecurefunc(GameTooltip, "SetAction", function(tooltip, slot)
            if not TooltipIDsAllowed() then return end
            local kind, id = GetActionInfo(slot)
            tooltipAddByKind(tooltip, id, kind)
        end)
    end

    hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tooltip, link)
        if not TooltipIDsAllowed() then return end
        local kind, id = string.match(link,"^(%a+):(%d+)")
        tooltipAddByKind(tooltip, id, kind)
    end)
    hooksecurefunc(GameTooltip, "SetHyperlink", function(tooltip, link)
        if not TooltipIDsAllowed() then return end
        local kind, id = string.match(link,"^(%a+):(%d+)")
        tooltipAddByKind(tooltip, id, kind)
    end)

    if UnitBuff then
        hooksecurefunc(GameTooltip, "SetUnitBuff", function(tooltip, ...)
            if not TooltipIDsAllowed() then return end
            local id = select(10, UnitBuff(...))
            tooltipAdd(tooltip, id, "spell")
        end)
    end

    if UnitDebuff then
        hooksecurefunc(GameTooltip, "SetUnitDebuff", function(tooltip, ...)
            if not TooltipIDsAllowed() then return end
            local id = select(10, UnitDebuff(...))
            tooltipAdd(tooltip, id, "spell")
        end)
    end

    if UnitAura then
        hooksecurefunc(GameTooltip, "SetUnitAura", function(tooltip, ...)
            if not TooltipIDsAllowed() then return end
            local id = select(10, UnitAura(...))
            tooltipAdd(tooltip, id, "spell")
        end)
    end

    if GameTooltip.SetSpellByID then
        hooksecurefunc(GameTooltip, "SetSpellByID", function(tooltip, id)
            if not TooltipIDsAllowed() then return end
            tooltipAddByKind(tooltip, id, "spell")
        end)
    end

    hooksecurefunc(_G, "SetItemRef", function(link)
        if not TooltipIDsAllowed() then return end
        local id = tonumber(link:match("spell:(%d+)"))
        tooltipAdd(ItemRefTooltip, id, "spell")
    end)

    if GameTooltip.SetRecipeResultItem then
        hooksecurefunc(GameTooltip, "SetRecipeResultItem", function(tooltip, id)
            if not TooltipIDsAllowed() then return end
            tooltipAdd(tooltip, id, "spell")
        end)
    end

    if GameTooltip.SetRecipeRankInfo then
        hooksecurefunc(GameTooltip, "SetRecipeRankInfo", function(tooltip, id)
            if not TooltipIDsAllowed() then return end
            tooltipAdd(tooltip, id, "spell")
        end)
    end

    if GameTooltip.SetCurrencyByID then
        hooksecurefunc(GameTooltip, "SetCurrencyByID", function(tooltip, id)
            if not TooltipIDsAllowed() then return end
            tooltipAdd(tooltip, id, "currency")
        end)
    end

    if GameTooltip.SetCurrencyTokenByID then
        hooksecurefunc(GameTooltip, "SetCurrencyTokenByID", function(tooltip, id)
            if not TooltipIDsAllowed() then return end
            tooltipAdd(tooltip, id, "currency")
        end)
    end

    -- Hook tooltip scripts
    if GameTooltip:HasScript("OnTooltipSetSpell") then
        GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip)
            if not TooltipIDsAllowed() then return end
            local id = select(2, tooltip:GetSpell())
            tooltipAdd(tooltip, id, "spell")
        end)
    end

    if GameTooltip:HasScript("OnTooltipSetUnit") then
        GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
            if not TooltipIDsAllowed() then return end
            if C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() then return end
            local unit = select(2, tooltip:GetUnit())
            if unit and UnitGUID then
                local guid = UnitGUID(unit) or ""
                local id = tonumber(guid:match("-(%d+)-%x+$"), 10)
                if id and guid:match("%a+") ~= "Player" then tooltipAdd(tooltip, id, "unit") end
            end
        end)
    end

    local function onSetItem(tooltip)
        if not TooltipIDsAllowed() then return end
        tooltipAddItemInfo(tooltip, nil)
    end
    if GameTooltip:HasScript("OnTooltipSetItem") then
        GameTooltip:HookScript("OnTooltipSetItem", onSetItem)
    end
    if ItemRefTooltip:HasScript("OnTooltipSetItem") then
        ItemRefTooltip:HookScript("OnTooltipSetItem", onSetItem)
    end
    if ItemRefShoppingTooltip1 and ItemRefShoppingTooltip1:HasScript("OnTooltipSetItem") then
        ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", onSetItem)
    end
    if ItemRefShoppingTooltip2 and ItemRefShoppingTooltip2:HasScript("OnTooltipSetItem") then
        ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", onSetItem)
    end
    if ShoppingTooltip1 and ShoppingTooltip1:HasScript("OnTooltipSetItem") then
        ShoppingTooltip1:HookScript("OnTooltipSetItem", onSetItem)
    end
    if ShoppingTooltip2 and ShoppingTooltip2:HasScript("OnTooltipSetItem") then
        ShoppingTooltip2:HookScript("OnTooltipSetItem", onSetItem)
    end
end

function QOL:RefreshTooltipIDs()
    if self:IsTooltipIDsEnabled() and not self.tooltipIDsInitialized then
        self:InitializeTooltipIDs()
    end
end


---------------------------------------------------------------------------
-- Automation
---------------------------------------------------------------------------

local function GetSettings()
    return GetDB()
end

local function OnMerchantShow()
    local settings = GetSettings()
    if not settings then return end

    if settings.sellJunk then
        for bag = 0, 4 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.quality == Enum.ItemQuality.Poor then
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
    end

    local repairMode = settings.autoRepair
    if repairMode and repairMode ~= "off" and CanMerchantRepair() then
        local repairCost = GetRepairAllCost()
        if repairCost and repairCost > 0 then
            if repairMode == "guildFirst" then
                local canGuildRepair = CanGuildBankRepair()
                RepairAllItems(canGuildRepair)
            else
                RepairAllItems(false)
            end
        end
    end
end

local function IsFriendOrBNet(name)
    if not name then return false end
    if C_FriendList.IsFriend(name) then return true end

    local numBNetTotal = BNGetNumFriends()
    for i = 1, numBNetTotal do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo then
            local charName = accountInfo.gameAccountInfo.characterName
            local realmName = accountInfo.gameAccountInfo.realmName
            if charName then
                local fullName = realmName and (charName .. "-" .. realmName) or charName
                if fullName == name or charName == name:match("^([^-]+)") then
                    return true
                end
            end
        end
    end
    return false
end

local function IsGuildMemberByName(name)
    if not name or not IsInGuild() then return false end
    local numMembers = GetNumGuildMembers()
    local searchName = name:match("^([^-]+)") or name
    for i = 1, numMembers do
        local memberName = GetGuildRosterInfo(i)
        if memberName then
            local memberShort = memberName:match("^([^-]+)") or memberName
            if memberShort == searchName then
                return true
            end
        end
    end
    return false
end

local function OnPartyInvite(inviterName)
    local settings = GetSettings()
    if not settings or not settings.autoAcceptInvites then return end

    local shouldAccept = IsFriendOrBNet(inviterName) or IsGuildMemberByName(inviterName)
    if shouldAccept then
        AcceptGroup()
        StaticPopup_Hide("PARTY_INVITE")
    end
end

local function OnQuestDetail()
    local settings = GetSettings()
    if not settings or not settings.autoAcceptQuest then return end
    AcceptQuest()
end

local function OnQuestComplete()
    local settings = GetSettings()
    if not settings or not settings.autoTurnInQuest then return end

    local numChoices = GetNumQuestChoices()
    if numChoices > 1 then return end
    GetQuestReward(numChoices > 0 and 1 or nil)
end

local lootRetryPending = false

local function TryLootAll()
    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            LootSlot(slotIndex)
        end
    end
end

local function CheckRemainingLoot()
    lootRetryPending = false
    local settings = GetSettings()
    if not settings or not settings.fastAutoLoot then return end

    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            TryLootAll()
            return
        end
    end
end

local function OnLootReady()
    local settings = GetSettings()
    if not settings or not settings.fastAutoLoot then return end

    if not GetCVarBool("autoLootDefault") then
        SetCVar("autoLootDefault", "1")
    end

    TryLootAll()

    if not lootRetryPending then
        lootRetryPending = true
        C_Timer.After(0.1, CheckRemainingLoot)
    end
end

local deletePopups = {
    ["DELETE_ITEM"] = true,
    ["DELETE_GOOD_ITEM"] = true,
    ["DELETE_GOOD_QUEST_ITEM"] = true,
    ["DELETE_QUEST_ITEM"] = true,
}

local deleteHooked = false
local function EnsureDeleteConfirmHook()
    if deleteHooked then return end
    deleteHooked = true

    hooksecurefunc("StaticPopup_Show", function(which)
        if not deletePopups[which] then return end

        local settings = GetSettings()
        if not settings or not settings.autoDeleteConfirm then return end

        for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
            local frame = _G["StaticPopup" .. i]
            if frame and frame.which == which and frame:IsShown() then
                local editBox = frame.editBox or _G["StaticPopup" .. i .. "EditBox"]
                if editBox then
                    editBox:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
                    local handler = editBox:GetScript("OnTextChanged")
                    if handler then
                        handler(editBox)
                    end
                end
                break
            end
        end
    end)
end

local function FindKeystoneInBags()
    local numBagFrames = NUM_BAG_FRAMES or 4
    for bag = 0, numBagFrames do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local itemClass, itemSubClass = select(12, C_Item.GetItemInfo(itemID))
                if itemClass == Enum.ItemClass.Reagent and itemSubClass == Enum.ItemReagentSubclass.Keystone then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

local function InsertKeystone()
    local settings = GetSettings()
    if not settings or not settings.autoInsertKey then return end

    local bag, slot = FindKeystoneInBags()
    if not bag then return end

    C_Container.PickupContainerItem(bag, slot)
    if C_Cursor.GetCursorItem() then
        C_ChallengeMode.SlotKeystone()
    end
end

local keystoneHooked = false
local function HookKeystoneFrame()
    if keystoneHooked then return end
    if ChallengesKeystoneFrame then
        ChallengesKeystoneFrame:HookScript("OnShow", InsertKeystone)
        keystoneHooked = true
    end
end

local automationFrame = CreateFrame("Frame")
automationFrame:RegisterEvent("MERCHANT_SHOW")
automationFrame:RegisterEvent("PARTY_INVITE_REQUEST")
automationFrame:RegisterEvent("QUEST_DETAIL")
automationFrame:RegisterEvent("QUEST_COMPLETE")
automationFrame:RegisterEvent("LOOT_READY")
automationFrame:RegisterEvent("ADDON_LOADED")

automationFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "PARTY_INVITE_REQUEST" then
        OnPartyInvite(...)
    elseif event == "QUEST_DETAIL" then
        OnQuestDetail()
    elseif event == "QUEST_COMPLETE" then
        OnQuestComplete()
    elseif event == "LOOT_READY" then
        OnLootReady()
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_ChallengesUI" then
            HookKeystoneFrame()
        end
    end
end)

EnsureDeleteConfirmHook()

