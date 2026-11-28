local _, AzerothCompendium = ...
local instance = {
	["id"] = 900005,
	["name"] = "The Shaper's Terrace",
	["type"] = "dungeon",
	["minLevel"] = 58,
	["maxLevel"] = 60,
	["forever"] = true,
	["bosses"] = {
		{
			["name"] = "Titanosaur",
			["npcs"] = {253201},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Izha'Rel / Tor'Rel",
			["npcs"] = {253218, 261811},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Thunderhoof",
			["npcs"] = {261812},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Venomridge",
			["npcs"] = {261813},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Direhorn Matriarch",
			["npcs"] = {262127},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Cinder",
			["npcs"] = {261974},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Snowtalon",
			["npcs"] = {262297},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Bolt",
			["npcs"] = {262081},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Vitrix",
			["npcs"] = {272561},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "Nanaya",
			["npcs"] = {261809},
			["loot"] = {},
			["spells"] = {},
		},
		{
			["name"] = "King Op",
			["npcs"] = {261993},
			["loot"] = {},
			["spells"] = {},
		},
	},
	["areaID"] = 16667,
}
local trash = {}
tinsert(AzerothCompendium.INSTANCES, instance)
AzerothCompendium.TRASH[instance.name] = trash
