local _,P=...
-- IDs identify specs independently of client language; names cover custom exports.
local specs={
 [62]={'MAGE','Arcane'},[63]={'MAGE','Fire'},[64]={'MAGE','Frost'},
 [256]={'PRIEST','Discipline'},[257]={'PRIEST','Holy'},[258]={'PRIEST','Shadow'},
 [71]={'WARRIOR','Arms'},[72]={'WARRIOR','Fury'},[73]={'WARRIOR','Protection'},
 [65]={'PALADIN','Holy'},[66]={'PALADIN','Protection'},[70]={'PALADIN','Retribution'},
 [259]={'ROGUE','Assassination'},[260]={'ROGUE','Combat'},[261]={'ROGUE','Subtlety'},
 [253]={'HUNTER','Beast Mastery'},[254]={'HUNTER','Marksmanship'},[255]={'HUNTER','Survival'},
 [265]={'WARLOCK','Affliction'},[266]={'WARLOCK','Demonology'},[267]={'WARLOCK','Destruction'},
 [262]={'SHAMAN','Elemental'},[263]={'SHAMAN','Enhancement'},[264]={'SHAMAN','Restoration'},
 [102]={'DRUID','Balance'},[103]={'DRUID','Feral'},[104]={'DRUID','Guardian'},[105]={'DRUID','Restoration'}}
function P.DetectPlayerSpec()
    local api=C_SpecializationInfo
    if not P.char or not api or type(api.GetSpecialization)~='function' or type(api.GetSpecializationInfo)~='function' then return nil end
    local index=P.Safe(api.GetSpecialization)
    if type(index)~='number' or index<1 then return nil end
    local ok,id,name=pcall(api.GetSpecializationInfo,index)
    if not ok or (type(issecretvalue)=='function' and (issecretvalue(id) or issecretvalue(name))) then return nil end
    local entry=specs[id];local candidate=entry and entry[1]==P.actualClass and entry[2] or name
    for _,spec in ipairs(P.Data.profiles[P.actualClass] or {}) do if candidate==spec then return spec end end
end
function P.AutoProfile()
    if not P.char then return end
    local spec=P.DetectPlayerSpec()
    P.detectedSpec=spec
    P.Profile(P.actualClass,spec or (P.char.preferredSpecs and P.char.preferredSpecs[P.actualClass]) or P.Data.profiles[P.actualClass][1])
    P.profileDetection=spec and 'Active client spec detected' or 'Active spec unavailable / not selected: using a class-specific planning profile'
end
