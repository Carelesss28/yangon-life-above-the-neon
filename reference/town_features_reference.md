# Town features and visual direction

Reference checklist supplied by the user, 20 November 2026. These are design requirements and expansion ideas, not a claim that the systems already function. The systems table preserves the supplied Core/Expansion priorities; these do not make every Core item part of the first playable district.

Visual reference: [cozy_cyberpunk_scale.png](graphics/cozy_cyberpunk_scale.png).

Implementation scope remains defined in [GameConcept.md](../GameConcept.md), [framework.md](../framework.md), and [FirstDistrict.md](../FirstDistrict.md). Resolve differences before implementation: the supplied systems list proposes a 1,000 × 1,000 m town, third-person camera, about 50% enterable buildings, encounters within the map, and town damage. The current plan uses a fixed high camera, a roughly 150 × 150 m first district, and incursions outside inhabited areas. This reference records those proposals without silently changing the current plan.

## Shared simulation rules

- **The clock controls daily life:** Classes, work, shops, NPC schedules, and transport use the same game clock. Each activity needs a time policy so a 30-minute day remains playable.
- **Invasions interrupt routines predictably:** Alerts pause or reschedule affected classes and jobs. Civilians shelter, then resume their routines after the event.
- **Every enterable building has a purpose:** Each provides a service, activity, home, character interaction, mission, or exploration reward.

## Visual direction

- **Art style:** Stylized 3D with believable materials, simplified shapes, and carefully placed details.
- **Architecture:** Modern apartments, glass classrooms, balconies, rooftop cafés, and enclosed skybridges.
- **Lighting:** Warm amber interiors contrasted with restrained cyan lighting.
- **Nature:** Dense tropical trees, palms, flowering plants, gardens, and water.
- **Streets:** Walkable pavements, crossings, bus stops, small shops, and food stalls.
- **Atmosphere:** Peaceful evening life, wet-road reflections, cozy interiors, and gentle city sounds.
- **School:** Landscaped academy campus with visible classrooms, a mecha courtyard, and training facilities.
- **Hillside:** Terraced buildings, winding stairs, garden paths, and scenic overlooks.
- **Seaside:** Waterfront promenade, cafés, fishing spots, and warm lights reflected on the water.
- **Mecha:** Clean futuristic designs that share the town’s materials and accent colours.
- **Characters:** Stylized people with readable silhouettes and everyday outfits.

## Bus requirements

- **Routes:** Connect school, homes, shops, hillside entrance, and waterfront.
- **Stops:** Shelters with route maps, seating, and arrival information.
- **Boarding:** Wait, board, ride, and exit at your stop.
- **Service:** Follow roads, obey traffic lights, and stop for passengers.
- **Payment:** Pay per journey or use a student transport pass.
- **NPC use:** Students commute; residents travel to work and shops.
- **Player experience:** Sit or stand and watch the town pass by.
- **Invasion response:** Affected routes suspend or divert.

## Metro requirements

- **Routes:** Connect major districts through a few stations.
- **Stops:** Stations with entrances, platforms, signs, and ticket gates.
- **Boarding:** Enter station, reach platform, board, and exit at your destination.
- **Service:** Follow tracks, stop at stations, and operate on a timetable.
- **Payment:** Use the same student transport pass as buses.
- **NPC use:** NPCs use metro for longer journeys.
- **Player experience:** Ride inside the carriage with views through windows.
- **Invasion response:** Affected stations close temporarily, with announcements.

## Full systems checklist

