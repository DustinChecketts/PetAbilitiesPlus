local ADDON_NAME, ns = ...

-- Classic (1-60) hunter pet training data.
-- Audited against Petopia Classic's Pet Abilities reference for the complete
-- wild-creature -> ability/rank mappings used by tooltips.
-- Names are authoritative for the Forever compatibility lookup; creature IDs
-- may differ in Forever and can be added to ForeverOverrides.lua when found.

local sources = {}
local function add(ability, rank, family, level, zone, names)
    for _, name in ipairs(names) do
        sources[name] = sources[name] or {}
        table.insert(sources[name], {
            name=name, ability=ability, rank=rank, family=family,
            level=level, zone=zone
        })
    end
end

-- Bite
add("Bite",1,"Various","2-11","Azeroth",{"Ragged Scavenger","Night Web Spider","Prairie Wolf","Night Web Matriarch","Githyiss the Vile","Forest Spider","Snow Tracker Wolf","Prairie Stalker","Gray Forest Wolf","Webwood Venomfang","Winter Wolf","Dreadmaw Crocolisk"})
add("Bite",2,"Various","8-16","Azeroth",{"Starving Winter Wolf","Webwood Silkspinner","Prowler","Vicious Night Web Spider","Prairie Wolf Alpha","Forest Lurker","Coyote","Giant Webwood Spider","Worg","Timber","Coyote Packleader","Lady Sathrah","Loch Crocolisk","Tarantula","Oasis Snapjaw"})
add("Bite",3,"Various","16-24","Azeroth",{"Bloodsnout Worg","Deepmoss Creeper","Wood Lurker","Deviate Crocolisk","Greater Tarantula","Ghostpaw Runner","Deepmoss Webspinner","Shanda the Spinner","Kresh","Forest Moss Creeper","Besseleth","Green Recluse","Large Loch Crocolisk","Chatter","Lupos","Aku'mai Fisher","Creepthess"})
add("Bite",4,"Various","24-32","Azeroth",{"Leech Widow","Giant Moss Creeper","Black Ravager","Ghamoo-ra","Giant Wetlands Crocolisk","Black Ravager Mastiff","Elder Moss Creeper","Aku'mai Snapjaw","Naraxis","Ghostpaw Alpha","Wildthorn Lurker","Snapjaw","Cranky Benj"})
add("Bite",5,"Various","32-39","Azeroth",{"Plains Creeper","Sparkleshell Snapper","Crag Coyote","Drywallow Crocolisk","Giant Plains Creeper","Darkfang Spider","Mudrock Tortoise","Darkfang Lurker","Mottled Drywallow Crocolisk","Darkfang Creeper"})
add("Bite",6,"Various","38-49","Azeroth",{"Barnabus","Ripscale","Drywallow Daggermaw","Longtooth Runner","Deathstrike Tarantula","Sawtooth Snapper","Mudrock Snapjaw","Old Cliff Jumper","Snarler","Deadmire","Timberweb Recluse","Felpaw Wolf","Death Howl"})
add("Bite",7,"Various","48-55","Azeroth",{"Rekk'tilac","Saltwater Snapjaw","Cave Creeper","Sewer Beast","Vilebranch Raiding Wolf","Felpaw Ravager","Ironback","Uhk'loc","Diseased Wolf","Plague Lurker"})
add("Bite",8,"Wolf","56-57","Blackrock Spire",{"Bloodaxe Worg"})

-- Charge
add("Charge",1,"Boar","1-11","Azeroth",{"Young Thistle Boar","Mottled Boar","Thistle Boar","Battleboar","Small Crag Boar","Bristleback Battleboar","Crag Boar","Dire Mottled Boar","Large Crag Boar","Porcine Entourage","Elder Crag Boar","Rockhide Boar","Stonetusk Boar","Elder Mottled Boar","Princess","Scarred Crag Boar","Corrupted Mottled Boar","Longsnout","Mountain Boar"})
add("Charge",2,"Boar","12-17","Azeroth",{"Young Goretusk","Goretusk","Mangy Mountain Boar","Elder Mountain Boar","Great Goretusk"})
add("Charge",3,"Boar","24-28","Azeroth",{"Bellygrub","Agam'ar","Raging Agam'ar","Rotting Agam'ar"})
-- Rank 4 has no known Classic training source.
add("Charge",5,"Boar","48-50","Blasted Lands",{"Ashmane Boar","Grunter"})
add("Charge",6,"Boar","60","Eastern Plaguelands",{"Plagued Swine"})

