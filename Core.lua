local ADDON_NAME, ns = ...

ns = ns or {}
ns.addonName = ADDON_NAME

-- SavedVariables are populated by the client after addon files begin loading.
-- Do not capture a file-load-time placeholder table: on /reload that can leave
-- ns.db pointing at a different table than the one Blizzard restores.
local function getDB()
    if type(PetAbilitiesPlusDB) ~= "table" then PetAbilitiesPlusDB = {} end
    ns.db = PetAbilitiesPlusDB
    return PetAbilitiesPlusDB
end

-- Hunter pet-training knowledge is character-specific. The SavedVariables
-- file is account-wide, so keep one cache per character instead of allowing
-- one hunter's learned abilities to affect another hunter.
local function getCharacterKey()
    -- Character GUID is the durable identity we need here. Hardcore characters
    -- can be deleted and recreated with the same name/realm; a new character
    -- must never inherit the dead character's pet-training ledger.
    local guid = UnitGUID and UnitGUID("player")
    if guid and guid ~= "" then return guid end
    return nil
end

local function getCharacterCache(create)
    local key = getCharacterKey()
    if not key then return nil end
    if create then
        local db = getDB()
        db.characters = db.characters or {}
        db.characters[key] = db.characters[key] or {}
    end
    local db = getDB()
    return db.characters and db.characters[key] or nil
end

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

-- Beast Training is authoritative for what the HUNTER has learned.
--
-- Important Forever distinction:
--   * presence in Beast Training = hunter knows/can teach that exact rank
--   * service kind "used"       = current pet already has that rank
--   * service kind "available"  = current pet can be taught it now
--   * service kind "unavailable"= current pet cannot be taught it now
--
-- Therefore the tooltip must use PRESENCE in Beast Training, not service kind.
ns.knownPetAbilities = {}
ns.petAbilityKnowledgeReady = false

-- Restore is intentionally deferred until PLAYER_LOGIN, after SavedVariables
-- and the player GUID are guaranteed to be available. Restoring during file
-- execution can bind the runtime cache to an empty pre-load table on /reload.

local FOREVER_ABILITY_ALIASES = {
    ["Screech"] = "Demoralizing Screech",
    ["Demoralizing Screech"] = "Demoralizing Screech",
}

local function canonicalAbilityName(name)
    return FOREVER_ABILITY_ALIASES[name] or name
end

local function abilityKey(name, rank)
    return tostring(canonicalAbilityName(name) or "") .. ":" .. tostring(rank or "")
end

local function parseRank(subName)
    if not subName or subName == "" then return nil end
    return tonumber(string.match(subName, "(%d+)"))
end

local function getAbilityMeta(name)
    if ns.GetAbilityCatalogEntry then
        return ns:GetAbilityCatalogEntry(canonicalAbilityName(name))
    end
    local lookupName = name == "Demoralizing Screech" and "Screech" or name
    return ns.ClassicAbilities and ns.ClassicAbilities[lookupName]
end

local function isWildLearnedAbility(name)
    local meta = getAbilityMeta(name)
    if not meta or not meta.ranks then return false end
    for rank, rankMeta in pairs(meta.ranks) do
        if rankMeta.source ~= "trainer" then return true end
    end
    return false
end

local function persistKnownAbility(name, rank, source)
    rank = tonumber(rank)
    if not name or not rank or not isWildLearnedAbility(name) then return false end
    local key = abilityKey(name, rank)
    if ns.knownPetAbilities[key] then return false end
    ns.knownPetAbilities[key] = true
    ns.petAbilityKnowledgeReady = true
    local cache = getCharacterCache(true)
    if cache then
        cache.knownPetAbilities = ns.knownPetAbilities
        cache.knownPetAbilitySources = cache.knownPetAbilitySources or {}
        cache.knownPetAbilitySources[key] = source or "observed"
    end
    return true
end

local function knownRanksForAbility(name)
    local ranks = {}
    local meta = getAbilityMeta(name)
    if not meta or not meta.ranks then return ranks end
    for rank in pairs(meta.ranks) do
        if ns:IsPetAbilityRankKnown(name, rank) then ranks[tonumber(rank)] = true end
    end
    return ranks
end

