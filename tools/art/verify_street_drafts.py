"""Index the second set of 35 raw drafts; preserve all previous deliveries."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

DELIVERY = Path(r'C:\Users\khant\Downloads\mecharpg')
DATE = '20261118'


def main():
    pieces = json.loads(Path(__file__).with_name('street_draft_manifest_source.json').read_text())
    records = []
    for piece in pieces:
        name = piece['piece']
        versions = sorted(DELIVERY.glob(f'{name}_{DATE}_[0-9][0-9].png'))
        if not versions:
            raise RuntimeError(f'Missing draft: {name}')
        path = versions[-1]
        prompt = path.with_name(path.stem + '_prompt.txt')
        assert prompt.exists() and prompt.stat().st_size > 0
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            size = list(image.size)
        canonical_prompt = DELIVERY / f'{name}_{DATE}_prompt.txt'
        if not canonical_prompt.exists():
            shutil.copyfile(prompt, canonical_prompt)
        records.append({**piece, 'file': path.name, 'prompt': prompt.name,
                        'size': size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                        'status': 'raw_draft_needs_cleanup_and_review',
                        'other_attempts': [p.name for p in versions[:-1]]})
    assert len(records) == 35
    report = {
        'date': DATE, 'batch': 'street_and_concrete_kit',
        'requested_piece_count': 35, 'verified_piece_count': len(records),
        'generator': 'Built-in image_gen', 'production_ready': False,
        'godot_import_tested': False,
        'scope': '7 street buildings/stalls, 4 empty interior shells, 24 modular kit drafts.',
        'notes': ['Green backgrounds are intentional for the raw draft collection pipeline.',
                  'Room footprint suggestions in prompts are provisional; BuildingList.md does not specify interior sizes.',
                  'Kit pieces require native-grid reconstruction, shared scale and matching seams; independent drafts are not guaranteed to join.',
                  'Props and furniture must remain separate when production sprites are assembled.',
                  'No characters, pilotable mechs or creatures were added.'],
        'cleanup_required': ['Remove green background and spill, including holes in the object.',
                             'Fit the framework footprint/canvas and clean 2:1 geometry.',
                             'Rebuild a native 1x pixel grid and quantize to the locked 56-color palette without dithering.',
                             'Split roofs, doors, glow masks and marker files.',
                             'Remove baked lighting from base sprites and paint emission separately.',
                             'Review every silhouette, orientation and kit seam in Godot.',
                             'Complete the test-batch import before promoting to final assets.'],
        'pieces': records}
    base = DELIVERY / f'street_batch_{DATE}'
    report_path = base.with_name(base.name + '_manifest.json')
    readme_path = base.with_name(base.name + '_readme.txt')
    if report_path.exists() or readme_path.exists():
        raise FileExistsError('Handoff already exists; do not overwrite it')
    report_path.write_text(json.dumps(report, indent=2), encoding='utf-8')
    lines = ['Street and concrete-block kit: 35 new raw drafts', '',
             report['scope'], 'These are raw AI drafts, not production-ready sprites.',
             'The previous campus delivery is unchanged.', '', 'Images:']
    lines.extend(f"{r['order']:02}. {r['file']}" for r in records)
    lines.extend(['', 'Cleanup still required:'] + ['- '+s for s in report['cleanup_required']])
    readme_path.write_text('\n'.join(lines)+'\n', encoding='utf-8')
    print(f'Verified {len(records)} new PNGs and their matching prompts.')
    print(report_path)
    print(readme_path)


if __name__ == '__main__':
    main()
