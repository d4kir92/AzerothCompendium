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

AzerothCompendium.LANGUAGES = {{"English", "enUS"}, {"Deutsch", "deDE"}, {"Español (España)", "esES"}, {"Español (México)", "esMX"}, {"Français", "frFR"}, {"Italiano", "itIT"}, {"한국어", "koKR"}, {"Português (Brasil)", "ptBR"}, {"Русский", "ruRU"}, {"简体中文", "zhCN"}, {"繁體中文", "zhTW"}}
local LANGUAGE_NAMES = {}
for _, info in ipairs(AzerothCompendium.LANGUAGES) do
    LANGUAGE_NAMES[info[2]] = info[1]
end

function AzerothCompendium:GetLanguage()
    local lang = type(ACOTAB) == "table" and ACOTAB["LANGUAGE"] or nil
    if lang ~= nil and LANGUAGE_NAMES[lang] ~= nil then return lang end

    return GetLocale()
end

function AzerothCompendium:GetLanguageName()
    local lang = AzerothCompendium:GetLanguage()

    return LANGUAGE_NAMES[lang] or lang
end

local languageCallbacks = {}
function AzerothCompendium:OnLanguage(callback)
    tinsert(languageCallbacks, callback)
    callback()
end

function AzerothCompendium:SetLanguage(lang)
    if LANGUAGE_NAMES[lang] == nil or lang == AzerothCompendium:GetLanguage() then return end
    ACOTAB = ACOTAB or {}
    if lang == GetLocale() then
        ACOTAB["LANGUAGE"] = nil
    else
        ACOTAB["LANGUAGE"] = lang
    end

    for _, callback in ipairs(languageCallbacks) do
        callback()
    end

    if AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
end

local LibTrans = AzerothCompendium.Trans
function AzerothCompendium:Trans(key, lang, ...)
    return LibTrans(self, key, lang or AzerothCompendium:GetLanguage(), ...)
end

function AzerothCompendium:SetClassFilter(value)
    AzerothCompendium:SetConfig("CLASSFILTER", value == true)
    if AzerothCompendium.SyncCompendiumClassFilter then AzerothCompendium:SyncCompendiumClassFilter() end
    if AzerothCompendium.SyncSettingsClassFilter then AzerothCompendium:SyncSettingsClassFilter() end
    if AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
end

function AzerothCompendium:IsClassicEraClient()
    local interface = select(4, GetBuildInfo())
    return type(interface) == "number" and interface < 16000
end

function AzerothCompendium:GetFlavor()
    if AzerothCompendium:IsClassicEraClient() then return FLAVOR_CLASSIC_ERA end
    local flavor = AzerothCompendium:GetConfig("FLAVOR", FLAVOR_FOREVER)
    if flavor ~= FLAVOR_FOREVER and flavor ~= FLAVOR_CLASSIC_ERA then
        flavor = FLAVOR_FOREVER
        AzerothCompendium:SetConfig("FLAVOR", flavor)
    end

    return flavor
end

function AzerothCompendium:SetFlavor(value)
    if value ~= FLAVOR_CLASSIC_ERA then value = FLAVOR_FOREVER end
    if not AzerothCompendium:IsClassicEraClient() then AzerothCompendium:SetConfig("FLAVOR", value) end
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

function AzerothCompendium:GetWishlistTexture(itemID)
    local source = AzerothCompendium:GetWishlist()[itemID]
    if source == nil then return nil end
    if type(source) == "table" and source.wishlistMark == "nice" then
        return "Interface\\AddOns\\AzerothCompendium\\media\\hearth"
    end
    return "Interface\\AddOns\\AzerothCompendium\\media\\star"
end
function AzerothCompendium:SetWishlistItem(itemID, source, mark)
    if type(itemID) ~= "number" then return end
    if type(source) == "table" then
        local saved = {}
        for key, value in pairs(source) do saved[key] = value end
        saved.wishlistMark = mark or source.wishlistMark or "favorite"
        source = saved
    end
    AzerothCompendium:GetWishlist()[itemID] = source
    if AzerothCompendium.WishlistStars then
        AzerothCompendium.WishlistStars:Refresh()
        AzerothCompendium.WishlistStars:RefreshBaganator()
    end
    if AzerothCompendium.RefreshWishlist then AzerothCompendium:RefreshWishlist() end
end

function AzerothCompendium:GetInstanceWingName(inst)
    if inst == nil or inst.wing == nil then return nil end

    return AzerothCompendium:Trans(inst.wing)
end

function AzerothCompendium:GetInstanceName(inst)
    local base = AzerothCompendium:GetInstanceBaseName(inst)
    local wing = AzerothCompendium:GetInstanceWingName(inst)
    if wing then return wing .. " - " .. base end

    return base
end

function AzerothCompendium:GetInstanceBaseName(inst)
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

local creatureNames = {cache = {}, tries = {}, waiting = {}, scheduled = false}

