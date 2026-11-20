# Cyberpunk Yangon: Art Framework

The rules every art file follows, so every piece drops into the game without rework.
The art sets the look; the engine handles placement, lighting, shadows, effects, collisions and the map.

---

## 1. How art is made

| What | Source | Why |
|---|---|---|
| Buildings (campus, city, landmarks) | **3D models** (Tripo), rendered to pixel art by Claude (section 14) | Exact isometric angle every time, so all buildings match |
| Big props (mech statue, vehicles, trees, kiosks, mechs) | **3D models**, rendered by Claude | Same reason |
| Terrain tiles (ground, paths, water, cliffs, stairs) | **2D images** (AI-generated or hand-drawn) | Flat diamond tiles are easy to make in 2D |
| Small props and decals (benches, signs, bins, cracks, puddles) | **2D images** | Small and quick, and the angle matters less |
| Characters | **2D images** (hand-drawn or AI-generated, then cleaned) | They need clean frame-by-frame animation |

### Production rules
1. **Finish one screen before building more.** The **campus entrance** (CampusArt.md) is brought to full detail first, and checked side by side against the Witchbrook references. Only then does production spread to the rest of the campus.
2. **Every piece is a separate file, never a scene.** One building, one tile, one prop or one character per file. The engine assembles scenes.
3. **Each piece is delivered complete:**
   - The exact canvas size for its footprint (section 5).
   - Its roof as a separate file (buildings).
   - A glow mask, if anything lights up (section 4).
   - Marker pixels: anchor, doors, use points (section 4).
   - Its info line: name, type, footprint, storeys, door style (section 16).
4. **Neutral daytime light on every piece.** The engine creates night, weather and neon glow.
5. **Priority order:** P0 from [BuildingList.md](BuildingList.md) first, starting with [CampusArt.md](CampusArt.md).
6. **Run the checklist (section 19) before sending** every piece.

### Style target and palette
- **Style target:** the finished campus entrance screen becomes the style reference that every later piece must match. It's saved as `reference/style_target.png` (640 x 360) once it's done.
- **Palette:** `assets/palette.png`, one swatch per pixel in a row.
  - **36 world colours** (greys, concrete, metal, glass, foliage, road, water) and **20 neon colours** (orange, yellow-green, cyan, blue, violet, magenta, pink, red).
  - Neon colours are used only on signs, screens, lights and glow masks.
  - **Status: provisional.** Until the entrance screen is finished, each rendered asset uses its own fitted 16-colour palette (section 14). The final palette is then extracted from the entrance screen and locked; after that every file uses only those colours.

---

## 2. World look: cyberpunk Yangon

**Every environment is modern sci-fi cyberpunk.** The whole city is near-future architecture: concrete, glass, steel, composite panels, light strips and holograms.
- **No colonial buildings and no traditional architectural motifs:** no colonial facades, arched windows, red brick, carved stone, columns, tile roofs, Victorian lamps, pagoda-style roofs or gold ornament patterns.
- **Yangon's identity comes from its people and life:** tea shops with low plastic stools, street food, markets, Burmese-script neon, monsoon weather, tropical greenery, the river, longyi and thanaka, and everyday routines.

**Tone:** lived-in and hopeful cyberpunk. Busy, warm, worth protecting. Not a bleak, ruined dystopia. Grime, wear and patched-up tech are fine; despair isn't.

### The mix in every scene
| Layer | Examples |
|---|---|
| **Modern cyberpunk architecture** | Concrete megablocks, glass towers, steel frames, modular apartment stacks, skybridges, elevated maglev, light-strip edges, holo facades, rooftop gardens, mech gantries |
| **Yangon life** (always there) | Tea shops, street food carts, markets, Burmese-script neon, crowded overhead cables, balcony laundry, potted plants, tropical trees, monsoon drains and streams, longyi and thanaka |
| **Atmosphere** (mostly from the engine) | Neon glow at night, monsoon rain and puddle reflections, steam, haze, flickering signs |

