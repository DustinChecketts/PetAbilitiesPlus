local ADDON_NAME, ns = ...

-- Deep, read-only probe of the native unit-tooltip payload and the unit fields
-- historically associated with Beast Lore. Never casts, swaps units, or taints
-- Blizzard unit globals.
local function out(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP LORE:|r " .. tostring(msg))
end

local function accessible(v)
    if type(issecretvalue) == "function" and issecretvalue(v) then return nil, "secret" end
    if type(canaccessvalue) == "function" and v ~= nil and not canaccessvalue(v) then return nil, "inaccessible" end
    return v
end

local function safeCall(label, fn, ...)
    if type(fn) ~= "function" then
        out(label .. " = <API unavailable>")
        return nil
    end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok then
        out(label .. " = <error: " .. tostring(a) .. ">")
        return nil
    end
    local vals = {a,b,c,d,e,f,g}
    local parts = {}
    for i = 1, 7 do
        if vals[i] ~= nil then
            local v, why = accessible(vals[i])
            parts[#parts + 1] = v ~= nil and tostring(v) or ("<" .. tostring(why) .. ">")
        end
    end
    out(label .. " = " .. (#parts > 0 and table.concat(parts, " | ") or "<nil>"))
    return a,b,c,d,e,f,g
end

local function enumName(enumTable, value)
    if type(enumTable) ~= "table" or value == nil then return nil end
    for k, v in pairs(enumTable) do
        if v == value then return k end
    end
end

local function valueText(v)
    local a, why = accessible(v)
    if a == nil and why then return "<" .. why .. ">" end
    local t = type(a)
    if t == "string" then return string.format("%q", a) end
    if t == "number" or t == "boolean" then return tostring(a) end
    if a == nil then return "nil" end
    return "<" .. t .. ">"
end

local function dumpTable(label, t)
    if type(t) ~= "table" then out(label .. " = " .. valueText(t)); return end

    local keys = {}
    for k, v in pairs(t) do
        -- Keep the probe useful: primitive payload fields are data; nested
        -- mixins such as ColorMixin are implementation noise.
        if type(v) ~= "function" then keys[#keys + 1] = k end
    end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)

    for _, k in ipairs(keys) do
        local v = t[k]
        local keyLabel = label .. "." .. tostring(k)
        if type(v) == "table" then
            -- Colors are common and safe to summarize numerically without
            -- walking their inherited ColorMixin methods.
            if tostring(k):lower():find("color", 1, true) then
                local r, g, b, a
                local ok = pcall(function()
                    if type(v.GetRGBA) == "function" then r, g, b, a = v:GetRGBA() end
                end)
                if ok and r ~= nil then
                    out(keyLabel .. " = rgba(" .. valueText(r) .. "," .. valueText(g) .. "," .. valueText(b) .. "," .. valueText(a) .. ")")
                else
                    out(keyLabel .. " = <table>")
                end
            elseif tostring(k) == "lines" then
                out(keyLabel .. " = <" .. tostring(#v) .. " lines>")
                for i, line in ipairs(v) do
                    if type(line) == "table" then
                        dumpTable(keyLabel .. "." .. i, line)
                    end
                end
            elseif tostring(k) == "args" or tostring(k) == "arguments" then
                out(keyLabel .. " = <table>")
                dumpTable(keyLabel, v)
            else
                out(keyLabel .. " = <table>")
            end
        else
            local suffix = ""
            if tostring(k) == "type" and Enum and Enum.TooltipDataLineType then
                local n = enumName(Enum.TooltipDataLineType, v)
                if n then suffix = " (" .. n .. ")" end
            elseif tostring(k) == "dataType" and Enum and Enum.TooltipDataType then
                local n = enumName(Enum.TooltipDataType, v)
                if n then suffix = " (" .. n .. ")" end
            end
            out(keyLabel .. " = " .. valueText(v) .. suffix)
        end
    end
end

local function wildNames()
    local t = {}
    for name, meta in pairs(ns.ClassicAbilities or {}) do
        for _, rankMeta in pairs(meta.ranks or {}) do
            if rankMeta.source ~= "trainer" then
                t[name] = true
                if name == "Screech" then t["Demoralizing Screech"] = true end
                break
            end
        end
    end
    for _, name in ipairs({"Swipe", "Trickster's Dance", "Dust Cloud", "Savage Rend"}) do t[name] = true end
    return t
end

local function parseAbility(text, names)
    if type(text) ~= "string" then return nil end
    local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    for name in pairs(names) do
        local escaped = name:gsub("([^%w])", "%%%1")
        local rank = clean:match(escaped .. "%s*%([Rr]ank%s*(%d+)%)") or
                     clean:match(escaped .. "%s+[Rr]ank%s*(%d+)")
        if rank then return name, tonumber(rank) end
    end
end

local function collectAbilities(data)
    local names, abilities, seen = wildNames(), {}, {}
    for _, line in ipairs(type(data) == "table" and type(data.lines) == "table" and data.lines or {}) do
        for _, text in ipairs({accessible(line.leftText or line.text), accessible(line.rightText)}) do
            if type(text) == "string" then
                local ability, rank = parseAbility(text, names)
                if ability and rank then
                    local key = ability .. ":" .. rank
                    if not seen[key] then
                        seen[key] = true
                        abilities[#abilities + 1] = {ability=ability, rank=rank}
                    end
                end
            end
        end
    end
    return abilities
end

local function record(unit, creatureID, data)
    local abilities = collectAbilities(data)
    out("detected teachable ranks = " .. tostring(#abilities))
    for _, row in ipairs(abilities) do out(row.ability .. " (Rank " .. row.rank .. ")") end
    if #abilities == 0 then return end

    PetAbilitiesPlusDB.beastLoreDiscoveries = PetAbilitiesPlusDB.beastLoreDiscoveries or {}
    local name = accessible(UnitName(unit))
    local level = accessible(UnitLevel(unit))
    local family = accessible(UnitCreatureFamily(unit))
    local zone = GetZoneText and accessible(GetZoneText()) or nil
    local subzone = GetSubZoneText and accessible(GetSubZoneText()) or nil
    local parts = {}
    for _, row in ipairs(abilities) do parts[#parts + 1] = row.ability .. ":" .. row.rank end
    table.sort(parts)
    local signature = table.concat(parts, ",")
    local key = tostring(creatureID)
    local old = PetAbilitiesPlusDB.beastLoreDiscoveries[key]
    if not old or old.signature ~= signature then
        PetAbilitiesPlusDB.beastLoreDiscoveries[key] = {
            creatureID=creatureID, name=name, level=level, family=family,
            zone=zone, subzone=subzone, abilities=abilities, signature=signature,
        }
        out("RECORDED unique creature/ability row.")
    else
        out("Already recorded; duplicate skipped.")
    end
end

local function inspect(unit)
    local guid = accessible(UnitGUID(unit))
    local creatureID = ns:GetCreatureIDFromGUID(guid)
    if not creatureID then out("Target is not an accessible creature."); return end

    out("=== NATIVE UNIT BASELINE ===")
    safeCall("UnitGUID", UnitGUID, unit)
    safeCall("UnitName", UnitName, unit)
    safeCall("UnitLevel", UnitLevel, unit)
    safeCall("UnitCreatureType", UnitCreatureType, unit)
    safeCall("UnitCreatureFamily", UnitCreatureFamily, unit)
    safeCall("UnitClassification", UnitClassification, unit)
    safeCall("UnitIsWildBattlePet", UnitIsWildBattlePet, unit)
    safeCall("UnitIsBattlePet", UnitIsBattlePet, unit)
    safeCall("UnitHealth/Max", function(u) return UnitHealth(u), UnitHealthMax(u) end, unit)
    safeCall("UnitArmor", UnitArmor, unit)
    safeCall("UnitDamage", UnitDamage, unit)
    if type(UnitResistance) == "function" then
        for school = 0, 6 do safeCall("UnitResistance[" .. school .. "]", UnitResistance, unit, school) end
    else
        out("UnitResistance = <API unavailable>")
    end

    out("=== BEAST LORE AURA 1462 ===")
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataBySpellName) == "function" then
        safeCall("C_UnitAuras.GetAuraDataBySpellName(Beast Lore)", C_UnitAuras.GetAuraDataBySpellName, unit, "Beast Lore", "HELPFUL")
    else
        out("GetAuraDataBySpellName = <API unavailable>")
    end
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        local found = false
        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if not ok or not aura then break end
            local spellId = accessible(aura.spellId)
            if spellId == 1462 then
                found = true
                dumpTable("beastLoreAura", aura)
                break
            end
        end
        if not found then out("Beast Lore spellID 1462 not found in readable HELPFUL auras.") end
    end

    out("=== C_TooltipInfo.GetUnit FULL PAYLOAD ===")
    if not C_TooltipInfo or type(C_TooltipInfo.GetUnit) ~= "function" then
        out("C_TooltipInfo.GetUnit = <API unavailable>")
        return
    end
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit, false)
    if not ok or type(data) ~= "table" then
        out("GetUnit failed: " .. tostring(data))
        return
    end
    dumpTable("tooltip", data)
    record(unit, creatureID, data)

    out("=== VISIBLE GAMETOOLTIP ===")
    if GameTooltip and GameTooltip.GetTooltipData then
        local visible = GameTooltip:GetTooltipData()
        if type(visible) == "table" then dumpTable("gameTooltip", visible) else out("GameTooltip:GetTooltipData() = <nil>") end
    else
        out("GameTooltip:GetTooltipData = <API unavailable>")
    end
    out("=== END PAP LORE ===")
end

local function dump()
    local db = PetAbilitiesPlusDB.beastLoreDiscoveries or {}
    local ids = {}
    for id in pairs(db) do ids[#ids + 1] = id end
    table.sort(ids, function(a,b) return tonumber(a) < tonumber(b) end)
    out("=== DISCOVERIES: " .. #ids .. " ===")
    for _, id in ipairs(ids) do
        local row, a = db[id], {}
        for _, ability in ipairs(row.abilities or {}) do a[#a + 1] = ability.ability .. " R" .. ability.rank end
        out(table.concat({tostring(row.creatureID), tostring(row.name), "L" .. tostring(row.level),
            tostring(row.family), tostring(row.zone), tostring(row.subzone), table.concat(a, ", ")}, " | "))
    end
end

SLASH_PAPLORE1 = "/paplore"
SlashCmdList.PAPLORE = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$"))
    if msg == "dump" then dump() else inspect("target") end
end
