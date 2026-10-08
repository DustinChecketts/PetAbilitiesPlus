local _, ns = ...

-- Optional, temporary Forever discovery recorder. All records remain local.
-- Nothing is submitted automatically, and a pet GUID is never used as proof
-- of the original wild NPC ID.
local function records()
    PetAbilitiesPlusDB = PetAbilitiesPlusDB or {}
    PetAbilitiesPlusDB.communityDiscoveries = PetAbilitiesPlusDB.communityDiscoveries or {}
    return PetAbilitiesPlusDB.communityDiscoveries
end

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if not ok or (issecretvalue and issecretvalue(value)) then return nil end
    return value
end

local function locationSnapshot()
    local location = {}
    -- Map coordinates are normalized 0..1, not absolute world XYZ.
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local mapId = safe(C_Map.GetBestMapForUnit, "player")
        if type(mapId) == "number" then
            location.mapId = mapId
            local pos = safe(C_Map.GetPlayerMapPosition, mapId, "player")
            if pos and type(pos.GetXY) == "function" then
                local ok, x, y = pcall(pos.GetXY, pos)
                if ok and type(x) == "number" and type(y) == "number" then
                    location.mapX, location.mapY = x, y
                end
            end
        end
    end
    -- UnitPosition may be absent or restricted on Forever.
    if type(UnitPosition) == "function" then
        local ok, x, y, z, instanceId = pcall(UnitPosition, "player")
        if ok and type(x) == "number" and type(y) == "number"
            and type(z) == "number" then
            location.worldX, location.worldY, location.worldZ = x, y, z
            if type(instanceId) == "number" then location.instanceId = instanceId end
        end
    end
    return location
end

local function snapshotTarget()
    if not safe(UnitExists, "target") then return nil end
    local guid = safe(UnitGUID, "target")
    local id = guid and ns:GetCreatureIDFromGUID(guid)
    if not id then return nil end
    return {
        npcId=id, name=safe(UnitName, "target"), level=safe(UnitLevel, "target"),
        family=safe(UnitCreatureFamily, "target"), zone=safe(GetZoneText),
        subzone=safe(GetSubZoneText), evidence="wild-target-before-tame",
        status="candidate", observedAt=safe(time) or 0,
        targetLocation=locationSnapshot()
    }
end

local armed
local function armTarget()
    local row = snapshotTarget()
    if not row then
        print("|cff80c0ffPAP:|r Target a wild beast before using /pap discover.")
        return
    end
    armed = row
    print("|cff80c0ffPAP:|r Armed tame observation for " ..
        tostring(row.name or row.npcId) .. " (NPC " .. tostring(row.npcId) ..
        "). Tame this exact target, then use /pap capture.")
end

local function capture()
    if not armed then
        print("|cff80c0ffPAP:|r First target a wild beast and use /pap discover.")
        return
    end
    if not safe(UnitExists, "pet") then
        print("|cff80c0ffPAP:|r No pet present. Observation remains armed.")
        return
    end
    local petFamily = safe(UnitCreatureFamily, "pet")
    if armed.family and petFamily and armed.family ~= petFamily then
        print("|cffff7777PAP:|r Pet family differs from wild target; capture rejected.")
        return
    end
    local row = armed
    row.tameLocation = locationSnapshot()
    row.petFamily = petFamily
    row.petName = safe(UnitName, "pet")
    row.evidence = "manual-target-and-pet-correlation"
    row.status = "candidate-needs-spellbook"
    local key = tostring(row.npcId)
    records()[key] = row
    armed = nil
    print("|cff80c0ffPAP:|r Recorded candidate " .. tostring(row.name or key) ..
        ". Use /pap discoveries to review. No submission was sent.")
end

