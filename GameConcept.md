# YANGON: Life above the neon — Game Concept and Plan

A cozy sci-fi student life game set in a near-future Yangon, with mecha training and occasional alien incursions.
Based on the concept plan `Yangon_YUST_Game_Concept_and_Development_Plan.pdf` (v1.0, 18 Nov 2026), adopted as the main plan.
Asset rules are in [framework.md](framework.md); the first area in [FirstDistrict.md](FirstDistrict.md); all buildings in [BuildingList.md](BuildingList.md).

The complete [Markdown reference conversion](Yangon_YUST_Game_Concept_and_Development_Plan.md) preserves all 25 numbered PDF sections. This file is the current implementation plan: later project decisions take precedence where the original PDF still says pixel art or leaves the engine and camera open. The PDF's proposals and open questions do not become confirmed requirements merely because they were imported.

This is a separate game from Zaw Gyi; do not import that project's characters, lore or release assumptions. YUST's full name and acronym, like the game title, remain provisional setting names.

Items marked **(Proposed)** are design suggestions that can still change. **(Open)** means not decided.

---

## 1. Decisions

| Topic | Decision |
|---|---|
| Title | Working title **"YANGON: Life above the neon"** (final title open) |
| Genre | Cozy sci-fi student life simulation with mecha activities |
| Platform | PC first |
| Engine | **Godot 4** (4.7.2) |
| Graphics | **3D**, stylized, with a **fixed high camera** and warm real-time lighting (reference: `reference/graphics/3d_lighting_reference.png`) |
| Art source | **3D models** from Tripo (and other 3D tools), prepared by Claude in Blender (framework.md) |
| World look | **Modern sci-fi cyberpunk** architecture only, no colonial or traditional buildings. Yangon comes through its people, food, language, signs, rain, greenery and gathering places |
| Setting | A fictional future Yangon with Myanmar names and identity |
| Player | A **customisable** 17-year-old student at **YUST: Yangon University of Science and Technology**, famous for mecha training |
| Home | The family apartment with a **family-run rooftop café** |
| Time | **30 real minutes = one full 24-hour day** (working interpretation); pausing in dialogue and menus is proposed |
| Threat | **Aliens.** Incursions happen **outside** the inhabited city, about **2-3 per in-game month** |
| Combat | Real-time action (mecha presentation details open) |
| Mechs | Mixed sizes by role; the first slice uses one school training machine |
| Relationships | Friendships and optional, age-appropriate romance with similarly aged peers |
| Economy | Jobs earn money; **outfits, vehicles and properties** can be bought |
| Mobility | Walking, futuristic public transport and traffic; **owned vehicles can be driven** and NPCs can ride along |
| Build approach | One complete working example per function first, then expand through reusable systems and data |
| Language | English |
| Team | You (design, 3D models, direction), Claude (code, Blender pipeline, planning), Codex (concept images, textures) |

---

## 2. Pillars
1. **A home worth returning to.** The rooftop café and apartment: warm light, familiar customers, family, plants, food and the city view.
2. **A distinctly Myanmar future.** Built from Yangon's social life, food, language, clothing, rain, greenery and gathering places. Technology has a local purpose.
3. **Student growth without pressure.** Regular attendance and easy practical tasks improve pilot skills. Generous retries; missed lessons can be caught up.
4. **A connected, inhabited city.** Height differences, stairs, bridges, skybridges, transit, traffic, gardens, lakes, animals and purposeful NPCs work together. A smaller, consistent neighbourhood beats a large empty map.
5. **Relationships through shared life.** Repeated encounters, café visits, classes, rides, training and optional romance. Characters have lives when the player is elsewhere.
6. **Mecha as part of life.** Classes, engineering, friendly matches and outer defence missions connect mecha play to school and friends.

**Feature filter:** does it strengthen home, student life, the city, relationships or mecha growth? What does it depend on? What is its smallest playable example?

---

## 3. Gameplay

### The connected loop
| Loop | Actions | What changes |
|---|---|---|
| Daily life | Wake at home, travel, attend a class, see friends, work or explore, return to the café | Money, relationships, knowledge of the city |
| Pilot growth | Easy exercises, practise unlocked moves, friendly matches | Pilot experience, new options |
| Personal growth | Earn money, choose clothes, decorate, save for a vehicle or property | Identity, convenience, personal space |
| Periodic events | Campus celebrations, outings, alien incursion alerts | Conversations, story, changing routines |

