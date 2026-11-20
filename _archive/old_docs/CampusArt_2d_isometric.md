# Campus Art: Yangon University of Science

What to make for the campus, in order. Every piece follows [framework.md](framework.md).

- **Campus:** about 300 x 300 m real, **about 150 x 150 tiles** at game scale (roughly 25 screens).
- **First area:** the **campus entrance, about 60 x 40 tiles** (2-3 screens), brought to full Witchbrook-level detail before anything else.
- **Look:** modern sci-fi cyberpunk, medium intensity: clean and high-tech, glass and steel, white and grey composite panels, light strips, holo crests, landscaped greenery (framework section 2). No colonial or traditional details.

Canvas sizes use the isometric formula (framework section 5): width (W + D) x 16, height (W + D) x 8 + H, anchor on the bottom row at x = W x 16. **3D** pieces come out at this size automatically when rendered (framework section 14).

---

## 1. Campus plan (150 x 150 tiles)
Seen from above, north at the top. In the game it's isometric. Positions may shift during building.
```
+----------------------------------------------------------------------------+
|  SPORTS AND LAKE           |  RESIDENTIAL COLLEGES     |  HANGAR AND        |
|  stadium, fieldhouse,      |  (2-3 houses, each 4      |  TRAINING          |
|  boathouse, campus lake    |   wings round a courtyard)|  mech hangar,      |
|  ~50 x 45                  |  ~50 x 45                 |  training ground,  |
|                            |                           |  launch platform   |
|----------------------------+---------------------------|  ~45 x 70          |
|  DEPARTMENTS (west)        |  CENTRAL QUAD              |                   |
|  engineering, robotics,    |  main hall tower, grand   |                    |
|  rescue, agri-tech, net    |  library, student union,  |--------------------|
|  ~50 x 55                  |  dining hall  ~50 x 55     |  DEPARTMENTS (east)|
|----------------------------+---------------------------|  ~45 x 35          |
|  medical centre, dorm      |  CAMPUS ENTRANCE (first)  |                    |
|  overflow, parking         |  gate, entrance plaza,    |                    |
|  ~50 x 40                  |  Pilot School  ~60 x 40   |                    |
+-----------------------------  main gate  -----------------------------------+
                         road to the city (campus maglev stop outside the gate)
```

---

## 2. The campus entrance (first area, ~60 x 40 tiles)

### What's in it
- **The main gate** facing the city road, with the campus maglev stop just outside.
- **An entrance plaza** behind the gate: paving with light-strip joints, a holo crest, a notice board, a hover-bike rack, a drone dock.
- **A raised terrace** one level up (retaining wall plus a wide flight of stairs), with the **mech statue** on top.
- **The Pilot School** front on the terrace, with its entrance and sim-pod lab.
- **A small stream** crossing the area, with a footbridge and a drain outlet.
- **Lawns, rain trees, padauk trees, hedges and planters** along the paths.
- **Life:** students walking and sitting, a vending machine, benches, bins, cables, small signs, puddles and leaves.

### Detail rule
No 4 x 4 tile patch without something interesting. Build each screen in layers: base ground, ground variation, decals (cracks, drains, leaves, paint), edges and trims, props and clutter, an overhead layer (cables, signs, tree canopies), light.

### Pieces for the entrance
| Piece | Source | Footprint (W x D) | Height H | Canvas | Notes |
|---|---|---|---|---|---|
| **main_gate** | 3D | 8 x 3 | 104 | 176 x 192 | Steel-and-glass gateway arch, holo crest, guard booth, ID turnstiles. Walk-through passage (door style: none) |
| **dept_pilot** (School of Mech Piloting) | 3D | 15 x 10 | 216 | 400 x 416 | Angular glass building, glowing "sync ring" on the roof, clear entrance on the front (door style: slide) |
| **mech_statue** | 3D | 3 x 3 | about 160 | auto | Bronze-and-steel academy mech on a plinth, about 6 m tall |
| **campus_maglev_stop** | 3D | 10 x 4 | about 64 | auto | Elevated platform outside the gate |
| **rain_tree** | 3D | 2 x 2 | about 140 | auto | Big campus tree. Can start from the oak model in `Downloads/new tree models.zip` |
| **padauk_tree** | 3D | 1 x 1 | about 110 | auto | Smaller tree with yellow flowers |
| **campus_light_post** | 2D or 3D | 1 x 1 | about 80 | 32 x 96 | Slim modern light column with a holo ring, yellow light marker |
| **bench** | 2D | 1 x 2 | about 24 | 48 x 48 | Concrete and wood, magenta use point |
| **planter** | 2D | 4 x 2 | about 24 | 96 x 72 | Modern concrete planter with flowers |
| **holo_crest** | 2D | 1 x 1 | about 64 | 32 x 80 | Academy crest on a slim pylon, glow |
| **holo_notice_board** | 2D | 1 x 2 | about 48 | 48 x 72 | Class times and news, glow |
| **hover_bike_rack** | 2D | 1 x 3 | about 24 | 64 x 56 | |
| **drone_dock** | 2D | 2 x 2 | about 40 | 64 x 72 | Small landing pad with a charger, glow |
| **vending_machine** | 2D | 1 x 1 | about 40 | 32 x 56 | Drinks and snacks, glow, use point |
| **bin, bollard, small signs** | 2D | 1 x 1 | 16-32 | 32 x 32-48 | Clutter |
| **decals** | 2D | 1 x 1 | 0 | 32 x 16 | Cracks, drain grates, puddles, fallen leaves, paint marks |

