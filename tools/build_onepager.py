from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from pypdf import PdfReader
import pypdfium2 as pdfium

out = Path('output/pdf/Ruinous-Forever-Planner-Player-Overview-v0.20.pdf')
out.parent.mkdir(parents=True, exist_ok=True)
c = canvas.Canvas(str(out), pagesize=(612, 792))
c.setTitle('Ruinous Forever Planner - Player Overview v0.20')
c.setAuthor('Ruinous Forever Planner')
navy = HexColor('#142838')
teal = HexColor('#116e73')
gold = HexColor('#e3bb63')
ink = HexColor('#233947')
muted = HexColor('#526773')

def text(x, y, value, size=10, color=ink, font='Helvetica'):
    c.setFillColor(color)
    c.setFont(font, size)
    c.drawString(x, y, value)

def para(x, top, width, value, size=10.2, leading=14, color=ink, max_height=80):
    p = Paragraph(value, ParagraphStyle('p', fontName='Helvetica', fontSize=size,
                  leading=leading, textColor=color))
    w, h = p.wrap(width, max_height)
    assert h <= max_height, (value, h, max_height)
    p.drawOn(c, x, top-h)

c.setFillColor(navy)
c.rect(0, 640, 612, 152, fill=1, stroke=0)
c.setFillColor(gold)
c.rect(42, 747, 30, 3, fill=1, stroke=0)
text(82, 744, 'BUILT FOR WOW FOREVER PLAYERS', 9, gold, 'Helvetica-Bold')
text(42, 704, 'Ruinous Forever Planner', 28, white, 'Helvetica-Bold')
para(42, 682, 520, 'Know what to work on next.<br/>Connect your gear, quests, leveling and professions in one place.',
     12, 17, HexColor('#d9e9ed'), 38)

text(42, 610, 'Spend less time comparing. Make your next session count.', 14, teal, 'Helvetica-Bold')
para(42, 590, 528, 'Use your current equipment, level and known quest progress to choose useful goals, '
     'avoid unnecessary farms and weigh an upgrade against simply continuing to level.', 10.5, 14, ink, 30)

cards = [
    ('01', 'Find meaningful upgrades',
     'Scans equipped and bag gear. Shows estimated upgrade percentages, green gains and red losses, '
     'plus a partial optimization rating. Includes resolved enchants and main/off-hand comparisons.'),
    ('02', 'Choose useful quests',
     'Suggests gear-related quest goals using your equipment and known completion. Connects to installed '
     'QuestieDB for a broader quest catalogue and prerequisite checks.'),
    ('03', 'Plan the next 10 levels',
     'Combines leveling priorities with gear opportunities and Solo/Group choices. Can suggest leveling '
     'first when a supported nearby reward makes a costly temporary upgrade poor value.'),
    ('04', 'Decide whether to dungeon',
     'Review five-player dungeon quests and reward references. Compare an estimated prepared run '
     'against your measured grinding XP rate, including travel and group wait time.'),
    ('05', 'Level professions along the way',
     'Browse 12 standard profession guides, scanned skill/cap progress and saved checklists. '
     'Coordinate useful crafts, supplies and gathering with XP leveling; incomplete routes are labeled.'),
    ('06', 'Keep your goals visible',
     'Pin gear and quest objectives to a floating tracker. Inspect item comparisons in supported '
     'auction, loot and bag tooltips. Use the minimap button and settings to control features.'),
]
for i, (number, title, body) in enumerate(cards):
    x = 42 + (i % 2)*271
    y = 452 - (i // 2)*112
    c.setFillColor(HexColor('#f2f6f7'))
    c.roundRect(x, y, 257, 103, 7, fill=1, stroke=0)
    text(x+13, y+81, number, 9, teal, 'Helvetica-Bold')
    text(x+36, y+81, title, 11.6, navy, 'Helvetica-Bold')
    para(x+13, y+67, 231, body, 9.8, 13, ink, 56)

c.setFillColor(teal)
c.roundRect(42, 127, 528, 78, 7, fill=1, stroke=0)
text(56, 184, 'GET STARTED', 10, white, 'Helvetica-Bold')
para(56, 174, 500, 'Open <b>/rfp</b> or click the minimap button. Verify your detected class/spec, choose '
     'Solo or Group, then <b>Scan gear</b>. Open Priorities and pin a useful next goal. '
     'If active spec detection is unavailable, the addon labels its class-specific fallback.',
     10, 13.5, white, 45)

text(42, 105, 'READ THE COVERAGE WITH THE RECOMMENDATION', 8.8, teal, 'Helvetica-Bold')
para(42, 94, 528, 'Current gear references concentrate on level 30. Level 1-60 and profession routes '
     'have labeled gaps. Ratings are stat estimates, not simulated combat performance or proof of full BiS. '
     'This guild test build offers advice; it does not play your character.', 9, 12, muted, 40)
c.setStrokeColor(HexColor('#dbe4e7'))
c.line(42, 42, 570, 42)
text(42, 27, 'RUINOUS FOREVER PLANNER', 8, muted, 'Helvetica-Bold')
text(340, 27, 'v0.20.0  |  Guild test build  |  October 21, 2026', 8, muted)
c.showPage()
c.save()
reader = PdfReader(out)
assert len(reader.pages) == 1
assert all(s in reader.pages[0].extract_text() for s in ['12 standard', '10 levels', '/rfp', 'level 30'])
preview = Path('tmp/pdfs/player-overview-v0.20.png')
doc = pdfium.PdfDocument(str(out))
doc[0].render(scale=1.8).to_pil().save(preview)
print(f'Created and rendered one-page PDF: {out}')
