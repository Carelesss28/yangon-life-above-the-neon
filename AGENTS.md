# Instructions for AI agents (Codex, Claude) in this project

**YANGON: Life above the neon** — a cozy sci-fi student life game with mecha, set in a near-future Yangon. **3D with a fixed high camera and warm real-time lighting**, built in Godot 4.

Read these before doing any work:
- [GameConcept.md](GameConcept.md): the game plan and decisions.
- [framework.md](framework.md): the rules for every model and texture.
- [FirstDistrict.md](FirstDistrict.md): the first place being built, with its model list.
- [BuildingList.md](BuildingList.md): every building.

## Who makes what
- **3D models** (buildings, props, vehicles, characters, trees) come from Tripo or other 3D tools. Claude prepares them in Blender and puts them in the game. **Don't generate 2D images of buildings or sprites.**
- **Codex generates 2D images only for:** concept and mood images, textures, signs, posters, logos and UI.
- **Claude** writes the game code, runs the Blender and Godot pipelines, and reviews every piece.

## Style (everything)
- **Modern sci-fi cyberpunk:** concrete, glass, steel, composite panels, light strips, holograms, screens, drones, cables.
- **No colonial or traditional architecture or details:** no red brick, arched windows, carved stone, columns, tile roofs, Victorian lamps, pagoda-style roofs or gold ornaments.
- **Yangon shows through life:** street food, tea shops with plastic stools, markets, Burmese-script neon, tropical plants, rain, longyi and thanaka.
- **Cozy and warm:** amber windows against cool blue-green city light; lived-in, hopeful.
- **Lighting is never painted into textures.** The game lights the world.
- Target look: `reference/graphics/3d_lighting_reference.png` (camera, lighting, atmosphere only; not its Japanese buildings or text).

## Generating images (must follow)
1. **Save every generated image automatically** to `C:\Users\khant\Downloads\mecharpg\`.
   - Generate in batches of up to 5 and save the whole batch right after it, without being asked.
   - Never leave a generated image unsaved.
2. **File names:** `<piece>_<YYYYMMDD>_<nn>.png`, using the names in FirstDistrict.md / BuildingList.md. `<nn>` counts up and never overwrites a file.
3. **Save the prompt** next to each batch as `<piece>_<YYYYMMDD>_prompt.txt`.
4. **Textures** are seamless where used on surfaces and have no baked light or shadow. **Signs** have readable, correctly spelled text (Burmese is checked by the user) and no real brands.
5. **Never** name existing games, artists, brands or copyrighted characters in prompts.

## Tripo prompts (models)
Use the template in framework.md section 12: stylized, chunky, a clear entrance on the front at ground level, a separate roof, light strips, flat clean colours, no ground, no text. Avoid "highly detailed", "greebles" and "intricate".

## Files
- Don't write into `assets3d/models/` or `game3d/` directly. New models go through `assets3d/_incoming/` and review (framework.md section 13).
- Don't delete or overwrite anything in `reference/`, `assets3d/`, `art_source/` or `game3d/`.
