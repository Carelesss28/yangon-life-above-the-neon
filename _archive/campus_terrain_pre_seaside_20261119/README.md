# Four-quadrant terrain ? Godot 4

Reference lighting pass: warm amber/warm-white window variations now extend around all building facades, with real entrance and window spill lights, rooftop cafe lights and market-hall/stall illumination. Taller modern streetlights follow the connected road loops, with alternating real light pools across the carriageway. Forest trails, lake paths, gardens, skytrain platforms, riverside stairs and the retaining wall have dedicated lighting. The forest canopy is set back around trails so their lights can be seen from the high camera. Night fill is cooler/dimmer; street/window emission switches off in daylight, and N restores each light's authored night intensity. All lighting is real time. No baked light textures were introduced.

The pass has 885 registered exterior lights, including 367 added by `scripts/city_lighting.gd`. Forward+ uses a 2048-element cluster budget; added local lights have shadows disabled. `scripts/city_lighting_check.gd` checks area coverage, lit window variations, daylight shutoff and exact night intensity restoration, then captures `screenshots/reference_lighting_*_20261119.png`. The current whole-map image is also saved as `screenshots/masterplan_full_20261119.png`.

Water style update: `shaders/stylized_water.gdshader` replaces the dark transparent surface with opaque turquoise water, broad colour variation, animated curved flow streaks, pale shoreline foam and softer highlights. River banks are solved at the actual water-plane/terrain intersection, so the surface reaches both banks; the lake disk now reaches its shoreline too. Twelve low rounded river stones have animated partial foam wakes. Lakes/pools have gentler, sparse broken ripple arcs; canals and the forest stream retain downstream flow. These are live shader effects and material colour, with lighting and shadows supplied by Godot. No baked lighting or water image textures are used. `scripts/water_style_check.gd` checks shoreline coverage and renders `screenshots/stylized_water_*_20261119.png` in daylight and blue hour. `scripts/water_data_check.gd` verifies the water-network routing.

Latest entrance/rail adjustment: every enclosed building is now enterable (43 interiors; the remaining two structures are open transit shelters). Near a door, use **E** or the visible **Enter building** button. Nearby entrances show **ENTER [E]** above the approach. E is handled before HUD focus, proximity is checked immediately on keypress, and detection uses horizontal distance with a ground-level height limit. Return to the interior exit and use E or **Exit building**. Wholesale and delivery buildings now have storage/dispatch furnishings too.

The skytrain's former clearance above local terrain/road decks is halved and smoothed across terraces. The city line follows the outer street corridors to avoid roofs at the lower height; the market alignment retains the elevated plateau allowance rather than halving absolute world elevation. Stations, lift travel, platforms and train routes derive from the lowered guideway. Earlier 24/38 m rail elevations and 30-interior counts below describe the preceding pass.

## Working elevated skytrain

`F` calls/rides station lifts, boards a stopped train or alights when its doors are open. `T` opens the live line map, arrivals and nearest-lift directions. Street entrances have cyan/amber station signs. Walk from the lift landing onto the platform and wait behind the yellow line. At Tech Interchange, stand toward the C or M edge to select a service; after alighting, the centre prompt favours the connecting line. All rides are free.

The **City Loop** runs clockwise: C1 Campus North -> C2 Tech Interchange -> C3 Lake Gardens -> C4 Riverfront -> C5 Home Terraces -> C6 YUST Gate -> C1. Two two-car trains operate on its 2.36 km elevated loop. The **Market Link** shuttle serves C2 Tech Interchange, M2 Market South and M3 Market Halls in both directions, along 0.88 km of elevated track. Eight unique stations share one Tech island interchange; every station has a working lift. Trains accelerate/brake, dwell for ten seconds, open doors only on the platform side, play a generated arrival chime and carry the player along the actual route. The line map gives approximate arrival times. Boarding/alighting between stations is blocked, and pause freezes train/lift movement. Station canopies and the ridden train's roofs cut away for visibility.

