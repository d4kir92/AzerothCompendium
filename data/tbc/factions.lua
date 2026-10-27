local _, AzerothCompendium = ...

AzerothCompendium.VENDORSIDES = AzerothCompendium.VENDORSIDES or {}
AzerothCompendium.VENDORS = AzerothCompendium.VENDORS or {}
for _, inst in ipairs({
	{
		["id"] = 932,
		["name"] = "The Aldor",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 932,
		["category"] = "shattrath",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29123}, {29124}, {28886}, {28887}, {28888}, {28889}, {31779}, {23602}, {29702}, {29689}, {24295}, {30844}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29127}, {29128}, {29130}, {24177}, {23604}, {29703}, {29691}, {25721}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29129}, {28881}, {28878}, {28885}, {28882}, {23145}, {23603}, {29704}, {29693}, {30843}, {24293}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{23149}, {23601}, {30842}},
			},
		},
	},
	{
		["id"] = 934,
		["name"] = "The Scryers",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 934,
		["category"] = "shattrath",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29126}, {29125}, {28910}, {28911}, {28912}, {28909}, {31780}, {23600}, {29698}, {29677}, {24294}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29131}, {29134}, {29132}, {29133}, {24176}, {22908}, {23599}, {29700}, {29684}, {25722}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{28907}, {28908}, {28904}, {28903}, {23143}, {23598}, {29701}, {29682}, {24292}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{23133}, {23597}},
			},
		},
	},
	{
		["id"] = 935,
		["name"] = "The Sha'tar",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 935,
		["category"] = "shattrath",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29177}, {29175}, {29176}, {31781}, {33153}, {31354}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29180}, {29179}, {29191}, {30634}, {24182}, {28281}, {22537}, {22915}, {13517}, {33159}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29195}, {30826}, {33155}, {28273}, {29717}, {35330}, {35333}, {35341}, {35345}, {35359}, {35362}, {35375}, {35368}, {35380}, {35381}, {35388}, {35395}, {35404}, {35416}, {35407}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{25904}},
			},
		},
	},
	{
		["id"] = 1011,
		["name"] = "Lower City",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1011,
		["category"] = "shattrath",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{30834}, {30832}, {30830}, {31778}, {33148}, {31357}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{30836}, {30835}, {30841}, {30846}, {30633}, {24179}, {24175}, {33157}, {22910}, {34200}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29199}, {22538}, {30833}, {35331}, {35335}, {35340}, {35344}, {35357}, {35361}, {35373}, {35370}, {35378}, {35382}, {35389}, {35391}, {35405}, {35412}, {35411}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{23138}},
			},
		},
	},
	{
		["id"] = 989,
		["name"] = "Keepers of Time",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 989,
		["category"] = "dungeon",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29183}, {29181}, {29182}, {31777}, {33152}, {31355}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29184}, {29185}, {29186}, {30635}, {24181}, {24174}, {33158}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29198}, {28272}, {22536}, {25910}, {33160}, {29713}, {35328}, {35334}, {35338}, {35346}, {35356}, {35363}, {35372}, {35369}, {35376}, {35384}, {35390}, {35393}, {35402}, {35414}, {35410}},
			},
		},
	},
	{
		["id"] = 967,
		["name"] = "The Violet Eye",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 967,
		["category"] = "dungeon",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29283}, {29287}, {29290}, {29279}, {33124}, {33165}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29282}, {29286}, {29291}, {29278}, {34581}, {34582}, {31394}, {33205}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29281}, {29285}, {29289}, {29277}, {31113}, {29187}, {31395}, {31393}, {31401}, {33209}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{29280}, {29284}, {29288}, {29276}},
			},
		},
	},
	{
		["id"] = 942,
		["name"] = "Cenarion Expedition",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 942,
		["category"] = "world",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{33999}, {29170}, {29172}, {29171}, {31804}, {31390}, {31402}, {33149}, {31356}, {22922}, {29721}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29174}, {31949}, {29173}, {29192}, {30623}, {31392}, {31391}, {24183}, {22918}, {28271}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{25838}, {25836}, {25835}, {29194}, {25735}, {25736}, {29720}, {25869}, {32070}, {23618}, {28632}, {25526}, {35329}, {35336}, {35342}, {35347}, {35358}, {35365}, {35374}, {35367}, {35379}, {35385}, {35387}, {35394}, {35403}, {35415}, {35408}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{24417}, {24429}, {25737}, {23814}},
			},
		},
	},
	{
		["id"] = 933,
		["name"] = "The Consortium",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 933,
		["category"] = "world",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29122}, {29119}, {29121}, {31776}, {33622}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29117}, {29116}, {29115}, {24178}, {25903}, {33156}, {33305}, {25734}, {22535}, {23874}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29457}, {29118}, {29456}, {25733}, {24314}, {23134}, {23155}, {23150}, {25908}, {25902}, {22552}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{25732}, {28274}, {23146}, {23136}},
			},
		},
	},
	{
		["id"] = 1012,
		["name"] = "Ashtongue Deathsworn",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1012,
		["category"] = "dungeon",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{32486}, {32487}, {32488}, {32489}, {32490}, {32492}, {32491}, {32493}, {32485}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{32443}, {32441}, {32433}, {32434}, {32431}, {32432}, {32447}, {32439}, {32437}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{32444}, {32442}, {32436}, {32435}, {32430}, {32429}, {32440}, {32438}},
			},
		},
	},
	{
		["id"] = 990,
		["name"] = "The Scale of the Sands",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 990,
		["category"] = "dungeon",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29301}, {29297}, {29305}, {29309}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29300}, {29296}, {29304}, {29308}, {32292}, {32308}, {32309}, {32302}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29299}, {29295}, {29303}, {29306}, {31737}, {31735}, {35763}, {32306}, {32305}, {32304}, {35762}, {32299}, {32301}, {32300}, {32311}, {35765}, {32312}, {32310}, {35764}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{29298}, {29294}, {29302}, {29307}, {32274}, {32283}, {32277}, {32282}, {32284}, {32281}, {32288}, {32286}, {32287}, {32290}, {32293}, {32291}, {32294}},
			},
		},
	},
	{
		["id"] = 1077,
		["name"] = "Shattered Sun Offensive",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1077,
		["category"] = "daily",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{34676}, {34675}, {34678}, {34679}, {34680}, {34677}, {35221}, {35322}, {35323}, {35325}, {35247}, {35257}, {35267}, {35258}, {37504}, {35242}, {35243}, {35265}, {35270}, {35755}, {35752}, {35754}, {35753}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{34667}, {34672}, {34666}, {34671}, {34670}, {34673}, {34674}, {34665}, {29193}, {35769}, {35768}, {35767}, {35766}, {35252}, {35259}, {35241}, {35271}, {35708}, {35505}, {35502}, {35699}, {35698}, {35697}, {35695}, {35696}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{35238}, {35251}, {35266}, {35239}, {35240}, {35253}, {35268}, {35269}, {35254}, {35500}, {34872}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{34780}, {35244}, {35255}, {35246}, {35256}, {35262}, {35248}, {35260}, {35263}, {35264}, {35249}, {35250}, {35261}},
			},
		},
	},
	{
		["id"] = 1031,
		["name"] = "Sha'tari Skyguard",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1031,
		["category"] = "daily",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{32770}, {32771}, {32445}, {38628}, {32319}, {32314}, {32317}, {32316}, {32318}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{32539}, {32538}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{32721}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{32722}},
			},
		},
	},
	{
		["id"] = 1015,
		["name"] = "Netherwing",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1015,
		["category"] = "daily",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{32858}, {32859}, {32857}, {32860}, {32861}, {32862}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{32864}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{32695}, {32863}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{32694}},
			},
		},
	},
	{
		["id"] = 970,
		["name"] = "Sporeggar",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 970,
		["category"] = "world",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{34478}, {31775}, {22906}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29150}, {29149}, {22916}, {38229}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{25827}, {25828}, {25550}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{25548}, {24539}, {27689}, {30156}},
			},
		},
	},
	{
		["id"] = 1038,
		["name"] = "Ogri'la",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 1038,
		["category"] = "daily",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{32647}, {32648}, {32651}, {32645}, {32828}, {32569}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{32653}, {32654}, {32652}, {32650}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{32784}, {32783}, {32572}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{32910}, {32909}},
			},
		},
	},
	{
		["id"] = 922,
		["name"] = "Tranquillien",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 922,
		["category"] = "warfront",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{22990}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{22986}, {22987}, {22985}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{28155}, {28158}, {28162}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{22991}, {22992}, {22993}, {28164}},
			},
		},
	},
	{
		["id"] = 947,
		["name"] = "Thrallmar",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 947,
		["category"] = "warfront",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29155}, {29165}, {29152}, {24004}, {33151}, {24002}, {31362}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29168}, {29167}, {32882}, {29190}, {30637}, {31358}, {24003}, {34201}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{25824}, {25823}, {29197}, {25739}, {25740}, {31361}, {29232}, {24001}, {35332}, {35337}, {35339}, {35343}, {35360}, {35364}, {35371}, {35366}, {35377}, {35383}, {35386}, {35392}, {35406}, {35413}, {35409}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{24006}, {24009}, {25738}, {31359}, {24000}},
			},
		},
	},
	{
		["id"] = 941,
		["name"] = "The Mag'har",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 941,
		["category"] = "warfront",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29139}, {29135}, {29137}, {31773}, {29102}, {29104}, {29105}, {29103}, {31829}, {31831}, {31833}, {31835}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29147}, {29141}, {29145}, {25743}, {22917}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29143}, {25742}, {34174}, {34172}, {29664}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{25741}},
			},
		},
	},
	{
		["id"] = 946,
		["name"] = "Honor Hold",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 946,
		["category"] = "warfront",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29153}, {29156}, {29151}, {23999}, {33150}, {23619}, {29722}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29169}, {29166}, {32883}, {29189}, {30622}, {24180}, {22547}, {34218}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{25826}, {25825}, {29196}, {29214}, {29215}, {29719}, {25870}, {22905}, {35464}, {35467}, {35466}, {35465}, {35469}, {35470}, {35471}, {35468}, {35475}, {35474}, {35472}, {35473}, {35476}, {35477}, {35478}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{24007}, {24008}, {29213}, {23142}, {22531}},
			},
		},
	},
	{
		["id"] = 978,
		["name"] = "Kurenai",
		["type"] = "faction",
		["vendor"] = true,
		["factionID"] = 978,
		["category"] = "warfront",
		["maxLevel"] = 70,
		["bosses"] = {
			{
				["name"] = "Exalted",
				["standing"] = 7,
				["loot"] = {{29140}, {29136}, {29138}, {31774}, {29227}, {29229}, {29230}, {29231}, {31830}, {31832}, {31834}, {31836}},
			},
			{
				["name"] = "Revered",
				["standing"] = 6,
				["loot"] = {{29148}, {29142}, {29146}, {29218}, {30443}},
			},
			{
				["name"] = "Honored",
				["standing"] = 5,
				["loot"] = {{29144}, {29219}, {34175}, {34173}, {30444}},
			},
			{
				["name"] = "Friendly",
				["standing"] = 4,
				["loot"] = {{29217}},
			},
		},
	},
}) do
	tinsert(AzerothCompendium.VENDORS, inst)
end

AzerothCompendium.VENDORSIDES[922] = 2
AzerothCompendium.VENDORSIDES[947] = 2
AzerothCompendium.VENDORSIDES[941] = 2
AzerothCompendium.VENDORSIDES[946] = 1
AzerothCompendium.VENDORSIDES[978] = 1
