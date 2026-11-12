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
if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    ns.optionsCategory = category
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end
function ns:OpenOptions()
    if Settings and Settings.OpenToCategory and ns.optionsCategory then
        Settings.OpenToCategory(ns.optionsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end
