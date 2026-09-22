local ADDON_NAME, ns = ...

-- Classic-era hunter pet ability data.
--
-- Milestone 1 deliberately prioritizes the Night Elf leveling route so the
-- Forever tooltip integration can be tested quickly. Creature IDs are used as
-- the lookup key; names are retained as readable annotations.
--
-- Forever-only additions/corrections belong in ForeverOverrides.lua.

local function pet(name, ability, rank, family, level, zone)
    return {
        name = name,
        ability = ability,
        rank = rank,
        family = family,
        level = level,
        zone = zone,
    }
end

ns.ClassicCreatureAbilities = {
    -- Teldrassil
    [1994] = { pet("Githyiss the Vile", "Bite", 1, "Spider", 5, "Teldrassil") },
    [1995] = { pet("Strigid Owl", "Claw", 1, "Owl", "5-6", "Teldrassil") },
    [1997] = { pet("Strigid Hunter", "Claw", 2, "Owl", "8-9", "Teldrassil") },
    [1999] = { pet("Webwood Venomfang", "Bite", 1, "Spider", "7-8", "Teldrassil") },
    [2000] = { pet("Webwood Silkspinner", "Bite", 2, "Spider", "8-9", "Teldrassil") },
    [2001] = { pet("Giant Webwood Spider", "Bite", 2, "Spider", "10-11", "Teldrassil") },
    [2042] = { pet("Nightsaber", "Cower", 1, "Cat", "5-6", "Teldrassil") },

    -- Darkshore / Auberdine
    [2070] = { pet("Moonstalker Runt", "Cower", 1, "Cat", "10-11", "Darkshore") },
    [2163] = { pet("Thistle Bear", "Claw", 2, "Bear", "11-12", "Darkshore") },
    [2232] = { pet("Tide Crawler", "Claw", 2, "Crab", "12-14", "Darkshore") },
    [2321] = { pet("Foreststrider Fledgling", "Cower", 1, "Tallstrider", "11-13", "Darkshore") },
    [2323] = { pet("Giant Foreststrider", "Cower", 2, "Tallstrider", "17-19", "Darkshore") },
    [2237] = { pet("Moonstalker Sire", "Cower", 2, "Cat", "17-18", "Darkshore") },
    [6788] = { pet("Den Mother", "Claw", 3, "Bear", "18-19", "Darkshore") },
    [3619] = { pet("Ghost Saber", "Claw", 3, "Cat", "19-20", "Darkshore") },

    -- Wetlands
    [1112] = { pet("Leech Widow", "Bite", 4, "Spider", 24, "Wetlands") },
    [2089] = { pet("Giant Wetlands Crocolisk", "Bite", 4, "Crocolisk", "25-26", "Wetlands") },
}

-- Metadata is independent from creature mappings so the future browser/checklist
-- can use the same canonical rank information.
ns.ClassicAbilities = {
    Bite = {
        ranks = {
            [1] = { petLevel = 1, trainingPoints = 1 },
            [2] = { petLevel = 8, trainingPoints = 4 },
            [3] = { petLevel = 16, trainingPoints = 7 },
            [4] = { petLevel = 24, trainingPoints = 10 },
            [5] = { petLevel = 32, trainingPoints = 13 },
            [6] = { petLevel = 40, trainingPoints = 17 },
            [7] = { petLevel = 48, trainingPoints = 21 },
            [8] = { petLevel = 56, trainingPoints = 25 },
        },
    },
    Claw = {
        ranks = {
            [1] = { petLevel = 1, trainingPoints = 1 },
            [2] = { petLevel = 8, trainingPoints = 4 },
            [3] = { petLevel = 16, trainingPoints = 7 },
            [4] = { petLevel = 24, trainingPoints = 10 },
            [5] = { petLevel = 32, trainingPoints = 13 },
            [6] = { petLevel = 40, trainingPoints = 17 },
            [7] = { petLevel = 48, trainingPoints = 21 },
            [8] = { petLevel = 56, trainingPoints = 25 },
        },
    },
    Cower = {
        ranks = {
            [1] = { petLevel = 5, trainingPoints = 8 },
            [2] = { petLevel = 15, trainingPoints = 10 },
            [3] = { petLevel = 25, trainingPoints = 12 },
            [4] = { petLevel = 35, trainingPoints = 14 },
            [5] = { petLevel = 45, trainingPoints = 16 },
            [6] = { petLevel = 55, trainingPoints = 18 },
        },
    },
}