### Terrain for the entrance (2D, framework section 9)
| Tiles | Notes |
|---|---|
| **Lawn**: 13-tile edge set + 2-3 plain variants | Campus grass |
| **Paving**: edge set + variants | Paths, with light-strip joints |
| **Plaza concrete**: edge set + variants | The entrance plaza |
| **Flower bed and hedge edges** | Borders along paths |
| **Retaining wall face** (concrete, both faces) + **stairs** (one level over 3 tiles) | The raised terrace |
| **Stream**: shallow and deep water (4 animated frames each), shore edge set with foam, drain outlet | Crosses the entrance |
| **Footbridge**: deck, railing, supports | Over the stream |

---

## 3. Other slice buildings (after the entrance)
| Piece | Source | Footprint | Height H | Canvas | Notes |
|---|---|---|---|---|---|
| **college_wing_north** | 3D | 20 x 4 | 200 | 384 x 392 | Modern modular dorm block: balconies, light strips, holo crest. Entrance to the common room |
| **college_wing_south** | 3D | 20 x 4 | 200 | 384 x 392 | Passage through the middle into the courtyard (walkable) |
| **college_wing_west / east** | 3D | 4 x 8 | 200 | 192 x 296 each | Dorm rooms. With the north and south wings they surround a 12 x 8 courtyard |
| **mech_hangar** | 3D | 28 x 16 | 240 | 704 x 592 | Steel-truss hangar, composite panels, 2 big bay doors (door style: bay), gantries, warning lights. Fits an 8-10 m mech |
| **training_booth** | 3D or 2D | 3 x 2 | 64 | 80 x 104 | Control booth overlooking the training ground |
| **training props** | 2D | 1-2 tiles | 24-64 | per piece | Targets, holo target emitters, low walls, ring gates, barrier blocks, floodlight towers |

---

## 4. Interiors (slice)
| Room | In building | Floor W x D | Wall H | Canvas | Furniture (each a separate prop with a use point) |
|---|---|---|---|---|---|
| **Classroom** | dept_pilot | 10 x 8 | 48 | 288 x 192 | Desks, chairs, holo board, instructor podium, lockers |
| **Sim-pod lab** | dept_pilot | 8 x 8 | 48 | 256 x 176 | 4 simulator pods (open and closed), control console, cable trays |
| **Player's dorm room** | residential college | 5 x 4 | 48 | 144 x 120 | Bed, desk with terminal, wardrobe, shelf, window, charging dock |
| **Common room** | residential college | 10 x 8 | 48 | 288 x 192 | Sofas, low table, holo screen, kitchenette, tea kettle, notice board |
| **Mech bay** | mech_hangar | 16 x 12 | 240 | 448 x 464 | Mech cradle and gantry, tool racks, parts crates, repair arm, console |

Interiors can be bigger than the buildings look from outside.

---

## 5. Characters (campus)
- Player body plus layers: academy uniform, pilot suit, a few hairstyles (framework section 11).
- Instructor, 3 classmates, background students made from the same layers in different colours.

---

## 6. Order
1. **Entrance terrain** (2D): lawn, paving, plaza, retaining wall and stairs, stream, footbridge.
2. **Entrance 3D models:** gate, Pilot School, mech statue, trees, maglev stop.
3. **Entrance small props and decals** (2D).
4. Assemble the entrance in Godot to full detail; compare with the Witchbrook references; lock the style target and palette.
5. Campus characters.
6. Dorm wings and interiors, then the hangar, training ground and mech bay.
7. The rest of the 150 x 150 campus, zone by zone (section 1).
