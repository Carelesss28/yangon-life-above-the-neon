# First District

The first playable place, brought to full detail before anything else (framework.md, production rule 1).
From the concept plan: *apartment/café, YUST entrance, one shop, one transit stop, one parking area, one garden and one skybridge*, with a slope or stairs. About **150 x 150 m**, close enough that several activities fit into one day.

Everything is modern sci-fi cyberpunk (framework.md section 2). Names are working names.

This is the current 3D first-district plan. The original PDF is preserved in [Markdown](Yangon_YUST_Game_Concept_and_Development_Plan.md); its pixel-art and undecided-engine passages are historical. The 150 x 150 m extent and model dimensions here are working production suggestions, not locked measurements supplied by that PDF. The larger 300 x 300 m campus remains later expansion.

---

## 1. Layout (seen from above, north at the top)
```
+------------------------------------------------------------+
|  GARDEN AND LAKE EDGE        |  YUST ENTRANCE                |
|  lawn, trees, benches, pond  |  main gate, plaza, Pilot      |
|  (slope down to the water)   |  School front, mech statue    |
|------------------------------+-------------------------------|
|  SKYBRIDGE (level 2) links the apartment tower to the        |
|  YUST side tower across the main road                        |
|------------------------------+-------------------------------|
|  APARTMENT + ROOFTOP CAFE    |  SHOPPING STREET               |
|  family building, stairs,    |  convenience store, tea shop, |
|  lift, parking area          |  stalls, bus / tram stop       |
+------------------------------------------------------------+
        main road with traffic lanes, crossings and signals
```

## 2. Places and what happens there
| Place | Player use |
|---|---|
| **Apartment and rooftop café** | Wake up, family, player room, café counter and shifts, covered terrace, rooftop garden, building entrance with stairs and lift |
| **Parking area** | Locate and park an owned vehicle; passenger pick-up. A loaned prototype car is proposed for testing before purchase progression is ready |
| **Main road** | Traffic lanes, crossings, signals, a bus or tram |
| **Shopping street** | Convenience store (buy an outfit or snacks), tea shop, stalls |
| **Transit stop** | Bus or tram to YUST and a quick route home |
| **YUST entrance** | Gate, plaza, the Pilot School (classroom and sim-pod room), mech statue |
| **Skybridge** | Pedestrian route between two towers; proves the vertical navigation |
| **Garden and lake edge** | Rest, animals (cats near warm machinery, birds), slow social moments |
| **Training arena** | A separate area for the first friendly match (after the district works) |

---

## 3. Models to make (3D, framework.md section 3)
Priority order. Sizes are real metres; the layout above shows where each goes.

### Buildings
| Model | Footprint (m) | Storeys | Door | Notes |
|---|---|---|---|---|
| **apartment_cafe** | 18 x 12 | 6 | fade | The family building: street entrance, stairs, lift; **a rooftop café on the top** with a covered terrace, counter, seating and a small garden. Warm amber light. The most important model |
| **yust_gate** | 16 x 6 | 2 | none | Modern gateway arch, holo crest, guard booth, ID turnstiles |
| **dept_pilot** (School of Mech Piloting) | 30 x 20 | 4 | slide | Angular glass building, glowing "sync ring" on the roof, clear entrance, classroom and sim-pod room inside |
| **yust_side_tower** | 14 x 14 | 8 | fade | The tower at the other end of the skybridge |
| **convenience_store** | 10 x 8 | 1 | slide | 24/7 shop with a clear shopfront |
| **tea_shop** | 10 x 7 | 1-2 | none | Open front, low plastic stools, kettles, neon sign |
| **transit_stop** | 12 x 4 | 1 | none | Bus or tram stop with a holo timetable |
| **mech_hangar** (later) | 56 x 32 | 1 tall hall | bay | For later arena/training content; proposed clear height about 15 m for the 8-10 m Frame, rather than treating it as three 3 m storeys |

### Connected structures
| Model | Size | Notes |
|---|---|---|
| **skybridge** | 24 m span, 3 m wide | Covered walkway between the towers at level 2, with railings, lights and support pillars |
| **stair_flight** | 3 m rise | Wide outdoor stairs with railings (kit piece, repeated) |
| **ramp** | 3 m rise over 10 m | For cars and mecha |
| **retaining_wall** | per 3 m | Concrete wall for the slope |
| **footbridge** | 8 m span | Over the pond or a stream |

The ramp above is a vehicle/mecha gameplay-kit proposal, not the default pedestrian alternative to stairs. Give walking routes their own suitable ramps/lifts and clear landings. Match both skybridge landings to the same actual floor elevation; "level 2" is a planning label until that elevation is set.

### Vehicles and big props
| Model | Notes |
|---|---|
| **car_small_electric** | The first drivable car: 4 wheels, 2 doors, a passenger seat, lights |
| **bus_or_tram** | One scheduled vehicle |
| **mech_statue** | Academy mech on a plinth, about 6 m |
| **trees** | Rain tree, padauk tree, palms (the tree GLBs in `Downloads/new tree models.zip` can be reused) |

### Props (small)
Street lamps and lanterns, benches, planters, bins, vending machine, notice board, café tables and stools, umbrellas, bike rack, charging posts, signs, cables and laundry lines, potted plants, stalls, cat.

### Characters
Player base body and a few outfits, the first classmate, a family member (mother or father), the instructor, 3-5 ambient commuters, one cat.

---

## 4. Terrain and world
- A **slope** between the garden and the road (stairs on one side, a ramp on the other).
- **Road** with lanes, crossings and signals; **paving**, grass, a small **pond** with a shore and a footbridge.
- Lighting setup: dawn, day, dusk and rainy night, tuned against the reference screenshot.

---

## 5. Order
1. **3D test scene in Godot:** camera, lighting and fog, a day-night cycle, walking on terrain with a slope and stairs, one placeholder block building with a fading roof. Compared with the reference.
2. **`apartment_cafe`** (the rooftop café), then `skybridge` and the stairs: these prove the vertical navigation and the cozy look.
3. **YUST entrance:** gate, `dept_pilot`, mech statue, `yust_side_tower`.
4. **Street:** convenience store, tea shop, transit stop, car, road.
5. **Props and trees** to full density; characters.
6. **The slice loop** (GameConcept.md section 4): home → class → invite a classmate → drive to the café → shift → outfit → save.

## 6. Complete-example checks
- Home/café: begin and cancel a shift cleanly; finish one order, receive pay once, and save/load money and outfit ownership.
- School: attend one easy exercise with the instructor and classmate, see subject progress, and retry without replaying all introductory dialogue.
- Social: an accepted invitation reserves the classmate; rain or an alert communicates a changed destination; a later conversation recalls the outing.
- Driving: two valid parking points, one available seat, safe boarding, travel, exit and schedule resumption. Save/load while parked with a passenger.
- World: walk every stair, slope and skybridge at day and night; enter at visible landings; check roof/foreground fading and unobstructed interact prompts.
- Mecha: one machine, opponent and arena; movement, a basic attack, a defensive action, tutorial feedback and quick rematch. No full roster or repeated incursions yet.

These are completion criteria, not claims that the systems or models have already been implemented.
