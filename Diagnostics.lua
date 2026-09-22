local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end
local function safe(v)
    if v == nil then return "nil" end
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    local ok, s = pcall(tostring, v)
    return ok and s or "<unreadable>"
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    out("pet spellbook API: GetSpellBookItemName=" .. safe(GetSpellBookItemName) ..
        " C_SpellBook=" .. safe(C_SpellBook and C_SpellBook.GetSpellBookItemName))
    for _, ability in ipairs({"Bite", "Claw", "Cower"}) do
        for rank = 1, 8 do
            local known = ns:IsPetAbilityRankKnown(ability, rank)
            if known == true then out(ability .. " Rank " .. rank .. " = KNOWN") end
        end
    end
end