| Category | System | What actually functions | Priority |
|---|---|---|---|
| **World** | Map | One connected 1,000 m × 1,000 m town with distinct neighborhoods | Core |
| World | Natural terrain | Hills, slopes, flat areas, coast, and paths that follow the terrain | Core |
| World | Districts | School, residential, commercial, workplaces, hillside, and waterfront | Core |
| World | Enterable buildings | Around 50% of buildings have usable interiors with activities or services | Core |
| World | Vertical routes | Stairs, lifts, rooftop access, and selected sky bridges connect destinations | Core |
| World | Interactive objects | Doors, seats, beds, vending machines, terminals, and lights | Core |
| World | Exploration | Hidden paths, viewpoints, collectibles, and small discoveries | Expansion |
| **Time and atmosphere** | Day/night cycle | A complete cycle every 30 real minutes; schedules follow game time | Core |
| Atmosphere | Weather | Clear skies, clouds, rain, and fog with matching sound and lighting | Expansion |
| Atmosphere | Lofi ambience | Area-based music, waves, wind, rain, and distant city sounds | Core |
| Atmosphere | Opening hours | Shops, classes, jobs, and services operate at appropriate times | Core |
| Atmosphere | Calendar | Weekdays, weekends, school events, and special occasions | Expansion |
| **Player** | Movement | Walk, run, jump, climb stairs, and navigate interiors | Core |
| Player | Camera | Third-person camera with collision handling and adjustable sensitivity | Core |
| Player | Interaction | Context actions for talking, shopping, entering, sitting, and using objects | Core |
| Player | Inventory | Carry, use, equip, store, buy, and sell items | Core |
| Player | Personal needs | Energy and hunger influence activities; food and sleep restore them | Expansion |
| Player | Skills | Persistent progress in piloting, studying, work, and social activities | Core |
| Player | Outfits | Buy and equip clothing with a preview | Expansion |
| **NPC simulation** | Identity | Each main NPC has a name, personality, home, role, and interests | Core |
| NPC simulation | Daily schedules | NPCs travel between home, school, work, shops, and leisure locations | Core |
| NPC simulation | Navigation | NPCs use paths, stairs, crossings, and building entrances | Core |
| NPC simulation | Context reactions | React to conversations, blocked routes, weather, and invasion alerts | Core |
| NPC simulation | Conversations | Dialogue changes with relationship, time, quests, and recent events | Core |
| NPC simulation | Memory | Remember selected promises, gifts, completed quests, and shared missions | Expansion |
| NPC simulation | Ambient behavior | Sit, eat, study, chat, fish, and use appropriate objects | Expansion |
| NPC simulation | Population management | Named residents persist; background crowds appear where needed | Core |
| **Relationships** | Friendship | Conversations and activities build familiarity and unlock interactions | Core |
| Relationships | Romance | Eligible characters have mutual relationship progression and dates | Expansion |
| Relationships | Shared activities | Invite NPCs to cafés, seaside walks, training, and other outings | Expansion |
| Relationships | Personal stories | Character quests reveal backgrounds and change relationships | Expansion |
| Relationships | Squad bonds | Shared missions unlock dialogue and coordinated combat abilities | Expansion |
| **School** | Enrolment and timetable | Player receives a student identity, class schedule, and academy access | Core |
| School | Lessons | Attend classes and complete short interactive learning tasks | Core |
| School | Attendance | Track participation and its effect on course progress | Core |
| School | Assessments | Practical challenges determine qualifications and unlocks | Core |
| School | Campus facilities | Classrooms, cafeteria, library, courtyard, hangar, and training areas work | Core |
| School | Clubs and activities | Join clubs, meet students, and complete optional activities | Expansion |
| School | School events | Tournaments, festivals, exhibitions, and graduation milestones | Expansion |
| **Pilot training** | Movement training | Learn turning, boosting, jumping, landing, and dodging | Core |
| Pilot training | Weapons training | Practise aiming, firing, melee attacks, and weapon switching | Core |
| Pilot training | Energy management | Learn to balance energy use, heat, shields, and movement | Core |
| Pilot training | Simulator | Repeat safe challenges with scores and feedback | Core |
| Pilot training | Pilot licence | Pass tests to unlock deployment permissions and mission tiers | Core |
| Pilot training | Friendly matches | Spar against classmates under arena rules | Expansion |
| Pilot training | Squad tactics | Practise protecting allies, holding positions, and combined attacks | Expansion |
| **Mecha** | Boarding and deployment | Enter a mecha in the hangar and deploy to a mission location | Core |
| Mecha | Controls | Move, boost, dodge, attack, defend, and target enemies | Core |
| Mecha | Combat resources | Health, energy, heat, and ammunition where applicable | Core |
| Mecha | Loadouts | Equip weapons and parts before deployment | Core |
| Mecha | Repairs | Restore damage through the hangar with a clear cost or recovery rule | Core |
| Mecha | Upgrades | Spend earned resources to improve equipment | Core |
| Mecha | Customization | Change paint, decals, and cosmetic parts | Expansion |
| Mecha | Additional models | Different mecha offer distinct movement and combat roles | Expansion |
| **Monster defence** | Mission system | Accept objectives, deploy, complete or fail, and receive results | Core |
| Monster defence | Monster behavior | Enemies detect targets, move, attack, react, and die | Core |
| Monster defence | Enemy roles | Different monsters create melee, ranged, and heavy threats | Core |
| Monster defence | Coastal and hill encounters | Fight in designated areas within the map | Core |
| Monster defence | Invasion alerts | Warnings identify the threatened area and available response | Core |
| Monster defence | Civilian response | Nearby civilians evacuate or shelter while services temporarily close | Core |
| Monster defence | Classmate allies | Selected students fight alongside the player | Expansion |
| Monster defence | Boss encounters | Larger monsters have readable attack patterns and mission objectives | Expansion |
| Monster defence | Mission consequences | Results affect rewards, dialogue, and temporary town conditions | Expansion |
| Monster defence | Town damage and recovery | Selected structures have damaged states and repair progression | Expansion |
| **Economy and jobs** | Money | Track earnings, purchases, rewards, and expenses | Core |
| Economy | Shops | Browse stock, check prices, purchase, and receive items | Core |
| Economy | Food services | Buy meals from cafés, restaurants, and vending machines | Core |
| Economy | Part-time jobs | Complete shifts or tasks to receive wages | Core |
| Economy | Career progression | Better performance unlocks higher pay and additional tasks | Expansion |
| Economy | Mission rewards | Defence missions provide credits and upgrade materials | Core |
| Economy | Town deliveries | Deliver goods between functional destinations | Expansion |
| **Housing** | Player home | Enter, sleep, store items, and change outfits | Core |
| Housing | NPC homes | Selected residents return home and can receive visits when appropriate | Expansion |
| Housing | Renting and ownership | Pay for access to housing and unlock properties | Expansion |
| Housing | Furniture | Purchase, place, rotate, and save furniture | Expansion |
| **Transport** | Road network | Connected lanes, junctions, crossings, and parking locations | Core |
| Transport | Traffic | Vehicles follow lanes, signals, and basic collision avoidance | Core |
| Transport | Driving | Enter, drive, park, and exit a player vehicle | Core |
| Transport | Vehicle ownership | Purchased vehicles remain associated with the player | Expansion |
| Transport | NPC passengers | Invite an NPC, board together, travel, and exit at the destination | Expansion |
| Transport | Public transport | Use stops and scheduled services to travel between districts | Expansion |
| Transport | Vehicle services | Purchase, repair, and customize vehicles | Expansion |
| **Hillside and seaside** | Coastal promenade | A continuous walking route with benches, lighting, and sea views | Core |
| Relaxation | Hilltop lookout | Accessible viewpoint with seating and city/ocean views | Core |
| Relaxation | Waterfront café | Buy food, sit, meet NPCs, and work shifts | Core |
| Relaxation | Fishing pier | Catch fish through a simple activity and keep or sell catches | Expansion |
| Relaxation | Gardens | Walkable green spaces with flowers, seating, and NPC activities | Core |
| Relaxation | Photography | Take and save pictures; optional photo challenges | Expansion |
| Relaxation | Animals | Birds, cats, and other suitable animals move and react | Expansion |
| Relaxation | Quiet activities | Read, study, picnic, or listen to music in designated spots | Expansion |
| **Quests and events** | Quest tracking | Record objectives, progress, completion, failure, and rewards | Core |
| Quests | Everyday requests | Help residents through deliveries, errands, and conversations | Core |
| Quests | Academy story | Progress from student training to defending the town | Core |
| Quests | Dynamic events | Occasional breakdowns, lost items, gatherings, or monster sightings | Expansion |
| **Interface** | Map and navigation | Show streets, destinations, objectives, and discovered services | Core |
| Interface | Phone | Access messages, timetable, missions, contacts, and town information | Core |
| Interface | Status displays | Show money, time, relevant player status, and combat resources | Core |
| Interface | Settings | Adjust controls, audio, graphics, subtitles, and camera behavior | Core |
| Interface | Tutorials | Introduce systems when the player first needs them | Core |
| **Technical foundation** | Save/load | Preserve progress, inventory, relationships, ownership, and world changes | Core |
| Technical | Interior loading | Load accessible interiors reliably when entering or approaching | Core |
| Technical | World streaming | Load nearby town sections while controlling memory use | Core |
| Technical | Simulation distance | Fully animate nearby NPCs; update distant routines more cheaply | Core |
| Technical | Reusable content | Add shops, NPCs, items, and jobs through shared systems and data | Core |
| Technical | Recovery behavior | Handle stuck NPCs, blocked traffic, interrupted missions, and respawning | Core |
| Technical | Performance tools | Measure frame time, memory, NPC activity, and navigation problems | Core |
