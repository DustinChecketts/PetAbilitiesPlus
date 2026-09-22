local ADDON_NAME, ns = ...

local function out(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffPAP DIAG:|r " .. tostring(msg)) end
local function safe(v)
    if v == nil then return "nil" end
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    local ok, s = pcall(tostring, v)
    return ok and s or "<unreadable>"
end

local function dumpLegacyPetBook()
    out("legacy BOOKTYPE_PET=" .. safe(BOOKTYPE_PET))
    if not GetSpellBookItemName then
        out("GetSpellBookItemName unavailable")
        return
    end
    for i = 1, 40 do
        local ok, name, subName = pcall(GetSpellBookItemName, i, BOOKTYPE_PET or "pet")
        if not ok then
            out("legacy[" .. i .. "] ERROR")
            break
        end
        if not name then break end
        out("legacy[" .. i .. "] name=" .. safe(name) .. " subName=" .. safe(subName))
    end
end

local function dumpModernPetBook()
    if not C_SpellBook then
        out("C_SpellBook unavailable")
        return
    end
    out("C_SpellBook.GetSpellBookItemName=" .. safe(C_SpellBook.GetSpellBookItemName))
    out("C_SpellBook.GetSpellBookItemInfo=" .. safe(C_SpellBook.GetSpellBookItemInfo))
    out("Enum.SpellBookSpellBank.Pet=" .. safe(Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet))

    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    if not bank then return end

    for i = 1, 40 do
        local name
        if C_SpellBook.GetSpellBookItemName then
            local ok, value = pcall(C_SpellBook.GetSpellBookItemName, i, bank)
            if ok then name = value end
        end

        local info
        if C_SpellBook.GetSpellBookItemInfo then
            local ok, value = pcall(C_SpellBook.GetSpellBookItemInfo, i, bank)
            if ok then info = value end
        end

        if not name and not info then break end
        local infoText = "nil"
        if type(info) == "table" then
            local parts = {}
            for k, v in pairs(info) do parts[#parts + 1] = safe(k) .. "=" .. safe(v) end
            table.sort(parts)
            infoText = table.concat(parts, ",")
        else
            infoText = safe(info)
        end
        out("modern[" .. i .. "] name=" .. safe(name) .. " info={" .. infoText .. "}")
    end
end

SLASH_PETABILITIESPLUSDIAG1 = "/papdiag"
SlashCmdList.PETABILITIESPLUSDIAG = function()
    out("--- PET SPELLBOOK ---")
    dumpLegacyPetBook()
    dumpModernPetBook()
end
