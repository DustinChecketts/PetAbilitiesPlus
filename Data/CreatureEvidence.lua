local _, ns = ...
-- One evidence model for Classic baseline, Forever overrides, community
-- reports, and local tame candidates. Never promote inherited Classic evidence
-- to Forever-verified merely because the creature exists in Forever.
local function key(row)
    return tostring(row.ability or "") .. ":" .. tostring(row.rank or "")
end
local function copy(row)
    local out = {}
    for k,v in pairs(row) do out[k]=v end
    return out
end
local function add(out, index, row, tier, sourceType, gameVersion, inherited)
    if not row or not row.ability then return end
    local item = copy(row)
    item.tier = tier
    item.sourceType = row.sourceType or sourceType
    item.gameVersion = row.gameVersion or gameVersion
    item.inheritedFrom = inherited
    local k = key(item)
    local previous = index[k]
    -- A local observation is a candidate until reviewed, not a verified override.
    -- A verified Forever row takes precedence over inherited Classic data.
    local priority = {lead=1, community=2, verified=3}
    if not previous or priority[item.tier] > priority[previous.tier] then
        if previous then
            for i,old in ipairs(out) do if old==previous then out[i]=item break end end
        else out[#out+1]=item end
        index[k]=item
    end
end

function ns:GetCreatureEvidence(npcId, creatureName)
    local out, index = {}, {}
    local classic = ns.ClassicCreatureAbilities
    local classicNames = ns.ClassicCreatureAbilitiesByName
    for _,row in ipairs(npcId and classic and classic[npcId] or {}) do
        add(out,index,row,"community","classic-reference","classic",true)
    end
    for _,row in ipairs(creatureName and classicNames and classicNames[creatureName] or {}) do
        add(out,index,row,"community","classic-reference","classic",true)
    end
    local forever = ns.ForeverCreatureAbilities
    local foreverNames = ns.ForeverCreatureAbilitiesByName
    for _,row in ipairs(npcId and forever and forever[npcId] or {}) do
        add(out,index,row,row.verified and "verified" or "lead","forever-observation","forever",false)
    end
    for _,row in ipairs(creatureName and foreverNames and foreverNames[creatureName] or {}) do
        add(out,index,row,row.verified and "verified" or "lead","forever-observation","forever",false)
    end
    local reported = ns.CommunityReportedByName
    for _,row in ipairs(creatureName and reported and reported[creatureName] or {}) do
        add(out,index,row,"community","community-spreadsheet","forever",false)
    end
    local verified = ns.CommunityVerified
    for _,row in ipairs(npcId and verified and verified[npcId] or {}) do
        add(out,index,row,"verified","reviewed-tame","forever",false)
    end
    local db = PetAbilitiesPlusDB
    local candidate = db and db.communityDiscoveries and npcId and db.communityDiscoveries[tostring(npcId)]
    for _,row in ipairs(candidate and candidate.spellbook or {}) do
        add(out,index,row,"lead","local-tame-candidate","forever",false)
    end
    table.sort(out,function(a,b)
        if a.ability==b.ability then return (a.rank or 0)<(b.rank or 0) end
        return tostring(a.ability)<tostring(b.ability)
    end)
    return out
end