All railway structures are above ground, with a lowered city guideway with at least about 7 m terrain clearance and a raised market approach with about 9 m minimum terrain clearance. Track geometry is instanced in batches; piers avoid the road network and reserved building plots. Station access uses animated lifts; stairs/escalators, NPC passengers, fares and a reverse-direction city service are not part of this first service. Existing interiors and walking controls remain available after leaving the train.

Implementation: `scripts/skytrain.gd`. `scripts/skytrain_check.gd` checks all stations, complete service cycles, track elevation, train separation, lift/platform movement, a city-to-market transfer, F-key controls, safe alighting and pause. `scripts/skytrain_capture.gd` saves the `screenshots/skytrain_*_20261119.png` previews. `scripts/road_check.gd` verifies road traversal with the railway piers and station entrances installed.

Latest full-map pass (19 November): 45 building/shelter groups, five curved glass market halls, connected local road loops in the home and tech districts, about 2,200 additional instanced broadleaf trees and 460 palms, courts, market kiosks, community gardens, greenhouse, playground, forest viewing decks, waterfall foam, promenade lamps/rails, retaining-wall vines, eight parked electric cars and a river ferry. Roads remain in one connected network, without dead ends, and road traversal checks pass. Geometry remains in real metres. Rendering uses Forward+ for bloom, ambient occlusion and reflections. `M` switches to the whole-map camera; `N` switches daylight/blue hour. A clean 1024 x 1536 overview is saved at `screenshots/masterplan_full_20261119.png`; this is an approximation of the selected concept, with simpler assets and different proportions in places.

30 of the 45 groups (67%, including shelters in the denominator) now have furnished explorable interiors. Find a cyan door strip, approach until the prompt appears, and press `E` to fade inside. Walk with the usual controls; return to the entrance and press `E` to fade back to the same outdoor position. Interiors include homes, classrooms/simulator rooms, tea shops/cafes, clinics, workshops, market halls, shops, laundry and offices. Only the current interior is loaded. These are furnished exploration spaces; commerce, classes, NPC routines and furniture interactions are not implemented by this pass.

Interior registration/transitions are in `scripts/building_interiors.gd`, furnishings in `scripts/interior_rooms.gd`, and full-map decoration in `scripts/masterplan_dressing.gd`. `scripts/interior_check.gd` checks all 30 interiors for solid floors, usable central aisles, entry/exit restoration and actual E-key fade transitions. Running it with graphics also saves `screenshots/interior_*_20261119.png`. `scripts/masterplan_check.gd` verifies map density, building containment and the road graph and renders the overview and district previews. Older terrain-only descriptions below are historical.

Current architecture pass (19 November): `scripts/reference_buildings.gd` reconstructs building forms from the user-selected updated concept `town_connected_roads_20261118_01.png`. The 31 replacement roots include five barrel-vault glass market halls, a curved-roof engineering hall, stepped residential wings with planted balconies, the covered family rooftop cafe, solar-roof campus buildings, clinic sign tower, shop glazing and loading depots. Geometry, materials and light are real 3D. The original downloaded tower/miniature city remain preserved and are no longer the default architecture; `--downloaded-buildings` overlays them for comparison.

The scene now starts at blue hour, with warm entrance lights and emissive windows. Press N for daylight. `scripts/building_check.gd` and `scripts/reference_building_check.gd` validate footprint containment, five curved roofs and lighting; the latter saves `screenshots/reference_*_20261119.png` when run with rendering. The earlier 38-box pass described below is superseded. This is an architectural approximation, not a pixel-identical reproduction: terrain planting, paving, density, interior detail and atmospheric rendering still differ from the concept. Building interiors and accessible rooftops remain unfinished.

Open project.godot and press F5. Four nominal 300 ? 300 m districts surround a plus crossroads. Overall bounds are 614 ? 614 m; a 14 m separator between district coordinate blocks combines with the original campus edge roads into continuous 24 m avenues.