function AzerothCompendium:GetSavedCreatureNames()
    ACOTAB = ACOTAB or {}
    if type(ACOTAB["CREATURENAMES"]) ~= "table" then ACOTAB["CREATURENAMES"] = {} end
    local key = AzerothCompendium:GetFlavor() .. ":" .. GetLocale()
    if creatureNames.cacheKey ~= key then
        creatureNames.cacheKey = key
        creatureNames.cache = {}
        creatureNames.tries = {}
    end

    if type(ACOTAB["CREATURENAMES"][key]) ~= "table" then ACOTAB["CREATURENAMES"][key] = {} end

    return ACOTAB["CREATURENAMES"][key]
end

function AzerothCompendium:ReadCreatureName(npcID)
    if IsInInstance() then return nil end
    local link = "unit:Creature-0-0-0-0-" .. npcID .. "-0000000000"
    local text = nil
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        local line = ok and type(data) == "table" and data.lines and data.lines[1] or nil
        text = line and line.leftText
    end

    if issecretvalue and issecretvalue(text) then return nil end
    if type(text) ~= "string" or text == "" then
        local tooltip = creatureNames.tooltip
        if tooltip == nil then
            tooltip = CreateFrame("GameTooltip", "AzerothCompendiumScanTooltip", UIParent, "GameTooltipTemplate")
            creatureNames.tooltip = tooltip
        end

        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:ClearLines()
        pcall(tooltip.SetHyperlink, tooltip, link)
        local region = _G["AzerothCompendiumScanTooltipTextLeft1"]
        text = region and region:GetText()
        tooltip:Hide()
    end

    if issecretvalue and issecretvalue(text) then return nil end
    if type(text) ~= "string" or text == "" or text == RETRIEVING_DATA or text == RETRIEVING_ITEM_INFO then return nil end

    return text
end

function AzerothCompendium:RetryCreatureNames()
    creatureNames.scheduled = false
    local waiting = creatureNames.waiting
    creatureNames.waiting = {}
    local found = false
    for npcID in pairs(waiting) do
        if AzerothCompendium:GetCreatureName(npcID) then found = true end
    end

    if found and AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
end

function AzerothCompendium:GetCreatureName(npcID)
    if type(npcID) ~= "number" then return nil end
    local saved = AzerothCompendium:GetSavedCreatureNames()
    local cached = creatureNames.cache[npcID]
    if cached then return cached end
    if IsInInstance() then return saved[npcID] end
    local name = AzerothCompendium:ReadCreatureName(npcID)
    if name then
        creatureNames.cache[npcID] = name
        saved[npcID] = name

        return name
    end

    local tries = creatureNames.tries[npcID] or 0
    if tries < 5 then
        creatureNames.tries[npcID] = tries + 1
        creatureNames.waiting[npcID] = true
        if not creatureNames.scheduled then
            creatureNames.scheduled = true
            AzerothCompendium:After(1, function() AzerothCompendium:RetryCreatureNames() end, "AzerothCompendium:CreatureNames")
        end
    end

    return saved[npcID]
end

function AzerothCompendium:PreloadCreatureNames()
    if IsInInstance() then return end
    creatureNames.preloadPending = false
    creatureNames.cache = {}
    creatureNames.tries = {}
    local seen = {}
    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        for _, boss in ipairs(inst.bosses or {}) do
            for _, npcID in ipairs(boss.npcs or {}) do
                if not seen[npcID] then
                    seen[npcID] = true
                    AzerothCompendium:GetCreatureName(npcID)
                end
            end
        end
    end

    if AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
end

creatureNames.preloadPending = true
creatureNames.frame = CreateFrame("Frame")
creatureNames.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
creatureNames.frame:SetScript("OnEvent", function()
    if creatureNames.preloadPending then AzerothCompendium:PreloadCreatureNames() end
end)

function AzerothCompendium:GetBossCreatureName(boss)
    if type(boss.name) ~= "string" or not boss.name:find(" / ", 1, true) then return AzerothCompendium:GetCreatureName(boss.npcs[1]) end
    local names, seen = {}, {}
    for _, npcID in ipairs(boss.npcs) do
        local name = AzerothCompendium:GetCreatureName(npcID)
        if name == nil then return nil end
        if not seen[name] then
            seen[name] = true
            tinsert(names, name)
        end
    end

    return table.concat(names, " / ")
end

local learnedBossLevels = {bosses = nil}

function AzerothCompendium:GetUnlevelledBosses()
    if learnedBossLevels.bosses then return learnedBossLevels.bosses end
    local bosses = {}
    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        for _, boss in ipairs(inst.bosses or {}) do
            if boss.level == nil or boss.learnedLevel then
                for _, npcID in ipairs(boss.npcs or {}) do
                    bosses[npcID] = bosses[npcID] or {}
                    tinsert(bosses[npcID], boss)
                end
            end
        end
    end

    learnedBossLevels.bosses = bosses

    return bosses
end

function AzerothCompendium:ApplyLearnedBossLevels()
    ACOTAB = ACOTAB or {}
    if type(ACOTAB["BOSSLEVELS"]) ~= "table" then ACOTAB["BOSSLEVELS"] = {} end
    local bosses = AzerothCompendium:GetUnlevelledBosses()
    for npcID, level in pairs(ACOTAB["BOSSLEVELS"]) do
        for _, boss in ipairs(bosses[npcID] or {}) do
            if boss.npcs[1] == npcID then
                boss.level = level
                boss.learnedLevel = true
            end
        end
    end
