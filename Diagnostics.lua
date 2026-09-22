local ADDON_NAME, ns = ...

local function out(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg))
end

local function safe(v)
    if v == nil then return "nil" end
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    local ok, s = pcall(tostring, v)
    return ok and s or "<unreadable>"
end

local function inspectTooltip(reason, tooltip, tooltipData)
    tooltip = tooltip or GameTooltip
    out("--- " .. reason .. " ---")
    out("shown=" .. safe(tooltip and tooltip:IsShown()) ..
        " ProcessInfo=" .. safe(tooltip and tooltip.ProcessInfo) ..
        " GetPrimaryTooltipData=" .. safe(tooltip and tooltip.GetPrimaryTooltipData))

    if tooltipData then
        out("callback data: type=" .. safe(tooltipData.type) ..
            " id=" .. safe(tooltipData.id) ..
            " guid=" .. safe(tooltipData.guid))
    end

    if tooltip and tooltip.GetPrimaryTooltipData then
        local ok, data = pcall(tooltip.GetPrimaryTooltipData, tooltip)
        if ok and data then
            out("primary data: type=" .. safe(data.type) ..
                " id=" .. safe(data.id) ..
                " guid=" .. safe(data.guid))
        else
            out("primary data: " .. (ok and "nil" or "ERROR"))
        end
    end

    if UnitExists("mouseover") then
        local name = UnitName("mouseover")
        local guid = UnitGUID("mouseover")
        local npcID = ns:GetCreatureIDFromGUID(guid)
        local rows = ns:GetAbilitiesForCreature(npcID, name)
        out("mouseover: name=" .. safe(name) .. " guid=" .. safe(guid) ..
            " npcID=" .. safe(npcID) .. " databaseMatch=" .. safe(rows and #rows or 0))
    else
        out("mouseover: no unit")
    end

    if tooltip and tooltip.NumLines then
        local ok, count = pcall(tooltip.NumLines, tooltip)
        out("NumLines=" .. safe(ok and count or "<error>"))
        if ok and count then
            for i = 1, count do
                local fs = _G["GameTooltipTextLeft" .. i]
                if fs and fs.GetText then
                    local okText, txt = pcall(fs.GetText, fs)
                    if okText then out("L" .. i .. "=" .. safe(txt)) end
                end
            end
        end
    end
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    inspectTooltip("manual /papdiag", GameTooltip)
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if tooltip == GameTooltip and ns.diagEnabled then
            inspectTooltip("TooltipDataProcessor Unit post-call", tooltip, data)
        end
    end)
end

SLASH_PETABILITIESPLUSDIAGTOGGLE1 = "/papdiagwatch"
SlashCmdList.PETABILITIESPLUSDIAGTOGGLE = function()
    ns.diagEnabled = not ns.diagEnabled
    out("automatic unit-tooltip logging " .. (ns.diagEnabled and "ON" or "OFF"))
end

out("diagnostic loaded. Hover a known beast and type /papdiag. Use /papdiagwatch only if requested.")