function ns:RefreshKnownPetAbilities()
    if not (GetNumTrainerServices and GetTrainerServiceInfo) then return false end

    local ok, count = pcall(GetNumTrainerServices)
    count = ok and tonumber(count) or nil
    if not count or count <= 0 then return false end

    -- Trainer services are pet-dependent in Forever: an ability can disappear
    -- from the list when the current pet cannot use it. Presence is positive
    -- evidence that the hunter knows a rank; absence is NOT evidence that the
    -- hunter forgot it. Merge discoveries into the existing cache instead of
    -- replacing it.
    local learned = ns.knownPetAbilities or {}
    local sawPetTraining = false
    for index = 1, count do
        local good, name, _, _, _, subName = pcall(GetTrainerServiceInfo, index)
        local abilityMeta = good and name and getAbilityMeta(name) or nil
        if good and name and abilityMeta then
            sawPetTraining = true

            -- Wild-taught ranks only appear in Beast Training after the hunter
            -- has learned them. The service state describes the CURRENT PET,
            -- so it is deliberately ignored here.
            if isWildLearnedAbility(name) then
                local rank = parseRank(subName)
                if rank then
                    local key = abilityKey(name, rank)
                    learned[key] = true
                    local cache = getCharacterCache(true)
                    if cache then
                        cache.knownPetAbilitySources = cache.knownPetAbilitySources or {}
                        cache.knownPetAbilitySources[key] = cache.knownPetAbilitySources[key] or "beast-training"
                    end
                end
            end
        end
    end

    if not sawPetTraining then return false end
    ns.knownPetAbilities = learned
    ns.petAbilityKnowledgeReady = true

    -- Persist the accumulated knowledge. Never remove a previously confirmed
    -- rank merely because a later current-pet trainer view omits it.
    local cache = getCharacterCache(true)
    if cache then
        cache.knownPetAbilities = learned
    end
    return true
end

function ns:IsPetAbilityRankKnown(abilityName, rank)
    if not abilityName then return false end
    return ns.knownPetAbilities[abilityKey(abilityName, rank)] == true
end

local trainingEvents = CreateFrame("Frame")
local trainerSyncActive = false

local function snapshotTrainerKnowledge()
    if not trainerSyncActive then return end
    ns:RefreshKnownPetAbilities()
end

for _, event in ipairs({
    "TRAINER_SHOW",
    "TRAINER_UPDATE",
    "TRAINER_SERVICE_INFO_NAME_UPDATE",
    "TRAINER_CLOSED",
}) do
    pcall(trainingEvents.RegisterEvent, trainingEvents, event)
end

trainingEvents:SetScript("OnEvent", function(_, event)
    if event == "TRAINER_SHOW" then
        -- Forever may fire TRAINER_SHOW before all service rows are populated.
        -- Enter a short-lived sync state and let the trainer's own data events
        -- provide authoritative snapshots as the window finishes populating.
        trainerSyncActive = true
        snapshotTrainerKnowledge()
    elseif event == "TRAINER_UPDATE" or event == "TRAINER_SERVICE_INFO_NAME_UPDATE" then
        snapshotTrainerKnowledge()
    elseif event == "TRAINER_CLOSED" then
        -- Take one final snapshot while the trainer data is still available,
        -- then stop reacting until Beast Training is opened again.
        snapshotTrainerKnowledge()
        trainerSyncActive = false
    end
end)

-- UnitName/GetRealmName are normally ready during file load, but restore again
-- at PLAYER_LOGIN for clients that initialize player identity later.
local loginEvents = CreateFrame("Frame")
loginEvents:RegisterEvent("PLAYER_LOGIN")
loginEvents:RegisterEvent("CHAT_MSG_SYSTEM")
loginEvents:SetScript("OnEvent", function(self, event, message)
    if event == "PLAYER_LOGIN" then
        local cache = getCharacterCache(false)
        if cache and type(cache.knownPetAbilities) == "table" then
            ns.knownPetAbilities = cache.knownPetAbilities
            ns.petAbilityKnowledgeReady = true
        else
            ns.knownPetAbilities = {}
            ns.petAbilityKnowledgeReady = false
        end
        return
    end

    -- Forever's hunter-learning message is rankless, e.g.
    -- "You have learned a new spell: [Claw]."  Never infer a lower rank from a
    -- higher known rank. First snapshot the authoritative Beast Training data.
    -- If that catalogue is unavailable (normal while learning in the field),
    -- resolve the exact rank only when there is exactly one possible new rank
    -- for the named ability on the current pet's spellbook. Otherwise retain
    -- the event as unresolved until a later Beast Training snapshot confirms it.
    if type(message) == "string"
        and (message:find("You have learned a new spell:", 1, true)
          or message:find("You have learned a new ability:", 1, true)) then
        local learnedName = message:match("%[([^%]]+)%]")
        if learnedName then learnedName = canonicalAbilityName(learnedName) end

        local refreshed = ns:RefreshKnownPetAbilities()
        if learnedName and not refreshed then
            local cache = getCharacterCache(true)
            if cache then
                cache.pendingLearnedAbilities = cache.pendingLearnedAbilities or {}
                cache.pendingLearnedAbilities[learnedName] = true
            end
        end

        if C_Timer and C_Timer.After then
            C_Timer.After(0.25, function()
                local ok = ns:RefreshKnownPetAbilities()
                if ok and learnedName then
                    local cache = getCharacterCache(true)
                    if cache and cache.pendingLearnedAbilities then
                        cache.pendingLearnedAbilities[learnedName] = nil
                    end
                end
            end)
        end
    end
end)