| Quadrant | Coordinates | Terrain and plots |
|---|---|---|
| Northwest: campus | X 0?300, Z 0?300 | Original +4/+2/0 m terraces, school, dorms, quad, hangar and training footprints |
| Northeast: student/tech | X 314?614, Z 0?300 | 0 m street edge, gentle +2 m plaza; repair, electronics, clinic, arcade, apartments, shops and transit plots |
| Southwest: home | X 0?300, Z 314?614 | Broad ramped terraces at 0/+2/+4 m; family home/rooftop cafe, courtyard, shops and community garden plots |
| Southeast: lakeside/market | X 314?614, Z 314?614 | 0 m market edge descending to ?2 m waterside; food market, sports, picnic and garden plots, lake and boardwalk |

WASD/arrows walk; Shift run; wheel zoom; Tab whole map; N day/night; 1 campus, 2 tech, 3 home, 4 lake; F2 labels; R reset; Esc pause. Buildings are labelled terrain footprints, not finished architecture. No traffic, NPCs, interiors, swimming or mecha gameplay yet. Trees reuse supplied models; other props are procedural blockouts. Lighting is real time.

Current overview: screenshots/four_quadrants.png. Close views: screenshots/district_0.png through district_3.png. Older screenshots show previous layouts. Run with user argument --capture after Godot's -- separator to regenerate current screenshots.

Terrain heights live in scripts/terrain_layout.gd; mesh, roads and plots in scripts/world.gd. Actual player physics tests pass for campus stairs/ramps, garden bridge, all four arrival points, east/west road crossing, first home terrace ramp, lakeside west approach and night switching. Run --headless --fixed-fps 60 --path . --script res://scripts/smoke_test.gd to repeat. Visual inspection supplements these route checks; not every square metre has been tested.


## Natural hill expansion

North hills: X=0..500, Z=?300..0 (500 ? 300 m). West hills: X=?300..0, Z=0..500 (300 ? 500 m). The northwest gap is outside the playable boundary. Existing town coordinates remain unchanged. Press 5 or 6 to enter the hills; Tab shows the expanded world.

The hills use continuous height-field collision, broad irregular ridges, narrow graded dirt trails, clustered trees from the supplied archive, shrubs, buried rock forms and fallen logs. North water runs from the outer source through a roughly 16 m steep waterfall chute into a lower creek and pool. This is procedural terrain blockout with temporary vegetation/rock art, not the finished concept-art fidelity. Mist, water sounds, wildlife, unique tropical species and detailed fern/root assets remain future work.

Both complete hill trails were traversed using real player physics, waypoint by waypoint, with final ground contact verified. All previous town route checks pass. The hills use 2 m terrain sampling; town retains its original 1 m sampling. Current screenshots: town_and_hills.png, district_4.png, district_5.png and north_waterfall.png in screenshots/.


## Northern market and southern district terrain pass

Northern market occupies X=0..600, Z=?700..?300: 600 ? 400 m. A planted southern transition meets the hills without moving the original town. Most market ground is +18 m, the gently raised shopping core is +20 m. Its broad approach buffers blend into the existing ridge; a 14 m access road and separate footway run outside the east edge at X=600..614. The road connects back to the northeast district around the forest, while a dirt trail links the north hill lookout to the arrival plaza.

Market plots reserve produce, everyday goods, clothing/crafts, food/tea, tech/robot parts, wholesale/cold storage, delivery/recycling, transit and community uses. Rain-garden basins and perimeter trees are blockout details. These are ground plots only, not market buildings or functional shops.

Southwest now has shared residential courtyards, a playground reservation and an upper residential garden linked to the existing terrace paths. Southeast has a smaller evening food strip, a cafe/rain-shelter reservation, shore planting, and a complete natural dirt walking loop around the lake with western connectors.

Controls: 1 campus, 2 tech, 3 home, 4 lake, 5 north hills, 6 west hills, 7 northern market. Tab shows the masterplan. Current overview is screenshots/terrain_masterplan.png; district_6.png shows the market. Older overviews describe superseded extents.

