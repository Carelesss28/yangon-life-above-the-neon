"""Convert the extracted PDF reference to readable Markdown without changing its decisions."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'tmp/pdfs/yust_source.txt').read_text(encoding='utf-8')
target = ROOT / 'Yangon_YUST_Game_Concept_and_Development_Plan.md'


def table_paragraph(value):
    lines = [line for line in value.splitlines() if line.strip()]
    return bool(lines) and all(line.startswith('  ') for line in lines)


def render_table(paragraphs):
    header_lines = paragraphs[0].splitlines()
    candidates = [list(re.finditer(r'\S.*?(?= {3,}|$)', line)) for line in header_lines]
    matches = max(candidates, key=len)
    starts = [m.start() for m in matches]
    if len(starts) < 2:
        return ['```text', '\n\n'.join(paragraphs).rstrip(), '```', '']
    rows = []
    for paragraph in paragraphs:
        cells = [[] for _ in starts]
        for line in paragraph.splitlines():
            for i,start in enumerate(starts):
                value = line[start:starts[i+1] if i+1<len(starts) else None].strip()
                if value:
                    cells[i].append(value)
        rows.append([' '.join(cell).replace('|','\\|') for cell in cells])
    result = ['| '+' | '.join(rows[0])+' |', '| '+' | '.join('---' for _ in starts)+' |']
    result.extend('| '+' | '.join(row)+' |' for row in rows[1:])
    return result+['']


def render_paragraph(paragraph):
    lines = [line.strip() for line in paragraph.splitlines() if line.strip()]
    if any(line.startswith('• ') for line in lines):
        return [re.sub(r'^• ', '- ', ' '.join(lines)), '']
    text = ' '.join(lines)
    if len(lines)==1 and len(text)<95 and not re.search(r'[.!?:;]$',text) and not text.startswith(('CONFIRMED','PROPOSED','OPEN')):
        return ['### '+text, '']
    return [text, '']


out = ['# YANGON: Life above the neon', '',
       'Game Concept and Development Plan - PDF reference conversion', '',
       '**Source:** version 1.0, 18 November 2026; cover plus 25 numbered content pages.', '',
       '[Original PDF](<C:/Users/khant/Downloads/Yangon_YUST_Game_Concept_and_Development_Plan.pdf>)', '',
       '> This is the original planning reference, not a new set of instructions or a replacement for current project decisions. Its CONFIRMED, PROPOSED and OPEN distinctions are retained. The PDF originally described pixel art and left the engine/camera open. The current project has subsequently chosen Godot 4, 3D models and a fixed high camera; see [GameConcept.md](GameConcept.md), [framework.md](framework.md) and [FirstDistrict.md](FirstDistrict.md). The final title and YUST name/acronym remain provisional.', '',
       'The cover subtitle is editorial; the reference image supplied by the user is a mood reference, not an approved production asset.', '',
       '![User-supplied rooftop café mood reference, extracted from the PDF](docs/yust_pdf_reference/rooftop_cafe_mood_reference.png)', '', '---', '']
section_count = 0
for part in re.split(r'(?=--- PAGE \d+ ---)',source):
    match = re.match(r'--- PAGE (\d+) ---',part)
    if not match or int(match[1])==1:
        continue
    lines = part.splitlines()[1:]
    lines = [line.rstrip() for line in lines if not line.lstrip().startswith('YANGON / YUST')]
    while lines and not lines[0].strip():lines.pop(0)
    section = lines.pop(0).strip()
    while lines and not lines[0].strip():lines.pop(0)
    title = lines.pop(0).strip()
    section_count += 1
    out.extend([f'## {section_count:02}. {title}', '', f'*{section}; PDF printed page {section_count:02} / 25.*', ''])
    paragraphs = [p for p in re.split(r'\n\s*\n','\n'.join(lines)) if p.strip()]
    i=0
    while i<len(paragraphs):
        if table_paragraph(paragraphs[i]):
            group=[]
            while i<len(paragraphs) and table_paragraph(paragraphs[i]):
                group.append(paragraphs[i]);i+=1
            out.extend(render_table(group))
        else:
            out.extend(render_paragraph(paragraphs[i]));i+=1
    out.extend(['---',''])
assert section_count==25
if target.exists():raise FileExistsError(target)
target.write_text('\n'.join(out),encoding='utf-8')
print(f'Converted {section_count} content sections: {target.name}')