### Cyberpunk intensity by area
| Area | Intensity | What it looks like |
|---|---|---|
| Downtown and the main city | **High** | Dense neon, holo billboards, megatowers, skybridges, drones, glowing shopfronts |
| Neighbourhood streets | **Medium** | Modular apartment blocks, small neon signs, holo menus, street stalls, cables, greenery |
| Academy campus | **Medium** | Clean, high-tech and green: glass and steel departments, light strips, holo crests, landscaped quads, mech facilities |
| Countryside and villages | **Low** | Nature first: modern prefab homes, solar panels, farm drones, small mechs in the fields, a lone charging post |

Even "low" areas show some future tech, so the whole world feels like one place.

### Avoid
- Colonial and traditional architecture (see above).
- Copying the look of existing cyberpunk games or films.
- Real brands, logos and political symbols.
- Neon on everything: the intensity table decides how much each area gets.

---

## 3. Camera and scale (locked)

### Projection
| Rule | Value |
|---|---|
| Projection | **2:1 isometric**, the same camera as Witchbrook. Locked |
| Floor tile | **32 x 16 px diamond = 1 m x 1 m** |
| Edge steps | 2 px across, 1 px down |
| Height | 16 px per metre |
| One storey | 3 m = **48 px** |
| Height level | 1 level = 48 px (one storey). Cliffs, raised platforms, walkways and bridges are whole levels (section 9) |
| Door height | about 36 px |
| Character | about 30 px tall, in a 32 x 48 frame |
| Axes | **W** runs down-right, **D** runs down-left. Footprints are W x D tiles |

### Game scale (buildings are compressed)
People, doors and storeys keep real proportions, but **building footprints are about half their real-life size**, as in Witchbrook. One screen (640 x 360 px) should show **3-6 buildings plus the streets between them**.

| Building type | Footprint (tiles, W x D) | Storeys drawn | Example |
|---|---|---|---|
| Stall, kiosk, booth | 2-4 x 2-3 | 1 | mohinga stall, ATM booth |
| Small shop | 5-8 x 4-5 | 1-2 | tea shop, convenience store |
| House, apartment block | 6-10 x 5-7 | 2-4 | apartment block, shophouse |
| Big building, department | 12-18 x 8-10 | 2-4 | Pilot School, dorm wing |
| Landmark, hangar | 20-28 x 12-16 | up to 5 | main hall, mech hangar |

- **Only landmarks** may be bigger than 20 tiles on either side.
- **Walk-in buildings** are at least 5 x 4 tiles.
- **Tall towers** show their lower storeys plus stacked tower parts (section 6); most of their height can run off the top of the screen.
- **Interiors can be bigger than the outside suggests.**
- **Maps** use the same scale: a real 300 x 300 m campus becomes about 150 x 150 tiles.

### The camera
- **Both ground directions run diagonally** at the 2:1 slope. No street or wall runs straight across the screen.
- **Every building shows two faces** (down-left and down-right) plus its roof seen from above. **Never draw a wall facing the camera head-on.**
- **Vertical edges stay straight up.** No perspective and no vanishing points.
- **High camera:** you see the tops of roofs and tables, and the floor inside open shopfronts.
- **Zoom:** a character is about 1/12 of the screen height (30 px of 360).
- **Angle guides:** `reference/iso_angle_guide.png` (a plain 2:1 box) and `reference/witchbrook/camera_angle_witchbrook.png` (a real frame with 2:1 lines).

```
      W axis \           / D axis         both axes diagonal (2 px across : 1 px down)
              \         /
               \       /                  walls rise straight up from these lines
                \     /
                 \   /                    no wall faces the camera straight on
                  \ /
```

---

## 4. Pixel rules for every image

### Light and shading
- Daylight comes from the **top-left**: roofs and tops lightest, down-left faces medium, down-right faces darkest.
- A dark 2 px strip where walls meet the ground.
- **No cast shadows painted on the ground.** The engine adds them.
- Windows, screens and signs drawn **unlit**. Lit pixels go in the glow mask.
- **3-4 shades per material**; shadows shift **cooler** (blue/purple), highlights shift **warmer** (yellow).