-- Claw
add("Claw",1,"Various","3-8","Azeroth",{"Scorpid Worker","Sarkoth","Pygmy Surf Crawler","Strigid Owl","Ice Claw Bear"})
add("Claw",2,"Various","8-14","Azeroth",{"Young Forest Bear","Strigid Hunter","Encrusted Surf Crawler","Venomtail Scorpid","Mangeclaw","Death Flayer","Ferocious Grizzled Bear","Thistle Bear","Bjarn","Tide Crawler"})
add("Claw",3,"Various","16-24","Azeroth",{"Black Bear Patriarch","Shore Crawler","Den Mother","Ghost Saber","Clattering Crawler","Ol' Sooty","Gray Bear","Ashenvale Bear","Skittering Crustacean","Snapping Crustacean"})
add("Claw",4,"Various","25-32","Azeroth",{"Elder Ashenvale Bear","Barbed Crustacean","Scorpashi Snapper","Scorpid Reaver"})
add("Claw",5,"Various","34-40","Azeroth",{"Scorpashi Lasher","Vile Sting","Drywallow Snapper","Venomlash Scorpid"})
add("Claw",6,"Various","40-44","Azeroth",{"Scorpid Hunter","Silt Crawler","Ironfur Bear","King Bangalash","Old Grizzlegut","Monstrous Crawler"})
add("Claw",7,"Various","48-56","Azeroth",{"Ironfur Patriarch","Angerclaw Mauler","Mongress","Ironbeak Hunter","Olm the Wise","Shardtooth Bear","Clack the Reaver","Winterspring Owl","Deathlash Scorpid","Diseased Grizzly"})
add("Claw",8,"Various","57-59","Winterspring",{"Winterspring Screecher","Elder Shardtooth"})

-- Cower
add("Cower",1,"Various","5-13","Azeroth",{"Nightsaber","Juvenile Snow Leopard","Greater Duskbat","Flatland Cougar","Durotar Tiger","Elder Plainstrider","Mazzranache","Moonstalker Runt","Foreststrider Fledgling","Fleeting Plainstrider"})
add("Cower",2,"Various","15-24","Azeroth",{"Savannah Patriarch","Ornery Plainstrider","Giant Foreststrider","Moonstalker Sire","Twilight Runner","Starving Mountain Lion"})
add("Cower",3,"Various","25-33","Azeroth",{"Crag Stalker","Feral Mountain Lion","Kraul Bat","Young Panther","Young Stranglethorn Tiger","Greater Kraul Bat","Panther"})
add("Cower",4,"Various","36-39","Azeroth",{"Ridge Stalker","Shrike Bat","Ridge Huntress"})
add("Cower",5,"Various","50-56","Azeroth",{"Jaguero Stalker","Plaguebat","Noxious Plaguebat"})
add("Cower",6,"Various","55-58","Azeroth",{"Frostsaber Cub","Monstrous Plaguebat"})

-- Dash
add("Dash",1,"Various","32-40","Azeroth",{"Kurzen War Tiger","Stranglethorn Tiger","Bonepaw Hyena","Scarlet Tracking Hound","Crag Coyote","Spot","Swamp Jaguar","Magram Bonepaw","Feral Crag Coyote","Broken Tooth","Sin'Dall","Elder Crag Coyote"})
add("Dash",2,"Various","40-48","Azeroth",{"Longtooth Runner","Ridge Stalker Patriarch","Bhag'thera","Starving Blisterpaw","Rabid Crag Coyote","Old Cliff Jumper","Elder Shadowmaw Panther","Murderous Blisterpaw","King Bangalash","Blisterpaw Hyena","Silvermane Stalker","Rabid Blisterpaw"})
add("Dash",3,"Various","50-60","Azeroth",{"Vilebranch Raiding Wolf","Grunter","Ravage","Scarshield Worg","Blackrock Worg","Bloodaxe Worg","Rak'Shiri","Frostsaber Huntress","Frostsaber Stalker","Zulian Panther"})

