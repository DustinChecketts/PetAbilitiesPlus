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

function ns:GetAbilitiesForCreature(creatureID)
    if not creatureID then
        return nil
    end

    local abilities = {}
    local seen = {}

    local function appendFrom(source)
        local rows = source and source[creatureID]
        if not rows then
            return
        end

        for _, row in ipairs(rows) do
            local key = tostring(row.ability) .. ":" .. tostring(row.rank or "")
            if not seen[key] then
                seen[key] = true
                abilities[#abilities + 1] = row
            end
        end
    end

    appendFrom(ns.ClassicCreatureAbilities)
    appendFrom(ns.ForeverCreatureAbilities)

    if #abilities == 0 then
        return nil
    end

    table.sort(abilities, function(a, b)
        if a.ability == b.ability then
            return (a.rank or 0) < (b.rank or 0)
        end
        return tostring(a.ability) < tostring(b.ability)
    end)

    return abilities
end

function ns:FormatAbility(row)
    if not row then
        return nil
    end

    if row.rank then
        return string.format("%s (Rank %d)", row.ability, row.rank)
    end

    return tostring(row.ability)
end
