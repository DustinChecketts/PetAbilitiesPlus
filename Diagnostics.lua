local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    out("Known-state check: Bite1=" .. tostring(ns:IsPetAbilityRankKnown("Bite", 1))
        .. " Claw1=" .. tostring(ns:IsPetAbilityRankKnown("Claw", 1))
        .. " Claw2=" .. tostring(ns:IsPetAbilityRankKnown("Claw", 2))
        .. " Cower1=" .. tostring(ns:IsPetAbilityRankKnown("Cower", 1)))
end
