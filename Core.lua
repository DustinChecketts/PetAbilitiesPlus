local ADDON_NAME, ns = ...

PetAbilitiesPlusDB = PetAbilitiesPlusDB or {}

ns = ns or {}
ns.addonName = ADDON_NAME
ns.db = PetAbilitiesPlusDB

function ns:GetCreatureIDFromGUID(guid)
    if not guid or type(guid) ~= "string" then return nil end
    local unitType, _, _, _, _, creatureID = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(creatureID)
end

local function appendRows(abilities, seen, rows)
    if not rows then return end
    for _, row in ipairs(rows) do
        local key = tostring(row.ability) .. ":" .. tostring(row.rank or "")
        if not seen[key] then
            seen[key] = true
            abilities[#abilities + 1] = row
        end
    end
end

function ns:GetAbilitiesForCreature(creatureID, creatureName)
    local abilities, seen = {}, {}
    if creatureID then
        appendRows(abilities, seen, ns.ClassicCreatureAbilities and ns.ClassicCreatureAbilities[creatureID])
        appendRows(abilities, seen, ns.ForeverCreatureAbilities and ns.ForeverCreatureAbilities[creatureID])
    end
    if creatureName then
        appendRows(abilities, seen, ns.ClassicCreatureAbilitiesByName and ns.ClassicCreatureAbilitiesByName[creatureName])
        appendRows(abilities, seen, ns.ForeverCreatureAbilitiesByName and ns.ForeverCreatureAbilitiesByName[creatureName])
    end
    if #abilities == 0 then return nil end
    table.sort(abilities, function(a, b)
        if a.ability == b.ability then return (a.rank or 0) < (b.rank or 0) end
        return tostring(a.ability) < tostring(b.ability)
    end)
    return abilities
end

function ns:FormatAbility(row)
    if not row then return nil end
    if row.rank then return string.format("%s (Rank %d)", row.ability, row.rank) end
    return tostring(row.ability)
end

-- Returns true/false when the Forever pet spellbook is readable.
-- Forever exposes the modern C_SpellBook Pet bank. Rank is carried in
-- GetSpellBookItemInfo(...).subName (for example "Rank 2").
function ns:IsPetAbilityRankKnown(abilityName, rank)
    if not abilityName then return nil end
    if not (C_SpellBook and C_SpellBook.GetSpellBookItemInfo
        and Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) then
        return nil
    end

    local bank = Enum.SpellBookSpellBank.Pet
    for index = 1, 200 do
        local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, index, bank)
        if not ok then return nil end
        if not info then break end

        local name = info.name
        if name == abilityName then
            if not rank then return true end
            local subName = info.subName
            local learnedRank = subName and tonumber(string.match(subName, "(%d+)"))
            if learnedRank == rank then return true end
        end
    end

    return false
end
