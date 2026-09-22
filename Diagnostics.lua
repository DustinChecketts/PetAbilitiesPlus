local ADDON_NAME, ns = ...

-- Development-only diagnostics. This file is intentionally excluded from the
-- release TOC; add it locally while investigating Forever API changes.
local function out(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg))
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    out("knowledgeReady=" .. tostring(ns.petAbilityKnowledgeReady))
    local found = 0
    for abilityName, meta in pairs(ns.ClassicAbilities or {}) do
        for rank, rankMeta in pairs(meta.ranks or {}) do
            if rankMeta.source ~= "trainer" and ns:IsPetAbilityRankKnown(abilityName, rank) then
                found = found + 1
                out(abilityName .. " (Rank " .. rank .. ") = HUNTER KNOWN")
            end
        end
    end
    out("cached hunter-known wild ranks=" .. found)
end