### Pixels
- One art pixel = one screen pixel at 640 x 360. Never mix resolutions; never scale, rotate or stretch finished art.
- Keep the level of detail similar everywhere. A cup isn't more detailed than the building it sits in.
- Pixels are fully opaque or fully transparent (glow masks, glass and smoke are the exceptions).
- No anti-aliasing, no soft brushes, no stray single pixels.
- Dithering only for large gradients (sky, big glass, smoke), always the same 2 x 2 checker. Never on characters.

### Outlines
- Outer silhouettes use the dark outline colour (navy or purple, never pure black).
- Inner detail lines use a darker shade of the surface's own colour.
- Characters, mechs and creatures keep a full outline so they stand out.

### Colour priority (readability)
- **The world** (ground, walls, roofs) stays muted, lower in contrast.
- **Interactive things** (doors, items, NPCs, the player) are a step brighter.
- **Saturated neon** only for signs, screens, lights and cyberpunk accents.

### Text in art
- Signs in Burmese or English are **readable at 1x** and spelled correctly (always check Burmese).
- No real brand names or logos; shop names are made up.

### Animation
- Base timing **12 fps**; hold key poses longer using frame durations.
- Same anchor in every frame of every animation.

### File format
- PNG, **8-bit RGBA, sRGB**, no colour profiles that change colours.
- No PNG larger than **2048 x 2048** (split bigger things, section 6).
- Animations: sprite sheet PNG plus JSON (Aseprite "Export Sprite Sheet", Hash format).

### Companion files (same canvas size as the sprite)
**Glow mask** `glow.png` / `<name>_glow.png`: only the pixels that emit light, in their lit colours (windows, neon, screens, eyes, lamps); everything else transparent. Claude can draft it from neon-coloured pixels; lit windows are always painted by hand.

**Markers** `markers.png` / `<name>_markers.png`: single pixels on a transparent layer.

| Colour | Hex | Meaning |
|---|---|---|
| Red | `#ff0000` | **Anchor**: the ground point the sprite stands on (required on every sprite) |
| Green | `#00ff00` | **Door**: the ground point in front of each door |
| Blue | `#0000ff` | **Mount point**: where the engine may attach signs or holograms |
| Yellow | `#ffff00` | **Light source**: lamps and big signs that light the street |
| Magenta | `#ff00ff` | **Use point**: where a character stands to use furniture |

---

## 5. Buildings: exterior

### Canvas size and anchor
```
         /\            canvas width  = (W + D) x 16 px
        /  \           canvas height = (W + D) x 8 + H
       |    |          H = height of the highest point above the ground, in px
       |    |
        \  /           ANCHOR = bottom corner of the footprint
         \/  <-        on the bottom row, (W x 16) px from the left edge
```
- Exactly this size, no padding.
- **Example:** a shop 6 x 4 tiles, 2 storeys (96 px) plus a 24 px roof: H = 120, canvas 160 x 200 px, anchor at x = 96.

### What to draw
- The two front walls (down-left face and down-right face) plus the roof. Never the back walls.
- The footprint is solid. If part of it is walkable (an arcade, a courtyard, stilts), say which tiles.

### Files per building
| File | Contents | Required |
|---|---|---|
| `base.png` | Walls, doors, signs: everything except the roof | yes |
| `roof.png` | Roof only. The engine fades it when the player walks behind the building | yes |
| `glow.png` | Lit pixels only | if anything glows |
| `markers.png` | Red anchor, green doors, blue and yellow where needed | yes |

---

## 6. Big buildings and towers
- **Towers** come as stackable parts, all the same width with the anchor in the same place:
  - `tower_base.png`: ground floor and entrance.
  - `tower_floor.png`: one storey that **repeats seamlessly** when stacked.
  - `tower_top.png`: the crown with antennas and holo rings.
- **Landmarks** can be drawn whole. If one is taller than 2048 px, split it into horizontal bands that line up exactly.

---

