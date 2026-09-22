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

-- Beast Training is authoritative for what the hunter has learned.
-- Forever exposes it through the trainer service API. Services whose kind is
-- "used" are displayed by the client as "Already Known".
ns.knownPetAbilities = ns.knownPetAbilities or {}
ns.petAbilityKnowledgeReady = false

local function abilityKey(name, rank)
    return tostring(name or "") .. ":" .. tostring(rank or "")
end

local function parseRank(subName)
    if not subName or subName == "" then return nil end
    return tonumber(string.match(subName, "(%d+)"))
end

function ns:RefreshKnownPetAbilities()
    if not (GetNumTrainerServices and GetTrainerServiceInfo) then return false end

    local ok, count = pcall(GetNumTrainerServices)
    count = ok and tonumber(count) or nil
    if not count or count <= 0 then return false end

    local learned = {}
    local sawPetTraining = false
    for index = 1, count do
        local good, name, kind, _, _, subName = pcall(GetTrainerServiceInfo, index)
        if good and name then
            -- A Beast Training list contains the pet abilities represented in
            -- our canonical data. Do not cache ordinary class-trainer services.
            if ns.ClassicAbilities and ns.ClassicAbilities[name] then
                sawPetTraining = true
                if kind == "used" then
                    learned[abilityKey(name, parseRank(subName))] = true
                end
            end
        end
    end

    if not sawPetTraining then return false end

    ns.knownPetAbilities = learned
    ns.petAbilityKnowledgeReady = true
    return true
end

function ns:IsPetAbilityRankKnown(abilityName, rank)
    if not abilityName or not ns.petAbilityKnowledgeReady then return nil end
    return ns.knownPetAbilities[abilityKey(abilityName, rank)] == true
end

local trainingEvents = CreateFrame("Frame")
for _, event in ipairs({
    "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_SERVICE_INFO_NAME_UPDATE"
}) do
    pcall(trainingEvents.RegisterEvent, trainingEvents, event)
end
trainingEvents:SetScript("OnEvent", function()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() ns:RefreshKnownPetAbilities() end)
    else
        ns:RefreshKnownPetAbilities()
    end
end)
