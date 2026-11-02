"""Render the bundled usage guide as a standalone, offline HTML document."""
from pathlib import Path
import html,re
source=Path('RuinousForeverPlanner/USAGE_GUIDE.md').read_text(encoding='utf8')
def inline(text):
 text=html.escape(text)
 text=re.sub(r'`([^`]+)`',r'<code>\1</code>',text)
 text=re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',text)
 text=re.sub(r'(https://[^\s<]+)',lambda m:'<a href="'+m[1].rstrip('.')+'">'+m[1].rstrip('.')+'</a>'+('.' if m[1].endswith('.') else ''),text)
 return text
parts=[];toc=[];paragraph=[];listing=None

def flush():
 if paragraph:parts.append('<p>'+inline(' '.join(paragraph))+'</p>');paragraph.clear()
def close_list():
 global listing
 if listing:parts.append('</'+listing+'>');listing=None
for line in source.splitlines():
 if not line.strip():flush();close_list();continue
 if line.startswith('#'):
  flush();close_list();level=len(line)-len(line.lstrip('#'));text=line[level:].strip();ident=re.sub(r'[^a-z0-9]+','-',text.lower()).strip('-')
  parts.append(f'<h{level} id="{ident}">{inline(text)}</h{level}>')
  if level==2:toc.append('<a href="#'+ident+'">'+html.escape(text)+'</a>')
 elif re.match(r'^\d+\. ',line):
  flush()
  if listing!='ol':close_list();listing='ol';parts.append('<ol>')
  parts.append('<li>'+inline(re.sub(r'^\d+\. ','',line))+'</li>')
 else:close_list();paragraph.append(line)
flush();close_list()
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Ruinous Forever Planner — Start Here</title><style>
:root{color-scheme:light}body{margin:0;background:#f2f5f8;color:#1e2b38;font:16px/1.65 system-ui,Segoe UI,sans-serif}header{background:#102b40;color:white;padding:28px max(24px,calc((100vw - 1100px)/2));font-size:22px;font-weight:700}header small{display:block;font-size:14px;font-weight:400;color:#c9deee}.layout{display:grid;grid-template-columns:250px minmax(0,820px);gap:32px;max-width:1100px;margin:32px auto;padding:0 24px}nav{position:sticky;top:20px;align-self:start;max-height:90vh;overflow:auto;font-size:14px}nav a{display:block;padding:6px 8px;text-decoration:none;color:#165c7c;border-left:2px solid #d5e2eb}nav a:hover{background:#e0eaf0}main{padding:28px 40px;background:white;border:1px solid #dbe5ec;border-radius:12px}h1{font-size:30px;line-height:1.2}h2{font-size:22px;line-height:1.35;margin-top:40px;color:#154d6b;scroll-margin-top:20px}code{font:14px ui-monospace,Consolas,monospace;background:#eef3f7;padding:2px 5px;border-radius:4px}a{color:#12628b;overflow-wrap:anywhere}li{margin-bottom:10px}p{margin:14px 0}.legend{padding:14px 18px;background:#eef7f3;border-left:4px solid #248457}.up{color:#167443}.down{color:#b82432}@media(max-width:850px){.layout{display:block}nav{position:static;max-height:none;margin-bottom:24px}main{padding:22px}}@media print{header,nav{display:none}.layout{display:block;margin:0;max-width:none;padding:0}main{border:0;padding:0}h2{break-after:avoid}li{break-inside:avoid}a{color:inherit}body{background:white}}
</style><header>Ruinous Forever Planner<small>Start Here · Offline usage guide · v0.22</small></header><div class="layout"><nav aria-label="Guide contents">'''+''.join(toc)+'''</nav><main><div class="legend"><strong>Quick start:</strong> Enable Ruinous Forever Planner and QuestieDB, open <code>/rfp</code>, verify your detected class/spec, and click Scan gear. <span class="up">Positive upgrades are green</span>; <span class="down">negative upgrades are red</span>. Read rating coverage before the percentage.</div>'''+''.join(parts)+'</main></div></html>'
Path('RuinousForeverPlanner/START-HERE.html').write_text(page,encoding='utf8')
assert len(toc)==20
assert '<script' not in page and 'https://fonts' not in page
print('Built standalone HTML guide with',len(toc),'feature sections')
