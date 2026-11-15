local _, AzerothCompendium = ...
local instance = {
	["id"] = 900004,
	["name"] = "Blackmaw Hold",
	["type"] = "dungeon",
	["minLevel"] = 55,
	["maxLevel"] = 60,
	["forever"] = true,
	["bosses"] = {},
	["areaID"] = 16554,
}
local trash = {}
tinsert(AzerothCompendium.INSTANCES, instance)
AzerothCompendium.TRASH[instance.name] = trash