## 7. Modular building kits (generic city blocks)
- **One piece = 1 tile wide x 1 storey (48 px).** Every piece for **both faces** (down-left and down-right), because the lighting differs.
- **Pieces per style:** plain wall, window wall, door wall, shopfront with shutter (open and closed), corner; add-ons (balcony, AC unit, fire escape, pipes, cables, key-on-a-string clip); roof edge, flat roof, roof corner, rooftop props (tanks, antennas, solar panels).
- **Styles:**
  - Concrete megablock (dense housing, Downtown)
  - Modular apartment stack (neighbourhoods)
  - Glass tower (offices, corporate district)
  - Patched-up stack (containers and prefab units along streams and rail lines)
- Names: `kit_<style>_<piece>_<face>.png`, e.g. `kit_megablock_window_left.png`.

---

## 8. Buildings: interior (walk-in)
Going through a door loads a **separate interior room**, as in Witchbrook.
- **Room:** W x D tiles of floor plus the **two back walls** at full storey height. No front walls.
- **Canvas:** the same formula as exteriors, with H = the back-wall height.
- **Exit door:** a green marker. **Windows** on the back walls get glow pixels.
- **Furniture:** each piece is its own file with its own footprint, red anchor and magenta use point.

---

## 9. Terrain
Everything stands on the terrain, and the world is **one connected map**: every place you can see you can reach, with no seams or gaps.

### Tiles
- **Every tile is a 32 x 16 diamond** on a 32 x 16 canvas. A tile with height (curb, step) gets a taller canvas, diamond at the bottom.
- **Surfaces**, each with 2-3 plain variants: grass, dirt, mud, sand, sidewalk and paving, plaza concrete, metal deck, road (plus lane markings and crossing stripes).
- **Edge sets:** where two surfaces meet, the engine joins them automatically (Godot terrain autotiling). Each surface needs a **13-tile edge set**: 4 outer corners, 4 edges, the middle, and 4 inner corners. Each is its own 32 x 16 file named `<surface>_edge_<position>.png` (e.g. `lawn_edge_n.png`, `lawn_edge_ne.png`, `lawn_inner_sw.png`).
- **Animated tiles** (water, holo floor): 4 frames that loop seamlessly, side by side.

### Height levels
**Level 0** is the ground; each level is one storey (48 px, 3 m) higher.

| Piece | What it is | Size |
|---|---|---|
| **Cliff / retaining wall face** | The visible sides of a raised area (rock, concrete, metal), both faces | per tile: 16 x 56 px (one face, 1 tile long, 48 px tall) |
| **Raised top** | Any surface tile, drawn 48 px higher by the engine | 32 x 16 |
| **Stairs** | One level over 3 tiles, along either ground axis | 3 tiles per flight, both directions, with left and right edges |
| **Ramp** | For wheels and mechs: one level over 4-6 tiles | like the stairs |
| **Ladder** | Climbs a cliff face | per face, 48 px tall |
| **Ledge** | A drop you can jump down (not climb up) | marked in the map, no extra art |

### Water
| Piece | What the engine does |
|---|---|
| **Shallow water** (animated) | Wade: slower walking, splashes |
| **Deep water** (animated) | Swim: swim animation, no running |
| **Shore edge set** (13 tiles, with foam) | Joins water to every land surface |
| **Drains and streams**: grates, culvert openings, small waterfalls (animated) | Roadside streams and monsoon drains |
| **Bridge deck, railing, support pillars** | Walk over water or a road on level 1, under it on level 0 |

### What the engine does (no extra art)
- Collisions follow the tiles: cliff faces block; stairs, ramps and ladders change level; deep water switches to swimming.
- **Over and under:** on a bridge you're on level 1, underneath on level 0; drawing is sorted by level, so nothing glitches.
- **Mechs** use roads and ramps, not stairs or ladders; they can wade through deep water.
- **Monsoon:** heavy rain can flood low streets with shallow water.

---

## 10. Props and street furniture
- Same rules as buildings: tight canvas, red anchor, footprint in tiles, glow and markers where needed.
- Lamps and big signs get a yellow light-source marker.
- Animated props (neon flicker, holo billboards, traffic lights, fans) use a sprite sheet plus JSON.

---

## 11. Characters
- **Frame:** 32 x 48 px, body about 30 px. **Anchor:** feet centre, same place in every frame.
- **Directions:** draw **down-right** and **up-right**; the engine mirrors them for the other two.

