# YANGON: Building and Location Catalogue (3D)

Long-term locations, grouped by what people use them for. The full city's extent remains open; the earlier 2 km x 2 km target is not a first-district requirement.
All dimensions use **real metres**, with **1 Godot unit = 1 m** and a typical storey about **3 m**, following [framework.md](framework.md) section 3.
Buildings are **3D models used directly in Godot**, not rendered into world sprites. Modular kits follow framework section 6; interiors section 5; delivery and review section 13.
Everything is modern sci-fi cyberpunk, with no colonial or traditional architecture (framework section 2).

**Dimension migration:** most catalogue footprints are provisional starting suggestions converted from the old compressed tile catalogue at 2 m per former footprint tile. They are not newly confirmed PDF measurements. The first-district model sizes in [FirstDistrict.md](FirstDistrict.md) take precedence; review each model before import.

**Priority**
- **P0**: supports the connected home-school-café first district. Build FirstDistrict.md's model list in its stated order.
- **P1**: expansion after the first district works.
- **P2**: extra depth, flavour and side activities.

**Walk-in**
- **Yes**: needs an interior scene when its activity is built (framework section 5).
- **No**: exterior/background or an object used from outside.
- **Kit**: assembled from modular 3D pieces (framework section 6).

---

## 0. YUST: Yangon University of Science and Technology

A mech academy laid out like an **Ivy League university**:
- Many departments, each with its own building, arranged around green **quads**.
- **Residential colleges** (dorm houses with courtyards), a grand library and athletics.
- A lake with a boathouse, like Yangon University by Inya Lake.

**Style:** modern cyberpunk, clean and high-tech (framework section 2). No colonial or traditional architecture.
- **Every building** is glass, steel, white and grey composite panels, light strips and holograms, each department with its own shape and accent colour.
- **The Ivy League feel comes from the layout,** not old buildings: big green quads, a landmark main tower, residential colleges with their own crests, a grand library, sports grounds and a lake.
- Landscaped greenery everywhere: lawns, rain trees, rooftop gardens, green walls.

**Campus size:** the earlier 300 x 300 m boundary remains a planning allocation, in metres. It is not a tile conversion or the first district size. Start with the entrance and one teaching space in [FirstDistrict.md](FirstDistrict.md); the full campus is later content. YUST and department names are provisional. The player starts in the family apartment with its rooftop café, not a dorm.

### 0a. Departments
| Name | Department | Footprint (m) | Storeys | Walk-in | Priority | Cyberpunk look | What players do there |
|---|---|---|---|---|---|---|---|
| dept_pilot | **School of Mech Piloting** (combat and defence) | 30 x 20 | 4 | Yes (classroom, sim-pod room) | **P0** | Angular glass tower with a glowing "sync ring" halo | Piloting lessons, simulator drills, the player's home department |
| dept_engineering | **Mech Engineering and Frame Design** | 36 x 24 | 3 | Yes (workshop, assembly bay) | P1 | Steel-truss hall, sparks, robot arms behind glass | Repair and build lessons, part crafting |
| dept_robotics_ai | **Robotics and AI** | 24 x 20 | 5 | Yes (lab) | P1 | White pods, blue light strips, drone docks on the roof | AI co-pilot, drones, mech software |
| dept_recon | **Scout and Aerial Frames** | 24 x 18 | 3 | Yes (lab) | P2 | Wind-tunnel tube and rooftop drone pad | Scouting lessons, drone races |
| dept_rescue | **Rescue and Disaster Response** | 30 x 24 | 3 | Yes (flood sim tank) | P1 | Indoor flood-simulation tank with storm lights | Rescue drills for monsoon floods |
| dept_civil | **Industrial and Construction Frames** | 30 x 24 | 2 | Yes (crane yard office) | P2 | Crane yard, hazard stripes, scaffold towers | Construction jobs and lessons |
| dept_agritech | **Agri-tech and Delta Ecology** | 24 x 20 | 4 | Yes (vertical farm) | P1 | Greenhouse tower with magenta grow lights | Farming lessons; links to the countryside |
| dept_cybernetics | **Cybernetics and Bio-medicine** | 24 x 20 | 4 | Yes (implant lab) | P2 | Clean white tower, teal medical holograms | Implants, medic training |
| dept_energy | **Energy and Reactor Engineering** | 20 x 20 | 3 | Yes (reactor control room) | P2 | Glowing core visible through glass | Mech power systems |
| dept_net | **Signals, Netrunning and Cybersecurity** | 16 x 16 | 8 | Yes (server floor) | P1 | Black monolith spire with data-stream neon | Hacking and comms lessons |
| dept_alien_studies | **Alien Studies Institute** (proposed) | 20 x 16 | 2 + basement | Yes (restricted lab) | P2 | Sealed concrete bunker, warning lights | Optional later research/story location about alien incursions; replaces the retired Silt-specific proposal |
| dept_humanities | **Humanities and Myanmar Studies** | 30 x 16 | 2 | Yes (lecture hall) | P2 | Low modern hall with a holo-projection atrium showing history | History, literature, languages |
| dept_business | **Business and Urban Economics** | 20 x 16 | 4 | Yes (lecture hall) | P2 | Glass office block with stock tickers | Trading, part-time job perks |
| dept_arts | **Arts, Media and Holo Design** | 24 x 18 | 2 | Yes (studio, theatre) | P2 | Colourful hologram facade, light installations | Festivals, plays, outfit design |

