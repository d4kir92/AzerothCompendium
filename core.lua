local _, AzerothCompendium = ...
local ADDON = "AzerothCompendium"
local ICON = 133737
AzerothCompendium:SetAddonOutput(ADDON, ICON)
local byType = nil
local preloaded = false
local questsByID = nil
local questSidesByID = nil
local questDataByID = nil

function AzerothCompendium:GetCompendiumTooltipLabel(text, size)
    size = tonumber(size) or 14

    return format("|T%d:%d:%d:0:0|t %s", ICON, size, size, tostring(text or ""))
end

local function IsOpposingQuestSide(side)
    local faction = UnitFactionGroup and UnitFactionGroup("player")

    return side == 1 and faction == "Horde" or side == 2 and faction == "Alliance"
end

function AzerothCompendium:GetAddonVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then return C_AddOns.GetAddOnMetadata(ADDON, "Version") end
    if GetAddOnMetadata then return GetAddOnMetadata(ADDON, "Version") end

    return "0.0.0"
end
local FOREVER_ITEM_MIN = 200000
local FLAVOR_FOREVER = "forever"
local FLAVOR_CLASSIC_ERA = "classic_era"
local ARMOR_MISC = 0
local ARMOR_CLOTH = 1
local ARMOR_LEATHER = 2
local ARMOR_MAIL = 3
local ARMOR_PLATE = 4
local ARMOR_SHIELD = 6
local ARMOR_LIBRAM = 7
local ARMOR_IDOL = 8
local ARMOR_TOTEM = 9
local ALWAYS_USABLE_SLOTS = {
    ["INVTYPE_CLOAK"] = true,
    ["INVTYPE_NECK"] = true,
    ["INVTYPE_FINGER"] = true,
    ["INVTYPE_TRINKET"] = true,
    ["INVTYPE_BAG"] = true,
}

local PROFICIENCY = {
    ["WARRIOR"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true,
            [ARMOR_LEATHER] = true,
            [ARMOR_MAIL] = true,
            [ARMOR_PLATE] = true,
            [ARMOR_SHIELD] = true
        },
        ["weapon"] = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [10] = true,
            [13] = true,
            [15] = true,
            [16] = true,
            [18] = true
        }
    },
    ["PALADIN"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true,
            [ARMOR_LEATHER] = true,
            [ARMOR_MAIL] = true,
            [ARMOR_PLATE] = true,
            [ARMOR_SHIELD] = true,
            [ARMOR_LIBRAM] = true
        },
        ["weapon"] = {
            [0] = true,
            [1] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true
        }
    },
    ["HUNTER"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true,
            [ARMOR_LEATHER] = true,
            [ARMOR_MAIL] = true
        },
        ["weapon"] = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [10] = true,
            [13] = true,
            [15] = true,
            [16] = true,
            [18] = true
        }
    },
    ["ROGUE"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true,
            [ARMOR_LEATHER] = true
        },
        ["weapon"] = {
            [0] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [7] = true,
            [13] = true,
            [15] = true,
            [16] = true,
            [18] = true
        }
    },
    ["PRIEST"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true
        },
        ["weapon"] = {
            [4] = true,
            [10] = true,
            [15] = true,
            [19] = true
        }
    },
    ["SHAMAN"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true,
            [ARMOR_LEATHER] = true,
            [ARMOR_MAIL] = true,
            [ARMOR_SHIELD] = true,
            [ARMOR_TOTEM] = true
        },
        ["weapon"] = {
            [0] = true,
            [1] = true,
            [4] = true,
            [5] = true,
            [10] = true,
            [13] = true,
            [15] = true
        }
    },
    ["MAGE"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true
        },
        ["weapon"] = {
            [7] = true,
            [10] = true,
            [15] = true,
            [19] = true
        }
    },
    ["WARLOCK"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true
        },
        ["weapon"] = {
            [7] = true,
            [10] = true,
            [15] = true,
            [19] = true
        }
    },
    ["DRUID"] = {
        ["armor"] = {
            [ARMOR_CLOTH] = true,
            [ARMOR_LEATHER] = true,
            [ARMOR_IDOL] = true
        },
        ["weapon"] = {
            [4] = true,
            [5] = true,
            [6] = true,
            [10] = true,
            [13] = true,
            [15] = true
        }
    },
}

