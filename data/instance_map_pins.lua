local _, AzerothCompendium = ...
AzerothCompendium.INSTANCEMAPPINS = {
    [3065] = { -- The Hall of Thanes
        {"entrance", 0.511, 0.948},
        {"boss", 0.509, 0.666, 261306}, -- Faldrim Anvilmar
        {"boss", 0.717, 0.465, 261316}, -- Magmatus
        {"boss", 0.509, 0.516, 261311}, -- Plunder
        {"boss", 0.510, 0.167, 261319}, -- Durgen Dirgehammer
    },
    [2999] = { -- Ruins of Lordaeron
        {"entrance", 0.612, 0.216},
        {"boss", 0.704, 0.389, 250483}, -- Witherfang
        {"boss", 0.606, 0.696, 250660}, -- The Baron
        {"boss", 0.382, 0.670, 256035}, -- Viktor the Vile
        {"boss", 0.406, 0.534, 250631}, -- The Abandoned
        {"boss", 0.424, 0.385, 256097}, -- Bjork
        {"boss", 0.463, 0.623, 250657}, -- Rath'mael
        {"boss", 0.433, 0.269, 255699}, -- Lordaeron Captain
        {"item", 0.347, 0.207, 275521}, -- Crest of Lordaeron
        {"item", 0.376, 0.493, 275521}, -- Crest of Lordaeron
        {"item", 0.433, 0.290, 275521}, -- Crest of Lordaeron
        {"item", 0.566, 0.596, 275521}, -- Crest of Lordaeron
        {"item", 0.591, 0.680, 280438}, -- Abominable Head
        {"item", 0.671, 0.493, 275521}, -- Crest of Lordaeron
    },
    [2998] = { -- Excavation Site: Wetlands
        {"entrance", 0.080, 0.610},
        {"boss", 0.340, 0.570, 260322}, -- Saltspine
        {"boss", 0.635, 0.250, 260326}, -- Relic Guardian
        {"boss", 0.715, 0.530, 260325}, -- Shadetooth
        {"boss", 0.790, 0.280, 260808}, -- Highland Horror
    },
    [2959] = { -- City of Dalaran
        {"level", 0.616, 0.542, 2959002},
        {"level", 0.513, 0.684, 2959002},
        {"level", 0.531, 0.365, 2959002},
        {"boss", 0.524, 0.840, 245999}, -- Arcane Anomaly
        {"boss", 0.565, 0.230, 246020}, -- Shade of the Archmage
        {"boss", 0.517, 0.551, 246003}, -- Fel Ancient
        {"boss", 0.613, 0.424, 246017}, -- Unstable Sentinel
        {"boss", 0.668, 0.516, 246016}, -- Arcanic Enigma
        {"boss", 0.418, 0.729, 246008}, -- Mana Devourer
    },
    [2959002] = { -- City of Dalaran - Dalaran Sewers
        {"entrance", 0.184, 0.840},
        {"level", 0.645, 0.640, 2959, true},
        {"boss", 0.545, 0.510, 247126}, -- Atrexis the Grave Knight
        {"boss", 0.680, 0.180, 247032}, -- Lyn the Ignored
    },
    [213] = { -- Ragefire Chasm
        {"entrance", 0.611, 0.072},
        {"boss", 0.564, 0.372, 11517},
        {"boss", 0.406, 0.574, 11520},
        {"boss", 0.338, 0.840, 11518},
        {"boss", 0.422, 0.857, 11519},
    },
    [291] = { -- The Deadmines
        {"entrance", 0.297, 0.133},
        {"level", 0.655, 0.667, 292},
        {"boss", 0.374, 0.610, 644},
        {"boss", 0.523, 0.510, 3586},
        {"boss", 0.493, 0.862, 642},
        {"boss", 0.607, 0.572, 1763},
    },
    [292] = { -- The Deadmines - Ironclad Cove
        {"level", 0.123, 0.883, 291, true},
        {"boss", 0.561, 0.265, 646},
        {"boss", 0.632, 0.389, 647},
        {"boss", 0.603, 0.455, 639},
        {"boss", 0.668, 0.398, 645},
    },
    [279] = { -- Wailing Caverns
        {"entrance", 0.463, 0.590},
        {"boss", 0.400, 0.271, 3671},
        {"boss", 0.300, 0.300, 3671}, -- Lady Anacondra
        {"boss", 0.310, 0.430, 3671}, -- Lady Anacondra
        {"boss", 0.460, 0.440, 3671}, -- Lady Anacondra
        {"boss", 0.156, 0.585, 3669},
        {"boss", 0.418, 0.356, 3653},
        {"boss", 0.856, 0.299, 3670},
        {"boss", 0.924, 0.782, 3674},
        {"boss", 0.613, 0.537, 3673},
        {"boss", 0.555, 0.475, 5775},
        {"boss", 0.642, 0.410, 5912},
        {"boss", 0.338, 0.133, 3654},
        {"boss", 0.300, 0.300, 3671},
        {"boss", 0.310, 0.430, 3671},
        {"boss", 0.460, 0.440, 3671},
    },
    [310] = { -- Shadowfang Keep 1
        {"entrance", 0.705, 0.606},
        {"level", 0.367, 0.392, 311},
        {"level", 0.148, 0.866, 311},
        {"level", 0.355, 0.666, 316, true},
        {"boss", 0.650, 0.715, 3914}, -- Rethilgore
        {"boss", 0.278, 0.601, 4278}, -- Commander Springvale
    },
    [311] = { -- Shadowfang Keep 2
        {"level", 0.593, 0.121, 310, true},
        {"level", 0.273, 0.881, 310, true},
        {"boss", 0.301, 0.762, 3887}, -- Baron Silverlaine
        {"boss", 0.472, 0.277, 3886}, -- Razorclaw the Butcher
    },
    [312] = { -- Shadowfang Keep 3
        {"level", 0.516, 0.904, 316, true},
        {"level", 0.533, 0.600, 313, true},
    },
    [313] = { -- Shadowfang Keep 4
        {"level", 0.442, 0.749, 314, true},
        {"level", 0.526, 0.872, 312},
        {"boss", 0.544, 0.537, 4274}, -- Fenrus the Devourer
    },
    [315] = { -- Shadowfang Keep 6
        {"level", 0.420, 0.842, 314},
        {"boss", 0.553, 0.627, 3927}, -- Wolf Master Nandos
        {"boss", 0.639, 0.200, 4275},
    },
    [316] = { -- Shadowfang Keep 7
        {"level", 0.239, 0.745, 310},
        {"level", 0.436, 0.331, 312, true},
        {"boss", 0.595, 0.820, 4279}, -- Odo the Blindwatcher
        {"boss", 0.690, 0.770, 3872}, -- Deathsworn Captain
    },
    [225] = { -- The Stockade
        {"entrance", 0.500, 0.815},
        {"boss", 0.440, 0.446, 1696},
        {"boss", 0.691, 0.300, 1666},
        {"boss", 0.780, 0.454, 1717},
        {"boss", 0.745, 0.562, 1716},
        {"boss", 0.213, 0.260, 1663},
        {"boss", 0.497, 0.222, 1720},
    },
    [221] = { -- Blackfathom Deeps 1
        {"entrance", 0.453, 0.108},
        {"level", 0.621, 0.741, 222},
        {"boss", 0.329, 0.602, 4887},
        {"boss", 0.101, 0.360, 4831},
        {"boss", 0.536, 0.568, 6243},
        {"boss", 0.614, 0.625, 12902},
    },
    [222] = { -- Blackfathom Deeps 2
        {"level", 0.477, 0.707, 223},
        {"level", 0.350, 0.290, 221},
        {"boss", 0.519, 0.816, 4832},
        {"boss", 0.856, 0.866, 4829},
    },
    [223] = { -- Blackfathom Deeps 3
        {"level", 0.300, 0.612, 222, true},
        {"boss", 0.606, 0.312, 4830},
        {"boss", 0.234, 0.498, 12876},
    },
    [226] = { -- Gnomeregan - The Hall of Gears
        {"entrance", 0.644, 0.275},
        {"level", 0.345, 0.640, 227},
        {"level", 0.470, 0.870, 227},
        {"level", 0.551, 0.440, 227},
        {"boss", 0.770, 0.670, 7361},
    },
    [302] = { -- Scarlet Monastery - Graveyard
        {"entrance", 0.840, 0.830},
        {"boss", 0.721, 0.593, 3983},
        {"boss", 0.250, 0.560, 4543},
        {"boss", 0.325, 0.660, 6490},
        {"boss", 0.400, 0.460, 6488},
        {"boss", 0.400, 0.660, 6489},
    },
    [303] = { -- Scarlet Monastery - Library
        {"entrance", 0.130, 0.248},
        {"boss", 0.300, 0.850, 3974},
        {"boss", 0.835, 0.740, 6487},
    },
    [304] = { -- Scarlet Monastery - Armory
        {"entrance", 0.610, 0.955},
        {"boss", 0.785, 0.103, 3975},
    },
    [305] = { -- Scarlet Monastery - Cathedral
        {"entrance", 0.623, 0.920},
        {"boss", 0.487, 0.280, 3976},
        {"boss", 0.493, 0.160, 3977},
        {"boss", 0.559, 0.243, 4542},
    },
    [301] = { -- Razorfen Kraul
        {"entrance", 0.715, 0.837},
        {"boss", 0.810, 0.510, 6168},
        {"boss", 0.865, 0.410, 4424},
        {"boss", 0.570, 0.300, 4428},
        {"boss", 0.215, 0.300, 4420},
        {"boss", 0.112, 0.724, 4422},
        {"boss", 0.110, 0.303, 4425},
        {"boss", 0.080, 0.690, 4421},
        {"boss", 0.494, 0.471, 4842},
    },
    [300] = { -- Razorfen Downs
        {"entrance", 0.237, 0.190},
        {"boss", 0.500, 0.080, 7356}, -- Plaguemaw the Rotting
        {"boss", 0.855, 0.450, 7357},
        {"boss", 0.350, 0.670, 8567},
        {"boss", 0.529, 0.672, 7354},
        {"boss", 0.443, 0.596, 7358},
        {"boss", 0.597, 0.275, 7355},
    },
    [280] = { -- Maraudon - Caverns of Maraudon
        {"entrance", 0.768, 0.657},
        {"level", 0.145, 0.570, 281},
        {"entrance", 0.622, 0.281},
        {"boss", 0.348, 0.107, 13282},
        {"boss", 0.162, 0.340, 12258},
        {"boss", 0.377, 0.694, 12236},
        {"boss", 0.246, 0.874, 12237},
    },
    [230] = { -- Uldaman - Hall of the Keepers
        {"entrance", 0.285, 0.692},
        {"level", 0.485, 0.210, 231},
        {"entrance", 0.680, 0.725},
        {"boss", 0.541, 0.722, 6910},
        {"boss", 0.585, 0.910, 6906},
        {"boss", 0.474, 0.407, 7206},
        {"boss", 0.258, 0.360, 7291},
        {"boss", 0.212, 0.248, 4854},
        {"boss", 0.360, 0.730, 7228},
    },
    [234] = { -- Dire Maul - Dire Maul
        {"entrance", 0.718, 0.926},
        {"level", 0.125, 0.080, 235},
    },
    [219] = { -- Zul'Farrak
        {"entrance", 0.566, 0.901},
        {"boss", 0.690, 0.256, 8127},
        {"boss", 0.554, 0.296, 7272},
        {"boss", 0.440, 0.160, 7271},
        {"boss", 0.255, 0.130, 7604},
        {"boss", 0.289, 0.403, 7795},
        {"boss", 0.420, 0.360, 7797},
        {"boss", 0.440, 0.330, 7267},
        {"boss", 0.538, 0.373, 10082},
        {"boss", 0.463, 0.578, 10080},
        {"boss", 0.317, 0.460, 10081},
        {"boss", 0.235, 0.183, 7796},
        {"boss", 0.334, 0.170, 7275},
        {"boss", 0.305, 0.400, 7273},
    },
    [317] = { -- Stratholme - Crusader's Square
        {"entrance", 0.640, 0.880},
        {"boss", 0.425, 0.080, 10808}, -- Timmy the Cruel
        {"boss", 0.575, 0.190, 10439}, -- Ramstein the Gorger
        {"entrance", 0.686, 0.880},
        {"level", 0.900, 0.330, 318, true},
        {"boss", 0.815, 0.438, 10393},
        {"boss", 0.847, 0.454, 10558},
        {"boss", 0.729, 0.193, 10516},
        {"boss", 0.304, 0.400, 11032},
        {"boss", 0.036, 0.501, 10997},
        {"boss", 0.271, 0.751, 10811},
        {"boss", 0.188, 0.837, 10813},
    },
    [220] = { -- The Temple of Atal'Hakkar
        {"entrance", 0.500, 0.110},
        {"boss", 0.125, 0.190, 5721}, -- Dreamscythe
        {"boss", 0.200, 0.190, 5720}, -- Weaver
        {"boss", 0.451, 0.585, 5713},
        {"boss", 0.451, 0.585, 5714},
        {"boss", 0.451, 0.585, 5715},
        {"boss", 0.451, 0.585, 5712},
        {"boss", 0.451, 0.585, 5717},
        {"boss", 0.451, 0.585, 5716},
        {"boss", 0.760, 0.370, 5710},
        {"boss", 0.767, 0.361, 5711},
        {"boss", 0.461, 0.845, 5719},
        {"boss", 0.448, 0.851, 5722},
        {"boss", 0.686, 0.874, 5709},
        {"boss", 0.501, 0.358, 8580},
        {"boss", 0.240, 0.457, 8443},
    },
    [242] = { -- Blackrock Depths - Detention Block
        {"entrance", 0.333, 0.791},
        {"level", 0.125, 0.080, 243},
        {"boss", 0.494, 0.567, 9025},
        {"boss", 0.475, 0.934, 9018},
        {"boss", 0.495, 0.617, 9319},
        {"boss", 0.240, 0.516, 9016},
        {"boss", 0.561, 0.312, 9017},
        {"boss", 0.613, 0.242, 9056},
        {"boss", 0.545, 0.700, 9024},
        {"boss", 0.505, 0.014, 8923},
        {"boss", 0.356, 0.570, 9033},
        {"boss", 0.500, 0.635, 9031},
    },
    [250] = { -- Blackrock Spire - Tazz'Alor
        {"entrance", 0.050, 0.080},
        {"level", 0.125, 0.080, 251},
        {"boss", 0.200, 0.080, 9196}, -- Highlord Omokk
        {"boss", 0.275, 0.080, 9236}, -- Shadow Hunter Vosh'gajin
        {"boss", 0.350, 0.080, 9237}, -- War Master Voone
        {"boss", 0.425, 0.080, 10596}, -- Mother Smolderweb
        {"boss", 0.500, 0.080, 10584}, -- Urok Doomhowl
        {"boss", 0.575, 0.080, 9736}, -- Quartermaster Zigris
        {"boss", 0.050, 0.190, 10220}, -- Halycon
        {"boss", 0.125, 0.190, 10268}, -- Gizrul the Slavener
        {"boss", 0.200, 0.190, 9568}, -- Overlord Wyrmthalak
        {"boss", 0.275, 0.190, 9219}, -- Spirestone Butcher
        {"boss", 0.350, 0.190, 9218}, -- Spirestone Battle Lord
        {"boss", 0.425, 0.190, 9217}, -- Spirestone Lord Magus
        {"boss", 0.500, 0.190, 9596}, -- Bannok Grimaxe
        {"boss", 0.575, 0.190, 10376}, -- Crystal Fang
        {"boss", 0.050, 0.300, 9718}, -- Ghok Bashguud
        {"boss", 0.125, 0.300, 9816}, -- Pyroguard Emberseer
        {"boss", 0.200, 0.300, 10264}, -- Solakar Flamewreath
        {"boss", 0.275, 0.300, 10899}, -- Goraluk Anvilcrack
        {"boss", 0.350, 0.300, 10509}, -- Jed Runewatcher
        {"boss", 0.425, 0.300, 10429}, -- Warchief Rend Blackhand
        {"boss", 0.500, 0.300, 10339}, -- Gyth
        {"boss", 0.575, 0.300, 10430}, -- The Beast
        {"boss", 0.050, 0.410, 10363}, -- General Drakkisath
    },
    [306] = { -- Scholomance - The Reliquary
        {"entrance", 0.390, 0.652},
        {"level", 0.125, 0.080, 307},
        {"boss", 0.200, 0.080, 14861}, -- Blood Steward of Kirtonos
        {"boss", 0.275, 0.080, 10506}, -- Kirtonos the Herald
        {"boss", 0.350, 0.080, 10503}, -- Jandice Barov
        {"boss", 0.425, 0.080, 11622}, -- Rattlegore
        {"boss", 0.500, 0.080, 14516}, -- Death Knight Darkreaver
        {"boss", 0.575, 0.080, 10433}, -- Marduk Blackpool
        {"boss", 0.050, 0.190, 10432}, -- Vectus
        {"boss", 0.200, 0.190, 10505}, -- Instructor Malicia
        {"boss", 0.275, 0.190, 11261}, -- Doctor Theolen Krastinov
        {"boss", 0.350, 0.190, 10901}, -- Lorekeeper Polkelt
        {"boss", 0.425, 0.190, 10507}, -- The Ravenian
        {"boss", 0.500, 0.190, 10504}, -- Lord Alexei Barov
        {"boss", 0.575, 0.190, 10502}, -- Lady Illucia Barov
        {"boss", 0.050, 0.300, 1853}, -- Darkmaster Gandling
    },
    [232] = { -- Molten Core
        {"entrance", 0.264, 0.226},
        {"boss", 0.660, 0.370, 12118}, -- Lucifron
        {"boss", 0.695, 0.230, 11982}, -- Magmadar
        {"boss", 0.350, 0.490, 12259}, -- Gehennas
        {"boss", 0.315, 0.690, 12057}, -- Garr
        {"boss", 0.550, 0.850, 12264}, -- Shazzrah
        {"boss", 0.535, 0.750, 12056}, -- Baron Geddon
        {"boss", 0.810, 0.820, 12098}, -- Sulfuron Harbinger
        {"boss", 0.685, 0.570, 11988}, -- Golemagg the Incinerator
        {"boss", 0.840, 0.660, 12018}, -- Majordomo Executus
        {"boss", 0.548, 0.540, 11502}, -- Ragnaros
    },
    [248] = { -- Onyxia's Lair
        {"entrance", 0.341, 0.205},
        {"boss", 0.670, 0.310, 10184}, -- Onyxia
    },
    [287] = { -- Blackwing Lair - Dragonmaw Garrison
        {"entrance", 0.527, 0.836},
        {"level", 0.435, 0.300, 288, true},
        {"level", 0.360, 0.130, 288, true},
        {"boss", 0.200, 0.080, 12435}, -- Razorgore the Untamed
        {"boss", 0.275, 0.080, 13020}, -- Vaelastrasz the Corrupt
        {"boss", 0.350, 0.080, 12017}, -- Broodlord Lashlayer
        {"boss", 0.425, 0.080, 11983}, -- Firemaw
        {"boss", 0.500, 0.080, 14601}, -- Ebonroc
        {"boss", 0.575, 0.080, 11981}, -- Flamegor
        {"boss", 0.050, 0.190, 14020}, -- Chromaggus
        {"boss", 0.125, 0.190, 11583}, -- Nefarian
    },
    [233] = { -- Zul'Gurub
        {"entrance", 0.290, 0.490},
        {"boss", 0.390, 0.730, 14517}, -- High Priestess Jeklik
        {"boss", 0.515, 0.540, 14507}, -- High Priest Venoxis
        {"boss", 0.470, 0.770, 14510}, -- High Priestess Mar'li
        {"boss", 0.625, 0.680, 11382}, -- Bloodlord Mandokir
        {"boss", 0.600, 0.462, 15082}, -- Gri'lek / Hazza'rah / Renataki / Wushoolay
        {"boss", 0.535, 0.320, 15114}, -- Gahz'ranka
        {"boss", 0.620, 0.340, 14509}, -- High Priest Thekal
        {"boss", 0.475, 0.190, 14515}, -- High Priestess Arlokk
        {"boss", 0.310, 0.240, 11380}, -- Jin'do the Hexxer
        {"boss", 0.505, 0.390, 14834}, -- Hakkar
    },
    [247] = { -- Ruins of Ahn'Qiraj
        {"entrance", 0.050, 0.080},
        {"boss", 0.200, 0.080, 15348}, -- Kurinnaxx
        {"boss", 0.275, 0.080, 15341}, -- General Rajaxx
        {"boss", 0.350, 0.080, 15340}, -- Moam
        {"boss", 0.425, 0.080, 15370}, -- Buru the Gorger
        {"boss", 0.500, 0.080, 15369}, -- Ayamiss the Hunter
        {"boss", 0.575, 0.080, 15339}, -- Ossirian the Unscarred
    },
    [319] = { -- Temple of Ahn'Qiraj - The Hive Undergrounds
        {"entrance", 0.050, 0.080},
        {"level", 0.125, 0.080, 320},
        {"boss", 0.200, 0.080, 15263}, -- The Prophet Skeram
        {"boss", 0.275, 0.080, 15544}, -- Vem / Lord Kri / Princess Yauj
        {"boss", 0.350, 0.080, 15516}, -- Battleguard Sartura
        {"boss", 0.425, 0.080, 15510}, -- Fankriss the Unyielding
        {"boss", 0.500, 0.080, 15299}, -- Viscidus
        {"boss", 0.575, 0.080, 15509}, -- Princess Huhuran
        {"boss", 0.050, 0.190, 15276}, -- Emperor Vek'lor / Emperor Vek'nilash
        {"boss", 0.125, 0.190, 15517}, -- Ouro
        {"boss", 0.200, 0.190, 15727}, -- C'Thun
    },
    [162] = { -- Naxxramas - The Construct Quarter
        {"entrance", 0.050, 0.080},
        {"level", 0.125, 0.080, 163},
        {"boss", 0.200, 0.080, 15956}, -- Anub'Rekhan
        {"boss", 0.275, 0.080, 15953}, -- Grand Widow Faerlina
        {"boss", 0.350, 0.080, 15952}, -- Maexxna
        {"boss", 0.425, 0.080, 15954}, -- Noth the Plaguebringer
        {"boss", 0.500, 0.080, 15936}, -- Heigan the Unclean
        {"boss", 0.575, 0.080, 16011}, -- Loatheb
        {"boss", 0.050, 0.190, 16061}, -- Instructor Razuvious
        {"boss", 0.125, 0.190, 16060}, -- Gothik the Harvester
        {"boss", 0.200, 0.190, 16064}, -- Thane Korth'azz / Lady Blaumeux / Sir Zeliek / Highlord Mograine
        {"boss", 0.275, 0.190, 16028}, -- Patchwerk
        {"boss", 0.350, 0.190, 15931}, -- Grobbulus
        {"boss", 0.425, 0.190, 15932}, -- Gluth
        {"boss", 0.500, 0.190, 15928}, -- Thaddius
        {"boss", 0.575, 0.190, 15989}, -- Sapphiron
        {"boss", 0.050, 0.300, 15990}, -- Kel'Thuzad
    },
    [314] = { -- Shadowfang Keep - Upper Observatory
        {"level", 0.437, 0.743, 315, true},
        {"level", 0.490, 0.780, 313},
    },
    [227] = { -- Gnomeregan - The Dormitory
        {"level", 0.245, 0.580, 228},
        {"level", 0.430, 0.830, 226, true},
        {"level", 0.640, 0.580, 226, true},
        {"boss", 0.755, 0.450, 7079},
    },
    [228] = { -- Gnomeregan - Launch Bay
        {"entrance", 0.870, 0.480},
        {"level", 0.488, 0.710, 229},
        {"level", 0.273, 0.308, 229},
        {"level", 0.445, 0.430, 227, true},
        {"boss", 0.438, 0.865, 6229},
    },
    [229] = { -- Gnomeregan - Tinkers' Court
        {"level", 0.481, 0.540, 228, true},
        {"level", 0.710, 0.773, 228, true},
        {"boss", 0.508, 0.331, 6235},
        {"boss", 0.295, 0.540, 6228},
        {"boss", 0.313, 0.300, 7800},
    },
    [231] = { -- Uldaman - Khaz'Goroth's Seat
        {"level", 0.645, 0.410, 230, true},
        {"boss", 0.554, 0.506, 2748},
    },
    [281] = { -- Maraudon - Zaetar's Grave
        {"level", 0.295, 0.040, 280, true},
        {"boss", 0.245, 0.144, 12225},
        {"boss", 0.406, 0.482, 12203},
        {"boss", 0.484, 0.686, 13601},
        {"boss", 0.333, 0.771, 13596},
        {"boss", 0.242, 0.784, 12201},
    },
    [243] = { -- Blackrock Depths - Shadowforge City
        {"level", 0.125, 0.080, 242},
        {"boss", 0.607, 0.673, 9041},
        {"boss", 0.369, 0.650, 8983},
        {"boss", 0.532, 0.649, 9502},
        {"boss", 0.491, 0.619, 9543},
        {"boss", 0.498, 0.609, 9499},
        {"boss", 0.538, 0.488, 9156},
        {"boss", 0.817, 0.119, 9938},
        {"boss", 0.567, 0.218, 9039},
        {"boss", 0.932, 0.119, 9019},
        {"boss", 0.931, 0.115, 8929},
        {"boss", 0.480, 0.580, 9537},
    },
    [251] = { -- Blackrock Spire - Skitterweb Tunnels
        {"level", 0.125, 0.080, 252},
    },
    [252] = { -- Blackrock Spire - Hordemar City
        {"level", 0.125, 0.080, 253},
    },
    [253] = { -- Blackrock Spire - Hall of Blackhand
        {"level", 0.125, 0.080, 254},
    },
    [254] = { -- Blackrock Spire - Halycon's Lair
        {"level", 0.125, 0.080, 255},
    },
    [255] = { -- Blackrock Spire - Chamber of Battle
        {"level", 0.125, 0.080, 254},
    },
    [288] = { -- Blackwing Lair - Halls of Strife
        {"level", 0.525, 0.320, 287},
        {"level", 0.463, 0.198, 287},
    },
    [289] = { -- Blackwing Lair - Crimson Laboratories
        {"level", 0.125, 0.080, 290},
    },
    [290] = { -- Blackwing Lair - Nefarian's Lair
        {"level", 0.125, 0.080, 289},
    },
    [235] = { -- Dire Maul - Gordok Commons
        {"level", 0.125, 0.080, 236},
        {"boss", 0.699, 0.752, 14326},
        {"boss", 0.620, 0.657, 14322},
        {"boss", 0.493, 0.816, 14321},
        {"boss", 0.277, 0.588, 14323},
        {"boss", 0.318, 0.497, 14325},
        {"boss", 0.312, 0.254, 14324},
        {"boss", 0.319, 0.259, 11501},
    },
    [236] = { -- Dire Maul - Capital Gardens
        {"level", 0.125, 0.080, 237},
        {"boss", 0.332, 0.530, 11489},
        {"boss", 0.202, 0.812, 11488},
    },
    [237] = { -- Dire Maul - Court of the Highborne
        {"level", 0.125, 0.080, 238},
        {"boss", 0.294, 0.436, 11487},
        {"boss", 0.322, 0.143, 11467},
        {"boss", 0.190, 0.130, 11486},
    },
    [238] = { -- Dire Maul - Prison of Immol'Thar
        {"level", 0.125, 0.080, 239},
        {"boss", 0.350, 0.576, 11496},
    },
    [239] = { -- Dire Maul - Warpwood Quarter
        {"level", 0.125, 0.080, 240},
        {"boss", 0.122, 0.310, 14354},
        {"boss", 0.435, 0.537, 11490},
        {"boss", 0.423, 0.463, 13280},
        {"boss", 0.426, 0.482, 14327},
    },
    [240] = { -- Dire Maul - The Shrine of Eldretharr
        {"level", 0.125, 0.080, 239},
        {"boss", 0.554, 0.269, 11492},
    },
    [307] = { -- Scholomance - Chamber of Summoning
        {"level", 0.125, 0.080, 308},
    },
    [308] = { -- Scholomance - The Upper Study
        {"level", 0.125, 0.080, 309},
    },
    [309] = { -- Scholomance - Headmaster's Study
        {"level", 0.125, 0.080, 308},
        {"boss", 0.406, 0.884, 10508},
    },
    [318] = { -- Stratholme - The Gauntlet
        {"level", 0.355, 0.390, 317},
        {"level", 0.570, 0.770, 317},
        {"boss", 0.649, 0.489, 10809},
        {"boss", 0.750, 0.468, 10436},
        {"boss", 0.564, 0.469, 10437},
        {"boss", 0.682, 0.199, 10438},
        {"boss", 0.653, 0.755, 10435},
        {"boss", 0.372, 0.199, 10440},
    },
    [320] = { -- Temple of Ahn'Qiraj - The Temple Gates
        {"level", 0.125, 0.080, 321},
    },
    [321] = { -- Temple of Ahn'Qiraj - Vault of C'Thun
        {"level", 0.125, 0.080, 320},
    },
    [163] = { -- Naxxramas - The Arachnid Quarter
        {"level", 0.125, 0.080, 164},
    },
    [164] = { -- Naxxramas - The Military Quarter
        {"level", 0.125, 0.080, 165},
    },
    [165] = { -- Naxxramas - The Plague Quarter
        {"level", 0.125, 0.080, 166},
    },
    [166] = { -- Naxxramas - The Lower Necropolis
        {"level", 0.125, 0.080, 167},
    },
    [167] = { -- Naxxramas - The Upper Necropolis
        {"level", 0.125, 0.080, 166},
    },
}
