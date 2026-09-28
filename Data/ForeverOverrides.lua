local ADDON_NAME, ns = ...

-- WoW Forever-specific additions and corrections.
--
-- This file is intentionally kept separate from the Classic baseline.
-- Add new Forever creatures, new ranks, or changed ability mappings here.
--
-- Forever renames Classic "Screech" to "Demoralizing Screech". Creature
-- tooltip rows are normalized below so the displayed name matches Forever;
-- Core.lua treats both names as the same learned-knowledge key.

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


-- Normalize the Classic creature mapping to Forever's in-game ability name.
-- Keep the underlying Classic metadata intact for reference/source auditing.
if ns.ClassicCreatureAbilitiesByName then
    for _, rows in pairs(ns.ClassicCreatureAbilitiesByName) do
        for _, row in ipairs(rows) do
            if row.ability == "Screech" then
                row.ability = "Demoralizing Screech"
            end
        end
    end
end
