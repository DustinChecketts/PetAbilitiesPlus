local _, ns = ...
-- Community-reported sources are deliberately separate from verified mappings.
-- Attribution: xWillawisp's "New Tames in Forever" published spreadsheet,
-- linked from https://forums.wow-petopia.com/viewtopic.php?t=27358
-- These records are reports, NOT proof from our tame/spellbook pipeline.
local source = "https://forums.wow-petopia.com/viewtopic.php?t=27358"
local rows = {
 {"Scrawny Ursera","Claw",1,3,4,"Thendal Grove, Zephras Isle","Bear"},
 {"Ursera Scavenger","Claw",1,4,4,"Thendal Cave, Zephras Isle","Bear"},
 {"Urs'anah","Claw",1,5,5,"Thendal Cave, Zephras Isle","Bear"},
 {"Juveline Vuldren","Bite",1,1,1,"Thendal Grove, Zephras Isle","Fox"},
 {"Prideclaw","Cower",1,5,5,"Shen'dar Highlands, Zephras Isle","Cat"},
 {"Galestrider","Dust Cloud",1,5,6,"Shen'dar Highlands, Zephras Isle","Tallstrider"},
 {"Vuldren","Bite",1,6,6,"Shen'dar Highlands, Zephras Isle","Fox"},
 {"Vulgara the Insatiable","Bite",2,8,8,"Shen'dar Highlands, Zephras Isle","Wolf"},
 {"Ornery Galestrider","Dust Cloud",1,8,8,"Gustberry Lowlands, Zephras Isle","Tallstrider"},
 {"Vuldren Alpha","Trickster's Dance",1,10,10,"Gustberry Lowlands, Zephras Isle","Fox"},
 {"Windsong Crawler","Claw",2,9,9,"Gustberry Lowlands, Zephras Isle","Crab"},
 {"Shriekling Fledgling","Cower",1,8,9,"Shriekling Den, Zephras Isle","Raptor"},
 {"Shriekling Matriarch","Savage Rend",1,9,9,"Shriekling Den, Zephras Isle","Raptor"},
 {"Shadowgale Shriekling","Savage Rend",1,10,11,"Shadowgale Forest","Bird of Prey"},
 {"Shadowgale Ursera","Claw",3,10,10,"Ruins of Bana'aethal","Bear"},
 {"Mystmane","Savage Rend",1,nil,nil,"Shadowgale Forest","Bear"},
 {"Coldrasp","Furious Howl",1,12,12,"Whispering Forest, Tirisfal Glades","Wolf"},
 {"Child of Jai'vhanel","Cower",1,10,10,"Darkshore","Owl"},
 {"Elmpaw","Claw",2,12,12,"Elwynn Forest","Bear"},
 {"Broodwidow","Dash",3,16,16,"Ruins of Lordaeron","Spider"},
 {"Highland Tortoise","Bite",4,26,26,"Wetlands","Turtle"},
}
ns.CommunityReported = {}
ns.CommunityReportedByName = {}
for _, row in ipairs(rows) do
    local item = {
        creature=row[1], ability=row[2], rank=row[3],
        minLevel=row[4], maxLevel=row[5], location=row[6], family=row[7],
        tier="community", contributor="xWillawisp / Petopia contributors",
        sourceType="community-spreadsheet", sourceUrl=source,
    }
    ns.CommunityReported[#ns.CommunityReported+1] = item
    local list = ns.CommunityReportedByName[item.creature] or {}
    list[#list+1] = item
    ns.CommunityReportedByName[item.creature] = list
end
-- "No ability" reports are not the same as an empty/uninspected field.
ns.CommunityNoAbilityReports = {
    "Rabid Forest Wolf", "Ghostfang", "Nightscreech", "Befouled Webwood",
    "Jai'vhanel", "Ridgeshade Creeper", "Ridgeshade Lurker",
    "Maddened Rotclaw", "Carnage", "Bloodtalon Matriarch",
}
-- Unknown ability entries remain leads, not negative observations.
ns.CommunityUninspected = {"Slydris","Highland Spider","Fernfeather"}
-- The source sheet spells Vuldren Alpha as "Vulgren Alpha".
-- The local NPC 250874 tame corroborates the ability but was manually
-- correlated; promotion to fully verified awaits automatic spellbook evidence.
ns.CommunityReportAliases = {["Vulgren Alpha"]="Vuldren Alpha"}