function AzerothCompendium:GetConfig(key, value)
    ACOTAB = ACOTAB or {}
    if ACOTAB[key] == nil then ACOTAB[key] = value end

    return ACOTAB[key]
end

function AzerothCompendium:SetConfig(key, value)
    ACOTAB = ACOTAB or {}
    AzerothCompendium:SV(ACOTAB, key, value)
end

function AzerothCompendium:SetClassFilter(value)
    AzerothCompendium:SetConfig("CLASSFILTER", value == true)
    if AzerothCompendium.SyncCompendiumClassFilter then AzerothCompendium:SyncCompendiumClassFilter() end
    if AzerothCompendium.SyncSettingsClassFilter then AzerothCompendium:SyncSettingsClassFilter() end
    if AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
end

function AzerothCompendium:GetFlavor()
    local flavor = AzerothCompendium:GetConfig("FLAVOR", FLAVOR_FOREVER)
    if flavor ~= FLAVOR_FOREVER and flavor ~= FLAVOR_CLASSIC_ERA then
        flavor = FLAVOR_FOREVER
        AzerothCompendium:SetConfig("FLAVOR", flavor)
    end

    return flavor
end

function AzerothCompendium:SetFlavor(value)
    if value ~= FLAVOR_CLASSIC_ERA then value = FLAVOR_FOREVER end
    AzerothCompendium:SetConfig("FLAVOR", value)
    if AzerothCompendium.SyncCompendiumFlavor then AzerothCompendium:SyncCompendiumFlavor() end
    if AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
end

function AzerothCompendium:GetWishlist()
    ACOTAB = ACOTAB or {}
    if type(ACOTAB["WISHLIST"]) ~= "table" then ACOTAB["WISHLIST"] = {} end

    return ACOTAB["WISHLIST"]
end

function AzerothCompendium:IsWishlisted(itemID)
    return AzerothCompendium:GetWishlist()[itemID] ~= nil
end

function AzerothCompendium:SetWishlistItem(itemID, source)
    if type(itemID) ~= "number" then return end
    AzerothCompendium:GetWishlist()[itemID] = source
    if AzerothCompendium.RefreshWishlist then AzerothCompendium:RefreshWishlist() end
end

function AzerothCompendium:GetInstanceName(inst)
    if inst == nil then return "" end
    if inst.honor then return AzerothCompendium:Trans("LID_HONORRANKS") end
    if inst.factionID then
        if C_Reputation and C_Reputation.GetFactionDataByID then
            local data = C_Reputation.GetFactionDataByID(inst.factionID)
            if type(data) == "table" and type(data.name) == "string" and data.name ~= "" then return data.name end
        end

        if GetFactionInfoByID then
            local name = GetFactionInfoByID(inst.factionID)
            if type(name) == "string" and name ~= "" then return name end
        end

        return inst.name
    end

    if inst.areaID and C_Map and C_Map.GetAreaInfo then
        local name = C_Map.GetAreaInfo(inst.areaID)
        if type(name) == "string" and name ~= "" then return name end
    end

    if inst.uiMapID and C_Map and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(inst.uiMapID)
        if info and info.name and info.name ~= "" then return info.name end
    end

    return inst.name
end

function AzerothCompendium:GetBossName(boss)
    if boss == nil then return "" end
    if boss.trash then return AzerothCompendium:Trans("LID_TRASH") end
    if boss.standing ~= nil then
        local label = _G["FACTION_STANDING_LABEL" .. (boss.standing + 1)]
        if type(label) == "string" and label ~= "" then return label end

        return boss.name
    end

    if boss.rank ~= nil then return AzerothCompendium:Trans("LID_RANK", nil, boss.rank) end
    local names = AzerothCompendium.BOSSNAMES
    if names and boss.npcs and boss.npcs[1] then
        local localized = names[boss.npcs[1]]
        if localized then return localized end
    end

    return boss.name
end

