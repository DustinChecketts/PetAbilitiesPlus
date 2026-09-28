local ADDON_NAME, ns = ...

-- Beta diagnostics for investigating Forever's hunter pet-training datastore.
local function out(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg))
end

local function safeCall(label, fn, ...)
    if type(fn) ~= "function" then
        out(label .. " = MISSING")
        return
    end
    local values = { pcall(fn, ...) }
    if not table.remove(values, 1) then
        out(label .. " = ERROR: " .. tostring(values[1]))
        return
    end
    local parts = {}
    for i = 1, #values do parts[i] = tostring(values[i]) end
    out(label .. " = " .. table.concat(parts, " | "))
end

local function dumpTrainer()
    out("--- TRAINER SERVICES ---")
    safeCall("GetNumTrainerServices", GetNumTrainerServices)
    local ok, count = pcall(GetNumTrainerServices or function() return 0 end)
    count = ok and tonumber(count) or 0
    for i = 1, count do
        local good, name, kind, texture, level, subName, category, expanded = pcall(GetTrainerServiceInfo, i)
        if good then
            out(string.format("#%d name=%s kind=%s level=%s sub=%s category=%s expanded=%s",
                i, tostring(name), tostring(kind), tostring(level), tostring(subName),
                tostring(category), tostring(expanded)))
            safeCall("  itemLink", GetTrainerServiceItemLink, i)
            safeCall("  levelReq", GetTrainerServiceLevelReq, i)
            safeCall("  skillReq", GetTrainerServiceSkillReq, i)
            safeCall("  abilityReqCount", GetTrainerServiceNumAbilityReq, i)
        end
    end
end

local function dumpSpellBook()
    out("--- SPELLBOOK ---")
    if not C_SpellBook then out("C_SpellBook = MISSING"); return end
    safeCall("HasPetSpells", C_SpellBook.HasPetSpells)
    safeCall("GetNumSpellBookSkillLines", C_SpellBook.GetNumSpellBookSkillLines)
    local ok, n = pcall(C_SpellBook.GetNumSpellBookSkillLines or function() return 0 end)
    n = ok and tonumber(n) or 0
    for line = 1, n do
        local good, info = pcall(C_SpellBook.GetSpellBookSkillLineInfo, line)
        if good and type(info) == "table" then
            out(string.format("skillLine #%d name=%s offset=%s slots=%s id=%s",
                line, tostring(info.name), tostring(info.itemIndexOffset),
                tostring(info.numSpellBookItems), tostring(info.skillLineID)))
        end
    end
    if Enum and Enum.SpellBookSpellBank then
        out("SpellBank.Player=" .. tostring(Enum.SpellBookSpellBank.Player)
            .. " Pet=" .. tostring(Enum.SpellBookSpellBank.Pet))
    end
end

local function dumpSkills()
    out("--- SKILLS / TRADESKILLS ---")
    safeCall("GetNumSkillLines", GetNumSkillLines)
    local ok, n = pcall(GetNumSkillLines or function() return 0 end)
    n = ok and tonumber(n) or 0
    for i = 1, n do
        local good, name, isHeader, isExpanded, rank, numTempPoints, modifier, maxRank =
            pcall(GetSkillLineInfo, i)
        if good and name then
            out(string.format("skill #%d name=%s header=%s rank=%s max=%s",
                i, tostring(name), tostring(isHeader), tostring(rank), tostring(maxRank)))
        end
    end
    out("C_TradeSkillUI=" .. tostring(C_TradeSkillUI ~= nil))
    safeCall("IsTradeskillTrainer", IsTradeskillTrainer)
end

local function dumpCache()
    out("--- PAP CACHE ---")
    out("knowledgeReady=" .. tostring(ns.petAbilityKnowledgeReady))
    local found = 0
    for abilityName, meta in pairs(ns.ClassicAbilities or {}) do
        for rank, rankMeta in pairs(meta.ranks or {}) do
            if rankMeta.source ~= "trainer" and ns:IsPetAbilityRankKnown(abilityName, rank) then
                found = found + 1
                out(abilityName .. " (Rank " .. rank .. ") = HUNTER KNOWN")
            end
        end
    end
    out("cached hunter-known wild ranks=" .. found)