### 0b. Shared campus buildings
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| yust_gate | 16 x 6 | 2 | No | **P0** | Modern steel-and-glass gateway, holo crest, guard booth and ID scanner; canonical model for the former main_gate entry |
| yust_side_tower | 14 x 14 | 8 | Yes (skybridge landing/lobby) | **P0** | Other end of the first district pedestrian skybridge |
| central_quad | 60 x 40 | - | No | P1 | Expanded campus lawns, paths, trees, statue and benches; the first district needs only an entrance plaza |
| main_hall | 40 x 20 | 3 + tower | Yes (admin office, great hall) | P1 | Campus landmark: a slim glass tower with a giant holo clock, seen from everywhere on campus. Ceremonies and graduation |
| grand_library | 40 x 30 | 3 | Yes (reading room, data archive) | P1 | Terraced glass building, reading terraces with holo bookshelves. Study and lore |
| residential_college | 40 x 32 (4 wings around a courtyard) | 4 | Yes (shared dorm room, common room) | P1 | Later student housing around a green courtyard; not the player starting home. Balconies, light strips and holo crest |
| dining_hall | 36 x 16 | 2 (tall hall) | Yes | P1 | Long tables, Burmese food counters, notice screens |
| student_union | 30 x 20 | 3 | Yes (club rooms, cafe, bookstore) | P1 | Clubs, part-time jobs, shopping for school supplies |
| mech_hangar | 56 x 32 | 1 tall hall (~15 m) | Yes (mech bays) | P1 | Later steel-truss training hangar, composite panels, bay doors and gantries; provisional clear height for an 8-10 m Frame |
| training_ground | 80 x 60 | - | No | P1 | Later campus outdoor course; the first mecha prototype uses a contained training arena |
| sim_arena | 50 x 32 | 3 | Yes (arena floor, stands) | P1 | Indoor holo arena. Exams and tournaments |
| launch_platform | 20 x 20 | - | No | P1 | Where mechs launch during city alerts |
| stadium | 80 x 60 | 3 (stands) | Yes (field) | P2 | Intercollege mech sports and festivals |
| fieldhouse_gym | 30 x 24 | 2 | Yes | P2 | Fitness, pilot physical training |
| boathouse | 16 x 10 | 2 | Yes | P2 | On the campus lake. Rowing club, boating |
| medical_center | 20 x 16 | 2 | Yes | P1 | Where the player wakes after getting hurt on campus |
| observatory_uplink | 12 x 12 | 3 + dome | Yes | P2 | Satellite dish and telescope, night events |
| campus_maglev_stop | 20 x 8 | elevated | Yes (platform) | P1 | Connects campus to the city |

Rival colleges get their own full campuses later, each with a different speciality and style.

## 1. Landmarks (unique, made whole)
| Name | Based on | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|---|
| sule_pagoda | Sule Pagoda, centre of the roundabout | 14 x 14 | stupa ~4 | No | P1 | Open question (section 8): keep or leave out |
| shwedagon_pagoda | Shwedagon Pagoda | 60 x 60 platform | stupa ~12 | Yes (platform terrace) | P1 | Open question (section 8): keep or leave out. If kept: peaceful zone, split into bands |
| city_hall | Yangon City Hall site | 40 x 20 | 12 | Yes | P1 | Modern civic tower with a public plaza and holo notice walls |
| gov_complex | The Secretariat site | 56 x 32 | 8 | Yes (some rooms) | P2 | Modern government and defence-corps complex |
| grand_market | Bogyoke Market site | 40 x 30 | 2 | Yes | P1 | Modern covered market: steel canopy roof, stalls inside |
| river_hotel | The Strand Hotel site | 30 x 14 | 10 | Yes | P2 | Riverside luxury hotel tower |
| central_station | Yangon Central Station site | 50 x 20 | 3 | Yes | P1 | Modern Circular Line maglev hub with a glass roof |
| ferry_terminal | Pansodan jetty | 20 x 10 | 1 | Yes | P1 | Riverside ferry to Dala |
| corp_megatower | (new: cyberpunk) | 30 x 30 | 40+ | Yes (lobby, top floor) | P1 | Stacked tower parts. Visible from the whole city |