One activity supports several systems: giving a classmate a ride uses driving and passengers, the café visit advances a social event, and the family has something new to talk about.
**No overloaded daily checklist:** the player chooses; required story moments are announced and leave free time.

### Time
- **30 real minutes = 24 game hours:** 1 game hour = 75 real seconds.
- Under that working interpretation, 1 game minute = 1.25 real seconds; an illustrative 07:00-23:00 waking day lasts 20 real minutes before pauses. A 30-60 second task would consume 24-48 game minutes if the clock kept running.
- **(Proposed)** The clock pauses in dialogue, inventory, shops and the pause menu. Classes and matches use fixed time costs. Broad class windows with catch-up options. Transit and a quick route home so walking doesn't eat the day.
- **(Proposed)** Manual saves at safe moments plus autosaves at activity boundaries. Sleeping skips to morning but never silently skips an accepted important event.
- **(Proposed)** Consider an optional slower clock after playtesting. Month length is open: a 28-day example would put 2-3 incursions about 9-14 days apart and take 14 unpaused real hours. These are pacing examples, not a selected calendar or event schedule.

### Home and the rooftop café
| Space | Player use |
|---|---|
| Player room | Change outfits, store items, messages, save and sleep, decoration |
| Family area | Morning conversations, shared meals, story scenes |
| Café counter | Optional short shifts: read an order, prepare a simple drink or snack, deliver it to a marked table |
| Covered terrace | Meet friends, enjoy the rain, small social events |
| Rooftop garden | A quiet resting place with a view of the city |
| Building entrance | Stairs or lift, deliveries, nearby transit, parking |

The café never gets lost because a shift was skipped. Regulars arrive at recognisable times; classmates visit after training. The menu is Myanmar tea and snacks, chosen with you.

### YUST: school and pilot growth
| Campus area | Purpose |
|---|---|
| Teaching room | Short lessons, announcements, classmates |
| Simulator room | Safe piloting exercises and repeatable practice |
| Engineering workshop | Simple repairs, part matching |
| Training arena | Friendly matches and school challenges |
| Student commons | Lunch, clubs, friendships, events |
| Campus garden and transit entrance | Meeting places connected to the city |

| Class | Easy exercise (30-60 s, generous retries) | Reward |
|---|---|---|
| Piloting | Walk through wide checkpoints | Movement experience; later a boost |
| Target practice | Shoot stationary targets with aim assist | Weapon experience; later another weapon |
| Engineering | Match an illustrated part to its slot | Workshop experience; later a tuning slot |
| Energy management | Move a slider into a marked safe zone | Later power distribution |
| Teamwork | Follow a classmate and activate a shared target | Later a partner command |

- Attendance gives steady experience; major mechanics unlock through a short guided introduction, never a hard test. Pilot skill is never sold for money.
- **Earlier project rule, retained separately from the PDF:** lessons give a grade that adds academy credits; credits raise the weekly allowance. Doing poorly never ends the game. This must remain compatible with easy tasks and catch-up lessons.
- **Friendly matches** (one classmate, small arena, short rounds) are optional; a loss costs nothing and blocks nothing.
- **Mech sizes:** Utility (3-5 m) and Frame (8-10 m) at city scale; Titan (30-50 m) later on separate battle maps. Start with one school training machine.

**(Proposed) School rhythm:** broad weekly class windows, early event notices and practice retries that skip repeated introductory dialogue. Engineering club (a helper robot or café device), a festival with class stalls, study groups and a mecha showcase are expansion ideas, not first-slice requirements.

**(Proposed) Progression guardrails:** show progress per subject, award modest experience for supported completion, and limit repetitive rewards only if grinding becomes dominant. Controls must feel responsive from the beginning; skill unlocks add options or efficiency rather than removing artificial input lag or random steering.

**(Proposed) First match:** one school machine, one opponent and one arena, with movement, one basic attack and one defensive action. Clear feedback, a short tutorial and a quick rematch. A 2-4 minute duration is only a playtest target. A loss does not remove money, equipment, friendship or school access. Team exercises and tournaments follow a working solo match. Number of pilots, personal mecha ownership and real-battle difficulty remain open.

