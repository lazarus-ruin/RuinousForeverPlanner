local _,P=...
local function valid(n) return type(n)=='number' and n==n and n>=0 and n<1e12 end
function P.StartSessionSample()
    local now,level,xp,max=P.Safe(GetTime),P.Safe(UnitLevel,'player'),P.Safe(UnitXP,'player'),P.Safe(UnitXPMax,'player')
    if not P.char or not valid(now) or not valid(level) or level>=60 or not valid(xp) or not valid(max) or max<=0 then return false,'Session XP/time unavailable, or level 60 reached.' end
    P.sessionSample={started=now,level=level,startLevel=level,xp=xp,max=max,gained=0,route=P.char.route,index=P.char.route and P.char.route.index}
    return true,'Session sample started. ALL XP counts, including quests, rested bonuses and dungeons. Reloading cancels the active sample.'
end
function P.RecordSessionSample()
    local s=P.sessionSample;if not s or s.error then return end
    local level,xp,max=P.Safe(UnitLevel,'player'),P.Safe(UnitXP,'player'),P.Safe(UnitXPMax,'player')
    if not valid(level) or not valid(xp) or not valid(max) then s.error='Missing XP observations; restart the sample.';return end
    local gain
    if level==s.level and xp>=s.xp then gain=xp-s.xp
    elseif level==s.level+1 then gain=s.max-s.xp+xp
    else s.error='Unresolved level transition; restart the sample.';return end
    s.gained=s.gained+gain;s.level=level;s.xp=xp;s.max=max
end
function P.FinishSessionSample()
    local s=P.sessionSample;if not s then return false,'Start a session sample first.' end
    P.RecordSessionSample();if s.error then return false,s.error end
    local now=P.Safe(GetTime);local seconds=valid(now) and now-s.started
    if not seconds or seconds<60 then return false,'Record at least 60 seconds before finishing.' end
    local row={seconds=seconds,xp=s.gained,level=s.level,startLevel=s.startLevel,rate=s.gained*3600/seconds}
    if s.route and s.route==P.char.route then row.routeSteps=math.max(0,s.route.index-s.index);row.routeName=s.route.name end
    P.char.sessionSamples=P.char.sessionSamples or {};table.insert(P.char.sessionSamples,1,row)
    while #P.char.sessionSamples>20 do table.remove(P.char.sessionSamples) end
    P.sessionSample=nil
    return true,string.format('Observed %.0f XP/hour: %d XP in %.1f minutes. Includes all XP; not a grinding-only baseline.',row.rate,row.xp,row.seconds/60)
end
