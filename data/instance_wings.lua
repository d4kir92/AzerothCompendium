local _, AzerothCompendium = ...
local SPLITS = {
    [189] = {
        {
            ["id"] = 189001,
            ["wing"] = "LID_WING_GRAVEYARD",
            ["minLevel"] = 26,
            ["maxLevel"] = 36,
            ["npcs"] = {3983,6490,6488,6489,4543},
            ["quests"] = {1051,1113},
            ["trash"] = {5819,7727,7728,7754,10332,2262,7787,7729,7761,7752,8226,7786,7753,7730},
            ["loot"] = {
                {2262,0.02},
                {5819,0.66},
                {7727,0.07},
                {7728,0.32},
                {7729,0.04},
                {7730,0.03},
                {7752,0.05},
                {7753,0.06},
                {7754,0.07},
                {7761,0.03},
                {7786,0.06},
                {7787,0.15},
                {8226,0.07},
                {10332,0.03},
            },
        },
        {
            ["id"] = 189002,
            ["wing"] = "LID_WING_LIBRARY",
            ["minLevel"] = 29,
            ["maxLevel"] = 39,
            ["npcs"] = {3974,6487},
            ["quests"] = {1049,1050,1160,1048,1053},
            ["trash"] = {5819,7755,7727,7728,7759,7760,7754,10332,1992,2262,7787,7729,7761,7752,8226,7786,5756,7736,8225,7753,7730,7758,7757},
            ["loot"] = {
                {1992},
                {2262,0.02},
                {5756,0.02},
                {5819,0.66},
                {7727,0.07},
                {7728,0.32},
                {7729,0.04},
                {7730,0.03},
                {7736},
                {7752,0.05},
                {7753,0.06},
                {7754,0.07},
                {7755},
                {7757,0.17},
                {7758},
                {7759,0.03},
                {7760},
                {7761,0.03},
                {7786,0.06},
                {7787,0.15},
                {8225,0.26},
                {8226,0.07},
                {10332,0.03},
            },
        },
        {
            ["id"] = 189003,
            ["wing"] = "LID_WING_ARMORY",
            ["minLevel"] = 32,
            ["maxLevel"] = 42,
            ["npcs"] = {3975},
            ["quests"] = {1048,1053},
            ["trash"] = {5819,7755,7727,7728,7759,7754,10332,1992,2262,7787,7729,7761,7752,8226,7786,5756,7736,8225,7753,7730,7757,10333,10329,23192},
            ["loot"] = {
                {1992},
                {2262,0.02},
                {5756,0.02},
                {5819,0.66},
                {7727,0.07},
                {7728,0.32},
                {7729,0.04},
                {7730,0.03},
                {7736},
                {7752,0.05},
                {7753,0.06},
                {7754,0.07},
                {7755},
                {7757,0.17},
                {7759,0.03},
                {7761,0.03},
                {7786,0.06},
                {7787,0.15},
                {8225,0.26},
                {8226,0.07},
                {10329,2.58},
                {10332,0.03},
                {10333,2.65},
                {23192},
            },
        },
        {
            ["id"] = 189004,
            ["wing"] = "LID_WING_CATHEDRAL",
            ["minLevel"] = 35,
            ["maxLevel"] = 45,
            ["npcs"] = {4542,3976,3977},
            ["quests"] = {1048,1053},
            ["trash"] = {5819,7755,7727,7728,7759,7760,7754,10332,1992,2262,7787,7729,7761,7752,8226,7786,5756,7736,8225,7753,7730,7758,7757,10328,10331,10329},
            ["loot"] = {
                {1992},
                {2262,0.02},
                {5756,0.02},
                {5819,0.66},
                {7727,0.07},
                {7728,0.32},
                {7729,0.04},
                {7730,0.03},
                {7736},
                {7752,0.05},
                {7753,0.06},
                {7754,0.07},
                {7755},
                {7757,0.17},
                {7758},
                {7759,0.03},
                {7760},
                {7761,0.03},
                {7786,0.06},
                {7787,0.15},
                {8225,0.26},
                {8226,0.07},
                {10328,0.3},
                {10329,2.58},
                {10331,2.18},
                {10332,0.03},
            },
        },
    },
}

local function FindBoss(inst, npcID)
    for _, boss in ipairs(inst.bosses or {}) do
        for _, id in ipairs(boss.npcs or {}) do
            if id == npcID then return boss end
        end
    end

    return nil
end

local function FindQuest(list, questID)
    for _, quest in ipairs(list or {}) do
        if quest[1] == questID then return quest end
    end

    return nil
end

local function BuildWing(inst, split)
    local wing = {}
    for key, value in pairs(inst) do
        wing[key] = value
    end

    wing.id = split.id
    wing.wing = split.wing
    wing.parentID = inst.id
    wing.minLevel = split.minLevel
    wing.maxLevel = split.maxLevel
    wing.bosses = {}
    for _, npcID in ipairs(split.npcs) do
        local boss = FindBoss(inst, npcID)
        if boss then tinsert(wing.bosses, boss) end
    end

    local trash = {}
    if split.loot then
        for _, entry in ipairs(split.loot) do
            tinsert(trash, entry)
        end
    else
        for _, itemID in ipairs(split.trash) do
            tinsert(trash, {itemID})
        end
    end

    tinsert(wing.bosses, {
        ["name"] = "Trash",
        ["trash"] = true,
        ["loot"] = trash,
    })

    local quests = AzerothCompendium.QUESTS and AzerothCompendium.QUESTS[inst.id]
    if quests then
        local wingQuests = {}
        for _, questID in ipairs(split.quests) do
            local quest = FindQuest(quests, questID)
            if quest then tinsert(wingQuests, quest) end
        end

        AzerothCompendium.QUESTS[split.id] = wingQuests
    end

    for _, source in ipairs({AzerothCompendium.LOADINGSCREENS, AzerothCompendium.LOADINGSCREENS_WIDE}) do
        if source and source[inst.id] then source[split.id] = source[inst.id] end
    end

    return wing
end

local instances = AzerothCompendium.INSTANCES or {}
for index = #instances, 1, -1 do
    local inst = instances[index]
    local splits = SPLITS[inst.id]
    if splits then
        tremove(instances, index)
        for offset, split in ipairs(splits) do
            tinsert(instances, index + offset - 1, BuildWing(inst, split))
        end

        if AzerothCompendium.QUESTS then AzerothCompendium.QUESTS[inst.id] = nil end
    end
end
