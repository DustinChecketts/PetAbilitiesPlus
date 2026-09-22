local ADDON_NAME, ns = ...

local TOOLTIP_HEADER = "Pet Abilities"
local lastMouseoverKey
local LEARNED = { 0.50, 0.50, 0.50 }
local UNLEARNED = { 0.20, 1.00, 0.20 }
local UNKNOWN = { 0.35, 0.85, 1.00 }

local function addAbilitiesToTooltip(tooltip, unit)
    if not tooltip or not unit or not UnitExists(unit) then return false end
    local creatureID = ns:GetCreatureIDFromGUID(UnitGUID(unit))
    local creatureName = UnitName(unit)
    local abilities = ns:GetAbilitiesForCreature(creatureID, creatureName)
    if not abilities then return false end

    local key = tostring(creatureID or "") .. ":" .. tostring(creatureName or "")
    if tooltip.PetAbilitiesPlusKey == key then return true end
    tooltip.PetAbilitiesPlusKey = key

    tooltip:AddLine(" ")
    tooltip:AddLine(TOOLTIP_HEADER, 1, 0.82, 0)
    for _, row in ipairs(abilities) do
        local text = ns:FormatAbility(row)
        if text then
            local known = ns:IsPetAbilityRankKnown(row.ability, row.rank)
            local color = known == true and LEARNED or (known == false and UNLEARNED or UNKNOWN)
            tooltip:AddLine(text, color[1], color[2], color[3])
        end
    end
    tooltip:Show()
    return true
end

local function rebuildMouseoverTooltip()
    if not UnitExists("mouseover") or not GameTooltip or not GameTooltip:IsShown() then return end
    local creatureID = ns:GetCreatureIDFromGUID(UnitGUID("mouseover"))
    local creatureName = UnitName("mouseover")
    if not ns:GetAbilitiesForCreature(creatureID, creatureName) then return end
    GameTooltip.PetAbilitiesPlusKey = nil
    GameTooltip:SetUnit("mouseover")
end

local function scheduleMouseoverRefresh()
    if not UnitExists("mouseover") then return end
    local key = tostring(UnitGUID("mouseover") or UnitName("mouseover") or "")
    if key == lastMouseoverKey then return end
    lastMouseoverKey = key
    if C_Timer and C_Timer.After then C_Timer.After(0, rebuildMouseoverTooltip) else rebuildMouseoverTooltip() end
end

GameTooltip:HookScript("OnTooltipCleared", function(tooltip) tooltip.PetAbilitiesPlusKey = nil end)

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
    and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end
        local _, unit = tooltip:GetUnit()
        if unit then addAbilitiesToTooltip(tooltip, unit) end
    end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:RegisterEvent("PET_BAR_UPDATE")
frame:RegisterEvent("PET_UI_UPDATE")
frame:SetScript("OnEvent", function(_, event)
    if event ~= "UPDATE_MOUSEOVER_UNIT" then lastMouseoverKey = nil end
    scheduleMouseoverRefresh()
end)

local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.10 then return end
    elapsed = 0
    if UnitExists("mouseover") then scheduleMouseoverRefresh() else lastMouseoverKey = nil end
end)