end

function AzerothCompendium:LearnBossLevel(unit)
    if not UnitExists(unit) or UnitIsPlayer(unit) then return end
    local guid = UnitGUID(unit)
    if issecretvalue and issecretvalue(guid) then return end
    if type(guid) ~= "string" then return end
    local unitType, _, _, _, _, npcID = strsplit("-", guid)
    if unitType ~= "Creature" then return end
    npcID = tonumber(npcID)
    local bosses = npcID and AzerothCompendium:GetUnlevelledBosses()[npcID]
    if bosses == nil then return end
    local level = UnitLevel(unit)
    if issecretvalue and issecretvalue(level) then return end
    if type(level) ~= "number" or level <= 0 then return end
    ACOTAB = ACOTAB or {}
    if type(ACOTAB["BOSSLEVELS"]) ~= "table" then ACOTAB["BOSSLEVELS"] = {} end
    if ACOTAB["BOSSLEVELS"][npcID] == level then return end
    ACOTAB["BOSSLEVELS"][npcID] = level
    AzerothCompendium:ApplyLearnedBossLevels()
    if AzerothCompendium.RefreshCompendium then AzerothCompendium:RefreshCompendium() end
end

learnedBossLevels.frame = CreateFrame("Frame")
learnedBossLevels.frame:RegisterEvent("PLAYER_LOGIN")
learnedBossLevels.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
learnedBossLevels.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
learnedBossLevels.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
learnedBossLevels.frame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        AzerothCompendium:ApplyLearnedBossLevels()
    elseif event == "PLAYER_TARGET_CHANGED" then
        AzerothCompendium:LearnBossLevel("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        AzerothCompendium:LearnBossLevel("mouseover")
    elseif unit then
        AzerothCompendium:LearnBossLevel(unit)
    end
end)

function AzerothCompendium:GetBossName(boss)
    if boss == nil then return "" end
    if boss.all then return AzerothCompendium:Trans("LID_ALLLOOT") end
    if boss.trash then return AzerothCompendium:Trans("LID_TRASH") end
    if boss.standing ~= nil then
        local label = _G["FACTION_STANDING_LABEL" .. (boss.standing + 1)]
        if type(label) == "string" and label ~= "" then return label end

        return boss.name
    end

    if boss.rank ~= nil then return AzerothCompendium:Trans("LID_RANK", nil, boss.rank) end
    if boss.npcs and boss.npcs[1] and AzerothCompendium:GetLanguage() == GetLocale() then
        local live = AzerothCompendium:GetBossCreatureName(boss)
        if live then return live end
    end

    local names = AzerothCompendium:GetLanguage() == "deDE" and AzerothCompendium.BOSSNAMES or nil
    if names and boss.npcs and boss.npcs[1] then
        local localized = names[boss.npcs[1]]
        if localized then return localized end
    end

    return boss.name
end

function AzerothCompendium:IsQuestForFlavor(questID)
    return AzerothCompendium:GetFlavor() == FLAVOR_FOREVER or not (AzerothCompendium.QUESTFOREVER and AzerothCompendium.QUESTFOREVER[questID])
end

function AzerothCompendium:IsQuestSideVisible(side)
    if side ~= 1 and side ~= 2 then return true end
    local default = IsOpposingQuestSide(1) and 2 or 1
    if type(ACOTAB) == "table" then
        if ACOTAB.SHOWALLIANCEQUESTS == true and ACOTAB.SHOWHORDEQUESTS == false then default = 1 end
        if ACOTAB.SHOWHORDEQUESTS == true and ACOTAB.SHOWALLIANCEQUESTS == false then default = 2 end
    end
    return self:GetConfig("QUESTFACTION", default) == side
end

function AzerothCompendium:GetInstanceQuests(inst)
    if inst == nil or inst.id == nil then return {} end

    local quests = AzerothCompendium.QUESTS and AzerothCompendium.QUESTS[inst.id] or {}
    local available = {}
    for _, quest in ipairs(quests) do
        if AzerothCompendium:IsQuestForFlavor(quest[1]) and not (AzerothCompendium.UNAVAILABLEQUESTS and AzerothCompendium.UNAVAILABLEQUESTS[quest[1]]) and AzerothCompendium:IsQuestSideVisible(quest[3]) then
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

function AzerothCompendium:GetQuestClasses(questID)
    local mask = AzerothCompendium.QUESTCLASSES and AzerothCompendium.QUESTCLASSES[questID]
    if type(mask) ~= "number" or mask <= 0 or bit == nil or GetClassInfo == nil then return nil end
    local classes = {}
    for classID = 1, 13 do
        if bit.band(mask, 2 ^ (classID - 1)) ~= 0 then
            local name, file = GetClassInfo(classID)
            if name and file then tinsert(classes, {name, file}) end
        end
    end

    return #classes > 0 and classes or nil
end

