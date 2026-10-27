local _, AzerothCompendium = ...

AzerothCompendium.VENDORSIDES = AzerothCompendium.VENDORSIDES or {}
AzerothCompendium.VENDORS = AzerothCompendium.VENDORS or {}
for _, inst in ipairs({
	{
		["id"] = 1037,
		["name"] = "Alliance Vanguard",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1037,
		["category"] = "warfront",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44503}, {44937}, {50372}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{38459}, {38465}, {38455}, {38463}, {38453}, {38457}, {38464}},
			},
		},
	},
	{
		["id"] = 1106,
		["name"] = "Argent Crusade",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1106,
		["category"] = "tabard",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44297}, {44295}, {44296}, {44283}, {42187}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44248}, {44247}, {44244}, {44245}, {44214}, {50369}, {41726}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{44216}, {44240}, {44239}, {44139}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{43154}},
			},
		},
	},
	{
		["id"] = 1104,
		["name"] = "Frenzyheart Tribe",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1104,
		["category"] = "sholazar",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44073}, {44719}, {44718}, {39671}, {40067}, {40087}, {44716}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44116}, {44117}, {44122}, {44120}, {44121}, {44123}, {44717}, {41723}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{44064}, {44072}, {41561}},
			},
		},
	},
	{
		["id"] = 1052,
		["name"] = "Horde Expedition",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1052,
		["category"] = "warfront",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44502}, {44938}, {50373}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{38458}, {38461}, {38454}, {38452}, {38462}, {38456}, {38460}},
			},
		},
	},
	{
		["id"] = 1090,
		["name"] = "Kirin Tor",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1090,
		["category"] = "tabard",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44180}, {44181}, {44182}, {44183}, {41718}, {42188}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44179}, {44176}, {44173}, {44174}, {50368}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{44167}, {44170}, {44171}, {44166}, {44141}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{43157}},
			},
		},
	},
	{
		["id"] = 1098,
		["name"] = "Knights of the Ebon Blade",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1098,
		["category"] = "tabard",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44302}, {44303}, {44305}, {44306}, {41725}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44256}, {44258}, {44257}, {44250}, {44249}, {50367}, {41721}, {42183}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{44242}, {44243}, {44241}, {44512}, {44138}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{43155}, {41562}},
			},
		},
	},
	{
		["id"] = 1156,
		["name"] = "The Ashen Verdict",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1156,
		["category"] = "dungeon",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{50404}, {50398}, {52572}, {50402}, {50400}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{50403}, {50397}, {52571}, {50401}, {50399}, {49971}, {49973}, {49969}, {49959}, {49965}, {49957}, {49962}, {49953}, {49955}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{50388}, {50384}, {52570}, {50387}, {50386}, {49974}, {49972}, {49970}, {49958}, {49963}, {49961}, {49966}, {49954}, {49956}, {52022}, {52023}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{50375}, {50377}, {52569}, {50376}, {50378}},
			},
		},
	},
	{
		["id"] = 1073,
		["name"] = "The Kalu'ak",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1073,
		["category"] = "world",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44050}, {44723}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44051}, {44052}, {44053}, {44509}, {45774}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{44061}, {44062}, {44054}, {44055}, {44059}, {44060}, {44057}, {44058}, {44511}, {41574}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{44049}, {41568}},
			},
		},
	},
	{
		["id"] = 1105,
		["name"] = "The Oracles",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1105,
		["category"] = "sholazar",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44074}, {44707}, {39898}, {44721}, {39896}, {39899}, {44722}, {39883}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44104}, {44106}, {44110}, {44109}, {44112}, {44111}, {44108}, {39878}, {41724}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{44071}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{44065}, {41567}},
			},
		},
	},
	{
		["id"] = 1094,
		["name"] = "The Silver Covenant",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1094,
		["category"] = "argent",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{46813}, {46815}, {46820}, {46817}},
			},
		},
	},
	{
		["id"] = 1124,
		["name"] = "The Sunreavers",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1124,
		["category"] = "argent",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{46814}, {46816}, {46821}, {46818}},
			},
		},
	},
	{
		["id"] = 1119,
		["name"] = "The Sons of Hodir",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1119,
		["category"] = "world",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{44133}, {44134}, {44136}, {44135}, {41720}, {42184}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44194}, {44195}, {44193}, {44192}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{44190}, {44189}, {44131}, {44130}, {44132}, {44129}, {44510}, {44137}},
			},
		},
	},
	{
		["id"] = 1091,
		["name"] = "The Wyrmrest Accord",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1091,
		["category"] = "tabard",
		["maxLevel"] = 80,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{43955}, {44202}, {44203}, {44204}, {44205}, {41722}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{44200}, {44198}, {44201}, {44199}, {44152}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{44188}, {44196}, {44197}, {44187}, {44140}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{43156}},
			},
		},
	},
}) do
	tinsert(AzerothCompendium.VENDORS, inst)
end

AzerothCompendium.VENDORSIDES[1037] = 1
AzerothCompendium.VENDORSIDES[1052] = 2
AzerothCompendium.VENDORSIDES[1094] = 1
AzerothCompendium.VENDORSIDES[1124] = 2
