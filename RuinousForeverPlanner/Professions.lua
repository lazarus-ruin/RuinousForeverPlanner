local _,P=...
-- Read-only planner: no crafting, purchasing or profession changes.
local function public(v) return not (type(issecretvalue)=='function' and issecretvalue(v)) end
function P.ReadProfessions()
    local found={}
    if type(GetProfessions)~='function' or type(GetProfessionInfo)~='function' then return found,'Profession API unavailable; browse guides as previews.' end
    local values={pcall(GetProfessions)}
    if not values[1] then return found,'Profession scan failed; browse guides as previews.' end
    -- Six fixed return positions, including nil gaps for unlearned secondary skills.
    for i=2,7 do
        local index=values[i]
        if public(index) and type(index)=='number' then
            local ok,name,icon,skill,cap,abilities,offset,id=pcall(GetProfessionInfo,index)
            if ok and public(id) and public(skill) and public(cap) and type(id)=='number' and type(skill)=='number' and type(cap)=='number' and skill>=0 and cap>0 then
                found[id]={skill=skill,cap=cap}
            end
        end
    end
    if next(found) then return found end
    return found,'No readable learned professions. Preview guides do not assert that you know a profession.'
end
function P.ProfessionSelection()
    local found,warning=P.ReadProfessions()
    local id=P.char and P.char.professionGuide
    if not P.ProfessionData[id] then
        for _,key in ipairs(P.ProfessionOrder) do if found[key] then id=key;break end end
        id=id or 197
    end
    return id,found,warning
end
function P.ProfessionActions(id,skill)
    local d=P.ProfessionData[id];local rows={}
    if not d then return rows end
    for _,r in ipairs(d.steps) do if not skill or skill<r.to then rows[#rows+1]=r end end
    return rows
end
function P.ToggleProfessionTask(n)
    if not P.char then return end
    local id,found=P.ProfessionSelection();local rows=P.ProfessionActions(id,found[id] and found[id].skill)
    local row=rows[n];if row then P.Toggle('profession:'..id..':'..row.from..':'..row.to) end
end
function P.ProfessionLines(compact)
    if not P.char then return {} end
    if P.UIOptions and not P.UIOptions().professions then return compact and {} or {'Profession recommendations disabled. Enable them in Settings.'} end
    local id,found,warning=P.ProfessionSelection();local d=P.ProfessionData[id]
    local level=P.Safe(UnitLevel,'player') or 1
    local lines={'PROFESSIONS + XP | levels '..level..'-'..math.min(60,level+10)}
    lines[#lines+1]='Time priority: gather on your quest path; batch crafts and training during town visits. Defer dedicated farming unless a useful craft justifies the detour.'
    if warning then lines[#lines+1]=warning end
    if compact then
        for _,key in ipairs(P.ProfessionOrder) do local live=found[key];if live then
            local data=P.ProfessionData[key];local rows=P.ProfessionActions(key,live.skill)
            lines[#lines+1]=data.name..' '..live.skill..'/'..live.cap..': '..(live.skill>=live.cap and 'At trained cap: check next-rank requirements before gathering/crafting.' or rows[1] and rows[1].text or 'Route complete; inspect useful recipes.')
        end end
        lines[#lines+1]='Open Professions for skill routes, prerequisites, gear uses and manual checklists.'
        return lines
    end
    local live=found[id];local skill=live and live.skill
    lines[#lines+1]=d.name..(live and (' | learned '..skill..'/'..live.cap) or ' | PREVIEW: not detected as learned')
    lines[#lines+1]='Gear / supplies: '..d.use
    lines[#lines+1]='Preparation: '..d.prep
    lines[#lines+1]='Training: '..d.training
    if live and skill>=live.cap then lines[#lines+1]='TRAINED CAP REACHED. Further crafts may give no skill: verify the next rank first.' end
    if level<20 then lines[#lines+1]='Levels 1-19: keep initial supplies affordable; do not sacrifice essential class training for skill points.'
    elseif level<40 then lines[#lines+1]='Levels 20-39: compare nearby crafts with current gear and next-ten-level quest rewards. Reserve travel/training gold.'
    elseif level<55 then lines[#lines+1]='Levels 40-54: avoid expensive temporary crafts when a nearby leveling reward replaces them soon.'
    else lines[#lines+1]='Levels 55-60: plan long-lived crafts with your group; verify recipes, reputation, specialization and materials before farming.' end
    lines[#lines+1]='Solo: collect materials during normal quests. Group: coordinate crafters and dungeon materials before a run; a recipe/drop is never guaranteed.'
    lines[#lines+1]='Compare crafted items using their tooltips/Gear rating. These routes do not claim an unscanned craft is an upgrade or estimate auction prices.'
    lines[#lines+1]='SKILL ROUTE (skill points, not character levels) | first five remaining steps have Toggle buttons'
    local rows=P.ProfessionActions(id,skill)
    for i,r in ipairs(rows) do
        local key='profession:'..id..':'..r.from..':'..r.to
        lines[#lines+1]=(P.char.done[key] and '[DONE] ' or '[ ] ')..i..'. '..r.from..'-'..r.to..': '..r.text..(r.from>=225 and ' [LATE BETA / UNTESTED]' or '')
    end
    if #rows==0 then lines[#lines+1]='Bundled route complete. Check useful learned recipes and remaining data gaps.' end
    lines[#lines+1]='Completion is manual. Skill gains, recipes known, material quantities and trainer eligibility are not automatically verified. Yellow/green crafts may need repeats.'
    lines[#lines+1]='Coverage: '..d.coverage..' | reviewed 2026-10-21. No live client acceptance test.'
    lines[#lines+1]='Source: '..d.source
    lines[#lines+1]='Use Choose profession for a dropdown; previews never learn/unlearn professions.'
    return lines
end
