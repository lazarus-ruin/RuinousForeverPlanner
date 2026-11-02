local _,P=...
local function exists(namespace,name)
    return type(namespace)=='table' and type(namespace[name])=='function'
end
function P.CaptureDiagnostics()
    if not P.char then return nil end
    local report={addonVersion=P.Data.version,referenceBuild='70170',referenceInterface=16001,
        uiAttempted=P.uiAttempted==true,uiCallSucceeded=P.uiCallSucceeded==true,
        uiError=P.lastUiError,actualClass=P.actualClass,selectedClass=P.char.class,selectedSpec=P.char.spec,actualLevel=P.Safe(UnitLevel,'player'),classPreview=P.char.class~=P.actualClass,visualLayoutVerified=false,routeStep=P.char.route and P.char.route.index,routeSteps=P.char.route and #P.char.route.steps,routeSource=P.char.route and P.char.route.source,routeAuto=P.char.route and P.char.route.auto,questBaseline=P.baselineMessage,sourceCatalogue=P.SourceData and {lists=38,items=634,profileContexts=60} or nil,combatDeferred=P.deferred==true,
        api={GetBuildInfo=type(GetBuildInfo)=='function',CreateFrame=type(CreateFrame)=='function',
            GetInventoryItemID=type(GetInventoryItemID)=='function',GetInventoryItemLink=type(GetInventoryItemLink)=='function',
            ItemInfo=exists(C_Item,'GetItemInfo'),ItemStats=exists(C_Item,'GetItemStats'),ItemRequest=exists(C_Item,'RequestLoadItemDataByID'),
            BagSlots=exists(C_Container,'GetContainerNumSlots'),BagInfo=exists(C_Container,'GetContainerItemInfo'),
            QuestCompleted=exists(C_QuestLog,'IsQuestFlaggedCompleted'),QuestInLog=exists(C_QuestLog,'IsOnQuest')}}
    if type(GetBuildInfo)=='function' then
        local ok,version,build,date,interface=pcall(GetBuildInfo)
        if ok then
            if type(issecretvalue)~='function' or not issecretvalue(version) then report.clientVersion=type(version)=='string' and version or nil end
            if type(issecretvalue)~='function' or not issecretvalue(build) then report.clientBuild=type(build)=='string' and build or nil end
            if type(issecretvalue)~='function' or not issecretvalue(interface) then report.clientInterface=type(interface)=='number' and interface or nil end
        end
    end
    local snap=P.snapshot
    if snap then
        local equipped=0; for _ in pairs(snap.equipped) do equipped=equipped+1 end
        report.scan={equippedCount=equipped,bagItemCount=#snap.bags,pendingNameCount=snap.pending,errorCount=#snap.errors,errors={}}
        for i=1,math.min(10,#snap.errors) do report.scan.errors[i]=snap.errors[i] end
    end
    -- Counts/capabilities only: no persistent inventory links, gear stats or quest log.
    P.char.diagnostics=report
    return report
end
function P.PrintDiagnostics()
    local r=P.CaptureDiagnostics()
    if not r then print('Ruinous Forever Planner: diagnostics unavailable before character settings load.'); return end
    print('Ruinous Forever Planner '..r.addonVersion..' | client '..tostring(r.clientBuild or 'unknown')..' | interface '..tostring(r.clientInterface or 'unknown'))
    local missing={}; for name,available in pairs(r.api) do if not available then missing[#missing+1]=name end end; table.sort(missing)
    print('Missing API capabilities: '..(#missing==0 and 'none detected' or table.concat(missing,', ')))
    if r.scan then print('Scan counts: '..r.scan.equippedCount..' equipped, '..r.scan.bagItemCount..' carried, '..r.scan.pendingNameCount..' pending names, '..r.scan.errorCount..' errors.') end
    print('Planner UI: '..(r.uiAttempted and (r.uiCallSucceeded and 'last build/render call completed' or 'last call failed') or 'not opened yet')..'; visual correctness is not established by this report.')
    if r.uiError then print('First planner UI error since last successful open: '..r.uiError) end
    print('Diagnostics save with normal /reload or logout. No automatic restart, reload or gameplay action is performed.')
end
