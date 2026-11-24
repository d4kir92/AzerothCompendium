local _, AzerothCompendium = ...
local instance = {
	["id"] = 16919,
	["name"] = "The Hall of Thanes",
	["type"] = "dungeon",
	["minLevel"] = 13,
	["maxLevel"] = 20,
	["areaID"] = 16919,
	["forever"] = true,
	["bosses"] = {
		{
			["name"] = "Faldrim Anvilmar",
			["npcs"] = {261306},
			["level"] = 16,
			["model"] = 142826,
			["loot"] = {{270227, 33.36}, {271096, 32.45}, {271097, 34.19},},
			["spells"] = {1604, 13860, 1292602},
		},
		{
			["name"] = "Magmatus",
			["npcs"] = {261316},
			["level"] = 16,
			["model"] = 1070,
			["loot"] = {{270230, 31.72}, {270231, 32.58}, {271095, 35.71},},
			["spells"] = {1604, 11970, 1293228},
		},
		{
			["name"] = "Plunder",
			["npcs"] = {261311},
			["level"] = 16,
			["model"] = 142840,
			["loot"] = {{270228, 34.77}, {270229, 32.68}, {271098, 32.55},},
			["spells"] = {1604, 11130, 21055, 22911},
		},
		{
			["name"] = "Durgen Dirgehammer",
			["npcs"] = {261319},
			["level"] = 16,
			["model"] = 142837,
			["loot"] = {{270256, 28.89}, {270260, 27.17}, {270261, 24.62}, {274286, 51.55},},
			["spells"] = {1604, 11977, 19134, 25710, 29544, 43958},
		},
	},
}
local trash = {
	{
		[1] = 2770,
		[2] = 4.2,
		["itemClass"] = 7,
		["mobs"] = {
			{
				["name"] = "Lesser Stone Golem",
				["npcs"] = {263466},
				["chance"] = 4.2,
				["classification"] = 1,
				["model"] = 2693,
			},
		},
	},
	{
		[1] = 275892,
		[2] = 0.65,
		["itemClass"] = 15,
		["mobs"] = {
			{
				["name"] = "Dark Iron Engineer",
				["npcs"] = {263397},
				["chance"] = 0.52,
				["classification"] = 1,
				["model"] = 3954,
			},
			{
				["name"] = "Dark Iron Looter",
				["npcs"] = {263396},
				["chance"] = 0.64,
				["classification"] = 1,
				["model"] = 3452,
			},
			{
				["name"] = "Dark Iron Summoner",
				["npcs"] = {263438},
				["chance"] = 0.65,
				["classification"] = 1,
				["model"] = 143713,
			},
		},
	},
	{
		[1] = 275893,
		[2] = 6.09,
		["itemClass"] = 15,
		["mobs"] = {
			{
				["name"] = "Dark Iron Looter",
				["npcs"] = {263396},
				["chance"] = 5.68,
				["classification"] = 1,
				["model"] = 3452,
			},
			{
				["name"] = "Dark Iron Engineer",
				["npcs"] = {263397},
				["chance"] = 6.08,
				["classification"] = 1,
				["model"] = 3954,
			},
			{
				["name"] = "Dark Iron Summoner",
				["npcs"] = {263438},
				["chance"] = 6.09,
				["classification"] = 1,
				["model"] = 143713,
			},
		},
	},
}
tinsert(AzerothCompendium.INSTANCES, instance)
AzerothCompendium.TRASH[instance.name] = trash