function AzerothCompendium:GetInstanceQuests(inst)
    if inst == nil or inst.id == nil then return {} end

    local quests = AzerothCompendium.QUESTS and AzerothCompendium.QUESTS[inst.id] or {}
    local available = {}
    for _, quest in ipairs(quests) do
        if not (AzerothCompendium.UNAVAILABLEQUESTS and AzerothCompendium.UNAVAILABLEQUESTS[quest[1]]) and not IsOpposingQuestSide(quest[3]) then
            tinsert(available, quest)
        end
    end
    table.sort(available, function(a, b)
        local levelA = AzerothCompendium:GetQuestRecommendedLevel(a)
        local levelB = AzerothCompendium:GetQuestRecommendedLevel(b)
        if levelA ~= levelB then return levelA < levelB end
        local nameA = AzerothCompendium:GetQuestName(a)
        local nameB = AzerothCompendium:GetQuestName(b)
        if nameA ~= nameB then return nameA < nameB end

        return a[1] < b[1]
    end)

    return available
end

function AzerothCompendium:GetQuestRecommendedLevel(quest)
    if quest == nil then return 0 end
    local questID = type(quest) == "table" and quest[1] or quest
    if C_QuestLog and C_QuestLog.GetQuestDifficultyLevel then
        local ok, level = pcall(C_QuestLog.GetQuestDifficultyLevel, questID)
        if ok and type(level) == "number" and level > 0 then return level end
    end
    if type(quest) == "table" and type(quest[2]) == "number" then return quest[2] end
    local data = AzerothCompendium:GetQuestDataByID(questID)
    if data and type(data[2]) == "number" then return data[2] end

    return AzerothCompendium.QUESTRECOMMENDEDLEVELS and AzerothCompendium.QUESTRECOMMENDEDLEVELS[questID] or 0
end

function AzerothCompendium:GetQuestRequiredLevel(quest)
    if quest == nil then return 0 end
    if type(quest) == "table" and type(quest[5]) == "number" then return quest[5] end
    local questID = type(quest) == "table" and quest[1] or quest
    local data = AzerothCompendium:GetQuestDataByID(questID)
    if data and type(data[5]) == "number" then return data[5] end

    return AzerothCompendium.QUESTREQUIREDLEVELS and AzerothCompendium.QUESTREQUIREDLEVELS[questID] or 0
end

function AzerothCompendium:GetQuestName(quest)
    if quest == nil then return "" end
    local questID = quest[1]
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = C_QuestLog.GetTitleForQuestID(questID)
        if type(title) == "string" and title ~= "" then return title end
    end
    if QuestUtils_GetQuestName then
        local title = QuestUtils_GetQuestName(questID)
        if type(title) == "string" and title ~= "" then return title end
    end

    return quest[4] or ("Quest " .. questID)
end

function AzerothCompendium:GetQuestNameByID(questID)
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = C_QuestLog.GetTitleForQuestID(questID)
        if type(title) == "string" and title ~= "" then return title end
    end
    if QuestUtils_GetQuestName then
        local title = QuestUtils_GetQuestName(questID)
        if type(title) == "string" and title ~= "" then return title end
    end
    if questsByID == nil then
        questsByID = {}
        for _, quests in pairs(AzerothCompendium.QUESTS or {}) do
            for _, quest in ipairs(quests) do questsByID[quest[1]] = quest[4] end
        end
    end

    return questsByID[questID] or AzerothCompendium.QUESTNAMES and AzerothCompendium.QUESTNAMES[questID] or ("Quest " .. questID)
end

function AzerothCompendium:GetQuestDataByID(questID)
    if questDataByID == nil then
        questDataByID = {}
        for _, quests in pairs(AzerothCompendium.QUESTS or {}) do
            for _, quest in ipairs(quests) do questDataByID[quest[1]] = quest end
        end
    end

    return questDataByID[questID]
end

local function IsQuestForOpposingFaction(questID)
    if questSidesByID == nil then
        questSidesByID = {}
        for _, quests in pairs(AzerothCompendium.QUESTS or {}) do
            for _, quest in ipairs(quests) do questSidesByID[quest[1]] = quest[3] end
        end
    end
    local side = questSidesByID[questID]

    return IsOpposingQuestSide(side)
end

function AzerothCompendium:IsQuestCompleted(questID)
    if IsQuestForOpposingFaction(questID) then return false end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, completed = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok then return completed == true end
    end
    if IsQuestFlaggedCompleted then
        local ok, completed = pcall(IsQuestFlaggedCompleted, questID)
        if ok then return completed == true end
    end

    return false