## 2. Housing

| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| apartment_cafe | 18 x 12 | 6 | Yes (family apartment, rooftop café) | **P0** | Starting home: family space, player room, café counter, covered terrace, garden, stairs/lift and parking |

### Additional housing
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| apartment_block | 16 x 12 | 6 | Yes (1 flat interior) | P1 | Generic modern walk-up with balconies, key-on-string clips and AC units; apartment_cafe is the starting family building |
| player_flat | interior only | - | Yes | P2 | Later owned apartment; an intermediate rental is proposed. The player starts at apartment_cafe |
| shophouse | 10 x 12 | 3-4 | Yes (shop floor) | P1 | Shop downstairs, flats above. Downtown's main filler |
| capsule_hotel | 10 x 10 | 5 | Yes | P1 | Cheap pod beds. Fast travel or save point |
| luxury_condo | 20 x 20 | 20+ | Yes (lobby, 1 unit) | P2 | Stacked tower parts |
| shanty_stack | 8 x 8 | 2-4 | Kit | P1 | Patched-up container and prefab stacks along streams and rail lines |
| monastery_dorm | 12 x 8 | 2 | Yes | P2 | Next to the monastery |

## 3. Food and drink
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| tea_shop | 10 x 7 | 1-2 | Yes | **P0** | Low stools, tea counter, holo menu. The social hub |
| mohinga_stall | 4 x 4 | - | No | P1 | Street stall you buy from outside |
| restaurant | 10 x 8 | 2 | Yes | P1 | Sit-down meals |
| noodle_bar | 10 x 8 | 1 | Yes | P1 | Counter seating, steam, neon |
| bakery_cafe | 10 x 8 | 2 | Yes | P1 |  |
| beer_station | 10 x 8 | 1 | Yes | P2 | Open-front bar with TV screens |
| food_court | 20 x 16 | 1 | Yes | P2 | Many vendors in one hall |
| betel_kiosk | 4 x 4 | - | No | P1 | Tiny street booth |

## 4. Shops
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| convenience_store | 10 x 8 | 1 | Yes | **P0** | 24/7 shop, fridges, ATM inside |
| wet_market_hall | 20 x 14 | 1 | Yes | P1 | Fish, meat, vegetables |
| clothes_shop | 10 x 8 | 2 | Yes | P1 | Longyi, htamein, jackets, raincoats. Fitting room to try outfits on |
| electronics_repair | 10 x 8 | 1 | Yes | P1 | Phone and implant repairs |
| pharmacy | 10 x 8 | 1 | Yes | P1 |  |
| hardware_store | 10 x 10 | 1 | Yes | P2 | Tools and parts |
| pawn_shop | 10 x 8 | 1 | Yes | P2 | Buy and sell |
| black_market | 10 x 8 | basement | Yes | P2 | Hidden entrance |
| mall | 40 x 30 | 4 | Yes (atrium, fashion floor, 3-4 shops) | P1 | Glass and neon. Main place to buy clothes and outfits, with fitting rooms and seasonal collections |

## 5. Health
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| clinic | 10 x 8 | 2 | Yes | P1 | Small doctor's office |
| hospital | 40 x 30 | 6 | Yes (lobby, ward) | P1 | Respawn point when the player gets hurt |
| cyberware_clinic | 10 x 10 | 2 | Yes | P1 | Implant installs and upgrades |
| traditional_medicine | 10 x 8 | 1 | Yes | P2 | Herbs and remedies |

## 6. Money, work and services
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| bank | 14 x 12 | 3 | Yes | P1 | Accounts and loans |
| atm_booth | 4 x 4 | - | No | P1 | Prop-sized building |
| office_tower | 20 x 20 | 15+ | Yes (lobby, 1 office floor) | P1 | Jobs. Stacked tower parts |
| post_and_parcel | 10 x 8 | 1 | Yes | P1 | Deliveries and parcel lockers |
| laundromat | 10 x 8 | 1 | Yes | P1 |  |
| barber | 10 x 8 | 1 | Yes | P1 | Hairstyle change |
| gym | 12 x 10 | 2 | Yes | P2 | Stats and training |
| workshop_garage | 12 x 10 | 1 | Yes | P1 | Vehicle repair and crafting |
| data_center | 20 x 20 | 4 | Yes (1 room) | P2 | Hacking missions |

## 7. Civic and safety
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| police_station | 16 x 12 | 3 | Yes | P1 |  |
| fire_station | 16 x 12 | 2 | Yes | P2 |  |
| ward_office | 10 x 8 | 2 | Yes | P1 | ID, permits, quests |
| school | 30 x 20 | 3 | Yes (classroom) | P1 |  |
| rival_college | varies | - | Yes | P2 | Other colleges get full campuses later (see section 0) |
| library | 16 x 12 | 2 | Yes | P2 | Lore and skills |

