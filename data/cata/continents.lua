local _, AzerothCompendium = ...
for _, id in ipairs({643, 645, 670, 36, 33, 859, 568, 669, 671, 757}) do
    AzerothCompendium.INSTANCECONTINENTS[id] = "easternkingdoms"
end
for _, id in ipairs({657, 755, 644, 938, 940, 939, 754, 720, 967}) do
    AzerothCompendium.INSTANCECONTINENTS[id] = "kalimdor"
end
AzerothCompendium.INSTANCECONTINENTS[725] = "maelstrom"
