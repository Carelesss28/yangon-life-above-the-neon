# YANGON: Asset Framework (3D)

The rules every model and texture follows, so every piece drops into the game and looks like it belongs.
The game is **3D with a fixed high camera and warm real-time lighting**; the visual target is `reference/graphics/3d_lighting_reference.png`.

This framework records the later 3D production decision. The original [PDF plan converted to Markdown](Yangon_YUST_Game_Concept_and_Development_Plan.md) remains a design reference; its pixel-art/sprite passages do not override the current model pipeline. First-district sizes are defined in [FirstDistrict.md](FirstDistrict.md); the broader catalogue contains provisional dimensions.

---

## 1. How art is made

| What | Source | Notes |
|---|---|---|
| Buildings, props, vehicles, mechs, trees, kit pieces | **3D models** from Tripo (or other 3D tools) | Exported as GLB; Claude prepares them in Blender (section 12) |
| Characters | **Rigged 3D models** on one shared humanoid skeleton | Outfits are swappable meshes (section 9) |
| Textures, signs, logos, posters, UI | **2D images** (Codex or hand-made) | Used as textures and UI; never as world sprites |
| Concept and mood images | Codex | For direction only |
| Terrain, lighting, weather, effects, animation playback | **Godot** (Claude) | No art needed |

### Production rules
1. **Finish one place before building more.** The first district (FirstDistrict.md) is brought to full detail and compared with the reference screenshot before production spreads.
2. **One model per file,** never a whole scene. The engine assembles scenes.
3. **Each model arrives ready to use** (section 3): correct scale, origin, front direction, named parts, separate emissive materials.
4. **Lighting is never painted into textures.** The engine lights the world; textures carry colour only.
5. **Everything is modern sci-fi cyberpunk** (section 2).
6. **Run the checklist (section 14)** before sending.

---

## 2. World look: cyberpunk Yangon

**Every environment is modern sci-fi cyberpunk.** Near-future architecture: concrete, glass, steel, composite panels, light strips, holograms.
- **No colonial buildings and no traditional architectural motifs:** no colonial facades, arched windows, red brick, carved stone, columns, tile roofs, Victorian lamps, pagoda-style roofs or gold ornament patterns.
- **Yangon's identity comes from its people and life:** tea shops with low plastic stools, street food, markets, Burmese-script neon, rain, tropical greenery, the river, longyi and thanaka, everyday routines. Technology has a local purpose.

**Tone: cozy, lived-in, hopeful.** Warm amber windows against cool blue-green city light; plants, worn surfaces, awnings and personal objects keep technology human. Not a bleak dystopia.

| Layer | Examples |
|---|---|
| **Modern architecture** | Concrete megablocks, glass towers, steel frames, modular apartment stacks, skybridges, elevated trains, light strips, holo facades, rooftop gardens, mecha gantries |
| **Yangon life** | Tea shops, street food carts, markets, Burmese-script neon, overhead cables, balcony laundry, potted plants, tropical trees, drains and streams, longyi and thanaka |
| **Atmosphere** (engine) | Rain, puddle reflections, steam, haze, flickering signs, neon glow |

| Area | Cyberpunk intensity | Look |
|---|---|---|
| Downtown and main streets | **High** | Dense neon, holo billboards, megatowers, skybridges, drones |
| Neighbourhoods | **Medium** | Modular apartments, small neon signs, holo menus, stalls, cables, greenery |
| YUST campus | **Medium** | Clean, high-tech and green: glass and steel, light strips, landscaped quads |
| Countryside | **Low** | Nature first: prefab homes, solar panels, farm drones, small mechs |

**Avoid:** colonial and traditional architecture; copying existing games or films; real brands and logos; neon on everything.
**Reference use:** the lighting screenshot is for **camera, lighting and atmosphere only**. Its Japanese buildings and text are not ours.

---

## 3. Scale and model rules

### Scale
- **Real-world metres.** 1 Godot unit = 1 m. A character is about 1.7 m tall; a door 2.1-2.2 m; a storey 3 m.
- **Compact districts:** buildings are real-size but districts are small and dense, so one screen shows several buildings plus the street (a first district is about 150 x 150 m).
- **Mecha sizes:** Utility 3-5 m, Frame 8-10 m (first slice), Titan 30-50 m (later).

