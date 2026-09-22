local ADDON_NAME, ns = ...

PetAbilitiesPlusDB = PetAbilitiesPlusDB or {}

ns = ns or {}
ns.addonName = ADDON_NAME
ns.db = PetAbilitiesPlusDB

function ns:GetCreatureIDFromGUID(guid)
    if not guid or type(guid) ~= "string" then
        return nil
    end

    local unitType, _, _, _, _, creatureID = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then
        return nil
    end

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

    -- Forever may use different creature IDs from the original Classic data.
    -- Names are therefore a deliberate fallback for known, unambiguous beasts.
    if creatureName then
        appendRows(abilities, seen, ns.ClassicCreatureAbilitiesByName and ns.ClassicCreatureAbilitiesByName[creatureName])
        appendRows(abilities, seen, ns.ForeverCreatureAbilitiesByName and ns.ForeverCreatureAbilitiesByName[creatureName])
    end

    if #abilities == 0 then return nil end

    table.sort(abilities, function(a, b)
        if a.ability == b.ability then
            return (a.rank or 0) < (b.rank or 0)
        end
        return tostring(a.ability) < tostring(b.ability)
    end)
    return abilities
end

function ns:FormatAbility(row)
    if not row then return nil end
    if row.rank then
        return string.format("%s (Rank %d)", row.ability, row.rank)
    end
    return tostring(row.ability)
end
