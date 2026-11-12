local _, ns = ...
-- Persistent diagnostics preference; default OFF for existing and new users.
function ns:IsDiagnosticsEnabled()
    return type(PetAbilitiesPlusDB) == "table"
        and type(PetAbilitiesPlusDB.settings) == "table"
        and PetAbilitiesPlusDB.settings.diagnosticsEnabled == true
end
function ns:SetDiagnosticsEnabled(enabled)
    PetAbilitiesPlusDB = type(PetAbilitiesPlusDB) == "table" and PetAbilitiesPlusDB or {}
    PetAbilitiesPlusDB.settings = PetAbilitiesPlusDB.settings or {}
    PetAbilitiesPlusDB.settings.diagnosticsEnabled = enabled == true
end

local panel = CreateFrame("Frame", "PetAbilitiesPlusOptionsPanel")
panel.name = "Pet Abilities Plus"
local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
heading:SetPoint("TOPLEFT", 18, -18)
heading:SetText("Pet Abilities Plus")
local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
description:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -12)
description:SetWidth(500)
description:SetJustifyH("LEFT")
description:SetText("Diagnostics are disabled by default. Enable them temporarily when investigating pet abilities or Beast Training.")
local toggle = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
toggle:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
toggle.Text:SetText("Enable verbose diagnostics")
toggle:SetScript("OnClick", function(self)
    ns:SetDiagnosticsEnabled(self:GetChecked())
end)
panel:SetScript("OnShow", function()
    toggle:SetChecked(ns:IsDiagnosticsEnabled())
end)
local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
hint:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 4, -14)
hint:SetWidth(500)
hint:SetJustifyH("LEFT")
hint:SetText("When enabled, diagnostic events are printed to chat. Manual /papdiag commands remain available even when disabled.")
-- Forever builds vary in which Blizzard settings API is available.
-- Always retain a standalone options frame so the preference is accessible.
panel:SetSize(560, 240)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:SetClampedToScreen(true)
panel:Hide()
local backdrop = CreateFrame("Frame", nil, panel, "BasicFrameTemplateWithInset")
backdrop:SetAllPoints()
backdrop:SetFrameLevel(panel:GetFrameLevel())
if backdrop.TitleText then backdrop.TitleText:SetText("Pet Abilities Plus - Options") end
local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 0, 0)
close:SetScript("OnClick", function() panel:Hide() end)
panel:SetScript("OnShow", function() toggle:SetChecked(ns:IsDiagnosticsEnabled()) end)

local registered = false
local categoryID
local function registerBlizzardOptions()
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and category then
            local added = pcall(Settings.RegisterAddOnCategory, category)
            if added then
                categoryID = category.GetID and category:GetID() or nil
                registered = true
                return
            end
        end
    end
    if type(InterfaceOptions_AddCategory) == "function" then
        registered = pcall(InterfaceOptions_AddCategory, panel)
    end
end
-- A single frame cannot simultaneously be a Settings canvas and an
-- independently shown dialog; register a separate canvas wrapper.
local standalone = panel
local canvas = CreateFrame("Frame", "PetAbilitiesPlusSettingsCanvas")
canvas.name = "Pet Abilities Plus"
local canvasTitle = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
canvasTitle:SetPoint("TOPLEFT", 16, -16)
canvasTitle:SetText("Pet Abilities Plus")
local canvasToggle = CreateFrame("CheckButton", nil, canvas, "InterfaceOptionsCheckButtonTemplate")
canvasToggle:SetPoint("TOPLEFT", 16, -58)
canvasToggle.Text:SetText("Enable verbose diagnostics")
canvasToggle:SetScript("OnClick", function(self)
    ns:SetDiagnosticsEnabled(self:GetChecked())
    toggle:SetChecked(ns:IsDiagnosticsEnabled())
end)
canvas:SetScript("OnShow", function()
    canvasToggle:SetChecked(ns:IsDiagnosticsEnabled())
end)
-- Register the settings-specific canvas, never the standalone dialog.
panel = canvas
registerBlizzardOptions()
panel = standalone
function ns:OpenOptions()
    if registered and categoryID and Settings and Settings.OpenToCategory then
        local ok = pcall(Settings.OpenToCategory, categoryID)
        if ok then return end
    elseif registered and type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        local ok = pcall(InterfaceOptionsFrame_OpenToCategory, canvas)
        if ok then return end
    end
    standalone:Show()
    standalone:Raise()
end
