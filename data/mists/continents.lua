local _, AzerothCompendium = ...
for _, id in ipairs({961, 960, 959, 994, 962, 1011, 1008, 1009, 996, 1098, 1136}) do
    AzerothCompendium.INSTANCECONTINENTS[id] = "pandaria"
end
for _, id in ipairs({1001, 1004, 1007}) do
    AzerothCompendium.INSTANCECONTINENTS[id] = "easternkingdoms"
end
