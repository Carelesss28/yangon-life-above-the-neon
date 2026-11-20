# YANGON: seaside town (Godot 4)

A cozy-cyberpunk seaside town around the YUST campus. Open `project.godot` and press F5.
The previous four-quadrant prototype is archived in `../_archive/campus_terrain_pre_seaside_20261119/`.

## Look
- CityRT-style daytime (bright, chunky, toy-town colours, marked roads) with neon at night.
- Anime render layer: cel-banded toon lighting on every material, screen-space ink outlines
  (`shaders/outline_post.gdshader`, toggle with **O**), a procedural sky with a day / dusk / night cycle (**N**).
- Civic-defence mood for the mecha theme: hazard stripes, armoured civic hall, utility poles and
  power lines, YUST mecha launch bay with blast doors, gantry and rotating beacons.
- All lighting is real time. No light or shadow is painted into any texture.

## Map (metres; north z=0 is the sea)
| Area | Where | Notes |
|---|---|---|
| Sea, beach, promenade | z < ~230 | Sea wall with railing, beach stairs, umbrellas, lifeguard tower, palms, Ferris wheel |
| Harbour | x 850-1150 | Three piers, gantry crane, containers, ferry terminal, moored boats, breakwater and lighthouse |
| Downtown / canal | x 430-820, z 235-560 | Civic hall, hospital, library, police, fire, towers, arcade, Central Park, downtown canal |
| Home terraces | x 60-390, z 235-560 | Climbs from 4 m to 10 m; family rooftop café, tea and mohinga shops, west canal, botanical garden |
| Harbour district | x 820-1150, z 235-560 | Fish market, warehouses, dockside apartments, east canal |
| Market | x 430-820, z 560-920 | Five distinct market halls, night-market stall street |
| YUST campus | x 828-1150, z 568-915 (322 x 347 m) | Gate, admin, pilot school, classrooms, library, labs, dorms, union, launch bay, training ground, pond |
| Hill park | x 0-440, z 575-1000 | Forest up to ~40 m, reservoir with dam and spillway, trail, lookout, winding hill road |

Four gravity-fed canals (reservoir -> west canal -> sea; cross canal; downtown canal; campus pond -> east canal -> harbour)
with walks, railings, weirs and ten footbridges. Roads cross canals on flush decks.

## Transport
- **Skytrain** (`F` to use a lift, board or alight, `T` for the map): City Loop (8 stations) and Market Link (5 stations).
  Change lines by getting off at **C4 YUST Gate** or **M5 Central Avenue**, then walking the signed ramp to the other platform.
- **Buses** (`B` to board at a stop, `V` for routes): Seafront Circuit, Downtown-Market, Home Terraces, Campus-Harbour;
  12 buses, 23 stops.

## Townspeople (scripts/npc_system.gd, npc_data.gd)
- Game clock: 30 real minutes = 24 game hours (HUD top right, with your kyat). It pauses in dialogue,
  the journal and interiors. Lighting follows the clock (day 06-17, dusk 17-19, night 19-06); N still overrides.
- 20 authored people with homes, jobs and hourly routines: family (Daw Khin May, U Aung Min, Su Su),
  classmates (Thura, Nandar, Kyaw Zin, Ei Phyu), YUST staff (Cmdr. Hla Myint, Dr. Yamin) and townspeople
  (tea-house and mohinga-shop owners, gardener, rider, librarian, mechanic, fisherman, spice seller,
  musician, police officer, nurse). They walk the sidewalks between places, go inside buildings and never
  teleport in view.
- **Q** talks (chat once a day, gift once a day, ask schedule, quests) or picks up gift items (glowing
  markers that respawn each morning). **H** opens the journal: relationships, quests, bag.
- Relationship levels: Acquaintance -> Familiar (20) -> Friend (45) -> Close friend (70). Loved gifts +12,
  liked +7, chat +4, quests +12-18. Instructors and family are never romance options; romance is not built yet.
- One quest per person, five kinds: fetch, deliver, collect-from-someone, visit a place, meet at a time.
  Yellow **!** = favour to ask, **?** = something to hand in or deliver.
- Progress saves to `user://yust_social.json` (`-- --fresh-social` starts clean).
- Shophouse rows have gateways in front of every main building door, so entrances are visible from the street.

## Crowd, minimap and traffic
- 50 non-interactive pedestrians; 70% head for time-of-day hotspots (tea shops and stations in the morning,
  markets at midday, promenade and park in the evening, night market and arcade at night).
- Minimap (top right, scripts/minimap.gd): roads, canals, buildings, stations, quest dots, player arrow.
  Click it for the whole-town map; click again, M, Tab, Esc or WASD to return.
- Traffic (scripts/traffic.gd): 34 cars and 22 motorbikes (models/vehicles, CC-BY, see CREDITS.md) drive on
  the right through the road graph, keep gaps, stop for the player, lights at night; 22 flying cars on sky
  lanes; ferry, fishing boats, speedboats and a cargo ship. `-- --no-traffic` disables it.

## Rules of the road, services, building functions
- 48 signalled junctions (green 13 s, amber 4 s, all-red 1.5 s), stop lines, red-light cameras; limits 50 km/h on
  avenues, 40 km/h on local streets, 30 km/h on the hill road. Drivers keep gaps, look ahead into the street they
  turn into, stop for people on foot and never block an occupied junction. About 1 in 10 drivers is reckless:
  cameras record them and traffic police (6 junction posts with police bikes) pull them over. 3 police patrol
  cars and a fire truck circulate. `scripts/traffic_check.gd` verifies it.
