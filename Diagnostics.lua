local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end
local function safe(v)
    if v == nil then return "nil" end
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    local ok, s = pcall(tostring, v)
    return ok and s or "<unreadable>"
end

local function dumpCrafts()
    out("--- BEAST TRAINING / CRAFT API ---")
    out("GetNumCrafts=" .. safe(GetNumCrafts) .. " GetCraftInfo=" .. safe(GetCraftInfo)
        .. " GetCraftDisplaySkillLine=" .. safe(GetCraftDisplaySkillLine))
    if not (GetNumCrafts and GetCraftInfo) then
        out("Legacy Craft API unavailable.")
        return
    end

    local ok, count = pcall(GetNumCrafts)
    if not ok then
        out("GetNumCrafts ERROR")
        return
    end
    out("GetNumCrafts=" .. safe(count))

    for i = 1, (tonumber(count) or 0) do
        local values = {pcall(GetCraftInfo, i)}
        if values[1] then
            table.remove(values, 1)
            local parts = {}
            for n, v in ipairs(values) do parts[#parts + 1] = n .. "=" .. safe(v) end
            out("craft[" .. i .. "] " .. table.concat(parts, " | "))
        else
            out("craft[" .. i .. "] ERROR")
        end
    end
end

local function dumpPotentialTrainingAPIs()
    out("--- TRAINING API SURFACE ---")
    for _, name in ipairs({
        "GetCraftInfo","GetCraftName","GetCraftDescription","GetCraftIcon",
        "GetCraftNumReagents","GetCraftReagentInfo","GetCraftSpellFocus",
        "GetCraftDisplaySkillLine","GetCraftSkillLine","GetCraftSelectionIndex",
        "GetPetTrainingPoints","GetPetLoyalty","GetNumPetLoyaltySkills"
    }) do
        out(name .. "=" .. safe(_G[name]))
    end
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    dumpPotentialTrainingAPIs()
    dumpCrafts()
    out("Tip: run once with Beast Training CLOSED and again with it OPEN.")
end
