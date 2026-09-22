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

local function frameName(frame)
    if not frame then return "nil" end
    local ok, name = pcall(frame.GetName, frame)
    if ok and name then return name end
    return "<anonymous>"
end

local function frameType(frame)
    if not frame then return "nil" end
    local ok, kind = pcall(frame.GetObjectType, frame)
    return ok and safe(kind) or "?"
end

local function shown(frame)
    if not frame or not frame.IsShown then return false end
    local ok, value = pcall(frame.IsShown, frame)
    return ok and value or false
end

local function interestingKey(k)
    k = string.lower(tostring(k))
    return string.find(k, "data", 1, true)
        or string.find(k, "spell", 1, true)
        or string.find(k, "train", 1, true)
        or string.find(k, "ability", 1, true)
        or string.find(k, "known", 1, true)
        or string.find(k, "avail", 1, true)
        or string.find(k, "filter", 1, true)
        or string.find(k, "rank", 1, true)
        or string.find(k, "cost", 1, true)
        or string.find(k, "skill", 1, true)
        or string.find(k, "element", 1, true)
        or string.find(k, "provider", 1, true)
        or string.find(k, "entry", 1, true)
        or string.find(k, "info", 1, true)
end

local function dumpTable(label, tbl, depth, seen)
    if type(tbl) ~= "table" or depth > 2 then return end
    seen = seen or {}
    if seen[tbl] then return end
    seen[tbl] = true

    local count = 0
    for k, v in pairs(tbl) do
        if interestingKey(k) then
            count = count + 1
            if count > 30 then
                out(label .. " ... truncated")
                break
            end
            if type(v) == "table" then
                out(label .. "." .. safe(k) .. "=<table>")
                dumpTable(label .. "." .. safe(k), v, depth + 1, seen)
            elseif type(v) ~= "function" then
                out(label .. "." .. safe(k) .. "=" .. safe(v))
            end
        end
    end
end

local function dumpFrame(frame, label)
    if not frame then return end
    out(label .. " name=" .. frameName(frame) .. " type=" .. frameType(frame)
        .. " shown=" .. tostring(shown(frame)))

    dumpTable(label, frame, 0, {})

    if frame.GetElementData then
        local ok, data = pcall(frame.GetElementData, frame)
        if ok and data then
            out(label .. ".GetElementData=<" .. type(data) .. ">")
            if type(data) == "table" then dumpTable(label .. ".elementData", data, 0, {}) end
        end
    end
    if frame.GetDataProvider then
        local ok, provider = pcall(frame.GetDataProvider, frame)
        if ok and provider then
            out(label .. ".GetDataProvider=" .. safe(provider))
            dumpTable(label .. ".provider", provider, 0, {})
        end
    end
end

local function dumpMouseFocus()
    out("--- MOUSE FOCUS CHAIN ---")
    local frames = {}
    if GetMouseFoci then
        local ok, result = pcall(function() return {GetMouseFoci()} end)
        if ok then frames = result end
    elseif GetMouseFocus then
        local ok, result = pcall(GetMouseFocus)
        if ok and result then frames = {result} end
    end

    if #frames == 0 then
        out("No mouse focus frame found. Hover a Beast Training row and retry.")
        return
    end

    for i, focus in ipairs(frames) do
        dumpFrame(focus, "focus[" .. i .. "]")
        local parent = focus
        for depth = 1, 8 do
            if not parent or not parent.GetParent then break end
            local ok, nextParent = pcall(parent.GetParent, parent)
            if not ok or not nextParent or nextParent == parent then break end
            parent = nextParent
            dumpFrame(parent, "focus[" .. i .. "].parent" .. depth)
        end
    end
end

local function scanGlobals()
    out("--- VISIBLE TRAINING GLOBALS ---")
    local hits = 0
    for name, value in pairs(_G) do
        local lower = string.lower(tostring(name))
        if (string.find(lower, "pet", 1, true) or string.find(lower, "beast", 1, true))
            and (string.find(lower, "train", 1, true) or string.find(lower, "skill", 1, true)) then
            if type(value) == "table" then
                local isFrame = value.GetObjectType ~= nil
                if (not isFrame) or shown(value) then
                    hits = hits + 1
                    out(name .. "=" .. safe(value)
                        .. (isFrame and (" [" .. frameType(value) .. ", shown=" .. tostring(shown(value)) .. "]") or ""))
                    if isFrame and shown(value) then dumpFrame(value, "global." .. name) end
                    if hits >= 40 then
                        out("global scan truncated")
                        break
                    end
                end
            elseif type(value) == "function" then
                hits = hits + 1
                out(name .. "=<function>")
                if hits >= 40 then break end
            end
        end
    end
    if hits == 0 then out("No matching globals found.") end
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    out("=== BEAST TRAINING UI INSPECTOR ===")
    out("Enable ALL THREE Beast Training filters first.")
    out("Hover a row (preferably an Already Known row) while running this.")
    dumpMouseFocus()
    scanGlobals()
end
