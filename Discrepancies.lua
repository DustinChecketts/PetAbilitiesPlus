local _, ns = ...
-- Public reporting is always opt-in. No HTTP requests or player identifiers.
-- A positive observation can flag a missing published source; absence of a
-- spell is never sufficient to claim a source was removed.
local function db()
    PetAbilitiesPlusDB = PetAbilitiesPlusDB or {}
    PetAbilitiesPlusDB.discrepancies = PetAbilitiesPlusDB.discrepancies or {}
    return PetAbilitiesPlusDB.discrepancies
end
local function abilityKey(row)
    local name = row.ability == "Screech" and "Demoralizing Screech" or row.ability
    return tostring(name) .. ":" .. tostring(row.rank or "")
end
local function expected(npcId, name)
    local found = {}
    local function ingest(rows)
        for _,row in ipairs(rows or {}) do found[abilityKey(row)] = row end
    end
    ingest(ns.ClassicCreatureAbilities and ns.ClassicCreatureAbilities[npcId])
    ingest(ns.ClassicCreatureAbilitiesByName and ns.ClassicCreatureAbilitiesByName[name])
    ingest(ns.ForeverCreatureAbilities and ns.ForeverCreatureAbilities[npcId])
    ingest(ns.ForeverCreatureAbilitiesByName and ns.ForeverCreatureAbilitiesByName[name])
    ingest(ns.CommunityReportedByName and ns.CommunityReportedByName[name])
    return found
end
function ns:ReviewTameForDiscrepancies(row)
    if type(row) ~= "table" or not row.npcId or type(row.spellbook) ~= "table" then return end
    local baseline = expected(row.npcId, row.name)
    -- Until a licensed Petopia Forever import is present, this is an
    -- internal-baseline comparison, NOT a verified Petopia contradiction.
    for _,spell in ipairs(row.spellbook) do
        if ns:IsTransferableWildRank(spell.ability, spell.rank) and not baseline[abilityKey(spell)] then
            local id = tostring(row.npcId) .. ":" .. abilityKey(spell)
            local entries = db()
            local report = entries[id] or {
                npcId=row.npcId, creature=row.name, ability=spell.ability,
                rank=spell.rank, status="needs-review",
                comparisonSource="PAP bundled baseline (not Petopia-verified)",
                observedAt=row.observedAt, sourceType="local-tame-candidate",
                evidence=row.evidence, clientBuild=select(4,GetBuildInfo()),
            }
            report.observations = (report.observations or 0) + 1
            entries[id] = report
        end
    end
end
function ns:GetDiscrepancyReport()
    local lines = {
        "PetAbilitiesPlus - candidate discrepancy report",
        "No submission is automatic. Review and remove anything private before sharing.",
        "Comparison: PAP bundled baseline, NOT a direct Petopia Forever comparison.",
        "Petopia Forever: https://www.wow-petopia.com/forever/abilities.php",
        ""
    }
    local keys = {}
    for k in pairs(db()) do keys[#keys+1]=k end
    table.sort(keys)
    for _,k in ipairs(keys) do
        local item = db()[k]
        lines[#lines+1] = string.format(
            "NPC %s (%s): %s Rank %s | %s | %s | build %s | %s observation(s)",
            tostring(item.npcId),tostring(item.creature),tostring(item.ability),
            tostring(item.rank),tostring(item.status),tostring(item.evidence),
            tostring(item.clientBuild or "?"),tostring(item.observations or 1))
    end
    if #keys == 0 then lines[#lines+1]="No candidate discrepancies captured." end
    return table.concat(lines,"\n")
end
function ns:ShowDiscrepancyReport()
    if ns.ShowDiscoveries then ns:ShowDiscoveries() end
    print("|cff80c0ffPAP:|r Discrepancies are included in the discovery export. Review before sharing.")
end
