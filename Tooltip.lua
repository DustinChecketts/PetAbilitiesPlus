local ADDON_NAME, ns = ...

local TOOLTIP_HEADER = "Pet Abilities"
local lastMouseoverKey

local function addAbilitiesToTooltip(tooltip, unit, force)
    if not tooltip or not unit or not UnitExists(unit) then return false end

    local creatureID = ns:GetCreatureIDFromGUID(UnitGUID(unit))
    local creatureName = UnitName(unit)
    local abilities = ns:GetAbilitiesForCreature(creatureID, creatureName)
    if not abilities then return false end

    local key = tostring(creatureID or "") .. ":" .. tostring(creatureName or "")
    if not force and tooltip.PetAbilitiesPlusKey == key then return true end
    tooltip.PetAbilitiesPlusKey = key

    tooltip:AddLine(" ")
    tooltip:AddLine(TOOLTIP_HEADER, 1, 0.82, 0)
    for _, row in ipairs(abilities) do
        local text = ns:FormatAbility(row)
        if text then tooltip:AddLine(text, 0.35, 0.85, 1) end
    end
    tooltip:Show()
    return true
end

local function rebuildMouseoverTooltip()
    if not UnitExists("mouseover") then return end

    local creatureID = ns:GetCreatureIDFromGUID(UnitGUID("mouseover"))
    local creatureName = UnitName("mouseover")
    local abilities = ns:GetAbilitiesForCreature(creatureID, creatureName)
    if not abilities then return end

    -- Forever's native creature tooltip can be rebuilt after normal tooltip
    -- callbacks fire. Rebuild it once for known pet-training beasts, then append
    -- our data. SetUnit preserves Blizzard's normal creature tooltip content.
    if GameTooltip and GameTooltip:IsShown() then
        GameTooltip.PetAbilitiesPlusKey = nil
        GameTooltip:SetUnit("mouseover")
        addAbilitiesToTooltip(GameTooltip, "mouseover", true)
    end
end

local function scheduleMouseoverRefresh()
    if not UnitExists("mouseover") then return end

    local key = tostring(UnitGUID("mouseover") or UnitName("mouseover") or "")
    if key == lastMouseoverKey then return end
    lastMouseoverKey = key

    -- Zero-delay defers until after Forever's own tooltip population pass.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, rebuildMouseoverTooltip)
    else
        rebuildMouseoverTooltip()
    end
end

GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
    tooltip.PetAbilitiesPlusKey = nil
end)

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end
        local _, unit = tooltip:GetUnit()
        if unit then addAbilitiesToTooltip(tooltip, unit) end
    end)
end

if GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        local _, unit = tooltip:GetUnit()
        if unit then addAbilitiesToTooltip(tooltip, unit) end
    end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:SetScript("OnEvent", scheduleMouseoverRefresh)

-- Forever does not consistently emit UPDATE_MOUSEOVER_UNIT for every world
-- tooltip. A light OnUpdate fallback notices a changed mouseover unit and runs
-- the same deferred refresh without continuously rebuilding the tooltip.
local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.10 then return end
    elapsed = 0

    if UnitExists("mouseover") then
        scheduleMouseoverRefresh()
    else
        lastMouseoverKey = nil
    end
end)
