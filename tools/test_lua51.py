"""Execute the same behavioral suite with a native Lua 5.1 runtime (lupa 2.8)."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
assert lua.eval('_VERSION')=='Lua 5.1'
lua.execute(Path('tests/mock.lua').read_text())
loader=lua.eval('function(code, ...) local f,err=loadstring(code); assert(f,err); return f(...) end')
for name in ['Data.lua','SourceData.lua','Catalog.lua','Core.lua','Inspection.lua','EnchantData.lua','Enchants.lua','Upgrades.lua','EquipmentModel.lua','ClassGuidance.lua','AutoProfile.lua','ProfessionData.lua','Professions.lua','Baseline.lua','ClassQuests.lua','SellAdvisor.lua','Quests.lua','Planner.lua','Optimization.lua','EfficiencyData.lua','Efficiency.lua','SessionSample.lua','Route.lua','NextAction.lua','Diagnostics.lua','UI.lua','Controls.lua','ItemTooltips.lua']:
    loader(Path('RuinousForeverPlanner',name).read_text(encoding='utf8'), 'RuinousForeverPlanner', lua.globals().TEST_P)
lua.execute(Path('tests/behavior.lua').read_text())
lua.execute(Path('tests/catalogue.lua').read_text(encoding='utf8'))
lua.execute(Path('tests/optimization.lua').read_text(encoding='utf8'))
lua.execute(Path('tests/tooltips.lua').read_text(encoding='utf-8-sig'))
lua.execute(Path('tests/efficiency.lua').read_text(encoding='utf8'))
lua.execute(Path('tests/enchants_offhands.lua').read_text(encoding='utf8'))
lua.execute(Path('tests/alt_layering.lua').read_text(encoding='utf8'))
lua.execute(Path('tests/professions_profile_loot.lua').read_text(encoding='utf8'))
lua.execute(Path('tests/classquests_sell.lua').read_text(encoding='utf8'))
lua.execute(Path('tests/routes_next.lua').read_text(encoding='utf8'))
if Path('tmp/factoruide-real.rfp').exists():
    parsed=lua.globals().TEST_P.ParseRoute(Path('tmp/factoruide-real.rfp').read_text(encoding='utf8'))
    assert parsed is not None and not isinstance(parsed,tuple) and len(parsed.steps)>0
print('PASS: native Lua 5.1 executed shipped addon and behavioral suite through lupa 2.8; WoW APIs remain mocked')
