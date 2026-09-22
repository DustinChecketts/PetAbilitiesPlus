local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end
local function safe(v)
    if v == nil then return "nil" end
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    local ok, s = pcall(tostring, v)
    return ok and s or "<unreadable>"
end

local function dumpTrainer()
    out("=== BEAST TRAINING SERVICE DUMP ===")
    out("GetNumTrainerServices=" .. safe(GetNumTrainerServices)
        .. " GetTrainerServiceInfo=" .. safe(GetTrainerServiceInfo)
        .. " GetTrainerServiceTypeFilter=" .. safe(GetTrainerServiceTypeFilter))

    if not (GetNumTrainerServices and GetTrainerServiceInfo) then
        out("Trainer service API unavailable.")
        return
    end

    local filters = {"available", "unavailable", "used"}
    if GetTrainerServiceTypeFilter then
        for _, kind in ipairs(filters) do
            local ok, value = pcall(GetTrainerServiceTypeFilter, kind)
            out("filter[" .. kind .. "]=" .. (ok and safe(value) or "ERROR"))
        end
    end

    local ok, count = pcall(GetNumTrainerServices)
    if not ok then out("GetNumTrainerServices ERROR"); return end
    out("services=" .. safe(count))

    local totals = {available=0, unavailable=0, used=0, other=0}
    for index = 1, (tonumber(count) or 0) do
        local good, name, kind, texture, level, sub, category = pcall(GetTrainerServiceInfo, index)
        if good and name then
            totals[kind] = (totals[kind] or 0) + 1
            out(string.format("[%d] %s%s | kind=%s | level=%s | category=%s",
                index,
                safe(name),
                (sub and sub ~= "") and (" (" .. safe(sub) .. ")") or "",
                safe(kind), safe(level), safe(category)))
        elseif not good then
            out("[" .. index .. "] ERROR")
        end
    end

    out(string.format("TOTAL available=%d unavailable=%d used=%d other=%d",
        totals.available or 0, totals.unavailable or 0, totals.used or 0, totals.other or 0))
    out("'used' is the client state displayed as Already Known.")
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = dumpTrainer