- Police station and fire & rescue station: signs, rotating beacons, parked patrol cars, police bike, fire trucks,
  bay doors and a hose tower (`scripts/services.gd`).
- Oversized plots were compacted in `tools/seaside_plan.py`; the freed frontage holds 23 functional cyberpunk
  buildings (charging hub, drone port, VR net café, cybernetics clinic, capsule hotel, holo cinema, mecha garage...).
- Every non-residential building has activities (`scripts/activities.gd`, press Q inside): jobs, shopping for gift
  items, meals, classes and study, sim runs, check-ups, outfits, sleep at home. Stats: Energy, Study, Piloting,
  Engineering, Fitness, Charm (journal H). `scripts/activities_check.gd` verifies coverage.
- Zoom: mouse wheel, touchpad two-finger swipe or pinch, +/- or PageUp/PageDown, or the buttons under the minimap.

## Hill attractions (scripts/hill_attractions.gd)
Six sites on flat platforms cut into the hills (terrain_layout.HILL_PADS), each well apart:
YUST field-training grounds (track, obstacle walls, climbing ramp, firing range, observation tower, a parked 9 m
training frame); Sky Terrace Resort (terraced hotel, infinity pool, three steaming hot-spring pools); meditation
garden and lantern park; hill village (mountain tea house, tea plantation terraces, goat farm); hilltop
campground (tents, flickering campfire) with a zipline over the reservoir and a stargazing deck; civic-defence
sensor station (radar dome, rotating dish, masts, armoured SHELTER 07). A cable car runs from the village up to
the resort. 13 activity spots (Q): training, swim, dinner, hot spring, cable car and zipline rides, meditation,
tea picking, farm chores, camping overnight, stargazing, sensor watch.

## Everything usable
- Motor District (200 x 200 m east of the harbour, Layout.MOTOR, its own ring road): car showroom, bike &
  scooter showroom, service garage with chargers, test track, delivery lot (scripts/motor_district.gd).
  Buy with Q at a showroom: bicycle 8,000 K up to the neon hover car 400,000 K. C gets in/out, G calls your
  last vehicle to you. Traffic cars are not usable; owned vehicles are (scripts/owned_vehicle.gd).
  Your own driving is enforced: red-light and speeding fines from cameras and traffic police.
- Rides like the metro (scripts/rides.gd): cable car up/down, zipline, Ferris wheel loop, harbour ferry cruise.
- Pilot the 9 m training frame on the field-training grounds (C to climb out).
- 62 activity spots (24 kinds): benches, beach, harbour crane, pier fishing, showrooms, garage, test track and the
  hill sites; say hello to passers-by with Q. scripts/use_check.gd verifies buying, driving, rides and piloting.

## Click-to-move, solid world, mecha hangar
- Left-click to walk (hold to steer); grid A* pathfinding around anything solid (scripts/click_move.gd,
  path_finder.gd). Clicking a person, building, counter, pickup, station, bus stop or your vehicle walks
  there and uses it. WASD still works.
- Everything solid has collision: seafront and canal railings, pier edges, trees, palms, lamp posts,
  utility poles, signal and camera poles, benches, containers. People are CharacterBody3D capsules that
  walk around obstacles; nobody (player or NPC) passes through anything (scripts/obstacle_check.gd).
- YUST mecha hangar (campus engineering hangar): open front, glass roof, four bays with gantries holding the
  user's four Tripo frames (models/mecha, originals untouched; review renders in
  assets3d/_incoming/mecha_20261120). Each can be piloted: Q at the bay plate or C next to it; W/S walk, A/D
  turn, Space boost, C climb out (the frame stays parked). "Return all frames" at the hangar counter.

## Controls
WASD walk, Shift run, E enter buildings (all 91 are explorable), 1-8 visit areas, Tab overview, M masterplan,
N day/dusk/night, O ink lines, Q talk / pick up, H journal, R reset, Esc pause.

## How it is built
- `tools/seaside_plan.py` generates the road graph (`scripts/road_layout.gd`) and building plots
  (`scripts/reference_blocks.gd`) and checks that no plot touches a road or canal. It also saves
  `screenshots/seaside_masterplan.png`. Edit the generator, then re-run it; do not hand-edit those two files.
- `scripts/terrain_layout.gd`: heights (coast, terraces, plateau, hills, reservoir, pond) and canal routes.
- `scripts/seaside_town.gd`: terrain, sea, roads and markings, sidewalks, promenade, harbour, canals,
  parks, campus grounds, launch bay, Ferris wheel, utility poles.
- `scripts/reference_buildings.gd`: building architecture (plus tower and civic styles); every building is a
  replaceable root with `replacement_id`, `building_use` and `reserved_plot` metadata.
- `scripts/masterplan_dressing.gd`, `street_life.gd`, `cyber_district.gd`: trees, lamps, neon, signs, props,
  infill blocks, drones, obstacles.

## Checks
- `godot --headless --fixed-fps 60 --path . --script res://scripts/town_check.gd`: road graph, campus size,
  canal grades, buildings and entrances, trains and buses running, and real player walks (campus, promenade,
  canal footbridge, home terraces climb, hill trail, beach stairs).
- `npc_check.gd -- --fresh-social`: routines, walking, talk/gift limits, all five quest kinds, saving.
- `entrance_approach_check.gd` and `interior_check.gd` still apply. The older `bus_check`, `skytrain_check`,
  `road_check`, `smoke_test` and other checks were written for the previous map and are now obsolete.
- `godot --path . -- --town-capture [--all-times]` saves `screenshots/seaside_*`.