### Alien incursions
**Notice** (alerts on transit screens and school messages) → **preparation** (save, check equipment, meet the team) → **deployment** to a separate outer defence zone → **mission** (defend a perimeter, intercept a threat) → **return** (debrief, rewards, people react) → **recovery** (calm café and campus days).
- Incursions happen outside the city; daily life continues with worried conversations and route changes, not constant destruction.
- **(Proposed)** Only selected story missions are compulsory; others are handled by trained forces or offered as optional.
- No civilian deaths, permanent companion loss or destroyed player property by default.
- A story reason is needed for why a 17-year-old deploys (Proposed: simulator-only at first, supervised by the adult defence corps).

### NPCs
Authored schedules, personality, memory (requests, invitations, rides, story events), context (time, weather, location, friendship, recent incursions), social ties, and world use (sitting, shopping, transit, sheltering from rain, visiting the café).
- **Interaction menu:** Talk, Invite, Offer Ride, Ask About Schedule, Give Item, shown only when relevant.
- Invited passengers suspend their schedule; accepted activities reserve the NPC; NPCs never teleport in view.
- Start with one deep classmate, one family member and a small ambient crowd. **Animals:** start with one species (e.g. cats near warm machinery).

**(Proposed) Dialogue priority:** urgent activity/alert -> accepted invitation -> personal event -> location comment -> ordinary conversation. Record one-time scenes and always provide an exit. Rain or alerts may redirect routines, but changed destinations must remain discoverable. Communicate a missed or unavailable invitation and allow a friendly follow-up; limit simultaneous invitations and let the player decline.

Major characters need authored scenes and identities; personality labels alone are not enough. Ambient commuters can use short routes, crossings and nearby destinations with simplified off-screen simulation. Live language-model dialogue has not been selected. Animal ownership, feeding and care systems remain optional future decisions.

### Friendship and romance
Acquaintance → familiar friend → close friend → optional romantic interest → relationship. Non-explicit, similarly aged peers only, instructors never romance options. Friendship stories don't require dating. Gifts help but don't buy affection.

**(Proposed)** Shared activities include a ride to a lakeside stall, a study/repair session at the café, a festival or friendly match, and a quiet conversation after a mission. Keep preferences and boundaries without punishing every minor mistake. Romance cast, genders, exclusivity and milestones remain open; a particular number of romance options is not confirmed.

### Economy and ownership
| Job | Easy activity |
|---|---|
| Family café | Serve a few clearly shown orders |
| Campus helper | Deliver materials, organise components |
| Robot repair | Match parts, short repair sequence |
| Tutoring | A guided exercise with another student |
| Local delivery | Carry an order along a familiar route |

- **Purchase ladder:** clothes and treats early, a scooter or car mid-term, property later. Prices are set in "short enjoyable work sessions" (e.g. outfit 1-2 shifts, starter vehicle 10-15).
- **Outfits:** everyday fashion, futuristic Myanmar-inspired clothing (longyi, htamein, jackets, raincoats), accessories, pilot-suit cosmetics. Uniform and pilot suit are earned. Wardrobe at home.
- **Vehicles:** one small electric car first: find it, drive, park, invite an NPC, travel together.
- **Properties:** family room → (Proposed) rentable studio → owned apartment. A story rule is needed for a 17-year-old buying property (Open).

**(Proposed) Economy checks:** optional work must not become a daily fee for school access or keeping the family home. Show prices and insufficient-funds feedback; charge once, record ownership and save reliably. Mission rewards should not make civilian jobs pointless. Currency, pay, prices, recurring expenses and property restrictions remain open. Uniform/pilot-suit earning rules above are retained earlier project decisions, not new requirements from the PDF.

Purchases must change lived play: visible outfit changes, usable vehicles and meaningful interiors. Renting is optional and does not replace the confirmed ability to purchase property. Decoration is additional scope; test fixed furnishing slots or a limited grid before free placement.

### Driving and transport
| Vehicle | Role | Priority |
|---|---|---|
| Small electric car | First owned drivable vehicle, one passenger | First example |
| Electric bus or tram | Scheduled travel between key places | After walking works |
| Hover scooter | Near-ground student transport in road lanes | Later |
| Elevated train | District connections and skyline views | Later |
| Delivery cart | Ambient supplies, café activity | Simple ambient route |
| Lake ferry | Only if waterways need it | Optional |

Cozy driving: forgiving handling, moderate speed, clear road edges. No crash damage, fuel or police by default. Traffic has lanes, signals, crossings and queues. Ordinary vehicles stay on roads and ramps; skybridges are for people.