function AzerothCompendium:IsQuestForPlayerClass(questID)
    local mask = AzerothCompendium.QUESTCLASSES and AzerothCompendium.QUESTCLASSES[questID]
    if type(mask) ~= "number" or mask <= 0 or bit == nil then return true end
    local _, _, classID = UnitClass("player")
    if type(classID) ~= "number" then return true end

    return bit.band(mask, 2 ^ (classID - 1)) ~= 0
end

function AzerothCompendium:GetQuestClassText(questID)
    local classes = AzerothCompendium:GetQuestClasses(questID)
    if classes == nil then return nil end
    local own = AzerothCompendium:IsQuestForPlayerClass(questID)
    local names = {}
    for _, class in ipairs(classes) do
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class[2]]
        if own and color and color.colorStr then
            tinsert(names, "|c" .. color.colorStr .. class[1] .. "|r")
        elseif own then
            tinsert(names, class[1])
        else
            tinsert(names, "|cffff4040" .. class[1] .. "|r")
        end
    end

    return table.concat(names, ", ")
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
    local side = questSidesByID[questID] or AzerothCompendium.QUESTSIDES and AzerothCompendium.QUESTSIDES[questID]

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

function AzerothCompendium:IsQuestReadyForTurnIn(questID)
    if not AzerothCompendium:IsQuestActive(questID) then return false end
    if C_QuestLog then
        for _, name in ipairs({"ReadyForTurnIn", "IsComplete"}) do
            local fn = C_QuestLog[name]
            if type(fn) == "function" then
                local ok, done = pcall(fn, questID)
                if ok and done ~= nil then return done == true end
            end
        end
    end

    if GetQuestLogIndexByID and GetQuestLogTitle then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and type(index) == "number" and index > 0 then
            local isComplete = select(6, GetQuestLogTitle(index))

            return isComplete == 1 or isComplete == true
        end
    end

    return false
end

function AzerothCompendium:GetQuestChain(questID)
    local quests = {}
    local seen = {}
    local function AddQuest(id, depth, prerequisiteChain)
        if not AzerothCompendium:IsQuestForFlavor(id) then return end
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

function AzerothCompendium:GetQuestRewards(questID)
    return AzerothCompendium.QUESTREWARDS and AzerothCompendium.QUESTREWARDS[questID]
end

function AzerothCompendium:GetQuestRewardXP(questID)
    local rewards = AzerothCompendium:GetQuestRewards(questID)
    local baseXP = rewards and rewards.xp or 0
    if AzerothCompendium:GetFlavor() ~= FLAVOR_FOREVER then return baseXP end

    local tunedXP = AzerothCompendium.QUESTXPFOREVERTUNING and AzerothCompendium.QUESTXPFOREVERTUNING[questID]
    if type(GetQuestLogRewardXP) == "function" then
        local ok, liveXP = pcall(GetQuestLogRewardXP, questID)
        if ok and type(liveXP) == "number" and not AzerothCompendium:IsSecret(liveXP) and liveXP > 0 then
            if tunedXP and liveXP == baseXP then return tunedXP end

            return liveXP
        end
    end

    return tunedXP or baseXP
end

local function IsQuestHidden(questID)
    if not AzerothCompendium:IsQuestForFlavor(questID) then return true end
    if AzerothCompendium.UNAVAILABLEQUESTS and AzerothCompendium.UNAVAILABLEQUESTS[questID] then return true end

    local quest = AzerothCompendium:GetQuestDataByID(questID)
    return not AzerothCompendium:IsQuestSideVisible(quest and quest[3] or AzerothCompendium.QUESTSIDES and AzerothCompendium.QUESTSIDES[questID])
end

local questFollowUps = nil
local function GetQuestFollowUps()
    if questFollowUps then return questFollowUps end
    questFollowUps = {}
    local seen = {}
    local function Add(parentID, childID)
        if parentID == childID then return end
        seen[parentID] = seen[parentID] or {}
        if seen[parentID][childID] then return end
        seen[parentID][childID] = true
        questFollowUps[parentID] = questFollowUps[parentID] or {}
        tinsert(questFollowUps[parentID], childID)
    end

    for _, chain in pairs(AzerothCompendium.QUESTCHAINS or {}) do
        for index = 2, #chain do
            Add(chain[index - 1], chain[index])
        end
    end

    for childID, prerequisites in pairs(AzerothCompendium.QUESTPREREQUISITES or {}) do
        for _, parentID in ipairs(prerequisites) do
            Add(parentID, childID)
        end
    end

    for parentID, children in pairs(AzerothCompendium.QUESTFOLLOWUPS or {}) do
        for _, childID in ipairs(children) do
            Add(parentID, childID)
        end
    end

    return questFollowUps
end

function AzerothCompendium:GetInstanceByID(id)
    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        if inst.id == id then return inst end
    end

    return nil
end

function AzerothCompendium:GetAttunement(inst)
    if inst == nil or inst.id == nil then return nil end

    return AzerothCompendium.ATTUNEMENTS and AzerothCompendium.ATTUNEMENTS[inst.id]
end

function AzerothCompendium:RequiresAttunement(inst)
    local attunement = AzerothCompendium:GetAttunement(inst)

    return attunement ~= nil and attunement.opens == nil
end

