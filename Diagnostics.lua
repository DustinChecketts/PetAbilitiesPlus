local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    local refreshed = ns:RefreshKnownPetAbilities()
    out("Beast Training sync=" .. tostring(refreshed)
        .. " knowledgeReady=" .. tostring(ns.petAbilityKnowledgeReady))
    if ns.petAbilityKnowledgeReady then
        local found = 0
        for abilityName, meta in pairs(ns.ClassicAbilities or {}) do
            for rank in pairs(meta.ranks or {}) do
                if ns:IsPetAbilityRankKnown(abilityName, rank) then
                    found = found + 1
                    out(abilityName .. " (Rank " .. rank .. ") = LEARNED")
                end
            end
        end
        out("learned ranks=" .. found)
    else
        out("Open Beast Training once to synchronize learned abilities.")
    end
end