Physics checks pass along the entire forest-to-market trail, the east market access road, the shopping-core approach and all 16 sampled lake-loop waypoints, alongside the earlier campus and hill route checks. Generation is deterministic. The prototype constructs a large amount of geometry at startup, so allow several seconds for the scene to appear. No final art, NPCs, interiors or traffic are implied by the plot labels.


## Continuous south river

A river strip spans the full map width, X=?300..614 m (914 m long), south of the existing town. Its natural channel meanders around Z=685..760, roughly 58?72 m wide; terrain continues to Z=810. Water is at ?8 m, exactly 10 m below the +2 m riverfront land; the channel bed is at ?12 m (4 m beneath the water). The north bank transitions from existing district heights into a +2 m public approach and a deeper sloping planted bank. A meadow transition extends from the west hills into this riverfront without replacing the town.

A continuous dirt route follows the north bank, with approaches from the home neighbourhood, lakeside district and west hills. Shore shrubs, rocks, scattered trees, three seating areas and sparse lamps are terrain-blockout details. The river continues to both map edges. No bridge, boat travel or swimming system has been added; water is decorative.

Press 8 for the riverfront, or Tab for the whole world. Current overview: screenshots/terrain_with_south_river.png; riverfront view: screenshots/district_7.png. The actual player traversed every 20 m waypoint along the full north-bank route and the home-to-river approach; previous terrain tests still pass.


## Revised two-level waterfront (current)

This replaces the earlier direct land-to-water drop: the upper southern town edge is +10 m; the **lower waterfront road, cycle path and promenade are 0 m**. River water is ?1.5 m, bed ?6 m. Interior town terraces remain unchanged and blend into the raised southern edge.

A retaining wall at Z=645 separates the levels. Three stairways at X=?30,150,520 use smooth collision slopes with visible treads. Two vehicle ramps at X=?250..?90 and X=300..460 run 160 m along the wall, dropping 10 m (6.25% grade), with lower turns onto the waterfront street. The lower road is 8 m wide. A continuous blue-green 3.4 m cycle path follows the river, separated from a pedestrian path; the road and water do not share the cycle corridor. Maintenance ladders are visual props; climbing and bicycle riding mechanics are not implemented yet. The paths and ramps can be explored with the existing walking controller.

Press 8 for the lower waterfront. Existing screenshots are regenerated in place using --capture. Route tests now check the 10 m town-to-road difference, all three stairs, both vehicle ramps and the full cycle-route alignment using player physics.


## Grass quality pass

Ground grass now uses shaders/ground_grass.gdshader: irregular multi-scale colour patches, fine surface grain, muted damp/meadow greens, and earth on steep faces. No painted light or shadow is used. Actual tapered blade tufts use shaders/grass_blades.gdshader, with root-to-tip colour, per-tuft variation and gentle wind. Blade lighting is real-time and double-sided; individual blade shadow casting is disabled to control cost.

scripts/grass_system.gd streams deterministic 16 m MultiMesh chunks around the walking camera. Up to two chunks are prepared per frame, stopping after one if its build exceeds a 6 ms preparation budget; a single build can still exceed that budget. This is bounded streaming, not a guaranteed frame-time target. Old chunks are released after moving or teleporting. Whole-map view hides blade geometry and retains the ground material. Campus grass is shorter than hill/meadow grass.

Roads, paving, reserved plots, dirt trails, cycle paths, water, fountains and steep faces reject blades. Exclusion data is collected from the actual terrain-building operations. Further art passes are still needed for paving, shrubs, trees, rocks, water and overall atmospheric lighting; the whole scene is not yet at reference-image fidelity.

Run --headless --path . --script res://scripts/grass_check.gd to check grass placement masks. Use -- --grass-capture to capture campus day/night and hill daylight views. Screenshots: grass_campus_day.png, grass_campus_night.png, grass_hills_day.png. These screenshots show the grass pass; older masterplan screenshots predate it.


## Town water network