function AzerothCompendium:HasAttunementKey(itemID)
    if itemID == nil then return false end
    local getCount = C_Item and C_Item.GetItemCount or GetItemCount
    if getCount then
        local ok, count = pcall(getCount, itemID)
        if ok and type(count) == "number" and count > 0 then return true end
    end

    local container = KEYRING_CONTAINER or -2
    local getSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local getItemID = C_Container and C_Container.GetContainerItemID or GetContainerItemID
    if getSlots == nil or getItemID == nil then return false end
    local ok, slots = pcall(getSlots, container)
    if not ok or type(slots) ~= "number" then return false end
    for slot = 1, slots do
        local okItem, id = pcall(getItemID, container, slot)
        if okItem and id == itemID then return true end
    end

    return false
end

function AzerothCompendium:IsAttuned(inst)
    if not AzerothCompendium:RequiresAttunement(inst) then return true end
    local attunement = AzerothCompendium:GetAttunement(inst)
    if attunement.key ~= nil and AzerothCompendium:HasAttunementKey(attunement.key) then return true end
    for _, questID in ipairs(attunement.done or {}) do
        if AzerothCompendium:IsQuestCompleted(questID) then return true end
    end

    return attunement.key == nil
end

function AzerothCompendium:GetInstanceQuestGraph(inst, filter)
    local nodes = {}
    local list = {}
    local inInstance = {}
    for _, quest in ipairs(AzerothCompendium:GetInstanceQuests(inst)) do
        inInstance[quest[1]] = quest
    end

    local function GetNode(id)
        local node = nodes[id]
        if node == nil then
            node = {
                id = id,
                quest = inInstance[id] or AzerothCompendium:GetQuestDataByID(id),
                instance = inInstance[id] ~= nil,
                parents = {},
                children = {},
                parentSet = {}
            }

            nodes[id] = node
            tinsert(list, node)
        end

        return node
    end

    local function Link(parentID, childID)
        if parentID == childID then return end
        local child = GetNode(childID)
        if child.parentSet[parentID] then return end
        local parent = GetNode(parentID)
        child.parentSet[parentID] = true
        tinsert(child.parents, parent)
        tinsert(parent.children, child)
    end

    local visited = {}
    local function Visit(id)
        if visited[id] then return end
        visited[id] = true
        GetNode(id)
        local chain = AzerothCompendium.QUESTCHAINS and AzerothCompendium.QUESTCHAINS[id]
        if chain then
            local previous = nil
            for _, chainID in ipairs(chain) do
                if not IsQuestHidden(chainID) then
                    if previous ~= nil then Link(previous, chainID) end
                    previous = chainID
                end

                if chainID == id then break end
            end

            for _, chainID in ipairs(chain) do
                if chainID == id then break end
                if not IsQuestHidden(chainID) then Visit(chainID) end
            end
        end

        for _, prerequisiteID in ipairs(AzerothCompendium.QUESTPREREQUISITES and AzerothCompendium.QUESTPREREQUISITES[id] or {}) do
            if not IsQuestHidden(prerequisiteID) then
                Link(prerequisiteID, id)
                Visit(prerequisiteID)
            end
        end
    end

    for id in pairs(inInstance) do
        Visit(id)
    end

    local attunement = AzerothCompendium:GetAttunement(inst)
    local attuneSet = {}
    for _, quest in ipairs(attunement and attunement.quests or {}) do
        if AzerothCompendium:IsQuestForFlavor(quest[1]) and AzerothCompendium:IsQuestSideVisible(quest[2]) then
            attuneSet[quest[1]] = true
            Visit(quest[1])
        end
    end

    for _, link in ipairs(attunement and attunement.links or {}) do
        if (attuneSet[link[1]] or nodes[link[1]] ~= nil) and (attuneSet[link[2]] or nodes[link[2]] ~= nil) then Link(link[1], link[2]) end
    end

    local followUps = GetQuestFollowUps()
    local expanded = {}
    local queue = {}
    for id in pairs(inInstance) do
        tinsert(queue, id)
    end

    while #queue > 0 do
        local id = tremove(queue)
        if not expanded[id] then
            expanded[id] = true
            for _, childID in ipairs(followUps[id] or {}) do
                if not IsQuestHidden(childID) then
                    Visit(childID)
                    Link(id, childID)
                    tinsert(queue, childID)
                end
            end
        end
    end

    if filter ~= nil then
        local matched = {}
        local function AncestorMatches(node, seen)
            if matched[node] ~= nil then return matched[node] end
            if seen[node] then return false end
            seen[node] = true
            local result = filter(node) == true
            for _, parent in ipairs(node.parents) do
                if not result and AncestorMatches(parent, seen) then result = true end
            end

            matched[node] = result

            return result
        end

        local keep = {}
        local function Keep(node)
            if keep[node] then return end
            keep[node] = true
            for _, parent in ipairs(node.parents) do
                Keep(parent)
            end
        end

        for _, node in ipairs(list) do
            if node.instance and AncestorMatches(node, {}) then Keep(node) end
        end

        local filtered = {}
        for _, node in ipairs(list) do
            if keep[node] then
                local parents = {}
                local children = {}
                for _, parent in ipairs(node.parents) do
                    if keep[parent] then tinsert(parents, parent) end
                end

                for _, child in ipairs(node.children) do
                    if keep[child] then tinsert(children, child) end
                end

                node.parents = parents
                node.children = children
                tinsert(filtered, node)
            end
        end

        list = filtered
    end

    local function IsBottom(node, stack)
        if node.bottom ~= nil then return node.bottom end
        if node.instance then
            node.bottom = true

            return true
        end

        if stack[node] then return false end
        stack[node] = true
        local bottom = false
        for _, parent in ipairs(node.parents) do
            if IsBottom(parent, stack) then bottom = true end
        end

        stack[node] = nil
        node.bottom = bottom

        return bottom
    end

    local inside = AzerothCompendium.QUESTINSIDE or {}
    local startInside = AzerothCompendium.QUESTSTARTINSIDE or {}
    local hasInside = false
    for _, node in ipairs(list) do
        if node.instance and (inside[node.id] or startInside[node.id]) then hasInside = true end
    end

    local anchors = {}
    local IsAnchor
    local function HasAnchorAncestor(node, stack)
        if stack[node] then return false end
        stack[node] = true
        for _, parent in ipairs(node.parents) do
            if IsAnchor(parent) or HasAnchorAncestor(parent, stack) then return true end
        end

        return false
    end

    IsAnchor = function(node)
        if anchors[node] == nil then
            anchors[node] = false
            anchors[node] = node.instance and (inside[node.id] or not hasInside or startInside[node.id] and not HasAnchorAncestor(node, {})) and true or false
        end

        return anchors[node]
    end
    local afterInstance = AzerothCompendium.QUESTAFTERINSTANCE or {}
    local function IsAfterSeed(node)
        return IsAnchor(node) or (node.instance and (startInside[node.id] == true or afterInstance[node.id] == true))
    end

    local function Reaches(node, key, cache, stack)
        if cache[node] ~= nil then return cache[node] end
        if stack[node] then return false end
        stack[node] = true
        local result = false
        local Seed = key == "parents" and IsAfterSeed or IsAnchor
        for _, other in ipairs(node[key]) do
            if Seed(other) or Reaches(other, key, cache, stack) then result = true end
        end

        stack[node] = nil
        cache[node] = result

        return result
    end

    local afterAnchor = {}
    for _, node in ipairs(list) do
        IsBottom(node, {})
        local anchor = IsAnchor(node)
        local after = IsAfterSeed(node) or Reaches(node, "parents", afterAnchor, {})
        node.outside = nil
        if attuneSet[node.id] and not node.instance then
            node.section = 1
        elseif anchor then
            node.section = 3
        elseif after then
            node.section = 4
        else
            node.section = 2
        end

        node.name = node.quest and AzerothCompendium:GetQuestName(node.quest) or AzerothCompendium:GetQuestNameByID(node.id)
        node.level = AzerothCompendium:GetQuestRecommendedLevel(node.quest or node.id)
    end

    local attuneCopies = {}
    for _, node in ipairs(list) do
        if attuneSet[node.id] and node.instance then
            local copy = {
                id = node.id,
                quest = node.quest,
                instance = false,
                bottom = false,
                section = 1,
                name = node.name,
                level = node.level,
                parents = node.parents,
                children = {node},
                parentSet = node.parentSet
            }

            for _, parent in ipairs(node.parents) do
                for index, child in ipairs(parent.children) do
                    if child == node then parent.children[index] = copy end
                end
            end

            node.parents = {copy}
            node.parentSet = {[node.id] = true}
            tinsert(attuneCopies, copy)
        end
    end

    for _, copy in ipairs(attuneCopies) do
        tinsert(list, copy)
    end

    list.attunement = attunement

    return list
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