end

function AzerothCompendium:IsQuestActive(questID)
    if IsQuestForOpposingFaction(questID) then return false end
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, active = pcall(C_QuestLog.IsOnQuest, questID)
        if ok then return active == true end
    end
    if GetQuestLogIndexByID then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok then return type(index) == "number" and index > 0 end
    end

    return false
end

function AzerothCompendium:GetQuestChain(questID)
    local quests = {}
    local seen = {}
    local function AddQuest(id, depth, prerequisiteChain)
        if AzerothCompendium.UNAVAILABLEQUESTS and AzerothCompendium.UNAVAILABLEQUESTS[id] then return end
        if seen[id] then return end
        local prerequisites = AzerothCompendium.QUESTPREREQUISITES and AzerothCompendium.QUESTPREREQUISITES[id]
        for _, prerequisiteID in ipairs(prerequisites or {}) do
            AddQuest(prerequisiteID, prerequisiteChain and depth or depth + 1, true)
        end
        local nested = AzerothCompendium.QUESTCHAINS and AzerothCompendium.QUESTCHAINS[id]
        for _, nestedID in ipairs(nested or {}) do
            if nestedID ~= id then AddQuest(nestedID, depth, prerequisiteChain) end
        end
        if seen[id] then return end
        seen[id] = true
        local startItem = AzerothCompendium.QUESTSTARTITEMS and AzerothCompendium.QUESTSTARTITEMS[id]
        tinsert(quests, {id, AzerothCompendium:GetQuestNameByID(id), #quests + 1, startItem and startItem[1], depth})
    end
    local ids = AzerothCompendium.QUESTCHAINS and AzerothCompendium.QUESTCHAINS[questID] or {questID}
    for _, id in ipairs(ids) do
        AddQuest(id, 0)
    end
    local maxDepth = 0
    for _, quest in ipairs(quests) do
        if quest[5] > maxDepth then maxDepth = quest[5] end
    end
    for _, quest in ipairs(quests) do
        quest[6] = quest[5]
        quest[5] = maxDepth - quest[5]
    end

    return quests
end

local prerequisiteInstancesByQuestID = nil

local function GetPrerequisiteInstancesByQuestID()
    if prerequisiteInstancesByQuestID ~= nil then return prerequisiteInstancesByQuestID end
    prerequisiteInstancesByQuestID = {}
    local seen = {}
    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        for _, quest in ipairs(AzerothCompendium:GetInstanceQuests(inst)) do
            for _, step in ipairs(AzerothCompendium:GetQuestChain(quest[1])) do
                local stepID = step[1]
                if stepID ~= quest[1] then
                    prerequisiteInstancesByQuestID[stepID] = prerequisiteInstancesByQuestID[stepID] or {}
                    seen[stepID] = seen[stepID] or {}
                    if not seen[stepID][inst.id] then
                        seen[stepID][inst.id] = true
                        tinsert(prerequisiteInstancesByQuestID[stepID], inst)
                    end
                end
            end
        end
    end

    return prerequisiteInstancesByQuestID
end

local function GetTooltipQuestTitle(tooltip)
    local name = tooltip.GetName and tooltip:GetName()
    local line = name and _G[name .. "TextLeft1"]

    return line and line:GetText()
end

local function TooltipContainsLine(tooltip, text)
    local name = tooltip.GetName and tooltip:GetName()
    if name == nil or tooltip.NumLines == nil then return false end
    for index = 1, tooltip:NumLines() do
        local line = _G[name .. "TextLeft" .. index]
        if line and line:GetText() == text then return true end
    end

    return false
end

local function AddQuestPrerequisiteTooltip(tooltip, questID)
    local destinations = GetPrerequisiteInstancesByQuestID()
    local instances = questID and destinations[questID]
    if instances == nil then
        local title = GetTooltipQuestTitle(tooltip)
        if type(title) ~= "string" or title == "" then return end
        local matched = {}
        instances = {}
        for id, destinationList in pairs(destinations) do
            if AzerothCompendium:GetQuestNameByID(id) == title then
                for _, inst in ipairs(destinationList) do
                    if not matched[inst.id] then
                        matched[inst.id] = true
                        tinsert(instances, inst)
                    end
                end
            end
        end
    end
    if instances == nil or #instances == 0 then return end
    local added = false
    for _, inst in ipairs(instances) do
        local text = AzerothCompendium:GetCompendiumTooltipLabel(AzerothCompendium:Trans("LID_PREREQUISITEFOR", nil, AzerothCompendium:GetInstanceName(inst)))
        if not TooltipContainsLine(tooltip, text) then
            tooltip:AddLine(text, 1, 0.82, 0, true)
            added = true
        end
    end
    if added then tooltip:Show() end
end

local function InstallLegacyQuestTooltipHook(tooltip)
    if type(tooltip) ~= "table" or tooltip.AzerothCompendiumQuestHook then return end
    local hooked = pcall(tooltip.HookScript, tooltip, "OnTooltipSetQuest", function(owner)
        AddQuestPrerequisiteTooltip(owner, tonumber(owner.AzerothCompendiumQuestID or owner.questID))
    end)
    if not hooked then return end
    tooltip.AzerothCompendiumQuestHook = true
    pcall(tooltip.HookScript, tooltip, "OnTooltipCleared", function(owner)
        owner.AzerothCompendiumQuestID = nil
    end)
    if hooksecurefunc then
        hooksecurefunc(tooltip, "SetHyperlink", function(owner, link)
            local questID = type(link) == "string" and tonumber(string.match(link, "^quest:(%d+)"))
            owner.AzerothCompendiumQuestID = questID
            if questID then AddQuestPrerequisiteTooltip(owner, questID) end
        end)
    end
end

local function InstallQuestTooltipHooks()
    if EventRegistry and EventRegistry.RegisterCallback then
        local function OnManualQuestTooltip(_, _, questID)
            AddQuestPrerequisiteTooltip(GameTooltip, tonumber(questID))
        end
        pcall(EventRegistry.RegisterCallback, EventRegistry, "QuestMapLogTitleButton.OnEnter", OnManualQuestTooltip, AzerothCompendium)
        pcall(EventRegistry.RegisterCallback, EventRegistry, "MapCanvas.QuestPin.OnEnter", OnManualQuestTooltip, AzerothCompendium)
    end
    local tooltipType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Quest
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and tooltipType then
        local installed = pcall(TooltipDataProcessor.AddTooltipPostCall, tooltipType, function(tooltip, data)
            local questID = data and tonumber(data.id or data.questID)
            if questID == nil and data and type(data.hyperlink) == "string" then
                questID = tonumber(string.match(data.hyperlink, "^quest:(%d+)"))
            end
            AddQuestPrerequisiteTooltip(tooltip, questID)
        end)
        if installed then return end
    end
    InstallLegacyQuestTooltipHook(GameTooltip)
    InstallLegacyQuestTooltipHook(ItemRefTooltip)
end

InstallQuestTooltipHooks()

function AzerothCompendium:IsQuestStartInInstance(questID)
    local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[questID]

    return giver ~= nil and giver[6] == true
end

function AzerothCompendium:SetQuestWaypoint(questID)
    local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[questID]
    if giver == nil then return false end
    if giver[6] == true then return false end
    if InCombatLockdown and InCombatLockdown() then return false, "combat" end
    if C_Map == nil or C_Map.SetUserWaypoint == nil or UiMapPoint == nil or UiMapPoint.CreateFromCoordinates == nil then return false end
    local point = UiMapPoint.CreateFromCoordinates(giver[1], giver[2] / 100, giver[3] / 100)
    C_Map.SetUserWaypoint(point)
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    if OpenWorldMap then
        OpenWorldMap(giver[1])
    elseif WorldMapFrame then
        if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(giver[1]) end
        if ShowUIPanel then ShowUIPanel(WorldMapFrame) else WorldMapFrame:Show() end
    end

    return true
end

function AzerothCompendium:IsForeverItem(itemID)
    return type(itemID) == "number" and itemID >= FOREVER_ITEM_MIN
end

function AzerothCompendium:GetInstances(kind)
    if byType == nil then
        byType = {
            ["dungeon"] = {},
            ["raid"] = {},
            ["pvp"] = {},
            ["faction"] = {}
        }

        for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
            local list = byType[inst.type]
            if list then tinsert(list, inst) end
        end

        for _, inst in ipairs(AzerothCompendium.VENDORS or {}) do
            local list = byType[inst.type]
            if list then tinsert(list, inst) end
        end

        local function ByName(a, b)
            if (a.honor == true) ~= (b.honor == true) then return a.honor == true end

            return AzerothCompendium:GetInstanceName(a) < AzerothCompendium:GetInstanceName(b)
        end

        table.sort(byType["faction"], ByName)
        table.sort(byType["pvp"], ByName)
    end

    return byType[kind] or {}
end

function AzerothCompendium:GetItemDisplay(itemID)
    local name, link, quality, _, _, _, _, _, equipLoc, icon = AzerothCompendium:GetItemInfo(itemID)
    if icon == nil then
        local _, _, _, invType, texture = AzerothCompendium:GetItemInfoInstant(itemID)
        icon = texture
        equipLoc = equipLoc or invType
    end

    return name, link, quality, equipLoc, icon
end

function AzerothCompendium:GetItemSlotText(itemID)
    local _, itemType, itemSubType, invType = AzerothCompendium:GetItemInfoInstant(itemID)
    local slot = nil
    if type(invType) == "string" and invType ~= "" then
        local global = _G[invType]
        if type(global) == "string" and global ~= "" then slot = global end
    end

    if slot and itemSubType and itemSubType ~= "" and itemSubType ~= slot then return slot .. ", " .. itemSubType end
    if slot then return slot end
    if itemSubType and itemSubType ~= "" then return itemSubType end

    return itemType or ""
end

function AzerothCompendium:IsUsableByClass(itemID, class)
    if itemID == nil then return true end
    local _, _, _, invType, _, classID, subClassID = AzerothCompendium:GetItemInfoInstant(itemID)
    if classID == nil then return true end
    if ALWAYS_USABLE_SLOTS[invType or ""] then return true end
    local prof = PROFICIENCY[class or ""]
    if prof == nil then return true end
    if classID == 4 then
        if subClassID == ARMOR_MISC then return true end

        return prof.armor[subClassID] == true
    end

    if classID == 2 then
        if subClassID == 20 then return true end

        return prof.weapon[subClassID] == true
    end

    return true
end

function AzerothCompendium:HasWidgetSet(tooltip)
    if type(tooltip) ~= "table" then return false end
    local container = tooltip.widgetContainer
    if type(container) ~= "table" then return false end
    if type(container.IsRegisteredForWidgetSet) ~= "function" then return false end
    if not container:IsRegisteredForWidgetSet() then return false end
    local frames = container.widgetFrames
    if type(frames) ~= "table" then return false end
    for _ in pairs(frames) do
        return true
    end

    return false
end

function AzerothCompendium:HideGameTooltip()
    if type(GameTooltip) ~= "table" then return end
    if not GameTooltip:IsShown() then return end
    if AzerothCompendium:HasWidgetSet(GameTooltip) then return end
    GameTooltip:Hide()
end

function AzerothCompendium:PreloadItems()
    if preloaded then return end
    preloaded = true
    local request = C_Item and C_Item.RequestLoadItemDataByID
    if request == nil then return end
    local queue = {}
    for _, source in ipairs({AzerothCompendium.INSTANCES or {}, AzerothCompendium.VENDORS or {}}) do
        for _, inst in ipairs(source) do
            for _, boss in ipairs(inst.bosses or {}) do
                for _, entry in ipairs(boss.loot or {}) do
                    tinsert(queue, entry[1])
                end
            end
        end
    end
    for _, entry in pairs(AzerothCompendium.QUESTSTARTITEMS or {}) do
        tinsert(queue, entry[1])
    end

    local index = 1
    local function Step()
        local last = math.min(index + 49, #queue)
        for i = index, last do
            request(queue[i])
        end

        index = last + 1
        if index <= #queue then AzerothCompendium:After(0.1, Step, "AzerothCompendium:PreloadItems") end
    end

    Step()
end

function AzerothCompendium:GetAddonName()
    return ADDON
end

function AzerothCompendium:GetIcon()
    return ICON
end
