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

local panel = CreateFrame("Frame", "PetAbilitiesPlusOptionsPanel", UIParent, "BasicFrameTemplateWithInset")
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
if panel.TitleText then panel.TitleText:SetText("Pet Abilities Plus - Options") end
panel:SetScript("OnShow", function() toggle:SetChecked(ns:IsDiagnosticsEnabled()) end)

-- Use a dedicated, hidden Settings canvas. This follows the native
-- RegisterCanvasLayoutCategory -> RegisterAddOnCategory pattern used by
-- working Forever addons. Do not reuse the standalone dialog as the canvas.
local categoryID
local legacyRegistered = false
local canvas = CreateFrame("Frame", "PetAbilitiesPlusSettingsCanvas")
canvas.name = "Pet Abilities Plus"
canvas:Hide()
local canvasTitle = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
canvasTitle:SetPoint("TOPLEFT", 16, -16)
canvasTitle:SetText("Pet Abilities Plus")
local canvasDescription = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
canvasDescription:SetPoint("TOPLEFT", canvasTitle, "BOTTOMLEFT", 0, -12)
canvasDescription:SetWidth(500)
canvasDescription:SetJustifyH("LEFT")
canvasDescription:SetText("Optional diagnostic event logging for troubleshooting.")
local canvasToggle = CreateFrame("CheckButton", nil, canvas, "InterfaceOptionsCheckButtonTemplate")
canvasToggle:SetPoint("TOPLEFT", canvasDescription, "BOTTOMLEFT", 0, -18)
canvasToggle.Text:SetText("Enable verbose diagnostics")
canvasToggle:SetScript("OnClick", function(self)
    ns:SetDiagnosticsEnabled(self:GetChecked())
    toggle:SetChecked(ns:IsDiagnosticsEnabled())
end)
canvas:SetScript("OnShow", function()
    canvasToggle:SetChecked(ns:IsDiagnosticsEnabled())
end)
local function registerOptions()
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, canvas, canvas.name)
        if ok and category then
            local added = pcall(Settings.RegisterAddOnCategory, category)
            if added then
                ns.optionsCategory = category
                categoryID = category.GetID and category:GetID() or nil
                return
            end
        end
    end
    if type(InterfaceOptions_AddCategory) == "function" then
        legacyRegistered = pcall(InterfaceOptions_AddCategory, canvas)
    end
end
-- Register after the addon is loaded, when Blizzard's Settings system is ready.
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= ns.addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    registerOptions()
end)
function ns:OpenOptions()
    if categoryID and Settings and Settings.OpenToCategory then
        local ok = pcall(Settings.OpenToCategory, categoryID)
        if ok then return end
    elseif legacyRegistered and type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        local ok = pcall(InterfaceOptionsFrame_OpenToCategory, canvas)
        if ok then return end
    end
    standalone:Show()
    standalone:Raise()
end