function AzerothCompendium:GetQuestGiverLocation(questID)
    local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[questID]
    if giver == nil then return nil end
    if giver[7] == nil then return giver[1], giver[2], giver[3] end
    local entrance = AzerothCompendium.INSTANCEENTRANCES and AzerothCompendium.INSTANCEENTRANCES[giver[7]]
    if entrance == nil then return nil end

    return entrance[1], entrance[2], entrance[3], entrance[4] or giver[7]
end

function AzerothCompendium:GetQuestGiverInstanceName(instanceID)
    if instanceID == nil then return nil end
    for _, inst in ipairs(AzerothCompendium.INSTANCES or {}) do
        if inst.id == instanceID or inst.parentID == instanceID then return AzerothCompendium:GetInstanceBaseName(inst) end
    end

    return nil
end

function AzerothCompendium:SetQuestWaypoint(questID)
    local giver = AzerothCompendium.QUESTGIVERS and AzerothCompendium.QUESTGIVERS[questID]
    if giver == nil then return false end
    if giver[6] == true then return false end
    local mapID, x, y = AzerothCompendium:GetQuestGiverLocation(questID)

    return AzerothCompendium:SetMapWaypoint(mapID, x, y)
end

local function GetQuestLogIndex(questID)
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        if ok and type(index) == "number" and index > 0 then return index end
    end

    if GetQuestLogIndexByID then
        local ok, index = pcall(GetQuestLogIndexByID, questID)
        if ok and type(index) == "number" and index > 0 then return index end
    end

    return nil
