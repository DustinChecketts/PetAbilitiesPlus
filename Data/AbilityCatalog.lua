local ADDON_NAME, ns = ...

-- Canonical, player-facing pet-training catalog.
--
-- Creature source mappings remain in ClassicAbilities/ForeverOverrides.
-- This layer describes WHAT a Hunter can learn and is intentionally independent
-- of any active pet. PetAbilitiesPlus' checklist and future ForeverPets browser
-- can consume the same model.
--
-- "wild" ranks are learned from tamed beasts and participate in the Hunter
-- knowledge ledger. "trainer" ranks are taught directly and are retained as
-- catalog metadata, not as missing wild discoveries.

local function copyTable(source)
    local result = {}
    if source then
        for key, value in pairs(source) do
            if type(value) == "table" then
                result[key] = copyTable(value)
            else
                result[key] = value
            end
        end
    end
    return result
end

ns.AbilityCatalog = {}

for name, meta in pairs(ns.ClassicAbilities or {}) do
    local displayName = name == "Screech" and "Demoralizing Screech" or name
    ns.AbilityCatalog[displayName] = copyTable(meta)
    ns.AbilityCatalog[displayName].name = displayName
end

-- Family eligibility is deliberately separate from creature source mappings.
-- "Various" source rows are not sufficient to infer a complete family list,
-- so families are populated only when the dataset explicitly knows them.
local explicitFamilies = {
    ["Charge"] = { "Boar" },
    ["Furious Howl"] = { "Wolf" },
    ["Lightning Breath"] = { "Wind Serpent" },
    ["Prowl"] = { "Cat" },
    ["Scorpid Poison"] = { "Scorpid" },
    ["Shell Shield"] = { "Turtle" },
    ["Thunderstomp"] = { "Gorilla" },
}

for name, families in pairs(explicitFamilies) do
    local entry = ns.AbilityCatalog[name]
    if entry then entry.families = families end
end

-- Forever data may add/replace ranks, families, names, or classification
-- without forcing the UI/ledger to understand where the data originated.
for name, override in pairs(ns.ForeverAbilityOverrides or {}) do
    local entry = ns.AbilityCatalog[name] or { name = name, ranks = {} }
    if override.ranks then
        entry.ranks = entry.ranks or {}
        for rank, rankMeta in pairs(override.ranks) do
            entry.ranks[rank] = copyTable(rankMeta)
        end
    end
    if override.families then entry.families = copyTable(override.families) end
    if override.kind then entry.kind = override.kind end
    if override.description then entry.description = override.description end
    if override.icon then entry.icon = override.icon end
    if override.spellID then entry.spellID = override.spellID end
    if override.displayName then entry.name = override.displayName end
    ns.AbilityCatalog[name] = entry
end

function ns:GetAbilityCatalogEntry(name)
    if not name then return nil end
    if name == "Screech" then name = "Demoralizing Screech" end
    return ns.AbilityCatalog[name]
end

function ns:GetAbilityCatalog()
    return ns.AbilityCatalog
end

function ns:GetAbilityFamilies(name)
    local entry = ns:GetAbilityCatalogEntry(name)
    return entry and entry.families or nil
end

function ns:IsWildTrainableRank(name, rank)
    local entry = ns:GetAbilityCatalogEntry(name)
    local meta = entry and entry.ranks and entry.ranks[tonumber(rank)]
    return meta ~= nil and meta.source ~= "trainer"
end