**(Proposed) Passenger flow:** check NPC availability -> confirm destination -> approach a valid parked vehicle -> check a free seat -> board -> suspend the NPC's normal route -> travel with limited context dialogue -> stop at valid parking -> both exit -> resume/update the shared activity. Boarding must be protected from moving traffic. A declined or cancelled ride must release the NPC's reserved activity and seat.

Detailed vehicle simulation is local to the player; spawn traffic out of sight and simplify distant traffic where possible. Insurance, severe collisions and racing are not implied by driving. Fully flying vehicles need new controls, navigation and camera work, not just another vehicle data entry.

### The city: layers
| Layer | Places and movement |
|---|---|
| Street level | Shops, café entrances, crossings, buses, cars, delivery stops |
| Sloped neighbourhoods | Terraces, stairways, planted edges, alternative routes |
| Tower level | Lobbies, lifts, skybridges, shared gardens |
| Rooftops | The family café, seating, private gardens |
| Water and parks | Lake paths, gardens, quiet seating |
| Outer defence zone | Training grounds and mission areas beyond the city |

Every bridge has a visible entrance and destination; stairs show their landing and direction; foreground buildings, bridges and roofs fade or cut away when they hide the player.

This is a fictional future interpretation of Yangon. Strong hills and engineered terraces are intentional setting choices, not a claim to reproduce today's geography. Use consistent lift markers, shop fronts, map icons and route signs.

---

## 4. First playable slice
| Feature | One complete example | Success condition |
|---|---|---|
| World | One neighbourhood with a slope or stairs, one skybridge, a small garden | Routes readable, player never hidden |
| Home / café | One room and one optional serving task | Start, complete, earn pay, save |
| School | One classroom and one easy piloting exercise | Attend and see a skill improve |
| NPC | One classmate with a routine, context dialogue and an invitation | Appears where expected, remembers the event |
| Driving | One car, one passenger, two parking points | Invite, board, travel, exit, resume |
| Economy | One job and one outfit purchase | Money and appearance persist after loading |
| Mecha | One training machine, one opponent, one arena | A short friendly match is clear and replayable |
| Time / life | Clock, night lighting, one animal, a small crowd | The world changes without breaking activities |

**The slice loop:** leave home → short class → invite a classmate → drive to the café → work a shift or socialise → buy an outfit → return home and save. A separate training arena proves mecha play.

**Deferred:** more districts, a big cast, multiple properties, flying vehicles, team combat, complex decoration, repeated incursion content.

---

## 5. How it's built

### Godot (3D)
- **Camera:** fixed high angle, gently following the player; roofs, bridges and walls between camera and player fade.
- **Lighting:** directional sun/moon with a day-night cycle, warm point lights for windows and lanterns, emissive neon, soft shadows, ambient occlusion, bloom, fog and rain.
- **World:** 3D terrain with real slopes, stairs and multiple levels; skybridges and interiors are part of the same world where possible.
- **Characters:** rigged 3D models with shared animations; outfits as swappable meshes on one skeleton.
- **Navigation:** Godot NavigationMesh for pedestrians; lane routes, signals and queues for traffic.
- **Data-driven systems:** vehicles, NPCs, classes, jobs, properties and mecha abilities defined as data with stable IDs; activities emit events (ClassCompleted, RideFinished, ItemPurchased, IncursionResolved) that other systems react to.
- **Save:** clock, calendar, location, money, inventory, ownership, skills, relationships, accepted activities and passenger state; versioned format.
- The earlier **2D isometric prototype** (`game/`) is replaced by a 3D project; its isometric scripts are kept only until the 3D test scene works.

Separate static definitions from saved state: base vehicle price belongs in content data; the purchased vehicle and parking location belong in the save. Relationship progress is saved state, not a dialogue text file. Use versioned save migrations. Data can add supported content; new behaviour still needs code, art and verification.

### Build order
| Stage | Build | Done when |
|---|---|---|
| 1. Foundations | **3D test scene:** camera, lighting, walking, a slope, stairs, one skybridge, one Tripo building, roof fading | A small layered map is clear to navigate and looks like the reference |
| 2. State | Clock, interaction, transitions, money, save/load | A purchase and a time change survive loading |
| 3. Home-school loop | Café task, class task, skill progress, one NPC routine | A relaxed day has real choices |
| 4. Driving | One car, lane traffic, parking, NPC boarding | Drive between two places with a passenger |
| 5. Mecha | Training room, basic controls, one exercise, a friendly duel | Mecha control feels good |
| 6. Social events | Invitations, shared rides, café scenes, relationship memory | Activities don't clash with schedules |
| 7. One outer mission | Alert, preparation, defence area, return scene | The city stays coherent through it |
| 8. Expand | More NPCs, classes, vehicles, purchases, neighbourhoods | New content reuses the systems |

