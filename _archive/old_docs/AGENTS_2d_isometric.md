# Instructions for AI agents (Codex, Claude) in this project

A 2.5D isometric pixel-art RPG set in a near-future cyberpunk Yangon, built in Godot 4.

Read these before doing any work:
- [GameConcept.md](GameConcept.md): the game plan and decisions.
- [framework.md](framework.md): the rules every art file must follow.
- [CampusArt.md](CampusArt.md): the campus (Yangon University of Science) and the first area, the campus entrance.
- [BuildingList.md](BuildingList.md): every building, with sizes.

## Who makes what
- **Buildings and big props** are 3D models (Tripo) that Claude renders to pixel art (framework section 14). Don't generate 2D images of buildings unless asked.
- **Codex generates 2D images:** terrain tiles, small props, decals, characters (framework section 15).
- **Claude** writes the game code, runs the art pipelines and reviews every piece.

## Style (every image)
- **Camera: 2:1 isometric, Witchbrook-style. Locked.**
  - Both ground directions diagonal; every bottom and roof edge rises exactly 1 pixel per 2 pixels across.
  - Vertical edges vertical, no perspective, no wall facing the camera.
- **Modern sci-fi cyberpunk:** concrete, glass, steel, composite panels, light strips, holograms, screens, drones, cables.
- **No colonial or traditional architecture or details:** no red brick, arched windows, carved stone, columns, tile roofs, Victorian lamps, pagoda-style roofs or gold ornaments.
- **Yangon shows through life:** street food, tea shops with plastic stools, markets, Burmese-script neon, tropical plants, monsoon drains, longyi and thanaka (framework section 2).
- **Game scale:** 1 tile = 1 m (32 x 16 px diamond), 48 px per storey, 30 px characters, building footprints about half real size (framework section 3).

## Generating images (must follow)
1. **Save every generated image automatically** to `C:\Users\khant\Downloads\mecharpg\`.
   - Generate in batches of up to 5 and save the whole batch right after it, without being asked.
   - Never leave a generated image unsaved.
2. **File names:** `<piece>_<YYYYMMDD>_<nn>.png` (e.g. `bench_20261118_01.png`), using the names in CampusArt.md / BuildingList.md. `<nn>` counts up and never overwrites a file.
3. **Save the prompt** next to each batch as `<piece>_<YYYYMMDD>_prompt.txt`.
4. **Attach `reference/iso_angle_guide.png`** as the camera reference: "match the camera angle of the attached guide box exactly; use it only for the angle".
5. **Use the prompt templates** in framework section 15:
   - One isolated piece.
   - Plain flat pure green background (#00ff00).
   - Neutral daylight from the top-left.
   - No text, no people (unless the piece is a character).
   - Terrain tiles: seamless 32 x 16 isometric diamonds.
6. **Never** name existing games, artists, brands or copyrighted characters in prompts.

## Files
- Don't write into `assets/` directly. Finished pieces go through `assets/_incoming/` and review (framework section 16).
- Don't delete or overwrite anything in `reference/`, `assets/`, `art_source/` or `game/`.
