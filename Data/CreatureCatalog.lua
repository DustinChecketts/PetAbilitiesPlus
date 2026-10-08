local _, ns = ...
-- Historical Classic NPC IDs, corroborated against published creature pages.
-- These are CLASSIC identities; Forever presence and ability ranks are separate
-- assertions and must not be silently treated as confirmed.
ns.CreatureCatalog = {
 [2349]={name="Giant Moss Creeper",family="Spider",minLevel=24,maxLevel=25,zone="Hillsbrad Foothills / Alterac Mountains",sourceUrl="https://www.wowhead.com/wotlk/npc=2349/giant-moss-creeper",identityTier="classic-reference"},
 [4005]={name="Deepmoss Creeper",family="Spider",minLevel=16,maxLevel=17,zone="Stonetalon Mountains",sourceUrl="https://www.wowhead.com/classic/npc=4005/deepmoss-creeper",identityTier="classic-reference"},
 [505]={name="Greater Tarantula",family="Spider",minLevel=19,maxLevel=20,zone="Redridge Mountains",sourceUrl="https://www.wowhead.com/classic/npc=505/greater-tarantula",identityTier="classic-reference"},
 [442]={name="Tarantula",family="Spider",zone="Redridge Mountains",sourceUrl="https://www.wowhead.com/classic/npc=442/tarantula",identityTier="classic-reference"},
 [2563]={name="Plains Creeper",family="Spider",zone="Arathi Highlands",sourceUrl="https://www.wowhead.com/classic/npc=2563/plains-creeper",identityTier="classic-reference"},
 [2565]={name="Giant Plains Creeper",family="Spider",zone="Arathi Highlands",sourceUrl="https://www.wowhead.com/cata/npc=2565/giant-plains-creeper",identityTier="classic-reference"},
 [2348]={name="Elder Moss Creeper",family="Spider",zone="Hillsbrad Foothills",sourceUrl="https://www.wowhead.com/cata/npc=2348/elder-moss-creeper",identityTier="classic-reference"},
 [250874]={name="Vuldren Alpha",family="Fox",minLevel=10,maxLevel=10,zone="Zephras Isle",subzone="Gustberry Lowlands",identityTier="forever-observed",sourceType="wild-target-guid"},
 [270693]={name="Daggerfang",family="Crocolisk",minLevel=15,maxLevel=15,zone="Loch Modan",subzone="The Loch",identityTier="forever-observed",sourceType="wild-target-guid"},
}
ns.CreatureCatalogByName = {}
for id, creature in pairs(ns.CreatureCatalog) do
    local list = ns.CreatureCatalogByName[creature.name] or {}
    list[#list+1] = id
    ns.CreatureCatalogByName[creature.name] = list
end
function ns:GetCreatureCatalogEntry(npcId)
    return npcId and ns.CreatureCatalog[tonumber(npcId)] or nil
end
