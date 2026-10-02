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
        {"boss", 0.486, 0.719, 255699}, -- Lordaeron Captain
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
        {"boss", 0.775, 0.690, 260325}, -- Shadetooth
        {"boss", 0.790, 0.280, 260808}, -- Highland Horror
    },
    [2959] = { -- City of Dalaran
        {"level", 0.605, 0.530, 2959002},
        {"boss", 0.536, 0.712, 245999}, -- Arcane Anomaly
        {"boss", 0.515, 0.270, 246020}, -- Shade of the Archmage
    },
    [2959002] = { -- City of Dalaran - Dalaran Sewers
        {"entrance", 0.184, 0.840},
        {"level", 0.645, 0.640, 2959, true},
        {"boss", 0.545, 0.510, 247126}, -- Atrexis the Grave Knight
    },
    [213] = { -- Ragefire Chasm
        {"entrance", 0.611, 0.072},
        {"boss", 0.564, 0.372, 11517}, -- Oggleflint
        {"boss", 0.406, 0.574, 11520}, -- Taragaman the Hungerer
        {"boss", 0.338, 0.840, 11518}, -- Jergosh the Invoker
        {"boss", 0.422, 0.857, 11519}, -- Bazzalan
    },
    [291] = { -- The Deadmines
        {"entrance", 0.297, 0.133},
        {"level", 0.655, 0.667, 292},
        {"boss", 0.374, 0.610, 644}, -- Rhahk'Zor
        {"boss", 0.523, 0.510, 3586}, -- Miner Johnson
        {"boss", 0.493, 0.862, 642}, -- Sneed's Shredder / Sneed
    },
    [292] = { -- The Deadmines - Ironclad Cove
        {"level", 0.123, 0.883, 291, true},
        {"boss", 0.121, 0.741, 1763}, -- Gilnid
        {"boss", 0.525, 0.170, 646}, -- Mr. Smite
        {"boss", 0.582, 0.357, 647}, -- Captain Greenskin
        {"boss", 0.603, 0.455, 639}, -- Edwin VanCleef
        {"boss", 0.668, 0.398, 645}, -- Cookie
    },
    [279] = { -- Wailing Caverns
        {"entrance", 0.463, 0.590},
        {"boss", 0.303, 0.423, 3671}, -- Lady Anacondra
        {"boss", 0.385, 0.340, 3653}, -- Kresh
        {"boss", 0.162, 0.563, 3669}, -- Lord Cobrahn
        {"boss", 0.187, 0.379, 3670}, -- Lord Pythas
        {"boss", 0.604, 0.742, 3674}, -- Skum
        {"boss", 0.480, 0.410, 5912}, -- Deviate Faerie Dragon
        {"boss", 0.613, 0.537, 3673}, -- Lord Serpentis
        {"boss", 0.555, 0.475, 5775}, -- Verdan the Everliving
        {"boss", 0.338, 0.133, 3654}, -- Mutanus the Devourer
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
        {"boss", 0.630, 0.185, 4275}, -- Archmage Arugal
        {"boss", 0.553, 0.627, 3927}, -- Wolf Master Nandos
    },
    [316] = { -- Shadowfang Keep 7
        {"level", 0.239, 0.745, 310},
        {"level", 0.436, 0.331, 312, true},
        {"boss", 0.595, 0.820, 4279}, -- Odo the Blindwatcher
        {"boss", 0.690, 0.770, 3872}, -- Deathsworn Captain
    },
    [225] = { -- The Stockade
        {"entrance", 0.500, 0.815},
        {"boss", 0.440, 0.446, 1696}, -- Targorr the Dread
        {"boss", 0.691, 0.300, 1666}, -- Kam Deepfury
        {"boss", 0.780, 0.454, 1717}, -- Hamhock
        {"boss", 0.745, 0.562, 1716}, -- Bazil Thredd
        {"boss", 0.213, 0.260, 1663}, -- Dextren Ward
        {"boss", 0.497, 0.222, 1720}, -- Bruegal Ironknuckle
    },
    [221] = { -- Blackfathom Deeps 1
        {"entrance", 0.453, 0.108},
        {"level", 0.621, 0.741, 222},
        {"boss", 0.325, 0.595, 4887}, -- Ghamoo-ra
        {"boss", 0.117, 0.378, 4831}, -- Lady Sarevess
        {"boss", 0.536, 0.568, 6243}, -- Gelihast
    },
    [222] = { -- Blackfathom Deeps 2
        {"level", 0.477, 0.707, 223},
        {"boss", 0.325, 0.710, 12902}, -- Lorgus Jett
        {"boss", 0.413, 0.727, 12876}, -- Baron Aquanis
        {"boss", 0.515, 0.810, 4832}, -- Twilight Lord Kelris
        {"boss", 0.848, 0.853, 4829}, -- Aku'mai
        {"level", 0.350, 0.290, 221},
    },
    [223] = { -- Blackfathom Deeps 3
        {"boss", 0.585, 0.280, 4830}, -- Old Serra'kis
        {"level", 0.300, 0.612, 222, true},
    },
    [226] = { -- Gnomeregan - The Hall of Gears
        {"entrance", 0.644, 0.275},
        {"level", 0.345, 0.640, 227},
        {"level", 0.470, 0.870, 227},
        {"level", 0.551, 0.440, 227},
        {"boss", 0.770, 0.670, 7361}, -- Grubbis
    },
    [302] = { -- Scarlet Monastery - Graveyard
        {"entrance", 0.840, 0.830},
        {"boss", 0.721, 0.593, 3983}, -- Interrogator Vishas
        {"boss", 0.250, 0.560, 4543}, -- Bloodmage Thalnos
        {"boss", 0.400, 0.660, 6489}, -- Ironspine
        {"boss", 0.325, 0.660, 6490}, -- Azshir the Sleepless
        {"boss", 0.400, 0.460, 6488}, -- Fallen Champion
    },
    [303] = { -- Scarlet Monastery - Library
        {"entrance", 0.130, 0.248},
        {"boss", 0.300, 0.850, 3974}, -- Houndmaster Loksey
        {"boss", 0.835, 0.740, 6487}, -- Arcanist Doan
    },
    [304] = { -- Scarlet Monastery - Armory
        {"entrance", 0.610, 0.955},
        {"boss", 0.785, 0.103, 3975}, -- Herod
    },
    [305] = { -- Scarlet Monastery - Cathedral
        {"entrance", 0.623, 0.920},
        {"boss", 0.559, 0.243, 4542}, -- High Inquisitor Fairbanks
        {"boss", 0.487, 0.280, 3976}, -- Scarlet Commander Mograine
        {"boss", 0.493, 0.160, 3977}, -- High Inquisitor Whitemane
    },
    [301] = { -- Razorfen Kraul
        {"entrance", 0.715, 0.837},
        {"boss", 0.810, 0.510, 6168}, -- Roogug
        {"boss", 0.865, 0.410, 4424}, -- Aggem Thorncurse
        {"boss", 0.570, 0.300, 4428}, -- Death Speaker Jargba
        {"boss", 0.215, 0.300, 4420}, -- Overlord Ramtusk
        {"boss", 0.500, 0.080, 4422}, -- Agathelos the Raging
        {"boss", 0.575, 0.080, 4425}, -- Blind Hunter
        {"boss", 0.080, 0.690, 4421}, -- Charlga Razorflank
        {"boss", 0.125, 0.190, 4842}, -- Earthcaller Halmgar
    },
    [300] = { -- Razorfen Downs
        {"entrance", 0.237, 0.190},
        {"boss", 0.200, 0.080, 7355}, -- Tuten'kash
        {"boss", 0.855, 0.450, 7357}, -- Mordresh Fire Eye
        {"boss", 0.350, 0.670, 8567}, -- Glutton
        {"boss", 0.425, 0.080, 7354}, -- Ragglesnout
        {"boss", 0.500, 0.080, 7356}, -- Plaguemaw the Rotting
        {"boss", 0.443, 0.596, 7358}, -- Amnennar the Coldbringer
    },
    [280] = { -- Maraudon - Caverns of Maraudon
        {"entrance", 0.768, 0.657},
        {"level", 0.145, 0.570, 281},
        {"boss", 0.200, 0.080, 13282}, -- Noxxion
        {"boss", 0.275, 0.080, 12258}, -- Razorlash
        {"boss", 0.350, 0.080, 12236}, -- Lord Vyletongue
        {"boss", 0.425, 0.080, 12237}, -- Meshlok the Harvester
        {"boss", 0.500, 0.080, 12225}, -- Celebras the Cursed
        {"boss", 0.575, 0.080, 12203}, -- Landslide
        {"boss", 0.050, 0.190, 13601}, -- Tinkerer Gizlock
        {"entrance", 0.622, 0.281},
    },
    [230] = { -- Uldaman - Hall of the Keepers
        {"entrance", 0.285, 0.692},
        {"level", 0.485, 0.210, 231},
        {"boss", 0.200, 0.080, 6910}, -- Revelosh
        {"boss", 0.585, 0.910, 6906}, -- Baelog / Eric \"The Swift\" / Olaf
        {"boss", 0.360, 0.730, 7228}, -- Ironaya
        {"boss", 0.425, 0.080, 7206}, -- Ancient Stone Keeper
        {"boss", 0.500, 0.080, 7291}, -- Galgann Firehammer
        {"boss", 0.575, 0.080, 4854}, -- Grimlok
        {"entrance", 0.680, 0.725},
    },
    [234] = { -- Dire Maul - Dire Maul
        {"entrance", 0.718, 0.926},
        {"level", 0.125, 0.080, 235},
        {"boss", 0.200, 0.080, 14354}, -- Pusillin
        {"boss", 0.275, 0.080, 11490}, -- Zevrim Thornhoof
        {"boss", 0.350, 0.080, 13280}, -- Hydrospawn
        {"boss", 0.425, 0.080, 14327}, -- Lethtendris
        {"boss", 0.500, 0.080, 11492}, -- Alzzin the Wildshaper
        {"boss", 0.575, 0.080, 11489}, -- Tendris Warpwood
        {"boss", 0.050, 0.190, 11488}, -- Illyanna Ravenoak
        {"boss", 0.125, 0.190, 11487}, -- Magister Kalendris
        {"boss", 0.200, 0.190, 11496}, -- Immol'thar
        {"boss", 0.275, 0.190, 11486}, -- Prince Tortheldrin
        {"boss", 0.350, 0.190, 11467}, -- Tsu'zee
        {"boss", 0.425, 0.190, 14326}, -- Guard Mol'dar
        {"boss", 0.500, 0.190, 14322}, -- Stomper Kreeg
        {"boss", 0.575, 0.190, 14321}, -- Guard Fengus
        {"boss", 0.050, 0.300, 14323}, -- Guard Slip'kik
        {"boss", 0.125, 0.300, 14325}, -- Captain Kromcrush
        {"boss", 0.200, 0.300, 14324}, -- Cho'Rush the Observer
        {"boss", 0.275, 0.300, 11501}, -- King Gordok
    },
    [219] = { -- Zul'Farrak
        {"entrance", 0.566, 0.901},
        {"boss", 0.200, 0.080, 8127}, -- Antu'sul
        {"boss", 0.275, 0.080, 7272}, -- Theka the Martyr
        {"boss", 0.440, 0.160, 7271}, -- Witch Doctor Zum'rah
        {"boss", 0.425, 0.080, 10082}, -- Zerillis
        {"boss", 0.500, 0.080, 10080}, -- Sandarr Dunereaver
        {"boss", 0.255, 0.130, 7604}, -- Sergeant Bly
        {"boss", 0.050, 0.190, 7795}, -- Hydromancer Velratha
        {"boss", 0.305, 0.400, 7273}, -- Gahz'rilla
        {"boss", 0.200, 0.190, 10081}, -- Dustwraith
        {"boss", 0.275, 0.190, 7796}, -- Nekrum Gutchewer
        {"boss", 0.334, 0.170, 7275}, -- Shadowpriest Sezz'ziz
        {"boss", 0.440, 0.330, 7267}, -- Chief Ukorz Sandscalp
        {"boss", 0.420, 0.360, 7797}, -- Ruuzlu
    },
    [317] = { -- Stratholme - Crusader's Square
        {"entrance", 0.640, 0.880},
        {"boss", 0.200, 0.080, 10393}, -- Skul
        {"boss", 0.275, 0.080, 10558}, -- Hearthsinger Forresten
        {"boss", 0.350, 0.080, 10516}, -- The Unforgiven
        {"boss", 0.425, 0.080, 10808}, -- Timmy the Cruel
        {"boss", 0.500, 0.080, 11032}, -- Malor the Zealous
        {"boss", 0.575, 0.080, 10997}, -- Cannon Master Willey
        {"boss", 0.050, 0.190, 10811}, -- Archivist Galford
        {"boss", 0.125, 0.190, 10813}, -- Balnazzar
        {"boss", 0.200, 0.190, 10809}, -- Stonespine
        {"boss", 0.275, 0.190, 10435}, -- Magistrate Barthilas
        {"boss", 0.350, 0.190, 10436}, -- Baroness Anastari
        {"boss", 0.425, 0.190, 10437}, -- Nerub'enkan
        {"boss", 0.500, 0.190, 10438}, -- Maleki the Pallid
        {"boss", 0.575, 0.190, 10439}, -- Ramstein the Gorger
        {"boss", 0.050, 0.300, 10440}, -- Baron Rivendare
        {"entrance", 0.686, 0.880},
        {"level", 0.900, 0.330, 318, true},
    },
    [220] = { -- The Temple of Atal'Hakkar
        {"entrance", 0.500, 0.110},
        {"boss", 0.200, 0.080, 8580}, -- Atal'alarion
        {"boss", 0.275, 0.080, 5713}, -- Gasher
        {"boss", 0.350, 0.080, 5714}, -- Loro
        {"boss", 0.425, 0.080, 5715}, -- Hukku
        {"boss", 0.500, 0.080, 5712}, -- Zolo
        {"boss", 0.575, 0.080, 5717}, -- Mijan
        {"boss", 0.050, 0.190, 5716}, -- Zul'Lor
        {"boss", 0.125, 0.190, 5721}, -- Dreamscythe
        {"boss", 0.200, 0.190, 5720}, -- Weaver
        {"boss", 0.275, 0.190, 5710}, -- Jammal'an the Prophet
        {"boss", 0.350, 0.190, 5711}, -- Ogom the Wretched
        {"boss", 0.425, 0.190, 5719}, -- Morphaz
        {"boss", 0.500, 0.190, 5722}, -- Hazzas
        {"boss", 0.575, 0.190, 8443}, -- Avatar of Hakkar
        {"boss", 0.050, 0.300, 5709}, -- Shade of Eranikus
    },
    [242] = { -- Blackrock Depths - Detention Block
        {"entrance", 0.333, 0.791},
        {"level", 0.125, 0.080, 243},
        {"boss", 0.200, 0.080, 9025}, -- Lord Roccor
        {"boss", 0.275, 0.080, 9016}, -- Bael'Gar
        {"boss", 0.350, 0.080, 9319}, -- Houndmaster Grebmar
        {"boss", 0.425, 0.080, 9018}, -- High Interrogator Gerstahn
        {"boss", 0.500, 0.080, 9031}, -- Anub'shiah / Eviscerator / Gorosh the Dervish / Grizzle / Hedrum the Creeper / Ok'thor the Breaker
        {"boss", 0.575, 0.080, 9024}, -- Pyromancer Loregrain
        {"boss", 0.050, 0.190, 9041}, -- Warder Stilgiss / Verek
        {"boss", 0.125, 0.190, 9056}, -- Fineous Darkvire
        {"boss", 0.200, 0.190, 9017}, -- Lord Incendius
        {"boss", 0.275, 0.190, 8983}, -- Golem Lord Argelmach
        {"boss", 0.350, 0.190, 9543}, -- Ribbly Screwspigot
        {"boss", 0.425, 0.190, 9537}, -- Hurley Blackbreath
        {"boss", 0.500, 0.190, 9502}, -- Phalanx
        {"boss", 0.575, 0.190, 9499}, -- Plugger Spazzring
        {"boss", 0.050, 0.300, 9156}, -- Ambassador Flamelash
        {"boss", 0.125, 0.300, 8923}, -- Panzor the Invincible
        {"boss", 0.200, 0.300, 9039}, -- Doom'rel / Dope'rel / Hate'rel / Seeth'rel / Vile'rel / Gloom'rel / Anger'rel
        {"boss", 0.275, 0.300, 9938}, -- Magmus
        {"boss", 0.350, 0.300, 9033}, -- General Angerforge
        {"boss", 0.425, 0.300, 8929}, -- Princess Moira Bronzebeard
        {"boss", 0.500, 0.300, 9019}, -- Emperor Dagran Thaurissan
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
        {"boss", 0.125, 0.190, 10508}, -- Ras Frostwhisper
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
        {"boss", 0.200, 0.080, 12118}, -- Lucifron
        {"boss", 0.275, 0.080, 11982}, -- Magmadar
        {"boss", 0.840, 0.660, 12259}, -- Gehennas
        {"boss", 0.425, 0.080, 12057}, -- Garr
        {"boss", 0.500, 0.080, 12264}, -- Shazzrah
        {"boss", 0.575, 0.080, 12056}, -- Baron Geddon
        {"boss", 0.050, 0.190, 12098}, -- Sulfuron Harbinger
        {"boss", 0.125, 0.190, 11988}, -- Golemagg the Incinerator
        {"boss", 0.200, 0.190, 12018}, -- Majordomo Executus
        {"boss", 0.548, 0.540, 11502}, -- Ragnaros
    },
    [248] = { -- Onyxia's Lair
        {"entrance", 0.050, 0.080},
        {"boss", 0.200, 0.080, 10184}, -- Onyxia
    },
    [287] = { -- Blackwing Lair - Dragonmaw Garrison
        {"entrance", 0.050, 0.080},
        {"level", 0.125, 0.080, 288},
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
        {"entrance", 0.050, 0.080},
        {"boss", 0.200, 0.080, 14517}, -- High Priestess Jeklik
        {"boss", 0.275, 0.080, 14507}, -- High Priest Venoxis
        {"boss", 0.350, 0.080, 14510}, -- High Priestess Mar'li
        {"boss", 0.425, 0.080, 11382}, -- Bloodlord Mandokir
        {"boss", 0.500, 0.080, 15082}, -- Gri'lek / Hazza'rah / Renataki / Wushoolay
        {"boss", 0.575, 0.080, 15114}, -- Gahz'ranka
        {"boss", 0.050, 0.190, 14509}, -- High Priest Thekal
        {"boss", 0.125, 0.190, 14515}, -- High Priestess Arlokk
        {"boss", 0.200, 0.190, 11380}, -- Jin'do the Hexxer
        {"boss", 0.275, 0.190, 14834}, -- Hakkar
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
        {"boss", 0.755, 0.450, 7079}, -- Viscous Fallout
        {"boss", 0.240, 0.680, 6235}, -- Electrocutioner 6000
    },
    [228] = { -- Gnomeregan - Launch Bay
        {"entrance", 0.870, 0.480},
        {"level", 0.488, 0.710, 229},
        {"level", 0.273, 0.308, 229},
        {"level", 0.445, 0.430, 227, true},
        {"boss", 0.427, 0.878, 6229}, -- Crowd Pummeler 9-60
    },
    [229] = { -- Gnomeregan - Tinkers' Court
        {"level", 0.481, 0.540, 228, true},
        {"level", 0.710, 0.773, 228, true},
        {"boss", 0.450, 0.680, 6228}, -- Dark Iron Ambassador
        {"boss", 0.310, 0.294, 7800}, -- Mekgineer Thermaplugg
    },
    [231] = { -- Uldaman - Khaz'Goroth's Seat
        {"level", 0.645, 0.410, 230, true},
        {"boss", 0.551, 0.506, 2748}, -- Archaedas
    },
    [281] = { -- Maraudon - Zaetar's Grave
        {"level", 0.295, 0.040, 280, true},
        {"boss", 0.255, 0.780, 12201}, -- Princess Theradras
        {"boss", 0.405, 0.810, 13596}, -- Rotgrip
    },
    [243] = { -- Blackrock Depths - Shadowforge City
        {"level", 0.125, 0.080, 242},
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
        {"level", 0.125, 0.080, 289},
    },
    [289] = { -- Blackwing Lair - Crimson Laboratories
        {"level", 0.125, 0.080, 290},
    },
    [290] = { -- Blackwing Lair - Nefarian's Lair
        {"level", 0.125, 0.080, 289},
    },
    [235] = { -- Dire Maul - Gordok Commons
        {"level", 0.125, 0.080, 236},
    },
    [236] = { -- Dire Maul - Capital Gardens
        {"level", 0.125, 0.080, 237},
    },
    [237] = { -- Dire Maul - Court of the Highborne
        {"level", 0.125, 0.080, 238},
    },
    [238] = { -- Dire Maul - Prison of Immol'Thar
        {"level", 0.125, 0.080, 239},
    },
    [239] = { -- Dire Maul - Warpwood Quarter
        {"level", 0.125, 0.080, 240},
    },
    [240] = { -- Dire Maul - The Shrine of Eldretharr
        {"level", 0.125, 0.080, 239},
    },
    [307] = { -- Scholomance - Chamber of Summoning
        {"level", 0.125, 0.080, 308},
    },
    [308] = { -- Scholomance - The Upper Study
        {"level", 0.125, 0.080, 309},
    },
    [309] = { -- Scholomance - Headmaster's Study
        {"level", 0.125, 0.080, 308},
    },
    [318] = { -- Stratholme - The Gauntlet
        {"level", 0.355, 0.390, 317},
        {"level", 0.570, 0.770, 317},
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
