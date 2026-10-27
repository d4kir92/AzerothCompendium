local _, AzerothCompendium = ...

AzerothCompendium.VENDORSIDES = AzerothCompendium.VENDORSIDES or {}
AzerothCompendium.VENDORS = AzerothCompendium.VENDORS or {}
for _, inst in ipairs({
	{
		["id"] = 1133,
		["name"] = "Bilgewater Cartel",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1133,
		["category"] = "world",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{64905}, {64906}, {64907}},
			},
		},
	},
	{
		["id"] = 1134,
		["name"] = "Gilneas",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1134,
		["category"] = "world",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{64892}, {64893}, {64894}},
			},
		},
	},
	{
		["id"] = 1135,
		["name"] = "The Earthen Ring",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1135,
		["category"] = "tabard",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{62362}, {62363}, {62364}, {62365}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62357}, {62358}, {62359}, {62361}, {62366}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{62353}, {62354}, {62355}, {62356}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{65905}},
			},
		},
	},
	{
		["id"] = 1158,
		["name"] = "Guardians of Hyjal",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1158,
		["category"] = "tabard",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{62383}, {62384}, {62385}, {62386}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62367}, {62378}, {62380}, {62381}, {62382}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{62374}, {62375}, {62376}, {62377}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{65906}},
			},
		},
	},
	{
		["id"] = 1171,
		["name"] = "Therazane",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1171,
		["category"] = "tabard",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{226459}, {226460}, {226462}, {226463}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62348}, {62350}, {62351}, {62352}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{62321}, {62342}, {62344}, {62347}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{65907}},
			},
		},
	},
	{
		["id"] = 1172,
		["name"] = "Dragonmaw Clan",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1172,
		["category"] = "tabard",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{62416}, {62417}, {62418}, {62420}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62368}, {62408}, {62409}, {62410}, {62415}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{62404}, {62405}, {62406}, {62407}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{65909}},
			},
		},
	},
	{
		["id"] = 1173,
		["name"] = "Ramkahen",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1173,
		["category"] = "tabard",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{62447}, {62448}, {62449}, {62450}, {63044}, {63045}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62369}, {62440}, {62441}, {62445}, {62446}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{62436}, {62437}, {62438}, {62439}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{65904}},
			},
		},
	},
	{
		["id"] = 1174,
		["name"] = "Wildhammer Clan",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1174,
		["category"] = "tabard",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{62431}, {62432}, {62433}, {62434}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62422}, {62427}, {62428}, {62429}, {62430}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{62423}, {62424}, {62425}, {62426}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{65908}},
			},
		},
	},
	{
		["id"] = 1177,
		["name"] = "Baradin's Wardens",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1177,
		["category"] = "daily",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{62468}, {62469}, {62470}, {62471}, {62472}, {63039}, {64998}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62473}, {62474}, {62475}, {62476}, {62477}, {62478}, {62479}, {63377}, {68739}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{63141}, {63355}, {63379}, {65175}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{63144}, {63145}, {63391}, {63517}},
			},
		},
	},
	{
		["id"] = 1178,
		["name"] = "Hellscream's Reach",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1178,
		["category"] = "daily",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{62463}, {62464}, {62465}, {62466}, {62467}, {64999}, {65356}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{62454}, {62455}, {62456}, {62457}, {62458}, {62459}, {62460}, {63376}, {68740}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{63378}, {64996}, {64997}, {65176}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{63518}, {64993}, {64994}, {64995}},
			},
		},
	},
	{
		["id"] = 1204,
		["name"] = "Avengers of Hyjal",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1204,
		["category"] = "dungeon",
		["maxLevel"] = 85,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{70934}, {71215}, {71216}, {71217}, {71237}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{68996}, {68998}, {69000}, {69001}, {69002}, {69184}, {69185}, {69198}, {69199}, {69200}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{70933}, {71131}, {71249}, {71250}, {71253}, {71254}, {71255}, {71258}, {71393}, {71394}, {71395}, {71396}, {71397}, {71398}, {71399}, {71400}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{70930}, {71227}, {71228}, {71229}, {71230}, {71388}, {71389}, {71390}, {71391}, {71392}},
			},
		},
	},
}) do
	tinsert(AzerothCompendium.VENDORS, inst)
end

AzerothCompendium.VENDORSIDES[1133] = 2
AzerothCompendium.VENDORSIDES[1134] = 1
AzerothCompendium.VENDORSIDES[1172] = 2
AzerothCompendium.VENDORSIDES[1174] = 1
AzerothCompendium.VENDORSIDES[1177] = 1
AzerothCompendium.VENDORSIDES[1178] = 2
