local ADDON_NAME, ns = ...

-- Temporary beta prototype: local-only discovery capture and explicit sharing.
-- No network requests, account identifiers, or automatic publication.
local function db()
    PetAbilitiesPlusDB = PetAbilitiesPlusDB or {}
    PetAbilitiesPlusDB.communityDiscoveries = PetAbilitiesPlusDB.communityDiscoveries or {}
    return PetAbilitiesPlusDB.communityDiscoveries
end

local function creatureId(guid)
    return ns.GetCreatureIDFromGUID and ns:GetCreatureIDFromGUID(guid)
end

local function currentLocation()
    local zone = GetZoneText and GetZoneText() or ""
    local subzone = GetSubZoneText and GetSubZoneText() or ""
    return zone, subzone
end

local function recordPet()
    if not (UnitExists and UnitExists("pet")) then return end
    local guid = UnitGUID and UnitGUID("pet")
    local npc = creatureId(guid)
    if not npc then return end
    local name = UnitName and UnitName("pet")
    local family = UnitCreatureFamily and UnitCreatureFamily("pet")
    local zone, subzone = currentLocation()
    local key = tostring(npc)
    local records = db()
    if not records[key] then
        records[key] = {npcId=npc, name=name or "", family=family or "",
            level=UnitLevel and UnitLevel("pet") or nil,
            zone=zone, subzone=subzone, status="unverified", shared=false,
            observedAt=time and time() or 0}
        print("|cff80c0ffPAP:|r Pet observed: " .. (name or key) ..
            ". Use /pap discoveries to review before sharing.")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UNIT_PET")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" or (event == "UNIT_PET" and unit == "player") then
        -- The pet GUID is not necessarily the original wild creature NPC ID:
        -- never infer that a summoned pet's GUID proves its wild source.
        -- Capture only as an unverified observation for manual review.
        recordPet()
    end
end)

local window
local function createWindow()
    local f = CreateFrame("Frame", "PAPDiscoveryPrototype", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(530, 360)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.TitleText:SetText("PetAbilitiesPlus - Discovery Prototype")
    local instructions = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    instructions:SetPoint("TOPLEFT", 20, -40)
    instructions:SetWidth(490)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Local observations only. Review the text, then copy it to a public submission form when available. No data is sent automatically.")
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -105)
    scroll:SetPoint("BOTTOMRIGHT", -36, 55)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(455)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    f.edit = edit
    local button = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    button:SetSize(135, 24)
    button:SetPoint("BOTTOMRIGHT", -20, 18)
    button:SetText("Select All")
    button:SetScript("OnClick", function() edit:SetFocus() edit:HighlightText() end)
    f:Hide()
    return f
end

function ns:ShowDiscoveries()
    if not window then window = createWindow() end
    local lines = {"PAP discovery observations (unverified)", ""}
    local keys = {}
    for key in pairs(db()) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local row = db()[key]
        lines[#lines+1] = string.format("NPC ID: %s | Name: %s | Family: %s | Level: %s | Zone: %s | Subzone: %s",
            key, row.name or "", row.family or "", tostring(row.level or ""), row.zone or "", row.subzone or "")
    end
    if #keys == 0 then lines[#lines+1] = "No observations recorded yet." end
    window.edit:SetText(table.concat(lines, "\n"))
    window.edit:SetCursorPosition(0)
    window:Show()
end

-- Additive slash command; Checklist.lua's /pap handler forwards here.