end


-- Probe whether Forever exposes a broader pet-training catalogue than the
-- current-pet view. These tests are intentionally read-only except for
-- temporarily changing Blizzard's trainer display filters/categories, which
-- are restored before the probe finishes.
local function trainerSignature(index)
    if type(GetTrainerServiceInfo) ~= "function" then return nil end
    local ok, name, kind, texture, level, subName, category, expanded =
        pcall(GetTrainerServiceInfo, index)
    if not ok or not name then return nil end
    return table.concat({
        tostring(name), tostring(kind), tostring(level), tostring(subName),
        tostring(category), tostring(expanded)
    }, " | ")
end

local function collectVisible(label, union)
    local ok, count = pcall(GetNumTrainerServices or function() return 0 end)
    count = ok and tonumber(count) or 0
    local added = 0
    for i = 1, count do
        local sig = trainerSignature(i)
        if sig and not union[sig] then
            union[sig] = true
            added = added + 1
        end
    end
    out(label .. ": count=" .. tostring(count) .. " newUnique=" .. tostring(added))
end

local function runTrainerProbe()
    out("=== TRAINER CATALOG PROBE START ===")
    out("pet=" .. tostring(UnitName("pet")) .. " family=" .. tostring(UnitCreatureFamily("pet")))
    if C_Trainer and C_Trainer.GetTrainerType then
        safeCall("C_Trainer.GetTrainerType", C_Trainer.GetTrainerType)
    end

    if type(GetNumTrainerServices) ~= "function" or type(GetTrainerServiceInfo) ~= "function" then
        out("Trainer service APIs unavailable. Open Beast Training first.")
        out("=== TRAINER CATALOG PROBE END ===")
        return
    end

    local union = {}

    -- Attempt 1: force all three native service-state filters on.
    local savedFilters = {}
    local filterNames = { "available", "unavailable", "used" }
    if type(GetTrainerServiceTypeFilter) == "function" then
        for _, filter in ipairs(filterNames) do
            local ok, value = pcall(GetTrainerServiceTypeFilter, filter)
            if ok then savedFilters[filter] = value end
        end
    end
    if type(SetTrainerServiceTypeFilter) == "function" then
        for _, filter in ipairs(filterNames) do
            pcall(SetTrainerServiceTypeFilter, filter, true)
        end
    end
    collectVisible("A1 all native filters ON", union)

    -- Attempt 2: make each service-state filter exclusive in turn. If the
    -- client has rows hidden behind filter state, the union can exceed A1.
    if type(SetTrainerServiceTypeFilter) == "function" then
        for _, wanted in ipairs(filterNames) do
            for _, filter in ipairs(filterNames) do
                pcall(SetTrainerServiceTypeFilter, filter, filter == wanted)
            end
            collectVisible("A2 exclusive " .. wanted, union)
        end
    else
        out("A2 SetTrainerServiceTypeFilter = MISSING")
    end

    -- Attempt 3: toggle the Forever C_Trainer categorization mode. Blizzard's
    -- Forever UI normally disables categories, but the API still exists.
    local savedCategorize
    if C_Trainer and C_Trainer.GetCategorizeTrainerUI and C_Trainer.SetCategorizeTrainerUI then
        local ok, value = pcall(C_Trainer.GetCategorizeTrainerUI)
        if ok then savedCategorize = value end
        for _, valueToTry in ipairs({ true, false }) do
            pcall(C_Trainer.SetCategorizeTrainerUI, valueToTry)
            if type(SetTrainerServiceTypeFilter) == "function" then
                for _, filter in ipairs(filterNames) do
                    pcall(SetTrainerServiceTypeFilter, filter, true)
                end
            end
            collectVisible("A3 categorize=" .. tostring(valueToTry), union)
        end
    else
        out("A3 C_Trainer categorization API = MISSING")
    end

    -- Attempt 4: scan beyond GetNumTrainerServices(). Some legacy APIs expose
    -- a filtered count but still accept an underlying/raw service index.
    local okCount, visibleCount = pcall(GetNumTrainerServices)
    visibleCount = okCount and tonumber(visibleCount) or 0
    local rawExtra = 0
    for i = visibleCount + 1, math.max(visibleCount + 40, 100) do
        local sig = trainerSignature(i)
        if sig then
            rawExtra = rawExtra + 1
            if not union[sig] then
                union[sig] = true
                out("A4 RAW EXTRA #" .. i .. " = " .. sig)
            end
        end
    end
    out("A4 out-of-range scan extras=" .. tostring(rawExtra))

    -- Attempt 5: ask TooltipInfo for trainer-service data beyond the visible
    -- count. This is a separate client data path from GetTrainerServiceInfo.
    local tooltipFn = C_TooltipInfo and C_TooltipInfo.GetTrainerService
    if type(tooltipFn) == "function" then
        local tooltipExtra = 0
        for i = visibleCount + 1, math.max(visibleCount + 40, 100) do
            local ok, data = pcall(tooltipFn, i)
            if ok and type(data) == "table" and data.lines and #data.lines > 0 then
                tooltipExtra = tooltipExtra + 1
                local first = data.lines[1]
                out("A5 TOOLTIP EXTRA #" .. i .. " = " .. tostring(first and (first.leftText or first.text)))
            end
        end
        out("A5 TooltipInfo out-of-range extras=" .. tostring(tooltipExtra))
    else
        out("A5 C_TooltipInfo.GetTrainerService = MISSING")
    end

    -- Attempt 6: dump skill-line/category metadata for every currently exposed
    -- row. A hidden family discriminator here would give us another lever.
    if type(SetTrainerServiceTypeFilter) == "function" then
        for _, filter in ipairs(filterNames) do
            pcall(SetTrainerServiceTypeFilter, filter, true)
        end
    end
    local okFinal, finalCount = pcall(GetNumTrainerServices)
    finalCount = okFinal and tonumber(finalCount) or 0
    if type(GetTrainerServiceSkillLine) == "function" then
        local skillLines = {}
        for i = 1, finalCount do
            local ok, value = pcall(GetTrainerServiceSkillLine, i)
            if ok and value then skillLines[tostring(value)] = true end
        end
        local names = {}
        for value in pairs(skillLines) do names[#names + 1] = value end
        table.sort(names)
        out("A6 service skill lines = " .. (#names > 0 and table.concat(names, ", ") or "NONE"))
    else
        out("A6 GetTrainerServiceSkillLine = MISSING")
    end

    -- Restore the user's Blizzard trainer settings.
    if type(SetTrainerServiceTypeFilter) == "function" then
        for _, filter in ipairs(filterNames) do
            if savedFilters[filter] ~= nil then
                pcall(SetTrainerServiceTypeFilter, filter, savedFilters[filter])
            end
        end
    end
    if savedCategorize ~= nil and C_Trainer and C_Trainer.SetCategorizeTrainerUI then
        pcall(C_Trainer.SetCategorizeTrainerUI, savedCategorize)
    end

    local total = 0
    for _ in pairs(union) do total = total + 1 end
    out("PROBE UNION unique services=" .. tostring(total))
    out("=== TRAINER CATALOG PROBE END ===")
end


local function scalar(v)
    local t = type(v)
    if t == "string" or t == "number" or t == "boolean" or v == nil then return tostring(v) end
    return "<" .. t .. ">"
end

local function dumpPetInfo(label, info)
    if type(info) ~= "table" then
        out(label .. " = " .. scalar(info))
        return
    end
    local fields = {
        "slotID", "name", "level", "familyName", "specialization", "type",
        "displayID", "petNumber", "creatureID", "specID", "loyaltyLevel",
        "loyaltyName", "happinessLevel", "experience", "experienceNeeded"
    }
    local parts = {}
    for _, key in ipairs(fields) do
        if info[key] ~= nil then parts[#parts + 1] = key .. "=" .. scalar(info[key]) end
    end
    out(label .. " :: " .. table.concat(parts, " | "))
    if type(info.petAbilities) == "table" then
        local ids = {}
        for _, id in ipairs(info.petAbilities) do ids[#ids + 1] = tostring(id) end
        out(label .. " petAbilities=[" .. table.concat(ids, ",") .. "]")
    end
    if type(info.specAbilities) == "table" then
        local ids = {}
        for _, id in ipairs(info.specAbilities) do ids[#ids + 1] = tostring(id) end
        out(label .. " specAbilities=[" .. table.concat(ids, ",") .. "]")
    end
end

local function trainerNames()
    local result = {}
    if type(GetNumTrainerServices) ~= "function" or type(GetTrainerServiceInfo) ~= "function" then return result end
    local ok, count = pcall(GetNumTrainerServices)
    if not ok then return result end
    for i = 1, tonumber(count) or 0 do
        local okInfo, name, kind, _, level, rank = pcall(GetTrainerServiceInfo, i)
        if okInfo and name then result[#result + 1] = tostring(name) .. ":" .. tostring(rank) .. ":" .. tostring(kind) end
    end
    table.sort(result)
    return result
end

local function runPetBackendProbe()
    out("=== PET/TRAINER BACKEND PROBE START ===")
    out("active unit pet=" .. tostring(UnitName("pet")) .. " family=" .. tostring(UnitCreatureFamily("pet")) .. " guid=" .. tostring(UnitGUID("pet")))
    local baseline = trainerNames()
    out("B0 trainer rows=" .. tostring(#baseline))

    -- B1: enumerate the entire C_StableInfo namespace actually exposed by this build.
    if type(C_StableInfo) == "table" then
        local names = {}
        for k, v in pairs(C_StableInfo) do names[#names + 1] = tostring(k) .. "(" .. type(v) .. ")" end
        table.sort(names)
        out("B1 C_StableInfo keys=" .. table.concat(names, ", "))
    else
        out("B1 C_StableInfo = MISSING")
    end

    -- B2: enumerate all active/stabled pet records. Forever's PetInfo structure
    -- can include family, creature ID, pet number, and petAbilities spell IDs.
    if C_StableInfo then
        if type(C_StableInfo.GetActivePetList) == "function" then
            local ok, list = pcall(C_StableInfo.GetActivePetList)
            out("B2 GetActivePetList ok=" .. tostring(ok) .. " type=" .. type(list))
            if ok and type(list) == "table" then
                out("B2 active list count=" .. tostring(#list))
                for i, info in ipairs(list) do dumpPetInfo("B2 ACTIVE#" .. i, info) end
            end
        end
        if type(C_StableInfo.GetStabledPetList) == "function" then
            local ok, list = pcall(C_StableInfo.GetStabledPetList)
            out("B2 GetStabledPetList ok=" .. tostring(ok) .. " type=" .. type(list))
            if ok and type(list) == "table" then
                out("B2 stabled list count=" .. tostring(#list))
                for i, info in ipairs(list) do dumpPetInfo("B2 STABLED#" .. i, info) end
            end
        end
        for _, fn in ipairs({"GetNumActivePets","GetNumStablePets","GetNumStableSlots","IsAtStableMaster"}) do
            if type(C_StableInfo[fn]) == "function" then safeCall("B2 C_StableInfo." .. fn, C_StableInfo[fn]) end
        end
    end

    -- B3: direct slot reads. This may expose records even when the list helpers
    -- are empty away from a stable master.
    if C_StableInfo and type(C_StableInfo.GetStablePetInfo) == "function" then
        for i = 1, 10 do
            local ok, info = pcall(C_StableInfo.GetStablePetInfo, i)
            if ok and info then dumpPetInfo("B3 SLOT#" .. i, info) end
        end
    else
        out("B3 GetStablePetInfo = MISSING")
    end

    -- B4: resolve every petAbilities spell ID returned by StableInfo. This is
    -- read-only and may reveal family ability data that never reaches Trainer.
    local seenSpell = {}
    local function inspectList(list, prefix)
        if type(list) ~= "table" then return end
        for i, info in ipairs(list) do
            if type(info) == "table" and type(info.petAbilities) == "table" then
                for _, spellID in ipairs(info.petAbilities) do
                    if not seenSpell[spellID] then
                        seenSpell[spellID] = true
                        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
                        local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
                        out("B4 " .. prefix .. "#" .. i .. " spellID=" .. tostring(spellID) .. " name=" .. tostring(name) ..
                            " subName=" .. tostring(type(spellInfo)=="table" and spellInfo.subName or nil))
                    end
                end
            end
        end
    end
    if C_StableInfo then
        local okA, active = pcall(C_StableInfo.GetActivePetList or function() return {} end)
        if okA then inspectList(active, "ACTIVE") end
        local okS, stabled = pcall(C_StableInfo.GetStabledPetList or function() return {} end)
        if okS then inspectList(stabled, "STABLED") end
    end

    -- B5: discover trainer-related globals/namespaces present in the running
    -- client. We print names only; no unknown mutating function is invoked.
    local discovered = {}
    for k, v in pairs(_G) do
        if type(k) == "string" then
            local lower = string.lower(k)
            if string.find(lower, "trainer", 1, true) and (type(v) == "function" or type(v) == "table") then
                discovered[#discovered + 1] = k .. "(" .. type(v) .. ")"
            end
        end
    end
    table.sort(discovered)
    out("B5 trainer globals=" .. table.concat(discovered, ", "))

    -- B6: compare the trainer catalogue before/after harmless read-only StableInfo
    -- queries. If merely selecting/querying a stored pet affects backend context,
    -- TRAINER_UPDATE or a changed catalogue would expose it.
    local after = trainerNames()
    local changed = (#baseline ~= #after)
    if not changed then
        for i = 1, #baseline do if baseline[i] ~= after[i] then changed = true break end end
    end
    out("B6 trainer rows after stable reads=" .. tostring(#after) .. " changed=" .. tostring(changed))

    out("=== PET/TRAINER BACKEND PROBE END ===")
end


-- Native stable-slot probe. Unlike the retired spoof probe, this never replaces
-- Blizzard globals. It only attempts Blizzard's own stable-slot operation and
-- only while the game reports that the player is at a Stable Master.
local stableProbe = {
    active = false,
    phase = nil,
    originalSlot1PetNumber = nil,
    candidateSlot = nil,
    candidatePetNumber = nil,
    baseline = nil,
    swapped = nil,
    startedAt = nil,
}

local function sameTrainerSet(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

local function reportTrainerDiff(label, before, after)
    out(label .. " rows=" .. tostring(#after) .. " changed=" .. tostring(not sameTrainerSet(before, after)))
    local beforeSet, afterSet = {}, {}
    for _, v in ipairs(before) do beforeSet[v] = true end
    for _, v in ipairs(after) do afterSet[v] = true end
    for _, v in ipairs(after) do if not beforeSet[v] then out(label .. " + " .. v) end end
    for _, v in ipairs(before) do if not afterSet[v] then out(label .. " - " .. v) end end
end

local function petAtSlot(slot)
    if not C_StableInfo or type(C_StableInfo.GetStablePetInfo) ~= "function" then return nil end
    local ok, info = pcall(C_StableInfo.GetStablePetInfo, slot)
    return ok and info or nil
end

local function finishStableProbe(reason)
    stableProbe.active = false
    stableProbe.phase = nil
    out("D9 " .. tostring(reason))
    out("=== NATIVE STABLE/TRAINER PROBE END ===")
end

local function runNativeStableProbe()
    out("=== NATIVE STABLE/TRAINER PROBE START ===")

    if not C_StableInfo or type(C_StableInfo.SetPetSlot) ~= "function" then
        out("D0 C_StableInfo.SetPetSlot unavailable")
        finishStableProbe("aborted")
        return
    end
    if type(C_StableInfo.IsAtStableMaster) ~= "function" then
        out("D0 IsAtStableMaster unavailable")
        finishStableProbe("aborted")
        return
    end

    local okAt, atStable = pcall(C_StableInfo.IsAtStableMaster)
    out("D0 IsAtStableMaster=" .. tostring(okAt and atStable))
    if not okAt or not atStable then
        out("D0 SAFETY STOP: talk to a Stable Master and keep the Stable window open.")
        finishStableProbe("no mutation attempted")
        return
    end

    local slot1 = petAtSlot(1)
    local stabled = C_StableInfo.GetStabledPetList and C_StableInfo.GetStabledPetList() or {}
    local candidate = type(stabled) == "table" and stabled[1] or nil
    if type(slot1) ~= "table" or type(candidate) ~= "table" or not candidate.slotID then
        out("D0 SAFETY STOP: need one current pet and at least one stabled pet.")
        finishStableProbe("no mutation attempted")
        return
    end

    stableProbe.originalSlot1PetNumber = slot1.petNumber
    stableProbe.candidateSlot = candidate.slotID
    stableProbe.candidatePetNumber = candidate.petNumber
    stableProbe.baseline = trainerNames()
    stableProbe.startedAt = GetTime and GetTime() or 0

    out("D1 current slot1=" .. tostring(slot1.name) .. " family=" .. tostring(slot1.familyName) ..
        " petNumber=" .. tostring(slot1.petNumber))
    out("D1 candidate slot=" .. tostring(candidate.slotID) .. " name=" .. tostring(candidate.name) ..
        " family=" .. tostring(candidate.familyName) .. " petNumber=" .. tostring(candidate.petNumber))
    out("D1 trainer baseline rows=" .. tostring(#stableProbe.baseline))

    -- This is Blizzard's native stable swap operation. The diagnostic proceeds
    -- only at a Stable Master, where Blizzard's own Stable UI uses this API.
    stableProbe.active = true
    stableProbe.phase = "swap"
    local ok, err = pcall(C_StableInfo.SetPetSlot, candidate.slotID, 1)
    out("D2 SetPetSlot(" .. tostring(candidate.slotID) .. ",1) ok=" .. tostring(ok) ..
        (ok and "" or " err=" .. tostring(err)))
    if not ok then finishStableProbe("swap call failed") end
end

local stableProbeFrame = CreateFrame("Frame")
for _, event in ipairs({
    "PET_STABLE_UPDATE",
    "UNIT_PET",
    "PET_UI_UPDATE",
    "PET_BAR_UPDATE",
    "SPELLS_CHANGED",
    "TRAINER_UPDATE",
    "TRAINER_SERVICE_INFO_NAME_UPDATE",
}) do
    pcall(stableProbeFrame.RegisterEvent, stableProbeFrame, event)
end

stableProbeFrame:SetScript("OnEvent", function(_, event, unit)
    if not stableProbe.active then return end
    if event == "UNIT_PET" and unit and unit ~= "player" then return end
    out("D EVENT " .. event .. (unit and (" unit=" .. tostring(unit)) or ""))

    local slot1 = petAtSlot(1)
    if stableProbe.phase == "swap" and type(slot1) == "table"
        and slot1.petNumber == stableProbe.candidatePetNumber then
        stableProbe.swapped = trainerNames()
        out("D3 native swap observed: slot1=" .. tostring(slot1.name) ..
            " family=" .. tostring(slot1.familyName))
        reportTrainerDiff("D4 swapped trainer", stableProbe.baseline, stableProbe.swapped)

        -- Immediately restore the original pet through the same native operation.
        stableProbe.phase = "restore"
        local restoreSlot
        local list = C_StableInfo.GetStabledPetList and C_StableInfo.GetStabledPetList() or {}
        if type(list) == "table" then
            for _, info in ipairs(list) do
                if type(info) == "table" and info.petNumber == stableProbe.originalSlot1PetNumber then
                    restoreSlot = info.slotID
                    break
                end
            end
        end
        if not restoreSlot then
            out("D5 RESTORE STOP: original pet not found in stabled list. Restore manually in Stable UI.")
            finishStableProbe("manual restore required")
            return
        end
        local ok, err = pcall(C_StableInfo.SetPetSlot, restoreSlot, 1)
        out("D5 restore SetPetSlot(" .. tostring(restoreSlot) .. ",1) ok=" .. tostring(ok) ..
            (ok and "" or " err=" .. tostring(err)))
        if not ok then finishStableProbe("restore call failed; restore manually") end
        return
    end

    if stableProbe.phase == "restore" and type(slot1) == "table"
        and slot1.petNumber == stableProbe.originalSlot1PetNumber then
        local restored = trainerNames()
        out("D6 original pet restored: slot1=" .. tostring(slot1.name) ..
            " family=" .. tostring(slot1.familyName))
        reportTrainerDiff("D7 restored trainer vs baseline", stableProbe.baseline, restored)
        finishStableProbe("completed")
    end
end)

stableProbeFrame:SetScript("OnUpdate", function()
    if not stableProbe.active or not GetTime then return end
    if GetTime() - (stableProbe.startedAt or 0) < 5 then return end
    local slot1 = petAtSlot(1)
    out("D8 TIMEOUT phase=" .. tostring(stableProbe.phase) ..
        " slot1=" .. tostring(slot1 and slot1.name) ..
        " petNumber=" .. tostring(slot1 and slot1.petNumber))
    finishStableProbe("timed out; verify pets in Stable UI")
end)


SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$"))
    if msg == "stableprobe" then
        runNativeStableProbe()
    elseif msg == "petprobe" then
        runPetBackendProbe()
    elseif msg == "probe" then
        runTrainerProbe()
    elseif msg == "deep" then
        out("=== DEEP DIAGNOSTIC START ===")
        out("pet=" .. tostring(UnitName("pet")) .. " family=" .. tostring(UnitCreatureFamily("pet")))
        dumpTrainer()
        dumpSpellBook()
        dumpSkills()
        dumpCache()
        out("=== DEEP DIAGNOSTIC END ===")
    else
        dumpCache()
        out("Use /papdiag deep, /papdiag probe, /papdiag petprobe, or /papdiag stableprobe.")
    end
end

-- Capture likely learning notifications/events without polling. The exact
-- Forever event is part of what this diagnostic is intended to discover.
local logger = CreateFrame("Frame")
for _, event in ipairs({
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_SKILL",
    "CHAT_MSG_COMBAT_MISC_INFO",
    "LEARNED_SPELL_IN_TAB",
    "SPELLS_CHANGED",
    "PET_BAR_UPDATE",
    "PET_UI_UPDATE",
    "TRAINER_UPDATE",
    "TRAINER_SERVICE_INFO_NAME_UPDATE",
}) do
    pcall(logger.RegisterEvent, logger, event)
end

logger:SetScript("OnEvent", function(_, event, ...)
    if event == "SPELLS_CHANGED" or event == "PET_BAR_UPDATE" or event == "PET_UI_UPDATE"
        or event == "TRAINER_UPDATE" or event == "TRAINER_SERVICE_INFO_NAME_UPDATE" then
        out("EVENT " .. event)
        return
    end
    local args = { ... }
    local parts = {}
    for i = 1, math.min(#args, 6) do parts[i] = tostring(args[i]) end
    out("EVENT " .. event .. " :: " .. table.concat(parts, " | "))
end)
