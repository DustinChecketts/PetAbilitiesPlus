local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end

local function dumpServices()
    if not (GetNumTrainerServices and GetTrainerServiceInfo) then
        out("Trainer service API unavailable.")
        return
    end
    local ok, count = pcall(GetNumTrainerServices)
    count = ok and tonumber(count) or 0
    out("raw services=" .. count)
    for index = 1, count do
        local good, name, kind, _, level, sub = pcall(GetTrainerServiceInfo, index)
        if good and name and (name == "Claw" or name == "Cower" or name == "Bite") then
            out(string.format("[%d] %s%s kind=%s level=%s",
                index, tostring(name),
                (sub and sub ~= "") and (" (" .. tostring(sub) .. ")") or "",
                tostring(kind), tostring(level)))
        end
    end
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    out("=== LEARNED-STATE CHECK ===")
    out("sync=" .. tostring(ns:RefreshKnownPetAbilities())
        .. " ready=" .. tostring(ns.petAbilityKnowledgeReady))
    out("Claw1=" .. tostring(ns:IsPetAbilityRankKnown("Claw",1))
        .. " Claw2=" .. tostring(ns:IsPetAbilityRankKnown("Claw",2))
        .. " Cower1=" .. tostring(ns:IsPetAbilityRankKnown("Cower",1))
        .. " Bite1=" .. tostring(ns:IsPetAbilityRankKnown("Bite",1)))
    dumpServices()
end
