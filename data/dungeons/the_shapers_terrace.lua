local _, AzerothCompendium = ...
local instance = {
	["id"] = 900005,
	["name"] = "The Shaper's Terrace",
	["type"] = "dungeon",
	["minLevel"] = 58,
	["maxLevel"] = 60,
	["forever"] = true,
	["bosses"] = {},
	["areaID"] = 16667,
}
local trash = {}
tinsert(AzerothCompendium.INSTANCES, instance)
AzerothCompendium.TRASH[instance.name] = trash