end

local function IsPlayerInGroup()
    if IsInGroup then return IsInGroup() end
    if GetNumGroupMembers then return GetNumGroupMembers() > 0 end

    return false
end

function AzerothCompendium:ShareQuest(questID)
    if QuestLogPushQuest == nil then return false, "unsupported" end
    if not IsPlayerInGroup() then return false, "nogroup" end
    local index = GetQuestLogIndex(questID)
    if index == nil then return false, "notinlog" end
    if C_QuestLog and C_QuestLog.IsPushableQuest and C_QuestLog.SetSelectedQuest then
        if not C_QuestLog.IsPushableQuest(questID) then return false, "notshareable" end
        C_QuestLog.SetSelectedQuest(questID)
        QuestLogPushQuest()

        return true
    end

    if SelectQuestLogEntry == nil or GetQuestLogPushable == nil then return false, "unsupported" end
    local previous = GetQuestLogSelection and GetQuestLogSelection()
    SelectQuestLogEntry(index)
    local pushable = GetQuestLogPushable()
    if pushable then QuestLogPushQuest() end
    if previous and previous > 0 then SelectQuestLogEntry(previous) end
    if not pushable then return false, "notshareable" end

    return true
end

local function GetInstanceLocation(locations, inst)
    if inst == nil or locations == nil then return nil end

    return locations[inst.id] or (inst.parentID and locations[inst.parentID]) or locations[inst.id * 1000 + 1]
end

local function GetLocationZoneName(location)
    local info = location and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(location[1])

    return info and info.name
end

local function SetLocationWaypoint(location)
    if location == nil then return false end

    return AzerothCompendium:SetMapWaypoint(location[1], location[2], location[3])
end

function AzerothCompendium:GetInstanceEntrance(inst)
    return GetInstanceLocation(AzerothCompendium.INSTANCEENTRANCES, inst)
end

function AzerothCompendium:GetInstanceEntranceZoneName(inst)
    return GetLocationZoneName(AzerothCompendium:GetInstanceEntrance(inst))
end

function AzerothCompendium:SetInstanceEntranceWaypoint(inst)
    return SetLocationWaypoint(AzerothCompendium:GetInstanceEntrance(inst))
end

function AzerothCompendium:GetInstanceMeetingStone(inst)
    return GetInstanceLocation(AzerothCompendium.MEETINGSTONES, inst)
end

function AzerothCompendium:GetInstanceMeetingStoneZoneName(inst)
    return GetLocationZoneName(AzerothCompendium:GetInstanceMeetingStone(inst))
end

function AzerothCompendium:SetInstanceMeetingStoneWaypoint(inst)
    return SetLocationWaypoint(AzerothCompendium:GetInstanceMeetingStone(inst))
end

function AzerothCompendium:SetMapWaypoint(mapID, x, y)
    if mapID == nil then return false end
    if InCombatLockdown and InCombatLockdown() then return false, "combat" end

    return AzerothCompendium:SetTrackedWaypoint(mapID, x / 100, y / 100)
end

function AzerothCompendium:CanOpenWorldMapTo()
    return C_Map ~= nil and C_Map.OpenWorldMap ~= nil
end

function AzerothCompendium:OpenWorldMapTo(mapID)
    if mapID == nil or not AzerothCompendium:CanOpenWorldMapTo() then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    C_Map.OpenWorldMap(mapID)

    return true
end

local mapOpener

local WORLD_MAP_CLICK_BUTTONS = {"MiniMapWorldMapButton", "QuestLogMicroButton"}

local function GetWorldMapClickButton()
    for _, name in ipairs(WORLD_MAP_CLICK_BUTTONS) do
        local button = _G[name]
        if type(button) == "table" and button.Click ~= nil and not (button.IsForbidden and button:IsForbidden()) then return button end
    end

    return nil
end

local function IsMapOpenerLocked()
    return InCombatLockdown ~= nil and InCombatLockdown()
end

local function ReleaseMapOpener()
    if mapOpener == nil or IsMapOpenerLocked() then return end
    local owner = mapOpener.owner
    mapOpener.owner = nil
    mapOpener.onClick = nil
    mapOpener:Hide()
    if owner and owner.UnlockHighlight then owner:UnlockHighlight() end
end

