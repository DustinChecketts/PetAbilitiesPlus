local ADDON_NAME, ns = ...

-- Read-only Pet Abilities checklist. This is intentionally built from the
-- complete catalog rather than the active pet, so it can become the Hunter's
-- persistent training checklist and later feed ForeverPets.

local frame
local dynamicObjects = {}

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

local function clearDynamicObjects()
    for _, object in ipairs(dynamicObjects) do object:Hide() end
    wipe(dynamicObjects)
end

local function addText(parent, text, x, y, template)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    dynamicObjects[#dynamicObjects + 1] = fs
    return fs
end

local function addRightText(parent, text, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("TOPRIGHT", -8, y)
    fs:SetWidth(315)
    fs:SetJustifyH("RIGHT")
    fs:SetText(text or "")
    fs:SetTextColor(0.72, 0.72, 0.72)
    dynamicObjects[#dynamicObjects + 1] = fs
    return fs
end

local function getAbilitySpellInfo(name)
    local entry = ns:GetAbilityCatalogEntry(name)
    if not entry then return nil end

    -- Future Forever/Petopia catalog records can provide an explicit icon or
    -- representative spellID. Until then, ask the client by localized name.
    if entry.icon then return entry.icon end
    if entry.spellID then
        if C_Spell and C_Spell.GetSpellTexture then
            local ok, texture = pcall(C_Spell.GetSpellTexture, entry.spellID)
            if ok and texture then return texture end
        elseif GetSpellTexture then
            local ok, texture = pcall(GetSpellTexture, entry.spellID)
            if ok and texture then return texture end
        end
    end

    local lookupName = name == "Demoralizing Screech" and "Screech" or name
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, lookupName)
        if ok and type(info) == "table" and info.iconID then return info.iconID end
    end
    if GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, lookupName)
        if ok and texture then return texture end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function addAbilityIcon(parent, name, y)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("TOPLEFT", 8, y + 3)
    icon:SetTexture(getAbilitySpellInfo(name))
    dynamicObjects[#dynamicObjects + 1] = icon
end

local function addStatusIcon(parent, known, y)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(14, 14)
    holder:SetPoint("TOPLEFT", 35, y + 2)
    dynamicObjects[#dynamicObjects + 1] = holder

    local bg = holder:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.08, 0.08, 0.08, 0.85)

    local border = holder:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetTexture("Interface\\Buttons\\WHITE8X8")
    if known then
        border:SetVertexColor(0.42, 0.42, 0.42, 1)
    else
        border:SetVertexColor(0.15, 0.85, 0.15, 1)
    end

    bg:SetDrawLayer("BORDER", 1)

    if known then
        local check = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        check:SetPoint("CENTER", 0, 1)
        check:SetText("✓")
        check:SetTextColor(0.65, 0.65, 0.65)
    end
end

local function familyText(entry)
    if not entry.families or #entry.families == 0 then return "Family data pending" end
    return table.concat(entry.families, ", ")
end

local function rebuild()
    if not frame then return end
    clearDynamicObjects()

    local y = -12
    for _, name in ipairs(sortedAbilityNames()) do
        local entry = ns:GetAbilityCatalogEntry(name)
        addAbilityIcon(frame.content, name, y)
        addText(frame.content, name, 38, y, "GameFontNormalLarge")
        addRightText(frame.content, familyText(entry), y - 2)
        y = y - 29

        local ranks = {}
        for rank, rankMeta in pairs(entry.ranks or {}) do
            if rankMeta.source ~= "trainer" then ranks[#ranks + 1] = tonumber(rank) end
        end
        table.sort(ranks)

        for _, rank in ipairs(ranks) do
            local meta = entry.ranks[rank]
            local known = ns:IsPetAbilityRankKnown(name, rank)
            addStatusIcon(frame.content, known, y)
            local status = known and "|cff808080Learned|r" or "|cff33ff33Not learned|r"
            local details = string.format("Rank %d  —  %s", rank, status)
            if meta.petLevel then details = details .. string.format("  —  Pet Level %d", meta.petLevel) end
            if meta.trainingPoints ~= nil then details = details .. string.format("  —  %d TP", meta.trainingPoints) end
            addText(frame.content, details, 55, y, "GameFontHighlight")
            y = y - 18
        end
        y = y - 12
    end
    frame.content:SetHeight(math.max(1, -y + 12))
end

local function createWindow()
    frame = CreateFrame("Frame", "PetAbilitiesPlusChecklistFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(670, 600)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.TitleText:SetText("Pet Abilities Plus")

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -38)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(610)
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
    if msg == "" or msg == "abilities" or msg == "checklist" then ns:ToggleChecklist() end
end
