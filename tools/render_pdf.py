from pathlib import Path
import pypdfium2 as pdfium
from PIL import Image, ImageOps, ImageDraw
p=pdfium.PdfDocument('output/pdf/Ruinous-Forever-Planner-PRD-v0.22.pdf')
dest=Path('tmp/pdfs'); dest.mkdir(parents=True,exist_ok=True)
thumbs=[]
for i in range(len(p)):
    page=p[i]; img=page.render(scale=1.1).to_pil().convert('RGB'); img.save(dest/f'page-{i+1:02d}.png')
    thumb=img.copy(); thumb.thumbnail((248,351)); tile=Image.new('RGB',(268,381),'#cbd5df'); tile.paste(thumb,(10,10)); ImageDraw.Draw(tile).text((12,363),str(i+1),fill='black'); thumbs.append(tile)
    text=page.get_textpage().get_text_range()
    print(i+1,len(text),text[:95].replace('\r',' ').replace('\n',' '))
for start in range(0,len(thumbs),8):
    group=thumbs[start:start+8]; sheet=Image.new('RGB',(4*268,2*381),'white')
    for j,t in enumerate(group): sheet.paste(t,((j%4)*268,(j//4)*381))
    sheet.save(dest/f'contact-{start//8+1}.png')
print('Rendered',len(p),'pages')