local function CreateMapOpener()
    local opener = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    opener:SetFrameStrata("FULLSCREEN_DIALOG")
    if SecureActionButton_ShouldUseOnKeyDown then
        opener:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    else
        opener:RegisterForClicks("LeftButtonUp")
    end
    opener:Hide()
    opener:SetScript("PreClick", function(sel, _, down)
        if SecureActionButton_ShouldUseOnKeyDown and (down == true) ~= (SecureActionButton_ShouldUseOnKeyDown(sel) == true) then return end
        local opened = false
        if sel.owner and sel.onClick then opened = sel.onClick(sel.owner) == true end
        if WorldMapFrame and WorldMapFrame:IsShown() then opened = false end
        sel:SetAttribute("type1", opened and "click" or nil)
        sel:SetAttribute("clickbutton1", opened and GetWorldMapClickButton() or nil)
    end)

    opener:SetScript("OnEnter", function(sel)
        local owner = sel.owner
        if owner == nil then return end
        if owner.LockHighlight then owner:LockHighlight() end
        local onEnter = owner:GetScript("OnEnter")
        if onEnter then onEnter(owner) end
    end)

    opener:SetScript("OnLeave", function(sel)
        local owner = sel.owner
        ReleaseMapOpener()
        local onLeave = owner and owner:GetScript("OnLeave")
        if onLeave then onLeave(owner) end
    end)

    opener:SetScript("OnUpdate", function(sel)
        local owner = sel.owner
        if owner == nil or not owner:IsVisible() or not owner:IsMouseOver() then
            local onLeave = owner and owner:GetScript("OnLeave")
            ReleaseMapOpener()
            if onLeave then onLeave(owner) end
        end
    end)

    opener:RegisterEvent("PLAYER_REGEN_DISABLED")
    opener:SetScript("OnEvent", ReleaseMapOpener)

    return opener
end

function AzerothCompendium:AttachMapOpener(owner, onClick)
    if owner == nil or IsMapOpenerLocked() or GetWorldMapClickButton() == nil then return false end
    if mapOpener == nil then mapOpener = CreateMapOpener() end
    if mapOpener.owner == owner then return true end
    local left, bottom, width, height = owner:GetRect()
    if left == nil then return false end
    local ratio = owner:GetEffectiveScale() / UIParent:GetEffectiveScale()
    mapOpener.owner = owner
    mapOpener.onClick = onClick
    mapOpener:ClearAllPoints()
    mapOpener:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * ratio, bottom * ratio)
    mapOpener:SetSize(width * ratio, height * ratio)
    mapOpener:Show()

    return true
end

function AzerothCompendium:IsForeverItem(itemID)
    return type(itemID) == "number" and itemID >= FOREVER_ITEM_MIN
end

function AzerothCompendium:UpdateInstanceLevelRanges()
    self.instanceLevelRanges = self.instanceLevelRanges or {defaults = {}}
    local state = self.instanceLevelRanges
    if state.activities == nil and self:GetFlavor() == FLAVOR_FOREVER and C_LFGList and C_LFGList.GetActivityInfoTable then
        local activities = {}
        for id = 1, 2000 do
            local info = C_LFGList.GetActivityInfoTable(id)
            if info and (info.categoryID == 2 or info.categoryID == 3) and type(info.mapID) == "number" and info.mapID > 0 and type(info.minLevelSuggestion) == "number" and type(info.maxLevelSuggestion) == "number" and info.minLevelSuggestion > 0 and info.maxLevelSuggestion >= info.minLevelSuggestion then
                local previous = activities[info.mapID]
                if previous == nil then
                    activities[info.mapID] = {minLevel = info.minLevelSuggestion, maxLevel = info.maxLevelSuggestion}
                elseif previous.minLevel ~= info.minLevelSuggestion or previous.maxLevel ~= info.maxLevelSuggestion then
                    previous.ambiguous = true
                end
            end
        end
        if next(activities) then state.activities = activities end
    end

    local changed = false
    for _, inst in ipairs(self.INSTANCES or {}) do
        if state.defaults[inst] == nil then
            state.defaults[inst] = {minLevel = inst.minLevel, maxLevel = inst.maxLevel}
        end
        local range = self:GetFlavor() == FLAVOR_FOREVER and state.activities and not inst.parentID and state.activities[inst.id]
        if not range or range.ambiguous then range = state.defaults[inst] end
        if inst.minLevel ~= range.minLevel or inst.maxLevel ~= range.maxLevel then
            inst.minLevel = range.minLevel
            inst.maxLevel = range.maxLevel
            changed = true
        end
    end
    if changed then byType = nil end
end

function AzerothCompendium:GetInstances(kind)
    self:UpdateInstanceLevelRanges()
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

        for _, levelKind in ipairs({"dungeon", "raid"}) do
            local order = {}
            for index, inst in ipairs(byType[levelKind]) do
                order[inst] = index
            end

            table.sort(byType[levelKind], function(a, b)
                local aMin, bMin = a.minLevel or math.huge, b.minLevel or math.huge
                if aMin ~= bMin then return aMin < bMin end
                local aMax, bMax = a.maxLevel or math.huge, b.maxLevel or math.huge
                if aMax ~= bMax then return aMax < bMax end

                return order[a] < order[b]
            end)
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

    for _, entry in ipairs(AzerothCompendium.WORLDQUESTITEMS or {}) do
        tinsert(queue, entry.itemID)
        if C_QuestLog and C_QuestLog.RequestLoadQuestByID then C_QuestLog.RequestLoadQuestByID(entry.questID) end
    end

    for _, rewards in pairs(AzerothCompendium.QUESTREWARDS or {}) do
        for _, list in ipairs({rewards.items or {}, rewards.choices or {}}) do
            for _, entry in ipairs(list) do
                tinsert(queue, entry[1])
            end
        end
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
