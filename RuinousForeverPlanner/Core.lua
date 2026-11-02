local _, P = ...
RuinousForeverPlanner = P
P.slotNames = {[1]='Head',[2]='Neck',[3]='Shoulder',[5]='Chest',[6]='Waist',[7]='Legs',[8]='Feet',[9]='Wrist',[10]='Hands',[11]='Ring 1',[12]='Ring 2',[13]='Trinket 1',[14]='Trinket 2',[15]='Back',[16]='Main hand',[17]='Off hand',[18]='Ranged'}
P.slotOrder = {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}
P.requested = {}
function P.Safe(fn, ...)
    if type(fn) ~= 'function' then return nil, 'API missing' end
    local ok, value = pcall(fn, ...)
    if not ok then return nil, 'API failed' end
    if type(issecretvalue) == 'function' and issecretvalue(value) then return nil, 'restricted value' end
    return value
end
function P.Stage(level)
    for _, s in ipairs(P.Data.stages) do if level >= s.min and level <= s.max then return s end end
end
function P.Init()
    P.char=nil; P.profile=nil; P.dbError=nil
    if type(RuinousForeverPlannerDB) ~= 'table' then RuinousForeverPlannerDB = {} end
    local db = RuinousForeverPlannerDB
    if type(db.schema)=='number' and db.schema > 2 then P.dbError = 'Newer saved-data schema; settings are read-only.'; return end
    db.schema = 2
    if type(db.characters) ~= 'table' then db.characters = {} end
    local key = P.Safe(UnitGUID, 'player')
    if type(key) ~= 'string' then P.dbError = 'Character identity unavailable; settings not loaded.'; return end
    local classOK,_,class=pcall(UnitClass,'player')
    if not classOK or type(class)~='string' or (type(issecretvalue)=='function' and issecretvalue(class)) or not P.Data.profiles[class] then
        P.dbError='Player class unavailable or unsupported; wait for login before selecting a profile.';return
    end
    if P.characterKey~=key or P.actualClass~=class then P.snapshot=nil;P.questSnapshot={};P.requested={};P.sessionSample=nil;P.routeCatchup=false end
    P.characterKey=key
    P.actualClass = class
    if type(db.characters[key]) ~= 'table' then db.characters[key] = {} end
    P.char = db.characters[key]
    local c = P.char
    if type(c.preferredSpecs)~='table' then c.preferredSpecs={} end
    local changed=c.class~=class
    c.class=class
    if changed then c.spec=c.preferredSpecs[class];c.previewLevel=nil end
    local found = false
    for _, spec in ipairs(P.Data.profiles[c.class]) do if spec == c.spec then found = true end end
    if not found then c.spec=class=='MAGE' and 'Frost' or P.Data.profiles[c.class][1] end
    c.preferredSpecs[class]=c.spec;c.ownerClass=class
    if type(c.done) ~= 'table' then c.done = {} end
    if c.mode ~= 'solo' and c.mode ~= 'group' then c.mode = 'solo' end
    if type(c.profiles)~='table' then c.profiles={} end
    if c.context~='PvP' then c.context='PvE' end
    local liveLevel=P.Safe(UnitLevel,'player') or 1
    if type(c.targetLevel)~='number' then c.targetLevel=math.min(60,liveLevel+10) end
    if liveLevel<20 and c.targetLevel==30 and not c.manualMilestone then c.targetLevel=math.min(60,liveLevel+10) end
    c.targetLevel=math.max(1,math.min(60,math.floor(c.targetLevel)))
    c.previewLevel=nil -- Level previews are session-only; login always starts at the actual level.
    P.ActivateProfile()
    if P.AutoProfile then P.AutoProfile() end
end
function P.ActivateProfile()
    local c=P.char
    if not c then return end
    local key=c.class..':'..c.spec..':'..c.context
    c.activeProfile=key
    if type(c.profiles[key])~='table' then c.profiles[key]={} end
    local profile=c.profiles[key]
    for _,field in ipairs({'gates','skipped','history','trackedQuests'}) do if type(profile[field])~='table' then profile[field]={} end end
    P.profile=profile
end
function P.Context(value)
    if not P.char or (value~='PvE' and value~='PvP') then return false end
    P.char.context=value; P.ActivateProfile(); return true
end
function P.Profile(class, spec)
    if not P.char or not P.Data.profiles[class] then return false end
    for _, v in ipairs(P.Data.profiles[class]) do
        if v:lower() == spec:lower() then P.char.class=class; P.char.spec=v;P.char.preferredSpecs=P.char.preferredSpecs or {};P.char.preferredSpecs[class]=v; P.ActivateProfile(); return true end
    end
    return false
