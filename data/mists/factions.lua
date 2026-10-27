local _, AzerothCompendium = ...

AzerothCompendium.VENDORSIDES = AzerothCompendium.VENDORSIDES or {}
AzerothCompendium.VENDORS = AzerothCompendium.VENDORS or {}
for _, inst in ipairs({
	{
		["id"] = 1269,
		["name"] = "Golden Lotus",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1269,
		["category"] = "daily",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{87781}, {87782}, {87783}, {89797}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{89420}, {89421}, {89423}, {89429}, {89430}, {89431}, {89432}, {89433}, {89434}, {93215}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{86235}, {86237}, {86273}, {86274}, {86275}, {86276}, {86277}, {86278}, {86295}, {86308}, {86309}, {86368}, {86369}, {86370}, {86371}, {86375}, {86376}, {89069}, {89070}, {89071}, {89072}, {89073}, {89339}, {89340}, {89341}, {89342}, {89343}, {89344}, {89345}, {89346}, {89347}, {98048}},
			},
		},
	},
	{
		["id"] = 1270,
		["name"] = "Shado-Pan",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1270,
		["category"] = "daily",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{89305}, {89306}, {89307}, {89800}, {89801}, {90844}, {90845}, {90846}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{84580}, {84583}, {84584}, {89096}, {89216}, {89280}, {89291}, {89296}, {89300}, {89308}, {89337}, {89338}, {93220}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{89074}, {89075}, {89076}, {89077}, {89078}, {89079}, {89080}, {89081}, {89082}, {89083}, {89301}, {89302}, {89303}},
			},
		},
	},
	{
		["id"] = 1271,
		["name"] = "Order of the Cloud Serpent",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1271,
		["category"] = "daily",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{79802}, {83877}, {85429}, {85430}, {89796}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{83931}, {83932}, {89222}, {89223}, {89224}, {89225}, {89227}, {93229}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{83830}, {83845}},
			},
		},
	},
	{
		["id"] = 1272,
		["name"] = "The Tillers",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1272,
		["category"] = "daily",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{80914}, {89362}, {89390}, {89391}, {89784}, {90175}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{74657}, {74658}, {89869}, {93226}},
			},
		},
	},
	{
		["id"] = 1302,
		["name"] = "The Anglers",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1302,
		["category"] = "daily",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{81354}, {87791}, {87792}, {87793}, {87794}, {89401}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{84661}, {85500}, {88535}, {93225}, {107950}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{84660}, {85447}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{85502}, {85505}},
			},
		},
	},
	{
		["id"] = 1337,
		["name"] = "The Klaxxi",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1337,
		["category"] = "daily",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{85262}, {89392}, {89393}, {89394}, {89395}, {89396}, {89397}, {89398}, {89399}, {89400}, {89798}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{89087}, {89088}, {89089}, {89090}, {89091}, {89092}, {89093}, {89094}, {89095}, {92522}, {98073}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{83787}, {83788}, {83789}, {83790}, {83791}, {83792}, {84196}, {84197}, {84198}, {84200}, {84217}, {84218}, {89055}, {89056}, {89057}, {89058}, {89059}, {89060}, {89061}, {89062}, {89063}, {89064}, {89065}, {89066}, {89067}, {89068}, {89230}, {90531}, {90532}},
			},
		},
	},
	{
		["id"] = 1341,
		["name"] = "The August Celestials",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1341,
		["category"] = "daily",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{86377}, {89304}, {89799}, {90655}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{84557}, {84559}, {84561}, {88862}, {88864}, {88865}, {88866}, {88867}, {88868}, {88876}, {88877}, {88878}, {93224}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{88741}, {88742}, {88743}, {88744}, {88745}, {88746}, {88747}, {88748}, {88749}, {88879}, {88880}, {88881}, {88882}, {88883}, {88884}, {88885}, {88892}, {88893}, {89124}, {98069}},
			},
		},
	},
	{
		["id"] = 1345,
		["name"] = "The Lorewalkers",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1345,
		["category"] = "world",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{87548}, {87549}, {89363}, {89795}, {95509}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{93230}},
			},
		},
	},
	{
		["id"] = 1359,
		["name"] = "The Black Prince",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1359,
		["category"] = "world",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{254313}},
			},
		},
	},
	{
		["id"] = 1375,
		["name"] = "Dominance Offensive",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1375,
		["category"] = "warfront",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{93169}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{93232}, {93253}, {93254}, {93255}, {93256}, {93257}, {93263}, {93264}, {93265}, {93266}, {93267}, {93268}, {93269}, {93270}, {93271}, {93323}, {93324}, {93325}, {93326}, {93327}, {93328}, {93329}, {93330}, {93331}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{93248}, {93249}, {93250}, {93251}, {93252}, {93341}, {93342}, {93343}, {93344}, {93345}},
			},
		},
	},
	{
		["id"] = 1376,
		["name"] = "Operation: Shieldwall",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1376,
		["category"] = "warfront",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{93168}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{93231}, {93258}, {93259}, {93260}, {93261}, {93262}, {93272}, {93273}, {93274}, {93275}, {93276}, {93277}, {93278}, {93279}, {93280}, {93332}, {93333}, {93334}, {93335}, {93336}, {93337}, {93338}, {93339}, {93340}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{93243}, {93244}, {93245}, {93246}, {93247}, {93346}, {93347}, {93348}, {93349}, {93350}},
			},
		},
	},
	{
		["id"] = 1387,
		["name"] = "Kirin Tor Offensive",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1387,
		["category"] = "warfront",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{95056}, {95564}, {95589}, {95591}, {97187}, {97188}, {97189}, {97190}, {97191}, {98558}, {98560}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{95052}, {95055}, {95545}, {97203}, {97204}, {97205}, {97206}, {97207}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{95053}, {95093}, {95526}, {95527}, {95528}, {95529}, {95530}, {95531}, {95532}, {95533}, {95534}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{95054}},
			},
		},
	},
	{
		["id"] = 1388,
		["name"] = "Sunreaver Onslaught",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1388,
		["category"] = "warfront",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{95565}, {95590}, {95592}, {97155}, {97192}, {97193}, {97194}, {97195}, {97196}, {98559}, {98562}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{95548}, {97156}, {97159}, {97208}, {97209}, {97210}, {97211}, {97212}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{95517}, {95518}, {95519}, {95520}, {95521}, {95522}, {95523}, {95524}, {95525}, {97154}, {97158}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{97157}},
			},
		},
	},
	{
		["id"] = 1435,
		["name"] = "Shado-Pan Assault",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1435,
		["category"] = "dungeon",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{95095}, {95096}, {95097}, {95098}, {95099}, {95100}, {95101}, {95102}, {95103}, {95104}, {97131}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{95559}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{94507}, {94508}, {94509}, {94510}, {94511}, {95074}, {95075}, {95076}, {95077}, {95078}, {95079}, {95080}, {95081}, {95082}, {95083}, {95084}, {95085}, {95086}, {95087}, {95088}, {95089}, {95090}, {95091}, {95105}, {95106}, {95107}, {95108}, {95109}, {95110}, {95111}, {95112}, {95113}, {95114}, {95115}, {95116}, {95117}, {95118}, {95119}, {95120}, {95121}, {95122}, {95123}, {95124}, {95125}, {95126}, {95127}, {95128}, {95129}, {95130}, {95131}, {95132}, {95133}, {95134}, {95135}, {95136}, {95137}, {95138}, {95139}, {95140}, {95141}, {98017}},
			},
			{
				["name"] = "Neutral",
				["standing"] = 3,
				["loot"] = {{95142}, {95143}, {95144}, {95145}, {95146}, {98065}},
			},
		},
	},
	{
		["id"] = 1492,
		["name"] = "Emperor Shaohao",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1492,
		["category"] = "world",
		["maxLevel"] = 90,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{87774}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{103685}, {104295}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{103678}, {103684}, {104014}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{103679}, {103680}, {103681}, {103682}, {103683}},
			},
		},
	},
}) do
	tinsert(AzerothCompendium.VENDORS, inst)
end

AzerothCompendium.VENDORSIDES[1375] = 2
AzerothCompendium.VENDORSIDES[1376] = 1
AzerothCompendium.VENDORSIDES[1387] = 1
AzerothCompendium.VENDORSIDES[1388] = 2
