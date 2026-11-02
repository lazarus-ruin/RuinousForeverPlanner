from pathlib import Path
js=Path('tools/factoruide_converter.js').read_text(encoding='utf8')
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Ruinous Planner - Factoruide route converter</title>
<style>body{font:17px/1.5 system-ui;background:#102531;color:#e2eff3;max-width:860px;margin:40px auto;padding:0 24px}h1{line-height:1.15}a{color:#8fe1d4}button,input{font:inherit;padding:10px;margin:6px 8px 6px 0}textarea{box-sizing:border-box;width:100%;height:280px;background:#f6fafb;color:#102531;padding:14px}section{padding:20px;background:#203b48;border-radius:12px;margin:20px 0}.status{white-space:pre-wrap}small{color:#b8ced5}</style>
<h1>Bring a Factoruide route into<br>Ruinous Forever Planner</h1>
<p>Everything here runs locally. No uploads, accounts or external scripts.</p>
<section><ol><li>Generate a single-character <b>WoW Forever</b> guide in <a href="https://factoruide.brouznouf.com/" target="_blank" rel="noopener">Factoruide</a>.</li><li>Use its Share/export option to save a <b>.fgguide file</b>. This converter accepts JSON files, not FGG1 compressed import strings.</li><li>Select the file below. Copy the converted text, then open <b>/rfp route</b> in WoW and paste it into Import route.</li></ol><input id="file" type="file" accept=".fgguide,.json"><div id="status" class="status" role="status">No file selected.</div></section>
<textarea id="output" readonly aria-label="Converted route text"></textarea><button id="copy" disabled>Copy route text</button><button id="save" disabled>Save converted text</button>
<p><b>Advice-only compatibility:</b> ordered quest steps and destination coordinates are retained. Automatic progress is limited to observed quest flags/objectives. Travel, training, purchases and unsupported conditions require manual confirmation. No route simulation or pathfinder is included. Verify quests and destinations in the launch client.</p>
<small>Factoruide is an independent project. Format reviewed October 30, 2026. No upstream guide is bundled as a universally valid leveling route.</small>
<script>'''+js+'''
const file=document.getElementById('file'),out=document.getElementById('output'),status=document.getElementById('status'),copy=document.getElementById('copy'),save=document.getElementById('save');
file.addEventListener('change',async()=>{copy.disabled=save.disabled=true;out.value='';try{const f=file.files[0];if(!f)return;if(f.size>8000000)throw Error('File exceeds 8 MB.');const r=RFPConverter.convert(await f.text());out.value=r.text;status.textContent=r.name+' - '+r.steps+' steps converted.\\n'+r.warnings.join('\\n');copy.disabled=save.disabled=false;}catch(e){status.textContent='Could not convert: '+e.message;}});
copy.addEventListener('click',async()=>{out.focus();out.select();try{await navigator.clipboard.writeText(out.value);status.textContent='Copied. Paste in the planner Import route dialog.';}catch(e){status.textContent='Text selected. Press Ctrl+C, then paste into the planner.';}});
save.addEventListener('click',()=>{const a=document.createElement('a');const url=URL.createObjectURL(new Blob([out.value],{type:'text/plain'}));a.href=url;a.download='ruinous-route.txt';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);});
</script></html>'''
Path('RuinousForeverPlanner/ROUTE-CONVERTER.html').write_text(html,encoding='utf8')
print('Built local data-only route converter')
