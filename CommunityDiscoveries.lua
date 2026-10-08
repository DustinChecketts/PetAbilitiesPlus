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
    end
    if #keys == 0 then lines[#lines+1] = "No candidates captured yet." end
    frame.edit:SetText(table.concat(lines, "\n"))
    frame.edit:SetCursorPosition(0)
    frame:Show()
end

ns.ArmCommunityDiscovery = armTarget
ns.CaptureCommunityDiscovery = capture
ns.ShowDiscoveries = show