-- Diagnostic only: query the pet spellbook without opening Blizzard's UI.
-- Report raw values first; do not infer creature sources from action buttons.
local function inspectPetSpellbook()
    local lines = {}
    local function add(value) lines[#lines+1] = value end
    local function value(v)
        if v == nil then return "<nil>" end
        if issecretvalue and issecretvalue(v) then return "<secret>" end
        return tostring(v)
    end
    add("PAP PET SPELLBOOK DIAGNOSTIC")
    add("pet exists: " .. value(safe(UnitExists, "pet")))
    add("pet family: " .. value(safe(UnitCreatureFamily, "pet")))
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    if C_SpellBook and type(C_SpellBook.HasPetSpells) == "function" then
        local ok, count = pcall(C_SpellBook.HasPetSpells)
        add("HasPetSpells: " .. (ok and value(count) or "API error"))
        if ok and type(count) == "number" and count > 0
            and type(C_SpellBook.GetSpellBookItemName) == "function" and bank then
            for slot = 1, math.min(count, 120) do
                local good, name, sub = pcall(C_SpellBook.GetSpellBookItemName, slot, bank)
                if good then
                    add("modern " .. slot .. ": " .. value(name) .. " / " .. value(sub))
                else
                    add("modern " .. slot .. ": API error")
                end
            end
        end
    else
        add("C_SpellBook.HasPetSpells unavailable")
    end
    if type(GetSpellName) == "function" and BOOKTYPE_PET then
        for slot = 1, 80 do
            local ok, name, sub = pcall(GetSpellName, slot, BOOKTYPE_PET)
            if not ok then add("legacy API error at " .. slot) break end
            if not name then break end
            add("legacy " .. slot .. ": " .. value(name) .. " / " .. value(sub))
        end
    else
        add("legacy GetSpellName unavailable")
    end
    local db = PetAbilitiesPlusDB or {}
    db.petSpellbookDiagnostics = {capturedAt=safe(time) or 0, lines=lines}
    print("|cff80c0ffPAP:|r Pet spellbook diagnostic saved. /pap discoveries shows results.")
    return lines
end


-- Read spellbook independently of the Blizzard UI. Only non-secret, readable
-- entries are recorded. A missing/empty result is NOT evidence of no abilities.
local function spellbookSnapshot()
    local found, seen = {}, {}
    local function add(name, sub, spellID)
        if type(name) ~= "string" or name == "" then return end
        if issecretvalue and (issecretvalue(name) or issecretvalue(sub) or issecretvalue(spellID)) then return end
        local rank = type(sub) == "string" and tonumber(sub:match("[Rr]ank%s*(%d+)")) or nil
        local key = name .. ":" .. tostring(rank or "")
        if seen[key] then return end
        seen[key] = true
        found[#found+1] = {ability=name, rank=rank, spellID=type(spellID) == "number" and spellID or nil}
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    if C_SpellBook and bank then
        local count = safe(C_SpellBook.HasPetSpells)
        if type(count) == "number" and count > 0 then
            for slot=1, math.min(count,120) do
                if type(C_SpellBook.GetSpellBookItemName) == "function" then
                    local ok, name, sub = pcall(C_SpellBook.GetSpellBookItemName, slot, bank)
                    if ok then add(name, sub) end
                end
                if type(C_SpellBook.GetSpellBookItemInfo) == "function" then
                    local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, slot, bank)
                    if ok and type(info) == "table" then
                        local name = info.name or (info.spellID and C_Spell and C_Spell.GetSpellName and safe(C_Spell.GetSpellName, info.spellID))
                        add(name, info.subName, info.spellID)
                    end
                end
            end
        end
    end
    if #found == 0 and type(GetSpellName) == "function" and BOOKTYPE_PET then
        for slot=1,80 do
            local ok, name, sub = pcall(GetSpellName, slot, BOOKTYPE_PET)
            if not ok or not name then break end
            add(name, sub)
        end
    end
    return found
end

local function mergeObservation(row)
    local key = tostring(row.npcId)
    local old = records()[key]
    if old then
        old.minLevel = math.min(tonumber(old.minLevel or old.level) or 999, tonumber(row.level) or 999)
        old.maxLevel = math.max(tonumber(old.maxLevel or old.level) or 0, tonumber(row.level) or 0)
        old.locations = old.locations or {}
        local pos = row.targetLocation
        if pos and pos.mapId and pos.mapX and pos.mapY then
            local marker = string.format("%s:%.3f:%.3f",pos.mapId,pos.mapX,pos.mapY)
            local exists = false
            for _, p in ipairs(old.locations) do if p.marker == marker then exists = true end end
            if not exists then old.locations[#old.locations+1] = {marker=marker,mapId=pos.mapId,x=pos.mapX,y=pos.mapY} end
        end
        old.observations = (old.observations or 1)+1
        if #row.spellbook > 0 then
            old.spellbook = old.spellbook or {}
            for _, ability in ipairs(row.spellbook) do
                local exists = false
                for _, prior in ipairs(old.spellbook) do
                    if prior.ability == ability.ability and prior.rank == ability.rank then exists=true end
                end
                if not exists then old.spellbook[#old.spellbook+1] = ability end
            end
        end
        old.status = #old.spellbook > 0 and "candidate-spellbook-captured" or "candidate-needs-spellbook"
        return old
    end
    row.minLevel, row.maxLevel = row.level, row.level
    row.observations = 1
    row.locations = {}
    records()[key] = row
    return row
end

local auto = CreateFrame("Frame")
local pending, lastPetGUID, deadline, elapsed = nil, nil, nil, 0
local function startTame()
    local target = snapshotTarget()
    if not target then return end
    pending = target
    lastPetGUID = safe(UnitGUID, "pet")
    deadline = (GetTime and GetTime() or 0) + 35
    elapsed = 0
    print("|cff80c0ffPAP:|r Observing Tame Beast on " .. tostring(target.name or target.npcId))
end
local function finishIfReady()
    if not pending or not safe(UnitExists,"pet") then return false end
    local guid = safe(UnitGUID,"pet")
    if not guid or guid == lastPetGUID then return false end
    local family = safe(UnitCreatureFamily,"pet")
    if pending.family and family and pending.family ~= family then return false end
    local spells = spellbookSnapshot()
    if #spells == 0 then return false end
    local row = pending
    row.petFamily = family
    row.petName = safe(UnitName,"pet")
    row.tameLocation = locationSnapshot()
    row.spellbook = spells
    row.status = "candidate-spellbook-captured"
    row.evidence = "automatic-tame-pet-spellbook"
    local prior = records()[tostring(row.npcId)]
    local oldCount = prior and #(prior.spellbook or {}) or 0
    local merged = mergeObservation(row)
    pending = nil
    if not prior or #merged.spellbook > oldCount then
        print("|cff80c0ffPAP:|r New pet discovery: " .. tostring(row.name) ..
            ". Review with /pap discoveries (optional sharing).")
    end
    return true
end
auto:RegisterEvent("UNIT_SPELLCAST_START")
auto:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
auto:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
auto:RegisterEvent("UNIT_PET")
auto:RegisterEvent("PET_BAR_UPDATE")
auto:RegisterEvent("SPELLS_CHANGED")
auto:SetScript("OnEvent",function(_,event,unit,castGUID,spellID)
    if (event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_CHANNEL_START"
        or event=="UNIT_SPELLCAST_SUCCEEDED") and unit=="player" then
        -- 1515 is Tame Beast's classic spell ID.
        if spellID == 1515 then startTame() end
    elseif pending and (event=="UNIT_PET" or event=="PET_BAR_UPDATE" or event=="SPELLS_CHANGED") then
        finishIfReady()
    end
end)
auto:SetScript("OnUpdate",function(_,dt)
    if not pending then return end
    elapsed = elapsed + dt
    if elapsed < 0.5 then return end
    elapsed = 0
    if GetTime and GetTime() > deadline then
        print("|cff80c0ffPAP:|r Tame observation expired; no verified new pet spellbook.")
        pending=nil
        return
    end
    finishIfReady()
end)

local frame
local function show()
    if not frame then
        frame = CreateFrame("Frame", "PAPDiscoveryPrototype", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(580, 380)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame.TitleText:SetText("PetAbilitiesPlus - Community Discoveries")
        local note = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", 18, -39)
        note:SetWidth(535)
        note:SetJustifyH("LEFT")
        note:SetText("Candidate observations are not verified ability sources. No data is sent automatically. Select and copy the text to share later.")
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 18, -94)
        scroll:SetPoint("BOTTOMRIGHT", -38, 56)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(510)
        edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scroll:SetScrollChild(edit)
        frame.edit = edit
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(120, 24)
        button:SetPoint("BOTTOMRIGHT", -20, 18)
        button:SetText("Select All")
        button:SetScript("OnClick", function() edit:SetFocus() edit:HighlightText() end)
        frame:Hide()
    end
    local lines = {"PetAbilitiesPlus community candidates", "Client: Forever", ""}
    local keys = {}
    for id in pairs(records()) do keys[#keys+1] = id end
    table.sort(keys)
    for _, id in ipairs(keys) do
        local row = records()[id]
        lines[#lines+1] = string.format("NPC %s | %s | level %s | family %s | %s / %s | %s",
            id, tostring(row.name or ""), tostring(row.level or ""),
            tostring(row.family or ""), tostring(row.zone or ""),
            tostring(row.subzone or ""), tostring(row.status or "candidate"))
        local function addPosition(label, pos)
            if type(pos) ~= "table" then return end
            if pos.mapId then
                lines[#lines+1] = string.format("%s map %s: %.2f, %.2f percent",
                    label, tostring(pos.mapId), (pos.mapX or 0)*100, (pos.mapY or 0)*100)
            end
            if pos.worldX and pos.worldY and pos.worldZ then
                lines[#lines+1] = string.format("%s world XYZ: %.2f, %.2f, %.2f (instance %s)",
                    label, pos.worldX, pos.worldY, pos.worldZ, tostring(pos.instanceId or "?"))
            end
        end
        addPosition("Target", row.targetLocation)
        addPosition("Tame", row.tameLocation)
        for _, spell in ipairs(row.spellbook or {}) do
            lines[#lines+1] = string.format("  [grey lead] %s %s (spell ID %s; tame candidate, not yet reviewed)", tostring(spell.ability), spell.rank and ("Rank "..spell.rank) or "(rank unknown)", tostring(spell.spellID or "?"))
        end
        lines[#lines+1] = "Observations: "..tostring(row.observations or 1)
    end
    if #keys == 0 then lines[#lines+1] = "No candidates captured yet." end
    local diag = PetAbilitiesPlusDB and PetAbilitiesPlusDB.petSpellbookDiagnostics
    if diag and type(diag.lines) == "table" then
        lines[#lines+1] = ""
        for _, line in ipairs(diag.lines) do lines[#lines+1] = line end
    end
    frame.edit:SetText(table.concat(lines, "\n"))
    frame.edit:SetCursorPosition(0)
    frame:Show()
end

ns.ArmCommunityDiscovery = armTarget
ns.CaptureCommunityDiscovery = capture
ns.ShowDiscoveries = show

ns.InspectCommunityPetSpellbook = inspectPetSpellbook
