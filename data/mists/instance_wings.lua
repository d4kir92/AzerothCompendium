local _, AzerothCompendium = ...
local SPLITS = {}

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