### Model file rules
| Rule | Value |
|---|---|
| Format | **GLB** (preferred), FBX or OBJ with textures |
| Units / axes | Metres, Y up |
| Origin | **Bottom centre of the footprint**, standing on the ground (y = 0) |
| Front | The main entrance faces **+Z** (glTF forward) |
| Scale | Real size at 1:1. Claude rescales if needed |
| Parts | Separate objects, named exactly: `roof` (for fading), `door_1`, `door_2`... (opening), `glass` (windows), `emit_*` (glowing parts) |
| Materials | Few and clean: one main material per surface type, plus `emit_*` and `glass`. Base colour required; normal map optional |
| Budget (triangles) | Building 5-30k, prop 0.5-5k, vehicle 5-15k, character 8-20k, tree 3-10k, kit piece 0.2-2k |
| Textures | One atlas per model, 1024 or 2048 px, base colour (plus emissive map where needed). No baked lighting or shadows |
| Detail | Chunky readable shapes at street scale; avoid thin wires and tiny greebles |

### Building shapes
- **Entrance:** a clear door at ground level on the front.
- **Roof** is its own object so the engine can fade it or cut it away.
- **Interiors:** walk-in buildings get an interior scene (section 5); the exterior model needs only a closed door.
- **Windows:** `glass` material; lit windows use an `emit_window` material the engine switches on at night.
- **Walkable bridges and rooftops** are modelled with real floors and railings, with collision added by Claude.

---

## 4. Camera and lighting (the target look)

### Camera
- **Fixed high angle** (about 50-55 degrees down), narrow perspective, looking at the player; the angle stays the same everywhere. The camera follows the player smoothly.
- **Nothing hides the player:** roofs, upper storeys, bridges and tall foreground objects fade or cut away when they sit between the camera and the player.
- Interiors use the same camera with the near walls hidden.

### Lighting
- **Sun and moon:** one directional light with a full day-night cycle; long soft shadows, warm at dusk, cool blue at night.
- **Warm lights:** windows, lanterns, shop signs and street lamps are real point or spot lights with a warm tint; they pool on the ground and guide the eye toward social spaces.
- **Neon and screens:** emissive materials with bloom; saturated neon only on signs, screens, light strips and accents.
- **Atmosphere:** ambient occlusion, soft fog, rain, wet-ground reflections used sparingly so paths stay readable.
- **Look:** stylized, slightly painterly, saturated warm lights against dark cool surroundings, like the reference.

---

## 5. Buildings and interiors
- **Exteriors:** one GLB per building (section 3). Towers can be stacked from `tower_base`, `tower_floor` (repeats) and `tower_top` parts.
- **Interiors (walk-in):** separate GLB per room, built at real size, with the front wall and ceiling removed or separate objects. Furniture is its own model with a use point (empty named `use_*`) where a character sits, sleeps or works.
- **Door styles** (Claude sets up the motion):

| Style | Use for |
|---|---|
| fade | Most buildings: interact, screen fades, the interior loads |
| slide | Sci-fi doors: departments, shops (door is its own `door_n` object) |
| bay | Hangar and garage doors |
| hinged | Small homes |
| none | Archways and open shopfronts |

---

## 6. Modular kits (generic city blocks)
Pieces on a **1 m grid, 3 m storeys**, so they snap together: plain wall, window wall, door wall, shopfront with shutter, corner, balcony, AC unit, fire escape, pipes, cables, roof edge, flat roof, rooftop props (tanks, antennas, solar panels).
Styles: concrete megablock, modular apartment stack, glass tower, patched-up stack (containers and prefab units).
Names: `kit_<style>_<piece>.glb`.

---

## 7. Terrain and connected world
The world is **one connected map**: every place you can see you can reach.
- **Ground:** Godot terrain meshes with real slopes, paving, grass, road, water; surfaces blend automatically.
- **Height:** real levels. Modular pieces on the 1 m grid: stairs (one storey over about 5 m), ramps, ladders, retaining walls, balconies, stilts.
- **Bridges and skybridges:** deck, railing and support pillar models; you walk over and under them with correct lighting and shadows.
- **Water (later proposal):** shallow (wade) and deep (swim) areas, shores with foam, drains, culverts and small streams; rain-driven water rise is additional scope. The first district only requires a readable pond/shore/bridge; do not make swimming or dynamic flooding a dependency of its walking loop.
- **Collision, navigation and levels** are built by Claude from the models.
- **Mecha** use roads and ramps, not stairs; they can wade through deep water.

---

## 8. Props and street furniture
Models with an origin at the base: lamps (with an `emit_*` bulb and a light position empty), benches, bins, vending machines, signs, planters, bus stops, charging posts, cables, laundry lines, plants, stalls, barrels and crates. Furniture has `use_*` points. Animated props (fans, neon flicker, holo billboards, traffic lights) are simple animated models or shader effects.

---

## 9. Characters
- **One shared humanoid skeleton** (Godot/Mixamo-compatible bones) for all characters, so animations are shared.
- **Body shapes:** a small set of base bodies (customisation: body, skin tone, face including thanaka, hair).
- **Outfits** are separate meshes skinned to the same skeleton (longyi, htamein, jackets, uniforms, raincoats, pilot suit, accessories). A few complete outfits first.
- **Animations** (shared library): idle, walk, run, sit, sleep, eat, use, serve (café), wade, swim, climb, jump down, drive, ride (passenger), emotes.
- Build the subset used by the first district first. Wade/swim/climb/jump-down are later movement proposals, not automatically confirmed by this animation inventory.
- Glowing parts (visors, implants) use `emit_*` materials.

