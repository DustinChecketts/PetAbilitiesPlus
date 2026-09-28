local ADDON_NAME, ns = ...

-- Read-only Pet Abilities checklist. This is intentionally built from the
-- complete catalog rather than the active pet, so it can become the Hunter's
-- persistent training checklist and later feed ForeverPets.

local frame
local rows = {}

local function sortedAbilityNames()
    local names = {}
    for name, entry in pairs(ns:GetAbilityCatalog() or {}) do
        local hasWild = false
        for _, rankMeta in pairs(entry.ranks or {}) do
            if rankMeta.source ~= "trainer" then hasWild = true break end
        end
        if hasWild then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

local function familyText(entry)
    if not entry.families or #entry.families == 0 then
        return "Eligible families: data pending"
    end
    return "Eligible families: " .. table.concat(entry.families, ", ")
end

local function addText(parent, text, x, y, template)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    rows[#rows + 1] = fs
    return fs
end

local function rebuild()
    if not frame then return end
    for _, object in ipairs(rows) do object:Hide() end
    wipe(rows)

    local y = -12
    for _, name in ipairs(sortedAbilityNames()) do
        local entry = ns:GetAbilityCatalogEntry(name)
        addText(frame.content, name, 8, y, "GameFontNormalLarge")
        y = y - 20
        addText(frame.content, familyText(entry), 20, y, "GameFontHighlightSmall")
        y = y - 18

        local ranks = {}
        for rank, rankMeta in pairs(entry.ranks or {}) do
            if rankMeta.source ~= "trainer" then
                ranks[#ranks + 1] = tonumber(rank)
            end
        end
        table.sort(ranks)

        for _, rank in ipairs(ranks) do
            local meta = entry.ranks[rank]
            local known = ns:IsPetAbilityRankKnown(name, rank)
            local marker = known and "|cff808080✓|r" or "|cff33ff33○|r"
            local status = known and "|cff808080Learned|r" or "|cff33ff33Not learned|r"
            local details = string.format("%s  Rank %d  —  %s", marker, rank, status)
            if meta.petLevel then details = details .. string.format("  —  Pet Level %d", meta.petLevel) end
            if meta.trainingPoints ~= nil then details = details .. string.format("  —  %d TP", meta.trainingPoints) end
            addText(frame.content, details, 32, y, "GameFontHighlight")
            y = y - 17
        end
        y = y - 10
    end
    frame.content:SetHeight(math.max(1, -y + 12))
end

local function createWindow()
    frame = CreateFrame("Frame", "PetAbilitiesPlusChecklistFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(560, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.TitleText:SetText("Pet Abilities Plus")

    local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", 14, -34)
    subtitle:SetText("Hunter pet-training checklist")
    rows[#rows + 1] = subtitle

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -54)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(500)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    frame.content = content

    frame:SetScript("OnShow", rebuild)
end

function ns:ToggleChecklist()
    if not frame then createWindow() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

SLASH_PETABILITIESPLUS1 = "/pap"
SlashCmdList.PETABILITIESPLUS = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "" or msg == "abilities" or msg == "checklist" then
        ns:ToggleChecklist()
    end
end
