local _,P=...
function P.ProfileInfo()
    if not P.char then return end
    return P.SourceData and P.SourceData.profileSources[P.char.class..':'..P.char.spec..':'..P.char.context]
end
function P.ProfileSupported()
    if P.SourceData then return P.ProfileInfo()~=nil end
    return P.char and P.char.class=='PRIEST' and P.char.spec=='Holy' and P.char.context=='PvE'
end
function P.ProfileRole()
    local info=P.ProfileInfo()
    if info then return info.role end
    local class=P.char and P.char.class
    return ({MAGE='caster',WARLOCK='caster',ROGUE='agility',HUNTER='ranged',WARRIOR='strength',PALADIN='strength',SHAMAN='caster',DRUID='caster',PRIEST=P.char and P.char.spec=='Shadow' and 'caster' or 'healer'})[class] or 'caster'
end
local slotLoc={[1]='INVTYPE_HEAD',[2]='INVTYPE_NECK',[3]='INVTYPE_SHOULDER',[5]='INVTYPE_CHEST',[6]='INVTYPE_WAIST',[7]='INVTYPE_LEGS',[8]='INVTYPE_FEET',[9]='INVTYPE_WRIST',[10]='INVTYPE_HAND',[11]='INVTYPE_FINGER',[13]='INVTYPE_TRINKET',[15]='INVTYPE_CLOAK',[16]='INVTYPE_WEAPON',[17]='INVTYPE_HOLDABLE',[18]='INVTYPE_RANGED'}
function P.ProfileCandidates()
    if not P.SourceData then
        if not P.ProfileSupported() then return {} end
        local list={}; for _,g in ipairs(P.Data.gear) do list[#list+1]=g end
        for _,g in ipairs(P.Data.questRewards or {}) do list[#list+1]=g end; return list
    end
    local info=P.ProfileInfo(); if not info then return {} end
    if P.catalogueSource~=P.SourceData then P.catalogueSource=P.SourceData;P.catalogueCache={} end
    local cacheKey=P.char.class..':'..P.char.spec..':'..P.char.context
    if P.catalogueCache[cacheKey] then return P.catalogueCache[cacheKey] end
    local source=P.SourceData.listVariants[info.path]; local result,seen={},{}
    for _,r in ipairs(source.candidates) do
        if not seen[r.id] then
            seen[r.id]=true
            local fact=P.SourceData.items[tostring(r.id)]
            if fact then
                local g={}; for k,v in pairs(fact) do g[k]=v end
                g.name=r.name; g.slot=r.slot; g.randomSuffix=r.randomSuffix; g.sourceList=source.source; g.sourceRank=r.rank
                g.min=fact.sourceMinLevel or 30; g.max=30
                g.levelNote=fact.sourceMinLevel and ('Source wear level '..fact.sourceMinLevel) or 'Level-30 reference; wear level unconfirmed'
                g.acquire=r.acquisition~='' and r.acquisition or 'Inspect source and live tooltip for acquisition.'
                g.materials=r.materials~='' and r.materials or ''
                g.equipLoc=fact.sourceEquipLoc or (r.slot~=16 and r.slot~=17 and r.slot~=18 and slotLoc[r.slot] or nil)
                g.mode='solo';g.effort='purchase'
                for _,link in ipairs(r.links) do
                    if link.url:find('/dungeons/',1,true) then g.mode='group';g.effort='dungeon';g.activity=link.label end
                    if link.url:find('/professions/',1,true) then g.effort='craft' end
                end
                if #g.questIDs>0 then g.effort='quest' end
                local alliance=g.acquire:find('Alliance',1,true); local horde=g.acquire:find('Horde',1,true)
                if alliance and not horde then g.faction='Alliance' elseif horde and not alliance then g.faction='Horde' end
                -- Preserve audited legacy acquisition windows and structured chain overrides.
                for _,old in ipairs(P.Data.gear) do if old.id==g.id then
                    g.min=old.min;g.max=old.max;g.questID=old.questID;g.faction=old.faction or g.faction
                    if old.mode=='group' then g.mode='group';g.activity=old.activity end
                end end
                result[#result+1]=g
            end
        end
    end
    P.catalogueCache[cacheKey]=result
    return result
end
function P.CandidateOwned(g)
    if not g.randomSuffix then return P.Owned(g.id) end
    if not P.snapshot or P.scanStale then return 'Unknown: scan required' end
    local pending=false
    for _,item in pairs(P.snapshot.equipped) do if item.id==g.id then
        if item.name==g.name then return 'Equipped' elseif not item.name then pending=true end
    end end
    for _,item in ipairs(P.snapshot.bags) do if item.id==g.id then
        if item.name==g.name then return 'In bags (not equipped)' elseif not item.name then pending=true end
    end end
    if pending or #P.snapshot.errors>0 then return 'Unknown: variant data incomplete' end
    return 'Not found in carried gear'
end
function P.CandidateDetails(g)
    local client=P.Item(g.id).details
    if client then return client end
    if g.confirmed and not g.randomSuffix and g.sourceMinLevel and g.sourceStats then
        return {minLevel=g.sourceMinLevel,equipLoc=g.equipLoc,stats=g.sourceStats,fromSource=true}
    end
end
function P.CoverageMessage()
    if not P.SourceData then return 'Full class catalogue is unavailable: reinstall the complete addon folder. Another-class sample is not substituted.' end
    local info=P.ProfileInfo()
    if info then return (info.shared and 'Shared role reference: ' or 'Source list: ')..P.SourceData.listVariants[info.path].title end
    return 'No bundled source list for this profile. Inventory and leveling guidance remain available.'
end

function P.GearCandidates() return P.SourceData and P.ProfileCandidates() or P.ProfileSupported() and P.Data.gear or {} end