end
function P.Toggle(id)
    if P.char then P.char.done[id] = not P.char.done[id] end
end
function P.Item(id, link)
    local item = {id=id,link=link}
    local name, err = P.Safe(C_Item and C_Item.GetItemInfo, link or id)
    item.name = name
    item.pending = not name
    item.error = err
    if name and P.ItemDetails then item.details=P.ItemDetails(link or id) end
    if not name and id and not P.requested[id] and C_Item and C_Item.RequestLoadItemDataByID then
        P.requested[id] = true
        pcall(C_Item.RequestLoadItemDataByID, id)
    end
    return item
end
function P.Scan()
    if P.Safe(InCombatLockdown) then P.deferred = true; return false end
    local snap = {equipped={},bags={},errors={},pending=0,bagSlots=0}
    local function errorText(s) snap.errors[#snap.errors+1]=s end
    for _, slot in ipairs(P.slotOrder) do
        local id, err = P.Safe(GetInventoryItemID,'player',slot)
        local link, linkErr = P.Safe(GetInventoryItemLink,'player',slot)
        if err or linkErr then errorText('Equipment '..slot..': '..(err or linkErr)) end
        if id then
            local item=P.Item(id,link); item.slot=slot; snap.equipped[slot]=item
            if item.pending then snap.pending=snap.pending+1 end
        end
    end
    -- Carried backpack + equipped bags only. Bank is deliberately excluded.
    local last = type(NUM_BAG_SLOTS)=='number' and NUM_BAG_SLOTS or 4
    if last < 4 or last > 5 then last = 4 end
    if type(Enum)=='table' and type(Enum.BagIndex)=='table' and Enum.BagIndex.ReagentBag==5 then last=5 end
    for bag=0,last do
        local count, err=P.Safe(C_Container and C_Container.GetContainerNumSlots,bag)
        if type(count)~='number' then errorText('Bag '..bag..': '..(err or 'slot count unavailable'))
        else
            snap.bagSlots=snap.bagSlots+count
            for slot=1,count do
                local info, infoErr=P.Safe(C_Container and C_Container.GetContainerItemInfo,bag,slot)
                if infoErr then errorText('Bag '..bag..' slot '..slot..': '..infoErr) end
                if type(info)=='table' then
                    local ok, item=pcall(function()
                        if type(issecretvalue)=='function' and (issecretvalue(info.itemID) or issecretvalue(info.hyperlink) or issecretvalue(info.stackCount)) then
                            error('restricted item fields')
                        end
                        local v=P.Item(info.itemID,info.hyperlink)
                        if type(issecretvalue)~='function' or not issecretvalue(info.isBound) then if type(info.isBound)=='boolean' then v.bound=info.isBound end end
                        v.bag=bag; v.slot=slot; v.count=info.stackCount or 1; return v
                    end)
                    if ok then snap.bags[#snap.bags+1]=item; if item.pending then snap.pending=snap.pending+1 end
                    else errorText('Bag '..bag..' slot '..slot..': item fields inaccessible') end
                end
            end
        end
    end
    P.snapshot=snap; P.deferred=false; P.scanStale=false
    if P.RefreshQuests then P.RefreshQuests() end
    if P.RecordCoverage then P.RecordCoverage() end
    return true
end
function P.Owned(id)
    local snap=P.snapshot
    if P.scanStale then return 'Unknown: automatic scans off; rescan gear' end
    if not snap then return 'Unknown: scan required' end
    for _, item in pairs(snap.equipped) do if item.id==id then return 'Equipped' end end
    for _, item in ipairs(snap.bags) do if item.id==id then return 'In bags (not equipped)' end end
    if #snap.errors>0 then return 'Unknown: scan incomplete' end
    return 'Not found in carried gear'
end
function P.Targets(level)
    local list={}
    if not P.ProfileSupported() then return list end
    for _, g in ipairs(P.GearCandidates()) do
        if level>=g.min and level<=g.max and (P.char.mode=='group' or g.mode=='solo') and (not g.faction or g.faction==P.Safe(UnitFactionGroup,'player')) then list[#list+1]=g end
    end
    return list
end
function P.MilestoneNotes(stage)
    local m=stage and stage.milestones
    if not m or not P.char then return {} end
    local faction=UnitFactionGroup('player')
    local lines={'NAMED MILESTONES: '..m.evidence}
    if faction=='Alliance' then lines[#lines+1]='Alliance quests: '..m.alliance
    elseif faction=='Horde' then lines[#lines+1]='Horde quests: '..m.horde
    else
        lines[#lines+1]='Alliance quests: '..m.alliance
        lines[#lines+1]='Horde quests: '..m.horde
    end
    if P.char.class==m.roleClass then
        lines[#lines+1]='Priest gear goals: '..m.gear
        lines[#lines+1]='Crafting: '..m.craft
        if m.classQuest then lines[#lines+1]='Class quests: '..m.classQuest end
    else for _,note in ipairs(P.ClassLevelNotes(stage.min)) do lines[#lines+1]=note end end
    lines[#lines+1]='Prerequisites / party checks: '..m.gate
    return lines
end
function P.Tasks(stage)
    local list={}
    if stage and P.char then for _, t in ipairs(stage.tasks) do
        if P.char.mode=='group' or t.mode=='solo' then
            local item=t
            if P.char.class~='PRIEST' and (t.id:match('%-gear$') or t.text:find('Truefaith',1,true) or t.text:find('Holy Priest',1,true) or t.text:find('Death Speaker Robes',1,true)) then
                item={};for k,v in pairs(t) do item[k]=v end
                item.text=t.id:match('%-group$') and 'Collect available dungeon quests and compare class-appropriate rewards before arranging a prepared run.' or P.ClassLevelNotes(stage.min)[1]
            end
            list[#list+1]=item
        end
    end end
    return list
end
function P.Refresh()
    if P.AdvanceRoute and P.char then P.AdvanceRoute() end
    if P.RecordCoverage and P.char then P.RecordCoverage() end
    if P.CaptureDiagnostics and P.char then P.CaptureDiagnostics() end
    if P.Render and P.char then
        local ok,err=pcall(P.Render)
        if not ok and P.HandleUiFailure then P.HandleUiFailure(err) end
    end
end
local events=CreateFrame('Frame')
P.events=events
for _, e in ipairs({'PLAYER_LOGIN','PLAYER_LEVEL_UP','PLAYER_EQUIPMENT_CHANGED','BAG_UPDATE_DELAYED','ITEM_DATA_LOAD_RESULT','PLAYER_REGEN_ENABLED','QUEST_LOG_UPDATE','QUEST_TURNED_IN','ZONE_CHANGED_NEW_AREA','PLAYER_XP_UPDATE','PLAYER_SPECIALIZATION_CHANGED','PLAYER_TALENT_UPDATE'}) do
    pcall(events.RegisterEvent,events,e)
end
events:SetScript('OnEvent',function(_,event)
    if event=='PLAYER_LOGIN' then P.Init(); if P.InstallItemTooltipHook then P.InstallItemTooltipHook() end; if P.StartBaseline then P.StartBaseline() end end
    if not P.char then return end
    if event=='PLAYER_SPECIALIZATION_CHANGED' or event=='PLAYER_TALENT_UPDATE' then if P.AutoProfile then P.AutoProfile() end;P.Refresh();return end
    if event=='PLAYER_XP_UPDATE' then if P.RecordSessionSample then P.RecordSessionSample() end; if P.RecordGrindSample then P.RecordGrindSample() end;return end
    if event=='ZONE_CHANGED_NEW_AREA' then P.Refresh();return end
    if event~='PLAYER_LOGIN' and event~='PLAYER_LEVEL_UP' and event~='QUEST_LOG_UPDATE' and event~='QUEST_TURNED_IN' and P.UIOptions and not P.UIOptions().autoScan then P.scanStale=true; P.Refresh(); return end
    if event=='ITEM_DATA_LOAD_RESULT' then
        -- Re-read cached names, but never request missing IDs in a loop.
        P.itemDirty=true;return
    elseif event=='PLAYER_LEVEL_UP' then
        -- UnitLevel can update after the event arguments; refresh on the next frame.
        P.levelDirty=true
    elseif event=='QUEST_LOG_UPDATE' or event=='QUEST_TURNED_IN' then
        P.questDirty=true
    elseif event=='PLAYER_REGEN_ENABLED' or event=='PLAYER_EQUIPMENT_CHANGED' or event=='BAG_UPDATE_DELAYED' or event=='PLAYER_LOGIN' then P.Scan() end
    P.Refresh()
end)
events:SetScript('OnUpdate',function(_,elapsed)
    if P.routeCatchup and P.AdvanceRoute then P.AdvanceRoute();if not P.routeCatchup then P.Refresh() end end
    if P.EfficiencyLoadStep then P.EfficiencyLoadStep(elapsed) end
    if P.BaselineStep then P.BaselineStep() end
    if P.itemDirty then P.itemDirty=false;P.Scan();P.Refresh() end
    if P.questDirty then P.questDirty=false; if P.RefreshQuests then P.RefreshQuests() end; P.Refresh() end
    if P.levelDirty then P.levelDirty=false;if P.RecordSessionSample then P.RecordSessionSample() end;if P.RecordGrindSample then P.RecordGrindSample() end; P.Refresh() end
end)