| Animation | Frames |
|---|---|
| idle | 2-4 |
| walk | 4-6 |
| run | 6 |
| sit, sleep | 1-2 |
| eat, use | 2-4 |
| wade (shallow water) | 4 |
| swim (deep water) | 4 |
| climb (ladder) | 2-4 |
| jump down (ledge) | 3 |

- **Layers**, each exported on the same frames so the engine can mix characters: body; clothing (longyi, htamein, jackets, uniforms, raincoat); hair; face (thanaka); implants and cyber-arms; hats.
- Implants, eyes and visors get a glow sheet with the same layout.

## 12. Vehicles
- Draw **down-right** and **up-right**; the engine mirrors them.
- Idle and moving animations (wheels, hover bob, rotors), 2-4 frames each.
- Anchor at the ground centre; footprint in tiles; headlights, underglow and screens in a glow sheet.
- Usually made as 3D models (section 14).

## 13. Doors
Opening is code; the door style goes in the info line.

| Style | Use for | What you provide | What the engine does |
|---|---|---|---|
| **fade** (default) | Most buildings | Nothing extra | Interact, screen fades, interior loads |
| **slide** | Sci-fi doors: departments, shops, dorms | `door_<n>.png` with only the door panel; a dark open doorway in `base.png` | Slides the panel open, then fades in |
| **bay** | Hangar and garage doors | `door_<n>.png` per panel, dark bay opening in `base.png` | Rolls or slides the panels, warning lights |
| **hinged** | Small homes, back doors | `door_<n>_01.png` to `_03.png` | Plays the frames, then fades in |
| **none** | Archways, open shopfronts, gates | Nothing | The player walks through |

- Door files use exactly the same canvas as `base.png`. `<n>` matches the green marker, numbered left to right.
- Optional `shutter.png`: the closed shutter for shops that close at night.

---

## 14. 3D models rendered to pixel art (buildings and big props)

### Pipeline (Claude runs it)
1. **Model:** Tripo or any 3D tool. Export **GLB** (preferred), FBX or OBJ, with textures. Give the target size in metres at game scale (section 3), or the name from BuildingList.md / CampusArt.md.
2. **Render:** `tools/blender_render_iso.py` (Blender, installed):
   - Orthographic camera at the exact 2:1 isometric angle. The model's **front faces down-left** and its **right side faces down-right**.
   - Heights scaled to 16 px per metre (48 px per storey).
   - Toon shading: 3 flat light bands (cooler shadow, mid, warmer light) times the model's own colours. Sun from the top-left. Transparent background, rendered at 4x.
3. **Pixelize:** `tools/pixelize.py --iso`:
   - Shrinks to game size; each pixel takes the most common colour of its block, so edges stay crisp.
   - Auto brightness lift for dark models; hard alpha.
   - Colours: a 16-colour palette fitted to the asset with dedicated neon slots (or the locked master palette with `--master`).
   - Removes stray pixels, adds the 1 px dark outline.
4. **Hand pass:** fix details, add signs and Burmese text, split the roof, check the glow mask, place markers.

Check a model's orientation first with `tools/blender_views.py` (renders it from 5 sides).

### Making models that pixelize well
- **Chunky shapes:** details smaller than about 0.3 m become noise (thin wires, small railings, small text).
- **Flat, clean colours;** noisy textures become speckles. Avoid near-black textures.
- **A clear entrance** on the front or the right side (the two sides the camera shows).
- **Glowing parts** (signs, light strips, screens) as separate materials, so they become the glow mask.
- **2-4 storeys** for most buildings; heights at game scale (section 3).

**Tripo prompt template (buildings):**
```
Low-poly stylized sci-fi [BUILDING TYPE] for an isometric game, chunky simple shapes,
clear main entrance door at ground level on the front, large readable windows,
light grey and white composite panels with one accent colour, a few large details instead of
many small ones, cyan light strips and one holographic sign, flat clean colours, [N] storeys.
```
- Ask for "stylized", "low-poly", "chunky". Avoid "highly detailed", "greebles", "intricate".

---

## 15. AI-generated 2D images (tiles, small props, characters)