## 10. Vehicles and mecha
- **Vehicles:** one model per vehicle, wheels and doors as separate objects (rotate / open), seats as `seat_*` empties, headlights and lights as `emit_*`. First: a small electric car. Later: bus or tram, hover scooter, delivery cart, elevated train.
- **Mecha:** rigged model with a shared mecha skeleton per size class; `emit_*` for lights, weapons as separate objects.

---

## 11. Textures, signs and UI (2D)
- Texture images: seamless where used on surfaces, 512-2048 px, no baked light.
- Signs, posters and logos: readable text, spelled correctly (always check Burmese); no real brands; shop names are made up.
- UI: readable at common PC resolutions, adjustable text size.
- Where they are made: Codex generates images to `C:\Users\khant\Downloads\mecharpg\` (see AGENTS.md); Claude places them.

---

## 12. Pipeline (Claude runs it)
1. **Receive** the GLB (from Tripo, Downloads or `art_source/models/`).
2. **Inspect:** `tools/blender_views.py` renders it from five sides to check orientation, scale and parts.
3. **Prepare in Blender** (`tools/blender_prepare_model.py`, to be written when the first district model is ready): fix scale and origin, rotate the front to +Z, rename parts, split `roof` / doors / `emit_*`, reduce triangles, bake or reduce textures, export a clean GLB.
4. **Import into Godot:** `game3d/models/`, with materials, collision and LODs.
5. **Check in context:** place it in the district test scene under the real lighting and compare with the reference.
6. **Report:** pass, or a fix list (for the model or for the Tripo prompt).

### Tripo prompt template (buildings)
```
Stylized sci-fi [BUILDING TYPE], modern near-future architecture, chunky readable shapes,
clear main entrance door at ground level on the front, large windows, light grey and white
composite panels with one accent colour, cyan light strips, [N] storeys, flat clean colours,
a separate roof, no ground, no text.
```
For props and kit pieces use "stylized sci-fi [PROP], chunky simple shapes, flat clean colours, no ground". Ask for "stylized" and "chunky"; avoid "highly detailed", "greebles" and "intricate".
**Lessons from the first test model** (a dark tower, 2026-11-18): dense tiny details became noise, near-black textures read poorly, and no visible door made the entrance unclear.

---

## 13. Folders and delivery
```
game3d/                 Godot 3D project (scenes, scripts, models, materials)
assets3d/
  models/               final GLB models, by category (buildings, props, vehicles, characters, kit)
  textures/             signs, posters, UI images
  _incoming/            new models waiting for review
art_source/             original GLBs, Blender files, concept images (never loaded by the game)
reference/              graphics/ (lighting target), topdown/ (city layout and mood), yangon/ (photos)
```
- Lowercase names with `_`, variants `_01`, `_02`.
- **Info line** per model (in a text file next to it): `name, type, footprint W x D in metres, storeys, door style`.
- **Review:** put new models in `assets3d/_incoming/<name>/` (or tell me the path); Claude checks and replies pass or fix list; passed models move to `models/`.

---

## 14. Checklist before sending a model
- [ ] Modern sci-fi cyberpunk, no colonial or traditional details; right intensity for its area
- [ ] Real scale (metres), origin at the bottom centre, entrance facing +Z
- [ ] Separate named parts: `roof`, `door_n`, `glass`, `emit_*`
- [ ] A clear entrance at ground level (buildings)
- [ ] Triangle count within budget; one clean texture atlas; no baked lighting
- [ ] Chunky readable detail; no thin wires or tiny noise
- [ ] Text on signs spelled correctly (Burmese checked); no real brands
- [ ] Info line included

---

## 15. References
| File / folder | Use it for |
|---|---|
| `reference/graphics/3d_lighting_reference.png` | **Camera, lighting, shadows and atmosphere** (the visual target) |
| `reference/witchbrook/` | Detail level and liveliness (a 2D game; not the graphics) |
| `reference/topdown/` | City layout and cyberpunk mood |
| `Yangon_YUST_Game_Concept_and_Development_Plan.pdf` (Downloads) | The game plan |
| `reference/yangon/` | Real Yangon photos for details of life (add as you find them) |
- References are for look, scale and accuracy; never copy another game's assets.

## 16. Open items
- [ ] First district models (FirstDistrict.md)
- [ ] `tools/blender_prepare_model.py`
- [ ] Final camera angle and post-processing, tuned in the Godot test scene
- [ ] Burmese and English fonts for signs and UI
