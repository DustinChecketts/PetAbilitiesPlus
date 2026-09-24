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

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$"))
    if msg == "deep" then
        out("=== DEEP DIAGNOSTIC START ===")
        out("pet=" .. tostring(UnitName("pet")) .. " family=" .. tostring(UnitCreatureFamily("pet")))
        dumpTrainer()
        dumpSpellBook()
        dumpSkills()
        dumpCache()
        out("=== DEEP DIAGNOSTIC END ===")
    else
        dumpCache()
        out("Use /papdiag deep while Beast Training is OPEN for full diagnostics.")
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
