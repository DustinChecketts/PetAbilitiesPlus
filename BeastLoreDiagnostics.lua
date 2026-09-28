local ADDON_NAME, ns = ...

-- Read-only Beast Lore discovery prototype. It inspects Blizzard's structured
-- tooltip data for the current target and never casts spells or changes units.
local function out(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP LORE:|r " .. tostring(msg))
end

local function accessible(v)
    if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
    if type(canaccessvalue) == "function" and v ~= nil and not canaccessvalue(v) then return nil end
    return v
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
        local rank = clean:match(escaped .. "%s*%(?[Rr]ank%s*(%d+)%)?")
        if rank then return name, tonumber(rank) end
    end
end

local function inspect(unit, verbose)
    if not C_TooltipInfo or type(C_TooltipInfo.GetUnit) ~= "function" then
        if verbose then out("C_TooltipInfo.GetUnit is unavailable.") end
        return
    end
    local guid = accessible(UnitGUID(unit))
    local creatureID = ns:GetCreatureIDFromGUID(guid)
    if not creatureID then
        if verbose then out("Target is not an accessible creature.") end
        return
    end
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if not ok or type(data) ~= "table" then
        if verbose then out("Structured unit tooltip unavailable: " .. tostring(data)) end
        return
    end

    local names, abilities, seen, raw = wildNames(), {}, {}, {}
    for _, line in ipairs(type(data.lines) == "table" and data.lines or {}) do
        for _, text in ipairs({accessible(line.leftText or line.text), accessible(line.rightText)}) do
            if type(text) == "string" then
                raw[#raw + 1] = text
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

    local name = accessible(UnitName(unit))
    local level = accessible(UnitLevel(unit))
    local family = accessible(UnitCreatureFamily(unit))
    local zone = GetZoneText and accessible(GetZoneText()) or nil
    local subzone = GetSubZoneText and accessible(GetSubZoneText()) or nil

    if verbose then
        out("id=" .. tostring(creatureID) .. " name=" .. tostring(name) .. " level=" .. tostring(level) .. " family=" .. tostring(family))
        out("location=" .. tostring(zone) .. ((subzone and subzone ~= "") and (" / " .. subzone) or ""))
        out("structured tooltip lines=" .. tostring(#raw))
        for i, text in ipairs(raw) do out("#" .. i .. " " .. text) end
        out("detected teachable ranks=" .. tostring(#abilities))
        for _, row in ipairs(abilities) do out(row.ability .. " (Rank " .. row.rank .. ")") end
    end

    if #abilities == 0 then return end

    PetAbilitiesPlusDB.beastLoreDiscoveries = PetAbilitiesPlusDB.beastLoreDiscoveries or {}
    local key = tostring(creatureID)
    local parts = {}
    for _, row in ipairs(abilities) do parts[#parts + 1] = row.ability .. ":" .. row.rank end
    table.sort(parts)
    local signature = table.concat(parts, ",")
    local old = PetAbilitiesPlusDB.beastLoreDiscoveries[key]
    if not old or old.signature ~= signature then
        PetAbilitiesPlusDB.beastLoreDiscoveries[key] = {
            creatureID=creatureID, name=name, level=level, family=family,
            zone=zone, subzone=subzone, abilities=abilities, signature=signature,
        }
        if verbose then out("RECORDED unique creature/ability row.") end
    elseif verbose then
        out("Already recorded; duplicate skipped.")
    end
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
    if msg == "dump" then dump() else inspect("target", true) end
end
