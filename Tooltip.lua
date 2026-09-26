local ADDON_NAME, ns = ...

local TOOLTIP_HEADER = "Pet Abilities"
local LEARNED = { 0.50, 0.50, 0.50 }
local UNLEARNED = { 0.20, 1.00, 0.20 }

local function addAbilitiesToTooltip(tooltip, unit)
    if not tooltip or not unit then return end

    -- Forever can return a secret unit token from GameTooltip:GetUnit(),
    -- especially while grouped/entering instances. Passing that token back
    -- into UnitExists/UnitGUID/UnitName from addon execution is forbidden.
    if type(issecretvalue) == "function" and issecretvalue(unit) then
        return
    end
    if type(canaccessvalue) == "function" and not canaccessvalue(unit) then
        return
    end
    if not UnitExists(unit) then return end

    local guid = UnitGUID(unit)
    if type(issecretvalue) == "function" and issecretvalue(guid) then
        return
    end
    if type(canaccessvalue) == "function" and guid ~= nil and not canaccessvalue(guid) then
        return
    end

    local creatureID = ns:GetCreatureIDFromGUID(guid)
    local creatureName = UnitName(unit)
    local abilities = ns:GetAbilitiesForCreature(creatureID, creatureName)
    if not abilities then return end

    tooltip:AddLine(" ")
    tooltip:AddLine(TOOLTIP_HEADER, 1, 0.82, 0)

    for _, row in ipairs(abilities) do
        local text = ns:FormatAbility(row)
        if text then
            local known = ns:IsPetAbilityRankKnown(row.ability, row.rank)
            local color = known and LEARNED or UNLEARNED
            tooltip:AddLine(text, color[1], color[2], color[3])
        end
    end
end

-- Blizzard owns tooltip creation, refresh, and dismissal. We only append
-- PetAbilitiesPlus data when Blizzard finishes building a unit tooltip.
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
    and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end
        local _, unit = tooltip:GetUnit()
        if unit then addAbilitiesToTooltip(tooltip, unit) end
    end)
end