-- Dive
add("Dive",1,"Various","30-39","Azeroth",{"Kraul Bat","Young Mesa Buzzard","Greater Kraul Bat","Mesa Buzzard","Wayward Buzzard","Dread Flyer","Shrike Bat"})
add("Dive",2,"Various","41-49","Azeroth",{"Vale Screecher","Roc","Fire Roc","Rogue Vale Screecher","Greater Firebird","Searing Roc","Ironbeak Owl","Arash-ethis"})
add("Dive",3,"Various","50-59","Azeroth",{"Carrion Vulture","Ironbeak Hunter","Dark Screecher","Spawn of Hakkar","Spiteflayer","Ironbeak Screecher","Olm the Wise","Plaguebat","Winterspring Owl","Zaricotl","Winterspring Screecher"})

-- Furious Howl
add("Furious Howl",1,"Wolf","9-22","Azeroth",{"Prairie Wolf Alpha","Worg","Coyote Packleader","Mist Howler"})
add("Furious Howl",2,"Wolf","25-46","Azeroth",{"Black Ravager Mastiff","Ghostpaw Alpha","Elder Crag Coyote","Longtooth Howler","Silvermane Howler"})
add("Furious Howl",3,"Wolf","40-49","Azeroth",{"Longtooth Runner","Snarler","Silvermane Wolf","Felpaw Wolf","Death Howl"})
add("Furious Howl",4,"Wolf","56-57","Blackrock Spire",{"Bloodaxe Worg"})

-- Lightning Breath (Rank 1 has no known Classic training source)
add("Lightning Breath",2,"Wind Serpent","15-24","Azeroth",{"Deviate Coiler","Deviate Stinglash","Thunderhawk Hatchling","Thunderhawk Cloudscraper","Deviate Dreadfang","Deviate Venomwing","Greater Thunderhawk"})
add("Lightning Breath",3,"Wind Serpent","25-29","Azeroth",{"Washte Pawne","Cloud Serpent","Venomous Cloud Serpent","Elder Cloud Serpent"})
add("Lightning Breath",4,"Wind Serpent","41-46","Feralas",{"Vale Screecher","Rogue Vale Screecher"})
add("Lightning Breath",5,"Wind Serpent","49-51","Azeroth",{"Hakkari Sapper","Hakkari Frostwing","Arash-ethis","Spawn of Hakkar"})
add("Lightning Breath",6,"Wind Serpent","60","Zul'Gurub",{"Son of Hakkar"})

-- Prowl
add("Prowl",1,"Cat","32-40","Azeroth",{"Mountain Lion","Ridge Stalker","Shadowmaw Panther","Shadow Panther"})
add("Prowl",2,"Cat","40-43","Azeroth",{"Ridge Stalker Patriarch","Elder Shadowmaw Panther"})
add("Prowl",3,"Cat","50-60","Azeroth",{"Jaguero Stalker","Frostsaber Stalker"})

-- Scorpid Poison
add("Scorpid Poison",1,"Scorpid","9-22","Azeroth",{"Venomtail Scorpid","Corrupted Scorpid","Death Flayer","Silithid Creeper","Silithid Swarmer"})
add("Scorpid Poison",2,"Scorpid","30-39","Azeroth",{"Scorpashi Snapper","Scorpid Reaver","Scorpid Terror","Cleft Scorpid","Vile Sting","Scorpashi Venomlash"})
add("Scorpid Poison",3,"Scorpid","40-55","Azeroth",{"Scorpid Hunter","Deadly Cleft Scorpid","Scorpid Tail Lasher","Scorpid Duneburrower","Scorpid Dunestalker","Scorpok Stinger","Deep Stinger","Venomtip Scorpid","Deathlash Scorpid","Stonelash Scorpid"})
add("Scorpid Poison",4,"Scorpid","56-59","Azeroth",{"Krellack","Stonelash Pincer","Firetail Scorpid","Stonelash Flayer"})

-- Screech
add("Screech",1,"Carrion Bird","16-17","Westfall",{"Greater Fleshripper"})
add("Screech",2,"Various","32-40","Azeroth",{"Salt Flats Vulture","Shrike Bat","Dread Ripper"})
add("Screech",3,"Various","48-52","Azeroth",{"Ironbeak Owl","Dark Screecher","Carrion Vulture"})
add("Screech",4,"Various","56-59","Azeroth",{"Monstrous Plaguebat","Winterspring Screecher"})

