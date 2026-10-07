local _, AzerothCompendium = ...

AzerothCompendium.QUESTNAMES = AzerothCompendium.QUESTNAMES or {}
for questID, value in pairs({
	[544] = "Prison Break In",
	[545] = "Dalaran Patrols",
	[556] = "Stone Tokens",
	[557] = "Bracers of Binding",
	[93680] = "Key to the City",
}) do
	AzerothCompendium.QUESTNAMES[questID] = AzerothCompendium.QUESTNAMES[questID] or value
end

AzerothCompendium.QUESTSIDES = AzerothCompendium.QUESTSIDES or {}
for questID, value in pairs({
	[544] = 2,
	[545] = 2,
	[556] = 2,
	[557] = 2,
	[93680] = 2,
}) do
	AzerothCompendium.QUESTSIDES[questID] = AzerothCompendium.QUESTSIDES[questID] or value
end

AzerothCompendium.QUESTREQUIREDLEVELS = AzerothCompendium.QUESTREQUIREDLEVELS or {}
for questID, value in pairs({
	[544] = 30,
	[545] = 30,
	[556] = 30,
	[557] = 30,
	[93680] = 30,
}) do
	AzerothCompendium.QUESTREQUIREDLEVELS[questID] = AzerothCompendium.QUESTREQUIREDLEVELS[questID] or value
end

AzerothCompendium.QUESTRECOMMENDEDLEVELS = AzerothCompendium.QUESTRECOMMENDEDLEVELS or {}
for questID, value in pairs({
	[544] = 34,
	[545] = 35,
	[556] = 32,
	[557] = 34,
	[93680] = 33,
}) do
	AzerothCompendium.QUESTRECOMMENDEDLEVELS[questID] = AzerothCompendium.QUESTRECOMMENDEDLEVELS[questID] or value
end

AzerothCompendium.QUESTGIVERS = AzerothCompendium.QUESTGIVERS or {}
for questID, value in pairs({
	[544] = {1424, 61.6, 20.8, 2410, "Magus Wordeen Voidglare"},
	[545] = {1424, 61.6, 20.8, 2410, "Magus Wordeen Voidglare"},
	[556] = {1424, 61.4, 20.8, 2437, "Keeper Bel'varil"},
	[557] = {1424, 61.4, 20.8, 2437, "Keeper Bel'varil"},
	[92432] = {1424, 48.3, 60.1, 247264, "Emissary Jacques"},
	[93680] = {1424, 61.6, 20.8, 2410, "Magus Wordeen Voidglare"},
}) do
	AzerothCompendium.QUESTGIVERS[questID] = AzerothCompendium.QUESTGIVERS[questID] or value
end

AzerothCompendium.QUESTREWARDS = AzerothCompendium.QUESTREWARDS or {}
for questID, value in pairs({
	[544] = {["money"] = 7000, ["xp"] = 3350, ["rep"] = {{68, 150}}},
	[545] = {["money"] = 2500, ["xp"] = 2050, ["rep"] = {{68, 75}}},
	[556] = {["money"] = 3000, ["xp"] = 2550, ["rep"] = {{68, 100}}},
	[557] = {["money"] = 3500, ["xp"] = 2700, ["rep"] = {{68, 100}}},
}) do
	AzerothCompendium.QUESTREWARDS[questID] = AzerothCompendium.QUESTREWARDS[questID] or value
end
