local _, AzerothCompendium = ...
local instance = {
	["id"] = 900002,
	["name"] = "Krol'dok Stronghold",
	["type"] = "dungeon",
	["minLevel"] = 40,
	["maxLevel"] = 45,
	["forever"] = true,
	["bosses"] = {
		{
			["name"] = "Slavecrusher Grox",
			["npcs"] = {258966},
			["model"] = 141217,
			["spells"] = {1604, 11428, 21049, 1280085},
			["loot"] = {{273101, 4.27}, {274995, 32.91}, {274996, 28.85}, {274997, 37.61},},
		},
		{
			["name"] = "Twilight Commander Zarmok",
			["npcs"] = {258972},
			["model"] = 141219,
			["spells"] = {1604, 8599, 12057, 1280011, 1296130},
			["loot"] = {{267091, 2.48}, {267234, 3.07}, {274998, 31.53}, {274999, 35.04}, {275000, 31.53},},
		},
		{
			["name"] = "War Handler Ashka",
			["npcs"] = {259281},
			["model"] = 141443,
			["spells"] = {1604, 9128, 12057, 1282076},
			["loot"] = {{275001, 38.49}, {275002, 33.33}, {275003, 28.18},},
		},
		{
			["name"] = "Nar'gurk <The Corruptor>",
			["npcs"] = {258964},
			["model"] = 141215,
			["spells"] = {770, 1161, 1604, 2974, 3043, 3355, 5246, 5484, 7321, 8380, 8492, 9490, 9747, 10447, 11572, 13810, 13812, 14314, 14323, 14324, 14914, 15258, 19281, 19974, 20066, 20186, 20301, 20511, 412609, 414644, 1280259, 1280353, 1280356, 1293696, 1314281},
			["loot"] = {{267104, 41.31}, {275004, 35.25}, {275005, 26.63}, {275006, 29.67},},
		},
		{
			["name"] = "Bossman Toof",
			["npcs"] = {264773},
			["model"] = 14424,
			["spells"] = {15548, 16244, 16856},
			["loot"] = {{286428, 31.96}, {286429, 30.28}, {286430, 37.76},},
		},
		{
			["name"] = "Overlord Mugg",
			["npcs"] = {258968},
			["model"] = 141218,
			["spells"] = {1604, 1282387, 1282393, 1282394, 1282397},
			["loot"] = {{267086, 43.38}, {271721, 11.06}, {275007, 23.73}, {275008, 21.11}, {275009, 21.83}, {275010, 26.35},},
		},
	},
	["areaID"] = 16842,
}
local trash = {
	{
		[1] = 868,
		[2] = 0.04,
		["itemClass"] = 2,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 873,
		[2] = 0.14,
		["itemClass"] = 2,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 1204,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 1980,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 2802,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 4063,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 4080,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 4734,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 4737,
		[2] = 0.04,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 6424,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 6426,
		[2] = 0.2,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.2,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 6429,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 7469,
		[2] = 0.16,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.16,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 7481,
		[2] = 0.04,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 7486,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 7488,
		[2] = 0.42,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.42,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 7496,
		[2] = 0.08,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 7524,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 7544,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 8139,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 8142,
		[2] = 0.08,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 8156,
		[2] = 0.29,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.29,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 8157,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.12,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 8158,
		[2] = 0.12,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.12,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 8159,
		[2] = 0.33,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.33,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 8160,
		[2] = 0.08,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 8161,
		[2] = 0.42,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.12,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.42,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 8162,
		[2] = 0.04,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 8163,
		[2] = 0.16,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.16,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9285,
		[2] = 0.33,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.33,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9287,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.12,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9288,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9289,
		[2] = 0.12,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.12,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9291,
		[2] = 0.04,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9292,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9883,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9884,
		[2] = 0.16,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.16,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9887,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.2,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9897,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9907,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9908,
		[2] = 0.16,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.16,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9916,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9919,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9925,
		[2] = 0.04,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9932,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9967,
		[2] = 0.12,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.12,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9968,
		[2] = 0.33,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.33,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9969,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9970,
		[2] = 0.04,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 9971,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9972,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 9973,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 11998,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 12689,
		[2] = 0.04,
		["itemClass"] = 9,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 13042,
		[2] = 0.04,
		["itemClass"] = 2,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 13117,
		[2] = 0.04,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 13199,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 14467,
		[2] = 0.04,
		["itemClass"] = 9,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 16043,
		[2] = 0.04,
		["itemClass"] = 9,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.04,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 267091,
		[2] = 17.26,
		["itemClass"] = 12,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 16.35,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 17.26,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 267234,
		[2] = 12.72,
		["itemClass"] = 12,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 11.17,
				["classification"] = 1,
				["model"] = 143142,
			},
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 12.72,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 287007,
		[2] = 0.24,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.24,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 287008,
		[2] = 0.16,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.16,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 287009,
		[2] = 0.16,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.16,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 287011,
		[2] = 0.28,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.16,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 287012,
		[2] = 1.18,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.57,
				["classification"] = 1,
				["model"] = 143142,
			},
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 1.18,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 287013,
		[2] = 0.9,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.28,
				["classification"] = 1,
				["model"] = 143142,
			},
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.9,
				["classification"] = 1,
				["model"] = 140001,
			},
		},
	},
	{
		[1] = 287014,
		[2] = 1.27,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 1.18,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 1.27,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 287015,
		[2] = 0.14,
		["itemClass"] = 2,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.08,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
	{
		[1] = 287016,
		[2] = 0.14,
		["itemClass"] = 4,
		["mobs"] = {
			{
				["name"] = "Twilight Grunt",
				["npcs"] = {258042},
				["chance"] = 0.12,
				["classification"] = 1,
				["model"] = 140001,
			},
			{
				["name"] = "Twilight Lieutenant",
				["npcs"] = {258104},
				["chance"] = 0.14,
				["classification"] = 1,
				["model"] = 143142,
			},
		},
	},
}
tinsert(AzerothCompendium.INSTANCES, instance)
AzerothCompendium.TRASH[instance.name] = trash