The installed water network uses five explicitly graded routes in terrain_layout.gd / WATER_ROUTES: hillside supply through campus to the river; recirculated home garden channels; recirculated tech-plaza channels feeding the lake; market rainwater collection and east-side drainage; and a pumped lake discharge. Heights never increase along any individual route. Pump units are explicit at the home and tech loop sources and lake discharge because those connections cannot be supplied by gravity alone.

Shallow channels carve the terrain and use animated downstream water surfaces with concrete edges. Deep sections become buried culverts with inspection covers; low-ground spans use supported enclosed carriers. Roads, paths, cycleways and reserved building plots receive flush crossing decks over the channel. Existing garden footbridge remains. Vegetation avoids the channel footprint. Water shaders contain no painted lighting. Quiet spatial generated water ambience plays near selected channels and the waterfall.

This is a routed visual/game-environment system, not a fluid or sewer simulation. Rain-dependent water levels, flood hydraulics, water quality and pump interaction are not implemented. Open rainwater/scenic channels do not represent wastewater plumbing. Source and treatment areas remain blockout representations.

Press F4 repeatedly to inspect campus, home, tech and outfall channels. Use -- --water-capture for screenshots/water_network_campus.png, water_network_homes.png, water_network_tech.png and water_network_outfall.png. Water route direction and crossing construction are checked by smoke_test.gd, followed by the existing full town, hill, ramp and cycle-corridor physics checks.


## Connected vehicle roads (current)

Vehicle roads are now defined by the explicit graph in scripts/road_layout.gd, replacing the earlier isolated road rectangles. The town has a perimeter loop plus the central crossroads; the northern market has a service loop and two forest-edge approach connections. The waterfront forms a loop through both long ramps and the upper-town road. The motor road on the lower waterfront spans between the ramp junctions; the remaining river frontage is pedestrian/cycling space, avoiding dangling asphalt ends.

Every road node has at least two incident edges, and all nodes are reachable from the central junction. Intersections are shared, flat collision decks with level approaches. Roads cut high ground where needed; raised sections use supported decks so the existing lake and lower paths remain underneath. Existing buildings remain reserved footprints. Trees and retaining-wall pieces avoid road corridors. Vehicle controls and traffic are not added by this terrain change.

Run --headless --fixed-fps 60 --path . --script res://scripts/road_check.gd for graph connectivity, dead-end checks, grades and physical traversal of every road segment. Footpaths and service walkways are separate from this vehicle graph and may end at destinations. Older road screenshots and concept images are superseded.


## Downloaded benches, bridge, stairs and swing

Current props use optimized copies of the new user-supplied models in models/downloaded_props/. The handcrafted model review set remains uninstalled. Benches and the main campus footbridge are replaced; all campus and waterfront stair flights use the downloaded stair mesh. A static floral swing is placed in the residential playground. Existing terrain and bridge walking collision remain in place. River/canal crossing slabs and the lakeside boardwalk remain functional terrain structures rather than being stretched from the decorative bridge asset.

Use -- --props-capture to generate screenshots/downloaded_stairs.png, downloaded_bridge.png, downloaded_bench.png, downloaded_swing.png and downloaded_waterfront_stairs.png. The original downloads remain untouched. Additional brick/stone staircase and marble/brick-arch bridge downloads are preserved as unused alternatives. Swing movement and sitting interactions are future work.


## Calm transparent water appearance

All channels, the hill creek/waterfall, fountain, rain basins, lake and river now share shaders/channel_water.gdshader. Water is pale blue and alpha blended, with slow advected normal ripples and a subtle angle-dependent sheen. Surface heights stay fixed, so adjoining pieces do not bob apart. Channels use continuous distance UVs through each route, including covered sections; their surface detail moves downstream at 0.22 m/s. The river uses a slow eastward drift, the hill creek a southward drift, and lakes/pools much slower movement. Large alternating colour bands and rigid waterfall foam stripes have been removed.

Shallow channels have visible neutral-coloured beds. Underwater lake/river terrain uses low-contrast gravel tones instead of grass, so transparency does not turn the water muddy green. Water casts no opaque shadows. This works with the existing Compatibility renderer; no screen-space reflection, refraction or fluid solver is required. Collision, river elevations, pumps and route grades remain unchanged.