---

## 6. Open decisions
- Final game title.
- Time: confirm 30 minutes = full 24 hours, and the pause rules.
- Calendar: days per month, school week, event frequency.
- Player identity: customisation details, pronouns, backstory.
- Family and café: family members, café name, menu, home layout.
- First classmate: personality, routine, interests, shared activity.
- Mecha combat: presentation, difficulty, how compulsory deployments are, ownership.
- Housing: when a 17-year-old can own property and what it enables.
- Religious buildings (pagodas, monasteries): keep as an exception to the modern-only rule, or leave out.
- Target PC hardware.
- PC operating systems, storefront and controller support.
- Mecha pilot count, action depth and the training/supervision threshold for real deployment.
- Currency, wages, prices, recurring expenses and outfit statistics.
- Romance cast, exclusivity, milestones and final number of options.
- Production estimates: estimate after the world, driving and mecha prototypes expose actual work, rather than assigning a release date now.

## 7. Risks
| Risk | Response | Check |
|---|---|---|
| Days feel rushed | Pauses, flexible class windows, short trips | Can a new player finish a class and one leisure activity comfortably? |
| Buildings hide the player | Fading and cut-away, distinct levels and crossings | Walk behind every tall structure and over every bridge |
| NPCs feel inconsistent | Availability rules, schedule overrides, memory | Invite someone before class, in rain, during an alert |
| Passengers break routines | Explicit board, seat, travel and exit states | Save and load while parked with a passenger |
| Combat overwhelms cozy life | Separate defence spaces, forgiving matches | Does a loss still allow a good ordinary day? |
| Economy grind | Prices measured in short enjoyable jobs | Count shifts per purchase |
| Too many features | Small connected slice first | Can one full day be played before adding a district? |
| 3D model consistency | One shared material, lighting and post-processing style; Blender clean-up for every model | Side-by-side check with the reference screenshot |
| Performance | Polygon and texture budgets, LODs, limited active traffic and crowds | Profile busy crossings on target PCs |
| Real-world sensitivity | Fictional alien enemy, battles outside the city, no real politics | Your review of local details |
| Teen characters | Age-appropriate, non-explicit relationships | — |

### Comfort and accessibility (Proposed)
Remappable controls, readable interact prompts, adjustable UI/text size, subtitles, reduced flashing and screen shake, and optional aim assistance. Controller support is still open. A slower optional clock should be evaluated through playtests.

### Integration checks
- Complete a class during a time transition and check rewards and the next class window.
- Accept an invitation across a schedule change, during rain and during an alert.
- Purchase an outfit immediately before saving: one charge, one ownership record, correct appearance after loading.
- Board beside moving traffic; save/load while parked with a passenger; exit and resume the outing without a stranded NPC.
- Traverse every stair, ramp and skybridge at night and check camera occlusion.
- Return from the outer defence area and verify time, ownership, conversations and normal city routines.

## 8. Next planning work
Define the first ordinary day, family/café identity and one classmate before increasing the cast. [FirstDistrict.md](FirstDistrict.md) supplies the locations for the first connected loop. All other neighbourhoods and the larger campus remain expansion plans.

### Reusable feature card
For each new feature record: player action; reason to include it; location; related NPC; required systems; smallest complete example; static content data; saved state; completion check; release priority. Keep proposed features distinct from approved commitments.

## 9. Example day (Proposed)
1. **Morning at home:** choose an outfit, speak with family, check the school activity as the café opens.
2. **Travel to YUST:** walk the stairs, pass the garden and crossing; choose transit, the skybridge or an owned vehicle.
3. **Short lesson:** guide the training machine through wide checkpoints, gain visible experience and hear about a future friendly match.
4. **Afternoon choice:** work, practise, visit the lake or offer a classmate a ride to the café; reserve their time for the outing.
5. **Evening café:** the friend takes a covered seat, a short shift earns money, and dialogue recalls school and the visit. Buy an outfit or save toward a vehicle.
6. **On an incursion day:** an announced external mission may change the rhythm. Return to family and campus conversations, then calm home activities.

This example sets the intended feeling; its characters, timings and rewards are not new confirmed lore.
