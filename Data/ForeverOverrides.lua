local ADDON_NAME, ns = ...

-- WoW Forever-specific additions and corrections.
--
-- This file is intentionally kept separate from the Classic baseline.
-- Add new Forever creatures, new ranks, or changed ability mappings here.

ns.ForeverCreatureAbilities = {
    -- Example:
    -- [123456] = {
    --     { ability = "Bite", rank = 9, family = "Wolf", level = 60, zone = "Example Zone" },
    -- },
}

ns.ForeverAbilityOverrides = {
    -- Example:
    -- Bite = {
    --     ranks = {
    --         [9] = { petLevel = 60, trainingPoints = 29 },
    --     },
    -- },
}
