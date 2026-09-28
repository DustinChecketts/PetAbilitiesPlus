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

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$"))
    if msg == "probe" then
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
        out("Use /papdiag deep for full diagnostics or /papdiag probe while Beast Training is OPEN.")
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