### Where images are saved
- **Every** generated image goes to **`C:\Users\khant\Downloads\mecharpg\`**; Claude collects from there.
- Codex generates in batches of up to 5 and saves each batch right away, without being asked.
- Names: `<piece>_<YYYYMMDD>_<nn>.png`, plus the prompt as `<piece>_<YYYYMMDD>_prompt.txt`. `<nn>` counts up; nothing is overwritten.

### Prompt rules
- **One isolated piece**, never a scene.
- **Camera:** "true 2:1 isometric, high top-down angle, vertical edges perfectly vertical, no perspective". For buildings also "both walls receding diagonally, roof visible, no wall facing the camera" and "every bottom and roof edge rises exactly 1 pixel for every 2 pixels across, on both sides".
- **Angle guide:** attach `reference/iso_angle_guide.png`: "match the camera angle of the attached guide box exactly; use it only for the angle, not the design".
- **Background:** "plain flat solid pure green background (#00ff00), no ground, no cast shadow".
- **Light:** "neutral daylight from the top-left". Never night or sunset.
- **Look:** "near-future sci-fi cyberpunk Yangon", the intensity from section 2, and the description from BuildingList.md / CampusArt.md. No colonial or traditional details.
- **No text** unless the exact text is given; Burmese is added by hand.
- **Never** name existing games, artists, brands or copyrighted characters.

**Template: props**
```
Pixel art, a single isolated [PIECE] for an isometric game. [DESCRIPTION].
Near-future sci-fi cyberpunk Yangon, [INTENSITY] cyberpunk, no colonial or traditional details.
Seen from the same camera as the attached guide box: true 2:1 isometric, high top-down angle,
vertical parts perfectly vertical, no perspective. Neutral daylight from the top-left.
Plain flat solid pure green background (#00ff00), no ground, no cast shadow, no text, no people.
Clean pixel art, no blur, no anti-aliasing.
```

**Template: terrain tiles**
```
Pixel art terrain tile for an isometric game: [SURFACE]. A seamless 2:1 isometric diamond floor
tile, 32 x 16 px, seen from the same camera as the attached guide box. Near-future sci-fi
cyberpunk Yangon. Neutral daylight, muted colours. Clean pixel art, no blur, no anti-aliasing,
no text. Plain flat pure green background (#00ff00) outside the diamond.
```

### Clean-up steps
| # | Step | Who |
|---|---|---|
| 1 | Remove the green background | Claude |
| 2 | Scale so one storey is about 48 px | Claude |
| 3 | Angle check: base edges within about 0.05 of 2:1 are fine; up to about 0.2 off is corrected automatically; worse is regenerated (or made in 3D) | Claude |
| 4 | Snap to a clean 1x pixel grid and the palette | Claude |
| 5 | Draft glow mask from neon pixels | Claude |
| 6 | Fix by hand: stray pixels, broken details, text | Artist |
| 7 | Split the roof, paint window glow, place markers | Artist |
| 8 | Run the checklist (section 19) | Artist, then Claude reviews |

Tools: `tools/process_ai_art.py` runs steps 1-5.

---

## 16. Folders, names and delivery
```
assets/
  palette.png
  tiles/<surface>_<variant>.png                       e.g. tiles/lawn_01.png
  buildings/<name>/base.png, roof.png, glow.png, markers.png, door_<n>.png, shutter.png
  buildings/<name>/interior/room.png, glow.png, markers.png
  kit/<style>/kit_<style>_<piece>_<face>.png
  props/<name>.png, <name>_glow.png, <name>_markers.png
  characters/<layer>/<name>_<anim>.png + .json
  vehicles/<name>_<anim>.png + .json
  ui/
  _incoming/<name>/       new or changed pieces waiting for review
  placeholders/           stand-ins made by Claude until real art arrives
art_source/               3D models, raw renders, raw AI images, Aseprite files (never loaded by the game)
```
- Lowercase, words joined with `_`, no spaces; variants `_01`, `_02`.
- **Info line** for every building or prop (in `info.txt`):
  ```
  name, type, footprint W x D, storeys, doors
  teashop_01, tea shop, 6 x 4, 2, fade
  ```

### Delivery and review
1. Put new or changed pieces in `assets/_incoming/<name>/` with their `info.txt`, or put 3D models anywhere and tell Claude the path.
2. Claude checks against this framework and replies **pass** or a **fix list**.
3. On pass, Claude moves the piece into its final folder and loads it into the game.
4. Changing a final piece: send it again through `_incoming` with `_v2`. Never overwrite final files directly.

---

## 17. What the artist does not draw
- **Effects** (pixelfx): rain, storm, fog, glitch, hologram flicker, sparks, electricity.
- **Lighting:** day/night, neon glow and bloom, ground shadows.
- **The map:** layout, roads, rivers and streams are assembled from tiles.
- **Behaviour:** doors opening, stairs, swimming, collisions.

## 18. References
| Folder / file | Use it for |
|---|---|
| `reference/witchbrook/` | **Camera, scale and detail level** (the main reference) |
| `reference/witchbrook/witchbrook_01_campus_courtyard.png` | Academy buildings, entrances, stairs, planters |
| `reference/witchbrook/witchbrook_02_city_street.png` | Roads, crossings, sidewalks, street trees, vehicles |
| `reference/witchbrook/witchbrook_03_market_plaza.png` | Plazas, fountains, stalls, crowds |
| `reference/witchbrook/witchbrook_04_interior_cutaway.png` | Walk-in interiors (back walls only) |
| `reference/witchbrook/witchbrook_05_countryside_trail.png` | Countryside paths, rocks, streams |
| `reference/witchbrook/witchbrook_06_winter_street.png` | Seasonal ground and trees |
| `reference/topdown/` | City layout (street grid, parking, parks) and cyberpunk mood only, **not** the camera |
| `reference/iso_angle_guide.png` | The exact 2:1 angle |
| `reference/yangon/` | Real Yangon photos for details of life (add as you find them) |

- References are for camera, scale, detail and real-life accuracy. Never trace or copy another game's art.

---

## 19. Checklist before sending
- [ ] A single separate piece, not part of a scene
- [ ] Modern sci-fi cyberpunk, no colonial or traditional details, right intensity for its area (section 2)
- [ ] 2:1 isometric: no wall facing the camera, verticals straight up (compare with `reference/iso_angle_guide.png`)
- [ ] Game scale: footprint from BuildingList.md / CampusArt.md, 48 px per storey, 30 px people
- [ ] Canvas exactly (W + D) x 16 by (W + D) x 8 + H, no padding
- [ ] Red anchor marker; green door and magenta use-point markers where needed
- [ ] Roof in its own file (buildings)
- [ ] Glow mask for anything that lights up, same canvas size
- [ ] Neutral daytime light from the top-left, no painted ground shadow, no anti-aliasing
- [ ] Colours from the palette (or the asset's fitted palette until the lock); neon only on lights
- [ ] Fully opaque or fully transparent pixels (except glow, glass, smoke); no stray pixels
- [ ] Text spelled correctly (always check Burmese); no real brands
- [ ] Animations: 12 fps base, same anchor in every frame
- [ ] Named and foldered as in section 16, with the info line and door style

---

## 20. When art is needed, and open items
The code never waits for art: every system starts with placeholders, and real art replaces them as it arrives.

| Milestone (GameConcept.md) | Art needed |
|---|---|
| M1 Campus entrance | Terrain for the entrance (lawn, paving, plaza with edge sets, one raised level with stairs, a stream with shore and bridge), the gate, Pilot School front, trees and street props, all to full detail |
| M2 People and time | Player character layers, 3 classmates, instructor, background students |
| M3 Mech feel | None: controls are tuned with placeholder shapes first |
| M4 Training mission | Frame (M) mech (sizes given after M3), training ground, hangar |
| M5 Defence mission | Creature enemy, neighbourhood street, damage art |
| M6 Slice complete | Everything in the slice, final |

**Open items**
- [ ] Style target: the finished campus entrance screen (`reference/style_target.png`)
- [ ] Final palette: extracted from the style target and locked
- [ ] Pixel fonts for Burmese and English signs
