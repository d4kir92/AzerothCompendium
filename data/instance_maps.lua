local _, AzerothCompendium = ...
local MEDIA_PATH = "Interface\\AddOns\\AzerothCompendium\\media\\"
local ART_WIDTH = 1024
local ART_HEIGHT = 683
local FILE_SIZE = 1024
AzerothCompendium.INSTANCEMAPS = {}
local function AddMaps(id, levels)
    local maps = {}
    for i, level in ipairs(levels) do
        maps[i] = {
            ["id"] = level[4] or level[1],
            ["file"] = MEDIA_PATH .. level[1],
            ["name"] = level[2],
            ["width"] = ART_WIDTH,
            ["height"] = level[3] or ART_HEIGHT,
            ["fileWidth"] = FILE_SIZE,
            ["fileHeight"] = FILE_SIZE,
            ["source"] = level[5],
        }
    end

    AzerothCompendium.INSTANCEMAPS[id] = maps
end

AddMaps(16544, {{2959, "City of Dalaran", 684}, {"2959_2", "Dalaran Sewers", 689, 2959002}})
AddMaps(16732, {{2998}})
AddMaps(16611, {{2999, nil, nil, nil, "Santiago Reyes - Atlas de Azeroth: Forever"}})
AddMaps(16919, {{3065, nil, nil, nil, "Santiago Reyes - Atlas de Azeroth: Forever"}})
AddMaps(389, {{213}})
AddMaps(36, {{291, "The Deadmines"}, {292, "Ironclad Cove"}})
AddMaps(43, {{279}})
AddMaps(33, {{310, "The Courtyard"}, {311, "Dining Hall"}, {316, "The Wall Walk"}, {312, "The Vacant Den"}, {313, "Lower Observatory"}, {314, "Upper Observatory"}, {315, "Lord Godfrey's Chamber"}})
AddMaps(34, {{225, nil, 670}})
AddMaps(48, {{221, "The Pool of Ask'Ar"}, {222, "Moonshrine Sanctum"}, {223, "The Forgotten Pool"}})
AddMaps(90, {{226, "The Hall of Gears"}, {227, "The Dormitory"}, {228, "Launch Bay"}, {229, "Tinkers' Court"}})
AddMaps(47, {{301}})
AddMaps(189001, {{302}})
AddMaps(189002, {{303}})
AddMaps(189003, {{304}})
AddMaps(189004, {{305}})
AddMaps(129, {{300}})
AddMaps(70, {{230, "Hall of the Keepers"}, {231, "Khaz'Goroth's Seat"}})
AddMaps(209, {{219}})
AddMaps(349, {{280, "Caverns of Maraudon"}, {281, "Zaetar's Grave"}})
AddMaps(109, {{220}})
AddMaps(230, {{242, "Detention Block"}, {243, "Shadowforge City"}})
AddMaps(229, {{250, "Tazz'Alor"}, {251, "Skitterweb Tunnels"}, {252, "Hordemar City"}, {253, "Hall of Blackhand"}, {254, "Halycon's Lair"}, {255, "Chamber of Battle"}})
AddMaps(409, {{232}})
AddMaps(469, {{287, "Dragonmaw Garrison"}, {288, "Halls of Strife"}, {289, "Crimson Laboratories"}, {290, "Nefarian's Lair"}})
AddMaps(429, {{234, "Dire Maul"}, {235, "Gordok Commons"}, {236, "Capital Gardens"}, {237, "Court of the Highborne"}, {238, "Prison of Immol'Thar"}, {239, "Warpwood Quarter"}, {240, "The Shrine of Eldretharr"}})
AddMaps(289, {{306, "The Reliquary"}, {307, "Chamber of Summoning"}, {308, "The Upper Study"}, {309, "Headmaster's Study"}})
AddMaps(329, {{317, "Crusader's Square"}, {318, "The Gauntlet"}})
AddMaps(309, {{233}})
AddMaps(249, {{248}})
AddMaps(509, {{247}})
AddMaps(531, {{319, "The Hive Undergrounds"}, {320, "The Temple Gates"}, {321, "Vault of C'Thun"}})
AddMaps(533, {{162, "The Construct Quarter"}, {163, "The Arachnid Quarter"}, {164, "The Military Quarter"}, {165, "The Plague Quarter"}, {166, "The Lower Necropolis"}, {167, "The Upper Necropolis"}})
