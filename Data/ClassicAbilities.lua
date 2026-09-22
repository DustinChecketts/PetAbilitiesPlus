local ADDON_NAME, ns = ...

-- Classic-era hunter pet ability data.
--
-- Data is intentionally human-readable. Each creature ID maps to one or more
-- teachable pet abilities. Keep base Classic data here; Forever-only changes
-- belong in Data/ForeverOverrides.lua.
--
-- Initial entries are a deliberately small verification set. The full Petopia
-- dataset will be expanded here after in-client tooltip validation confirms
-- the Forever unit/tooltip path is sound.

ns.ClassicCreatureAbilities = {
    -- Tirisfal Glades
    [1501] = {
        { ability = "Bite", rank = 1, family = "Wolf", level = "2-3", zone = "Tirisfal Glades" }, -- Mindless Zombie? placeholder ID verification required
    },

    -- NOTE:
    -- We will populate the production table from Petopia's Classic ability
    -- listings using verified creature IDs. Do not add entries by creature
    -- name alone because duplicate names can exist across NPC records.
}

-- Ability metadata is separate from creature mappings so a future browser can
-- display rank requirements and acquisition targets without parsing tooltip data.
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
}
