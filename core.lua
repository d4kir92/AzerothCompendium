local _, AzerothCompendium = ...
local ADDON = "AzerothCompendium"
local ICON = 133737
AzerothCompendium:SetAddonOutput(ADDON, ICON)
local byType = nil
local preloaded = false
local FOREVER_ITEM_MIN = 200000
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