-- Shell Shield
add("Shell Shield",1,"Turtle","20-32","Azeroth",{"Kresh","Aku'mai Fisher","Ghamoo-ra","Aku'mai Snapjaw","Snapjaw","Cranky Benj"})

-- Thunderstomp
add("Thunderstomp",1,"Gorilla","32-38","Stranglethorn Vale",{"Mistvale Gorilla","Jungle Thunderer"})
add("Thunderstomp",2,"Gorilla","40-50","Azeroth",{"Elder Mistvale Gorilla","Groddoc Thunderer"})
add("Thunderstomp",3,"Gorilla","52-55","Un'Goro Crater",{"Un'Goro Thunderer","U'cha"})

ns.ClassicCreatureAbilitiesByName = sources
ns.ClassicCreatureAbilities = ns.ClassicCreatureAbilities or {}

-- Canonical rank metadata, including trainer-taught skills for the upcoming
-- browser/checklist. Wild-source tooltips use the mappings above.
ns.ClassicAbilities = {}
local function ability(name, ranks)
    ns.ClassicAbilities[name] = { ranks = {} }
    for rank, values in pairs(ranks) do
        ns.ClassicAbilities[name].ranks[rank] = { petLevel=values[1], trainingPoints=values[2], source=values[3] or "wild" }
    end
end
ability("Bite", {[1]={1,1},[2]={8,4},[3]={16,7},[4]={24,10},[5]={32,13},[6]={40,17},[7]={48,21},[8]={56,25}})
ability("Charge", {[1]={1,5},[2]={12,9},[3]={24,13},[4]={36,17},[5]={48,21},[6]={60,25}})
ability("Claw", {[1]={1,1},[2]={8,4},[3]={16,7},[4]={24,10},[5]={32,13},[6]={40,17},[7]={48,21},[8]={56,25}})
ability("Cower", {[1]={5,8},[2]={15,10},[3]={25,12},[4]={35,14},[5]={45,16},[6]={55,18}})
ability("Dash", {[1]={30,15},[2]={40,20},[3]={50,25}})
ability("Dive", {[1]={30,15},[2]={40,20},[3]={50,25}})
ability("Furious Howl", {[1]={10,10},[2]={24,15},[3]={40,20},[4]={56,25}})
ability("Lightning Breath", {[1]={1,1},[2]={12,5},[3]={24,10},[4]={36,15},[5]={48,20},[6]={60,25}})
ability("Prowl", {[1]={30,15},[2]={40,20},[3]={50,25}})
ability("Scorpid Poison", {[1]={8,10},[2]={24,15},[3]={40,20},[4]={56,25}})
ability("Screech", {[1]={8,10},[2]={24,15},[3]={48,20},[4]={56,25}})
ability("Shell Shield", {[1]={20,15}})
ability("Thunderstomp", {[1]={30,15},[2]={40,20},[3]={50,25}})

ability("Growl", {[1]={1,0,"trainer"},[2]={10,0,"trainer"},[3]={20,0,"trainer"},[4]={30,0,"trainer"},[5]={40,0,"trainer"},[6]={50,0,"trainer"},[7]={60,0,"trainer"}})
ability("Great Stamina", {[1]={10,5,"trainer"},[2]={12,10,"trainer"},[3]={18,15,"trainer"},[4]={24,25,"trainer"},[5]={30,50,"trainer"},[6]={36,75,"trainer"},[7]={42,100,"trainer"},[8]={48,125,"trainer"},[9]={54,150,"trainer"},[10]={60,185,"trainer"}})
ability("Natural Armor", {[1]={10,1,"trainer"},[2]={12,5,"trainer"},[3]={18,10,"trainer"},[4]={24,15,"trainer"},[5]={30,25,"trainer"},[6]={36,50,"trainer"},[7]={42,75,"trainer"},[8]={48,100,"trainer"},[9]={54,125,"trainer"},[10]={60,150,"trainer"}})
for _, resistance in ipairs({"Arcane Resistance","Fire Resistance","Frost Resistance","Nature Resistance","Shadow Resistance"}) do
    ability(resistance, {[1]={20,5,"trainer"},[2]={30,15,"trainer"},[3]={40,45,"trainer"},[4]={50,90,"trainer"},[5]={60,105,"trainer"}})
end
