local ADDON_NAME, ns = ...

local TOOLTIP_HEADER = "Pet Abilities"

local function addAbilitiesToTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return end

    local creatureID = ns:GetCreatureIDFromGUID(UnitGUID(unit))
    local creatureName = UnitName(unit)
    local abilities = ns:GetAbilitiesForCreature(creatureID, creatureName)
    if not abilities then return end

    -- Avoid duplicate lines if Forever rebuilds the same tooltip repeatedly.
    local key = tostring(creatureID or "") .. ":" .. tostring(creatureName or "")
    if tooltip.PetAbilitiesPlusKey == key then return end
    tooltip.PetAbilitiesPlusKey = key

    tooltip:AddLine(" ")
    tooltip:AddLine(TOOLTIP_HEADER, 1, 0.82, 0)
    for _, row in ipairs(abilities) do
        local text = ns:FormatAbility(row)
        if text then tooltip:AddLine(text, 0.35, 0.85, 1) end
    end
    tooltip:Show()
end

local function clearMarker(tooltip)
    tooltip.PetAbilitiesPlusKey = nil
end

GameTooltip:HookScript("OnTooltipCleared", clearMarker)

-- Forever currently identifies as a Mainline project while exposing a hybrid
-- API surface. Hook both available tooltip paths instead of choosing one.
if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end
        local _, unit = tooltip:GetUnit()
        addAbilitiesToTooltip(tooltip, unit)
    end)
end

if GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        local _, unit = tooltip:GetUnit()
        addAbilitiesToTooltip(tooltip, unit)
    end)
end

-- Reliable fallback for Forever mouseover tooltips.
local frame = CreateFrame("Frame")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:SetScript("OnEvent", function()
    if GameTooltip and GameTooltip:IsShown() and UnitExists("mouseover") then
        addAbilitiesToTooltip(GameTooltip, "mouseover")
    end
end)
