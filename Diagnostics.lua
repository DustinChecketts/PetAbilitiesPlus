local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    local refreshed = ns:RefreshKnownPetAbilities()
    out("Beast Training sync=" .. tostring(refreshed)
        .. " knowledgeReady=" .. tostring(ns.petAbilityKnowledgeReady))
    if not ns.petAbilityKnowledgeReady then
        out("Open Beast Training once to synchronize hunter-known abilities.")
        return
    end

    local found = 0
    for abilityName, meta in pairs(ns.ClassicAbilities or {}) do
        for rank, rankMeta in pairs(meta.ranks or {}) do
            if rankMeta.source ~= "trainer" and ns:IsPetAbilityRankKnown(abilityName, rank) then
                found = found + 1
                out(abilityName .. " (Rank " .. rank .. ") = HUNTER KNOWN")
            end
        end
    end
    out("hunter-known wild ranks=" .. found)
end
