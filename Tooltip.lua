local ADDON_NAME, ns = ...

local TOOLTIP_HEADER = "Pet Abilities"

local function addAbilitiesToTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then
        return
    end

    if UnitCreatureType and UnitCreatureType(unit) ~= "Beast" then
        return
    end

    local creatureID = ns:GetCreatureIDFromGUID(UnitGUID(unit))
    local abilities = ns:GetAbilitiesForCreature(creatureID)
    if not abilities then
        return
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(TOOLTIP_HEADER, 1, 0.82, 0)

    for _, row in ipairs(abilities) do
        local text = ns:FormatAbility(row)
        if text then
            tooltip:AddLine(text, 0.35, 0.85, 1)
        end
    end

    tooltip:Show()
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not tooltip or tooltip ~= GameTooltip then
            return
        end

        local _, unit = tooltip:GetUnit()
        addAbilitiesToTooltip(tooltip, unit)
    end)
else
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        local _, unit = tooltip:GetUnit()
        addAbilitiesToTooltip(tooltip, unit)
    end)
end
