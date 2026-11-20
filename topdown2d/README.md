# YANGON: Life above the neon - 2D top-down world (Godot 4)

The whole `campus_terrain` map as a playable top-down game, 16 px per metre, reference-03 neon style.
Live: https://yangon-campus-2d.vercel.app  |  Desktop: double-click `run.bat` or open this folder in Godot 4.7 (F5).

| Key | Action |
|---|---|
| WASD / arrows, Shift | walk / run |
| E | talk, enter a building, leave, ride the skytrain |
| M | world map | N / T | next time of day / fast time | H | hide help |

**Districts:** YUST campus, student/tech hub, home terraces (family rooftop cafe), lakeside, northern market (5 glass halls), north + west forests
with trails, south riverfront with promenade and stairs. 55 enterable buildings, 14 interior types, 8 skytrain stations (E rides to the next one),
moving trains, hover cars on 7 road loops, students on the path network, cats, birds, day/night with lit windows.
Authored people (with lines from GameConcept.md) live inside: Mum and Grandpa in the family cafe, instructors, engineers, tea shop owner...

## Pipeline
`art/world_data.mjs` (layout, metres, same axes as the 3D scripts) + `art/lore.mjs` (dialogue) + `art/world.art.js` (pxl art, rendered in
100 m chunks) -> `node art/build.mjs` -> `assets/` (`.dat` = raw PNG bytes so exports work) + `assets/game_data.dat`.
pxl: https://github.com/crsolver/claude-pxl (set `PXL=path/to/bin/pxl.js`; raise the image-size cap in `src/core/image.ts` for the campus-era single image, chunks no longer need it).
Screenshots `godot --path . -- --capture`, collision test `godot --path . -- --collide`. Web: `godot --headless --export-release Web web/index.html`, then `vercel deploy --prod` in `web/`.
The earlier single-image campus build is kept in `old_campus/`.
