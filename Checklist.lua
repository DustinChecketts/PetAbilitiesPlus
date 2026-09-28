local ADDON_NAME, ns = ...

-- Read-only Pet Abilities checklist. This is intentionally built from the
-- complete catalog rather than the active pet, so it can become the Hunter's
-- persistent training checklist and later feed ForeverPets.

local frame
local dynamicObjects = {}
local selectedFamily = "All Families"
local selectedPet = nil

local function currentPetChoice()
    if not (UnitExists and UnitExists("pet")) then return nil end
    local family = UnitCreatureFamily and UnitCreatureFamily("pet")
    if type(family) ~= "string" or family == "" then return nil end
    local name = UnitName and UnitName("pet") or "Current Pet"
    return { label = tostring(name) .. " (" .. family .. ")", family = family }
end

local function allFamilies()
    local seen, families = {}, {}
    for _, entry in pairs(ns:GetAbilityCatalog() or {}) do
        for _, family in ipairs(entry.families or {}) do
            if not seen[family] then
                seen[family] = true
                families[#families + 1] = family
            end
        end
    end
    table.sort(families)
    return families
end

local function abilityMatchesFamily(entry)
    local wanted = selectedPet and selectedPet.family or selectedFamily
    if wanted == "All Families" then return true end
    for _, family in ipairs(entry.families or {}) do
        if family == wanted then return true end
    end
    return false
end

local function sortedAbilityNames()
    local names = {}
    for name, entry in pairs(ns:GetAbilityCatalog() or {}) do
        local hasWild = false
        for _, rankMeta in pairs(entry.ranks or {}) do
            if rankMeta.source == "wild" then hasWild = true break end
        end
        if hasWild and abilityMatchesFamily(entry) then names[#names + 1] = name end
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

local function showAbilityTooltip(owner, name)
    local entry = ns:GetAbilityCatalogEntry(name)
    if not entry then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(name, 1, 0.82, 0)
    if entry.description then
        GameTooltip:AddLine(entry.description, 1, 1, 1, true)
    else
        GameTooltip:AddLine("Pet ability. Rank values vary.", 1, 1, 1, true)
    end
    if entry.families and #entry.families > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(table.concat(entry.families, ", "), 0.72, 0.72, 0.72, true)
    end
    GameTooltip:Show()
end

local function addAbilityIcon(parent, name, y)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    button:SetPoint("TOPLEFT", 7, y + 4)
    dynamicObjects[#dynamicObjects + 1] = button
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(getAbilitySpellInfo(name))
    button:SetScript("OnEnter", function(self) showAbilityTooltip(self, name) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

local function showRankTooltip(owner, name, rank, meta)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(string.format("%s (Rank %d)", name, rank), 1, 0.82, 0)
    local entry = ns:GetAbilityCatalogEntry(name)
    if entry and entry.description then GameTooltip:AddLine(entry.description, 1, 1, 1, true) end
    if meta.petLevel then GameTooltip:AddLine("Requires Pet Level " .. meta.petLevel, 1, 1, 1) end
    if meta.trainingPoints ~= nil then GameTooltip:AddLine("Training Points: " .. meta.trainingPoints, 1, 1, 1) end
    local known = ns:IsPetAbilityRankKnown(name, rank)
    if known then GameTooltip:AddLine("Learned", 0.50, 0.75, 1.00)
    else GameTooltip:AddLine("Not learned", 1.00, 0.82, 0.00) end
    if meta.unverifiedDetails then GameTooltip:AddLine("Some Forever rank details are still being verified.", 0.8, 0.65, 0.25, true) end
    GameTooltip:Show()
end

local function addRankHitbox(parent, name, rank, meta, y)
    local hitbox = CreateFrame("Frame", nil, parent)
    hitbox:SetPoint("TOPLEFT", 52, y + 3)
    hitbox:SetPoint("TOPRIGHT", -8, y + 3)
    hitbox:SetHeight(18)
    hitbox:EnableMouse(true)
    hitbox:SetScript("OnEnter", function(self) showRankTooltip(self, name, rank, meta) end)
    hitbox:SetScript("OnLeave", GameTooltip_Hide)
    dynamicObjects[#dynamicObjects + 1] = hitbox
end

local function addStatusIcon(parent, known, y)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(16, 16)
    holder:SetPoint("TOPLEFT", 34, y + 2)
    dynamicObjects[#dynamicObjects + 1] = holder

    local box = holder:CreateTexture(nil, "ARTWORK")
    box:SetAllPoints()
    box:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")

    if known then
        local check = holder:CreateTexture(nil, "OVERLAY")
        check:SetSize(16, 16)
        check:SetPoint("CENTER")
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
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
            if rankMeta.source == "wild" then ranks[#ranks + 1] = tonumber(rank) end
        end
        table.sort(ranks)

        for _, rank in ipairs(ranks) do
            local meta = entry.ranks[rank]
            local known = ns:IsPetAbilityRankKnown(name, rank)
            addStatusIcon(frame.content, known, y)
            addRankHitbox(frame.content, name, rank, meta, y)
            local status = known and "|cff80c0ffLearned|r" or "|cffffd100Not learned|r"
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

local function createFamilyDropdown(parent)
    local dropdown = CreateFrame("Frame", "PetAbilitiesPlusFamilyDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", -2, -31)
    UIDropDownMenu_SetWidth(dropdown, 155)
    UIDropDownMenu_SetText(dropdown, selectedPet and selectedPet.label or selectedFamily)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local function addChoice(label)
            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = not selectedPet and selectedFamily == label
            info.func = function()
                selectedPet = nil
                selectedFamily = label
                UIDropDownMenu_SetText(dropdown, label)
                rebuild()
            end
            UIDropDownMenu_AddButton(info, level)
        end

        local pet = currentPetChoice()
        if pet then
            local info = UIDropDownMenu_CreateInfo()
            info.text = pet.label
            info.checked = selectedPet and selectedPet.label == pet.label
            info.func = function()
                selectedPet = pet
                selectedFamily = pet.family
                UIDropDownMenu_SetText(dropdown, pet.label)
                rebuild()
            end
            UIDropDownMenu_AddButton(info, level)

            local separator = UIDropDownMenu_CreateInfo()
            separator.text = " "
            separator.disabled = true
            UIDropDownMenu_AddButton(separator, level)
        end

        addChoice("All Families")
        for _, family in ipairs(allFamilies()) do addChoice(family) end
    end)

    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("LEFT", dropdown, "RIGHT", -6, 2)
    label:SetText("Pet Family")
    label:SetTextColor(0.72, 0.72, 0.72)
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
    createFamilyDropdown(frame)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -72)
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