## 8. Religion and culture
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| monastery | 20 x 16 | 2 | Yes | P1 | Peaceful zone |
| neighbourhood_pagoda | 8 x 8 | stupa ~2 | No | P1 | Small stupas around the city |
| mosque | 16 x 16 | 2 | Yes | P2 | Downtown has several |
| hindu_temple | 12 x 10 | 2 | Yes | P2 | Colourful tower gateway |
| church | 14 x 24 | 2 | Yes | P2 |  |
| chinese_temple | 12 x 10 | 1 | Yes | P2 | Chinatown |

Keep all of these respectful: no combat or crime inside.

**Open question:** pagodas, monasteries and other religious buildings are traditional by nature. Keep them as real places in the city (an exception to the no-traditional-architecture rule), or leave them out?

## 9. Entertainment
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| arcade | 10 x 10 | 2 | Yes | P1 | Mini-games |
| karaoke_bar | 10 x 10 | 3 | Yes | P1 |  |
| cinema | 20 x 16 | 2 | Yes | P2 | Holo screens |
| night_club | 14 x 12 | 2 | Yes | P2 | Neon heavy |
| vr_parlour | 10 x 8 | 2 | Yes | P2 | Cyberpunk activity |
| park_pavilion | 8 x 8 | 1 | No | P1 | In parks like Maha Bandula Park |

## 10. Transport
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| transit_stop | 12 x 4 | - | No | **P0** | Bus or tram stop with holo timetable; canonical first-district model (legacy name: bus_stop) |
| maglev_stop | 20 x 8 | elevated | Yes (platform) | P1 | Circular Line stations along the elevated track |
| taxi_hover_rank | 10 x 4 | - | No | P1 |  |
| ev_charging_station | 12 x 10 | 1 | Yes (kiosk) | P1 | Replaces petrol stations |
| parking_tower | 20 x 20 | 6 | No | P2 | Stacked tower parts |
| river_pier | 12 x 4 | - | No | P1 | Small boats on the river quay |

## 11. Industry and utilities
| Name | Footprint (m) | Storeys | Walk-in | Priority | Notes |
|---|---|---|---|---|---|
| warehouse | 24 x 16 | 2 | Yes | P1 | Port side, missions |
| factory | 30 x 20 | 3 | Yes (1 floor) | P2 |  |
| power_substation | 10 x 10 | - | No | P1 | Fenced, sparks, hum |
| water_tower | 4 x 4 | tall | No | P1 |  |
| comm_tower | 4 x 4 | very tall | No | P1 | Antennas, blinking lights |
| recycling_yard | 20 x 16 | - | No | P2 |  |
| drone_hub | 12 x 12 | 2 | Yes | P2 | Delivery drones take off here |

## 12. Kit filler (no unique drawing)
These support later city expansion. Each style is one modular 3D kit (framework section 6), and the engine assembles hundreds of buildings from it.

| Kit style | Used for | Priority |
|---|---|---|
| concrete_block | Modular apartment stacks and shop fronts everywhere | **P0** |
| megablock | Dense Downtown housing blocks | P1 |
| glass_tower | Corporate district, offices, condos | P1 |
| patched_stack | Containers and prefab units along streams, rail lines and the river edge | P1 |

---

## First vertical slice (P0)

[FirstDistrict.md](FirstDistrict.md) is the authoritative model queue and size list. Finish one connected district before expanding the campus or city.

1. **apartment_cafe**: family apartment, player room, rooftop café, covered seating and garden; starting home.
2. **skybridge** and its stairs/lift landings: connect the family tower with **yust_side_tower**.
3. **yust_gate**, an entrance plaza, **dept_pilot** with one teaching/simulator activity, and **mech_statue**.
4. **convenience_store**, **tea_shop**, **transit_stop**, one drivable car and a second destination parking point.
5. Garden/lake edge, slope, pedestrian stairs/alternate route, roads, signals, props and one animal species.
6. One classmate, one family member, one instructor and a small ambient crowd.
7. A separate contained training arena proves the school machine, one exercise and a friendly match. The full hangar and larger campus come after the district loop works.

The pipeline and budgets are in [framework.md](framework.md). FirstDistrict dimensions are real metres; no tile/sprite conversion applies. Canonical names `yust_gate` and `transit_stop` replace catalogue aliases `main_gate` and `bus_stop`; this document update does not rename existing code or assets. `dept_alien_studies` replaces the retired Silt-specific design proposal.

## Count and scope

This is a location catalogue, not a promised launch asset count. Towers may use several reusable parts; rooms need separate furniture; skybridges need connected landings. The earlier 13/109 building and 89-interior totals belonged to the campus-first sprite plan and are retired. Use FirstDistrict.md for the initial queue and count approved models after review.
