local _, P = ...
local window, body, scroll, content
local page='Now'
function P.OpenPage(value) page=value;P.Show();if scroll then scroll:SetVerticalScroll(0) end end
function P.OpenEfficiencyGuide() page='Guide';P.Show();if scroll then scroll:SetVerticalScroll(0) end end
local classButton,specButton,profileMenu
local classNames={DRUID='Druid',HUNTER='Hunter',MAGE='Mage',PALADIN='Paladin',PRIEST='Priest',ROGUE='Rogue',SHAMAN='Shaman',WARLOCK='Warlock',WARRIOR='Warrior'}
P.inspectIndex=1
P.inspectBagIndex=1
local function button(parent,text,x,y,width,fn)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    b:SetSize(width or 110,24); b:SetPoint('TOPLEFT',x,y); b:SetText(text)
    b:SetScript('OnClick',function(self,...)
        local ok,err=pcall(fn,self,...)
        if not ok and P.HandleUiFailure then P.HandleUiFailure(err) end
    end)
    return b
end
function P.IsPlannerShown() return window and window:IsShown() or false end
function P.HideProfileMenu() if profileMenu then profileMenu:Hide() end end
function P.HidePlanner() P.HideProfileMenu(); if window then window:Hide() end end
function P.ShowProfileMenu(kind,owner)
    if not P.char then return end
    if profileMenu then profileMenu:Hide() end
    local entries={}
    if kind=='page' then for _,name in ipairs({'Inventory','Class quests','Professions','Sell','Group','Preparation','Priorities','Help'}) do entries[#entries+1]=name end
    elseif kind=='profession' then for _,id in ipairs(P.ProfessionOrder) do entries[#entries+1]=id end
    elseif kind=='class' then
        for key in pairs(P.Data.profiles) do entries[#entries+1]=key end
        table.sort(entries)
    else for _,spec in ipairs(P.Data.profiles[P.char.class]) do entries[#entries+1]=spec end end
    profileMenu=CreateFrame('Frame',nil,window)
    profileMenu:SetSize(200,#entries*26+12); profileMenu:SetPoint(kind=='profession' and 'BOTTOMLEFT' or 'TOPLEFT',owner,kind=='profession' and 'TOPLEFT' or 'BOTTOMLEFT',0,-2)
    profileMenu:SetFrameStrata('DIALOG'); profileMenu:SetFrameLevel(300); profileMenu:EnableMouse(true)
    local bg=profileMenu:CreateTexture(nil,'BACKGROUND'); bg:SetAllPoints(); bg:SetColorTexture(.035,.05,.075,1)
    P.profileMenu=profileMenu; P.profileMenuEntries={}
    for i,entry in ipairs(entries) do
        local selected=kind=='class' and P.char.class==entry or kind=='spec' and P.char.spec==entry
        local b=button(profileMenu,(selected and '[x] ' or '')..(kind=='profession' and P.ProfessionData[entry].name or classNames[entry] or entry),6,-6-(i-1)*26,188,function()
            if kind=='page' then page=entry
            elseif kind=='profession' then P.char.professionGuide=entry
            elseif kind=='class' then P.Profile(entry,entry==P.char.class and P.char.spec or (P.char.preferredSpecs and P.char.preferredSpecs[entry]) or P.Data.profiles[entry][1]) else P.Profile(P.char.class,entry) end
            P.inspectIndex=1; P.inspectBagIndex=1; profileMenu:Hide(); P.Render()
        end)
        P.profileMenuEntries[entry]=b
    end
    profileMenu:Show()
end
local function clean(v)
    -- Database text can contain no markup; client item names are escaped for display.
    return tostring(v or ''):gsub('|','||')
end
local function itemText(item)
    if not item then return 'Empty / not applicable (when scan is complete)' end
    return clean(item.name or 'Item data pending')..' [ID '..tostring(item.id or '?')..']'
end
function P.InspectTarget()
    local targets=P.Targets(P.Safe(UnitLevel,'player') or 0)
    if #targets==0 then return nil end
    P.inspectIndex=math.max(1,math.min(#targets,P.inspectIndex))
    return targets[P.inspectIndex]
end
local function inspect(mode,owner,quiet)
    local target=P.InspectTarget()
    if not target then if not quiet then print('No current candidate for this profile / level / mode.') end; return end
    local ref
    if mode=='target' then ref={mode='target',id=target.id}
    elseif mode=='equipped' then ref={mode='equipped',slot=target.slot}
    else
        local items=P.BagAlternatives(target.slot)
        P.inspectBagIndex=math.max(1,math.min(#items,P.inspectBagIndex))
        local item=items[P.inspectBagIndex]
        if not item then if not quiet then print('No carried slot alternatives with available equip-type data.') end; return end
        ref={mode='bag',bag=item.bag,slot=item.slot}
    end
    local ok,err=P.ItemTooltip(ref,owner)
    if not ok and not quiet then print('Ruinous Forever Planner: '..err) end
end
function P.Render()
    if not window or not window:IsShown() or not P.char then return end
    local c=P.char
    if classButton then classButton:SetText((classNames[c.class] or c.class)..' v') end
    if specButton then specButton:SetText(c.spec..' v') end
    local level=P.Safe(UnitLevel,'player') or 0
    local faction=P.Safe(UnitFactionGroup,'player') or 'Unknown'
    local stage=P.Stage(P.ViewLevel())
    local lines={'Ruinous Forever Planner 0.22 | Level '..level,
        (classNames[c.class] or c.class)..' / '..c.spec..' / '..c.context..' | '..c.mode..' | '..page}
    local function add(t) lines[#lines+1]=t end
    add('Character: '..(classNames[P.actualClass] or P.actualClass or 'Unknown')..' | Actual level '..level)
    if P.profileDetection then add(P.profileDetection..(P.detectedSpec and (': '..P.detectedSpec) or '')) end
    if P.primaryButton then P.primaryButton:SetText(page=='Now' and 'Inspect / pin action' or page=='Sell' and 'Edit sell estimates' or page=='Class quests' and 'Track class quest' or 'Track top upgrade') end
    for _,b in ipairs(P.itemControls or {}) do if page=='Now' then b:Hide() else b:Show() end end
    for _,b in ipairs(P.nowControls or {}) do if page=='Now' then b:Show() else b:Hide() end end
    if P.routeAutoButton then P.routeAutoButton:SetText(P.char.route and P.char.route.auto and 'Auto progress: ON' or 'Auto progress: OFF') end
    if page=='Gear' or page=='Quests' then add(P.CoverageMessage()) end
    if c.class~=P.actualClass then add('Preview profile: scanned gear belongs to your current character.') end
    if level<20 and (page=='Priorities' or page=='Guide') then for _,note in ipairs(P.ClassLevelNotes(level)) do add(note) end end
    if P.deferred or P.scanStale then add('Gear scan needs refreshing before comparing upgrades.') end
    local snap=P.snapshot
    if snap and #snap.errors>0 then add('Some gear could not be read. Use Scan gear to retry.') end
    if (page=='Priorities' or page=='Gear') and P.UIOptions and P.UIOptions().optimization then add(P.OptimizationSummary()) end
    add(' ')
    if page=='Now' then
        for _,line in ipairs(P.NextActionLines(false)) do add(line) end
    elseif page=='Priorities' and (not P.UIOptions or P.UIOptions().leveling) then
        if P.EfficiencyLines then P.StartEfficiencyLoad(); for _,line in ipairs(P.EfficiencyLines(nil,true)) do add(line) end end
        add(' ');add('PERSONALIZED NEXT ACTIONS (gear ownership affects this list)')
        local plan=P.Plan()
        if #plan==0 then add('No outstanding gear actions. Continue nearby leveling quests.') end
        for i,a in ipairs(plan) do if i<=4 then
            add(' '); add(a.title)
            if a.item then local est=P.UpgradeEstimate(a.item); if est.percent then add(P.UpgradeDisplay(est)) end end
        end end
        add(' '); add('Open Gear or Quests for item details; Guide shows the full leveling plan.')
    elseif page=='Guide' and (not P.UIOptions or P.UIOptions().leveling) then
        if P.EfficiencyLines then P.StartEfficiencyLoad();for _,line in ipairs(P.EfficiencyLines()) do add(line) end end
        for _,line in ipairs(P.ProfessionLines(true)) do add(line) end
        add(' '); add('STAGED QUEST / CRAFTING PLAN')
        if c.previewLevel then add('PREVIEW LEVEL '..c.previewLevel..': stage text below is a preview; personalized actions above use actual level.') end
        if stage then
            add(stage.min..'-'..stage.max..': '..P.StageTitle(stage))
            for _,note in ipairs(P.MilestoneNotes(stage)) do add(' '); add(note) end
            add('Hubs: '..(faction=='Alliance' and stage.alliance or faction=='Horde' and stage.horde or 'Faction unknown'))
            for i,t in ipairs(P.Tasks(stage)) do
                add(' '); add((c.done[t.id] and '[DONE] ' or '[ ] ')..i..'. '..t.mode:upper()..': '..t.text)
            end
            add(' '); add('Toggle numbered tasks with buttons below or /rfp done NUMBER.')
            add('Completion is manual; it does not assert quest, crafting or access eligibility.')
        else add('No leveling stage for this level. Supported range: 1-60.') end
    elseif page=='Class quests' then
        for _,line in ipairs(P.ClassQuestLines(false)) do add(line) end
    elseif page=='Sell' then
        for _,line in ipairs(P.SellLines()) do add(line) end
    elseif page=='Professions' then
        for _,line in ipairs(P.ProfessionLines(false)) do add(line) end
    elseif page=='Rating' then
        if P.UIOptions and not P.UIOptions().optimization then add('Gear rating is disabled. Enable it in Settings.') else
            local report=P.OptimizationReport()
            add(P.OptimizationSummary(report))
            add('Weighted-stat ratios include resolved permanent enchants. Main/off hand are compared as one set, weighted as two applicable positions (one for a two-hander). Damage and procs remain outside this stat model.')
            for _,line in ipairs(P.EnchantLines(false)) do add(line) end
            if report.source then add('Reference: '..report.source) end
            if report.shared then add('This profile uses a shared role reference rather than a dedicated spec ranking.') end
            if report.easterEgg then add(' ');add('|cff40e080'..report.easterEgg..'|r') end
            add(' ');add('INCREASE YOUR RATING')
            if #report.recommendations==0 then add(report.percent and 'No measurable increase in the evaluated slots. Unscored slots still require review.' or 'Refresh gear or use a level/profile with comparable source data.') end
            for i,rec in ipairs(report.recommendations) do if i<=5 then
                add(' ');add('|cff40e080'..string.format('+%.1f rating points: ',rec.gainPoints)..'|r'..rec.title)
                add(rec.why)
            end end
            add(' ');add('SLOT BREAKDOWN')
            for _,row in ipairs(report.slots) do add(row.label..': '..(row.certified and 'Matches certified item and enchant' or row.ratio and string.format('%.1f%%',row.ratio*100)..' of the weighted benchmark' or row.reason or 'Unknown')) end
            add(' ');add('Weights are editable in Settings. Skipping targets or changing Solo/Group does not remove their benchmarks. Bags do not count as equipped.')
            if not report.fullBiS then add('Full BiS is not verified. Complete level-60 certified sets are not included in this dataset.') end
        end
    elseif page=='Gear' and (not P.UIOptions or P.UIOptions().gear) then
        local targets=P.Targets(level)
        if #targets==0 then
            add('No verified current-level gear targets in this profile / activity filter. The published references focus on level 30; early-level data is incomplete.')
            for _,note in ipairs(P.ClassLevelNotes(level)) do add(note) end
            for _,note in ipairs(P.UpcomingTargetLines(level)) do add(note) end
            add('Equipped items below are this character inventory, not recommended target items.')
        end
        local selected=P.InspectTarget()
        if selected then add('Inspector: candidate '..P.inspectIndex..' - '..selected.name..'. Use Previous / Next and tooltip buttons below.') end
        local covered={}; for _,g in ipairs(targets) do covered[g.slot]=true end
        add('Page '..(math.floor((P.inspectIndex-1)/6)+1)..' / '..math.max(1,math.ceil(#targets/6))..' | '..#targets..' candidates. Use Page - / Page + below.')
        for index,g in ipairs(targets) do if math.floor((index-1)/6)==math.floor((P.inspectIndex-1)/6) then
            covered[g.slot]=true
            add('Candidate '..index..': '..g.name..' | '..g.mode..' | '..(g.levelNote or ('source wear level '..g.min)))
            add(P.UpgradeDisplay(P.UpgradeEstimate(g)))
            add('State: '..P.CandidateOwned(g)..' | comparison slot '..P.slotNames[g.slot])
            add('Currently equipped: '..itemText(snap and snap.equipped[g.slot]))
            add('Equipped details: '..clean(P.StatSummary(snap and snap.equipped[g.slot] and snap.equipped[g.slot].details)))
            local targetInfo=P.Item(g.id)
            add('Candidate client details: '..clean(P.StatSummary(targetInfo.details)))
            if targetInfo.details and targetInfo.details.minLevel and targetInfo.details.minLevel>g.max then
                add('CONFLICT: cached client requirement exceeds this source window; do not treat this record as an actionable upgrade.')
            elseif targetInfo.details and targetInfo.details.minLevel and targetInfo.details.minLevel>level then
                add('FUTURE ONLY: cached client required level is above your live level; other usability requirements remain unknown.')
            end
            local alternatives=P.BagAlternatives(g.slot)
            add('Carried slot alternatives: '..#alternatives..' (equip-type match only; class/training usability and relative value unknown)')
            for _,alt in ipairs(alternatives) do add('  Bag '..alt.bag..'/'..alt.slot..': '..itemText(alt)..' | '..clean(P.StatSummary(alt.details))) end
            if g.slot==16 then add('Weapon choice: inspect your off-hand too; a two-hand target cannot be valued as an isolated slot upgrade.') end
            local replacement=P.ShortTermReplacement and P.ShortTermReplacement(g)
            if replacement then add(replacement.text); add(replacement.why) end
            add(g.acquire); add(g.materials); add(g.source); add(' ')
        end end
        add('POSITIONS WITHOUT AN ACTIVE TARGET IN THIS DATASET / FILTER')
        for _,slot in ipairs(P.slotOrder) do if not covered[slot] then add(P.slotNames[slot]..': '..itemText(snap and snap.equipped[slot])..' | target data unavailable or filtered') end end
        add('Candidates are not a numeric upgrade calculation. Inspect stats in game before replacing gear.')
        add('Ownership is by exact item ID; no random suffix items or duplicates are scored.')
        add('Coverage is the selected published list; source ranks and stat estimates are not full-set optimization.')
        add('Dataset reviewed '..P.Data.reviewed..'; individual pages label these items confirmed in beta.')
    elseif page=='Quests' then
        add('QUEST REWARDS BASED ON EQUIPPED GEAR AND COMPLETION FLAGS')
        add('Source-linked quest rewards for this profile; QuestieDB supplies known prerequisites when enabled.')
        local rewards=P.QuestRecommendations()
        if #rewards==0 then add('No unfinished reward candidate for your current gear, level and profile. This does not mean every quest is complete.') end
        for index,r in ipairs(rewards) do if index<=5 then
            add(' '); add(r.item.name..' | '..P.UpgradeDisplay(r.estimate)); add('Next: '..r.nextText); add(r.reason); add(r.item.acquire); add(r.item.source)
        end end
        add(P.baselineMessage or 'QuestieDB baseline not initialized.')
        add('Open Quest catalogue below to search the full baseline and track a quest.')
        add('Use Track targets below to pin a reward. Completed one-time quests and owned rewards are excluded from suggestions.')
    elseif page=='Group' then
        add('YOUR GROUP OBJECTIVES - other members unknown; no party sharing in this build.')
        local goals=P.GroupGoals()
        local groups={}
        for _,a in ipairs(goals) do local activity=a.item.activity or 'Other group activity'; groups[activity]=groups[activity] or {}; groups[activity][#groups[activity]+1]=a end
        local names={}; for name in pairs(groups) do names[#names+1]=name end; table.sort(names)
        for _,name in ipairs(names) do add(' '); add(name..': '..#groups[name]..' outstanding sample objectives.')
            for _,a in ipairs(groups[name]) do add(a.title); add(a.why) end end
        add(' '); add('Collect relevant dungeon quests, agree on bosses, role and supplies. Do not interpret wear levels as safe party levels.')
        add('Readiness comes from manual gate declarations. Actual keys, party goals and quest eligibility remain unknown.')
    elseif page=='Preparation' then
        add('PREPARATION FOR MILESTONE '..P.Milestone())
        if faction=='Alliance' then
            add(' '); add('DEFIAS QUEST OBSERVATIONS (source-linked IDs; eligibility unknown)')
            for _,q in ipairs(P.Data.quests or {}) do add(q.id..': '..q.summary..' | '..P.QuestStatus(q.id)) end
        end
        for _,a in ipairs(P.Plan()) do
            if a.item then add(' '); add(a.title); add(a.item.acquire); add(a.item.materials)
                add('Gate: '..(P.profile.gates[tostring(a.item.id)] or 'unknown')..' (manual) | item ID '..a.item.id) end
        end
        add(' '); add('/rfp gate ID ready|blocked|unknown records your manual prerequisite assessment.')
        add('/rfp skip ID toggles a target off/on for this profile; owned and scan warnings remain visible.')
    elseif ((page=='Priorities' or page=='Guide') and P.UIOptions and not P.UIOptions().leveling) or (page=='Gear' and P.UIOptions and not P.UIOptions().gear) then
        add('This feature is disabled. Open Settings to enable it.')
    elseif page=='Inventory' then
        if not snap then add('No scan available.') else
            add('EQUIPPED (shirt and tabard excluded)')
            for _,slot in ipairs(P.slotOrder) do add(P.slotNames[slot]..': '..itemText(snap.equipped[slot])) end
            add(' '); add('CARRIED BAGS (keyring, bank, mail, auction and account storage excluded)')
            for _,it in ipairs(snap.bags) do add('Bag '..it.bag..'/'..it.slot..' x'..tostring(it.count)..': '..itemText(it)) end
            for _,err in ipairs(snap.errors) do add('INCOMPLETE: '..err) end
        end
    else
        add('Guide: ten-level gear-aware planning. Dungeon / XP: one-run versus grinding comparison.')
        add('Commands: /rfp | /rfp scan | /rfp solo | /rfp group')
        add('/rfp profile PRIEST Holy (manual planning profile, not a talent change)')
        add('/rfp current (return to your actual character class and live level)')
        add('/rfp context PvE|PvP | /rfp target 30 | /rfp preview 45 | /rfp preview live')
        add('/rfp gate 253987 ready | /rfp skip 253987')
        add('/rfp done 1 (toggles current visible stage task)')
        add('/rfp retry (retry missing item names once)')
        add('/rfp item ITEMID | /rfp slot SLOTID | /rfp bag BAG SLOT (inspect only, never equip)')
        add('/rfp doctor (capability/scan report; normal reload/logout saves diagnostics)')
        add('Settings/checklists save per character on normal reload/logout.')
        add(' ')
        local _,build,_,interface=GetBuildInfo()
        add('Client build '..tostring(build)..'; interface '..tostring(interface)..'; reference: 70170 / 16001.')
        add('No live-client test has been performed for this prototype.')
        add(' '); add('COVERAGE HISTORY (sample counts, not a combat performance trend)')
        for i=math.max(1,#P.profile.history-9),#P.profile.history do local r=P.profile.history[i]
            add('Level '..r.level..': '..r.equipped..' equipped, '..r.bagged..' carried, '..r.total..' targets | '..r.version)
        end
        add(' ')
        for key,url in pairs(P.Data.sources) do add(key..': '..url) end
    end
    body:SetText(table.concat(lines,'\n'))
    body:SetHeight(math.max(400,body:GetStringHeight()+24))
    content:SetHeight(body:GetHeight())
    local oldScroll=scroll:GetVerticalScroll() or 0
    scroll:SetVerticalScroll(math.min(oldScroll,math.max(0,body:GetHeight()-scroll:GetHeight())))
end
function P.Show()
    if P.activeDialog then P.activeDialog:Hide() end
    if not P.char then print('Ruinous Forever Planner: '..(P.dbError or 'Login is not ready.')); return end
    if not window then
        window=CreateFrame('Frame','RuinousForeverPlannerWindow',UIParent)
        window:SetFrameStrata('DIALOG'); window:SetFrameLevel(100)
        window:SetSize(780,610); window:SetPoint('CENTER'); window:SetClampedToScreen(true)
        window:SetMovable(true); window:EnableMouse(true); window:RegisterForDrag('LeftButton')
        window:SetScript('OnDragStart',window.StartMoving); window:SetScript('OnDragStop',window.StopMovingOrSizing)
        window:SetScript('OnHide',P.HideItemTooltip)
        local bg=window:CreateTexture(nil,'BACKGROUND'); bg:SetAllPoints(); bg:SetColorTexture(0.025,0.035,0.055,1)
        button(window,'Close',660,-8,100,function() window:Hide() end)
        for i,name in ipairs({'Now','Gear','Quests','Guide','Rating','More'}) do
            button(window,name=='More' and 'More v' or name,12+(i-1)*106,-8,102,function(self) if name=='More' then P.ShowProfileMenu('page',self) else page=name;scroll:SetVerticalScroll(0);P.Render() end end)
        end
        button(window,'Settings',12,-512,100,function() P.ShowOptions() end)
        button(window,'Track targets',122,-512,110,function() P.ShowTargets() end)
        button(window,'Quest catalogue',242,-512,130,function() P.ShowQuestBrowser() end)
        button(window,'Page -',382,-512,85,function() P.inspectIndex=math.max(1,P.inspectIndex-6);page='Gear';scroll:SetVerticalScroll(0);P.Render() end)
        button(window,'Page +',477,-512,85,function() P.inspectIndex=P.inspectIndex+6;page='Gear';scroll:SetVerticalScroll(0);P.Render() end)
        P.primaryButton=button(window,'Track top upgrade',572,-512,160,function()
            if page=='Now' then P.PinNextAction();return end
            if page=='Sell' then P.ShowSellEstimates();return end
            if page=='Class quests' then local first=P.ClassQuestPlan().rows[1];if first then P.PinClassQuest(first.quest.id) end;return end
            if page=='Guide' then local first=P.EfficiencyPlan().actions[1];if first then P.PinEfficiencyGoal(first) end;return end
            local first=P.OptimizationReport().recommendations[1]
            if first and first.kind=='enchant' then P.PinEnchantGoal(first);return end
            if first then P.UIOptions();P.profile.tracked[tostring(first.item.id)]=true;if first.partner then P.profile.tracked[tostring(first.partner.id)]=true end;P.UpdateControls() end
        end)
        classButton=button(window,'Class v',12,-40,150,function(self) P.ShowProfileMenu('class',self) end)
        specButton=button(window,'Spec v',170,-40,150,function(self) P.ShowProfileMenu('spec',self) end)
        P.classButton=classButton; P.specButton=specButton
        button(window,'Solo / Group',328,-40,110,function() P.char.mode=P.char.mode=='solo' and 'group' or 'solo'; P.Render() end)
        button(window,'Scan gear',446,-40,90,function() P.Scan(); P.Render() end)
        button(window,'Dungeon / XP',544,-40,115,function() P.ShowDungeonAdvisor() end)
        button(window,'PvE / PvP',667,-40,100,function() P.Context(P.char.context=='PvE' and 'PvP' or 'PvE'); P.Render() end)
        scroll=CreateFrame('ScrollFrame',nil,window,'UIPanelScrollFrameTemplate')
        scroll:SetPoint('TOPLEFT',16,-80); scroll:SetPoint('BOTTOMRIGHT',-36,110)
        local child=CreateFrame('Frame',nil,scroll); child:SetSize(710,400); scroll:SetScrollChild(child)
        content=child
        body=child:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
        body:SetPoint('TOPLEFT'); body:SetWidth(704); body:SetJustifyH('LEFT'); body:SetJustifyV('TOP'); body:SetSpacing(4)
        P.itemControls={}
        local function itemButton(...) local b=button(...);P.itemControls[#P.itemControls+1]=b;return b end
        itemButton(window,'Profession v',662,-574,105,function(self) page='Professions';P.Render();P.ShowProfileMenu('profession',self) end)
        itemButton(window,'Previous item',12,-544,105,function() if page=='Sell' then P.sellIndex=math.max(1,P.sellIndex-1);P.Render();return end;P.inspectIndex=math.max(1,P.inspectIndex-1); P.inspectBagIndex=1; page='Gear'; P.Render() end)
        itemButton(window,'Next item',122,-544,105,function() if page=='Sell' then P.sellIndex=P.sellIndex+1;P.Render();return end;P.inspectIndex=P.inspectIndex+1; P.inspectBagIndex=1; page='Gear'; P.Render() end)
        for _,info in ipairs({{'Target tooltip','target',232,110},{'Equipped tooltip','equipped',352,120},{'Bag tooltip','bag',482,110}}) do
            local b=itemButton(window,info[1],info[3],-544,info[4],function(self) inspect(info[2],self,false) end)
            b:SetScript('OnEnter',function(self) inspect(info[2],self,true) end)
            b:SetScript('OnLeave',P.HideItemTooltip)
        end
        itemButton(window,'Next bag item',602,-544,110,function() P.inspectBagIndex=P.inspectBagIndex+1; local t=P.InspectTarget()
            local list=t and P.BagAlternatives(t.slot) or {}; if P.inspectBagIndex>#list then P.inspectBagIndex=1 end; page='Gear'; P.Render() end)
        for i=1,5 do itemButton(window,'Toggle '..i,12+(i-1)*130,-574,120,function()
            if page=='Sell' then local item=P.SelectedSellItem();if item and i==1 then local e=P.EconomyDB();e.keep[tostring(item.id)]=not e.keep[tostring(item.id)] end;P.Render();return end
            if page=='Professions' then P.ToggleProfessionTask(i);P.Render();return end
            local tasks=P.Tasks(P.Stage(P.ViewLevel())); if tasks[i] then P.Toggle(tasks[i].id) end; P.Render()
        end) end
        P.nowControls={}
        local function nowButton(text,x,y,w,fn) local b=button(window,text,x,y,w,fn);P.nowControls[#P.nowControls+1]=b;return b end
        nowButton('Import route',12,-544,125,P.ShowRouteImport)
        nowButton('Map waypoint',147,-544,125,function()local ok,msg=P.RouteWaypoint();print(msg)end)
        nowButton('Manual next',282,-544,125,function()P.RouteManualNext();P.Render()end)
        nowButton('Undo',417,-544,80,function()P.RouteUndo();P.Render()end)
        P.routeAutoButton=nowButton('Auto progress',507,-544,150,function()if P.char.route then P.char.route.auto=not P.char.route.auto end;P.Render()end)
        nowButton('Launch checks / report',12,-574,220,P.ShowLaunchChecks)
        nowButton('Start XP sample',242,-574,155,function()local ok,msg=P.StartSessionSample();print(msg);P.Render()end)
        nowButton('Finish sample',407,-574,145,function()local ok,msg=P.FinishSessionSample();print(msg);P.Render()end)
    end
    window:Show(); P.Render()
end
local showPlanner=P.Show
function P.HandleUiFailure(err)
    local firstError=not P.lastUiError
    P.uiAttempted=true; P.uiCallSucceeded=false
    if firstError then P.lastUiError=tostring(err):sub(1,500) end
    if window and type(window.Hide)=='function' then pcall(window.Hide,window) end
    if P.CaptureDiagnostics then P.CaptureDiagnostics() end
    if firstError then print('Ruinous Forever Planner could not build or refresh its UI. Use /rfp doctor for the recorded error.') end
end
function P.Show()
    if not P.char then return showPlanner() end
    P.uiAttempted=true
    local ok,err=pcall(showPlanner)
    if ok then
        P.uiCallSucceeded=true; P.lastUiError=nil
        if P.CaptureDiagnostics then P.CaptureDiagnostics() end
    else P.HandleUiFailure(err) end
end
SLASH_RUINOUSFOREVERPLANNER1='/rfp'
SlashCmdList.RUINOUSFOREVERPLANNER=function(msg)
    if not P.char then P.Show(); return end
    local cmd,arg=msg:match('^(%S+)%s*(.-)%s*$')
    cmd=cmd and cmd:lower() or ''
    if cmd=='solo' or cmd=='group' then P.char.mode=cmd
    elseif cmd=='doctor' then P.PrintDiagnostics(); return
    elseif cmd=='scan' then P.Scan()
    elseif cmd=='route' then P.Show();P.ShowRouteImport();return
    elseif cmd=='now' then page='Now'
    elseif cmd=='classquests' then page='Class quests'
    elseif cmd=='classquest' then if not P.PinClassQuest(tonumber(arg)) then print('Use a resolved class quest ID from Class Qs.');return end;page='Class quests'
    elseif cmd=='sell' then page='Sell'
    elseif cmd=='professions' then page='Professions'
    elseif cmd=='current' then P.AutoProfile();P.char.previewLevel=nil;P.Scan()
    elseif cmd=='retry' then P.requested={}; P.Scan()
    elseif cmd=='item' or cmd=='slot' or cmd=='bag' then
        local ref
        if cmd=='item' then ref={mode='target',id=tonumber(arg)}
        elseif cmd=='slot' then ref={mode='equipped',slot=tonumber(arg)}
        else local bag,slot=arg:match('^(%d+)%s+(%d+)$'); ref={mode='bag',bag=tonumber(bag),slot=tonumber(slot)} end
        P.Show()
        local ok,err=P.ItemTooltip(ref,window); if not ok then print('Ruinous Forever Planner: '..err) end
        return
    elseif cmd=='profile' then
        local class,spec=arg:match('^(%S+)%s+(.+)$')
        if not class or not P.Profile(class:upper(),spec) then print('Use /rfp profile CLASS Spec; see Class and Spec buttons.'); return end
    elseif cmd=='context' then
        local context=arg:lower()=='pvp' and 'PvP' or arg:lower()=='pve' and 'PvE'
        if not P.Context(context) then print('Use /rfp context PvE or PvP.'); return end
    elseif cmd=='target' or cmd=='preview' then
        if cmd=='preview' and arg=='live' then P.char.previewLevel=nil
        else
            local n=tonumber(arg)
            if not n or n<1 or n>60 or n~=math.floor(n) then print('Use a whole level from 1 to 60.'); return end
            if cmd=='target' then P.char.targetLevel=n;P.char.manualMilestone=true else P.char.previewLevel=n end
        end
    elseif cmd=='gate' then
        local id,state=arg:match('^(%d+)%s+(%a+)$')
        if not P.Gate(tonumber(id),state) then print('Use /rfp gate ITEMID ready|blocked|unknown for a bundled target.'); return end
    elseif cmd=='skip' then
        local id=tonumber(arg); local valid=false
        for _,g in ipairs(P.TrackableGear()) do if g.id==id then valid=true end end
        if not valid then print('Use a bundled target item ID.'); return end
        P.Skip(id)
    elseif cmd=='done' then
        local tasks=P.Tasks(P.Stage(P.ViewLevel())); local task=tasks[tonumber(arg)]
        if task then P.Toggle(task.id) else print('Use /rfp done NUMBER from the visible priorities.'); return end
    elseif cmd~='' then print('Unknown command. Use /rfp for the planner and Help / Sources.'); return end
    P.Show()
end