Use -- --calm-water-capture for screenshots/calm_water_channel.png, calm_water_lake.png, calm_water_river.png and calm_water_creek.png. F4 still visits channel viewpoints; 4 visits the lake, 8 the riverfront. Motion is visible during normal play.


## Ambient wildlife

39 original stylized 3D animals are installed: 5 cats near campus/home/tech/market/waterfront gathering areas; 12 birds in four garden groups; 6 ducks (two adults and four smaller birds) swimming within the lake; and 16 butterflies over four planted areas. Cat legs, head and tail animate; birds hop and make short flights when approached; ducks swim and bob; butterfly wings flap as they wander.

Ground animals reject vehicle roads, water channels, steep changes and the river edge. Animals have no blocking collision, so they do not interrupt walking or cycling routes. Habitats use deterministic random behaviour and sleep beyond 160 m from the player. Birds settle and butterflies disappear at night. This is local ambient behaviour, not a full animal ecosystem. Petting, feeding, animal ownership, flock navigation and animal sounds are not implemented.

Press F6 repeatedly for wildlife viewpoints. The duck view leaves the player on shore and moves the camera over the lake; WASD returns the camera to the player. Scroll to zoom for closer inspection. Screenshots: wildlife_cat.png, wildlife_birds.png, wildlife_ducks.png, wildlife_butterflies.png. Use -- --wildlife-capture to regenerate them.

Run --headless --path . --script res://scripts/wildlife_check.gd for spawn counts, model scale, movement across habitats, lake boundaries, road avoidance and butterfly night behaviour. All checks passed. The animal nodes do not alter the terrain or the player's collision.
## Regular electric bus service (19 November 2026)

Three circulating routes run ten physical buses across fifteen stops: B1 City Circuit, B2 Market Express and B3 Home Feeder. Shared stops connect campus and Tech Interchange, with connections to the elevated skytrain. Each stop has a shelter, seating, lighting, a live approximate arrival board and a walking ramp wherever the road is raised.

Press **B** near an open bus door at a stop to board; press **B** again while stopped to alight. Press **V** for routes and estimated arrivals. Trips are free. Buses dock at the curb, open sliding doors, dwell for eight seconds, queue behind other buses and yield at junctions and to pedestrians. The roof cuts away during a ride. Boarding locks out other transport and district shortcuts until alighting.

Run `godot --path campus_terrain --script res://scripts/bus_check.gd` to check routes, stop access, ten minutes of service, vehicle separation, boarding, riding, alighting and transport ownership.

# Replaceable building decoration (19 November 2026)

The scene now includes 38 procedural building/shelter roots, assembled from real 3D meshes by `scripts/prototype_buildings.gd`. Campus teaching blocks, dorms, shops, apartments, a rooftop cafe, market halls and transit shelters occupy existing reserved plots. Gardens, sports areas, lawns and training space remain open. Exteriors have simple collision, windows, front entrances, separate roof nodes, canopies, planters and selected cafe seating. Interiors and rooftop access are not implemented.

Every root under `PrototypeBuildings` stores `replacement_id`, `building_use` and `reserved_plot` metadata. Replace that root with a prepared GLB while preserving the placement and footprint. These are temporary decorations requested by the user, rather than approved production models.

Two downloaded models are also placed: `futuristic_tower` on the pilot-school plot and `neo_utopian_city` on the robot-workshop plot. Each was reduced from approximately 1.9 million to 28,000 triangles, with textures limited to 2048 pixels. Original downloads and review renders are preserved under `assets3d/_incoming/downloaded_buildings_20261119/`. The city model is a multi-building complex used provisionally; both still need separate production roof/door/emissive parts, entrance review and interiors.

Run `godot --path campus_terrain --script res://scripts/building_check.gd` to validate placements and capture the campus, homes, tech district and northern market. Screenshots use the `prototype_buildings_*_20261119.png` names. Older descriptions of all buildings being reserved footprints describe the earlier terrain-only state.

