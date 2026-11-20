"""Verify and index raw campus drafts in the explicitly requested delivery folder."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DELIVERY = Path(r'C:\Users\khant\Downloads\mecharpg')
DATE = '20261118'


def main():
    pieces = json.loads((Path(__file__).with_name('campus_draft_manifest_source.json')).read_text())
    records = []
    for piece in pieces:
        name = piece['piece']
        versions = sorted(DELIVERY.glob(f'{name}_{DATE}_[0-9][0-9].png'))
        if not versions:
            raise RuntimeError(f'Missing requested image: {name}')
        path = versions[-1]
        prompt = path.with_name(path.stem + '_prompt.txt')
        assert prompt.exists() and prompt.stat().st_size > 0, f'Missing prompt: {path.name}'
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            size = list(image.size)
            corner = list(image.convert('RGBA').getpixel((0, 0)))
        canonical_prompt = DELIVERY / f'{name}_{DATE}_prompt.txt'
        if not canonical_prompt.exists():
            shutil.copyfile(prompt, canonical_prompt)
        records.append({**piece, 'file': path.name, 'prompt': prompt.name,
                        'size': size, 'corner_rgba': corner,
                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                        'status': 'raw_draft_needs_cleanup_and_review',
                        'other_attempts': [p.name for p in versions[:-1]]})
    assert len(records) == 35
    report = {
        'date': DATE, 'requested_piece_count': 35, 'verified_piece_count': len(records),
        'generator': 'Built-in image_gen',
        'production_ready': False, 'godot_import_tested': False,
        'documents_read': ['AGENTS.md', 'framework.md', 'CampusArt.md', 'BuildingList.md',
                           'GameConcept.md', 'reference/art_handoff.md'],
        'known_rejected_attempts': {
            f'padauk_tree_{DATE}_01.png': 'Wrong subject: generated a building. Use _02.',
            f'tile_training_surface_01_{DATE}_01.png': 'Unwanted walls. Use _02.'},
        'cleanup_required': ['Remove green background, including holes and edge spill.',
                             'Fit documented footprint and exact canvas.',
                             'Rebuild a consistent native pixel grid; reduce to locked 56-color palette.',
                             'Correct geometry, stray pixels and oversized details by hand.',
                             'Separate roof, doors and emission layers; place markers.',
                             'Remove baked-in window illumination from base layers.',
                             'Review local motifs and remove excessive ornament where inappropriate.',
                             'Tile drafts need simplification; hedge/flower drafts have unwanted raised landscaping.',
                             'Complete player walk/idle test and validate in Godot before production assets.'],
        'pieces': records}
    report_path = DELIVERY / f'campus_batch_{DATE}_manifest.json'
    if report_path.exists():
        raise FileExistsError(report_path)
    report_path.write_text(json.dumps(report, indent=2), encoding='utf-8')
    lines = ['Campus drafts: 35 requested pieces', '',
             'Raw AI art for selection and cleanup, not game-ready sprites.',
             'The existing three native tiles have not been changed.',
             'Prompts are saved beside every image. No copyrighted game/artist names were used.',
             'Two rejected attempts are retained; use padauk_tree _02 and tile_training_surface_01 _02.',
             '', 'Latest drafts:']
    lines.extend(f"{r['order']:02}. {r['file']}" for r in records)
    lines.extend(['', 'Still required:'] + ['- '+s for s in report['cleanup_required']])
    readme = DELIVERY / f'campus_batch_{DATE}_readme.txt'
    if readme.exists():
        raise FileExistsError(readme)
    readme.write_text('\n'.join(lines)+'\n', encoding='utf-8')
    print(f'Verified {len(records)} requested PNGs and all matching prompts.')
    print(report_path)
    print(readme)


if __name__ == '__main__':
    main()
